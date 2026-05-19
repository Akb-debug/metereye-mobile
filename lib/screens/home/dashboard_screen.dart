import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../widgets/credit_bar.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/section_title.dart';
import '../../features/Releve/screens/releve_manuel_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dash, _) {
        final nomComplet = context.read<AuthProvider>().user?.nomComplet ?? '';
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
              'Ajouter un relevé',
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
              child: const Icon(Icons.bolt_rounded,
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
                                      icon: Icons.access_time_rounded,
                                      iconBg: const Color(0xFFF3E8FF),
                                      iconColor: Colors.purple.shade600,
                                      value: dash.isLoading &&
                                              dash.stats == null
                                          ? '…'
                                          : dash.dateFinEstimee,
                                      label: 'Fin estimée',
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
            '${dash.numCompteur} · Dernière lecture : ${dash.derniereLeture}',
            style: AppTextStyles.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                      : Text(
                          dash.creditUnites,
                          style: AppTextStyles.heading1.copyWith(
                              fontSize: 48,
                              color: Colors.white,
                              letterSpacing: -1),
                        ),
                  Text(
                    'unités restantes',
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '≈ ${dash.joursRestants} jours',
                    style: AppTextStyles.heading2
                        .copyWith(color: Colors.white, fontSize: 22),
                  ),
                  Text(
                    'avant coupure',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          CreditBar(value: dash.creditPct),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(DashboardProvider dash) {
    final data = dash.conso7j;
    final maxY = dash.maxConso7j;

    return Container(
      margin: EdgeInsets.all(context.hPad),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consommation — 7 jours',
                  style: AppTextStyles.heading2.copyWith(fontSize: 15)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('kWh',
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (dash.isLoading && data.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
            )
          else if (data.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bar_chart_rounded,
                          size: 36,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.4)),
                    ),
                    const SizedBox(height: 12),
                    Text('Aucune donnée cette semaine',
                        style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Ajoutez un relevé pour voir le graphe',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.primary,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      getTooltipItem: (group, _, rod, __) {
                        final jour =
                            data[group.x]['jour'] as String;
                        return BarTooltipItem(
                          '$jour\n',
                          AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10),
                          children: [
                            TextSpan(
                              text:
                                  '${rod.toY.toStringAsFixed(2)} kWh',
                              style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data[idx]['jour'] as String,
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: maxY > 0 ? maxY / 3 : 2,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value >= 10
                                ? value.toInt().toString()
                                : value.toStringAsFixed(1),
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.textSecondary),
                          );
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
                    horizontalInterval: maxY > 0 ? maxY / 3 : 2,
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: Color(0xFFEFF3F8), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (i) {
                    final kwh =
                        (data[i]['kwh'] as num).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: kwh,
                          gradient: kwh > 0
                              ? AppColors.mainGradient
                              : const LinearGradient(colors: [
                                  AppColors.borderColor,
                                  AppColors.borderColor
                                ]),
                          width: 18,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5),
                          ),
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
                                padding: const EdgeInsets.only(
                                    right: 4, bottom: 2),
                                style: const TextStyle(
                                    color: AppColors.alertOrange,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Nunito'),
                                labelResolver: (_) => 'Moy.',
                              ),
                            ),
                          ],
                        )
                      : const ExtraLinesData(),
                ),
                swapAnimationDuration:
                    const Duration(milliseconds: 400),
                swapAnimationCurve: Curves.easeInOut,
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
              const SectionTitle('Dernière lecture'),
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
              'Aucune lecture enregistrée.',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            )
          else if (reading != null) ...[
            _readingRow(
              Icons.bolt_rounded,
              AppColors.primary,
              'Valeur',
              '${reading.valeur.toStringAsFixed(2)} kWh',
            ),
            const SizedBox(height: 8),
            _readingRow(
              Icons.schedule_rounded,
              AppColors.secondary,
              'Date',
              reading.formattedDate,
            ),
            const SizedBox(height: 8),
            _readingRow(
              Icons.input_rounded,
              AppColors.alertOrange,
              'Source',
              reading.source,
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
