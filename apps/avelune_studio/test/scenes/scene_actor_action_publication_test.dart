import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_actor_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

SceneAsset _scene(SceneActionPayload payload) => SceneAsset(
  id: 'editable-actor',
  name: 'Acteur éditable',
  metadata: const {'original': 'synthetic'},
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'action',
        kind: SceneNodeKind.action,
        title: 'Keep title',
        payload: payload,
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'action',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: port,
          fromNodeId: 'action',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

class _Fixture {
  _Fixture(this.root, this.session, this.maps, this.project, this.map);
  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final ProjectManifest project;
  final MapData map;
  File get mapFile => File('${root.path}/maps/alpha.json');

  static Future<_Fixture> create() async {
    final temporary = await Directory.systemTemp.createTemp(
      'actor_guided_publication_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    for (final path in ['maps', 'assets', 'audio']) {
      await Directory('${root.path}/$path').create();
    }
    final project = ProjectManifest(
      name: 'Original guided actor QA',
      maps: const [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'sheet',
          name: 'Original sheet',
          relativePath: 'assets/sheet.png',
        ),
      ],
      characters: [
        ProjectCharacterEntry(
          id: 'character',
          name: 'Original actor',
          tilesetId: 'sheet',
          frameHeight: 1,
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: direction,
                frames: const [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                  ),
                ],
              ),
          ],
        ),
      ],
      cinematicMediaAssets: [
        CinematicMediaAsset(
          id: 'sound',
          label: 'Original sound',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'audio/sound.wav',
        ),
      ],
    );
    final map = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: const GridSize(width: 4, height: 4),
      entities: const [
        MapEntity(
          id: 'actor',
          name: 'Actor',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          npc: MapEntityNpcData(characterId: 'character'),
        ),
      ],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/maps/alpha.json')
        .writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/assets/sheet.png').writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAL0lEQVR4nO3OIQEAAAgDMKIShSg0hRg3E/Ornr2kEhAQEBAQEBAQEBAQEBAQEBAQSAcejaD8iD3577EAAAAASUVORK5CYII=',
      ),
    );
    final wav = Uint8List(46);
    final data = ByteData.sublistView(wav);
    wav.setRange(0, 4, ascii.encode('RIFF'));
    data.setUint32(4, 38, Endian.little);
    wav.setRange(8, 16, ascii.encode('WAVEfmt '));
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, 8000, Endian.little);
    data.setUint32(28, 16000, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    wav.setRange(36, 40, ascii.encode('data'));
    data.setUint32(40, 2, Endian.little);
    await File('${root.path}/audio/sound.wav').writeAsBytes(wav);
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final loaded = await maps.loadProject(session);
    final document = await maps.loadMap(session, loaded.maps.single);
    return _Fixture(root, session, maps, loaded, document.map);
  }
}

Future<SceneActionPayload> _edit(
  ProjectManifest project,
  MapData map,
  SceneActionPayload payload, {
  required bool change,
}) async {
  final ready = Completer<void>();
  late SceneActorActionDraft draft;
  draft = SceneActorActionDraft(
    project: project,
    commandId: payload.interactiveCommand is SceneActorRouteInteractiveCommand
        ? NarrativeCommandIds.actorRoute
        : NarrativeCommandIds.actorVisibility,
    current: payload,
    loadMap: (_) async => map,
    changed: () {
      if (!draft.loading && !ready.isCompleted) ready.complete();
    },
  );
  try {
    await ready.future;
    if (change) {
      if (draft.isRoute) {
        draft.steps.first.durationText = '125';
        final visibility = draft.steps.firstWhere(
          (step) => step.kind == SceneActorRouteStepKind.visibility,
        );
        expect(visibility.enabled, isFalse);
        visibility.enabled = true;
      } else {
        draft.visible = !draft.visible;
      }
    }
    expect(draft.valid, isTrue, reason: draft.mapError);
    return draft.payload!;
  } finally {
    draft.dispose();
  }
}

void main() {
  for (final mode in ['visibility', 'route', 'egress']) {
    final route = mode != 'visibility';
    final egress = mode == 'egress';
    test(
      'actor $mode draft publishes through scene.upsert then cold reopens',
      () async {
        final f = await _Fixture.create();
        addTearDown(() => f.root.delete(recursive: true));
        final target = egress
            ? SceneActorTarget.player(mapId: 'alpha')
            : SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor');
        final payload = SceneActionPayload.interactive(
          route
              ? SceneInteractiveCommand.actorRoute(
                  target: target,
                  steps: [
                    SceneActorRouteStep.face(
                      direction: EntityFacing.east,
                      durationMs: 50,
                    ),
                    SceneActorRouteStep.move(
                      direction: EntityFacing.south,
                      durationMs: 200,
                      initialCollisionOwnerEntityId: egress ? 'actor' : null,
                    ),
                    SceneActorRouteStep.wait(durationMs: 0),
                    SceneActorRouteStep.through(enabled: true),
                    SceneActorRouteStep.visibility(visible: false),
                    SceneActorRouteStep.visibility(visible: true),
                    SceneActorRouteStep.sound(
                      mediaAssetId: 'sound',
                      gain: 0.35,
                    ),
                  ],
                  skippable: true,
                )
              : SceneInteractiveCommand.actorVisibility(
                  target: target,
                  visible: false,
                ),
          actionKind: 'keep-action',
          parameters: const {'keep': 'parameter'},
        );
        final edited = await _edit(f.project, f.map, payload, change: true);
        expect(edited, isNot(payload));
        expect(edited.actionKind, payload.actionKind);
        expect(edited.parameters, payload.parameters);
        if (route) {
          expect(
            (edited.interactiveCommand as SceneActorRouteInteractiveCommand)
                .steps
                .whereType<SceneActorVisibilityStep>()
                .map((step) => step.visible),
            [true, true],
          );
        }
        if (egress) {
          final command =
              edited.interactiveCommand as SceneActorRouteInteractiveCommand;
          expect(command.target, SceneActorTarget.player(mapId: 'alpha'));
          expect(
            command.steps
                .whereType<SceneActorMoveStep>()
                .single
                .initialCollisionOwnerEntityId,
            'actor',
          );
        }
        final mapBefore = await f.mapFile.readAsBytes();
        final scene = _scene(edited);
        final receipt = await LocalSceneAdapter(
          session: f.session,
          mapAdapter: f.maps,
        ).publishScene(base: null, current: scene);
        expect(receipt.catalog.changedPaths, ['project.json']);
        final reopenedMaps = LocalMapWorkspaceAdapter();
        final reopened = await reopenedMaps.loadProject(f.session);
        expect(reopened.scenes.single, scene);
        expect(await f.mapFile.readAsBytes(), mapBefore);
        final loaded = await reopenedMaps.loadMap(
          f.session,
          reopened.maps.single,
        );
        final stored =
            reopened.scenes.single.graph.nodes
                    .singleWhere((n) => n.id == 'action')
                    .payload
                as SceneActionPayload;
        final reapplied = await _edit(
          reopened,
          loaded.map,
          stored,
          change: false,
        );
        expect(reapplied, edited);
        expect(reopened.scenes.single.metadata, const {
          'original': 'synthetic',
        });
        expect(
          reopened.scenes.single.graph.nodes
              .singleWhere((n) => n.id == 'action')
              .title,
          'Keep title',
        );
      },
    );
  }
}
