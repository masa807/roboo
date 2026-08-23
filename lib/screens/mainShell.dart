import 'package:flutter/material.dart';
import '/theme/color.dart';
import '/utils/responsive.dart';
import '/widget/navbar_widget.dart';
import '/screens/home_screen.dart';
import '/screens/table_screen.dart';
import '/screens/request_screen.dart';
import '/screens/stats_screen.dart';

/// الشاشة الأم يلي بتحمل الأربع تابات، Scaffold وحيد بكل التطبيق
/// (AppBar متغير حسب التاب + BottomNav ثابت)
/// ما في ولا Navigator.push/pop للتبديل بين التابات -> فوري بدون أي رمش
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // محتوى كل تاب (بدون Scaffold/AppBar خاص فيه)
  final List<Widget> _tabs = const [
    HomeContent(),
    WeeklyScheduleContent(),
    AbsenceRequestContent(),
    StatsContent(),
  ];

  // عنوان الـ AppBar لكل تاب
  static const List<String> _titles = [
    ' الرئيسية',
    'برنامجي الأسبوعي',
    'الطلبات',
    'الاحصائيات',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary1,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: context.r(24)),
          onPressed: () {
            // فتح الدرج الجانبي لاحقاً
          },
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
                  onPressed: () {
                    // فتح شاشة الإشعارات لاحقاً
                  },
                ),
              ]
            : null,
      ),
      // كل تاب محافظ على حالته (scroll position, state) لأنه IndexedStack
      // ما بيعيد بناء الشاشات، بس بيخفي/يظهر
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          // تبديل فوري، بدون await ولا push
          setState(() => _currentIndex = i);
        },
      ),
    );
  }
}
