import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/entity_editing_coordinator.dart';
import 'package:map_editor/src/application/services/entity_editing_service.dart';
import 'package:map_editor/src/application/use_cases/character_use_cases.dart';
import 'package:map_editor/src/application/use_cases/entity_use_cases.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_v2_mode_activation_use_case.dart';
import 'package:map_editor/src/application/use_cases/trainer_use_cases.dart';
import 'package:map_editor/src/application/models/trainer_field_update.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_migration_persistence_repository.dart';
import 'package:path/path.dart' as p;

const selbrumePortMapId = 'map_port_brisants';
const selbrumeMarshMapId = 'map_marais_salants';
const selbrumeLysaEntityId = 'npc_lysa';
const selbrumePortEntryTriggerId = 'zone_port_entry';
const selbrumeClueEntityId = 'clue_glass_object';
const selbrumeLysaSceneId = 'scene_lysa_port';
const selbrumePortEntrySceneId = 'scene_port_entry';
const selbrumeClueSceneId = 'scene_clue_glass';
const selbrumeLysaCharacterId = 'character_lysa';
const selbrumeLysaTrainerId = 'trainer_lysa_port';
const selbrumeDialogueId = 'dialogue_lysa_port';
const selbrumeDialogueRelativePath = 'dialogues/lysa_port.yarn';
const selbrumeLysaCinematicId = 'cinematic_lysa_port';
const selbrumeLysaFactId = 'fact_lysa_port_resolved';
const selbrumeLysaStorylineId = 'story_main_brume_phare';
const selbrumeLysaChapterId = 'chapter_1_port';
const selbrumeLysaStoryStepId = 'step_rival_battle';
const selbrumeLysaWorldRuleId = 'world_rule_lysa_port_resolved';
const selbrumeLysaVictoryOutcomeId = 'lysa.victory';
const selbrumeLysaDefeatOutcomeId = 'lysa.defeat';

final class SelbrumeEventV2Fixture {
  SelbrumeEventV2Fixture._({
    required this.repoRoot,
    required this.originalRoot,
    required this.promotionBaselineRoot,
    required this.temporaryRoot,
    required this.projectRoot,
    required this.projectPath,
    required this.originalFingerprintBefore,
    required this.copyFingerprintBefore,
    required this.eventIdsByRole,
  });

  final Directory repoRoot;
  final Directory originalRoot;
  final Directory promotionBaselineRoot;
  final Directory temporaryRoot;
  final Directory projectRoot;
  final String projectPath;
  final String originalFingerprintBefore;
  final String copyFingerprintBefore;
  final Map<String, String> eventIdsByRole;

  static Future<SelbrumeEventV2Fixture> create() async {
    final repoRoot = findPokemonProjectRoot();
    final originalRoot = Directory(p.join(repoRoot.path, 'selbrume'));
    final originalFingerprintBefore =
        await selbrumeAuthoringFingerprint(originalRoot);
    final temporaryRoot =
        await Directory.systemTemp.createTemp('pokemap_phase_j_selbrume_');
    final promotionBaselineRoot = Directory(
      p.join(temporaryRoot.path, 'selbrume_promotion_baseline'),
    );
    await _cloneProject(originalRoot, promotionBaselineRoot);
    await _removeLocalArtifacts(promotionBaselineRoot);
    await _restoreVersionedPromotionBaseline(
      repoRoot: repoRoot,
      baselineRoot: promotionBaselineRoot,
    );
    final projectRoot = Directory(p.join(temporaryRoot.path, 'selbrume'));
    await _cloneProject(promotionBaselineRoot, projectRoot);
    final copyFingerprintBefore =
        await selbrumeAuthoringFingerprint(projectRoot);

    final projectPath = p.join(projectRoot.path, 'project.json');
    final events = await _authorSelbrumeSlice(
      projectRoot: projectRoot,
      projectPath: projectPath,
    );
    return SelbrumeEventV2Fixture._(
      repoRoot: repoRoot,
      originalRoot: originalRoot,
      promotionBaselineRoot: promotionBaselineRoot,
      temporaryRoot: temporaryRoot,
      projectRoot: projectRoot,
      projectPath: projectPath,
      originalFingerprintBefore: originalFingerprintBefore,
      copyFingerprintBefore: copyFingerprintBefore,
      eventIdsByRole: Map.unmodifiable(events),
    );
  }

  Future<String> originalFingerprintAfter() {
    return selbrumeAuthoringFingerprint(originalRoot);
  }

