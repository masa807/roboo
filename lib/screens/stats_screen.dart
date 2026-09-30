import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/stats/stats_cubit.dart';
import '../../models/stats_model.dart';
import '../../theme/color.dart';
import '../../widget/app_background.dart';
import '../../utils/responsive.dart';

/// تاب الاحصائيات
/// ملاحظة: ما في Scaffold ولا AppBar هون -> موجودين مرة وحدة بس بالـ MainShell
class StatsContent extends StatelessWidget {
  const StatsContent({super.key});

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
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<StatsCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  context.w(16),
                  context.h(16),
                  context.w(16),
                  context.h(24),
                ),
                children: [
                  _buildMonthCard(context, state),
                  SizedBox(height: context.h(20)),
                  Text(
                    'توزيع الحصص حسب المدرسة',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: context.sp(14),
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary3,
                    ),
                  ),
                  SizedBox(height: context.h(10)),
                  ..._buildBody(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, StatsState state) {
    if (state.isLoading) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(40)),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(32)),
          child: Column(
            children: [
              Text(
                state.error!,
                style: TextStyle(
                  fontSize: context.sp(14),
                  color: AppColors.secondary3,
                ),
              ),
              SizedBox(height: context.h(12)),
              ElevatedButton(
                onPressed: () => context.read<StatsCubit>().refresh(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ];
    }

    if (state.schools.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.h(32)),
          child: Center(
            child: Text(
              'لا توجد حصص في هذا الشهر',
              style: TextStyle(
                fontSize: context.sp(13),
                color: AppColors.secondary3,
              ),
            ),
          ),
        ),
      ];
    }

    return state.schools
        .map(
          (stat) => _SchoolStatCard(
            stat: stat,
            ratio: stat.sessionsCount / state.maxSessions,
          ),
        )
        .toList();
  }

  Widget _buildMonthCard(BuildContext context, StatsState state) {
    final textTheme = Theme.of(context).textTheme;
    final cubit = context.read<StatsCubit>();

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الشهر التالي: معطّل إذا نحن بالشهر الحالي
              IconButton(
                onPressed: state.isCurrentMonth ? null : cubit.nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(
                    state.isCurrentMonth ? 0.35 : 1,
                  ),
                  size: context.r(20),
                ),
              ),
              Text(
                '${_monthNames[state.month.month - 1]} ${state.month.year}',
                style: textTheme.titleMedium?.copyWith(
                  fontSize: context.sp(15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: cubit.prevMonth,
                icon: Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: context.r(20),
                ),
              ),
            ],
          ),
          SizedBox(height: context.h(8)),
          Text(
            state.isLoading ? '–' : '${state.total}',
            style: TextStyle(
              fontSize: context.sp(48),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          SizedBox(height: context.h(4)),
          Text(
            'حصة أنجزتها في هذا الشهر',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: context.sp(13),
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

// ==== كارد إحصائية مدرسة واحدة ====
class _SchoolStatCard extends StatelessWidget {
  final SchoolSessionStat stat;
  final double ratio;

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
              Text(
                '${stat.sessionsCount} حصة',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: context.sp(13.5),
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary3,
                ),
              ),
              const Spacer(),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: context.h(7),
              backgroundColor: AppColors.primary4,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF0A75C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
