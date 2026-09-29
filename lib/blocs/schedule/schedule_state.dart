import '../../models/weekly_schedule_model.dart';

enum ScheduleStatus { initial, loading, loaded, error }

class ScheduleState {
  final ScheduleStatus status;
  final DateTime weekStart;
  final List<WeeklyScheduleItem> sessions;
  final String? errorMessage;

  const ScheduleState({
    this.status = ScheduleStatus.initial,
    required this.weekStart,
    this.sessions = const [],
    this.errorMessage,
  });

  ScheduleState copyWith({
    ScheduleStatus? status,
    DateTime? weekStart,
    List<WeeklyScheduleItem>? sessions,
    String? errorMessage,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      weekStart: weekStart ?? this.weekStart,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }
}
