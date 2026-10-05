import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../core/network/api_client.dart';
import '../models/daily_checklist_model.dart';

class AttendanceRepository {
  AttendanceRepository(this._api);
  final ApiClient _api;
  static const _uuid = Uuid();
  final _storage = const FlutterSecureStorage();
  Future<void> _queue = Future.value();
  String _key(String trainer) =>
      'roboo_attendance:${Uri.encodeComponent(_api.dio.options.baseUrl)}:$trainer';
  Future<Map<String, dynamic>> _pending(String trainer) async {
    final raw = await _storage.read(key: _key(trainer));
    return raw == null ? {} : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final version = _api.sessionVersion;
    final future = _queue.then((_) {
      if (version != _api.sessionVersion) {
        throw const ApiException('تم تغيير الجلسة.');
      }
      return action();
    });
    _queue = future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return future;
  }

  Future<void> _save(String trainer, Map<String, dynamic> pending) =>
      _storage.write(key: _key(trainer), value: jsonEncode(pending));
  Future<List<DailyChecklistItem>> getDailyChecklist({
    required String trainerId,
    required DateTime date,
  }) async {
    // Retry only this account's saved attempts; a temporary failure does not hide the checklist.
    try {
      await syncPending(trainerId);
    } on ApiException catch (e) {
      if ([401, 403].contains(e.statusCode)) rethrow;
    }
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await _api.get(
      '/api/trainers/$trainerId/daily-checklist',
      queryParameters: {'date': dateStr},
    );
    try {
      return (response.data as List)
          .map(
            (e) => DailyChecklistItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } catch (_) {
      throw const ApiException('تعذر قراءة بيانات الحضور من الخادم.');
    }
  }

  /// رسالة المحاولات اللي بانتظار المزامنة فقط.
  /// المحاولات المرفوضة نهائياً من السيرفر بتنحذف ولا بتنعرض.
  Future<String?> pendingMessage(String trainerId) async {
    try {
      return await _serial(() async {
        final items = await _pending(trainerId);
        if (items.isEmpty) return null;
        final rejected = items.entries
            .where((e) => e.value['error'] != null)
            .map((e) => e.key)
            .toList();
        if (rejected.isNotEmpty) {
          for (final key in rejected) {
            items.remove(key);
          }
          await _save(trainerId, items);
        }
        if (items.isEmpty) return null;
        return '${items.length} محاولة محفوظة بانتظار المزامنة؛ لم يُؤكَّد حضورها بعد.';
      });
    } on ApiException {
      return null;
    }
  }

  Future<void> syncPending(String trainerId) => _serial(() async {
    final pending = await _pending(trainerId);
    final items = pending.values
        .where((v) => v['error'] == null)
        .take(100)
        .map((v) => v['body'])
        .toList();
    if (items.isEmpty) return;
    final response = await _api.post(
      '/api/attendance/sync-batch',
      data: {'items': items},
    );
    final results = (response.data as Map)['results'] as List;
    for (final result in results) {
      final matches = pending.entries
          .where(
            (e) =>
                e.value['body']['clientGeneratedId'] ==
                result['clientGeneratedId'],
          )
          .map((e) => e.key)
          .toList();
      for (final key in matches) {
        if (result['success'] == true ||
            result['errorCode'] == 'Attendance.AlreadyCheckedIn') {
          pending.remove(key);
        } else {
          pending[key]['error'] =
              result['errorMessage'] ?? 'رفض الخادم المحاولة.';
        }
      }
    }
    await _save(trainerId, pending);
  });
  Future<void> checkIn({
    required String trainerId,
    required String sessionTrainerId,
    required double latitude,
    required double longitude,
    required double accuracy,
    bool isMocked = false,
  }) => _serial(() async {
    final pending = await _pending(trainerId);
    final existing = pending[sessionTrainerId];
    if (existing != null && existing['error'] == null) {
      // A lost response must retry the exact payload and UUID, including the original GPS/time.
      final response = await _api.post(
        '/api/attendance/sync-batch',
        data: {
          'items': [existing['body']],
        },
      );
      final result = ((response.data as Map)['results'] as List).single as Map;
      if (result['success'] != true &&
          result['errorCode'] != 'Attendance.AlreadyCheckedIn') {
        pending[sessionTrainerId]['error'] =
            result['errorMessage'] ?? 'رفض الخادم المحاولة.';
        await _save(trainerId, pending);
        throw ApiException(
          result['errorMessage'] as String? ?? 'رفض الخادم المحاولة.',
        );
      }
      pending.remove(sessionTrainerId);
      await _save(trainerId, pending);
      return;
    }
    // Old, confirmed rejections must not permanently fill the retry queue.
    // Never evict an attempt whose result is still unknown.
    if (!pending.containsKey(sessionTrainerId)) {
      final rejected = pending.entries
          .where((entry) => entry.value['error'] != null)
          .map((entry) => entry.key)
          .toList();
      for (final key in rejected) {
        if (pending.length < 100) break;
        pending.remove(key);
      }
    }
    if (pending.length >= 100 && !pending.containsKey(sessionTrainerId)) {
      throw const ApiException(
        'توجد محاولات كثيرة بانتظار المزامنة. اتصل بالخادم أولًا.',
      );
    }
    final body = {
      'sessionTrainerId': sessionTrainerId,
      'clientGeneratedId': _uuid.v4(),
      'checkInDeviceTime': DateTime.now().toUtc().toIso8601String(),
      'checkInLat': latitude,
      'checkInLng': longitude,
      'checkInAccuracy': accuracy,
      'checkInIsMocked': isMocked,
    };
    pending[sessionTrainerId] = {'body': body};
    await _save(trainerId, pending);
    try {
      await _api.post('/api/attendance/check-in', data: body);
      pending.remove(sessionTrainerId);
      await _save(trainerId, pending);
    } on ApiException catch (e) {
      if (e.statusCode != null &&
          e.statusCode! >= 400 &&
          e.statusCode! < 500 &&
          ![401, 408, 409, 429].contains(e.statusCode)) {
        pending[sessionTrainerId]['error'] = e.message;
        await _save(trainerId, pending);
        rethrow;
      }
      throw const ApiException(
        'لم يتأكد التسجيل. حُفظت المحاولة بأمان لإعادة مزامنتها عند الاتصال؛ لا تعدّ حضورًا حتى يؤكدها الخادم.',
      );
    }
  });
}
