import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  /// GET /api/notifications?page=&pageSize=&unreadOnly=
  Future<NotificationsPage> getNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _api.get(
      '/api/notifications',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'unreadOnly': unreadOnly,
      },
    );
    return NotificationsPage.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    final response = await _api.get('/api/notifications/unread-count');
    final body = response.data;

    if (body is num) return body.toInt();
    if (body is Map) {
      for (final key in const ['count', 'unreadCount', 'value']) {
        final v = body[key];
        if (v is num) return v.toInt();
      }
      for (final v in body.values) {
        if (v is num) return v.toInt();
      }
    }
    return 0;
  }

  /// POST /api/notifications/{id}/read
  Future<void> markAsRead(String id) async {
    await _api.post('/api/notifications/$id/read');
  }

  /// POST /api/notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.post('/api/notifications/read-all');
  }
}
