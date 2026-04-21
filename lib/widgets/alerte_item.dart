import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlerteItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isCompact;

  const AlerteItem({
    super.key,
    required this.data,
    this.isCompact = false,
  });

  IconData _getIcon() {
    switch (data['type']) {
      case 'urgent': return Icons.warning_rounded;
      case 'warning': return Icons.info_rounded;
      case 'success': return Icons.check_circle_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor() {
    switch (data['type']) {
      case 'urgent': return AppColors.alertRed;
      case 'warning': return AppColors.alertOrange;
      case 'success': return AppColors.alertGreen;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool lue = data['lue'] ?? false;
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
            color: Colors.black.withOpacity(0.04),
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
                color: color.withOpacity(0.1),
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
                          data['titre'],
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        data['heure'],
                        style: AppTextStyles.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['desc'],
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
