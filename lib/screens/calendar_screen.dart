import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../models/home_model.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';

/// شاشة الكالندر الشهري
/// بتنفتح بـ Navigator.push عادي (مش تاب بالـ MainShell)
/// فلهيك إلها Scaffold + AppBar خاص فيها
class CalendarScreen extends StatefulWidget {
  /// بيانات الأيام يلي فيها حصص (المفتاح بصيغة yyyy-MM-dd)
  final Map<String, DayModel> daysData;

  const CalendarScreen({super.key, this.daysData = const {}});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  static const List<String> _weekDaysShort = [
    'أحد',
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  static const List<String> _monthNames = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  String _keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _goToPrevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  /// بيرجع لائحة كل خانات الشهر (تتضمن أيام من الشهر السابق/اللاحق لتعبئة الشبكة)
  List<DateTime?> _buildMonthGrid() {
    final firstDayOfMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    // الأحد = 0 ... السبت = 6 (weekday بـ Dart: الاثنين=1 ... الأحد=7)
    final leadingEmpty = firstDayOfMonth.weekday % 7;

    final List<DateTime?> cells = [];
    cells.addAll(List.filled(leadingEmpty, null));
    for (int day = 1; day <= daysInMonth; day++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, day));
    }
    // نكمل الصفوف لحد ما تصير مضاعف 7
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cells = _buildMonthGrid();
    final selectedDayModel = widget.daysData[_keyOf(_selectedDay)];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary1,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'التقويم',
          style: TextStyle(color: Colors.white, fontSize: context.sp(18)),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(16),
              context.w(16),
              context.h(24),
            ),
            children: [
              // ===== كارد الكالندر =====
              Container(
                padding: EdgeInsets.all(context.w(14)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(16)),
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
                    // ---- هيدر الشهر + أزرار التنقل ----
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _goToNextMonth,
                          icon: Icon(
                            Icons.chevron_right,
                            color: AppColors.primary1,
                            size: context.r(24),
                          ),
                        ),
                        Text(
                          '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: context.sp(16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary1,
                          ),
                        ),
                        IconButton(
                          onPressed: _goToPrevMonth,
                          icon: Icon(
                            Icons.chevron_left,
                            color: AppColors.primary1,
                            size: context.r(24),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.h(6)),

                    // ---- رؤوس أيام الأسبوع ----
                    Row(
                      children: _weekDaysShort
                          .map(
                            (d) => Expanded(
                              child: Center(
                                child: Text(
                                  d,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: context.sp(11),
                                    color: AppColors.secondary3,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: context.h(6)),

                    // ---- شبكة الأيام ----
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                          ),
                      itemBuilder: (context, index) {
                        final date = cells[index];
                        if (date == null) return const SizedBox.shrink();

                        final isSelected = _isSameDay(date, _selectedDay);
                        final isToday = _isSameDay(date, DateTime.now());
                        final dayModel = widget.daysData[_keyOf(date)];
                        final hasSessions =
                            dayModel != null && dayModel.sessions.isNotEmpty;

                        Color dotColor = AppColors.primary2;
                        if (hasSessions && dayModel!.isComplete) {
                          dotColor = AppColors.secondary1;
                        } else if (hasSessions) {
                          dotColor = AppColors.primary1;
                        }

                        return Padding(
                          padding: EdgeInsets.all(context.w(3)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setState(() => _selectedDay = date),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary1
                                    : (isToday
                                          ? AppColors.primary4
                                          : Colors.transparent),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: context.sp(12.5),
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : (isToday
                                                ? AppColors.primary1
                                                : Colors.black87),
                                    ),
                                  ),
                                  SizedBox(height: context.h(2)),
                                  if (hasSessions)
                                    Container(
                                      width: context.r(5),
                                      height: context.r(5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? Colors.white
                                            : dotColor,
                                      ),
                                    )
                                  else
                                    SizedBox(height: context.r(5)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(18)),

              // ===== قائمة حصص اليوم المختار =====
              Text(
                'حصص يوم ${_selectedDay.day} ${_monthNames[_selectedDay.month - 1]}',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.h(10)),

              if (selectedDayModel == null || selectedDayModel.sessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: context.h(24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.r(14)),
                  ),
                  child: Center(
                    child: Text(
                      'ما في حصص هالنهار',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: context.sp(12),
                        color: AppColors.secondary3,
                      ),
                    ),
                  ),
                )
              else
                ...selectedDayModel.sessions.map(
                  (s) => Container(
                    margin: EdgeInsets.only(bottom: context.h(10)),
                    padding: EdgeInsets.all(context.w(12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(context.r(12)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: context.r(8),
                          offset: Offset(0, context.h(2)),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: context.w(4),
                          height: context.h(36),
                          decoration: BoxDecoration(
                            color: _statusColor(s.status),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        SizedBox(width: context.w(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.subject,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: context.sp(13.5),
                                ),
                              ),
                              SizedBox(height: context.h(2)),
                              Text(
                                '${s.school} • ${s.time}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: context.sp(11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
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
}
