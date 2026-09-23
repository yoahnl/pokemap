import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'm3_story_fixture.dart';

Future<void> prepareGameExportFixture(M3StoryFixture source) async {
  final projectFile = File(p.join(source.directory.path, 'project.json'));
  final project = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  final startEntry = project.maps.first;
  final targetEntry = project.maps.last;
  final startFile = File(p.join(source.directory.path, startEntry.relativePath));
  final start = MapData.fromJson(
    jsonDecode(await startFile.readAsString()) as Map<String, dynamic>,
  );
  final startMap = start.copyWith(
    triggers: [
      for (final trigger in start.triggers)
        if (trigger.id == 'quai')
          trigger.copyWith(
            area: const MapRect(
              pos: GridPos(x: 8, y: 8),
              size: GridSize(width: 1, height: 1),
            ),
          )
        else
          trigger,
    ],
    entities: [
      for (final entity in start.entities)
        if (entity.id == 'depart')
          entity.copyWith(
            spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
          )
        else
          entity,
    ],
    warps: [
      ...start.warps,
      MapWarp(
        id: 'export-passage',
        pos: const GridPos(x: 9, y: 9),
        targetMapId: targetEntry.id,
        targetPos: const GridPos(x: 8, y: 9),
      ),
    ],
  );
  await startFile.writeAsString(jsonEncode(startMap.toJson()), flush: true);
  final configured = project.copyWith(
    storylines: const [],
    facts: const [],
    dialogues: project.dialogues.where((entry) => entry.id == 'zone').toList(),
    scenes: [
      ...project.scenes.where((scene) => scene.id.endsWith('000000000007')),
      _completionScene(),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: project.eventRegistry!.records
          .where((record) => record.id.endsWith('000000000007'))
          .toList()
        ..add(NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: 'evt_019abcde-6000-7000-8000-000000000001',
            name: 'Arrivée dans la clairière',
            source: NarrativeEventSourceRef.mapEnter(targetEntry.id),
            conditions: const [],
            sceneId: 'scene.export.complete',
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        )),
      legacyClaims: const [],
    ),
    pokemon: const ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      enabled: false,
    ),
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: startEntry.id,
      startSpawnId: 'depart',
      playerName: 'Joueur',
    ),
  );
  await projectFile.writeAsString(jsonEncode(configured.toJson()), flush: true);
}

SceneAsset _completionScene() => SceneAsset(
  id: 'scene.export.complete',
  name: 'Fin de la traversée',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'finish',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.finishGame(
            endingId: 'ending.export.complete',
            outcome: SceneGameCompletionOutcome.completed,
            result: SceneFinishGameResult(
              title: SceneLocalizedText(fallback: 'Traversée terminée'),
              summary: SceneLocalizedText(fallback: 'La clairière est atteinte.'),
            ),
            postGamePolicy: ScenePostGamePolicy.returnToTitle,
          ),
        ),
      ),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(outcomePolicy: SceneOutcomePolicy.progression),
      ),
    ],
    edges: [
      SceneEdge(id: 'start-finish', fromNodeId: 'start',
        fromPortId: 'completed', toNodeId: 'finish',
        kind: SceneEdgeKind.defaultFlow),
      SceneEdge(id: 'finish-end', fromNodeId: 'finish',
        fromPortId: 'completed', toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow),
    ],
  ),
);
