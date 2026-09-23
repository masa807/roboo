import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';

/// موديل بسيط لتوزيع الحصص حسب المدرسة
class SchoolSessionStat {
  final String schoolName;
  final int sessionsCount;

  const SchoolSessionStat({
    required this.schoolName,
    required this.sessionsCount,
  });
}

/// تاب الاحصائيات
/// ملاحظة: ما في Scaffold ولا AppBar هون -> موجودين مرة وحدة بس بالـ MainShell
/// (إذا بدك AppBar خاص فيها بالشكل يلي بالصورة، بلش هيك واسأل Masa إذا بدو
/// AppBar موحد من MainShell أو خاص فيها لحالها)
class StatsContent extends StatefulWidget {
  const StatsContent({super.key});

  @override
  State<StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<StatsContent> {
  late DateTime _visibleMonth;

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

  // بيانات تجريبية - استبدلها لاحقاً بالـ Provider / API
  final List<SchoolSessionStat> _schoolStats = const [
    SchoolSessionStat(schoolName: 'مدرسة النور الدولية', sessionsCount: 18),
    SchoolSessionStat(schoolName: 'مدرسة الفارابي', sessionsCount: 14),
    SchoolSessionStat(schoolName: 'أكاديمية الرواد', sessionsCount: 10),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

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

  int get _totalSessionsThisMonth =>
      _schoolStats.fold(0, (sum, s) => sum + s.sessionsCount);

  int get _maxSchoolSessions => _schoolStats.isEmpty
      ? 1
      : _schoolStats
            .map((s) => s.sessionsCount)
            .reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            // ===== كارد الشهر + العدد الكلي =====
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: context.w(20),
                vertical: context.h(20),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary1, AppColors.primary2],
                ),
                borderRadius: BorderRadius.circular(context.r(20)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary1.withOpacity(0.25),
                    blurRadius: context.r(16),
                    offset: Offset(0, context.h(6)),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ---- هيدر الشهر + أزرار التنقل ----
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _goToNextMonth,
                        icon: Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: context.r(20),
                        ),
                      ),
                      Text(
                        '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: context.sp(15),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _goToPrevMonth,
                        icon: Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: context.r(20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(8)),

                  // ---- العدد الكبير ----
                  Text(
                    '$_totalSessionsThisMonth',
                    style: TextStyle(
                      fontSize: context.sp(48),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'حصة أنجزتها هالشهر',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: context.sp(13),
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.h(20)),

            // ===== عنوان القسم =====
            Text(
              'توزيع الحصص حسب المدرسة',
              style: textTheme.titleSmall?.copyWith(
                fontSize: context.sp(14),
                fontWeight: FontWeight.bold,
                color: AppColors.secondary3,
              ),
            ),
            SizedBox(height: context.h(10)),

            // ===== كروت المدارس =====
            ..._schoolStats.map(
              (stat) => _SchoolStatCard(
                stat: stat,
                ratio: _maxSchoolSessions == 0
                    ? 0
                    : stat.sessionsCount / _maxSchoolSessions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== كارد إحصائية مدرسة واحدة ====
class _SchoolStatCard extends StatelessWidget {
  final SchoolSessionStat stat;
  final double ratio; // نسبة الملء بالبروجرس بار (0.0 - 1.0)

  const _SchoolStatCard({required this.stat, required this.ratio});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: EdgeInsets.only(bottom: context.h(10)),
      padding: EdgeInsets.all(context.w(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.r(14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: context.r(10),
            offset: Offset(0, context.h(3)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // عدد الحصص - يمين
              Text(
                '${stat.sessionsCount} حصة',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary3,
                ),
              ),
              const Spacer(),
              // اسم المدرسة - شمال
              Text(
                stat.schoolName,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: context.sp(13.5),
                  color: AppColors.secondary3,
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(10)),

          // ---- البروجرس بار ----
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: context.h(7),
              backgroundColor: AppColors.primary4,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(
                  0xFFF0A75C,
                ), // نفس البرتقالي المستخدم بزر الإرسال بشاشة الطلبات
              ),
            ),
          ),
        ],
      ),
    );
  }
}
