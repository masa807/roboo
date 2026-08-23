import 'package:flutter/material.dart';
import '../widget/app_background.dart';

/// محتوى تاب الاحصائيات - Placeholder لحد ما تجهزه
/// ملاحظة: ما في Scaffold ولا AppBar هون -> موجودين مرة وحدة بس بالـ MainShell
class StatsContent extends StatelessWidget {
  const StatsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBackground(
      child: SafeArea(child: Center(child: Text('قريباً'))),
    );
  }
}
