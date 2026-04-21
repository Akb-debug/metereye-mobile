import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';
import '../home/home_shell.dart';
import 'login_screen.dart';

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
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
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
                validator: (val) => val == null || val.trim().length < 2 ? 'Minimum 2 caractères' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: prenomController,
                label: 'Prénom',
                icon: Icons.person_outline,
                hint: 'Votre prénom',
                validator: (val) => val == null || val.trim().length < 2 ? 'Minimum 2 caractères' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                hint: 'Ex : email@exemple.com',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Email invalide' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: telephoneController,
                label: 'Téléphone',
                icon: Icons.phone_outlined,
                hint: 'Ex : +221123456789',
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().length < 8 ? 'Minimum 8 chiffres' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: passwordController,
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                obscureText: true,
                showToggle: true,
                hint: 'Minimum 6 caractères',
                validator: (val) => val == null || val.trim().length < 6 ? 'Minimum 6 caractères' : null,
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: confirmPasswordController,
                label: 'Confirmer le mot de passe',
                icon: Icons.lock_outline,
                obscureText: true,
                showToggle: true,
                hint: 'Répétez votre mot de passe',
                validator: (val) => val == null || val.trim().isEmpty ? 'Veuillez confirmer le mot de passe' : null,
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
