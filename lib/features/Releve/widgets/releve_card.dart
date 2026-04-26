import 'package:flutter/material.dart';
import '../models/releve.dart';

class ReleveCard extends StatelessWidget {
  final Releve releve;

  const ReleveCard({
    super.key,
    required this.releve,
  });

  @override
  Widget build(BuildContext context) {
    final isError = releve.statut == 'ERREUR';
    final isValid = releve.statut == 'VALIDE';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec date et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(releve.dateTime),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Source: ${releve.source}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.red[50]
                        : isValid
                            ? Colors.green[50]
                            : Colors.orange[50],
                    border: Border.all(
                      color: isError
                          ? Colors.red[200]!
                          : isValid
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    releve.statut,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isError
                          ? Colors.red[700]
                          : isValid
                              ? Colors.green[700]
                              : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Valeur et consommation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valeur',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${releve.valeur.toStringAsFixed(2)} kWh',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Consommation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${releve.consommationCalculee.toStringAsFixed(2)} kWh',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Commentaire si présent
            if (releve.commentaire != null && releve.commentaire!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    releve.commentaire!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayString;
    if (dateOnly == today) {
      dayString = 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      dayString = 'Hier';
    } else {
      dayString =
          '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }

    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    return '$dayString à $timeString';
  }
}