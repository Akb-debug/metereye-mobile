import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../../compteur/providers/compteur_provider.dart';
import '../../../compteur/services/compteur_service.dart';
import '../services/esp32_wifi_service.dart';
import '../providers/esp32_wifi_provider.dart';
import 'esp32_config_screen.dart';


class CaptureViewScreen extends StatefulWidget {
  const CaptureViewScreen({super.key});

  @override
  State<CaptureViewScreen> createState() => _CaptureViewScreenState();
}

class _CaptureViewScreenState extends State<CaptureViewScreen> {
  bool _isCheckingConnection = true;
  int _checkAttempts = 0;
  bool _isInitializing = false;
  Uint8List? _capturedImage;
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithRetry();
    });
  }
  
  Future<void> _initializeWithRetry() async {
    if (_isInitializing) return; // garde anti-réentrance
    _isInitializing = true;
    _checkAttempts = 0;

    final provider = context.read<ESP32WifiProvider>();
    await provider.initialize();
    
    while (provider.isConfigured && !provider.isConnected && _checkAttempts < 3) {
      _checkAttempts++;
      debugPrint('CaptureView: Check attempt $_checkAttempts...');
      await provider.checkConnection();
      if (provider.isConnected) break;
      await Future.delayed(const Duration(seconds: 2));
    }
    
    if (mounted) {
      setState(() => _isCheckingConnection = false);
    }
    _isInitializing = false;
  }

  Future<void> _triggerCapture() async {
    final provider = context.read<ESP32WifiProvider>();
    final auth = context.read<AuthProvider>();
    final compteurProvider = context.read<CompteurProvider>();
    final meterId = compteurProvider.createdCompteur?.id;
    
    if (!provider.isConfigured) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
      );
      return;
    }
    
    if (!provider.isConnected) {
      await provider.checkConnection();
      if (!provider.isConnected) {
        _showConnectionError();
        return;
      }
    }
    
    final imageBytes = await provider.takeSnapshot();
    if (imageBytes != null && mounted) {
      setState(() {
        _capturedImage = imageBytes;
        _isUploading = true;
      });
      
      if (meterId != null && auth.token != null) {
        try {
          final result = await CompteurService().uploadImageReading(
            token: auth.token!,
            meterId: int.parse(meterId.toString()),
            imageBytes: imageBytes,
          );
          
          if (mounted) {
            setState(() { _isUploading = false; });
            _showSuccessDialog(CaptureResponse(
              success: true, 
              message: "Analyse terminée avec succès", 
              meterValue: result['value']?.toString() ?? result['valeur']?.toString() ?? result['valeurReleve']?.toString()
            ));
          }
        } catch(e) {
          if (mounted) {
            setState(() { _isUploading = false; });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur upload: $e'))
            );
          }
        }
      } else {
        setState(() { _isUploading = false; });
      }
    }
  }
  
  void _showConnectionError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ESP32 non accessible'),
        content: const Text(
          'L\'ESP32-CAM ne répond pas. Vérifiez que:\n\n'
          '1. L\'ESP32 est allumé\n'
          '2. Il est connecté au même WiFi\n'
          '3. L\'adresse IP est correcte',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
              );
            },
            child: const Text('Configurer'),
          ),
        ],
      ),
    );
  }
  
  void _showSuccessDialog(CaptureResponse capture) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
             Icon(Icons.check_circle, color: AppColors.alertGreen),
             SizedBox(width: 8),
             Text('Capture réussie!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Valeur détectée:',
              style: GoogleFonts.nunito(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '${capture.meterValue ?? "N/A"} kWh',
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (capture.confidence != null)
              Text(
                'Confiance: ${(capture.confidence! * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
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
          'Capture Compteur',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Indicateur ESP32 connecté
          Consumer<ESP32WifiProvider>(
            builder: (context, esp32, _) {
              if (_isCheckingConnection) {
                return _buildCheckingIndicator();
              }
              
              final bool isConnected = esp32.isConnected;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'ESP32' : 'Déconnecté',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _isCheckingConnection 
              ? null 
              : () {
                  context.read<ESP32WifiProvider>().initialize();
                },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── ZONE INFO ──────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Consumer<ESP32WifiProvider>(
                  builder: (context, provider, _) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildInfoPanel(provider),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // ── ÉTAT ET ACTIONS ──────────────────────────────────
              Consumer<ESP32WifiProvider>(
                builder: (context, provider, _) {
                  if (provider.isCapturing || _isUploading) {
                    return _buildProcessingIndicator();
                  }
                  
                  if (!provider.isConfigured) {
                    return _buildConfigButton();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bannière de vérification non-bloquante
                      if (_isCheckingConnection)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Vérification de la connexion ESP32...',
                                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      // Erreur non-bloquante
                      if (!_isCheckingConnection && provider.error != null)
                        _buildErrorCard(provider.error!),
                      if (!_isCheckingConnection && provider.error == null)
                        _buildCaptureButton(provider)
                      else if (_isCheckingConnection)
                        _buildCaptureButton(provider),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(ESP32WifiProvider provider) {
    IconData icon;
    Color color;
    String title;
    String subtitle;
    
    if (!provider.isConfigured) {
      icon = Icons.settings;
      color = Colors.orange;
      title = 'Configuration requise';
      subtitle = 'Préparez votre compteur pour commencer';
    } else if (_isCheckingConnection) {
      // Pendant la vérification initiale
      icon = Icons.sync;
      color = AppColors.primary;
      title = 'Vérification...';
      subtitle = 'Connexion à votre compteur en cours...';
    } else if (provider.isConnected) {
      icon = Icons.wifi;
      color = AppColors.alertGreen;
      title = 'Compteur Prêt';
      subtitle = 'Appuyez sur le bouton pour capturer l\'image';
    } else {
      icon = Icons.wifi_off;
      color = AppColors.alertRed;
      // Si on a une erreur 500, c'est que le WiFi marche mais la caméra non
      if (provider.error?.contains('500') ?? false) {
        icon = Icons.camera_enhance_outlined;
        title = 'Problème Caméra';
        subtitle = 'Le WiFi est OK, mais la caméra ne répond pas';
      } else {
        title = 'Compteur inaccessible';
        subtitle = 'Veuillez vous rapprocher de votre compteur';
      }
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            if (!provider.isConfigured)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              )
            else if (!_isCheckingConnection && !provider.isConnected)
              TextButton.icon(
                onPressed: () => provider.checkConnection(),
                icon: const Icon(Icons.refresh),
                label: const Text('Tester la connexion'),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConfigButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
        );
      },
      icon: const Icon(Icons.settings),
      label: Text(
        'Configurer l\'ESP32',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Widget _buildCaptureButton(ESP32WifiProvider provider) {
    final bool canCapture = provider.isConnected && !provider.isCapturing;
    
    return Column(
      children: [
        if (_capturedImage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: MemoryImage(_capturedImage!),
                fit: BoxFit.contain,
              )
            ),
          ),
        ElevatedButton.icon(
          onPressed: canCapture && !_isUploading ? _triggerCapture : null,
          icon: Icon(_isUploading || provider.isCapturing ? Icons.sync : Icons.camera_alt),
          label: Text(
            _isUploading ? 'Analyse OCR en cours...' : (provider.isCapturing ? 'Capture...' : 'Capturer avec ESP32-CAM'),
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: canCapture ? AppColors.primary : AppColors.textSecondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
            );
          },
          icon: const Icon(Icons.settings),
          label: const Text('Modifier la configuration'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(
            'Vérification de la connexion ESP32...',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Capture et analyse OCR en cours...',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.alertRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.alertRed, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Erreur',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.alertRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  context.read<ESP32WifiProvider>().clearError();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ESP32ConfigScreen()),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Configurer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.alertRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
