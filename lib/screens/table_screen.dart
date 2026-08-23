import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../models/home_model.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';

/// محتوى تاب الجدول الأسبوعي فقط - بدون Scaffold/BottomNav خاص فيه
class WeeklyScheduleContent extends StatefulWidget {
  const WeeklyScheduleContent({super.key});

  @override
  State<WeeklyScheduleContent> createState() => _WeeklyScheduleContentState();
}

class _WeeklyScheduleContentState extends State<WeeklyScheduleContent> {
  String? _openDayKey;
  final List<DayModel> _days = [
    DayModel(key: 'sun', name: 'الأحد', date: '', sessions: []),
    DayModel(key: 'mon', name: 'الاثنين', date: '', sessions: []),
    DayModel(
      key: 'tue',
      name: 'الثلاثاء',
      date: '',
      sessions: [
        SessionModel(
          subject: 'الرياضيات',
          school: 'مدرسة النور الدولية',
          time: '09:00 - 08:00',
          status: SessionStatus.upcoming,
        ),
        SessionModel(
          subject: 'اللغة الإنجليزية',
          school: 'مدرسة النور الدولية',
          time: '10:15 - 09:15',
          status: SessionStatus.upcoming,
        ),
        SessionModel(
          subject: 'الكيمياء',
          school: 'مدرسة النور الدولية',
          time: '11:30 - 10:30',
          status: SessionStatus.upcoming,
        ),
      ],
    ),
    DayModel(key: 'wed', name: 'الأربعاء', date: '', sessions: []),
    DayModel(key: 'thu', name: 'الخميس', date: '', sessions: []),
    DayModel(key: 'fri', name: 'الجمعة', date: '', sessions: []),
    DayModel(key: 'sat', name: 'السبت', date: '', sessions: []),
  ];

  @override
  void initState() {
    super.initState();
    _openDayKey = _days.isNotEmpty ? _days.first.key : null;
  }

  @override
  Widget build(BuildContext context) {
    // ملاحظة: ما في Scaffold ولا AppBar هون نهائياً
    // الـ AppBar والـ Scaffold والـ BottomNav كلهم موجودين مرة وحدة بس بالـ MainShell
    return AppBackground(
      child: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(16),
            context.w(16),
            context.h(24),
          ),
          itemCount: _days.length,
          itemBuilder: (context, index) {
            final day = _days[index];
            return _WeekDayCard(
              key: ValueKey(day.key),
              day: day,
              isOpen: _openDayKey == day.key,
              onToggle: () {
                setState(() {
                  _openDayKey = _openDayKey == day.key ? null : day.key;
                });
              },
            );
          },
        ),
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final DayModel day;
  final bool isOpen;
  final VoidCallback onToggle;

  const _WeekDayCard({
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
                  Text(
                    day.name,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: context.sp(14),
                    ),
                  ),
                  const Spacer(),
                  _buildCountBadge(context),
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
                          'لا يوجد حصص',
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: context.sp(12),
                            color: AppColors.secondary3.withOpacity(0.6),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: day.sessions
                          .map((s) => _SessionLine(session: s))
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

  Widget _buildCountBadge(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(5),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary4,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${day.sessions.length} حصة',
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.primary1,
          fontWeight: FontWeight.bold,
          fontSize: context.sp(11),
        ),
      ),
    );
  }
}

// ==== سطر الحصة الواحدة جوا الكارد ====
class _SessionLine extends StatelessWidget {
  final SessionModel session;
  const _SessionLine({required this.session});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: EdgeInsets.only(top: context.h(12)),
        padding: EdgeInsets.only(bottom: context.h(10)),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE1EEF0))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.subject,
                    textAlign: TextAlign.right,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: context.sp(13.5),
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    session.school,
                    textAlign: TextAlign.right,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: context.sp(11),
                      color: AppColors.secondary3.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(8)),
            Text(
              session.time,
              style: textTheme.bodySmall?.copyWith(
                fontSize: context.sp(11.5),
                color: AppColors.secondary3.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
