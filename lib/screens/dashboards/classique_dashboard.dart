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

class ClassiqueDashboard extends StatefulWidget {
  const ClassiqueDashboard({Key? key}) : super(key: key);

  @override
  State<ClassiqueDashboard> createState() => _ClassiqueDashboardState();
}

class _ClassiqueDashboardState extends State<ClassiqueDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final meterProvider = Provider.of<MeterProvider>(context, listen: false);
    
    // Charger les compteurs Classiques
    await meterProvider.loadCompteurs();
    
    // Si on a des compteurs, charger les données du premier
    if (meterProvider.compteursClassique.isNotEmpty) {
      final firstMeter = meterProvider.compteursClassique.first;
      meterProvider.selectCompteur(firstMeter);
      
      // Charger les relevés et statistiques
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
            const Text("Dashboard Classique"),
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
      floatingActionButton: meterProvider.selectedCompteur != null
          ? FloatingActionButton.extended(
              onPressed: _showAddReadingDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter relevé'),
            )
          : null,
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

    if (meterProvider.compteursClassique.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sélecteur de compteur si plusieurs
          if (meterProvider.compteursClassique.length > 1)
            _buildMeterSelector(meterProvider),
          
          // Carte principale du compteur
          if (meterProvider.selectedCompteur != null) ...[
            _buildMainMeterCard(meterProvider.selectedCompteur!, meterProvider),
            const SizedBox(height: 16),
            
            // Index et consommation
            _buildIndexSection(meterProvider),
            const SizedBox(height: 16),
            
            // Statistiques
            _buildStatsGrid(meterProvider),
            const SizedBox(height: 16),
            
            // Graphique de consommation mensuelle
            _buildConsumptionChart(meterProvider),
            const SizedBox(height: 16),
            
            // Derniers relevés
            _buildRecentReadings(meterProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildMeterSelector(MeterProvider meterProvider) {
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
            'Mes compteurs',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: meterProvider.compteursClassique.length,
              itemBuilder: (context, index) {
                final meter = meterProvider.compteursClassique[index];
                final isSelected = meterProvider.selectedCompteur?.id == meter.id;
                
                return GestureDetector(
                  onTap: () => _selectMeter(meter, meterProvider),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          meter.reference,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          meter.formattedValeur,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMeterCard(MeterModel meter, MeterProvider meterProvider) {
    final dernierReleve = meterProvider.getDernierReleve(meter.id);
    
    return MeterCard(
      meter: meter,
      dernierReleve: dernierReleve,
      showActions: true,
      onRecharge: null, // Pas de recharge pour les compteurs classiques
      onDetails: () => _showMeterDetails(meter),
    );
  }

  Widget _buildIndexSection(MeterProvider meterProvider) {
    final meter = meterProvider.selectedCompteur!;
    final stats = meterProvider.stats;
    
    return Row(
      children: [
        // Badge d'index circulaire
        Expanded(
          flex: 2,
          child: Center(
            child: CreditBadge(
              meter: meter,
              stats: stats,
              size: 120,
              showTrend: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Informations détaillées
        Expanded(
          flex: 3,
          child: CreditInfoCard(
            meter: meter,
            stats: stats,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(MeterProvider meterProvider) {
    final stats = meterProvider.stats;
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          'Index actuel',
          '${meterProvider.selectedCompteur?.valeurActuelle.toStringAsFixed(2) ?? 'N/A'} kWh',
          Icons.speed,
          Colors.green,
        ),
        _buildStatCard(
          'Conso. mensuelle',
          stats?.formattedConsommationMois ?? 'N/A',
          Icons.insert_chart,
          Colors.blue,
        ),
        _buildStatCard(
          'Moyenne/jour',
          stats?.formattedConsommationMoyenneJour ?? 'N/A',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildStatCard(
          'Estimation facture',
          _calculateEstimatedBill(stats),
          Icons.receipt,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionChart(MeterProvider meterProvider) {
    return Card(
      elevation: 4,
      child: ConsumptionChart(
        readings: meterProvider.releves,
        stats: meterProvider.stats,
        title: 'Consommation mensuelle',
        showConsumption: true, // Montrer la consommation calculée
      ),
    );
  }

  Widget _buildRecentReadings(MeterProvider meterProvider) {
    return Card(
      elevation: 4,
      child: SizedBox(
        height: 300,
        child: ReadingsList(
          readings: meterProvider.releves.take(5).toList(), // 5 derniers relevés
          title: 'Derniers relevés',
          showMeterInfo: false,
          onRefresh: () {
            if (meterProvider.selectedCompteur != null) {
              meterProvider.loadReleves(meterProvider.selectedCompteur!.id);
            }
          },
          onTap: (reading) => _showReadingDetails(reading),
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
              Icons.electrical_services,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun compteur Classique',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de compteur classique associé à votre compte.',
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

  String _calculateEstimatedBill(dynamic stats) {
    // Tarif moyen au Togo : environ 75 FCFA/kWh
    const double tarifKwh = 75.0;
    
    if (stats?.consommationMois != null) {
      final estimatedCost = stats!.consommationMois! * tarifKwh;
      return '${estimatedCost.toStringAsFixed(0)} FCFA';
    }
    
    return 'N/A';
  }

  void _selectMeter(MeterModel meter, MeterProvider meterProvider) {
    meterProvider.selectCompteur(meter);
    
    // Recharger les données pour le nouveau compteur
    Future.wait([
      meterProvider.loadReleves(meter.id),
      meterProvider.loadStats(meter.id, periode: 'month'),
    ]);
  }

  void _showAddReadingDialog() {
    final meterProvider = Provider.of<MeterProvider>(context, listen: false);
    final meter = meterProvider.selectedCompteur!;
    
    showDialog(
      context: context,
      builder: (context) => AddReadingDialog(meter: meter),
    );
  }

  void _showMeterDetails(MeterModel meter) {
    // Naviguer vers l'écran de détails du compteur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Détails du compteur ${meter.reference}')),
    );
  }

  void _showReadingDetails(ReadingModel reading) {
    showDialog(
      context: context,
      builder: (context) => ReadingDetailsDialog(reading: reading),
    );
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
