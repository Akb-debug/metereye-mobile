import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/reading_model.dart';
import '../models/consumption_stats_model.dart';

class ConsumptionChart extends StatelessWidget {
  final List<ReadingModel> readings;
  final ConsumptionStatsModel? stats;
  final String title;
  final bool showConsumption;
  final double? height;

  const ConsumptionChart({
    Key? key,
    required this.readings,
    this.stats,
    this.title = 'Évolution de la consommation',
    this.showConsumption = true,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (readings.isEmpty && (stats?.consommationParJour?.isEmpty ?? true)) {
      return _buildEmptyState(theme);
    }

    return Container(
      height: height ?? 250,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée disponible',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    // Utiliser les données de stats si disponibles, sinon les readings
    final useStatsData = stats?.consommationParJour != null && 
                        stats!.consommationParJour!.isNotEmpty;
    
    if (useStatsData) {
      return _buildStatsChart(theme);
    } else {
      return _buildReadingsChart(theme);
    }
  }

  Widget _buildStatsChart(ThemeData theme) {
    final sortedEntries = stats!.getConsommationParJourTriee?.entries.toList() ?? [];
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateHorizontalInterval(sortedEntries),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateBottomInterval(sortedEntries.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedEntries.length) return const Text('');
                final date = sortedEntries[index].key;
                return _buildDateLabel(date, theme);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return _buildValueLabel(value, theme);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedEntries.length - 1).toDouble(),
        minY: 0,
        maxY: _calculateMaxY(sortedEntries),
        lineBarsData: [
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.primaryColor.withOpacity(0.4),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.3),
                  theme.primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsChart(ThemeData theme) {
    final sortedReadings = List<ReadingModel>.from(readings)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateHorizontalIntervalForReadings(sortedReadings),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateBottomInterval(sortedReadings.length),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedReadings.length) return const Text('');
                final date = sortedReadings[index].dateTime;
                return _buildDateTimeLabel(date, theme);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return _buildValueLabel(value, theme);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedReadings.length - 1).toDouble(),
        minY: 0,
        maxY: _calculateMaxYForReadings(sortedReadings),
        lineBarsData: [
          LineChartBarData(
            spots: sortedReadings.asMap().entries.map((entry) {
              final value = showConsumption && entry.value.consommationCalculee != null
                  ? entry.value.consommationCalculee!
                  : entry.value.valeur;
              return FlSpot(entry.key.toDouble(), value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.8),
                theme.primaryColor.withOpacity(0.4),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: theme.primaryColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.3),
                  theme.primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateLabel(String dateStr, ThemeData theme) {
    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        final day = parts[2];
        final month = parts[1];
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$day/$month',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        );
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
    return const SizedBox.shrink();
  }

  Widget _buildDateTimeLabel(DateTime dateTime, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '${dateTime.day}/${dateTime.month}',
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
      ),
    );
  }

  Widget _buildValueLabel(double value, ThemeData theme) {
    return Text(
      value.toStringAsFixed(0),
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
    );
  }

  double _calculateHorizontalInterval(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return 1.0;
    final values = entries.map((e) => e.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue / 5;
  }

  double _calculateHorizontalIntervalForReadings(List<ReadingModel> readings) {
    if (readings.isEmpty) return 1.0;
    final values = readings.map((r) => r.valeur).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue / 5;
  }

  double _calculateBottomInterval(int length) {
    if (length <= 7) return 1.0;
    if (length <= 14) return 2.0;
    if (length <= 30) return 5.0;
    return 10.0;
  }

  double _calculateMaxY(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return 10.0;
    final values = entries.map((e) => e.value).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2;
  }

  double _calculateMaxYForReadings(List<ReadingModel> readings) {
    if (readings.isEmpty) return 10.0;
    final values = readings.map((r) => r.valeur).toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.2;
  }
}
