import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flame_3d/core.dart' show Vector2;
import 'package:flame_3d/graphics.dart' show GpuBackend;
import 'package:flutter/widgets.dart' hide Texture;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart' show SpatialSceneGame;
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_actor_occlusion.dart';

final project = ProjectManifest(
  name: 'Pilot',
  maps: const [],
  tilesets: const [],
  models3d: [
    ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'source-tree',
      relativePath: 'assets/models3d/tree.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    ),
  ],
);
MapData target() => MapData(
  id: 'target',
  name: 'Target',
  size: GridSize(width: 2, height: 2),
  layers: const [],
  spatialScene: MapSpatialScene(
    width: 2,
    depth: 2,
    instances: [
      SpatialModelInstance(
        id: 'tree-1',
        modelId: 'tree',
        position: Model3dVector3.zero,
      ),
    ],
  ),
);
SpatialSceneView view(
  ProjectManifest manifest,
  RuntimeResourceBudget budget, {
  String? identity,
}) => SpatialSceneView(
  scene: MapSpatialScene(width: 2, depth: 2),
  models: manifest.models3d,
  loadModel: (_) async => _triangle('tree'),
  groundProject: manifest,
  resourceIdentity: identity,
  resourceBudget: budget,
  controller: SpatialSceneController(),
  onCell: (_, __) {},
  background: const Color(0xff000000),
  ground: const Color(0xff000000),
  edge: const Color(0xff000000),
  errorBuilder: (_, __) => const SizedBox(),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'prepared plans transfer once without changing adopted resources',
    () async {
      final f = _PreparedPlansFixture();
      addTearDown(f.dispose);
      expect(await f.preparation.prepare(), isTrue);
      f.adopt();
      final model = f.models['source-tree'];
      final lease = f.modelLeases['source-tree'];
      final resident = f.budget.residentBytes;
      final plans = f.take();
      expect(plans, isNotNull);
      expect(f.take(), isNull);
      f.preparation.commit();
      expect(f.take(), isNull);
      expect(plans!.ground.scene, same(f.map.spatialScene));
      expect(plans.occlusion.map, same(f.map));
      expect(plans.ground.resolve(100), isEmpty);
      expect(f.models['source-tree'], same(model));
      expect(f.modelLeases['source-tree'], same(lease));
      expect(f.budget.residentBytes, resident);
      expect(f.budget.transientBytes, 0);
    },
  );
  for (final mismatch in [
    'not ready',
    'not adopted',
    'committed',
    'discarded',
    'map',
    'project',
    'identity',
    'budget',
    'request',
    'source',
  ]) {
    test(
      'prepared plans reject $mismatch without changing resources',
      () async {
        final f = _PreparedPlansFixture();
        addTearDown(f.dispose);
        if (mismatch != 'not ready') {
          expect(await f.preparation.prepare(), isTrue);
          if (mismatch != 'not adopted') f.adopt();
        }
        if (mismatch == 'committed') f.preparation.commit();
        if (mismatch == 'discarded') f.preparation.discard();
        if (mismatch == 'request') f.requestCurrent = false;
        if (mismatch == 'source') f.sourceCurrent = false;
        final models = Map.of(f.models);
        final textures = Map.of(f.textures);
        final modelLeases = Map.of(f.modelLeases);
        final textureLeases = Map.of(f.textureLeases);
        final resident = f.budget.residentBytes;
        final otherBudget = RuntimeResourceBudget();
        addTearDown(otherBudget.dispose);
        expect(
          f.preparation.takePreparedPlans(
            map: mismatch == 'map' ? f.map.copyWith() : f.map,
            project: mismatch == 'project' ? project.copyWith() : project,
            resourceIdentity: mismatch == 'identity' ? 'other' : 'root:sha',
            resourceBudget: mismatch == 'budget' ? otherBudget : f.budget,
          ),
          isNull,
        );
        expect(f.models, models);
        expect(f.textures, textures);
        expect(f.modelLeases, modelLeases);
        expect(f.textureLeases, textureLeases);
        expect(f.budget.residentBytes, resident);
        expect(f.budget.transientBytes, 0);
        expect(f.budget.activeDecodes, 0);
      },
    );
  }
  test('independent preparations never share mutable plans', () async {
    final first = _PreparedPlansFixture();
    final second = _PreparedPlansFixture(map: first.map, budget: first.budget);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    expect(await first.preparation.prepare(), isTrue);
    expect(await second.preparation.prepare(), isTrue);
    first.adopt();
    second.adopt();
    final a = first.take()!;
    final b = second.take()!;
    expect(a.ground, isNot(same(b.ground)));
    expect(a.occlusion, isNot(same(b.occlusion)));
    a.ground.cliff = (
      tilesetId: 'changed',
      sourceRect: const SmartTileSourceRect(x: 0, y: 0, width: 1, height: 1),
    );
    first.preparation.discard();
    expect(a.ground.cliff?.tilesetId, 'changed');
    expect(b.ground.cliff, isNull);
  });
  for (final elapsed in [0, 134]) {
    test(
      'prepared mixed SmartTile activation matches fresh plans at $elapsed with current onEnter clocks',
      () async {
        _UnusedBackend();
        final f = _mixedPreparedFixture();
        final budget = RuntimeResourceBudget();
        final controller = SpatialSceneController();
        final png = Uint8List.fromList(
          img.encodePng(img.Image(width: 32, height: 32)),
        );
        var active = true;
        var localElapsed = elapsed + 67;
        final game =
            SpatialSceneGame(
                SpatialSceneView(
                  scene: f.map.spatialScene!,
                  groundMap: f.map,
                  groundProject: f.project,
                  models: f.project.models3d,
                  loadModel: (_) async => _triangle('Tree'),
                  loadGroundImage: (_) async => png,
                  controller: controller,
                  resourceBudget: budget,
                  resourceIdentity: 'mixed',
                  rasterAnimationElapsedMsForCell: (_, _, _, _, _) =>
                      localElapsed,
                  actorOcclusionStateForCell: (_, _, x, _, _) =>
                      (active: active && x == 0, elapsedMs: localElapsed),
                  presentationElapsedSeconds: () => elapsed / 1000,
                  onCell: (_, _) {},
                  background: const Color(0xff000000),
                  ground: const Color(0xff224422),
                  edge: const Color(0xff111111),
                  errorBuilder: (_, _) => const SizedBox(),
                ),
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
        expect(
          await game.prepareDestination(
            SpatialScenePreparation(
              map: f.map,
              project: f.project,
              loadModel: (_) async => _triangle('Tree'),
              loadGroundImage: (_) async => png,
              resourceIdentity: 'mixed',
              resourceBudget: budget,
              isCurrent: () => true,
            ),
          ),
          isTrue,
        );
        game.groundElapsed = elapsed / 1000;
        expect(await game.refresh(), isTrue);
        game.update(0);
        final projected = projectSpatialSmartTileModels(
          map: f.map,
          catalog: f.project.smartTileCatalog,
        );
        final projection = resolveSpatialSmartTileModelProjection(
          map: f.map,
          catalog: f.project.smartTileCatalog,
        );
        final freshGround = SpatialGroundPlan(projected, f.project);
        final freshOcclusion = SpatialActorOcclusionPlan(projected, f.project);
        final ground = game.grounds.single;
        expect(projected.spatialScene!.instances.length, 7);
        expect(
          game.modelComponents.keys,
          unorderedEquals(
            projected.spatialScene!.instances.map((instance) => instance.id),
          ),
        );
        expect(game.sceneChunks[f.map.id]!.cellOrigins, projection.cellOrigins);
        expect(
          ground.plan.groundReplacementCells,
          freshGround.groundReplacementCells,
        );
        expect(ground.plan.bridgeCells, freshGround.bridgeCells);
        expect(ground.plan.cliff, freshGround.cliff);
        expect(
          ground.visuals.map(_groundSignature),
          freshGround
              .resolve(
                elapsed,
                animationElapsedMsForCell: (_, _, _, _) => localElapsed,
              )
              .map(_groundSignature),
        );
        expect(ground.currentImageIds, {
          ...freshGround.imageIdsAt(
            elapsed,
            animationElapsedMsForCell: (_, _, _, _) => localElapsed,
          ),
          for (final visual in freshOcclusion.resolve(
            elapsed,
            stateForCell: (_, x, _, _) =>
                (active: active && x == 0, elapsedMs: localElapsed),
          ))
            visual.visual.tilesetId,
        });
        for (final point in [(0.5, 0.5), (1.5, 0.5), (0.5, 1.5), (2.5, 1.5)]) {
          expect(
            ground.plan.scene!.worldHeightAt(point.$1, point.$2),
            freshGround.scene!.worldHeightAt(point.$1, point.$2),
          );
        }
        for (final nextActive in [true, false, true]) {
          active = nextActive;
          localElapsed += 67;
          final preparedVisuals = ground.occlusionPlan.resolve(
            elapsed,
            stateForCell: (_, x, _, _) =>
                (active: active && x == 0, elapsedMs: localElapsed),
          );
          final freshVisuals = freshOcclusion.resolve(
            elapsed,
            stateForCell: (_, x, _, _) =>
                (active: active && x == 0, elapsedMs: localElapsed),
          );
          expect(
            preparedVisuals.map(_occlusionSignature),
            freshVisuals.map(_occlusionSignature),
          );
          expect(preparedVisuals.length, active ? 2 : 0);
        }
      },
    );
  }
  test('immutable catalogue scope survives map projection changes only with same budget', () {
    final budget = RuntimeResourceBudget();
    final before = view(project, budget, identity: 'root:sha');
    final after = view(
      project.copyWith(name: 'Projection'),
      budget,
      identity: 'root:sha',
    );
    addTearDown(before.controller.dispose);
    addTearDown(after.controller.dispose);
    addTearDown(budget.dispose);
    expect(after.modelSourcesMatch(before), isTrue);
    expect(after.immutableResourcesMatch(before), isTrue);
    for (final candidate in [
      view(project.copyWith(name: 'Other'), budget, identity: 'other:sha'),
      view(
        project.copyWith(name: 'Other'),
        RuntimeResourceBudget(),
        identity: 'root:sha',
      ),
      view(project.copyWith(name: 'Other'), budget),
    ]) {
      expect(candidate.immutableResourcesMatch(before), isFalse);
      expect(candidate.modelSourcesMatch(before), isFalse);
      candidate.controller.dispose();
    }
  });
  test(
    'unmounted controller declines destination preparation without loading',
    () async {
      final controller = SpatialSceneController();
      addTearDown(controller.dispose);
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      var reads = 0;
      expect(
        await controller.prepareDestination(
          SpatialScenePreparation(
            map: target(),
            project: project,
            loadModel: (_) async {
              reads++;
              return _triangle('tree');
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => true,
          ),
        ),
        isFalse,
      );
      expect(reads, 0);
    },
  );
  test('prepared models reuse warm entries and transfer their existing budget lease', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final modelLeases = <String, RuntimeResourceReservation>{};
    final textureLeases = <String, RuntimeResourceReservation>{};
    var reads = 0;
    SpatialSceneResourcePreparation prepare() =>
        SpatialSceneResourcePreparation(
          SpatialScenePreparation(
            map: target(),
            project: project,
            loadModel: (_) async {
              reads++;
              return _triangle('tree');
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => true,
          ),
          modelCache: cache,
          groundTextureCache: textures,
          isCurrent: () => true,
        );
    final first = prepare();
    expect(await first.prepare(), isTrue);
    expect(cache, isEmpty);
    expect(budget.residentBytes, greaterThan(0));
    first.adoptInto(cache, textures, modelLeases, textureLeases);
    final lease = modelLeases['source-tree'];
    final resident = budget.residentBytes;
    first.commit();
    final second = prepare();
    expect(await second.prepare(), isTrue);
    second.adoptInto(cache, textures, modelLeases, textureLeases);
    second.commit();
    expect(reads, 1);
    expect(modelLeases['source-tree'], same(lease));
    expect(budget.residentBytes, resident);
    expect(cache.length, 1);
  });
  test('cancelled preparation releases only new resources and never publishes late', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final gate = Completer<Uint8List>();
    var current = true;
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) => gate.future,
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => current,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    final loading = prep.prepare();
    await Future<void>.delayed(Duration.zero);
    current = false;
    gate.complete(_triangle('tree'));
    expect(await loading, isFalse);
    expect(cache, isEmpty);
    expect(textures, isEmpty);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });
  for (final layerCount in [1, 1000]) {
    for (final cancellation in ['request', 'source', null]) {
      test(
        'warm preparation ${cancellation == null ? 'builds plans' : 'skips plans after $cancellation cancellation'} with $layerCount layers',
        () async {
          final budget = RuntimeResourceBudget();
          addTearDown(budget.dispose);
          final lease = await budget.acquire(residentBytes: 128);
          lease.commit();
          addTearDown(lease.release);
          final warmModel = Future.value(Model(nodes: {}, animations: const []));
          final models = {'source-tree': warmModel};
          final textures = <String, Future<Texture>>{};
          final modelLeases = {'source-tree': lease};
          final textureLeases = <String, RuntimeResourceReservation>{};
          final layers = _CountingLayers(layerCount);
          var requestCurrent = true;
          var sourceCurrent = true;
          var modelReads = 0;
          var imageReads = 0;
          final prep = SpatialSceneResourcePreparation(
            SpatialScenePreparation(
              map: target().copyWith(layers: layers),
              project: project,
              loadModel: (_) async {
                modelReads++;
                return _triangle('tree');
              },
              loadGroundImage: (_) async {
                imageReads++;
                return Uint8List(0);
              },
              resourceIdentity: 'root:sha',
              resourceBudget: budget,
              isCurrent: () => requestCurrent,
            ),
            modelCache: models,
            groundTextureCache: textures,
            isCurrent: () => sourceCurrent,
          );
          addTearDown(prep.discard);
          final loading = prep.prepare();
          if (cancellation == 'request') requestCurrent = false;
          if (cancellation == 'source') sourceCurrent = false;
          layers.reads = 0;
          expect(await loading, cancellation == null);
          expect(layers.reads, cancellation == null ? greaterThan(0) : 0);
          if (cancellation == null) {
            prep.adoptInto(models, textures, modelLeases, textureLeases);
            prep.commit();
          } else {
            expect(
              () => prep.adoptInto(
                models,
                textures,
                modelLeases,
                textureLeases,
              ),
              throwsStateError,
            );
          }
          expect(modelReads, 0);
          expect(imageReads, 0);
          expect(models, {'source-tree': same(warmModel)});
          expect(modelLeases, {'source-tree': same(lease)});
          expect(textures, isEmpty);
          expect(textureLeases, isEmpty);
          expect(budget.residentBytes, 128);
          expect(budget.transientBytes, 0);
          expect(budget.activeDecodes, 0);
        },
      );
    }
  }
  test('failed preparation releases leases and remains retryable', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) async => throw StateError('missing'),
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => true,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    await expectLater(prep.prepare(), throwsStateError);
    expect(cache, isEmpty);
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
    expect(budget.activeDecodes, 0);
  });
  test(
    'native ground textures preload and remain warm after adoption',
    () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final catalog = ProjectSmartTileCatalog(
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'ground',
            columns: 1,
            rows: 1,
          ),
        ],
      );
      final groundProject = project.copyWith(smartTileCatalog: catalog);
      final groundMap = target().copyWith(
        spatialScene: target().spatialScene!.copyWith(
          cliffFrame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
        ),
      );
      final models = <String, Future<Model>>{};
      final textures = <String, Future<Texture>>{};
      final modelLeases = <String, RuntimeResourceReservation>{};
      final textureLeases = <String, RuntimeResourceReservation>{};
      var reads = 0;
      SpatialSceneResourcePreparation next() => SpatialSceneResourcePreparation(
        SpatialScenePreparation(
          map: groundMap,
          project: groundProject,
          loadModel: (_) async => _triangle('tree'),
          loadGroundImage: (_) async {
            reads++;
            return Uint8List.fromList(
              img.encodePng(img.Image(width: 2, height: 2)),
            );
          },
          resourceIdentity: 'root:sha',
          resourceBudget: budget,
          isCurrent: () => true,
        ),
        modelCache: models,
        groundTextureCache: textures,
        isCurrent: () => true,
      );
      final first = next();
      expect(await first.prepare(), isTrue);
      first.adoptInto(models, textures, modelLeases, textureLeases);
      final original = await textures['ground'];
      final resident = budget.residentBytes;
      first.commit();
      final second = next();
      expect(await second.prepare(), isTrue);
      second.adoptInto(models, textures, modelLeases, textureLeases);
      second.commit();
      expect(reads, 1);
      expect(await textures['ground'], same(original));
      expect(textureLeases.length, 1);
      expect(budget.residentBytes, resident);
    },
  );
  test(
    'partial failure releases completed new model before publication',
    () async {
      final budget = RuntimeResourceBudget();
      addTearDown(budget.dispose);
      final models = <String, Future<Model>>{};
      final textures = <String, Future<Texture>>{};
      final map = target().copyWith(
        spatialScene: target().spatialScene!.copyWith(
          instances: [
            ...target().spatialScene!.instances,
            SpatialModelInstance(
              id: 'missing',
              modelId: 'missing',
              position: Model3dVector3.zero,
            ),
          ],
        ),
      );
      final prep = SpatialSceneResourcePreparation(
        SpatialScenePreparation(
          map: map,
          project: project,
          loadModel: (_) async => _triangle('tree'),
          loadGroundImage: (_) async => Uint8List(0),
          resourceIdentity: 'root:sha',
          resourceBudget: budget,
          isCurrent: () => true,
        ),
        modelCache: models,
        groundTextureCache: textures,
        isCurrent: () => true,
      );
      await expectLater(prep.prepare(), throwsStateError);
      expect(models, isEmpty);
      expect(budget.residentBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );
  test('cancelling adopted warm preparation releases its entries before map activation', () async {
    final budget = RuntimeResourceBudget();
    addTearDown(budget.dispose);
    final cache = <String, Future<Model>>{};
    final textures = <String, Future<Texture>>{};
    final leases = <String, RuntimeResourceReservation>{};
    final groundLeases = <String, RuntimeResourceReservation>{};
    final prep = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: target(),
        project: project,
        loadModel: (_) async => _triangle('tree'),
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: budget,
        isCurrent: () => true,
      ),
      modelCache: cache,
      groundTextureCache: textures,
      isCurrent: () => true,
    );
    expect(await prep.prepare(), isTrue);
    prep.adoptInto(cache, textures, leases, groundLeases);
    expect(cache.length, 1);
    prep.discard();
    expect(cache, isEmpty);
    expect(leases, isEmpty);
    expect(budget.residentBytes, 0);
  });
  for (final cancel in [false, true]) {
    test(
      'two preparation workers bound reads and drain cancellation=$cancel',
      () async {
        final budget = RuntimeResourceBudget();
        addTearDown(budget.dispose);
        final definitions = [
          for (var i = 0; i < 6; i++)
            ProjectModel3dEntry(
              id: 'model-$i',
              name: 'Model $i',
              sourceAssetId: 'source-$i',
              relativePath: 'assets/models3d/model-$i.glb',
              inspection: Model3dInspection(
                bounds: Model3dBounds(
                  min: Model3dVector3.zero,
                  max: Model3dVector3(x: 1, y: 1, z: 1),
                ),
                meshCount: 1,
                triangleCount: 1,
              ),
            ),
        ];
        final map = target().copyWith(
          spatialScene: target().spatialScene!.copyWith(
            instances: [
              for (var i = 0; i < 6; i++)
                SpatialModelInstance(
                  id: 'instance-$i',
                  modelId: 'model-$i',
                  position: Model3dVector3.zero,
                ),
            ],
          ),
        );
        final gates = [for (var i = 0; i < 6; i++) Completer<Uint8List>()];
        final started = <int>[];
        var active = 0, maximum = 0;
        var current = true;
        final cache = <String, Future<Model>>{};
        final prep = SpatialSceneResourcePreparation(
          SpatialScenePreparation(
            map: map,
            project: project.copyWith(models3d: definitions),
            loadModel: (id) async {
              final i = int.parse(id.split('-').last);
              started.add(i);
              active++;
              if (active > maximum) maximum = active;
              try {
                return await gates[i].future;
              } finally {
                active--;
              }
            },
            loadGroundImage: (_) async => Uint8List(0),
            resourceIdentity: 'root:sha',
            resourceBudget: budget,
            isCurrent: () => current,
          ),
          modelCache: cache,
          groundTextureCache: <String, Future<Texture>>{},
          isCurrent: () => true,
        );
        final loading = prep.prepare();
        try {
          await Future<void>.delayed(Duration.zero);
          expect(started, [0, 1]);
          if (cancel) current = false;
          for (final gate in gates) {
            if (!gate.isCompleted) gate.complete(_triangle('tree'));
          }
          expect(await loading, !cancel);
          expect(maximum, 2);
          expect(started, cancel ? [0, 1] : [0, 1, 2, 3, 4, 5]);
          expect(cache, isEmpty);
          prep.discard();
          expect(budget.residentBytes, 0);
          expect(budget.transientBytes, 0);
          expect(budget.activeDecodes, 0);
        } finally {
          for (final gate in gates) {
            if (!gate.isCompleted) gate.complete(_triangle('tree'));
          }
          await loading;
          prep.discard();
        }
      },
    );
  }
}

