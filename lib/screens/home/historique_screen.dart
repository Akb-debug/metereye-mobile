import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/section_title.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/historique_provider.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  DashboardProvider? _dashboardProvider;
  int? _loadedCompteurId;

  void _onDashboardChange() {
    if (!mounted) return;
    final compteurId = _dashboardProvider?.compteurActif?.id;
    if (compteurId != null && compteurId != _loadedCompteurId) {
      _loadedCompteurId = compteurId;
      context.read<HistoriqueProvider>().loadHistorique(compteurId);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dashboardProvider = context.read<DashboardProvider>();
      _dashboardProvider!.addListener(_onDashboardChange);
      _onDashboardChange();
    });
  }

  @override
  void dispose() {
    _dashboardProvider?.removeListener(_onDashboardChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoriqueProvider>(
      builder: (context, historique, _) {
        final compteurId =
            context.read<DashboardProvider>().compteurActif?.id ?? 0;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Historique'),
            backgroundColor: AppColors.background,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPeriodSelector(historique, compteurId),
                    _buildSummaryCard(historique),
                    _buildLineChart(historique),
                    _buildAIAnalysis(),
                    _buildLastLectures(historique),
                    if (historique.error != null)
                      _buildErrorBanner(historique, compteurId),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(HistoriqueProvider historique, int compteurId) {
    final periods = ['7 jours', '30 jours', '3 mois'];
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
      child: Row(
        children: periods.map((p) {
          final isSelected = historique.selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p),
              selected: isSelected,
              onSelected: (val) {
                if (val) historique.changerPeriode(p, compteurId);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Nunito',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      isSelected ? AppColors.primary : AppColors.borderColor,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard(HistoriqueProvider historique) {
    final sw = context.sw;
    return Container(
      margin: EdgeInsets.all(context.hPad),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: historique.isLoadingStats
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                  3, (_) => _skeletonBox(48, (sw * 0.16).clamp(48.0, 80.0))),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _summaryItem('Total consommé',
                      historique.totalConsommeFormatted, AppColors.secondary),
                ),
                _verticalDivider(),
                Expanded(
                  child: _summaryItem('Variation',
                      historique.variationFormatted, AppColors.secondary),
                ),
                _verticalDivider(),
                Expanded(
                  child: _summaryItem('Moy./jour',
                      historique.moyenneFormatted, AppColors.primary),
                ),
              ],
            ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: AppTextStyles.heading2.copyWith(
                  color: color, fontSize: 18)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _verticalDivider() =>
      Container(height: 30, width: 1, color: AppColors.borderColor);

  Widget _skeletonBox(double height, double width) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _buildLineChart(HistoriqueProvider historique) {
    final chartHeight = context.chartH;

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Évolution du crédit'),
          Text('Unités lues sur le compteur',
              style: AppTextStyles.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 24),
          if (historique.isLoadingReleves)
            SizedBox(
              height: chartHeight,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (historique.releves.isEmpty)
            SizedBox(
              height: chartHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('Pas de données pour cette période',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: LineChart(
                LineChartData(
                  minY: historique.minYChart,
                  maxY: historique.maxYChart,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => const FlLine(
                        color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx % 2 != 0) return const SizedBox();
                          final labels = historique.labelsForChart;
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                labels[idx],
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 9),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}',
                          style: AppTextStyles.caption.copyWith(fontSize: 9),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: historique.spotsForChart,
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isRecharge =
                              historique.isRechargePoint(index);
                          return FlDotCirclePainter(
                            radius: isRecharge ? 6 : 4,
                            color: isRecharge
                                ? AppColors.alertRed
                                : AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((s) {
                          final idx = s.x.toInt();
                          final labels = historique.labelsForChart;
                          final label = (idx >= 0 && idx < labels.length)
                              ? labels[idx]
                              : '';
                          return LineTooltipItem(
                            '${s.y.toInt()} u\n$label',
                            AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    return Container(
      margin: EdgeInsets.all(context.hPad),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Analyse MeterEye AI',
                    style: AppTextStyles.heading2
                        .copyWith(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _insightRow(Icons.trending_down,
              'Votre crédit baisse de 155 unités/jour en moyenne'),
          _insightRow(Icons.access_time,
              'Pics de consommation entre 18h et 22h chaque soir'),
          _insightRow(Icons.check_circle_outline,
              'Vous consommez moins que la semaine dernière (−8%)'),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: AppTextStyles.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLastLectures(HistoriqueProvider historique) {
    final sw = context.sw;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.hPad),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Dernières lectures'),
          if (historique.isLoadingReleves)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, __) =>
                  const Divider(color: Color(0xFFF1F5F9)),
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _skeletonBox(40, 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _skeletonBox(12, (sw * 0.25).clamp(60.0, 120.0)),
                          const SizedBox(height: 4),
                          _skeletonBox(10, (sw * 0.18).clamp(48.0, 90.0)),
                        ],
                      ),
                    ),
                    _skeletonBox(18, (sw * 0.1).clamp(32.0, 56.0)),
                  ],
                ),
              ),
            )
          else if (historique.dernieresLectures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Aucune lecture pour cette période.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historique.dernieresLectures.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Color(0xFFF1F5F9)),
              itemBuilder: (_, index) {
                final lecture = historique.dernieresLectures[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.bolt_rounded,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(lecture.formattedDate,
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            Text(lecture.sourceLabel,
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Text(
                        '${lecture.valeur.toInt()}',
                        style: AppTextStyles.heading2.copyWith(
                            color: AppColors.primary, fontSize: 16),
                      ),
                      Text(' u',
                          style: AppTextStyles.caption
                              .copyWith(fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(HistoriqueProvider historique, int compteurId) {
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              historique.error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => historique.refresh(compteurId),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
