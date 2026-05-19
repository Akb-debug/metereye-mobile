import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../theme/app_theme.dart';
import '../providers/ble_provider.dart';
import '../providers/esp32_wifi_provider.dart';
import 'capture_view_screen.dart';
// import '../../../providers/dashboard_provider.dart'; // Supprimé

/// Écran unifié de setup ESP32 - BLE pour config WiFi, récupération auto de l'IP
class ESP32SetupScreen extends StatefulWidget {
  const ESP32SetupScreen({super.key});

  @override
  State<ESP32SetupScreen> createState() => _ESP32SetupScreenState();
}

class _ESP32SetupScreenState extends State<ESP32SetupScreen> {
  bool _autoConfigured = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    
    // Configurer le callback quand l'ESP32 est déjà connecté au WiFi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bleProvider = context.read<BleProvider>();
      bleProvider.setCallbacks(
        onAlreadyConnected: (ip) async {
          // L'ESP32 est déjà connecté au WiFi, récupérer l'IP automatiquement
          print('[ESP32] Auto-configured with IP: $ip');
          
          final wifiProvider = context.read<ESP32WifiProvider>();
          await wifiProvider.configure(ip);
          
          if (mounted) {
            setState(() => _autoConfigured = true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ESP32 connecté automatiquement! IP: $ip'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
      
      // Initialiser le provider WiFi
      context.read<ESP32WifiProvider>().initialize();
      
      // Si pas connecté en BLE, démarrer le scan automatiquement
      if (!bleProvider.isConnected && bleProvider.state != BleState.scanning) {
        print('[ESP32Setup] Auto-starting BLE scan...');
        bleProvider.startScan();
      }
    });
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
          'Connexion ESP32',
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
          child: Consumer2<BleProvider, ESP32WifiProvider>(
            builder: (context, ble, wifi, _) {
              // Si Bluetooth désactivé
              if (ble.isBluetoothOff || ble.error == 'bluetooth_off') {
                return _buildBluetoothOffView(ble);
              }
              
              // Si déjà configuré en WiFi (prêt à capturer)
              if (wifi.isConnected || _autoConfigured) {
                if (!_hasNavigated) {
                  _hasNavigated = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const CaptureViewScreen()),
                      );
                    }
                  });
                }
                return _buildConnectedView(wifi);
              }
              
              // Si connecté en BLE mais pas encore configuré en WiFi
              if (ble.isConnected && !ble.isConfiguring && ble.wifiIp == null) {
                return _buildWiFiConfigView(ble);
              }
              
              // Si en cours de configuration WiFi
              if (ble.isConfiguring) {
                return _buildConfiguringView(ble);
              }
              
              // Si connecté en BLE et l'ESP32 a déjà une IP (WiFi déjà configuré)
              if (ble.isConnected && ble.wifiIp != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (_hasNavigated) return;
                  await _autoConfigureFromBle(context, ble.wifiIp!);
                  if (mounted && !_hasNavigated) {
                    _hasNavigated = true;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const CaptureViewScreen()),
                    );
                  }
                });
                return _buildAutoConfiguringView(ble.wifiIp!);
              }
              
              // Sinon, scanner les devices BLE
              return _buildScanView(ble);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _autoConfigureFromBle(BuildContext context, String ip) async {
    if (_autoConfigured) return;
    
    final wifiProvider = context.read<ESP32WifiProvider>();
    // Sauvegarder l'IP sans bloquer sur le check HTTP
    // (l'ESP32 peut mettre quelques secondes à démarrer son serveur)
    await wifiProvider.saveIpOnly(ip);
    setState(() => _autoConfigured = true);
  }

  Widget _buildBluetoothOffView(BleProvider ble) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_disabled, size: 56, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                'Bluetooth désactivé',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pour configurer votre ESP32-CAM, veuillez activer le Bluetooth de votre appareil.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Bouton activation
        StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          builder: (context, snapshot) {
            final isOn = snapshot.data == BluetoothAdapterState.on;
            if (isOn) {
              // Bluetooth vient d'être activé, relancer le scan
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ble.clearError();
                ble.startScan();
              });
            }
            return ElevatedButton.icon(
              onPressed: isOn ? null : () async {
                try {
                  await FlutterBluePlus.turnOn();
                } catch (_) {
                  // Sur iOS ou si l'activation automatique n'est pas supportée,
                  // montrer un message pour activer manuellement
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Activer le Bluetooth'),
                        content: const Text(
                          'Veuillez activer le Bluetooth manuellement dans les paramètres de votre appareil.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              icon: Icon(isOn ? Icons.check_circle : Icons.bluetooth),
              label: Text(
                isOn ? 'Bluetooth activé ✓' : 'Activer le Bluetooth',
                style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOn ? AppColors.alertGreen : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildScanView(BleProvider ble) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HEADER ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.bluetooth, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Rechercher l\'ESP32-CAM',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Assurez-vous que l\'ESP32 est allumé à proximité.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // ── BOUTON SCAN ────────────────────────────────
        if (ble.state == BleState.scanning)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Recherche en cours...'),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () => ble.startScan(),
            icon: const Icon(Icons.search),
            label: Text(
              'Rechercher l\'ESP32',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        
        const SizedBox(height: 24),
        
        // ── LISTE DEVICES ───────────────────────────────
        if (ble.devices.isEmpty && ble.state != BleState.scanning)
          Center(
            child: Text(
              'Aucun ESP32 trouvé',
              style: GoogleFonts.nunito(color: AppColors.textSecondary),
            ),
          )
        else ...[
          // Auto-connect au premier device trouvé (logique invisible)
          if (ble.devices.isNotEmpty && !ble.isConnected && ble.state == BleState.scanning)
            Builder(builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Future.delayed(Duration.zero, () async {
                  print('[ESP32Setup] Auto-connecting to ${ble.devices.first.name}');
                  await ble.stopScan();
                  final success = await ble.connect(ble.devices.first);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Échec de connexion auto'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              });
              return const SizedBox.shrink();
            }),
          Expanded(
            child: ListView.builder(
              itemCount: ble.devices.length,
              itemBuilder: (context, index) {
                final device = ble.devices[index];
                final bool isConnecting = ble.state == BleState.connecting;
                final bool isThisDevice = ble.connectedDevice?.id == device.id;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.developer_board),
                    title: Text(device.name),
                    subtitle: Text(device.id),
                    trailing: isConnecting && !isThisDevice
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : ElevatedButton(
                            onPressed: isConnecting 
                                ? null 
                                : () async {
                                    final success = await ble.connect(device);
                                    if (!success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Échec de connexion'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            child: const Text('Connecter'),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWiFiConfigView(BleProvider ble) {
    // Scanner automatiquement les réseaux au premier affichage
    if (!ble.isScanningWiFi && ble.wifiNetworks.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ble.scanWiFiNetworks();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HEADER ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.alertGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.wifi, size: 48, color: AppColors.alertGreen),
              const SizedBox(height: 12),
              Text(
                'ESP32 Connecté en Bluetooth!',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez votre réseau WiFi ci-dessous :',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ── SCAN EN COURS ─────────────────────────────
        if (ble.isScanningWiFi)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Recherche des réseaux WiFi...'),
              ],
            ),
          )
        else if (ble.wifiNetworks.isEmpty)
          Center(
            child: Column(
              children: [
                Text(
                  'Aucun réseau trouvé',
                  style: GoogleFonts.nunito(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => ble.scanWiFiNetworks(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Relancer le scan'),
                ),
              ],
            ),
          )
        else
          // ── LISTE DES RÉSEAUX ─────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Réseaux disponibles (${ble.wifiNetworks.length})',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: ble.wifiNetworks.length,
                    itemBuilder: (context, index) {
                      final network = ble.wifiNetworks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.wifi),
                          title: Text(network),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // Ouvrir dialogue pour mot de passe
                            _showPasswordDialog(context, ble, network);
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Bouton rafraîchir
                TextButton.icon(
                  onPressed: () => ble.scanWiFiNetworks(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Relancer le scan'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showPasswordDialog(BuildContext context, BleProvider ble, String ssid) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connecter à $ssid'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mot de passe WiFi',
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              final success = await ble.configureWiFi(
                ssid,
                passwordController.text,
              );
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connexion à $ssid en cours...'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguringView(BleProvider ble) {
    // Parser le statut pour afficher un message user-friendly
    String statusMessage = _getUserFriendlyStatus(ble.wifiStatus);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Configuration WiFi en cours...',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Cela peut prendre jusqu\'à 30 secondes',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Convertit le statut JSON en message lisible
  String _getUserFriendlyStatus(String? rawStatus) {
    if (rawStatus == null) return 'Connexion au réseau...';
    
    // Si c'est du JSON, essayer de parser
    if (rawStatus.trim().startsWith('{')) {
      try {
        // Extraire le status simplement sans dépendance jsonDecode
        if (rawStatus.contains('"status":"error"')) {
          return 'Erreur de connexion';
        } else if (rawStatus.contains('"status":"connected"')) {
          return 'Connecté avec succès!';
        } else if (rawStatus.contains('"status":"connecting"')) {
          return 'Connexion en cours...';
        } else if (rawStatus.contains('"status":"failed"')) {
          return 'Échec de connexion - vérifiez le mot de passe';
        }
      } catch (_) {
        // Fallback: ne pas afficher le JSON brut
      }
    }
    
    // Si c'est déjà un message simple, l'afficher tel quel
    if (rawStatus.length < 50 && !rawStatus.contains('{')) {
      return rawStatus;
    }
    
    // Message par défaut (ne jamais afficher de JSON brut)
    return 'Connexion au réseau...';
  }

  Widget _buildAutoConfiguringView(String ip) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi, size: 64, color: AppColors.alertGreen),
          const SizedBox(height: 24),
          Text(
            'ESP32 déjà connecté au WiFi!',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IP détectée: $ip',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Configuration automatique...',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(ESP32WifiProvider wifi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── HEADER ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.alertGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.alertGreen.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: AppColors.alertGreen),
              const SizedBox(height: 12),
              Text(
                'ESP32 Prêt!',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.alertGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connecté à ${wifi.esp32Ip}',
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // ── BOUTON ACCUEIL ─────────────────────────────
        ElevatedButton.icon(
          onPressed: () {
            if (!mounted) return;
            
            // Rafraîchir les données si nécessaire (CompteurProvider)
            // context.read<CompteurProvider>().refresh(); 
            
            // Retourner au Dashboard principal
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.dashboard_rounded),
          label: Text(
            'Accéder au Dashboard',
            style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ── INFO ──────────────────────────────────────
        Text(
          'L\'ESP32-CAM est configuré et prêt à capturer des images de votre compteur.',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
