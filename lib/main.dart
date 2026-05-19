import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart';

// Nouveau module compteur
import 'features/compteur/providers/compteur_provider.dart';
import 'features/compteur/services/compteur_service.dart';

// Module relevé
import 'features/Releve/providers/releve_providers.dart';
import 'features/Releve/services/releve_service.dart';

// Module alertes
import 'features/alertes/providers/alerte_provider.dart';
import 'features/alertes/services/alerte_service.dart';

// Dashboard
import 'providers/dashboard_provider.dart';
import 'providers/historique_provider.dart';
import 'providers/profil_provider.dart';
import 'providers/data_sync_notifier.dart';
import 'services/meter_service.dart';

// Module ESP32
import 'features/esp32/esp32/providers/esp32_wifi_provider.dart';
import 'features/esp32/esp32/providers/capture_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  final sync = DataSyncNotifier();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: sync),

        ChangeNotifierProvider(
          create: (_) => CompteurProvider(
            service: CompteurService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReleveProvider(
            service: ReleveService(),
            sync: sync,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(service: MeterService(), sync: sync),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoriqueProvider(service: MeterService(), sync: sync),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfilProvider(service: MeterService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AlerteProvider(service: AlerteService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ESP32WifiProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CaptureProvider(sync: sync),
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