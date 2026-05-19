import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../screens/home/home_shell.dart';
import '../../../theme/app_theme.dart';
import '../providers/iot_module_provider.dart';

class ModuleStatusPage extends StatefulWidget {
  final String deviceCode;
  final String deviceId;
  final String token;

  const ModuleStatusPage({
    super.key,
    required this.deviceCode,
    required this.deviceId,
    required this.token,
  });

  @override
  State<ModuleStatusPage> createState() => _ModuleStatusPageState();
}

class _ModuleStatusPageState extends State<ModuleStatusPage> {
  bool _checking = false;
  bool? _isActive;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => IotModuleProvider(),
      child: Builder(builder: (ctx) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Etat du module'),
            backgroundColor: AppColors.background,
            automaticallyImplyLeading: false,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Icone succes envoi
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline_rounded,
                          size: 48, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Configuration envoyee !',
                      style: AppTextStyles.heading1.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Le module ${widget.deviceId} a recu sa configuration WiFi et va maintenant se connecter au reseau.',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Carte info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.developer_board_rounded,
                            label: 'Module',
                            value: widget.deviceId,
                          ),
                          const Divider(height: 24, color: AppColors.borderColor),
                          _InfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Intervalle de releve',
                            value: 'Toutes les 60 secondes',
                          ),
                          const Divider(height: 24, color: AppColors.borderColor),
                          _StatusRow(isActive: _isActive),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Attente du premier releve
                    if (_isActive == null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.alertOrange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                color: AppColors.alertOrange, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'En attente du premier releve automatique (environ 60 secondes)',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.alertOrange),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Bouton verifier
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _checking ? null : () => _verify(ctx),
                        icon: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          _checking ? 'Verification...' : 'Verifier le module',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Nunito'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Bouton accueil
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomeShell()),
                          (_) => false,
                        ),
                        child: Text(
                          'Aller au tableau de bord',
                          style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Future<void> _verify(BuildContext ctx) async {
    setState(() => _checking = true);
    final provider = ctx.read<IotModuleProvider>();

    // Injecter le module courant pour refreshStatus
    await provider.refreshStatus(widget.token);

    // Lire le resultat directement depuis le service
    try {
      final svc = provider;
      await svc.refreshStatus(widget.token);
      final m = provider.module;
      setState(() {
        _isActive = m?.isActive ?? false;
        _checking = false;
      });
      if (_isActive == true && ctx.mounted) {
        _showSuccessSnack(ctx);
      }
    } catch (_) {
      setState(() => _checking = false);
    }
  }

  void _showSuccessSnack(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('Module pret et connecte !',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final bool? isActive;
  const _StatusRow({this.isActive});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    if (isActive == null) {
      color = AppColors.textSecondary;
      label = 'En attente...';
      icon = Icons.circle_outlined;
    } else if (isActive!) {
      color = AppColors.secondary;
      label = 'Module pret et connecte';
      icon = Icons.check_circle_rounded;
    } else {
      color = AppColors.alertOrange;
      label = 'Connexion en cours...';
      icon = Icons.sync_rounded;
    }

    return Row(
      children: [
        Icon(Icons.sensors_rounded, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text('Statut',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
