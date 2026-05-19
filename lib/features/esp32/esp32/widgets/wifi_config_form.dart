import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';

class WifiConfigForm extends StatefulWidget {
  final Function(String ssid, String password) onSubmit;

  const WifiConfigForm({
    super.key,
    required this.onSubmit,
  });

  @override
  State<WifiConfigForm> createState() => _WifiConfigFormState();
}

class _WifiConfigFormState extends State<WifiConfigForm> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit(
        _ssidController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wifi_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paramètres WiFi',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Connexion du module ESP32',
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

            // ── SSID ───────────────────────────────────────────────────
            TextFormField(
              controller: _ssidController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                labelText: 'Nom du réseau (SSID)',
                hintText: 'Ex: MaBox-5GHz',
                prefixIcon: Icon(Icons.wifi_tethering_rounded,
                    color: AppColors.primary, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom du réseau est obligatoire';
                }
                if (value.trim().length < 2) {
                  return 'Le nom du réseau est trop court';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Mot de passe ───────────────────────────────────────────
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Mot de passe WiFi',
                prefixIcon: const Icon(Icons.lock_outline_rounded,
                    color: AppColors.primary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le mot de passe est obligatoire';
                }
                if (value.trim().length < 8) {
                  return 'Minimum 8 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Bouton ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  'Envoyer au module',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Note ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ces informations seront transmises au module via Bluetooth pour établir la connexion WiFi.',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
