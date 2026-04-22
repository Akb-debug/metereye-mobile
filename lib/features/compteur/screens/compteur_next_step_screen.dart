import 'package:flutter/material.dart';
import '../models/mode_lecture.dart';
import '../../../screens/dashboard_screen.dart';

class CompteurNextStepScreen extends StatelessWidget {
  final ModeLecture modeLecture;
  final int compteurId;
  final String compteurReference;

  const CompteurNextStepScreen({
    super.key,
    required this.modeLecture,
    required this.compteurId,
    required this.compteurReference,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    String description;

    switch (modeLecture) {
      case ModeLecture.manual:
        title = 'Prochaine étape : relevé manuel';
        description =
            'Le compteur $compteurReference a été créé. Tu peux maintenant passer à la saisie manuelle du premier relevé.';
        break;
      case ModeLecture.esp32Cam:
        title = 'Prochaine étape : onboarding ESP32-CAM';
        description =
            'Le compteur $compteurReference a été créé. Tu dois maintenant scanner le QR code du module ESP32-CAM et l’associer au compteur.';
        break;
      case ModeLecture.sensor:
        title = 'Prochaine étape : configuration capteur';
        description =
            'Le compteur $compteurReference a été créé. Tu dois maintenant configurer le capteur PZEM-004T.';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Étape suivante')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(description),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}