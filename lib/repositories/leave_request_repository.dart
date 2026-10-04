import '../core/network/api_client.dart';
import '../models/leave_request_model.dart';

class LeaveRequestRepository {
  LeaveRequestRepository(this._client);

  final ApiClient _client;

  /// GET /api/trainers/{trainerId}/leave-requests?status=
  /// [status] اختياري — لو تركته null بيرجع كل الطلبات
  Future<List<LeaveRequestModel>> getTrainerLeaveRequests({
    required String trainerId,
    LeaveRequestStatus? status,
    int page = 1,
  }) async {
    final response = await _client.get(
      '/api/trainers/$trainerId/leave-requests',
      queryParameters: {
        'page': page,
        'pageSize': 20,
        if (status != null) 'status': status.code,
      },
    );
    final data =
        (response.data as Map<String, dynamic>)['items'] as List<dynamic>;
    return data
        .map((e) => LeaveRequestModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/leave-requests/{id}
  Future<LeaveRequestModel> getLeaveRequestById(String id) async {
    final response = await _client.get('/api/leave-requests/$id');
    return LeaveRequestModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /api/leave-requests
  Future<void> createLeaveRequest(CreateLeaveRequestPayload payload) async {
    await _client.post('/api/leave-requests', data: payload.toJson());
  }

  /// POST /api/leave-requests/{id}/cancel
  Future<void> cancelLeaveRequest(String id) async {
    await _client.post('/api/leave-requests/$id/cancel');
  }

  /// POST /api/leave-requests/{id}/approve
  Future<void> approveLeaveRequest(
    String id, {
    required String reviewedBy,
  }) async {
    await _client.post(
      '/api/leave-requests/$id/approve',
      data: {'reviewedBy': reviewedBy},
    );
  }

  /// POST /api/leave-requests/{id}/reject
  Future<void> rejectLeaveRequest(
    String id, {
    required String reviewedBy,
  }) async {
    await _client.post(
      '/api/leave-requests/$id/reject',
      data: {'reviewedBy': reviewedBy},
    );
  }

  /// GET /api/trainers/{trainerId}/available-substitutes?sessionIds=...
  Future<List<SubstituteTrainerModel>> getAvailableSubstitutes({
    required String trainerId,
    required List<String> sessionIds,
  }) async {
    final response = await _client.get(
      '/api/trainers/$trainerId/available-substitutes',
      queryParameters: {'sessionIds': sessionIds},
    );
    final data = response.data as List<dynamic>;
    return data
        .where((e) => e is Map && e['isAvailable'] == true)
        .map((e) => SubstituteTrainerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
