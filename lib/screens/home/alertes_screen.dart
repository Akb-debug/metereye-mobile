// 🔄 MODIFIÉ — alertes_screen.dart — ajouts : Consumer<AlerteProvider>, données dynamiques,
//              loader, erreur réseau, badge réel, marquer comme lu au tap, "Tout marquer"

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/alertes/models/alerte_model.dart';
import '../../features/alertes/providers/alerte_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/alerte_item.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  String _filter = "Toutes";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlerteProvider>().loadAlertes();
    });
  }

  List<AlerteModel> _filteredAlerts(List<AlerteModel> alertes) {
    if (_filter == "Toutes") return alertes;
    if (_filter == "🔴 Urgentes") {
      return alertes.where((a) => a.type == 'urgent').toList();
    }
    if (_filter == "⚠️ Attention") {
      return alertes.where((a) => a.type == 'warning').toList();
    }
    if (_filter == "✅ Info") {
      return alertes
          .where((a) => a.type == 'success' || a.type == 'info')
          .toList();
    }
    return alertes;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlerteProvider>(
      builder: (context, alerteProvider, _) {
        final filtered = _filteredAlerts(alerteProvider.alertes);

        return Scaffold(
          appBar: AppBar(
            title: const Text("Alertes"),
            backgroundColor: AppColors.background,
            actions: [
              // Bouton "Tout marquer comme lu" — visible s'il y a des non-lues
              if (!alerteProvider.isLoading &&
                  alerteProvider.nonLuesCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded),
                  tooltip: 'Tout marquer comme lu',
                  color: AppColors.textPrimary,
                  onPressed: () => alerteProvider.marquerToutesLues(),
                ),
              _buildBadgeIcon(
                  Icons.notifications_rounded, alerteProvider.nonLuesCount),
              const SizedBox(width: 8),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _buildFilters(),
                  Expanded(
                    child: _buildBody(alerteProvider, filtered),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Corps selon l'état ─────────────────────────────────────────────────────

  Widget _buildBody(
      AlerteProvider alerteProvider, List<AlerteModel> filtered) {
    // Chargement initial (liste vide)
    if (alerteProvider.isLoading && alerteProvider.alertes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Erreur réseau sans données
    if (alerteProvider.error != null && alerteProvider.alertes.isEmpty) {
      return _buildErrorWidget(alerteProvider);
    }

    // Liste vide après filtre
    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    // Liste principale avec pull-to-refresh
    return RefreshIndicator(
      onRefresh: alerteProvider.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final alerte = filtered[index];
          return GestureDetector(
            onTap: () {
              if (!alerte.lue) {
                alerteProvider.marquerCommeLue(alerte.id);
              }
            },
            child: AlerteItem(alerte: alerte),
          );
        },
      ),
    );
  }

  // ── Widgets d'état ─────────────────────────────────────────────────────────

  Widget _buildErrorWidget(AlerteProvider alerteProvider) {
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
              alerteProvider.error ?? 'Une erreur est survenue.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: alerteProvider.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Aucune alerte dans cette catégorie',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ── Widgets visuels inchangés ──────────────────────────────────────────────

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(icon, color: AppColors.textPrimary),
          onPressed: () {},
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                  color: AppColors.alertRed, shape: BoxShape.circle),
              constraints:
                  const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ["Toutes", "🔴 Urgentes", "⚠️ Attention", "✅ Info"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _filter = f);
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Nunito',
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderColor),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
