import '../../core/school_time.dart';
import '../../models/daily_checklist_model.dart';

enum AttendanceStatus { initial, loading, loaded, error }

enum CheckInStatus { idle, gettingLocation, submitting, success, failure }

class AttendanceState {
  final AttendanceStatus status;
  final List<DailyChecklistItem> sessions;
  final String? errorMessage;
  final String? syncMessage;
  final DateTime selectedDate;

  final CheckInStatus checkInStatus;
  final String? checkInError;
  final String? checkingInSessionId;

  AttendanceState({
    this.status = AttendanceStatus.initial,
    this.sessions = const [],
    this.errorMessage,
    this.syncMessage,
    DateTime? selectedDate,
    this.checkInStatus = CheckInStatus.idle,
    this.checkInError,
    this.checkingInSessionId,
  }) : selectedDate = selectedDate ?? SchoolTime.now();

  AttendanceState copyWith({
    AttendanceStatus? status,
    List<DailyChecklistItem>? sessions,
    String? errorMessage,
    String? syncMessage,
    DateTime? selectedDate,
    CheckInStatus? checkInStatus,
    String? checkInError,
    String? checkingInSessionId,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
      syncMessage: syncMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      checkInError: checkInError,
      checkingInSessionId: checkingInSessionId,
    );
  }
}
