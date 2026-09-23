import '../../models/auth_models.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.authenticating() : this(status: AuthStatus.authenticating);

  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated([String? message])
    : this(status: AuthStatus.unauthenticated, errorMessage: message);
}
