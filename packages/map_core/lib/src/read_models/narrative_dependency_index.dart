import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

import '../authoring/storyline_legacy_import_preview.dart';
import '../models/map_data.dart';
import '../models/enums.dart';
import '../models/cinematic_asset.dart';
import '../models/map_entity_payloads.dart';
import '../models/narrative_event_definition.dart';
import '../models/narrative_event_registry.dart';
import '../models/narrative_event_source_ref.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';

/// Canonical namespaces used by Narrative Studio dependency consumers.
enum NarrativeDependencyTargetKind {
  fact,
  eventV2,
  scene,
  dialogue,
  cinematic,
  storyline,
  chapter,
  step,
  worldRule,
  sourceMap,
}

enum NarrativeDependencyResolution {
  resolved,
  missing,
  ambiguous,
  unavailable,
  legacyExternal,
}

enum NarrativeDependencyCriticality {
  informational,
  authoringWarning,
  runtimeBlocking,
}

enum NarrativeDependencyIssueKind {
  missingReference,
  ambiguousReference,
  unavailableReference,
  duplicateId,
  forbiddenCycle,
}

@immutable
final class NarrativeDependencyKey {
  const NarrativeDependencyKey(
    this.kind,
    this.id, {
    this.scope,
    this.parentId,
    this.sourceKind,
  });

  final NarrativeDependencyTargetKind kind;
  final String id;
  final String? scope;
  final String? parentId;
  final String? sourceKind;

  const NarrativeDependencyKey.map(String mapId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          mapId,
          scope: _physicalMapScope,
          parentId: mapId,
          sourceKind: 'map',
        );

  const NarrativeDependencyKey.mapSource({
    required String mapId,
    required String sourceKind,
    required String sourceId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          sourceId,
          scope: _physicalMapScope,
          parentId: mapId,
          sourceKind: sourceKind,
        );

  const NarrativeDependencyKey.scene(String sceneId)
      : this(NarrativeDependencyTargetKind.scene, sceneId);

  const NarrativeDependencyKey.eventV2(String eventId)
      : this(NarrativeDependencyTargetKind.eventV2, eventId);

  const NarrativeDependencyKey.projectNewGame()
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          'newGame',
          scope: 'project',
          sourceKind: 'newGame',
        );

  const NarrativeDependencyKey.legacyScenario(String scenarioId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          scenarioId,
          scope: 'legacy',
          sourceKind: 'scenario',
        );

