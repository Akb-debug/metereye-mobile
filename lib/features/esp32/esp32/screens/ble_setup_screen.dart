import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../../../config/app_config.dart';
import '../../../../theme/app_theme.dart';
import '../../../compteur/services/compteur_service.dart';
import '../providers/ble_provider.dart';
import '../providers/esp32_wifi_provider.dart';

class BleSetupScreen extends StatelessWidget {
  final int compteurId;
  final String compteurRef;
  final String token;

  const BleSetupScreen({
    super.key,
    required this.compteurId,
    required this.compteurRef,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BleProvider(),
      child: _BleSetupContent(
        compteurId: compteurId,
        compteurRef: compteurRef,
        token: token,
      ),
    );
  }
}

class _BleSetupContent extends StatefulWidget {
  final int compteurId;
  final String compteurRef;
  final String token;

  const _BleSetupContent({
    required this.compteurId,
    required this.compteurRef,
    required this.token,
  });

  @override
  State<_BleSetupContent> createState() => _BleSetupContentState();
}

class _BleSetupContentState extends State<_BleSetupContent> with TickerProviderStateMixin {
  // WiFi scan state
  bool _isScanningWifi = false;
  List<WiFiAccessPoint> _wifiNetworks = [];
  String? _wifiError;
  
  // Animation
  late AnimationController _bluetoothAnimationController;
  bool _isScanningBluetooth = false;

