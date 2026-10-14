import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'spatial_border_resolution_test.dart' show spatialBorderFixture;

void main() {
  test(
    'complete cliff profiles replace only their visible applied footprints',
    () {
      final fixture = _fixture(replacesGround: true);
      expect(
        resolveSpatialBorderGroundReplacements(
          manifest: fixture.project,
          map: fixture.map,
        ),
        isEmpty,
      );
      final applied = applySpatialBorderFeaturePreview(
        fixture.map,
        manifest: fixture.project,
        proposedResult: _resolve(fixture.project, fixture.map),
      );
      final replacements = resolveSpatialBorderGroundReplacements(
        manifest: fixture.project,
        map: applied,
      );
      expect(replacements, hasLength(applied.spatialScene!.instances.length));
      final first = applied.spatialScene!.instances.first;
      expect(replacements.first.left, closeTo(first.position.x - .2, .000001));
      expect(replacements.first.right, closeTo(first.position.x + .2, .000001));
      expect(replacements.first.lowerHeight, 0.0);
      expect(replacements.first.upperHeight, 1.0);
      final removed = applied.copyWith(
        spatialScene: applied.spatialScene!.copyWith(instances: []),
      );
      expect(
        resolveSpatialBorderGroundReplacements(
          manifest: fixture.project,
          map: removed,
        ),
        isEmpty,
      );
      expect(
        resolveSpatialBorderGroundReplacements(
          manifest: _fixture().project,
          map: applied,
        ),
        isEmpty,
      );
      final reopened = MapData.fromJson(applied.toJson());
      final project = ProjectManifest.fromJson(fixture.project.toJson());
      expect(
        resolveSpatialBorderGroundReplacements(
          manifest: project,
          map: reopened,
        ),
        replacements,
      );
    },
  );

  test('publication fingerprints distinguish direction and corner shape', () {
    final fixture = _fixture();
    final raw = encodeBorderBlueprintRecordJson(
      fixture.project.borderCatalog.records.single,
      formatVersion: 5,
    );
    String fingerprint() => computeBorderPublicationCandidateFingerprint(
      blueprintId: 'fence',
      resolverVersion: borderResolverVersion,
      definition: decodeBorderBlueprintRecordJson(
        raw,
        formatVersion: 5,
      ).latestPublished!.definition,
    );
    final original = fingerprint();
    final definition = (raw['latestPublished'] as Map)['definition'] as Map;
    definition['followContourDirection'] = false;
    expect(fingerprint(), isNot(original));
    definition['followContourDirection'] = true;
    for (final primitive in (definition['primitives'] as List).cast<Map>()) {
      if (primitive['cornerTurn'] != null) {
        primitive['cornerTurn'] = primitive['cornerTurn'] == 'right'
            ? 'left'
            : 'right';
      }
    }
    expect(fingerprint(), isNot(original));
  });

  test('cliff contours select directed corners and face all four sides', () {
    final fixture = _fixture();
    final resolved = _resolve(fixture.project, fixture.map);
    expect(resolved.result.canApply, isTrue);
    final placements = resolved.result.materialization!.spatialPlacements;
    final corners = placements.where((p) => p.primitiveId.startsWith('corner'));
    expect(corners.map((p) => p.primitiveId).toSet(), {
      'corner-right',
      'corner-left',
    });
    final straights = placements.where((p) => p.primitiveId == 'lineStraight');
    final rotations = straights
        .map(
          (p) => resolved.modelInstances
              .singleWhere((instance) => instance.id == p.instanceId)
              .rotationDegrees,
        )
        .toSet();
    expect(rotations, {0.0, -90.0, -180.0, -270.0});
    final region =
        (fixture.map.layers.single as BorderLayer)
                .content
                .features
                .single
                .geometry
            as BorderRegionGeometry;
    final contours = extractCanonicalBorderRegionContours(
      region: region,
      tileSizePx: const GridSize(width: 1, height: 1),
    );
    for (final contour in contours) {
      for (var i = 0; i < contour.edges.length; i++) {
        final edge = contour.edges[i];
        final previous = contour
            .edges[(i + contour.edges.length - 1) % contour.edges.length];
        final instance = resolved.modelInstances.singleWhere(
          (instance) =>
              instance.position.x == edge.startVertex.x &&
              instance.position.z == edge.startVertex.y,
        );
        final placement = placements.singleWhere(
          (p) => p.instanceId == instance.id,
        );
        final turn =
            (borderCardinalDirectionV1Rank(edge.direction) -
                borderCardinalDirectionV1Rank(previous.direction) +
                4) %
            4;
        expect(
          placement.primitiveId,
          turn == 0
              ? 'lineStraight'
              : turn == 1
              ? 'corner-right'
              : 'corner-left',
        );
        expect(
          instance.rotationDegrees,
          -90.0 *
              borderCardinalDirectionV1Rank(
                turn == 0 ? edge.direction : previous.direction,
              ),
        );
      }
    }
  });

  test('cliff contours anchor their crowns to filled land height', () {
    final fixture = _fixture();
    final resolved = _resolve(fixture.project, fixture.map);
    expect(resolved.result.canApply, isTrue);
    expect(
      resolved.modelInstances.map((instance) => instance.position.y),
      everyElement(0.0),
    );
    final applied = applySpatialBorderFeaturePreview(
      fixture.map,
      manifest: fixture.project,
      proposedResult: resolved,
    );
    final reopened = MapData.fromJson(applied.toJson());
    final project = ProjectManifest.fromJson(fixture.project.toJson());
    expect(_resolve(project, reopened).modelInstances, resolved.modelInstances);
    expect(
      diagnoseSpatialBorderFeature(
        manifest: project,
        map: reopened,
        layerId: 'border',
        featureId: 'fence',
      ).hasErrors,
      isFalse,
    );
  });

  test('directed edge strokes anchor to the land on their right', () {
    final fixture = _fixture();
    final edges = [
      [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 1)],
      [for (var z = 1; z <= 4; z++) GridPos(x: 4, y: z)],
      [for (var x = 4; x >= 1; x--) GridPos(x: x, y: 4)],
      [for (var z = 4; z >= 1; z--) GridPos(x: 1, y: z)],
    ];
    final scene = fixture.map.spatialScene!.copyWith(
      heightLevels: [
        for (var z = 0; z < 6; z++)
          for (var x = 0; x < 6; x++)
            x >= 1 && x < 4 && z >= 1 && z < 4 ? 8 : 0,
      ],
    );
    for (var direction = 0; direction < edges.length; direction++) {
      final points = edges[direction];
      final map = updateBorderFeatureGeometry(
        fixture.map.copyWith(spatialScene: scene),
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          alignment: BorderStrokeAlignment.gridEdges,
          strokes: [BorderStroke(id: 'edge', points: points, closed: false)],
        ),
      );
      final resolved = _resolve(fixture.project, map);
      expect(resolved.result.canApply, isTrue);
      expect(resolved.modelInstances, hasLength(4));
      expect(
        resolved.modelInstances.map((instance) => instance.position.y),
        everyElement(0.0),
        reason: 'The crown must meet the upper land on each directed edge',
      );
      expect(
        resolved.modelInstances.map((instance) => instance.rotationDegrees),
        everyElement(-90.0 * direction),
        reason: 'Both cliff endpoints must keep the outside on the left',
      );
    }
  });

  test('directed cliff publication refuses a missing inside corner', () {
    final fixture = _fixture(includeLeft: false);
    final resolved = _resolve(fixture.project, fixture.map);
    expect(resolved.result.canApply, isFalse);
    expect(
      resolved.result.diagnostics.map((d) => d.code),
      contains('border.spatial.corner_turn_missing'),
    );
    expect(resolved.modelInstances, isEmpty);
  });

  test('directed cell-center cliffs use upper land on all four sides', () {
    final fixture = _fixture();
    final scene = fixture.map.spatialScene!.copyWith(
      heightLevels: [
        for (var z = 0; z < 6; z++)
          for (var x = 0; x < 6; x++)
            x >= 1 && x <= 3 && z >= 1 && z <= 3 ? 8 : 0,
      ],
    );
    final edges = [
      [for (var x = 1; x <= 3; x++) GridPos(x: x, y: 0)],
      [for (var z = 1; z <= 3; z++) GridPos(x: 4, y: z)],
      [for (var x = 3; x >= 1; x--) GridPos(x: x, y: 4)],
      [for (var z = 3; z >= 1; z--) GridPos(x: 0, y: z)],
    ];
    for (var direction = 0; direction < edges.length; direction++) {
      final map = updateBorderFeatureGeometry(
        fixture.map.copyWith(spatialScene: scene),
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(id: 'crown', points: edges[direction], closed: false),
          ],
        ),
      );
      final result = _resolve(fixture.project, map);
      expect(result.result.canApply, isTrue);
      expect(result.modelInstances, hasLength(3));
      expect(
        result.modelInstances.map((instance) => instance.position.y),
        everyElement(0.0),
        reason: 'The authored crown meets upper land beside the cliff cell',
      );
      expect(
        result.modelInstances.map((instance) => instance.rotationDegrees),
        everyElement(-90.0 * direction),
      );
    }
  });

  test('directed cell-center corners use their inside land quadrant', () {
    final fixture = _fixture();
    final cases = [
      (
        points: [
          const GridPos(x: 1, y: 1),
          const GridPos(x: 2, y: 1),
          const GridPos(x: 3, y: 1),
          const GridPos(x: 3, y: 2),
          const GridPos(x: 3, y: 3),
        ],
        land: {(1, 2), (2, 2), (2, 3)},
        corner: const GridPos(x: 3, y: 1),
        primitiveId: 'corner-right',
      ),
      (
        points: [
          const GridPos(x: 3, y: 3),
          const GridPos(x: 3, y: 2),
          const GridPos(x: 3, y: 1),
          const GridPos(x: 2, y: 1),
          const GridPos(x: 1, y: 1),
        ],
        land: {(4, 3), (4, 2), (4, 0), (2, 0), (1, 0)},
        corner: const GridPos(x: 3, y: 1),
        primitiveId: 'corner-left',
      ),
    ];
    for (final example in cases) {
      final map = updateBorderFeatureGeometry(
        fixture.map.copyWith(
          spatialScene: fixture.map.spatialScene!.copyWith(
            heightLevels: [
              for (var z = 0; z < 6; z++)
                for (var x = 0; x < 6; x++)
                  example.land.contains((x, z)) ? 8 : 0,
            ],
          ),
        ),
        layerId: 'border',
        featureId: 'fence',
        geometry: BorderStrokeGeometry(
          strokes: [
            BorderStroke(id: 'corner', points: example.points, closed: false),
          ],
        ),
      );
      final resolved = _resolve(fixture.project, map);
      expect(resolved.result.canApply, isTrue);
      expect(
        resolved.modelInstances.map((instance) => instance.position.y),
        everyElement(0.0),
      );
      final instance = resolved.modelInstances.singleWhere(
        (instance) =>
            instance.position.x == example.corner.x + .5 &&
            instance.position.z == example.corner.y + .5,
      );
      expect(
        resolved.result.materialization!.spatialPlacements
            .singleWhere((placement) => placement.instanceId == instance.id)
            .primitiveId,
        example.primitiveId,
      );
      final applied = applySpatialBorderFeaturePreview(
        map,
        manifest: fixture.project,
        proposedResult: resolved,
      );
      final reopened = MapData.fromJson(applied.toJson());
      expect(
        _resolve(fixture.project, reopened).modelInstances,
        resolved.modelInstances,
      );
    }
  });

  test('ordinary cell-center borders retain their own ground anchor', () {
    final fixture = spatialBorderFixture();
    final map = updateBorderFeatureGeometry(
      fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!.copyWith(
          heightLevels: [
            for (var z = 0; z < fixture.map.size.height; z++)
              for (var x = 0; x < fixture.map.size.width; x++) z == 2 ? 8 : 0,
          ],
        ),
      ),
      layerId: 'border',
      featureId: 'fence',
      geometry: BorderStrokeGeometry(
        strokes: [
          BorderStroke(
            id: 'ordinary',
            points: [
              const GridPos(x: 1, y: 1),
              const GridPos(x: 2, y: 1),
              const GridPos(x: 3, y: 1),
            ],
            closed: false,
          ),
        ],
      ),
    );
    final result = _resolve(fixture.project, map);
    expect(result.result.canApply, isTrue);
    expect(
      result.modelInstances.map((instance) => instance.position.y),
      everyElement(0.0),
    );
  });
}

