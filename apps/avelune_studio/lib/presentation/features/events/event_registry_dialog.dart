import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<void> showEventRegistryDialog(
  BuildContext context,
  EventWorkspaceController controller,
) async {
  final mode = await showDialog<EventSystemMode>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mode des événements du projet'),
      content: const Text(
        'Ce réglage concerne tout le projet. Le mode mixte conserve les revendications des anciennes sources ; le mode moderne peut être refusé si elles ne sont pas traitées. Enregistrez d’abord vos brouillons. Le changement choisi sera enregistré immédiatement.',
      ),
      actions: [
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
        StudioButton(
          label: 'Activer le mode mixte',
          onPressed: () => Navigator.pop(context, EventSystemMode.dualRead),
        ),
        StudioButton(
          label: 'Activer le mode moderne',
          secondary: true,
          onPressed: () => Navigator.pop(context, EventSystemMode.v2Only),
        ),
      ],
    ),
  );
  if (mode != null && context.mounted) await controller.changeMode(mode);
}
