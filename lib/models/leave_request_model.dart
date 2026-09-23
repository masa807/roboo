enum LeaveRequestStatus { pending, approved, rejected }

extension LeaveRequestStatusX on LeaveRequestStatus {
  int get code => index; // 0, 1, 2 متل الـ API

  static LeaveRequestStatus fromCode(int code) {
    switch (code) {
      case 1:
        return LeaveRequestStatus.approved;
      case 2:
        return LeaveRequestStatus.rejected;
      case 0:
      default:
        return LeaveRequestStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case LeaveRequestStatus.pending:
        return 'قيد المراجعة';
      case LeaveRequestStatus.approved:
        return 'موافَق عليه';
      case LeaveRequestStatus.rejected:
        return 'مرفوض';
    }
  }
}

/// selectionMode متل ما راجعة بالـ Swagger — 0 = يوم كامل (targetDate)،
/// 1 = حصص محددة (sessionTrainerIds). إذا الـ enum الحقيقي مختلف
/// بس عدّل القيم هون، الباقي كله رح يمشي بدون تغيير.
enum LeaveSelectionMode { fullDay, specificSessions }

extension LeaveSelectionModeX on LeaveSelectionMode {
  int get code => index;
}

class LeaveRequestModel {
  final String id;
  final String trainerId;
  final String reason;
  final LeaveSelectionMode selectionMode;
  final DateTime? targetDate;
  final List<String> sessionTrainerIds;
  final String? proposedSubstituteTrainerId;
  final LeaveRequestStatus status;
  final String? reviewedBy;

  const LeaveRequestModel({
    required this.id,
    required this.trainerId,
    required this.reason,
    required this.selectionMode,
    this.targetDate,
    this.sessionTrainerIds = const [],
    this.proposedSubstituteTrainerId,
    this.status = LeaveRequestStatus.pending,
    this.reviewedBy,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'] as String,
      trainerId: json['trainerId'] as String,
      reason: json['reason'] as String? ?? '',
      selectionMode: (json['selectionMode'] as int? ?? 0) == 1
          ? LeaveSelectionMode.specificSessions
          : LeaveSelectionMode.fullDay,
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      sessionTrainerIds:
          (json['sessionTrainerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      proposedSubstituteTrainerId:
          json['proposedSubstituteTrainerId'] as String?,
      status: LeaveRequestStatusX.fromCode(json['status'] as int? ?? 0),
      reviewedBy: json['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainerId': trainerId,
      'reason': reason,
      'selectionMode': selectionMode.code,
      if (targetDate != null)
        'targetDate':
            '${targetDate!.year.toString().padLeft(4, '0')}-${targetDate!.month.toString().padLeft(2, '0')}-${targetDate!.day.toString().padLeft(2, '0')}',
      'sessionTrainerIds': sessionTrainerIds,
      if (proposedSubstituteTrainerId != null)
        'proposedSubstituteTrainerId': proposedSubstituteTrainerId,
    };
  }
}

/// بيانات إنشاء طلب غياب جديد (البودي تبع POST /api/leave-requests)
class CreateLeaveRequestPayload {
  final String trainerId;
  final String reason;
  final LeaveSelectionMode selectionMode;
  final DateTime? targetDate;
  final List<String> sessionTrainerIds;
  final String? proposedSubstituteTrainerId;

  const CreateLeaveRequestPayload({
    required this.trainerId,
    required this.reason,
    required this.selectionMode,
    this.targetDate,
    this.sessionTrainerIds = const [],
    this.proposedSubstituteTrainerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'trainerId': trainerId,
      'reason': reason,
      'selectionMode': selectionMode.code,
      if (targetDate != null)
        'targetDate':
            '${targetDate!.year.toString().padLeft(4, '0')}-${targetDate!.month.toString().padLeft(2, '0')}-${targetDate!.day.toString().padLeft(2, '0')}',
      'sessionTrainerIds': sessionTrainerIds,
      if (proposedSubstituteTrainerId != null)
        'proposedSubstituteTrainerId': proposedSubstituteTrainerId,
    };
  }
}

/// مدرّب بديل متاح (نتيجة GET /available-substitutes)
class SubstituteTrainerModel {
  final String id;
  final String name;

  const SubstituteTrainerModel({required this.id, required this.name});

  factory SubstituteTrainerModel.fromJson(Map<String, dynamic> json) {
    return SubstituteTrainerModel(
      id: json['id'] as String,
      name: (json['name'] ?? json['fullName'] ?? '') as String,
    );
  }
}
