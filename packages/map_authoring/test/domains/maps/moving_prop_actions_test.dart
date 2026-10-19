import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';

void main() {
  test(
      'guided prop identities preserve existing API props when generated IDs collide',
      () {
    final existing = MovingPropDefinition.fromJson(
        {...propDefinition().toJson(), 'id': 'prop-other'});
    final source = propMap();
    final map = source.copyWith(movingProps: [
      existing
    ], placedElements: [
      ...source.placedElements,
      source.placedElements.single
          .copyWith(id: 'other', pos: const GridPos(x: 5, y: 2)),
    ]);
    final editing = const MovingPropEditing();
    final created = editing.definition(
        map: map,
        project: propProject(),
        placedElementId: 'other',
        direction: EntityFacing.east,
        distancePx: 32,
        collisionRect:
            const PixelRect(leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32));
    expect(created.id, 'prop-other-2');
    final updated =
        editing.upsert(map: map, project: propProject(), prop: created);
    expect(updated.movingProps, [existing, created]);
    final reopened = editing.definition(
        map: updated,
        project: propProject(),
        placedElementId: 'other',
        direction: EntityFacing.east,
        distancePx: 64,
        collisionRect:
            const PixelRect(leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32));
    expect(reopened.id, created.id);
    expect(map.movingProps, [existing]);
  });

  for (final jsonl in [false, true]) {
    test(
        'props use ${jsonl ? 'JSONL' : 'direct API'} with atomic invalid/reference refusal',
        () async {
      final map = propMap();
      final project = propProject();
      final host = await ResourceInformationFixture.create(
          project.copyWith(maps: const []));
      addTearDown(host.dispose);
      final file = File('${host.root.path}/hall.json');
      await file.writeAsString(jsonEncode(map.toJson()));
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      Future<void> mutate(
          String action, Map<String, Object?> parameters) async {
        if (jsonl) {
          await host.mutate(action, parameters);
          return;
        }
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final id = 'direct-${host.next++}';
        final before = await file.readAsBytes();
        final plan = await host.mutations.planMutation(
            ProjectHandle(host.project),
            AuthoringRequest(
                requestId: id,
                actionId: action,
                actionVersion: 1,
                workspaceHandle: host.workspace,
                parameters: parameters,
                expectedRevision: snapshot.revision,
                idempotencyKey: id));
        expect(await file.readAsBytes(), before);
        final result = await host.mutations.applyMutation(
            ProjectHandle(host.project),
            planId: plan.planId,
            operationId: id);
        expect(result.receipt.status, AuthoringReceiptStatus.applied);
      }

      await mutate('map.prop.upsert',
          {'mapId': 'hall', 'prop': propDefinition().toJson()});
      final authored = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(authored.movingProps, [propDefinition()]);
      expect(authored.placedElements, map.placedElements);
      expect(authored.layers, map.layers);
      final before = await file.readAsBytes();
      final invalid = await host.plan('map.prop.upsert', {
        'mapId': 'hall',
        'prop': {...propDefinition().toJson(), 'placedElementId': 'missing'}
      });
      expect(invalid.status, AuthoringResultStatus.failure);
      expect(jsonEncode(invalid.toJson()), contains('map.prop_invalid'));
      expect(await file.readAsBytes(), before);
      await mutate('scene.upsert', {'scene': propScene().toJson()});
      final simulation = await host.command('query', {
        'projectHandle': host.project,
        'request': AuthoringQueryRequest(
            resourceKind: 'scene',
            operation: AuthoringQueryOperation.get,
            ids: [
              'gate-scene'
            ],
            extensions: {
              'actionId': 'scene.simulate',
              'parameters': {
                'portsByNodeId': {'move': 'moved'}
              }
            }).toJson(),
      });
      expect(simulation.status, AuthoringResultStatus.success);
      final result = (simulation.data['items'] as List).single as Map;
      expect(result['mountedPlayer'], isFalse);
      expect(result['effects'], 'proposedOnly');
      final movement = (result['proposedPropMovements'] as List).single as Map;
      expect(movement['collisionChecked'], isFalse);
      expect(movement['motionExecuted'], isFalse);
      expect(movement['selectedOutputPort'], 'moved');
      expect(await file.readAsBytes(), before);
      final missing = propScene(propIds: ['missing']);
      final invalidScene =
          await host.plan('scene.upsert', {'scene': missing.toJson()});
      expect(invalidScene.status, AuthoringResultStatus.failure);
      expect(await file.readAsBytes(), before);
      final referenced = await host
          .plan('map.prop.delete', {'mapId': 'hall', 'propId': 'gate'});
      expect(referenced.status, AuthoringResultStatus.failure);
      expect(jsonEncode(referenced.toJson()), contains('map.prop_referenced'));
      expect(await file.readAsBytes(), before);
      await File('${host.root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await mutate('map.prop.delete', {'mapId': 'hall', 'propId': 'gate'});
      final removed = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(removed.movingProps, isEmpty);
      expect(removed.placedElements, map.placedElements);
      final restarted = await host.snapshots.load(ProjectHandle(host.project));
      expect(restarted.maps.single.movingProps, isEmpty);
      final open = {...propDefinition().toJson(), 'initialState': 'open'};
      await mutate('map.prop.upsert', {'mapId': 'hall', 'prop': open});
      var openMap = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(openMap.placedElements.single.pos, const GridPos(x: 3, y: 2));
      await mutate('placed_element.set_geometry', {
        'mapId': 'hall',
        'instanceId': 'art',
        'pixelX': 128,
        'pixelY': 64,
        'pixelSize': null
      });
      openMap = MapData.fromJson(jsonDecode(await file.readAsString()));
      expect(openMap.movingProps.single.closedPositionPx,
          const PixelOffset(x: 96, y: 64));
      expect(openMap.movingProps.single.openPositionPx,
          const PixelOffset(x: 128, y: 64));
      expect(openMap.placedElements.single.pos, const GridPos(x: 4, y: 2));
      final positioned = await file.readAsBytes();
      final outside = await host.plan('placed_element.set_geometry', {
        'mapId': 'hall',
        'instanceId': 'art',
        'pixelX': 0,
        'pixelY': 64,
        'pixelSize': null
      });
      expect(outside.status, AuthoringResultStatus.failure);
      expect(await file.readAsBytes(), positioned);
    });
  }
}

MovingPropDefinition propDefinition() => MovingPropDefinition(
    id: 'gate',
    placedElementId: 'art',
    closedPositionPx: const PixelOffset(x: 64, y: 64),
    openPositionPx: const PixelOffset(x: 96, y: 64),
    collisionRect:
        const PixelRect(leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32));

MapData propMap() => MapData(
        id: 'hall',
        name: 'Hall',
        size: const GridSize(width: 10, height: 10),
        layers: [
          MapLayer.tile(id: 'art', name: 'Décor', cells: List.filled(100, 0))
        ],
        placedElements: const [
          MapPlacedElement(
              id: 'art',
              elementId: 'gate-art',
              layerId: 'art',
              pos: GridPos(x: 2, y: 2),
              applyCollision: false,
              properties: {
                pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored
              })
        ]);

ProjectManifest propProject() => const ProjectManifest(
    name: 'Props',
    maps: [
      ProjectMapEntry(id: 'hall', name: 'Hall', relativePath: 'hall.json')
    ],
    settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
    tilesets: [
      ProjectTilesetEntry(id: 'tiles', name: 'Tiles', relativePath: 'tiles.png')
    ],
    elements: [
      ProjectElementEntry(
          id: 'gate-art',
          name: 'Grille',
          tilesetId: 'tiles',
          categoryId: 'decor',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
          ])
    ]);

SceneAsset propScene({List<String> propIds = const ['gate']}) => SceneAsset(
    id: 'gate-scene',
    name: 'Grille',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'move',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.setPropState(
                  mapId: 'hall',
                  propIds: propIds,
                  state: MovingPropState.open))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'move',
          kind: SceneEdgeKind.defaultFlow),
      for (final port in ['moved', 'blocked'])
        SceneEdge(
            id: port,
            fromNodeId: 'move',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow),
    ]));