  const NarrativeDependencyKey.legacyScenarioNode({
    required String scenarioId,
    required String nodeId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          nodeId,
          scope: 'legacy',
          parentId: scenarioId,
          sourceKind: 'scenarioNode',
        );

  const NarrativeDependencyKey.legacySourceClaim(String cohortId)
      : this(
          NarrativeDependencyTargetKind.sourceMap,
          cohortId,
          scope: 'migration',
          sourceKind: 'legacySourceClaim',
        );

  const NarrativeDependencyKey.legacyGlobalStoryPart({
    required String scenarioId,
    required String partKind,
    required String partId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          partId,
          scope: 'legacy',
          parentId: scenarioId,
          sourceKind: partKind,
        );

  const NarrativeDependencyKey.synthetic({
    required String sourceKind,
    required String sourceId,
    String? parentId,
  }) : this(
          NarrativeDependencyTargetKind.sourceMap,
          sourceId,
          scope: 'synthetic',
          parentId: parentId,
          sourceKind: sourceKind,
        );

  /// Owning map for a physical map root or child source, if this key is one.
  String? get physicalMapId {
    if (kind != NarrativeDependencyTargetKind.sourceMap) return null;
    if (scope == _physicalMapScope) return parentId;
    return null;
  }

  bool get isPhysicalMapSource => physicalMapId != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeDependencyKey &&
          other.kind == kind &&
          other.id == id &&
          other.scope == scope &&
          other.parentId == parentId &&
          other.sourceKind == sourceKind;

  @override
  int get hashCode => Object.hash(kind, id, scope, parentId, sourceKind);

  @override
  String toString() {
    final qualifiers = <String>[
      if (scope != null) 'scope=$scope',
      if (parentId != null) 'parent=$parentId',
      if (sourceKind != null) 'sourceKind=$sourceKind',
    ];
    return qualifiers.isEmpty
        ? '${kind.name}:$id'
        : '${kind.name}:$id (${qualifiers.join(', ')})';
  }
}

/// Package-neutral destination. The editor may translate it to its own route.
@immutable
final class NarrativeDependencyNavigationIntent {
  const NarrativeDependencyNavigationIntent({
    required this.kind,
    required this.assetId,
    this.parentId,
    this.rootId,
    this.scope,
    this.sourceKind,
    this.mapId,
    this.context,
  });

  /// Builds a deep-link intent from the canonical dependency identity.
  ///
  /// Keeping every qualifier avoids reconstructing a map/source target by
  /// parsing the human-facing path stored in [context].
  factory NarrativeDependencyNavigationIntent.fromKey(
    NarrativeDependencyKey key, {
    String? parentId,
    String? rootId,
    String? context,
  }) {
    return NarrativeDependencyNavigationIntent(
      kind: key.kind,
      assetId: key.id,
      parentId: key.parentId ?? parentId,
      rootId: rootId,
      scope: key.scope,
      sourceKind: key.sourceKind,
      mapId: key.physicalMapId,
      context: context,
    );
  }

  final NarrativeDependencyTargetKind kind;
  final String assetId;
  final String? parentId;
  final String? rootId;
  final String? scope;
  final String? sourceKind;
  final String? mapId;
  final String? context;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeDependencyNavigationIntent &&
          other.kind == kind &&
          other.assetId == assetId &&
          other.parentId == parentId &&
          other.rootId == rootId &&
          other.scope == scope &&
          other.sourceKind == sourceKind &&
          other.mapId == mapId &&
          other.context == context;

  @override
  int get hashCode => Object.hash(
        kind,
        assetId,
        parentId,
        rootId,
        scope,
        sourceKind,
        mapId,
        context,
      );
}

@immutable
final class NarrativeDependencyDefinition {
  NarrativeDependencyDefinition({
    required this.key,
    required this.label,
    this.owner,
    this.path,
    this.navigationIntent,
    Map<String, String> metadata = const <String, String>{},
  }) : metadata = Map<String, String>.unmodifiable(metadata);

  final NarrativeDependencyKey key;
  final String label;
  final NarrativeDependencyKey? owner;
  final String? path;
  final NarrativeDependencyNavigationIntent? navigationIntent;
  final Map<String, String> metadata;
}

@immutable
final class NarrativeDependencyUsage {
  const NarrativeDependencyUsage({
    required this.target,
    required this.owner,
    required this.path,
    required this.criticality,
    this.resolution = NarrativeDependencyResolution.resolved,
    this.navigationIntent,
  });

  final NarrativeDependencyKey target;
  final NarrativeDependencyKey owner;
  final String path;
  final NarrativeDependencyCriticality criticality;
  final NarrativeDependencyResolution resolution;
  final NarrativeDependencyNavigationIntent? navigationIntent;

  NarrativeDependencyUsage withResolution(
    NarrativeDependencyResolution value,
  ) {
    return NarrativeDependencyUsage(
      target: target,
      owner: owner,
      path: path,
      criticality: criticality,
      resolution: value,
      navigationIntent: navigationIntent,
    );
  }
}

@immutable
final class NarrativeDependencyIssue {
  const NarrativeDependencyIssue({
    required this.kind,
    required this.target,
    required this.criticality,
    required this.message,
    this.owner,
    this.path,
  });

  final NarrativeDependencyIssueKind kind;
  final NarrativeDependencyKey target;
  final NarrativeDependencyCriticality criticality;
  final String message;
  final NarrativeDependencyKey? owner;
  final String? path;
}

@immutable
final class NarrativeDependencyIndex {
  factory NarrativeDependencyIndex({
    Iterable<NarrativeDependencyDefinition> definitions =
        const <NarrativeDependencyDefinition>[],
    Iterable<NarrativeDependencyUsage> usages =
        const <NarrativeDependencyUsage>[],
    Iterable<NarrativeDependencyIssue> issues =
        const <NarrativeDependencyIssue>[],
  }) {
    final sortedDefinitions = definitions.toList()..sort(_compareDefinitions);
    final sortedUsages = usages.toList()..sort(_compareUsages);
    final sortedIssues = issues.toList()..sort(_compareIssues);
    return NarrativeDependencyIndex._(
      definitions: sortedDefinitions,
      usages: sortedUsages,
      issues: sortedIssues,
      definitionsByKey: _groupDefinitionsByKey(sortedDefinitions),
      usagesByTarget: _groupUsagesByTarget(sortedUsages),
      usagesByOwner: _groupUsagesByOwner(sortedUsages),
    );
  }

  NarrativeDependencyIndex._({
    required List<NarrativeDependencyDefinition> definitions,
    required List<NarrativeDependencyUsage> usages,
    required List<NarrativeDependencyIssue> issues,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
        definitionsByKey,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
        usagesByTarget,
    required Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
        usagesByOwner,
  })  : definitions = UnmodifiableListView(definitions),
        usages = UnmodifiableListView(usages),
        issues = UnmodifiableListView(issues),
        _definitionsByKey = UnmodifiableMapView(definitionsByKey),
        _usagesByTarget = UnmodifiableMapView(usagesByTarget),
        _usagesByOwner = UnmodifiableMapView(usagesByOwner);

  final List<NarrativeDependencyDefinition> definitions;
  final List<NarrativeDependencyUsage> usages;
  final List<NarrativeDependencyIssue> issues;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
      _definitionsByKey;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
      _usagesByTarget;
  final Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
      _usagesByOwner;

  List<NarrativeDependencyDefinition> definitionsFor(
    NarrativeDependencyKey key,
  ) {
    return _definitionsByKey[key] ?? const <NarrativeDependencyDefinition>[];
  }

  List<NarrativeDependencyUsage> usagesFor(NarrativeDependencyKey key) {
    return _usagesByTarget[key] ?? const <NarrativeDependencyUsage>[];
  }

  List<NarrativeDependencyUsage> usagesOwnedBy(
    NarrativeDependencyKey owner,
  ) {
    return _usagesByOwner[owner] ?? const <NarrativeDependencyUsage>[];
  }
}

NarrativeDependencyIndex buildNarrativeDependencyIndex({
  required ProjectManifest project,
  List<MapData> maps = const <MapData>[],
}) {
  return _NarrativeDependencyIndexBuilder(project, maps).build();
}

final class _NarrativeDependencyIndexBuilder {
  _NarrativeDependencyIndexBuilder(this.project, List<MapData> maps)
      : maps = List<MapData>.unmodifiable(maps);

  final ProjectManifest project;
  final List<MapData> maps;
  final List<NarrativeDependencyDefinition> _definitions = [];
  final List<NarrativeDependencyUsage> _usages = [];
  final List<NarrativeDependencyIssue> _issues = [];
  final List<(String, String)> _eventCycleEdges = [];

  NarrativeDependencyIndex build() {
    _collectProjectDefinitions();
    _collectMaps();
    _collectNewGame();
    _collectEvents();
    _collectLegacyClaims();
    _collectScenes();
    _collectStorylines();
    _collectCinematics();
    _collectWorldRules();
    _collectLegacyScenarios();
    _collectCycleIssues();
    return _resolve();
  }

  void _collectProjectDefinitions() {
    for (final map in project.maps) {
      _definition(
        NarrativeDependencyTargetKind.sourceMap,
        map.id,
        map.name,
        path: 'maps[${map.id}]',
        scope: _physicalMapScope,
        parentId: map.id,
        sourceKind: 'map',
      );
    }
    for (final fact in project.facts) {
      _definition(
        NarrativeDependencyTargetKind.fact,
        fact.id,
        fact.label,
        path: 'facts[${fact.id}]',
      );
    }
    for (final dialogue in project.dialogues) {
      _definition(
        NarrativeDependencyTargetKind.dialogue,
        dialogue.id,
        dialogue.name,
        path: 'dialogues[${dialogue.id}]',
      );
    }
    for (final scene in project.scenes) {
      _definition(
        NarrativeDependencyTargetKind.scene,
        scene.id,
        scene.name,
        path: 'scenes[${scene.id}]',
      );
    }
    for (final cinematic in project.cinematics) {
      _definition(
        NarrativeDependencyTargetKind.cinematic,
        cinematic.id,
        cinematic.title,
        path: 'cinematics[${cinematic.id}]',
      );
    }
    for (final storyline in project.storylines) {
      final storylineKey = _definition(
        NarrativeDependencyTargetKind.storyline,
        storyline.id,
        storyline.title,
        path: 'storylines[${storyline.id}]',
      );
      for (final chapter in storyline.chapters) {
        final chapterKey = _definition(
          NarrativeDependencyTargetKind.chapter,
          chapter.id,
          chapter.title,
          owner: storylineKey,
          path: 'storylines[${storyline.id}].chapters[${chapter.id}]',
        );
        for (final step in chapter.steps) {
          _definition(
            NarrativeDependencyTargetKind.step,
            step.id,
            step.title,
            owner: chapterKey,
            navigationRootId: storyline.id,
            path:
                'storylines[${storyline.id}].chapters[${chapter.id}].steps[${step.id}]',
          );
        }
      }
    }
    for (final rule in project.worldRules) {
      _definition(
        NarrativeDependencyTargetKind.worldRule,
        rule.id,
        rule.label,
        path: 'worldRules[${rule.id}]',
      );
    }
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      final label = record.when(
        draft: (draft) => draft.name,
        configured: (definition, _) => definition.name,
      );
      _definition(
        NarrativeDependencyTargetKind.eventV2,
        record.id,
        label,
        path: 'eventRegistry.records[${record.id}]',
      );
    }
  }

  void _collectNewGame() {
    final config = project.newGame;
    final criticality = config.enabled
        ? NarrativeDependencyCriticality.runtimeBlocking
        : NarrativeDependencyCriticality.authoringWarning;
    final startMapId = config.startMapId.trim();
    if (startMapId.isNotEmpty) {
      _usage(
        target: _mapKey(startMapId),
        owner: _newGameOwner,
        path: 'newGame.startMapId',
        criticality: criticality,
      );
    }
    final startSpawnId = config.startSpawnId?.trim();
    if (startMapId.isNotEmpty &&
        startSpawnId != null &&
        startSpawnId.isNotEmpty) {
      _usage(
        target: _mapSourceChildKey(startMapId, 'entity', startSpawnId),
        owner: _newGameOwner,
        path: 'newGame.startSpawnId',
        criticality: criticality,
      );
    }
    final factIds = config.initialFacts.keys.toList()..sort();
    for (final factId in factIds) {
      if (factId.trim().isEmpty) continue;
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          factId,
        ),
        owner: _newGameOwner,
        path: 'newGame.initialFacts[$factId]',
        criticality: criticality,
      );
    }
    final existingPartyFactId = config.existingPartyFactId?.trim();
    if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          existingPartyFactId,
        ),
        owner: _newGameOwner,
        path: 'newGame.existingPartyFactId',
        criticality: criticality,
      );
    }
    final starterSceneId = config.starterSelectionSceneId?.trim();
    if (starterSceneId != null && starterSceneId.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.scene,
          starterSceneId,
        ),
        owner: _newGameOwner,
        path: 'newGame.starterSelectionSceneId',
        criticality: criticality,
      );
    }
  }

  void _collectMaps() {
    for (final map in maps) {
      final mapKey = _mapKey(map.id);
      if (!project.maps.any((entry) => entry.id == map.id)) {
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          map.id,
          map.name,
          path: 'maps[${map.id}]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'map',
        );
      }
      for (var index = 0; index < map.entities.length; index++) {
        final entity = map.entities[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          entity.id,
          entity.inspectorHeadline,
          owner: mapKey,
          path: 'maps[${map.id}].entities[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'entity',
        );
        if (entity.kind == MapEntityKind.npc) {
          final npc = entity.npc;
          if (npc != null) {
            _collectAuthoredDialogueRef(
              npc.dialogue,
              owner,
              'maps[${map.id}].entities[$index].npc.dialogue',
            );
            _collectAuthoredDialogueRef(
              npc.defeatDialogueRef,
              owner,
              'maps[${map.id}].entities[$index].npc.defeatDialogueRef',
            );
            final visibilityPredicate = npc.visibilityRule?.predicate;
            if (visibilityPredicate != null) {
              _collectMapPredicate(
                visibilityPredicate,
                owner,
                'maps[${map.id}].entities[$index].npc.visibilityRule.predicate',
              );
            }
            for (var conditionalIndex = 0;
                conditionalIndex < npc.conditionalDialogues.length;
                conditionalIndex++) {
              final conditional = npc.conditionalDialogues[conditionalIndex];
              final prefix =
                  'maps[${map.id}].entities[$index].npc.conditionalDialogues[$conditionalIndex]';
              _collectMapPredicate(conditional.when, owner, '$prefix.when');
              _collectAuthoredDialogueRef(
                conditional.dialogue,
                owner,
                '$prefix.dialogue',
              );
            }
          }
        } else if (entity.kind == MapEntityKind.sign) {
          _collectAuthoredDialogueRef(
            entity.sign?.dialogue,
            owner,
            'maps[${map.id}].entities[$index].sign.dialogue',
          );
        }
      }
      for (var index = 0; index < map.placedElements.length; index++) {
        final element = map.placedElements[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          element.id,
          element.id,
          owner: mapKey,
          path: 'maps[${map.id}].placedElements[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'element',
        );
        for (var behaviorIndex = 0;
            behaviorIndex < element.behaviors.length;
            behaviorIndex++) {
          _collectAuthoredDialogueRef(
            element.behaviors[behaviorIndex].effect.dialogue,
            owner,
            'maps[${map.id}].placedElements[$index].behaviors[$behaviorIndex].effect.dialogue',
          );
        }
      }
      for (var index = 0; index < map.gameplayZones.length; index++) {
        final zone = map.gameplayZones[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          zone.id,
          zone.name.trim().isEmpty ? zone.id : zone.name,
          owner: mapKey,
          path: 'maps[${map.id}].gameplayZones[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'gameplayZone',
        );
      }
      for (var index = 0; index < map.triggers.length; index++) {
        final trigger = map.triggers[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          trigger.id,
          trigger.name.trim().isEmpty ? trigger.id : trigger.name,
          owner: mapKey,
          path: 'maps[${map.id}].triggers[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'trigger',
        );
      }
      for (var index = 0; index < map.events.length; index++) {
        final event = map.events[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          event.id,
          event.title.trim().isEmpty ? event.id : event.title,
          owner: mapKey,
          path: 'maps[${map.id}].events[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'event',
        );
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          event.id,
          event.title.trim().isEmpty ? event.id : event.title,
          owner: owner,
          path: 'maps[${map.id}].events[$index].globalAlias',
          scope: 'synthetic',
          sourceKind: 'legacyMapEvent',
        );
        for (var pageIndex = 0; pageIndex < event.pages.length; pageIndex++) {
          final page = event.pages[pageIndex];
          final prefix = 'maps[${map.id}].events[$index].pages[$pageIndex]';
          final sceneId = page.sceneTarget?.sceneId.trim();
          if (sceneId != null && sceneId.isNotEmpty) {
            _usage(
              target: NarrativeDependencyKey(
                NarrativeDependencyTargetKind.scene,
                sceneId,
              ),
              owner: owner,
              path: '$prefix.sceneTarget.sceneId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
          final condition = page.condition;
          if (condition != null) {
            _collectScriptCondition(
              condition,
              owner,
              '$prefix.condition',
              mapId: map.id,
            );
          }
        }
      }
      for (var index = 0; index < map.warps.length; index++) {
        final warp = map.warps[index];
        final owner = _definition(
          NarrativeDependencyTargetKind.sourceMap,
          warp.id,
          warp.id,
          owner: mapKey,
          path: 'maps[${map.id}].warps[$index]',
          scope: _physicalMapScope,
          parentId: map.id,
          sourceKind: 'warp',
        );
        _usage(
          target: _mapKey(warp.targetMapId),
          owner: owner,
          path: 'maps[${map.id}].warps[$index].targetMapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      for (var index = 0; index < map.connections.length; index++) {
        _usage(
          target: _mapKey(map.connections[index].targetMapId),
          owner: mapKey,
          path: 'maps[${map.id}].connections[$index].targetMapId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
    }
  }

  void _collectAuthoredDialogueRef(
    DialogueRef? reference,
    NarrativeDependencyKey owner,
    String path,
  ) {
    if (reference == null) return;
    final scriptPath = reference.scriptPathRelative.trim();
    if (scriptPath.isNotEmpty) {
      _usage(
        target: NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyDialogueScript',
          sourceId: scriptPath,
          parentId: reference.dialogueId.trim().isEmpty
              ? null
              : reference.dialogueId.trim(),
        ),
        owner: owner,
        path: '$path.scriptPathRelative',
        criticality: NarrativeDependencyCriticality.informational,
        resolution: NarrativeDependencyResolution.legacyExternal,
      );
      return;
    }
    _collectDialogueRef(reference.dialogueId, owner, '$path.dialogueId');
  }

  void _collectDialogueRef(
    String? rawDialogueId,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final dialogueId = rawDialogueId?.trim();
    if (dialogueId == null || dialogueId.isEmpty) return;
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.dialogue,
        dialogueId,
      ),
      owner: owner,
      path: path,
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
    );
  }

  void _collectMapPredicate(
    MapEntityRuntimePredicate predicate,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final kind = predicate.kind;
    final sourceId = predicate.refId.trim();
    if (sourceId.isEmpty) return;
    switch (kind) {
      case MapEntityRuntimePredicateKind.storyFlagSet:
      case MapEntityRuntimePredicateKind.storyFlagUnset:
        _collectLegacyFactRef(sourceId, owner, '$path.refId');
      case MapEntityRuntimePredicateKind.stepCompleted:
      case MapEntityRuntimePredicateKind.stepNotCompleted:
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            sourceId,
          ),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      case MapEntityRuntimePredicateKind.chapterCompleted:
      case MapEntityRuntimePredicateKind.chapterNotCompleted:
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            sourceId,
          ),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      case MapEntityRuntimePredicateKind.cutsceneCompleted:
      case MapEntityRuntimePredicateKind.cutsceneNotCompleted:
        _usage(
          target: NarrativeDependencyKey.legacyScenario(sourceId),
          owner: owner,
          path: '$path.refId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
    }
  }

  void _collectLegacyFactRef(
    String sourceId,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final matchingIds = project.facts
        .where((fact) => fact.id == sourceId || fact.legacyFlagName == sourceId)
        .map((fact) => fact.id)
        .toSet();
    if (matchingIds.length == 1) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          matchingIds.single,
        ),
        owner: owner,
        path: path,
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      return;
    }
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        sourceId,
        scope: matchingIds.isEmpty ? null : 'legacyAlias',
      ),
      owner: owner,
      path: path,
      criticality: NarrativeDependencyCriticality.authoringWarning,
      resolution: matchingIds.isEmpty
          ? NarrativeDependencyResolution.legacyExternal
          : NarrativeDependencyResolution.ambiguous,
    );
  }

  void _collectScriptCondition(
    ScriptCondition root,
    NarrativeDependencyKey owner,
    String rootPath, {
    String? mapId,
  }) {
    final pending = <(ScriptCondition, String)>[(root, rootPath)];
    for (var cursor = 0; cursor < pending.length; cursor++) {
      final (condition, path) = pending[cursor];
      switch (condition.type) {
        case ScriptConditionType.flagIsSet:
        case ScriptConditionType.flagIsUnset:
          final flag = condition.params[ScriptConditionParams.flagName]?.trim();
          if (flag != null && flag.isNotEmpty) {
            _collectLegacyFactRef(flag, owner, '$path.params.flagName');
          }
        case ScriptConditionType.eventIsConsumed:
          final eventId =
              condition.params[ScriptConditionParams.eventId]?.trim();
          if (eventId != null && eventId.isNotEmpty) {
            _usage(
              target: mapId == null
                  ? NarrativeDependencyKey.synthetic(
                      sourceKind: 'legacyMapEvent',
                      sourceId: eventId,
                    )
                  : _mapSourceChildKey(mapId, 'event', eventId),
              owner: owner,
              path: '$path.params.eventId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        case ScriptConditionType.playerOnMap:
          final targetMapId =
              condition.params[ScriptConditionParams.mapId]?.trim();
          if (targetMapId != null && targetMapId.isNotEmpty) {
            _usage(
              target: _mapKey(targetMapId),
              owner: owner,
              path: '$path.params.mapId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        default:
          break;
      }
      for (var index = 0; index < condition.children.length; index++) {
        pending.add((condition.children[index], '$path.children[$index]'));
      }
    }
  }

  void _collectEvents() {
    for (final record
        in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
      record.when<void>(
        draft: (draft) {
          final owner = _eventKey(draft.id);
          final source = draft.source;
          if (source != null) {
            _collectEventSource(owner, draft.id, source);
          }
          for (var index = 0; index < draft.conditions.length; index++) {
            _collectEventCondition(
              owner,
              draft.id,
              draft.conditions[index],
              index,
            );
          }
          final sceneId = draft.sceneId;
          if (sceneId != null) _collectEventScene(owner, draft.id, sceneId);
        },
        configured: (definition, _) {
          final owner = _eventKey(definition.id);
          _collectEventSource(owner, definition.id, definition.source);
          for (var index = 0; index < definition.conditions.length; index++) {
            _collectEventCondition(
              owner,
              definition.id,
              definition.conditions[index],
              index,
            );
          }
          _collectEventScene(owner, definition.id, definition.sceneId);
        },
      );
    }
  }

  void _collectEventSource(
    NarrativeDependencyKey owner,
    String eventId,
    NarrativeEventSourceRef source,
  ) {
    _collectNarrativeEventSource(
      owner,
      source,
      'eventRegistry.records[$eventId].source',
    );
  }

  void _collectNarrativeEventSource(
    NarrativeDependencyKey owner,
    NarrativeEventSourceRef source,
    String prefix,
  ) {
    source.when<void>(
      entityInteract: (mapId, entityId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        _usage(
          target: _mapSourceChildKey(mapId, 'entity', entityId),
          owner: owner,
          path: '$prefix.entityId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      triggerEnter: (mapId, triggerId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        _usage(
          target: _mapSourceChildKey(mapId, 'trigger', triggerId),
          owner: owner,
          path: '$prefix.triggerId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      mapEnter: (mapId) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: '$prefix.mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      outcomeReceived: (outcome) {
        final target = switch (outcome.producerKind) {
          NarrativeOutcomeProducerKind.scene => NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              outcome.producerId,
            ),
          NarrativeOutcomeProducerKind.battle =>
            NarrativeDependencyKey.synthetic(
              sourceKind: 'battle',
              sourceId: outcome.producerId,
            ),
          NarrativeOutcomeProducerKind.legacyScenario =>
            NarrativeDependencyKey.legacyScenario(outcome.producerId),
        };
        _usage(
          target: target,
          owner: owner,
          path: '$prefix.outcome.producerId#${outcome.outcomeId}',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          resolution: outcome.producerKind == NarrativeOutcomeProducerKind.scene
              ? null
              : NarrativeDependencyResolution.legacyExternal,
        );
      },
    );
  }

  void _collectLegacyClaims() {
    final claims =
        project.eventRegistry?.legacyClaims ?? const <LegacySourceClaim>[];
    for (final claim in claims) {
      final prefix = 'eventRegistry.legacyClaims[${claim.cohortId}]';
      final owner = _definition(
        NarrativeDependencyTargetKind.sourceMap,
        claim.cohortId,
        'Migration claim ${claim.cohortId}',
        path: prefix,
        scope: 'migration',
        sourceKind: 'legacySourceClaim',
        metadata: <String, String>{
          'cohortFingerprint': claim.cohortFingerprint,
          'migrationReceiptId': claim.migrationReceiptId,
          'memberCount': '${claim.members.length}',
          'targetEventCount': '${claim.targetEventIds.length}',
        },
      );
      _collectNarrativeEventSource(owner, claim.source, '$prefix.source');
      for (var index = 0; index < claim.members.length; index++) {
        final provenance = claim.members[index].provenance;
        final provenancePath = '$prefix.members[$index].provenance';
        provenance.when<void>(
          mapEvent: (mapId, eventId) {
            _usage(
              target: _mapKey(mapId),
              owner: owner,
              path: '$provenancePath.mapId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
            _usage(
              target: _mapSourceChildKey(mapId, 'event', eventId),
              owner: owner,
              path: '$provenancePath.eventId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          },
          scenarioSourceNode: (scenarioId, nodeId) {
            _usage(
              target: NarrativeDependencyKey.legacyScenario(scenarioId),
              owner: owner,
              path: '$provenancePath.scenarioId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
            _usage(
              target: NarrativeDependencyKey.legacyScenarioNode(
                scenarioId: scenarioId,
                nodeId: nodeId,
              ),
              owner: owner,
              path: '$provenancePath.nodeId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          },
        );
      }
      for (final targetEventId in claim.targetEventIds) {
        _usage(
          target: _eventKey(targetEventId),
          owner: owner,
          path: '$prefix.targetEventIds[$targetEventId]',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
    }
  }

  void _collectEventCondition(
    NarrativeDependencyKey owner,
    String eventId,
    NarrativeEventCondition condition,
    int index,
  ) {
    condition.when<void>(
      fact: (factId, _) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            factId,
          ),
          owner: owner,
          path: 'eventRegistry.records[$eventId].conditions[$index].factId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      },
      narrativeEventConsumed: (consumedEventId, expectedValue) {
        _usage(
          target: _eventKey(consumedEventId),
          owner: owner,
          path: 'eventRegistry.records[$eventId].conditions[$index].eventId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
        if (expectedValue) {
          _eventCycleEdges.add((owner.id, consumedEventId));
        }
      },
    );
  }

  void _collectEventScene(
    NarrativeDependencyKey owner,
    String eventId,
    String sceneId,
  ) {
    _usage(
      target: NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        sceneId,
      ),
      owner: owner,
      path: 'eventRegistry.records[$eventId].sceneId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
    );
  }

  void _collectScenes() {
    for (final scene in project.scenes) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.scene,
        scene.id,
      );
      final storylineId = scene.storylineId;
      if (storylineId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            storylineId,
          ),
          owner: owner,
          path: 'scenes[${scene.id}].storylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final chapterId = scene.chapterId;
      if (chapterId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            chapterId,
          ),
          owner: owner,
          path: 'scenes[${scene.id}].chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      for (var index = 0; index < scene.graph.nodes.length; index++) {
        _collectSceneNode(owner, scene.id, scene.graph.nodes[index], index);
      }
    }
  }

  void _collectStorylines() {
    for (final storyline in project.storylines) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.storyline,
        storyline.id,
      );
      for (var chapterIndex = 0;
          chapterIndex < storyline.chapters.length;
          chapterIndex++) {
        final chapter = storyline.chapters[chapterIndex];
        for (var sceneIndex = 0;
            sceneIndex < chapter.directSceneLinkIds.length;
            sceneIndex++) {
          _usage(
            target: NarrativeDependencyKey.scene(
              chapter.directSceneLinkIds[sceneIndex],
            ),
            owner: owner,
            path:
                'storylines[${storyline.id}].chapters[$chapterIndex].directSceneLinkIds[$sceneIndex]',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        for (var stepIndex = 0; stepIndex < chapter.steps.length; stepIndex++) {
          final step = chapter.steps[stepIndex];
          final prefix =
              'storylines[${storyline.id}].chapters[$chapterIndex].steps[$stepIndex]';
          for (var sceneIndex = 0;
              sceneIndex < step.sceneLinkIds.length;
              sceneIndex++) {
            _usage(
              target: NarrativeDependencyKey(
                NarrativeDependencyTargetKind.scene,
                step.sceneLinkIds[sceneIndex],
              ),
              owner: owner,
              path: '$prefix.sceneLinkIds[$sceneIndex]',
              criticality: NarrativeDependencyCriticality.authoringWarning,
            );
          }
          final entryCondition = step.entryCondition;
          if (entryCondition != null) {
            _collectScriptCondition(
              entryCondition,
              owner,
              '$prefix.entryCondition',
            );
          }
          final completionCondition = step.completionCondition;
          if (completionCondition != null) {
            _collectScriptCondition(
              completionCondition,
              owner,
              '$prefix.completionCondition',
            );
          }
        }
      }
      for (var linkIndex = 0;
          linkIndex < storyline.sceneLinks.length;
          linkIndex++) {
        final link = storyline.sceneLinks[linkIndex];
        final prefix = 'storylines[${storyline.id}].sceneLinks[$linkIndex]';
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            link.chapterId,
          ),
          owner: owner,
          path: '$prefix.chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        final stepId = link.stepId;
        if (stepId != null) {
          _usage(
            target: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              stepId,
            ),
            owner: owner,
            path: '$prefix.stepId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final legacyTargetId = link.sceneRef?.targetId;
        if (legacyTargetId != null) {
          _usage(
            target: NarrativeDependencyKey.legacyScenario(legacyTargetId),
            owner: owner,
            path: '$prefix.legacy.sceneRef.targetId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
            resolution: NarrativeDependencyResolution.legacyExternal,
          );
        }
        for (var outcomeIndex = 0;
            outcomeIndex < link.outcomeLinks.length;
            outcomeIndex++) {
          final outcomeLink = link.outcomeLinks[outcomeIndex];
          for (var effectIndex = 0;
              effectIndex < outcomeLink.effects.length;
              effectIndex++) {
            _collectStorylineEffect(
              outcomeLink.effects[effectIndex],
              owner,
              '$prefix.outcomeLinks[$outcomeIndex].effects[$effectIndex]',
            );
          }
        }
      }
      for (var index = 0; index < storyline.relationships.length; index++) {
        final relationship = storyline.relationships[index];
        final prefix = 'storylines[${storyline.id}].relationships[$index]';
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            relationship.sourceStorylineId,
          ),
          owner: owner,
          path: '$prefix.sourceStorylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            relationship.targetStorylineId,
          ),
          owner: owner,
          path: '$prefix.targetStorylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
        final anchor = relationship.anchor;
        if (anchor != null) {
          _collectStorylineAnchor(anchor, owner, '$prefix.anchor');
        }
        final availability = relationship.availability;
        if (availability != null) {
          _collectStorylineAnchor(
            availability.startAnchor,
            owner,
            '$prefix.availability.startAnchor',
          );
          final endAnchor = availability.endAnchor;
          if (endAnchor != null) {
            _collectStorylineAnchor(
              endAnchor,
              owner,
              '$prefix.availability.endAnchor',
            );
          }
          final availabilityCondition = availability.availabilityCondition;
          if (availabilityCondition != null) {
            _collectScriptCondition(
              availabilityCondition,
              owner,
              '$prefix.availability.availabilityCondition',
            );
          }
          final expiresCondition = availability.expiresCondition;
          if (expiresCondition != null) {
            _collectScriptCondition(
              expiresCondition,
              owner,
              '$prefix.availability.expiresCondition',
            );
          }
        }
        final condition = relationship.condition;
        if (condition != null) {
          _collectScriptCondition(condition, owner, '$prefix.condition');
        }
      }
      final legacySource = storyline.legacySource;
      if (legacySource != null) {
        _usage(
          target: NarrativeDependencyKey.synthetic(
            sourceKind: legacySource.kind,
            sourceId: legacySource.sourceId,
          ),
          owner: owner,
          path: 'storylines[${storyline.id}].legacy.sourceId',
          criticality: NarrativeDependencyCriticality.informational,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
      }
    }
  }

  void _collectStorylineEffect(
    StorylineEffect effect,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final target = switch (effect.type) {
      StorylineEffectType.activateStep ||
      StorylineEffectType.completeStep =>
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          effect.targetId,
        ),
      StorylineEffectType.unlockStoryline => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          effect.targetId,
        ),
      StorylineEffectType.emitFact => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          effect.targetId,
        ),
      StorylineEffectType.setWorldRule => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.worldRule,
          effect.targetId,
        ),
      StorylineEffectType.affectRelationship =>
        NarrativeDependencyKey.synthetic(
          sourceKind: 'storylineRelationship',
          sourceId: effect.targetId,
        ),
    };
    _usage(
      target: target,
      owner: owner,
      path: '$path.targetId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
      resolution: effect.type == StorylineEffectType.affectRelationship
          ? NarrativeDependencyResolution.legacyExternal
          : null,
    );
  }

  void _collectStorylineAnchor(
    StorylineAnchor anchor,
    NarrativeDependencyKey owner,
    String path,
  ) {
    final target = switch (anchor.kind) {
      StorylineAnchorKind.storyline => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.storyline,
          anchor.targetId,
        ),
      StorylineAnchorKind.chapter => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.chapter,
          anchor.targetId,
        ),
      StorylineAnchorKind.step => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          anchor.targetId,
        ),
      StorylineAnchorKind.sceneOutcome => NarrativeDependencyKey.synthetic(
          sourceKind: 'sceneOutcome',
          sourceId: anchor.targetId,
        ),
    };
    _usage(
      target: target,
      owner: owner,
      path: '$path.targetId',
      criticality: NarrativeDependencyCriticality.authoringWarning,
      resolution: anchor.kind == StorylineAnchorKind.sceneOutcome
          ? NarrativeDependencyResolution.legacyExternal
          : null,
    );
  }

  void _collectCinematics() {
    for (final cinematic in project.cinematics) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.cinematic,
        cinematic.id,
      );
      final storylineId = cinematic.storylineId;
      if (storylineId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.storyline,
            storylineId,
          ),
          owner: owner,
          path: 'cinematics[${cinematic.id}].storylineId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final chapterId = cinematic.chapterId;
      if (chapterId != null) {
        _usage(
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.chapter,
            chapterId,
          ),
          owner: owner,
          path: 'cinematics[${cinematic.id}].chapterId',
          criticality: NarrativeDependencyCriticality.authoringWarning,
        );
      }
      final mapId = cinematic.mapId;
      if (mapId != null) {
        _usage(
          target: _mapKey(mapId),
          owner: owner,
          path: 'cinematics[${cinematic.id}].mapId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      if (mapId != null) {
        for (var index = 0; index < cinematic.requiredActors.length; index++) {
          final entityId = cinematic.requiredActors[index].entityId;
          if (entityId != null) {
            _usage(
              target: _mapSourceChildKey(mapId, 'entity', entityId),
              owner: owner,
              path:
                  'cinematics[${cinematic.id}].requiredActors[$index].entityId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        }
        final bindings = cinematic.stageContext?.actorBindings ??
            const <CinematicActorBinding>[];
        for (var index = 0; index < bindings.length; index++) {
          final entityId = bindings[index].mapEntityId;
          if (entityId != null) {
            _usage(
              target: _mapSourceChildKey(mapId, 'entity', entityId),
              owner: owner,
              path:
                  'cinematics[${cinematic.id}].stageContext.actorBindings[$index].mapEntityId',
              criticality: NarrativeDependencyCriticality.runtimeBlocking,
            );
          }
        }
        final movementBindings =
            cinematic.stageContext?.movementTargetBindings ??
                const <CinematicMovementTargetBinding>[];
        for (var index = 0; index < movementBindings.length; index++) {
          final binding = movementBindings[index];
          final sourceId = binding.sourceId?.trim();
          final sourceKind = switch (binding.kind) {
            CinematicMovementTargetBindingKind.mapEntity => 'entity',
            CinematicMovementTargetBindingKind.mapEvent => 'event',
            CinematicMovementTargetBindingKind.abstractPoint ||
            CinematicMovementTargetBindingKind.stagePoint =>
              null,
          };
          if (sourceKind == null || sourceId == null || sourceId.isEmpty) {
            continue;
          }
          _usage(
            target: _mapSourceChildKey(mapId, sourceKind, sourceId),
            owner: owner,
            path:
                'cinematics[${cinematic.id}].stageContext.movementTargetBindings[$index].sourceId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          );
        }
      }
      final scenarioId = cinematic.legacyBridge?.scenarioId;
      if (scenarioId != null) {
        _usage(
          target: NarrativeDependencyKey.legacyScenario(scenarioId),
          owner: owner,
          path: 'cinematics[${cinematic.id}].legacyBridge.scenarioId',
          criticality: NarrativeDependencyCriticality.informational,
          resolution: NarrativeDependencyResolution.legacyExternal,
        );
      }
    }
  }

  void _collectWorldRules() {
    for (final rule in project.worldRules) {
      final owner = NarrativeDependencyKey(
        NarrativeDependencyTargetKind.worldRule,
        rule.id,
      );
      final sourceTarget = switch (rule.source.kind) {
        WorldRuleSourceKind.fact => NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            rule.source.sourceId,
          ),
        WorldRuleSourceKind.storyStepCompletion => NarrativeDependencyKey(
            NarrativeDependencyTargetKind.step,
            rule.source.sourceId,
          ),
        WorldRuleSourceKind.consumedEvent => NarrativeDependencyKey.synthetic(
            sourceKind: 'legacyMapEvent',
            sourceId: rule.source.sourceId,
          ),
      };
      _usage(
        target: sourceTarget,
        owner: owner,
        path: 'worldRules[${rule.id}].source.sourceId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      _usage(
        target: _mapKey(rule.target.mapId),
        owner: owner,
        path: 'worldRules[${rule.id}].target.mapId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      final entityId = rule.target.entityId;
      if (entityId != null) {
        _usage(
          target: _mapSourceChildKey(rule.target.mapId, 'entity', entityId),
          owner: owner,
          path: 'worldRules[${rule.id}].target.entityId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      final eventId = rule.target.eventId;
      if (eventId != null) {
        _usage(
          target: _mapSourceChildKey(rule.target.mapId, 'event', eventId),
          owner: owner,
          path: 'worldRules[${rule.id}].target.eventId',
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
        );
      }
      _collectDialogueRef(
        rule.effect.dialogueId,
        owner,
        'worldRules[${rule.id}].effect.dialogueId',
      );
    }
  }

  void _collectLegacyScenarios() {
    final globalStoryCandidates =
        <String, StorylineLegacyGlobalStoryImportCandidate>{
      for (final candidate
          in buildLegacyGlobalStoryImportPreview(project).candidates)
        candidate.sourceScenarioId: candidate,
    };
    for (final scenario in project.scenarios) {
      final owner = _definition(
        NarrativeDependencyTargetKind.sourceMap,
        scenario.id,
        scenario.name,
        path: 'scenarios[${scenario.id}]',
        scope: 'legacy',
        sourceKind: 'scenario',
        metadata: <String, String>{
          'scope': scenario.scope.name,
          'entryNodeId': scenario.entryNodeId,
          ...scenario.metadata,
        },
      );
      final globalStoryCandidate = globalStoryCandidates[scenario.id];
      if (globalStoryCandidate != null) {
        for (var chapterIndex = 0;
            chapterIndex < globalStoryCandidate.draftStoryline.chapters.length;
            chapterIndex++) {
          final chapter =
              globalStoryCandidate.draftStoryline.chapters[chapterIndex];
          final chapterKey = _definition(
            NarrativeDependencyTargetKind.sourceMap,
            chapter.id,
            chapter.title,
            owner: owner,
            path:
                'scenarios[${scenario.id}].metadata[authoring.globalStoryStudioDocument].chapters[$chapterIndex]',
            scope: 'legacy',
            parentId: scenario.id,
            sourceKind: 'globalStoryChapter',
            metadata: <String, String>{
              'legacyScenarioId': scenario.id,
              'legacyDocument': 'authoring.globalStoryStudioDocument',
              'order': '${chapter.order}',
            },
          );
          for (var stepIndex = 0;
              stepIndex < chapter.steps.length;
              stepIndex++) {
            final step = chapter.steps[stepIndex];
            _definition(
              NarrativeDependencyTargetKind.sourceMap,
              step.id,
              step.title,
              owner: chapterKey,
              path:
                  'scenarios[${scenario.id}].metadata[authoring.stepStudioDocument].steps[$stepIndex]',
              scope: 'legacy',
              parentId: scenario.id,
              sourceKind: 'globalStoryStep',
              metadata: <String, String>{
                'legacyScenarioId': scenario.id,
                'legacyDocument': 'authoring.stepStudioDocument',
                'order': '${step.order}',
              },
            );
          }
        }
      }
      final activationCondition = scenario.activationCondition;
      if (activationCondition != null) {
        _collectScriptCondition(
          activationCondition,
          owner,
          'scenarios[${scenario.id}].legacy.activationCondition',
        );
      }
      for (var index = 0; index < scenario.nodes.length; index++) {
        final node = scenario.nodes[index];
        _definition(
          NarrativeDependencyTargetKind.sourceMap,
          node.id,
          node.title.trim().isEmpty ? node.id : node.title,
          owner: owner,
          path: 'scenarios[${scenario.id}].legacy.nodes[$index]',
          scope: 'legacy',
          parentId: scenario.id,
          sourceKind: 'scenarioNode',
        );
        final binding = node.binding;
        final prefix = 'scenarios[${scenario.id}].legacy.nodes[$index].binding';
        final mapId = binding.mapId?.trim();
        final payloadCondition = node.payload.condition;
        if (payloadCondition != null) {
          _collectScriptCondition(
            payloadCondition,
            owner,
            'scenarios[${scenario.id}].legacy.nodes[$index].payload.condition',
            mapId: mapId,
          );
        }
        final actionKind = node.payload.actionKind?.trim();
        final payloadStepId = node.payload.params['stepId']?.trim();
        if (actionKind == 'completeStep' &&
            payloadStepId != null &&
            payloadStepId.isNotEmpty) {
          _usage(
            target: NarrativeDependencyKey(
              NarrativeDependencyTargetKind.step,
              payloadStepId,
            ),
            owner: owner,
            path:
                'scenarios[${scenario.id}].legacy.nodes[$index].payload.params.stepId',
            criticality: NarrativeDependencyCriticality.runtimeBlocking,
          );
        }
        if (mapId != null && mapId.isNotEmpty) {
          _usage(
            target: _mapKey(mapId),
            owner: owner,
            path: '$prefix.mapId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        _collectDialogueRef(binding.dialogueId, owner, '$prefix.dialogueId');
        final flagName = binding.flagName?.trim();
        if (flagName != null && flagName.isNotEmpty) {
          _collectLegacyFactRef(flagName, owner, '$prefix.flagName');
        }
        final entityId = binding.entityId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            entityId != null &&
            entityId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'entity', entityId),
            owner: owner,
            path: '$prefix.entityId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final eventId = binding.eventId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            eventId != null &&
            eventId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'event', eventId),
            owner: owner,
            path: '$prefix.eventId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final triggerId = binding.triggerId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            triggerId != null &&
            triggerId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'trigger', triggerId),
            owner: owner,
            path: '$prefix.triggerId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
        final warpId = binding.warpId?.trim();
        if (mapId != null &&
            mapId.isNotEmpty &&
            warpId != null &&
            warpId.isNotEmpty) {
          _usage(
            target: _mapSourceChildKey(mapId, 'warp', warpId),
            owner: owner,
            path: '$prefix.warpId',
            criticality: NarrativeDependencyCriticality.authoringWarning,
          );
        }
      }
    }
  }

  void _collectCycleIssues() {
    final eventIds =
        project.eventRegistry?.records.map((record) => record.id).toSet() ??
            <String>{};
    final eventEdges = _eventCycleEdges
        .where(
          (edge) => eventIds.contains(edge.$1) && eventIds.contains(edge.$2),
        )
        .toList();
    for (final eventId in _cyclicNodes(eventIds, eventEdges)) {
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.forbiddenCycle,
          target: _eventKey(eventId),
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message:
              'Event V2 "$eventId" belongs to a consumed-event dependency cycle.',
        ),
      );
    }

    for (final scene in project.scenes) {
      final nodeIds = scene.graph.nodes.map((node) => node.id).toSet();
      final edges = <(String, String)>[
        for (final edge in scene.graph.edges)
          if (nodeIds.contains(edge.fromNodeId) &&
              nodeIds.contains(edge.toNodeId))
            (edge.fromNodeId, edge.toNodeId),
      ];
      if (_cyclicNodes(nodeIds, edges).isEmpty) continue;
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.forbiddenCycle,
          target: NarrativeDependencyKey(
            NarrativeDependencyTargetKind.scene,
            scene.id,
          ),
          criticality: NarrativeDependencyCriticality.authoringWarning,
          message: 'Scene "${scene.id}" contains a graph cycle.',
        ),
      );
    }
  }

  void _collectSceneNode(
    NarrativeDependencyKey owner,
    String sceneId,
    SceneNode node,
    int index,
  ) {
    final path = 'scenes[$sceneId].graph.nodes[$index].payload';
    final payload = node.payload;
    if (payload is SceneYarnDialoguePayload) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.dialogue,
          payload.dialogueId,
        ),
        owner: owner,
        path: '$path.dialogueId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (payload is SceneCinematicPayload) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          payload.cinematicId,
        ),
        owner: owner,
        path: '$path.cinematicId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (payload is SceneConditionPayload) {
      final source = payload.conditionSource;
      if (source != null) {
        _collectSceneCondition(owner, source, '$path.conditionSource');
      }
    } else if (payload is SceneActionPayload) {
      final consequence = payload.consequence;
      if (consequence != null) {
        _collectSceneConsequence(owner, consequence, '$path.consequence');
      }
    }
  }

  void _collectSceneCondition(
    NarrativeDependencyKey owner,
    SceneConditionSource source,
    String path,
  ) {
    if (source.sourceKind == SceneConditionSourceKind.factLikeStoryFlag) {
      _collectLegacyFactRef(source.sourceId, owner, '$path.sourceId');
      return;
    }
    final target = switch (source.sourceKind) {
      SceneConditionSourceKind.fact => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          source.sourceId,
        ),
      SceneConditionSourceKind.storyStepCompletion ||
      SceneConditionSourceKind.storyStepActive =>
        NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          source.sourceId,
        ),
      SceneConditionSourceKind.consumedEvent =>
        NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyMapEvent',
          sourceId: source.sourceId,
        ),
      SceneConditionSourceKind.dialogueOutcome => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.dialogue,
          source.sourceId,
        ),
      SceneConditionSourceKind.worldState => NarrativeDependencyKey(
          NarrativeDependencyTargetKind.worldRule,
          source.sourceId,
        ),
      _ => NarrativeDependencyKey.synthetic(
          sourceKind: 'legacyCondition.${source.sourceKind.name}',
          sourceId: source.sourceId,
        ),
    };
    final usesCanonicalResolution =
        source.sourceKind == SceneConditionSourceKind.fact ||
            source.sourceKind == SceneConditionSourceKind.storyStepCompletion ||
            source.sourceKind == SceneConditionSourceKind.storyStepActive ||
            source.sourceKind == SceneConditionSourceKind.consumedEvent ||
            source.sourceKind == SceneConditionSourceKind.dialogueOutcome ||
            source.sourceKind == SceneConditionSourceKind.worldState;
    _usage(
      target: target,
      owner: owner,
      path: '$path.sourceId',
      criticality: NarrativeDependencyCriticality.runtimeBlocking,
      resolution: usesCanonicalResolution
          ? null
          : NarrativeDependencyResolution.legacyExternal,
    );
  }

  void _collectSceneConsequence(
    NarrativeDependencyKey owner,
    SceneConsequence consequence,
    String path,
  ) {
    if (consequence is SceneSetFactConsequence) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.fact,
          consequence.factId,
        ),
        owner: owner,
        path: '$path.factId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (consequence is SceneMarkEventConsumedConsequence) {
      _usage(
        target: _mapKey(consequence.mapId),
        owner: owner,
        path: '$path.mapId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
      _usage(
        target: _mapSourceChildKey(
          consequence.mapId,
          'event',
          consequence.eventId,
        ),
        owner: owner,
        path: '$path.eventId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    } else if (consequence is SceneCompleteStoryStepConsequence) {
      _usage(
        target: NarrativeDependencyKey(
          NarrativeDependencyTargetKind.step,
          consequence.stepId,
        ),
        owner: owner,
        path: '$path.stepId',
        criticality: NarrativeDependencyCriticality.runtimeBlocking,
      );
    }
  }

  NarrativeDependencyIndex _resolve() {
    final definitionsByKey =
        <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{};
    for (final definition in _definitions) {
      definitionsByKey.putIfAbsent(definition.key, () => []).add(definition);
    }
    for (final entry in definitionsByKey.entries) {
      if (entry.value.length < 2) continue;
      _issues.add(
        NarrativeDependencyIssue(
          kind: NarrativeDependencyIssueKind.duplicateId,
          target: entry.key,
          criticality: NarrativeDependencyCriticality.runtimeBlocking,
          message:
              '${entry.value.length} definitions share ${entry.key.kind.name} ID "${entry.key.id}".',
        ),
      );
    }

    final declaredMapIds = project.maps.map((entry) => entry.id).toSet();
    final loadedMapIds = maps.map((map) => map.id).toSet();
    final hasUnavailableDeclaredMaps =
        declaredMapIds.difference(loadedMapIds).isNotEmpty;
    final resolvedUsages = <NarrativeDependencyUsage>[];
    for (final usage in _usages) {
      NarrativeDependencyResolution resolution;
      if (usage.resolution == NarrativeDependencyResolution.legacyExternal ||
          usage.resolution == NarrativeDependencyResolution.ambiguous) {
        resolution = usage.resolution;
      } else {
        final definitionCount = definitionsByKey[usage.target]?.length ?? 0;
        final physicalMapId = usage.target.physicalMapId;
        final isGlobalLegacyMapEvent =
            usage.target.kind == NarrativeDependencyTargetKind.sourceMap &&
                usage.target.scope == 'synthetic' &&
                usage.target.sourceKind == 'legacyMapEvent';
        if (definitionCount > 1) {
          resolution = NarrativeDependencyResolution.ambiguous;
        } else if (isGlobalLegacyMapEvent &&
            definitionCount == 0 &&
            hasUnavailableDeclaredMaps) {
          resolution = NarrativeDependencyResolution.unavailable;
        } else if (physicalMapId != null &&
            declaredMapIds.contains(physicalMapId) &&
            !loadedMapIds.contains(physicalMapId)) {
          resolution = NarrativeDependencyResolution.unavailable;
        } else if (definitionCount == 1) {
          resolution = NarrativeDependencyResolution.resolved;
        } else {
          resolution = NarrativeDependencyResolution.missing;
        }
      }
      final resolved = usage.withResolution(resolution);
      resolvedUsages.add(resolved);
      if (resolution == NarrativeDependencyResolution.missing ||
          resolution == NarrativeDependencyResolution.ambiguous ||
          resolution == NarrativeDependencyResolution.unavailable) {
        final issueKind = switch (resolution) {
          NarrativeDependencyResolution.missing =>
            NarrativeDependencyIssueKind.missingReference,
          NarrativeDependencyResolution.ambiguous =>
            NarrativeDependencyIssueKind.ambiguousReference,
          NarrativeDependencyResolution.unavailable =>
            NarrativeDependencyIssueKind.unavailableReference,
          _ => throw StateError('Unsupported dependency issue resolution'),
        };
        _issues.add(
          NarrativeDependencyIssue(
            kind: issueKind,
            target: usage.target,
            owner: usage.owner,
            path: usage.path,
            criticality: usage.criticality,
            message: switch (resolution) {
              NarrativeDependencyResolution.missing =>
                '${usage.target} is missing.',
              NarrativeDependencyResolution.ambiguous =>
                '${usage.target} resolves to multiple definitions.',
              NarrativeDependencyResolution.unavailable =>
                '${usage.target} is declared but its map data is unavailable.',
              _ => throw StateError('Unsupported dependency issue resolution'),
            },
          ),
        );
      }
    }
    return NarrativeDependencyIndex(
      definitions: _definitions,
      usages: resolvedUsages,
      issues: _issues,
    );
  }

  NarrativeDependencyKey _definition(
    NarrativeDependencyTargetKind kind,
    String id,
    String label, {
    NarrativeDependencyKey? owner,
    String? path,
    String? scope,
    String? parentId,
    String? sourceKind,
    String? navigationRootId,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final key = NarrativeDependencyKey(
      kind,
      id,
      scope: scope,
      parentId: parentId,
      sourceKind: sourceKind,
    );
    _definitions.add(
      NarrativeDependencyDefinition(
        key: key,
        label: label,
        owner: owner,
        path: path,
        navigationIntent: NarrativeDependencyNavigationIntent.fromKey(
          key,
          parentId: owner?.id,
          rootId: navigationRootId,
          context: path,
        ),
        metadata: metadata,
      ),
    );
    return key;
  }

  void _usage({
    required NarrativeDependencyKey target,
    required NarrativeDependencyKey owner,
    required String path,
    required NarrativeDependencyCriticality criticality,
    NarrativeDependencyResolution? resolution,
  }) {
    _usages.add(
      NarrativeDependencyUsage(
        target: target,
        owner: owner,
        path: path,
        criticality: criticality,
        resolution: resolution ?? NarrativeDependencyResolution.resolved,
        navigationIntent: NarrativeDependencyNavigationIntent.fromKey(
          owner,
          context: path,
        ),
      ),
    );
  }
}

