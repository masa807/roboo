import 'package:flutter/material.dart';
import '../theme/color.dart';

class SessionCard extends StatefulWidget {
  final String centerName;
  final String time;
  final bool initiallyChecked;
  final ValueChanged<bool>? onChanged;

  const SessionCard({
    super.key,
    required this.centerName,
    required this.time,
    this.initiallyChecked = false,
    this.onChanged,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.initiallyChecked;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _checked ? AppColors.primary1 : AppColors.primary4,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // أيقونة جانبية دلالة على مركز/مدرسة
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary4,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school_rounded,
              color: AppColors.primary1,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.centerName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary3,
                    decoration: _checked ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.secondary3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.primary3,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.time,
                      style: TextStyle(fontSize: 12, color: AppColors.primary3),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // تشيك بوكس دائري مخصص
          GestureDetector(
            onTap: () {
              setState(() => _checked = !_checked);
              widget.onChanged?.call(_checked);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _checked ? AppColors.primary1 : Colors.transparent,
                border: Border.all(
                  color: _checked ? AppColors.primary1 : AppColors.primary3,
                  width: 2,
                ),
              ),
              child: _checked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
