import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error_translator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String roleName;
  final String? nomComplet;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.roleName,
    this.nomComplet,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoggedIn = false;

  UserModel? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _isLoggedIn;
  String? get role => _profile?.roleName ?? _user?.role;
  String? get token => _user?.token;

  Future<bool> login(String email, String motDePasse) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.login(email, motDePasse);
      final profile = UserProfile(id: user.userId.toString(), name: user.nomComplet, email: user.email, roleName: user.role);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', user.token);
      await prefs.setString('role', profile.roleName);
      await prefs.setString('nomComplet', user.nomComplet);
      await prefs.setString('email', user.email);
      await prefs.setString('userId', user.userId.toString());
      _user = user;
      _profile = profile;
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorTranslator.fromException(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Étape 1: Inscription
      await _authService.register(
        nom: nom,
        prenom: prenom,
        email: email,
        motDePasse: motDePasse,
        telephone: telephone,
      );
      
      // Étape 2: Tentative de login automatique
      try {
        return await login(email, motDePasse);
      } catch (loginError) {
        // Si le login échoue mais l'inscription a réussi,
        // on considère quand même que l'inscription est réussie
        // pour permettre la redirection vers la création de compteur
        _errorMessage = 'Compte créé avec succès. Veuillez vous connecter manuellement.';
        _isLoading = false;
        notifyListeners();
        return true; // Retourner true pour permettre la redirection
      }
    } catch (e) {
      _errorMessage = ErrorTranslator.fromException(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        final nomComplet = prefs.getString('nomComplet') ?? '';
        final email = prefs.getString('email') ?? '';
        final roleName = prefs.getString('role') ?? 'CASHPOWER';
        final userId = prefs.getString('userId') ?? '0';
        final profile = UserProfile(id: userId, name: nomComplet, email: email, roleName: roleName);
        _profile = profile;
        _user = UserModel(
          token: token,
          type: 'Bearer',
          role: profile.roleName,
          nomComplet: profile.name,
          userId: int.tryParse(profile.id) ?? 0,
          email: profile.email,
        );
        _isLoggedIn = true;
      } else {
        _isLoggedIn = false;
      }
    } catch (_) {
      _isLoggedIn = false;
      _user = null;
      _profile = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('nomComplet');
    await prefs.remove('email');
    await prefs.remove('userId');
    _user = null;
    _profile = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

