import 'dart:typed_data';

import 'package:avelune_render_contracts/avelune_render_contracts.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';

import 'support/billboard_glb_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returning through a door reuses the previous map unchanged', () async {
    final f = _Retention();
    addTearDown(f.dispose);
    expect(await f.show(f.a), isTrue);
    final chunk = f.game.sceneChunks['a'];
    final reads = (f.modelReads, f.imageReads);
    expect(await f.show(f.b), isTrue);
    expect(f.game.sceneChunks.keys, ['b']);
    expect(f.game.cache.keys, contains('tree-source'));
    expect(f.game.groundTextureCache.keys, contains('ground'));
    expect(
      await f.game.prepareDestination(f.request(f.a)),
      isA<DestinationAlreadyCovered>(),
    );
    expect(await f.show(f.a), isTrue);
    expect(f.game.sceneChunks['a'], same(chunk));
    expect((f.modelReads, f.imageReads), reads);
  });

  test('a second map change releases the previous map', () async {
    final f = _Retention();
    addTearDown(f.dispose);
    expect(await f.show(f.a), isTrue);
    final chunk = f.game.sceneChunks['a'];
    expect(await f.show(f.b), isTrue);
    expect(await f.show(f.c), isTrue);
    expect(f.game.cache, isEmpty);
    expect(f.game.modelReservations, isEmpty);
    expect(f.game.groundTextureCache, isEmpty);
    expect(f.game.groundReservations, isEmpty);
    expect(f.budget.residentBytes, 0);
    expect(await f.show(f.a), isTrue);
    expect(f.game.sceneChunks['a'], isNot(same(chunk)));
    expect(f.modelReads, 2);
  });

  for (final (label, edit, covered) in [
    ('an equal copy of', (MapData map) => map.copyWith(), true),
    ('an edited', (MapData map) => map.copyWith(name: 'Edited'), false),
  ]) {
    test(
      'preparing $label the previous map ${covered ? 'skips' : 'runs'} the preparation',
      () async {
        final f = _Retention();
        addTearDown(f.dispose);
        expect(await f.show(f.a), isTrue);
        expect(await f.show(f.b), isTrue);
        var checks = 0;
        expect(
          await f.game.prepareDestination(
            f.request(
              edit(f.a),
              isCurrent: () {
                checks++;
                return true;
              },
            ),
          ),
          covered
              ? isA<DestinationAlreadyCovered>()
              : isA<DestinationPrepared>(),
        );
        expect(checks, covered ? 1 : greaterThan(1));
      },
    );
  }

  test('memory pressure evicts the whole previous map', () async {
    final f = _Retention();
    addTearDown(f.dispose);
    expect(await f.show(f.a), isTrue);
    final chunk = f.game.sceneChunks['a'];
    expect(await f.show(f.b), isTrue);
    expect(f.budget.residentBytes, greaterThan(0));
    final other = await f.budget.acquire(
      residentBytes: f.budget.profile.maximumResidentBytes,
    );
    expect(f.game.cache, isEmpty);
    expect(f.game.modelReservations, isEmpty);
    expect(f.game.groundTextureCache, isEmpty);
    expect(f.game.groundReservations, isEmpty);
    expect(f.budget.residentBytes, f.budget.profile.maximumResidentBytes);
    other.release();
    expect(await f.game.prepareDestination(f.request(f.a)), isA<DestinationPrepared>());
    expect(await f.show(f.a), isTrue);
    expect(f.game.sceneChunks['a'], isNot(same(chunk)));
    expect(f.modelReads, 2);
  });

  test('the map in use again is no longer evictable', () async {
    final f = _Retention();
    addTearDown(f.dispose);
    expect(await f.show(f.a), isTrue);
    expect(await f.show(f.b), isTrue);
    expect(await f.show(f.a), isTrue);
    await expectLater(
      f.budget.acquire(residentBytes: f.budget.profile.maximumResidentBytes),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(f.game.cache.keys, contains('tree-source'));
    expect(f.game.groundTextureCache.keys, contains('ground'));
    expect(f.budget.residentBytes, greaterThan(0));
  });

  test('changing the project drops the previous map', () async {
    final f = _Retention();
    addTearDown(f.dispose);
    expect(await f.show(f.a), isTrue);
    final chunk = f.game.sceneChunks['a'];
    expect(await f.show(f.b), isTrue);
    f.game.configuration = f.configuration(
      f.a,
      project: f.project.copyWith(name: 'Edited'),
    );
    expect(await f.game.refresh(), isTrue);
    expect(f.game.sceneChunks['a'], isNot(same(chunk)));
  });
}

final class _Retention {
  _Retention() {
    _UnusedBackend();
    project = ProjectManifest(
      name: 'Retention',
      maps: const [],
      tilesets: const [],
      models3d: [
        ProjectModel3dEntry(
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
            triangleCount: 2,
          ),
        ),
      ],
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
    a = MapData(
      id: 'a',
      name: 'A',
      size: const GridSize(width: 2, height: 2),
      layers: [MapLayer.tile(id: 'ordinary', name: 'Ordinary')],
      spatialScene: MapSpatialScene(
        width: 2,
        depth: 2,
        cliffFrame: const SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
        ),
        instances: [
          SpatialModelInstance(
            id: 'tree',
            modelId: 'tree',
            position: Model3dVector3.zero,
          ),
        ],
      ),
    );
    b = MapData(
      id: 'b',
      name: 'B',
      size: const GridSize(width: 2, height: 2),
      spatialScene: MapSpatialScene(width: 2, depth: 2),
    );
    c = b.copyWith(id: 'c', name: 'C');
    game =
        SpatialSceneGame(
            configuration(a),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
  }

  final budget = RuntimeResourceBudget();
  final controller = SpatialSceneController();
  late final ProjectManifest project;
  late final MapData a, b, c;
  late final SpatialSceneGame game;
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 32, height: 32)),
  );
  final glb = billboardGlb(opaque: (_, _) => true);
  var modelReads = 0, imageReads = 0;

  Future<Uint8List> loadModel(String _) async {
    modelReads++;
    return glb;
  }

  Future<Uint8List> loadImage(String _) async {
    imageReads++;
    return png;
  }

  Future<bool> show(MapData map) {
    game.configuration = configuration(map);
    return game.refresh();
  }

  SpatialScenePreparation request(MapData map, {bool Function()? isCurrent}) =>
      SpatialScenePreparation(
        map: map,
        project: project,
        loadModel: loadModel,
        loadGroundImage: loadImage,
        resourceIdentity: 'project',
        resourceBudget: budget,
        isCurrent: isCurrent ?? () => true,
      );

  SpatialSceneView configuration(MapData map, {ProjectManifest? project}) =>
      SpatialSceneView(
        scene: map.spatialScene!,
        groundMap: map,
        groundProject: project ?? this.project,
        models: this.project.models3d,
        loadModel: loadModel,
        loadGroundImage: loadImage,
        controller: controller,
        resourceIdentity: 'project',
        resourceBudget: budget,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff224422),
        edge: const Color(0xff111111),
        errorBuilder: (_, _) => const SizedBox(),
      );

  void dispose() {
    game.onRemove();
    controller.dispose();
    budget.dispose();
  }
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}
