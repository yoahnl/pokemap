import 'dart:typed_data';
import 'dart:convert';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'locked front model lets the picker reach the model behind it',
    () async {
      _UnusedBackend();
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      final scene = MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'back',
            modelId: 'cube',
            position: Model3dVector3(x: 4, y: 0, z: 3.5),
          ),
          SpatialModelInstance(
            id: 'front-particles',
            modelId: 'cube',
            position: Model3dVector3(x: 4, y: 0, z: 4.5),
          ),
        ],
      );
      final models = [
        ProjectModel3dEntry(
          id: 'cube',
          name: 'Cube',
          sourceAssetId: 'cube',
          relativePath: 'assets/models3d/cube.glb',
          inspection: Model3dInspection(
            bounds: Model3dBounds(
              min: Model3dVector3(x: -.5, y: 0, z: -.5),
              max: Model3dVector3(x: .5, y: 2, z: .5),
            ),
            meshCount: 1,
            triangleCount: 12,
          ),
        ),
      ];
      var reads = 0;
      Future<Uint8List> load(String _) async {
        reads++;
        return _triangle();
      }

      SpatialSceneView configuration(Set<String> locked, {String? selected}) =>
          SpatialSceneView(
            scene: scene,
            selectedContent: selected == null
                ? null
                : SpatialSceneContentHit(
                    kind: SpatialSceneContentKind.model,
                    id: selected,
                    cell: (4, 4),
                  ),
            models: models,
            loadModel: load,
            controller: controller,
            canSelectContent: (kind, id) => !locked.contains(id),
            onCell: (_, _) {},
            background: const Color(0xff000000),
            ground: const Color(0xff000000),
            edge: const Color(0xff000000),
            errorBuilder: (_, _) => const SizedBox(),
          );
      final initial = configuration({});
      final game = SpatialSceneGame(
        initial,
        onPreviewStatus: (_) {},
        onSurfaceChanged: () {},
      )..onGameResize(Vector2(200, 200));
      (game.camera as AdaptiveCamera3D).frame(
        Vector3(4, 1, 4),
        pitch: 0,
        yaw: 0,
        distance: 10,
        viewportAspectRatio: 1,
      );
      const pointer = Offset(100, 100);
      expect(game.pickContent(pointer)?.id, 'front-particles');
      final locked = configuration({'front-particles'});
      game.configuration = locked;
      expect(game.pickContent(pointer)?.id, 'back');
      expect(locked.scene, same(initial.scene));
      expect(locked.models, same(initial.models));
      expect(locked.modelSourcesMatch(initial), isTrue);
      expect(reads, 0);
      game.configuration = configuration({'front-particles', 'back'});
      expect(game.pickContent(pointer), isNull);
      game.configuration = initial;
      expect(game.pickContent(pointer)?.id, 'front-particles');
      game.sceneReady = true;
      await game.refresh();
      addTearDown(game.onRemove);
      final beforeGeneration = game.generation;
      final beforeReads = reads;
      final backComponent = game.modelComponents['back']!.component;
      final frontComponent = game.modelComponents['front-particles']!.component;
      final selected = configuration({}, selected: 'front-particles');
      game.renderedConfiguration = selected;
      game.syncContentSelection(initial, selected);
      expect(game.modelSelections.keys, ['front-particles']);
      final selectedBehind = configuration({
        'front-particles',
      }, selected: 'back');
      game.renderedConfiguration = selectedBehind;
      game.syncContentSelection(selected, selectedBehind);
      expect(game.modelSelections.keys, ['back']);
      game.renderedConfiguration = locked;
      game.syncContentSelection(selectedBehind, locked);
      expect(game.modelSelections, isEmpty);
      expect(game.modelComponents['back']!.component, same(backComponent));
      expect(
        game.modelComponents['front-particles']!.component,
        same(frontComponent),
      );
      expect(game.generation, beforeGeneration);
      expect(reads, beforeReads);
    },
  );
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

Uint8List _triangle() {
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
        {'name': 'Triangle', 'mesh': 0},
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
