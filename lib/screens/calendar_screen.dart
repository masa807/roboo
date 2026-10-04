import '../core/school_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/color.dart';
import '../utils/responsive.dart';
import '../blocs/attendance/attendance_cubit.dart';
import '../blocs/attendance/attendance_state.dart';

class CalendarBottomSheet extends StatefulWidget {
  const CalendarBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<AttendanceCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const CalendarBottomSheet()),
    );
  }

  @override
  State<CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<CalendarBottomSheet> {
  late DateTime _visibleMonth;

  static const List<String> _weekDays = [
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
    final selected = context.read<AttendanceCubit>().state.selectedDate;
    _visibleMonth = DateTime(selected.year, selected.month, 1);
  }

  void _prevMonth() => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
  });

  List<DateTime?> _buildGrid() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leading = first.weekday % 7;

    final List<DateTime?> cells = List.filled(leading, null, growable: true);
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_visibleMonth.year, _visibleMonth.month, d));
    }
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
    final cells = _buildGrid();

    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        final selectedDay = state.selectedDate;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(context.r(24)),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            context.w(16),
            context.h(12),
            context.w(16),
            context.h(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: context.w(40),
                height: context.h(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              SizedBox(height: context.h(16)),

              // هيدر الشهر
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _nextMonth,
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
                    onPressed: _prevMonth,
                    icon: Icon(
                      Icons.chevron_left,
                      color: AppColors.primary1,
                      size: context.r(24),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.h(6)),

              // رؤوس أيام الأسبوع
              Row(
                children: _weekDays
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

              // شبكة الأيام
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  final date = cells[index];
                  if (date == null) return const SizedBox.shrink();

                  final isSelected = _isSameDay(date, selectedDay);
                  final isToday = _isSameDay(date, SchoolTime.now());

                  return Padding(
                    padding: EdgeInsets.all(context.w(3)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        context.read<AttendanceCubit>().loadDate(date);
                        Navigator.pop(context); // يقفل الـ sheet بعد الاختيار
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary1
                              : (isToday
                                    ? AppColors.primary4
                                    : Colors.transparent),
                        ),
                        child: Center(
                          child: Text(
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
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: context.h(12)),

              // زر إغلاق
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إغلاق',
                  style: TextStyle(
                    color: AppColors.secondary3,
                    fontSize: context.sp(13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
