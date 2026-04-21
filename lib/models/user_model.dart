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
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return UserModel(
      token: json['token']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Bearer',
      role: user['role']?.toString() ?? 'PERSONNEL',
      nomComplet: user['email']?.toString() ?? '',
      userId: (user['id'] as num?)?.toInt() ?? 0,
      email: user['email']?.toString() ?? '',
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
