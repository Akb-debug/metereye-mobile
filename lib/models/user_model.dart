class UserModel {
  final String token;
  final String type;
  final String role;
  final String nomComplet;
  final int userId;
  final String email;

  UserModel({
    required this.token,
    required this.type,
    required this.role,
    required this.nomComplet,
    required this.userId,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final nested = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    String str(String key) =>
        json[key]?.toString().trim().isNotEmpty == true
            ? json[key].toString().trim()
            : nested[key]?.toString().trim() ?? '';

    final nomComplet = str('nomComplet').isNotEmpty
        ? str('nomComplet')
        : [str('prenom'), str('nom')]
            .where((v) => v.isNotEmpty)
            .join(' ');

    return UserModel(
      token: json['token']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Bearer',
      role: str('role').isNotEmpty ? str('role') : 'PERSONNEL',
      nomComplet: nomComplet,
      userId: (json['userId'] as num?)?.toInt() ??
          (nested['id'] as num?)?.toInt() ?? 0,
      email: str('email'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'type': type,
      'role': role,
      'nomComplet': nomComplet,
      'userId': userId,
      'email': email,
    };
  }
}