  /// Exports the J1 authoring result as a small, standalone Golden Slice.
  ///
  /// Event records are never reconstructed here: the registry bytes come from
  /// the product operations exercised by [_authorSelbrumeSlice]. Only
  /// dependencies unrelated to the selected maps are removed.
  Future<void> exportAutonomousFixture(Directory destination) async {
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
    await destination.create(recursive: true);

    final projectRoot = _jsonObject(
      decodeNarrativeEventJsonStrict(await File(projectPath).readAsString()),
    );
    final selectedMapIds = <String>{selbrumePortMapId, selbrumeMarshMapId};
    final selectedMapEntries = _jsonObjects(projectRoot['maps'])
        .where((entry) => selectedMapIds.contains(entry['id']))
        .toList(growable: false);
    final selectedMapRoots = <String, Map<String, Object?>>{};
    final elementIds = <String>{};
    final tilesetIds = <String>{};
    final characterIds = <String>{'vova', selbrumeLysaCharacterId};
    final trainerIds = <String>{selbrumeLysaTrainerId};
    final removedConnections = <Map<String, Object?>>[];
    for (final entry in selectedMapEntries) {
      final mapId = entry['id']! as String;
      final relativePath = entry['relativePath']! as String;
      final mapRoot = _jsonObject(
        decodeNarrativeEventJsonStrict(
          await File(p.join(projectRootDirectory.path, relativePath))
              .readAsString(),
        ),
      );
      for (final connection in _jsonObjects(mapRoot['connections'])) {
        removedConnections.add({
          'mapId': mapId,
          'direction': connection['direction'],
          'targetMapId': connection['targetMapId'],
        });
      }
      mapRoot['connections'] = <Object?>[];
      mapRoot['warps'] = <Object?>[];
      _collectStringValuesForKey(mapRoot, 'elementId', elementIds);
      _collectStringValuesForKey(mapRoot, 'tilesetId', tilesetIds);
      _collectStringValuesForKey(mapRoot, 'characterId', characterIds);
      _collectStringValuesForKey(mapRoot, 'trainerId', trainerIds);
      selectedMapRoots[mapId] = mapRoot;
    }

    final selectedElements = _jsonObjects(projectRoot['elements'])
        .where((entry) => elementIds.contains(entry['id']))
        .toList(growable: false);
    for (final element in selectedElements) {
      _collectStringValuesForKey(element, 'tilesetId', tilesetIds);
    }
    final selectedTrainers = _jsonObjects(projectRoot['trainers'])
        .where((entry) => trainerIds.contains(entry['id']))
        .toList(growable: false);
    for (final trainer in selectedTrainers) {
      _collectStringValuesForKey(trainer, 'characterId', characterIds);
    }
    final selectedCharacters = _jsonObjects(projectRoot['characters'])
        .where((entry) => characterIds.contains(entry['id']))
        .toList(growable: false);
    for (final character in selectedCharacters) {
      _collectStringValuesForKey(character, 'tilesetId', tilesetIds);
    }
    final allTilesets = _jsonObjects(projectRoot['tilesets']);
    final selectedGroupIds = selectedMapEntries
        .map((entry) => entry['groupId'])
        .whereType<String>()
        .toSet();

    projectRoot['maps'] = selectedMapEntries;
    projectRoot['groups'] = _jsonObjects(projectRoot['groups'])
        .where((entry) => selectedGroupIds.contains(entry['id']))
        .toList(growable: false);
    projectRoot['tilesets'] = <Object?>[];
    projectRoot['elements'] = selectedElements;
    projectRoot['characters'] = selectedCharacters;
    projectRoot['trainers'] = selectedTrainers;
    projectRoot['scenes'] = <Object?>[
      for (final entry in _jsonObjects(projectRoot['scenes']))
        if (<String>{
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        }.contains(entry['id']))
          entry,
    ];
    projectRoot['dialogues'] = <Object?>[
      <String, Object?>{
        'id': selbrumeDialogueId,
        'name': 'Lysa au port',
        'relativePath': selbrumeDialogueRelativePath,
        'tags': <Object?>['phase-j', 'selbrume'],
        'description': 'Dialogue de la Golden Slice Event V2.',
        'defaultStartNode': 'LysaPort',
        'folderId': null,
        'sortOrder': 0,
      },
    ];
    for (final key in const <String>[
      'encounterTables',
      'scenarios',
      'scripts',
      'dialogueFolders',
      'environmentPresets',
      'pathCategories',
      'pathPatternPresets',
      'pathPresets',
      'terrainCategories',
      'terrainPresets',
    ]) {
      projectRoot[key] = <Object?>[];
    }
    projectRoot['cinematics'] = <Object?>[_goldenLysaCinematic().toJson()];
    projectRoot['facts'] = <Object?>[
      NarrativeFactDefinition(
        id: selbrumeLysaFactId,
        label: 'Lysa vaincue au Port des Brisants',
      ).toJson(),
    ];
    projectRoot['storylines'] = _jsonObjects(projectRoot['storylines'])
        .where((entry) => entry['id'] == selbrumeLysaStorylineId)
        .toList(growable: false);
    projectRoot['worldRules'] = <Object?>[_goldenLysaWorldRule().toJson()];
    projectRoot['surfaceCatalog'] = <String, Object?>{
      'atlases': <Object?>[],
      'animations': <Object?>[],
      'presets': <Object?>[],
    };
    projectRoot['shadowCatalog'] = <String, Object?>{
      'profiles': <Object?>[],
    };
    _collectStringValuesForKey(projectRoot, 'tilesetId', tilesetIds);
    final selectedTilesets = allTilesets
        .where((entry) => tilesetIds.contains(entry['id']))
        .toList(growable: false);
    projectRoot['tilesets'] = selectedTilesets;

    // Parsing the reduced manifest is the export-time schema gate.
    ProjectManifest.fromJson(projectRoot);
    await _writeCanonicalJson(
      File(p.join(destination.path, 'project.json')),
      projectRoot,
    );
    for (final entry in selectedMapEntries) {
      final mapId = entry['id']! as String;
      final relativePath = entry['relativePath']! as String;
      await _writeCanonicalJson(
        File(p.join(destination.path, relativePath)),
        selectedMapRoots[mapId]!,
      );
    }
    final dialogueFile = File(
      p.join(destination.path, selbrumeDialogueRelativePath),
    );
    await dialogueFile.parent.create(recursive: true);
    await dialogueFile.writeAsString(_selbrumeJ2Dialogue, flush: true);
    for (final tileset in selectedTilesets) {
      final relativePath = tileset['relativePath']! as String;
      final source = File(p.join(projectRootDirectory.path, relativePath));
      final target = File(p.join(destination.path, relativePath));
      await target.parent.create(recursive: true);
      await source.copy(target.path);
    }

    final authoredRegistry = NarrativeEventRegistry.fromJson(
      _jsonObject(projectRoot['eventRegistry']),
    );
    final definitions = authoredRegistry.records
        .map((record) => record.definitionOrNull)
        .whereType<NarrativeEventDefinition>()
        .toList(growable: false);
    await _writeCanonicalJson(
      File(p.join(destination.path, 'semantic_diff.json')),
      <String, Object?>{
        'schemaVersion': 1,
        'baseProject': 'selbrume',
        'selectedMaps': selectedMapIds.toList()..sort(),
        'removedExternalConnections': removedConnections,
        'addedCharacters': <String>[selbrumeLysaCharacterId],
        'addedTrainers': <String>[selbrumeLysaTrainerId],
        'addedScenes': <String>[
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        ],
        'updatedStorylines': <String>[selbrumeLysaStorylineId],
        'goldenSlice': <String, Object?>{
          'dialogueId': selbrumeDialogueId,
          'cinematicId': selbrumeLysaCinematicId,
          'trainerId': selbrumeLysaTrainerId,
          'factId': selbrumeLysaFactId,
          'storyStepId': selbrumeLysaStoryStepId,
          'worldRuleId': selbrumeLysaWorldRuleId,
          'outcomes': <String>[
            selbrumeLysaVictoryOutcomeId,
            selbrumeLysaDefeatOutcomeId,
          ],
        },
        'events': <Object?>[
          for (final definition in definitions)
            <String, Object?>{
              'id': definition.id,
              'name': definition.name,
              'source': definition.source.toJson(),
              'sceneId': definition.sceneId,
              'reusePolicy': definition.reusePolicy.name,
            },
        ],
      },
    );
    await _writePromotionPayloads(destination);
    await _writeFixtureManifests(
      destination,
      promotionBaselineRoot: promotionBaselineRoot,
    );
  }

