import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/section_title.dart';

class TransparenceScreen extends StatelessWidget {
  const TransparenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("👥 Transparence & Partage")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            // ── INFO LOGEMENT ────────────────────────────────────────────────────
            _buildHousingInfo(),

            // ── GRAPHE RÉPARTITION IMMEUBLE ─────────────────────────────────────
            _buildBuildingComparison(),

            // ── TABLEAU RÉCAPITULATIF ───────────────────────────────────────────
            _buildSummaryTable(),

            // ── FORMULAIRE CONTESTATION ──────────────────────────────────────────
            _buildDisputeForm(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHousingInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.home_rounded, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "${AppData.quartier} — ${AppData.appartement}",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textPrimary),
                ),
                Text(
                  "Propriétaire : ${AppData.proprietaire}",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.alertGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text(
              "Accès lecture ✅",
              style: TextStyle(color: AppTheme.alertGreen, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingComparison() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📊 Consommation par ménage — Février 2025"),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.alertGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Text(
              "Votre part : 25.2%",
              style: TextStyle(color: AppTheme.alertGreen, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < AppData.immeuble.length) {
                          final label = AppData.immeuble[value.toInt()]['appt'] as String;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              label.split(" — ")[0],
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.end,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(AppData.immeuble.length, (i) {
                  final data = AppData.immeuble[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data['kwh'].toDouble(),
                        color: data['isMe'] ? AppTheme.primary : const Color(0xFFCBD5E1),
                        width: 24,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(6), bottomRight: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
                alignment: BarChartAlignment.spaceEvenly,
              ),
              swapAnimationDuration: const Duration(milliseconds: 150),
              swapAnimationCurve: Curves.linear,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text("Consommation en kWh", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📋 Récapitulatif mensuel"),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                children: _buildTableHeader(["Ménage", "kWh", "Montant", "Statut"]),
              ),
              ...AppData.immeuble.asMap().entries.map((entry) {
                final i = entry.key;
                final data = entry.value;
                final bool isMe = data['isMe'];
                final bool isEven = i % 2 == 0;
                
                return TableRow(
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFEFF6FF) : (isEven ? Colors.white : const Color(0xFFF8FAFC)),
                  ),
                  children: [
                    _buildTableCell(data['appt'].split(" — ")[0], isBold: isMe),
                    _buildTableCell("${data['kwh']}"),
                    _buildTableCell("${(data['kwh'] * 79).toInt()} F"),
                    _buildTableCell("Payé", isStatus: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTableHeader(List<String> headers) {
    return headers.map((h) => Padding(
      padding: const EdgeInsets.all(10),
      child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
    )).toList();
  }

  Widget _buildTableCell(String text, {bool isBold = false, bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: isStatus 
        ? Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(color: AppTheme.alertGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: const Text("Payé", style: TextStyle(color: AppTheme.alertGreen, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          )
        : Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isBold ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
    );
  }

  Widget _buildDisputeForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📋 Demande de vérification"),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Une erreur sur votre facture ? Décrivez votre demande ici...",
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Envoyer au propriétaire"),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              "Sera transmis directement à M. Agbéko Dossou",
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
