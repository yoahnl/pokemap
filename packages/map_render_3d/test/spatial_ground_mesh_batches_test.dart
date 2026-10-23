import 'dart:typed_data';

import 'package:flame_3d/components.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_ground_mesh_batches.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

void main() {
  late SpatialGroundMeshBatches batches;
  late List<List<SpatialGroundVisual>> built;
  late _RecordingBackend backend;
  setUp(() {
    built = [];
    backend = _RecordingBackend();
    final texture = Texture(ByteData(64 * 32 * 4), width: 64, height: 32);
    batches = SpatialGroundMeshBatches((visuals) {
      built.add(visuals);
      return [
        for (final mesh in spatialGroundMeshes(visuals, {'atlas': texture}))
          MeshComponent(mesh: mesh),
      ];
    });
  });

  test(
    'an animated UV change retains static component identity and batching',
    () {
      batches.resolve([
        _visual(0),
        _visual(1),
        _visual(2, animated: true),
        _visual(3),
      ]);
      final previous = [...batches.components];
      built.clear();
      batches.resolve([
        _visual(0),
        _visual(1),
        _visual(2, animated: true, frameX: 32),
        _visual(3),
      ]);
      expect(batches.components.first, same(previous.first));
      expect(batches.components.last, same(previous.last));
      expect(built.single.length, 1);
      expect(built.single.single.visual.cellX, 2);
      expect(batches.components[1], isNot(same(previous[1])));
      expect(batches.components[1].mesh.surfaces.single.vertexCount, 4);
      batches.components[1].mesh.surfaces.single.createResource();
      expect(Float32List.view(backend.latest.bytes.buffer)[3], .5);
    },
  );

  test('an unchanged frame performs no mesh construction', () {
    final visuals = [_visual(0), _visual(1, animated: true)];
    batches.resolve(visuals);
    final previous = [...batches.components];
    built.clear();
    batches.resolve([_visual(0), _visual(1, animated: true)]);
    expect(built, isEmpty);
    expect(batches.components, orderedEquals(previous));
  });

  test('consecutive static and animated ranges keep original alpha order', () {
    batches.resolve([_visual(0), _visual(1, animated: true), _visual(2)]);
    expect(batches.components, hasLength(3));
    expect(
      built.map((range) => range.map((item) => item.visual.cellX).toList()),
      [
        [0],
        [1],
        [2],
      ],
    );
    for (final component in batches.components) {
      expect(
        (component.mesh.surfaces.single.material as SpatialPixelMaterial)
            .albedoColor
            .a,
        closeTo(.5, .01),
      );
    }
  });

  test(
    'geometry and topology invalidation discard obsolete component identities',
    () {
      batches.resolve([_visual(0), _visual(1, animated: true)]);
      final previous = [...batches.components];
      built.clear();
      batches.resolve([
        _visual(0),
        _visual(1, animated: true, flipped: true),
      ], invalidateGeometry: true);
      expect(batches.components.any(previous.contains), isFalse);
      expect(built.fold<int>(0, (count, range) => count + range.length), 2);
      final transformed = [...batches.components];
      batches.resolve([_visual(0), _visual(1), _visual(2, animated: true)]);
      expect(batches.components.any(transformed.contains), isFalse);
    },
  );

  test('replacement insertion retains consecutive alpha order with stable priorities', () {
    batches.resolve([_visual(0), _visual(1, animated: true), _visual(2)]);
    final old = [...batches.components];
    batches.resolve([
      _visual(0),
      _visual(1, animated: true, frameX: 32),
      _visual(2),
    ]);
    final reinserted = [
      ...old.where(batches.components.contains),
      ...batches.components.where((component) => !old.contains(component)),
    ]..sort((a, b) => a.priority.compareTo(b.priority));
    expect(reinserted, orderedEquals(batches.components));
    expect(reinserted.first, same(old.first));
  });
}

SpatialGroundVisual _visual(
  int x, {
  bool animated = false,
  int frameX = 0,
  bool flipped = false,
}) {
  final transform = SmartTileSpriteTransform(flipX: flipped);
  return (
    visual: SmartTileLayerVisual(
      cellX: x,
      cellY: 0,
      ruleId: 'rule',
      candidateId: 'candidate',
      channel: SmartTileRenderChannel.ground,
      isAnimated: animated,
      tilesetId: 'atlas',
      sourceRect: SmartTileSourceRect(x: frameX, y: 0, width: 32, height: 32),
      transform: transform,
      geometry: resolveSmartTileSpriteGeometry(
        cellX: x,
        cellY: 0,
        destinationCellWidth: 1,
        destinationCellHeight: 1,
        sourceCellWidth: 32,
        sourceCellHeight: 32,
        offsetUnit: SmartTileOffsetUnit.cell,
        offsetX: 0,
        offsetY: 0,
        atlasPixelOffsetX: 0,
        atlasPixelOffsetY: 0,
        footprintWidth: 1,
        footprintHeight: 1,
        anchorX: 0,
        anchorY: 0,
        transform: transform,
      ),
      offsetUnit: SmartTileOffsetUnit.cell,
      offsetX: 0,
      offsetY: 0,
      footprintWidth: 1,
      footprintHeight: 1,
      anchorX: 0,
      anchorY: 0,
      drawOrder: 0,
    ),
    height: 0,
    opacity: .5,
  );
}

final class _RecordingBackend extends GpuBackend {
  late _RecordingBuffer latest;
  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => latest = _RecordingBuffer(sizeInBytes);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingBuffer implements GpuBuffer {
  _RecordingBuffer(int size) : bytes = Uint8List(size);
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
