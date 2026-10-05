import 'package:flutter/foundation.dart';

import 'core/school_time.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'repositories/notification_repository.dart';
import 'core/network/api_client.dart';
import 'core/network/storage/token_storage.dart';
import 'core/network/notifications/notification_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/device_repository.dart';
import 'repositories/leave_request_repository.dart';
import 'repositories/schedule_repository.dart';
import 'theme/theme.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SchoolTime.initialize();
  if (const bool.fromEnvironment('ENABLE_PUSH', defaultValue: true)) {
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
      await NotificationService.instance.init().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      /* Push is optional; the inbox and attendance remain available. */
    }
  }
  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://191.218.163.66:8180/swagger',
  );
  final uri = Uri.tryParse(baseUrl);
  if (uri == null ||
      !uri.hasAuthority ||
      !['http', 'https'].contains(uri.scheme) ||
      (kReleaseMode && uri.scheme != 'https')) {
    throw StateError('Set API_BASE_URL to the HTTPS backend URL for release.');
  }

  final tokenStorage = TokenStorage.instance;
  tokenStorage.configureServer(baseUrl);
  final apiClient = ApiClient(
    baseUrl: baseUrl,
    tokenProvider: () => tokenStorage.getAccessToken(),
  );

  final authRepository = AuthRepository(apiClient, tokenStorage);
  final leaveRequestRepository = LeaveRequestRepository(apiClient);
  final attendanceRepository = AttendanceRepository(apiClient);
  final scheduleRepository = ScheduleRepository(apiClient);
  final deviceRepository = DeviceRepository(apiClient);
  final notificationRepository = NotificationRepository(apiClient);

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
        RepositoryProvider<DeviceRepository>.value(value: deviceRepository),
        RepositoryProvider<NotificationRepository>.value(
          value: notificationRepository,
        ),
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
