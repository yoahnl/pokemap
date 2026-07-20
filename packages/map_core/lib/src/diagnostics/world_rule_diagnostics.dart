import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_fact_runtime_state.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';
import '../operations/narrative_fact_runtime.dart';

enum WorldRuleDiagnosticSeverity {
  error,
  warning,
  info,
}

enum WorldRuleDiagnosticCode {
  worldRuleSourceMissing,
  worldRuleSourceUnknown,
  worldRuleSourceUnsupported,
  worldRuleTargetMissing,
  worldRuleTargetUnknown,
  worldRuleEffectMissing,
  worldRuleEffectUnsupported,
  worldRuleEffectTargetMismatch,
  worldRuleConflict,
  worldRuleSourceNeverProduced,
  worldRuleBlockingEntityNeverReleased,
  worldRuleUsesRawTechnicalId,
  worldRuleLegacyPredicateLeak,
  worldRuleFactRuntimeCollision,
  worldRuleFactTypeMismatch,
}

final class WorldRuleDiagnostic {
  const WorldRuleDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.ruleId,
    this.sourceId,
    this.targetId,
    this.mapId,
    this.suggestedFixLabel,
  });

  final WorldRuleDiagnosticCode code;
  final WorldRuleDiagnosticSeverity severity;
  final String message;
  final String ruleId;
  final String? sourceId;
  final String? targetId;
  final String? mapId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.ruleId == ruleId &&
          other.sourceId == sourceId &&
          other.targetId == targetId &&
          other.mapId == mapId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        ruleId,
        sourceId,
        targetId,
        mapId,
        suggestedFixLabel,
      );
}

final class WorldRuleDiagnosticsReport {
  WorldRuleDiagnosticsReport({
    required List<WorldRuleDiagnostic> diagnostics,
  }) : _diagnostics = List<WorldRuleDiagnostic>.unmodifiable(diagnostics);

  final List<WorldRuleDiagnostic> _diagnostics;

  List<WorldRuleDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<WorldRuleDiagnostic> byCode(WorldRuleDiagnosticCode code) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }

  List<WorldRuleDiagnostic> byRuleId(String ruleId) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.ruleId == ruleId),
    );
  }
}

