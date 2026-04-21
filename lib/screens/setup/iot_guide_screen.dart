import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'iot_connect_screen.dart';

class IotGuideScreen extends StatelessWidget {
  const IotGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Installation du module"),
        automaticallyImplyLeading: false, // Mandatory step
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.settings_remote_rounded, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    "Installez votre module MeterEye",
                    style: AppTextStyles.heading1.copyWith(color: Colors.white, fontSize: 20),
                  ),
                  Text(
                    "Suivez ces 4 étapes simples",
                    style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _stepCard(
                    1,
                    "Sortez le module de la boîte",
                    "Votre kit contient un module ESP32-CAM, un support adhésif et un câble USB. Vérifiez que tout est présent.",
                    Icons.inventory_2_rounded,
                    const Color(0xFFFFFBEB),
                    AppColors.alertOrange,
                  ),
                  _stepCard(
                    2,
                    "Alimentez le module",
                    "Branchez le câble USB à une prise ou batterie externe. Le voyant LED clignote en bleu : le module est prêt.",
                    Icons.power_rounded,
                    const Color(0xFFEFF6FF),
                    AppColors.primary,
                  ),
                  _stepCard(
                    3,
                    "Positionnez face au compteur",
                    "Collez le support à 5–10 cm du compteur. Le chiffre du crédit doit être bien centré devant la caméra.",
                    Icons.camera_alt_rounded,
                    const Color(0xFFECFDF5),
                    AppColors.secondary,
                  ),
                  _stepCard(
                    4,
                    "Connectez au WiFi",
                    "Rejoignez le réseau 'MeterEye-Setup' depuis votre WiFi, puis entrez vos identifiants domestiques dans l'app.",
                    Icons.wifi_rounded,
                    const Color(0xFFF3E8FF),
                    const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.alertOrange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Évitez les zones trop lumineuses (soleil direct) pour garantir une bonne lisibilité de la caméra.",
                            style: AppTextStyles.caption.copyWith(color: AppColors.alertOrange, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IotConnectScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_tethering_rounded),
                        SizedBox(width: 8),
                        Text("Connecter mon module"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepCard(int number, String title, String desc, IconData icon, Color bg, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$number",
                style: AppTextStyles.heading2.copyWith(color: AppColors.primary, fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ],
      ),
    );
  }
}
