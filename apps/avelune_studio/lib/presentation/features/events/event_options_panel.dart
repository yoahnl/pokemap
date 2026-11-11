import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/events/application/event_option_choices.dart';
import '../../../features/events/domain/event_record_view.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/layout/studio_section.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_labels.dart';
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
    this.onParallel,
    this.ownerVariants = const {},
    this.priorityInput,
    this.orderInput,
  });
  final NarrativeEventRecord record;
  final EventSystemMode? mode;
  final String? priorityInput, orderInput;
  final NarrativeOutcomeEventSourceCatalog outcomes;
  final ValueChanged<NarrativeEventParallelPolicy?>? onParallel;
  final Map<String, String> ownerVariants;
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
        Text('Effet en jeu', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(eventRepeatEffect(record, outcomes)),
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
          value: eventResetChoice(record.resetPolicy),
          options: const {
            'never': 'Jamais',
            'map': 'À la réentrée sur la carte',
            'outcome': 'À la réception d’un résultat',
          },
          onChanged: (v) async {
            if (eventResetWithoutOutcome(v) case final policy?) {
              onReset(policy);
            }
            if (v == 'outcome') {
              final selected = await chooseEventOutcome(context, outcomes);
              if (selected != null && context.mounted) {
                onReset(NarrativeEventResetPolicy.onOutcomeReceived(selected));
              }
            }
          },
        ),
        if (eventResetNote(record) case final note?)
          Text(note, style: Theme.of(context).textTheme.bodySmall),
        if (record.resetPolicy case NarrativeEventResetOnOutcomeReceived(
          :final outcome,
        ))
          Text(
            '${outcome.producerKind.name} · ${outcome.producerId} · ${outcome.outcomeId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 16),
        StudioSelect(
          label: 'Exécution',
          value: record.parallelPolicy == null ? 'sequential' : 'parallel',
          options: {
            'sequential': 'Séquentielle',
            if (eventAllowsParallel(record)) 'parallel': 'Parallèle',
          },
          onChanged: onParallel == null
              ? null
              : (value) => onParallel!(eventParallelChoice(value)),
        ),
        if (record.parallelPolicy case final policy?) ...[
          const SizedBox(height: 12),
          const Text(
            'Répète une courte mise à jour d’état sans immobiliser le joueur. Les dialogues, combats et transitions suspendent le cycle.',
          ),
          const SizedBox(height: 12),
          StudioCommitField(
            key: ValueKey('parallel-cadence:${record.id}'),
            label: 'Cadence (ms)',
            value: '${policy.cadenceMs}',
            tryCommit: (value) {
              final next = eventParallelCadence(policy, value);
              if (next == null || onParallel == null) return false;
              onParallel!(next);
              return true;
            },
          ),
          if (record.source?.kind ==
              NarrativeEventSourceKind.entityAutorun) ...[
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Page propriétaire',
              value: eventParallelOwnerChoice(policy),
              options: {
                eventAllOwnerPages: 'Toutes les pages actives',
                ...ownerVariants,
              },
              onChanged: onParallel == null
                  ? null
                  : (value) =>
                        onParallel!(eventParallelOwnerPage(policy, value)),
            ),
          ],
        ],
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
        if (mode == null || mode == EventSystemMode.legacyOnly) ...[
          const SizedBox(height: 12),
          const StudioNotice(
            'Le mode historique peut empêcher la distribution de cet événement. Activer un événement ne change pas le mode du projet.',
          ),
        ],
        const SizedBox(height: 12),
        StudioSection(
          key: PageStorageKey<String>('event-advanced:${record.id}'),
          title: 'Options avancées',
          collapsible: true,
          initiallyExpanded: priorityInput != null || orderInput != null,
          children: [
            SizedBox(
              key: PageStorageKey<String>('event-advanced-fields:${record.id}'),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quand plusieurs événements partagent ce déclencheur, la priorité la plus haute passe d’abord, puis l’ordre le plus petit. Propres à cet événement, enregistrés avec Enregistrer.',
                  ),
                  const SizedBox(height: 12),
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
                  Text('Mode des événements du projet : ${_modeLabel(mode)}'),
                  const SizedBox(height: 4),
                  const Text(
                    'Ce réglage concerne tout le projet. Enregistrer cet événement ne le modifie jamais : il se change dans sa propre fenêtre, qui l’enregistre immédiatement après votre choix.',
                  ),
                  const SizedBox(height: 8),
                  StudioButton(
                    label: 'Examiner le mode du projet',
                    secondary: true,
                    onPressed: onMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  static String _modeLabel(EventSystemMode? mode) => switch (mode) {
    null => 'registre absent',
    EventSystemMode.legacyOnly => 'historique',
    EventSystemMode.dualRead => 'mixte',
    EventSystemMode.v2Only => 'moderne',
  };
}