  Future<void> _writePromotionPayloads(Directory destination) async {
    final payloadRoot = Directory(
      p.join(destination.path, 'promotion_payload'),
    );
    final baseProject = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(promotionBaselineRoot.path, 'project.json'))
            .readAsString(),
      ),
    );
    final authoredProject = _jsonObject(
      decodeNarrativeEventJsonStrict(await File(projectPath).readAsString()),
    );

    void upsertFromAuthored(String key, Set<String> ids) {
      final additions = _jsonObjects(authoredProject[key])
          .where((entry) => ids.contains(entry['id']))
          .toList(growable: false);
      if (additions.length != ids.length) {
        throw StateError(
          'Promotion payload is missing ${ids.length - additions.length} '
          '$key definition(s).',
        );
      }
      baseProject[key] = _upsertJsonEntriesById(
        _jsonObjects(baseProject[key]),
        additions,
      );
    }

    upsertFromAuthored('characters', const <String>{selbrumeLysaCharacterId});
    upsertFromAuthored('trainers', const <String>{selbrumeLysaTrainerId});
    upsertFromAuthored('scenes', const <String>{
      selbrumeLysaSceneId,
      selbrumePortEntrySceneId,
      selbrumeClueSceneId,
    });
    baseProject['dialogues'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['dialogues']),
      <Map<String, Object?>>[
        <String, Object?>{
          'id': selbrumeDialogueId,
          'name': 'Lysa au port',
          'relativePath': selbrumeDialogueRelativePath,
          'tags': <Object?>['phase-j', 'selbrume'],
          'description': 'Dialogue de la Golden Slice Event V2.',
          'defaultStartNode': 'LysaPort',
          'folderId': null,
          'sortOrder': 0,
        },
      ],
    );
    baseProject['cinematics'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['cinematics']),
      <Map<String, Object?>>[_goldenLysaCinematic().toJson()],
    );
    baseProject['facts'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['facts']),
      <Map<String, Object?>>[
        NarrativeFactDefinition(
          id: selbrumeLysaFactId,
          label: 'Lysa vaincue au Port des Brisants',
        ).toJson(),
      ],
    );
    upsertFromAuthored(
      'storylines',
      const <String>{selbrumeLysaStorylineId},
    );
    baseProject['worldRules'] = _upsertJsonEntriesById(
      _jsonObjects(baseProject['worldRules']),
      <Map<String, Object?>>[_goldenLysaWorldRule().toJson()],
    );
    baseProject['eventRegistry'] = authoredProject['eventRegistry'];

    // This is the destination-ready project, not the reduced runtime fixture:
    // all unrelated Selbrume content must survive promotion.
    ProjectValidator.validate(ProjectManifest.fromJson(baseProject));
    await _writePrettyJson(
      File(p.join(payloadRoot.path, 'project.json')),
      baseProject,
    );

    await _writePromotionMap(
      payloadRoot: payloadRoot,
      mapId: selbrumePortMapId,
      addedEntityId: selbrumeLysaEntityId,
    );
    await _writePromotionMap(
      payloadRoot: payloadRoot,
      mapId: selbrumeMarshMapId,
      addedEntityId: selbrumeClueEntityId,
    );
    final dialogueFile = File(
      p.join(payloadRoot.path, selbrumeDialogueRelativePath),
    );
    await dialogueFile.parent.create(recursive: true);
    await dialogueFile.writeAsString(_selbrumeJ2Dialogue, flush: true);
    await _writePromotionCheckpoint(destination);
  }

  Future<void> _writePromotionCheckpoint(Directory destination) async {
    final checkpointRoot = Directory(
      p.join(destination.path, 'promotion_checkpoint'),
    );
    final entries = <Map<String, Object?>>[];
    for (final relativePath in const <String>[
      'project.json',
      'maps/map_port_brisants.json',
      'maps/map_marais_salants.json',
    ]) {
      final source = File(p.join(promotionBaselineRoot.path, relativePath));
      final bytes = await source.readAsBytes();
      final target = File(p.join(checkpointRoot.path, relativePath));
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
      entries.add(<String, Object?>{
        'destination': 'selbrume/$relativePath',
        'checkpoint': 'promotion_checkpoint/$relativePath',
        'beforeExists': true,
        'beforeSha256': narrativeEventBytesFingerprint(bytes),
      });
    }
    entries.add(<String, Object?>{
      'destination': 'selbrume/$selbrumeDialogueRelativePath',
      'checkpoint': null,
      'beforeExists': false,
      'beforeSha256': null,
    });
    await _writeCanonicalJson(
      File(p.join(checkpointRoot.path, 'checkpoint_manifest.json')),
      <String, Object?>{
        'schemaVersion': 1,
        'state': 'prePromotionCheckpoint',
        'orderedFiles': entries,
      },
    );
  }

  Future<void> _writePromotionMap({
    required Directory payloadRoot,
    required String mapId,
    required String addedEntityId,
  }) async {
    final relativePath = 'maps/$mapId.json';
    final baseMap = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(promotionBaselineRoot.path, relativePath))
            .readAsString(),
      ),
    );
    final authoredMap = _jsonObject(
      decodeNarrativeEventJsonStrict(
        await File(p.join(projectRoot.path, relativePath)).readAsString(),
      ),
    );
    final addedEntities = _jsonObjects(authoredMap['entities'])
        .where((entry) => entry['id'] == addedEntityId)
        .toList(growable: false);
    if (addedEntities.length != 1) {
      throw StateError(
        'Promotion payload expected entity $addedEntityId on $mapId.',
      );
    }
    baseMap['entities'] = _upsertJsonEntriesById(
      _jsonObjects(baseMap['entities']),
      addedEntities,
    );
    MapData.fromJson(baseMap);
    await _writePrettyJson(
      File(p.join(payloadRoot.path, relativePath)),
      baseMap,
    );
  }

  Directory get projectRootDirectory => projectRoot;

  Future<void> dispose() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  }
}

