import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum _SnackType { error, success, warning, info }

/// Snackbar unifié avec icône, couleur et style cohérent dans toute l'app.
///
/// Usage :
///   AppSnackbar.error(context, 'Message d'erreur');
///   AppSnackbar.success(context, 'Opération réussie');
class AppSnackbar {
  AppSnackbar._();

  static void error(BuildContext context, String message) =>
      _show(context, message, _SnackType.error);

  static void success(BuildContext context, String message) =>
      _show(context, message, _SnackType.success);

  static void warning(BuildContext context, String message) =>
      _show(context, message, _SnackType.warning);

  static void info(BuildContext context, String message) =>
      _show(context, message, _SnackType.info);

  /// Variante sans BuildContext — utilise un messenger pré-capturé avant un gap async.
  static void errorOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, _SnackType.error);

  static void successOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, _SnackType.success);

  static void warningOnMessenger(ScaffoldMessengerState m, String message) =>
      _showOnMessenger(m, message, _SnackType.warning);

  static void _show(BuildContext context, String message, _SnackType type) =>
      _showOnMessenger(ScaffoldMessenger.of(context), message, type);

  static void _showOnMessenger(
      ScaffoldMessengerState m, String message, _SnackType type) {
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: Duration(seconds: type == _SnackType.error ? 5 : 3),
        content: _SnackContent(message: message, type: type),
      ),
    );
  }
}

class _SnackContent extends StatelessWidget {
  final String message;
  final _SnackType type;

  const _SnackContent({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cfg.border),
        boxShadow: [
          BoxShadow(
            color: cfg.shadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cfg.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cfg.icon, color: cfg.iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cfg.title,
                  style: AppTextStyles.body.copyWith(
                    color: cfg.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.body.copyWith(
                    color: cfg.textColor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _SnackConfig _config(_SnackType t) => switch (t) {
        _SnackType.error => const _SnackConfig(
            bg: Color(0xFFFFF1F2),
            border: Color(0xFFFCA5A5),
            shadow: Color.fromRGBO(239, 68, 68, 0.14),
            iconBg: Color(0xFFFFE4E4),
            iconColor: AppColors.alertRed,
            textColor: Color(0xFF991B1B),
            icon: Icons.error_outline_rounded,
            title: 'Erreur',
          ),
        _SnackType.success => const _SnackConfig(
            bg: Color(0xFFF0FDF4),
            border: Color(0xFF86EFAC),
            shadow: Color.fromRGBO(16, 185, 129, 0.13),
            iconBg: Color(0xFFDCFCE7),
            iconColor: AppColors.alertGreen,
            textColor: Color(0xFF166534),
            icon: Icons.check_circle_outline_rounded,
            title: 'Succès',
          ),
        _SnackType.warning => const _SnackConfig(
            bg: Color(0xFFFFFBEB),
            border: Color(0xFFFDE68A),
            shadow: Color.fromRGBO(245, 158, 11, 0.13),
            iconBg: Color(0xFFFEF3C7),
            iconColor: AppColors.alertOrange,
            textColor: Color(0xFF92400E),
            icon: Icons.warning_amber_rounded,
            title: 'Attention',
          ),
        _SnackType.info => const _SnackConfig(
            bg: Color(0xFFEFF6FF),
            border: Color(0xFF93C5FD),
            shadow: Color.fromRGBO(37, 99, 235, 0.12),
            iconBg: Color(0xFFDBEAFE),
            iconColor: AppColors.primary,
            textColor: Color(0xFF1E40AF),
            icon: Icons.info_outline_rounded,
            title: 'Information',
          ),
      };
}

class _SnackConfig {
  final Color bg, border, shadow, iconBg, iconColor, textColor;
  final IconData icon;
  final String title;

  const _SnackConfig({
    required this.bg,
    required this.border,
    required this.shadow,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
    required this.icon,
    required this.title,
  });
}
