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
    return ModeLectureResponse(
      message: json['message'],
      modeLecture: json['modeLecture'],
      commentaire: json['commentaire'],
      statut: json['statut'],
    );
  }
}