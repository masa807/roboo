import 'package:flutter/material.dart';
import '../theme/color.dart';

/// ─────────────────────────────────────────────────────────────
/// app_dialogs.dart  —  حوارات جاهزة لتطبيق AttendEase
/// - بدون أي package خارجي (Flutter فقط)
/// - بتتبع اتجاه التطبيق (RTL) وخط الـ Theme تلقائياً
/// - ما فيها اعتماد على أي Bloc: الإجراءات كلها بتيجي كـ callbacks
/// المسار: lib/widget/app_dialogs.dart
/// ─────────────────────────────────────────────────────────────

enum AppDialogType { success, error, warning, info, question }

class _DialogStyle {
  final IconData icon;
  final Color color;
  const _DialogStyle(this.icon, this.color);
}

_DialogStyle _styleOf(BuildContext context, AppDialogType type) {
  switch (type) {
    case AppDialogType.success:
      return const _DialogStyle(Icons.check_circle_rounded, Color(0xFF2E7D32));
    case AppDialogType.error:
      return _DialogStyle(Icons.error_rounded, AppColors.errorColor);
    case AppDialogType.warning:
      return _DialogStyle(Icons.warning_rounded, AppColors.errorColor);
    case AppDialogType.info:
      return _DialogStyle(Icons.info_rounded, AppColors.primary1);
    case AppDialogType.question:
      return _DialogStyle(Icons.help_rounded, AppColors.primary1);
  }
}

// ───────────────────────── الأساس المشترك ─────────────────────────

Future<T?> _showAnimatedDialog<T>(
  BuildContext context,
  Widget child, {
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'dialog',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (_, animation, __, page) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: page,
        ),
      );
    },
  );
}

class _AppDialog extends StatelessWidget {
  final AppDialogType type;
  final String title;
  final String message;
  final String primaryText;
  final VoidCallback? onPrimary;
  final String? secondaryText;
  final VoidCallback? onSecondary;
  final Color? primaryColor;

  const _AppDialog({
    required this.type,
    required this.title,
    required this.message,
    required this.primaryText,
    this.onPrimary,
    this.secondaryText,
    this.onSecondary,
    this.primaryColor,
  });

  void _close(BuildContext context, VoidCallback? action) {
    Navigator.of(context, rootNavigator: true).pop();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleOf(context, type);
    final btnColor = primaryColor ?? style.color;
    final width = MediaQuery.of(context).size.width;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width * 0.86,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 38),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  if (secondaryText != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _close(context, onSecondary),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(secondaryText!),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _close(context, onPrimary),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(primaryText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── الحوارات الجاهزة ─────────────────────────

/// رسالة نجاح
Future<void> showSuccessDialog({
  required BuildContext context,
  required String message,
  String title = 'تمت العملية بنجاح',
  String okText = 'حسناً',
  VoidCallback? onOk,
}) {
  if (!context.mounted) return Future.value();
  return _showAnimatedDialog(
    context,
    _AppDialog(
      type: AppDialogType.success,
      title: title,
      message: message,
      primaryText: okText,
      onPrimary: onOk,
    ),
  );
}

/// رسالة خطأ
Future<void> showErrorDialog({
  required BuildContext context,
  required String message,
  String title = 'حدث خطأ',
  String okText = 'حسناً',
  VoidCallback? onOk,
}) {
  if (!context.mounted) return Future.value();
  return _showAnimatedDialog(
    context,
    _AppDialog(
      type: AppDialogType.error,
      title: title,
      message: message,
      primaryText: okText,
      onPrimary: onOk,
    ),
  );
}

/// رسالة معلومات
Future<void> showInfoDialog({
  required BuildContext context,
  required String message,
  String title = 'تنبيه',
  String okText = 'حسناً',
  VoidCallback? onOk,
}) {
  if (!context.mounted) return Future.value();
  return _showAnimatedDialog(
    context,
    _AppDialog(
      type: AppDialogType.info,
      title: title,
      message: message,
      primaryText: okText,
      onPrimary: onOk,
    ),
  );
}

/// حوار تأكيد عام (نعم / لا)
Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
  String confirmText = 'تأكيد',
  String cancelText = 'إلغاء',
  AppDialogType type = AppDialogType.question,
  Color? confirmColor,
}) {
  if (!context.mounted) return Future.value();
  return _showAnimatedDialog(
    context,
    _AppDialog(
      type: type,
      title: title,
      message: message,
      primaryText: confirmText,
      onPrimary: onConfirm,
      secondaryText: cancelText,
      onSecondary: onCancel,
      primaryColor: confirmColor,
    ),
  );
}

/// تأكيد تسجيل الخروج — نفّذ الـ logout الفعلي داخل onConfirm
/// مثال: onConfirm: () => context.read<AuthBloc>().add(...)
Future<void> showLogoutDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  return showConfirmDialog(
    context: context,
    title: 'تسجيل الخروج',
    message:
        'هل أنت متأكد أنك تريد تسجيل الخروج؟ ستحتاج لتسجيل الدخول مرة أخرى للوصول إلى بياناتك.',
    confirmText: 'تسجيل الخروج',
    cancelText: 'إلغاء',
    type: AppDialogType.warning,
    onConfirm: onConfirm,
  );
}

/// تأكيد حذف (لون أحمر)
Future<void> showDeleteDialog({
  required BuildContext context,
  required VoidCallback onConfirm,
  String title = 'تأكيد الحذف',
  String message = 'هل تريد فعلاً الحذف؟ لا يمكن التراجع عن هذا الإجراء.',
  String confirmText = 'نعم، احذف',
  String cancelText = 'لا، تراجع',
}) {
  return showConfirmDialog(
    context: context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
    type: AppDialogType.error,
    onConfirm: onConfirm,
  );
}

// ───────────────────────── حوار التحميل ─────────────────────────

/// اعرضه قبل الطلب، وأغلقه بـ hideLoadingDialog(context) بعد ما يخلص
Future<void> showLoadingDialog({
  required BuildContext context,
  String message = 'جاري التحميل...',
}) {
  if (!context.mounted) return Future.value();
  return _showAnimatedDialog(
    context,
    PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary1),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

void hideLoadingDialog(BuildContext context) {
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pop();
}
