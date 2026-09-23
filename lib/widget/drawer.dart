import 'package:flutter/material.dart';
import '../theme/color.dart';
import '../utils/responsive.dart';

/// الدرج الجانبي (Drawer) - نفس هوية التطبيق
/// بيتحكم فيه من MainShell عبر currentIndex + onSelect
class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onLogout;
  final VoidCallback? onProfile;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    this.onLogout,
    this.onProfile,
  });

  static const List<_DrawerItemData> _items = [
    _DrawerItemData(icon: Icons.home_rounded, label: 'الرئيسية', index: 0),
    _DrawerItemData(icon: Icons.table_chart_rounded, label: 'الجدول', index: 1),
    _DrawerItemData(icon: Icons.assignment_rounded, label: 'الطلبات', index: 2),
    _DrawerItemData(
      icon: Icons.bar_chart_rounded,
      label: 'الاحصائيات',
      index: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== هيدر الدرج: صورة المستخدم + الاسم =====
            // ملاحظة: SafeArea(top: false) عشان التدرج يمتد تحت شريط الحالة
            // وما يبين أبيض فوق
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                context.w(20),
                context.h(20), // بيتضاف عليها ارتفاع شريط الحالة تلقائياً
                context.w(20),
                context.h(24),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary1, AppColors.primary2],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: context.r(32),
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: context.r(34),
                        color: AppColors.primary1,
                      ),
                    ),
                    SizedBox(height: context.h(12)),
                    Text(
                      'محمد سلامة', // TODO: اربطه لاحقاً بالـ Provider / بيانات المستخدم
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: context.sp(16),
                      ),
                    ),
                    SizedBox(height: context.h(2)),
                    Text(
                      'مدرب كرة قدم', // TODO: نفس الشي
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: context.sp(12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.h(8)),

            // ===== عناصر التنقل الرئيسية =====
            ..._items.map(
              (item) => _DrawerTile(
                data: item,
                isSelected: currentIndex == item.index,
                onTap: () {
                  Navigator.pop(context); // سكر الدرج
                  onSelect(item.index);
                },
              ),
            ),

            // ===== زر البروفايل - تحت الاحصائيات مباشرة =====
            _DrawerTile(
              data: const _DrawerItemData(
                icon: Icons.person_outline_rounded,
                label: 'الملف الشخصي',
                index: -1, // مش تاب، مجرد صفحة بتنفتح لحالها
              ),
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                onProfile?.call();
              },
            ),

            const Spacer(),
            Divider(height: 1, color: AppColors.primary4),

            // ===== تسجيل الخروج =====
            SafeArea(
              top: false,
              child: _SimpleTile(
                icon: Icons.logout_rounded,
                label: 'تسجيل الخروج',
                iconColor: AppColors.errorColor,
                textColor: AppColors.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  onLogout?.call();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  final IconData icon;
  final String label;
  final int index;
  const _DrawerItemData({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _DrawerTile extends StatelessWidget {
  final _DrawerItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.w(10),
        vertical: context.h(3),
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary4 : Colors.transparent,
        borderRadius: BorderRadius.circular(context.r(12)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(12)),
        ),
        leading: Icon(
          data.icon,
          color: isSelected ? AppColors.primary1 : AppColors.secondary3,
          size: context.r(22),
        ),
        title: Text(
          data.label,
          style: TextStyle(
            color: isSelected ? AppColors.primary1 : AppColors.secondary3,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: context.sp(14),
          ),
        ),
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SimpleTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.secondary3,
        size: context.r(22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? AppColors.secondary3,
          fontSize: context.sp(14),
        ),
      ),
    );
  }
}
