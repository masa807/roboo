import 'dart:async';

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
    on<AuthSessionExpired>((event, emit) {
      _generation++;
      emit(const AuthState.unauthenticated('انتهت الجلسة، يرجى تسجيل الدخول.'));
    });
    _subscription = _repository.sessionExpired.listen((_) {
      if (!isClosed) add(const AuthSessionExpired());
    });
  }

  final AuthRepository _repository;
  int _generation = 0;
  late final StreamSubscription<void> _subscription;
  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    try {
      final user = await _repository.tryAutoLogin();
      if (generation != _generation || emit.isDone) return;
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (_) {
      if (generation != _generation || emit.isDone) return;
      // أي فشل بالتحقق (سيرفر مطفي، توكن تالف...) -> على اللوجين
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    emit(const AuthState.authenticating());
    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      if (generation != _generation || emit.isDone) return;
      emit(AuthState.authenticated(user));
    } on ApiException catch (e) {
      if (generation != _generation || emit.isDone) return;
      emit(AuthState.unauthenticated(e.message));
    } catch (_) {
      if (generation != _generation || emit.isDone) return;
      emit(const AuthState.unauthenticated('حدث خطأ غير متوقع'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final generation = ++_generation;
    try {
      await _repository.logout();
    } catch (_) {
      // حتى لو فشل مسح الجلسة من السيرفر، منطلّع المستخدم محلياً
    }
    if (generation == _generation && !emit.isDone) {
      emit(const AuthState.unauthenticated());
    }
  }
}
