import '../core/network/api_client.dart';

/// تسجيل وإلغاء تسجيل توكن الجهاز (FCM) عند السيرفر
class DeviceRepository {
  DeviceRepository(this._api);

  final ApiClient _api;

  /// قيم DevicePlatform بالباك إند: Android = 0, Ios = 1, Web = 2
  /// (iOS غير مفعّل حالياً، بس خليناه جاهز للمستقبل)
  static const Map<String, int> _platformValues = {
    'android': 0,
    'ios': 1,
    'web': 2,
  };

  /// POST /api/devices
  Future<void> registerToken(String token, String platform) async {
    final value = _platformValues[platform];
    if (value == null) {
      throw ArgumentError.value(platform, 'platform', 'منصة غير معروفة');
    }

    await _api.post('/api/devices', data: {'token': token, 'platform': value});
  }

  /// POST /api/devices/unregister
  Future<void> unregisterToken(String token) async {
    await _api.post('/api/devices/unregister', data: {'token': token});
  }
}
