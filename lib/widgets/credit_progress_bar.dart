import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreditProgressBar extends StatelessWidget {
  final double value;

  const CreditProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (value > 0.5) {
      barColor = AppColors.alertGreen;
    } else if (value > 0.2) {
      barColor = AppColors.alertOrange;
    } else {
      barColor = AppColors.alertRed;
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}
