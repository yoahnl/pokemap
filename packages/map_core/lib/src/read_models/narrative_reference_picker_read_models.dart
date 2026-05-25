import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import '../models/scenario_asset.dart';
import '../models/script_conditions.dart';

const String _actionEmitOutcome = 'emitoutcome';
const String _actionSourceOutcome = 'sourceoutcome';
const String _actionStartTrainerBattle = 'starttrainerbattle';
const String _outcomeIdParam = 'outcomeId';
const String _battleIdParam = 'battleId';
const String _stepStudioDocumentMetadataKey = 'authoring.stepStudioDocument';
const String _legacyStepIdMetadataKey = 'step.id';
const String _legacyStepNameMetadataKey = 'step.name';
const String _legacyStepDescriptionMetadataKey = 'step.description';
const String _legacyStepCutsceneIdsMetadataKey = 'step.cutsceneIds';

enum NarrativeBattleOutcomeKind {
  victory,
  defeat,
}

enum NarrativeStoryStepPickerSource {
  stepStudio,
  legacyMetadata,
}

enum NarrativeEventSourceKind {
  mapEnter,
  triggerEnter,
  entityInteract,
  outcomeReceived,
}

enum NarrativePredicateReferenceKind {
  storyFlag,
  storyStep,
  cutscene,
  scenarioOutcome,
  battleOutcome,
}

@immutable
final class NarrativeScenarioPickerOption {
  NarrativeScenarioPickerOption({
    required this.scenarioId,
    required this.humanLabel,
    required this.description,
    required this.scope,
    required this.entryNodeId,
    required List<String> declaredOutcomeIds,
    required this.nodeCount,
    required this.edgeCount,
    required this.debugTechnicalLabel,
  }) : declaredOutcomeIds = List<String>.unmodifiable(declaredOutcomeIds);

