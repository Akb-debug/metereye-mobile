import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../widgets/credit_bar.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/alerte_item.dart';
import '../../widgets/section_title.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          "MeterEye AI",
          style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lecture du compteur en cours...")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── EN-TÊTE GRADIENT ────────────────────────────────────────────────
            _buildHeader(),

            // ── CARTES STATS ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const StatChip(
                        icon: Icons.bolt_rounded,
                        iconBg: Color(0xFFEFF6FF),
                        iconColor: AppColors.primary,
                        value: "${AppData.consoAujourd} kWh",
                        label: "Aujourd'hui",
                      ),
                      const SizedBox(width: 12),
                      const StatChip(
                        icon: Icons.calendar_today_rounded,
                        iconBg: Color(0xFFECFDF5),
                        iconColor: AppColors.secondary,
                        value: "${AppData.consoMois} kWh",
                        label: "Ce mois",
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatChip(
                        icon: Icons.trending_down_rounded,
                        iconBg: const Color(0xFFFFFBEB),
                        iconColor: AppColors.alertOrange,
                        value: "${AppData.moyJournaliere.toInt()} u/j",
                        label: "Moy. journalière",
                      ),
                      const SizedBox(width: 12),
                      StatChip(
                        icon: Icons.access_time_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: Colors.purple.shade600,
                        value: "28 Fév",
                        label: "Fin estimée",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── GRAPHE CONSOMMATION ─────────────────────────────────────────────
            _buildConsumptionChart(),

            // ── ALERTES RÉCENTES ────────────────────────────────────────────────
            _buildRecentAlerts(context),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 32),
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bonjour, Koffi 👋", style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            "${AppData.numCompteur} · Dernière lecture : 09:47",
            style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${AppData.creditUnites}",
                    style: AppTextStyles.heading1.copyWith(fontSize: 48, color: Colors.white, letterSpacing: -1),
                  ),
                  Text(
                    "unités restantes",
                    style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.85), fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "≈ ${AppData.joursRestants} jours",
                    style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    "avant coupure",
                    style: AppTextStyles.caption.copyWith(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CreditBar(value: AppData.creditPct),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle("Consommation — 7 jours"),
              Text("kWh", style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: 6,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY} kWh",
                        AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = AppData.conso7j.map((e) => e['jour'] as String).toList();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt() % days.length],
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text("${value.toInt()}", style: AppTextStyles.caption.copyWith(fontSize: 10));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(AppData.conso7j.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: AppData.conso7j[i]['kwh'].toDouble(),
                        gradient: AppColors.mainGradient,
                        width: 20,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 3.08,
                      color: AppColors.alertOrange,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: const TextStyle(color: AppColors.alertOrange, fontSize: 10, fontWeight: FontWeight.bold),
                        labelResolver: (_) => "Moy.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    final recentAlerts = AppData.alertes.where((a) => a['lue'] == false).take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle("Alertes récentes"),
              TextButton(
                onPressed: () {
                  // This would ideally switch the tab in HomeShell
                },
                child: Text(
                  "Tout voir",
                  style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ...recentAlerts.map((a) => AlerteItem(data: a, isCompact: true)),
        ],
      ),
    );
  }
}
