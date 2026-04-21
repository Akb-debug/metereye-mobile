import 'package:flutter/material.dart';
import '../models/meter_model.dart';
import '../models/consumption_stats_model.dart';

class CreditBadge extends StatelessWidget {
  final MeterModel meter;
  final ConsumptionStatsModel? stats;
  final double? size;
  final bool showTrend;
  final bool showEstimation;

  const CreditBadge({
    Key? key,
    required this.meter,
    this.stats,
    this.size,
    this.showTrend = true,
    this.showEstimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCashPower = meter.isCashPower;
    final badgeSize = size ?? 120.0;
    
    if (!isCashPower) {
      // Pour les compteurs classiques, afficher l'index
      return _buildIndexBadge(theme, badgeSize);
    }

    final creditRestant = stats?.creditRestant ?? meter.valeurActuelle;
    final isFaible = stats?.isCreditFaible ?? (creditRestant < 100);
    final isCritique = stats?.isCreditCritique ?? (creditRestant < 50);

    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCreditColor(isCritique, isFaible),
        boxShadow: [
          BoxShadow(
            color: _getCreditColor(isCritique, isFaible).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercle de progression
          if (showTrend)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: _calculateProgress(creditRestant),
                backgroundColor: Colors.white.withOpacity(0.3),
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          
          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bolt,
                  color: Colors.white,
                  size: badgeSize * 0.25,
                ),
                const SizedBox(height: 4),
                Text(
                  '${creditRestant.toInt()}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: badgeSize * 0.2,
                  ),
                ),
                Text(
                  'FCFA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: badgeSize * 0.12,
                  ),
                ),
              ],
            ),
          ),
          
          // Badge d'alerte si crédit faible
          if (isCritique)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: badgeSize * 0.25,
                height: badgeSize * 0.25,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
                child: Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: badgeSize * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndexBadge(ThemeData theme, double badgeSize) {
    return Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cercle de progression (basé sur la consommation mensuelle)
          if (showTrend)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: _calculateIndexProgress(),
                backgroundColor: Colors.white.withOpacity(0.3),
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          
          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.electrical_services,
                  color: Colors.white,
                  size: badgeSize * 0.25,
                ),
                const SizedBox(height: 4),
                Text(
                  meter.valeurActuelle.toStringAsFixed(0),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: badgeSize * 0.2,
                  ),
                ),
                Text(
                  'kWh',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: badgeSize * 0.12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCreditColor(bool isCritique, bool isFaible) {
    if (isCritique) return Colors.red;
    if (isFaible) return Colors.orange;
    return Colors.green;
  }

  double _calculateProgress(double creditRestant) {
    // Considérer 1000 FCFA comme le crédit maximum normal
    const maxCredit = 1000.0;
    return (creditRestant / maxCredit).clamp(0.0, 1.0);
  }

  double _calculateIndexProgress() {
    // Simuler une progression basée sur l'index actuel
    // Considérer 1000 kWh comme l'index mensuel typique
    const maxIndex = 1000.0;
    return (meter.valeurActuelle / maxIndex).clamp(0.0, 1.0);
  }
}

class CreditInfoCard extends StatelessWidget {
  final MeterModel meter;
  final ConsumptionStatsModel? stats;

  const CreditInfoCard({
    Key? key,
    required this.meter,
    this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCashPower = meter.isCashPower;
    
    if (!isCashPower) {
      return _buildIndexInfo(theme);
    }

    final creditRestant = stats?.creditRestant ?? meter.valeurActuelle;
    final isFaible = stats?.isCreditFaible ?? (creditRestant < 100);
    final isCritique = stats?.isCreditCritique ?? (creditRestant < 50);
    final dateEpuisement = stats?.dateEstimationEpuisement;
    final consommationMoyenne = stats?.consommationMoyenneJour;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: _getCreditColor(isCritique, isFaible),
                ),
                const SizedBox(width: 8),
                Text(
                  'Informations de crédit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Crédit actuel
            _buildInfoRow(
              'Crédit restant',
              '${creditRestant.toInt()} FCFA',
              Icons.bolt,
              _getCreditColor(isCritique, isFaible),
            ),
            
            // Consommation moyenne
            if (consommationMoyenne != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Consommation moyenne/jour',
                '${consommationMoyenne!.toStringAsFixed(1)} FCFA',
                Icons.trending_down,
                Colors.blue,
              ),
            ],
            
            // Date d'épuisement estimée
            if (dateEpuisement != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Épuisement estimé',
                stats!.formattedDateEpuisement,
                Icons.event,
                isCritique ? Colors.red : Colors.orange,
              ),
            ],
            
            // Message d'alerte
            if (isCritique) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crédit critique! Rechargez immédiatement.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isFaible) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crédit faible. Pensez à recharger bientôt.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndexInfo(ThemeData theme) {
    final consommationMois = stats?.consommationMois;
    final estimationFacture = consommationMois != null ? consommationMois * 75 : null; // 75 FCFA/kWh
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.electrical_services, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Informations de consommation',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Index actuel
            _buildInfoRow(
              'Index actuel',
              '${meter.valeurActuelle.toStringAsFixed(2)} kWh',
              Icons.speed,
              Colors.green,
            ),
            
            // Consommation mensuelle
            if (consommationMois != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Consommation mensuelle',
                '${consommationMois!.toStringAsFixed(2)} kWh',
                Icons.insert_chart,
                Colors.blue,
              ),
            ],
            
            // Estimation facture
            if (estimationFacture != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                'Estimation facture',
                '${estimationFacture!.toStringAsFixed(0)} FCFA',
                Icons.receipt,
                Colors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCreditColor(bool isCritique, bool isFaible) {
    if (isCritique) return Colors.red;
    if (isFaible) return Colors.orange;
    return Colors.green;
  }
}