WorldRuleDiagnosticsReport diagnoseWorldRules(
  ProjectManifest project, {
  List<MapData> maps = const <MapData>[],
}) {
  final diagnostics = <WorldRuleDiagnostic>[];
  final mapsById = {for (final map in maps) map.id: map};
  final projectMapIds = project.maps.map((map) => map.id).toSet();
  final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  final dialogueIds = project.dialogues.map((dialogue) => dialogue.id).toSet();
  final storyStepIds = _storyStepIds(project);
  final consumedEventIds = _eventIds(project, maps);
  final producibleFactValues = _producibleFactValues(project);
  final producibleStoryStepIds = _producibleStoryStepIds(project);

  for (final rule in project.worldRules) {
    _diagnoseSource(
      rule,
      diagnostics,
      factResolver: factResolver,
      storyStepIds: storyStepIds,
      consumedEventIds: consumedEventIds,
    );
    _diagnoseSourceProducibility(
      rule,
      diagnostics,
      factResolver: factResolver,
      producibleFactValues: producibleFactValues,
      producibleStoryStepIds: producibleStoryStepIds,
    );
    _diagnoseTarget(
      rule,
      diagnostics,
      narrativeEventIds: {
        for (final record
            in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
          record.id,
      },
      projectMapIds: projectMapIds,
      mapsById: mapsById,
    );
    _diagnoseEffect(
      rule,
      diagnostics,
      dialogueIds: dialogueIds,
    );
    _diagnoseLabels(rule, diagnostics);
  }
  _diagnoseConflicts(project.worldRules, diagnostics);
  _diagnoseBlockingEntityRelease(
    project.worldRules,
    mapsById: mapsById,
    diagnostics: diagnostics,
  );
  return WorldRuleDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseSource(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required NarrativeFactRuntimeResolver factResolver,
  required Set<String> storyStepIds,
  required Set<String> consumedEventIds,
}) {
  if (rule.source.sourceId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une source métier.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir un Fact, une étape ou un event consommé.',
      ),
    );
    return;
  }
  if (!isWorldRuleSourcePredicateCompatible(
    rule.source.kind,
    rule.source.predicate,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceUnsupported,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'Le prédicat de source n’est pas supporté par ce type.',
        ruleId: rule.id,
        sourceId: rule.source.sourceId,
        suggestedFixLabel: 'Choisir un prédicat compatible avec la source.',
      ),
    );
  }

  switch (rule.source.kind) {
    case WorldRuleSourceKind.fact:
      final resolution = factResolver.resolve(
        factId: rule.source.sourceId,
        runtimeState: const NarrativeFactRuntimeState.empty(),
        storyFlags: const StoryFlags(),
      );
      switch (resolution) {
        case NarrativeFactRuntimeResolved(:final fact):
          if (rule.source.expectedFactValue != null &&
              fact.valueKind != rule.source.expectedFactValue!.kind) {
            diagnostics.add(
              WorldRuleDiagnostic(
                code: WorldRuleDiagnosticCode.worldRuleFactTypeMismatch,
                severity: WorldRuleDiagnosticSeverity.error,
                message:
                    'La valeur comparée ne correspond pas au type du Fact.',
                ruleId: rule.id,
                sourceId: rule.source.sourceId,
                suggestedFixLabel: 'Choisir une valeur du même type.',
              ),
            );
          }
        case NarrativeFactRuntimeUnknownFact():
          diagnostics.add(
            WorldRuleDiagnostic(
              code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
              severity: WorldRuleDiagnosticSeverity.error,
              message: 'La World Rule référence un Fact absent du projet.',
              ruleId: rule.id,
              sourceId: rule.source.sourceId,
              suggestedFixLabel: 'Choisir un Fact existant.',
            ),
          );
        case NarrativeFactRuntimeAmbiguousFact() ||
              NarrativeFactRuntimeInvalidRuntimeKey():
          diagnostics.add(
            WorldRuleDiagnostic(
              code: WorldRuleDiagnosticCode.worldRuleFactRuntimeCollision,
              severity: WorldRuleDiagnosticSeverity.error,
              message: 'Le catalogue Fact possède des clés runtime ambiguës.',
              ruleId: rule.id,
              sourceId: rule.source.sourceId,
              suggestedFixLabel: 'Corriger les IDs et aliases des Facts.',
            ),
          );
      }
    case WorldRuleSourceKind.storyStepCompletion:
      if (storyStepIds.isNotEmpty &&
          !storyStepIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence une étape narrative inconnue.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir une étape existante.',
          ),
        );
      }
    case WorldRuleSourceKind.consumedEvent:
      if (consumedEventIds.isNotEmpty &&
          !consumedEventIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence un event consommé inconnu.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir un event existant.',
          ),
        );
      }
  }
}

void _diagnoseTarget(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> projectMapIds,
  required Map<String, MapData> mapsById,
  required Set<String> narrativeEventIds,
}) {
  if (rule.target.kind == WorldRuleTargetKind.narrativeEvent) {
    final eventId = rule.target.eventId?.trim() ?? '';
    if (eventId.isEmpty) {
      diagnostics.add(_missingTarget(rule, 'Narrative Event V2 cible'));
    } else if (!narrativeEventIds.contains(eventId)) {
      diagnostics.add(_unknownTarget(rule, eventId, 'Narrative Event V2'));
    }
    return;
  }
  if (rule.target.mapId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une map cible.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir une map cible.',
      ),
    );
    return;
  }
  if (!projectMapIds.contains(rule.target.mapId) &&
      !mapsById.containsKey(rule.target.mapId)) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule cible une map inconnue.',
        ruleId: rule.id,
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir une map du projet.',
      ),
    );
    return;
  }
  final map = mapsById[rule.target.mapId];
  if (map == null) {
    return;
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.mapEntity:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'entité cible'));
        return;
      }
      if (!map.entities.any((entity) => entity.id == entityId)) {
        diagnostics.add(_unknownTarget(rule, entityId, 'entité'));
      }
    case WorldRuleTargetKind.npcDialogue:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'PNJ cible'));
        return;
      }
      final entity = _findEntity(map, entityId);
      if (entity == null) {
        diagnostics.add(_unknownTarget(rule, entityId, 'PNJ'));
      } else if (entity.kind != MapEntityKind.npc) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule de dialogue cible une entité non PNJ.',
            ruleId: rule.id,
            targetId: entityId,
            mapId: rule.target.mapId,
            suggestedFixLabel: 'Choisir un PNJ.',
          ),
        );
      }
    case WorldRuleTargetKind.mapEvent:
      final eventId = rule.target.eventId?.trim() ?? '';
      if (eventId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'event cible'));
        return;
      }
      if (!map.events.any((event) => event.id == eventId)) {
        diagnostics.add(_unknownTarget(rule, eventId, 'event'));
      }
    case WorldRuleTargetKind.narrativeEvent:
      throw StateError('Narrative Event targets are diagnosed project-wide.');
  }
}

