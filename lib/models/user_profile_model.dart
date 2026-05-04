// 🔄 MODIFIÉ — user_profile_model.dart — ajouts : seuilAlerteAnomalie, notificationPush/Sms/Email,
//              getter initiales, getter isVerifie, fix fromJson (nomComplet depuis DTO, role string)

class UserProfileModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final String roleName;
  final double seuilAlerteCredit;
  final double seuilAlerteAnomalie;
  final bool notificationPush;
  final bool notificationSms;
  final bool notificationEmail;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.roleName,
    required this.seuilAlerteCredit,
    required this.seuilAlerteAnomalie,
    required this.notificationPush,
    required this.notificationSms,
    required this.notificationEmail,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Le DTO envoie 'role' comme String direct ("CASHPOWER"), pas un objet imbriqué
    final roleValue = json['role'] is Map<String, dynamic>
        ? (json['role'] as Map<String, dynamic>)['name']?.toString() ?? 'USER'
        : json['role']?.toString() ?? json['roleName']?.toString() ?? 'USER';

    // Le DTO envoie 'nomComplet' = "Doe Jean" (nom + " " + prenom côté Java).
    // On essaie d'abord les champs séparés (compatibilité future), sinon on dérive.
    final nomDirect = json['nom']?.toString() ?? '';
    final prenomDirect = json['prenom']?.toString() ?? '';
    final nomCompletDto = json['nomComplet']?.toString() ?? '';
    final parts = nomCompletDto.split(' ').where((p) => p.isNotEmpty).toList();

    final nom = nomDirect.isNotEmpty
        ? nomDirect
        : (parts.length > 1 ? parts.sublist(1).join(' ') : nomCompletDto);
    final prenom = prenomDirect.isNotEmpty
        ? prenomDirect
        : (parts.isNotEmpty ? parts.first : '');

    // 'email' est le champ principal ; 'username' = email côté backend (getUsername() → email)
    final email = json['email']?.toString().isNotEmpty == true
        ? json['email'].toString()
        : json['username']?.toString() ?? '';

    return UserProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: email,
      nom: nom,
      prenom: prenom,
      telephone: json['telephone']?.toString() ?? '',
      roleName: roleValue,
      seuilAlerteCredit:
          (json['seuilAlerteCredit'] as num?)?.toDouble() ?? 5000.0,
      seuilAlerteAnomalie:
          (json['seuilAlerteAnomalie'] as num?)?.toDouble() ?? 30.0,
      notificationPush: json['notificationPush'] as bool? ?? true,
      notificationSms: json['notificationSms'] as bool? ?? false,
      notificationEmail: json['notificationEmail'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'roleName': roleName,
        'seuilAlerteCredit': seuilAlerteCredit,
        'seuilAlerteAnomalie': seuilAlerteAnomalie,
        'notificationPush': notificationPush,
        'notificationSms': notificationSms,
        'notificationEmail': notificationEmail,
      };

  /// "Jean Doe" — reconstruit depuis prenom + nom, fallback sur email
  String get nomComplet {
    final full = '${prenom.trim()} ${nom.trim()}'.trim();
    return full.isEmpty ? email : full;
  }

  /// "JD" — premières lettres du premier et du dernier mot de nomComplet
  String get initiales {
    final words =
        nomComplet.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '??';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  /// Vrai dès que le compte est chargé (compte actif côté backend)
  bool get isVerifie => true;
}