const _selbrumeJ2Dialogue = '''title: LysaPort
tags: phase-j selbrume
---
Lysa: La brume se lève sur le Port des Brisants.
Lysa: Si tu veux continuer, montre-moi ce que vaut ton équipe.
===
''';

SceneAsset _authorGoldenLysaSceneWithPublicOperations(
  ProjectManifest project,
  SceneAsset draft,
) {
  var scene = removeSceneEdgeDraft(draft, 'edge_start_end').updatedScene;
  final dialogue = addSceneLinkedAssetNodeDraft(
    scene,
    payload: SceneYarnDialoguePayload(
      dialogueId: selbrumeDialogueId,
      yarnNodeName: 'LysaPort',
      speakerHints: const <String>[selbrumeLysaCharacterId],
    ),
    title: 'Dialogue avec Lysa',
    afterNodeId: 'node_start',
  );
  scene = dialogue.updatedScene;
  final cinematic = addSceneCinematicNodeDraft(
    scene,
    project: project,
    cinematicId: selbrumeLysaCinematicId,
    afterNodeId: dialogue.createdNode.id,
  );
  scene = cinematic.updatedScene;
  final battle = addSceneLinkedAssetNodeDraft(
    scene,
    payload: SceneBattlePayload(
      battleKind: 'trainer',
      trainerId: selbrumeLysaTrainerId,
      npcEntityId: selbrumeLysaEntityId,
      declaredOutcomes: const <String>['victory', 'defeat'],
    ),
    title: 'Combat contre Lysa',
    afterNodeId: cinematic.createdNode.id,
  );
  scene = battle.updatedScene;
  final fact = addSceneConsequenceActionNodeDraft(
    scene,
    consequence: SceneConsequence.setFact(
      factId: selbrumeLysaFactId,
      value: true,
      label: 'Mémoriser la victoire contre Lysa',
    ),
    afterNodeId: battle.createdNode.id,
  );
  scene = fact.updatedScene;
  final completeStep = addSceneConsequenceActionNodeDraft(
    scene,
    consequence: SceneConsequence.completeStoryStep(
      stepId: selbrumeLysaStoryStepId,
      label: 'Terminer l’affrontement contre la rivale',
    ),
    afterNodeId: fact.createdNode.id,
  );
  scene = completeStep.updatedScene;
  final defeatEnd = addSceneNodeDraft(
    scene,
    kind: SceneNodeKind.end,
    title: 'Défaite contre Lysa',
    afterNodeId: battle.createdNode.id,
  );
  scene = defeatEnd.updatedScene;

  for (final link in <({String from, String port, String to})>[
    (from: 'node_start', port: 'completed', to: dialogue.createdNode.id),
    (
      from: dialogue.createdNode.id,
      port: 'completed',
      to: cinematic.createdNode.id,
    ),
    (
      from: cinematic.createdNode.id,
      port: 'completed',
      to: battle.createdNode.id,
    ),
    (
      from: battle.createdNode.id,
      port: 'victory',
      to: fact.createdNode.id,
    ),
    (
      from: fact.createdNode.id,
      port: 'completed',
      to: completeStep.createdNode.id,
    ),
    (
      from: completeStep.createdNode.id,
      port: 'completed',
      to: 'node_end',
    ),
    (
      from: battle.createdNode.id,
      port: 'defeat',
      to: defeatEnd.createdNode.id,
    ),
  ]) {
    scene = addSceneEdgeDraft(
      scene,
      fromNodeId: link.from,
      fromPortId: link.port,
      toNodeId: link.to,
    ).updatedScene;
  }

  return SceneAsset(
    id: scene.id,
    name: 'Rencontre et combat contre Lysa au port',
    description: 'Golden Slice Event V2 de Selbrume.',
    storylineId: selbrumeLysaStorylineId,
    chapterId: selbrumeLysaChapterId,
    tags: const <String>['phase-j', 'selbrume', 'golden-slice'],
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: <SceneNode>[
        for (final node in scene.graph.nodes)
          if (node.id == 'node_end')
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: 'Victoire contre Lysa',
              payload: SceneEndPayload(
                sceneOutcomeId: selbrumeLysaVictoryOutcomeId,
              ),
            )
          else if (node.id == defeatEnd.createdNode.id)
            SceneNode(
              id: node.id,
              kind: node.kind,
              title: node.title,
              payload: SceneEndPayload(
                sceneOutcomeId: selbrumeLysaDefeatOutcomeId,
              ),
            )
          else
            node,
      ],
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(
        id: selbrumeLysaVictoryOutcomeId,
        label: 'Victoire contre Lysa',
      ),
      SceneOutcome(
        id: selbrumeLysaDefeatOutcomeId,
        label: 'Défaite contre Lysa',
      ),
    ],
  );
}