const _newGameOwner = NarrativeDependencyKey.projectNewGame();

NarrativeDependencyKey _eventKey(String id) =>
    NarrativeDependencyKey.eventV2(id);

NarrativeDependencyKey _mapKey(String mapId) =>
    NarrativeDependencyKey.map(mapId);

NarrativeDependencyKey _mapSourceChildKey(
  String mapId,
  String kind,
  String id,
) =>
    NarrativeDependencyKey.mapSource(
      mapId: mapId,
      sourceKind: kind,
      sourceId: id,
    );

const _physicalMapScope = 'map';

/// Iterative Kosaraju traversal. It deliberately avoids recursive DFS so a
/// large authoring project cannot overflow the VM stack while being indexed.
Set<T> _cyclicNodes<T>(
  Iterable<T> nodes,
  Iterable<(T, T)> edges,
) {
  final adjacency = <T, List<T>>{};
  final reverse = <T, List<T>>{};
  for (final node in nodes) {
    adjacency.putIfAbsent(node, () => <T>[]);
    reverse.putIfAbsent(node, () => <T>[]);
  }
  for (final (from, to) in edges) {
    adjacency.putIfAbsent(from, () => <T>[]).add(to);
    adjacency.putIfAbsent(to, () => <T>[]);
    reverse.putIfAbsent(to, () => <T>[]).add(from);
    reverse.putIfAbsent(from, () => <T>[]);
  }

  final visited = <T>{};
  final postorder = <T>[];
  for (final start in adjacency.keys) {
    if (visited.contains(start)) continue;
    final stack = <(T, bool)>[(start, false)];
    while (stack.isNotEmpty) {
      final (node, expanded) = stack.removeLast();
      if (expanded) {
        postorder.add(node);
        continue;
      }
      if (!visited.add(node)) continue;
      stack.add((node, true));
      final targets = adjacency[node]!;
      for (var index = targets.length - 1; index >= 0; index--) {
        final target = targets[index];
        if (!visited.contains(target)) stack.add((target, false));
      }
    }
  }

  final assigned = <T>{};
  final cyclic = <T>{};
  for (var index = postorder.length - 1; index >= 0; index--) {
    final start = postorder[index];
    if (!assigned.add(start)) continue;
    final component = <T>[];
    final stack = <T>[start];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      component.add(node);
      for (final target in reverse[node]!) {
        if (assigned.add(target)) stack.add(target);
      }
    }
    if (component.length > 1 ||
        adjacency[component.single]!.contains(component.single)) {
      cyclic.addAll(component);
    }
  }
  return cyclic;
}

