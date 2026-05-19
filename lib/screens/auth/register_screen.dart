import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import 'login_screen.dart';
import '../../../features/compteur/screens/create_compteur_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _naviguerVersAccueil() {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (_) => CreateCompteurScreen(token: token ?? '')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── HERO ─────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
                decoration: const BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Créer\nvotre compte',
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bienvenue sur MeterEye AI.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              // ── FORM CARD ────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (auth.errorMessage != null)
                        _InlineError(message: auth.errorMessage!),

                      // ── Identité ──────────────────────────────────────
                      const _SectionLabel(
                          icon: Icons.person_outline_rounded,
                          label: 'Identité'),
                      const SizedBox(height: 12),
                      CustomInput(
                        controller: nomController,
                        label: 'Nom',
                        icon: Icons.badge_outlined,
                        hint: 'Votre nom',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le nom est obligatoire';
                          }
                          if (val.trim().length < 2) {
                            return 'Le nom doit contenir au moins 2 caractères';
                          }
                          if (!RegExp(r"^[a-zA-Z\s'-]+$")
                              .hasMatch(val.trim())) {
                            return 'Lettres, espaces, tirets et apostrophes uniquement';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: prenomController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                        hint: 'Votre prénom',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le prénom est obligatoire';
                          }
                          if (val.trim().length < 2) {
                            return 'Le prénom doit contenir au moins 2 caractères';
                          }
                          if (!RegExp(r"^[a-zA-Z\s'-]+$")
                              .hasMatch(val.trim())) {
                            return 'Lettres, espaces, tirets et apostrophes uniquement';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Coordonnées ────────────────────────────────────
                      const _SectionLabel(
                          icon: Icons.contacts_outlined,
                          label: 'Coordonnées'),
                      const SizedBox(height: 12),
                      CustomInput(
                        controller: emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        hint: 'Ex : email@exemple.com',
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "L'email est obligatoire";
                          }
                          if (!RegExp(
                                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                              .hasMatch(val.trim())) {
                            return 'Adresse email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: telephoneController,
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        hint: 'Ex : +221123456789',
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le numéro de téléphone est obligatoire';
                          }
                          final phone =
                              val.trim().replaceAll(RegExp(r'[^0-9+]'), '');
                          if (phone.length < 8) {
                            return 'Le numéro doit contenir au moins 8 chiffres';
                          }
                          if (phone.length > 15) {
                            return 'Le numéro ne peut pas dépasser 15 chiffres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Sécurité ───────────────────────────────────────
                      const _SectionLabel(
                          icon: Icons.lock_outline_rounded,
                          label: 'Sécurité'),
                      const SizedBox(height: 12),
                      CustomInput(
                        controller: passwordController,
                        label: 'Mot de passe',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        showToggle: true,
                        hint: 'Minimum 6 caractères',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Le mot de passe est obligatoire';
                          }
                          if (val.trim().length < 6) {
                            return 'Minimum 6 caractères';
                          }
                          if (!RegExp(r'(?=.*[a-z])').hasMatch(val)) {
                            return 'Au moins une lettre minuscule';
                          }
                          if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) {
                            return 'Au moins une lettre majuscule';
                          }
                          if (!RegExp(r'(?=.*\d)').hasMatch(val)) {
                            return 'Au moins un chiffre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: confirmPasswordController,
                        label: 'Confirmer le mot de passe',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        showToggle: true,
                        hint: 'Répétez votre mot de passe',
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          if (val != passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // ── Bouton ─────────────────────────────────────────
                      ElevatedButton(
                        onPressed: auth.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                if (passwordController.text !=
                                    confirmPasswordController.text) {
                                  context
                                      .read<AuthProvider>()
                                      .setError(
                                          'Les mots de passe ne correspondent pas.');
                                  return;
                                }
                                final success = await context
                                    .read<AuthProvider>()
                                    .register(
                                      nom: nomController.text.trim(),
                                      prenom: prenomController.text.trim(),
                                      email: emailController.text.trim(),
                                      motDePasse:
                                          passwordController.text.trim(),
                                      telephone:
                                          telephoneController.text.trim(),
                                    );
                                if (success && mounted) {
                                  // ignore: use_build_context_synchronously
                                  Provider.of<AppStateProvider>(context,
                                          listen: false)
                                      .login();
                                  _naviguerVersAccueil();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Créer mon compte'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── FOOTER ───────────────────────────────────────────────
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ?',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Se connecter',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sous-titre de section ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Erreur inline ─────────────────────────────────────────────────────────────

class _InlineError extends StatelessWidget {
  final String message;
  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
