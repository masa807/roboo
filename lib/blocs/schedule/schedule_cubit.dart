import '../../core/school_time.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repository, {required this.trainerId})
    : super(ScheduleState(weekStart: _sundayOf(SchoolTime.now())));

  final ScheduleRepository _repository;
  final String trainerId;
  int _request = 0;

  /// بيرجع الأحد تبع الأسبوع يلي فيه [date] (الأسبوع بمنطقتنا بيبلش من الأحد)
  static DateTime _sundayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // DateTime.weekday: الاثنين=1 ... الأحد=7
    final daysSinceSunday = d.weekday % 7; // الأحد=0, الاثنين=1 ... السبت=6
    return d.subtract(Duration(days: daysSinceSunday));
  }

  Future<void> loadWeek() async {
    if (isClosed) return;
    final request = ++_request;
    emit(state.copyWith(status: ScheduleStatus.loading));
    try {
      final sessions = await _repository.getWeeklySchedule(
        trainerId: trainerId,
        weekStart: state.weekStart,
      );
      if (isClosed || request != _request) return;
      emit(state.copyWith(status: ScheduleStatus.loaded, sessions: sessions));
    } catch (e) {
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          status: ScheduleStatus.error,
          errorMessage: e is ApiException
              ? e.message
              : 'تعذر قراءة الجدول، أعد المحاولة.',
        ),
      );
    }
  }

  Future<void> nextWeek() async {
    if (isClosed) return;
    emit(
      state.copyWith(weekStart: state.weekStart.add(const Duration(days: 7))),
    );
    await loadWeek();
  }

  Future<void> previousWeek() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        weekStart: state.weekStart.subtract(const Duration(days: 7)),
      ),
    );
    await loadWeek();
  }
}
