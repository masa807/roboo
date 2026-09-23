import 'package:flutter/material.dart';
import 'package:roboo_app/screens/home_screen.dart';
import 'package:roboo_app/screens/mainShell.dart';
import '../theme/color.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';

/// موديل بيانات البروفايل - استبدلها لاحقاً بالـ Provider / API
class ProfileData {
  final String fullName;
  final String role;
  final String email;
  final String phone;
  final String joinDate;
  final List<String> assignedSchools;

  const ProfileData({
    required this.fullName,
    required this.role,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.assignedSchools,
  });

  /// أول حرفين من الاسم (للأفاتار)
  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.characters.first;
    return '${parts[0].characters.first}${parts[1].characters.first}';
  }
}

/// شاشة الملف الشخصي
/// بتنفتح بـ Navigator.push من الدرج (مش تاب بالـ MainShell)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // بيانات تجريبية - استبدلها لاحقاً بالـ Provider / API
  static const ProfileData _profile = ProfileData(
    fullName: 'وسام خالد',
    role: 'مدرب رياضي',
    email: 'wissam.khaled@fioteam.com',
    phone: '233 112 0599',
    joinDate: 'يناير 2024',
    assignedSchools: [
      'مدرسة النور الدولية',
      'مدرسة الفارابي',
      'أكاديمية الرواد',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary1,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: context.r(24),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainShell()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'الملف الشخصي',
          style: TextStyle(color: Colors.white, fontSize: context.sp(18)),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.w(16),
              context.h(24),
              context.w(16),
              context.h(24),
            ),
            children: [
              // ===== الأفاتار + الاسم + الدور =====
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: context.r(44),
                      backgroundColor: AppColors.primary1,
                      child: Text(
                        _profile.initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.sp(28),
                        ),
                      ),
                    ),
                    SizedBox(height: context.h(14)),
                    Text(
                      _profile.fullName,
                      style: TextStyle(
                        fontSize: context.sp(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary3,
                      ),
                    ),
                    SizedBox(height: context.h(4)),
                    Text(
                      _profile.role,
                      style: TextStyle(
                        fontSize: context.sp(13),
                        color: AppColors.secondary3.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: context.h(10)),

                    // ---- بادج "بيانات يديرها الأدمن" ----
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(12),
                        vertical: context.h(6),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6D9BB), // برتقالي فاتح
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: context.r(13),
                            color: const Color(0xFF8A5A2B),
                          ),
                          SizedBox(width: context.w(6)),
                          Text(
                            'بيانات يديرها الأدمن',
                            style: TextStyle(
                              fontSize: context.sp(11.5),
                              color: const Color(0xFF8A5A2B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(24)),

              // ===== كارد المعلومات (إيميل / هاتف / تاريخ الانضمام) =====
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.r(14)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: context.r(10),
                      offset: Offset(0, context.h(3)),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'البريد الإلكتروني', value: _profile.email),
                    _divider(context),
                    _InfoRow(label: 'رقم الهاتف', value: _profile.phone),
                    _divider(context),
                    _InfoRow(label: 'تاريخ الانضمام', value: _profile.joinDate),
                  ],
                ),
              ),
              SizedBox(height: context.h(20)),

              // ===== المدارس المسؤول عنها =====
              Text(
                'المدارس المسؤول عنها',
                style: TextStyle(
                  fontSize: context.sp(14),
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary3,
                ),
              ),
              SizedBox(height: context.h(10)),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: context.w(8),
                runSpacing: context.h(8),
                children: _profile.assignedSchools
                    .map((school) => _SchoolChip(label: school))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.primary4,
      indent: context.w(16),
      endIndent: context.w(16),
    );
  }
}

// ==== صف معلومة واحدة (قيمة يسار / نص انكليزي - تسمية يمين عربي) ====
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(16),
        vertical: context.h(14),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: context.sp(13.5),
                fontWeight: FontWeight.w600,
                color: AppColors.secondary3,
              ),
            ),
            const Spacer(),
            Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: context.sp(13),
                color: AppColors.secondary3.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==== شيب اسم مدرسة ====
class _SchoolChip extends StatelessWidget {
  final String label;
  const _SchoolChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.w(14),
        vertical: context.h(8),
      ),
      decoration: BoxDecoration(
        color: AppColors.primary4,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: context.sp(12.5),
          color: AppColors.primary1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
