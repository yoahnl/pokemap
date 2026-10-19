import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final transport in ['directApi', 'cli']) {
    test(
        'waiting animation image $transport uses canonical offset with validation and cold reopen',
        () async {
      final root = await Directory.systemTemp.createTemp('idle-image-');
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
          name: 'Waiting image',
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
                          TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
                      durationMs: 100),
                  TilesetVisualFrame(
                      source:
                          TilesetSourceRect(x: 2, y: 0, width: 2, height: 2),
                      durationMs: 250),
                  TilesetVisualFrame(
                      source:
                          TilesetSourceRect(x: 4, y: 0, width: 2, height: 2),
                      durationMs: 150)
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
            'id': 'idle-${sequence++}',
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
              .any((a) => a['id'] == 'placed_element.set_animation'),
          isTrue);
      Future<Map<String, Object?>> plan(
          String action, Map<String, Object?> params) async {
        final snapshot = await snapshots.load(opened.projectHandle);
        final request = AuthoringRequest(
            requestId: 'idle-${sequence++}',
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'idle-${sequence++}',
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

      const animation = MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          autoplay: false,
          startOffsetMs: 350,
          speed: 2.5,
          randomStart: false);
      final before = await mapFile.readAsBytes();
      for (final invalid in [
        animation.copyWith(startOffsetMs: -1),
        animation.copyWith(speed: 0)
      ]) {
        await expectLater(
            plan('placed_element.set_animation', {
              'mapId': 'map',
              'instanceId': 'a',
              'animation': invalid.toJson()
            }),
            throwsA(anything));
        expect(await mapFile.readAsBytes(), before);
      }
      await apply('placed_element.set_animation',
          {'mapId': 'map', 'instanceId': 'a', 'animation': animation.toJson()});
      final updated = await read();
      expect(updated.placedElements.first.animation, animation);
      expect(updated.placedElements.last.animation, isNull);
      expect(updated.placedElements.first.properties,
          map.placedElements.first.properties);
      expect(
          resolvePlacedElementAnimationFrameIndex(
              frameDurationsMs: const [100, 250, 150],
              elapsedMs: 100000,
              animation: updated.placedElements.first.animation),
          2);
      expect(
          resolvePlacedElementAnimationOneShotFrame(
                  frameDurationsMs: const [100, 250, 150], elapsedMs: 0)
              .frameIndex,
          0);
      final history = await call(
          'history', {'projectHandle': opened.projectHandle.value, 'limit': 1});
      await call('undo', {
        'projectHandle': opened.projectHandle.value,
        'entryId': ((history['entries'] as List).single as Map)['entryId'],
        'idempotencyKey': 'undo-idle'
      });
      expect((await read()).placedElements, map.placedElements);
      await apply('placed_element.set_animation',
          {'mapId': 'map', 'instanceId': 'a', 'animation': animation.toJson()});
      final saved = MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>);
      expect(saved.placedElements.first.animation, animation);
      await api.closeWorkspace(opened.workspaceHandle);
      final reopened = await api.openProject(root.path);
      expect(
          (await snapshots.load(reopened.projectHandle))
              .maps
              .single
              .placedElements
              .first
              .animation,
          animation);
      await api.closeWorkspace(reopened.workspaceHandle);
    });
  }
}
