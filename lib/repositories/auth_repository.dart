import '../core/network/api_client.dart';
import '../core/network/jwt_utils.dart';
import '../core/network/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokenStorage);

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  /// POST /api/auth/login
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return _handleLoginResponse(response.data as Map<String, dynamic>);
  }

  /// POST /api/auth/refresh-token
  Future<AuthUser> refreshToken() async {
    final refreshTokenValue = await _tokenStorage.getRefreshToken();
    if (refreshTokenValue == null) {
      throw const ApiException('لا يوجد جلسة سابقة لتجديدها');
    }
    final response = await _client.post(
      '/api/auth/refresh-token',
      data: {'refreshTokenValue': refreshTokenValue},
    );
    return _handleLoginResponse(response.data as Map<String, dynamic>);
  }

  /// بيتفحص إذا في جلسة محفوظة صالحة لتسجيل دخول تلقائي عند فتح التطبيق.
  /// - بيرجع المستخدم إذا التوكن صالح أو نجح تجديده.
  /// - بيرجع null (وبيمسح الجلسة) إذا ما في جلسة أو السيرفر رفض التجديد.
  /// - بيرمي ApiException بدون statusCode إذا الفشل بسبب الاتصال، والجلسة
  ///   بتضل محفوظة عشان تنجرّب من جديد بالفتحة الجاية.
  Future<AuthUser?> tryAutoLogin() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return null;

    try {
      if (!JwtUtils.isExpired(accessToken)) {
        return AuthUser.fromAccessToken(accessToken);
      }

      // التوكن منتهي — جرب تجديده بالـ refresh token
      final refresh = await _tokenStorage.getRefreshToken();
      if (refresh == null) {
        await _tokenStorage.clear();
        return null;
      }
      return await refreshToken();
    } on ApiException catch (e) {
      if (e.statusCode == null) rethrow; // مشكلة اتصال: منحتفظ بالجلسة
      await _tokenStorage.clear(); // السيرفر رفض التجديد: الجلسة منتهية
      return null;
    } catch (_) {
      // توكن تالف أو غير قابل للقراءة
      await _tokenStorage.clear();
      return null;
    }
  }

  /// POST /api/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<AuthUser> _handleLoginResponse(Map<String, dynamic> json) async {
    final loginResponse = LoginResponse.fromJson(json);
    await _tokenStorage.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );
    return AuthUser.fromAccessToken(
      loginResponse.accessToken,
      fullNameFallback: loginResponse.fullName,
    );
  }
}
