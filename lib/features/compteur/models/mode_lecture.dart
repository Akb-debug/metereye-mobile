enum ModeLecture {
  manual,
  esp32Cam,
  sensor;

  String toApiValue() {
    switch (this) {
      case ModeLecture.manual:
        return 'MANUAL';
      case ModeLecture.esp32Cam:
        return 'ESP32_CAM';
      case ModeLecture.sensor:
        return 'SENSOR';
    }
  }

  String get label {
    switch (this) {
      case ModeLecture.manual:
        return 'Lecture manuelle';
      case ModeLecture.esp32Cam:
        return 'Lecture par ESP32-CAM';
      case ModeLecture.sensor:
        return 'Lecture par capteur PZEM-004T';
    }
  }

  String get description {
    switch (this) {
      case ModeLecture.manual:
        return 'L’utilisateur saisira lui-même les relevés.';
      case ModeLecture.esp32Cam:
        return 'Le compteur sera lu automatiquement via le module ESP32-CAM.';
      case ModeLecture.sensor:
        return 'Le relevé proviendra directement du capteur.';
    }
  }
}