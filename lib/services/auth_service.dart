import 'dart:io';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
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
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.error is SocketException) {
        throw Exception('Impossible de joindre le serveur.');
      }
      throw Exception(
          e.response?.data?['message']?.toString() ?? 'Erreur serveur');
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
      throw Exception(
          e.response?.data?['message']?.toString() ?? 'Inscription impossible');
    }
  }
}
