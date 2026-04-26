import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../providers/releve_providers.dart';
import '../widgets/consommation_widget.dart';
import '../widgets/error_message_widget.dart';
import '../widgets/previous_value_widget.dart';

class ReleveManuelScreen extends StatefulWidget {
  final int compteurId;
  final String compteurReference;
  final double? valeurPrecedente;

  const ReleveManuelScreen({
    super.key,
    required this.compteurId,
    required this.compteurReference,
    this.valeurPrecedente,
  });

  @override
  State<ReleveManuelScreen> createState() => _ReleveManuelScreenState();
}

class _ReleveManuelScreenState extends State<ReleveManuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valeurController = TextEditingController();
  final _commentaireController = TextEditingController();

  @override
  void dispose() {
    _valeurController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token ?? '';
    debugPrint('RELEVE SUBMIT — token vide: ${token.isEmpty}, compteurId: ${widget.compteurId}');

    // Vérifications préventives avant tout appel réseau
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session invalide. Déconnectez-vous et reconnectez-vous.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.compteurId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun compteur sélectionné. Revenez sur le tableau de bord.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final valeur = double.parse(_valeurController.text.trim().replaceAll(',', '.'));

    final success = await context.read<ReleveProvider>().soumettreReleve(
          token: token,
          compteurId: widget.compteurId,
          valeur: valeur,
          valeurPrecedente: widget.valeurPrecedente,
          commentaire: _commentaireController.text.trim().isEmpty
              ? null
              : _commentaireController.text.trim(),
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
    final provider = context.watch<ReleveProvider>();

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
              // ── EN-TÊTE COMPTEUR ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.electric_meter_rounded,
                        color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saisie manuelle',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          widget.compteurReference,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── VALEUR PRÉCÉDENTE ────────────────────────────────────────────
              PreviousValueWidget(valeur: widget.valeurPrecedente),
              if (widget.valeurPrecedente != null) const SizedBox(height: 16),

              // ── CHAMP VALEUR ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'La valeur est obligatoire';
                        }
                        final v = double.tryParse(
                            val.trim().replaceAll(',', '.'));
                        if (v == null) return 'Entrez un nombre valide';
                        if (v <= 0) return 'La valeur doit être positive';
                        if (widget.valeurPrecedente != null &&
                            v < widget.valeurPrecedente!) {
                          return 'Valeur inférieure à la dernière lecture (${widget.valeurPrecedente})';
                        }
                        return null;
                      },
                      onChanged: (val) {
                        final v = double.tryParse(
                            val.trim().replaceAll(',', '.'));
                        if (v != null) {
                          context.read<ReleveProvider>().calculerConsommation(
                              v, widget.valeurPrecedente);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── CONSOMMATION ESTIMÉE ─────────────────────────────────────────
              ConsommationWidget(consommation: provider.consommationEstimee),
              if (provider.consommationEstimee != null)
                const SizedBox(height: 12),

              // ── COMMENTAIRE ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                          borderSide:
                              const BorderSide(color: AppColors.primary, width: 2),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── MESSAGE D'ERREUR ─────────────────────────────────────────────
              ErrorMessageWidget(
                errorMessage: provider.errorMessage,
                onDismiss: () => context.read<ReleveProvider>().clearMessages(),
              ),
              if (provider.errorMessage != null) const SizedBox(height: 16),

              // ── BOUTON SOUMETTRE ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
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
