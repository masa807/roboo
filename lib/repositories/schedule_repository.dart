import '../core/network/api_client.dart';
import '../models/weekly_schedule_model.dart';

class ScheduleRepository {
  ScheduleRepository(this._api);

  final ApiClient _api;

  /// يجيب جدول أسبوع كامل بدايةً من [weekStart]
  Future<List<WeeklyScheduleItem>> getWeeklySchedule({
    required String trainerId,
    required DateTime weekStart,
  }) async {
    final dateStr =
        '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

    final response = await _api.get(
      '/api/trainers/$trainerId/weekly-schedule',
      queryParameters: {'weekStart': dateStr},
    );

    final list = response.data as List<dynamic>;
    return list
        .map((e) => WeeklyScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
