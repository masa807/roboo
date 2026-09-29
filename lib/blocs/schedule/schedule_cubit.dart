import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit(this._repository, {required this.trainerId})
    : super(ScheduleState(weekStart: _sundayOf(DateTime.now())));

  final ScheduleRepository _repository;
  final String trainerId;

  /// بيرجع الأحد تبع الأسبوع يلي فيه [date] (الأسبوع بمنطقتنا بيبلش من الأحد)
  static DateTime _sundayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // DateTime.weekday: الاثنين=1 ... الأحد=7
    final daysSinceSunday = d.weekday % 7; // الأحد=0, الاثنين=1 ... السبت=6
    return d.subtract(Duration(days: daysSinceSunday));
  }

  Future<void> loadWeek() async {
    emit(state.copyWith(status: ScheduleStatus.loading));
    try {
      final sessions = await _repository.getWeeklySchedule(
        trainerId: trainerId,
        weekStart: state.weekStart,
      );
      emit(state.copyWith(status: ScheduleStatus.loaded, sessions: sessions));
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: ScheduleStatus.error, errorMessage: e.message),
      );
    }
  }

  Future<void> nextWeek() async {
    emit(
      state.copyWith(weekStart: state.weekStart.add(const Duration(days: 7))),
    );
    await loadWeek();
  }

  Future<void> previousWeek() async {
    emit(
      state.copyWith(
        weekStart: state.weekStart.subtract(const Duration(days: 7)),
      ),
    );
    await loadWeek();
  }
}
