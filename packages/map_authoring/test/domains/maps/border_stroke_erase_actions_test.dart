import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;
import 'environment_spatial_actions_test.dart' show environmentModelGlb;

void main() {
  test(
      'planar canonical erasure resolves both fragments and preserves the foreign layers',
      () async {
    final fixture = _planarFixture();
    final draft = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([fixture.map], project: fixture.project),
        'border_layer.stroke_erase',
        _parameters(const [GridPos(x: 4, y: 1)])));
    final after = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));
    final feature =
        after.layers.whereType<BorderLayer>().single.content.features.single;
    expect(
        (feature.geometry as BorderStrokeGeometry)
            .strokes
            .map((stroke) => stroke.points.length),
        [3, 3]);
    expect(feature.materialization!.placements, hasLength(6));
    expect(after.layers.first, fixture.map.layers.first);
    expect(after.spatialScene, isNull);
    expect(draft.changeSet.changes, hasLength(1));
    expect(MapData.fromJson(after.toJson()), after);
  });

  test(
      'planar erase prunes invalid deleted overrides and preserves surviving locked stations',
      () {
    final fixture = _planarFixture();
    final feature = fixture.map.layers
        .whereType<BorderLayer>()
        .single
        .content
        .features
        .single;
    final request = BorderResolutionRequest(
        mapSize: fixture.map.size,
        tileSizePx: const GridSize(width: 16, height: 16),
        blueprintId: feature.blueprintId,
        blueprintRevision: fixture.project.borderCatalog
            .recordById(feature.blueprintId)!
            .latestPublished!,
        feature: feature,
        visualSnapshots: fixture.project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion);
    final base = resolveBorderFeature(request);
    final keepPlacement = base.materialization!.placements
          .singleWhere((placement) => placement.anchorCell.x == 2);
    final removePlacement = base.materialization!.placements
          .singleWhere((placement) => placement.anchorCell.x == 4);
    final keep = BorderSlotOverride(
        slotKey: keepPlacement.slotKey,
        variationSalt: BorderSignedInt64.fromInt(2),
        suppressed: false,
        locked: true,
        lockedPlacement: keepPlacement);
    final remove = BorderSlotOverride(
        slotKey: removePlacement.slotKey,
        variationSalt: BorderSignedInt64.fromInt(4),
        suppressed: false,
        locked: false,
        replacementPrimitiveId: 'missing-source');
    final before = updateBorderFeatureOverrides(fixture.map,
        layerId: 'border', featureId: 'fence', overrides: [keep, remove]);
    final after = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: before,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 4, y: 1)]);
    final changed =
        after.layers.whereType<BorderLayer>().single.content.features.single;
    expect(changed.overrides, [keep]);
    expect(
        changed.materialization!.placements
            .singleWhere((placement) => placement.slotKey == keep.slotKey),
        keepPlacement);
    expect(changed.materialization!.placements, hasLength(6));
    expect(after.layers.first, fixture.map.layers.first);
  });

  test(
      'native erase removes deleted slot overrides and preserves surviving locked stations',
      () {
    final fixture = _fixture();
    final feature = _feature(fixture.map);
    BorderSlotOverride overrideAt(int x, {bool locked = false}) {
      final instance = fixture.map.spatialScene!.instances.singleWhere(
          (instance) =>
              instance.id != 'foreign' && instance.position.x == x + .5);
      final slot = feature.materialization!.spatialPlacements
          .singleWhere((slot) => slot.instanceId == instance.id);
      return BorderSlotOverride(
          slotKey: slot.slotKey,
          variationSalt: BorderSignedInt64.fromInt(x),
          suppressed: false,
          locked: locked,
          lockedInstanceId: locked ? instance.id : null);
    }

    final keep = overrideAt(2, locked: true);
    final remove = overrideAt(4);
    final before = updateBorderFeatureOverrides(fixture.map,
        layerId: 'border', featureId: 'fence', overrides: [keep, remove]);
    final after = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: before,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 4, y: 1)]);
    expect(_feature(after).overrides, [keep]);
    final locked = before.spatialScene!.instances
        .singleWhere((instance) => instance.id == keep.lockedInstanceId);
    expect(
        after.spatialScene!.instances
            .singleWhere((instance) => instance.id == locked.id),
        locked);
    expect(_feature(after).generatedPlacementIds, hasLength(6));
  });

  test(
      'local erase is one semantic map change with two fresh fragments and foreign content intact',
      () async {
    final fixture = _fixture();
    final before = fixture.map;
    final old = _feature(before);
    final proposed = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: before,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 4, y: 1)]);
    _expectSplit(before, proposed);
    final updated = _feature(proposed);
    expect(updated.seed, old.seed);
    expect(updated.lineSide, old.lineSide);
    expect(updated.spatialOffsetWorld, old.spatialOffsetWorld);
    expect(updated.overrides, old.overrides);
    expect(updated.keepOutRegions, old.keepOutRegions);
    expect(MapData.fromJson(proposed.toJson()), proposed);
    expect(
        diagnoseSpatialBorderFeature(
                manifest: fixture.project,
                map: proposed,
                layerId: 'border',
                featureId: 'fence')
            .diagnostics
            .map((issue) => issue.code),
        isNot(contains('border.spatial.materialization_stale')));
    final draft = await MapMutationDispatcher.canonical().build(context(
        librarySnapshot([before], project: fixture.project),
        'border_layer.stroke_erase',
        _parameters(const [GridPos(x: 4, y: 1)])));
    expect(draft.changeSet.changes, hasLength(1));
    expect(
        MapData.fromJson(jsonDecode(
            utf8.decode(draft.changeSet.changes.single.afterBytes!))),
        proposed);
    expect(draft.preview['strokeCount'], 2);
    expect(draft.preview['featureRemoved'], false);
    expect(fixture.map, same(before));
  });

  test(
      'complete erase deletes only its feature and ownership, while noop remains identity preserving',
      () async {
    final fixture = _fixture();
    final noop = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 0, y: 0)]);
    expect(noop, same(fixture.map));
    final erased = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: fixture.map,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 1, y: 1), GridPos(x: 7, y: 1)]);
    expect((erased.layers.single as BorderLayer).content.featureById('fence'),
        isNull);
    expect(erased.spatialScene!.instances,
        [fixture.map.spatialScene!.instances.last]);
    expect(MapData.fromJson(erased.toJson()), erased);
    await expectLater(
        Future.sync(() => MapMutationDispatcher.canonical().build(context(
            librarySnapshot([fixture.map], project: fixture.project),
            'border_layer.stroke_erase',
            _parameters(const [GridPos(x: 0, y: 0)])))),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'map.no_change')));
  });

  test(
      'corner and closed stroke erasure preserves rasterized fragments and rejects invalid requests',
      () {
    final fixture = _fixture();
    final geometry = BorderStrokeGeometry(strokes: [
      BorderStroke(id: 'loop', closed: true, points: const [
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 3, y: 2),
        GridPos(x: 3, y: 3),
        GridPos(x: 2, y: 3),
        GridPos(x: 1, y: 3),
        GridPos(x: 1, y: 2)
      ])
    ]);
    final loop = updateBorderFeatureGeometry(fixture.map,
        layerId: 'border', featureId: 'fence', geometry: geometry);
    final erased = const BorderActions().eraseStroke(
        manifest: fixture.project,
        map: loop,
        layerId: 'border',
        featureId: 'fence',
        sampledPoints: const [GridPos(x: 3, y: 1)]);
    final stroke =
        (_feature(erased).geometry as BorderStrokeGeometry).strokes.single;
    expect(stroke.closed, false);
    expect(stroke.points, hasLength(7));
    expect(stroke.points, isNot(contains(const GridPos(x: 3, y: 1))));
    for (final points in [
      const <GridPos>[],
      const [GridPos(x: -1, y: 1)],
      const [GridPos(x: 10, y: 1)]
    ]) {
      expect(
          () => const BorderActions().eraseStroke(
              manifest: fixture.project,
              map: fixture.map,
              layerId: 'border',
              featureId: 'fence',
              sampledPoints: points),
          throwsA(isA<MapAuthoringException>()));
    }
    expect(
        () => const BorderActions().eraseStroke(
            manifest: fixture.project,
            map: fixture.map,
            layerId: 'border',
            featureId: 'missing',
            sampledPoints: const [GridPos(x: 4, y: 1)]),
        throwsA(isA<MapAuthoringException>()));
  });

  test(
      'JSONL erase plans without writes applies once rejects stale and reopens undo exactly',
      () async {
    final fixture = _fixture();
    final host = await ResourceInformationFixture.create(ProjectManifest(
        version: fixture.project.version,
        name: 'Erase test',
        maps: const [],
        tilesets: const [],
        settings: fixture.project.settings));
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/maps/map.json');
    await mapFile.parent.create(recursive: true);
    await mapFile.writeAsString(jsonEncode(fixture.map.toJson()));
    final model = fixture.project.models3d.single;
    final bytes = environmentModelGlb();
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
    final modelFile = File('${host.root.path}/${model.relativePath}');
    await modelFile.parent.create(recursive: true);
    await modelFile.writeAsBytes(bytes);
    final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File('${host.root.path}/assets/.pokemap-assets.json')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact)
    ]).toJson()));
    await File('${host.root.path}/project.json')
        .writeAsString(jsonEncode(fixture.project.toJson()));
    final beforeBytes = await mapFile.readAsBytes();
    final parameters = _parameters(const [GridPos(x: 4, y: 1)]);
    final planned = await host.plan('border_layer.stroke_erase', parameters);
    final stalePlan = await host.plan('border_layer.stroke_erase', parameters);
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    expect(await mapFile.readAsBytes(), beforeBytes);
    final applied = await host.apply(planned);
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final afterBytes = await mapFile.readAsBytes();
    final stale = await host.apply(stalePlan);
    expect(stale.status, AuthoringResultStatus.failure);
    expect(await mapFile.readAsBytes(), afterBytes);
    _expectSplit(
        fixture.map, MapData.fromJson(jsonDecode(utf8.decode(afterBytes))));
    final rejected = await host.plan(
        'border_layer.stroke_erase', {...parameters, 'featureId': 'unknown'});
    expect(rejected.status, AuthoringResultStatus.failure);
    expect(await mapFile.readAsBytes(), afterBytes);
    await host.command('close', {'projectHandle': host.project});
    final reopened =
        await host.command('open', {'projectRoot': host.root.path});
    expect(reopened.status, AuthoringResultStatus.success);
    expect(
        (await host.snapshots
                .load(ProjectHandle(reopened.data['projectHandle'] as String)))
            .maps
            .single,
        MapData.fromJson(jsonDecode(utf8.decode(afterBytes))));
    final history = await host.command('history',
        {'projectHandle': reopened.data['projectHandle'], 'limit': 10});
    final undo = await host.command('undo', {
      'projectHandle': reopened.data['projectHandle'],
      'entryId': (history.data['entries'] as List).first['entryId'],
      'idempotencyKey': 'erase-undo'
    });
    expect(undo.status, AuthoringResultStatus.success,
        reason: jsonEncode(undo.toJson()));
    expect(await mapFile.readAsBytes(), beforeBytes);
  });
}