CinematicAsset _goldenLysaCinematic() {
  return CinematicAsset(
    id: selbrumeLysaCinematicId,
    title: 'Lysa se prépare au combat',
    mapId: selbrumePortMapId,
    storylineId: selbrumeLysaStorylineId,
    chapterId: selbrumeLysaChapterId,
    tags: const <String>['phase-j', 'selbrume'],
    timeline: CinematicTimeline(
      steps: <CinematicTimelineStep>[
        CinematicTimelineStep(
          id: 'lysa_battle_beat',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 250,
        ),
      ],
    ),
  );
}

StorylineAsset _goldenLysaStoryline(StorylineAsset original) {
  final chapters = <StorylineChapter>[
    for (final chapter in original.chapters)
      StorylineChapter(
        id: chapter.id,
        title: chapter.title,
        description: chapter.description,
        order: chapter.order,
        steps: <StorylineStep>[
          for (final step in chapter.steps)
            if (step.id == selbrumeLysaStoryStepId)
              StorylineStep(
                id: step.id,
                title: step.title,
                description: step.description,
                order: step.order,
                entryCondition: step.entryCondition,
                completionCondition: step.completionCondition,
                sceneLinkIds: <String>{
                  ...step.sceneLinkIds,
                  selbrumeLysaSceneId,
                }.toList(growable: false),
                expectedOutcomeIds: <String>{
                  ...step.expectedOutcomeIds,
                  selbrumeLysaVictoryOutcomeId,
                }.toList(growable: false),
                status: step.status,
                authorNotes: step.authorNotes,
                metadata: step.metadata,
              )
            else
              step,
        ],
        directSceneLinkIds: chapter.directSceneLinkIds,
        status: chapter.status,
        authorNotes: chapter.authorNotes,
        metadata: chapter.metadata,
      ),
  ];
  final matchingSteps = chapters
      .expand((chapter) => chapter.steps)
      .where((step) => step.id == selbrumeLysaStoryStepId)
      .length;
  if (matchingSteps != 1) {
    throw StateError(
      'Selbrume must expose exactly one $selbrumeLysaStoryStepId.',
    );
  }
  return StorylineAsset(
    id: original.id,
    schemaVersion: original.schemaVersion,
    type: original.type,
    status: original.status,
    title: original.title,
    description: original.description,
    sortOrder: original.sortOrder,
    locale: original.locale,
    chapters: chapters,
    sceneLinks: original.sceneLinks,
    relationships: original.relationships,
    legacySource: original.legacySource,
    authorNotes: original.authorNotes,
    metadata: original.metadata,
  );
}

WorldRuleDefinition _goldenLysaWorldRule() {
  return WorldRuleDefinition(
    id: selbrumeLysaWorldRuleId,
    label: 'Lysa quitte le port après sa défaite',
    source: const WorldRuleSource(
      kind: WorldRuleSourceKind.fact,
      sourceId: selbrumeLysaFactId,
      predicate: WorldRuleSourcePredicate.isTrue,
    ),
    target: const WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: selbrumePortMapId,
      entityId: selbrumeLysaEntityId,
    ),
    effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
    priority: 0,
  );
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  return (value as List? ?? const <Object?>[])
      .whereType<Map>()
      .map((entry) => entry.cast<String, Object?>())
      .toList(growable: false);
}

Map<String, Object?> _jsonObject(Object? value) {
  if (value is! Map) {
    throw FormatException('Expected a JSON object, got ${value.runtimeType}.');
  }
  return value.cast<String, Object?>();
}

List<Map<String, Object?>> _upsertJsonEntriesById(
  List<Map<String, Object?>> base,
  List<Map<String, Object?>> additions,
) {
  final additionById = <String, Map<String, Object?>>{
    for (final entry in additions) entry['id']! as String: entry,
  };
  final result = <Map<String, Object?>>[
    for (final entry in base) additionById.remove(entry['id']) ?? entry,
  ];
  result.addAll(additionById.values);
  return result;
}

void _collectStringValuesForKey(
  Object? value,
  String key,
  Set<String> output,
) {
  if (value is Map) {
    final candidate = value[key];
    if (candidate is String && candidate.isNotEmpty) output.add(candidate);
    for (final nested in value.values) {
      _collectStringValuesForKey(nested, key, output);
    }
  } else if (value is List) {
    for (final nested in value) {
      _collectStringValuesForKey(nested, key, output);
    }
  }
}

Future<void> _writeCanonicalJson(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    canonicalizeNarrativeEventJsonUtf8(value),
    flush: true,
  );
}

Future<void> _writePrettyJson(File file, Object? value) async {
  // Promotion payloads remain human-reviewable in the real Selbrume diff.
  // Canonicalization still validates the full JSON boundary before writing.
  canonicalizeNarrativeEventJson(value);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
    flush: true,
  );
}

