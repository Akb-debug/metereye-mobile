class AppData {
  // Utilisateur
  static const String userName     = "Koffi Agbémagnon";
  static const String userPhone    = "+228 90 12 34 56";
  static const String userEmail    = "k.agbemagnon@email.tg";
  static const String userQuartier = "Adidogomé, Lomé";
  static const String numCompteur  = "CCP-2024-07841";
  static const String moduleId     = "ESP32-A4F2-0841";

  // Compteur CashPower — état actuel
  static const int    creditUnites    = 1247;   // unités restantes
  static const double creditPct       = 0.62;   // 62%
  static const int    joursRestants   = 8;
  static const double consoAujourd    = 2.4;    // kWh aujourd'hui
  static const double consoMois       = 68.3;   // kWh ce mois
  static const double moyJournaliere  = 155.0;  // unités/jour
  static const String dernierelecture = "Aujourd'hui à 09:47";
  static const String prochaineAlerte = "28 Fév 2025 à 14h30";

  // Consommation 7 derniers jours (kWh)
  static const List<Map<String, dynamic>> conso7j = [
    {"jour": "Lun", "kwh": 2.1},
    {"jour": "Mar", "kwh": 3.4},
    {"jour": "Mer", "kwh": 2.8},
    {"jour": "Jeu", "kwh": 4.8},
    {"jour": "Ven", "kwh": 2.2},
    {"jour": "Sam", "kwh": 3.9},
    {"jour": "Dim", "kwh": 2.4},
  ];

  // Lectures du compteur sur 30 jours (unités lues)
  static const List<Map<String, dynamic>> lectures30j = [
    {"date": "01 Fév", "unites": 1850},
    {"date": "03 Fév", "unites": 1695},
    {"date": "05 Fév", "unites": 1540},
    {"date": "07 Fév", "unites": 1420},
    {"date": "10 Fév", "unites": 1920}, // recharge
    {"date": "12 Fév", "unites": 1760},
    {"date": "14 Fév", "unites": 1590},
    {"date": "16 Fév", "unites": 1435},
    {"date": "18 Fév", "unites": 1340},
    {"date": "20 Fév", "unites": 1840}, // recharge
    {"date": "22 Fév", "unites": 1680},
    {"date": "24 Fév", "unites": 1490},
    {"date": "Auj.",   "unites": 1247},
  ];

  // Alertes
  static const List<Map<String, dynamic>> alertes = [
    {
      "type": "urgent",
      "titre": "Crédit critique !",
      "desc": "Il ne reste que 150 unités. Coupure estimée dans 21h.",
      "heure": "Auj. 08:14",
      "lue": false
    },
    {
      "type": "warning",
      "titre": "Consommation inhabituelle",
      "desc": "Consommation d'hier (4.8 kWh) est 2× votre moyenne habituelle.",
      "heure": "Hier 23:05",
      "lue": false
    },
    {
      "type": "success",
      "titre": "Lecture effectuée avec succès",
      "desc": "Crédit lu : 1 247 unités. Module opérationnel.",
      "heure": "Auj. 09:47",
      "lue": false
    },
    {
      "type": "warning",
      "titre": "Crédit faible dans 3 jours",
      "desc": "À votre rythme actuel, le crédit sera épuisé le 28 Fév.",
      "heure": "Hier 07:00",
      "lue": true
    },
    {
      "type": "info",
      "titre": "Rapport hebdomadaire",
      "desc": "Consommation semaine du 10 au 17 Fév : 42 kWh (−8% vs semaine préc.).",
      "heure": "17 Fév",
      "lue": true
    },
    {
      "type": "warning",
      "titre": "Pic de consommation détecté",
      "desc": "Pics entre 19h–21h durant 3 jours consécutifs. Vérifiez vos appareils.",
      "heure": "15 Fév",
      "lue": true
    },
    {
      "type": "urgent",
      "titre": "Connexion IoT interrompue",
      "desc": "Module ESP32 hors ligne pendant 2h. Vérifiez le câble USB et le WiFi.",
      "heure": "14 Fév",
      "lue": true
    },
    {
      "type": "success",
      "titre": "Objectif atteint !",
      "desc": "Vous avez réduit votre consommation de 8% ce mois-ci. Bravo !",
      "heure": "10 Fév",
      "lue": true
    },
  ];
}
