import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/components.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_cooperative_work.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_ground_mesh_batches.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

void main() {
  setUp(_UnusedBackend.new);

  group('spatialCollectSteps', () {
    test('yields to the event loop whenever its slice is exhausted', () async {
      var yields = 0;
      final budget = SpatialCooperativeBudget(
        slice: Duration.zero,
        yieldToFrames: () async => yields++,
      );
      final collected = await spatialCollectSteps<int>(
        [1, null, 2, null, null, 3],
        budget: budget,
        isCurrent: () => true,
      );
      expect(collected, [1, 2, 3]);
      expect(yields, 6);
      expect(budget.yields, 6);
    });

    test('never yields while the work fits in its slice', () async {
      var yields = 0;
      final collected = await spatialCollectSteps<int>(
        [1, null, 2],
        budget: SpatialCooperativeBudget(
          slice: const Duration(hours: 1),
          yieldToFrames: () async => yields++,
        ),
        isCurrent: () => true,
      );
      expect(collected, [1, 2]);
      expect(yields, 0);
    });

    test('stops consuming steps once the work is no longer current', () async {
      var current = true;
      var consumed = 0;
      Iterable<int?> steps() sync* {
        for (var index = 0; index < 10; index++) {
          consumed++;
          yield index;
        }
      }

      final collected = await spatialCollectSteps<int>(
        steps(),
        budget: SpatialCooperativeBudget(
          slice: Duration.zero,
          yieldToFrames: () async {
            if (consumed == 3) current = false;
          },
        ),
        isCurrent: () => current,
      );
      expect(collected, isNull);
      expect(consumed, 3);
    });

    test('the default yield resumes outside fake timer zones', () async {
      final budget = SpatialCooperativeBudget(slice: Duration.zero);
      final collected = await spatialCollectSteps<int>(
        [1, 2],
        budget: budget,
        isCurrent: () => true,
      );
      expect(collected, [1, 2]);
      expect(budget.yields, 2);
    });
  });

  test('stepwise ground meshes match the synchronous meshes exactly', () {
    final textures = _textures();
    final visuals = [for (var x = 0; x < 6; x++) _visual(x)];
    final synchronous = spatialGroundMeshes(visuals, textures).toList();
    final steps = spatialGroundMeshSteps(visuals, textures).toList();
    expect(steps.whereType<Mesh>(), hasLength(synchronous.length));
    expect(steps.where((step) => step == null), hasLength(visuals.length));
    _expectSameMeshes(steps.whereType<Mesh>().toList(), synchronous);
  });

  test('stepwise terrain meshes match the synchronous meshes exactly', () {
    final scene = MapSpatialScene(
      width: 3,
      depth: 2,
      heightLevels: [4, 0, 2, 0, 0, 4],
    );
    const ground = Color(0xff125588), edge = Color(0xff113344);
    final synchronous = terrainMeshes(scene, ground, edge).toList();
    final steps = terrainMeshSteps(scene, ground, edge).toList();
    expect(steps.where((step) => step == null), isNotEmpty);
    _expectSameMeshes(steps.whereType<Mesh>().toList(), synchronous);
  });

  test('stepwise batches commit the same components only once finished', () {
    final textures = _textures();
    List<MeshComponent> build(List<SpatialGroundVisual> visuals) => [
      for (final mesh in spatialGroundMeshes(visuals, textures))
        MeshComponent(mesh: mesh),
    ];
    Iterable<MeshComponent?> buildSteps(
      List<SpatialGroundVisual> visuals,
    ) sync* {
      for (final mesh in spatialGroundMeshSteps(visuals, textures)) {
        yield mesh == null ? null : MeshComponent(mesh: mesh);
      }
    }

    final visuals = [
      _visual(0),
      _visual(1),
      _visual(2, animated: true),
      _visual(3),
    ];
    final reference = SpatialGroundMeshBatches(build)..resolve(visuals);
    final stepwise = SpatialGroundMeshBatches(build, buildSteps: buildSteps);

    final abandoned = stepwise.resolveSteps(visuals).iterator;
    expect(abandoned.moveNext(), isTrue);
    expect(stepwise.components, isEmpty);

    var yields = 0;
    for (final _ in stepwise.resolveSteps(visuals)) {
      yields++;
    }
    expect(yields, greaterThanOrEqualTo(visuals.length));
    expect(stepwise.components, hasLength(reference.components.length));
    _expectSameMeshes(
      [for (final component in stepwise.components) component.mesh],
      [for (final component in reference.components) component.mesh],
    );
    expect(
      [for (final component in stepwise.components) component.priority],
      [for (final component in reference.components) component.priority],
    );
  });

  test('without stepwise builders batches keep their synchronous path', () {
    var builds = 0;
    final batches = SpatialGroundMeshBatches((visuals) {
      builds++;
      return [
        for (final mesh in spatialGroundMeshes(visuals, _textures()))
          MeshComponent(mesh: mesh),
      ];
    });
    var yields = 0;
    for (final _ in batches.resolveSteps([_visual(0), _visual(1)])) {
      yields++;
    }
    expect(builds, 1);
    expect(yields, 0);
    expect(batches.components, hasLength(1));
  });
}

void _expectSameMeshes(List<Mesh> actual, List<Mesh> expected) {
  expect(actual, hasLength(expected.length));
  for (var index = 0; index < expected.length; index++) {
    final a = actual[index].surfaces.toList();
    final e = expected[index].surfaces.toList();
    expect(a, hasLength(e.length));
    for (var surface = 0; surface < e.length; surface++) {
      expect(a[surface].positions, e[surface].positions);
      expect(a[surface].indices, e[surface].indices);
      expect(a[surface].vertexCount, e[surface].vertexCount);
    }
  }
}

Map<String, Texture> _textures() => {
  'atlas': Texture(ByteData(64 * 32 * 4), width: 64, height: 32),
};

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

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
