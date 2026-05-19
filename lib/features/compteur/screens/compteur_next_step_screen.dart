import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mode_lecture.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/home/home_shell.dart';
import '../../../theme/app_theme.dart';
import '../../iot/screens/module_setup_choice_page.dart';

class CompteurNextStepScreen extends StatelessWidget {
  final ModeLecture modeLecture;
  final int compteurId;
  final String compteurReference;
  final String token;

  const CompteurNextStepScreen({
    super.key,
    required this.modeLecture,
    required this.compteurId,
    required this.compteurReference,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIot = modeLecture == ModeLecture.esp32Cam ||
        modeLecture == ModeLecture.sensor;

    final String title;
    final String description;
    final IconData icon;
    final Color iconColor;

    switch (modeLecture) {
      case ModeLecture.manual:
        title = 'Compteur créé avec succès';
        description =
            'Le compteur $compteurReference est prêt. Vous pouvez maintenant saisir des relevés manuellement depuis l\'écran d\'accueil.';
        icon = Icons.edit_note_rounded;
        iconColor = AppColors.primary;
        break;
      case ModeLecture.esp32Cam:
        title = 'Configurer l\'ESP32-CAM';
        description =
            'Le compteur $compteurReference a été créé. Associez un module ESP32-CAM via Bluetooth pour automatiser les relevés.';
        icon = Icons.camera_alt_rounded;
        iconColor = const Color(0xFF7C3AED);
        break;
      case ModeLecture.sensor:
        title = 'Configurer le capteur PZEM-004T';
        description =
            'Le compteur $compteurReference a été créé. Associez un capteur PZEM-004T pour automatiser les relevés d\'énergie.';
        icon = Icons.sensors_rounded;
        iconColor = AppColors.alertOrange;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Étape suivante'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.heading1.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _continuer(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIot ? iconColor : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isIot ? 'Configurer le module' : 'Aller au tableau de bord',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                  ),
                ),
              ),
            ),
            if (isIot) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => _allerAccueil(context),
                  child: Text(
                    'Configurer plus tard',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _continuer(BuildContext context) {
    if (modeLecture == ModeLecture.esp32Cam ||
        modeLecture == ModeLecture.sensor) {
      final userId =
          int.tryParse(context.read<AuthProvider>().profile?.id ?? '0') ?? 0;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ModuleSetupChoicePage(
            compteurId: compteurId,
            modeLecture: modeLecture,
            token: token,
            userId: userId,
          ),
        ),
      );
    } else {
      _allerAccueil(context);
    }
  }

  void _allerAccueil(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }
}
