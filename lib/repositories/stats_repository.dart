import '../core/school_time.dart';
import '../models/stats_model.dart';
import 'attendance_repository.dart';

class StatsRepository {
  StatsRepository(this._attendanceRepo);
  final AttendanceRepository _attendanceRepo;

  /// عدد الطلبات المتوازية، حتى ما نضغط على السيرفر
  static const int _batchSize = 6;

  /// بيحسب الحصص اللي سُجّل فيها حضور خلال [month]، مجمّعة حسب المدرسة
  Future<List<SchoolSessionStat>> getMonthlySchoolStats({
    required String trainerId,
    required DateTime month,
  }) async {
    final now = SchoolTime.now();
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0).day;
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final lastDay = isCurrentMonth ? now.day : lastDayOfMonth;

    final counts = <String, int>{};
    final names = <String, String>{};

    for (var start = 1; start <= lastDay; start += _batchSize) {
      final end = (start + _batchSize - 1) > lastDay
          ? lastDay
          : start + _batchSize - 1;

      final days = await Future.wait([
        for (var d = start; d <= end; d++)
          _attendanceRepo.getDailyChecklist(
            trainerId: trainerId,
            date: DateTime(month.year, month.month, d),
          ),
      ]);

      for (final items in days) {
        for (final item in items) {
          if (!item.isCheckedIn) continue;
          counts[item.schoolId] = (counts[item.schoolId] ?? 0) + 1;
          names[item.schoolId] = item.schoolName;
        }
      }
    }

    final result =
        counts.entries
            .map(
              (e) => SchoolSessionStat(
                schoolId: e.key,
                schoolName: names[e.key] ?? '',
                sessionsCount: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.sessionsCount.compareTo(a.sessionsCount));

    return result;
  }
}
