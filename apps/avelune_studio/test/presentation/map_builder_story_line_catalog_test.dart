import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_line.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_workshop.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_commands.dart';
import 'package:avelune_studio/features/scenes/application/steps/scene_step_patch.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/story_draft/application/story_publication_gateway.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/world/data/local_world_adapter.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<ProjectSession> _catalog() async {
  final temporary = await Directory.systemTemp.createTemp('story_line_');
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  await WorkingProjectCatalog.create(
    store: await CatalogStorageStore.open(projectRoot: root.path),
    projectId: 'story-line',
    project: ProjectManifest(
      name: 'Bourg',
      maps: const [
        ProjectMapEntry(
          id: 'bourg',
          name: 'Bourg',
          relativePath: 'maps/bourg.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas',
          relativePath: 'atlas.png',
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: const [],
        legacyClaims: const [],
      ),
    ),
  );
  final map = MapData(
    id: 'bourg',
    name: 'Bourg',
    size: const GridSize(width: 8, height: 8),
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Sol',
        palette: [
          const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
        ],
        cells: List.filled(64, 0),
      ),
    ],
    entities: const [
      MapEntity(
        id: 'guide',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 2),
        npc: MapEntityNpcData(displayName: 'Guide'),
      ),
    ],
  );
  final file = File('${root.path}/maps/bourg.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
  return ProjectSession(
    sessionId: 'story-line',
    name: 'Bourg',
    directoryPath: root.path,
    storage: ProjectSessionStorage.workingCatalog,
  );
}

void main() {
  test(
    'a new line saved through the real adapters reads back after reopening',
    () async {
      final session = await _catalog();
      final adapter = LocalMapWorkspaceAdapter();
      final operations = <String>[];
      void count(AuthoringTransactionCheckpointContext context) {
        if (!operations.contains(context.operationId)) {
          operations.add(context.operationId);
        }
      }

      final events = LocalEventAdapter(
        session: session,
        mapAdapter: adapter,
        faultInjector: count,
      );
      final dialogues = LocalDialogueAdapter(
        session: session,
        mapAdapter: adapter,
        faultInjector: count,
      );
      final maps = MapWorkspaceController(session, adapter);
      addTearDown(maps.dispose);
      await maps.initialize();
      await maps.activate(maps.project!.maps.single);
      final story = MapBuilderStoryBinding(
        maps: maps,
        changed: () {},
        view: () => null,
        loadMedia: events.loadPresentationMediaCatalog,
        gateway: (draft, saved) => StoryPublicationGateway(
          draft: draft,
          events: events,
          scenes: LocalSceneAdapter(
            session: session,
            mapAdapter: adapter,
            faultInjector: count,
          ),
          dialogues: dialogues,
          facts: LocalWorldAdapter(session: session, mapAdapter: adapter),
          savedDialogues: saved,
        ),
      );
      await story.prepare();
      expect(story.error, isNull);
      final guide = story.elements!.byKey('entity:guide')!;
      expect(story.addBehaviour(guide), isTrue, reason: story.error);
      final record = story.behaviours.registry(maps.project!)!.records.single;
      expect(
        story.writeLine(guide, record, 'Bienvenue au bourg.\nBonne route !'),
        isTrue,
        reason: story.error,
      );

      expect(await story.save(), isTrue, reason: story.error);
      expect(story.dirty, isFalse);
      expect(operations, hasLength(3), reason: '$operations');

      final fresh = LocalMapWorkspaceAdapter();
      final reopened = MapWorkspaceController(session, fresh);
      addTearDown(reopened.dispose);
      await reopened.initialize();
      await reopened.ensureWorkshop(MapWorkspaceWorkshop.events);
      final saved = reopened.project!.eventRegistry!.records.single;
      expect(saved.id, record.id);
      final scene = reopened.project!.scenes.singleWhere(
        (scene) => scene.id == saved.sceneId,
      );
      final dialogueId = behaviourLineDialogueId(scene)!;
      final snapshot = await LocalDialogueAdapter(
        session: session,
        mapAdapter: fresh,
      ).load(dialogueId);
      final line = readBehaviourLine(
        scene: scene,
        behaviours: [saved],
        dialogue: NarrativeDialogueSource(
          entry: snapshot.entry,
          source: snapshot.source,
          revision: snapshot.revision,
        ),
      );
      expect(line, isA<BehaviourLine>());
      expect((line as BehaviourLine).lines, [
        'Bienvenue au bourg.',
        'Bonne route !',
      ]);
      expect(
        story.behaviours.dialogues[dialogueId],
        StoryDialogueSource(entry: snapshot.entry, source: snapshot.source),
      );
      expect(
        story.behaviours.dialogues[dialogueId]?.revision,
        snapshot.revision,
      );

      final base = story.sceneOf(scene.id)!;
      expect(base, scene);
      final talk = base.graph.nodes.singleWhere(
        (node) => node.kind == SceneNodeKind.yarnDialogue,
      );
      var next = 0;
      final inserted = insertSceneStep(
        base,
        at: const SceneStepSlot(index: 1),
        kind: talk.kind,
        payload: talk.payload,
        ids: SceneStepIds(
          node: () => 'again_${next++}',
          edge: () => 'again_link_${next++}',
        ),
      );
      final edited = (inserted as SceneStepEdited).scene;
      expect(
        sceneGraphPatchForScenes(base: base, current: edited),
        isA<SceneGraphPatchReady>(),
      );
      expect(story.editScene(scene.id, edited), isTrue, reason: story.error);
      operations.clear();
      expect(await story.save(), isTrue, reason: story.error);
      expect(story.dirty, isFalse);
      expect(operations, hasLength(1), reason: '$operations');

      final again = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
      addTearDown(again.dispose);
      await again.initialize();
      await again.ensureWorkshop(MapWorkspaceWorkshop.events);
      expect(
        again.project!.scenes.singleWhere((item) => item.id == scene.id),
        edited,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