final class _PreparedPlansFixture {
  _PreparedPlansFixture({MapData? map, RuntimeResourceBudget? budget})
    : map = map ?? target(),
      budget = budget ?? RuntimeResourceBudget() {
    preparation = SpatialSceneResourcePreparation(
      SpatialScenePreparation(
        map: this.map,
        project: project,
        loadModel: (_) async => _triangle('tree'),
        loadGroundImage: (_) async => Uint8List(0),
        resourceIdentity: 'root:sha',
        resourceBudget: this.budget,
        isCurrent: () => requestCurrent,
      ),
      modelCache: models,
      groundTextureCache: textures,
      isCurrent: () => sourceCurrent,
    );
  }
  final MapData map;
  final RuntimeResourceBudget budget;
  final models = <String, Future<Model>>{};
  final textures = <String, Future<Texture>>{};
  final modelLeases = <String, RuntimeResourceReservation>{};
  final textureLeases = <String, RuntimeResourceReservation>{};
  late final SpatialSceneResourcePreparation preparation;
  bool requestCurrent = true, sourceCurrent = true;
  void adopt() =>
      preparation.adoptInto(models, textures, modelLeases, textureLeases);
  SpatialPreparedScenePlans? take() => preparation.takePreparedPlans(
    map: map,
    project: project,
    resourceIdentity: 'root:sha',
    resourceBudget: budget,
  );
  void dispose() {
    preparation.discard();
    for (final lease in [...modelLeases.values, ...textureLeases.values]) {
      lease.release();
    }
    budget.dispose();
  }
}

