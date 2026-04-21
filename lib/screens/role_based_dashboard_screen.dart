import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/meter_provider.dart';
import 'dashboards/cashpower_dashboard.dart';
import 'dashboards/classique_dashboard.dart';
import 'dashboards/proprio_dashboard.dart';
import 'auth/welcome_screen.dart';

class RoleBasedDashboardScreen extends StatefulWidget {
  const RoleBasedDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RoleBasedDashboardScreen> createState() => _RoleBasedDashboardScreenState();
}

class _RoleBasedDashboardScreenState extends State<RoleBasedDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier le statut de connexion au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Si l'utilisateur n'est pas connecté, rediriger vers l'écran de connexion
    if (!authProvider.isLoggedIn) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Si l'utilisateur n'est pas connecté, afficher un écran de chargement
    if (!authProvider.isLoggedIn) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Rediriger vers le bon dashboard selon le rôle
    return _buildDashboardForRole(authProvider.role);
  }

  Widget _buildDashboardForRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'CASHPOWER':
        return const CashpowerDashboard();
      case 'CLASSIQUE':
        return const ClassiqueDashboard();
      case 'PROPRIO':
        return const ProprioDashboard();
      case 'ADMIN':
        // Pour l'admin, on peut montrer le dashboard proprio ou un dashboard admin dédié
        return const ProprioDashboard();
      case 'LOCATAIRE':
        // Le locataire peut avoir accès aux deux types de compteurs
        return const ProprioDashboard();
      default:
        // Par défaut, on montre le dashboard classique
        return const ClassiqueDashboard();
    }
  }
}
