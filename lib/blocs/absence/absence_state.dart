import '../../models/leave_request_model.dart';

enum AbsenceStatus { initial, loading, loaded, error }

/// حالة إضافية لعملية submit/cancel/approve/reject لحالها،
/// حتى ما تتعارض مع حالة تحميل القائمة.
enum AbsenceActionStatus { idle, submitting, success, failure }

class AbsenceState {
  final AbsenceStatus status;
  final List<LeaveRequestModel> requests;
  final String? errorMessage;

  final AbsenceActionStatus actionStatus;
  final String? actionError;

  const AbsenceState({
    this.status = AbsenceStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.actionStatus = AbsenceActionStatus.idle,
    this.actionError,
  });

  AbsenceState copyWith({
    AbsenceStatus? status,
    List<LeaveRequestModel>? requests,
    String? errorMessage,
    AbsenceActionStatus? actionStatus,
    String? actionError,
  }) {
    return AbsenceState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: actionError,
    );
  }
}