Future<void> _writeFixtureManifests(
  Directory destination, {
  required Directory promotionBaselineRoot,
}) async {
  final payloadFiles = <File>[];
  await for (final entity
      in destination.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relativePath = p.posix.normalize(
      p.relative(entity.path, from: destination.path).replaceAll(r'\', '/'),
    );
    if (relativePath == 'fixture_manifest.json' ||
        relativePath == 'promotion_manifest.json') {
      continue;
    }
    payloadFiles.add(entity);
  }
  payloadFiles.sort((a, b) => a.path.compareTo(b.path));
  final entries = <Map<String, Object?>>[];
  for (final file in payloadFiles) {
    final relativePath = p.posix.normalize(
      p.relative(file.path, from: destination.path).replaceAll(r'\', '/'),
    );
    entries.add(<String, Object?>{
      'path': relativePath,
      'sha256': narrativeEventBytesFingerprint(await file.readAsBytes()),
      'bytes': await file.length(),
    });
  }
  await _writeCanonicalJson(
    File(p.join(destination.path, 'fixture_manifest.json')),
    <String, Object?>{
      'schemaVersion': 1,
      'generator':
          'packages/map_editor/tool/build_selbrume_event_v2_fixture.dart',
      'payloadFiles': entries,
    },
  );
  final entryByPath = <String, Map<String, Object?>>{
    for (final entry in entries) entry['path']! as String: entry,
  };
  final promotions = <({String source, String destination})>[
    (
      source: 'promotion_payload/project.json',
      destination: 'selbrume/project.json',
    ),
    (
      source: 'promotion_payload/maps/map_port_brisants.json',
      destination: 'selbrume/maps/map_port_brisants.json',
    ),
    (
      source: 'promotion_payload/maps/map_marais_salants.json',
      destination: 'selbrume/maps/map_marais_salants.json',
    ),
    (
      source: 'promotion_payload/$selbrumeDialogueRelativePath',
      destination: 'selbrume/$selbrumeDialogueRelativePath',
    ),
  ];
  await _writeCanonicalJson(
    File(p.join(destination.path, 'promotion_manifest.json')),
    <String, Object?>{
      'schemaVersion': 1,
      'state': 'frozenForJ5',
      'orderedFiles': <Object?>[
        for (var index = 0; index < promotions.length; index++)
          <String, Object?>{
            'order': index + 1,
            'source': promotions[index].source,
            'destination': promotions[index].destination,
            'beforeExists': await File(
              p.join(
                promotionBaselineRoot.path,
                promotions[index].destination.replaceFirst('selbrume/', ''),
              ),
            ).exists(),
            'beforeSha256': await _fileFingerprintOrNull(
              File(
                p.join(
                  promotionBaselineRoot.path,
                  promotions[index].destination.replaceFirst('selbrume/', ''),
                ),
              ),
            ),
            'afterSha256': entryByPath[promotions[index].source]!['sha256'],
            'sha256': entryByPath[promotions[index].source]!['sha256'],
          },
      ],
    },
  );
}

Future<String?> _fileFingerprintOrNull(File file) async {
  if (!await file.exists()) return null;
  return narrativeEventBytesFingerprint(await file.readAsBytes());
}

Future<void> _restoreVersionedPromotionBaseline({
  required Directory repoRoot,
  required Directory baselineRoot,
}) async {
  final fixtureRoot = Directory(
    p.join(
      repoRoot.path,
      'examples',
      'playable_runtime_host',
      'event_builder_v2_selbrume_slice',
    ),
  );
  final promotion = _jsonObject(
    decodeNarrativeEventJsonStrict(
      await File(p.join(fixtureRoot.path, 'promotion_manifest.json'))
          .readAsString(),
    ),
  );
  final entries = _jsonObjects(promotion['orderedFiles']);
  if (promotion['state'] != 'frozenForJ5' || entries.length != 4) {
    throw StateError('The versioned J5 promotion baseline is not frozen.');
  }
  for (final entry in entries) {
    final destination = entry['destination']! as String;
    if (!destination.startsWith('selbrume/')) {
      throw StateError('Unexpected promotion destination: $destination');
    }
    final relativePath = destination.substring('selbrume/'.length);
    final target = File(p.join(baselineRoot.path, relativePath));
    if (entry['beforeExists'] == true) {
      final checkpoint = File(
        p.join(fixtureRoot.path, 'promotion_checkpoint', relativePath),
      );
      final bytes = await checkpoint.readAsBytes();
      if (narrativeEventBytesFingerprint(bytes) != entry['beforeSha256']) {
        throw StateError('Checkpoint hash mismatch for $destination.');
      }
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
    } else if (await target.exists()) {
      await target.delete();
    }
    final restoredHash = await _fileFingerprintOrNull(target);
    if (restoredHash != entry['beforeSha256']) {
      throw StateError('Baseline restore mismatch for $destination.');
    }
  }
}

Future<Map<String, String>> _authorSelbrumeSlice({
  required Directory projectRoot,
  required String projectPath,
}) async {
  final projectRepository = FileProjectRepository();
  final mapRepository = FileMapRepository();
  var project = await projectRepository.loadProject(projectPath);
  await _validateProjectClosure(
    projectRoot: projectRoot,
    project: project,
    mapRepository: mapRepository,
  );
  final existingEvents = await _existingSelbrumeSlice(
    projectRoot: projectRoot,
    project: project,
    mapRepository: mapRepository,
  );
  if (existingEvents != null) return existingEvents;

  final activation = await NarrativeEventV2ModeActivationUseCase(
    gateway: NarrativeEventMigrationPersistenceRepository(),
  ).activate(projectPath);
  if (!activation.succeeded) {
    throw StateError('${activation.code}: ${activation.message}');
  }
  project = await projectRepository.loadProject(projectPath);

  final workspace = ProjectFileSystem(projectRoot.path);
  project = await CreateCharacterUseCase(projectRepository).execute(
    workspace,
    project,
    name: selbrumeLysaCharacterId,
    tilesetId: 'grant',
  );
  project = await UpdateCharacterUseCase(projectRepository).execute(
    workspace,
    project,
    characterId: selbrumeLysaCharacterId,
    name: 'Lysa',
  );
  project = await CreateTrainerUseCase(projectRepository).execute(
    workspace,
    project,
    name: selbrumeLysaTrainerId,
    trainerClass: 'Rivale',
    battleDifficulty: 5,
    characterId: selbrumeLysaCharacterId,
    tags: const <String>['selbrume', 'phase-j'],
  );
  project = await UpdateTrainerUseCase(projectRepository).execute(
    workspace,
    project,
    trainerId: selbrumeLysaTrainerId,
    name: 'Lysa du port',
    characterId: const TrainerFieldUpdate<String>.set(
      selbrumeLysaCharacterId,
    ),
  );
  project = await AddTrainerPokemonUseCase(projectRepository).execute(
    workspace,
    project,
    trainerId: selbrumeLysaTrainerId,
    speciesId: 'bulbasaur',
    level: 7,
    moves: const <String>['tackle', 'growl'],
  );

  final storylineMatches = project.storylines
      .where((storyline) => storyline.id == selbrumeLysaStorylineId)
      .toList(growable: false);
  if (storylineMatches.length != 1) {
    throw StateError(
      'Selbrume must expose exactly one $selbrumeLysaStorylineId.',
    );
  }
  project = project.copyWith(
    dialogues: <ProjectDialogueEntry>[
      ...project.dialogues,
      const ProjectDialogueEntry(
        id: selbrumeDialogueId,
        name: 'Lysa au port',
        relativePath: selbrumeDialogueRelativePath,
        tags: <String>['phase-j', 'selbrume'],
        description: 'Dialogue de la Golden Slice Event V2.',
        defaultStartNode: 'LysaPort',
      ),
    ],
    cinematics: <CinematicAsset>[
      ...project.cinematics,
      _goldenLysaCinematic(),
    ],
    facts: <NarrativeFactDefinition>[
      ...project.facts,
      NarrativeFactDefinition(
        id: selbrumeLysaFactId,
        label: 'Lysa vaincue au Port des Brisants',
      ),
    ],
    storylines: <StorylineAsset>[
      for (final storyline in project.storylines)
        if (storyline.id == selbrumeLysaStorylineId)
          _goldenLysaStoryline(storyline)
        else
          storyline,
    ],
    worldRules: <WorldRuleDefinition>[
      ...project.worldRules,
      _goldenLysaWorldRule(),
    ],
  );

  for (final scene in const <({String seed, String description})>[
    (
      seed: 'lysa_port',
      description: 'Rencontre et combat contre Lysa au port.',
    ),
    (
      seed: 'port_entry',
      description: 'Première entrée dans le Port des Brisants.',
    ),
    (
      seed: 'clue_glass',
      description: 'Découverte de l’indice en verre poli.',
    ),
  ]) {
    final created = createSceneDraftInProject(
      project,
      name: scene.seed,
      description: scene.description,
    );
    if (created.createdScene.id == selbrumeLysaSceneId) {
      final authored = _authorGoldenLysaSceneWithPublicOperations(
        created.updatedProject,
        created.createdScene,
      );
      project = created.updatedProject.copyWith(
        scenes: <SceneAsset>[
          for (final candidate in created.updatedProject.scenes)
            if (candidate.id == authored.id) authored else candidate,
        ],
      );
    } else {
      project = created.updatedProject;
    }
  }
  await projectRepository.saveProject(project, projectPath);

  final entityService = EntityEditingService(
    addEntityToMapUseCase: AddEntityToMapUseCase(),
    updateEntityOnMapUseCase: UpdateEntityOnMapUseCase(),
    deleteEntityFromMapUseCase: DeleteEntityFromMapUseCase(),
    entityEditingCoordinator: const EntityEditingCoordinator(),
  );
  final portEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final marshEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumeMarshMapId,
  );
  final portPath = p.join(projectRoot.path, portEntry.relativePath);
  final marshPath = p.join(projectRoot.path, marshEntry.relativePath);

  var portMap = await mapRepository.loadMap(portPath);
  final lysaDraft = entityService.addEntityAt(
    portMap,
    const GridPos(x: 26, y: 16),
    kind: MapEntityKind.npc,
  );
  portMap = entityService.updateEntity(
    lysaDraft.updatedMap,
    entityId: lysaDraft.createdEntity.id,
    id: selbrumeLysaEntityId,
    name: 'Lysa',
    size: const GridSize(width: 1, height: 1),
    blocksMovement: true,
    npc: const MapEntityNpcData(
      displayName: 'Lysa',
      facing: EntityFacing.south,
      visualElementId: 'grant',
      trainerId: selbrumeLysaTrainerId,
      characterId: selbrumeLysaCharacterId,
    ),
    properties: const <String, String>{
      'contractRole': 'phase_j_lysa_source',
    },
  ).updatedMap;
  await mapRepository.saveMap(
    portMap,
    portPath,
    projectDialogueContext: project,
  );

  var marshMap = await mapRepository.loadMap(marshPath);
  final clueDraft = entityService.addEntityAt(
    marshMap,
    const GridPos(x: 8, y: 32),
    kind: MapEntityKind.custom,
  );
  marshMap = entityService.updateEntity(
    clueDraft.updatedMap,
    entityId: clueDraft.createdEntity.id,
    id: selbrumeClueEntityId,
    name: 'Indice en verre poli',
    blocksMovement: false,
    properties: const <String, String>{
      'contractRole': 'phase_j_clue_source',
      'visualOwnerId': 'pe_marais_indice_verre',
    },
  ).updatedMap;
  await mapRepository.saveMap(
    marshMap,
    marshPath,
    projectDialogueContext: project,
  );

  final rawUuids = <String>[
    '019abcde-4000-7000-8000-000000000001',
    '019abcde-4000-7000-8000-000000000002',
    '019abcde-4000-7000-8000-000000000003',
  ];
  var nextUuid = 0;
  var operation = 0;
  final useCase = NarrativeEventBuilderV2UseCase(
    persistenceGateway: projectRepository,
    idGeneratorFactory: () {
      final raw = rawUuids[nextUuid++];
      return NarrativeEventIdGenerator(rawUuidFactory: () => raw);
    },
    operationIdFactory: () => 'phase_j_${++operation}',
  );
  final intents = <({
    String role,
    String name,
    NarrativeEventSourceRef source,
    String sceneId,
  })>[
    (
      role: 'lysa',
      name: 'Rencontre avec Lysa au port',
      source: NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      ),
      sceneId: selbrumeLysaSceneId,
    ),
    (
      role: 'portEntry',
      name: 'Entrée dans le Port des Brisants',
      source: NarrativeEventSourceRef.triggerEnter(
        selbrumePortMapId,
        selbrumePortEntryTriggerId,
      ),
      sceneId: selbrumePortEntrySceneId,
    ),
    (
      role: 'clue',
      name: 'Indice du verre poli',
      source: NarrativeEventSourceRef.entityInteract(
        selbrumeMarshMapId,
        selbrumeClueEntityId,
      ),
      sceneId: selbrumeClueSceneId,
    ),
  ];
  final eventIds = <String, String>{};
  for (final intent in intents) {
    final created = await useCase.create(
      projectPath: projectPath,
      request: NarrativeEventBuilderV2CreationRequest(
        name: intent.name,
        source: intent.source,
        sceneId: intent.sceneId,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        publish: true,
      ),
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!created.succeeded || created.eventId == null) {
      throw StateError('${created.code}: ${created.message}');
    }
    final activated = await useCase.setEnabled(
      projectPath: projectPath,
      eventId: created.eventId!,
      enabled: true,
      environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
    );
    if (!activated.succeeded) {
      throw StateError('${activated.code}: ${activated.message}');
    }
    eventIds[intent.role] = created.eventId!;
  }
  return eventIds;
}

