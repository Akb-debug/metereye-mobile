import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/alerte_card.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  String activeFilter = "Tout";

  @override
  Widget build(BuildContext context) {
    final unreadCount = AppData.alertes.where((a) => !a['lue']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔔 Alertes"),
        actions: [
          _buildBadgeIcon(Icons.notifications_rounded, unreadCount),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // ── FILTRE PILLS SCROLLABLE ──────────────────────────────────────────
          _buildFilterPills(),

          // ── LISTE DES ALERTES ────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredAlerts.length,
              itemBuilder: (context, index) {
                final alerte = _filteredAlerts[index];
                return AlerteCard(
                  type: alerte['type'],
                  titre: alerte['titre'],
                  desc: alerte['desc'],
                  heure: alerte['heure'],
                  lue: alerte['lue'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon, int count) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, size: 28),
        if (count > 0)
          Positioned(
            right: 0,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.alertRed, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                "$count",
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      {"label": "Tout", "type": "all"},
      {"label": "Urgentes", "type": "urgent", "color": AppTheme.alertRed},
      {"label": "Attention", "type": "warning", "color": AppTheme.alertOrange},
      {"label": "Info", "type": "info", "color": AppTheme.primary},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: filters.map((f) {
          final isSelected = activeFilter == f['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String),
              selected: isSelected,
              onSelected: (val) => setState(() => activeFilter = f['label'] as String),
              selectedColor: AppTheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFFE2E8F0),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    if (activeFilter == "Tout") return AppData.alertes;
    return AppData.alertes.where((a) {
      if (activeFilter == "Urgentes") return a['type'] == 'urgent';
      if (activeFilter == "Attention") return a['type'] == 'warning';
      if (activeFilter == "Info") return a['type'] == 'info' || a['type'] == 'success';
      return true;
    }).toList();
  }
}