Map<String, Object?> _parameters(List<GridPos> points) => {
      'mapId': 'map',
      'layerId': 'border',
      'featureId': 'fence',
      'points': points.map((point) => point.toJson()).toList()
    };

BorderFeature _feature(MapData map) =>
    (map.layers.single as BorderLayer).content.featureById('fence')!;

({ProjectManifest project, MapData map}) _fixture() {
  final fixture = spatialBorderAuthoringFixture(published: true);
  var map = fixture.map.copyWith(
      size: const GridSize(width: 10, height: 6),
      spatialScene: MapSpatialScene(
          width: 10, depth: 6, heightLevels: List.filled(60, 1)));
  map = updateBorderFeatureGeometry(map,
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderStrokeGeometry(strokes: [
        BorderStroke(
            id: 'line',
            points: [for (var x = 1; x <= 7; x++) GridPos(x: x, y: 1)],
            closed: false)
      ]));
  final resolved = resolveSpatialBorderFeature(
      manifest: fixture.project,
      map: map,
      layerId: 'border',
      featureId: 'fence');
  expect(resolved.result.canApply, true,
      reason: '${resolved.result.diagnostics.map((issue) => issue.code)}');
  map = applySpatialBorderFeaturePreview(map,
      manifest: fixture.project, proposedResult: resolved);
  map = map.copyWith(
      spatialScene: map.spatialScene!.copyWith(instances: [
    ...map.spatialScene!.instances,
    SpatialModelInstance(
        id: 'foreign',
        modelId: 'tree',
        position: Model3dVector3(x: 4.5, y: 2, z: 1.5))
  ]));
  return (project: fixture.project, map: map);
}

