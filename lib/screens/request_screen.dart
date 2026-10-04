import '../core/school_time.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/absence/absence_cubit.dart';
import '../blocs/absence/absence_state.dart';
import '../models/daily_checklist_model.dart';
import '../models/leave_request_model.dart';
import '../theme/color.dart';
import '../widget/app_dialoge.dart';

/// محتوى تاب الطلبات فقط - بدون Scaffold/BottomNav خاص فيه
class AbsenceRequestContent extends StatefulWidget {
  const AbsenceRequestContent({super.key});

  @override
  State<AbsenceRequestContent> createState() => _AbsenceRequestContentState();
}

class _AbsenceRequestContentState extends State<AbsenceRequestContent> {
  static const String _allDayValue = '__all_day__';

  DateTime? selectedDate;
  final TextEditingController reasonController = TextEditingController();

  // حصص اليوم المختار
  List<DailyChecklistItem> daySessions = [];
  bool loadingSessions = false;
  String? sessionsError;

  // _allDayValue = كل الحصص، أو sessionTrainerId لحصة وحدة
  String? selectedSessionValue;

  List<SubstituteTrainerModel> availableSubstitutes = [];
  String? selectedSubstituteId;
  bool loadingSubstitutes = false;
  int _substituteRequest = 0;

  static const List<String> _arabicWeekDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  String get _autoDayName {
    if (selectedDate == null) return '—';
    return _arabicWeekDays[selectedDate!.weekday - 1];
  }

  String get _formattedDate {
    if (selectedDate == null) return 'اختر التاريخ';
    return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
  }

  bool get _isAllDay => selectedSessionValue == _allDayValue;

