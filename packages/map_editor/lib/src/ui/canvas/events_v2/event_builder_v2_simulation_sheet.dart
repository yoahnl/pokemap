import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/use_cases/narrative_event_builder_v2_use_case.dart';
import '../../design_system/design_system.dart';

typedef RunEventBuilderV2Simulation = Future<NarrativeEventSimulationReport>
    Function(NarrativeEventSimulationInput input);

/// Controlled, read-only preview of the production Event dispatch decision.
///
/// The sheet only edits a temporary Fact/progress/source state. Its callback
/// must invoke the core simulation operation, which delegates to the same
/// `NarrativeEventDispatchAuthority` used by gameplay and runtime.
class EventBuilderV2SimulationSheet extends StatefulWidget {
  const EventBuilderV2SimulationSheet({
    super.key,
    required this.snapshot,
    required this.eventId,
    required this.onRun,
  });

  final NarrativeEventBuilderV2EditorSnapshot snapshot;
  final String eventId;
  final RunEventBuilderV2Simulation onRun;

  @override
  State<EventBuilderV2SimulationSheet> createState() =>
      _EventBuilderV2SimulationSheetState();
}

class _EventBuilderV2SimulationSheetState
    extends State<EventBuilderV2SimulationSheet> {
  late final List<_SimulationSourceChoice> _sources;
  late final Map<String, NarrativeValue> _factValues;
  final Map<String, TextEditingController> _factControllers = {};
  late final Set<String> _consumedEventIds;
  int _sourceIndex = 0;
  bool _running = false;
  String? _error;
  NarrativeEventSimulationReport? _report;

  @override
  void initState() {
    super.initState();
    _sources = _buildSources(widget.snapshot);
    final currentSource = widget.snapshot.record?.when(
      draft: (draft) => draft.source,
      configured: (definition, _) => definition.source,
    );
    final currentIndex = _sources.indexWhere(
      (choice) => choice.source == currentSource,
    );
    if (currentIndex >= 0) _sourceIndex = currentIndex;
    _factValues = {
      for (final entry in widget.snapshot.facts)
        entry.fact.id: entry.fact.initialValue,
    };
    for (final entry in widget.snapshot.facts) {
      final value = entry.fact.initialValue;
      if (value.kind != NarrativeValueKind.boolean) {
        _factControllers[entry.fact.id] = TextEditingController(
          text: value.kind == NarrativeValueKind.integer
              ? '${value.intValue}'
              : value.stringValue,
        );
      }
    }
    _consumedEventIds = <String>{};
  }

  @override
  void dispose() {
    for (final controller in _factControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final report = await widget.onRun(
        NarrativeEventSimulationInput(
          targetEventId: widget.eventId,
          source: _sources.isEmpty ? null : _sources[_sourceIndex].source,
          factValues: {
            for (final entry in _factValues.entries)
              if (entry.value.kind == NarrativeValueKind.boolean)
                entry.key: entry.value.boolValue,
          },
          factNarrativeValues: {
            for (final entry in _factValues.entries)
              if (entry.value.kind != NarrativeValueKind.boolean)
                entry.key: entry.value,
          },
          consumedNarrativeEventIds: _consumedEventIds,
        ),
      );
      if (!mounted) return;
      setState(() => _report = report);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = 'La simulation a échoué : $error');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('event-builder-v2-simulation-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info,
          title: 'Même décision que le jeu',
          message: 'Cette prévisualisation utilise l’autorité de dispatch du '
              'runtime. Les conditions V1 sont combinées avec « toutes » '
              '(AND) ; le mode « au moins une » arrivera dans un lot dédié.',
        ),
        const SizedBox(height: 14),
        if (_sources.isEmpty)
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Aucune source simulable',
            message: 'Rattachez d’abord une source réelle dans Event Builder.',
          )
        else
          PokeMapDropdownField<int>(
            key: const ValueKey('event-builder-v2-simulation-source'),
            label: 'Source reçue par le jeu',
            value: _sourceIndex,
            items: [
              for (var index = 0; index < _sources.length; index++)
                PokeMapDropdownItem(
                  value: index,
                  label: _sources[index].label,
                ),
            ],
            onChanged: (value) => setState(() => _sourceIndex = value),
          ),
        const SizedBox(height: 14),
        const PokeMapSectionHeader(
          title: 'Facts simulés',
          description:
              'Valeurs temporaires, jamais enregistrées dans le projet.',
        ),
        if (widget.snapshot.facts.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucun Fact',
            description: 'Cet Event ne dépend d’aucun Fact connu.',
            icon: Icon(CupertinoIcons.checkmark_alt_circle),
          )
        else
          for (final entry in widget.snapshot.facts) ...[
            _SimulationFactInput(
              key: ValueKey(
                'event-builder-v2-simulation-fact-${entry.fact.id}',
              ),
              fact: entry.fact,
              value: _factValues[entry.fact.id]!,
              controller: _factControllers[entry.fact.id],
              onChanged: (value) => setState(
                () => _factValues[entry.fact.id] = value,
              ),
            ),
            const SizedBox(height: 6),
          ],
        const SizedBox(height: 10),
        const PokeMapSectionHeader(
          title: 'Progression Event simulée',
          description: 'Activez les Events considérés comme déjà consommés.',
        ),
        for (final entry in widget.snapshot.events) ...[
          PokeMapToggleTile(
            key: ValueKey(
              'event-builder-v2-simulation-consumed-${entry.record.id}',
            ),
            label: _eventName(entry.record),
            description: 'Déjà consommé dans cette sauvegarde de test',
            value: _consumedEventIds.contains(entry.record.id),
            onChanged: (value) => setState(() {
              if (value) {
                _consumedEventIds.add(entry.record.id);
              } else {
                _consumedEventIds.remove(entry.record.id);
              }
            }),
          ),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-run-simulation'),
            onPressed: _running ? null : _run,
            isLoading: _running,
            leading: const Icon(CupertinoIcons.play_fill),
            child: const Text('Tester le déclenchement'),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ],
        if (_report case final report?) ...[
          const SizedBox(height: 14),
          _SimulationResult(
            report: report,
            factLabels: {
              for (final entry in widget.snapshot.facts)
                entry.fact.id: entry.fact.label,
            },
            eventLabels: {
              for (final entry in widget.snapshot.events)
                entry.record.id: _eventName(entry.record),
            },
          ),
        ],
      ],
    );
  }
}