  @override
  void initState() {
    super.initState();

    // Animation Bluetooth
    _bluetoothAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Vérifier et demander activation Bluetooth
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBluetoothAndStartScan();
    });
  }

  /// Vérifie si le Bluetooth est activé et demande l'activation si nécessaire
  Future<void> _checkBluetoothAndStartScan() async {
    // 1. Vérifier les permissions de localisation (nécessaire pour BLE sur Android)
    final locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) {
      if (mounted) {
        _showPermissionDeniedDialog('Localisation', 'Le scan Bluetooth nécessite l\'accès à la localisation.');
      }
      return;
    }

    // 2. Vérifier les permissions Bluetooth
    if (await Permission.bluetoothScan.isDenied || await Permission.bluetoothConnect.isDenied) {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      
      if (await Permission.bluetoothScan.isDenied || await Permission.bluetoothConnect.isDenied) {
        if (mounted) {
          _showPermissionDeniedDialog('Bluetooth', 'L\'application nécessite l\'accès au Bluetooth pour scanner les appareils.');
        }
        return;
      }
    }

    // 3. Vérifier l'état du Bluetooth
    final bluetoothState = await FlutterBluePlus.adapterState.first;

    if (bluetoothState != BluetoothAdapterState.on) {
      // Bluetooth désactivé - afficher une boîte de dialogue
      if (mounted) {
        await _showBluetoothDisabledDialog();
      }
      return;
    }

    // 4. Bluetooth activé - configurer et lancer le scan
    if (mounted) {
      final provider = context.read<BleProvider>();
      provider.setCallbacks(
        onAlreadyConnected: (ip) => _onAlreadyConnected(ip),
        onScanningAnimation: (isScanning) => _setBluetoothScanning(isScanning),
      );
      provider.startScan();
    }
  }

  /// Affiche une boîte de dialogue quand une permission est refusée
  void _showPermissionDeniedDialog(String permissionName, String reason) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.alertOrange, size: 28),
              const SizedBox(width: 12),
              Text(
                'Permission requise',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            '$reason\n\nVeuillez accorder la permission $permissionName dans les paramètres de l\'application.',
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Affiche une boîte de dialogue pour demander l'activation du Bluetooth
  Future<void> _showBluetoothDisabledDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.bluetooth_disabled, color: AppColors.alertOrange, size: 28),
              const SizedBox(width: 12),
              Text(
                'Bluetooth désactivé',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Pour configurer votre module ESP32, vous devez activer le Bluetooth de votre téléphone.',
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retour à l'écran précédent
                Navigator.of(context).pop();
              },
              child: Text(
                'Annuler',
                style: GoogleFonts.nunito(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                // Ouvrir les paramètres Bluetooth système
                await FlutterBluePlus.turnOn();
                // Attendre un peu puis vérifier à nouveau
                await Future.delayed(const Duration(seconds: 2));
                _checkBluetoothAndStartScan();
              },
              icon: const Icon(Icons.bluetooth, size: 20),
              label: Text(
                'Activer Bluetooth',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    _bluetoothAnimationController.dispose();
    super.dispose();
  }
  
  void _setBluetoothScanning(bool isScanning) {
    if (mounted) {
      setState(() {
        _isScanningBluetooth = isScanning;
      });
      if (isScanning) {
        _bluetoothAnimationController.repeat();
      } else {
        _bluetoothAnimationController.stop();
      }
    }
  }
  
  void _onAlreadyConnected(String ip) {
    if (!mounted) return;
    
    // Sauvegarder l'IP localement pour persistance
    final wifiProvider = context.read<ESP32WifiProvider>();
    wifiProvider.configure(ip);
    
    // Créer et associer le module automatiquement
    _createAndAssociateModule().then((_) {
      if (mounted) {
        // Sauvegarder aussi l'UUID lié pour reconnexion future
        _saveLinkedEspUuid();
        
        // Retour au dashboard ou fermeture du setup
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }
  
  Future<void> _saveLinkedEspUuid() async {
    final provider = context.read<BleProvider>();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('linked_esp_uuid', provider.uuid ?? 'unknown');
    await prefs.setString('linked_esp_ip', provider.wifiIp ?? '0.0.0.0');
    await prefs.setInt('linked_compteur_id', widget.compteurId);
    debugPrint('ESP32 linked saved: ${provider.uuid}');
  }
  
  Future<void> _createAndAssociateModule() async {
    final provider = context.read<BleProvider>();
    final userId = CompteurService.extractUserIdFromToken(widget.token);
    
    if (userId == null) {
      debugPrint('Erreur: impossible d\'extraire userId du token');
      return;
    }
    
    try {
      final service = CompteurService();
      await service.createAndAssociateModuleEsp32(
        token: widget.token,
        userId: userId,
        compteurId: widget.compteurId,
        uuid: provider.uuid ?? 'unknown',
        ipAddress: provider.wifiIp ?? '0.0.0.0',
        wifiSsid: 'AlreadyConnected',
        captureInterval: 3600,
      );
      debugPrint('Module ESP32 créé et associé avec succès (déjà connecté)');
    } catch (e) {
      debugPrint('Erreur création module ESP32: $e');
    }
  }

  Future<void> _scanWifiNetworks() async {
    setState(() {
      _isScanningWifi = true;
      _wifiError = null;
    });

    try {
      var locationStatus = await Permission.location.status;
      if (locationStatus.isDenied) {
        locationStatus = await Permission.location.request();
      }
      if (!locationStatus.isGranted) {
        setState(() {
          _wifiError = 'Permission de localisation requise pour scanner les réseaux WiFi';
          _isScanningWifi = false;
        });
        return;
      }

      final canStartScan = await WiFiScan.instance.startScan();
      if (!canStartScan) {
        setState(() {
          _wifiError = 'Activez la localisation pour scanner les réseaux WiFi';
          _isScanningWifi = false;
        });
        return;
      }

      await Future.delayed(const Duration(seconds: 2));
      final results = await WiFiScan.instance.getScannedResults();

      if (mounted) {
        setState(() {
          _wifiNetworks = results
            .where((ap) => ap.ssid.isNotEmpty)
            .toList()
            ..sort((a, b) => b.level.compareTo(a.level));
          _isScanningWifi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wifiError = 'Erreur lors du scan WiFi';
          _isScanningWifi = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(provider),
      body: _buildBody(provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BleProvider provider) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
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
      actions: [
        if (_isScanningBluetooth)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          ),
        if (provider.isConnected)
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.alertRed),
            onPressed: () => provider.disconnect(),
          ),
      ],
    );
  }

  Widget _buildBody(BleProvider provider) {
    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (provider.state == BleState.configured) {
      return _buildSuccessState(provider);
    }

    if (provider.isConnected) {
      return _buildWifiConfigState(provider);
    }

    if (provider.state == BleState.scanning) {
      return _buildScanningState();
    }

    return _buildDeviceList(provider);
  }

  Widget _buildErrorState(BleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.alertRed.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              provider.clearError();
              provider.startScan();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Réessayer', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BleProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.alertGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppColors.alertGreen, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            'WiFi Configuré !',
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (provider.wifiIp != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'IP: ${provider.wifiIp}',
                style: GoogleFonts.robotoMono(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Voir mon compteur', style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiConfigState(BleProvider provider) {
    if (_wifiNetworks.isEmpty && !_isScanningWifi) {
      _scanWifiNetworks();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Card
          _buildDeviceCard(provider),
          const SizedBox(height: 24),
          // WiFi Section
          _buildWifiSection(),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BleProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bluetooth_connected, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: provider.wifiStatus == 'connected' ? Colors.green : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.wifiStatus == 'connected' ? 'Module connecté au WiFi' : 'Module connecté en BLE',
                      style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getDeviceDisplayName(provider),
                  style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (provider.wifiIp != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'IP: ${provider.wifiIp}',
                    style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Retourne un nom d'affichage propre pour le module
  String _getDeviceDisplayName(BleProvider provider) {
    // Si WiFi connecté, afficher le nom du device
    if (provider.wifiStatus == 'connected') {
      return provider.connectedDevice?.name ?? 'MeterEye ESP32';
    }
    // Sinon afficher l'UUID ou le nom tronqué
    final uuid = provider.uuid;
    if (uuid == null || uuid.isEmpty) {
      return provider.connectedDevice?.name ?? 'ESP32';
    }
    // Si c'est un JSON ou texte très long, tronquer
    if (uuid.length > 20) {
      return '${uuid.substring(0, 17)}...';
    }
    return uuid;
  }

  Widget _buildWifiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Réseaux WiFi disponibles',
              style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            if (_isScanningWifi)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text('Scan...', style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_wifiError != null) ...[
          _buildWifiError(),
          const SizedBox(height: 16),
        ],
        if (_isScanningWifi)
          _buildWifiScanning()
        else if (_wifiNetworks.isEmpty)
          _buildWifiEmpty()
        else
          _buildWifiList(),
      ],
    );
  }

  Widget _buildWifiError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.alertRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _wifiError!,
              style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.alertRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiScanning() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
            const SizedBox(height: 16),
            Text('Recherche des réseaux...', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiEmpty() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Aucun réseau trouvé', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Assurez-vous que le WiFi est activé et réessayez',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _scanWifiNetworks,
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            label: Text('Réessayer', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _wifiNetworks.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.borderColor.withValues(alpha: 0.5), indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final network = _wifiNetworks[index];
          final signalStrength = _getSignalStrength(network.level);
          final signalColor = _getSignalColor(network.level);

          return InkWell(
            onTap: () => _showPasswordModal(network.ssid),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == _wifiNetworks.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: signalColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.wifi, size: 20, color: signalColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.ssid,
                          style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(color: signalColor, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(signalStrength, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: signalColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSignalStrength(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Très bon';
    if (rssi >= -70) return 'Bon';
    if (rssi >= -80) return 'Faible';
    return 'Très faible';
  }

  Color _getSignalColor(int rssi) {
    if (rssi >= -50) return AppColors.secondary;
    if (rssi >= -60) return AppColors.secondary.withValues(alpha: 0.8);
    if (rssi >= -70) return AppColors.alertOrange;
    if (rssi >= -80) return AppColors.alertOrange.withValues(alpha: 0.8);
    return AppColors.alertRed;
  }

  void _showPasswordModal(String ssid) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Configurer le WiFi',
                        style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réseau: $ssid',
                        style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: 'Entrez le mot de passe WiFi',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                            onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Veuillez entrer le mot de passe';
                          if (value.length < 8) return 'Le mot de passe doit contenir au moins 8 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _configureWiFi(ssid, passwordController.text);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Configurer', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Annuler', style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _configureWiFi(String ssid, String password) async {
    final provider = context.read<BleProvider>();
    final success = await provider.configureWiFi(
      ssid,
      password,
      backendUrl: AppConfig.baseUrl,
      token: widget.token,
      compteurId: widget.compteurId,
    );

    if (success && mounted) {
      // Sauvegarder l'IP localement pour reconnexion future
      await _saveLinkedEspUuid();

      // Créer et associer le module ESP32 au compteur dans le backend
      try {
        final service = CompteurService();
        final userId = CompteurService.extractUserIdFromToken(widget.token);

        if (userId == null) {
          debugPrint('Erreur: impossible d\'extraire userId du token');
          return;
        }

        await service.createAndAssociateModuleEsp32(
          token: widget.token,
          userId: userId,
          compteurId: widget.compteurId,
          uuid: provider.uuid ?? 'unknown',
          ipAddress: provider.wifiIp ?? '0.0.0.0',
          wifiSsid: ssid,
          captureInterval: 3600,
        );
        debugPrint('Module ESP32 créé et associé avec succès');
      } catch (e) {
        debugPrint('Erreur création/association module ESP32: $e');
        // On continue même si l'API échoue (module peut déjà exister)
      }
    }

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${provider.error ?? "Configuration échouée"}', style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildScanningState() {
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation Bluetooth pulsante
            AnimatedBuilder(
              animation: _bluetoothAnimationController,
              builder: (context, child) {
                final animValue = _bluetoothAnimationController.value;
                final sinValue = sin(animValue * 2 * pi);
                final opacity = (0.1 + 0.1 * sinValue).clamp(0.05, 0.25);
                final shadowOpacity = (0.2 + 0.3 * sinValue).clamp(0.1, 0.5);
                final blurRadius = (20 + 10 * sinValue).clamp(10.0, 35.0);
                final spreadRadius = (2 + 3 * sinValue).clamp(0.0, 6.0);
                final iconSize = (40 + 5 * sinValue).clamp(35.0, 50.0);

                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: shadowOpacity),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.bluetooth_searching,
                    size: iconSize,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Recherche d\'ESP32...',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Assurez-vous que votre module ESP32 est allumé',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            // Indicateur de scan actif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan en cours',
                    style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(BleProvider provider) {
    if (provider.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun ESP32 trouvé',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Vérifiez que le module est allumé et à proximité',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.startScan(),
              icon: const Icon(Icons.refresh),
              label: Text('Scanner à nouveau', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Modules ESP32 détectés',
                  style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              TextButton.icon(
                onPressed: () => provider.startScan(),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('Rafraîchir', style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: provider.devices.length,
            itemBuilder: (context, index) {
              final device = provider.devices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.bluetooth, color: AppColors.primary),
                  ),
                  title: Text(
                    device.name,
                    style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    device.id,
                    style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ),
                  onTap: () => provider.connect(device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
