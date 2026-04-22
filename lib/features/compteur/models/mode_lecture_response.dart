class ModeLectureResponse {
  final String? message;
  final String? modeLecture;
  final String? commentaire;
  final String? statut;

  ModeLectureResponse({
    this.message,
    this.modeLecture,
    this.commentaire,
    this.statut,
  });

  factory ModeLectureResponse.fromJson(Map<String, dynamic> json) {
    // Vérifier si la réponse a une structure avec un champ "data"
    final data = json['data'] ?? json;
    
    return ModeLectureResponse(
      message: json['message'] ?? data['message'],
      modeLecture: data['modeLecture'],
      commentaire: data['commentaire'],
      statut: data['statut'],
    );
  }
}