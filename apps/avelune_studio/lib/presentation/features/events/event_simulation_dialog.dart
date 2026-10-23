import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_core/map_core.dart' show MapInstanceWorldState, MapInstanceRuntimeState;
import '../../../features/events/application/event_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'event_labels.dart';
import 'event_condition_labels.dart';

Future<void> showEventSimulation(
  BuildContext context,
  EventWorkspaceController controller,
  String id,
) => showDialog<void>(
  context: context,
  builder: (_) => _Simulation(controller: controller, id: id),
);

class _Simulation extends StatefulWidget {
  const _Simulation({required this.controller, required this.id});
  final EventWorkspaceController controller;
  final String id;
  @override
  State<_Simulation> createState() => _SimulationState();
}

class _SimulationState extends State<_Simulation> {
  final _values = <String, NarrativeValue>{};
  final _textValues = <String, String>{};
  final _consumed = <String>{};
  final _invalidValues = <String>{};
  final _localValues = <(String, String, String), bool>{};
  final _absentMaps = <String>{};
  NarrativeEventSimulationReport? _report;
  String? _error;
  void _run() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (_invalidValues.isNotEmpty) {
      setState(() {
        _report = null;
        _error = 'Corrigez les valeurs numériques avant de simuler.';
      });
      return;
    }
    try {
      setState(() {
        _error = null;
        _report = widget.controller.simulation(
          NarrativeEventSimulationInput(
            targetEventId: widget.id,
            factNarrativeValues: _values,
            consumedNarrativeEventIds: _consumed,
            mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
              for (final map in widget.controller.maps)
                if (!_absentMaps.contains(map.id))
                  map.id: MapInstanceRuntimeState(
                    instanceId: 'simulation:${map.id}',
                    eventBooleans: {
                      for (final entity in map.entities)
                        entity.id: {
                          for (final entry in _localValues.entries)
                            if (entry.key.$1 == map.id && entry.key.$2 == entity.id)
                              entry.key.$3: entry.value,
                        },
                    },
                  ),
            }),
          ),
        );
      });
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final report = _report;
    final localConditions = <(String, String, String)>{};
    for (final record in controller.records) {
      for (final condition in eventExpression(record).leaves) {
        condition.whenTyped<void>(
          fact: (_, _, _) {},
          narrativeEventConsumed: (_, _) {},
          mapEventInstanceBoolean: (map, owner, key, _) {
            localConditions.add((map, owner, key));
          },
        );
      }
    }
    return AlertDialog(
      title: const Text('Simulation du déclenchement'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const StudioNotice(
                'Essai isolé sur la version de travail, y compris les événements concurrents. Aucun état joueur ni fichier n’est modifié.',
              ),
              for (final fact in controller.project.facts) ...[
                const SizedBox(height: 12),
                if (fact.valueKind == NarrativeValueKind.boolean)
                  StudioSelect(
                    label: fact.label,
                    value: (_values[fact.id] ?? fact.initialValue).boolValue
                        .toString(),
                    options: const {'false': 'Non', 'true': 'Oui'},
                    onChanged: (v) => setState(() {
                      _report = null;
                      _values[fact.id] = NarrativeValue.boolean(v == 'true');
                    }),
                  )
                else
                  StudioDraftField(
                    key: ValueKey('simulation:${fact.id}'),
                    label: fact.label,
                    value:
                        _textValues[fact.id] ??
                        eventValueLabel(_values[fact.id] ?? fact.initialValue),
                    onChanged: (v) => setState(() {
                      _textValues[fact.id] = v;
                      _report = null;
                      try {
                        _values[fact.id] =
                            fact.valueKind == NarrativeValueKind.integer
                            ? NarrativeValue.integer(int.parse(v))
                            : NarrativeValue.string(v);
                        _invalidValues.remove(fact.id);
                        _error = null;
                      } catch (_) {
                        _invalidValues.add(fact.id);
                        _error = 'Une valeur numérique doit être un entier.';
                      }
                    }),
                  ),
              ],
              const SizedBox(height: 16),
              if (localConditions.isNotEmpty) ...[
                const Text('Mémoires locales de cet essai'),
                const Text('Une nouvelle instance repart avec ses mémoires désactivées. Ces valeurs ne sont pas des états persistants du jeu.'),
                for (final map in controller.maps.where((map) =>
                    localConditions.any((condition) => condition.$1 == map.id)))
                  StudioSelect(
                    key: ValueKey('simulation-instance:${map.id}'),
                    label: 'Instance de ${map.name}',
                    value: _absentMaps.contains(map.id) ? 'absent' : 'retained',
                    options: const {'retained': 'Présente', 'absent': 'Absente'},
                    onChanged: (value) => setState(() {
                      _report = null;
                      if (value == 'absent') {
                        _absentMaps.add(map.id);
                      } else {
                        _absentMaps.remove(map.id);
                      }
                    }),
                  ),
                for (final condition in localConditions)
                  StudioSelect(
                    key: ValueKey('simulation-local:${condition.$1}:${condition.$2}:${condition.$3}'),
                    label: '${controller.maps.where((map) => map.id == condition.$1).firstOrNull?.entities.where((entity) => entity.id == condition.$2).firstOrNull?.name ?? 'Propriétaire indisponible'} · ${condition.$3}',
                    value: (_localValues[condition] ?? false).toString(),
                    options: const {'false': 'Désactivée', 'true': 'Activée'},
                    onChanged: (value) => setState(() {
                      _report = null;
                      _localValues[condition] = value == 'true';
                    }),
                  ),
                const SizedBox(height: 16),
              ],
              const Text('Événements déjà consommés dans cet essai'),
              for (final record in controller.records)
                CheckboxListTile(
                  dense: true,
                  title: Text(eventName(record)),
                  value: _consumed.contains(record.id),
                  onChanged: (v) => setState(() {
                    _report = null;
                    if (v == true) {
                      _consumed.add(record.id);
                    } else {
                      _consumed.remove(record.id);
                    }
                  }),
                ),
              if (_error != null) StudioNotice(_error!, isError: true),
              if (report != null) ...[
                const Divider(),
                Text(
                  report.handledEventId == widget.id
                      ? 'Cet événement est sélectionné'
                      : report.handledEventId != null
                      ? 'Un autre événement est prioritaire'
                      : 'Aucun événement sélectionné',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (report.handledEventId != null)
                  Text(
                    controller.records
                            .where((r) => r.id == report.handledEventId)
                            .map(eventName)
                            .firstOrNull ??
                        report.handledEventId!,
                  ),
                for (final reason in report.reasons)
                  Text(eventSimulationReason(reason)),
                for (final candidate in report.candidates)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      '${candidate.name} · priorité ${candidate.priority} · ordre ${candidate.order}\n'
                      '${candidate.selected ? 'Sélectionné' : candidate.reasons.map(eventSimulationReason).join(' · ')}',
                    ),
                  ),
                for (final diagnostic in report.diagnostics) Text(diagnostic),
              ],
            ],
          ),
        ),
      ),
      actions: [
        StudioButton(
          label: 'Fermer',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
        StudioButton(
          label: 'Simuler',
          icon: Icons.science_outlined,
          onPressed: _run,
        ),
      ],
    );
  }
}