SpatialBorderResolutionResult _resolve(ProjectManifest manifest, MapData map) =>
    resolveSpatialBorderFeature(
      manifest: manifest,
      map: map,
      layerId: 'border',
      featureId: 'fence',
    );

({ProjectManifest project, MapData map}) _fixture({
  bool includeLeft = true,
  bool replacesGround = false,
}) {
  final fixture = spatialBorderFixture();
  final raw = encodeBorderBlueprintRecordJson(
    fixture.project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    definition['replacesGround'] = replacesGround;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['authoredOrientation'] = 'east';
      primitive['anchorWorld'] = {'x': 0.0, 'y': 2.0, 'z': 0.0};
    }
    final corner = Map<String, Object?>.from(
      primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map,
    );
    primitives.removeWhere((p) => p['role'] == 'lineCorner');
    primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
    if (includeLeft) {
      primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
    }
  }
  final project = fixture.project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
    ),
  );
  final cells = [
    for (var z = 0; z < 6; z++)
      for (var x = 0; x < 6; x++)
        x >= 1 && x <= 4 && z >= 1 && z <= 4 && !(x == 2 && z == 2),
  ];
  final map = updateBorderFeatureGeometry(
    fixture.map.copyWith(
      spatialScene: MapSpatialScene(
        width: 6,
        depth: 6,
        levelHeight: .25,
        heightLevels: cells.map((cell) => cell ? 8 : 0).toList(),
      ),
    ),
    layerId: 'border',
    featureId: 'fence',
    geometry: BorderRegionGeometry(width: 6, height: 6, cells: cells),
  );
  return (project: project, map: map);
}
