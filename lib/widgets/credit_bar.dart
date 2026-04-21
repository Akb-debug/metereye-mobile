import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreditBar extends StatelessWidget {
  final double value; // 0.0 to 1.0

  const CreditBar({super.key, required this.value});

  Color get barColor {
    if (value > 0.5) return AppColors.secondary;
    if (value > 0.2) return AppColors.alertOrange;
    return AppColors.alertRed;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: barColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
