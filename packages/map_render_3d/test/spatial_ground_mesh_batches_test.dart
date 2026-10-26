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
  late Map<String, Texture> textures;
  setUp(() {
    built = [];
    backend = _RecordingBackend();
    final texture = Texture(ByteData(64 * 32 * 4), width: 64, height: 32);
    textures = {
      'atlas': texture,
      'other': Texture(ByteData(128 * 64 * 4), width: 128, height: 64),
    };
    batches = SpatialGroundMeshBatches((visuals) {
      built.add(visuals);
      return [
        for (final mesh in spatialGroundMeshes(visuals, textures))
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
      expect(built, isEmpty);
      expect(batches.components[1], same(previous[1]));
      expect(batches.components[1].mesh.surfaces.single.vertexCount, 4);
      batches.components[1].mesh.surfaces.single.createResource();
      final material =
          batches.components[1].mesh.surfaces.single.material
              as SpatialPixelMaterial;
      expect(Float32List.view(backend.latest.bytes.buffer)[3], 0);
      expect(material.uvTransformU.storage, [1, 0, .5, 0]);
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

  test(
    'animated frame cycles retain geometry and never accumulate UV offsets',
    () {
      batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
      final component = batches.components.single;
      final surface = component.mesh.surfaces.single;
      final positions = surface.positions;
      final indices = surface.indices;
      final buffer = surface.resource;
      built.clear();
      for (final frameX in [32, 0, 32, 0]) {
        batches.resolve([
          _visual(0, animated: true, frameX: frameX),
          _visual(1, animated: true, frameX: frameX),
        ]);
        expect(built, isEmpty);
        expect(batches.components.single, same(component));
        expect(component.mesh.surfaces.single, same(surface));
        expect(surface.positions, same(positions));
        expect(surface.indices, same(indices));
        expect(surface.resource, same(buffer));
        final material = surface.material as SpatialPixelMaterial;
        expect(material.uvTransformU.storage, [1, 0, frameX / 64, 0]);
        expect(material.uvTransformV.storage, [0, 1, 0, 0]);
      }
    },
  );

  test('different cell animation phases update UV buffers without rebuilding geometry', () {
    batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
    final previous = batches.components.single;
    final material =
        previous.mesh.surfaces.single.material as SpatialPixelMaterial;
    final surface = previous.mesh.surfaces.single;
    final previousBuffer = surface.resource;
    final previousBytes = Uint8List.fromList(backend.latest.bytes);
    final positions = surface.positions;
    built.clear();
    batches.resolve([
      _visual(0, animated: true, frameX: 32),
      _visual(1, animated: true),
    ]);
    expect(built, isEmpty);
    expect(batches.components.single, same(previous));
    expect(surface.positions, same(positions));
    expect(material.uvTransformU.storage, [1, 0, 0, 0]);
    expect(surface.resource, isNot(same(previousBuffer)));
    final vertices = Float32List.view(backend.latest.bytes.buffer);
    expect(vertices[3], .5);
    expect(vertices[83], 0);
    expect(
      (previousBuffer as _RecordingBuffer).bytes,
      orderedEquals(previousBytes),
    );
    batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
    expect(built, isEmpty);
    expect(batches.components.single, same(previous));
    surface.resource;
    final restored = Float32List.view(backend.latest.bytes.buffer);
    expect(restored[3], 0);
    expect(restored[83], 0);
    expect(material.uvTransformU.storage, [1, 0, 0, 0]);
  });

  test(
    'a uniform atlas change retains geometry with the new texture dimensions',
    () {
      batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
      final component = batches.components.single;
      built.clear();
      batches.resolve([
        _visual(0, animated: true, atlasId: 'other', frameX: 32),
        _visual(1, animated: true, atlasId: 'other', frameX: 32),
      ]);
      expect(built, isEmpty);
      expect(batches.components.single, same(component));
      final material =
          component.mesh.surfaces.single.material as SpatialPixelMaterial;
      expect(material.albedoTexture, same(textures['other']));
      expect(material.sourceMaterialName, 'ground:other');
      expect(material.uvTransformU.storage, [.5, 0, .25, 0]);
      expect(material.uvTransformV.storage, [0, .5, 0, 0]);
      batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
      expect(built, isEmpty);
      expect(batches.components.single, same(component));
      final restored =
          component.mesh.surfaces.single.material as SpatialPixelMaterial;
      expect(restored.albedoTexture, same(textures['atlas']));
      expect(restored.sourceMaterialName, 'ground:atlas');
      expect(restored.uvTransformU.storage, [1, 0, 0, 0]);
      expect(restored.uvTransformV.storage, [0, 1, 0, 0]);
    },
  );

  test('an atlas split rebuilds ordered surfaces without altering the previous frame', () {
    batches.resolve([_visual(0, animated: true), _visual(1, animated: true)]);
    final previous = batches.components.single;
    final previousMaterial =
        previous.mesh.surfaces.single.material as SpatialPixelMaterial;
    batches.resolve([
      _visual(0, animated: true, frameX: 32),
      _visual(1, animated: true, atlasId: 'other'),
    ]);
    expect(batches.components.single, isNot(same(previous)));
    expect(previousMaterial.uvTransformU.storage, [1, 0, 0, 0]);
    expect(
      batches.components.single.mesh.surfaces.map(
        (surface) =>
            (surface.material as SpatialPixelMaterial).sourceMaterialName,
      ),
      ['ground:atlas', 'ground:other'],
    );
  });

  test('invalid animated frames retain the same validation failure', () {
    batches.resolve([_visual(0, animated: true)]);
    final material =
        batches.components.single.mesh.surfaces.single.material
            as SpatialPixelMaterial;
    expect(
      () => batches.resolve([_visual(0, animated: true, frameX: 64)]),
      throwsStateError,
    );
    expect(material.uvTransformU.storage, [1, 0, 0, 0]);
  });

  test(
    'frame uniforms match rebuilt UVs on clipped ramps for every D4 transform',
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
        final localBatches = SpatialGroundMeshBatches(
          (visuals) => [
            for (final mesh in spatialGroundMeshes(
              visuals,
              textures,
              scene: scene,
            ))
              MeshComponent(mesh: mesh),
          ],
        );
        SpatialGroundVisual frame(int x) => _visual(
          0,
          animated: true,
          frameX: x,
          spriteTransform: transform,
          footprint: 3,
          clip: SmartTileSpatialClip(left: .1, top: .2, right: .9, bottom: .95),
        );
        localBatches.resolve([frame(0)]);
        final component = localBatches.components.single;
        final surface = component.mesh.surfaces.single;
        surface.createResource();
        final original = Float32List.fromList(
          Float32List.view(
            backend.latest.bytes.buffer,
            0,
            surface.verticesBytes ~/ 4,
          ),
        );
        localBatches.resolve([frame(32)]);
        expect(localBatches.components.single, same(component));
        final material = surface.material as SpatialPixelMaterial;
        final reference = spatialGroundMeshes(
          [frame(32)],
          textures,
          scene: scene,
        ).single.surfaces.single;
        reference.createResource();
        final expected = Float32List.view(
          backend.latest.bytes.buffer,
          0,
          reference.verticesBytes ~/ 4,
        );
        expect(surface.positions, orderedEquals(reference.positions));
        expect(surface.indices, orderedEquals(reference.indices));
        expect(surface.vertexCount, greaterThan(4));
        for (var vertex = 0; vertex < surface.vertexCount; vertex++) {
          final u = original[vertex * 20 + 3];
          final v = original[vertex * 20 + 4];
          expect(
            u * material.uvTransformU.x + material.uvTransformU.z,
            closeTo(expected[vertex * 20 + 3], .000001),
          );
          expect(
            v * material.uvTransformV.y + material.uvTransformV.z,
            closeTo(expected[vertex * 20 + 4], .000001),
          );
        }
      }
    },
  );

  test('fully excluded visuals still validate every animated atlas frame', () {
    final localBatches = SpatialGroundMeshBatches(
      (visuals) => [
        for (final mesh in spatialGroundMeshes(
          visuals,
          textures,
          scene: MapSpatialScene(width: 1, depth: 1),
        ))
          MeshComponent(mesh: mesh),
      ],
    );
    localBatches.resolve([_visual(10, animated: true)]);
    expect(localBatches.components, isEmpty);
    expect(
      () => localBatches.resolve([_visual(10, animated: true, frameX: 64)]),
      throwsStateError,
    );
  });

  test('per-cell frame uploads match rebuilt geometry normals and UVs on clipped ramps', () {
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
      final localBatches = SpatialGroundMeshBatches(
        (visuals) => [
          for (final mesh in spatialGroundMeshes(
            visuals,
            textures,
            scene: scene,
          ))
            MeshComponent(mesh: mesh),
        ],
      );
      SpatialGroundVisual frame(int cell, int x) => _visual(
        cell,
        animated: true,
        frameX: x,
        spriteTransform: transform,
        footprint: 3,
        clip: SmartTileSpatialClip(left: .1, top: .2, right: .9, bottom: .95),
      );
      localBatches.resolve([frame(0, 0), frame(1, 0)]);
      final component = localBatches.components.single;
      final surface = component.mesh.surfaces.single;
      for (final offsets in [(32, 0), (32, 32), (0, 0)]) {
        final current = [frame(0, offsets.$1), frame(1, offsets.$2)];
        localBatches.resolve(current);
        expect(localBatches.components.single, same(component));
        surface.resource;
        final actual = Float32List.fromList(
          Float32List.view(
            backend.latest.bytes.buffer,
            0,
            surface.verticesBytes ~/ 4,
          ),
        );
        final reference = spatialGroundMeshes(
          current,
          textures,
          scene: scene,
        ).single.surfaces.single;
        reference.createResource();
        final expected = Float32List.view(
          backend.latest.bytes.buffer,
          0,
          reference.verticesBytes ~/ 4,
        );
        expect(surface.positions, orderedEquals(reference.positions));
        expect(surface.indices, orderedEquals(reference.indices));
        expect(
          actual,
          orderedEquals(expected.map((value) => closeTo(value, .000001))),
        );
        final material = surface.material as SpatialPixelMaterial;
        expect(material.uvTransformU.storage, [1, 0, 0, 0]);
        expect(material.uvTransformV.storage, [0, 1, 0, 0]);
      }
    }
  });

  test(
    'a visual split over multiple meshes retains every buffer during animation',
    () {
      final scene = MapSpatialScene(width: 128, depth: 128);
      final localBatches = SpatialGroundMeshBatches(
        (visuals) => [
          for (final mesh in spatialGroundMeshes(
            visuals,
            textures,
            scene: scene,
          ))
            MeshComponent(mesh: mesh),
        ],
      );
      localBatches.resolve([_visual(0, animated: true, footprint: 128)]);
      final previous = [...localBatches.components];
      expect(previous, hasLength(2));
      final buffers = [
        for (final component in previous)
          component.mesh.surfaces.single.resource,
      ];
      localBatches.resolve([
        _visual(0, animated: true, footprint: 128, frameX: 32),
      ]);
      expect(localBatches.components, orderedEquals(previous));
      for (final (index, component) in localBatches.components.indexed) {
        final surface = component.mesh.surfaces.single;
        expect(surface.resource, same(buffers[index]));
        expect((surface.material as SpatialPixelMaterial).uvTransformU.z, .5);
      }
      localBatches.resolve([
        _visual(0, animated: true, footprint: 128),
        _visual(0, animated: true),
      ]);
      final mixed = [...localBatches.components];
      final changed = [
        _visual(0, animated: true, footprint: 128, frameX: 32),
        _visual(0, animated: true),
      ];
      localBatches.resolve(changed);
      expect(localBatches.components, orderedEquals(mixed));
      final surface = mixed.last.mesh.surfaces.single;
      surface.resource;
      final actual = Float32List.fromList(
        Float32List.view(
          backend.latest.bytes.buffer,
          0,
          surface.verticesBytes ~/ 4,
        ),
      );
      final reference = spatialGroundMeshes(
        changed,
        textures,
        scene: scene,
      ).last.surfaces.single;
      reference.createResource();
      final expected = Float32List.view(
        backend.latest.bytes.buffer,
        0,
        reference.verticesBytes ~/ 4,
      );
      expect(
        actual,
        orderedEquals(expected.map((value) => closeTo(value, .000001))),
      );
      expect((surface.material as SpatialPixelMaterial).uvTransformU.storage, [
        1,
        0,
        0,
        0,
      ]);
    },
  );

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
  String atlasId = 'atlas',
  SmartTileSpriteTransform? spriteTransform,
  int footprint = 1,
  SmartTileSpatialClip? clip,
}) {
  final transform = spriteTransform ?? SmartTileSpriteTransform(flipX: flipped);
  return (
    visual: SmartTileLayerVisual(
      cellX: x,
      cellY: 0,
      ruleId: 'rule',
      candidateId: 'candidate',
      channel: SmartTileRenderChannel.ground,
      isAnimated: animated,
      tilesetId: atlasId,
      sourceRect: SmartTileSourceRect(x: frameX, y: 0, width: 32, height: 32),
      transform: transform,
      spatialClip: clip,
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
        footprintWidth: footprint,
        footprintHeight: footprint,
        anchorX: 0,
        anchorY: 0,
        transform: transform,
      ),
      offsetUnit: SmartTileOffsetUnit.cell,
      offsetX: 0,
      offsetY: 0,
      footprintWidth: footprint,
      footprintHeight: footprint,
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
