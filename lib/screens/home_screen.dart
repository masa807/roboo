import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../models/home_model.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';
import 'calendar_screen.dart';

/// محتوى تاب الرئيسية فقط - بدون Scaffold/BottomNav خاص فيه
/// هاد الويدجت رح ينحط جوا IndexedStack بالـ MainShell
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _openDayKey;

  // بيانات تجريبية - استبدلها لاحقاً بالـ Provider / API
  final List<DayModel> _days = [
    DayModel(
      key: 'sat',
      name: 'السبت',
      date: '16 أغسطس',
      sessions: [
        SessionModel(
          subject: 'تدريب كرة قدم',
          school: 'مدرسة الأمل',
          time: '09:00 ص',
          status: SessionStatus.active,
        ),
        SessionModel(
          subject: 'تدريب سباحة',
          school: 'مدرسة النور',
          time: '01:00 م',
          status: SessionStatus.upcoming,
        ),
      ],
    ),
    DayModel(
      key: 'sun',
      name: 'الأحد',
      date: '17 أغسطس',
      sessions: [
        SessionModel(
          subject: 'تدريب كرة سلة',
          school: 'مدرسة الفجر',
          time: '10:00 ص',
          status: SessionStatus.done,
        ),
      ],
    ),
    DayModel(key: 'mon', name: 'الاثنين', date: '18 أغسطس', sessions: []),
  ];

  Map<String, DayModel> get _daysMap {
    final Map<String, DayModel> map = {};
    final now = DateTime.now();
    for (int i = 0; i < _days.length; i++) {
      final date = now.add(Duration(days: i));
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      map[key] = _days[i];
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    _openDayKey = _days.isNotEmpty ? _days.first.key : null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ملاحظة: ما في Scaffold ولا AppBar هون نهائياً
    // الـ AppBar والـ Scaffold والـ BottomNav كلهم موجودين مرة وحدة بس بالـ MainShell
    return AppBackground(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(16),
            context.w(16),
            context.h(24),
          ),
          children: [
            // ===== هيدر: عنوان الأسبوع + زر الكالندر =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الأسبوع الحالي ',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: context.sp(16),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    // فتح الكالندر تبقى Navigator.push عادية لأنها مش تاب أساسي
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CalendarScreen(daysData: _daysMap),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.w(14),
                      vertical: context.h(8),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary4,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: context.r(14),
                          color: AppColors.primary1,
                        ),
                        SizedBox(width: context.w(5)),
                        Text(
                          'التقويم',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.primary1,
                            fontWeight: FontWeight.bold,
                            fontSize: context.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(14)),

            // ===== كروت الأيام =====
            ..._days.map(
              (day) => _DayCard(
                key: ValueKey(day.key),
                day: day,
                isOpen: _openDayKey == day.key,
                onToggle: () {
                  setState(() {
                    _openDayKey = _openDayKey == day.key ? null : day.key;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== كارد اليوم الواحد ====
class _DayCard extends StatelessWidget {
  final DayModel day;
  final bool isOpen;
  final VoidCallback onToggle;

  const _DayCard({
    super.key,
    required this.day,
    required this.isOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: context.r(12),
            offset: Offset(0, context.h(3)),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(context.r(14)),
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontSize: context.sp(14),
                          ),
                        ),
                        SizedBox(height: context.h(2)),
                        Text(
                          day.date,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: context.sp(11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildBadge(context),
                  SizedBox(width: context.w(8)),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.secondary3,
                      size: context.r(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(
                context.w(14),
                0,
                context.w(14),
                context.h(14),
              ),
              child: day.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.h(12)),
                        child: Text(
                          'ما في حصص هالنهار',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: context.sp(12),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: day.sessions
                          .map((s) => _SessionRow(session: s))
                          .toList(),
                    ),
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (day.isEmpty) {
      return _badge(
        context,
        'لا يوجد',
        AppColors.secondary4,
        AppColors.secondary3,
        textTheme,
      );
    }
    if (day.isComplete) {
      return _badge(
        context,
        'مكتمل',
        AppColors.secondary1,
        AppColors.primary1,
        textTheme,
      );
    }
    return _badge(
      context,
      '${day.sessions.length} حصص',
      AppColors.primary4,
      AppColors.primary1,
      textTheme,
    );
  }

  Widget _badge(
    BuildContext context,
    String text,
    Color bg,
    Color fg,
    TextTheme textTheme,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(11),
        ),
      ),
    );
  }
}

// ==== صف الحصة الواحدة جوا الكارد ====
class _SessionRow extends StatelessWidget {
  final SessionModel session;

  const _SessionRow({required this.session});

  Color get _stripColor {
    switch (session.status) {
      case SessionStatus.done:
        return AppColors.secondary1;
      case SessionStatus.missed:
        return AppColors.errorColor;
      case SessionStatus.active:
        return AppColors.primary3;
      case SessionStatus.upcoming:
        return AppColors.primary2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(top: context.h(10)),
      padding: EdgeInsets.all(context.w(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFEFE),
        borderRadius: BorderRadius.circular(context.r(10)),
        border: Border(
          top: const BorderSide(color: Color(0xFFE1EEF0)),
          bottom: const BorderSide(color: Color(0xFFE1EEF0)),
          left: const BorderSide(color: Color(0xFFE1EEF0)),
          right: BorderSide(color: _stripColor, width: context.w(4)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: context.sp(13.5),
                  ),
                ),
                SizedBox(height: context.h(3)),
                Row(
                  children: [
                    Text(
                      session.school,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: context.sp(11),
                      ),
                    ),
                    SizedBox(width: context.w(8)),
                    Text(
                      session.time,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: context.sp(11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: context.w(8)),
          _buildTrailing(context),
        ],
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    switch (session.status) {
      case SessionStatus.done:
        return CircleAvatar(
          radius: context.r(17),
          backgroundColor: AppColors.secondary1,
          child: Icon(Icons.check, color: Colors.white, size: context.r(16)),
        );
      case SessionStatus.missed:
        return CircleAvatar(
          radius: context.r(17),
          backgroundColor: AppColors.errorColor,
          child: Icon(Icons.close, color: Colors.white, size: context.r(16)),
        );
      case SessionStatus.active:
        return ElevatedButton(
          onPressed: () {
            // فتح شاشة تسجيل الحضور (GPS)
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary3,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: context.w(12),
              vertical: context.h(8),
            ),
            minimumSize: Size.zero,
          ),
          child: Text('تسجيل', style: TextStyle(fontSize: context.sp(11))),
        );
      case SessionStatus.upcoming:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.w(10),
            vertical: context.h(6),
          ),
          decoration: BoxDecoration(
            color: AppColors.primary4,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'قادمة',
            style: TextStyle(
              fontSize: context.sp(10.5),
              color: AppColors.primary1,
            ),
          ),
        );
    }
  }
}
