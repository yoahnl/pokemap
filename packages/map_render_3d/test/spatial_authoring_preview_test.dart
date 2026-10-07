import 'dart:async';
import 'dart:typed_data';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame/game.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_cell_overlay.dart';
import 'package:map_render_3d/src/spatial_model_placement_preview.dart';
import 'package:map_render_3d/src/spatial_picking.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

ProjectModel3dEntry definition(String id, {double scale = 1}) =>
    ProjectModel3dEntry(
      id: id,
      name: id,
      sourceAssetId: 'source-$id',
      relativePath: 'assets/models3d/$id.glb',
      scale: scale,
      pivot: Model3dVector3(x: 1, y: 0, z: .5),
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 2, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 12,
      ),
    );

Model model() => Model.simple(
  mesh: CuboidMesh(
    size: Vector3.all(1),
    material: UnlitMaterial(albedoColor: const Color(0xffffffff)),
  ),
);

const previewColor = Color(0xff22aabb);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Freezed model getters keep model sources stable across hover rebuilds',
    () {
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      final initial = ProjectManifest(
        name: 'Preview project',
        maps: const [],
        tilesets: const [],
        models3d: [definition('tree')],
      );
      final loader = _ModelReader();
      SpatialSceneView view(
        ProjectManifest project, {
        List<ProjectModel3dEntry>? models,
        _ModelReader? reader,
      }) => SpatialSceneView(
        scene: MapSpatialScene(width: 2, depth: 2),
        groundProject: project,
        models: models ?? project.models3d,
        loadModel: (reader ?? loader).read,
        controller: controller,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff224422),
        edge: const Color(0xff111111),
        errorBuilder: (_, _) => const SizedBox(),
      );
      for (final project in [
        initial,
        ProjectManifest.fromJson(initial.toJson()),
      ]) {
        final before = view(project);
        final after = view(project);
        expect(identical(before.models, after.models), isFalse);
        expect(after.modelSourcesMatch(before), isTrue);
        expect(
          view(
            project.copyWith(name: 'Another project'),
          ).modelSourcesMatch(before),
          isFalse,
        );
        expect(
          view(project, reader: _ModelReader()).modelSourcesMatch(before),
          isFalse,
        );
        expect(
          view(
            project,
            models: [definition('tree', scale: 2)],
          ).modelSourcesMatch(before),
          isFalse,
        );
      }
    },
  );

  test(
    'surface hit retains the nearest continuous point and existing cell',
    () {
      final scene = MapSpatialScene(
        width: 2,
        depth: 2,
        heightLevels: [0, 0, 2, 0],
      );
      for (final ray in [
        (Vector3(.25, 10, .75), Vector3(0, -1, 0)),
        (Vector3(.5, 1, 4), Vector3(0, -.1, -1)),
        (Vector3(1, 10, .5), Vector3(0, -1, 0)),
      ]) {
        final hit = pickSpatialSurface(scene, ray.$1, ray.$2)!;
        expect(hit.cell, pickSpatialCell(scene, ray.$1, ray.$2));
      }
      final top = pickSpatialSurface(
        scene,
        Vector3(.25, 10, .75),
        Vector3(0, -1, 0),
      )!;
      expect(top.position, Model3dVector3(x: .25, y: 0, z: .75));
      final cliff = pickSpatialSurface(
        scene,
        Vector3(.5, 1, 4),
        Vector3(0, -.1, -1),
      )!;
      expect(cliff.position.y, closeTo(.8, .000001));
      expect(cliff.position.z, closeTo(2, .000001));
    },
  );

  test('continuous surface misses outside or behind the ray', () {
    final scene = MapSpatialScene(width: 2, depth: 2);
    expect(
      pickSpatialSurface(scene, Vector3(3, 10, .5), Vector3(0, -1, 0)),
      isNull,
    );
    expect(
      pickSpatialSurface(scene, Vector3(.5, 10, .5), Vector3(0, 1, 0)),
      isNull,
    );
  });

  test('fractional ramp point follows its slope with world level height', () {
    final scene = MapSpatialScene(
      width: 3,
      depth: 3,
      levelHeight: .5,
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
    final hit = pickSpatialSurface(
      scene,
      Vector3(1.4, 10, 1.7),
      Vector3(0, -1, 0),
    )!;
    expect(hit.cell, (1, 1));
    expect(hit.position.x, closeTo(1.4, .000001));
    expect(hit.position.z, closeTo(1.7, .000001));
    expect(hit.position.y, closeTo(.3, .000001));
    expect(hit.position.y, closeTo(scene.worldHeightAt(1.4, 1.7), .000001));
  });

  test('preview overlay uses target height without changing terrain', () {
    final scene = MapSpatialScene(width: 2, depth: 2);
    final overlay = SpatialCellOverlay(
      id: 'hover',
      cell: (1, 0),
      kind: SpatialCellOverlayKind.preview,
      color: previewColor,
      targetHeight: 2.5,
    );
    final surface = spatialCellOverlayMeshes(scene, [
      overlay,
    ]).single.surfaces.single;
    expect(surface.vertexCount, 16);
    expect([
      for (var i = 1; i < surface.positions.length; i += 3)
        surface.positions[i],
    ], everyElement(closeTo(2.535, .000001)));
    expect(scene.heightLevels, [0, 0, 0, 0]);
    expect(
      overlay,
      isNot(
        SpatialCellOverlay(
          id: 'hover',
          cell: (1, 0),
          kind: SpatialCellOverlayKind.preview,
          color: previewColor,
          targetHeight: 3,
        ),
      ),
    );
  });

  test(
    'placement preview defaults and frame honor pivot rotation and scale',
    () async {
      final original = model();
      final renderer = SpatialPlacementPreviewRenderer(
        World3D(),
        loadModel: (_) async => original,
      );
      addTearDown(renderer.dispose);
      final defaults = SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      );
      expect(defaults.rotationDegrees, 0);
      expect(defaults.scale, 1);
      await renderer.sync(
        preview: SpatialModelPlacementPreview(
          modelId: 'tree',
          position: Model3dVector3(x: 5.25, y: 2, z: 6.75),
          rotationDegrees: 90,
          scale: .5,
        ),
        models: [definition('tree', scale: 2)],
        color: previewColor,
        offset: const Offset(10, -4),
      );
      final component = renderer.component!;
      expect(component.model, same(original));
      expect(component.position.x, closeTo(15.75, .000001));
      expect(component.position.y, 2);
      expect(component.position.z, closeTo(1.75, .000001));
      expect(component.scale, Vector3.all(1));
      expect(component.children, hasLength(12));
      expect(
        (original.nodes.values.single.mesh!.surfaces.single.material
                as UnlitMaterial)
            .albedoColor,
        const Color(0xffffffff),
      );
    },
  );

  test('moving a loaded ghost reuses its component and parsed model', () async {
    var loads = 0;
    final renderer = SpatialPlacementPreviewRenderer(
      World3D(),
      loadModel: (_) async {
        loads++;
        return model();
      },
    );
    addTearDown(renderer.dispose);
    final models = [definition('tree')];
    await renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
      models: models,
      color: previewColor,
    );
    final initial = renderer.component;
    await renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3(x: 2.25, y: .75, z: 3.5),
      ),
      models: models,
      color: previewColor,
    );
    expect(renderer.component, same(initial));
    expect(loads, 1);
    expect(renderer.component!.position, Vector3(1.25, .75, 3));
  });

  testWidgets('moving a staged ghost keeps its pending mount and model', (
    tester,
  ) async {
    final game = FlameGame<World3D>(world: World3D());
    game.camera.world = null;
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();
    await tester.runAsync(game.ready);
    var loads = 0;
    final renderer = SpatialPlacementPreviewRenderer(
      game.world,
      loadModel: (_) async {
        loads++;
        return model();
      },
    );
    addTearDown(renderer.dispose);
    final models = [definition('tree')];
    final initial = renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
      models: models,
      color: previewColor,
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    final staged = renderer.component;
    expect(staged, isNotNull);
    final originalFrame = staged!.children.toList();
    var initialCompleted = false;
    initial.then((_) => initialCompleted = true);
    final moving = renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3(x: 3, y: 1, z: 4),
        scale: 2,
      ),
      models: models,
      color: const Color(0xffaabb22),
    );
    await tester.runAsync(game.ready);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(initialCompleted, isTrue);
    await tester.runAsync(() => moving);
    expect(loads, 1);
    expect(renderer.component, same(staged));
    expect(renderer.component!.position, Vector3(1, 1, 3));
    expect(renderer.component!.scale, Vector3.all(2));
    expect(renderer.component!.children.toList(), originalFrame);
    for (final child in renderer.component!.children.cast<MeshComponent>()) {
      expect(
        (child.mesh.surfaces.single.material as UnlitMaterial).albedoColor,
        const Color(0xffaabb22),
      );
    }
    await tester.pumpWidget(const SizedBox());
  });

  test('clearing an unfinished preview prevents its late attachment', () async {
    final pending = Completer<Model>();
    final renderer = SpatialPlacementPreviewRenderer(
      World3D(),
      loadModel: (_) => pending.future,
    );
    addTearDown(renderer.dispose);
    final rendering = renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
      models: [definition('tree')],
      color: previewColor,
    );
    renderer.clear();
    pending.complete(model());
    await rendering;
    expect(renderer.component, isNull);
  });

  test(
    'changing model prevents the stale model from replacing the latest',
    () async {
      final pending = Completer<Model>();
      final latestModel = model();
      final renderer = SpatialPlacementPreviewRenderer(
        World3D(),
        loadModel: (entry) =>
            entry.id == 'tree' ? pending.future : Future.value(latestModel),
      );
      addTearDown(renderer.dispose);
      final models = [definition('tree'), definition('rock')];
      final stale = renderer.sync(
        preview: SpatialModelPlacementPreview(
          modelId: 'tree',
          position: Model3dVector3.zero,
        ),
        models: models,
        color: previewColor,
      );
      await renderer.sync(
        preview: SpatialModelPlacementPreview(
          modelId: 'rock',
          position: Model3dVector3.zero,
        ),
        models: models,
        color: previewColor,
      );
      pending.complete(model());
      await stale;
      expect(renderer.component!.model, same(latestModel));
    },
  );

  test('closing the scene rejects outstanding preview loads', () async {
    final pending = Completer<Model>();
    final renderer = SpatialPlacementPreviewRenderer(
      World3D(),
      loadModel: (_) => pending.future,
    );
    final rendering = renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
      models: [definition('tree')],
      color: previewColor,
    );
    renderer.dispose();
    pending.complete(model());
    await rendering;
    expect(renderer.component, isNull);
  });

  test('null or removed model preview clears the loaded ghost', () async {
    final renderer = SpatialPlacementPreviewRenderer(
      World3D(),
      loadModel: (_) async => model(),
    );
    addTearDown(renderer.dispose);
    final preview = SpatialModelPlacementPreview(
      modelId: 'tree',
      position: Model3dVector3.zero,
    );
    final models = [definition('tree')];
    await renderer.sync(preview: preview, models: models, color: previewColor);
    await renderer.sync(preview: null, models: models, color: previewColor);
    expect(renderer.component, isNull);
    await renderer.sync(preview: preview, models: models, color: previewColor);
    await renderer.sync(
      preview: preview,
      models: const [],
      color: previewColor,
    );
    expect(renderer.component, isNull);
  });

  test('a successful preview clears the previous load error status', () async {
    final statuses = <Object?>[];
    final failure = StateError('unavailable preview model');
    final renderer = SpatialPlacementPreviewRenderer(
      World3D(),
      loadModel: (entry) async {
        if (entry.id == 'tree') throw failure;
        return model();
      },
      onStatus: statuses.add,
    );
    addTearDown(renderer.dispose);
    final models = [definition('tree'), definition('rock')];
    await renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
      models: models,
      color: previewColor,
    );
    expect(statuses, [failure]);
    await renderer.sync(
      preview: SpatialModelPlacementPreview(
        modelId: 'rock',
        position: Model3dVector3.zero,
      ),
      models: models,
      color: previewColor,
    );
    expect(statuses, [failure, null]);
    expect(renderer.component, isNotNull);
  });
}

final class _ModelReader {
  Future<Uint8List> read(String _) async => Uint8List(0);
}
