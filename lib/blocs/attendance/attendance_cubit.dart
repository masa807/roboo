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

  /// بيحمّل حصص اليوم الحالي (عند أول فتح)
  Future<void> loadToday() async {
    await loadDate(DateTime.now());
  }

  /// بيحمّل حصص يوم معين (بُستعمل من الكالندر)
  Future<void> loadDate(DateTime date) async {
    emit(state.copyWith(status: AttendanceStatus.loading, selectedDate: date));
    try {
      final sessions = await _repository.getDailyChecklist(
        trainerId: trainerId,
        date: date,
      );
      emit(
        state.copyWith(
          status: AttendanceStatus.loaded,
          sessions: sessions,
          selectedDate: date,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: AttendanceStatus.error, errorMessage: e.message),
      );
    }
  }

  Future<bool> checkIn(String sessionTrainerId) async {
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
            checkInError: 'خدمة الموقع مطفية، فعّليها من إعدادات الجهاز',
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
            checkInError: 'لازم تسمح بالوصول للموقع لتسجيل الحضور',
          ),
        );
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      emit(state.copyWith(checkInStatus: CheckInStatus.submitting));

      await _repository.checkIn(
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
          checkInError: 'تعذر تحديد الموقع، حاول مرة تانية',
        ),
      );
      return false;
    }
  }
}
