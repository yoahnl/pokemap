import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/events/application/event_outcome_source_summary.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<NarrativeOutcomeRef?> chooseEventOutcome(
  BuildContext context,
  NarrativeOutcomeEventSourceCatalog catalog,
) => showDialog<NarrativeOutcomeRef>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Résultat public reçu'),
    content: SizedBox(
      width: 620,
      height: 420,
      child: ListView(
        children: [
          if (catalog.options.isEmpty)
            const Text('Aucun résultat disponible dans ce projet.'),
          for (final option in catalog.options)
            StudioChoice(
              key: ValueKey('outcome:${option.debugTechnicalLabel}'),
              label: '${option.producerLabel} · ${option.outcomeLabel}',
              subtitle: option.selectable
                  ? option.debugTechnicalLabel
                  : option.unavailableReason,
              leading: Icon(
                option.selectable ? Icons.flag_outlined : Icons.lock_outline,
              ),
              onTap: option.selectable
                  ? () => Navigator.pop(context, option.outcome)
                  : null,
            ),
        ],
      ),
    ),
    actions: [
      StudioButton(
        label: 'Annuler',
        secondary: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);

class EventOutcomeSummary extends StatelessWidget {
  const EventOutcomeSummary({
    super.key,
    required this.source,
    required this.controller,
    required this.onOpenProducer,
  });
  final NarrativeEventSourceRef? source;
  final EventWorkspaceController controller;
  final ValueChanged<String>? onOpenProducer;
  @override
  Widget build(BuildContext context) {
    final summary = summarizeEventOutcomeSource(
      source: source,
      catalog: controller.catalog.outcomeSources,
      scenes: controller.project.scenes,
    );
    return SingleChildScrollView(
      child: StudioPanel(
        title: 'Global / Résultats',
        children: [
          const Icon(Icons.flag_outlined, size: 52),
          const SizedBox(height: 20),
          Text(
            summary.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Text(summary.outcomeLabel),
          Text(summary.producerKindLabel),
          const SizedBox(height: 12),
          Text(summary.status),
          if (summary.openableProducerId case final producerId?) ...[
            const SizedBox(height: 12),
            StudioButton(
              label: 'Ouvrir le producteur',
              icon: Icons.open_in_new,
              onPressed: onOpenProducer == null
                  ? null
                  : () => onOpenProducer!(producerId),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Cet événement reçoit un signal global. Il ne possède pas de position sur une carte.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Le vrai test en jeu doit faire jouer le producteur. La simulation du déclenchement reste disponible ici.',
          ),
        ],
      ),
    );
  }
}
