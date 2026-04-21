import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlerteCard extends StatelessWidget {
  final String type;
  final String titre;
  final String desc;
  final String heure;
  final bool lue;
  final bool mini;

  const AlerteCard({
    super.key,
    required this.type,
    required this.titre,
    required this.desc,
    required this.heure,
    required this.lue,
    this.mini = false,
  });

  Color _getColor() {
    switch (type) {
      case 'urgent': return AppColors.alertRed;
      case 'warning': return AppColors.alertOrange;
      case 'success': return AppColors.alertGreen;
      default: return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case 'urgent': return Icons.error_rounded;
      case 'warning': return Icons.warning_rounded;
      case 'success': return Icons.check_circle_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: mini ? 4 : 6),
      padding: EdgeInsets.all(mini ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: !lue ? Border(left: BorderSide(color: color, width: 4)) : null,
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            titre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          heure,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: mini ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!lue)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
