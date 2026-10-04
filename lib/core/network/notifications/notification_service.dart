import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// لازم تكون top-level عشان تشتغل والتطبيق مسكّر.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // إشعارات النوع notification بيعرضها النظام تلقائياً، ما في شي لازم نعمله هون.
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool get isAvailable => _initialized;
  bool _signedIn = false;
  void setSignedIn(bool value) {
    _signedIn = value;
  }

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'attendease_default',
    'AttendEase',
    description: 'إشعارات التطبيق',
    importance: Importance.high,
  );

  final StreamController<Map<String, dynamic>> _tapController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// بيطلع لما المدرب يضغط على إشعار (data الخاصة بالإشعار).
  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;

  /// بيطلع لما الـ token يتجدد، سجّله من جديد عالسيرفر.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _tapController.add(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (_) {}
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _initialized = true;

    // التطبيق مفتوح: FCM ما بيعرض شي لحاله، فنعرضه نحن.
    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForeground(message).catchError((Object _) {}));
    });

    // التطبيق بالخلفية والمدرب ضغط عالإشعار.
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _tapController.add(Map<String, dynamic>.from(m.data));
    });
  }

  /// استدعيها بعد ما التطبيق يبني أول frame لو بدك تعالج الإشعار
  /// اللي فتح التطبيق وهو مسكّر تماماً.
  Future<Map<String, dynamic>?> getInitialMessageData() async {
    if (!_initialized) return null;
    try {
      final message = await _messaging.getInitialMessage();
      if (message != null) return Map<String, dynamic>.from(message.data);
      final launch = await _local.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      return launch?.didNotificationLaunchApp == true && payload != null
          ? Map<String, dynamic>.from(jsonDecode(payload) as Map)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestPermission() async {
    if (!_initialized) return false;
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  Future<String?> getToken() async =>
      _initialized ? await _messaging.getToken() : null;

  /// استدعيها عند تسجيل الخروج.
  Future<void> deleteToken() async {
    if (_initialized) {
      try {
        await _messaging.deleteToken();
      } finally {
        await _local.cancelAll();
      }
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    if (!_signedIn) return;
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      id:
          (message.data['notificationId'] ??
                  message.messageId ??
                  notification.title ??
                  '')
              .hashCode &
          0x7fffffff,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
