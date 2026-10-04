import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();
  final _storage = const FlutterSecureStorage();
  Future<void> _queue = Future.value();
  String _key = 'roboo_session_v2';
  void configureServer(String baseUrl) {
    _key = 'roboo_session_v2:${Uri.encodeComponent(baseUrl)}';
  }

  Future<void> _serialize(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<Map<String, dynamic>> _read() async {
    await _queue;
    final value = await _storage.read(key: _key);
    if (value == null) return {};
    try {
      final data = jsonDecode(value);
      if (data is! Map ||
          data['accessToken'] is! String ||
          data['refreshToken'] is! String) {
        return {};
      }
      return Map<String, dynamic>.from(data);
    } on FormatException {
      return {};
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) => _serialize(
    () => _storage.write(
      key: _key,
      value: jsonEncode({
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      }),
    ),
  );
  Future<String?> getAccessToken() async =>
      (await _read())['accessToken'] as String?;
  Future<String?> getRefreshToken() async =>
      (await _read())['refreshToken'] as String?;
  Future<bool> hasToken() async => (await getAccessToken())?.isNotEmpty == true;
  Future<void> clear() => _serialize(() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  });
}
