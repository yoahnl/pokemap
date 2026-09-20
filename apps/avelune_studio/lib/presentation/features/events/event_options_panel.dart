import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/events/domain/event_record_view.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_outcome_picker.dart';

class EventOptionsPanel extends StatelessWidget {
  const EventOptionsPanel({
    super.key,
    required this.record,
    required this.mode,
    required this.onReuse,
    required this.onReset,
    required this.outcomes,
    required this.onPriority,
    required this.onOrder,
    required this.onConfigure,
    required this.onEnabled,
    required this.onMode,
    this.priorityInput,
    this.orderInput,
  });
  final NarrativeEventRecord record;
  final EventSystemMode? mode;
  final String? priorityInput, orderInput;
  final NarrativeOutcomeEventSourceCatalog outcomes;
  final ValueChanged<NarrativeEventReusePolicy> onReuse;
  final ValueChanged<NarrativeEventResetPolicy> onReset;
  final ValueChanged<String> onPriority, onOrder;
  final VoidCallback onConfigure, onEnabled, onMode;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: StudioPanel(
      title: 'Comportement et activation',
      children: [
        const Text(
          'Ces changements restent locaux jusqu’à Enregistrer. Modifier un événement activé prépare une version désactivée.',
        ),
        const SizedBox(height: 16),
        StudioSelect(
          label: 'Après avoir joué',
          value: record.reusePolicy?.name,
          options: const {
            'oneShot': 'Une seule occurrence',
            'reusable': 'Peut être rejoué',
          },
          onChanged: (v) => onReuse(NarrativeEventReusePolicy.values.byName(v)),
        ),
        const SizedBox(height: 16),
        StudioSelect(
          label: 'Réarmer l’occurrence',
          value: switch (record.resetPolicy) {
            NarrativeEventResetNever() => 'never',
            NarrativeEventResetOnMapReentry() => 'map',
            NarrativeEventResetOnOutcomeReceived() => 'outcome',
          },
          options: const {
            'never': 'Jamais',
            'map': 'À la réentrée sur la carte',
            'outcome': 'À la réception d’un résultat',
          },
          onChanged: (v) async {
            if (v == 'never') onReset(const NarrativeEventResetPolicy.never());
            if (v == 'map') {
              onReset(const NarrativeEventResetPolicy.onMapReentry());
            }
            if (v == 'outcome') {
              final selected = await chooseEventOutcome(context, outcomes);
              if (selected != null && context.mounted) {
                onReset(NarrativeEventResetPolicy.onOutcomeReceived(selected));
              }
            }
          },
        ),
        if (record.resetPolicy case NarrativeEventResetOnOutcomeReceived(
          :final outcome,
        ))
          Text(
            '${outcome.producerKind.name} · ${outcome.producerId} · ${outcome.outcomeId}',
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (record.draftOrNull != null)
              StudioButton(
                label: 'Configurer l’événement',
                onPressed: onConfigure,
              )
            else
              StudioButton(
                label: record.enabledOrNull == true
                    ? 'Préparer la désactivation'
                    : 'Préparer l’activation',
                onPressed: onEnabled,
              ),
          ],
        ),
        const SizedBox(height: 20),
        StudioCommitField(
          key: ValueKey('priority:${record.id}'),
          label: 'Priorité',
          alwaysCommit: true,
          value: priorityInput ?? '${record.priority}',
          onCommit: onPriority,
        ),
        const SizedBox(height: 16),
        StudioCommitField(
          key: ValueKey('order:${record.id}'),
          label: 'Ordre de distribution',
          alwaysCommit: true,
          value: orderInput ?? '${record.order}',
          onCommit: onOrder,
        ),
        const SizedBox(height: 16),
        Text('Mode du projet : ${mode?.name ?? 'registre absent'}'),
        if (mode == null || mode == EventSystemMode.legacyOnly)
          const StudioNotice(
            'Le mode historique peut empêcher la distribution de cet événement. Activer un événement ne change pas le mode du projet.',
          ),
        const SizedBox(height: 8),
        StudioButton(
          label: 'Examiner le mode du projet',
          secondary: true,
          onPressed: onMode,
        ),
      ],
    ),
  );
}