class _SimulationFactInput extends StatelessWidget {
  const _SimulationFactInput({
    super.key,
    required this.fact,
    required this.value,
    required this.controller,
    required this.onChanged,
  });

  final NarrativeFactDefinition fact;
  final NarrativeValue value;
  final TextEditingController? controller;
  final ValueChanged<NarrativeValue> onChanged;

  @override
  Widget build(BuildContext context) => switch (fact.valueKind) {
        NarrativeValueKind.boolean => PokeMapToggleTile(
            label: fact.label,
            description: 'Valeur booléenne temporaire',
            value: value.boolValue,
            onChanged: (next) => onChanged(NarrativeValue.boolean(next)),
          ),
        NarrativeValueKind.integer => PokeMapTextField(
            controller: controller,
            label: fact.label,
            hintText: 'Valeur entière temporaire',
            keyboardType: TextInputType.number,
            onChanged: (raw) {
              final parsed = int.tryParse(raw.trim());
              if (parsed == null) return;
              try {
                onChanged(NarrativeValue.integer(parsed));
              } on ArgumentError {
                // Keep the last valid exact JSON integer while editing.
              }
            },
          ),
        NarrativeValueKind.string => PokeMapTextField(
            controller: controller,
            label: fact.label,
            hintText: 'Texte temporaire',
            onChanged: (raw) => onChanged(NarrativeValue.string(raw)),
          ),
      };
}

class _SimulationResult extends StatelessWidget {
  const _SimulationResult({
    required this.report,
    required this.factLabels,
    required this.eventLabels,
  });

  final NarrativeEventSimulationReport report;
  final Map<String, String> factLabels;
  final Map<String, String> eventLabels;

