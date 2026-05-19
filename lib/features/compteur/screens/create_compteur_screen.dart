import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../models/configure_mode_lecture_request.dart';
import '../models/create_compteur_request.dart';
import '../models/mode_lecture.dart';
import '../models/type_compteur.dart';
import '../providers/compteur_provider.dart';
import '../widgets/mode_lecture_info_card.dart';
import 'compteur_next_step_screen.dart';

class CreateCompteurScreen extends StatefulWidget {
  final String token;

  const CreateCompteurScreen({super.key, required this.token});

  @override
  State<CreateCompteurScreen> createState() => _CreateCompteurScreenState();
}

class _CreateCompteurScreenState extends State<CreateCompteurScreen> {
  final _formKey = GlobalKey<FormState>();

  final _referenceController = TextEditingController();
  final _adresseController = TextEditingController();
  final _valeurInitialeController = TextEditingController();
  final _commentaireController = TextEditingController();

  TypeCompteur _selectedType = TypeCompteur.classique;
  ModeLecture _selectedMode = ModeLecture.manual;

  @override
  void dispose() {
    _referenceController.dispose();
    _adresseController.dispose();
    _valeurInitialeController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<CompteurProvider>();

    final compteurRequest = CreateCompteurRequest(
      reference: _referenceController.text.trim(),
      adresse: _adresseController.text.trim(),
      typeCompteur: _selectedType,
      valeurInitiale: double.parse(_valeurInitialeController.text.trim()),
    );

    final modeRequest = ConfigureModeLectureRequest(
      modeLecture: _selectedMode,
      commentaire: _commentaireController.text.trim(),
    );

    final success = await provider.createCompteurAndConfigureMode(
      token: widget.token,
      compteurRequest: compteurRequest,
      modeRequest: modeRequest,
    );

    if (!mounted) return;

    if (success && provider.createdCompteur != null) {
      if (provider.configuredMode != null) {
        AppSnackbar.success(
            context, 'Compteur créé et mode de lecture configuré.');
      } else {
        AppSnackbar.warning(context,
            'Compteur créé. Vous pourrez configurer le mode de lecture plus tard.');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompteurNextStepScreen(
            modeLecture: _selectedMode,
            compteurId: provider.createdCompteur!.id,
            compteurReference: provider.createdCompteur!.reference,
            token: widget.token,
          ),
        ),
      );
    } else {
      AppSnackbar.error(
        context,
        provider.errorMessage ?? 'Impossible de créer le compteur. Réessayez.',
      );
    }
  }

  // ── InputDecoration partagée pour les dropdowns ───────────────────────────

  InputDecoration _dropdownDeco({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompteurProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Créer un compteur'),
            backgroundColor: AppColors.background,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── HEADER ─────────────────────────────────────────────
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // ── SECTION 1 : Identification ─────────────────────────
                  _buildCard(
                    icon: Icons.electric_meter_rounded,
                    iconColor: AppColors.primary,
                    title: 'Identification',
                    subtitle: 'Informations principales du compteur',
                    children: [
                      AppTextField(
                        controller: _referenceController,
                        label: 'Référence',
                        hint: 'Ex : CPT-001',
                        prefixIcon: Icons.qr_code_2_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'La référence est obligatoire';
                          }
                          if (v.trim().length < 3) {
                            return 'Au moins 3 caractères';
                          }
                          if (v.trim().length > 50) {
                            return 'Maximum 50 caractères';
                          }
                          if (!RegExp(r'^[A-Z0-9\-_]+$').hasMatch(v.trim())) {
                            return 'Majuscules, chiffres, tirets et _ uniquement';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _adresseController,
                        label: 'Adresse',
                        hint: 'Ex : 12 Rue de la Paix, Dakar',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "L'adresse est obligatoire";
                          }
                          if (v.trim().length < 5) {
                            return 'Au moins 5 caractères';
                          }
                          if (v.trim().length > 200) {
                            return 'Maximum 200 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TypeCompteur>(
                        initialValue: _selectedType,
                        decoration: _dropdownDeco(
                          label: 'Type de compteur',
                          icon: Icons.electric_meter_outlined,
                        ),
                        items: TypeCompteur.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label,
                                      style: AppTextStyles.body),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _valeurInitialeController,
                        label: 'Valeur initiale',
                        hint: 'Ex : 0.00',
                        prefixIcon: Icons.bolt_rounded,
                        suffixText: 'kWh',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'La valeur initiale est obligatoire';
                          }
                          final value = double.tryParse(v.trim());
                          if (value == null) return 'Valeur numérique invalide';
                          if (value < 0) return 'La valeur ne peut pas être négative';
                          if (value > 999999) return 'Maximum 999 999';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── SECTION 2 : Mode de lecture ────────────────────────
                  _buildCard(
                    icon: Icons.settings_input_component_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Mode de lecture',
                    subtitle: 'Comment les relevés seront collectés',
                    children: [
                      DropdownButtonFormField<ModeLecture>(
                        initialValue: _selectedMode,
                        isExpanded: true,
                        decoration: _dropdownDeco(
                          label: 'Mode de lecture',
                          icon: Icons.sensors_rounded,
                        ),
                        items: ModeLecture.values
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label,
                                      style: AppTextStyles.body),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedMode = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ModeLectureInfoCard(mode: _selectedMode),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _commentaireController,
                        label: 'Commentaire',
                        hint: 'Ex : Compteur principal du bâtiment A',
                        prefixIcon: Icons.notes_rounded,
                        maxLines: 3,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Le commentaire est obligatoire';
                          }
                          if (v.trim().length < 5) {
                            return 'Au moins 5 caractères';
                          }
                          if (v.trim().length > 500) {
                            return 'Maximum 500 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'Créer et configurer',
                    icon: Icons.check_rounded,
                    loading: provider.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
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
            child: const Icon(Icons.electric_meter_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau compteur',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Configurez votre compteur électrique',
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
              Expanded(
                child: Column(
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
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(
              height: 1,
              color: AppColors.borderColor.withValues(alpha: 0.6)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
