import 'dart:collection';

import 'package:meta/meta.dart' show immutable;

import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/script_asset.dart';
import '../models/script_conditions.dart';
import '../models/items/project_item_catalog.dart';
import 'narrative_dependency_index.dart';

enum ProjectItemReferenceKind {
  newGameBag,
  newGamePartyHeld,
  newGameStarterHeld,
  sceneGive,
  sceneTake,
  sceneInventoryCondition,
  scriptGive,
  scenarioGive,
  condition,
  shopEntry,
  trainerReward,
  trainerHeld,
  mapPickup,
  machineCapability,
  evolutionRequirement,
}

@immutable
final class ProjectItemReference {
  const ProjectItemReference({
    required this.itemId,
    required this.kind,
    required this.sourceKind,
    required this.sourceId,
    required this.editablePath,
    this.blocksDeletion = true,
  });

  final String itemId;
  final ProjectItemReferenceKind kind;
  final String sourceKind;
  final String sourceId;
  final String editablePath;
  final bool blocksDeletion;

  ProjectItemReference normalized() {
    final normalizedItemId = itemId.trim();
    final normalizedSourceKind = sourceKind.trim();
    final normalizedSourceId = sourceId.trim();
    final normalizedEditablePath = editablePath.trim();
    if (normalizedItemId.isEmpty ||
        normalizedSourceKind.isEmpty ||
        normalizedSourceId.isEmpty ||
        normalizedEditablePath.isEmpty) {
      throw StateError('ProjectItemReference fields must not be empty');
    }
    return ProjectItemReference(
      itemId: normalizedItemId,
      kind: kind,
      sourceKind: normalizedSourceKind,
      sourceId: normalizedSourceId,
      editablePath: normalizedEditablePath,
      blocksDeletion: blocksDeletion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectItemReference &&
          other.itemId == itemId &&
          other.kind == kind &&
          other.sourceKind == sourceKind &&
          other.sourceId == sourceId &&
          other.editablePath == editablePath &&
          other.blocksDeletion == blocksDeletion;

  @override
  int get hashCode => Object.hash(
    itemId,
    kind,
    sourceKind,
    sourceId,
    editablePath,
    blocksDeletion,
  );
}

@immutable
final class ProjectItemReferenceIndex {
  factory ProjectItemReferenceIndex(Iterable<ProjectItemReference> references) {
    final normalized = references.map((reference) => reference.normalized());
    final sorted = normalized.toSet().toList()..sort(_compareReferences);
    final byItemId = <String, List<ProjectItemReference>>{};
    for (final reference in sorted) {
      byItemId.putIfAbsent(reference.itemId, () => []).add(reference);
    }
    return ProjectItemReferenceIndex._(
      references: sorted,
      referencesByItemId: {
        for (final entry in byItemId.entries)
          entry.key: UnmodifiableListView(entry.value),
      },
    );
  }

  ProjectItemReferenceIndex._({
    required List<ProjectItemReference> references,
    required Map<String, List<ProjectItemReference>> referencesByItemId,
  }) : references = UnmodifiableListView(references),
       _referencesByItemId = UnmodifiableMapView(referencesByItemId);

  final List<ProjectItemReference> references;
  final Map<String, List<ProjectItemReference>> _referencesByItemId;

  Set<String> get referencedItemIds =>
      Set<String>.unmodifiable(_referencesByItemId.keys);

  List<ProjectItemReference> referencesFor(String itemId) =>
      _referencesByItemId[itemId.trim()] ?? const <ProjectItemReference>[];

  List<ProjectItemReference> blockingReferencesFor(String itemId) =>
      List<ProjectItemReference>.unmodifiable(
        referencesFor(itemId).where((reference) => reference.blocksDeletion),
      );
}

ProjectItemReferenceIndex buildProjectItemReferenceIndex({
  required ProjectManifest project,
  List<MapData> maps = const <MapData>[],
  ProjectItemCatalog? itemCatalog,
  Iterable<ProjectItemReference> additionalReferences =
      const <ProjectItemReference>[],
}) {
  return _ProjectItemReferenceIndexBuilder(
    project: project,
    maps: maps,
    itemCatalog: itemCatalog,
    additionalReferences: additionalReferences,
  ).build();
}

final class _ProjectItemReferenceIndexBuilder {
  _ProjectItemReferenceIndexBuilder({
    required this.project,
    required List<MapData> maps,
    required this.itemCatalog,
    required Iterable<ProjectItemReference> additionalReferences,
  }) : maps = List<MapData>.unmodifiable(maps),
       additionalReferences = List<ProjectItemReference>.unmodifiable(
         additionalReferences,
       );

  final ProjectManifest project;
  final List<MapData> maps;
  final ProjectItemCatalog? itemCatalog;
  final List<ProjectItemReference> additionalReferences;
  final List<ProjectItemReference> _references = <ProjectItemReference>[];

  ProjectItemReferenceIndex build() {
    _collectNewGame();
    _collectScenes();
    _collectScripts();
    _collectScenarios();
    _collectShops();
    _collectTrainers();
    _collectMaps();
    _collectMachineCapabilities();
    _collectNarrativeConditions();
    _references.addAll(additionalReferences);
    return ProjectItemReferenceIndex(_references);
  }

  void _collectNewGame() {
    for (var index = 0; index < project.newGame.initialBag.length; index++) {
      _add(
        itemId: project.newGame.initialBag[index].itemId,
        kind: ProjectItemReferenceKind.newGameBag,
        sourceKind: 'newGame',
        sourceId: 'newGame',
        editablePath: 'newGame.initialBag[$index].itemId',
      );
    }
    for (var index = 0; index < project.newGame.initialParty.length; index++) {
      _add(
        itemId: project.newGame.initialParty[index].heldItemId,
        kind: ProjectItemReferenceKind.newGamePartyHeld,
        sourceKind: 'newGame',
        sourceId: 'newGame',
        editablePath: 'newGame.initialParty[$index].heldItemId',
      );
    }
    for (
      var index = 0;
      index < project.newGame.starterOptions.length;
      index++
    ) {
      _add(
        itemId: project.newGame.starterOptions[index].pokemon.heldItemId,
        kind: ProjectItemReferenceKind.newGameStarterHeld,
        sourceKind: 'newGame',
        sourceId: project.newGame.starterOptions[index].id,
        editablePath: 'newGame.starterOptions[$index].pokemon.heldItemId',
      );
    }
  }

  void _collectScenes() {
    for (final scene in project.scenes) {
      for (var index = 0; index < scene.graph.nodes.length; index++) {
        final payload = scene.graph.nodes[index].payload;
        final prefix = 'scenes[${scene.id}].graph.nodes[$index].payload';
        if (payload is SceneActionPayload) {
          final consequence = payload.consequence;
          if (consequence is SceneGiveItemConsequence) {
            _add(
              itemId: consequence.itemId,
              kind: ProjectItemReferenceKind.sceneGive,
              sourceKind: 'scene',
              sourceId: scene.id,
              editablePath: '$prefix.consequence.itemId',
            );
          } else if (consequence is SceneTakeItemConsequence) {
            _add(
              itemId: consequence.itemId,
              kind: ProjectItemReferenceKind.sceneTake,
              sourceKind: 'scene',
              sourceId: scene.id,
              editablePath: '$prefix.consequence.itemId',
            );
          }
        } else if (payload is SceneConditionPayload &&
            payload.conditionSource?.sourceKind ==
                SceneConditionSourceKind.inventoryItem) {
          _add(
            itemId: payload.conditionSource!.sourceId,
            kind: ProjectItemReferenceKind.sceneInventoryCondition,
            sourceKind: 'scene',
            sourceId: scene.id,
            editablePath: '$prefix.conditionSource.sourceId',
          );
        }
      }
    }
  }

  void _collectScripts() {
    for (final scriptEntry in project.scripts) {
      final script = scriptEntry.asset;
      for (var nodeIndex = 0; nodeIndex < script.nodes.length; nodeIndex++) {
        final node = script.nodes[nodeIndex];
        for (
          var commandIndex = 0;
          commandIndex < node.commands.length;
          commandIndex++
        ) {
          final command = node.commands[commandIndex];
          if (command.type != ScriptCommandType.giveItem) continue;
          _add(
            itemId: command.params['itemId'],
            kind: ProjectItemReferenceKind.scriptGive,
            sourceKind: 'script',
            sourceId: scriptEntry.id,
            editablePath:
                'scripts[${scriptEntry.id}].asset.nodes[$nodeIndex].commands[$commandIndex].params.itemId',
          );
        }
      }
    }
  }

  void _collectScenarios() {
    for (final scenario in project.scenarios) {
      for (var index = 0; index < scenario.nodes.length; index++) {
        final node = scenario.nodes[index];
        if (node.payload.actionKind?.trim() != 'giveItem') continue;
        _add(
          itemId: node.payload.params['itemId'],
          kind: ProjectItemReferenceKind.scenarioGive,
          sourceKind: 'scenario',
          sourceId: scenario.id,
          editablePath:
              'scenarios[${scenario.id}].nodes[$index].payload.params.itemId',
        );
      }
    }
  }

  void _collectShops() {
    for (final shop in project.shops) {
      for (var index = 0; index < shop.entries.length; index++) {
        _add(
          itemId: shop.entries[index].itemId,
          kind: ProjectItemReferenceKind.shopEntry,
          sourceKind: 'shop',
          sourceId: shop.id,
          editablePath: 'shops[${shop.id}].entries[$index].itemId',
        );
      }
      for (var stateIndex = 0; stateIndex < shop.states.length; stateIndex++) {
        final state = shop.states[stateIndex];
        _collectCondition(
          state.activation,
          sourceKind: 'shop',
          sourceId: shop.id,
          editablePath: 'shops[${shop.id}].states[$stateIndex].activation',
        );
        for (
          var entryIndex = 0;
          entryIndex < state.entries.length;
          entryIndex++
        ) {
          _add(
            itemId: state.entries[entryIndex].itemId,
            kind: ProjectItemReferenceKind.shopEntry,
            sourceKind: 'shop',
            sourceId: shop.id,
            editablePath:
                'shops[${shop.id}].states[$stateIndex].entries[$entryIndex].itemId',
          );
        }
      }
    }
  }

  void _collectTrainers() {
    for (final trainer in project.trainers) {
      for (var index = 0; index < trainer.rewardItemGrants.length; index++) {
        _add(
          itemId: trainer.rewardItemGrants[index].itemId,
          kind: ProjectItemReferenceKind.trainerReward,
          sourceKind: 'trainer',
          sourceId: trainer.id,
          editablePath:
              'trainers[${trainer.id}].rewardItemGrants[$index].itemId',
        );
      }
      for (var index = 0; index < trainer.team.length; index++) {
        _add(
          itemId: trainer.team[index].heldItemId,
          kind: ProjectItemReferenceKind.trainerHeld,
          sourceKind: 'trainer',
          sourceId: trainer.id,
          editablePath: 'trainers[${trainer.id}].team[$index].heldItemId',
        );
      }
    }
  }

  void _collectMaps() {
    for (final map in maps) {
      for (var index = 0; index < map.entities.length; index++) {
        _add(
          itemId: map.entities[index].item?.gameItemId,
          kind: ProjectItemReferenceKind.mapPickup,
          sourceKind: 'map',
          sourceId: map.id,
          editablePath: 'maps[${map.id}].entities[$index].item.gameItemId',
        );
      }
    }
  }

  void _collectMachineCapabilities() {
    final catalog = itemCatalog;
    if (catalog == null) return;
    for (var index = 0; index < catalog.entries.length; index++) {
      final definition = catalog.entries[index];
      if (definition.machine == null) continue;
      _add(
        itemId: definition.id,
        kind: ProjectItemReferenceKind.machineCapability,
        sourceKind: 'itemCatalog',
        sourceId: definition.id,
        editablePath: 'itemCatalog.entries[$index].machine',
        blocksDeletion: false,
      );
    }
  }

  void _collectNarrativeConditions() {
    final narrativeIndex = buildNarrativeDependencyIndex(
      project: project,
      maps: maps,
    );
    for (final usage in narrativeIndex.usages) {
      if (usage.target.kind != NarrativeDependencyTargetKind.item) continue;
      _add(
        itemId: usage.target.id,
        kind: ProjectItemReferenceKind.condition,
        sourceKind: usage.owner.sourceKind ?? usage.owner.kind.name,
        sourceId: usage.owner.id,
        editablePath: usage.path,
      );
    }
  }

  void _collectCondition(
    ScriptCondition condition, {
    required String sourceKind,
    required String sourceId,
    required String editablePath,
  }) {
    if (condition.type == ScriptConditionType.itemQuantityAtLeast) {
      _add(
        itemId: condition.params[ScriptConditionParams.itemId],
        kind: ProjectItemReferenceKind.condition,
        sourceKind: sourceKind,
        sourceId: sourceId,
        editablePath: '$editablePath.params.itemId',
      );
    }
    for (var index = 0; index < condition.children.length; index++) {
      _collectCondition(
        condition.children[index],
        sourceKind: sourceKind,
        sourceId: sourceId,
        editablePath: '$editablePath.children[$index]',
      );
    }
  }

  void _add({
    required String? itemId,
    required ProjectItemReferenceKind kind,
    required String sourceKind,
    required String sourceId,
    required String editablePath,
    bool blocksDeletion = true,
  }) {
    final normalizedItemId = itemId?.trim();
    if (normalizedItemId == null || normalizedItemId.isEmpty) return;
    _references.add(
      ProjectItemReference(
        itemId: normalizedItemId,
        kind: kind,
        sourceKind: sourceKind,
        sourceId: sourceId,
        editablePath: editablePath,
        blocksDeletion: blocksDeletion,
      ),
    );
  }
}

int _compareReferences(ProjectItemReference left, ProjectItemReference right) {
  final byItem = left.itemId.compareTo(right.itemId);
  if (byItem != 0) return byItem;
  final byKind = left.kind.index.compareTo(right.kind.index);
  if (byKind != 0) return byKind;
  final bySourceKind = left.sourceKind.compareTo(right.sourceKind);
  if (bySourceKind != 0) return bySourceKind;
  final bySourceId = left.sourceId.compareTo(right.sourceId);
  if (bySourceId != 0) return bySourceId;
  final byPath = left.editablePath.compareTo(right.editablePath);
  if (byPath != 0) return byPath;
  return left.blocksDeletion == right.blocksDeletion
      ? 0
      : left.blocksDeletion
      ? -1
      : 1;
}