  /// الـ ids اللي بنبعتها للـ API حسب اختيار الحصة
  List<String> get _selectedSessionIds {
    if (selectedSessionValue == null) return const [];
    if (_isAllDay) {
      return daySessions.map((s) => s.sessionTrainerId).toList();
    }
    return [selectedSessionValue!];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AbsenceCubit>().loadRequests();
    });
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = SchoolTime.now();
    final first = DateTime(now.year, now.month, now.day + 2);
    final last = DateTime(now.year, now.month, now.day + 15);
    final initial =
        selectedDate != null &&
            !selectedDate!.isBefore(first) &&
            !selectedDate!.isAfter(last)
        ? selectedDate!
        : first;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary1,
              onPrimary: Colors.white,
              onSurface: AppColors.secondary3,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );

    if (picked != null && mounted) {
      _substituteRequest++;
      setState(() {
        selectedDate = picked;
        selectedSubstituteId = null;
        availableSubstitutes = [];
        loadingSubstitutes = false;
        daySessions = [];
        selectedSessionValue = null;
        sessionsError = null;
      });
      await _loadSessionsForDate(picked);
    }
  }

  /// بيجيب حصص اليوم المختار ويعبّي فيها الـ dropdown
  Future<void> _loadSessionsForDate(DateTime date) async {
    setState(() => loadingSessions = true);
    try {
      final sessions = await context.read<AbsenceCubit>().loadSessionsForDate(
        date,
      );
      if (!mounted) return;
      // لو المستخدم غيّر التاريخ وإحنا بننتظر، نتجاهل النتيجة القديمة
      if (selectedDate != date) return;
      setState(() {
        daySessions = sessions
            .where(
              (s) =>
                  s.sessionStatus != DailySessionStatus.cancelled &&
                  !s.isCheckedIn,
            )
            .toList();
        loadingSessions = false;
        // اختيار افتراضي: كل الحصص إذا في حصص
        selectedSessionValue = daySessions.isEmpty ? null : _allDayValue;
      });
      if (sessions.isNotEmpty) _loadSubstitutesForSelection();
    } catch (_) {
      if (!mounted || selectedDate != date) return;
      setState(() {
        loadingSessions = false;
        sessionsError = 'حدث خطأ في جلب الحصص';
      });
    }
  }

  /// جلب البدلاء المتاحين للحصص المختارة.
  /// [keepSelection] = true: منحافظ على البديل المختار إذا لسا موجود بالقائمة
  /// الجديدة (بنستخدمها بعد فشل الإرسال)، وإلا بيتفك الاختيار.
  Future<void> _loadSubstitutesForSelection({
    bool keepSelection = false,
  }) async {
    final generation = ++_substituteRequest;
    final ids = _selectedSessionIds;
    if (ids.isEmpty) {
      setState(() {
        loadingSubstitutes = false;
        availableSubstitutes = [];
        selectedSubstituteId = null;
      });
      return;
    }

    final previousSelection = selectedSubstituteId; // جديد

    setState(() {
      loadingSubstitutes = true;
      sessionsError = null;
      if (!keepSelection) selectedSubstituteId = null; // جديد
    });
    try {
      final result = await context
          .read<AbsenceCubit>()
          .loadAvailableSubstitutes(ids);
      if (!mounted || generation != _substituteRequest) return;
      setState(() {
        availableSubstitutes = result;
        loadingSubstitutes = false;
        // جديد: لو البديل المختار ما عاد بالقائمة (صار معطّل) منفك اختياره
        if (keepSelection && !result.any((t) => t.id == previousSelection)) {
          selectedSubstituteId = null;
        }
      });
    } catch (_) {
      if (!mounted || generation != _substituteRequest) return;
      setState(() {
        loadingSubstitutes = false;
        availableSubstitutes = [];
        selectedSubstituteId = null;
        sessionsError = 'تعذر جلب البدلاء، أعد اختيار الحصة للمحاولة.';
      });
    }
  }

  void _showMissingDataDialog(String message) {
    showInfoDialog(
      context: context,
      title: 'الرجاء استكمال البيانات',
      message: message,
    );
  }

  /// 1) تحقق من الحقول  2) حوار تأكيد  3) الإرسال الفعلي (_sendRequest)
  void _submit() {
    if (loadingSessions || loadingSubstitutes) return;
    if (selectedSubstituteId == null) {
      _showMissingDataDialog('يرجى اختيار المدرب البديل.');
      return;
    }
    final now = SchoolTime.now();
    final chosen = daySessions.where(
      (s) => _selectedSessionIds.contains(s.sessionTrainerId),
    );
    if (chosen.any((s) {
      final start = SchoolTime.sessionStart(s.date, s.startTime);
      return start.difference(now) < const Duration(hours: 48) ||
          start.difference(now) > const Duration(days: 15);
    })) {
      _showMissingDataDialog(
        'يجب تقديم الطلب قبل الحصة بـ48 ساعة على الأقل، و15 يومًا على الأكثر.',
      );
      return;
    }
    if (selectedDate == null) {
      _showMissingDataDialog('الرجاء اختيار التاريخ');
      return;
    }
    if (selectedSessionValue == null) {
      _showMissingDataDialog('لا يوجد حصص في هذا التاريخ');
      return;
    }
    if (reasonController.text.trim().isEmpty) {
      _showMissingDataDialog('الرجاء كتابة سبب الغياب');
      return;
    }

    showConfirmDialog(
      context: context,
      title: 'تأكيد إرسال الطلب',
      message: 'هل تريد إرسال طلب الغياب بتاريخ $_formattedDate؟',
      confirmText: 'إرسال',
      cancelText: 'مراجعة',
      onConfirm: _sendRequest,
    );
  }

  Future<void> _sendRequest() async {
    final success = await context.read<AbsenceCubit>().submitRequest(
      reason: reasonController.text.trim(),
      // إذا اختار "كل الحصص" بنبعت fullDay، وإلا حصص محددة
      // ⚠️ تأكد من اسم القيمة الثانية بالـ enum عندك
      selectionMode: _isAllDay
          ? LeaveSelectionMode.fullDay
          : LeaveSelectionMode.specificSessions,
      targetDate: selectedDate,
      sessionTrainerIds: _isAllDay ? const [] : _selectedSessionIds,
      proposedSubstituteTrainerId: selectedSubstituteId,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        selectedDate = null;
        selectedSubstituteId = null;
        selectedSessionValue = null;
        availableSubstitutes = [];
        daySessions = [];
        reasonController.clear();
      });
      showSuccessDialog(
        context: context,
        title: 'تم إرسال الطلب',
        message: 'تم إرسال طلب الغياب بنجاح، وسيتم إشعارك عند مراجعته',
      );
    } else {
      // جديد: لو كان في بديل مختار، منحدّث قائمة البدلاء (ممكن يكون صار معطّل)
      if (selectedSubstituteId != null) {
        _loadSubstitutesForSelection(keepSelection: true);
      }

      final error = context.read<AbsenceCubit>().state.actionError;
      showErrorDialog(
        context: context,
        title: 'تعذر إرسال الطلب',
        message: error ?? 'حدث خطأ أثناء إرسال الطلب',
      );
    }
  }

  /// حوار تأكيد قبل إلغاء طلب معلّق
  void _confirmCancel(String requestId) {
    showDeleteDialog(
      context: context,
      title: 'إلغاء الطلب',
      message: 'هل تريد إلغاء طلب الغياب هذا؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmText: 'نعم، ألغِ الطلب',
      cancelText: 'لا، تراجع',
      onConfirm: () => _cancelRequest(requestId),
    );
  }

  Future<void> _cancelRequest(String requestId) async {
    final success = await context.read<AbsenceCubit>().cancelRequest(requestId);
    if (!mounted) return;

    if (success) {
      showSuccessDialog(
        context: context,
        title: 'تم الإلغاء',
        message: 'تم إلغاء طلب الغياب بنجاح',
      );
    } else {
      final error = context.read<AbsenceCubit>().state.actionError;
      showErrorDialog(
        context: context,
        title: 'تعذر إلغاء الطلب',
        message: error ?? 'حدث خطأ أثناء إلغاء الطلب',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.primary4,
        child: BlocBuilder<AbsenceCubit, AbsenceState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestCard(state),
                  const SizedBox(height: 24),
                  const Text(
                    'مدربين متاحين للتبديل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSubstitutesList(),
                  const SizedBox(height: 24),
                  const Text(
                    'طلباتي السابقة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRequestsList(state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubstitutesList() {
    if (loadingSubstitutes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (selectedDate == null) {
      return const Text(
        'الرجاء اختيار التاريخ أولاً لعرض المدربين المتاحين',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    if (availableSubstitutes.isEmpty) {
      return const Text(
        'لا يوجد مدربين بدلاء متاحين لهذا التاريخ',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    return Column(
      children: availableSubstitutes.map((t) => _buildTrainerCard(t)).toList(),
    );
  }

  Widget _buildRequestsList(AbsenceState state) {
    if (state.status == AbsenceStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (state.status == AbsenceStatus.error) {
      return Text(
        state.errorMessage ?? 'حدث خطأ أثناء تحميل الطلبات',
        style: const TextStyle(color: Colors.red, fontSize: 13),
      );
    }
    if (state.requests.isEmpty) {
      return const Text(
        'لا يوجد طلبات غياب سابقة',
        style: TextStyle(color: Colors.grey, fontSize: 13),
      );
    }
    return Column(
      children: [
        ...state.requests.map((r) => _buildRequestHistoryCard(r)),
        if (state.hasMore)
          TextButton(
            onPressed: state.loadingMore
                ? null
                : () => context.read<AbsenceCubit>().loadMore(),
            child: Text(state.loadingMore ? 'جار التحميل…' : 'تحميل المزيد'),
          ),
      ],
    );
  }

  Widget _buildRequestHistoryCard(LeaveRequestModel r) {
    Color statusColor;
    switch (r.status) {
      case LeaveRequestStatus.approved:
        statusColor = Colors.green;
        break;
      case LeaveRequestStatus.rejected:
        statusColor = Colors.red;
        break;
      case LeaveRequestStatus.cancelled:
      case LeaveRequestStatus.unknown:
        statusColor = Colors.grey;
        break;
      case LeaveRequestStatus.pending:
        statusColor = Colors.orange;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary3,
                  ),
                ),
                if (r.targetDate != null)
                  Text(
                    '${r.targetDate!.day}/${r.targetDate!.month}/${r.targetDate!.year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.status.label,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (r.status == LeaveRequestStatus.pending) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _confirmCancel(r.id),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(AbsenceState state) {
    final isSubmitting = state.actionStatus == AbsenceActionStatus.submitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تقديم طلب غياب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary3,
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('التاريخ'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary4,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.primary1,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      color: AppColors.secondary3,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _buildLabel('اليوم'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color: AppColors.primary1,
                ),
                const SizedBox(width: 8),
                Text(
                  _autoDayName,
                  style: const TextStyle(
                    color: AppColors.secondary3,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildLabel('الحصة'),
          _buildSessionsDropdown(),

          const SizedBox(height: 16),
          _buildLabel('سبب الغياب'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: reasonController,
              maxLines: 3,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
                hintText: 'الرجاء كتابة السبب',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0A75C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'إرسال الطلب',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.secondary3),
      ),
    );
  }

  /// Dropdown الحصص: بيعرض حالة (اختاري تاريخ / تحميل / خطأ / لا حصص) أو الحصص الفعلية
  Widget _buildSessionsDropdown() {
    String? hint;
    if (selectedDate == null) {
      hint = 'الرجاء اختيار التاريخ أولاً';
    } else if (loadingSessions) {
      hint = 'جاري تحميل الحصص...';
    } else if (sessionsError != null) {
      hint = sessionsError;
    } else if (daySessions.isEmpty) {
      hint = 'لا يوجد حصص متاحة لهذا اليوم';
    }

    final items = <DropdownMenuItem<String>>[];
    if (hint == null) {
      items.add(
        const DropdownMenuItem(
          value: _allDayValue,
          child: Text(
            'كل حصص اليوم',
            style: TextStyle(
              color: AppColors.secondary3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (final s in daySessions) {
        items.add(
          DropdownMenuItem(
            value: s.sessionTrainerId,
            child: Text(
              '${s.subjectName} • ${s.displayTimeRange}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.secondary3),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hint == null ? selectedSessionValue : null,
          isExpanded: true,
          icon: loadingSessions
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.keyboard_arrow_down),
          hint: Text(
            hint ?? 'الرجاء اختيار الحصة',
            style: const TextStyle(color: AppColors.secondary3),
          ),
          items: items,
          // null = الـ dropdown معطّل
          onChanged: hint != null
              ? null
              : (val) {
                  setState(() => selectedSessionValue = val);
                  _loadSubstitutesForSelection();
                },
        ),
      ),
    );
  }

  Widget _buildTrainerCard(SubstituteTrainerModel trainer) {
    final isSelected = selectedSubstituteId == trainer.id;
    final initial = trainer.name.isNotEmpty ? trainer.name[0] : '؟';

    return InkWell(
      onTap: () => setState(() => selectedSubstituteId = trainer.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primary1, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary4,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary1,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                trainer.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary3,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary1),
          ],
        ),
      ),
    );
  }
}