void _diagnoseEffect(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> dialogueIds,
}) {
  if (!isWorldRuleEffectCompatibleWithTarget(
    rule.target.kind,
    rule.effect.kind,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'L’effet de la World Rule ne correspond pas à sa cible.',
        ruleId: rule.id,
        targetId: _targetIdentity(rule.target),
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir un effet compatible avec la cible.',
      ),
    );
  }
  if (rule.effect.kind == WorldRuleEffectKind.npcDialogueOverride) {
    final dialogueId = rule.effect.dialogueId?.trim() ?? '';
    if (dialogueId.isEmpty) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectMissing,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet de dialogue doit choisir un dialogue.',
          ruleId: rule.id,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    } else if (!dialogueIds.contains(dialogueId)) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectUnsupported,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet référence un dialogue absent du projet.',
          ruleId: rule.id,
          targetId: dialogueId,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    }
  }
}

void _diagnoseLabels(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics,
) {
  if (rule.label.trim() == rule.id ||
      (rule.label.contains('_') && !rule.label.contains(' '))) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule affiche encore un identifiant technique.',
        ruleId: rule.id,
        suggestedFixLabel: 'Donner un label lisible à la règle.',
      ),
    );
  }
  final debug = [
    rule.debugTechnicalLabel,
    rule.source.debugTechnicalLabel,
  ].whereType<String>().join(' ').toLowerCase();
  if (debug.contains('scriptcondition') ||
      debug.contains('script_condition') ||
      debug.contains('predicate')) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule expose encore un prédicat legacy.',
        ruleId: rule.id,
        suggestedFixLabel: 'Remplacer par une source métier lisible.',
      ),
    );
  }
}

void _diagnoseConflicts(
  List<WorldRuleDefinition> rules,
  List<WorldRuleDiagnostic> diagnostics,
) {
  final alreadyInvalidRuleIds = <String>{
    for (final diagnostic in diagnostics)
      if (diagnostic.severity == WorldRuleDiagnosticSeverity.error)
        diagnostic.ruleId,
  };
  final enabled = rules
      .where(
        (rule) => rule.enabled && !alreadyInvalidRuleIds.contains(rule.id),
      )
      .toList(growable: false);
  final emitted = <String>{};
  for (var leftIndex = 0; leftIndex < enabled.length; leftIndex++) {
    final left = enabled[leftIndex];
    for (var rightIndex = leftIndex + 1;
        rightIndex < enabled.length;
        rightIndex++) {
      final right = enabled[rightIndex];
      if (left.priority != right.priority ||
          _targetIdentity(left.target) != _targetIdentity(right.target) ||
          _sourcesMutuallyExclusive(left.source, right.source)) {
        continue;
      }
      final sameEffect = _sameResolvedEffect(left.effect, right.effect);
      if (sameEffect) {
        final diagnosticKey = 'duplicate:${right.id}';
        if (emitted.add(diagnosticKey)) {
          diagnostics.add(
            _conflictDiagnostic(
              right,
              severity: WorldRuleDiagnosticSeverity.warning,
              message:
                  'Plusieurs World Rules actives produisent le même effet avec la même priorité.',
            ),
          );
        }
        continue;
      }
      for (final rule in <WorldRuleDefinition>[left, right]) {
        final diagnosticKey = 'opposed:${rule.id}';
        if (!emitted.add(diagnosticKey)) {
          continue;
        }
        diagnostics.add(
          _conflictDiagnostic(
            rule,
            severity: WorldRuleDiagnosticSeverity.error,
            message:
                'Des World Rules compatibles peuvent produire des états opposés sur la même cible et avec la même priorité.',
          ),
        );
      }
    }
  }
}

WorldRuleDiagnostic _conflictDiagnostic(
  WorldRuleDefinition rule, {
  required WorldRuleDiagnosticSeverity severity,
  required String message,
}) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleConflict,
    severity: severity,
    message: message,
    ruleId: rule.id,
    targetId: _targetIdentity(rule.target),
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Changer la priorité ou rendre les sources exclusives.',
  );
}

bool _sameResolvedEffect(WorldRuleEffect left, WorldRuleEffect right) {
  return left.kind == right.kind && left.dialogueId == right.dialogueId;
}

