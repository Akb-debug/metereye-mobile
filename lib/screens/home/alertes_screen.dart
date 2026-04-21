import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../widgets/alerte_item.dart';

class AlertesScreen extends StatefulWidget {
  const AlertesScreen({super.key});

  @override
  State<AlertesScreen> createState() => _AlertesScreenState();
}

class _AlertesScreenState extends State<AlertesScreen> {
  String _filter = "Toutes";

  List<Map<String, dynamic>> get _filteredAlerts {
    if (_filter == "Toutes") return AppData.alertes;
    if (_filter == "🔴 Urgentes") return AppData.alertes.where((a) => a['type'] == 'urgent').toList();
    if (_filter == "⚠️ Attention") return AppData.alertes.where((a) => a['type'] == 'warning').toList();
    if (_filter == "✅ Info") return AppData.alertes.where((a) => a['type'] == 'success' || a['type'] == 'info').toList();
    return AppData.alertes;
  }

  @override
  Widget build(BuildContext context) {
    int unreadCount = AppData.alertes.where((a) => a['lue'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Alertes"),
        backgroundColor: AppColors.background,
        actions: [
          _buildBadgeIcon(Icons.notifications_rounded, unreadCount),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── FILTRES ────────────────────────────────────────────────────────
          _buildFilters(),

          // ── LISTE ALERTES ──────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: _filteredAlerts.length,
              itemBuilder: (context, index) {
                return AlerteItem(data: _filteredAlerts[index]);
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
              decoration: const BoxDecoration(color: AppColors.alertRed, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                "$count",
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Nunito',
                fontSize: 13,
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
}
