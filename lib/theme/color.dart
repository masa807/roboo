import 'package:flutter/material.dart';

/// جميع ألوان التطبيق بمكان واحد
class AppColors {
  AppColors._();

  // الألوان الأساسية (Primary)
  static const Color primary1 = Color(0xFF007E91);
  static const Color primary2 = Color(0xFF6BBBC0);
  static const Color primary3 = Color(0xFF76AAAD);
  static const Color primary4 = Color(0xFFEDEDED);

  // الألوان الثانوية (Secondary)
  static const Color secondary1 = Color(0xFFB2D7A7);
  static const Color secondary2 = Color(0xFFFAFFE3);
  static const Color secondary3 = Color(0xFF6D5D6E);
  static const Color secondary4 = Color(0xFFF3EDDF);

  // ألوان الحالة
  static const Color errorColor = Color(0xFFD32F2F);

  // ظل الكروت
  static Color cardShadow = Colors.black.withOpacity(0.06);
}
