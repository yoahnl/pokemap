import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/src/parser/gltf/animation_interpolation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_actor_occlusion.dart';
import 'package:map_render_3d/src/spatial_actor_visual.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/model_playback.dart';
import 'package:map_render_3d/src/spatial_game_surface.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_lighting_preview.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';
import 'package:map_render_3d/src/spatial_scene_decoration.dart';
import 'package:map_render_3d/src/spatial_weather_material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_UnusedBackend.new);

  for (final decoration in [false, true]) {
    testWidgets(
      'covered model pause and resume match visible clocks decoration=$decoration',
      (tester) async {
        final visible = _ModelPauseFixture();
        final hidden = _ModelPauseFixture();
        for (final fixture in [visible, hidden]) {
          addTearDown(fixture.controller.dispose);
          addTearDown(fixture.preview.dispose);
          fixture.game.pauseEngine();
          final lease = await fixture.game.resourceBudget.acquire(
            residentBytes: 1,
          );
          lease.commit();
          fixture.game.modelReservations['lamp'] = lease;
        }
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Offstage(
              child: Stack(
                children: [
                  for (final fixture in [visible, hidden])
                    SpatialGameSurface(
                      game: fixture.game,
                      loadingBuilder: (_) => const SizedBox(),
                      errorBuilder: (_, error) => throw error,
                    ),
                ],
              ),
            ),
          ),
        );
        await tester.runAsync(() async {
          for (final fixture in [visible, hidden]) {
            for (
              var frame = 0;
              frame < 100 && !fixture.game.isLoaded;
              frame++
            ) {
              fixture.game.update(0);
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            expect(fixture.game.isLoaded, isTrue);
            await fixture.game.toBeLoaded();
          }
        });
        await tester.pump();
        await tester.runAsync(() async {
          for (final fixture in [visible, hidden]) {
            await fixture.game.ready();
          }
        });
        for (final fixture in [visible, hidden]) {
          expect(
            fixture.game.modelComponents.keys,
            contains('lamp'),
            reason:
                'ready=${fixture.game.sceneReady} refreshing=${fixture.game.refreshing} rendered=${fixture.game.renderedConfiguration != null} failures=${fixture.failures}',
          );
          final component = fixture.game.modelComponents['lamp']!.component;
          expect(component.isMounted, isTrue);
          fixture.deltas.clear();
          if (decoration) {
            fixture.game.animationModels.clear();
            fixture.game.decorationAnimationModels[('decor', 'lamp')] =
                component;
          }
        }
        final visibleComponent =
            visible.game.modelComponents['lamp']!.component;
        final hiddenComponent = hidden.game.modelComponents['lamp']!.component;
        void advance() {
          visible.game.update(.02);
          hidden.game.update(.02);
          expect(
            hiddenComponent.playback.clock,
            closeTo(visibleComponent.playback.clock, 1e-9),
          );
          expect(
            hiddenComponent.playback.paused,
            visibleComponent.playback.paused,
          );
          expect(hidden.deltas, visible.deltas);
        }

        advance();
        advance();
        expect(visibleComponent.playback.clock, closeTo(.04, 1e-9));
        hidden.covered = true;
        visible.paused = hidden.paused = true;
        for (var frame = 0; frame < 4; frame++) {
          advance();
        }
        expect(hiddenComponent.playback.paused, isTrue);
        expect(hiddenComponent.playback.clock, closeTo(.06, 1e-9));
        visible.paused = hidden.paused = false;
        visible.preview.togglePause('lamp');
        hidden.preview.togglePause('lamp');
        advance();
        expect(hiddenComponent.playback.paused, isTrue);
        visible.preview.togglePause('lamp');
        hidden.preview.togglePause('lamp');
        advance();
        if (!decoration) {
          final ambientClock = hiddenComponent.playback.clock;
          visible.state = hidden.state = SpatialModelRuntimeState(
            modelId: 'lamp',
            animationIndex: 0,
            normalizedTime: .7,
            blocksMovement: true,
          );
          advance();
          expect(hiddenComponent.playback.paused, isTrue);
          expect(hiddenComponent.playback.clock, .7);
          visible.state = hidden.state = visible.state!.copyWith(
            normalizedTime: .9,
          );
          advance();
          expect(hiddenComponent.playback.clock, .9);
          visible.state = hidden.state = null;
          advance();
          expect(
            hiddenComponent.playback.clock,
            closeTo(ambientClock + .02, 1e-9),
          );
        }
        advance();
        hidden.covered = false;
        visible.paused = hidden.paused = true;
        advance();
        final pausedClock = hiddenComponent.playback.clock;
        advance();
        expect(hiddenComponent.playback.clock, pausedClock);
        visible.paused = hidden.paused = false;
        advance();
        expect(hiddenComponent.playback.clock, pausedClock);
        advance();
        expect(
          hiddenComponent.playback.clock,
          closeTo(pausedClock + .02, 1e-9),
        );
        expect(hidden.deltas, everyElement(.02));
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test('covered rebuilds retain lighting until preparation resumes', () async {
    final f = _Fixture(1);
    var covered = false;
    final game = f.game(
      (_) async => f.png,
      renderPreparationPaused: () => covered,
    );
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    final context = game.context as SpatialRenderContext;
    final lighting = context.lighting;
    final replacement = SpatialLightingProfile.stylized(ambientStrength: .3);
    game.previewLighting = replacement;
    covered = true;
    game.syncLighting();
    expect(context.lighting, same(lighting));
    covered = false;
    game.syncLighting();
    expect(context.lighting, same(replacement));
  });

  test(
    'covered refresh preserves the original frame and clock guards',
    () async {
      final f = _Fixture(4);
      var frames = 0;
      var elapsed = 0.0;
      final base = f.game(
        (_) async => f.png,
        renderPreparationPaused: () => true,
        actorFrames: (dt) {
          frames++;
          elapsed += dt;
          return {};
        },
        presentationElapsedSeconds: () => elapsed,
      );
      final game = _CountingPreparationGame(base.configuration)
        ..onGameResize(Vector2(200, 200))
        ..sceneReady = true;
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      final initialFrames = frames;
      final preparation = game.preparationCalls;
      final modelSyncs = game.modelSyncCalls;
      game.refreshing = true;
      game.update(.02);
      expect(frames, initialFrames + 1);
      expect(game.groundElapsed, 0);
      expect(game.atmosphereElapsed, .02);
      expect(game.preparationCalls, preparation);
      expect(game.modelSyncCalls, modelSyncs + 1);
      game.renderedConfiguration = null;
      game.update(.02);
      expect(frames, initialFrames + 1);
      expect(game.atmosphereElapsed, .02);
    },
  );

  test(
    'covered preparation keeps clocks live and resumes the retained scene',
    () async {
      final f = _Fixture(20, occlusion: true);
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(const Color(0xffffffff), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(1, 1);
      final texture = await SpatialActorTexture.fromImage(image);
      image.dispose();
      picture.dispose();
      var covered = false;
      var paused = false;
      var elapsed = 0.0;
      var extraActor = false;
      final deltas = <double>[];
      final reads = <String>[];
      final fixtureGame = f.game(
        (id) async {
          reads.add(id);
          return f.png;
        },
        sourceMap: f.map.copyWith(
          spatialScene: MapSpatialScene(
            width: 1,
            depth: 1,
            dayNightCycle: SpatialDayNightCycle(
              durationSeconds: 1440,
              startMinuteOfDay: 0,
            ),
          ),
        ),
        renderPreparationPaused: () => covered,
        presentationPaused: () => paused,
        presentationElapsedSeconds: () => elapsed,
        actorFrames: (dt) {
          deltas.add(dt);
          if (!paused) elapsed += dt;
          SpatialActorVisual actor() => SpatialActorVisual(
            x: elapsed,
            y: 0,
            z: 0,
            texture: texture,
            frame: const Rect.fromLTWH(0, 0, 1, 1),
          );
          return {'hero': actor(), if (extraActor) 'newcomer': actor()};
        },
      );
      final game = _CountingPreparationGame(fixtureGame.configuration)
        ..onGameResize(Vector2(200, 200))
        ..sceneReady = true;
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future.wait(List.of(game.groundTextureCache.values));
      game.update(0);
      game.configuration.controller.sceneChanges.addListener(game.syncCamera);
      final ground = game.grounds.single;
      final components = List.of(ground.components);
      final actorMesh = game.actors['hero']!.mesh;
      final leases = Map.of(game.groundReservations);
      final cached = Map.of(game.groundTextureCache);
      final generation = game.generation;
      final work = _groundWork(ground.plan);
      final preparation = game.preparationCalls;
    final modelSyncs = game.modelSyncCalls;
      final haloAllocations = game.presentationEffects.allocations;
      final resident = game.resourceBudget.residentBytes;
      final cameraPosition = game.camera.position.clone();
      final cameraTarget = game.camera.target.clone();
      final initialReads = List.of(reads);
      deltas.clear();
      covered = true;
      extraActor = true;
      game.configuration.controller.panBy(3, 4);
      for (var frame = 0; frame < 8; frame++) {
        game.update(.02);
      }
      await Future<void>.delayed(Duration.zero);
      expect(deltas, List.filled(8, .02));
      expect(elapsed, closeTo(.16, .000001));
      expect(game.groundElapsed, closeTo(.16, .000001));
      expect(game.atmosphereElapsed, closeTo(.16, .000001));
      expect(
        game.configuration.controller.dayNightMinuteOfDay,
        closeTo(.16, .000001),
      );
      expect(game.preparationCalls, preparation);
    expect(game.modelSyncCalls, modelSyncs + 8);
      expect(game.camera.position, cameraPosition);
      expect(game.camera.target, cameraTarget);
      expect(_groundWork(ground.plan), work);
      expect(reads, initialReads);
      expect(game.groundReservations, leases);
      expect(game.groundTextureCache, cached);
      expect(game.resourceBudget.residentBytes, resident);
      expect(game.resourceBudget.pendingDecodes, 0);
      expect(game.presentationEffects.allocations, haloAllocations);
      expect(ground.components, orderedEquals(components));
      expect(game.actors.keys, ['hero']);
      expect(game.actors['hero']!.mesh, same(actorMesh));
      expect(actorMesh.position.x, 0);
      paused = true;
      game.update(.02);
      expect(elapsed, closeTo(.16, .000001));
      expect(game.atmosphereElapsed, closeTo(.16, .000001));
      expect(game.groundElapsed, closeTo(.18, .000001));
      expect(game.preparationCalls, preparation);
      paused = false;
      covered = false;
      deltas.clear();
      game.update(.02);
      expect(deltas, [.02]);
      expect(elapsed, closeTo(.18, .000001));
      expect(game.actors['hero']!.mesh, same(actorMesh));
      expect(actorMesh.position.x, closeTo(.18, .000001));
      expect(game.actors, contains('newcomer'));
      expect(game.preparationCalls, greaterThan(preparation));
      await Future.wait(List.of(game.groundTextureCache.values));
      game.update(0);
      expect(ground.visuals.single.visual.tilesetId, 'page-6');
      expect(game.generation, generation);
      expect(game.closed, isFalse);
      for (final entry in leases.entries) {
        expect(game.groundReservations[entry.key], same(entry.value));
      }
    },
  );

  test('invariant selected images skip 300 arbitrary animation clocks', () {
    final f = _Fixture(4, singleImage: true);
    final plan = SpatialGroundPlan(f.map, f.project);
    var clockCalls = 0;
    int clock(String layer, int x, int y, int time) {
      clockCalls++;
      return time * 7 + 51;
    }

    final first = plan.imageIdsAt(0, animationElapsedMsForCell: clock);
    expect(first, {'page-0'});
    clockCalls = 0;
    final initialWork = _groundWork(plan);
    var retainedIdentity = true;
    for (var query = 0; query < 300; query++) {
      final time = switch (query % 3) {
        0 => query * 29,
        1 => -query * 71,
        _ => 100000 - query * 113,
      };
      retainedIdentity =
          identical(
            plan.imageIdsAt(time, animationElapsedMsForCell: clock),
            first,
          ) &&
          retainedIdentity;
    }
    expect(clockCalls, 0);
    expect(initialWork, (
      resolveBatchCalls: 0,
      animationVariantVisits: 0,
      compiledAnimationVariants: 4,
      selectedCellVisits: 1,
    ));
    expect(_groundWork(plan), initialWork);
    expect(retainedIdentity, isTrue);
    expect(() => first.add('other'), throwsUnsupportedError);
  });

  for (final cells in [1, 256]) {
    for (final frames in [4, 97]) {
      test(
        'cold proof compiles $frames variants per $cells selected cells once',
        () {
          final f = _Fixture(frames, singleImage: true);
          final layer = (f.map.layers.single as SmartTileLayer).copyWith(
            field: SmartTileField.cell(semanticCells: List.filled(cells, 1)),
          );
          final map = f.map.copyWith(
            size: GridSize(width: cells, height: 1),
            layers: [layer],
            spatialScene: MapSpatialScene(width: cells, depth: 1),
          );
          final plan = SpatialGroundPlan(map, f.project);
          expect(_groundWork(plan).compiledAnimationVariants, 0);
          final images = plan.imageIdsAt(0);
          expect(images, {'page-0'});
          final cold = _groundWork(plan);
          expect(cold, (
            resolveBatchCalls: 0,
            animationVariantVisits: 0,
            compiledAnimationVariants: cells * frames,
            selectedCellVisits: cells,
          ));
          for (var frame = 0; frame < 300; frame++) {
            expect(plan.imageIdsAt(frame * 17), same(images));
          }
          expect(_groundWork(plan), cold);
        },
      );
    }
  }

  test('invariant image queries keep on-enter rendering clocks live', () {
    final f = _Fixture(4, singleImage: true);
    final layer = (f.map.layers.single as SmartTileLayer).copyWith(
      animationActivation: SmartTileAnimationActivation.onEnter,
    );
    final plan = SpatialGroundPlan(f.map.copyWith(layers: [layer]), f.project);
    final images = plan.imageIdsAt(0);
    var cellTime = 0;
    var clockCalls = 0;
    int clock(String layer, int x, int y, int time) {
      clockCalls++;
      return cellTime;
    }

    for (final sample in [(0, 0), (66, 64), (-10, 0), (33, 32)]) {
      cellTime = sample.$1;
      expect(
        plan.imageIdsAt(1000, animationElapsedMsForCell: clock),
        same(images),
      );
      expect(
        plan
            .resolve(1000, animationElapsedMsForCell: clock)
            .single
            .visual
            .sourceRect
            .x,
        sample.$2,
      );
    }
    expect(clockCalls, 4);
    expect(_groundWork(plan).resolveBatchCalls, 4);
    expect(_groundWork(plan).animationVariantVisits, 4);
  });

  test(
    'multi-atlas current and prefetch sets stay exact with arbitrary clocks',
    () {
      final f = _Fixture(4);
      final plan = SpatialGroundPlan(f.map, f.project);
      var calls = 0;
      var cellTime = 66;
      int clock(String layer, int x, int y, int time) {
        calls++;
        return cellTime;
      }

      expect(plan.imageIdsAt(0, animationElapsedMsForCell: clock), {'page-2'});
      cellTime = 99;
      expect(
        plan.imageIdsAt(
          plan.animationLookaheadMs,
          animationElapsedMsForCell: clock,
        ),
        {'page-3'},
      );
      cellTime = -100;
      expect(plan.imageIdsAt(-100, animationElapsedMsForCell: clock), {
        'page-0',
      });
      expect(calls, 3);
      expect(_groundWork(plan).resolveBatchCalls, 3);
      expect(_groundWork(plan).animationVariantVisits, 3);
    },
  );

  test('invariant and dynamic windows track a mutable cliff image', () {
    for (final singleImage in [false, true]) {
      final f = _Fixture(4, singleImage: singleImage);
      final plan = SpatialGroundPlan(f.map, f.project);
      final original = plan.imageIdsAt(0);
      const rect = SmartTileSourceRect(x: 0, y: 0, width: 32, height: 32);
      plan.cliff = (tilesetId: 'cliff-a', sourceRect: rect);
      final first = plan.imageIdsAt(0);
      expect(first, {'page-0', 'cliff-a'});
      plan.cliff = (tilesetId: 'cliff-b', sourceRect: rect);
      expect(plan.imageIdsAt(0), {'page-0', 'cliff-b'});
      plan.cliff = null;
      expect(plan.imageIdsAt(0), {'page-0'});
      expect(original, {'page-0'});
      expect(first, {'page-0', 'cliff-a'});
    }
  });

  test(
    'prepared visibility order and replaced sources own exact image sets',
    () {
      final f = _Fixture(4, singleImage: true);
      final source = f.map.layers.single as SmartTileLayer;
      final other = source.copyWith(id: 'other', presetId: 'other');
      final catalog = f.project.smartTileCatalog;
      final project = f.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: catalog.materials,
          animations: catalog.animations,
          atlases: [
            for (final atlas in catalog.atlases)
              atlas.copyWith(
                tilesetId: atlas.id == 'atlas-0' ? 'page-0' : 'page-1',
              ),
          ],
          presets: [
            catalog.presets.single.copyWith(
              rules: [
                catalog.presets.single.rules.single.copyWith(
                  candidates: [
                    const SmartTileCandidate(
                      id: 'fixed',
                      parts: [
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas-0',
                              column: 0,
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
            catalog.presets.single.copyWith(
              id: 'other',
              rules: [
                catalog.presets.single.rules.single.copyWith(
                  candidates: [
                    const SmartTileCandidate(
                      id: 'fixed',
                      parts: [
                        SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas-1',
                              column: 0,
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
      final map = f.map.copyWith(layers: [source, other]);
      final plan = SpatialGroundPlan(map, project);
      final all = plan.imageIdsAt(0);
      expect(all, {'page-0', 'page-1'});
      final filtered = plan.withLayerVisibility((id) => id == 'water');
      final visible = filtered.imageIdsAt(0);
      expect(visible, {'page-0'});
      expect(plan.imageIdsAt(100), same(all));
      expect(filtered.imageIdsAt(100), same(visible));
      expect(plan.withLayerVisibility((_) => false).imageIdsAt(0), isEmpty);
      expect(
        plan.reordered(map.copyWith(layers: [other, source])).imageIdsAt(0),
        all,
      );
      final replaced = SpatialGroundPlan(
        map,
        project.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: project.smartTileCatalog.materials,
            animations: project.smartTileCatalog.animations,
            presets: project.smartTileCatalog.presets,
            atlases: [
              for (final atlas in project.smartTileCatalog.atlases)
                atlas.copyWith(tilesetId: 'replacement'),
            ],
          ),
        ),
      );
      expect(replaced.imageIdsAt(0), {'replacement'});
      expect(all, {'page-0', 'page-1'});
    },
  );

  test('flat border plans contribute their selected invariant images', () {
    final f = _Fixture(4, singleImage: true);
    final plan = SpatialGroundPlan(
      f.map.copyWith(layers: const []),
      f.project,
      additionalBorders: SpatialGroundBorderInputs(
        surfaces: [
          SpatialBorderGroundSurface(
            layerId: 'border',
            sourceSmartTilePresetId: 'water',
            materialId: 'water',
            height: 1,
            opacity: 1,
            footprints: [
              BorderGroundFootprint(
                points: [
                  BorderGroundPoint(x: 0, z: 0),
                  BorderGroundPoint(x: 1, z: 0),
                  BorderGroundPoint(x: 1, z: 1),
                  BorderGroundPoint(x: 0, z: 1),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    final images = plan.imageIdsAt(0);
    expect(images, {'page-0'});
    expect(plan.imageIdsAt(50), same(images));
    expect(_groundWork(plan).resolveBatchCalls, 0);
    expect(plan.resolve(66).single.visual.sourceRect.x, 64);
    expect(plan.withLayerVisibility((_) => false).imageIdsAt(0), isEmpty);
  });

  for (final size in [256, 65536]) {
    test(
      '300 rendered image queries do not rescan $size displayed visuals',
      () async {
        final f = _Fixture(2, animated: false);
        final game = f.game((_) async => f.png);
        addTearDown(game.onRemove);
        expect(await game.refresh(), isTrue);
        final ground = game.grounds.single;
        final displayed = ground.visuals;
        final counted = _CountingVisuals(
          List.generate(size, (index) => displayed[index % displayed.length]),
        );
        ground.visuals = counted;
        final images = ground.renderedImageIds;
        expect(images, {'page-0', 'page-1'});
        expect(counted.reads, size);
        counted.reads = 0;
        Set<String>? last;
        for (var frame = 0; frame < 300; frame++) {
          last = ground.renderedImageIds;
        }
        expect(counted.reads, 0);
        expect(last, same(images));
      },
    );
  }

  test('displayed source replacement refreshes image references', () async {
    final f = _Fixture(2, animated: false);
    final game = f.game((_) async => f.png);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    final ground = game.grounds.single;
    final displayed = ground.visuals;
    final first = _CountingVisuals([displayed.first]);
    final second = _CountingVisuals([displayed.last]);
    ground.visuals = first;
    final before = ground.renderedImageIds;
    expect(before, {'page-0'});
    first.reads = 0;
    ground.visuals = second;
    final after = ground.renderedImageIds;
    expect(after, {'page-1'});
    expect(after, isNot(same(before)));
    expect(second.reads, 1);
    expect(first.reads, 0);
    second.reads = 0;
    expect(ground.renderedImageIds, same(after));
    expect(second.reads, 0);
    ground.visuals = const [];
    expect(ground.renderedImageIds, isEmpty);
    expect(after, {'page-1'});
  });

  test('cliff and occlusion revisions never rescan displayed cells', () async {
    final f = _Fixture(2, animated: false);
    final game = f.game((_) async => f.png);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    final ground = game.grounds.single;
    final counted = _CountingVisuals(ground.visuals);
    ground.visuals = counted;
    final before = ground.renderedImageIds;
    counted.reads = 0;
    ground.plan.cliff = (
      tilesetId: 'cliff',
      sourceRect: const SmartTileSourceRect(x: 0, y: 0, width: 32, height: 32),
    );
    final withCliff = ground.renderedImageIds;
    expect(withCliff, {'page-0', 'page-1', 'cliff'});
    expect(before, {'page-0', 'page-1'});
    ground.renderedOcclusionImageIds = {'canopy'};
    final withOcclusion = ground.renderedImageIds;
    expect(withOcclusion, {'page-0', 'page-1', 'cliff', 'canopy'});
    ground.renderedOcclusionImageIds = {'canopy'};
    expect(ground.renderedImageIds, same(withOcclusion));
    ground.renderedOcclusionImageIds
      ..clear()
      ..add('other-canopy');
    final changedOcclusion = ground.renderedImageIds;
    expect(changedOcclusion, {'page-0', 'page-1', 'cliff', 'other-canopy'});
    expect(withOcclusion, {'page-0', 'page-1', 'cliff', 'canopy'});
    ground.plan.cliff = null;
    ground.renderedOcclusionImageIds = {};
    expect(ground.renderedImageIds, {'page-0', 'page-1'});
    expect(counted.reads, 0);
    expect(() => withCliff.add('unexpected'), throwsUnsupportedError);
    ground.visuals = const [];
    expect(ground.renderedImageIds, isEmpty);
  });

  test('queued texture admission retains displayed image references', () async {
    final f = _Fixture(6);
    final game = f.game((_) async => f.png);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    await game.groundTextureCache['page-1'];
    final displayed = game.grounds.single.renderedImageIds;
    final displayedTexture = game.groundTextureCache['page-0'];
    final displayedLease = game.groundReservations['page-0'];
    final gates = [
      await game.resourceBudget.acquire(),
      await game.resourceBudget.acquire(),
    ];
    for (final gate in gates) {
      addTearDown(gate.release);
    }
    game.update(.099);
    expect(game.resourceBudget.pendingDecodes, greaterThan(0));
    expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-0');
    expect(game.grounds.single.renderedImageIds, same(displayed));
    expect(game.groundTextureCache['page-0'], same(displayedTexture));
    expect(game.groundReservations['page-0'], same(displayedLease));
    for (final gate in gates) {
      gate.release();
    }
    await game.groundTextureCache['page-3'];
    await game.groundTextureCache['page-4'];
    game.update(0);
    expect(game.grounds.single.renderedImageIds, {'page-3'});
    expect(game.groundTextureCache['page-0'], same(displayedTexture));
    expect(game.groundReservations['page-0'], same(displayedLease));
    expect(displayed, {'page-0'});
  });

  test(
    'a delayed occlusion atlas retains the displayed occlusion lease',
    () async {
      final f = _Fixture(4, occlusion: true);
      final replacement = _Fixture(4, occlusion: true, occlusionPage: 3);
      final pending = Completer<Uint8List>();
      final game = f.game(
        (id) => id == 'page-3' ? pending.future : Future.value(f.png),
      );
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await game.groundTextureCache['page-1'];
      game.update(0);
      final ground = game.grounds.single;
      final previous = ground.renderedImageIds;
      expect(previous, {'page-0', 'page-2'});
      final lease = game.groundReservations['page-2'];
      ground.occlusionPlan = SpatialActorOcclusionPlan(
        replacement.map,
        replacement.project,
      );
      game.update(0);
      expect(ground.renderedImageIds, same(previous));
      expect(ground.renderedOcclusionImageIds, {'page-2'});
      expect(game.groundReservations['page-2'], same(lease));
      pending.complete(f.png);
      await game.groundTextureCache['page-3'];
      game.update(0);
      expect(ground.renderedImageIds, {'page-0', 'page-3'});
      expect(ground.renderedOcclusionImageIds, {'page-3'});
      expect(game.groundTextureCache, contains('page-2'));
      expect(game.groundReservations['page-2'], same(lease));
    },
  );

  test(
    'frame purges retain a prepared destination until cancellation',
    () async {
      final f = _Fixture(4, animated: false);
      final game = f.game((_) async => f.png);
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      final residentBytes = game.resourceBudget.residentBytes;
      var current = true;
      expect(
        await game.prepareDestination(
          SpatialScenePreparation(
            map: f.map.copyWith(
              id: 'destination',
              layers: const [],
              spatialScene: MapSpatialScene(
                width: 1,
                depth: 1,
                cliffFrame: const SmartTileFrameRef(
                  atlasId: 'atlas-3',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
            project: f.project,
            loadModel: (_) async => throw StateError('No models'),
            loadGroundImage: (_) async => f.png,
            resourceIdentity: 'fixture',
            resourceBudget: game.resourceBudget,
            isCurrent: () => current,
          ),
        ),
        isTrue,
      );
      final texture = game.groundTextureCache['page-3'];
      final lease = game.groundReservations['page-3'];
      expect(texture, isNotNull);
      expect(lease, isNotNull);
      for (var frame = 0; frame < 300; frame++) {
        game.update(0);
      }
      expect(game.groundTextureCache['page-3'], same(texture));
      expect(game.groundReservations['page-3'], same(lease));
      current = false;
      game.update(0);
      expect(game.groundTextureCache, isNot(contains('page-3')));
      expect(game.groundReservations, isNot(contains('page-3')));
      expect(game.resourceBudget.residentBytes, residentBytes);
    },
  );
  test(
    'ten thousand future pages are inventoried but never eagerly loaded',
    () async {
      final f = _Fixture(10000);
      final reads = <String>[];
      final game = f.game((id) async {
        reads.add(id);
        if (id != 'page-0' && id != 'page-1') {
          throw StateError('Unused future page was loaded: $id');
        }
        return f.png;
      });
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reads.toSet(), {'page-0', 'page-1'});
      expect(game.groundTextureCache.length, lessThanOrEqualTo(2));
      expect(
        game.resourceBudget.residentBytes,
        lessThanOrEqualTo(2 * 32 * 32 * 8),
      );
    },
  );

  for (final durations in [[20], [100], [20, 100], [5, 20, 100]]) {
    test('texture prefetch follows authored durations $durations', () async {
      final f = _Fixture(6, durations: durations);
      final reads = <String>[];
      final game = f.game((id) async { reads.add(id); return f.png; });
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(reads.toSet(), {'page-0', 'page-1'});
      game.update(durations.first / 1000);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      game.update(0);
      expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-1');
    });
  }

  test('replaced live clock selects and renders the new window without refresh', () async {
    final f = _Fixture(8);
    final game = f.game((_) async => f.png, clock: (_, _, _, _, _) => 0);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    final replacement = f.game((_) async => f.png, clock: (_, _, _, _, _) => 99);
    addTearDown(replacement.onRemove);
    game.configuration = replacement.configuration;
    game.renderedConfiguration = replacement.configuration;
    final generation = game.generation;
    game.update(0);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    game.update(0);
    expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-3');
    expect(game.generation, generation);
  });

  test('occlusion-only atlas remains resident with the visible background', () async {
    final f = _Fixture(3, occlusion: true);
    final reads = <String>[];
    final game = f.game((id) async { reads.add(id); return f.png; });
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(reads.toSet(), {'page-0', 'page-1', 'page-2'});
  });

  test(
    'destination preparation uses the same current and next page window',
    () async {
      final f = _Fixture(10000);
      final reads = <String>[];
      final budget = RuntimeResourceBudget();
      final preparation = SpatialSceneResourcePreparation(
        SpatialScenePreparation(
          map: f.map,
          project: f.project,
          loadModel: (_) async => throw StateError('No models'),
          loadGroundImage: (id) async {
            reads.add(id);
            if (id != 'page-0' && id != 'page-1') {
              throw StateError('Unused destination page was loaded: $id');
            }
            return f.png;
          },
          resourceIdentity: 'fixture',
          resourceBudget: budget,
          isCurrent: () => true,
        ),
        modelCache: {},
        groundTextureCache: {},
        isCurrent: () => true,
      );
      addTearDown(budget.dispose);
      addTearDown(preparation.discard);
      expect(await preparation.prepare(), isTrue);
      expect(reads.toSet(), {'page-0', 'page-1'});
      preparation.discard();
      expect(budget.residentBytes, 0);
      expect(budget.activeDecodes, 0);
    },
  );

  test('destination rejects a corrupt next source and releases its leases', () async {
    final f = _Fixture(4);
    final budget = RuntimeResourceBudget();
    final failure = StateError('Corrupt future destination page');
    final preparation = SpatialSceneResourcePreparation(
      SpatialScenePreparation(map: f.map, project: f.project,
        loadModel: (_) async => throw StateError('No models'),
        loadGroundImage: (id) async { if (id == 'page-1') throw failure; return f.png; },
        resourceIdentity: 'corrupt-next', resourceBudget: budget, isCurrent: () => true),
      modelCache: {}, groundTextureCache: {}, isCurrent: () => true);
    addTearDown(preparation.discard);
    addTearDown(budget.dispose);
    await expectLater(preparation.prepare(), throwsA(same(failure)));
    expect(budget.residentBytes, 0);
    expect(budget.transientBytes, 0);
  });

  test(
    'warm scene initialization loads its displayed phase instead of the pack',
    () async {
      final f = _Fixture(100);
      final reads = <String>[];
      final game = f.game((id) async {
        reads.add(id);
        if (id != 'page-3' && id != 'page-4') {
          throw StateError('Wrong warm page: $id');
        }
        return f.png;
      })..groundElapsed = .1;
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(reads.toSet(), {'page-3', 'page-4'});
    },
  );

  for (final pages in [4, 90]) {
    test(
      'encountered $pages page cycles keep reads and reservations stable',
      () async {
        final f = _Fixture(pages, imageSize: pages == 90 ? 256 : 32);
        final reads = <String, int>{};
        final game = f.game((id) async {
          reads.update(id, (count) => count + 1, ifAbsent: () => 1);
          return f.png;
        });
        addTearDown(game.onRemove);
        expect(await game.refresh(), isTrue);
        expect(reads.length, lessThanOrEqualTo(2));
        for (var frame = 0; frame < pages * 3; frame++) {
          game.update(.033);
          await Future.wait(List.of(game.groundTextureCache.values));
          game.update(0);
        }
        expect(reads.length, pages);
        expect(reads.values, everyElement(1));
        expect(game.groundReservations.length, pages);
        expect(
          game.resourceBudget.residentBytes,
          pages * (pages == 90 ? 256 : 32) * (pages == 90 ? 256 : 32) * 8,
        );
        game.onRemove();
        expect(game.groundTextureCache, isEmpty);
        expect(game.resourceBudget.residentBytes, 0);
      },
    );
  }

  test('pending exterior ground survives active scene texture pruning', () async {
    final f = _Fixture(4);
    final started = Completer<void>();
    final delayed = Completer<Uint8List>();
    final game = f.game(
      (_) async => f.png,
      sourceMap: f.map.copyWith(layers: const []),
      decorations: [
        SpatialSceneDecoration(
          ownerMapId: f.map.id,
          offset: Offset.zero,
          project: f.project,
          loadModel: (_) async => throw StateError('No models'),
          loadGroundImage: (id) async {
            if (id == 'page-0') {
              if (!started.isCompleted) started.complete();
              return delayed.future;
            }
            return f.png;
          },
          decoration: MapExteriorDecoration(
            mapId: f.map.id,
            playableWidth: 1,
            playableDepth: 1,
            west: 1,
            sectors: [
              ExteriorDecorationSector(
                id: 'west',
                originX: -1,
                originZ: 0,
                scene: f.map.spatialScene!,
                layers: f.map.layers,
              ),
            ],
          ),
        ),
      ],
    );
    addTearDown(game.onRemove);
    final pending = game.refresh();
    await started.future;
    expect(game.refreshing, isFalse);
    game.update(0);
    delayed.complete(f.png);
    expect(await pending, isTrue);
    await Future.wait(List.of(game.groundTextureCache.values));
    expect(game.decorationStats.ready, isTrue);
    expect(game.groundReservations, contains('page-0'));
    expect(game.resourceBudget.activeDecodes, 0);
    game.onRemove();
    expect(game.resourceBudget.residentBytes, 0);
  });

  test(
    'pending encountered pages finish after leaving the texture window',
    () async {
      final f = _Fixture(4);
      final delayed = Completer<Uint8List>();
      var delayedReads = 0;
      final game = f.game((id) async {
        if (id == 'page-1') {
          delayedReads++;
          return delayed.future;
        }
        return f.png;
      });
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(Duration.zero);
      game.update(.099);
      await game.groundTextureCache['page-3'];
      game.update(0);
      delayed.complete(f.png);
      await game.groundTextureCache['page-1'];
      expect(game.groundReservations, contains('page-1'));
      game.groundElapsed = .033;
      game.update(0);
      expect(game.grounds.single.renderedImageIds, {'page-1'});
      expect(delayedReads, 1);
    },
  );

  for (final imageSize in [32, 512]) {
    test(
      'oversized cycles respect retention bounds for $imageSize px pages',
      () async {
        final f = _Fixture(160, imageSize: imageSize);
        final game = f.game((_) async => f.png);
        addTearDown(game.onRemove);
        expect(await game.refresh(), isTrue);
        for (var frame = 0; frame < 160; frame++) {
          game.update(.033);
          await Future.wait(List.of(game.groundTextureCache.values));
          game.update(0);
          final ground = game.grounds.single;
          final required = {
            ...ground.currentImageIds,
            ...ground.nextImageIds,
            ...ground.renderedImageIds,
          };
          final optional = game.groundReservations.entries.where(
            (entry) => !required.contains(entry.key),
          );
          expect(optional.length, lessThanOrEqualTo(128));
          expect(
            optional.fold<int>(
              0,
              (sum, entry) => sum + entry.value.residentBytes,
            ),
            lessThanOrEqualTo(48 * 1024 * 1024),
          );
        }
        expect(game.groundReservations.length, lessThan(160));
      },
    );
  }

  test(
    'shared mandatory consumers evict retained pages and preserve the window',
    () async {
      final f = _Fixture(4);
      final game = f.game((_) async => f.png);
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      for (var frame = 0; frame < 4; frame++) {
        game.update(.033);
        await Future.wait(List.of(game.groundTextureCache.values));
        game.update(0);
      }
      final ground = game.grounds.single;
      final required = {
        ...ground.currentImageIds,
        ...ground.nextImageIds,
        ...ground.renderedImageIds,
      };
      final requiredLeases = {
        for (final id in required) id: game.groundReservations[id],
      };
      final requiredBytes = requiredLeases.values.fold<int>(
        0,
        (sum, lease) => sum + lease!.residentBytes,
      );
      final otherConsumer = await game.resourceBudget.acquire(residentBytes: 8);
      otherConsumer.resize(
        residentBytes:
            game.resourceBudget.profile.maximumResidentBytes - requiredBytes,
        transientBytes: 0,
      );
      expect(game.groundReservations.keys.toSet(), required);
      expect(game.groundReservations, requiredLeases);
      expect(
        game.resourceBudget.residentBytes,
        game.resourceBudget.profile.maximumResidentBytes,
      );
      otherConsumer.release();
      game.onRemove();
      expect(game.resourceBudget.residentBytes, 0);
    },
  );

  test(
    'a smaller shared budget evicts optional pages without eager loading',
    () async {
      final f = _Fixture(90, imageSize: 256);
      final reads = <String, int>{};
      final statuses = <Object?>[];
      final budget = RuntimeResourceBudget(
        profile: const RuntimeResourceProfile(
          maximumResidentBytes: 2 * 1024 * 1024,
        ),
      );
      final game = f.game(
        (id) async {
          reads.update(id, (count) => count + 1, ifAbsent: () => 1);
          return f.png;
        },
        resourceBudget: budget,
        onStatus: statuses.add,
      );
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      expect(reads.length, lessThanOrEqualTo(2));
      for (var frame = 0; frame < 180; frame++) {
        game.update(.033);
        await Future.wait(List.of(game.groundTextureCache.values));
        game.update(0);
        expect(budget.residentBytes, lessThanOrEqualTo(2 * 1024 * 1024));
      }
      expect(reads.length, 90);
      expect(reads['page-0'], greaterThan(1));
      expect(statuses.whereType<Object>(), isEmpty);
      expect(game.groundReservations.length, lessThanOrEqualTo(4));
    },
  );
  test('map changes release encountered pages outside the new plan', () async {
    final f = _Fixture(4);
    final game = f.game((_) async => f.png);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    for (var frame = 0; frame < 4; frame++) {
      game.update(.033);
      await Future.wait(List.of(game.groundTextureCache.values));
      game.update(0);
    }
    final destination = f.game(
      (_) async => f.png,
      sourceMap: f.map.copyWith(id: 'empty', layers: const []),
      resourceBudget: game.resourceBudget,
    );
    addTearDown(destination.onRemove);
    game.configuration = destination.configuration;
    expect(await game.refresh(), isTrue);
    expect(game.grounds, isEmpty);
    expect(game.groundTextureCache, isEmpty);
    expect(game.groundReservations, isEmpty);
    expect(game.resourceBudget.residentBytes, 0);
    expect(game.resourceBudget.transientBytes, 0);
  });

  test(
    'prepared destinations borrow no optional snapshot under shared pressure',
    () async {
      final f = _Fixture(4);
      final reads = <String, int>{};
      Future<Uint8List> load(String id) async {
        reads.update(id, (count) => count + 1, ifAbsent: () => 1);
        return f.png;
      }

      final game = f.game(load);
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      for (var frame = 0; frame < 4; frame++) {
        game.update(.033);
        await Future.wait(List.of(game.groundTextureCache.values));
        game.update(0);
      }
      final initial = game.groundTextureCache['page-2'];
      expect(
        await game.prepareDestination(
          SpatialScenePreparation(
            map: f.map.copyWith(
              id: 'destination',
              layers: const [],
              spatialScene: MapSpatialScene(
                width: 1,
                depth: 1,
                cliffFrame: const SmartTileFrameRef(
                  atlasId: 'atlas-2',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
            project: f.project,
            loadModel: (_) async => throw StateError('No models'),
            loadGroundImage: load,
            resourceIdentity: 'fixture',
            resourceBudget: game.resourceBudget,
            isCurrent: () => true,
          ),
        ),
        isTrue,
      );
      expect(reads['page-2'], 2);
      expect(game.groundTextureCache['page-2'], same(initial));
      final required = {'page-0', 'page-1', 'page-2'};
      final otherConsumer = await game.resourceBudget.acquire(
        residentBytes:
            game.resourceBudget.profile.maximumResidentBytes -
            required.length * 32 * 32 * 8,
      );
      expect(game.groundReservations.keys.toSet(), required);
      expect(game.groundTextureCache['page-2'], same(initial));
      otherConsumer.release();
      game.onRemove();
      expect(game.resourceBudget.residentBytes, 0);
    },
  );

  test('resource invalidation releases optional pages before retiring displayed resources', () async {
    final f = _Fixture(4);
    final game = f.game((_) async => f.png);
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    for (var frame = 0; frame < 4; frame++) {
      game.update(.033);
      await Future.wait(List.of(game.groundTextureCache.values));
      game.update(0);
    }
    final ground = game.grounds.single;
    final required = {
      ...ground.currentImageIds,
      ...ground.nextImageIds,
      ...ground.renderedImageIds,
    };
    game.clearGroundResourceCache(retire: true);
    expect(game.groundReservations, isEmpty);
    expect(game.groundTextureCache, isEmpty);
    expect(game.retiredReservations.length, required.length);
    expect(game.resourceBudget.residentBytes, required.length * 32 * 32 * 8);
    game.onRemove();
    expect(game.resourceBudget.residentBytes, 0);
  });
  test(
    'animation retains encountered pages within the active plan',
    () async {
      final f = _Fixture(8);
      final reads = <String>[];
      final game = f.game((id) async {
        reads.add(id);
        return f.png;
      });
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      for (var frame = 0; frame < 12; frame++) {
        game.update(.034);
        await Future<void>.delayed(const Duration(milliseconds: 1));
        game.update(0);
        await Future<void>.delayed(Duration.zero);
        expect(game.groundTextureCache.length, lessThanOrEqualTo(8));
        expect(
          game.resourceBudget.residentBytes,
          lessThanOrEqualTo(8 * 32 * 32 * 8),
        );
      }
      expect(reads.toSet().length, greaterThan(2));
      game.onRemove();
      expect(game.resourceBudget.residentBytes, 0);
      expect(game.resourceBudget.transientBytes, 0);
      expect(game.resourceBudget.pendingDecodes, 0);
    },
  );

  test('a delayed next page preserves the complete previous mesh', () async {
    final f = _Fixture(4);
    final next = Completer<Uint8List>();
    final started = Completer<void>();
    final game = f.game((id) async {
      if (id == 'page-1') {
        if (!started.isCompleted) started.complete();
        return next.future;
      }
      return f.png;
    });
    addTearDown(game.onRemove);
    expect(await game.refresh(), isTrue);
    await started.future;
    final components = List.of(game.grounds.single.components);
    final images = game.grounds.single.renderedImageIds;
    final lease = game.groundReservations['page-0'];
    final generation = game.generation;
    game.update(.034);
    expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-0');
    expect(game.grounds.single.components, orderedEquals(components));
    expect(game.grounds.single.renderedImageIds, same(images));
    expect(game.groundReservations['page-0'], same(lease));
    next.complete(f.png);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    game.update(0);
    expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-1');
    expect(game.generation, generation);
  });

  test(
    'stale animation completion releases its lease after scene disposal',
    () async {
      final f = _Fixture(4);
      final next = Completer<Uint8List>();
      final started = Completer<void>();
      final game = f.game((id) async {
        if (id == 'page-1') {
          if (!started.isCompleted) started.complete();
          return next.future;
        }
        return f.png;
      });
      expect(await game.refresh(), isTrue);
      await started.future;
      game.onRemove();
      next.complete(f.png);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(game.groundTextureCache, isEmpty);
      expect(game.groundReservations, isEmpty);
      expect(game.resourceBudget.residentBytes, 0);
      expect(game.resourceBudget.transientBytes, 0);
      expect(game.resourceBudget.activeDecodes, 0);
    },
  );

  test(
    'next-page source failures become actionable when the page is required',
    () async {
      final f = _Fixture(4);
      final statuses = <Object?>[];
      final failure = StateError('Unreadable future page');
      final game = f.game((id) async {
        if (id == 'page-1') throw failure;
        return f.png;
      }, onStatus: statuses.add);
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(statuses.whereType<Object>(), isEmpty);
      game.update(.034);
      game.update(0);
      expect(statuses.whereType<Object>(), [same(failure)]);
      expect(game.grounds.single.visuals.single.visual.tilesetId, 'page-0');
    },
  );

  test(
    'independent neighbor clocks retain only both current and next windows',
    () async {
      final f = _Fixture(100);
      final reads = <String>[];
      Future<Uint8List> load(String id) async {
        reads.add(id);
        return f.png;
      }

      final game = f.game(
        load,
        neighbors: [
          SpatialSceneNeighbor(
            map: f.map.copyWith(id: 'neighbor'),
            offset: const Offset(1, 0),
            project: f.project,
            loadGroundImage: load,
          ),
        ],
        clock: (map, layer, x, y, time) => time + (map == 'neighbor' ? 99 : 0),
      );
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(reads.toSet(), {'page-0', 'page-1', 'page-3', 'page-4'});
      game.update(.034);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      game.update(0);
      expect(game.groundTextureCache.length, lessThanOrEqualTo(6));
      expect(
        game.resourceBudget.residentBytes,
        lessThanOrEqualTo(6 * 32 * 32 * 8),
      );
    },
  );

  test(
    'all visible static pages stay loaded without animation churn',
    () async {
      final f = _Fixture(100, animated: false);
      final reads = <String>[];
      final game = f.game((id) async {
        reads.add(id);
        return f.png;
      });
      addTearDown(game.onRemove);
      expect(await game.refresh(), isTrue);
      final leases = Map.of(game.groundReservations);
      final components = List.of(game.grounds.single.components);
      game.update(10);
      expect(reads.toSet(), {'page-0', 'page-1'});
      expect(game.groundReservations, equals(leases));
      expect(game.grounds.single.components, orderedEquals(components));
    },
  );

  test(
    'a required page error is reported without a successful scene',
    () async {
      final f = _Fixture(4);
      final game = f.game(
        (_) async => throw StateError('Unreadable current page'),
      );
      addTearDown(game.onRemove);
      await expectLater(game.refresh(), throwsStateError);
      expect(game.renderedConfiguration, isNull);
      expect(game.resourceBudget.residentBytes, 0);
    },
  );
}

final class _Fixture {
  _Fixture(
    int frames, {
    bool animated = true,
    bool singleImage = false,
    List<int> durations = const [33],
    int imageSize = 32,
    bool occlusion = false,
    int occlusionPage = 2,
  }) {
    png = Uint8List.fromList(img.encodePng(img.Image(width: imageSize, height: imageSize)));
    map = MapData(
      id: 'room',
      name: 'Room',
      size: const GridSize(width: 1, height: 1),
      spatialScene: MapSpatialScene(width: 1, depth: 1),
      layers: const [
        SmartTileLayer(
          id: 'water',
          name: 'Water',
          presetId: 'water',
          usage: SmartTileUsage.terrain,
          materialPalette: ['', 'water'],
          field: SmartTileField.cell(semanticCells: [1]),
        ),
      ],
    );
    project = ProjectManifest(
      name: 'Fixture',
      maps: const [],
      tilesets: const [],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const [
          ProjectSmartTileMaterial(
            id: 'water',
            name: 'Water',
            connectionGroupId: 'water',
          ),
        ],
        atlases: [
          for (var i = 0; i < frames; i++)
            ProjectSmartTileAtlas(
              id: 'atlas-$i',
              name: 'Page $i',
              tilesetId: singleImage ? 'page-0' : 'page-$i',
              originX: singleImage ? i * 32 : 0,
              columns: 1,
              rows: 1,
            ),
        ],
        animations: [
          ProjectSmartTileAnimation(
            id: 'wave',
            name: 'Wave',
            frames: [
              for (var i = 0; i < frames; i++)
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas-$i',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: durations[i % durations.length],
                ),
            ],
          ),
        ],
        presets: [
          ProjectSmartTilePreset(
            id: 'water',
            name: 'Water',
            usage: SmartTileUsage.terrain,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'water',
            allowedMaterialIds: ['water'],
            rules: [
              SmartTileRule(
                id: 'fill',
                centerMatch: SmartTileSlotMatch.material('water'),
                candidates: [
                  SmartTileCandidate(
                    id: 'wave',
                    parts: [
                      if (occlusion)
                        SmartTileVisualPart(
                          channel: SmartTileRenderChannel.actorOcclusion,
                          source: SmartTileVisualSource.frame(
                            frame: SmartTileFrameRef(
                              atlasId: 'atlas-$occlusionPage',
                              column: 0,
                              row: 0,
                            ),
                          ),
                        ),
                      if (animated)
                        const SmartTileVisualPart(
                          source: SmartTileVisualSource.animation(
                            animationId: 'wave',
                          ),
                        )
                      else
                        for (var index = 0; index < 2; index++)
                          SmartTileVisualPart(
                            source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                atlasId: 'atlas-$index',
                                column: 0,
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
  }
  late final MapData map;
  late final ProjectManifest project;
  late final Uint8List png;

  SpatialSceneGame game(
    Future<Uint8List> Function(String) load, {
    List<SpatialSceneNeighbor> neighbors = const [],
    List<SpatialSceneDecoration> decorations = const [],
    int Function(String, String, int, int, int)? clock,
    void Function(Object?)? onStatus,
    MapData? sourceMap,
    RuntimeResourceBudget? resourceBudget,
    bool Function()? renderPreparationPaused,
    bool Function()? presentationPaused,
    double Function()? presentationElapsedSeconds,
    Map<String, SpatialActorVisual> Function(double)? actorFrames,
  }) {
    final controller = SpatialSceneController();
    final budget = resourceBudget ?? RuntimeResourceBudget();
    final groundMap = sourceMap ?? map;
    final game =
        SpatialSceneGame(
            SpatialSceneView(
              scene: groundMap.spatialScene!,
              groundMap: groundMap,
              groundProject: project,
              models: const [],
              loadModel: (_) async => throw StateError('No models'),
              loadGroundImage: load,
              controller: controller,
              resourceBudget: budget,
              resourceIdentity: 'fixture',
              neighbors: neighbors,
              decorations: decorations,
              rasterAnimationElapsedMsForCell: clock,
              renderPreparationPaused: renderPreparationPaused,
              presentationPaused: presentationPaused,
              presentationElapsedSeconds: presentationElapsedSeconds,
              actorFrames: actorFrames,
              onCell: (_, _) {},
              background: const Color(0xff000000),
              ground: const Color(0xff224422),
              edge: const Color(0xff111111),
              errorBuilder: (_, _) => const SizedBox(),
            ),
            onPreviewStatus: onStatus ?? (_) {},
            onSurfaceChanged: () {},
          )
          ..onGameResize(Vector2(200, 200))
          ..sceneReady = true;
    addTearDown(controller.dispose);
    addTearDown(budget.dispose);
    return game;
  }
}

class _CountingPreparationGame extends SpatialSceneGame {
  _CountingPreparationGame(super.configuration)
    : super(onPreviewStatus: (_) {}, onSurfaceChanged: () {});

  int preparationCalls = 0;
  int modelSyncCalls = 0;

  @override
  void syncActors(double dt) {
    preparationCalls++;
    super.syncActors(dt);
  }

  @override
  void syncRuntimeModels() {
    modelSyncCalls++;
    super.syncRuntimeModels();
  }

  @override
  void syncLighting() {
    preparationCalls++;
    super.syncLighting();
  }

  @override
  void syncActorContactShadows() {
    preparationCalls++;
    super.syncActorContactShadows();
  }
}

class _ModelPauseFixture {
  _ModelPauseFixture() {
    final scene = MapSpatialScene(
      width: 1,
      depth: 1,
      instances: [
        SpatialModelInstance(
          id: 'lamp',
          modelId: 'lamp',
          position: Model3dVector3.zero,
          animationIndex: 0,
        ),
      ],
    );
    game = SpatialSceneGame(
      SpatialSceneView(
        scene: scene,
        models: [
          ProjectModel3dEntry(
            id: 'lamp',
            name: 'Lamp',
            sourceAssetId: 'lamp',
            relativePath: 'assets/models3d/lamp.glb',
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
        loadModel: (_) async =>
            throw StateError('The cached model must be reused'),
        controller: controller,
        animationPreview: preview,
        renderPreparationPaused: () => covered,
        presentationPaused: () => paused,
        modelRuntimeState: (_, _) => state,
        actorFrames: (dt) {
          deltas.add(dt);
          return {};
        },
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff224422),
        edge: const Color(0xff111111),
        errorBuilder: (_, error) => throw error,
      ),
      onPreviewStatus: failures.add,
      onSurfaceChanged: () {},
    );
    game.cache['lamp'] = Future.value(
      Model(
        nodes: {},
        animations: [
          ModelAnimation(
            name: 'ambient',
            nodes: {
              0: AbsoluteNodeAnimation(
                channels: [
                  EndpointSafeAnimationController(
                    animation: TranslationAnimationSpline.from(
                      interpolation: AnimationInterpolation.linear,
                      times: [0, 1],
                      values: [Vector3.zero(), Vector3(3, 0, 0)],
                    ),
                  ),
                ],
              ),
            },
          ),
        ],
      ),
    );
    game.onGameResize(Vector2(200, 200));
    game.weatherEffects.batches.addAll([
      SpatialWeatherBatch(),
      SpatialWeatherBatch(),
    ]);
  }

  final controller = SpatialSceneController();
  final preview = SpatialAnimationPreviewController();
  final deltas = <double>[];
  final failures = <Object?>[];
  bool covered = false, paused = false;
  SpatialModelRuntimeState? state;
  late final SpatialSceneGame game;
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _CountingVisuals extends ListBase<SpatialGroundVisual> {
  _CountingVisuals(List<SpatialGroundVisual> values)
    : values = List.unmodifiable(values);

  final List<SpatialGroundVisual> values;
  int reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) =>
      throw UnsupportedError('Immutable displayed visuals');

  @override
  SpatialGroundVisual operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, SpatialGroundVisual value) =>
      throw UnsupportedError('Immutable displayed visuals');
}

({
  int resolveBatchCalls,
  int animationVariantVisits,
  int compiledAnimationVariants,
  int selectedCellVisits,
})
_groundWork(SpatialGroundPlan ground) {
  var calls = 0;
  var variants = 0;
  var compiled = 0;
  var cells = 0;
  for (final plan in ground.debugVisualPlans) {
    final work = plan.debugWork;
    calls += work.resolveBatchCalls;
    variants += work.animationVariantVisits;
    compiled += work.compiledAnimationVariants;
    cells += work.selectedCellVisits;
  }
  return (
    resolveBatchCalls: calls,
    animationVariantVisits: variants,
    compiledAnimationVariants: compiled,
    selectedCellVisits: cells,
  );
}
