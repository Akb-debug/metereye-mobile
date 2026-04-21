import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/section_title.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  String selectedPeriod = "30J";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Historique & Analyses")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // ── SÉLECTEUR DE PÉRIODE ──────────────────────────────────────────────
            _buildPeriodSelector(),

            // ── GRAPHE COURBE 30 JOURS ───────────────────────────────────────────
            _buildLineChart(),

            // ── TABLEAU RECHARGES ───────────────────────────────────────────────
            _buildRechargeHistory(),

            // ── ANALYSE IA ──────────────────────────────────────────────────────
            _buildAIAnalysis(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ["7J", "30J", "6M", "1AN"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: periods.map((period) {
          final isSelected = selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📈 Évolution de la consommation"),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "${value.toInt()}",
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(AppData.conso30j.length, (i) {
                      return FlSpot(i.toDouble(), AppData.conso30j[i]);
                    }),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.2),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Ligne moyenne quartier
                  LineChartBarData(
                    spots: List.generate(AppData.conso30j.length, (i) {
                      return FlSpot(i.toDouble(), AppData.moyenneQuartier);
                    }),
                    isCurved: false,
                    color: AppTheme.alertOrange,
                    barWidth: 2,
                    dashArray: [8, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "${spot.y} kWh",
                          const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Ma consommation", AppTheme.primary),
              const SizedBox(width: 20),
              _buildLegendItem("Moy. quartier", AppTheme.alertOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildRechargeHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("💳 Historique des recharges"),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppData.recharges.length,
            separatorBuilder: (context, index) => Container(height: 1, color: AppTheme.border),
            itemBuilder: (context, index) {
              final recharge = AppData.recharges[index];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.alertGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.bolt_rounded, color: AppTheme.alertGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recharge['date'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text(
                          "${recharge['montant']} FCFA",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("${recharge['unites']} unités", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.alertGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text("Validé", style: TextStyle(color: AppTheme.alertGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysis() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.smart_toy_rounded, color: AppTheme.primary, size: 24),
              SizedBox(width: 12),
              Text(
                "Analyse MeterEye AI",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAIAnalysisItem("📈 Consommation +12% par rapport au mois dernier"),
          _buildAIAnalysisItem("⏰ Pics entre 18h00 et 22h00 chaque soir"),
          _buildAIAnalysisItem("💡 Conseil : Utilisez les appareils énergivores avant 17h"),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
