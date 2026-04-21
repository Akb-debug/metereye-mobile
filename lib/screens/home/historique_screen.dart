import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../widgets/section_title.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  String _selectedPeriod = "30 jours";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique"),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── SÉLECTEUR PÉRIODE ───────────────────────────────────────────────
            _buildPeriodSelector(),

            // ── CARTE RÉSUMÉ ────────────────────────────────────────────────────
            _buildSummaryCard(),

            // ── GRAPHE COURBE ──────────────────────────────────────────────────
            _buildLineChart(),

            // ── ANALYSE IA ─────────────────────────────────────────────────────
            _buildAIAnalysis(),

            // ── DERNIÈRES LECTURES ─────────────────────────────────────────────
            _buildLastLectures(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ["7 jours", "30 jours", "3 mois"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedPeriod = p);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Nunito',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderColor),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("Total consommé", "68.3 kWh", AppColors.secondary),
          _verticalDivider(),
          _summaryItem("Variation", "−8%", AppColors.secondary),
          _verticalDivider(),
          _summaryItem("Moy./jour", "2.3 kWh", AppColors.primary),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.heading2.copyWith(color: color, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(height: 30, width: 1, color: AppColors.borderColor);
  }

  Widget _buildLineChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("Évolution du crédit"),
          Text("Unités lues sur le compteur", style: AppTextStyles.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 != 0) return const SizedBox();
                        final idx = value.toInt();
                        if (idx >= 0 && idx < AppData.lectures30j.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.5,
                              child: Text(
                                AppData.lectures30j[idx]['date'],
                                style: AppTextStyles.caption.copyWith(fontSize: 9),
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text("${value.toInt()}", style: AppTextStyles.caption.copyWith(fontSize: 9));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(AppData.lectures30j.length, (i) {
                      return FlSpot(i.toDouble(), AppData.lectures30j[i]['unites'].toDouble());
                    }),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        bool isRecharge = index > 0 && 
                            barData.spots[index].y > barData.spots[index - 1].y;
                        return FlDotCirclePainter(
                          radius: isRecharge ? 6 : 4,
                          color: isRecharge ? AppColors.alertRed : AppColors.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.0)],
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
                        return LineTooltipItem(
                          "${s.y.toInt()} u\n${AppData.lectures30j[s.x.toInt()]['date']}",
                          AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFEFF6FF), const Color(0xFFE0F2FE)],
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
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text("Analyse MeterEye AI", style: AppTextStyles.heading2.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          _insightRow(Icons.trending_down, "Votre crédit baisse de 155 unités/jour en moyenne"),
          _insightRow(Icons.access_time, "Pics de consommation entre 18h et 22h chaque soir"),
          _insightRow(Icons.check_circle_outline, "Vous consommez moins que la semaine dernière (−8%)"),
        ],
      ),
    );
  }

  Widget _insightRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTextStyles.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildLastLectures() {
    final lectures = AppData.lectures30j.reversed.take(5).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("Dernières lectures"),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lectures.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final lecture = lectures[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                      child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lecture['date'], style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                        Text("Lecture automatique", style: AppTextStyles.caption),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "${lecture['unites']}",
                      style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontSize: 16),
                    ),
                    const SizedBox(width: 2),
                    Text(" u", style: AppTextStyles.caption.copyWith(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