void _expectSplit(MapData before, MapData after) {
  final feature = _feature(after);
  final strokes = (feature.geometry as BorderStrokeGeometry).strokes;
  expect(strokes, hasLength(2));
  expect(strokes.map((stroke) => stroke.points.length), [3, 3]);
  expect(feature.generatedPlacementIds, hasLength(6));
  expect(
      after.spatialScene!.instances
          .lastWhere((instance) => instance.id == 'foreign'),
      before.spatialScene!.instances.last);
  for (final x in [1, 2, 6, 7]) {
    final previous = before.spatialScene!.instances
        .singleWhere((instance) => instance.position.x == x + .5);
    expect(
        after.spatialScene!.instances
            .singleWhere((instance) => instance.id == previous.id),
        previous);
  }
}

({ProjectManifest project, MapData map}) _planarFixture() {
  final defaults = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 0,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1);
  final primitives = [
    for (final role in [
      BorderPrimitiveRole.lineCap,
      BorderPrimitiveRole.lineStraight,
      BorderPrimitiveRole.lineCorner
    ])
      BorderPublishedPrimitive(
          id: role.name,
          sourceElementId: 'sprite',
          visualSnapshotId: 'border-snapshot-sha256:${'a' * 64}',
          role: role,
          weight: 1,
          anchorPx: const BorderPixelPos(x: 7, y: 7),
          transforms: BorderTransformPolicy(
              allowedQuarterTurns: const [0, 1, 2, 3], allowFlipX: true),
          publishedMetrics: BorderPrimitiveAssetMetrics(
              assetFingerprint: 'sprite',
              pixelSize: const GridSize(width: 16, height: 16),
              opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
              defaultAnchorPx: const BorderPixelPos(x: 7, y: 7),
              occupancyMaskRle: encodeBorderRleMask(List.filled(256, true))))
  ];
  final project = ProjectManifest(
      name: 'Planar border',
      maps: const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
      ],
      settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
      tilesets: const [
        ProjectTilesetEntry(
            id: 'atlas', name: 'Atlas', relativePath: 'atlas.png')
      ],
      elements: const [
        ProjectElementEntry(
            id: 'sprite',
            name: 'Sprite',
            tilesetId: 'atlas',
            categoryId: 'decor',
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 16))
            ])
      ],
      borderCatalog: ProjectBorderCatalog(formatVersion: 2, records: [
        BorderBlueprintRecord(
            id: 'fence',
            draft: BorderBlueprintDraft(
                baseRevision: 1,
                definition: BorderBlueprintDraftDefinition(
                    name: 'Fence',
                    previewSeed: BorderSignedInt64.zero,
                    template: BorderBlueprintTemplate.connectedLine,
                    primitives: const [],
                    defaults: defaults,
                    sortOrder: 0)),
            latestPublished: BorderBlueprintRevision(
                revision: 1,
                definition: BorderBlueprintPublishedDefinition(
                    name: 'Fence',
                    previewSeed: BorderSignedInt64.zero,
                    template: BorderBlueprintTemplate.connectedLine,
                    primitives: primitives,
                    defaults: defaults,
                    sortOrder: 0)))
      ], visualSnapshots: [
        BorderVisualSnapshot(
            id: 'border-snapshot-sha256:${'a' * 64}',
            contentFingerprint: 'a' * 64,
            frames: [
              BorderVisualFrameSnapshot(
                  relativeAssetPath: 'assets/borders/snapshots/${'a' * 64}.png',
                  sourceRectPx:
                      BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
                  durationMs: 100)
            ])
      ]));
  final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 10, height: 6),
      layers: [
        MapLayer.tile(
            id: 'foreign',
            name: 'Foreign',
            palette: const [
              TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0)
            ],
            cells: List.filled(60, 0)),
        MapLayer.border(
            id: 'border',
            name: 'Border',
            content: BorderLayerContent(formatVersion: 2, features: [
              BorderFeature(
                  id: 'fence',
                  name: 'Fence',
                  blueprintId: 'fence',
                  seed: BorderSignedInt64.fromInt(17),
                  overrides: const [],
                  keepOutRegions: const [],
                  geometry: BorderStrokeGeometry(strokes: [
                    BorderStroke(id: 'line', closed: false, points: [
                      for (var x = 1; x <= 7; x++) GridPos(x: x, y: 1)
                    ])
                  ]))
            ]))
      ]);
  return (project: project, map: map);
}