bool _sourcesMutuallyExclusive(WorldRuleSource left, WorldRuleSource right) {
  if (left.kind != right.kind || left.sourceId != right.sourceId) {
    return false;
  }
  return switch ((left.predicate, right.predicate)) {
    (WorldRuleSourcePredicate.isTrue, WorldRuleSourcePredicate.isFalse) ||
    (WorldRuleSourcePredicate.isFalse, WorldRuleSourcePredicate.isTrue) ||
    (
      WorldRuleSourcePredicate.completed,
      WorldRuleSourcePredicate.notCompleted
    ) ||
    (
      WorldRuleSourcePredicate.notCompleted,
      WorldRuleSourcePredicate.completed
    ) ||
    (WorldRuleSourcePredicate.consumed, WorldRuleSourcePredicate.notConsumed) ||
    (WorldRuleSourcePredicate.notConsumed, WorldRuleSourcePredicate.consumed) =>
      true,
    _ => false,
  };
}

void _diagnoseSourceProducibility(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required NarrativeFactRuntimeResolver factResolver,
  required Map<String, Set<NarrativeValue>> producibleFactValues,
  required Set<String> producibleStoryStepIds,
}) {
  if (rule.source.kind == WorldRuleSourceKind.storyStepCompletion) {
    if (rule.source.predicate != WorldRuleSourcePredicate.completed ||
        producibleStoryStepIds.contains(rule.source.sourceId)) {
      return;
    }
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
        severity: WorldRuleDiagnosticSeverity.warning,
        message:
            'Aucune Scene ni liaison narrative ne peut terminer l’étape attendue par cette World Rule.',
        ruleId: rule.id,
        sourceId: rule.source.sourceId,
        suggestedFixLabel:
            'Lier une Scene à cette étape ou ajouter une conséquence completeStoryStep.',
      ),
    );
    return;
  }
  if (rule.source.kind != WorldRuleSourceKind.fact ||
      (rule.source.predicate != WorldRuleSourcePredicate.isTrue &&
          rule.source.predicate != WorldRuleSourcePredicate.isFalse)) {
    return;
  }
  final resolution = factResolver.resolve(
    factId: rule.source.sourceId,
    runtimeState: const NarrativeFactRuntimeState.empty(),
    storyFlags: const StoryFlags(),
  );
  if (resolution is! NarrativeFactRuntimeResolved) {
    return;
  }
  final expected = rule.source.resolvedExpectedFactValue;
  final operator = rule.source.resolvedFactOperator;
  final producible = producibleFactValues[rule.source.sourceId] ?? const {};
  if (producible.any(
    (value) => value.kind == expected.kind && value.matches(operator, expected),
  )) {
    return;
  }
  diagnostics.add(
    WorldRuleDiagnostic(
      code: WorldRuleDiagnosticCode.worldRuleSourceNeverProduced,
      severity: WorldRuleDiagnosticSeverity.warning,
      message:
          'Aucun état initial ni aucune Scene ne peut produire la valeur de Fact attendue par cette World Rule.',
      ruleId: rule.id,
      sourceId: rule.source.sourceId,
      suggestedFixLabel:
          'Initialiser ce Fact ou ajouter une conséquence Scene qui produit cette valeur.',
    ),
  );
}

Map<String, Set<NarrativeValue>> _producibleFactValues(
  ProjectManifest project,
) {
  final values = <String, Set<NarrativeValue>>{
    for (final fact in project.facts)
      fact.id: <NarrativeValue>{fact.initialValue},
  };
  for (final entry in project.newGame.resolvedInitialFactValues.entries) {
    values.putIfAbsent(entry.key, () => <NarrativeValue>{}).add(entry.value);
  }
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneActionPayload) {
        continue;
      }
      final consequence = payload.consequence;
      if (consequence is SceneSetFactConsequence) {
        values
            .putIfAbsent(consequence.factId, () => <NarrativeValue>{})
            .add(consequence.narrativeValue);
      }
    }
  }
  for (final scenario in project.scenarios) {
    for (final node in scenario.nodes) {
      final producedValue = switch (node.payload.actionKind?.trim()) {
        'setFlag' => true,
        'clearFlag' => false,
        _ => null,
      };
      final flagName = node.binding.flagName?.trim() ?? '';
      if (producedValue == null || flagName.isEmpty) {
        continue;
      }
      for (final fact in project.facts) {
        if (fact.id == flagName || fact.legacyFlagName == flagName) {
          values
              .putIfAbsent(fact.id, () => <NarrativeValue>{})
              .add(NarrativeValue.boolean(producedValue));
        }
      }
    }
  }
  for (final storyline in project.storylines) {
    for (final link in storyline.sceneLinks) {
      for (final outcome in link.outcomeLinks) {
        for (final effect in outcome.effects) {
          if (effect.type != StorylineEffectType.emitFact) {
            continue;
          }
          final produced = effect.resolvedFactValue;
          if (produced != null) {
            values
                .putIfAbsent(effect.targetId, () => <NarrativeValue>{})
                .add(produced);
          }
        }
      }
    }
  }
  return values;
}

