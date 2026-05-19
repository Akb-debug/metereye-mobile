import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Traduit toute erreur (HTTP, réseau, exception) en message lisible en français.
class ErrorTranslator {
  ErrorTranslator._();

  /// À utiliser dans un bloc `catch (e)` pour afficher un message clair.
  static String fromException(Object e) {
    if (e is AppException) return e.message;
    if (e is SocketException) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    }
    if (e is Exception) {
      final raw = e.toString().replaceFirst('Exception: ', '').trim();
      return _polish(raw.isNotEmpty ? raw : 'Erreur inconnue.');
    }
    return 'Une erreur inattendue est survenue.';
  }

  /// Produit une [AppException] depuis une réponse HTTP en extrayant le message backend.
  static AppException fromResponse(http.Response res, {String? fallback}) {
    // Tente d'extraire le message du body JSON
    String? backendMsg;
    try {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final raw = body['message']?.toString().trim() ?? '';
      if (raw.isNotEmpty) backendMsg = raw;
    } catch (_) {}

    final msg = backendMsg != null
        ? _polish(backendMsg)
        : _fromCode(res.statusCode, fallback);

    return AppException(msg);
  }

  // ── Codes HTTP ─────────────────────────────────────────────────────────────

  static String _fromCode(int code, String? fallback) => switch (code) {
        400 => fallback ?? 'Données incorrectes. Vérifiez le formulaire.',
        401 => 'Session expirée. Veuillez vous reconnecter.',
        403 => 'Accès refusé. Vous n\'avez pas les droits nécessaires.',
        404 => fallback ?? 'Ressource introuvable.',
        409 => fallback ?? 'Un enregistrement similaire existe déjà.',
        422 => 'Données invalides. Vérifiez les champs saisis.',
        500 => 'Erreur serveur. Réessayez dans quelques instants.',
        503 => 'Service temporairement indisponible. Réessayez plus tard.',
        _ => fallback ?? 'Erreur de communication (code $code).',
      };

  // ── Nettoyage du message brut ──────────────────────────────────────────────

  static String _polish(String raw) {
    var msg = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '')
        .trim();

    if (msg.isEmpty) return 'Erreur inconnue.';

    // Majuscule en début
    msg = msg[0].toUpperCase() + msg.substring(1);

    // Point final si absent
    if (!msg.endsWith('.') && !msg.endsWith('!') && !msg.endsWith('?')) {
      msg += '.';
    }

    return msg;
  }
}

/// Exception applicative avec message déjà formaté pour l'utilisateur.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}
