// ✅ CRÉÉ — nouveau fichier
// Mappé sur AlerteResponseDTO du backend Spring Boot

class AlerteModel {
  final int id;
  final String typeAlerte;
  final String message;
  final bool lue;
  final DateTime? dateCreation;
  final int? compteurId;
  final String? compteurReference;

  const AlerteModel({
    required this.id,
    required this.typeAlerte,
    required this.message,
    required this.lue,
    this.dateCreation,
    this.compteurId,
    this.compteurReference,
  });

  factory AlerteModel.fromJson(Map<String, dynamic> json) {
    return AlerteModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      typeAlerte: json['typeAlerte']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      lue: json['lue'] as bool? ?? false,
      dateCreation: _parseDate(json['dateCreation']),
      compteurId: (json['compteurId'] as num?)?.toInt(),
      compteurReference: json['compteurReference']?.toString(),
    );
  }

  AlerteModel copyWith({bool? lue}) => AlerteModel(
        id: id,
        typeAlerte: typeAlerte,
        message: message,
        lue: lue ?? this.lue,
        dateCreation: dateCreation,
        compteurId: compteurId,
        compteurReference: compteurReference,
      );

  // ── Getters UI ────────────────────────────────────────────────────────────

  /// Mappe typeAlerte → type visuel utilisé par AlerteItem
  /// 'urgent' (rouge) | 'warning' (orange) | 'success' (vert) | 'info' (bleu)
  String get type {
    switch (typeAlerte) {
      case 'COUPURE_IMMINENTE':
      case 'APPAREIL_HORS_LIGNE':
      case 'CREDIT_FAIBLE':
        return 'urgent';
      case 'ANOMALIE_CONSOMMATION':
        return 'warning';
      case 'RAPPORT_DISPONIBLE':
      case 'APPAREIL_RECONNECTE':
      case 'NOUVEAU_RELEVE':
        return 'success';
      default:
        return 'info';
    }
  }

  /// Titre court affiché dans la card
  String get titre {
    switch (typeAlerte) {
      case 'NOUVEAU_RELEVE':
        return 'Nouveau relevé';
      case 'CREDIT_FAIBLE':
        return 'Crédit faible';
      case 'COUPURE_IMMINENTE':
        return 'Coupure imminente !';
      case 'ANOMALIE_CONSOMMATION':
        return 'Anomalie de consommation';
      case 'RAPPORT_DISPONIBLE':
        return 'Rapport disponible';
      case 'APPAREIL_HORS_LIGNE':
        return 'Connexion IoT interrompue';
      case 'APPAREIL_RECONNECTE':
        return 'Module IoT reconnecté';
      case 'CONNEXION_UTILISATEUR':
        return 'Connexion';
      default:
        return typeAlerte.replaceAll('_', ' ');
    }
  }

  /// Format "Auj. HH:mm" | "Hier HH:mm" | "jj Mmm" — sans dépendance intl
  String get heureFormatted {
    if (dateCreation == null) return '--';
    final now = DateTime.now();
    final d = dateCreation!;
    final hhmm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Auj. $hhmm';
    }
    final hier = now.subtract(const Duration(days: 1));
    if (d.year == hier.year && d.month == hier.month && d.day == hier.day) {
      return 'Hier $hhmm';
    }
    const mois = [
      'Jan','Fév','Mar','Avr','Mai','Juin',
      'Juil','Aoû','Sep','Oct','Nov','Déc'
    ];
    return '${d.day} ${mois[d.month - 1]}';
  }

  // ── Helpers privés ────────────────────────────────────────────────────────

  /// Gère les deux formats Spring Boot :
  ///   • tableau  [year, month, day, hour, min, sec, nano]  (timestamp=true, défaut)
  ///   • string   "2024-01-15T09:47:00"                     (timestamp=false)
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final p = raw.cast<num>();
      return DateTime(
        p[0].toInt(),
        p[1].toInt(),
        p[2].toInt(),
        p.length > 3 ? p[3].toInt() : 0,
        p.length > 4 ? p[4].toInt() : 0,
        p.length > 5 ? p[5].toInt() : 0,
      );
    }
    return DateTime.tryParse(raw.toString());
  }
}
