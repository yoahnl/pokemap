import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart';

void main() {
  for (final storage in ReliabilityStorage.values) {
    group(storage.name, () {
      Future<ReliabilityMapFixture> fixture(
          ReliabilityMapVariant variant) async {
        final result = await ReliabilityMapFixture.create(
            variant: variant, storage: storage);
        addTearDown(() async {
          print(jsonEncode({
            'variant': variant.name,
            'storage': storage.name,
            'measurements': result.measurements,
            'jsonlCalls': result.jsonlCalls,
            'jsonlRequestBytes': result.jsonlRequestBytes,
            'jsonlResponseBytes': result.jsonlResponseBytes,
            'measurementScope':
                'headless synthetic direct API; reader calls only; no UI/native render/LLM certification'
          }));
          await result.dispose();
          expect(await result.root.exists(), isFalse);
        });
        return result;
      }

      test('healthy control has supported cliff and complete painted ground',
          () async {
        final host = await fixture(ReliabilityMapVariant.healthy);
        final before = await host.mapFile.readAsBytes();
        final resolution = _resolve(host.content.project, await host.readMap());
        expect(resolution.result.canApply, isTrue);
        expect(resolution.result.diagnostics, isEmpty);
        final integrity = inspectSpatialMapIntegrity(
            manifest: host.content.project, map: await host.readMap());
        expect(integrity.groundGaps, isEmpty);
        expect(integrity.borderObjectOverlaps, isEmpty);
        await host.reopen();
        expect(await host.mapFile.readAsBytes(), before);
      });

      test('T1 explicit ground restoration then native feature removal',
          () async {
        final host = await fixture(ReliabilityMapVariant.shoreGap);
        final original = await host.readMap();
        final cells = host.content.contour;
        expect(inspectSpatialMapIntegrity(manifest:host.content.project,map:original).exposedCellCount,0);
        expect(
            cells.every((cell) => _materialAt(original, cell) == ''), isTrue);
        await _paint(host, cells, 'grass');
        await host.apply('border_layer.feature_delete',
            {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'});
        await host.reopen();
        final saved = await host.readMap();
        expect(saved.layers.whereType<BorderLayer>().single.content.features,
            isEmpty);
        expect(
            cells.every((cell) => _materialAt(saved, cell) == 'grass'), isTrue);
        _outsidePaintUnchanged(original, saved, cells.toSet());
        expect(saved.properties, original.properties);
        expect(saved.spatialScene!.instances.single.id, 'unrelated-object');
      });

      test('T2 explicit lower ground repair clears crown/base diagnostics',
          () async {
        final host = await fixture(ReliabilityMapVariant.floatingCliff);
        final original = await host.readMap();
        expect(_faceDiagnostics(_resolve(host.content.project, original)),
            isNotEmpty);
        await host.apply('map3d.terrain.surface.upsert_batch', {
          'mapId': 'map',
          'surfaces': [
            SpatialTerrainSurface(
              id: 'lower-ground',
              x: 0,
              z: 0,
              height: 0,
              footprints: [
                BorderGroundFootprint(points: [
                  BorderGroundPoint(x: 0, z: 0),
                  BorderGroundPoint(x: 24, z: 0),
                  BorderGroundPoint(x: 24, z: host.content.contourY.toDouble()),
                  BorderGroundPoint(x: 0, z: host.content.contourY.toDouble()),
                ])
              ],
            ).toJson()
          ],
        });
        await host.reopen();
        final saved = await host.readMap();
        final resolved = _resolve(host.content.project, saved);
        expect(_faceDiagnostics(resolved), isEmpty);
        expect(resolved.result.canApply, isTrue);
        expect(
            saved.layers
                .whereType<BorderLayer>()
                .single
                .content
                .features
                .single
                .geometry,
            host.content.feature.geometry);
        expect(_paintCells(saved), _paintCells(original));
      });

      test('T3 explicit oriented contour becomes fresh native cliff', () async {
        final host = await fixture(ReliabilityMapVariant.missingCliff);
        final original = await host.readMap();
        expect(original.layers.whereType<BorderLayer>().single.content.features,
            isEmpty);
        await host.apply(
            'border_layer.feature_create', _featureParameters(host.content));
        await _materialize(host);
        await host.reopen();
        final saved = await host.readMap();
        final feature = saved.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single;
        expect((feature.geometry as BorderStrokeGeometry).strokes.single.points,
            host.content.contour);
        expect(feature.lineSide, BorderLineSide.primary);
        expect(feature.materialization, isNotNull);
        final resolved = _resolve(host.content.project, saved);
        expect(resolved.result.canApply, isTrue);
        expect(resolved.result.diagnostics, isEmpty);
        expect(resolved.result.materialization, feature.materialization);
        expect(_paintCells(saved), _paintCells(original));
      });

      test('T4 interior hole repair changes exactly the requested cell',
          () async {
        final host = await fixture(ReliabilityMapVariant.interiorHole);
        final original = await host.readMap();
        expect(_materialAt(original, ReliabilityMapContent.hole), '');
        final gaps = inspectSpatialMapIntegrity(
                manifest: host.content.project, map: original)
            .groundGaps;
        expect(
            gaps.any((gap) => gap.cell == ReliabilityMapContent.hole), isTrue);
        await _paint(host, [ReliabilityMapContent.hole], 'grass');
        await host.reopen();
        final saved = await host.readMap();
        expect(_materialAt(saved, ReliabilityMapContent.hole), 'grass');
        _outsidePaintUnchanged(original, saved, {ReliabilityMapContent.hole});
        expect(saved.spatialScene, original.spatialScene);
        expect(saved.layers.whereType<BorderLayer>().single,
            original.layers.whereType<BorderLayer>().single);
      });

      test('T5 suppress only the slot overlapping a synthetic dock', () async {
        final host = await fixture(ReliabilityMapVariant.dockOverlap);
        final original = await host.readMap();
        final scene = original.spatialScene!;
        final dock =
            scene.instances.singleWhere((instance) => instance.id == 'dock');
        final feature = original.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single;
        final placements = feature.materialization!.spatialPlacements;
        final target = placements.singleWhere((placement) => scene.instances
            .any((instance) =>
                instance.id == placement.instanceId &&
                instance.position == dock.position));
        final before = inspectSpatialMapIntegrity(
            manifest: host.content.project, map: original);
        expect(
            before.borderObjectOverlaps
                .any((overlap) => overlap.instanceId == 'dock'),
            isTrue);
        await host.apply('border_layer.feature_set_suppressed', {
          'mapId': 'map',
          'layerId': 'border',
          'featureId': 'fence',
          'slotKey': target.slotKey,
          'suppressed': true,
        });
        await _materialize(host);
        await host.reopen();
        final saved = await host.readMap();
        final afterFeature = saved.layers
            .whereType<BorderLayer>()
            .single
            .content
            .features
            .single;
        expect(afterFeature.overrides.single.suppressed, isTrue);
        expect(
            afterFeature.materialization!.spatialPlacements
                .map((placement) => placement.slotKey)
                .toSet(),
            placements
                .where((placement) => placement.slotKey != target.slotKey)
                .map((placement) => placement.slotKey)
                .toSet());
        expect(
            saved.spatialScene!.instances
                .singleWhere((instance) => instance.id == 'dock'),
            dock);
        expect(
            inspectSpatialMapIntegrity(
                    manifest: host.content.project, map: saved)
                .borderObjectOverlaps
                .where((overlap) => overlap.instanceId == 'dock'),
            isEmpty);
        expect(_paintCells(saved), _paintCells(original));
      });

      test(
          'T6 manually resolved material ID persists; automatic name resolution is separate',
          () async {
        final host = await fixture(ReliabilityMapVariant.healthy);
        final candidates = host.content.project.smartTileCatalog.materials
            .where((m) => m.name == 'Mer')
            .toList();
        expect(candidates.map((m) => m.id), ['sea']);
        const target = GridPos(x: 12, y: 9);
        final before = await host.readMap();
        await _paint(host, [target], candidates.single.id);
        await host.reopen();
        final saved = await host.readMap();
        expect(_materialAt(saved, target), 'sea');
        _outsidePaintUnchanged(before, saved, {target});
      });

      test('T7 creates native map and ground layer from existing resources',
          () async {
        final host = await fixture(ReliabilityMapVariant.noWorkingMap);
        expect(await host.mapFile.exists(), isFalse);
        await host.apply('map.create', {
          'mapId': 'map',
          'name': 'Created reliability field',
          'width': 24,
          'height': 16
        });
        await host.apply('smart_tile.layer.create', {
          'mapId': 'map',
          'layerId': 'terrain',
          'name': 'Terrain',
          'presetId': 'ground'
        });
        await _paint(host, [const GridPos(x: 12, y: 9)], 'sea');
        await host.reopen();
        final saved = await host.readMap();
        expect(saved.size, const GridSize(width: 24, height: 16));
        expect(saved.spatialScene, isNotNull);
        expect(
            saved.layers.whereType<SmartTileLayer>().single.presetId, 'ground');
        expect(_materialAt(saved, const GridPos(x: 12, y: 9)), 'sea');
        final selected = storage == ReliabilityStorage.catalog
            ? await host.api.readWorkshopSnapshot(host.opened.projectHandle,
                actionId: 'smart_tile.layer.create',
                parameters: {
                    'mapId': 'map',
                    'presetId': 'ground',
                    'layerId': 'next',
                    'name': 'Next'
                  })
            : await host.snapshots.load(host.opened.projectHandle);
        expect(selected.manifest.smartTileCatalog.materials.map((m) => m.id),
            containsAll(['grass', 'sea']));
      });

      test('T8 ambiguity is represented by two candidates without writing',
          () async {
        final host = await fixture(ReliabilityMapVariant.ambiguousMaterial);
        final before = await host.mapFile.readAsBytes();
        final candidates = host.content.project.smartTileCatalog.materials
            .where((m) => m.name == 'Mer')
            .toList();
        expect(candidates.map((m) => m.id), ['sea', 'sea-alternate']);
        expect(await host.mapFile.readAsBytes(), before);
        expect(host.measurements, isEmpty);
      });

      test('T9 legacy plan replay after reopen reuses its receipt', () async {
        final host = await fixture(ReliabilityMapVariant.interiorHole);
        final plan = await host.plan('smart_tile.cell.paint',
            _paintParameters([ReliabilityMapContent.hole], 'grass'),
            identity: 'lost-response');
        final first = await host.api.applyMutation(host.opened.projectHandle,
            planId: plan.planId, operationId: 'lost-response');
        final before = await host.mapFile.readAsBytes();
        final modified = await host.mapFile.lastModified();
        await host.reopen();
        final replay = await host.api.applyMutation(host.opened.projectHandle,
            planId: plan.planId, operationId: 'lost-response');
        expect(replay.receipt.receiptId, first.receipt.receiptId);
        expect(await host.mapFile.readAsBytes(), before);
        expect(await host.mapFile.lastModified(), modified);
      });

      test('T10 identical paint after undo has a new durable identity',
          () async {
        final host = await fixture(ReliabilityMapVariant.interiorHole);
        final before = await host.mapFile.readAsBytes();
        final parameters =
            _paintParameters([ReliabilityMapContent.hole], 'grass');
        final first = await host.apply('smart_tile.cell.paint', parameters,
            identity: 'paint-first');
        await host.api.undoMutation(host.opened.projectHandle,
            entryId: first.receipt.receiptId, idempotencyKey: 'undo-first');
        expect(await host.mapFile.readAsBytes(), before);
        final second = await host.apply('smart_tile.cell.paint', parameters,
            identity: 'paint-second');
        expect(second.receipt.receiptId, isNot(first.receipt.receiptId));
        await host.reopen();
        expect(_materialAt(await host.readMap(), ReliabilityMapContent.hole),
            'grass');
      });

      test('invalid map and unknown material leave map bytes intact', () async {
        final host = await fixture(ReliabilityMapVariant.healthy);
        final before = await host.mapFile.readAsBytes();
        await expectLater(
            host.plan('smart_tile.cell.paint', {
              ..._paintParameters([ReliabilityMapContent.hole], 'grass'),
              'mapId': 'missing-map'
            }),
            throwsA(anything));
        await expectLater(
            host.plan(
                'smart_tile.cell.paint',
                _paintParameters(
                    [ReliabilityMapContent.hole], 'unknown-material')),
            throwsA(anything));
        expect(await host.mapFile.readAsBytes(), before);
      });

      test(
          'JSONL discovery records actual bytes separately from direct API work',
          () async {
        final host = await fixture(ReliabilityMapVariant.healthy);
        final result = await host.command('describe', {});
        expect(result.status, AuthoringResultStatus.success);
        expect(host.jsonlCalls, 1);
        expect(host.jsonlRequestBytes, greaterThan(0));
        expect(host.jsonlResponseBytes, greaterThan(0));
        expect(host.measurements, isEmpty);
      });
    });
  }

  test(
      'three reserved variants have independent deterministic names and contours',
      () {
    for (var reserved = 1; reserved <= 3; reserved++) {
      final first = ReliabilityMapContent.create(ReliabilityMapVariant.healthy,
          reservedVariant: reserved);
      final second = ReliabilityMapContent.create(ReliabilityMapVariant.healthy,
          reservedVariant: reserved);
      expect(first.map, second.map);
      expect(first.contour.first.y, 4 + reserved);
      expect(
          first.project.smartTileCatalog.materials
              .singleWhere((m) => m.id == 'sea')
              .name,
          isNot('Mer'));
      expect(_resolve(first.project, first.map).result.diagnostics, isEmpty);
    }
  });

  test('combined control retains independent ground, face and overlap defects',
      () {
    final content =
        ReliabilityMapContent.create(ReliabilityMapVariant.combined);
    expect(_materialAt(content.map, ReliabilityMapContent.hole), '');
    expect(
        _faceDiagnostics(_resolve(content.project, content.map)), isNotEmpty);
    final integrity =
        inspectSpatialMapIntegrity(manifest: content.project, map: content.map);
    expect(integrity.groundGaps, isNotEmpty);
    expect(integrity.borderObjectOverlaps, isNotEmpty);
  });
}

List<int> _paintCells(MapData map) =>
    smartTileSemanticCells(map.layers.whereType<SmartTileLayer>().single);
String _materialAt(MapData map, GridPos cell) {
  final layer = map.layers.whereType<SmartTileLayer>().single;
  return layer
      .materialPalette[_paintCells(map)[cell.y * map.size.width + cell.x]];
}

void _outsidePaintUnchanged(
    MapData before, MapData after, Set<GridPos> changed) {
  for (var y = 0; y < before.size.height; y++) {
    for (var x = 0; x < before.size.width; x++) {
      final cell = GridPos(x: x, y: y);
      if (!changed.contains(cell)) {
        expect(_materialAt(after, cell), _materialAt(before, cell),
            reason: '$x,$y');
      }
    }
  }
}

Map<String, Object?> _paintParameters(List<GridPos> cells, String materialId) =>
    {
      'mapId': 'map',
      'layerId': 'terrain',
      'materialId': materialId,
      'cells': [for (final cell in cells) cell.toJson()]
    };
Future<AuthoringMutationResult> _paint(
        ReliabilityMapFixture host, List<GridPos> cells, String material) =>
    host.apply('smart_tile.cell.paint', _paintParameters(cells, material));
SpatialBorderResolutionResult _resolve(ProjectManifest project, MapData map) =>
    resolveSpatialBorderFeature(
        manifest: project, map: map, layerId: 'border', featureId: 'fence');
Iterable<String> _faceDiagnostics(SpatialBorderResolutionResult resolved) =>
    resolved.result.diagnostics.map((diagnostic) => diagnostic.code).where(
        (code) => code.contains('face_base') || code.contains('face_crown'));
Future<AuthoringMutationResult> _materialize(ReliabilityMapFixture host) =>
    host.apply('border_layer.materialize_batch_apply', {
      'mapId': 'map',
      'features': [
        {'layerId': 'border', 'featureId': 'fence'}
      ],
      'tileWidthPx': 16,
      'tileHeightPx': 16,
      'resolverVersion': borderResolverVersion,
    });
Map<String, Object?> _featureParameters(ReliabilityMapContent content) => {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'name': 'Step',
      'blueprintId': 'fence',
      'seed': '17',
      'lineSide': 'primary',
      'geometry': {
        'kind': 'stroke',
        'strokes': [
          {
            'id': 'step',
            'points': [for (final cell in content.contour) cell.toJson()],
            'closed': false
          }
        ]
      },
    };
