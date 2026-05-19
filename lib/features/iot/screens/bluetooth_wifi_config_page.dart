import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wifi_scan/wifi_scan.dart';
import '../../../theme/app_theme.dart';
import '../models/bluetooth_provisioning_payload.dart';
import '../models/iot_module_response.dart';
import '../providers/bluetooth_provisioning_provider.dart';
import 'module_status_page.dart';

class BluetoothWifiConfigPage extends StatelessWidget {
  final IotModuleResponse module;
  final int compteurId;
  final String token;

  const BluetoothWifiConfigPage({
    super.key,
    required this.module,
    required this.compteurId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BluetoothProvisioningProvider(),
      child: _BluetoothWifiConfigContent(
        module: module,
        compteurId: compteurId,
        token: token,
      ),
    );
  }
}

class _BluetoothWifiConfigContent extends StatefulWidget {
  final IotModuleResponse module;
  final int compteurId;
  final String token;

  const _BluetoothWifiConfigContent({
    required this.module,
    required this.compteurId,
    required this.token,
  });

  @override
  State<_BluetoothWifiConfigContent> createState() =>
      _BluetoothWifiConfigContentState();
}

class _BluetoothWifiConfigContentState
    extends State<_BluetoothWifiConfigContent> with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  List<WiFiAccessPoint> _wifiNetworks = [];
  bool _isScanningWifi = false;

  // ── Bluetooth adapter state ───────────────────────────────────────────────
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  bool _bluetoothOn =
      FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Écoute les changements d'état de l'adaptateur BT en temps réel
    _adapterSub = FlutterBluePlus.adapterState.listen(_onAdapterState);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initBle());
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onAdapterState(BluetoothAdapterState state) {
    if (!mounted) return;
    final isOn = state == BluetoothAdapterState.on;
    setState(() => _bluetoothOn = isOn);

    // Bluetooth vient d'être activé → lancer le scan automatiquement
    if (isOn && _permissionsGranted) {
      final prov = context.read<BluetoothProvisioningProvider>();
      if (!prov.isConnected && !prov.isScanning) {
        prov.clearError();
        prov.startScan();
      }
    }
  }

  Future<void> _initBle() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
    _permissionsGranted = true;
    if (!mounted) return;

    // Ne lancer le scan que si le BT est déjà activé
    if (_bluetoothOn) {
      context.read<BluetoothProvisioningProvider>().startScan();
    }
  }

  Future<void> _requestEnableBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        // Fallback si turnOn() n'est pas disponible
        await openAppSettings();
      }
    } else {
      // iOS : impossible d'activer programmatiquement → paramètres système
      await openAppSettings();
    }
  }

  Future<void> _scanWifi() async {
    if (_isScanningWifi) return;
    setState(() => _isScanningWifi = true);
    try {
      final loc = await Permission.location.request();
      if (!loc.isGranted) {
        if (mounted) setState(() => _isScanningWifi = false);
        return;
      }
      await WiFiScan.instance.startScan();
      // 3 secondes pour capturer aussi les points d'accès mobiles
      await Future.delayed(const Duration(seconds: 3));
      final results = await WiFiScan.instance.getScannedResults();
      if (mounted) {
        // Déduplication par SSID : on garde le signal le plus fort
        final Map<String, WiFiAccessPoint> deduped = {};
        for (final ap in results.where((ap) => ap.ssid.isNotEmpty)) {
          if (!deduped.containsKey(ap.ssid) ||
              ap.level > deduped[ap.ssid]!.level) {
            deduped[ap.ssid] = ap;
          }
        }
        setState(() {
          _wifiNetworks = deduped.values.toList()
            ..sort((a, b) => b.level.compareTo(a.level));
          _isScanningWifi = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanningWifi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BluetoothProvisioningProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configurer le WiFi du module'),
        backgroundColor: AppColors.background,
        actions: [
          if (prov.isConnected)
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.alertRed),
              onPressed: prov.disconnect,
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _buildBody(context, prov),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, BluetoothProvisioningProvider prov) {
    // Bluetooth désactivé — prioritaire sur tout le reste
    if (!_bluetoothOn) return _buildBluetoothOff();

    // Envoi en cours
    if (prov.isSending) return _buildSending();

    // Erreur BLE (autre que bluetooth_off)
    if (prov.phase == ProvisioningPhase.error && !prov.isConnected) {
      return _buildError(ctx, prov);
    }

    // Connecté — afficher la config WiFi
    if (prov.isConnected) return _buildWifiConfig(ctx, prov);

    // Scan des modules BLE
    return _buildBleScan(ctx, prov);
  }

  // ── Bluetooth désactivé ───────────────────────────────────────────────────

  Widget _buildBluetoothOff() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.alertOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_disabled_rounded,
                size: 48,
                color: AppColors.alertOrange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bluetooth désactivé',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Activez le Bluetooth de votre téléphone pour détecter et configurer votre module.',
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            if (Platform.isAndroid) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _requestEnableBluetooth,
                  icon: const Icon(Icons.bluetooth_rounded, size: 20),
                  label: const Text('Activer le Bluetooth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'La recherche de modules démarrera automatiquement une fois activé.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Allez dans Réglages → Bluetooth et activez-le, puis revenez ici.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Scan BLE ──────────────────────────────────────────────────────────────

  Widget _buildBleScan(BuildContext ctx, BluetoothProvisioningProvider prov) {
    if (prov.isScanning && prov.devices.isEmpty) {
      return _buildScanning();
    }

    if (prov.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Aucun module detecte',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito')),
            const SizedBox(height: 8),
            Text('Verifiez que le module est allume et a portee',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: prov.startScan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scanner a nouveau'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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
                child: Text('Modules detectes',
                    style: AppTextStyles.heading2.copyWith(fontSize: 16)),
              ),
              if (prov.isScanning)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              else
                TextButton.icon(
                  onPressed: prov.startScan,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Rafraichir'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: prov.devices.length,
            itemBuilder: (_, i) {
              final dev = prov.devices[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bluetooth_rounded,
                        color: AppColors.primary),
                  ),
                  title: Text(dev.name,
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700)),
                  subtitle: Text(dev.id,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white, size: 18),
                  ),
                  onTap: () => prov.connect(dev),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final s = sin(_pulseCtrl.value * 2 * pi);
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: (0.08 + 0.08 * s).clamp(0.04, 0.18)),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                          alpha: (0.2 + 0.25 * s).clamp(0.05, 0.45)),
                      blurRadius: (20 + 10 * s).clamp(10.0, 32.0),
                      spreadRadius: (2 + 3 * s).clamp(0.0, 6.0),
                    ),
                  ],
                ),
                child: Icon(Icons.bluetooth_searching_rounded,
                    size: (40 + 5 * s).clamp(35.0, 48.0),
                    color: AppColors.primary),
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Recherche du module...',
              style: AppTextStyles.heading2.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          Text('Assurez-vous que le module est allume',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Config WiFi ───────────────────────────────────────────────────────────

  Widget _buildWifiConfig(BuildContext ctx, BluetoothProvisioningProvider prov) {
    if (_wifiNetworks.isEmpty && !_isScanningWifi) {
      _scanWifi();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte module connecte
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bluetooth_connected_rounded,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          prov.connectedDevice?.name ?? 'Module connecte',
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('Connecte en Bluetooth',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Réseaux WiFi disponibles',
                        style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Sélectionnez le réseau pour connecter le module',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isScanningWifi)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              else
                IconButton(
                  onPressed: _scanWifi,
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.primary, size: 22),
                  tooltip: 'Actualiser',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isScanningWifi && _wifiNetworks.isEmpty)
            const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary))
          else if (_wifiNetworks.isEmpty)
            _buildWifiEmpty()
          else
            _buildWifiList(ctx, prov),
        ],
      ),
    );
  }

  Widget _buildWifiEmpty() {
    return Column(
      children: [
        Icon(Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text('Aucun reseau trouve',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _scanWifi,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          label: const Text('Rafraichir',
              style: TextStyle(color: AppColors.primary, fontFamily: 'Nunito')),
        ),
      ],
    );
  }

  Widget _buildWifiList(
      BuildContext ctx, BluetoothProvisioningProvider prov) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _wifiNetworks.length,
        separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppColors.borderColor.withValues(alpha: 0.5),
            indent: 16,
            endIndent: 16),
        itemBuilder: (_, i) {
          final net = _wifiNetworks[i];
          final signalColor = _signalColor(net.level);
          return InkWell(
            onTap: () => _showPasswordModal(ctx, prov, net.ssid),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.wifi_rounded, color: signalColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(net.ssid,
                            style: AppTextStyles.body
                                .copyWith(fontWeight: FontWeight.w600)),
                        Text(_signalLabel(net.level),
                            style: AppTextStyles.caption
                                .copyWith(color: signalColor)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPasswordModal(
      BuildContext ctx, BluetoothProvisioningProvider prov, String ssid) {
    final pwdCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
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
                      decoration: BoxDecoration(
                          color: AppColors.borderColor,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Connexion WiFi',
                      style: AppTextStyles.heading1.copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('Reseau : $ssid',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: pwdCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe WiFi',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setModal(() => obscure = !obscure),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5)),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (v.length < 8) return 'Minimum 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(sheetCtx);
                          _sendProvisioning(ctx, prov, ssid, pwdCtrl.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Envoyer la configuration',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito')),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendProvisioning(BuildContext ctx,
      BluetoothProvisioningProvider prov, String ssid, String password) async {
    final payload = BluetoothProvisioningPayload.build(
      ssid: ssid,
      password: password,
      meterId: widget.compteurId,
      deviceId: widget.module.deviceId,
      token: widget.token,
      moduleType: widget.module.typeModule,
    );

    final ok = await prov.sendProvisioning(payload);

    if (ok && ctx.mounted) {
      Navigator.pushReplacement(
        ctx,
        MaterialPageRoute(
          builder: (_) => ModuleStatusPage(
            deviceCode: widget.module.deviceCode,
            deviceId: widget.module.deviceId,
            token: widget.token,
          ),
        ),
      );
    }
  }

  // ── Envoi en cours ────────────────────────────────────────────────────────

  Widget _buildSending() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text('Envoi de la configuration...',
              style: AppTextStyles.heading2.copyWith(fontSize: 17)),
          const SizedBox(height: 8),
          Text('Ne quittez pas cette page',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── Erreur ────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext ctx, BluetoothProvisioningProvider prov) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_disabled_rounded,
                size: 64,
                color: AppColors.alertRed.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(prov.error ?? 'Erreur Bluetooth',
                textAlign: TextAlign.center,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                prov.clearError();
                prov.startScan();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _signalColor(int rssi) {
    if (rssi >= -50) return AppColors.secondary;
    if (rssi >= -65) return AppColors.alertOrange;
    return AppColors.alertRed;
  }

  String _signalLabel(int rssi) {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -65) return 'Bon';
    if (rssi >= -75) return 'Faible';
    return 'Tres faible';
  }
}
