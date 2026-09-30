import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState.unknown()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _repository;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await _repository.tryAutoLogin();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (_) {
      // أي فشل بالتحقق (سيرفر مطفي، توكن تالف...) -> على اللوجين
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.authenticating());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      emit(AuthState.unauthenticated(e.message));
    } catch (_) {
      emit(const AuthState.unauthenticated('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _repository.logout();
    } catch (_) {
      // حتى لو فشل مسح الجلسة من السيرفر، منطلّع المستخدم محلياً
    }
    emit(const AuthState.unauthenticated());
  }
}
