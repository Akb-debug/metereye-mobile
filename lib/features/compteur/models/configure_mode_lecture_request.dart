import 'mode_lecture.dart';

class ConfigureModeLectureRequest {
  final ModeLecture modeLecture;
  final String commentaire;

  ConfigureModeLectureRequest({
    required this.modeLecture,
    required this.commentaire,
  });

  Map<String, dynamic> toJson() => {
        'modeLecture': modeLecture.toApiValue(),
        'commentaire': commentaire,
      };
}