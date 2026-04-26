import 'package:flutter/material.dart';

class PreviousValueWidget extends StatelessWidget {
  final double? valeur;
  final String label;
  final String? unit;

  const PreviousValueWidget({
    super.key,
    required this.valeur,
    this.label = 'Dernière valeur enregistrée',
    this.unit = 'kWh',
  });

  @override
  Widget build(BuildContext context) {
    if (valeur == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
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
            '${valeur!.toStringAsFixed(2)} ${unit ?? ''}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}