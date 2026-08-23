import 'package:flutter/material.dart';

/// أساس التصميم (مقاسات شاشة التصميم الأصلية - مثلاً iPhone 11 / شاشة قياسية)
const double _designWidth = 375;
const double _designHeight = 812;

/// Extension على BuildContext لتسهيل التعامل مع القياسات المتجاوبة
extension AppResponsive on BuildContext {
  /// عرض الشاشة الحالية
  double get screenWidth => MediaQuery.of(this).size.width;

  /// ارتفاع الشاشة الحالية
  double get screenHeight => MediaQuery.of(this).size.height;

  /// تحويل قيمة عرض بناءً على مقاس التصميم الأصلي (للـ padding, margin, width...)
  double w(double value) => (value / _designWidth) * screenWidth;

  /// تحويل قيمة ارتفاع بناءً على مقاس التصميم الأصلي (للـ height, vertical spacing...)
  double h(double value) => (value / _designHeight) * screenHeight;

  /// حجم خط متجاوب (يعتمد على أصغر بعد بالشاشة لضمان توازن أفضل)
  double sp(double value) {
    final scale = screenWidth / _designWidth;
    // نحد أقصى وأدنى نسبة تكبير حتى ما يصير الخط كبير كتير أو صغير كتير
    final clamped = scale.clamp(0.85, 1.25);
    return value * clamped;
  }

  /// نصف قطر متجاوب (border radius, icon size...)
  double r(double value) => w(value);
}
