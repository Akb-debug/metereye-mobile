import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meter_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/meter_card.dart';
import '../../widgets/consumption_chart.dart';
import '../../widgets/credit_badge.dart';
import '../../widgets/readings_list.dart';
import '../../models/meter_model.dart';
import '../../models/reading_model.dart';
import '../../models/reading_request_model.dart';
import '../../models/recharge_request_model.dart';

class ProprioDashboard extends StatefulWidget {
  const ProprioDashboard({Key? key}) : super(key: key);

  @override
  State<ProprioDashboard> createState() => _ProprioDashboardState();
}

class _ProprioDashboardState extends State<ProprioDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final meterProvider = Provider.of<MeterProvider>(context, listen: false);
    
    // Charger tous les compteurs du propriétaire
    await meterProvider.loadCompteurs();
    
    // Si on a des compteurs, sélectionner le premier et charger ses données
    if (meterProvider.compteurs.isNotEmpty) {
      final firstMeter = meterProvider.compteurs.first;
      meterProvider.selectCompteur(firstMeter);
      
      // Charger les relevés et statistiques du premier compteur
      await Future.wait([
        meterProvider.loadReleves(firstMeter.id),
        meterProvider.loadStats(firstMeter.id, periode: 'month'),
      ]);
    }
  }

  Future<void> _refreshData() async {
    final meterProvider = Provider.of<MeterProvider>(context, listen: false);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final meterProvider = Provider.of<MeterProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Dashboard Propriétaire"),
            Text(
              "Bonjour ${authProvider.user?.nomComplet ?? ''}",
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
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _buildBody(meterProvider),
      ),
    );
  }

  Widget _buildBody(MeterProvider meterProvider) {
    if (meterProvider.isLoadingCompteurs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (meterProvider.compteursError != null) {
      return _buildErrorState(meterProvider.compteursError!, () {
        meterProvider.loadCompteurs();
      });
    }

    if (meterProvider.compteurs.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Vue d'ensemble des compteurs
          _buildOverviewSection(meterProvider),
          const SizedBox(height: 16),
          
          // Filtres par type
          _buildTypeFilters(meterProvider),
          const SizedBox(height: 16),
          
          // Liste des compteurs
          _buildMetersList(meterProvider),
          
          // Détails du compteur sélectionné
          if (meterProvider.selectedCompteur != null) ...[
            const SizedBox(height: 16),
            _buildSelectedMeterDetails(meterProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewSection(MeterProvider meterProvider) {
    final totalCompteurs = meterProvider.compteurs.length;
    final cashPowerCount = meterProvider.compteursCashPower.length;
    final classiqueCount = meterProvider.compteursClassique.length;
    final actifsCount = meterProvider.compteursActifs.length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Total compteurs',
                    totalCompteurs.toString(),
                    Icons.electrical_services,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Cash Power',
                    cashPowerCount.toString(),
                    Icons.bolt,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Classique',
                    classiqueCount.toString(),
                    Icons.speed,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Actifs',
                    actifsCount.toString(),
                    Icons.check_circle,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTypeFilters(MeterProvider meterProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtrer par type',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Tous (${meterProvider.compteurs.length})',
                  true,
                  () => _filterByType('all', meterProvider),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Cash Power (${meterProvider.compteursCashPower.length})',
                  false,
                  () => _filterByType('cashpower', meterProvider),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Classique (${meterProvider.compteursClassique.length})',
                  false,
                  () => _filterByType('classique', meterProvider),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMetersList(MeterProvider meterProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mes compteurs',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meterProvider.compteurs.length,
          itemBuilder: (context, index) {
            final meter = meterProvider.compteurs[index];
            final dernierReleve = meterProvider.getDernierReleve(meter.id);
            final isSelected = meterProvider.selectedCompteur?.id == meter.id;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: MeterCard(
                meter: meter,
                dernierReleve: dernierReleve,
                onTap: () => _selectMeter(meter, meterProvider),
                showActions: false, // Actions dans la section détails
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedMeterDetails(MeterProvider meterProvider) {
    final meter = meterProvider.selectedCompteur!;
    final isCashPower = meter.isCashPower;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Détails: ${meter.reference}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isCashPower)
                  ElevatedButton.icon(
                    onPressed: () => _showRechargeDialog(meter),
                    icon: const Icon(Icons.add_circle, size: 18),
                    label: const Text('Recharger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showAddReadingDialog(meter),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter relevé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Badge et informations
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: CreditBadge(
                      meter: meter,
                      stats: meterProvider.stats,
                      size: 100,
                      showTrend: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: CreditInfoCard(
                    meter: meter,
                    stats: meterProvider.stats,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Graphique de consommation
            ConsumptionChart(
              readings: meterProvider.releves,
              stats: meterProvider.stats,
              title: isCashPower 
                  ? 'Évolution du crédit - 30 derniers jours'
                  : 'Consommation - 30 derniers jours',
              showConsumption: !isCashPower,
              height: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Derniers relevés
            SizedBox(
              height: 200,
              child: ReadingsList(
                readings: meterProvider.releves.take(3).toList(),
                title: 'Derniers relevés',
                showMeterInfo: false,
                onRefresh: () {
                  meterProvider.loadReleves(meter.id);
                },
                onTap: (reading) => _showReadingDetails(reading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compteur trouvé',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de compteur associé à votre compte de propriétaire.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _filterByType(String type, MeterProvider meterProvider) {
    // Logique de filtrage - pour l'instant on garde tous les compteurs
    // Dans une version future, on pourrait implémenter un vrai filtrage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Filtre: $type')),
    );
  }

  void _selectMeter(MeterModel meter, MeterProvider meterProvider) {
    meterProvider.selectCompteur(meter);
    
    // Recharger les données pour le nouveau compteur
    Future.wait([
      meterProvider.loadReleves(meter.id),
      meterProvider.loadStats(meter.id, periode: 'month'),
    ]);
  }

  void _showRechargeDialog(MeterModel meter) {
    showDialog(
      context: context,
      builder: (context) => RechargeDialog(meter: meter),
    );
  }

  void _showAddReadingDialog(MeterModel meter) {
    showDialog(
      context: context,
      builder: (context) => AddReadingDialog(meter: meter),
    );
  }

  void _showReadingDetails(ReadingModel reading) {
    showDialog(
      context: context,
      builder: (context) => ReadingDetailsDialog(reading: reading),
    );
  }
}

class RechargeDialog extends StatefulWidget {
  final MeterModel meter;

  const RechargeDialog({Key? key, required this.meter}) : super(key: key);

  @override
  State<RechargeDialog> createState() => _RechargeDialogState();
}

class _RechargeDialogState extends State<RechargeDialog> {
  final _montantController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Recharger ${widget.meter.reference}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _montantController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant (FCFA)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Code de recharge',
              prefixIcon: Icon(Icons.vpn_key),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _recharger,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Recharger'),
        ),
      ],
    );
  }

  Future<void> _recharger() async {
    final montant = double.tryParse(_montantController.text);
    final code = _codeController.text.trim();

    if (montant == null || montant <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un montant valide')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meterProvider = Provider.of<MeterProvider>(context, listen: false);
      final request = RechargeRequestModel(
        compteurId: widget.meter.id,
        montant: montant,
        codeRecharge: code.isNotEmpty ? code : null,
      );

      final success = await meterProvider.rechargerCompteur(request);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(meterProvider.operationSuccess ?? 'Recharge réussie')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(meterProvider.operationError ?? 'Erreur de recharge')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class AddReadingDialog extends StatefulWidget {
  final MeterModel meter;

  const AddReadingDialog({Key? key, required this.meter}) : super(key: key);

  @override
  State<AddReadingDialog> createState() => _AddReadingDialogState();
}

class _AddReadingDialogState extends State<AddReadingDialog> {
  final _valeurController = TextEditingController();
  final _commentaireController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ajouter un relevé - ${widget.meter.reference}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Index actuel: ${widget.meter.valeurActuelle.toStringAsFixed(2)} kWh',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valeurController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nouvel index (kWh)',
              prefixIcon: Icon(Icons.speed),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentaireController,
            decoration: const InputDecoration(
              labelText: 'Commentaire (optionnel)',
              prefixIcon: Icon(Icons.comment),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addReading,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  Future<void> _addReading() async {
    final valeur = double.tryParse(_valeurController.text);
    final commentaire = _commentaireController.text.trim();

    if (valeur == null || valeur < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une valeur valide')),
      );
      return;
    }

    if (valeur <= widget.meter.valeurActuelle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nouvel index doit être supérieur à l\'index actuel')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meterProvider = Provider.of<MeterProvider>(context, listen: false);
      final request = ReadingRequestModel(
        compteurId: widget.meter.id,
        valeur: valeur,
        commentaire: commentaire.isNotEmpty ? commentaire : null,
      );

      final success = await meterProvider.ajouterReleve(request);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(meterProvider.operationSuccess ?? 'Relevé ajouté avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(meterProvider.operationError ?? 'Erreur lors de l\'ajout du relevé')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class ReadingDetailsDialog extends StatelessWidget {
  final ReadingModel reading;

  const ReadingDetailsDialog({Key? key, required this.reading}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Détails du relevé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Date', reading.formattedDate),
          _buildDetailRow('Valeur', '${reading.formattedValeur} kWh'),
          if (reading.consommationCalculee != null)
            _buildDetailRow('Consommation', reading.formattedConsommation),
          _buildDetailRow('Source', reading.source),
          _buildDetailRow('Statut', reading.statut),
          if (reading.commentaire != null && reading.commentaire!.isNotEmpty)
            _buildDetailRow('Commentaire', reading.commentaire!),
          if (reading.isOcr) ...[
            _buildDetailRow('Valeur OCR', reading.valeurOcr?.toStringAsFixed(2) ?? 'N/A'),
            _buildDetailRow('Confiance OCR', reading.formattedConfianceOcr),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
