import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../models/daily_checklist_model.dart';
import '../../models/leave_request_model.dart';
import '../../repositories/leave_request_repository.dart';
import 'absence_state.dart';

class AbsenceCubit extends Cubit<AbsenceState> {
  AbsenceCubit(
    this._repository, {
    required this.trainerId,
    this.sessionsFetcher,
  }) : super(const AbsenceState());

  final LeaveRequestRepository _repository;
  final String trainerId;
  int _page = 1;
  int _generation = 0;
  LeaveRequestStatus? _filter;
  @override
  void emit(AbsenceState state) {
    if (!isClosed) super.emit(state);
  }

  Future<void> loadMore() async {
    if (isClosed ||
        state.status == AbsenceStatus.loading ||
        !state.hasMore ||
        state.loadingMore) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(loadingMore: true));
    try {
      final next = await _repository.getTrainerLeaveRequests(
        trainerId: trainerId,
        status: _filter,
        page: _page + 1,
      );
      if (isClosed || generation != _generation) return;
      _page++;
      final ids = state.requests.map((r) => r.id).toSet();
      emit(
        state.copyWith(
          requests: [
            ...state.requests,
            ...next.where((r) => !ids.contains(r.id)),
          ],
          hasMore: next.length == 20,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (generation == _generation) {
        emit(
          state.copyWith(
            loadingMore: false,
            actionStatus: AbsenceActionStatus.failure,
            actionError: 'تعذر تحميل المزيد، أعد المحاولة.',
          ),
        );
      }
    }
  }

  /// دالة بتجيب حصص المدرب بتاريخ معين (نفس مصدر daily-checklist)
  final Future<List<DailyChecklistItem>> Function(DateTime date)?
  sessionsFetcher;

  /// تحويل أخطاء الباك إند المعروفة لرسائل عربية واضحة.
  /// [substituteProposed] = true لما الطلب كان فيه بديل مقترح.
  String _friendlyMessage(ApiException e, {bool substituteProposed = false}) {
    final msg = e.message;

    // POST /leave-requests: بديل معطّل -> 403 (SubstituteNotAllowed)
    if (msg.contains('SubstituteNotAllowed') ||
        (e.statusCode == 403 && substituteProposed)) {
      return 'البديل المختار غير متاح حالياً، اختر بديلاً آخر';
    }

    // approve: أخطاء 409 الجديدة
    if (msg.contains('SubstituteInactive')) {
      return 'البديل المقترح لم يعد فعّالاً';
    }
    if (msg.contains('SessionCancelled')) {
      return 'إحدى الحصص المرتبطة بالطلب أصبحت ملغاة';
    }

    return msg;
  }

  /// جلب حصص يوم معين لعرضها بحقل "الحصة"
  Future<List<DailyChecklistItem>> loadSessionsForDate(DateTime date) async {
    final fetcher = sessionsFetcher;
    if (fetcher == null) return const [];
    return fetcher(date);
  }

  /// يجيب طلبات الغياب تبع المدرب. [status] اختياري للفلترة.
  Future<void> loadRequests({LeaveRequestStatus? status}) async {
    if (isClosed) return;
    final generation = ++_generation;
    _page = 1;
    _filter = status;
    emit(state.copyWith(status: AbsenceStatus.loading, loadingMore: false));
    try {
      final requests = await _repository.getTrainerLeaveRequests(
        trainerId: trainerId,
        status: status,
      );
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: AbsenceStatus.loaded,
          requests: requests,
          hasMore: requests.length == 20,
        ),
      );
    } catch (e) {
      if (generation != _generation || isClosed) return;
      emit(
        state.copyWith(
          status: AbsenceStatus.error,
          errorMessage: e is ApiException
              ? e.message
              : 'تعذر قراءة الطلبات، أعد المحاولة.',
        ),
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
    if (isClosed || state.actionStatus == AbsenceActionStatus.submitting) {
      return false;
    }
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
          actionError: _friendlyMessage(
            e,
            substituteProposed: proposedSubstituteTrainerId != null,
          ),
        ),
      );
      return false;
    }
  }

  /// إلغاء طلب غياب (من طرف المدرب صاحب الطلب)
  Future<bool> cancelRequest(String requestId) async {
    if (isClosed || state.actionStatus == AbsenceActionStatus.submitting) {
      return false;
    }
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
          actionError: _friendlyMessage(e),
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
