import 'package:flutter/foundation.dart';

/// Bus d'événements léger : publié quand un relevé est enregistré en base.
/// Les providers qui affichent des données s'abonnent pour se rafraîchir
/// automatiquement sans couplage direct.
class DataSyncNotifier extends ChangeNotifier {
  void notifyReadingAdded() => notifyListeners();
}
