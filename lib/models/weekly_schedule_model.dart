/// حالة الحصة بالجدول الأسبوعي — نفس ترميز daily-checklist تقريباً
/// (0 = مجدولة، 1 = جارية، 2 = منتهية). عدّليها لو الباك اند مختلف.
enum WeeklySessionStatus { scheduled, active, done }

extension WeeklySessionStatusX on WeeklySessionStatus {
  static WeeklySessionStatus fromCode(int code) {
    switch (code) {
      case 1:
        return WeeklySessionStatus.active;
      case 2:
        return WeeklySessionStatus.done;
      case 0:
      default:
        return WeeklySessionStatus.scheduled;
    }
  }
}

/// عنصر حصة واحدة من GET /api/trainers/{trainerId}/weekly-schedule
class WeeklyScheduleItem {
  final String sessionId;
  final DateTime date;
  final String startTime; // "08:00:00"
  final String endTime; // "09:00:00"
  final String schoolName;
  final String subjectName;
  final String roomName;
  final WeeklySessionStatus status;
  final bool isOriginal;

  const WeeklyScheduleItem({
    required this.sessionId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.schoolName,
    required this.subjectName,
    required this.roomName,
    required this.status,
    required this.isOriginal,
  });

  String get displayTimeRange => '$startTime - $endTime';

  factory WeeklyScheduleItem.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItem(
      sessionId: json['sessionId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      schoolName: json['schoolName'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      status: WeeklySessionStatusX.fromCode(json['status'] as int? ?? 0),
      isOriginal: json['isOriginal'] as bool? ?? true,
    );
  }
}
