enum TypeCompteur {
  classique,
  cashPower;

  String toApiValue() {
    switch (this) {
      case TypeCompteur.classique:
        return 'CLASSIQUE';
      case TypeCompteur.cashPower:
        return 'CASH_POWER';
    }
  }

  String get label {
    switch (this) {
      case TypeCompteur.classique:
        return 'Compteur classique';
      case TypeCompteur.cashPower:
        return 'Cash Power';
    }
  }
}