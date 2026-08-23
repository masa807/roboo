/// حالة الحصة الواحدة
enum SessionStatus { done, missed, upcoming, active }

/// موديل الحصة الواحدة
class SessionModel {
  final String subject;
  final String school;
  final String time;
  final SessionStatus status;

  SessionModel({
    required this.subject,
    required this.school,
    required this.time,
    required this.status,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      subject: json['subject'] as String,
      school: json['school'] as String,
      time: json['time'] as String,
      status: _statusFromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'school': school,
      'time': time,
      'status': status.name,
    };
  }

  static SessionStatus _statusFromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SessionStatus.upcoming,
    );
  }

  SessionModel copyWith({
    String? subject,
    String? school,
    String? time,
    SessionStatus? status,
  }) {
    return SessionModel(
      subject: subject ?? this.subject,
      school: school ?? this.school,
      time: time ?? this.time,
      status: status ?? this.status,
    );
  }
}

/// موديل اليوم الواحد وحصصو
class DayModel {
  final String key;
  final String name;
  final String date;
  final List<SessionModel> sessions;

  DayModel({
    required this.key,
    required this.name,
    required this.date,
    required this.sessions,
  });

  factory DayModel.fromJson(Map<String, dynamic> json) {
    return DayModel(
      key: json['key'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => sessions.isEmpty;

  bool get isComplete =>
      sessions.isNotEmpty &&
      sessions.every((s) => s.status == SessionStatus.done);

  DayModel copyWith({
    String? key,
    String? name,
    String? date,
    List<SessionModel>? sessions,
  }) {
    return DayModel(
      key: key ?? this.key,
      name: name ?? this.name,
      date: date ?? this.date,
      sessions: sessions ?? this.sessions,
    );
  }
}
