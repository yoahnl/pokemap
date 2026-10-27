import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('model projection applies the same native context override as raster plans', () {
    var calls = 0;
    final projection = resolveSpatialSmartTileModelProjection(map: _map(), catalog: _catalog(),
      cellContextResolvers: {'floor': ({required preset, required x, required y}) {
        calls++;
        return const SmartTileCellContext();
      }});
    expect(calls, 3);
    expect(projection.instances, isEmpty);
    expect(projection.groundReplacements, isEmpty);
  });

  test('instance clip survives serialization and placement edits', () {
    final json =
        SpatialModelInstance(
            id: 'floor',
            modelId: 'carrier',
            position: Model3dVector3(x: 0, y: -.125, z: 0),
            blocksMovement: false,
          ).toJson()
          ..['clip'] = {
            'left': -1.0,
            'top': -2.0,
            'right': 0.0,
            'bottom': -1.0,
          };
    final instance = SpatialModelInstance.fromJson(json);
    expect(instance.toJson()['clip'], json['clip']);
    expect(
      instance.copyWith(rotationDegrees: 90).toJson()['clip'],
      json['clip'],
    );
    expect(SpatialModelInstance.fromJson(instance.toJson()), instance);
    expect(
      instance,
      isNot(SpatialModelInstance.fromJson({...json}..remove('clip'))),
    );
  });

  test('instance clip rejects malformed, non-finite and empty rectangles', () {
    final base = SpatialModelInstance(
      id: 'floor',
      modelId: 'carrier',
      position: Model3dVector3(x: 0, y: 0, z: 0),
      blocksMovement: false,
    ).toJson();
    for (final clip in [
      {'left': 0, 'top': 0, 'right': 0, 'bottom': 1},
      {'left': 0, 'top': 0, 'right': double.infinity, 'bottom': 1},
      {'left': 0, 'top': 0, 'right': 1, 'bottom': 1, 'extra': 1},
      [0, 0, 1, 1],
    ]) {
      expect(
        () => SpatialModelInstance.fromJson({...base, 'clip': clip}),
        throwsFormatException,
      );
    }
  });

  test(
    'clipped carriers use visible support when geometry origin is outside',
    () {
      final catalog = _catalog(offsetX: 20, offsetZ: 12);
      final projection = resolveSpatialSmartTileModelProjection(
        map: _map(),
        catalog: catalog,
      );
      expect(projection.instances, hasLength(2));
      final first = projection.instances.first;
      expect(first.position.x, 20.5);
      expect(first.position.z, 12.5);
      expect(first.position.y, 2 - .125);
      expect(first.toJson()['clip'], {
        'left': -20.5,
        'top': -12.5,
        'right': -19.5,
        'bottom': -11.5,
      });
      expect(projection.groundReplacements['floor'], {(0, 0), (2, 0)});
      expect(projection.cellOrigins[first.id]?.cell, const GridPos(x: 0, y: 0));
      expect(
        MapData.fromJson(
          projectSpatialSmartTileModels(map: _map(), catalog: catalog).toJson(),
        ).spatialScene!.instances,
        projection.instances,
      );
    },
  );

  test(
    'clipping support rotates with each quarter turn independently of geometry',
    () {
      for (var turn = 0; turn < 4; turn++) {
        final part = SmartTileVisualPart(
          source: const SmartTileVisualSource.model3d(
            modelId: 'carrier',
            offsetX: 10,
            offsetZ: 20,
            offsetY: -.125,
            scale: .75,
            replacesGround: true,
          ),
          transform: SmartTileSpriteTransform(quarterTurns: turn),
          spatialClip: SmartTileSpatialClip(
            left: 0,
            top: 0,
            right: 1,
            bottom: 1,
          ),
        );
        final instance = resolveSpatialSmartTileInstances(
          map: _map(),
          catalog: _catalog(part: part),
        ).first;
        final delta = [
          (10.0, 20.0),
          (-20.0, 10.0),
          (-10.0, -20.0),
          (20.0, -10.0),
        ][turn];
        expect(
          (instance.position.x, instance.position.z),
          (.5 + delta.$1, .5 + delta.$2),
        );
        expect(instance.rotationDegrees, -turn * 90);
        expect(instance.scale, .75);
        expect(instance.position.y, 1.875);
        expect(instance.toJson()['clip'], {
          'left': -10.5,
          'top': -20.5,
          'right': -9.5,
          'bottom': -19.5,
        });
      }
    },
  );

  test(
    'partial clips retain their own footprint without deleting underlying ground',
    () {
      final part = SmartTileVisualPart(
        source: const SmartTileVisualSource.model3d(
          modelId: 'carrier',
          offsetX: 10,
        ),
        footprintWidth: 3,
        footprintHeight: 5,
        spatialClip: SmartTileSpatialClip(
          left: .25,
          top: .2,
          right: .75,
          bottom: .8,
        ),
      );
      final map = _map().copyWith(
        size: const GridSize(width: 7, height: 7),
        spatialScene: MapSpatialScene(width: 7, depth: 7),
        layers: [
          (_map().layers.single as SmartTileLayer).copyWith(
            field: SmartTileField.cell(
              semanticCells: [1, ...List.filled(48, 0)],
            ),
          ),
        ],
      );
      final projection = resolveSpatialSmartTileModelProjection(
        map: map,
        catalog: _catalog(part: part),
      );
      expect(projection.groundReplacements, isEmpty);
      expect(projection.instances.first.toJson()['clip'], {
        'left': -10.75,
        'top': -1.5,
        'right': -9.25,
        'bottom': 1.5,
      });
    },
  );

  test('static model clips retain ground, understory and canopy placement', () {
    for (final channel in [
      SmartTileRenderChannel.ground,
      SmartTileRenderChannel.understory,
      SmartTileRenderChannel.canopy,
    ]) {
      final part = _part().copyWith(
        channel: channel,
        source: const SmartTileVisualSource.model3d(
          modelId: 'carrier',
          offsetX: 20,
          offsetZ: 12,
          offsetY: .375,
          followTerrain: false,
        ),
      );
      final catalog = _catalog(part: part);
      expect(_issues(catalog), isEmpty, reason: channel.name);
      final projection = resolveSpatialSmartTileModelProjection(
        map: _map(),
        catalog: catalog,
      );
      expect(projection.groundReplacements, isEmpty);
      expect(projection.instances.first.position.y, .375);
      expect(projection.instances.first.supportPosition.x, .5);
      expect(projection.instances.first.supportPosition.z, .5);
      expect(projection.instances.first.blocksMovement, isFalse);
      expect(projection.instances.first.clip, isNotNull);
      expect(ProjectSmartTileCatalog.fromJson(catalog.toJson()), catalog);
    }
  });

  test('model clips reject incompatible channels and animated visuals', () {
    expect(_issues(_catalog()), isEmpty);
    for (final part in [
      _part().copyWith(channel: SmartTileRenderChannel.foreground),
      _part().copyWith(channel: SmartTileRenderChannel.actorOcclusion),
      _part().copyWith(
        source: const SmartTileVisualSource.model3d(
          modelId: 'carrier',
          animationIndex: 0,
        ),
      ),
      _part().copyWith(transform: const SmartTileSpriteTransform(flipX: true)),
    ]) {
      expect(_issues(_catalog(part: part)), isNotEmpty);
      expect(
        () => resolveSpatialSmartTileInstances(
          map: _map(),
          catalog: _catalog(part: part),
        ),
        throwsFormatException,
      );
    }
  });

  test('clipped canopy and understory cannot replace ground', () {
    for (final channel in [
      SmartTileRenderChannel.understory,
      SmartTileRenderChannel.canopy,
    ]) {
      final catalog = _catalog(part: _part().copyWith(channel: channel));
      expect(
        _issues(catalog),
        contains('smart_tiles.model3d.ground_replacement_invalid'),
      );
      expect(
        () => resolveSpatialSmartTileInstances(map: _map(), catalog: catalog),
        throwsFormatException,
      );
    }
  });

  test('model clipping requires catalog format nine', () {
    final json = _catalog().toJson();
    expect(
      ProjectSmartTileCatalog.fromJson(Map<String, dynamic>.from(json)),
      _catalog(),
    );
    expect(
      () => ProjectSmartTileCatalog.fromJson({...json, 'formatVersion': 8}),
      throwsFormatException,
    );
  });

  test(
    'partial replacement clips and blocking clipped placements are rejected',
    () {
      final partial = _part().copyWith(
        spatialClip: SmartTileSpatialClip(
          left: 0,
          top: 0,
          right: .5,
          bottom: 1,
        ),
      );
      expect(
        _issues(_catalog(part: partial)),
        contains('smart_tiles.model3d.clip_replacement_invalid'),
      );
      expect(
        () => resolveSpatialSmartTileInstances(
          map: _map(),
          catalog: _catalog(part: partial),
        ),
        throwsFormatException,
      );
      final json = SpatialModelInstance(
        id: 'floor',
        modelId: 'carrier',
        position: Model3dVector3(x: 0, y: 0, z: 0),
      ).toJson()..['clip'] = {'left': 0, 'top': 0, 'right': 1, 'bottom': 1};
      expect(() => SpatialModelInstance.fromJson(json), throwsFormatException);
      expect(
        () => SpatialModelInstance.fromJson({
          ...json,
          'blocksMovement': false,
          'animationIndex': 0,
        }),
        throwsFormatException,
      );
    },
  );

  test('terrain edits reanchor clipped carriers at their visible support', () {
    final map = projectSpatialSmartTileModels(map: _map(), catalog: _catalog());
    final before = map.spatialScene!.instances.first;
    final after = const SpatialMapOperations().setLevels(map, const [
      SpatialCellLevel(x: 0, z: 0, level: 3),
    ]);
    final instance = after.spatialScene!.instances.first;
    expect(instance.position.y, before.position.y + 1);
    expect(instance.clip, before.clip);
    expect(instance.supportPosition.x, .5);
    expect(instance.supportPosition.z, .5);
    expect(
      after.spatialScene!.instances.last,
      map.spatialScene!.instances.last,
    );
  });

  test(
    'unclipped outside anchors still fail and erased cells do not materialize',
    () {
      final unclipped = _part().copyWith(spatialClip: null);
      expect(
        () => resolveSpatialSmartTileInstances(
          map: _map(),
          catalog: _catalog(part: unclipped),
        ),
        throwsFormatException,
      );
      final map = _map();
      final layer = map.layers.single as SmartTileLayer;
      final erased = map.copyWith(
        layers: [
          layer.copyWith(
            field: const SmartTileField.cell(semanticCells: [0, 0, 1]),
          ),
        ],
      );
      final instances = resolveSpatialSmartTileInstances(
        map: erased,
        catalog: _catalog(),
      );
      expect(instances, hasLength(1));
      expect(instances.single.position.x, 22.5);
    },
  );
}

