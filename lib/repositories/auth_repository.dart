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
      throw const ApiException('ما في جلسة سابقة لتجديدها');
    }
    final response = await _client.post(
      '/api/auth/refresh-token',
      data: {'refreshTokenValue': refreshTokenValue},
    );
    return _handleLoginResponse(response.data as Map<String, dynamic>);
  }

  /// بيتفحص إذا في جلسة محفوظة صالحة لتسجيل دخول تلقائي عند فتح التطبيق.
  /// بيرجع null إذا ما في جلسة (لازم يروح المستخدم لشاشة اللوجن).
  Future<AuthUser?> tryAutoLogin() async {
    final accessToken = await _tokenStorage.getAccessToken();
    if (accessToken == null) return null;

    try {
      if (!JwtUtils.isExpired(accessToken)) {
        return AuthUser.fromAccessToken(accessToken);
      }
      // التوكن منتهي — جرب تجديده تلقائياً بالـ refresh token
      return await refreshToken();
    } catch (_) {
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
