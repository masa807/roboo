import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.page = 0,
    this.totalCount = 0,
    this.unreadCount = 0,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final int page;
  final int totalCount;

  /// عدد غير المقروء من السيرفر (مو من القائمة المحمّلة)
  final int unreadCount;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => items.length < totalCount;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? page,
    int? totalCount,
    int? unreadCount,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());

  final NotificationRepository _repository;
  static const int _pageSize = 20;
  int _generation = 0;
  int _countGeneration = 0;

  /// جلب عدد غير المقروء فقط (للشارة على الجرس)
  Future<void> loadUnreadCount() async {
    if (isClosed) return;
    final generation = ++_countGeneration;
    try {
      final count = await _repository.getUnreadCount();
      if (isClosed || generation != _countGeneration) return;
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // الشارة مو أساسية، بنتجاهل الخطأ
    }
  }

  /// تحميل أول صفحة
  Future<void> load() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(
      state.copyWith(status: NotificationsStatus.loading, isLoadingMore: false),
    );
    try {
      final result = await _repository.getNotifications(
        page: 1,
        pageSize: _pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        NotificationsState(
          status: NotificationsStatus.success,
          items: result.items,
          page: result.page,
          totalCount: result.totalCount,
          unreadCount: state.unreadCount,
        ),
      );
      loadUnreadCount();
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: 'تعذر تحميل الإشعارات',
        ),
      );
    }
  }

  /// تحديث بالسحب (ما بيرجع لحالة loading عشان القائمة ما تفرغ)
  Future<void> refresh() async {
    if (isClosed) return;
    final generation = ++_generation;
    emit(state.copyWith(isLoadingMore: false));
    try {
      final result = await _repository.getNotifications(
        page: 1,
        pageSize: _pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        NotificationsState(
          status: NotificationsStatus.success,
          items: result.items,
          page: result.page,
          totalCount: result.totalCount,
          unreadCount: state.unreadCount,
        ),
      );
      loadUnreadCount();
    } catch (_) {
      // بنبقي القائمة الحالية كما هي
    }
  }

  /// تحميل الصفحة التالية عند الوصول لآخر القائمة
  Future<void> loadMore() async {
    if (isClosed ||
        state.isLoadingMore ||
        !state.hasMore ||
        state.status != NotificationsStatus.success) {
      return;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await _repository.getNotifications(
        page: state.page + 1,
        pageSize: _pageSize,
      );
      if (isClosed || generation != _generation) return;
      emit(
        state.copyWith(
          items: [
            ...state.items,
            ...result.items.where(
              (item) => !state.items.any((existing) => existing.id == item.id),
            ),
          ],
          page: result.page,
          totalCount: result.totalCount,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || generation != _generation) return;
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// تمييز إشعار كمقروء: تحديث فوري، وإذا فشل الطلب منرجّع القديم
  Future<void> markAsRead(String id) async {
    if (isClosed) return;
    final previousItems = state.items;
    final previousCount = state.unreadCount;

    final target = previousItems.where((n) => n.id == id);
    if (target.isEmpty || target.first.isRead) return;

    emit(
      state.copyWith(
        items: [
          for (final n in previousItems)
            n.id == id ? n.copyWith(isRead: true) : n,
        ],
        unreadCount: previousCount > 0 ? previousCount - 1 : 0,
      ),
    );

    try {
      await _repository.markAsRead(id);
      await loadUnreadCount();
    } catch (_) {
      if (isClosed) return;
      await load();
      await loadUnreadCount();
    }
  }

  /// تمييز الكل كمقروء
  Future<void> markAllAsRead() async {
    if (isClosed) return;
    if (state.unreadCount == 0) return;
    final previousItems = state.items;

    emit(
      state.copyWith(
        items: [for (final n in previousItems) n.copyWith(isRead: true)],
        unreadCount: 0,
      ),
    );

    try {
      await _repository.markAllAsRead();
      await loadUnreadCount();
    } catch (_) {
      if (isClosed) return;
      await load();
      await loadUnreadCount();
    }
  }
}
