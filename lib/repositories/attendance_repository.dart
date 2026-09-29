import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../models/daily_checklist_model.dart';

class AttendanceRepository {
  AttendanceRepository(this._api);

  final ApiClient _api;
  static const _uuid = Uuid();

  /// يجيب حصص يوم معين لمدرب معين
  Future<List<DailyChecklistItem>> getDailyChecklist({
    required String trainerId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    print('>>> getDailyChecklist: trainerId=$trainerId, date=$dateStr'); // مؤقت

    final response = await _api.get(
      '/api/trainers/$trainerId/daily-checklist',
      queryParameters: {'date': dateStr},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => DailyChecklistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// تسجيل حضور لحصة معينة عبر GPS
  Future<void> checkIn({
    required String sessionTrainerId,
    required double latitude,
    required double longitude,
    required double accuracy,
    bool isMocked = false,
  }) async {
    await _api.post(
      '/api/attendance/check-in',
      data: {
        'sessionTrainerId': sessionTrainerId,
        'clientGeneratedId': _uuid.v4(),
        'checkInDeviceTime': DateTime.now().toUtc().toIso8601String(),
        'checkInLat': latitude,
        'checkInLng': longitude,
        'checkInAccuracy': accuracy,
        'checkInIsMocked': isMocked,
      },
    );
  }
}
