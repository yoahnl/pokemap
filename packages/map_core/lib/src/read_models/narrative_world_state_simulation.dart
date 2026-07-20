import '../diagnostics/world_rule_diagnostics.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';
import '../projection/world_rule_projection.dart';

/// Serializable, immutable input used to reproduce a world-state preview.
final class NarrativeWorldStateSimulationInput {
  NarrativeWorldStateSimulationInput({
    required this.gameState,
    List<NarrativeOutcomeRef> hypotheticalOutcomes =
        const <NarrativeOutcomeRef>[],
  }) : hypotheticalOutcomes = List.unmodifiable(hypotheticalOutcomes);

  factory NarrativeWorldStateSimulationInput.fromJson(
    Map<String, dynamic> json,
  ) {
    final gameState = json['gameState'];
    final outcomes = json['hypotheticalOutcomes'];
    if (gameState is! Map) {
      throw const FormatException('Simulation input requires gameState.');
    }
    if (outcomes is! List) {
      throw const FormatException(
        'Simulation input requires hypotheticalOutcomes.',
      );
    }
    return NarrativeWorldStateSimulationInput(
      gameState: GameState.fromJson(Map<String, dynamic>.from(gameState)),
      hypotheticalOutcomes: [
        for (final outcome in outcomes) NarrativeOutcomeRef.fromJson(outcome),
      ],
    );
  }

  final GameState gameState;
  final List<NarrativeOutcomeRef> hypotheticalOutcomes;

  Map<String, dynamic> toJson() => {
        'gameState': gameState.toJson(),
        'hypotheticalOutcomes': [
          for (final outcome in hypotheticalOutcomes) outcome.toJson(),
        ],
      };

  NarrativeWorldStateSimulationInput copyWith({
    GameState? gameState,
    List<NarrativeOutcomeRef>? hypotheticalOutcomes,
  }) =>
      NarrativeWorldStateSimulationInput(
        gameState: gameState ?? this.gameState,
        hypotheticalOutcomes: hypotheticalOutcomes ?? this.hypotheticalOutcomes,
      );

