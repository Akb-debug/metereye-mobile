import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../home/home_shell.dart';
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
  final TextEditingController confirmPasswordController = TextEditingController();

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
      MaterialPageRoute(builder: (_) => CreateCompteurScreen(token: token ?? '')),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créer votre compte', style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text(
                'Bienvenue sur MeterEye AI.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              if (auth.errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              CustomInput(
                controller: nomController,
                label: 'Nom',
                icon: Icons.person_outline,
                hint: 'Votre nom',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Le nom est obligatoire';
                  if (val.trim().length < 2) return 'Le nom doit contenir au moins 2 caractères';
                  if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val.trim())) return 'Le nom ne peut contenir que des lettres, espaces, tirets et apostrophes';
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
                  if (val == null || val.trim().isEmpty) return 'Le prénom est obligatoire';
                  if (val.trim().length < 2) return 'Le prénom doit contenir au moins 2 caractères';
                  if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(val.trim())) return 'Le prénom ne peut contenir que des lettres, espaces, tirets et apostrophes';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                hint: 'Ex : email@exemple.com',
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'L\'email est obligatoire';
                      if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(val.trim())) return 'Veuillez entrer une adresse email valide (ex: nom@domaine.com)';
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
                      if (val == null || val.trim().isEmpty) return 'Le numéro de téléphone est obligatoire';
                      final phone = val.trim().replaceAll(RegExp(r'[^0-9+]'), '');
                      if (phone.length < 8) return 'Le numéro doit contenir au moins 8 chiffres';
                      if (phone.length > 15) return 'Le numéro ne peut pas dépasser 15 chiffres';
                      if (!RegExp(r'^\+?[0-9]+$').hasMatch(phone)) return 'Le numéro ne peut contenir que des chiffres et éventuellement un + au début';
                      return null;
                    },
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: passwordController,
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                obscureText: true,
                showToggle: true,
                hint: 'Minimum 6 caractères',
                validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Le mot de passe est obligatoire';
                      if (val.trim().length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
                      if (val.trim().length > 50) return 'Le mot de passe ne peut pas dépasser 50 caractères';
                      if (!RegExp(r'(?=.*[a-z])').hasMatch(val)) return 'Le mot de passe doit contenir au moins une lettre minuscule';
                      if (!RegExp(r'(?=.*[A-Z])').hasMatch(val)) return 'Le mot de passe doit contenir au moins une lettre majuscule';
                      if (!RegExp(r'(?=.*\d)').hasMatch(val)) return 'Le mot de passe doit contenir au moins un chiffre';
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
                      if (val == null || val.trim().isEmpty) return 'Veuillez confirmer le mot de passe';
                      if (val != passwordController.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (passwordController.text != confirmPasswordController.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                          );
                          return;
                        }
                        final success = await context.read<AuthProvider>().register(
                              nom: nomController.text.trim(),
                              prenom: prenomController.text.trim(),
                              email: emailController.text.trim(),
                              motDePasse: passwordController.text.trim(),
                              telephone: telephoneController.text.trim(),
                            );
                        if (success && mounted) {
                          Provider.of<AppStateProvider>(context, listen: false).login();
                          _naviguerVersAccueil();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Créer mon compte'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            ],
          ),
        ),
      ),
    );
  }
}
