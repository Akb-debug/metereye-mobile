import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../core/error_translator.dart';
import '../models/user_model.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<UserModel> login(String email, String motDePasse) async {
    try {
      final response = await _dio.post(
        AppConfig.loginUrl,
        data: {
          'email': email,
          'motDePasse': motDePasse,
        },
      );
      debugPrint('LOGIN RESPONSE: ${response.data}');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw AppException(_dioMessage(e,
          fallback401: 'Email ou mot de passe incorrect.'));
    }
  }

  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String telephone,
    String role = 'PERSONNEL',
  }) async {
    try {
      await _dio.post(
        AppConfig.registerUrl,
        data: {
          'email': email,
          'motDePasse': motDePasse,
          'nom': nom,
          'prenom': prenom,
          'telephone': telephone,
          'role': role,
        },
      );
    } on DioException catch (e) {
      throw AppException(_dioMessage(e,
          fallback401: 'Identifiants incorrects.'));
    }
  }

  String _dioMessage(DioException e, {String? fallback401}) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    }
    final code = e.response?.statusCode;
    if (code == 401 && fallback401 != null) return fallback401;
    final msg = e.response?.data is Map
        ? e.response!.data['message']?.toString().trim()
        : null;
    if (msg != null && msg.isNotEmpty) return _capitalize(msg);
    return switch (code) {
      400 => 'Données incorrectes. Vérifiez le formulaire.',
      401 => 'Session expirée. Veuillez vous reconnecter.',
      403 => 'Accès refusé.',
      404 => 'Ressource introuvable.',
      409 => 'Un compte avec ces informations existe déjà.',
      500 => 'Erreur serveur. Réessayez dans quelques instants.',
      _ => 'Erreur de communication (code ${code ?? "?"})',
    };
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