SmartTileVisualPart _part({double offsetX = 20, double offsetZ = 12}) =>
    SmartTileVisualPart(
      source: SmartTileVisualSource.model3d(
        modelId: 'carrier',
        offsetX: offsetX,
        offsetZ: offsetZ,
        offsetY: -.125,
        replacesGround: true,
      ),
      spatialClip: SmartTileSpatialClip(left: 0, top: 0, right: 1, bottom: 1),
    );

ProjectSmartTileCatalog _catalog({
  SmartTileVisualPart? part,
  double offsetX = 20,
  double offsetZ = 12,
}) => ProjectSmartTileCatalog(
  materials: [
    ProjectSmartTileMaterial(
      id: 'floor',
      name: 'Floor',
      connectionGroupId: 'floor',
    ),
  ],
  presets: [
    ProjectSmartTilePreset(
      id: 'floor',
      name: 'Floor',
      usage: SmartTileUsage.terrain,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      topology: SmartTileTopology.uniform,
      defaultMaterialId: 'floor',
      templateHint: SmartTileTemplateHint.simple,
      allowedMaterialIds: ['floor'],
      rules: [
        SmartTileRule(
          id: 'floor',
          centerMatch: const SmartTileSlotMatch.material('floor'),
          candidates: [
            SmartTileCandidate(
              id: 'floor',
              parts: [part ?? _part(offsetX: offsetX, offsetZ: offsetZ)],
            ),
          ],
        ),
      ],
    ),
  ],
);

Iterable<String> _issues(ProjectSmartTileCatalog catalog) =>
    validateProjectSmartTileCatalog(
      catalog: catalog,
      projectTilesetIds: const [],
      projectModelIds: const ['carrier'],
      spatial: true,
    ).map((issue) => issue.code);

MapData _map() => MapData(
  id: 'room',
  name: 'Room',
  version: ProjectVersion.v9,
  size: const GridSize(width: 3, height: 1),
  spatialScene: MapSpatialScene(
    width: 3,
    depth: 1,
    heightLevels: [2, 0, 1],
    navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: .5)),
  ),
  layers: const [
    SmartTileLayer(
      id: 'floor',
      name: 'Floor',
      presetId: 'floor',
      usage: SmartTileUsage.terrain,
      materialPalette: ['', 'floor'],
      field: SmartTileField.cell(semanticCells: [1, 0, 1]),
    ),
  ],
);
