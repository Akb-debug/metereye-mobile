import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/compteur/models/mode_lecture.dart';
import '../../../theme/app_theme.dart';
import '../models/iot_module_request.dart';
import '../models/iot_module_response.dart';
import '../providers/iot_module_provider.dart';
import 'bluetooth_wifi_config_page.dart';

class ModuleFormPage extends StatefulWidget {
  final int compteurId;
  final ModeLecture modeLecture;
  final String token;

  const ModuleFormPage({
    super.key,
    required this.compteurId,
    required this.modeLecture,
    required this.token,
  });

  @override
  State<ModuleFormPage> createState() => _ModuleFormPageState();
}

class _ModuleFormPageState extends State<ModuleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceIdCtrl = TextEditingController();
  final _btAddrCtrl = TextEditingController();
  final _firmwareCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  late String _selectedType;

  static const _typeOptions = [
    ('ESP32_PZEM004T', 'Raspberry Pi + PZEM-004T'),
    ('ESP32_CAM', 'ESP32-CAM'),
    ('SENSOR_GENERIC', 'Capteur générique'),
    ('IOT_MODULE', 'Module IoT'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.modeLecture == ModeLecture.sensor
        ? 'ESP32_PZEM004T'
        : 'ESP32_CAM';
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _btAddrCtrl.dispose();
    _firmwareCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IotModuleProvider(),
      child: Builder(builder: (ctx) {
        final provider = ctx.watch<IotModuleProvider>();
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Ajouter un module'),
            backgroundColor: AppColors.background,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── HEADER ───────────────────────────────────────
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // ── SECTION 1 : Champs obligatoires ──────────────
                      _buildCard(
                        icon: Icons.developer_board_rounded,
                        iconColor: AppColors.primary,
                        title: 'Identification du module',
                        subtitle: 'Informations requises',
                        children: [
                          _fieldLabel('Identifiant du module'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _deviceIdCtrl,
                            style: AppTextStyles.body,
                            decoration: _inputDeco(
                              hint: 'Ex: PZEM-RPI-001',
                              icon: Icons.developer_board_rounded,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Identifiant requis'
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('Type de module'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedType,
                            decoration: _inputDeco(
                              hint: 'Sélectionnez un type',
                              icon: Icons.category_rounded,
                            ),
                            items: _typeOptions
                                .map((t) => DropdownMenuItem(
                                      value: t.$1,
                                      child: Text(t.$2,
                                          style: AppTextStyles.body
                                              .copyWith(fontSize: 14)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedType = v);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── SECTION 2 : Champs optionnels ─────────────────
                      _buildCard(
                        icon: Icons.tune_rounded,
                        iconColor: AppColors.textSecondary,
                        title: 'Informations complémentaires',
                        subtitle: 'Tous les champs sont optionnels',
                        children: [
                          _fieldLabel('Adresse Bluetooth',
                              optional: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _btAddrCtrl,
                            style: AppTextStyles.body,
                            decoration: _inputDeco(
                              hint: 'Ex: AA:BB:CC:DD:EE:FF',
                              icon: Icons.bluetooth_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('Version firmware',
                              optional: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firmwareCtrl,
                            style: AppTextStyles.body,
                            decoration: _inputDeco(
                              hint: 'Ex: 1.0.0',
                              icon: Icons.memory_rounded,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _fieldLabel('Numéro de série',
                              optional: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _serialCtrl,
                            style: AppTextStyles.body,
                            decoration: _inputDeco(
                              hint: 'Ex: SN-2026-001',
                              icon: Icons.tag_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Intervalle de capture : 60 secondes (prototype)',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── ERREUR ────────────────────────────────────────
                      if (provider.error != null) ...[
                        _ErrorBanner(message: provider.error!),
                        const SizedBox(height: 16),
                      ],

                      // ── BOUTON ────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () => _submit(ctx),
                          child: provider.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Enregistrer le module'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    final isCam = _selectedType.contains('CAM');
    final icon = isCam
        ? Icons.camera_alt_rounded
        : Icons.developer_board_rounded;
    final label = isCam ? 'Module ESP32-CAM' : 'Module PZEM-004T';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.mainGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enregistrez votre module IoT',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
              height: 1,
              color: AppColors.borderColor.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {bool optional = false}) {
    return Row(
      children: [
        Text(
          text,
          style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textPrimary),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Optionnel',
              style: AppTextStyles.caption.copyWith(fontSize: 10),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _submit(BuildContext ctx) async {
    if (!_formKey.currentState!.validate()) return;

    final request = IotModuleRequest(
      deviceId: _deviceIdCtrl.text.trim(),
      typeModule: _selectedType,
      captureInterval: 60,
      compteurId: widget.compteurId,
      bluetoothAddress: _btAddrCtrl.text.trim().isEmpty
          ? null
          : _btAddrCtrl.text.trim(),
      firmwareVersion: _firmwareCtrl.text.trim().isEmpty
          ? null
          : _firmwareCtrl.text.trim(),
      serialNumber:
          _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
    );

    final provider = ctx.read<IotModuleProvider>();
    final ok = await provider.createModule(widget.token, request);

    if (ok && ctx.mounted) {
      _navigateToBluetoothConfig(ctx, provider.module!);
    }
  }

  void _navigateToBluetoothConfig(
      BuildContext ctx, IotModuleResponse module) {
    Navigator.push(
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Nunito',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
