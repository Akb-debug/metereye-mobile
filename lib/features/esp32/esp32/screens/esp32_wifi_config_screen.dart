import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../../../theme/app_theme.dart';
import '../providers/esp32_bluetooth_provider.dart';

class Esp32WifiConfigScreen extends StatefulWidget {
  final int compteurId;
  final String compteurReference;
  final String token;
  final String deviceUuid;
  final Esp32BluetoothProvider bluetoothProvider;

  const Esp32WifiConfigScreen({
    super.key,
    required this.compteurId,
    required this.compteurReference,
    required this.token,
    required this.deviceUuid,
    required this.bluetoothProvider,
  });

  @override
  State<Esp32WifiConfigScreen> createState() => _Esp32WifiConfigScreenState();
}

class _Esp32WifiConfigScreenState extends State<Esp32WifiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isScanningWifi = true;
  String? _selectedSsid;
  List<WiFiAccessPoint> _wifiNetworks = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scanWifiNetworks();
  }

  Future<void> _scanWifiNetworks() async {
    setState(() {
      _isScanningWifi = true;
      _errorMessage = null;
    });

    try {
      // Vérifier et demander la permission de localisation
      var locationStatus = await Permission.location.status;
      
      if (locationStatus.isDenied) {
        // Demander la permission
        locationStatus = await Permission.location.request();
      }
      
      if (locationStatus.isPermanentlyDenied) {
        // Permission refusée définitivement, afficher un message
        setState(() {
          _errorMessage = 'Permission de localisation refusée. Veuillez l\'activer dans les paramètres de l\'application.';
          _isScanningWifi = false;
        });
        return;
      }
      
      if (!locationStatus.isGranted) {
        setState(() {
          _errorMessage = 'Permission de localisation requise pour scanner les réseaux WiFi';
          _isScanningWifi = false;
        });
        return;
      }

      // Démarrer le scan
      final canStartScan = await WiFiScan.instance.startScan();
      if (!canStartScan) {
        setState(() {
          _errorMessage = 'Activez la localisation dans les paramètres système pour scanner les réseaux WiFi';
          _isScanningWifi = false;
        });
        return;
      }

      // Attendre un peu pour que les résultats arrivent
      await Future.delayed(const Duration(seconds: 2));

      // Récupérer les résultats
      final results = await WiFiScan.instance.getScannedResults();

      if (mounted) {
        setState(() {
          // Filtrer et trier par force de signal
          _wifiNetworks = results
            .where((ap) => ap.ssid.isNotEmpty) // Filtrer les SSID vides
            .toList()
            ..sort((a, b) => b.level.compareTo(a.level)); // Trier par signal décroissant
          _isScanningWifi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Activez la localisation dans les paramètres système pour scanner les réseaux WiFi';
          _isScanningWifi = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.bluetoothProvider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildDeviceCard(),
              const SizedBox(height: 28),
              _buildWifiForm(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Configuration WiFi',
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.2),
                AppColors.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.wifi,
            size: 32,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Connecter au WiFi',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Configurez le réseau WiFi pour le module ESP32-CAM',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module connecté',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.deviceUuid,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réseaux disponibles',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_isScanningWifi)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan...',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Message d'erreur si présent
          if (_errorMessage != null) ...[
            _buildErrorMessage(_errorMessage!),
            const SizedBox(height: 16),
          ],

          // Liste des réseaux WiFi
          if (_isScanningWifi)
            _buildScanningNetworks()
          else if (_wifiNetworks.isEmpty)
            _buildEmptyNetworks()
          else
            _buildNetworksList(),

          const SizedBox(height: 24),

        ],
      ),
    );
  }

  Widget _buildScanningNetworks() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Recherche des réseaux...',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.alertRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNetworks() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off,
            size: 48,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun réseau trouvé',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assurez-vous que le WiFi est activé et réessayez',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _scanWifiNetworks,
            icon: Icon(Icons.refresh, color: AppColors.primary),
            label: Text(
              'Réessayer',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworksList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _wifiNetworks.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: AppColors.borderColor.withOpacity(0.5),
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final network = _wifiNetworks[index];
          final isSelected = _selectedSsid == network.ssid;
          final signalStrength = _getSignalStrength(network.level);
          final signalColor = _getSignalColor(network.level);
          final isSecured = _isNetworkSecured(network);

          return InkWell(
            onTap: () {
              _showPasswordModal(network.ssid);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.05) : null,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == _wifiNetworks.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  // Icône WiFi avec force du signal
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : signalColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.wifi,
                      size: 20,
                      color: isSelected ? AppColors.primary : signalColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Infos réseau
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          network.ssid,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: signalColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              signalStrength,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: signalColor,
                              ),
                            ),
                            if (isSecured) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.lock_outline,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Icône flèche
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
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
    if (rssi >= -60) return AppColors.secondary.withOpacity(0.8);
    if (rssi >= -70) return AppColors.alertOrange;
    if (rssi >= -80) return AppColors.alertOrange.withOpacity(0.8);
    return AppColors.alertRed;
  }

  bool _isNetworkSecured(WiFiAccessPoint network) {
    final caps = network.capabilities.toUpperCase();
    return caps.contains('WPA') || caps.contains('WEP') || caps.contains('PSK') || caps.contains('EAP');
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Titre
                      Text(
                        'Configurer le WiFi',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réseau: $ssid',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Champ mot de passe
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          hintText: 'Entrez le mot de passe WiFi',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le mot de passe';
                          }
                          if (value.length < 8) {
                            return 'Le mot de passe doit contenir au moins 8 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Bouton Configurer
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              setState(() {
                                _selectedSsid = ssid;
                                _passwordController.text = passwordController.text;
                              });
                              _submitWifiConfig();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Configurer le WiFi',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Bouton Annuler
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Future<void> _submitWifiConfig() async {
    if (_selectedSsid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez sélectionner un réseau WiFi',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.alertOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await widget.bluetoothProvider.configureWifi(
      ssid: _selectedSsid!,
      password: _passwordController.text.trim(),
      compteurId: widget.compteurId,
      token: widget.token,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configuration WiFi envoyée avec succès!',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Redirection vers le dashboard après 1.5 secondes
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.bluetoothProvider.errorMessage ?? 'Erreur lors de la configuration WiFi',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.alertRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
