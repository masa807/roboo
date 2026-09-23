abstract class AuthEvent {
  const AuthEvent();
}

/// يُطلق مرة عند فتح التطبيق للتحقق من وجود جلسة محفوظة
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