String eventSimulationReason(NarrativeEventSimulationReason reason) =>
    switch (reason) {
      NarrativeEventSimulationReason.sourceMissing => 'Source absente',
      NarrativeEventSimulationReason.eventMissing => 'Événement absent',
      NarrativeEventSimulationReason.authorityBlocked =>
        'Bloqué par le mode du registre',
      NarrativeEventSimulationReason.draft => 'Brouillon non configuré',
      NarrativeEventSimulationReason.disabled => 'Désactivé',
      NarrativeEventSimulationReason.worldRuleDisabled =>
        'Désactivé par une règle du monde',
      NarrativeEventSimulationReason.worldRuleHidden =>
        'Masqué par une règle du monde',
      NarrativeEventSimulationReason.sourceMismatch => 'Source différente',
      NarrativeEventSimulationReason.factConditionFalse =>
        'Condition d’état non satisfaite',
      NarrativeEventSimulationReason.narrativeEventConsumedConditionFalse =>
        'Condition d’événement non satisfaite',
      NarrativeEventSimulationReason.mapEventInstanceBooleanConditionFalse =>
        'État local de l’événement non satisfait',
      NarrativeEventSimulationReason.eventConsumed => 'Déjà joué',
      NarrativeEventSimulationReason.eventInFlight => 'Déjà en cours',
      NarrativeEventSimulationReason.claimTombstone =>
        'Source historique réservée',
      NarrativeEventSimulationReason.claimTargetsIneligible =>
        'Événements revendiqués non disponibles',
      NarrativeEventSimulationReason.noEligibleCandidate =>
        'Aucun candidat admissible',
      NarrativeEventSimulationReason.runtimeReferenceUnavailable =>
        'Référence indisponible pour le jeu',
    };
