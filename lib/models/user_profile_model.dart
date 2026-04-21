class UserProfileModel {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final String telephone;
  final double seuilAlerteCredit;
  final String roleName;

  UserProfileModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.seuilAlerteCredit,
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
      seuilAlerteCredit: (json['seuilAlerteCredit'] as num?)?.toDouble() ?? 0.0,
      roleName: role['name']?.toString() ?? json['roleName']?.toString() ?? 'USER',
    );
  }

  String get nomComplet {
    final fullName = '${prenom.trim()} ${nom.trim()}'.trim();
    return fullName.isEmpty ? email : fullName;
  }
}
