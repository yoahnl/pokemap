import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final ground in [false, true]) {
    test(
      'neighbor refresh replaces an invalidated pending ${ground ? 'ground texture' : 'model'} without losing its admission',
      () async {
        _UnusedBackend();
        final budget = RuntimeResourceBudget();
        final controller = SpatialSceneController();
        final source = Completer<Uint8List>();
        final started = Completer<void>();
        final visible = <Set<String>>[];
        var reads = 0;
        final model = ProjectModel3dEntry(
          id: 'tree',
          name: 'Tree',
          sourceAssetId: 'tree-source',
          relativePath: 'assets/models3d/tree.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3.zero,
              max: Model3dVector3(x: 1, y: 1, z: 1),
            ),
            meshCount: 1,
            triangleCount: 1,
          ),
        );
        final map = MapData(
          id: 'active',
          name: 'Active',
          size: GridSize(width: 2, height: 2),
          spatialScene: MapSpatialScene(
            width: 2,
            depth: 2,
            cliffFrame: ground
                ? SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0)
                : null,
            instances: [
              if (!ground)
                SpatialModelInstance(
                  id: 'tree-instance',
                  modelId: 'tree',
                  position: Model3dVector3.zero,
                ),
            ],
          ),
        );
        final neighbor = MapData(
          id: 'neighbor',
          name: 'Neighbor',
          size: GridSize(width: 2, height: 2),
          spatialScene: MapSpatialScene(width: 2, depth: 2),
        );
        final project = ProjectManifest(
          name: 'Test',
          maps: const [],
          tilesets: const [],
          models3d: [model],
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: const [
              ProjectSmartTileAtlas(
                id: 'atlas',
                name: 'Atlas',
                tilesetId: 'ground',
                columns: 1,
                rows: 1,
              ),
            ],
          ),
        );
        final bytes = ground
            ? Uint8List.fromList(
                img.encodePng(img.Image(width: 32, height: 32)),
              )
            : _triangle('Tree');
        Future<Uint8List> load(String _) {
          reads++;
          if (reads == 1) {
            started.complete();
            return source.future;
          }
          return Future.value(bytes);
        }

        SpatialSceneView configuration(List<SpatialSceneNeighbor> neighbors) =>
            SpatialSceneView(
              scene: map.spatialScene!,
              groundMap: map,
              groundProject: project,
              models: project.models3d,
              loadModel: load,
              loadGroundImage: load,
              controller: controller,
              neighbors: neighbors,
              resourceBudget: budget,
              resourceIdentity: 'project',
              onCell: (_, _) {},
              onVisibleMapsChanged: visible.add,
              background: const Color(0xff000000),
              ground: const Color(0xff224422),
              edge: const Color(0xff111111),
              errorBuilder: (_, _) => const SizedBox(),
            );
        final game =
            SpatialSceneGame(
                configuration(const []),
                onPreviewStatus: (_) {},
                onSurfaceChanged: () {},
              )
              ..onGameResize(Vector2(200, 200))
              ..sceneReady = true;
        addTearDown(() {
          game.onRemove();
          controller.dispose();
          budget.dispose();
        });
        final stale = game.refresh();
        await started.future;
        game.configuration = configuration([
          SpatialSceneNeighbor(
            map: neighbor,
            offset: const Offset(2, 0),
            loadGroundImage: (_) async => Uint8List(0),
          ),
        ]);
        final current = game.refresh();
        final accepted = expectLater(current, completion(isTrue));
        source.complete(bytes);
        await accepted;
        expect(await stale, isFalse);
        expect(reads, 2);
        final cache = ground ? game.groundTextureCache : game.cache;
        final reservations = ground
            ? game.groundReservations
            : game.modelReservations;
        final key = ground ? 'ground' : 'tree-source';
        expect(cache, contains(key));
        expect(reservations, contains(key));
        final admitted = cache[key];
        final admission = reservations[key];
        expect(visible, [
          {'active', 'neighbor'},
        ]);
        expect(budget.isDisposed, isFalse);
        expect(budget.residentBytes, greaterThan(0));
        expect(budget.transientBytes, 0);
        expect(budget.activeDecodes, 0);
        final residentBytes = budget.residentBytes;
        expect(await game.refresh(), isTrue);
        expect(reads, 2);
        expect(cache[key], same(admitted));
        expect(reservations[key], same(admission));
        expect(budget.residentBytes, residentBytes);
        game.onRemove();
        expect(budget.residentBytes, 0);
        expect(budget.transientBytes, 0);
        expect(budget.pendingDecodes, 0);
      },
    );
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

Uint8List _triangle(String name) {
  final binary = ByteData(36);
  final coordinates = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  for (var i = 0; i < coordinates.length; i++) {
    binary.setFloat32(i * 4, coordinates[i], Endian.little);
  }
  final json = utf8.encode(
    jsonEncode({
      'asset': {'version': '2.0'},
      'scene': 0,
      'scenes': [
        {
          'nodes': [0],
        },
      ],
      'nodes': [
        {'name': name, 'mesh': 0},
      ],
      'buffers': [
        {'byteLength': 36},
      ],
      'bufferViews': [
        {'buffer': 0, 'byteLength': 36},
      ],
      'accessors': [
        {'bufferView': 0, 'componentType': 5126, 'count': 3, 'type': 'VEC3'},
      ],
      'meshes': [
        {
          'primitives': [
            {
              'attributes': {'POSITION': 0},
            },
          ],
        },
      ],
    }),
  );
  final jsonSize = (json.length + 3) ~/ 4 * 4;
  final bytes = Uint8List(12 + 8 + jsonSize + 8 + 36);
  final data = ByteData.sublistView(bytes);
  data.setUint32(0, 0x46546c67, Endian.little);
  data.setUint32(4, 2, Endian.little);
  data.setUint32(8, bytes.length, Endian.little);
  data.setUint32(12, jsonSize, Endian.little);
  data.setUint32(16, 0x4e4f534a, Endian.little);
  bytes.fillRange(20, 20 + jsonSize, 32);
  bytes.setRange(20, 20 + json.length, json);
  data.setUint32(20 + jsonSize, 36, Endian.little);
  data.setUint32(24 + jsonSize, 0x004e4942, Endian.little);
  bytes.setRange(28 + jsonSize, bytes.length, binary.buffer.asUint8List());
  return bytes;
}
