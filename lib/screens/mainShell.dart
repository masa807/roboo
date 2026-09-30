import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import '../repositories/leave_request_repository.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/stats_repository.dart';
import '../blocs/auth/auth_event.dart';

/// الشاشة الأم يلي بتحمل الأربع تابات، Scaffold وحيد بكل التطبيق
/// (AppBar متغير حسب التاب + BottomNav ثابت + Drawer جانبي)
/// ما في ولا Navigator.push/pop للتبديل بين التابات -> فوري بدون أي رمش
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _statsTabIndex = 3;

  int _currentIndex = 0;
  List<Widget>? _tabs;

  StatsCubit? _statsCubit;
  bool _statsLoaded = false;

  String _requireTrainerId(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    final trainerId = user?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      throw StateError('MainShell built without an authenticated trainer');
    }
    return trainerId;
  }

  void _logout() {
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

    return Scaffold(
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
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: context.r(24),
                  ),
                  onPressed: () {},
                ),
              ]
            : null,
      ),
      body: IndexedStack(index: _currentIndex, children: _tabs!),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _currentIndex,
        onTap: _selectTab,
      ),
    );
  }
}
