import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/releve_providers.dart';
import 'releve_card.dart';

class ReleveHistoriqueWidget extends StatefulWidget {
  final int compteurId;
  final String token;

  const ReleveHistoriqueWidget({
    super.key,
    required this.compteurId,
    required this.token,
  });

  @override
  State<ReleveHistoriqueWidget> createState() => _ReleveHistoriqueWidgetState();
}

class _ReleveHistoriqueWidgetState extends State<ReleveHistoriqueWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReleveProvider>().chargerReleves(
            token: widget.token,
            compteurId: widget.compteurId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReleveProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur: ${provider.errorMessage}',
                style: TextStyle(fontSize: 13, color: Colors.red[700]),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.releves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Aucun relevé enregistré',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des relevés',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.releves.length,
          itemBuilder: (context, index) {
            return ReleveCard(releve: provider.releves[index]);
          },
        ),
      ],
    );
  }
}
