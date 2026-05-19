import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

  const StatChip({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final pad = (sw * 0.034).clamp(10.0, 16.0);
    final iconSize = (sw * 0.095).clamp(32.0, 44.0);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(pad),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: iconSize * 0.5),
            ),
            SizedBox(width: pad * 0.75),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.heading2.copyWith(
                        fontSize: (sw * 0.042).clamp(14.0, 18.0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: (sw * 0.026).clamp(9.0, 12.0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
