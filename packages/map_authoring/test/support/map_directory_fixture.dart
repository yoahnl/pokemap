import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import 'narrative_title_fixture.dart';

MapData mapDirectoryMap(int index, {String npcName = 'Professor'}) => MapData(
      id: 'map_$index',
      name: 'Map $index',
      size: const GridSize(width: 8, height: 8),
      entities: [
        MapEntity(
            id: 'npc_$index',
            name: 'npc_$index',
            kind: MapEntityKind.npc,
            pos: GridPos(x: index, y: 2),
            npc: MapEntityNpcData(
                displayName: npcName,
                characterId: index == 0 ? 'character_0' : null)),
      ],
      triggers: [
        MapTrigger(
            id: 'trigger_$index',
            name: 'Doorway',
            type: TriggerType.event,
            area: const MapRect(
                pos: GridPos(x: 3, y: 4), size: GridSize(width: 1, height: 1))),
      ],
    );

ProjectManifest mapDirectoryProject(int maps) {
  final base = narrativeTitleProject(unrelated: maps);
  return base.copyWith(
    scenes: [
      ...base.scenes,
      SceneAsset(
        id: 'scene_talk',
        name: 'Talk',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'talk',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: 'greet')),
        ], edges: const []),
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        ...base.eventRegistry!.records,
        NarrativeEventRecord.configuredStructurallyUnchecked(
          enabled: true,
          NarrativeEventDefinition(
            id: narrativeTitleEvent(7),
            name: 'Talk to the professor',
            source: NarrativeEventSourceRef.entityInteract('map_0', 'npc_0'),
            conditions: const [],
            sceneId: 'scene_talk',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 7,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

Future<void> writeMapDirectoryFiles(Directory root, int maps) async {
  for (var index = 0; index < maps; index++) {
    final file = File('${root.path}/maps/map_$index.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(mapDirectoryMap(index).toJson()));
  }
  final dialogue = File('${root.path}/dialogues/greet.yarn');
  await dialogue.parent.create(recursive: true);
  await dialogue.writeAsString('title: Start\n---\nWelcome to the lab.\n===\n');
}

Future<NarrativeTitleFixture> createMapDirectoryFixture(
    {int maps = 2, Directory? at}) async {
  final fixture = await NarrativeTitleFixture.create(
      at: at, project: mapDirectoryProject(maps));
  await writeMapDirectoryFiles(fixture.root, maps);
  return fixture;
}

Future<String> publishRenamedNpc(
    NarrativeTitleFixture fixture, int index, String name) async {
  final file = File('${fixture.root.path}/maps/map_$index.json');
  return fixture.apply(
      'narrative.publish_document',
      {
        'map': mapDirectoryMap(index, npcName: name).toJson(),
        'mapRevision': narrativeEventBytesFingerprint(await file.readAsBytes()),
      },
      'rename-$index-$name');
}