  final String scenarioId;
  final String humanLabel;
  final String description;
  final ScenarioScope scope;
  final String entryNodeId;
  final List<String> declaredOutcomeIds;
  final int nodeCount;
  final int edgeCount;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeScenarioPickerOption &&
          other.scenarioId == scenarioId &&
          other.humanLabel == humanLabel &&
          other.description == description &&
          other.scope == scope &&
          other.entryNodeId == entryNodeId &&
          _listEquals(other.declaredOutcomeIds, declaredOutcomeIds) &&
          other.nodeCount == nodeCount &&
          other.edgeCount == edgeCount &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        scenarioId,
        humanLabel,
        description,
        scope,
        entryNodeId,
        Object.hashAll(declaredOutcomeIds),
        nodeCount,
        edgeCount,
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeStoryStepPickerOption {
  NarrativeStoryStepPickerOption({
    required this.stepId,
    required this.humanLabel,
    required this.description,
    required this.sourceScenarioId,
    required this.sourceScenarioLabel,
    required this.sourceKind,
    required this.order,
    required List<String> linkedCutsceneIds,
    required List<String> expectedOutcomeIds,
    required List<String> emittedOutcomeIds,
    required this.debugTechnicalLabel,
  })  : linkedCutsceneIds = List<String>.unmodifiable(linkedCutsceneIds),
        expectedOutcomeIds = List<String>.unmodifiable(expectedOutcomeIds),
        emittedOutcomeIds = List<String>.unmodifiable(emittedOutcomeIds);

  final String stepId;
  final String humanLabel;
  final String description;
  final String sourceScenarioId;
  final String sourceScenarioLabel;
  final NarrativeStoryStepPickerSource sourceKind;
  final int order;
  final List<String> linkedCutsceneIds;
  final List<String> expectedOutcomeIds;
  final List<String> emittedOutcomeIds;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStoryStepPickerOption &&
          other.stepId == stepId &&
          other.humanLabel == humanLabel &&
          other.description == description &&
          other.sourceScenarioId == sourceScenarioId &&
          other.sourceScenarioLabel == sourceScenarioLabel &&
          other.sourceKind == sourceKind &&
          other.order == order &&
          _listEquals(other.linkedCutsceneIds, linkedCutsceneIds) &&
          _listEquals(other.expectedOutcomeIds, expectedOutcomeIds) &&
          _listEquals(other.emittedOutcomeIds, emittedOutcomeIds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        stepId,
        humanLabel,
        description,
        sourceScenarioId,
        sourceScenarioLabel,
        sourceKind,
        order,
        Object.hashAll(linkedCutsceneIds),
        Object.hashAll(expectedOutcomeIds),
        Object.hashAll(emittedOutcomeIds),
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeEventSourcePickerOption {
  const NarrativeEventSourcePickerOption({
    required this.sourceId,
    required this.sourceKind,
    required this.humanLabel,
    required this.mapId,
    required this.mapLabel,
    required this.entityId,
    required this.entityLabel,
    required this.triggerId,
    required this.triggerLabel,
    required this.outcomeId,
    required this.debugTechnicalLabel,
  });

  final String sourceId;
  final NarrativeEventSourceKind sourceKind;
  final String humanLabel;
  final String mapId;
  final String mapLabel;
  final String entityId;
  final String entityLabel;
  final String triggerId;
  final String triggerLabel;
  final String outcomeId;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeEventSourcePickerOption &&
          other.sourceId == sourceId &&
          other.sourceKind == sourceKind &&
          other.humanLabel == humanLabel &&
          other.mapId == mapId &&
          other.mapLabel == mapLabel &&
          other.entityId == entityId &&
          other.entityLabel == entityLabel &&
          other.triggerId == triggerId &&
          other.triggerLabel == triggerLabel &&
          other.outcomeId == outcomeId &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        sourceId,
        sourceKind,
        humanLabel,
        mapId,
        mapLabel,
        entityId,
        entityLabel,
        triggerId,
        triggerLabel,
        outcomeId,
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativePredicateReferencePickerOption {
  NarrativePredicateReferencePickerOption({
    required this.referenceId,
    required this.referenceKind,
    required this.humanLabel,
    required List<String> sourceScenarioIds,
    required this.debugTechnicalLabel,
  }) : sourceScenarioIds = List<String>.unmodifiable(sourceScenarioIds);

  final String referenceId;
  final NarrativePredicateReferenceKind referenceKind;
  final String humanLabel;
  final List<String> sourceScenarioIds;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativePredicateReferencePickerOption &&
          other.referenceId == referenceId &&
          other.referenceKind == referenceKind &&
          other.humanLabel == humanLabel &&
          _listEquals(other.sourceScenarioIds, sourceScenarioIds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        referenceId,
        referenceKind,
        humanLabel,
        Object.hashAll(sourceScenarioIds),
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeOutcomePickerOption {
  NarrativeOutcomePickerOption({
    required this.outcomeId,
    required this.humanLabel,
    required List<String> declaredByScenarioIds,
    required List<String> emittedByScenarioIds,
    required List<String> consumedByScenarioIds,
    required this.debugTechnicalLabel,
  })  : declaredByScenarioIds =
            List<String>.unmodifiable(declaredByScenarioIds),
        emittedByScenarioIds = List<String>.unmodifiable(emittedByScenarioIds),
        consumedByScenarioIds =
            List<String>.unmodifiable(consumedByScenarioIds);

  final String outcomeId;
  final String humanLabel;
  final List<String> declaredByScenarioIds;
  final List<String> emittedByScenarioIds;
  final List<String> consumedByScenarioIds;
  final String debugTechnicalLabel;

  bool get isDeclared => declaredByScenarioIds.isNotEmpty;

  bool get isEmitted => emittedByScenarioIds.isNotEmpty;

  bool get isConsumed => consumedByScenarioIds.isNotEmpty;

  bool get isOrphan => !isDeclared || !isEmitted || !isConsumed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeOutcomePickerOption &&
          other.outcomeId == outcomeId &&
          other.humanLabel == humanLabel &&
          _listEquals(other.declaredByScenarioIds, declaredByScenarioIds) &&
          _listEquals(other.emittedByScenarioIds, emittedByScenarioIds) &&
          _listEquals(other.consumedByScenarioIds, consumedByScenarioIds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        outcomeId,
        humanLabel,
        Object.hashAll(declaredByScenarioIds),
        Object.hashAll(emittedByScenarioIds),
        Object.hashAll(consumedByScenarioIds),
        debugTechnicalLabel,
      );
}

@immutable
final class NarrativeBattleReferencePickerOption {
  NarrativeBattleReferencePickerOption({
    required this.battleReferenceId,
    required this.battleId,
    required this.humanLabel,
    required this.sourceScenarioId,
    required this.sourceNodeId,
    required this.trainerId,
    required this.trainerLabel,
    required this.trainerClass,
    required this.npcEntityId,
    required this.isTrainerKnown,
    required List<NarrativeBattleOutcomeKind> supportedOutcomeKinds,
    required this.debugTechnicalLabel,
  }) : supportedOutcomeKinds = List<NarrativeBattleOutcomeKind>.unmodifiable(
          supportedOutcomeKinds,
        );

  final String battleReferenceId;
  final String battleId;
  final String humanLabel;
  final String sourceScenarioId;
  final String sourceNodeId;
  final String trainerId;
  final String? trainerLabel;
  final String? trainerClass;
  final String npcEntityId;
  final bool isTrainerKnown;
  final List<NarrativeBattleOutcomeKind> supportedOutcomeKinds;
  final String debugTechnicalLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeBattleReferencePickerOption &&
          other.battleReferenceId == battleReferenceId &&
          other.battleId == battleId &&
          other.humanLabel == humanLabel &&
          other.sourceScenarioId == sourceScenarioId &&
          other.sourceNodeId == sourceNodeId &&
          other.trainerId == trainerId &&
          other.trainerLabel == trainerLabel &&
          other.trainerClass == trainerClass &&
          other.npcEntityId == npcEntityId &&
          other.isTrainerKnown == isTrainerKnown &&
          _listEquals(other.supportedOutcomeKinds, supportedOutcomeKinds) &&
          other.debugTechnicalLabel == debugTechnicalLabel;

  @override
  int get hashCode => Object.hash(
        battleReferenceId,
        battleId,
        humanLabel,
        sourceScenarioId,
        sourceNodeId,
        trainerId,
        trainerLabel,
        trainerClass,
        npcEntityId,
        isTrainerKnown,
        Object.hashAll(supportedOutcomeKinds),
        debugTechnicalLabel,
      );
}

List<NarrativeScenarioPickerOption> buildNarrativeScenarioPickerOptions(
  ProjectManifest manifest,
) {
  final options = manifest.scenarios.map((scenario) {
    final scenarioId = scenario.id.trim();
    return NarrativeScenarioPickerOption(
      scenarioId: scenarioId,
      humanLabel: _labelOrId(scenario.name, scenarioId),
      description: scenario.description.trim(),
      scope: scenario.scope,
      entryNodeId: scenario.entryNodeId.trim(),
      declaredOutcomeIds: _dedupeAndSort(scenario.declaredOutcomes),
      nodeCount: scenario.nodes.length,
      edgeCount: scenario.edges.length,
      debugTechnicalLabel: scenarioId,
    );
  }).toList(growable: false);

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.scenarioId));
  return List<NarrativeScenarioPickerOption>.unmodifiable(options);
}

List<NarrativeOutcomePickerOption> buildNarrativeOutcomePickerOptions(
  ProjectManifest manifest,
) {
  final byOutcomeId = <String, _MutableOutcomePickerOption>{};

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final outcomeId in _dedupeAndSort(scenario.declaredOutcomes)) {
      byOutcomeId
          .putIfAbsent(outcomeId, () => _MutableOutcomePickerOption(outcomeId))
          .declaredByScenarioIds
          .add(scenarioId);
    }

    for (final node in scenario.nodes) {
      final actionKind = _normalizedActionKind(node);
      if (actionKind != _actionEmitOutcome &&
          actionKind != _actionSourceOutcome) {
        continue;
      }
      for (final outcomeId in _outcomeIdsForNode(node)) {
        final option = byOutcomeId.putIfAbsent(
          outcomeId,
          () => _MutableOutcomePickerOption(outcomeId),
        );
        if (actionKind == _actionEmitOutcome) {
          option.emittedByScenarioIds.add(scenarioId);
        } else {
          option.consumedByScenarioIds.add(scenarioId);
        }
      }
    }
  }

  final options = byOutcomeId.values.map((entry) {
    return NarrativeOutcomePickerOption(
      outcomeId: entry.outcomeId,
      humanLabel: _humanizeTechnicalId(entry.outcomeId),
      declaredByScenarioIds: _dedupeAndSort(entry.declaredByScenarioIds),
      emittedByScenarioIds: _dedupeAndSort(entry.emittedByScenarioIds),
      consumedByScenarioIds: _dedupeAndSort(entry.consumedByScenarioIds),
      debugTechnicalLabel: entry.outcomeId,
    );
  }).toList(growable: false);

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.outcomeId));
  return List<NarrativeOutcomePickerOption>.unmodifiable(options);
}

