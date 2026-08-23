import 'package:flutter/material.dart';
import '../theme/color.dart';

class CheckInOutButtons extends StatelessWidget {
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final bool isCheckedIn; // لو تم تسجيل الحضور فعلاً اليوم

  const CheckInOutButtons({
    super.key,
    required this.onCheckIn,
    required this.onCheckOut,
    this.isCheckedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'تسجيل حضور',
            icon: Icons.login_rounded,
            color: AppColors.primary1,
            filled: !isCheckedIn,
            onTap: isCheckedIn ? null : onCheckIn,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'تسجيل انصراف',
            icon: Icons.logout_rounded,
            color: AppColors.secondary3,
            filled: isCheckedIn,
            onTap: isCheckedIn ? onCheckOut : null,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppColors.primary4
              : (filled ? color : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDisabled ? AppColors.primary4 : color,
            width: 1.6,
          ),
          boxShadow: (!isDisabled && filled)
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? AppColors.primary3
                  : (filled ? Colors.white : color),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDisabled
                    ? AppColors.primary3
                    : (filled ? Colors.white : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
