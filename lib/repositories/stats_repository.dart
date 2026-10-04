import '../models/stats_model.dart';
import 'attendance_repository.dart';

class StatsRepository {
  StatsRepository(this._attendanceRepo);
  final AttendanceRepository _attendanceRepo;
  Future<List<SchoolSessionStat>> getMonthlySchoolStats({
    required String trainerId,
    required DateTime month,
  }) =>
      _attendanceRepo.getMonthlySchoolStats(trainerId: trainerId, month: month);
}
