import 'package:flutter/material.dart';

/// خلفية فيها الشعار الباهت بس - مش Scaffold
/// كل شاشة/تاب بتحط الـ Scaffold تبعها هي، وبتلف الـ body بـ AppBackground
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Stack(
        children: [
          // الشعار الباهت بالمنتصف
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    'assets/images/logo_watermark.jpg',
                    width: 260,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          // المحتوى الفعلي فوق الشعار
          child,
        ],
      ),
    );
  }
}
