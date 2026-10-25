import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final source in [
    ('ground', SmartTileRenderChannel.ground, true, false),
    ('understory', SmartTileRenderChannel.understory, true, false),
    ('canopy', SmartTileRenderChannel.canopy, true, false),
    ('floating', SmartTileRenderChannel.ground, false, false),
    ('replacement', SmartTileRenderChannel.ground, true, true),
  ]) {
    for (final legacy in [false, true]) {
      for (final unrelated in [0, 1000]) {
        test(
          'hide order show reuses prepared dependencies for ${source.$1} with $unrelated unrelated presets, legacy=$legacy',
          () async {
            final h = await _Harness.create(
              generated: true,
              materialized: true,
              guardCatalog: true,
              unrelatedPresets: unrelated,
              generatedChannel: source.$2,
              generatedFollowTerrain: source.$3,
              generatedReplacesGround: source.$4,
              mixedLayers: true,
              legacyOrder: legacy,
              generatedPivotY: .37123456789,
            );
            addTearDown(h.dispose);
            final project = h.project as _GuardedCatalogProject;
            final catalog = project.smartTileCatalog;
            final reordered = h.map.copyWith(
              layers: h.map.layers.reversed.toList(),
            );
            final oracle = projectSpatialSmartTileModels(
              map: reordered,
              catalog: catalog,
            );
            final expected = {
              for (final instance in oracle.spatialScene!.instances)
                instance.id: instance,
            };
            final oracleGround = SpatialGroundPlan(oracle, project)
                .resolve(0)
                .map(
                  (part) => (
                    part.visual.tilesetId,
                    part.visual.sourceRect,
                    part.height,
                    part.opacity,
                  ),
                )
                .toList();
            final components = Map.of(h.game.modelComponents);
            final generated = components.entries.singleWhere(
              (entry) => entry.key.startsWith('smt_'),
            );
            final initialY = generated.value.component.position.y;
            final initialAnchorY = generated.value.anchor.y;
            final generation = h.game.generation;
            final reads = h.reads;
            generated.value.component.playback.clock = .625;
            project.rejectCatalogReads = true;
            expect(() => catalog.presets.first.id, throwsStateError);
            final hidden = SpatialSceneVisibility(hiddenLayers: ['blue']);
            final initial = h.configuration(h.map, visibility: hidden);
            h.game.configuration = initial;
            h.game.renderedConfiguration = initial;
            h.game.syncVisibility();
            h.game.configuration = h.configuration(
              reordered,
              visibility: hidden,
            );
            expect(await h.game.refresh(), isTrue);
            expect(h.game.modelComponents.keys.toSet(), expected.keys.toSet());
            for (final entry in expected.entries) {
              final actual = h.game.runtimeModelIndex.instance(
                'active',
                entry.key,
              )!;
              expect(
                actual.copyWith(position: entry.value.position),
                entry.value,
              );
              expect(actual.position.x, entry.value.position.x);
              expect(actual.position.z, entry.value.position.z);
              expect(actual.position.y, closeTo(entry.value.position.y, 1e-12));
              expect(
                h.game.modelComponents[entry.key]!.component,
                same(components[entry.key]!.component),
              );
            }
            expect(
              generated.value.component.position.y,
              Float32List.fromList([
                initialY +
                    (expected[generated.key]!.position.y - initialAnchorY),
              ]).single,
            );
            final shown = h.configuration(reordered);
            h.game.configuration = shown;
            h.game.renderedConfiguration = shown;
            h.game.syncVisibility();
            expect(
              h.game.grounds.single.visuals
                  .map(
                    (part) => (
                      part.visual.tilesetId,
                      part.visual.sourceRect,
                      part.height,
                      part.opacity,
                    ),
                  )
                  .toList(),
              oracleGround,
            );
            for (var i = 0; i < 20; i++) {
              h.game.configuration = h.configuration(h.map);
              expect(await h.game.refresh(), isTrue);
              expect(generated.value.component.position.y, initialY);
              h.game.configuration = h.configuration(reordered);
              expect(await h.game.refresh(), isTrue);
            }
            h.game.configuration = h.configuration(h.map);
            expect(await h.game.refresh(), isTrue);
            expect(generated.value.component.position.y, initialY);
            expect(generated.value.component.playback.clock, .625);
            expect(h.game.generation, generation);
            expect(h.reads, reads);
          },
        );
      }
    }
  }

  test('hidden layers preserve canonical paint heights before and after an order change', () async {
    final h = await _Harness.create(generated: true, materialized: true);
    addTearDown(h.dispose);
    final ground = h.game.grounds.single;
    final initialRed = ground.visuals
        .firstWhere((v) => v.visual.sourceRect.x == 0)
        .height;
    final hidden = SpatialSceneVisibility(hiddenLayers: ['blue']);
    final configuration = h.configuration(h.map, visibility: hidden);
    h.game.configuration = configuration;
    h.game.renderedConfiguration = configuration;
    h.game.syncVisibility();
    expect(
      ground.visuals.firstWhere((v) => v.visual.sourceRect.x == 0).height,
      initialRed,
    );
    final reordered = h.map.copyWith(layers: h.map.layers.reversed.toList());
    h.game.configuration = h.configuration(reordered, visibility: hidden);
    await h.game.refresh();
    final canonical = ground.sourcePlan
        .resolve(0)
        .firstWhere((v) => v.visual.sourceRect.x == 0)
        .height;
    expect(
      ground.visuals.firstWhere((v) => v.visual.sourceRect.x == 0).height,
      canonical,
    );
    final generated = h.game.modelComponents.entries.singleWhere(
      (entry) => entry.key.startsWith('smt_'),
    );
    expect(generated.value.component.presentationVisible, isTrue);
    expect(
      generated.value.component.position.y,
      closeTo(
        h.game.runtimeModelIndex.instance('active', generated.key)!.position.y,
        .0000001,
      ),
    );
    final shown = h.configuration(reordered);
    h.game.configuration = shown;
    h.game.renderedConfiguration = shown;
    h.game.syncVisibility();
    expect(
      ground.visuals.firstWhere((v) => v.visual.sourceRect.x == 0).height,
      canonical,
    );
  });

  test('visibility changed during an in-flight refresh applies before the completed frame', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final pending = h.game.refresh();
    expect(h.game.refreshing, isTrue);
    final hidden = h.configuration(
      h.map,
      visibility: SpatialSceneVisibility(
        hiddenContent: [(SpatialSceneContentKind.model, 'lamp')],
      ),
    );
    h.game.configuration = hidden;
    await pending;
    expect(h.game.visibleConfiguration, same(hidden));
    expect(
      h.game.modelComponents['lamp']!.component.presentationVisible,
      isFalse,
    );
  });

  test('first and repeated layer visibility changes reuse prepared catalog dependencies', () async {
    final h = await _Harness.create(guardCatalog: true);
    addTearDown(h.dispose);
    final project = h.project as _GuardedCatalogProject;
    expect(project.catalogReads, greaterThan(0));
    project.rejectCatalogReads = true;
    final reads = h.reads;
    final generations = h.game.generation;
    for (final layers in [
      <String>['red'],
      <String>[],
      <String>['red', 'blue'],
      <String>[],
    ]) {
      final configuration = h.configuration(
        h.map,
        visibility: SpatialSceneVisibility(hiddenLayers: layers),
      );
      h.game.configuration = configuration;
      h.game.renderedConfiguration = configuration;
      h.game.syncVisibility();
      expect(h.game.generation, generations);
      expect(h.reads, reads);
    }
  });

  test('hide and show retain active models, actors, clocks and neighboring identities', () async {
    final h = await _Harness.create(neighborSameId: true, dayLights: true);
    addTearDown(h.dispose);
    final game = h.game;
    final model = game.modelComponents['lamp']!.component;
    final neighbor = game.animationModels[('neighbor', 'lamp')]!;
    final actor = game.actors['hero']!.mesh;
    model.playback.clock = .375;
    final lighting = game.pointLightBindings;
    final generation = game.generation;
    final reads = h.reads;
    final raster = game.grounds.single.components;
    expect(
      (game.context as SpatialRenderContext).lighting.pointLights,
      hasLength(2),
    );
    final hidden = h.configuration(
      h.map,
      visibility: SpatialSceneVisibility(
        hiddenContent: [
          (SpatialSceneContentKind.model, 'lamp'),
          (SpatialSceneContentKind.actor, 'hero'),
        ],
      ),
    );
    game.configuration = hidden;
    game.renderedConfiguration = hidden;
    game.syncVisibility();
    expect(model.presentationVisible, isFalse);
    expect(actor.isVisible(game.camera), isFalse);
    expect(neighbor.presentationVisible, isTrue);
    expect(
      (game.context as SpatialRenderContext).lighting.pointLights,
      hasLength(1),
    );
    expect(model.playback.clock, .375);
    expect(game.modelComponents['lamp']!.component, same(model));
    expect(game.actors['hero']!.mesh, same(actor));
    expect(game.grounds.single.components, same(raster));
    expect(game.generation, generation);
    expect(game.visibilityGroundRebuilds, 0);
    expect(h.reads, reads);
    final shown = h.configuration(h.map);
    game.configuration = shown;
    game.renderedConfiguration = shown;
    game.syncVisibility();
    expect(model.presentationVisible, isTrue);
    expect(actor.isVisible(game.camera), isTrue);
    expect(model.playback.clock, .375);
    expect(game.pointLightBindings, same(lighting));
    expect(game.animationModels[('neighbor', 'lamp')], same(neighbor));
    expect(game.generation, generation);
    expect(h.reads, reads);
  });

  test('hidden source layer removes raster and generated models without scene reload', () async {
    final h = await _Harness.create(generated: true, materialized: true);
    addTearDown(h.dispose);
    final game = h.game;
    final generated = h.map.spatialScene!.instances.singleWhere(
      (instance) => instance.id.startsWith('smt_'),
    );
    final component = game.modelComponents[generated.id]!.component;
    final ground = game.grounds.single;
    final original = ground.visuals.map((v) => v.visual.sourceRect.x).toList();
    final reads = h.reads;
    final generation = game.generation;
    final hidden = h.configuration(
      h.map,
      visibility: SpatialSceneVisibility(hiddenLayers: ['red']),
    );
    game.configuration = hidden;
    game.renderedConfiguration = hidden;
    game.syncVisibility();
    expect(component.presentationVisible, isFalse);
    expect(ground.visuals.map((v) => v.visual.sourceRect.x), everyElement(32));
    expect(game.visibilityGroundRebuilds, 1);
    expect(game.generation, generation);
    expect(h.reads, reads);
    final shown = h.configuration(h.map);
    game.configuration = shown;
    game.renderedConfiguration = shown;
    game.syncVisibility();
    expect(component.presentationVisible, isTrue);
    expect(ground.visuals.map((v) => v.visual.sourceRect.x), original);
    expect(game.modelComponents[generated.id]!.component, same(component));
    expect(game.generation, generation);
    expect(h.reads, reads);
  });

  test(
    'visual order changes replace active raster only and retain scene state',
    () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final game = h.game;
      final model = game.modelComponents['lamp']!.component;
      model.playback.clock = .375;
      final playback = model.playback;
      final actor = game.actors['hero']!.mesh;
      final lights = game.pointLightBindings;
      final lighting = game.authoredLighting;
      final neighbor = game.sceneChunks['neighbor'];
      final generation = game.generation;
      final reads = h.reads;
      final initialRaster = game.grounds.single.components.toList();
      final initialOrder = game.grounds.single.visuals
          .map((v) => v.visual.sourceRect.x)
          .toList();
      final reordered = h.map.copyWith(layers: h.map.layers.reversed.toList());
      game.configuration = h.configuration(reordered);
      expect(await game.refresh(), isTrue);
      expect(game.generation, generation);
      expect(game.visualOrderUpdates, 1);
      expect(game.visualGroundRebuilds, 1);
      expect(
        game.grounds.single.visuals.map((v) => v.visual.sourceRect.x),
        initialOrder.reversed,
      );
      expect(
        game.grounds.single.components.first,
        isNot(same(initialRaster.first)),
      );
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(game.modelComponents['lamp']!.component.playback, same(playback));
      expect(playback.clock, .375);
      expect(game.actors['hero']!.mesh, same(actor));
      expect(game.pointLightBindings, same(lights));
      expect(game.authoredLighting, same(lighting));
      expect(game.sceneChunks['neighbor'], same(neighbor));
      expect(h.reads, reads);
      final ground = game.grounds.single;
      final afterRaster = ground.components;
      final decorReordered = reordered.copyWith(
        placedElements: [
          for (final placed in reordered.placedElements)
            placed.copyWith(visualOrder: 20),
        ],
      );
      game.configuration = h.configuration(decorReordered);
      expect(await game.refresh(), isTrue);
      expect(game.generation, generation);
      expect(game.grounds.single, same(ground));
      expect(game.grounds.single.components, same(afterRaster));
      expect(game.visualOrderUpdates, 2);
      expect(game.visualGroundRebuilds, 1);
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(h.reads, reads);
      expect(game.visibleConfiguration.groundMap, same(decorReordered));
      expect(await game.refresh(), isTrue);
      expect(game.modelComponents['lamp']!.component, same(model));
      expect(game.sceneChunks['neighbor'], same(neighbor));
      expect(h.reads, reads);
    },
  );

  test(
    'locked source layer lets picking pass materialized Smart Tile models',
    () async {
      final h = await _Harness.create(generated: true, materialized: true);
      addTearDown(h.dispose);
      final game = h.game;
      (game.camera as AdaptiveCamera3D).frame(
        Vector3(1, 1, .5),
        pitch: 0,
        yaw: 0,
        distance: 10,
        viewportAspectRatio: 1,
      );
      const pointer = Offset(100, 100);
      final generated = h.map.spatialScene!.instances.singleWhere(
        (instance) => instance.id.startsWith('smt_'),
      );
      expect(game.pickModel(pointer)?.id, generated.id);
      final generation = game.generation;
      final reads = h.reads;
      final component = game.modelComponents[generated.id]!.component;
      final locked = h.configuration(
        h.map,
        canSelectLayer: (id) => id != 'red',
      );
      game.configuration = locked;
      game.renderedConfiguration = locked;
      expect(game.pickContent(pointer)?.id, 'lamp');
      expect(game.pickModel(pointer)?.id, 'lamp');
      final unlocked = h.configuration(h.map);
      game.configuration = unlocked;
      game.renderedConfiguration = unlocked;
      expect(game.pickModel(pointer)?.id, generated.id);
      expect(game.modelComponents[generated.id]!.component, same(component));
      expect(game.generation, generation);
      expect(h.reads, reads);
    },
  );

  test('layer order updates generated paint bias without replacing generated models', () async {
    final h = await _Harness.create(generated: true);
    addTearDown(h.dispose);
    final game = h.game;
    final generated = game.modelComponents.entries
        .where((entry) => entry.key.startsWith('smt_'))
        .single;
    final component = generated.value.component;
    final y = component.position.y;
    final lightBindings = game.pointLightBindings;
    component.playback.clock = .625;
    final generation = game.generation;
    final reads = h.reads;
    final reordered = h.map.copyWith(layers: h.map.layers.reversed.toList());
    game.configuration = h.configuration(reordered);
    expect(await game.refresh(), isTrue);
    expect(game.modelComponents[generated.key]!.component, same(component));
    expect((component.position.y - y).abs(), closeTo(.001, .0000001));
    expect(component.playback.clock, .625);
    expect(game.visualOrderUpdates, 1);
    expect(game.visualGroundRebuilds, 1);
    expect(game.pointLightBindings, same(lightBindings));
    final caster = game.authoredShadowCasters.singleWhere(
      (caster) => caster.id == 'active:${generated.key}',
    );
    expect(
      caster.worldCorners.map((point) => point.y).reduce(math.min),
      closeTo(component.position.y, .0000001),
    );
    expect(
      game.runtimeModelIndex.instance('active', generated.key)!.position.y,
      closeTo(component.position.y, .0000001),
    );
    expect(game.generation, generation);
    expect(h.reads, reads);
  });

  test('a reorder queued during refresh applies the latest order without replacing models', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    final model = h.game.modelComponents['lamp']!.component;
    final generation = h.game.generation;
    final reads = h.reads;
    final refreshing = h.game.refresh();
    expect(h.game.refreshing, isTrue);
    h.game.configuration = h.configuration(
      h.map.copyWith(layers: h.map.layers.reversed.toList()),
    );
    final first = h.game.refresh();
    final latest = h.map.copyWith(
      placedElements: [
        for (final placed in h.map.placedElements)
          placed.copyWith(visualOrder: 5),
      ],
    );
    h.game.configuration = h.configuration(latest);
    final last = h.game.refresh();
    await refreshing;
    expect(await first, isTrue);
    expect(await last, isTrue);
    expect(h.game.visibleConfiguration.groundMap, same(latest));
    expect(h.game.generation, generation + 1);
    expect(h.game.modelComponents['lamp']!.component, same(model));
    expect(h.reads, reads);
  });
}

