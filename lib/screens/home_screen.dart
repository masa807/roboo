import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/color.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';
import '../blocs/attendance/attendance_cubit.dart';
import '../blocs/attendance/attendance_state.dart';
import '../models/daily_checklist_model.dart';
import 'calendar_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // الحصص اللي فشل تسجيلها (بتظهر X)
  final Set<String> _failedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceCubit>().loadToday();
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _onCheckIn(String sessionTrainerId) async {
    // لو كان فاشل قبل، نشيله ليعيد المحاولة
    setState(() => _failedIds.remove(sessionTrainerId));

    final success = await context.read<AttendanceCubit>().checkIn(
      sessionTrainerId,
    );
    if (!mounted) return;

    if (success) {
      _showSnack('تم تسجيل الحضور بنجاح');
    } else {
      setState(() => _failedIds.add(sessionTrainerId));
      final error = context.read<AttendanceCubit>().state.checkInError;
      _showSnack(error ?? 'تعذر تسجيل الحضور', isError: true);
    }
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) return 'اليوم';

    const months = [
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
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBackground(
      child: SafeArea(
        child: BlocBuilder<AttendanceCubit, AttendanceState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.fromLTRB(
                context.w(16),
                context.h(16),
                context.w(16),
                context.h(24),
              ),
              children: [
                // ===== هيدر (دايماً ظاهر) =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatSelectedDate(state.selectedDate),
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: context.sp(16),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => CalendarBottomSheet.show(context),
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
                              'اختر يوم',
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

                // ===== المحتوى حسب الحالة =====
                if (state.status == AttendanceStatus.loading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: context.h(40)),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == AttendanceStatus.error)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: context.h(40)),
                      Text(
                        state.errorMessage ?? 'حدث خطأ في جلب الحصص',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: context.h(12)),
                      ElevatedButton(
                        onPressed: () => context
                            .read<AttendanceCubit>()
                            .loadDate(state.selectedDate),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  )
                else if (state.sessions.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: context.h(40)),
                      child: Text(
                        'لا يوجد حصص لهذا اليوم',
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: context.sp(13),
                        ),
                      ),
                    ),
                  )
                else
                  ...state.sessions.map(
                    (s) => _SessionCard(
                      session: s,
                      isFailed: _failedIds.contains(s.sessionTrainerId),
                      isCheckingIn:
                          state.checkingInSessionId == s.sessionTrainerId &&
                          (state.checkInStatus ==
                                  CheckInStatus.gettingLocation ||
                              state.checkInStatus == CheckInStatus.submitting),
                      onCheckIn: () => _onCheckIn(s.sessionTrainerId),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==== كارد الحصة ====
class _SessionCard extends StatelessWidget {
  final DailyChecklistItem session;
  final bool isCheckingIn;
  final bool isFailed;
  final VoidCallback onCheckIn;

  const _SessionCard({
    required this.session,
    required this.isCheckingIn,
    required this.isFailed,
    required this.onCheckIn,
  });

  Color get _stripColor {
    if (session.isCheckedIn) return AppColors.secondary1;
    if (isFailed) return AppColors.errorColor;
    return AppColors.primary3;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(context.r(10));

    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFEFE),
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFE1EEF0)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الشريط الملون
              Container(width: context.w(4), color: _stripColor),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(context.w(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.subjectName,
                              style: textTheme.titleSmall?.copyWith(
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary3,
                              ),
                            ),
                            SizedBox(height: context.h(4)),
                            Row(
                              children: [
                                Icon(
                                  Icons.alarm,
                                  size: context.r(13),
                                  color: AppColors.primary3,
                                ),
                                SizedBox(width: context.w(4)),
                                Text(
                                  session.displayTimeRange,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: context.sp(11),
                                  ),
                                ),
                                SizedBox(width: context.w(8)),
                                Flexible(
                                  child: Text(
                                    session.schoolName,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall?.copyWith(
                                      fontSize: context.sp(11),
                                    ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    // ✅ نجح التسجيل
    if (session.isCheckedIn) {
      return CircleAvatar(
        radius: context.r(17),
        backgroundColor: AppColors.secondary1,
        child: Icon(Icons.check, color: Colors.white, size: context.r(16)),
      );
    }

    // ❌ فشل التسجيل (بالضغط عليها بتعيد المحاولة)
    if (isFailed && !isCheckingIn) {
      return InkWell(
        customBorder: const CircleBorder(),
        onTap: onCheckIn,
        child: CircleAvatar(
          radius: context.r(17),
          backgroundColor: AppColors.errorColor,
          child: Icon(Icons.close, color: Colors.white, size: context.r(16)),
        ),
      );
    }

    // زر "سجل الآن" لكل الحصص
    return ElevatedButton.icon(
      onPressed: isCheckingIn ? null : onCheckIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary3,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary3.withOpacity(0.7),
        disabledForegroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: context.w(12),
          vertical: context.h(8),
        ),
        minimumSize: Size.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      icon: isCheckingIn
          ? SizedBox(
              width: context.r(14),
              height: context.r(14),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(Icons.location_on, size: context.r(14)),
      label: Text(
        'سجل الآن',
        style: TextStyle(fontSize: context.sp(11), fontWeight: FontWeight.bold),
      ),
    );
  }
}
