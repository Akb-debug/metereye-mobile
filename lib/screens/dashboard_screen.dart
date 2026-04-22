import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/stat_card.dart';
import '../widgets/alerte_card.dart';
import '../widgets/credit_progress_bar.dart';
import '../widgets/section_title.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("⚡ MeterEye AI"),
            Text(
              "Bonjour Koffi ",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // ── CARTE PRINCIPALE "Mon Compteur" ──────────────────────────────────
            _buildMainCounterCard(),

            // ── GRILLE STATISTIQUES (2×2) ─────────────────────────────────────────
            _buildStatsGrid(),

            // ── GRAPHE CONSOMMATION 7 JOURS ──────────────────────────────────────
            _buildConsumptionChart(),

            // ── APERÇU ALERTES RÉCENTES ──────────────────────────────────────────
            _buildAlertsOverview(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCounterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 2),
        )
      ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "CashPower Prépayé",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "${AppData.creditUnites}",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "unités restantes",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const CreditProgressBar(value: AppData.creditPct),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${(AppData.creditPct * 100).toInt()}% restant",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                "≈ ${AppData.joursRestants} jours",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: const [
        StatCard(
          icon: Icons.bolt_rounded,
          iconBg: Color(0xFFFEF9C3),
          iconColor: Color(0xFFF59E0B),
          value: "${AppData.consoAujourd} kWh",
          label: "Conso aujourd'hui",
        ),
        StatCard(
          icon: Icons.calendar_month_rounded,
          iconBg: Color(0xFFEFF6FF),
          iconColor: Color(0xFF3B82F6),
          value: "${AppData.consoMois} kWh",
          label: "Conso ce mois",
        ),
        StatCard(
          icon: Icons.account_balance_wallet_rounded,
          iconBg: Color(0xFFECFDF5),
          iconColor: Color(0xFF10B981),
          value: "${AppData.creditUnites} unités",
          label: "Coût estimé",
        ),
        StatCard(
          icon: Icons.auto_awesome_rounded,
          iconBg: Color(0xFFFAF5FF),
          iconColor: Color(0xFF8B5CF6),
          value: "8j 14h",
          label: "Durée restante",
        ),
      ],
    );
  }

  Widget _buildConsumptionChart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📊 Consommation — 7 derniers jours"),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 6,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "${rod.toY} kWh",
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[value.toInt() % days.length],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
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
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(AppData.conso7j.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: AppData.conso7j[i]['kwh'].toDouble(),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 3.0,
                      color: AppColors.alertRed.withOpacity(0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 5, bottom: 5),
                        style: const TextStyle(color: AppColors.alertRed, fontSize: 9, fontWeight: FontWeight.bold),
                        labelResolver: (line) => 'Moy. 3.0',
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

  Widget _buildAlertsOverview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle("🔔 Alertes récentes"),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Voir tout →",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const AlerteCard(
            type: 'warning',
            titre: "Crédit faible dans 3 jours",
            desc: "Votre consommation actuelle épuisera votre solde rapidement.",
            heure: "il y a 2h",
            lue: false,
            mini: true,
          ),
          const AlerteCard(
            type: 'success',
            titre: "Recharge détectée : +500 unités",
            desc: "Votre solde a été mis à jour avec succès.",
            heure: "hier 18:32",
            lue: true,
            mini: true,
          ),
        ],
      ),
    );
  }
}
