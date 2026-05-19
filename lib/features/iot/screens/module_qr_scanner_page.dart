import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../features/compteur/models/mode_lecture.dart';
import '../../../theme/app_theme.dart';
import '../models/iot_module_response.dart';
import '../providers/iot_module_provider.dart';
import 'bluetooth_wifi_config_page.dart';

class ModuleQrScannerPage extends StatefulWidget {
  final int compteurId;
  final int userId;
  final String token;
  final ModeLecture modeLecture;

  const ModuleQrScannerPage({
    super.key,
    required this.compteurId,
    required this.userId,
    required this.token,
    required this.modeLecture,
  });

  @override
  State<ModuleQrScannerPage> createState() => _ModuleQrScannerPageState();
}

class _ModuleQrScannerPageState extends State<ModuleQrScannerPage> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IotModuleProvider(),
      child: Builder(builder: (ctx) {
        final provider = ctx.watch<IotModuleProvider>();
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Scanner le QR Code'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flash_on_rounded),
                onPressed: () => _scanner.toggleTorch(),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Camera
              MobileScanner(
                controller: _scanner,
                onDetect: (capture) {
                  if (_scanned || provider.isLoading) return;
                  final code = capture.barcodes.firstOrNull?.rawValue;
                  if (code != null && code.isNotEmpty) {
                    _handleScan(ctx, code);
                  }
                },
              ),
              // Cadre de scan
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              // Instruction
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    if (provider.isLoading) ...[
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Association en cours...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Nunito'),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (provider.error != null) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.alertRed.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          provider.error!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Nunito'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() => _scanned = false);
                          provider.reset();
                        },
                        child: const Text('Reessayer',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700)),
                      ),
                    ] else
                      const Text(
                        'Placez le QR Code du module\ndans le cadre',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontFamily: 'Nunito'),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _handleScan(BuildContext ctx, String qrCode) async {
    if (_scanned) return;
    setState(() => _scanned = true);

    final provider = ctx.read<IotModuleProvider>();
    await _scanner.stop();

    final ok = await provider.scanAndAssociate(
      token: widget.token,
      userId: widget.userId,
      qrCode: qrCode,
      compteurId: widget.compteurId,
    );

    if (!ctx.mounted) return;
    if (ok) {
      _goToBluetoothConfig(ctx, provider.module!);
    } else {
      await _scanner.start();
    }
  }

  void _goToBluetoothConfig(BuildContext ctx, IotModuleResponse module) {
    Navigator.pushReplacement(
      ctx,
      MaterialPageRoute(
        builder: (_) => BluetoothWifiConfigPage(
          module: module,
          compteurId: widget.compteurId,
          token: widget.token,
        ),
      ),
    );
  }
}
