import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/notifications/notifications_cubit.dart';
import '../models/notification_model.dart';
import '../theme/color.dart';
import '../utils/responsive.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onOpen});

  /// بيتنفذ لما المدرب يضغط على إشعار (مثلاً لفتح تاب الطلبات)
  final void Function(AppNotification notification)? onOpen;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().load();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary1,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'الإشعارات',
          style: TextStyle(color: Colors.white, fontSize: context.sp(18)),
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'تحديد الكل كمقروء',
                icon: Icon(
                  Icons.done_all,
                  color: Colors.white,
                  size: context.r(24),
                ),
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          switch (state.status) {
            case NotificationsStatus.initial:
            case NotificationsStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case NotificationsStatus.failure:
              return _ErrorView(
                message: state.errorMessage ?? 'حدث خطأ',
                onRetry: () => context.read<NotificationsCubit>().load(),
              );

            case NotificationsStatus.success:
              if (state.items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: context.read<NotificationsCubit>().refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: context.h(160)),
                      const _EmptyView(),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: context.read<NotificationsCubit>().refresh,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: context.h(8)),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return Padding(
                        padding: EdgeInsets.all(context.r(16)),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final item = state.items[index];
                    return _NotificationTile(
                      notification: item,
                      onTap: () {
                        if (!item.isRead) {
                          context.read<NotificationsCubit>().markAsRead(
                            item.id,
                          );
                        }
                        Navigator.of(context).pop();
                        widget.onOpen?.call(item);
                      },
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  IconData get _icon {
    switch (notification.type) {
      case 'leave_request':
        return Icons.event_busy_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread ? AppColors.primary1.withOpacity(0.06) : null,
        padding: EdgeInsets.symmetric(
          horizontal: context.w(16),
          vertical: context.h(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.r(40),
              height: context.r(40),
              decoration: BoxDecoration(
                color: AppColors.primary1.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon,
                color: AppColors.primary1,
                size: context.r(22),
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: context.sp(15),
                      fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: context.sp(13),
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: context.h(6)),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: context.sp(11),
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: EdgeInsets.only(top: context.h(6)),
                width: context.r(8),
                height: context.r(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary1,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          size: context.r(64),
          color: Colors.black26,
        ),
        SizedBox(height: context.h(12)),
        Text(
          'لا يوجد إشعارات',
          style: TextStyle(fontSize: context.sp(16), color: Colors.black45),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: context.r(56), color: Colors.black26),
          SizedBox(height: context.h(12)),
          Text(
            message,
            style: TextStyle(fontSize: context.sp(15), color: Colors.black54),
          ),
          SizedBox(height: context.h(12)),
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