Map<NarrativeDependencyKey, List<NarrativeDependencyDefinition>>
    _groupDefinitionsByKey(
  List<NarrativeDependencyDefinition> definitions,
) {
  final grouped =
      <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{};
  for (final definition in definitions) {
    grouped.putIfAbsent(definition.key, () => []).add(definition);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyDefinition>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyDefinition>.unmodifiable(entry.value),
  };
}

Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>>
    _groupUsagesByTarget(
  List<NarrativeDependencyUsage> usages,
) {
  final grouped = <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.target, () => []).add(usage);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyUsage>.unmodifiable(entry.value),
  };
}

Map<NarrativeDependencyKey, List<NarrativeDependencyUsage>> _groupUsagesByOwner(
  List<NarrativeDependencyUsage> usages,
) {
  final grouped = <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{};
  for (final usage in usages) {
    grouped.putIfAbsent(usage.owner, () => []).add(usage);
  }
  return <NarrativeDependencyKey, List<NarrativeDependencyUsage>>{
    for (final entry in grouped.entries)
      entry.key: List<NarrativeDependencyUsage>.unmodifiable(entry.value),
  };
}

int _compareKeys(NarrativeDependencyKey left, NarrativeDependencyKey right) {
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final id = left.id.compareTo(right.id);
  if (id != 0) return id;
  final scope = (left.scope ?? '').compareTo(right.scope ?? '');
  if (scope != 0) return scope;
  final parentId = (left.parentId ?? '').compareTo(right.parentId ?? '');
  if (parentId != 0) return parentId;
  return (left.sourceKind ?? '').compareTo(right.sourceKind ?? '');
}

