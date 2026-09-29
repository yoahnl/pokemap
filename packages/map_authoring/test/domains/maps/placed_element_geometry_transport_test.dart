import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final transport in ['directApi', 'cli']) {
    test('pixel geometry $transport is atomic, strict, ordered and undoable',
        () async {
      final root = await Directory.systemTemp.createTemp('geometry-');
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
          id: 'map',
          name: 'Map',
          size: const GridSize(width: 3, height: 3),
          layers: const [
            MapLayer.tile(
                id: 'decor', name: 'Decor', cells: [0, 0, 0, 0, 0, 0, 0, 0, 0])
          ],
          placedElements: [
            for (final id in ['a', 'b'])
              MapPlacedElement(
                  id: id,
                  elementId: 'prop',
                  layerId: 'decor',
                  pos: const GridPos(x: 1, y: 1),
                  properties: const {
                    'pokemapPlacementOrigin': 'authored',
                    'preserved': 'yes'
                  })
          ]);
      const manifest = ProjectManifest(
          name: 'Geometry',
          settings: ProjectSettings(tileWidth: 16, tileHeight: 32),
          maps: [
            ProjectMapEntry(
                id: 'map', name: 'Map', relativePath: 'maps/map.json')
          ],
          tilesets: [
            ProjectTilesetEntry(
                id: 'ts', name: 'TS', relativePath: 'assets/ts.png')
          ],
          elementCategories: [
            ProjectElementCategory(id: 'cat', name: 'Cat')
          ],
          elements: [
            ProjectElementEntry(
                id: 'prop',
                name: 'Prop',
                tilesetId: 'ts',
                categoryId: 'cat',
                frames: [
                  TilesetVisualFrame(
                      source:
                          TilesetSourceRect(x: 0, y: 0, width: 2, height: 2))
                ])
          ]);
      await Directory('${root.path}/maps').create();
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(manifest.toJson()));
      final mapFile = File('${root.path}/maps/map.json');
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
      final mutations = LocalMapAuthoringMutationApi(
          policy: policy, snapshotLoader: snapshots);
      final worker = JsonlWorker(api: api, mutations: mutations);
      final opened = await api.openProject(root.path);
      await mutations.attachProject(
          projectRootPath: root.path,
          workspaceHandle: opened.workspaceHandle,
          projectHandle: opened.projectHandle);
      var sequence = 0;
      Future<Map<String, Object?>> call(
          String command, Map<String, Object?> args) async {
        if (transport == 'cli') {
          final result = AuthoringResult.fromJson(jsonDecode(
              await worker.processLine(jsonEncode({
            'id': 'geometry-${sequence++}',
            'command': command,
            'args': args
          }))) as Map<String, dynamic>);
          if (result.status != AuthoringResultStatus.success) {
            throw StateError(result.toJson().toString());
          }
          return result.data;
        }
        return switch (command) {
          'plan' => mutations.plan(
              opened.projectHandle,
              AuthoringRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          'apply' => mutations.apply(opened.projectHandle,
              planId: args['planId']! as String,
              operationId: args['operationId']! as String),
          'history' => mutations.history(opened.projectHandle, limit: 1),
          'query' => api.query(
              opened.projectHandle,
              AuthoringQueryRequest.fromJson(
                  Map<String, dynamic>.from(args['request']! as Map))),
          'validate' => api.validate(opened.projectHandle),
          'undo' => mutations.undo(opened.projectHandle,
              entryId: args['entryId']! as String,
              idempotencyKey: args['idempotencyKey']! as String),
          _ => throw StateError(command),
        };
      }

      final described = AuthoringResult.fromJson(jsonDecode(
              await worker.processLine(jsonEncode(
                  {'id': 'describe', 'command': 'describe', 'args': {}})))
          as Map<String, dynamic>);
      expect(
          (described.data['mutationActions']! as List)
              .cast<Map>()
              .any((a) => a['id'] == 'placed_element.set_geometry'),
          isTrue);
      Future<Map<String, Object?>> plan(
          String action, Map<String, Object?> params) async {
        final snapshot = await snapshots.load(opened.projectHandle);
        final request = AuthoringRequest(
            requestId: 'geometry-${sequence++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'geometry-${sequence++}',
            dryRun: false,
            parameters: params);
        return call('plan', {
          'projectHandle': opened.projectHandle.value,
          'request': request.toJson()
        });
      }

      Future<MapData> read() async {
        final page = await call('query', {
          'projectHandle': opened.projectHandle.value,
          'request': AuthoringQueryRequest(
              resourceKind: 'map',
              operation: AuthoringQueryOperation.get,
              view: AuthoringQueryView.detail,
              ids: const ['map']).toJson(),
        });
        return MapData.fromJson(
            Map<String, dynamic>.from((page['items']! as List).single as Map));
      }

      Future<void> apply(String action, Map<String, Object?> params) async {
        final planned = await plan(action, params);
        final result = await call('apply', {
          'projectHandle': opened.projectHandle.value,
          'planId': planned['planId'],
          'operationId': 'apply-${sequence++}'
        });
        expect((result['receipt']! as Map)['status'], 'applied');
      }

      const valid = <String, Object?>{
        'mapId': 'map',
        'instanceId': 'a',
        'pixelX': 17,
        'pixelY': 35,
        'pixelSize': {'width': 5, 'height': 7}
      };
      final before = await mapFile.readAsBytes();
      for (final invalid in <Map<String, Object?>>[
        {...valid}..remove('pixelSize'),
        {...valid, 'pixelX': 17.0},
        {...valid, 'unknown': true},
        {
          ...valid,
          'pixelSize': {'width': 5, 'height': 7, 'extra': 1}
        },
        {
          ...valid,
          'pixelSize': {'width': 5.0, 'height': 7}
        },
        {
          ...valid,
          'pixelSize': {'width': 0, 'height': 7}
        },
        {
          ...valid,
          'pixelSize': {'width': 1048577, 'height': 1}
        },
        {...valid, 'pixelX': -1},
        {...valid, 'pixelX': 48},
        {...valid, 'pixelX': 9007199254740992},
        {...valid, 'instanceId': 'missing'},
      ]) {
        await expectLater(
            plan('placed_element.set_geometry', invalid), throwsA(anything));
        expect(await mapFile.readAsBytes(), before);
      }
      await apply('placed_element.set_geometry', valid);
      final transformed = await read();
      final validation =
          await call('validate', {'projectHandle': opened.projectHandle.value});
      expect((validation['structure']! as Map)['valid'], isTrue);
      expect(transformed.placedElements.map((e) => e.id), ['a', 'b']);
      final instance = transformed.placedElements.first;
      expect(instance.pos, const GridPos(x: 1, y: 1));
      expect(instance.pixelOffset, const PixelOffset(x: 1, y: 3));
      expect(instance.pixelSize, const PixelSize(width: 5, height: 7));
      expect(instance.properties, map.placedElements.first.properties);
      final projection = await const RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
          gameId: 'games.test.geometry',
          gameVersion: '1.0.0',
          title: 'Geometry',
          authorName: 'Test',
          defaultLocale: 'fr',
          supportedLocales: const ['fr'],
        ),
      );
      final exported = MapData.fromJson(jsonDecode(utf8.decode(
        projection.payloadFiles['project/maps/map.json']!,
      )) as Map<String, dynamic>);
      expect(exported.placedElements, transformed.placedElements);
      expect(exported.version, ProjectVersion.v8);
      final delta = MapHistoryDelta.between(map, transformed);
      expect(delta.applyBackward(transformed), map);
      expect(delta.applyForward(map), transformed);
      expect(
          MapData.fromJson(jsonDecode(jsonEncode(transformed.toJson()))
              as Map<String, dynamic>),
          transformed);
      final history = await call(
          'history', {'projectHandle': opened.projectHandle.value, 'limit': 1});
      await call('undo', {
        'projectHandle': opened.projectHandle.value,
        'entryId': ((history['entries']! as List).first as Map)['entryId'],
        'idempotencyKey': 'undo-geometry'
      });
      expect(await mapFile.readAsBytes(), before);
      await apply('placed_element.set_geometry', valid);
      await apply('placed_element.move',
          {'mapId': 'map', 'instanceId': 'a', 'x': 2, 'y': 1});
      expect((await read()).placedElements.first.pixelSize, instance.pixelSize);
      expect((await read()).placedElements.first.pixelOffset,
          instance.pixelOffset);
      await apply('placed_element.clone',
          {'mapId': 'map', 'instanceId': 'a', 'newId': 'c', 'x': 0, 'y': 0});
      expect((await read()).placedElements.last.pixelSize, instance.pixelSize);
      expect(
          (await read()).placedElements.last.pixelOffset, instance.pixelOffset);
      await apply('placed_element.update', {
        'mapId': 'map',
        'instanceId': 'a',
        'instance': (await read()).placedElements.first.copyWith(
          opacity: 0.5,
          properties: const {
            'pokemapPlacementOrigin': 'authored',
            ' label ': ' value '
          },
          behaviors: const [
            MapPlacedElementBehavior(
              trigger: MapPlacedElementTriggerType.onAction,
              effect: MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: ' Test '),
            )
          ],
        ).toJson()
      });
      expect((await read()).placedElements.map((e) => e.id), ['a', 'b', 'c']);
      expect((await read()).placedElements.first.behaviors.single.id,
          'a::behavior::0');
      expect((await read()).placedElements.first.properties['label'], 'value');
      expect(
          (await read()).placedElements.first.behaviors.single.effect.message,
          'Test');
      await apply('placed_element.set_geometry',
          {...valid, 'pixelX': 16, 'pixelY': 32, 'pixelSize': null});
      expect((await read()).placedElements.first.pixelSize, isNull);
      await apply('placed_element.update', {
        'mapId': 'map',
        'instanceId': 'b',
        'instance': (await read())
            .placedElements[1]
            .copyWith(properties: const {}).toJson(),
      });
      final generatedBefore = await mapFile.readAsBytes();
      await expectLater(
          plan('placed_element.set_geometry', {...valid, 'instanceId': 'b'}),
          throwsA(anything));
      expect(await mapFile.readAsBytes(), generatedBefore);
      final stale = await plan('placed_element.set_geometry', valid);
      await apply('placed_element.set_opacity',
          {'mapId': 'map', 'instanceId': 'a', 'opacity': 0.75});
      final concurrentBefore = await mapFile.readAsBytes();
      await expectLater(
          call('apply', {
            'projectHandle': opened.projectHandle.value,
            'planId': stale['planId'],
            'operationId': 'stale-apply'
          }),
          throwsA(anything));
      expect(await mapFile.readAsBytes(), concurrentBefore);
      await apply('placed_element.update', {
        'mapId': 'map',
        'instanceId': 'a',
        'instance': (await read())
            .placedElements
            .first
            .copyWith(id: 'renamed')
            .toJson(),
      });
      expect((await read()).placedElements.map((e) => e.id),
          ['renamed', 'b', 'c']);
      await worker.processLine(jsonEncode({
        'id': 'close',
        'command': 'close',
        'args': {'projectHandle': opened.projectHandle.value}
      }));
    });
  }
}