List<NarrativeStoryStepPickerOption> buildNarrativeStoryStepPickerOptions(
  ProjectManifest manifest,
) {
  final byStepId = <String, NarrativeStoryStepPickerOption>{};

  for (final scenario in manifest.scenarios) {
    if (scenario.scope != ScenarioScope.globalStory) {
      continue;
    }
    for (final option in _storyStepOptionsForScenario(scenario)) {
      byStepId.putIfAbsent(option.stepId, () => option);
    }
  }

  final options = byStepId.values.toList(growable: false);
  options.sort((a, b) {
    final byScenario = _compareStringsCaseInsensitive(
        a.sourceScenarioLabel, b.sourceScenarioLabel);
    if (byScenario != 0) {
      return byScenario;
    }
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) {
      return byOrder;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.stepId, b.stepId);
  });
  return List<NarrativeStoryStepPickerOption>.unmodifiable(options);
}

List<NarrativeEventSourcePickerOption> buildNarrativeEventSourcePickerOptions(
  ProjectManifest manifest, {
  Iterable<MapData> maps = const [],
}) {
  final mapEntriesById = <String, ProjectMapEntry>{
    for (final map in manifest.maps)
      if (map.id.trim().isNotEmpty) map.id.trim(): map,
  };
  final optionsBySourceId = <String, NarrativeEventSourcePickerOption>{};

  void add(NarrativeEventSourcePickerOption option) {
    optionsBySourceId.putIfAbsent(option.sourceId, () => option);
  }

  for (final mapEntry in manifest.maps) {
    final mapId = mapEntry.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    final mapLabel = _labelOrId(mapEntry.name, mapId);
    add(
      NarrativeEventSourcePickerOption(
        sourceId: 'mapEnter:$mapId',
        sourceKind: NarrativeEventSourceKind.mapEnter,
        humanLabel: 'Map enter: $mapLabel',
        mapId: mapId,
        mapLabel: mapLabel,
        entityId: '',
        entityLabel: '',
        triggerId: '',
        triggerLabel: '',
        outcomeId: '',
        debugTechnicalLabel: 'sourceMapEnter:$mapId',
      ),
    );
  }

  for (final map in maps) {
    final mapId = map.id.trim();
    if (mapId.isEmpty) {
      continue;
    }
    final mapLabel = _mapLabelFor(mapId, map.name, mapEntriesById);

    for (final trigger in map.triggers) {
      final triggerId = trigger.id.trim();
      if (triggerId.isEmpty) {
        continue;
      }
      final triggerLabel = _labelOrId(trigger.name, triggerId);
      add(
        NarrativeEventSourcePickerOption(
          sourceId: 'triggerEnter:$mapId:$triggerId',
          sourceKind: NarrativeEventSourceKind.triggerEnter,
          humanLabel: 'Trigger enter: $triggerLabel ($mapLabel)',
          mapId: mapId,
          mapLabel: mapLabel,
          entityId: '',
          entityLabel: '',
          triggerId: triggerId,
          triggerLabel: triggerLabel,
          outcomeId: '',
          debugTechnicalLabel: 'sourceTriggerEnter:$mapId:$triggerId',
        ),
      );
    }

    for (final entity in map.entities) {
      final entityId = entity.id.trim();
      if (entityId.isEmpty) {
        continue;
      }
      final entityLabel = _labelOrId(entity.inspectorHeadline, entityId);
      add(
        NarrativeEventSourcePickerOption(
          sourceId: 'entityInteract:$mapId:$entityId',
          sourceKind: NarrativeEventSourceKind.entityInteract,
          humanLabel: 'Entity interact: $entityLabel ($mapLabel)',
          mapId: mapId,
          mapLabel: mapLabel,
          entityId: entityId,
          entityLabel: entityLabel,
          triggerId: '',
          triggerLabel: '',
          outcomeId: '',
          debugTechnicalLabel: 'sourceEntityInteract:$mapId:$entityId',
        ),
      );
    }
  }

  for (final outcome in buildNarrativeOutcomePickerOptions(manifest)) {
    final outcomeId = outcome.outcomeId.trim();
    if (outcomeId.isEmpty) {
      continue;
    }
    add(
      NarrativeEventSourcePickerOption(
        sourceId: 'outcomeReceived:$outcomeId',
        sourceKind: NarrativeEventSourceKind.outcomeReceived,
        humanLabel: 'Outcome received: ${outcome.humanLabel}',
        mapId: '',
        mapLabel: '',
        entityId: '',
        entityLabel: '',
        triggerId: '',
        triggerLabel: '',
        outcomeId: outcomeId,
        debugTechnicalLabel: 'sourceOutcome:$outcomeId',
      ),
    );
  }

  final options = optionsBySourceId.values.toList(growable: false);
  options.sort((a, b) {
    final byKind = a.sourceKind.index.compareTo(b.sourceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.sourceId, b.sourceId);
  });
  return List<NarrativeEventSourcePickerOption>.unmodifiable(options);
}

