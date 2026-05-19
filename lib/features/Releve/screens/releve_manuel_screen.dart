import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_snackbar.dart';
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
      AppSnackbar.warning(context, 'Veuillez sélectionner un compteur.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token ?? '';
    if (token.isEmpty) {
      AppSnackbar.error(
          context, 'Session expirée. Déconnectez-vous et reconnectez-vous.');
      return;
    }

    final value = double.parse(
        _valeurController.text.trim().replaceAll(',', '.'));
    final comment = _commentaireController.text.trim();

    final success = await context.read<ReleveProvider>().soumettreReleve(
          token: token,
          meterId: _selectedCompteur!.id,
          value: value,
          comment: comment.isEmpty ? null : comment,
        );

    if (success && mounted) {
      AppSnackbar.success(context, 'Relevé ajouté avec succès.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final compteurProvider = context.watch<CompteurProvider>();
    final releveProvider = context.watch<ReleveProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouveau relevé'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ────────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 20),

              // ── SECTION 1 : Sélection du compteur ─────────────────────
              _buildCard(
                icon: Icons.electric_meter_rounded,
                iconColor: AppColors.primary,
                title: 'Compteur',
                subtitle: 'Sélectionnez le compteur concerné',
                child: compteurProvider.isLoadingCompteurs
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : compteurProvider.errorCompteurs != null
                        ? _buildCompteurError(compteurProvider)
                        : compteurProvider.mesCompteurs.isEmpty
                            ? _buildCompteurVide(compteurProvider)
                            : DropdownButtonFormField<CompteurResponse>(
                                initialValue: _selectedCompteur,
                                hint: Text(
                                  'Sélectionner un compteur',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary),
                                ),
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(
                                      Icons.electric_meter_rounded,
                                      color: AppColors.primary,
                                      size: 20),
                                ),
                                items: compteurProvider.mesCompteurs
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c.reference,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedCompteur = val),
                              ),
              ),
              const SizedBox(height: 16),

              // ── SECTION 2 : Valeur relevée ─────────────────────────────
              _buildCard(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.alertOrange,
                title: 'Index relevé',
                subtitle: 'Valeur lue sur le compteur',
                child: TextFormField(
                  controller: _valeurController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Ex: 3542.5',
                    suffixText: 'kWh',
                    prefixIcon: Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 20),
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
              ),
              const SizedBox(height: 16),

              // ── SECTION 3 : Commentaire ────────────────────────────────
              _buildCard(
                icon: Icons.notes_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Commentaire',
                subtitle: 'Optionnel — contexte du relevé',
                child: TextFormField(
                  controller: _commentaireController,
                  maxLines: 3,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Relevé pris le matin avant départ...',
                    prefixIcon: Icon(Icons.notes_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── ERREUR ─────────────────────────────────────────────────
              ErrorMessageWidget(
                errorMessage: releveProvider.errorMessage,
                onDismiss: () =>
                    context.read<ReleveProvider>().clearMessages(),
              ),
              if (releveProvider.errorMessage != null)
                const SizedBox(height: 16),

              // ── BOUTON ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      releveProvider.isLoading ? null : _soumettre,
                  child: releveProvider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Enregistrer le relevé'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
            child: const Icon(Icons.add_chart_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saisir un relevé',
                  style: AppTextStyles.heading2
                      .copyWith(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Enregistrez la valeur lue sur votre compteur',
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
    required Widget child,
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
          child,
        ],
      ),
    );
  }

  Widget _buildCompteurError(CompteurProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Erreur : ${p.errorCompteurs}',
          style: AppTextStyles.body.copyWith(color: AppColors.alertRed),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            final token = context.read<AuthProvider>().token ?? '';
            context.read<CompteurProvider>().chargerMesCompteurs(token: token);
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }

  Widget _buildCompteurVide(CompteurProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aucun compteur trouvé.',
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            final token = context.read<AuthProvider>().token ?? '';
            context.read<CompteurProvider>().chargerMesCompteurs(token: token);
          },
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Réessayer'),
        ),
      ],
    );
  }
}