Future<Map<String, String>?> _existingSelbrumeSlice({
  required Directory projectRoot,
  required ProjectManifest project,
  required FileMapRepository mapRepository,
}) async {
  final registry = project.eventRegistry;
  if (registry == null || registry.mode != EventSystemMode.dualRead) {
    return null;
  }
  final expected = <String, ({NarrativeEventSourceRef source, String sceneId})>{
    'lysa': (
      source: NarrativeEventSourceRef.entityInteract(
        selbrumePortMapId,
        selbrumeLysaEntityId,
      ),
      sceneId: selbrumeLysaSceneId,
    ),
    'portEntry': (
      source: NarrativeEventSourceRef.triggerEnter(
        selbrumePortMapId,
        selbrumePortEntryTriggerId,
      ),
      sceneId: selbrumePortEntrySceneId,
    ),
    'clue': (
      source: NarrativeEventSourceRef.entityInteract(
        selbrumeMarshMapId,
        selbrumeClueEntityId,
      ),
      sceneId: selbrumeClueSceneId,
    ),
  };
  final result = <String, String>{};
  for (final entry in expected.entries) {
    final matches = registry.records.where((record) {
      final definition = record.definitionOrNull;
      return record.enabledOrNull == true &&
          definition?.source == entry.value.source &&
          definition?.sceneId == entry.value.sceneId &&
          definition?.reusePolicy == NarrativeEventReusePolicy.oneShot;
    }).toList(growable: false);
    if (matches.length != 1) return null;
    result[entry.key] = matches.single.id;
  }
  if (!project.characters.any((entry) => entry.id == selbrumeLysaCharacterId) ||
      !project.trainers.any((entry) => entry.id == selbrumeLysaTrainerId) ||
      !<String>{for (final scene in project.scenes) scene.id}.containsAll(
        const <String>{
          selbrumeLysaSceneId,
          selbrumePortEntrySceneId,
          selbrumeClueSceneId,
        },
      )) {
    return null;
  }
  final portEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final marshEntry = project.maps.singleWhere(
    (entry) => entry.id == selbrumeMarshMapId,
  );
  final port = await mapRepository.loadMap(
    p.join(projectRoot.path, portEntry.relativePath),
  );
  final marsh = await mapRepository.loadMap(
    p.join(projectRoot.path, marshEntry.relativePath),
  );
  if (!port.entities.any((entry) => entry.id == selbrumeLysaEntityId) ||
      !port.triggers.any((entry) => entry.id == selbrumePortEntryTriggerId) ||
      !marsh.entities.any((entry) => entry.id == selbrumeClueEntityId)) {
    return null;
  }
  return result;
}