List<NarrativeBattleReferencePickerOption>
    buildNarrativeBattleReferencePickerOptions(ProjectManifest manifest) {
  final trainersById = <String, ProjectTrainerEntry>{
    for (final trainer in manifest.trainers)
      if (trainer.id.trim().isNotEmpty) trainer.id.trim(): trainer,
  };
  final options = <NarrativeBattleReferencePickerOption>[];

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final node in scenario.nodes) {
      if (_normalizedActionKind(node) != _actionStartTrainerBattle) {
        continue;
      }

      final nodeId = node.id.trim();
      final trainerId = node.binding.trainerId?.trim() ?? '';
      final trainer = trainersById[trainerId];
      final authoredBattleId = node.payload.params[_battleIdParam]?.trim();
      final battleId = _firstNonBlank([
        authoredBattleId,
        trainerId,
        '$scenarioId:$nodeId',
      ]);
      final battleReferenceId = '$scenarioId:$nodeId';

      options.add(
        NarrativeBattleReferencePickerOption(
          battleReferenceId: battleReferenceId,
          battleId: battleId,
          humanLabel: _battleHumanLabel(
            trainer: trainer,
            trainerId: trainerId,
            battleId: battleId,
            battleReferenceId: battleReferenceId,
          ),
          sourceScenarioId: scenarioId,
          sourceNodeId: nodeId,
          trainerId: trainerId,
          trainerLabel: trainer?.name.trim(),
          trainerClass: trainer?.trainerClass.trim(),
          npcEntityId: node.binding.entityId?.trim() ?? '',
          isTrainerKnown: trainer != null,
          supportedOutcomeKinds: const [
            NarrativeBattleOutcomeKind.victory,
            NarrativeBattleOutcomeKind.defeat,
          ],
          debugTechnicalLabel: '$battleReferenceId -> $battleId',
        ),
      );
    }
  }

  options.sort(_compareByLabelThen(
      (option) => option.humanLabel, (option) => option.battleReferenceId));
  return List<NarrativeBattleReferencePickerOption>.unmodifiable(options);
}

