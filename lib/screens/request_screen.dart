import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../utils/responsive.dart';

/// محتوى تاب الطلبات فقط - بدون Scaffold/BottomNav خاص فيه
/// خليتها ترجع Column مباشرة (مش Scaffold) عشان تنحط جوا AppBackground
/// أو Scaffold وحيد بالـ MainShell بدون تعارض
class AbsenceRequestContent extends StatefulWidget {
  const AbsenceRequestContent({super.key});

  @override
  State<AbsenceRequestContent> createState() => _AbsenceRequestContentState();
}

class _AbsenceRequestContentState extends State<AbsenceRequestContent> {
  DateTime? selectedDate;
  String? selectedSlot;
  final TextEditingController reasonController = TextEditingController();

  final List<String> slots = ['لا توجد حصص متاحة هالنهار'];

  static const List<String> _arabicWeekDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  /// بيحسب اسم اليوم بالعربي تلقائياً من التاريخ المختار
  /// DateTime.weekday: الاثنين = 1 ... الأحد = 7
  String get _autoDayName {
    if (selectedDate == null) return '—';
    return _arabicWeekDays[selectedDate!.weekday - 1];
  }

  final List<Map<String, String>> trainers = [
    {'name': 'محمد سلامة', 'role': 'مدرب كرة قدم', 'initial': 'م'},
    {'name': 'ريم قدورة', 'role': 'مدربة سباحة', 'initial': 'ر'},
    {'name': 'خالد عيسى', 'role': 'مدرب كرة سلة', 'initial': 'خ'},
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 1),
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

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  String get _formattedDate {
    if (selectedDate == null) return 'اختر التاريخ';
    return '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    // ملاحظة: ما في Scaffold ولا AppBar هون نهائياً
    // الـ AppBar والـ Scaffold والـ BottomNav كلهم موجودين مرة وحدة بس بالـ MainShell
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: AppColors.primary4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequestCard(),
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
              ...trainers.map((t) => _buildTrainerCard(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard() {
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
          // حقل اليوم متولد تلقائياً من التاريخ - مش قابل للتعديل
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
          _buildDropdown(
            slots.first,
            slots,
            (val) => setState(() => selectedSlot = val),
          ),

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
                hintText: 'اكتب السبب هون...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // TODO: منطق إرسال الطلب
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0A75C), // برتقالي الزر
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
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

  Widget _buildDropdown(
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary4,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.secondary3),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTrainerCard(Map<String, String> trainer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary4,
            child: Text(
              trainer['initial']!,
              style: const TextStyle(
                color: AppColors.primary1,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainer['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary3,
                  ),
                ),
                Text(
                  trainer['role']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary1.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.phone, color: Colors.pink, size: 16),
                SizedBox(width: 6),
                Text(
                  'اتصال',
                  style: TextStyle(color: AppColors.primary1, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
