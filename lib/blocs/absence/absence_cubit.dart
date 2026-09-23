import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../models/leave_request_model.dart';
import '../../repositories/leave_request_repository.dart';
import 'absence_state.dart';

class AbsenceCubit extends Cubit<AbsenceState> {
  AbsenceCubit(this._repository, {required this.trainerId})
    : super(const AbsenceState());

  final LeaveRequestRepository _repository;
  final String trainerId;

  /// يجيب طلبات الغياب تبع المدرب. [status] اختياري للفلترة.
  Future<void> loadRequests({LeaveRequestStatus? status}) async {
    emit(state.copyWith(status: AbsenceStatus.loading));
    try {
      final requests = await _repository.getTrainerLeaveRequests(
        trainerId: trainerId,
        status: status,
      );
      emit(state.copyWith(status: AbsenceStatus.loaded, requests: requests));
    } on ApiException catch (e) {
      emit(
        state.copyWith(status: AbsenceStatus.error, errorMessage: e.message),
      );
    }
  }

  /// إرسال طلب غياب جديد. بعد النجاح بيعيد تحميل القائمة تلقائياً.
  Future<bool> submitRequest({
    required String reason,
    required LeaveSelectionMode selectionMode,
    DateTime? targetDate,
    List<String> sessionTrainerIds = const [],
    String? proposedSubstituteTrainerId,
  }) async {
    emit(state.copyWith(actionStatus: AbsenceActionStatus.submitting));
    try {
      await _repository.createLeaveRequest(
        CreateLeaveRequestPayload(
          trainerId: trainerId,
          reason: reason,
          selectionMode: selectionMode,
          targetDate: targetDate,
          sessionTrainerIds: sessionTrainerIds,
          proposedSubstituteTrainerId: proposedSubstituteTrainerId,
        ),
      );
      emit(state.copyWith(actionStatus: AbsenceActionStatus.success));
      await loadRequests();
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          actionStatus: AbsenceActionStatus.failure,
          actionError: e.message,
        ),
      );
      return false;
    }
  }

  /// إلغاء طلب غياب (من طرف المدرب صاحب الطلب)
  Future<bool> cancelRequest(String requestId) async {
    emit(state.copyWith(actionStatus: AbsenceActionStatus.submitting));
    try {
      await _repository.cancelLeaveRequest(requestId);
      emit(state.copyWith(actionStatus: AbsenceActionStatus.success));
      await loadRequests();
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          actionStatus: AbsenceActionStatus.failure,
          actionError: e.message,
        ),
      );
      return false;
    }
  }

  /// موافقة الأدمن على الطلب
  Future<bool> approveRequest(
    String requestId, {
    required String reviewedBy,
  }) async {
    emit(state.copyWith(actionStatus: AbsenceActionStatus.submitting));
    try {
      await _repository.approveLeaveRequest(requestId, reviewedBy: reviewedBy);
      emit(state.copyWith(actionStatus: AbsenceActionStatus.success));
      await loadRequests();
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          actionStatus: AbsenceActionStatus.failure,
          actionError: e.message,
        ),
      );
      return false;
    }
  }

  /// رفض الأدمن للطلب
  Future<bool> rejectRequest(
    String requestId, {
    required String reviewedBy,
  }) async {
    emit(state.copyWith(actionStatus: AbsenceActionStatus.submitting));
    try {
      await _repository.rejectLeaveRequest(requestId, reviewedBy: reviewedBy);
      emit(state.copyWith(actionStatus: AbsenceActionStatus.success));
      await loadRequests();
      return true;
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          actionStatus: AbsenceActionStatus.failure,
          actionError: e.message,
        ),
      );
      return false;
    }
  }

  /// جلب المدربين البدلاء المتاحين لحصص معينة
  Future<List<SubstituteTrainerModel>> loadAvailableSubstitutes(
    List<String> sessionIds,
  ) {
    return _repository.getAvailableSubstitutes(
      trainerId: trainerId,
      sessionIds: sessionIds,
    );
  }
}