List<NarrativePredicateReferencePickerOption>
    buildNarrativePredicateReferencePickerOptions(ProjectManifest manifest) {
  final byKey = <String, _MutablePredicateReferencePickerOption>{};

  void add({
    required NarrativePredicateReferenceKind kind,
    required String referenceId,
    required String humanLabel,
    required String sourceScenarioId,
  }) {
    final id = referenceId.trim();
    if (id.isEmpty) {
      return;
    }
    final key = '${kind.name}:$id';
    byKey
        .putIfAbsent(
          key,
          () => _MutablePredicateReferencePickerOption(
            referenceId: id,
            referenceKind: kind,
            humanLabel: _labelOrId(humanLabel, id),
          ),
        )
        .addSourceScenarioId(sourceScenarioId);
  }

  for (final scenario in manifest.scenarios) {
    final scenarioId = scenario.id.trim();
    for (final flagName in _flagNamesForScenario(scenario)) {
      add(
        kind: NarrativePredicateReferenceKind.storyFlag,
        referenceId: flagName,
        humanLabel: _humanizeTechnicalId(flagName),
        sourceScenarioId: scenarioId,
      );
    }
  }

  for (final step in buildNarrativeStoryStepPickerOptions(manifest)) {
    add(
      kind: NarrativePredicateReferenceKind.storyStep,
      referenceId: step.stepId,
      humanLabel: step.humanLabel,
      sourceScenarioId: step.sourceScenarioId,
    );
  }

  for (final scenario in manifest.scenarios) {
    if (scenario.scope != ScenarioScope.localEventFlow) {
      continue;
    }
    add(
      kind: NarrativePredicateReferenceKind.cutscene,
      referenceId: scenario.id,
      humanLabel: _labelOrId(scenario.name, scenario.id),
      sourceScenarioId: scenario.id,
    );
  }

  for (final outcome in buildNarrativeOutcomePickerOptions(manifest)) {
    final outcomeId = outcome.outcomeId.trim();
    if (outcomeId.isEmpty) {
      continue;
    }
    final sourceScenarioIds = _dedupeAndSort([
      ...outcome.declaredByScenarioIds,
      ...outcome.emittedByScenarioIds,
      ...outcome.consumedByScenarioIds,
    ]);
    for (final scenarioId in sourceScenarioIds) {
      add(
        kind: NarrativePredicateReferenceKind.scenarioOutcome,
        referenceId: 'scenario.outcome.$outcomeId',
        humanLabel: 'Scenario outcome: ${outcome.humanLabel}',
        sourceScenarioId: scenarioId,
      );
    }
  }

  for (final battle in buildNarrativeBattleReferencePickerOptions(manifest)) {
    for (final outcomeKind in battle.supportedOutcomeKinds) {
      final suffix = outcomeKind.name;
      add(
        kind: NarrativePredicateReferenceKind.battleOutcome,
        referenceId: 'battle:${battle.battleId}:$suffix',
        humanLabel:
            '${_capitalizeFirst(_humanizeTechnicalId(battle.battleId))} $suffix',
        sourceScenarioId: battle.sourceScenarioId,
      );
    }
  }

  final options = byKey.values.map((entry) {
    return NarrativePredicateReferencePickerOption(
      referenceId: entry.referenceId,
      referenceKind: entry.referenceKind,
      humanLabel: entry.humanLabel,
      sourceScenarioIds: _dedupeAndSort(entry.sourceScenarioIds),
      debugTechnicalLabel: entry.referenceId,
    );
  }).toList(growable: false);

  options.sort((a, b) {
    final byKind = a.referenceKind.index.compareTo(b.referenceKind.index);
    if (byKind != 0) {
      return byKind;
    }
    final byLabel = _compareStringsCaseInsensitive(a.humanLabel, b.humanLabel);
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(a.referenceId, b.referenceId);
  });
  return List<NarrativePredicateReferencePickerOption>.unmodifiable(options);
}

