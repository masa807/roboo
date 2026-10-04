/// توزيع الحصص حسب المدرسة
class SchoolSessionStat {
  final String schoolId;
  final String schoolName;
  final int sessionsCount;

  const SchoolSessionStat({
    this.schoolId = '',
    required this.schoolName,
    required this.sessionsCount,
  });
}
