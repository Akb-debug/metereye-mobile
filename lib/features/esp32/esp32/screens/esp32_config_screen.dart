import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../providers/esp32_wifi_provider.dart';
import 'capture_view_screen.dart';

/// Écran de configuration de l'ESP32-CAM
class ESP32ConfigScreen extends StatefulWidget {
  const ESP32ConfigScreen({super.key});

  @override
  State<ESP32ConfigScreen> createState() => _ESP32ConfigScreenState();
}

class _ESP32ConfigScreenState extends State<ESP32ConfigScreen> {
  final _ipController = TextEditingController();
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Charger la config existante
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ESP32WifiProvider>();
      if (provider.esp32Ip != null) {
        _ipController.text = provider.esp32Ip!;
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une IP')),
      );
      return;
    }

    setState(() => _isTesting = true);

    final provider = context.read<ESP32WifiProvider>();
    await provider.configure(ip);

    setState(() => _isTesting = false);

    if (provider.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ESP32 connecté avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Configuration ESP32',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<ESP32WifiProvider>(
            builder: (context, provider, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(provider),
                  const SizedBox(height: 24),
                  Text(
                    'Adresse IP de l\'ESP32-CAM',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrez l\'adresse IP affichée sur le moniteur série de l\'ESP32 après connexion WiFi.',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '192.168.1.42',
                      prefixIcon: const Icon(Icons.wifi),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isTesting || provider.status == ESP32ConnectionStatus.checking)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    ElevatedButton.icon(
                      onPressed: _testAndSave,
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                        provider.isConfigured ? 'Tester & Mettre à jour' : 'Tester & Sauvegarder',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (provider.isConfigured) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => provider.clearConfiguration(),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Supprimer la configuration',
                          style: GoogleFonts.nunito(),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                  const Spacer(),
                  if (provider.isConnected)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CaptureViewScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        'Aller à la Capture',
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.alertGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ESP32WifiProvider provider) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? subtitle;

    switch (provider.status) {
      case ESP32ConnectionStatus.connected:
        statusColor = AppColors.alertGreen;
        statusIcon = Icons.check_circle;
        statusText = 'ESP32 Connecté';
        subtitle = 'IP: ${provider.esp32Ip}';
        break;
      case ESP32ConnectionStatus.disconnected:
        statusColor = AppColors.alertRed;
        statusIcon = Icons.error_outline;
        statusText = 'ESP32 Déconnecté';
        subtitle = provider.error;
        break;
      case ESP32ConnectionStatus.checking:
        statusColor = AppColors.primary;
        statusIcon = Icons.sync;
        statusText = 'Vérification...';
        break;
      case ESP32ConnectionStatus.notConfigured:
        statusColor = Colors.orange;
        statusIcon = Icons.settings;
        statusText = 'Non configuré';
        subtitle = 'Entrez l\'IP de l\'ESP32';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Statut inconnu';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (provider.status == ESP32ConnectionStatus.disconnected ||
              provider.status == ESP32ConnectionStatus.notConfigured)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.checkConnection(),
              color: statusColor,
            ),
        ],
      ),
    );
  }
}
