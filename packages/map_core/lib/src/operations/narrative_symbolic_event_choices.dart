part of 'narrative_symbolic_reachability_solver.dart';

typedef _LegacySymbolicSource = ({
  String mapId,
  MapEventDefinition event,
  List<WorldRuleDefinition> rules,
});

typedef _SymbolicEventChoice = ({
  String id,
  SceneAsset scene,
  bool consumesEvent,
  bool indeterminate,
});

bool _isPlayerControlledSource(NarrativeEventSourceRef source) =>
    source.kind == NarrativeEventSourceKind.entityInteract ||
    source.kind == NarrativeEventSourceKind.modelInteract ||
    source.kind == NarrativeEventSourceKind.triggerEnter;

bool _canRepeatSymbolicEvent(
  NarrativeEventDefinition definition,
  SceneAsset? scene,
) =>
    definition.reusePolicy == NarrativeEventReusePolicy.reusable ||
    (scene?.graph.nodes.any(
          (node) => switch (node.payload) {
            SceneEndPayload(outcomePolicy: SceneOutcomePolicy.retryable) =>
              true,
            _ => false,
          },
        ) ??
        false);

_NarrativeComponentWrites _reusableEventInputs(
  NarrativeEventDefinition definition, {
  required ProjectManifest project,
  required Map<String, SceneAsset> scenesById,
}) {
  final footprint = _narrativeBatchFootprint(
    project: project,
    definitions: [definition],
    scenesById: scenesById,
    milestoneWriters: const {},
  );
  return _NarrativeComponentWrites.from({
    ...footprint.reads,
    ...footprint.writes,
  });
}

List<_LegacySymbolicSource> _legacySymbolicSources(
  List<MapData> maps,
  EventSystemMode mode,
  List<WorldRuleDefinition> worldRules,
) {
  if (mode == EventSystemMode.v2Only) return const [];
  final occupiedCells = <(String, int, int)>{};
  final rulesByEvent = <(String, String), List<WorldRuleDefinition>>{};
  for (final rule in worldRules) {
    final eventId = rule.target.eventId;
    if (!rule.enabled ||
        rule.target.kind != WorldRuleTargetKind.mapEvent ||
        eventId == null) {
      continue;
    }
    rulesByEvent.putIfAbsent((rule.target.mapId, eventId), () => []).add(rule);
  }
  for (final rules in rulesByEvent.values) {
    rules.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      return priority == 0 ? a.id.compareTo(b.id) : priority;
    });
  }
  return [
    for (final map in maps)
      for (final event in map.events)
        if (occupiedCells.add((map.id, event.position.x, event.position.y)) &&
            event.pages.any((page) => page.sceneTarget != null))
          (
            mapId: map.id,
            event: event,
            rules: rulesByEvent[(map.id, event.id)] ?? const [],
          ),
  ];
}

_SymbolicEventChoice? _legacySymbolicChoice(
  _LegacySymbolicSource source,
  NarrativeSymbolicState state,
  Map<String, SceneAsset> scenesById,
) {
  for (final (index, page) in source.event.pages.indexed) {
    final condition = page.condition;
    final active = condition == null
        ? true
        : _legacySymbolicCondition(
            condition,
            source.mapId,
            state,
            typedFacts: hasEventBuilderPageProvenance(page),
          );
    if (active == false) continue;
    if (active == null || !_legacyEventEnabled(source.rules, page, state)) {
      return null;
    }
    final scene = scenesById[page.sceneTarget?.sceneId];
    final id = 'mapEvent:${source.mapId}:${source.event.id}:$index';
    if (scene == null || state.executedEventIds.contains(id)) return null;
    return (id: id, scene: scene, consumesEvent: false, indeterminate: false);
  }
  return null;
}

bool? _legacySymbolicCondition(
  ScriptCondition condition,
  String mapId,
  NarrativeSymbolicState state, {
  required bool typedFacts,
}) {
  final params = condition.params;
  switch (condition.type) {
    case ScriptConditionType.allOf:
    case ScriptConditionType.anyOf:
      final requiredValue = condition.type == ScriptConditionType.allOf;
      var unknown = false;
      for (final child in condition.children) {
        final result = _legacySymbolicCondition(
          child,
          mapId,
          state,
          typedFacts: typedFacts,
        );
        if (result == !requiredValue) return !requiredValue;
        unknown |= result == null;
      }
      return unknown ? null : requiredValue;
    case ScriptConditionType.not:
      if (condition.children.isEmpty) return true;
      final result = _legacySymbolicCondition(
        condition.children.first,
        mapId,
        state,
        typedFacts: typedFacts,
      );
      return result == null ? null : !result;
    case ScriptConditionType.flagIsSet:
      return state.hasTrueFact(params[ScriptConditionParams.flagName] ?? '');
    case ScriptConditionType.flagIsUnset:
      return !state.hasTrueFact(params[ScriptConditionParams.flagName] ?? '');
    case ScriptConditionType.factEquals:
      if (!typedFacts) return false;
      final value = state.factValues[params[ScriptConditionParams.factId]];
      if (value == null) return state.indeterminate ? null : false;
      return params[ScriptConditionParams.valueType] == value.kind.wireName &&
          params[ScriptConditionParams.value] == value.toJson().toString();
    case ScriptConditionType.stepCompleted:
      return state.completedStepIds.contains(
        params[ScriptConditionParams.stepId],
      );
    case ScriptConditionType.eventIsConsumed:
      return state.consumedEventIds.contains(
        params[ScriptConditionParams.eventId],
      );
    case ScriptConditionType.badgeOwned:
      return state.badgeIds.contains(params[ScriptConditionParams.badgeId]);
    case ScriptConditionType.playerOnMap:
      return params[ScriptConditionParams.mapId] == mapId;
    default:
      return null;
  }
}