  @override
  Widget build(BuildContext context) {
    final handled = report.status == NarrativeEventSimulationStatus.handled;
    final target = report.targetCandidate;
    return PokeMapPanel(
      key: const ValueKey('event-builder-v2-simulation-result'),
      padding: const EdgeInsets.all(12),
      header: PokeMapSectionHeader(
        title: handled ? 'Déclenchement accepté' : 'Déclenchement refusé',
        description: _decisionLabel(report, eventLabels),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapDiagnosticCallout(
            severity: handled
                ? PokeMapDiagnosticSeverity.info
                : PokeMapDiagnosticSeverity.warning,
            title: handled ? 'Le jeu lance une Scene' : 'Aucune Scene lancée',
            message: _reasonSummary(report, target),
          ),
          if (target != null) ...[
            const SizedBox(height: 10),
            PokeMapCard(
              child: Text(
                'Comportement : ${_reuseLabel(target.reusePolicy)} · '
                'priorité ${target.priority} · ordre ${target.order}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (target.conditions.isNotEmpty) ...[
              const SizedBox(height: 10),
              const PokeMapSectionHeader(
                title: 'Conditions — toutes requises',
                description: 'Chaque ligne vient de l’évaluation canonique.',
              ),
              for (final condition in target.conditions) ...[
                PokeMapCard(
                  key: ValueKey(
                    'event-builder-v2-simulation-condition-${condition.index}',
                  ),
                  child: Row(
                    children: [
                      PokeMapIconTile(
                        icon: condition.passed
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.xmark_circle_fill,
                        tone: condition.passed
                            ? PokeMapTone.success
                            : PokeMapTone.warning,
                        size: 30,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _conditionLabel(condition),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PokeMapBadge(
                        label: condition.passed ? 'Vraie' : 'Fausse',
                        variant: condition.passed
                            ? PokeMapBadgeVariant.success
                            : PokeMapBadgeVariant.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
          ],
          if (report.candidates.length > 1) ...[
            const SizedBox(height: 10),
            const PokeMapSectionHeader(
              title: 'Concurrence sur la source',
              description: 'Priorité décroissante, puis ordre croissant.',
            ),
            for (final candidate in report.candidates)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: PokeMapBadge(
                  label: '${candidate.name} · priorité ${candidate.priority} · '
                      'ordre ${candidate.order}${candidate.selected ? ' · choisi' : ''}',
                  variant: candidate.selected
                      ? PokeMapBadgeVariant.success
                      : PokeMapBadgeVariant.neutral,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _conditionLabel(NarrativeEventSimulationConditionTrace condition) {
    final target = condition.kind == NarrativeEventSimulationConditionKind.fact
        ? factLabels[condition.targetId] ?? condition.targetId
        : eventLabels[condition.targetId] ?? condition.targetId;
    final actual = condition.actualNarrativeValue == null
        ? 'indisponible'
        : _simulationValueLabel(condition.actualNarrativeValue!);
    final expected = _simulationValueLabel(condition.expectedNarrativeValue);
    if (condition.operator == NarrativeFactOperator.equals &&
        condition.expectedNarrativeValue.kind == NarrativeValueKind.boolean) {
      return '$target : $actual, attendu $expected';
    }
    return '$target : $actual, ${_simulationOperatorLabel(condition.operator)} '
        '$expected';
  }
}

String _simulationValueLabel(NarrativeValue value) => switch (value.kind) {
      NarrativeValueKind.boolean => value.boolValue ? 'vrai' : 'faux',
      NarrativeValueKind.integer => '${value.intValue}',
      NarrativeValueKind.string => '“${value.stringValue}”',
    };

String _simulationOperatorLabel(NarrativeFactOperator operator) =>
    switch (operator) {
      NarrativeFactOperator.equals => 'attendu =',
      NarrativeFactOperator.notEquals => 'attendu ≠',
      NarrativeFactOperator.greaterThan => 'attendu >',
      NarrativeFactOperator.greaterThanOrEqual => 'attendu ≥',
      NarrativeFactOperator.lessThan => 'attendu <',
      NarrativeFactOperator.lessThanOrEqual => 'attendu ≤',
    };

List<_SimulationSourceChoice> _buildSources(
  NarrativeEventBuilderV2EditorSnapshot snapshot,
) {
  final result = <_SimulationSourceChoice>[
    for (final option in snapshot.spatialSources)
      if (option.selectable && option.source != null)
        _SimulationSourceChoice(option.source!, option.humanLabel),
    for (final option in snapshot.outcomeSources)
      if (option.selectable && option.outcome != null)
        _SimulationSourceChoice(
          NarrativeEventSourceRef.outcomeReceived(option.outcome!),
          option.humanSourceSentence,
        ),
  ];
  final unique = <NarrativeEventSourceRef, _SimulationSourceChoice>{};
  for (final choice in result) {
    unique.putIfAbsent(choice.source, () => choice);
  }
  return List.unmodifiable(unique.values);
}

final class _SimulationSourceChoice {
  const _SimulationSourceChoice(this.source, this.label);

  final NarrativeEventSourceRef source;
  final String label;
}

String _eventName(NarrativeEventRecord record) => record.when(
      draft: (draft) => draft.name,
      configured: (definition, _) => definition.name,
    );

String _decisionLabel(
  NarrativeEventSimulationReport report,
  Map<String, String> eventLabels,
) {
  final handledId = report.handledEventId;
  if (handledId != null) {
    return '${eventLabels[handledId] ?? handledId} gagne l’évaluation.';
  }
  return switch (report.status) {
    NarrativeEventSimulationStatus.sourceMissing =>
      'La source de test est absente.',
    NarrativeEventSimulationStatus.authorityBlocked =>
      'Le projet bloque la préparation du dispatch.',
    NarrativeEventSimulationStatus.claimedButIneligible =>
      'La source historique est revendiquée mais aucun Event n’est éligible.',
    NarrativeEventSimulationStatus.noMatch =>
      'Aucun Event éligible pour cette source.',
    NarrativeEventSimulationStatus.handled => 'Un Event est sélectionné.',
  };
}

String _reasonSummary(
  NarrativeEventSimulationReport report,
  NarrativeEventSimulationCandidateTrace? target,
) {
  final reasons =
      target?.reasons.isNotEmpty == true ? target!.reasons : report.reasons;
  if (reasons.isEmpty) return 'Toutes les conditions requises sont vraies.';
  return reasons.map(_reasonLabel).join(' · ');
}

String _reasonLabel(NarrativeEventSimulationReason reason) => switch (reason) {
      NarrativeEventSimulationReason.sourceMissing => 'Source absente',
      NarrativeEventSimulationReason.eventMissing => 'Event absent',
      NarrativeEventSimulationReason.authorityBlocked =>
        'Autorité de dispatch bloquée',
      NarrativeEventSimulationReason.draft => 'Brouillon non exécutable',
      NarrativeEventSimulationReason.disabled => 'Event inactif',
      NarrativeEventSimulationReason.sourceMismatch =>
        'Source différente de la simulation',
      NarrativeEventSimulationReason.factConditionFalse =>
        'Au moins un Fact est faux',
      NarrativeEventSimulationReason.narrativeEventConsumedConditionFalse =>
        'Une condition de progression est fausse',
      NarrativeEventSimulationReason.eventConsumed =>
        'Event one-shot déjà consommé',
      NarrativeEventSimulationReason.eventInFlight => 'Event déjà en cours',
      NarrativeEventSimulationReason.claimTombstone =>
        'Source historique neutralisée',
      NarrativeEventSimulationReason.claimTargetsIneligible =>
        'Cibles historiques inéligibles',
      NarrativeEventSimulationReason.noEligibleCandidate =>
        'Aucun candidat éligible',
      NarrativeEventSimulationReason.runtimeReferenceUnavailable =>
        'Référence runtime indisponible',
    };

String _reuseLabel(NarrativeEventReusePolicy? policy) => switch (policy) {
      NarrativeEventReusePolicy.oneShot =>
        'une seule fois (reste consommé après succès)',
      NarrativeEventReusePolicy.reusable =>
        'réutilisable à chaque occurrence éligible',
      null => 'à définir',
    };
