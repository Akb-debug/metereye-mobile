import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
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
      // Vérifier si le mode de lecture a été configuré
      if (provider.configuredMode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compteur créé et mode de lecture configuré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compteur créé! Vous pourrez configurer le mode de lecture plus tard.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CompteurNextStepScreen(
            modeLecture: _selectedMode,
            compteurId: provider.createdCompteur!.id,
            compteurReference: provider.createdCompteur!.reference,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur lors de la création du compteur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompteurProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Créer un compteur'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _referenceController,
                    label: 'Référence',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'La référence du compteur est obligatoire';
                      if (v.trim().length < 3) return 'La référence doit contenir au moins 3 caractères';
                      if (v.trim().length > 50) return 'La référence ne peut pas dépasser 50 caractères';
                      if (!RegExp(r'^[A-Z0-9-_]+$').hasMatch(v.trim())) return 'La référence ne peut contenir que des lettres majuscules, chiffres, tirets et underscores';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _adresseController,
                    label: 'Adresse',
                    maxLines: 2,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'L\'adresse est obligatoire';
                      if (v.trim().length < 5) return 'L\'adresse doit contenir au moins 5 caractères';
                      if (v.trim().length > 200) return 'L\'adresse ne peut pas dépasser 200 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TypeCompteur>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de compteur',
                      border: OutlineInputBorder(),
                    ),
                    items: TypeCompteur.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'La valeur initiale est obligatoire';
                      final value = double.tryParse(v.trim());
                      if (value == null) return 'Veuillez entrer une valeur numérique valide';
                      if (value < 0) return 'La valeur ne peut pas être négative';
                      if (value > 999999) return 'La valeur ne peut pas dépasser 999999';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<ModeLecture>(
                    value: _selectedMode,
                    decoration: const InputDecoration(
                      labelText: 'Mode de lecture',
                      border: OutlineInputBorder(),
                    ),
                    items: ModeLecture.values
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
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
                    maxLines: 3,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Le commentaire est obligatoire';
                      if (v.trim().length < 5) return 'Le commentaire doit contenir au moins 5 caractères';
                      if (v.trim().length > 500) return 'Le commentaire ne peut pas dépasser 500 caractères';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Créer et configurer',
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
}