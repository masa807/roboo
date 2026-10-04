enum WeeklySessionStatus {
  scheduled,
  completed,
  cancelled,
  pendingSubstitute,
  substituted,
  unknown,
}

extension WeeklySessionStatusX on WeeklySessionStatus {
  static WeeklySessionStatus fromCode(int code) => code >= 0 && code <= 4
      ? WeeklySessionStatus.values[code]
      : WeeklySessionStatus.unknown;
  String get label => [
    'مجدولة',
    'مكتملة',
    'ملغاة',
    'بانتظار بديل',
    'مسندة لبديل',
    'غير معروفة',
  ][index];
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
  final bool isReplaced;

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
    this.isReplaced = false,
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
      isReplaced: json['isReplaced'] as bool? ?? false,
    );
  }
}
