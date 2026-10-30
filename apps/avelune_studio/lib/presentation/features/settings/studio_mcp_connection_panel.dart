import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/studio_mcp_providers.dart';
import '../../../platform/mcp/studio_mcp_service.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class StudioMcpConnectionButton extends ConsumerWidget {
  const StudioMcpConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => StudioTool(
    label: 'Connexion aux assistants',
    icon: Icons.hub_outlined,
    onPressed: () => showDialog<void>(
      context: context,
      builder: (_) =>
          StudioMcpConnectionPanel(service: ref.read(studioMcpServiceProvider)),
    ),
  );
}

class StudioMcpConnectionPanel extends StatefulWidget {
  const StudioMcpConnectionPanel({super.key, required this.service});
  final StudioMcpService service;

  @override
  State<StudioMcpConnectionPanel> createState() =>
      _StudioMcpConnectionPanelState();
}

class _StudioMcpConnectionPanelState extends State<StudioMcpConnectionPanel> {
  String? _copyMessage;

  Future<void> _copy() async {
    final connection = widget.service.connection;
    if (connection == null || widget.service.state != StudioMcpState.ready) {
      return;
    }
    try {
      await Clipboard.setData(
        ClipboardData(text: connection.clientConfiguration),
      );
      if (mounted) {
        setState(
          () => _copyMessage =
              'Configuration copiée. Collez-la dans votre assistant.',
        );
      }
    } on Object {
      if (mounted) {
        setState(() => _copyMessage = 'La copie a échoué. Réessayez.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.service,
    builder: (context, _) {
      final service = widget.service;
      final status = switch (service.state) {
        StudioMcpState.starting => 'Connexion en cours de démarrage…',
        StudioMcpState.ready => 'Connexion prête',
        StudioMcpState.failed => service.error ?? 'Connexion indisponible.',
        StudioMcpState.stopping => 'Arrêt de la connexion…',
        StudioMcpState.stopped => 'Connexion arrêtée',
      };
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: StudioPanel(
              title: 'Connexion aux assistants',
              icon: Icons.hub_outlined,
              actions: [
                StudioTool(
                  label: 'Fermer la connexion aux assistants',
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
              children: [
                const Text(
                  'Connectez votre assistant à Avelune Studio pour travailler sur le projet ouvert.',
                ),
                const SizedBox(height: 16),
                StudioNotice(
                  status,
                  isError: service.state == StudioMcpState.failed,
                ),
                const SizedBox(height: 12),
                if (service.state == StudioMcpState.ready) ...[
                  const Text(
                    'Copiez la configuration de connexion dans les réglages de votre assistant. Elle contient une clé privée valable pendant cette session.',
                  ),
                  const SizedBox(height: 12),
                  StudioButton(
                    label: 'Copier la configuration',
                    icon: Icons.copy,
                    onPressed: _copy,
                  ),
                ] else if (service.state == StudioMcpState.failed ||
                    service.state == StudioMcpState.stopped)
                  StudioButton(
                    label: 'Réessayer la connexion',
                    icon: Icons.refresh,
                    onPressed: () => unawaited(service.retry()),
                  ),
                if (_copyMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_copyMessage!),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
