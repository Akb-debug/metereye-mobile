import 'package:flutter/material.dart';
import '../models/meter_model.dart';
import '../models/reading_model.dart';

class MeterCard extends StatelessWidget {
  final MeterModel meter;
  final ReadingModel? dernierReleve;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onRecharge;
  final VoidCallback? onDetails;

  const MeterCard({
    Key? key,
    required this.meter,
    this.dernierReleve,
    this.onTap,
    this.showActions = false,
    this.onRecharge,
    this.onDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCashPower = meter.isCashPower;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meter.reference,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meter.adresse,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildTypeBadge(isCashPower, theme),
                      const SizedBox(height: 4),
                      _buildStatusBadge(theme),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCashPower
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCashPower ? Icons.bolt : Icons.electrical_services,
                      color: isCashPower ? Colors.blue : Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCashPower ? 'Crédit restant' : 'Index actuel',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            meter.formattedValeur,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCashPower ? Colors.blue : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (meter.modeLectureConfigure != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Mode: ${meter.modeLectureConfigure}'),
                    avatar: const Icon(Icons.tune, size: 18),
                  ),
                ),
              ],
              if (dernierReleve != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dernier relevé: ${dernierReleve!.formattedDate}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getSourceColor(dernierReleve!.source).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dernierReleve!.source,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getSourceColor(dernierReleve!.source),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isCashPower && onRecharge != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onRecharge,
                          icon: const Icon(Icons.add_circle, size: 18),
                          label: const Text('Recharger'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (isCashPower && onRecharge != null && onDetails != null)
                      const SizedBox(width: 8),
                    if (onDetails != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDetails,
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Détails'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isCashPower, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCashPower ? Colors.blue.withOpacity(0.2) : Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCashPower ? 'CASH POWER' : 'CLASSIQUE',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isCashPower ? Colors.blue : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final String text;
    final Color color;

    if (meter.isPendingConfiguration) {
      text = 'À CONFIGURER';
      color = Colors.orange;
    } else if (meter.actif) {
      text = meter.statut;
      color = Colors.green;
    } else {
      text = meter.statut;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toUpperCase()) {
      case 'MANUEL':
      case 'MANUAL':
        return Colors.orange;
      case 'ESP32_CAM':
      case 'OCR':
        return Colors.purple;
      case 'SENSOR':
      case 'AUTOMATIQUE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
