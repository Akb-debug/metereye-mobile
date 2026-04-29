// 🔄 MODIFIÉ — profil_screen.dart — données statiques → dynamiques via
//   ProfilProvider (Consumer), initState déclenche loadProfil(), switchs
//   appellent toggleNotification(), gestion d'erreur globale + banner retry.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profil_provider.dart';
import '../auth/welcome_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Déclenche le chargement des données après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilProvider>().loadProfil();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Build principal ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Consumer<ProfilProvider>(
        builder: (context, profil, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(profil),
                // Banner d'erreur globale (hors chargement initial)
                if (profil.error != null && !profil.isLoading)
                  _buildErrorBanner(context, profil),
                const SizedBox(height: 16),
                _buildIoTSection(profil),
                _buildMeterInfoSection(profil),
                _buildAlertSettingsSection(context, profil),
                _buildAboutSection(),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── En-tête profil ────────────────────────────────────────────────────────

  Widget _buildProfileHeader(ProfilProvider profil) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Avatar — placeholder gris pendant le chargement
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: profil.isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : Text(
                    profil.initialesAvatar,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // Nom — placeholder pendant le chargement
          profil.isLoading
              ? _shimmerLine(width: 160, height: 20)
              : Text(
                  profil.nomAffiche,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
          const SizedBox(height: 4),
          profil.isLoading
              ? _shimmerLine(width: 200, height: 14)
              : Text(
                  profil.emailAffiche,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge "Vérifié" visible dès que le profil est chargé
              if (profil.user != null)
                _buildHeaderBadge('Vérifié', Colors.white.withOpacity(0.2)),
              if (profil.user != null) const SizedBox(width: 8),
              // Badge "IoT Connecté" uniquement si le module est en ligne
              if (profil.isIoTConnecte)
                _buildHeaderBadge(
                    'IoT Connecté', Colors.white.withOpacity(0.2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Section module IoT ────────────────────────────────────────────────────

  Widget _buildIoTSection(ProfilProvider profil) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon Module IoT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

          if (profil.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (profil.module == null)
            // Aucun module configuré
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aucun module IoT configuré',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Configurer'),
                  ),
                ],
              ),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: profil.isIoTConnecte
                  // Point vert animé si connecté
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(
                                0.3 + (0.7 * _pulseController.value)),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981)
                                    .withOpacity(0.5 * _pulseController.value),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        );
                      },
                    )
                  // Point gris statique si hors ligne
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
              title: Text(
                '${profil.moduleTitre} — ${profil.moduleStatut}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            _buildInfoRow(Icons.access_time_rounded, 'Dernière lecture',
                profil.derniereLecture),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Recalibrer la caméra'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section infos compteur ────────────────────────────────────────────────

  Widget _buildMeterInfoSection(ProfilProvider profil) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infos Compteur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (profil.isLoading) ...[
            _shimmerInfoRow(),
            _shimmerInfoRow(),
            _shimmerInfoRow(),
          ] else ...[
            _buildInfoRow(
                Icons.electric_meter_rounded, 'Type', profil.compteurType),
            _buildInfoRow(Icons.tag_rounded, 'Numéro', profil.compteurNumero),
            _buildInfoRow(
                Icons.location_on_rounded, 'Quartier', profil.compteurAdresse),
          ],
        ],
      ),
    );
  }

  // ── Section paramètres d'alertes ──────────────────────────────────────────

  Widget _buildAlertSettingsSection(
      BuildContext context, ProfilProvider profil) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Paramètres des alertes',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (profil.isSavingSettings) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          _buildSwitchTile(
            context,
            profil,
            key: 'creditFaible',
            title: 'Alerte crédit faible (< 200 unités)',
            value: profil.switchCreditFaible,
          ),
          _buildSwitchTile(
            context,
            profil,
            key: 'coupureIminente',
            title: 'Alerte coupure imminente',
            value: profil.switchCoupureIminente,
          ),
          _buildSwitchTile(
            context,
            profil,
            key: 'rapportHebdo',
            title: 'Rapport hebdomadaire',
            value: profil.switchRapportHebdo,
          ),
          _buildSwitchTile(
            context,
            profil,
            key: 'notifPic',
            title: 'Notifications de pic',
            value: profil.switchNotifPic,
          ),
          _buildSwitchTile(
            context,
            profil,
            key: 'partageProprietaire',
            title: 'Partage avec propriétaire',
            value: profil.switchPartageProprietaire,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    ProfilProvider profil, {
    required String key,
    required String title,
    required bool value,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: (val) async {
        try {
          await profil.toggleNotification(key, val);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de la mise à jour. Réessayer.'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        }
      },
      title: Text(
        title,
        style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B)),
      ),
      activeColor: const Color(0xFF2563EB),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ── Section À propos ──────────────────────────────────────────────────────

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
          const Text('MeterEye AI',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF2563EB))),
          const Text('Version 1.0.0 Beta',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          const Text(
            'MeterEye AI est une solution innovante permettant de suivre en temps réel sa consommation électrique grâce à la vision par ordinateur.',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          const Text(
            'metereyeai.tg',
            style: TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Bouton déconnexion (logique inchangée) ────────────────────────────────

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
        child: const Text('Se déconnecter'),
      ),
    );
  }

  // ── Banner d'erreur globale ───────────────────────────────────────────────

  Widget _buildErrorBanner(BuildContext context, ProfilProvider profil) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEF4444),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              profil.error ?? 'Erreur de chargement',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => profil.refresh(),
            child: const Text('Réessayer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Widgets utilitaires ───────────────────────────────────────────────────

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  /// Ligne placeholder grise animée (skeleton)
  Widget _shimmerLine({double width = 140, double height = 14}) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// Ligne skeleton pour les sections info compteur
  Widget _shimmerInfoRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Container(
              width: 80,
              height: 13,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4))),
          const Spacer(),
          Container(
              width: 100,
              height: 13,
              decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}
