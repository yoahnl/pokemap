import 'dart:typed_data';

import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';

void main() {
  late _RecordingBackend backend;
  late Texture atlas;

  setUp(() {
    backend = _RecordingBackend();
    atlas = Texture(ByteData(128 * 64 * 4), width: 128, height: 64);
  });

  test('contiguous atlas rectangles share a surface with ordered D4 quads', () {
    final visuals = [
      for (final (index, transform) in smartTileD4Transforms.indexed)
        _visual(
          x: index * 3,
          transform: transform,
          rect: index.isEven
              ? const SmartTileSourceRect(x: 16, y: 8, width: 32, height: 16)
              : const SmartTileSourceRect(x: 64, y: 32, width: 16, height: 24),
          height: .001 * (index + 1),
        ),
    ];
    final mesh = spatialGroundMeshes(visuals, {'atlas': atlas}).single;
    expect(mesh.surfaces, hasLength(1));
    final surface = mesh.surfaces.single;
    expect(surface.vertexCount, 32);
    expect(surface.indexCount, 48);
    expect((surface.material as SpatialPixelMaterial).uvRect.storage, [
      0,
      0,
      1,
      1,
    ]);
    final uploaded = _uploadedVertices(surface, backend);
    for (final (index, item) in visuals.indexed) {
      final expectedUvs = index.isEven
          ? [(0.125, 0.125), (0.125, 0.375), (0.375, 0.375), (0.375, 0.125)]
          : [(0.5, 0.5), (0.5, 0.875), (0.625, 0.875), (0.625, 0.5)];
      final original = spatialGroundVertices(
        item.visual.geometry,
        height: item.height,
      );
      for (var corner = 0; corner < 4; corner++) {
        final offset = (index * 4 + corner) * 20;
        expect(
          uploaded.sublist(offset, offset + 3),
          [
            original[corner].position.x,
            original[corner].position.y,
            original[corner].position.z,
          ].map((value) => closeTo(value, .000001)).toList(),
        );
        expect(uploaded[offset + 3], expectedUvs[corner].$1);
        expect(uploaded[offset + 4], expectedUvs[corner].$2);
      }
      final order = item.visual.transform.flipX
          ? [0, 2, 1, 0, 3, 2]
          : [0, 1, 2, 0, 2, 3];
      expect(surface.indices.sublist(index * 6, index * 6 + 6), [
        for (final i in order) index * 4 + i,
      ]);
    }
  });

  test('atlas and opacity boundaries preserve translucent A B A order', () {
    final other = Texture(ByteData(128 * 64 * 4), width: 128, height: 64);
    final visuals = [
      _visual(x: 0, opacity: .5),
      _visual(x: 1, atlasId: 'other', opacity: .5),
      _visual(x: 2, opacity: .5),
      _visual(x: 3, opacity: .25),
      _visual(
        x: 4,
        opacity: .25,
        rect: const SmartTileSourceRect(x: 32, y: 0, width: 32, height: 32),
      ),
    ];
    final surfaces = spatialGroundMeshes(visuals, {
      'atlas': atlas,
      'other': other,
    }).single.surfaces;
    expect(surfaces, hasLength(4));
    expect(surfaces.map((s) => s.vertexCount), [4, 4, 4, 8]);
    expect(
      surfaces.map((s) => (s.material as SpatialPixelMaterial).albedoTexture),
      [atlas, other, atlas, atlas],
    );
    expect(
      surfaces.map((s) => (s.material as SpatialPixelMaterial).albedoColor.a),
      [.5, .5, .5, .25],
    );
    expect(surfaces.map((s) => s.positions.first), [0, 1, 2, 3]);
  });

  test(
    'atlas UVs survive fractional ramps clipping and every D4 transform',
    () {
      final scene = MapSpatialScene(
        width: 3,
        depth: 3,
        heightLevels: [2, 2, 2, 2, 2, 2, 0, 0, 0],
        navigation: SpatialNavigationProfile(
          ramps: [
            SpatialRamp(
              id: 'ramp',
              x: 1.25,
              z: 1,
              width: .5,
              depth: 1,
              lowLevel: 0,
              highLevel: 2,
              direction: SpatialRampDirection.north,
            ),
          ],
        ),
      );
      for (final transform in smartTileD4Transforms) {
        final item = _visual(
          transform: transform,
          footprintWidth: 4,
          footprintHeight: 4,
          height: .007,
        );
        final original = spatialGroundVertices(
          item.visual.geometry,
          scene: scene,
          height: item.height,
        );
        final surface = spatialGroundMeshes(
          [item],
          {'atlas': atlas},
          scene: scene,
        ).single.surfaces.single;
        final uploaded = _uploadedVertices(surface, backend);
        expect(surface.vertexCount, original.length);
        expect(original.length, greaterThan(4));
        for (final (index, vertex) in original.indexed) {
          final offset = index * 20;
          for (var axis = 0; axis < 3; axis++) {
            expect(
              uploaded[offset + axis],
              closeTo(
                [vertex.position.x, vertex.position.y, vertex.position.z][axis],
                .000001,
              ),
            );
          }
          expect(uploaded[offset + 3], closeTo(vertex.texCoord.x / 4, .000001));
          expect(uploaded[offset + 4], closeTo(vertex.texCoord.y / 2, .000001));
          expect(vertex.position.x, inInclusiveRange(0, 3));
          expect(vertex.position.z, inInclusiveRange(0, 3));
        }
        expect(surface.indices, [
          for (var base = 0; base < original.length; base += 4) ...[
            base,
            base + 1,
            base + 2,
            base,
            base + 2,
            base + 3,
          ],
        ]);
      }
    },
  );

  for (final quads in [14999, 15000, 15001]) {
    test('mesh splitting preserves $quads quads without empty surfaces', () {
      final item = _visual();
      final meshes = spatialGroundMeshes(List.filled(quads, item), {
        'atlas': atlas,
      }).toList();
      expect(meshes.length, quads > 15000 ? 2 : 1);
      final surfaces = meshes.expand((m) => m.surfaces);
      expect(surfaces.fold(0, (sum, s) => sum + s.vertexCount), quads * 4);
      expect(surfaces.fold(0, (sum, s) => sum + s.indexCount), quads * 6);
      for (final surface in surfaces) {
        expect(surface.vertexCount, inInclusiveRange(4, 60000));
        expect(surface.indices.every((i) => i < surface.vertexCount), isTrue);
        expect(surface.positions.every((value) => value.isFinite), isTrue);
      }
    });
  }

  test(
    'an atlas change immediately after a full mesh creates no empty surface',
    () {
      final first = _visual();
      final meshes = spatialGroundMeshes(
        [...List.filled(15000, first), _visual(atlasId: 'other', opacity: .25)],
        {'atlas': atlas, 'other': atlas},
      ).toList();
      expect(meshes.map((mesh) => mesh.surfaces.length), [1, 1]);
      expect(meshes.last.surfaces.single.vertexCount, 4);
      expect(
        (meshes.last.surfaces.single.material as SpatialPixelMaterial)
            .albedoColor
            .a,
        .25,
      );
    },
  );

  test('a single subdivided visual can cross the mesh vertex limit', () {
    final scene = MapSpatialScene(width: 128, depth: 128);
    final item = _visual(
      footprintWidth: 128,
      footprintHeight: 128,
      opacity: .5,
    );
    final meshes = spatialGroundMeshes(
      [item],
      {'atlas': atlas},
      scene: scene,
    ).toList();
    expect(meshes.map((m) => m.surfaces.single.vertexCount), [60000, 5536]);
    expect(
      meshes.expand((m) => m.surfaces).fold(0, (sum, s) => sum + s.indexCount),
      128 * 128 * 6,
    );
    for (final surface in meshes.expand((m) => m.surfaces)) {
      expect(surface.indices.every((i) => i < surface.vertexCount), isTrue);
      expect((surface.material as SpatialPixelMaterial).albedoColor.a, .5);
    }
  });

  test('mesh rebuilding uses current rectangles and atlas dimensions', () {
    final large = Texture(ByteData(256 * 128 * 4), width: 256, height: 128);
    final frames = [
      (_visual(), atlas, (0.125, 0.25)),
      (
        _visual(
          rect: const SmartTileSourceRect(x: 32, y: 16, width: 32, height: 32),
        ),
        atlas,
        (0.375, 0.5),
      ),
      (
        _visual(
          rect: const SmartTileSourceRect(x: 96, y: 64, width: 32, height: 32),
        ),
        large,
        (0.4375, 0.625),
      ),
    ];
    for (final (visual, texture, center) in frames) {
      final surface = spatialGroundMeshes(
        [visual],
        {'atlas': texture},
      ).single.surfaces.single;
      final uploaded = _uploadedVertices(surface, backend);
      final u = (uploaded[3] + uploaded[43]) / 2;
      final v = (uploaded[4] + uploaded[44]) / 2;
      expect(u, center.$1);
      expect(v, center.$2);
      expect(
        (surface.material as SpatialPixelMaterial).albedoTexture,
        same(texture),
      );
    }
  });

  test('invalid atlas rectangles still fail before producing a mesh', () {
    for (final rect in [
      const SmartTileSourceRect(x: 0, y: 48, width: 32, height: 32),
      const SmartTileSourceRect(x: 100, y: 0, width: 32, height: 32),
    ]) {
      expect(
        () => spatialGroundMeshes(
          [_visual(rect: rect)],
          {'atlas': atlas},
        ).toList(),
        throwsStateError,
      );
    }
  });

  test(
    'non power of two atlases sample every texel center and the last pixel',
    () {
      final texture = Texture(ByteData(96 * 160 * 4), width: 96, height: 160);
      const rectangles = [
        SmartTileSourceRect(x: 17, y: 41, width: 37, height: 59),
        SmartTileSourceRect(x: 95, y: 159, width: 1, height: 1),
      ];
      final surface = spatialGroundMeshes(
        [for (final rect in rectangles) _visual(rect: rect)],
        {'atlas': texture},
      ).single.surfaces.single;
      expect(surface.vertexCount, 8);
      final uploaded = _uploadedVertices(surface, backend);
      for (final (index, rect) in rectangles.indexed) {
        final base = index * 80;
        for (var y = 0; y < rect.height; y++) {
          for (var x = 0; x < rect.width; x++) {
            final u =
                uploaded[base + 3] +
                (uploaded[base + 63] - uploaded[base + 3]) *
                    ((x + .5) / rect.width);
            final v =
                uploaded[base + 4] +
                (uploaded[base + 24] - uploaded[base + 4]) *
                    ((y + .5) / rect.height);
            final fragmentUv = Float32List.fromList([u, v]);
            expect((fragmentUv[0] * texture.width).floor(), rect.x + x);
            expect((fragmentUv[1] * texture.height).floor(), rect.y + y);
          }
        }
      }
    },
  );
}