void _diagnoseBlockingEntityRelease(
  List<WorldRuleDefinition> rules, {
  required Map<String, MapData> mapsById,
  required List<WorldRuleDiagnostic> diagnostics,
}) {
  final neverProducedRuleIds = <String>{
    for (final diagnostic in diagnostics)
      if (diagnostic.code ==
          WorldRuleDiagnosticCode.worldRuleSourceNeverProduced)
        diagnostic.ruleId,
  };
  for (final rule in rules) {
    if (!rule.enabled ||
        !neverProducedRuleIds.contains(rule.id) ||
        rule.target.kind != WorldRuleTargetKind.mapEntity ||
        rule.effect.kind != WorldRuleEffectKind.entityHidden) {
      continue;
    }
    final map = mapsById[rule.target.mapId];
    if (map == null) {
      continue;
    }
    final entity = _findEntity(map, rule.target.entityId ?? '');
    if (entity == null || !entity.blocksMovement) {
      continue;
    }
    final hasAnotherReleaseRule = rules.any(
      (candidate) =>
          candidate.enabled &&
          candidate.id != rule.id &&
          !neverProducedRuleIds.contains(candidate.id) &&
          candidate.target.kind == WorldRuleTargetKind.mapEntity &&
          _targetIdentity(candidate.target) == _targetIdentity(rule.target) &&
          candidate.effect.kind == WorldRuleEffectKind.entityHidden,
    );
    if (hasAnotherReleaseRule) {
      continue;
    }
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleBlockingEntityNeverReleased,
        severity: WorldRuleDiagnosticSeverity.warning,
        message:
            'Cette entité bloquante ne possède aucune règle atteignable qui puisse la retirer du parcours.',
        ruleId: rule.id,
        sourceId: rule.source.sourceId,
        targetId: entity.id,
        mapId: rule.target.mapId,
        suggestedFixLabel:
            'Rendre la source atteignable ou ajouter une autre règle de déverrouillage.',
      ),
    );
  }
}

Set<String> _producibleStoryStepIds(ProjectManifest project) {
  final result = <String>{};
  for (final scenario in project.scenarios) {
    for (final node in scenario.nodes) {
      if (node.payload.actionKind?.trim() != 'completeStep') {
        continue;
      }
      final stepId = node.payload.params['stepId']?.trim() ?? '';
      if (stepId.isNotEmpty) {
        result.add(stepId);
      }
    }
  }
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneActionPayload) {
        continue;
      }
      final consequence = payload.consequence;
      if (consequence is SceneCompleteStoryStepConsequence) {
        result.add(consequence.stepId);
      }
    }
  }
  for (final storyline in project.storylines) {
    for (final link in storyline.sceneLinks) {
      for (final outcome in link.outcomeLinks) {
        for (final effect in outcome.effects) {
          if (effect.type == StorylineEffectType.completeStep) {
            result.add(effect.targetId);
          }
        }
      }
    }
  }
  return result;
}

WorldRuleDiagnostic _missingTarget(WorldRuleDefinition rule, String label) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule doit choisir une $label.',
    ruleId: rule.id,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

WorldRuleDiagnostic _unknownTarget(
  WorldRuleDefinition rule,
  String targetId,
  String label,
) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule cible un(e) $label inconnu(e).',
    ruleId: rule.id,
    targetId: targetId,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

MapEntity? _findEntity(MapData map, String entityId) {
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

Set<String> _storyStepIds(ProjectManifest project) {
  return {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
  };
}

Set<String> _eventIds(ProjectManifest project, List<MapData> maps) {
  return {
    for (final map in maps)
      for (final event in map.events) event.id,
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[])
      record.id,
  };
}

String _targetIdentity(WorldRuleTarget target) {
  return switch (target.kind) {
    WorldRuleTargetKind.mapEntity =>
      '${target.mapId}:entity:${target.entityId ?? ''}',
    WorldRuleTargetKind.npcDialogue =>
      '${target.mapId}:npcDialogue:${target.entityId ?? ''}',
    WorldRuleTargetKind.mapEvent =>
      '${target.mapId}:event:${target.eventId ?? ''}',
    WorldRuleTargetKind.narrativeEvent =>
      'narrativeEvent:${target.eventId ?? ''}',
  };
}
