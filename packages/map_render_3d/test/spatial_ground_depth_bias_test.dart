import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

SmartTileLayerVisual groundVisual() => SmartTileLayerVisual(
  cellX: 0,
  cellY: 0,
  ruleId: 'ground',
  candidateId: 'grass',
  channel: SmartTileRenderChannel.ground,
  isAnimated: false,
  tilesetId: 'grass',
  sourceRect: const SmartTileSourceRect(x: 0, y: 0, width: 16, height: 16),
  transform: const SmartTileSpriteTransform(),
  geometry: resolveSmartTileSpriteGeometry(
    cellX: 0,
    cellY: 0,
    destinationCellWidth: 1,
    destinationCellHeight: 1,
    sourceCellWidth: 16,
    sourceCellHeight: 16,
    offsetUnit: SmartTileOffsetUnit.pixel,
    offsetX: 0,
    offsetY: 0,
    atlasPixelOffsetX: 0,
    atlasPixelOffsetY: 0,
    footprintWidth: 1,
    footprintHeight: 1,
    anchorX: 0,
    anchorY: 0,
    transform: const SmartTileSpriteTransform(),
  ),
  offsetUnit: SmartTileOffsetUnit.pixel,
  offsetX: 0,
  offsetY: 0,
  footprintWidth: 1,
  footprintHeight: 1,
  anchorX: 0,
  anchorY: 0,
  drawOrder: 0,
);

void main() {
  final texture = Texture(ByteData(16 * 16 * 4), width: 16, height: 16);
  final visual = groundVisual();
  final layers = [
    (visual: visual, height: .003, opacity: 1.0),
    (visual: visual, height: .007, opacity: 1.0),
  ];

  test(
    'ground paint ranks preserve physical terrain vertices and batching',
    () {
      final scene = MapSpatialScene(
        width: 1,
        depth: 1,
        levelHeight: .25,
        heightLevels: [3],
      );
      final mesh = spatialGroundMeshes(layers, {
        'grass': texture,
      }, scene: scene).single;
      expect(mesh.surfaceCount, 1);
      expect(
        (mesh.surfaces.single.material as SpatialPixelMaterial).groundDepthOnly,
        isTrue,
      );
      expect(mesh.surfaces.single.vertexCount, 8);
      final positions = mesh.surfaces.single.positions;
      expect([
        for (var i = 1; i < positions.length; i += 3) positions[i],
      ], everyElement(.75));
      expect(scene.heightLevels, [3]);
    },
  );

  test('ground layer offsets survive the batched GPU vertex upload', () {
    final backend = _BufferBackend();
    final scene = MapSpatialScene(width: 1, depth: 1);
    final surface = spatialGroundMeshes(
      layers,
      {'grass': texture},
      scene: scene,
    ).single.surfaces.single;
    surface.resource;
    final vertices = backend.buffer!.bytes.buffer.asFloat32List(
      0,
      surface.vertexCount * 20,
    );
    for (var i = 0; i < surface.vertexCount; i++) {
      final offset = i * 20;
      expect(vertices[offset + 1], 0);
      expect(vertices[offset + 9], 0);
      expect(vertices[offset + 10], closeTo(i < 4 ? .003 : .007, 1e-8));
      expect(vertices[offset + 11], 0);
    }
  });

  test('ground paint ranks keep the exact lowered cliff support heights', () {
    final scene = MapSpatialScene(
      width: 1,
      depth: 1,
      levelHeight: .25,
      heightLevels: [3],
    );
    final mesh = spatialGroundMeshes(
      layers,
      {'grass': texture},
      scene: scene,
      groundReplacements: {
        (0, 0): [
          SpatialBorderGroundReplacement(
            left: 0.0,
            top: 0.0,
            right: .5,
            bottom: 1.0,
            lowerHeight: .25,
            upperHeight: .75,
          ),
        ],
      },
    ).single;
    final positions = mesh.surfaces.single.positions;
    expect(
      {for (var i = 1; i < positions.length; i += 3) positions[i]},
      {.25, .75},
    );
  });

  test(
    'ground without a spatial scene retains its explicit placement height',
    () {
      final mesh = spatialGroundMeshes(
        [layers.first],
        {'grass': texture},
      ).single;
      expect(
        (mesh.surfaces.single.material as SpatialPixelMaterial).groundDepthOnly,
        isFalse,
      );
      final positions = mesh.surfaces.single.positions;
      expect([
        for (var i = 1; i < positions.length; i += 3) positions[i],
      ], everyElement(closeTo(.003, 1e-8)));
    },
  );
}

final class _BufferBackend extends GpuBackend {
  _Buffer? buffer;

  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => buffer = _Buffer(sizeInBytes);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Buffer implements GpuBuffer {
  _Buffer(int length) : bytes = Uint8List(length);

  final Uint8List bytes;

  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {
    bytes.setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + data.lengthInBytes,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