int _compareDefinitions(
  NarrativeDependencyDefinition left,
  NarrativeDependencyDefinition right,
) {
  final key = _compareKeys(left.key, right.key);
  if (key != 0) return key;
  final owner = _compareOptionalKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = (left.path ?? '').compareTo(right.path ?? '');
  if (path != 0) return path;
  final label = left.label.compareTo(right.label);
  if (label != 0) return label;
  final navigation = _compareOptionalNavigationIntents(
    left.navigationIntent,
    right.navigationIntent,
  );
  if (navigation != 0) return navigation;
  return _compareStringMaps(left.metadata, right.metadata);
}

int _compareUsages(
  NarrativeDependencyUsage left,
  NarrativeDependencyUsage right,
) {
  final target = _compareKeys(left.target, right.target);
  if (target != 0) return target;
  final owner = _compareKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = left.path.compareTo(right.path);
  if (path != 0) return path;
  final criticality = left.criticality.index.compareTo(right.criticality.index);
  if (criticality != 0) return criticality;
  final resolution = left.resolution.index.compareTo(right.resolution.index);
  if (resolution != 0) return resolution;
  return _compareOptionalNavigationIntents(
    left.navigationIntent,
    right.navigationIntent,
  );
}

int _compareIssues(
  NarrativeDependencyIssue left,
  NarrativeDependencyIssue right,
) {
  final target = _compareKeys(left.target, right.target);
  if (target != 0) return target;
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final owner = _compareOptionalKeys(left.owner, right.owner);
  if (owner != 0) return owner;
  final path = (left.path ?? '').compareTo(right.path ?? '');
  if (path != 0) return path;
  final criticality = left.criticality.index.compareTo(right.criticality.index);
  if (criticality != 0) return criticality;
  return left.message.compareTo(right.message);
}