class _MutableOutcomePickerOption {
  _MutableOutcomePickerOption(this.outcomeId);

  final String outcomeId;
  final List<String> declaredByScenarioIds = <String>[];
  final List<String> emittedByScenarioIds = <String>[];
  final List<String> consumedByScenarioIds = <String>[];
}

class _MutablePredicateReferencePickerOption {
  _MutablePredicateReferencePickerOption({
    required this.referenceId,
    required this.referenceKind,
    required this.humanLabel,
  });

  final String referenceId;
  final NarrativePredicateReferenceKind referenceKind;
  final String humanLabel;
  final List<String> sourceScenarioIds = <String>[];

  void addSourceScenarioId(String scenarioId) {
    final id = scenarioId.trim();
    if (id.isNotEmpty) {
      sourceScenarioIds.add(id);
    }
  }
}

Iterable<NarrativeStoryStepPickerOption> _storyStepOptionsForScenario(
  ScenarioAsset scenario,
) sync* {
  final sourceScenarioId = scenario.id.trim();
  final sourceScenarioLabel = _labelOrId(scenario.name, sourceScenarioId);
  final parsedOptions = <NarrativeStoryStepPickerOption>[];

  final rawDocument = scenario.metadata[_stepStudioDocumentMetadataKey]?.trim();
  if (rawDocument != null && rawDocument.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawDocument);
      final document = _mapValue(decoded);
      final steps = _listValue(document?['steps']);
      for (var i = 0; i < steps.length; i++) {
        final step = _mapValue(steps[i]);
        if (step == null) {
          continue;
        }
        final stepId = _stringValue(step['id']);
        if (stepId.isEmpty) {
          continue;
        }
        final activation = _mapValue(step['activation']);
        final completion = _mapValue(step['completion']);
        final cutsceneIds = <String>[
          ..._idsFromObjectList(step['cutscenes'], 'cutsceneId'),
          _stringValue(completion?['cutsceneId']),
        ];
        final expectedOutcomeIds = <String>[
          _stringValue(activation?['outcomeId']),
        ];
        final emittedOutcomeIds = <String>[
          _stringValue(completion?['outcomeId']),
          ..._idsFromObjectList(step['outcomes'], 'outcomeId'),
        ];

        parsedOptions.add(
          NarrativeStoryStepPickerOption(
            stepId: stepId,
            humanLabel: _labelOrId(_stringValue(step['name']), stepId),
            description: _stringValue(step['description']),
            sourceScenarioId: sourceScenarioId,
            sourceScenarioLabel: sourceScenarioLabel,
            sourceKind: NarrativeStoryStepPickerSource.stepStudio,
            order: _intValue(step['order'], fallback: i),
            linkedCutsceneIds: _dedupeAndSort(cutsceneIds),
            expectedOutcomeIds: _dedupeAndSort(expectedOutcomeIds),
            emittedOutcomeIds: _dedupeAndSort(emittedOutcomeIds),
            debugTechnicalLabel: '$sourceScenarioId:$stepId',
          ),
        );
      }
    } catch (_) {
      // Invalid authoring metadata remains non-fatal for picker derivation.
    }
  }

  if (parsedOptions.isNotEmpty) {
    yield* parsedOptions;
    return;
  }

  final legacyStepId =
      _stringValue(scenario.metadata[_legacyStepIdMetadataKey]);
  if (legacyStepId.isEmpty) {
    return;
  }

  yield NarrativeStoryStepPickerOption(
    stepId: legacyStepId,
    humanLabel: _labelOrId(
      scenario.metadata[_legacyStepNameMetadataKey] ?? '',
      legacyStepId,
    ),
    description: _stringValue(
      scenario.metadata[_legacyStepDescriptionMetadataKey],
    ),
    sourceScenarioId: sourceScenarioId,
    sourceScenarioLabel: sourceScenarioLabel,
    sourceKind: NarrativeStoryStepPickerSource.legacyMetadata,
    order: 0,
    linkedCutsceneIds: _dedupeAndSort(
      (scenario.metadata[_legacyStepCutsceneIdsMetadataKey] ?? '').split(','),
    ),
    expectedOutcomeIds: const [],
    emittedOutcomeIds: const [],
    debugTechnicalLabel: '$sourceScenarioId:$legacyStepId',
  );
}

