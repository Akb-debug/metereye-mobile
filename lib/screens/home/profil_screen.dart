// 🔄 MODIFIÉ — profil_screen.dart — ajouts : Consumer<ProfilProvider>, données dynamiques,
//              banner erreur global, états de chargement, switchs liés au backend

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfilProvider>().loadProfil();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfilProvider>(
      builder: (context, profil, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F8),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (profil.error != null && !profil.isLoading)
                  _buildErrorBanner(profil),
                _buildProfileHeader(profil),
                const SizedBox(height: 16),
                _buildIoTSection(profil),
                _buildMeterInfoSection(profil),
                _buildAlertSettingsSection(profil),
                _buildAboutSection(),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Banner d'erreur global ─────────────────────────────────────────────────

  Widget _buildErrorBanner(ProfilProvider profil) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 48, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              profil.error!,
              style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: profil.refresh,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Réessayer',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── En-tête profil ─────────────────────────────────────────────────────────

  Widget _buildProfileHeader(ProfilProvider profil) {
    final isLoadingUser = profil.isLoading && profil.user == null;

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
          isLoadingUser
              ? CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    profil.initialesAvatar,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          isLoadingUser
              ? Column(children: [
                  _skeletonLine(120, 18),
                  const SizedBox(height: 8),
                  _skeletonLine(160, 13),
                ])
              : Column(children: [
                  Text(
                    profil.nomAffiche,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  Text(
                    profil.emailAffiche,
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (profil.user != null)
                _buildHeaderBadge(
                    'Vérifié', Colors.white.withValues(alpha: 0.2)),
              if (profil.user != null) const SizedBox(width: 8),
              if (profil.isIoTConnecte)
                _buildHeaderBadge(
                    'IoT Connecté', Colors.white.withValues(alpha: 0.2)),
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
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // ── Section IoT ────────────────────────────────────────────────────────────

  Widget _buildIoTSection(ProfilProvider profil) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mon Module IoT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (profil.isLoading && profil.module == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(children: [
                _skeletonCircle(12),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _skeletonLine(140, 14),
                  const SizedBox(height: 6),
                  _skeletonLine(100, 12),
                ]),
              ]),
            )
          else if (profil.module == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aucun module IoT configuré',
                      style:
                          TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          size: 18),
                      label: const Text('Configurer un module IoT',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: profil.isIoTConnecte
                  ? AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(
                                alpha: 0.3 + 0.7 * _pulseController.value),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(
                                    alpha: 0.5 * _pulseController.value),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
              title: Text(
                '${profil.moduleTitre} ${profil.isIoTConnecte ? "en ligne" : "hors ligne"}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(profil.moduleStatut,
                  style: const TextStyle(fontSize: 12)),
            ),
            _buildInfoRow(Icons.access_time_rounded, 'Dernière lecture',
                profil.derniereLecture),
            if (profil.module?.signalLabel != null)
              _buildInfoRow(Icons.wifi_rounded, 'Signal',
                  profil.module!.signalLabel!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Recalibrer la caméra',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(
                      color: Color(0xFF2563EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Section compteur ───────────────────────────────────────────────────────

  Widget _buildMeterInfoSection(ProfilProvider profil) {
    final isLoadingCompteur =
        profil.isLoading && profil.compteurActif == null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Infos Compteur',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (isLoadingCompteur) ...[
            const SizedBox(height: 12),
            _skeletonInfoRow(),
            const SizedBox(height: 8),
            _skeletonInfoRow(),
            const SizedBox(height: 8),
            _skeletonInfoRow(),
          ] else ...[
            _buildInfoRow(Icons.electric_meter_rounded, 'Type',
                profil.compteurType),
            _buildInfoRow(Icons.tag_rounded, 'Numéro', profil.compteurNumero),
            _buildInfoRow(
                Icons.location_on_rounded, 'Quartier', profil.compteurAdresse),
          ],
        ],
      ),
    );
  }

  // ── Section alertes ────────────────────────────────────────────────────────

  Widget _buildAlertSettingsSection(ProfilProvider profil) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          )
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
                const SizedBox(width: 10),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF2563EB)),
                ),
              ],
            ],
          ),
          _buildSwitchTile(
            'creditFaible',
            'Alerte crédit faible (< 200 unités)',
            profil.switchCreditFaible,
            profil,
          ),
          _buildSwitchTile(
            'coupureIminente',
            'Alerte coupure imminente',
            profil.switchCoupureIminente,
            profil,
          ),
          _buildSwitchTile(
            'rapportHebdo',
            'Rapport hebdomadaire',
            profil.switchRapportHebdo,
            profil,
          ),
          _buildSwitchTile(
            'notifPic',
            'Notifications de pic',
            profil.switchNotifPic,
            profil,
          ),
          _buildSwitchTile(
            'partageProprietaire',
            'Partage avec propriétaire',
            profil.switchPartageProprietaire,
            profil,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String key, String title, bool value, ProfilProvider profil) {
    return SwitchListTile(
      value: value,
      onChanged: profil.isSavingSettings
          ? null
          : (val) {
              profil.toggleNotification(key, val).catchError((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Erreur lors de la mise à jour. Réessayer.'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
              });
            },
      title: Text(title,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B))),
      activeThumbColor: const Color(0xFF2563EB),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  // ── Section À propos (statique) ────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MeterEye AI',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Color(0xFF2563EB))),
          Text('Version 1.0.0 Beta',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          SizedBox(height: 12),
          Text(
            'MeterEye AI est une solution innovante permettant de suivre en temps réel sa consommation électrique grâce à la vision par ordinateur.',
            style: TextStyle(
                fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 12),
          Text('metereyeai.tg',
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  fontSize: 13)),
        ],
      ),
    );
  }

  // ── Bouton déconnexion — logique INCHANGÉE ─────────────────────────────────

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
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
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Se déconnecter',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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

  Widget _skeletonLine(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
      );

  Widget _skeletonCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
      );

  Widget _skeletonInfoRow() => Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 80,
            height: 13,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 100,
            height: 13,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
}
