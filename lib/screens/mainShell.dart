import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/notifications/notification_service.dart';
import '../theme/color.dart';
import '../utils/responsive.dart';
import '../widget/navbar_widget.dart';
import '../widget/drawer.dart';
import '../screens/home_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/request_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/login_screen.dart';
import '../blocs/absence/absence_cubit.dart';
import '../blocs/attendance/attendance_cubit.dart';
import '../blocs/schedule/schedule_cubit.dart';
import '../blocs/stats/stats_cubit.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../repositories/device_repository.dart';
import '../repositories/leave_request_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/stats_repository.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/notifications/notifications_cubit.dart';
import '../repositories/notification_repository.dart';
import '../screens/notifications_screen.dart';

/// الشاشة الأم يلي بتحمل الأربع تابات، Scaffold وحيد بكل التطبيق
/// (AppBar متغير حسب التاب + BottomNav ثابت + Drawer جانبي)
/// ما في ولا Navigator.push/pop للتبديل بين التابات -> فوري بدون أي رمش
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const int _requestsTabIndex = 2;
  static const int _statsTabIndex = 3;

  int _currentIndex = 0;
  List<Widget>? _tabs;

  StatsCubit? _statsCubit;
  bool _statsLoaded = false;

  late final NotificationsCubit _notificationsCubit;

  StreamSubscription<Map<String, dynamic>>? _tapSub;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  String get _platform => Platform.isIOS ? 'ios' : 'android';

  String _requireTrainerId(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final trainerId = user?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      throw StateError('MainShell built without an authenticated trainer');
    }
    return trainerId;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // كيوبت الإشعارات مشترك بين الشارة وشاشة القائمة
    _notificationsCubit = NotificationsCubit(
      context.read<NotificationRepository>(),
    )..loadUnreadCount();

    // وصل إشعار والتطبيق مفتوح -> بنحدّث الشارة
    _foregroundSub = FirebaseMessaging.onMessage.listen((_) {
      _notificationsCubit.loadUnreadCount();
    });

    // ضغط على إشعار والتطبيق شغّال (foreground أو background)
    _tapSub = NotificationService.instance.onNotificationTap.listen(
      _handleNotificationTap,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // التطبيق كان مسكّر تماماً وانفتح من إشعار
      final initial = await NotificationService.instance
          .getInitialMessageData();
      if (initial != null && mounted) _handleNotificationTap(initial);

      await _registerDevice();
    });
  }

  /// رجوع التطبيق من الخلفية -> تحديث الشارة
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notificationsCubit.loadUnreadCount();
    }
  }

  /// طلب الإذن + جلب التوكن + تسجيله عند السيرفر
  Future<void> _registerDevice() async {
    try {
      final ns = NotificationService.instance;
      if (!await ns.requestPermission()) return;

      final token = await ns.getToken();
      if (token == null || !mounted) return;

      final repo = context.read<DeviceRepository>();
      await repo.registerToken(token, _platform);

      // لو التوكن تجدد، بنسجله من جديد
      _tokenSub = ns.onTokenRefresh.listen((t) {
        repo.registerToken(t, _platform).catchError((_) {});
      });
    } catch (e) {
      // فشل تسجيل الإشعارات ما لازم يعطل التطبيق
      debugPrint('Notification registration failed: $e');
    }
  }

  /// لازم يتنفذ قبل AuthLogoutRequested لأن التوكن بينمسح بعد الخروج
  Future<void> _unregisterDevice() async {
    try {
      final ns = NotificationService.instance;
      final token = await ns.getToken();
      if (token != null && mounted) {
        await context
            .read<DeviceRepository>()
            .unregisterToken(token)
            .timeout(const Duration(seconds: 3));
      }
      await ns.deleteToken();
    } catch (e) {
      debugPrint('Notification unregister failed: $e');
    }
  }

  /// حسب نوع الإشعار بنفتح التاب المناسب
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (!mounted) return;
    switch (data['type']) {
      case 'leave_request':
        _selectTab(_requestsTabIndex);
        break;
      default:
        break;
    }
  }

  /// فتح شاشة قائمة الإشعارات من أيقونة الجرس
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _notificationsCubit,
          child: NotificationsScreen(
            onOpen: (n) => _handleNotificationTap({'type': n.type, ...?n.data}),
          ),
        ),
      ),
    );
  }

  /// بيتنفذ بعد ما المستخدم يأكد من حوار تسجيل الخروج (الحوار جوّا الـ Drawer)
  Future<void> _logout() async {
    await _unregisterDevice();
    if (!mounted) return;
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  /// تبديل التاب. الإحصائيات بتتحمّل أول مرة بتنفتح فيها بس
  void _selectTab(int i) {
    setState(() => _currentIndex = i);
    if (i == _statsTabIndex && !_statsLoaded) {
      _statsLoaded = true;
      _statsCubit?.load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapSub?.cancel();
    _tokenSub?.cancel();
    _foregroundSub?.cancel();
    _notificationsCubit.close();
    _statsCubit?.close();
    super.dispose();
  }

  static const List<String> _titles = [
    ' الرئيسية',
    'برنامجي الأسبوعي',
    'الطلبات',
    'الاحصائيات',
  ];

  @override
  Widget build(BuildContext context) {
    if (_tabs == null) {
      _statsCubit = StatsCubit(
        StatsRepository(context.read<AttendanceRepository>()),
        trainerId: _requireTrainerId(context),
      );

      _tabs = [
        // 0 - الرئيسية
        BlocProvider(
          create: (_) => AttendanceCubit(
            context.read<AttendanceRepository>(),
            trainerId: _requireTrainerId(context),
          ),
          child: const HomeContent(),
        ),
        // 1 - الجدول
        BlocProvider(
          create: (_) => ScheduleCubit(
            context.read<ScheduleRepository>(),
            trainerId: _requireTrainerId(context),
          ),
          child: const WeeklyScheduleContent(),
        ),
        // 2 - الطلبات
        BlocProvider(
          create: (_) {
            final trainerId = _requireTrainerId(context);
            final attendanceRepo = context.read<AttendanceRepository>();
            return AbsenceCubit(
              context.read<LeaveRequestRepository>(),
              trainerId: trainerId,
              sessionsFetcher: (date) => attendanceRepo.getDailyChecklist(
                trainerId: trainerId,
                date: date,
              ),
            );
          },
          child: const AbsenceRequestContent(),
        ),
        // 3 - الاحصائيات (التحميل أول ما تنفتح، شوف _selectTab)
        BlocProvider.value(value: _statsCubit!, child: const StatsContent()),
      ];
    }

    // لما تسجيل الخروج يخلص (unauthenticated) بنرجع لشاشة الدخول ونمسح الـ stack
    // ملاحظة: إذا عندك هالانتقال معمول بمكان تاني (مثلاً main.dart) شيل هالـ listener
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status &&
          curr.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: AppDrawer(
          currentIndex: _currentIndex,
          onSelect: _selectTab,
          onLogout: _logout,
          onProfile: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
        ),
        appBar: AppBar(
          backgroundColor: AppColors.primary1,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white, size: context.r(24)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Text(
            _titles[_currentIndex],
            style: TextStyle(color: Colors.white, fontSize: context.sp(18)),
          ),
          actions: _currentIndex == 0
              ? [
                  BlocBuilder<NotificationsCubit, NotificationsState>(
                    bloc: _notificationsCubit,
                    buildWhen: (prev, curr) =>
                        prev.unreadCount != curr.unreadCount,
                    builder: (context, state) {
                      return IconButton(
                        icon: Badge(
                          isLabelVisible: state.unreadCount > 0,
                          label: Text(
                            state.unreadCount > 99
                                ? '99+'
                                : '${state.unreadCount}',
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: context.r(24),
                          ),
                        ),
                        onPressed: _openNotifications,
                      );
                    },
                  ),
                ]
              : null,
        ),
        body: IndexedStack(index: _currentIndex, children: _tabs!),
        bottomNavigationBar: AnimatedBottomNav(
          currentIndex: _currentIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