int _compareOptionalNavigationIntents(
  NarrativeDependencyNavigationIntent? left,
  NarrativeDependencyNavigationIntent? right,
) {
  if (left == null) return right == null ? 0 : -1;
  if (right == null) return 1;
  final kind = left.kind.index.compareTo(right.kind.index);
  if (kind != 0) return kind;
  final assetId = left.assetId.compareTo(right.assetId);
  if (assetId != 0) return assetId;
  final parentId = (left.parentId ?? '').compareTo(right.parentId ?? '');
  if (parentId != 0) return parentId;
  final rootId = (left.rootId ?? '').compareTo(right.rootId ?? '');
  if (rootId != 0) return rootId;
  final scope = (left.scope ?? '').compareTo(right.scope ?? '');
  if (scope != 0) return scope;
  final sourceKind = (left.sourceKind ?? '').compareTo(right.sourceKind ?? '');
  if (sourceKind != 0) return sourceKind;
  final mapId = (left.mapId ?? '').compareTo(right.mapId ?? '');
  if (mapId != 0) return mapId;
  return (left.context ?? '').compareTo(right.context ?? '');
}

int _compareStringMaps(Map<String, String> left, Map<String, String> right) {
  final leftEntries = left.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final rightEntries = right.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final length = leftEntries.length.compareTo(rightEntries.length);
  if (length != 0) return length;
  for (var index = 0; index < leftEntries.length; index++) {
    final key = leftEntries[index].key.compareTo(rightEntries[index].key);
    if (key != 0) return key;
    final value = leftEntries[index].value.compareTo(rightEntries[index].value);
    if (value != 0) return value;
  }
  return 0;
}

int _compareOptionalKeys(
  NarrativeDependencyKey? left,
  NarrativeDependencyKey? right,
) {
  if (left == null) return right == null ? 0 : -1;
  if (right == null) return 1;
  return _compareKeys(left, right);
}
