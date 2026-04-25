import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../auth/welcome_screen.dart';

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
    settings = {"creditFaible": true, "coupureIminente": true, "rapportHebdo": false, "notifPic": true, "partageProprietaire": false};
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
      backgroundColor: const Color(0xFFF0F4F8),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildIoTSection(),
            _buildMeterInfoSection(),
            _buildAlertSettingsSection(),
            _buildAboutSection(),
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
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Text(
              "JD",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Jean Doe",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(
            "jean.doe@example.com",
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderBadge("Vérifié", Colors.white.withOpacity(0.2)),
              const SizedBox(width: 8),
              _buildHeaderBadge("IoT Connecté", Colors.white.withOpacity(0.2)),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mon Module IoT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.3 + (0.7 * _pulseController.value)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5 * _pulseController.value),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Infos Compteur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _buildInfoRow(Icons.electric_meter_rounded, "Type", "CashPower Prépayé"),
          _buildInfoRow(Icons.tag_rounded, "Numéro", "CP-2024-001"),
          _buildInfoRow(Icons.location_on_rounded, "Quartier", "Bè-Kpota"),
        ],
      ),
    );
  }

  Widget _buildAlertSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Paramètres des alertes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
      activeColor: const Color(0xFF2563EB),
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
          Text("MeterEye AI", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: const Color(0xFF2563EB))),
          Text("Version 1.0.0 Beta", style: TextStyle(fontSize: 11, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          Text(
            "MeterEye AI est une solution innovante permettant de suivre en temps réel sa consommation électrique grâce à la vision par ordinateur.",
            style: TextStyle(fontSize: 12, color: const Color(0xFF64748B), height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Text("metereyeai.tg", style: TextStyle(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          final navigator = Navigator.of(context);
          final appState = context.read<AppStateProvider>();
          await context.read<AuthProvider>().logout();
          appState.logout();
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFEF4444),
          elevation: 0,
        ),
        child: const Text("Se déconnecter"),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: const Color(0xFF64748B))),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
