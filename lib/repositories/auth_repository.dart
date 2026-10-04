import 'dart:async';

import '../core/network/api_client.dart';
import '../core/network/jwt_utils.dart';
import '../core/network/storage/token_storage.dart';
import '../core/network/notifications/notification_service.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenStorage) {
    _client.setTokenProvider(_validAccessToken);
    _client.refreshSession = (sent) async {
      final current = await _tokenStorage.getAccessToken();
      if (current != null && sent != 'Bearer $current') return current;
      await refreshToken();
      return _tokenStorage.getAccessToken();
    };
    _client.onSessionExpired = _expire;
  }
  final ApiClient _client;
  final TokenStorage _tokenStorage;
  final _expired = StreamController<void>.broadcast();
  Stream<void> get sessionExpired => _expired.stream;
  Future<AuthUser>? _refreshFlight;
  int _epoch = 0;

  Future<String?> _validAccessToken() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      if (JwtUtils.isExpired(token)) {
        await refreshToken();
        return await _tokenStorage.getAccessToken();
      }
      return token;
    } on FormatException {
      await _expire();
      return null;
    }
  }

  Future<void> _revoke(String? refreshToken, {String? deviceToken}) async {
    if (refreshToken == null || refreshToken.isEmpty) return;
    try {
      await _client.post(
        '/api/auth/logout',
        anonymous: true,
        data: {'refreshTokenValue': refreshToken, 'deviceToken': ?deviceToken},
      );
    } catch (_) {
      /* Local logout must work when the server is unavailable. */
    }
  }

  Future<void> _expire() async {
    await logout();
    _expired.add(null);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final version = ++_epoch;
    _client.sessionVersion++;
    _refreshFlight = null;
    await _tokenStorage.clear();
    final response = await _client.post(
      '/api/auth/login',
      anonymous: true,
      data: {'email': email.trim(), 'password': password},
    );
    return _accept(Map<String, dynamic>.from(response.data as Map), version);
  }

  Future<AuthUser> refreshToken() {
    final existing = _refreshFlight;
    if (existing != null) return existing;
    final flight = _refresh(_epoch);
    _refreshFlight = flight;
    return flight.whenComplete(() {
      if (identical(_refreshFlight, flight)) _refreshFlight = null;
    });
  }

  Future<AuthUser> _refresh(int version) async {
    final token = await _tokenStorage.getRefreshToken();
    if (version != _epoch) throw const ApiException('تم تغيير الجلسة.');
    if (token == null) {
      await _expire();
      throw const ApiException('انتهت الجلسة.', statusCode: 401);
    }
    try {
      final response = await _client.post(
        '/api/auth/refresh-token',
        anonymous: true,
        data: {'refreshTokenValue': token},
      );
      return await _accept(
        Map<String, dynamic>.from(response.data as Map),
        version,
      );
    } on ApiException catch (e) {
      if (version == _epoch && [400, 401, 403].contains(e.statusCode)) {
        await _expire();
      }
      rethrow;
    }
  }

  Future<AuthUser> _accept(Map<String, dynamic> json, int version) async {
    final pair = LoginResponse.fromJson(json);
    if (version != _epoch) {
      unawaited(_revoke(pair.refreshToken));
      throw const ApiException('تم إلغاء العملية.');
    }
    final user = AuthUser.fromAccessToken(
      pair.accessToken,
      fullNameFallback: pair.fullName,
    );
    if (!user.isTrainer || user.trainerId.isEmpty) {
      unawaited(_revoke(pair.refreshToken));
      throw const ApiException(
        'هذا التطبيق مخصص للمدربين. استخدم لوحة الإدارة لحساب الأدمن.',
        statusCode: 403,
      );
    }
    if (pair.refreshToken.isEmpty || pair.accessToken.isEmpty) {
      throw const ApiException('استجابة الجلسة غير مكتملة.');
    }
    await _tokenStorage.saveTokens(
      accessToken: pair.accessToken,
      refreshToken: pair.refreshToken,
    );
    if (version != _epoch) throw const ApiException('تم تغيير الجلسة.');
    NotificationService.instance.setSignedIn(true);
    return user;
  }

  Future<AuthUser?> tryAutoLogin() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      if (JwtUtils.isExpired(token)) return await refreshToken();
      final user = AuthUser.fromAccessToken(token);
      if (!user.isTrainer || user.trainerId.isEmpty) {
        await logout();
        return null;
      }
      NotificationService.instance.setSignedIn(true);
      return user;
    } on ApiException catch (e) {
      if ([400, 401, 403].contains(e.statusCode)) return null;
      rethrow;
    } on FormatException {
      await _expire();
      return null;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    await logout();
    _expired.add(null);
  }

  Future<void> logout() async {
    _epoch++;
    _client.sessionVersion++;
    NotificationService.instance.setSignedIn(false);
    final token = await _tokenStorage.getRefreshToken();
    await _tokenStorage.clear();
    String? deviceToken;
    try {
      deviceToken = await NotificationService.instance.getToken().timeout(
        const Duration(seconds: 2),
      );
    } catch (_) {}
    unawaited(_revoke(token, deviceToken: deviceToken));
    try {
      await NotificationService.instance.deleteToken().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {}
  }
}
