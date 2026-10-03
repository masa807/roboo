/// عنصر إشعار واحد كما بيرجع من السيرفر
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, String>? data;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      data: rawData is Map
          ? rawData.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'data': data,
    'isRead': isRead,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

/// صفحة من الإشعارات (نفس شكل Response بالباك إند)
class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  final List<AppNotification> items;
  final int totalCount;
  final int page;
  final int pageSize;

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPage(
      items: list,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? list.length,
    );
  }
}
