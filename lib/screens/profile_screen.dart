import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/color.dart';
import '../widget/app_background.dart';
import '../utils/responsive.dart';
import '../blocs/auth/auth_bloc.dart';
import '../models/auth_models.dart';

/// شاشة الملف الشخصي
/// بتنفتح بـ Navigator.push من الدرج (مش تاب بالـ MainShell)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.characters.first;
    return '${parts[0].characters.first}${parts[1].characters.first}';
  }

  String _roleLabel(AuthUser user) {
    if (user.isAdmin) return 'أدمن';
    if (user.isTrainer) return 'مدرب رياضي';
    return user.roles.isNotEmpty ? user.roles.first : '—';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;

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
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'الملف الشخصي',
          style: TextStyle(color: Colors.white, fontSize: context.sp(18)),
        ),
      ),
      body: user == null
          ? const Center(child: Text('لا يوجد مستخدم مسجل دخوله'))
          : AppBackground(
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
                              _initials(user.fullName),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: context.sp(28),
                              ),
                            ),
                          ),
                          SizedBox(height: context.h(14)),
                          Text(
                            user.fullName.isNotEmpty
                                ? user.fullName
                                : 'بدون اسم',
                            style: TextStyle(
                              fontSize: context.sp(18),
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary3,
                            ),
                          ),
                          SizedBox(height: context.h(4)),
                          Text(
                            _roleLabel(user),
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
                              color: const Color(0xFFF6D9BB),
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

                    // ===== كارد المعلومات =====
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
                          _InfoRow(
                            label: 'البريد الإلكتروني',
                            value: user.email.isNotEmpty
                                ? user.email
                                : 'غير متوفر',
                          ),
                          _divider(context),
                          // TODO: رقم الهاتف وتاريخ الانضمام مش موجودين حالياً
                          // بالـ JWT ولا بأي endpoint - لما يصير عندنا مصدر
                          // (مثلاً GET /api/trainers/{id}) نضيفهم هون بنفس الشكل
                          const _InfoRow(
                            label: 'رقم الهاتف',
                            value: 'غير متوفر حالياً',
                          ),
                          _divider(context),
                          const _InfoRow(
                            label: 'تاريخ الانضمام',
                            value: 'غير متوفر حالياً',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.h(20)),

                    // ===== المدارس المسؤول عنها =====
                    // TODO: بحاجة endpoint يرجع المدارس المرتبطة بالمدرب
                    // (schedule-templates فيها schoolId، ممكن نبني منها
                    // لائحة مدارس فريدة لاحقاً لما نربط الجدول)
                    Text(
                      'المدارس المسؤول عنها',
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary3,
                      ),
                    ),
                    SizedBox(height: context.h(10)),
                    Text(
                      'غير متوفر حالياً',
                      style: TextStyle(
                        fontSize: context.sp(12.5),
                        color: AppColors.secondary3.withOpacity(0.6),
                      ),
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
