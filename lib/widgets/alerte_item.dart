// 🔄 MODIFIÉ — alerte_item.dart — source de données : Map<String,dynamic> → AlerteModel
//              Rendu visuel inchangé au pixel près

import 'package:flutter/material.dart';
import '../features/alertes/models/alerte_model.dart';
import '../theme/app_theme.dart';

class AlerteItem extends StatelessWidget {
  final AlerteModel alerte;
  final bool isCompact;

  const AlerteItem({
    super.key,
    required this.alerte,
    this.isCompact = false,
  });

  IconData _getIcon() {
    switch (alerte.type) {
      case 'urgent':
        return Icons.warning_rounded;
      case 'warning':
        return Icons.info_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor() {
    switch (alerte.type) {
      case 'urgent':
        return AppColors.alertRed;
      case 'warning':
        return AppColors.alertOrange;
      case 'success':
        return AppColors.alertGreen;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool lue = alerte.lue;
    final Color color = _getColor();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 0 : 16,
        vertical: isCompact ? 6 : 5,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: !lue && !isCompact
            ? Border(left: BorderSide(color: color, width: 4))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Opacity(
        opacity: lue ? 0.7 : 1.0,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alerte.titre,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        alerte.heureFormatted,
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerte.message,
                    style: AppTextStyles.caption.copyWith(height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!lue && !isCompact)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
