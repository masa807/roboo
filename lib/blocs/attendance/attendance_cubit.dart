import '../../core/school_time.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/api_client.dart';
import '../../repositories/attendance_repository.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  AttendanceCubit(this._repository, {required this.trainerId})
    : super(AttendanceState());

  final AttendanceRepository _repository;
  final String trainerId;
  int _request = 0;
  @override
  void emit(AttendanceState state) {
    if (!isClosed) super.emit(state);
  }

  /// بيحمّل حصص اليوم الحالي (عند أول فتح)
  Future<void> loadToday() async {
    await loadDate(SchoolTime.now());
  }

  /// بيحمّل حصص يوم معين (بُستعمل من الكالندر)
  Future<void> loadDate(DateTime date) async {
    if (isClosed) return;
    final request = ++_request;
    emit(state.copyWith(status: AttendanceStatus.loading, selectedDate: date));
    try {
      final sessions = await _repository.getDailyChecklist(
        trainerId: trainerId,
        date: date,
      );
      final message = await _repository.pendingMessage(trainerId);
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          syncMessage: message,
          status: AttendanceStatus.loaded,
          sessions: sessions,
          selectedDate: date,
        ),
      );
    } catch (e) {
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: AttendanceStatus.error,
          errorMessage: e is ApiException ? e.message : 'تعذر تحميل الحضور.',
        ),
      );
    }
  }

  Future<bool> checkIn(String sessionTrainerId) async {
    if (isClosed ||
        state.checkInStatus == CheckInStatus.gettingLocation ||
        state.checkInStatus == CheckInStatus.submitting) {
      return false;
    }
    emit(
      state.copyWith(
        checkInStatus: CheckInStatus.gettingLocation,
        checkingInSessionId: sessionTrainerId,
      ),
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(
          state.copyWith(
            checkInStatus: CheckInStatus.failure,
            checkInError: 'خدمة الموقع غير مفعلة ',
          ),
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(
          state.copyWith(
            checkInStatus: CheckInStatus.failure,
            checkInError: 'الرجاء السماح للتطبيق بالوصول لموقعك',
          ),
        );
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (isClosed) return false;
      emit(state.copyWith(checkInStatus: CheckInStatus.submitting));

      await _repository.checkIn(
        trainerId: trainerId,
        sessionTrainerId: sessionTrainerId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        isMocked: position.isMocked,
      );

      emit(state.copyWith(checkInStatus: CheckInStatus.success));
      await loadDate(state.selectedDate); // نحدّث بنفس اليوم المختار
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          checkInStatus: CheckInStatus.failure,
          checkInError: e.message,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          checkInStatus: CheckInStatus.failure,
          checkInError: 'تعذر تحديد الموقع، حاول مرة اخرى',
        ),
      );
      return false;
    }
  }
}
