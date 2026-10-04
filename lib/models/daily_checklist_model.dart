enum DailySessionStatus {
  scheduled,
  completed,
  cancelled,
  pendingSubstitute,
  substituted,
  unknown,
}

extension DailySessionStatusX on DailySessionStatus {
  static DailySessionStatus fromCode(int code) => code >= 0 && code <= 4
      ? DailySessionStatus.values[code]
      : DailySessionStatus.unknown;
  String get label => [
    'مجدولة',
    'مكتملة',
    'ملغاة',
    'بانتظار بديل',
    'مسندة لبديل',
    'غير معروفة',
  ][index];
}

/// عنصر واحد من daily-checklist - حصة يوم واحد مع كل تفاصيلها
class DailyChecklistItem {
  final String sessionTrainerId;
  final String sessionId;
  final DateTime date;
  final String startTime; // "08:00:00"
  final String endTime; // "09:00:00"
  final String schoolId;
  final String schoolName;
  final double schoolLatitude;
  final double schoolLongitude;
  final int allowedRadiusMeters;
  final String subjectName;
  final String roomName;
  final DailySessionStatus sessionStatus;
  final bool isOriginal;
  final bool isCheckedIn;
  final DateTime? checkInServerTime;

  const DailyChecklistItem({
    required this.sessionTrainerId,
    required this.sessionId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.schoolId,
    required this.schoolName,
    required this.schoolLatitude,
    required this.schoolLongitude,
    required this.allowedRadiusMeters,
    required this.subjectName,
    required this.roomName,
    required this.sessionStatus,
    required this.isOriginal,
    required this.isCheckedIn,
    this.checkInServerTime,
  });

  /// "08:00:00" -> "08:00 ص" تقريبي بسيط للعرض
  String get displayTimeRange => '$startTime - $endTime';

  factory DailyChecklistItem.fromJson(Map<String, dynamic> json) {
    return DailyChecklistItem(
      sessionTrainerId: json['sessionTrainerId'] as String,
      sessionId: json['sessionId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      schoolId: json['schoolId'] as String,
      schoolName: json['schoolName'] as String? ?? '',
      schoolLatitude: (json['schoolLatitude'] as num).toDouble(),
      schoolLongitude: (json['schoolLongitude'] as num).toDouble(),
      allowedRadiusMeters: (json['allowedRadiusMeters'] as num).toInt(),
      subjectName: json['subjectName'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      sessionStatus: DailySessionStatusX.fromCode(
        json['sessionStatus'] as int? ?? 0,
      ),
      isOriginal: json['isOriginal'] as bool? ?? true,
      isCheckedIn: json['isCheckedIn'] as bool? ?? false,
      checkInServerTime: json['checkInServerTime'] != null
          ? DateTime.tryParse(json['checkInServerTime'] as String)
          : null,
    );
  }

  DailyChecklistItem copyWith({
    bool? isCheckedIn,
    DateTime? checkInServerTime,
  }) {
    return DailyChecklistItem(
      sessionTrainerId: sessionTrainerId,
      sessionId: sessionId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      schoolId: schoolId,
      schoolName: schoolName,
      schoolLatitude: schoolLatitude,
      schoolLongitude: schoolLongitude,
      allowedRadiusMeters: allowedRadiusMeters,
      subjectName: subjectName,
      roomName: roomName,
      sessionStatus: sessionStatus,
      isOriginal: isOriginal,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInServerTime: checkInServerTime ?? this.checkInServerTime,
    );
  }
}
