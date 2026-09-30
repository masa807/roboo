import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/stats_model.dart';
import '../../repositories/stats_repository.dart';

class StatsState {
  final DateTime month;
  final bool isLoading;
  final String? error;
  final List<SchoolSessionStat> schools;

  const StatsState({
    required this.month,
    this.isLoading = false,
    this.error,
    this.schools = const [],
  });

  factory StatsState.initial() {
    final now = DateTime.now();
    return StatsState(month: DateTime(now.year, now.month, 1));
  }

  int get total => schools.fold(0, (sum, s) => sum + s.sessionsCount);

  int get maxSessions => schools.isEmpty
      ? 1
      : schools.map((s) => s.sessionsCount).reduce((a, b) => a > b ? a : b);

  bool get isCurrentMonth {
    final now = DateTime.now();
    return month.year == now.year && month.month == now.month;
  }
}

class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._repo, {required this.trainerId})
    : super(StatsState.initial());

  final StatsRepository _repo;
  final String trainerId;

  final Map<String, List<SchoolSessionStat>> _cache = {};
  int _requestId = 0; // لتجاهل الردود القديمة إذا تنقل المستخدم بسرعة

  String _key(DateTime m) => '${m.year}-${m.month}';

  Future<void> load() => _loadMonth(state.month);

  Future<void> nextMonth() {
    if (state.isCurrentMonth) return Future.value();
    return _loadMonth(DateTime(state.month.year, state.month.month + 1, 1));
  }

  Future<void> prevMonth() =>
      _loadMonth(DateTime(state.month.year, state.month.month - 1, 1));

  /// سحب للتحديث: بيتجاهل الكاش للشهر المعروض
  Future<void> refresh() {
    _cache.remove(_key(state.month));
    return _loadMonth(state.month);
  }

  Future<void> _loadMonth(DateTime month) async {
    final id = ++_requestId;
    final cached = _cache[_key(month)];

    if (cached != null) {
      emit(StatsState(month: month, schools: cached));
      return;
    }

    emit(StatsState(month: month, isLoading: true));

    try {
      final schools = await _repo.getMonthlySchoolStats(
        trainerId: trainerId,
        month: month,
      );
      if (id != _requestId) return;
      _cache[_key(month)] = schools;
      emit(StatsState(month: month, schools: schools));
    } catch (e) {
      if (id != _requestId) return;
      emit(StatsState(month: month, error: 'تعذّر تحميل الإحصائيات'));
    }
  }
}
