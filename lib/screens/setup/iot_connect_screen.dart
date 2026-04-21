import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../theme/app_theme.dart';
import '../home/home_shell.dart';

enum ConnectionState { searching, found, reading }

class IotConnectScreen extends StatefulWidget {
  const IotConnectScreen({super.key});

  @override
  State<IotConnectScreen> createState() => _IotConnectScreenState();
}

class _IotConnectScreenState extends State<IotConnectScreen> with TickerProviderStateMixin {
  ConnectionState _state = ConnectionState.searching;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1)
    )..repeat(reverse: true);

    _startSimulation();
  }

  void _startSimulation() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = ConnectionState.found);
    });
  }

  void _startReading() {
    setState(() => _state = ConnectionState.reading);
    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showResult = true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Connexion du module"),
        automaticallyImplyLeading: _state == ConnectionState.searching,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case ConnectionState.searching: return _buildSearching();
      case ConnectionState.found: return _buildFound();
      case ConnectionState.reading: return _buildReading();
    }
  }

  Widget _buildSearching() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            _pulseCircle(160, 0.06),
            _pulseCircle(110, 0.10),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_tethering_rounded, size: 32, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text("Recherche du module...", style: AppTextStyles.heading1.copyWith(fontSize: 20)),
        const SizedBox(height: 8),
        Text(
          "Rejoignez le réseau Wi-Fi 'MeterEye-Setup'\ndepuis les paramètres de votre téléphone",
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const LinearProgressIndicator(
          backgroundColor: Color(0xFFE2E8F0),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _pulseCircle(double size, double opacity) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: size * (1 + _pulseController.value * 0.1),
          height: size * (1 + _pulseController.value * 0.1),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(opacity * (1 - _pulseController.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildFound() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: const AlwaysStoppedAnimation(1.0),
          child: Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              gradient: AppColors.mainGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text("Module détecté !", style: AppTextStyles.heading1.copyWith(fontSize: 24)),
        const SizedBox(height: 6),
        const Text("MeterEye · ESP32-A4F2-0841", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              _infoRow(Icons.wifi, "Signal WiFi", "Excellent"),
              const Divider(height: 24, color: AppColors.borderColor),
              _infoRow(Icons.power, "Alimentation", "USB ✅"),
              const Divider(height: 24, color: AppColors.borderColor),
              _infoRow(Icons.camera_alt, "Caméra", "Prête ✅"),
              const Divider(height: 24, color: AppColors.borderColor),
              _infoRow(Icons.memory_rounded, "Firmware", "v2.1.4"),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _startReading,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 54)),
          child: const Text("Tester la lecture du compteur →"),
        ),
      ],
    );
  }

  Widget _buildReading() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📷 Lecture en cours...", style: AppTextStyles.heading2.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 90,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.secondary, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Positioned(
                          top: 50 + (90 * _scanController.value),
                          child: Container(
                            width: 200,
                            height: 2,
                            color: AppColors.secondary.withOpacity(0.8),
                          ),
                        );
                      },
                    ),
                    const Positioned(
                      bottom: 8,
                      child: Text("Analyse OCR en cours...", style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !_showResult
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text("Lecture de l'affichage...", style: AppTextStyles.body),
                  ],
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Crédit lu avec succès !", style: AppTextStyles.heading2.copyWith(color: AppColors.secondary, fontSize: 16)),
                                Text("1 247 unités restantes", style: AppTextStyles.heading1.copyWith(fontSize: 24, color: AppColors.textPrimary)),
                                Text("Dernière lecture : 09:47", style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        const Spacer(),
        if (_showResult)
          ElevatedButton(
            onPressed: () {
              Provider.of<AppStateProvider>(context, listen: false).linkIoT();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeShell()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 54),
            ),
            child: const Text("Accéder à mon tableau de bord  🎉"),
          ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