Object _groundSignature(SpatialGroundVisual value) => (
  value.height,
  value.opacity,
  value.visual.cellX,
  value.visual.cellY,
  value.visual.channel,
  value.visual.tilesetId,
  value.visual.sourceRect,
  value.visual.geometry.visualBounds,
  value.visual.drawOrder,
);

Object _occlusionSignature(SpatialActorOcclusionVisual value) => (
  value.id,
  value.x,
  value.y,
  value.z,
  value.width,
  value.height,
  value.opacity,
  value.visual.cellX,
  value.visual.cellY,
  value.visual.tilesetId,
  value.visual.sourceRect,
  value.visual.geometry.visualBounds,
);

({MapData map, ProjectManifest project}) _mixedPreparedFixture() {
  final layer = SmartTileLayer(
    id: 'mixed',
    name: 'Mixed',
    presetId: 'mixed',
    usage: SmartTileUsage.terrain,
    materialPalette: const ['', 'grass'],
    animationActivation: SmartTileAnimationActivation.onEnter,
    field: const SmartTileField.cell(semanticCells: [1, 1, 1, 1, 1, 1]),
  );
  final map = MapData(
    id: 'mixed',
    name: 'Mixed',
    size: const GridSize(width: 3, height: 2),
    layers: [layer],
    spatialScene: MapSpatialScene(
      width: 3,
      depth: 2,
      heightLevels: [0, 0, 4, 4, 4, 4],
      levelHeight: .25,
      cliffFrame: const SmartTileFrameRef(
        atlasId: 'atlas-0',
        column: 0,
        row: 0,
      ),
      instances: [
        SpatialModelInstance(
          id: 'authored',
          modelId: 'tree',
          position: Model3dVector3.zero,
        ),
      ],
      navigation: SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 1,
            z: 0,
            width: 1,
            depth: 1,
            lowLevel: 0,
            highLevel: 4,
            direction: SpatialRampDirection.east,
          ),
        ],
      ),
      terrainSurfaces: SpatialTerrainSurfaceSet(
        surfaces: [
          SpatialTerrainSurface(
            id: 'slope',
            x: 0,
            z: 1,
            height: 1,
            gradientX: .25,
            gradientZ: .5,
            footprints: [
              BorderGroundFootprint(
                points: [
                  BorderGroundPoint(x: 0, z: 0),
                  BorderGroundPoint(x: 3, z: 0),
                  BorderGroundPoint(x: 3, z: 1),
                  BorderGroundPoint(x: 0, z: 1),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return (
    map: map,
    project: project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        atlases: [
          for (var i = 0; i < 4; i++)
            ProjectSmartTileAtlas(
              id: 'atlas-$i',
              name: 'Atlas $i',
              tilesetId: 'page-$i',
              columns: 1,
              rows: 1,
            ),
        ],
        animations: [
          ProjectSmartTileAnimation(
            id: 'wave',
            name: 'Wave',
            frames: [
              for (var i = 0; i < 4; i++)
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas-$i',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 67,
                ),
            ],
          ),
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'mixed',
            name: 'Mixed',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: const SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: const SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: const ['grass'],
            rules: [
              SmartTileRule(
                id: 'fill',
                centerMatch: const SmartTileSlotMatch.material('grass'),
                candidates: const [
                  SmartTileCandidate(
                    id: 'fill',
                    parts: [
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.model3d(modelId: 'tree'),
                      ),
                      SmartTileVisualPart(
                        source: SmartTileVisualSource.animation(
                          animationId: 'wave',
                        ),
                      ),
                      SmartTileVisualPart(
                        channel: SmartTileRenderChannel.actorOcclusion,
                        source: SmartTileVisualSource.animation(
                          animationId: 'wave',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _CountingLayers extends ListBase<MapLayer> {
  _CountingLayers(int count)
    : _layers = [
        for (var i = 0; i < count; i++)
          MapLayer.tile(id: 'layer-$i', name: 'Layer $i'),
      ];

  final List<MapLayer> _layers;
  var reads = 0;

  @override
  int get length => _layers.length;

  @override
  set length(int value) => throw UnsupportedError('Immutable layers');

  @override
  MapLayer operator [](int index) {
    reads++;
    return _layers[index];
  }

  @override
  void operator []=(int index, MapLayer value) =>
      throw UnsupportedError('Immutable layers');
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