bool _legacyEventEnabled(
  List<WorldRuleDefinition> rules,
  MapEventPage page,
  NarrativeSymbolicState state,
) {
  bool? enabled = !page.isDisabled;
  for (final rule in rules) {
    final ruleEnables = switch (rule.effect.kind) {
      WorldRuleEffectKind.eventEnabled => true,
      WorldRuleEffectKind.eventDisabled ||
      WorldRuleEffectKind.eventHidden => false,
      _ => null,
    };
    if (ruleEnables == null || ruleEnables == enabled) continue;
    final source = rule.source;
    final applies = switch (source.kind) {
      WorldRuleSourceKind.fact =>
        state.factValues[source.sourceId]?.matches(
              source.resolvedFactOperator,
              source.resolvedExpectedFactValue,
            ) ??
            false,
      WorldRuleSourceKind.storyStepCompletion =>
        state.completedStepIds.contains(source.sourceId) ==
            (source.predicate == WorldRuleSourcePredicate.completed),
      WorldRuleSourceKind.consumedEvent =>
        state.consumedEventIds.contains(source.sourceId) ==
            (source.predicate == WorldRuleSourcePredicate.consumed),
      _ => null,
    };
    if (applies != false) enabled = applies == true ? ruleEnables : null;
  }
  return enabled == true;
}

_NarrativeBatchFootprint _legacySymbolicFootprint(
  List<_LegacySymbolicSource> sources,
  Map<String, SceneAsset> scenesById,
  Map<String, Set<String>> milestoneWriters,
) {
  final reads = <String>{if (sources.isNotEmpty) _playerMapFootprintKey};
  final writes = <String>{};
  void collectReads(ScriptCondition condition) {
    final key = switch (condition.type) {
      ScriptConditionType.flagIsSet || ScriptConditionType.flagIsUnset => (
        'fact',
        ScriptConditionParams.flagName,
      ),
      ScriptConditionType.factEquals => ('fact', ScriptConditionParams.factId),
      ScriptConditionType.stepCompleted => (
        'step',
        ScriptConditionParams.stepId,
      ),
      ScriptConditionType.eventIsConsumed => (
        'consumed',
        ScriptConditionParams.eventId,
      ),
      ScriptConditionType.badgeOwned => (
        'badge',
        ScriptConditionParams.badgeId,
      ),
      _ => null,
    };
    final id = key == null ? null : condition.params[key.$2];
    if (key != null && id != null) {
      reads.add('${key.$1}:$id');
    }
    for (final child in condition.children) {
      collectReads(child);
    }
  }

  for (final source in sources) {
    for (final rule in source.rules) {
      final prefix = switch (rule.source.kind) {
        WorldRuleSourceKind.fact => 'fact',
        WorldRuleSourceKind.storyStepCompletion => 'step',
        WorldRuleSourceKind.consumedEvent => 'consumed',
        _ => null,
      };
      if (prefix != null) reads.add('$prefix:${rule.source.sourceId}');
    }
    for (final page in source.event.pages) {
      if (page.condition case final condition?) collectReads(condition);
      final scene = scenesById[page.sceneTarget?.sceneId];
      if (scene != null) _addSceneSymbolicFootprint(scene, reads, writes);
    }
  }
  return _NarrativeBatchFootprint(
    reads: reads,
    writes: {...writes, for (final key in writes) ...?milestoneWriters[key]},
  );
}

Map<Object, int> _interactionGroups(
  Map<Object, _NarrativeBatchFootprint> footprints,
) {
  final sources = footprints.keys.toList(growable: false);
  final parent = List<int>.generate(sources.length, (index) => index);
  int root(int index) {
    while (index != parent[index]) {
      parent[index] = parent[parent[index]];
      index = parent[index];
    }
    return index;
  }

  for (var i = 0; i < sources.length; i++) {
    for (var j = i + 1; j < sources.length; j++) {
      if (root(i) != root(j) &&
          _narrativeBatchesAreCoupled(
            footprints[sources[i]]!,
            footprints[sources[j]]!,
          )) {
        parent[root(j)] = root(i);
      }
    }
  }
  return {for (final (index, source) in sources.indexed) source: root(index)};
}
