import 'package:flutter/material.dart';
import '../models/reading_model.dart';

class ReadingsList extends StatelessWidget {
  final List<ReadingModel> readings;
  final bool showMeterInfo;
  final VoidCallback? onRefresh;
  final Function(ReadingModel)? onTap;
  final String? title;

  const ReadingsList({
    Key? key,
    required this.readings,
    this.showMeterInfo = true,
    this.onRefresh,
    this.onTap,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (readings.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualiser',
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: readings.length,
            itemBuilder: (context, index) {
              final reading = readings[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => onTap?.call(reading),
                  title: Text('${reading.formattedValeur} � ${reading.source}'),
                  subtitle: Text(showMeterInfo
                      ? '${reading.compteurReference} � ${reading.formattedDate}'
                      : reading.formattedDate),
                  trailing: reading.consommationCalculee == null
                      ? null
                      : Text(reading.formattedConsommation),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun relev� trouv�',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class ReadingsSummary extends StatelessWidget {
  final List<ReadingModel> readings;
  final String title;

  const ReadingsSummary({
    Key? key,
    required this.readings,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();

    final totalReadings = readings.length;
    final manualReadings = readings.where((r) => r.isManuel).length;
    final espReadings = readings.where((r) => r.isEsp32Cam).length;
    final sensorReadings = readings.where((r) => r.isSensor).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text('Total des relev�s: $totalReadings'),
            Text('Manuel: $manualReadings'),
            Text('ESP32-CAM: $espReadings'),
            Text('Capteur: $sensorReadings'),
          ],
        ),
      ),
    );
  }
}
