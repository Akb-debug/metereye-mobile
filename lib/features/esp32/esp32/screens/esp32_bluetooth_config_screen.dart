import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../providers/esp32_bluetooth_provider.dart';
import '../widgets/bluetooth_device_list.dart';
import 'esp32_wifi_config_screen.dart';

class Esp32BluetoothConfigScreen extends StatefulWidget {
  final int compteurId;
  final String compteurReference;
  final String token;

  const Esp32BluetoothConfigScreen({
    super.key,
    required this.compteurId,
    required this.compteurReference,
    required this.token,
  });

  @override
  State<Esp32BluetoothConfigScreen> createState() => _Esp32BluetoothConfigScreenState();
}

class _Esp32BluetoothConfigScreenState extends State<Esp32BluetoothConfigScreen> {
  late final Esp32BluetoothProvider _provider;
  bool _hasNavigatedToWifi = false;

  @override
  void initState() {
    super.initState();
    _provider = Esp32BluetoothProvider();
    _provider.initialize();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (context, snapshot) {
            final adapterState = snapshot.data;

            // Si le Bluetooth est désactivé, afficher la UI d'activation
            if (adapterState == BluetoothAdapterState.off) {
              return _buildBluetoothOffScreen();
            }

            // Sinon, afficher la configuration normale
            return Consumer<Esp32BluetoothProvider>(
              builder: (context, provider, _) {
                if (provider.isConnected && provider.receivedUuid != null && !_hasNavigatedToWifi) {
                  _hasNavigatedToWifi = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _navigateToWifiConfig(context, provider);
                  });
                }

                return Column(
                  children: [
                    _buildHeader(provider),
                    const SizedBox(height: 20),
                    _buildStatus(provider),
                    const SizedBox(height: 24),
                    Expanded(
                      child: BluetoothDeviceList(
                        devices: provider.discoveredDevices,
                        isScanning: provider.isScanning,
                        onDeviceTap: (device) => provider.connectToDevice(device),
                      ),
                    ),
                    if (provider.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _buildError(provider.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            );
          },
        ),
        bottomNavigationBar: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (context, snapshot) {
            final adapterState = snapshot.data;
            if (adapterState == BluetoothAdapterState.off) {
              return const SizedBox.shrink();
            }
            return _buildBottomBar();
          },
        ),
      ),
    );
  }

  Widget _buildBluetoothOffScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_disabled,
                size: 48,
                color: AppColors.alertRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bluetooth désactivé',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Veuillez activer le Bluetooth pour rechercher et configurer votre module ESP32-CAM.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FlutterBluePlus.turnOn();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Impossible d\'activer le Bluetooth automatiquement. Veuillez l\'activer manuellement dans les paramètres.',
                            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.alertOrange,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.bluetooth, size: 24),
                label: Text(
                  'Activer le Bluetooth',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWifiConfig(BuildContext context, Esp32BluetoothProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Esp32WifiConfigScreen(
          compteurId: widget.compteurId,
          compteurReference: widget.compteurReference,
          token: widget.token,
          deviceUuid: provider.receivedUuid!,
          bluetoothProvider: provider,
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
        'Bluetooth',
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        Consumer<Esp32BluetoothProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: provider.isScanning ? AppColors.textSecondary : AppColors.primary,
              ),
              onPressed: provider.isScanning ? null : provider.startScan,
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(Esp32BluetoothProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              provider.isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            provider.isScanning ? 'Recherche...' : 'Appareils disponibles',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compteur: ${widget.compteurReference}',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(Esp32BluetoothProvider provider) {
    String text;
    Color color;

    if (provider.isScanning) {
      text = 'Scan en cours...';
      color = AppColors.primary;
    } else if (provider.discoveredDevices.isEmpty) {
      text = 'Aucun appareil trouvé';
      color = AppColors.textSecondary;
    } else {
      text = '${provider.discoveredDevices.length} appareil(s)';
      color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.isScanning)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(
              provider.discoveredDevices.isEmpty ? Icons.bluetooth_disabled : Icons.bluetooth,
              size: 14,
              color: color,
            ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alertRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.alertRed, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.alertRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Text(
          'Sélectionnez un module ESP32-CAM',
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