SpatialGroundVisual _visual({
  int x = 0,
  String atlasId = 'atlas',
  SmartTileSourceRect rect = const SmartTileSourceRect(
    x: 0,
    y: 0,
    width: 32,
    height: 32,
  ),
  SmartTileSpriteTransform transform = const SmartTileSpriteTransform(),
  int footprintWidth = 1,
  int footprintHeight = 1,
  double height = .003,
  double opacity = 1,
}) => (
  visual: SmartTileLayerVisual(
    cellX: x,
    cellY: 0,
    ruleId: 'rule',
    candidateId: 'candidate',
    channel: SmartTileRenderChannel.ground,
    isAnimated: false,
    tilesetId: atlasId,
    sourceRect: rect,
    transform: transform,
    geometry: resolveSmartTileSpriteGeometry(
      cellX: x,
      cellY: 0,
      destinationCellWidth: 1,
      destinationCellHeight: 1,
      sourceCellWidth: 32,
      sourceCellHeight: 32,
      offsetUnit: SmartTileOffsetUnit.pixel,
      offsetX: 0,
      offsetY: 0,
      atlasPixelOffsetX: 0,
      atlasPixelOffsetY: 0,
      footprintWidth: footprintWidth,
      footprintHeight: footprintHeight,
      anchorX: 0,
      anchorY: 0,
      transform: transform,
    ),
    offsetUnit: SmartTileOffsetUnit.pixel,
    offsetX: 0,
    offsetY: 0,
    footprintWidth: footprintWidth,
    footprintHeight: footprintHeight,
    anchorX: 0,
    anchorY: 0,
    drawOrder: 0,
  ),
  height: height,
  opacity: opacity,
);

Float32List _uploadedVertices(Surface surface, _RecordingBackend backend) {
  surface.createResource();
  return Float32List.view(
    backend.latest.bytes.buffer,
    0,
    surface.verticesBytes ~/ 4,
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
