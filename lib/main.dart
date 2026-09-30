import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/network/api_client.dart';
import 'core/network/storage/token_storage.dart';
import 'repositories/auth_repository.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/leave_request_repository.dart';
import 'repositories/schedule_repository.dart';
import 'theme/theme.dart';
import 'screens/login_screen.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_gate.dart';

void main() {
  final tokenStorage = TokenStorage.instance;
  final apiClient = ApiClient(
    baseUrl: 'http://191.218.163.66:8180',
    tokenProvider: () => tokenStorage.getAccessToken(),
  );

  final authRepository = AuthRepository(apiClient, tokenStorage);
  final leaveRequestRepository = LeaveRequestRepository(apiClient);
  final attendanceRepository = AttendanceRepository(apiClient);
  final scheduleRepository = ScheduleRepository(apiClient);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LeaveRequestRepository>.value(
          value: leaveRequestRepository,
        ),
        RepositoryProvider<AttendanceRepository>.value(
          value: attendanceRepository,
        ),
        RepositoryProvider<ScheduleRepository>.value(value: scheduleRepository),
      ],
      child: BlocProvider(
        create: (_) =>
            AuthBloc(authRepository)..add(const AuthCheckRequested()),
        child: const MyApp(),
      ),
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

      // الثيم الموحّد
      theme: AppTheme.lightTheme,

      // أول شاشة تفتح
      home: const AuthGate(),
    );
  }
}
