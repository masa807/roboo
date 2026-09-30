import '../models/stats_model.dart';
import 'attendance_repository.dart';

/// ما في endpoint للإحصائيات بالباك، فمنجمّعها من daily-checklist
/// لكل يوم بالشهر (لحد اليوم الحالي)
class StatsRepository {
  StatsRepository(this._attendanceRepo);

  final AttendanceRepository _attendanceRepo;

  static const int _batchSize = 7;

  Future<List<SchoolSessionStat>> getMonthlySchoolStats({
    required String trainerId,
    required DateTime month,
  }) async {
    final now = DateTime.now();
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    final days = <DateTime>[];
    for (var d = 1; d <= lastDay; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.isAfter(now)) break; // ما في حضور بالمستقبل
      days.add(date);
    }

    final counts = <String, int>{};

    for (var i = 0; i < days.length; i += _batchSize) {
      final batch = days.skip(i).take(_batchSize);
      final results = await Future.wait(
        batch.map(
          (date) => _attendanceRepo.getDailyChecklist(
            trainerId: trainerId,
            date: date,
          ),
        ),
      );

      for (final items in results) {
        for (final item in items) {
          // الحصة المعدودة = يلي المدرب سجّل حضورها
          // (إذا بدك تعدّ المنتهية بغض النظر عن الحضور:
          //  item.sessionStatus == DailySessionStatus.done)
          if (!item.isCheckedIn) continue;
          counts[item.schoolName] = (counts[item.schoolName] ?? 0) + 1;
        }
      }
    }

    return counts.entries
        .map(
          (e) => SchoolSessionStat(schoolName: e.key, sessionsCount: e.value),
        )
        .toList()
      ..sort((a, b) => b.sessionsCount.compareTo(a.sessionsCount));
  }
}
