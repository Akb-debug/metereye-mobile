import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_data.dart';
import '../widgets/section_title.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Map<String, bool> settings;

  @override
  void initState() {
    super.initState();
    settings = Map.from(AppData.alertSettings);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── EN-TÊTE AVATAR ──────────────────────────────────────────────────
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // ── SECTION COMPTEUR IoT ───────────────────────────────────────────
            _buildIoTSection(),

            // ── INFOS COMPTEUR ─────────────────────────────────────────────────
            _buildMeterInfoSection(),

            // ── PARAMÈTRES ALERTES ─────────────────────────────────────────────
            _buildAlertSettingsSection(),

            // ── À PROPOS ───────────────────────────────────────────────────────
            _buildAboutSection(),

            // ── BOUTON DÉCONNEXION ──────────────────────────────────────────────
            _buildLogoutButton(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Text(
              AppData.userAvatar,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            AppData.userName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            AppData.userEmail,
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderBadge("✅ Vérifié", Colors.white.withOpacity(0.2)),
              const SizedBox(width: 8),
              _buildHeaderBadge("📡 IoT Connecté", Colors.white.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildIoTSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("📡 Mon Module IoT"),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.alertGreen.withOpacity(0.3 + (0.7 * _pulseController.value)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.alertGreen.withOpacity(0.5 * _pulseController.value),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                );
              },
            ),
            title: const Text("ESP32-CAM en ligne", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text("Module actif et synchronisé", style: TextStyle(fontSize: 12)),
          ),
          _buildInfoRow(Icons.access_time_rounded, "Dernière lecture", "Aujourd'hui 09:47"),
          _buildInfoRow(Icons.wifi_rounded, "Signal", "Bon (3/4 barres)"),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            child: const Text("Recalibrer la caméra"),
          ),
        ],
      ),
    );
  }

  Widget _buildMeterInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("⚡ Infos Compteur"),
          _buildInfoRow(Icons.electric_meter_rounded, "Type", "CashPower Prépayé"),
          _buildInfoRow(Icons.tag_rounded, "Numéro", AppData.numCompteur),
          _buildInfoRow(Icons.location_on_rounded, "Quartier", AppData.quartier),
        ],
      ),
    );
  }

  Widget _buildAlertSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle("🔔 Paramètres des alertes"),
          _buildSwitchTile("creditFaible", "Alerte crédit faible (< 200 unités)"),
          _buildSwitchTile("coupureIminente", "Alerte coupure imminente"),
          _buildSwitchTile("rapportHebdo", "Rapport hebdomadaire"),
          _buildSwitchTile("notifPic", "Notifications de pic"),
          _buildSwitchTile("partageProprietaire", "Partage avec propriétaire"),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String key, String title) {
    return SwitchListTile(
      value: settings[key] ?? false,
      onChanged: (val) => setState(() => settings[key] = val),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      activeColor: AppTheme.primary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("⚡ MeterEye AI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
          const Text("Version 1.0.0 Beta — CDEJ TG0121", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          const Text(
            "MeterEye AI est une solution innovante permettant de suivre en temps réel sa consommation électrique grâce à la vision par ordinateur, favorisant ainsi la maîtrise énergétique et la transparence locative au Togo.",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          const Text("metereyeai.tg", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: AppTheme.alertRed,
          elevation: 0,
        ),
        child: const Text("🚪 Se déconnecter"),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
