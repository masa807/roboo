import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/color.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';
import '../blocs/schedule/schedule_cubit.dart';
import '../blocs/schedule/schedule_state.dart';
import '../models/weekly_schedule_model.dart';

/// محتوى تاب الجدول الأسبوعي فقط - بدون Scaffold/BottomNav خاص فيه
class WeeklyScheduleContent extends StatefulWidget {
  const WeeklyScheduleContent({super.key});

  @override
  State<WeeklyScheduleContent> createState() => _WeeklyScheduleContentState();
}

class _WeeklyScheduleContentState extends State<WeeklyScheduleContent> {
  String? _openDayKey;

  static const List<String> _dayKeys = [
    'sun',
    'mon',
    'tue',
    'wed',
    'thu',
    'fri',
    'sat',
  ];
  static const List<String> _dayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  @override
  void initState() {
    super.initState();
    _openDayKey = _dayKeys.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleCubit>().loadWeek();
    });
  }

  /// بيجمّع حصص الأسبوع بحسب اليوم (0..6 يقابل _dayKeys)
  Map<int, List<WeeklyScheduleItem>> _groupByDay(
    List<WeeklyScheduleItem> sessions,
  ) {
    final Map<int, List<WeeklyScheduleItem>> map = {
      for (int i = 0; i < 7; i++) i: [],
    };
    for (final s in sessions) {
      // weekday: الاثنين=1 ... الأحد=7 -> نحولها لفهرس 0=الأحد..6=السبت
      final index = s.date.weekday % 7;
      map[index]!.add(s);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  String _formatWeekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    String fmt(DateTime d) => '${d.day}/${d.month}';
    return '${fmt(weekStart)} - ${fmt(weekEnd)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, state) {
            if (state.status == ScheduleStatus.loading ||
                state.status == ScheduleStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ScheduleStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ?? 'حدث خطأ أثناء تحميل الجدول',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            context.read<ScheduleCubit>().loadWeek(),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final grouped = _groupByDay(state.sessions);

            return Column(
              children: [
                _buildWeekNav(context, state.weekStart),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      context.w(16),
                      context.h(8),
                      context.w(16),
                      context.h(24),
                    ),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final key = _dayKeys[index];
                      final sessions = grouped[index] ?? [];
                      return _WeekDayCard(
                        key: ValueKey(key),
                        dayName: _dayNames[index],
                        sessions: sessions,
                        isOpen: _openDayKey == key,
                        onToggle: () {
                          setState(() {
                            _openDayKey = _openDayKey == key ? null : key;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeekNav(BuildContext context, DateTime weekStart) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.primary1),
            onPressed: () => context.read<ScheduleCubit>().nextWeek(),
          ),
          Text(
            _formatWeekLabel(weekStart),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.sp(14),
              color: AppColors.secondary3,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.primary1),
            onPressed: () => context.read<ScheduleCubit>().previousWeek(),
          ),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final String dayName;
  final List<WeeklyScheduleItem> sessions;
  final bool isOpen;
  final VoidCallback onToggle;

  const _WeekDayCard({
    super.key,
    required this.dayName,
    required this.sessions,
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
                    dayName,
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
              child: sessions.isEmpty
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
                      children: sessions
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
        '${sessions.length} حصة',
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
  final WeeklyScheduleItem session;
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
                    session.subjectName,
                    textAlign: TextAlign.right,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: context.sp(13.5),
                    ),
                  ),
                  SizedBox(height: context.h(2)),
                  Text(
                    '${session.schoolName} · ${session.roomName} · ${session.isReplaced ? 'تم استبدالك' : session.status.label}',
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
              session.displayTimeRange,
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
