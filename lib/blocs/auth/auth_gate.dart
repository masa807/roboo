import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../theme/color.dart';
import '../../screens/login_screen.dart';
import '../../screens/mainShell.dart';

/// بتقرّر أول شاشة حسب حالة الـ AuthBloc:
/// - unknown: عم يتحقق من الجلسة المحفوظة -> splash
/// - authenticated: MainShell (الهوم)
/// - غير هيك (unauthenticated / authenticating): LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.unauthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      // authenticating و unauthenticated كلهم لوجين، فما منعيد بناء الشاشة
      // (عشان ما يضيع شي كاتبه المستخدم بالفورم)
      buildWhen: (prev, curr) =>
          _screenOf(prev) != _screenOf(curr) || prev.user?.id != curr.user?.id,
      builder: (context, state) {
        switch (_screenOf(state)) {
          case _Screen.splash:
            return const _SplashScreen();
          case _Screen.home:
            return MainShell(key: ValueKey(state.user?.id));
          case _Screen.login:
            return const LoginScreen();
        }
      },
    );
  }
}

enum _Screen { splash, home, login }

_Screen _screenOf(AuthState state) {
  switch (state.status) {
    case AuthStatus.unknown:
      return _Screen.splash;
    case AuthStatus.authenticated:
      return state.user?.isTrainer == true && state.user!.trainerId.isNotEmpty
          ? _Screen.home
          : _Screen.login;
    case AuthStatus.authenticating:
    case AuthStatus.unauthenticated:
      return _Screen.login;
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary1,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
