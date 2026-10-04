import '../core/network/jwt_utils.dart';

/// الرد الكامل من /api/auth/login أو /api/auth/refresh-token
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final String fullName;
  final List<String> roles;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.fullName,
    required this.roles,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      accessTokenExpiresAt: DateTime.parse(
        json['accessTokenExpiresAt'] as String,
      ),
      fullName: json['fullName'] as String? ?? '',
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );
  }
}

/// بيانات المستخدم المسجّل دخوله — مستخرجة من الـ JWT + رد اللوجن،
/// وهاي يلي رح تستعملها بكل التطبيق (مثلاً user.id كـ trainerId بالـ endpoints).
class AuthUser {
  final String id; // من claim "sub"
  final String trainerId;
  final String email;
  final String fullName;
  final List<String> roles;

  const AuthUser({
    required this.id,
    required this.trainerId,
    required this.email,
    required this.fullName,
    required this.roles,
  });

  bool get isAdmin => roles.contains('Admin');
  bool get isTrainer => roles.contains('Trainer');

  static const _roleClaim =
      'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

  factory AuthUser.fromAccessToken(
    String accessToken, {
    String? fullNameFallback,
  }) {
    final payload = JwtUtils.decodePayload(accessToken);
    final rawRole = payload[_roleClaim] ?? payload['role'];
    final roles = rawRole is List
        ? rawRole.map((e) => e.toString()).toList()
        : rawRole != null
        ? [rawRole.toString()]
        : <String>[];
    return AuthUser(
      id: payload['sub'] as String,
      trainerId: payload['trainerId'] as String? ?? '',
      email: payload['email'] as String? ?? '',
      fullName: payload['fullName'] as String? ?? fullNameFallback ?? '',
      roles: roles,
    );
  }
}
