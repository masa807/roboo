import 'dart:convert';

/// فك تشفير الـ payload تبع JWT (بدون تحقق من التوقيع — هاد شغل السيرفر،
/// إحنا بس عم نقرا البيانات لعرضها بالتطبيق).
class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic> decodePayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw const FormatException('توكن غير صالح');
    }
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  static bool isExpired(String token) {
    final payload = decodePayload(token);
    final exp = payload['exp'] as int?;
    if (exp == null) return true;
    final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().add(const Duration(seconds: 60)).isAfter(expiry);
  }
}