List<String> _outcomeIdsForNode(ScenarioNode node) {
  final values = <String>[
    node.binding.outcomeId ?? '',
    node.payload.params[_outcomeIdParam] ?? '',
  ];
  return _dedupeAndSort(values);
}

Iterable<String> _flagNamesForScenario(ScenarioAsset scenario) sync* {
  yield* _flagNamesFromCondition(scenario.activationCondition);
  for (final node in scenario.nodes) {
    final directFlagName = node.binding.flagName?.trim() ?? '';
    if (directFlagName.isNotEmpty) {
      yield directFlagName;
    }
    yield* _flagNamesFromCondition(node.payload.condition);
  }
  yield* _flagNamesFromStepStudioMetadata(scenario);
}

Iterable<String> _flagNamesFromCondition(ScriptCondition? condition) sync* {
  if (condition == null) {
    return;
  }
  switch (condition.type) {
    case ScriptConditionType.flagIsSet:
    case ScriptConditionType.flagIsUnset:
      final flagName = condition.params[ScriptConditionParams.flagName]?.trim();
      if (flagName != null && flagName.isNotEmpty) {
        yield flagName;
      }
      break;
    default:
      break;
  }
  for (final child in condition.children) {
    yield* _flagNamesFromCondition(child);
  }
}

Iterable<String> _flagNamesFromStepStudioMetadata(
  ScenarioAsset scenario,
) sync* {
  final rawDocument = scenario.metadata[_stepStudioDocumentMetadataKey]?.trim();
  if (rawDocument == null || rawDocument.isEmpty) {
    return;
  }
  try {
    final decoded = jsonDecode(rawDocument);
    final document = _mapValue(decoded);
    final steps = _listValue(document?['steps']);
    for (final stepObject in steps) {
      final step = _mapValue(stepObject);
      if (step == null) {
        continue;
      }
      final activation = _mapValue(step['activation']);
      final completion = _mapValue(step['completion']);
      final activationFlag = _stringValue(activation?['flagName']);
      if (activationFlag.isNotEmpty) {
        yield activationFlag;
      }
      final completionFlag = _stringValue(completion?['flagName']);
      if (completionFlag.isNotEmpty) {
        yield completionFlag;
      }
    }
  } catch (_) {
    return;
  }
}