final class _Harness {
  late MapData map;
  late ProjectManifest project;
  late SpatialSceneGame game;
  final controller = SpatialSceneController();
  var reads = 0;
  late Map<String, SpatialActorVisual> frames;
  late List<SpatialSceneNeighbor> neighbors;
  final png = Uint8List.fromList(
    img.encodePng(img.Image(width: 64, height: 32)),
  );

  static Future<_Harness> create({
    bool generated = false,
    bool materialized = false,
    bool neighborSameId = false,
    bool dayLights = false,
    bool guardCatalog = false,
    int unrelatedPresets = 0,
    SmartTileRenderChannel generatedChannel = SmartTileRenderChannel.ground,
    bool generatedFollowTerrain = true,
    bool generatedReplacesGround = false,
    bool mixedLayers = false,
    bool legacyOrder = false,
    double generatedPivotY = 0,
  }) async {
    _UnusedBackend();
    final h = _Harness();
    final model = ProjectModel3dEntry(
      id: 'lamp',
      name: 'Lamp',
      pivot: Model3dVector3(x: 0, y: generatedPivotY, z: 0),
      sourceAssetId: 'lamp',
      castsShadowsByDefault: generated,
      relativePath: 'assets/models3d/lamp.glb',
      light: Model3dPointLight(
        localPosition: Model3dVector3(x: 0, y: 1, z: 0),
        nightOnly: !dayLights,
      ),
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    h.project = ProjectManifest(
      name: 'Order',
      maps: const [],
      tilesets: const [],
      models3d: [model],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const [
          ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tiles',
            columns: 2,
            rows: 1,
          ),
        ],
        materials: [
          for (final id in ['red', 'blue'])
            ProjectSmartTileMaterial(id: id, name: id, connectionGroupId: id),
        ],
        presets: [
          for (final entry in ['red', 'blue'].indexed)
            ProjectSmartTilePreset(
              id: entry.$2,
              name: entry.$2,
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              templateHint: SmartTileTemplateHint.simple,
              coveragePolicy: SmartTileCoveragePolicy.sparse,
              coverageProfile: const SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: const SmartTileTransformPolicy(),
              defaultMaterialId: entry.$2,
              allowedMaterialIds: [entry.$2],
              rules: [
                SmartTileRule(
                  id: entry.$2,
                  centerMatch: SmartTileSlotMatch.material(entry.$2),
                  candidates: [
                    SmartTileCandidate(
                      id: 'fill',
                      parts: [
                        if (generated && entry.$1 == 0)
                          SmartTileVisualPart(
                            channel: generatedChannel,
                            source: SmartTileVisualSource.model3d(
                              modelId: 'lamp',
                              followTerrain: generatedFollowTerrain,
                              replacesGround: generatedReplacesGround,
                            ),
                          ),
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas',
                              column: entry.$1,
                              row: 0,
                            ),
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
    );
    if (guardCatalog)
      h.project = _GuardedCatalogProject(
        h.project,
        unrelatedPresets: unrelatedPresets,
      );
    h.map = MapData(
      id: 'active',
      name: 'Active',
      properties: legacyOrder
          ? const {'tileLayerOrder': 'bottom_to_top'}
          : const {},
      size: const GridSize(width: 1, height: 1),
      spatialScene: MapSpatialScene(
        width: 1,
        depth: 1,
        instances: [
          SpatialModelInstance(
            id: 'lamp',
            modelId: 'lamp',
            position: Model3dVector3.zero,
          ),
        ],
      ),
      layers: [
        for (final id in ['red', 'blue'])
          SmartTileLayer(
            id: id,
            name: id,
            presetId: id,
            usage: SmartTileUsage.terrain,
            materialPalette: ['', id],
            field: const SmartTileField.cell(semanticCells: [1]),
          ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'decor',
          layerId: 'red',
          elementId: 'unused',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    if (mixedLayers) {
      final smart = h.map.layers.whereType<SmartTileLayer>().first;
      h.map = h.map.copyWith(
        layers: [
          h.map.layers.first,
          const MapLayer.tile(id: 'flat', name: 'Flat'),
          smart.copyWith(id: 'authored-hidden', isVisible: false),
          smart.copyWith(id: 'authored-transparent', opacity: 0),
          h.map.layers.last,
        ],
      );
    }
    if (materialized) {
      h.map = h.map.copyWith(
        spatialScene: h.map.spatialScene!.copyWith(
          instances: [
            h.map.spatialScene!.instances.single.copyWith(
              position: Model3dVector3(x: .5, y: 0, z: 0),
            ),
          ],
        ),
      );
      h.map = projectSpatialSmartTileModels(
        map: h.map,
        catalog: h.project.smartTileCatalog,
      );
    }
    h.neighbors = [
      SpatialSceneNeighbor(
        map: MapData(
          id: 'neighbor',
          name: 'Neighbor',
          size: const GridSize(width: 1, height: 1),
          spatialScene: MapSpatialScene(
            width: 1,
            depth: 1,
            instances: [
              SpatialModelInstance(
                id: neighborSameId ? 'lamp' : 'lamp-next',
                modelId: 'lamp',
                position: Model3dVector3.zero,
              ),
            ],
          ),
        ),
        offset: const Offset(1, 0),
        loadGroundImage: h.loadGround,
      ),
    ];
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 1, 1),
      ui.Paint()..color = const Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    final texture = await SpatialActorTexture.fromImage(image);
    image.dispose();
    picture.dispose();
    h.frames = {
      'hero': SpatialActorVisual(
        x: .5,
        y: 0,
        z: .5,
        texture: texture,
        frame: const ui.Rect.fromLTWH(0, 0, 1, 1),
      ),
    };
    if (materialized) h.frames = const {};
    h.game =
        SpatialSceneGame(
            h.configuration(h.map),
            onPreviewStatus: (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    await h.game.refresh();
    return h;
  }

  Future<Uint8List> loadModel(String _) async {
    reads++;
    return _triangle();
  }

  Future<Uint8List> loadGround(String _) async {
    reads++;
    return png;
  }

  Map<String, SpatialActorVisual> actorFrames(double _) => frames;
  SpatialSceneView configuration(
    MapData value, {
    bool Function(String)? canSelectLayer,
    SpatialSceneVisibility? visibility,
  }) => SpatialSceneView(
    visibility: visibility,
    canSelectLayer: canSelectLayer,
    scene: value.spatialScene!,
    groundMap: value,
    groundProject: project,
    models: project.models3d,
    loadModel: loadModel,
    loadGroundImage: loadGround,
    actorFrames: actorFrames,
    neighbors: neighbors,
    controller: controller,
    onCell: (_, _) {},
    background: const Color(0xff000000),
    ground: const Color(0xff224422),
    edge: const Color(0xff111111),
    errorBuilder: (_, _) => const SizedBox(),
  );
  void dispose() {
    game.onRemove();
    controller.dispose();
  }
}

final class _GuardedCatalogProject implements ProjectManifest {
  _GuardedCatalogProject(this.source, {int unrelatedPresets = 0}) {
    final catalog = source.smartTileCatalog;
    _catalog = ProjectSmartTileCatalog(
      atlases: catalog.atlases,
      materials: catalog.materials,
      animations: catalog.animations,
      patterns: catalog.patterns,
      categories: catalog.categories,
      presets: [
        for (final preset in catalog.presets) _GuardedPreset(preset, this),
        for (var i = 0; i < unrelatedPresets; i++)
          _GuardedPreset(
            catalog.presets.first.copyWith(id: 'unrelated-$i'),
            this,
          ),
      ],
    );
  }
  final ProjectManifest source;
  late final ProjectSmartTileCatalog _catalog;
  var catalogReads = 0;
  var rejectCatalogReads = false;
  @override
  ProjectSmartTileCatalog get smartTileCatalog {
    if (rejectCatalogReads)
      throw StateError('Visibility accessed the project catalog.');
    catalogReads++;
    return _catalog;
  }

  @override
  get settings => source.settings;
  @override
  get models3d => source.models3d;
  @override
  get tilesets => source.tilesets;
  @override
  get borderCatalog => source.borderCatalog;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _GuardedPreset implements ProjectSmartTilePreset {
  _GuardedPreset(this.source, this.project);
  final ProjectSmartTilePreset source;
  final _GuardedCatalogProject project;
  @override
  String get id {
    if (project.rejectCatalogReads)
      throw StateError('Local mutation traversed the prepared catalog.');
    return source.id;
  }

  @override
  get name => source.name;
  @override
  get categoryId => source.categoryId;
  @override
  get usage => source.usage;
  @override
  get topology => source.topology;
  @override
  get templateHint => source.templateHint;
  @override
  get boundaryPolicy => source.boundaryPolicy;
  @override
  get status => source.status;
  @override
  get coveragePolicy => source.coveragePolicy;
  @override
  get coverageProfile => source.coverageProfile;
  @override
  get transformPolicy => source.transformPolicy;
  @override
  get defaultMaterialId => source.defaultMaterialId;
  @override
  get allowedMaterialIds => source.allowedMaterialIds;
  @override
  get rules => source.rules;
  @override
  get tags => source.tags;
  @override
  get sortOrder => source.sortOrder;
  @override
  get seedSalt => source.seedSalt;
  @override
  get fallbackRuleId => source.fallbackRuleId;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
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
