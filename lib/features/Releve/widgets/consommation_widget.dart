import 'package:flutter/material.dart';

class ConsommationWidget extends StatelessWidget {
  final double? consommation;
  final String label;
  final String? unit;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;

  const ConsommationWidget({
    super.key,
    required this.consommation,
    this.label = 'Consommation calculée',
    this.unit = 'kWh',
    this.backgroundColor,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (consommation == null) {
      return const SizedBox.shrink();
    }

    final bgColor = backgroundColor ?? Colors.green[50];
    final brColor = borderColor ?? Colors.green[200];
    final txtColor = textColor ?? Colors.green;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: brColor!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${consommation!.toStringAsFixed(2)} ${unit ?? ''}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}