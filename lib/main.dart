import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/network/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme/theme.dart';
import 'screens/login_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';

void main() {
  final tokenStorage = TokenStorage.instance;
  final apiClient = ApiClient(
    baseUrl: 'http://191.218.163.66:8180',
    tokenProvider: tokenStorage.getAccessToken,
  );
  final authRepository = AuthRepository(apiClient, tokenStorage);

  runApp(
    BlocProvider(
      create: (_) => AuthBloc(authRepository)..add(const AuthCheckRequested()),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام إدارة الدوام',
      debugShowCheckedModeBanner: false,

      // تفعيل الاتجاه من اليمين لليسار (ضروري للعربي)
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // الثيم الموحّد يلي عملناه
      theme: AppTheme.lightTheme,

      // أول شاشة تفتح
      home: const LoginScreen(),
    );
  }
}
