import 'package:flutter/material.dart';
import '../../../features/compteur/models/mode_lecture.dart';
import '../../../theme/app_theme.dart';
import 'module_form_page.dart';
import 'module_qr_scanner_page.dart';

class ModuleSetupChoicePage extends StatelessWidget {
  final int compteurId;
  final ModeLecture modeLecture;
  final String token;
  final int userId;

  const ModuleSetupChoicePage({
    super.key,
    required this.compteurId,
    required this.modeLecture,
    required this.token,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isSensor = modeLecture == ModeLecture.sensor;
    final color =
        isSensor ? AppColors.alertOrange : const Color(0xFF7C3AED);
    final typeLabel = isSensor ? 'PZEM-004T (Raspberry Pi)' : 'ESP32-CAM';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurer le module'),
        backgroundColor: AppColors.background,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tete
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSensor
                              ? Icons.sensors_rounded
                              : Icons.camera_alt_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Module $typeLabel',
                              style: AppTextStyles.heading2
                                  .copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Compteur #$compteurId',
                              style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Comment voulez-vous ajouter le module ?',
                  style: AppTextStyles.heading2.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choisissez la methode qui correspond a votre situation.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                // Option QR Code
                _ChoiceCard(
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.primary,
                  title: 'Scanner le QR Code du module',
                  subtitle:
                      'Scannez le code imprime sur le module pour l\'associer automatiquement.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModuleQrScannerPage(
                        compteurId: compteurId,
                        userId: userId,
                        token: token,
                        modeLecture: modeLecture,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Option Formulaire
                _ChoiceCard(
                  icon: Icons.edit_note_rounded,
                  color: color,
                  title: 'Remplir le formulaire manuellement',
                  subtitle:
                      'Saisissez les informations du module si vous ne pouvez pas scanner le QR Code.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModuleFormPage(
                        compteurId: compteurId,
                        modeLecture: modeLecture,
                        token: token,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Lien "plus tard"
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                    child: Text(
                      'Configurer plus tard',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 22),
          ],
        ),
      ),
    );
  }
}
