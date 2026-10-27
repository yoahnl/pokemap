import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_actor_occlusion.dart';
import 'package:map_render_3d/src/spatial_ground.dart';
import 'package:map_render_3d/src/spatial_scene_preparation.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_scene_neighbor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_UnusedBackend.new);

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
    expect(game.groundTextureCache, isNot(contains('page-0')));
    expect(game.groundReservations, isNot(contains('page-0')));
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
      expect(game.groundTextureCache, isNot(contains('page-2')));
      expect(game.groundReservations, isNot(contains('page-2')));
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

  test(
    'animation evicts retired pages and retains bounded admission',
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
        expect(game.groundTextureCache.length, lessThanOrEqualTo(3));
        expect(
          game.resourceBudget.residentBytes,
          lessThanOrEqualTo(3 * 32 * 32 * 8),
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
    bool occlusion = false,
    int occlusionPage = 2,
  }) {
    png = Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 32)));
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
    int Function(String, String, int, int, int)? clock,
    void Function(Object?)? onStatus,
  }) {
    final controller = SpatialSceneController();
    final budget = RuntimeResourceBudget();
    final game =
        SpatialSceneGame(
            SpatialSceneView(
              scene: map.spatialScene!,
              groundMap: map,
              groundProject: project,
              models: const [],
              loadModel: (_) async => throw StateError('No models'),
              loadGroundImage: load,
              controller: controller,
              resourceBudget: budget,
              resourceIdentity: 'fixture',
              neighbors: neighbors,
              rasterAnimationElapsedMsForCell: clock,
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
