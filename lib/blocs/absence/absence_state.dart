import '../../models/leave_request_model.dart';

enum AbsenceStatus { initial, loading, loaded, error }

/// حالة إضافية لعملية submit/cancel/approve/reject لحالها،
/// حتى ما تتعارض مع حالة تحميل القائمة.
enum AbsenceActionStatus { idle, submitting, success, failure }

class AbsenceState {
  final AbsenceStatus status;
  final bool hasMore;
  final bool loadingMore;
  final List<LeaveRequestModel> requests;
  final String? errorMessage;

  final AbsenceActionStatus actionStatus;
  final String? actionError;

  const AbsenceState({
    this.status = AbsenceStatus.initial,
    this.hasMore = false,
    this.loadingMore = false,
    this.requests = const [],
    this.errorMessage,
    this.actionStatus = AbsenceActionStatus.idle,
    this.actionError,
  });

  AbsenceState copyWith({
    AbsenceStatus? status,
    bool? hasMore,
    bool? loadingMore,
    List<LeaveRequestModel>? requests,
    String? errorMessage,
    AbsenceActionStatus? actionStatus,
    String? actionError,
  }) {
    return AbsenceState(
      status: status ?? this.status,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      requests: requests ?? this.requests,
      errorMessage: errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionError: actionError,
    );
  }
}
