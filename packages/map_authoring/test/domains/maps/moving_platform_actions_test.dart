import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';

void main() {
  for (final jsonl in [false, true]) {
    test(
        'platform upsert and delete through ${jsonl ? 'JSONL' : 'direct API'} preserve ordinary map content',
        () async {
      final host = await ResourceInformationFixture.create(_project());
      addTearDown(host.dispose);
      final mapFile = File('${host.root.path}/map.json');
      await mapFile.writeAsString(jsonEncode(_map().toJson()));
      await File('${host.root.path}/project.json').writeAsString(jsonEncode(
          _project().copyWith(maps: const [
        ProjectMapEntry(id: 'gym', name: 'Gym', relativePath: 'map.json')
      ]).toJson()));
      Future<void> mutate(
          String action, Map<String, Object?> parameters) async {
        if (jsonl) {
          await host.mutate(action, parameters);
        } else {
          final snapshot =
              await host.snapshots.load(ProjectHandle(host.project));
          final key = 'direct-${host.next++}';
          final before = await mapFile.readAsBytes();
          final planned = await host.mutations.planMutation(
              ProjectHandle(host.project),
              AuthoringRequest(
                  requestId: key,
                  actionId: action,
                  actionVersion: 1,
                  workspaceHandle: host.workspace,
                  parameters: parameters,
                  expectedRevision: snapshot.revision,
                  idempotencyKey: key));
          expect(await mapFile.readAsBytes(), before);
          final applied = await host.mutations.applyMutation(
              ProjectHandle(host.project),
              planId: planned.planId,
              operationId: key);
          expect(applied.receipt.status, AuthoringReceiptStatus.applied);
        }
      }

      await mutate('map.platform.upsert',
          {'mapId': 'gym', 'platform': _platform().toJson()});
      var map = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(map.movingPlatforms.single.toJson(), _platform().toJson());
      expect(map.placedElements, _map().placedElements);
      expect(map.layers, _map().layers);
      final updated = _platform().toJson()..['translationDistanceCells'] = 6;
      await mutate(
          'map.platform.upsert', {'mapId': 'gym', 'platform': updated});
      map = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(map.movingPlatforms.length, 1);
      final scene = SceneAsset(
          id: 'platform-scene',
          name: 'Platform',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'move',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.movePlatform(
                        mapId: 'gym',
                        platformId: 'bridge',
                        motion: MovingPlatformMotion.forward))),
            SceneNode(id: 'end', kind: SceneNodeKind.end)
          ], edges: [
            SceneEdge(
                id: 'start',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'move',
                kind: SceneEdgeKind.defaultFlow),
            for (final outcome in [
              'moved',
              'blocked',
              'notRiding',
              'rotationRequiresPivot'
            ])
              SceneEdge(
                  id: outcome,
                  fromNodeId: 'move',
                  fromPortId: outcome,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.defaultFlow),
          ]));
      final manifestPath = File('${host.root.path}/project.json');
      final manifest = ProjectManifest.fromJson(
          jsonDecode(await manifestPath.readAsString()));
      await manifestPath.writeAsString(
          jsonEncode(manifest.copyWith(scenes: [scene]).toJson()));
      final referenced = await host.plan(
          'map.platform.delete', {'mapId': 'gym', 'platformId': 'bridge'});
      expect(referenced.status, AuthoringResultStatus.failure);
      expect(
          jsonEncode(referenced.toJson()), contains('map.platform_referenced'));
      await manifestPath.writeAsString(jsonEncode(manifest.toJson()));
      await mutate(
          'map.platform.delete', {'mapId': 'gym', 'platformId': 'bridge'});
      map = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(map.movingPlatforms, isEmpty);
      expect(map.placedElements, _map().placedElements);
      final invalid = _platform().toJson();
      invalid['terrainLayerIds'] = ['solid'];
      final planned = await host
          .plan('map.platform.upsert', {'mapId': 'gym', 'platform': invalid});
      expect(planned.status, AuthoringResultStatus.failure);
      expect(
          (MapData.fromJson(jsonDecode(await mapFile.readAsString())))
              .movingPlatforms,
          isEmpty);
    });
  }
}

MovingPlatformDefinition _platform() => MovingPlatformDefinition(
        id: 'bridge',
        placedElementId: 'art',
        initialPose: MovingPlatformPose(leftPx: 64, topPx: 64, quarterTurns: 0),
        lattice: MovingPlatformLattice(
            widthPx: 32,
            heightPx: 24.03323336836951,
            originLeftPx: 0,
            originTopPx: 0,
            cellOffsetLeftPx: 0,
            cellOffsetTopPx: 0),
        translationDistanceCells: 5,
        terrainLayerIds: {
          'magma'
        },
        travelCells: const [
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2)
        ],
        variants: [
          for (var i = 0; i < 4; i++)
            MovingPlatformVariant(
                elementId: 'platform',
                anchorOffsetPx: const GridPos(x: 0, y: 0),
                supportCells: const [GridPos(x: 0, y: 0)],
                clearanceCells: const [GridPos(x: 0, y: 0)],
                forwardClearanceCells: const [GridPos(x: 0, y: 0)],
                backwardClearanceCells: const [GridPos(x: 0, y: 0)],
                rotationClearanceCells: const [GridPos(x: 0, y: 0)])
        ]);

MapData _map() => MapData(
        id: 'gym',
        name: 'Gym',
        size: const GridSize(width: 10, height: 10),
        layers: [
          MapLayer.tile(id: 'magma', name: 'Magma', cells: List.filled(100, 0)),
          MapLayer.collision(
              id: 'solid', name: 'Walls', collisions: List.filled(100, false))
        ],
        placedElements: const [
          MapPlacedElement(
              id: 'art',
              elementId: 'platform',
              layerId: 'magma',
              pos: GridPos(x: 2, y: 2),
              applyCollision: false,
              properties: {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              })
        ]);

ProjectManifest _project() => const ProjectManifest(
    name: 'Platform authoring',
    maps: [],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
    tilesets: [
      ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
    ],
    elements: [
      ProjectElementEntry(
          id: 'platform',
          name: 'Platform',
          tilesetId: 'tiles',
          categoryId: 'platform',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2))
          ])
    ]);
