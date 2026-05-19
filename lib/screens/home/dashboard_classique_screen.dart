import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/section_title.dart';
import '../../features/Releve/screens/releve_manuel_screen.dart';

class DashboardClassiqueScreen extends StatefulWidget {
  const DashboardClassiqueScreen({super.key});

  @override
  State<DashboardClassiqueScreen> createState() =>
      _DashboardClassiqueScreenState();
}

class _DashboardClassiqueScreenState extends State<DashboardClassiqueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dash = context.read<DashboardProvider>();
      if (dash.compteurActif == null && !dash.isLoading) {
        dash.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dash, _) {
        final nomComplet =
            context.read<AuthProvider>().user?.nomComplet ?? '';
        final userName =
            nomComplet.trim().isNotEmpty ? nomComplet.trim() : 'vous';

        return Scaffold(
          extendBodyBehindAppBar: true,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReleveManuelScreen()),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_chart_rounded),
            label: const Text(
              'Nouveau relevé',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          appBar: AppBar(
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.electric_meter_rounded,
                  color: Colors.white, size: 20),
            ),
            title: Text(
              'MeterEye AI',
              style: AppTextStyles.heading1
                  .copyWith(color: Colors.white, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: dash.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed:
                    dash.isLoading ? null : () => dash.loadDashboard(),
              ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: dash.error != null && dash.compteurActif == null
                  ? _buildError(dash)
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(dash, userName),
                          Padding(
                            padding: EdgeInsets.only(
                              left: context.hPad,
                              right: context.hPad,
                              top: 12,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    StatChip(
                                      icon: Icons.bolt_rounded,
                                      iconBg: const Color(0xFFEFF6FF),
                                      iconColor: AppColors.primary,
                                      value: dash.isLoading &&
                                              dash.stats == null
                                          ? '…'
                                          : dash.consoAujourd,
                                      label: "Aujourd'hui",
                                    ),
                                    const SizedBox(width: 12),
                                    StatChip(
                                      icon: Icons.calendar_today_rounded,
                                      iconBg: const Color(0xFFECFDF5),
                                      iconColor: AppColors.secondary,
                                      value: dash.isLoading &&
                                              dash.stats == null
                                          ? '…'
                                          : dash.consoMois,
                                      label: 'Ce mois',
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
                                      value: dash.isLoading &&
                                              dash.stats == null
                                          ? '…'
                                          : dash.moyJournaliere,
                                      label: 'Moy. journalière',
                                    ),
                                    const SizedBox(width: 12),
                                    StatChip(
                                      icon: Icons.date_range_rounded,
                                      iconBg: const Color(0xFFF3E8FF),
                                      iconColor: Colors.purple.shade600,
                                      value: dash.isLoading &&
                                              dash.stats == null
                                          ? '…'
                                          : _formatKwh(
                                              dash.stats?.consommationSemaine),
                                      label: 'Cette semaine',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildConsumptionChart(dash),
                          _buildDerniereLeture(dash),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatKwh(double? v) =>
      v == null ? '--' : '${v.toStringAsFixed(2)} kWh';

  Color _sourceColor(String source) {
    switch (source.toUpperCase()) {
      case 'ESP32_CAM':
        return Colors.purple.shade600;
      case 'SENSOR':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  String _sourceLabel(String source) {
    switch (source.toUpperCase()) {
      case 'ESP32_CAM':
        return 'ESP32-CAM';
      case 'SENSOR':
        return 'CAPTEUR';
      default:
        return 'MANUEL';
    }
  }

  Color _statutColor(String statut) {
    switch (statut.toUpperCase()) {
      case 'VALIDE':
        return AppColors.secondary;
      case 'ERREUR':
        return AppColors.alertRed;
      default:
        return AppColors.alertOrange;
    }
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────

  Widget _buildError(DashboardProvider dash) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              dash.error ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => dash.loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DashboardProvider dash, String userName) {
    final prenom = userName.split(' ').first;
    final reading = dash.latestReading;
    final previous = dash.previousReading;

    final double indexActuel =
        reading?.valeur ?? dash.compteurActif?.valeurActuelle ?? 0;
    final double? indexPrecedent = previous?.valeur;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: context.statusBarH + 56,
        left: context.hPad,
        right: context.hPad,
        bottom: 32,
      ),
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
          Text(
            'Bonjour, $prenom 👋',
            style: AppTextStyles.heading1
                .copyWith(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 2),
          Text(
            '${dash.numCompteur} · Dernier relevé : ${dash.derniereLeture}',
            style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dash.isLoading && dash.compteurActif == null
                        ? const SizedBox(
                            width: 120,
                            height: 52,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              indexActuel.toStringAsFixed(2),
                              style: AppTextStyles.heading1.copyWith(
                                  fontSize: 48,
                                  color: Colors.white,
                                  letterSpacing: -1),
                            ),
                          ),
                    Text(
                      'kWh · Index actuel',
                      style: AppTextStyles.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14),
                    ),
                    if (indexPrecedent != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Précédent : ${indexPrecedent.toStringAsFixed(2)} kWh',
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              if (reading != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _badge(
                      _sourceLabel(reading.source),
                      _sourceColor(reading.source),
                    ),
                    const SizedBox(height: 6),
                    _badge(
                      reading.statut.toUpperCase() == 'VALIDE'
                          ? 'VALIDE'
                          : reading.statut.toUpperCase() == 'ERREUR'
                              ? 'ERREUR'
                              : 'EN ATTENTE',
                      _statutColor(reading.statut),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(DashboardProvider dash) {
    final data = dash.conso7j;
    final chartHeight = context.chartH;

    return Container(
      margin: EdgeInsets.all(context.hPad),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Consommation — 7 jours'),
              Text('kWh',
                  style: AppTextStyles.caption.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (dash.isLoading && data.isEmpty)
            SizedBox(
              height: chartHeight,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (data.isEmpty)
            SizedBox(
              height: chartHeight,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('Pas de données disponibles',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: chartHeight,
              child: BarChart(
                BarChartData(
                  maxY: dash.maxConso7j,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(2)} kWh',
                          AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
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
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[idx]['jour'] as String,
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 11),
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
                          return Text('${value.toInt()}',
                              style: AppTextStyles.caption
                                  .copyWith(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => const FlLine(
                        color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (data[i]['kwh'] as num).toDouble(),
                          gradient: AppColors.mainGradient,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                  extraLinesData: dash.moyenneConso > 0
                      ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: dash.moyenneConso,
                              color: AppColors.alertOrange,
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                style: const TextStyle(
                                    color: AppColors.alertOrange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                                labelResolver: (_) => 'Moy.',
                              ),
                            ),
                          ],
                        )
                      : const ExtraLinesData(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDerniereLeture(DashboardProvider dash) {
    final reading = dash.latestReading;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.hPad),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Dernier relevé'),
              if (dash.isLoading && reading == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reading == null && !dash.isLoading)
            Text(
              'Aucun relevé enregistré.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            )
          else if (reading != null) ...[
            _readingRow(
              Icons.electric_meter_rounded,
              AppColors.primary,
              'Index',
              '${reading.valeur.toStringAsFixed(2)} kWh',
            ),
            const SizedBox(height: 8),
            _readingRow(
              Icons.schedule_rounded,
              AppColors.secondary,
              'Date',
              reading.formattedDate,
            ),
            if (reading.consommationCalculee != null) ...[
              const SizedBox(height: 8),
              _readingRow(
                Icons.trending_up_rounded,
                AppColors.alertOrange,
                'Consommation',
                '+${reading.consommationCalculee!.toStringAsFixed(2)} kWh',
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.input_rounded,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Source : ',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary, fontSize: 13)),
                _badge(
                  _sourceLabel(reading.source),
                  _sourceColor(reading.source),
                ),
                const SizedBox(width: 8),
                _badge(
                  reading.statut.toUpperCase() == 'VALIDE'
                      ? 'VALIDE'
                      : reading.statut.toUpperCase() == 'ERREUR'
                          ? 'ERREUR'
                          : 'EN ATTENTE',
                  _statutColor(reading.statut),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _readingRow(
      IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text('$label : ',
            style: AppTextStyles.body
                .copyWith(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
