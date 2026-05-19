import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_snackbar.dart';
import '../../core/error_translator.dart';
import '../../features/compteur/models/mode_lecture.dart';
import '../../features/compteur/screens/compteur_next_step_screen.dart';
import '../../features/compteur/screens/create_compteur_screen.dart';
import '../../features/iot/models/iot_module_response.dart';
import '../../features/iot/screens/bluetooth_wifi_config_page.dart';
import '../../features/iot/screens/module_setup_choice_page.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profil_provider.dart';
import '../../services/meter_service.dart';
import '../../theme/responsive_utils.dart';
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
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (profil.error != null && !profil.isLoading)
                      _buildErrorBanner(profil),
                    _buildProfileHeader(profil),
                    if (!profil.isLoading)
                      _buildSetupIncompleteBanner(context, profil),
                    const SizedBox(height: 8),
                    _buildIoTSection(profil),
                    _buildMeterInfoSection(profil),
                    _buildAlertSettingsSection(profil),
                    _buildAboutSection(),
                    _buildLogoutButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
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
      margin: EdgeInsets.fromLTRB(
          context.hPad, context.statusBarH + 8, context.hPad, 0),
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

  // ── Banner configuration incomplète ───────────────────────────────────────

  Widget _buildSetupIncompleteBanner(BuildContext context, ProfilProvider profil) {
    final hasCompteur   = profil.compteurActif != null;
    final hasModeLecture= profil.compteurActif?.modeLectureConfigure != null;
    final isManual      = profil.compteurActif?.isManualMode ?? false;
    final hasModule     = profil.module != null;
    final moduleConfigured = profil.module?.configured ?? false;

    final steps = <_SetupStepData>[];

    // Étape 1 : créer un compteur
    if (!hasCompteur) {
      steps.add(_SetupStepData(
        icon: Icons.electric_meter_rounded,
        title: 'Créer votre compteur',
        subtitle: 'Ajoutez votre premier compteur électrique',
        onTap: () => _goToCreateCompteur(context),
      ));
    }

    // Étape 2 : configurer le mode de lecture
    if (hasCompteur && !hasModeLecture && !hasModule) {
      steps.add(_SetupStepData(
        icon: Icons.settings_input_antenna_rounded,
        title: 'Configurer le mode de lecture',
        subtitle: 'Choisissez Manuel, ESP32-CAM ou Capteur PZEM',
        onTap: () => _showModeLectureSheet(context, profil),
      ));
    }

    // Étape 3 : associer le module IoT
    if (hasCompteur && !isManual && !hasModule &&
        (hasModeLecture || !hasModule)) {
      steps.add(_SetupStepData(
        icon: Icons.developer_board_rounded,
        title: 'Associer le module IoT',
        subtitle: 'Scannez le QR code ou saisissez l\'identifiant du module',
        onTap: () => _goToModuleSetup(context, profil),
      ));
    }

    // Étape 4 : envoyer la config WiFi au module via Bluetooth
    if (hasCompteur && hasModule && !moduleConfigured) {
      steps.add(_SetupStepData(
        icon: Icons.bluetooth_rounded,
        title: 'Connexion WiFi du module',
        subtitle: 'Envoyez les identifiants WiFi à votre module IoT',
        onTap: () => _goToBluetoothConfig(context, profil),
      ));
    }

    if (steps.isEmpty) return _buildSetupCompleteBanner(context, profil);

    final nextStep = steps.first;

    return Container(
      margin: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.construction_rounded,
                      size: 18, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Configuration en attente',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF92400E),
                            fontFamily: 'Nunito',
                          )),
                      Text(
                        '${steps.length} étape${steps.length > 1 ? 's' : ''} '
                        'restante${steps.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFDE68A)),
          // ── Liste des étapes (informatif, numérotées) ──
          ...steps.asMap().entries.map(
                (e) => _buildStepInfo(e.key + 1, e.value, isNext: e.key == 0),
              ),
          // ── Bouton CTA unique ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: nextStep.onTap,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  nextStep.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepInfo(int number, _SetupStepData step,
      {required bool isNext}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isNext
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isNext ? Colors.white : const Color(0xFFF59E0B))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isNext
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF64748B),
                        fontFamily: 'Nunito')),
                const SizedBox(height: 1),
                Text(step.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner configuration terminée ────────────────────────────────────────

  Widget _buildSetupCompleteBanner(BuildContext context, ProfilProvider profil) {
    return Container(
      margin: EdgeInsets.fromLTRB(context.hPad, 16, context.hPad, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Configuration terminée',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF065F46),
                            fontFamily: 'Nunito',
                          )),
                      Text('Votre module est opérationnel',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFBBF7D0)),
          // ── Boutons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _goToReconfiguration(context, profil),
                      icon: const Icon(Icons.settings_rounded, size: 16),
                      label: const Text('Reconfigurer',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(
                            color: Color(0xFF2563EB), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _confirmReinitialisation(context, profil),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Réinitialiser',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(
                            color: Color(0xFFEF4444), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToReconfiguration(BuildContext context, ProfilProvider profil) {
    if (profil.module != null) {
      _goToBluetoothConfig(context, profil);
    } else if (profil.compteurActif != null) {
      _goToModuleSetup(context, profil);
    } else {
      _goToCreateCompteur(context);
    }
  }

  Future<void> _confirmReinitialisation(
      BuildContext context, ProfilProvider profil) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser la configuration ?',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                fontFamily: 'Nunito')),
        content: const Text(
          'Cette action dissociera votre module IoT. Votre compteur et vos relevés seront conservés.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Réinitialiser',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await profil.refresh();
      if (mounted) {
        AppSnackbar.successOnMessenger(
            messenger, 'Module dissocié. Vous pouvez en configurer un nouveau.');
      }
    }
  }

  // ── Navigation setup ───────────────────────────────────────────────────────

  void _goToCreateCompteur(BuildContext context) {
    final token = context.read<AuthProvider>().token ?? '';
    final profilProv = context.read<ProfilProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCompteurScreen(token: token),
      ),
    ).then((_) {
      if (mounted) profilProv.refresh();
    });
  }

  void _goToBluetoothConfig(BuildContext context, ProfilProvider profil) {
    final token = context.read<AuthProvider>().token ?? '';
    final m = profil.module!;
    final profilProv = context.read<ProfilProvider>();
    final compteurId = m.compteurId ?? profil.compteurActif?.id ?? 0;

    // Convertit ModuleIotModel → IotModuleResponse pour BluetoothWifiConfigPage
    final moduleResponse = IotModuleResponse(
      deviceCode: m.deviceCode,
      deviceId: m.deviceCode,
      typeModule: m.typeModule ?? 'IOT_MODULE',
      status: m.statut,
      configured: m.configured,
      captureInterval: m.captureInterval,
      compteurId: compteurId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BluetoothWifiConfigPage(
          module: moduleResponse,
          compteurId: compteurId,
          token: token,
        ),
      ),
    ).then((_) {
      if (mounted) profilProv.refresh();
    });
  }

  void _goToModuleSetup(BuildContext context, ProfilProvider profil) {
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final userId = int.tryParse(auth.profile?.id ?? '0') ?? 0;
    final compteur = profil.compteurActif!;
    final modeLecture = _modeLectureFromString(compteur.modeLectureConfigure)
        ?? ModeLecture.esp32Cam;
    final profilProv = context.read<ProfilProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleSetupChoicePage(
          compteurId: compteur.id,
          modeLecture: modeLecture,
          token: token,
          userId: userId,
        ),
      ),
    ).then((_) {
      if (mounted) profilProv.refresh();
    });
  }

  Future<void> _showModeLectureSheet(
      BuildContext context, ProfilProvider profil) async {
    // Capture before async gap
    final auth = context.read<AuthProvider>();
    final token = auth.token ?? '';
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final profilProv = context.read<ProfilProvider>();
    final compteur = profil.compteurActif!;

    final selected = await showModalBottomSheet<ModeLecture>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ModeLectureSheet(),
    );
    if (selected == null || !mounted) return;

    try {
      await MeterService().configureModeLecture(
        compteur.id,
        modeLecture: _modeLectureToApi(selected),
      );
      if (!mounted) return;
      nav.push(
        MaterialPageRoute(
          builder: (_) => CompteurNextStepScreen(
            modeLecture: selected,
            compteurId: compteur.id,
            compteurReference: compteur.reference,
            token: token,
          ),
        ),
      ).then((_) {
        if (mounted) profilProv.refresh();
      });
    } catch (e) {
      if (mounted) AppSnackbar.errorOnMessenger(messenger, ErrorTranslator.fromException(e));
    }
  }

  static ModeLecture? _modeLectureFromString(String? s) => switch (
        s?.toUpperCase()) {
        'ESP32_CAM' => ModeLecture.esp32Cam,
        'SENSOR'    => ModeLecture.sensor,
        'MANUAL'    => ModeLecture.manual,
        _           => null,
      };

  static String _modeLectureToApi(ModeLecture m) => switch (m) {
        ModeLecture.manual   => 'MANUAL',
        ModeLecture.esp32Cam => 'ESP32_CAM',
        ModeLecture.sensor   => 'SENSOR',
      };

  // ── En-tête profil ─────────────────────────────────────────────────────────

  Widget _buildProfileHeader(ProfilProvider profil) {
    final isLoadingUser = profil.isLoading && profil.user == null;
    final sw = context.sw;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: context.statusBarH + 24,
        bottom: 30,
        left: context.hPad,
        right: context.hPad,
      ),
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
                  _skeletonLine((sw * 0.3).clamp(80.0, 160.0), 18),
                  const SizedBox(height: 8),
                  _skeletonLine((sw * 0.4).clamp(100.0, 200.0), 13),
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
          Wrap(
            spacing: 8,
            children: [
              if (profil.user != null)
                _buildHeaderBadge(
                    'Vérifié', Colors.white.withValues(alpha: 0.2)),
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
      margin: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
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
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skeletonLine(
                            (context.sw * 0.35).clamp(80.0, 160.0), 14),
                        const SizedBox(height: 6),
                        _skeletonLine(
                            (context.sw * 0.25).clamp(60.0, 120.0), 12),
                      ]),
                ),
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
                  _iotConfigureButton(profil),
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
      margin: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
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
      margin: EdgeInsets.symmetric(
          horizontal: context.hPad, vertical: 8),
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
              const Expanded(
                child: Text('Paramètres des alertes',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
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
                  AppSnackbar.error(
                    context,
                    'Impossible de mettre à jour les notifications. Réessayez.',
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

  // ── Section À propos ───────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Container(
      margin: EdgeInsets.all(context.hPad),
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

  // ── Bouton déconnexion ─────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.hPad, 8, context.hPad, 0),
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
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B)),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end),
          ),
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

  // ── Wire bouton IoT existant ───────────────────────────────────────────────

  Widget _iotConfigureButton(ProfilProvider profil) {
    final hasMode = profil.compteurActif?.modeLectureConfigure != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: hasMode
            ? () => _goToModuleSetup(context, profil)
            : () => _showModeLectureSheet(context, profil),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: Text(
          hasMode ? 'Associer le module IoT' : 'Configurer un module IoT',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _skeletonInfoRow() {
    final sw = context.sw;
    return Row(
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
          width: (sw * 0.2).clamp(48.0, 100.0),
          height: 13,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Spacer(),
        Container(
          width: (sw * 0.25).clamp(60.0, 130.0),
          height: 13,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ── Données d'une étape de configuration ──────────────────────────────────────

class _SetupStepData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SetupStepData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

// ── Sheet sélection du mode de lecture ────────────────────────────────────────

class _ModeLectureSheet extends StatelessWidget {
  const _ModeLectureSheet();

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Choisir le mode de lecture',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFamily: 'Nunito',
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sélectionnez la méthode de relevé pour ce compteur.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _ModeOption(
            icon: Icons.edit_note_rounded,
            color: const Color(0xFF2563EB),
            title: 'Manuel',
            subtitle: 'Saisie manuelle des relevés depuis l\'application',
            onTap: () => Navigator.pop(context, ModeLecture.manual),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            icon: Icons.camera_alt_rounded,
            color: const Color(0xFF7C3AED),
            title: 'ESP32-CAM',
            subtitle: 'Lecture automatique par caméra via Bluetooth',
            onTap: () => Navigator.pop(context, ModeLecture.esp32Cam),
          ),
          const SizedBox(height: 12),
          _ModeOption(
            icon: Icons.sensors_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Capteur PZEM-004T',
            subtitle: 'Relevé automatique par capteur de courant',
            onTap: () => Navigator.pop(context, ModeLecture.sensor),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Nunito',
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.7), size: 20),
          ],
        ),
      ),
    );
  }
}