String _normalizedActionKind(ScenarioNode node) {
  return (node.payload.actionKind ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('_', '');
}

String _labelOrId(String label, String id) {
  final trimmed = label.trim();
  return trimmed.isNotEmpty ? trimmed : id;
}

String _mapLabelFor(
  String mapId,
  String mapDataName,
  Map<String, ProjectMapEntry> mapEntriesById,
) {
  final entry = mapEntriesById[mapId];
  if (entry != null) {
    return _labelOrId(entry.name, mapId);
  }
  return _labelOrId(mapDataName, mapId);
}

String _battleHumanLabel({
  required ProjectTrainerEntry? trainer,
  required String trainerId,
  required String battleId,
  required String battleReferenceId,
}) {
  if (trainer != null) {
    return _firstNonBlank([
      _joinNonBlank([trainer.trainerClass, trainer.name]),
      trainer.name,
      trainer.trainerClass,
      trainer.id,
    ]);
  }
  return _firstNonBlank([trainerId, battleId, battleReferenceId]);
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, entry) => MapEntry(key.toString(), entry));
}

List<Object?> _listValue(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.cast<Object?>();
}

List<String> _idsFromObjectList(Object? value, String key) {
  return [
    for (final entry in _listValue(value)) _stringValue(_mapValue(entry)?[key]),
  ];
}

String _stringValue(Object? value) {
  return value?.toString().trim() ?? '';
}

int _intValue(Object? value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _joinNonBlank(Iterable<String?> values) {
  return values
      .map((value) => value?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .join(' ');
}

String _firstNonBlank(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

String _humanizeTechnicalId(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  final label = trimmed
      .split(RegExp(r'[._:\-\s]+'))
      .where((part) => part.isNotEmpty)
      .join(' ');
  return label.isEmpty ? trimmed : label;
}

String _capitalizeFirst(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed[0].toUpperCase() + trimmed.substring(1);
}

List<String> _dedupeAndSort(Iterable<String> values) {
  final normalized = <String>{
    for (final value in values)
      if (value.trim().isNotEmpty) value.trim(),
  };
  final list = normalized.toList(growable: false);
  list.sort(_compareStringsCaseInsensitive);
  return list;
}

int Function(T a, T b) _compareByLabelThen<T>(
  String Function(T item) labelOf,
  String Function(T item) idOf,
) {
  return (a, b) {
    final byLabel = _compareStringsCaseInsensitive(labelOf(a), labelOf(b));
    if (byLabel != 0) {
      return byLabel;
    }
    return _compareStringsCaseInsensitive(idOf(a), idOf(b));
  };
}

int _compareStringsCaseInsensitive(String a, String b) {
  final byLower = a.toLowerCase().compareTo(b.toLowerCase());
  if (byLower != 0) {
    return byLower;
  }
  return a.compareTo(b);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