  NarrativeWorldStateSimulationInput withStepCompletion(
    String stepId, {
    required bool completed,
  }) {
    final normalized = stepId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(stepId, 'stepId', 'must not be empty');
    }
    final completedIds = gameState.progression.completedStepIds.toSet();
    if (completed) {
      completedIds.add(normalized);
    } else {
      completedIds.remove(normalized);
    }
    final ordered = completedIds.toList()..sort();
    return copyWith(
      gameState: gameState.copyWith(
        progression: gameState.progression.copyWith(
          completedStepIds: ordered,
        ),
      ),
    );
  }

  NarrativeWorldStateSimulationInput withOutcome(NarrativeOutcomeRef outcome) {
    return copyWith(
      hypotheticalOutcomes: [...hypotheticalOutcomes, outcome],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeWorldStateSimulationInput &&
          other.gameState == gameState &&
          _listEquals(other.hypotheticalOutcomes, hypotheticalOutcomes);

  @override
  int get hashCode => Object.hash(
        gameState,
        Object.hashAll(hypotheticalOutcomes),
      );
}

final class NarrativeWorldRuleSimulationTrace {
  const NarrativeWorldRuleSimulationTrace({
    required this.ruleId,
    required this.label,
    required this.priority,
    required this.targetKey,
    required this.effectKind,
    required this.applicable,
    required this.winner,
    required this.explanation,
  });

  final String ruleId;
  final String label;
  final int priority;
  final String targetKey;
  final WorldRuleEffectKind effectKind;
  final bool applicable;
  final bool winner;
  final String explanation;
}

final class NarrativeWorldEntitySimulationState {
  NarrativeWorldEntitySimulationState({
    required this.mapId,
    required this.entityId,
    required this.label,
    required this.visible,
    required this.dialogueId,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String mapId;
  final String entityId;
  final String label;
  final bool visible;
  final String? dialogueId;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldMapEventSimulationState {
  NarrativeWorldMapEventSimulationState({
    required this.mapId,
    required this.eventId,
    required this.label,
    required this.active,
    required this.hidden,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String mapId;
  final String eventId;
  final String label;
  final bool active;
  final bool hidden;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldEventV2SimulationState {
  NarrativeWorldEventV2SimulationState({
    required this.eventId,
    required this.label,
    required this.mapId,
    required this.configured,
    required this.active,
    required this.hidden,
    required List<String> contributorRuleIds,
  }) : contributorRuleIds = List.unmodifiable(contributorRuleIds);

  final String eventId;
  final String label;
  final String? mapId;
  final bool configured;
  final bool active;
  final bool hidden;
  final List<String> contributorRuleIds;
}

final class NarrativeWorldStateSimulationReport {
  NarrativeWorldStateSimulationReport({
    required this.input,
    required List<NarrativeWorldRuleSimulationTrace> rules,
    required List<NarrativeWorldEntitySimulationState> entityStates,
    required List<NarrativeWorldMapEventSimulationState> mapEventStates,
    required List<NarrativeWorldEventV2SimulationState> narrativeEventStates,
    required List<WorldRuleDiagnostic> diagnostics,
  })  : rules = List.unmodifiable(rules),
        entityStates = List.unmodifiable(entityStates),
        mapEventStates = List.unmodifiable(mapEventStates),
        narrativeEventStates = List.unmodifiable(narrativeEventStates),
        diagnostics = List.unmodifiable(diagnostics);

  final NarrativeWorldStateSimulationInput input;
  final List<NarrativeWorldRuleSimulationTrace> rules;
  final List<NarrativeWorldEntitySimulationState> entityStates;
  final List<NarrativeWorldMapEventSimulationState> mapEventStates;
  final List<NarrativeWorldEventV2SimulationState> narrativeEventStates;
  final List<WorldRuleDiagnostic> diagnostics;

  List<NarrativeWorldRuleSimulationTrace> get applicableRules =>
      List.unmodifiable(rules.where((rule) => rule.applicable));

  List<NarrativeWorldRuleSimulationTrace> get winnerRules =>
      List.unmodifiable(rules.where((rule) => rule.winner));
}

NarrativeWorldStateSimulationReport simulateNarrativeWorldState({
  required ProjectManifest project,
  required List<MapData> maps,
  required NarrativeWorldStateSimulationInput input,
}) {
  final diagnostics = diagnoseWorldRules(project, maps: maps).diagnostics;
  final diagnosticsByRuleId = <String, List<WorldRuleDiagnostic>>{};
  for (final diagnostic in diagnostics) {
    diagnosticsByRuleId
        .putIfAbsent(diagnostic.ruleId, () => <WorldRuleDiagnostic>[])
        .add(diagnostic);
  }
  final effects = projectWorldRuleEffects(
    project,
    input.gameState,
    maps: maps,
  );
  final effectsByTarget = <String, List<WorldRuleResolvedEffect>>{};
  for (final effect in effects) {
    effectsByTarget
        .putIfAbsent(
            _targetKey(effect.target), () => <WorldRuleResolvedEffect>[])
        .add(effect);
  }
  final winnerRuleIds = <String>{
    for (final effects in effectsByTarget.values)
      if (effects.isNotEmpty) effects.last.ruleId,
  };
  final applicableRuleIds = effects.map((effect) => effect.ruleId).toSet();
  final orderedRules = project.worldRules.toList()
    ..sort((left, right) {
      final priority = left.priority.compareTo(right.priority);
      return priority != 0 ? priority : left.id.compareTo(right.id);
    });
  final traces = <NarrativeWorldRuleSimulationTrace>[
    for (final rule in orderedRules)
      NarrativeWorldRuleSimulationTrace(
        ruleId: rule.id,
        label: rule.label,
        priority: rule.priority,
        targetKey: _targetKey(rule.target),
        effectKind: rule.effect.kind,
        applicable: applicableRuleIds.contains(rule.id),
        winner: winnerRuleIds.contains(rule.id),
        explanation: _ruleExplanation(
          rule,
          applicable: applicableRuleIds.contains(rule.id),
          winner: winnerRuleIds.contains(rule.id),
          diagnostics: diagnosticsByRuleId[rule.id] ?? const [],
        ),
      ),
  ];

  final entityStates = <NarrativeWorldEntitySimulationState>[];
  final mapEventStates = <NarrativeWorldMapEventSimulationState>[];
  for (final map in maps) {
    for (final entity in map.entities) {
      final entityEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: map.id,
              entityId: entity.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final dialogueEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.npcDialogue,
              mapId: map.id,
              entityId: entity.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final entityWinner = entityEffects.lastOrNull;
      final dialogueWinner = dialogueEffects.lastOrNull;
      final visible = switch (entityWinner?.effect.kind) {
        WorldRuleEffectKind.entityHidden => false,
        WorldRuleEffectKind.entityVisible => true,
        _ => true,
      };
      final dialogueId =
          dialogueWinner?.effect.dialogueId ?? entity.npc?.dialogue?.dialogueId;
      entityStates.add(
        NarrativeWorldEntitySimulationState(
          mapId: map.id,
          entityId: entity.id,
          label: entity.name.trim().isEmpty ? entity.id : entity.name,
          visible: visible,
          dialogueId: dialogueId,
          contributorRuleIds: {
            for (final effect in entityEffects) effect.ruleId,
            for (final effect in dialogueEffects) effect.ruleId,
          }.toList()
            ..sort(),
        ),
      );
    }
    for (final event in map.events) {
      final eventEffects = effectsByTarget[_targetKey(
            WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEvent,
              mapId: map.id,
              eventId: event.id,
            ),
          )] ??
          const <WorldRuleResolvedEffect>[];
      final state = _eventState(
        enabled: true,
        effect: eventEffects.lastOrNull?.effect.kind,
      );
      mapEventStates.add(
        NarrativeWorldMapEventSimulationState(
          mapId: map.id,
          eventId: event.id,
          label: event.title.trim().isEmpty ? event.id : event.title,
          active: state.active,
          hidden: state.hidden,
          contributorRuleIds: [
            for (final effect in eventEffects) effect.ruleId,
          ],
        ),
      );
    }
  }

  final narrativeEventStates = <NarrativeWorldEventV2SimulationState>[];
  for (final record
      in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    final eventEffects = effectsByTarget[_targetKey(
          WorldRuleTarget(
            kind: WorldRuleTargetKind.narrativeEvent,
            mapId: '',
            eventId: record.id,
          ),
        )] ??
        const <WorldRuleResolvedEffect>[];
    record.when(
      draft: (draft) {
        narrativeEventStates.add(
          NarrativeWorldEventV2SimulationState(
            eventId: draft.id,
            label: draft.name,
            mapId: _sourceMapId(draft.source),
            configured: false,
            active: false,
            hidden: false,
            contributorRuleIds: const [],
          ),
        );
      },
      configured: (definition, enabled) {
        final state = _eventState(
          enabled: enabled,
          effect: eventEffects.lastOrNull?.effect.kind,
        );
        narrativeEventStates.add(
          NarrativeWorldEventV2SimulationState(
            eventId: definition.id,
            label: definition.name,
            mapId: _sourceMapId(definition.source),
            configured: true,
            active: state.active,
            hidden: state.hidden,
            contributorRuleIds: [
              for (final effect in eventEffects) effect.ruleId,
            ],
          ),
        );
      },
    );
  }

  return NarrativeWorldStateSimulationReport(
    input: input,
    rules: traces,
    entityStates: entityStates,
    mapEventStates: mapEventStates,
    narrativeEventStates: narrativeEventStates,
    diagnostics: diagnostics,
  );
}

String _ruleExplanation(
  WorldRuleDefinition rule, {
  required bool applicable,
  required bool winner,
  required List<WorldRuleDiagnostic> diagnostics,
}) {
  if (!rule.enabled) return 'Règle désactivée.';
  final blocking = diagnostics.where(
    (diagnostic) => diagnostic.severity == WorldRuleDiagnosticSeverity.error,
  );
  if (blocking.isNotEmpty) return blocking.first.message;
  if (!applicable) return 'La source ne correspond pas au snapshot.';
  if (!winner) return 'Applicable, remplacée par une priorité supérieure.';
  return 'Applicable et gagnante pour cette cible.';
}

String _targetKey(WorldRuleTarget target) => switch (target.kind) {
      WorldRuleTargetKind.mapEntity =>
        '${target.mapId}:entity:${target.entityId ?? ''}',
      WorldRuleTargetKind.npcDialogue =>
        '${target.mapId}:npcDialogue:${target.entityId ?? ''}',
      WorldRuleTargetKind.mapEvent =>
        '${target.mapId}:mapEvent:${target.eventId ?? ''}',
      WorldRuleTargetKind.narrativeEvent =>
        'narrativeEvent:${target.eventId ?? ''}',
    };

({bool active, bool hidden}) _eventState({
  required bool enabled,
  required WorldRuleEffectKind? effect,
}) =>
    switch (effect) {
      WorldRuleEffectKind.eventEnabled => (active: true, hidden: false),
      WorldRuleEffectKind.eventDisabled => (active: false, hidden: false),
      WorldRuleEffectKind.eventHidden => (active: false, hidden: true),
      _ => (active: enabled, hidden: false),
    };

String? _sourceMapId(NarrativeEventSourceRef? source) => source?.when(
      entityInteract: (mapId, _) => mapId,
      triggerEnter: (mapId, _) => mapId,
      mapEnter: (mapId) => mapId,
      outcomeReceived: (_) => null,
    );

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
