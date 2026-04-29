// 🔄 MODIFIÉ — user_profile_model.dart — ajouts : seuilAlerteAnomalie,
//   notificationPush, notificationSms, notificationEmail, getter initiales

class UserProfileModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final double seuilAlerteCredit;
  final double seuilAlerteAnomalie;
  final bool notificationPush;
  final bool notificationSms;
  final bool notificationEmail;
  final String roleName;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.seuilAlerteCredit,
    required this.seuilAlerteAnomalie,
    required this.notificationPush,
    required this.notificationSms,
    required this.notificationEmail,
    required this.roleName,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final role = json['role'] is Map<String, dynamic>
        ? json['role'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UserProfileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prenom: json['prenom']?.toString() ?? '',
      telephone: json['telephone']?.toString() ?? '',
      seuilAlerteCredit:
          (json['seuilAlerteCredit'] as num?)?.toDouble() ?? 0.0,
      seuilAlerteAnomalie:
          (json['seuilAlerteAnomalie'] as num?)?.toDouble() ?? 0.0,
      notificationPush: json['notificationPush'] as bool? ?? false,
      notificationSms: json['notificationSms'] as bool? ?? false,
      notificationEmail: json['notificationEmail'] as bool? ?? false,
      roleName:
          role['name']?.toString() ?? json['roleName']?.toString() ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'seuilAlerteCredit': seuilAlerteCredit,
        'seuilAlerteAnomalie': seuilAlerteAnomalie,
        'notificationPush': notificationPush,
        'notificationSms': notificationSms,
        'notificationEmail': notificationEmail,
        'roleName': roleName,
      };

  /// "JD" depuis prenom + nom (première lettre de chacun, majuscule)
  String get initiales {
    final p = prenom.trim().isNotEmpty ? prenom.trim()[0].toUpperCase() : '';
    final n = nom.trim().isNotEmpty ? nom.trim()[0].toUpperCase() : '';
    final result = '$p$n';
    return result.isNotEmpty ? result : '??';
  }

  /// "Jean Doe"
  String get nomComplet {
    final fullName = '${prenom.trim()} ${nom.trim()}'.trim();
    return fullName.isEmpty ? email : fullName;
  }

  /// Compte actif si l'objet existe
  bool get isVerifie => true;
}
