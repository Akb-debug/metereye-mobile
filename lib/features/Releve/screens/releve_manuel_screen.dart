import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../../compteur/models/compteur_response.dart';
import '../../compteur/providers/compteur_provider.dart';
import '../providers/releve_providers.dart';
import '../widgets/error_message_widget.dart';

class ReleveManuelScreen extends StatefulWidget {
  const ReleveManuelScreen({super.key});

  @override
  State<ReleveManuelScreen> createState() => _ReleveManuelScreenState();
}

class _ReleveManuelScreenState extends State<ReleveManuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valeurController = TextEditingController();
  final _commentaireController = TextEditingController();

  CompteurResponse? _selectedCompteur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      if (token.isNotEmpty) {
        context.read<CompteurProvider>().chargerMesCompteurs(token: token);
      }
    });
  }

  @override
  void dispose() {
    _valeurController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (_selectedCompteur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un compteur.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session invalide. Déconnectez-vous et reconnectez-vous.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final value = double.parse(_valeurController.text.trim().replaceAll(',', '.'));
    final comment = _commentaireController.text.trim();

    final success = await context.read<ReleveProvider>().soumettreReleve(
          token: token,
          meterId: _selectedCompteur!.id,
          value: value,
          comment: comment.isEmpty ? null : comment,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relevé ajouté avec succès'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compteurProvider = context.watch<CompteurProvider>();
    final releveProvider = context.watch<ReleveProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Nouveau relevé'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SÉLECTION DU COMPTEUR ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compteur',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    compteurProvider.isLoadingCompteurs
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : compteurProvider.errorCompteurs != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Erreur : ${compteurProvider.errorCompteurs}',
                                    style: AppTextStyles.body.copyWith(
                                        color: Colors.red.shade700),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      final token = context
                                              .read<AuthProvider>()
                                              .token ??
                                          '';
                                      context
                                          .read<CompteurProvider>()
                                          .chargerMesCompteurs(token: token);
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Réessayer'),
                                  ),
                                ],
                              )
                        : compteurProvider.mesCompteurs.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aucun compteur trouvé.',
                                    style: AppTextStyles.body
                                        .copyWith(color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton.icon(
                                    onPressed: () {
                                      final token = context
                                              .read<AuthProvider>()
                                              .token ??
                                          '';
                                      context
                                          .read<CompteurProvider>()
                                          .chargerMesCompteurs(token: token);
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Réessayer'),
                                  ),
                                ],
                              )
                            : DropdownButtonFormField<CompteurResponse>(
                                initialValue: _selectedCompteur,
                                hint: const Text('Sélectionner un compteur'),
                                isExpanded: true,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                      Icons.electric_meter_rounded,
                                      color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                                items: compteurProvider.mesCompteurs
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c.reference,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCompteur = val),
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── VALEUR RELEVÉE ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valeur relevée',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valeurController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Ex: 3542.5',
                        suffixText: 'kWh',
                        prefixIcon: const Icon(Icons.bolt_rounded,
                            color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'La valeur est obligatoire';
                        }
                        final v =
                            double.tryParse(val.trim().replaceAll(',', '.'));
                        if (v == null) return 'Entrez un nombre valide';
                        if (v < 0) return 'La valeur doit être positive ou nulle';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── COMMENTAIRE ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commentaire (optionnel)',
                      style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentaireController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ex: Relevé pris le matin avant départ...',
                        prefixIcon: const Icon(Icons.notes_rounded,
                            color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── ERREUR ───────────────────────────────────────────────────
              ErrorMessageWidget(
                errorMessage: releveProvider.errorMessage,
                onDismiss: () => context.read<ReleveProvider>().clearMessages(),
              ),
              if (releveProvider.errorMessage != null)
                const SizedBox(height: 16),

              // ── BOUTON SOUMETTRE ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: releveProvider.isLoading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: releveProvider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Enregistrer le relevé',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
