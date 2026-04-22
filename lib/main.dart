import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/meter_provider.dart';

// Nouveau module compteur
import 'features/compteur/providers/compteur_provider.dart';
import 'features/compteur/services/compteur_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider.value(value: authProvider),

        // Ancien provider existant
        ChangeNotifierProvider(create: (_) => MeterProvider()),

        // Nouveau provider feature-first pour Sprint 2
        ChangeNotifierProvider(
          create: (_) => CompteurProvider(
            service: CompteurService(),
          ),
        ),
      ],
      child: const MeterEyeApp(),
    ),
  );
}

class AppStateProvider extends ChangeNotifier {
  bool _isFirstLaunch = true;
  bool _isLoggedIn = false;
  bool _isIoTLinked = false;

  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoggedIn => _isLoggedIn;
  bool get isIoTLinked => _isIoTLinked;

  void completeOnboarding() {
    _isFirstLaunch = false;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _isIoTLinked = false;
    notifyListeners();
  }

  void linkIoT() {
    _isIoTLinked = true;
    notifyListeners();
  }
}

class MeterEyeApp extends StatelessWidget {
  const MeterEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeterEye AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}