Future<void> _validateProjectClosure({
  required Directory projectRoot,
  required ProjectManifest project,
  required FileMapRepository mapRepository,
}) async {
  for (final entry in project.maps) {
    await mapRepository.loadMap(p.join(projectRoot.path, entry.relativePath));
  }
  for (final entry in project.dialogues) {
    if (!await File(p.join(projectRoot.path, entry.relativePath)).exists()) {
      throw StateError('Missing dialogue dependency: ${entry.relativePath}');
    }
  }
  for (final entry in project.tilesets) {
    if (!await File(p.join(projectRoot.path, entry.relativePath)).exists()) {
      throw StateError('Missing tileset dependency: ${entry.relativePath}');
    }
  }
}

Future<String> selbrumeAuthoringFingerprint(Directory root) async {
  final files = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = p.posix.normalize(
      p.relative(entity.path, from: root.path).replaceAll(r'\', '/'),
    );
    if (relative == 'project.json' ||
        relative.startsWith('maps/') ||
        relative.startsWith('dialogues/')) {
      files.add(entity);
    }
  }
  files.sort((a, b) => p
      .relative(a.path, from: root.path)
      .compareTo(p.relative(b.path, from: root.path)));
  final evidence = <String>[];
  for (final file in files) {
    final relative = p.posix.normalize(
      p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
    );
    evidence.add(
      '$relative:${narrativeEventBytesFingerprint(await file.readAsBytes())}',
    );
  }
  return narrativeEventBytesFingerprint(utf8.encode(evidence.join('\n')));
}

Directory findPokemonProjectRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync() &&
        File(p.join(current.path, 'AGENTS.md')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = parent;
  }
}

Future<void> _cloneProject(Directory source, Directory destination) async {
  final result = await Process.run(
    '/bin/cp',
    <String>['-cR', source.path, destination.path],
  );
  if (result.exitCode == 0) return;
  await _copyDirectory(source, destination);
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await destination.create(recursive: true);
  await for (final entity
      in source.list(recursive: false, followLinks: false)) {
    final target = p.join(destination.path, p.basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(target));
    } else if (entity is File) {
      await entity.copy(target);
    }
  }
}

Future<void> _removeLocalArtifacts(Directory root) async {
  final removals = <FileSystemEntity>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final name = p.basename(entity.path);
    if (name == '.DS_Store' ||
        name == '.dart_tool' ||
        name == 'build' ||
        name == '.pokemap' ||
        name.startsWith('.pokemap-project-') ||
        name.endsWith('.lock')) {
      removals.add(entity);
    }
  }
  removals.sort((a, b) => b.path.length.compareTo(a.path.length));
  for (final entity in removals) {
    if (await entity.exists()) {
      await entity.delete(recursive: entity is Directory);
    }
  }
}
