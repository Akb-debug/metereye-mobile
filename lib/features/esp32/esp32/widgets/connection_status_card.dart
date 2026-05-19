import 'package:flutter/material.dart';
import '../providers/esp32_bluetooth_provider.dart';

class ConnectionStatusCard extends StatelessWidget {
  final ConnectionStatus status;
  final String? deviceName;

  const ConnectionStatusCard({
    super.key,
    required this.status,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  if (deviceName != null && status == ConnectionStatus.connected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Connecté à: $deviceName',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    Color backgroundColor;
    Color iconColor;
    IconData iconData;

    switch (status) {
      case ConnectionStatus.disconnected:
        backgroundColor = Colors.grey.shade100;
        iconColor = Colors.grey;
        iconData = Icons.bluetooth_disabled;
        break;
      case ConnectionStatus.scanning:
        backgroundColor = Colors.blue.shade50;
        iconColor = Colors.blue;
        iconData = Icons.search;
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        iconData = Icons.bluetooth_searching;
        break;
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.shade50;
        iconColor = Colors.green;
        iconData = Icons.bluetooth_connected;
        break;
      case ConnectionStatus.configuring:
        backgroundColor = Colors.purple.shade50;
        iconColor = Colors.purple;
        iconData = Icons.settings;
        break;
      case ConnectionStatus.configured:
        backgroundColor = Colors.teal.shade50;
        iconColor = Colors.teal;
        iconData = Icons.check_circle;
        break;
      case ConnectionStatus.error:
        backgroundColor = Colors.red.shade50;
        iconColor = Colors.red;
        iconData = Icons.error_outline;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  String _getStatusTitle() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Non connecté';
      case ConnectionStatus.scanning:
        return 'Recherche...';
      case ConnectionStatus.connecting:
        return 'Connexion...';
      case ConnectionStatus.connected:
        return 'Connecté';
      case ConnectionStatus.configuring:
        return 'Configuration...';
      case ConnectionStatus.configured:
        return 'Configuré';
      case ConnectionStatus.error:
        return 'Erreur';
    }
  }

  String _getStatusDescription() {
    switch (status) {
      case ConnectionStatus.disconnected:
        return 'Sélectionnez un appareil ESP32-CAM pour commencer';
      case ConnectionStatus.scanning:
        return 'Recherche des modules ESP32-CAM à proximité';
      case ConnectionStatus.connecting:
        return 'Connexion au module en cours...';
      case ConnectionStatus.connected:
        return 'Module connecté en Bluetooth';
      case ConnectionStatus.configuring:
        return 'Envoi de la configuration WiFi...';
      case ConnectionStatus.configured:
        return 'Configuration terminée avec succès';
      case ConnectionStatus.error:
        return 'Une erreur est survenue. Veuillez réessayer';
    }
  }
}
