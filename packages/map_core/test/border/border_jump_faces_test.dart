import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('preserved traversal retains all four grid-edge normals', () {
    for (final (points, normal, carriers) in [
      (
        [GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)],
        BorderCardinalDirection.south,
        {GridPos(x: 2, y: 3), GridPos(x: 2, y: 2)},
      ),
      (
        [GridPos(x: 3, y: 2), GridPos(x: 3, y: 3)],
        BorderCardinalDirection.west,
        {GridPos(x: 2, y: 2), GridPos(x: 3, y: 2)},
      ),
      (
        [GridPos(x: 3, y: 3), GridPos(x: 2, y: 3)],
        BorderCardinalDirection.north,
        {GridPos(x: 2, y: 2), GridPos(x: 2, y: 3)},
      ),
      (
        [GridPos(x: 3, y: 3), GridPos(x: 3, y: 2)],
        BorderCardinalDirection.east,
        {GridPos(x: 3, y: 2), GridPos(x: 2, y: 2)},
      ),
    ]) {
      final stroke = BorderStroke(
        id: buildBorderPreservedStrokeIdV1(
          authoredStrokeId: 'line',
          sourceEdgeOffset: 0,
          wrapLength: null,
          orderedPoints: points,
        ),
        points: points,
        closed: false,
      );
      final geometry = BorderStrokeGeometry(
        strokes: [stroke],
        alignment: BorderStrokeAlignment.gridEdges,
      );
      final primary = deriveBorderJumpFaceCandidates(_request(geometry)).single;
      final inverted = deriveBorderJumpFaceCandidates(
        _request(geometry, jumpSide: BorderLineSide.inverted),
      ).single;
      expect(primary.topologicalNormal, normal);
      expect(primary.potentialCarrierCells.toSet(), carriers);
      expect(inverted.potentialCarrierCells, primary.potentialCarrierCells);
      expect(inverted.startWorldPx, primary.startWorldPx);
      expect(inverted.endWorldPx, primary.endWorldPx);
      expect(inverted.key, primary.key);
      expect(inverted.topologicalNormal, isNot(normal));
    }
  });

  test('a map boundary filters carriers without moving the physical edge', () {
    final geometry = _stroke([
      GridPos(x: 2, y: 0),
      GridPos(x: 3, y: 0),
    ], gridEdges: true);
    final face = deriveBorderJumpFaceCandidates(
      _request(
        geometry,
        mapSize: const GridSize(width: 3, height: 2),
        tileSize: const GridSize(width: 31, height: 17),
      ),
    ).single;
    expect(face.startWorldPx, const BorderPixelPos(x: 62, y: 0));
    expect(face.endWorldPx, const BorderPixelPos(x: 93, y: 0));
    expect(face.potentialCarrierCells, [GridPos(x: 2, y: 0)]);
  });

  test('odd rectangular cells retain exact full-cell cap intervals', () {
    final geometry = _stroke([GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)]);
    final faces = deriveBorderJumpFaceCandidates(
      _request(geometry, tileSize: const GridSize(width: 31, height: 17)),
    );
    expect(faces.first.startWorldPx, const BorderPixelPos(x: 62, y: 59));
    expect(faces.first.endWorldPx, const BorderPixelPos(x: 93, y: 59));
    expect(faces.last.startWorldPx, const BorderPixelPos(x: 93, y: 59));
    expect(faces.last.endWorldPx, const BorderPixelPos(x: 124, y: 59));
    expect(() => faces.clear(), throwsUnsupportedError);
    expect(
      () => faces.first.potentialCarrierCells.clear(),
      throwsUnsupportedError,
    );
  });

  test(
    'inverting a region changes direction while retaining its carrier and edge',
    () {
      final region = _region((x, y) => x >= 2 && x <= 5 && y >= 2 && y <= 5);
      final primary = deriveBorderJumpFaceCandidates(_request(region));
      final inverted = deriveBorderJumpFaceCandidates(
        _request(region, jumpSide: BorderLineSide.inverted),
      );
      expect(inverted.map((face) => face.key), primary.map((face) => face.key));
      for (var index = 0; index < primary.length; index++) {
        expect(
          inverted[index].potentialCarrierCells,
          primary[index].potentialCarrierCells,
        );
        expect(inverted[index].startWorldPx, primary[index].startWorldPx);
        expect(inverted[index].endWorldPx, primary[index].endWorldPx);
        expect(
          inverted[index].topologicalNormal,
          isNot(primary[index].topologicalNormal),
        );
      }
    },
  );

  test(
    'unsupported templates, spatial blueprints and nonportable canvases are refused',
    () {
      final stroke = _stroke([GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)]);
      for (final request in [
        _request(stroke, template: BorderBlueprintTemplate.organicEdge),
        _request(stroke, template: BorderBlueprintTemplate.stoneChainLine),
        _request(
          _region((x, y) => x == 3 && y == 3),
          template: BorderBlueprintTemplate.masonryLine,
        ),
        _request(
          _region((x, y) => x == 3 && y == 3),
          featureSide: BorderLineSide.inverted,
        ),
        _request(stroke, spatial: true),
        _request(
          stroke,
          mapSize: const GridSize(width: 9007199254740991, height: 12),
          tileSize: const GridSize(width: 2, height: 32),
        ),
      ]) {
        expect(
          () => deriveBorderJumpFaceCandidates(request),
          throwsA(isA<ValidationException>()),
        );
      }
    },
  );

  test(
    'straight cell strokes preserve a unique normal and inherit it at caps',
    () {
      final points = [
        GridPos(x: 2, y: 3),
        GridPos(x: 3, y: 3),
        GridPos(x: 4, y: 3),
      ];
      final forward = deriveBorderJumpFaceCandidates(_request(_stroke(points)));
      final reverse = deriveBorderJumpFaceCandidates(
        _request(_stroke(points.reversed.toList())),
      );
      expect(forward, hasLength(3));
      expect(forward.map((face) => face.topologicalNormal).toSet(), {
        BorderCardinalDirection.south,
      });
      expect(forward.map((face) => face.potentialCarrierCells.single), points);
      expect(forward.map((face) => face.key), reverse.map((face) => face.key));
      expect(
        forward.map((face) => face.topologicalNormal),
        reverse.map((face) => face.topologicalNormal),
      );
    },
  );

  test(
    'jump side composes with the feature side without changing the carrier',
    () {
      final geometry = _stroke([GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)]);
      for (final (featureSide, jumpSide, expected) in [
        (
          BorderLineSide.primary,
          BorderLineSide.primary,
          BorderCardinalDirection.south,
        ),
        (
          BorderLineSide.inverted,
          BorderLineSide.primary,
          BorderCardinalDirection.north,
        ),
        (
          BorderLineSide.primary,
          BorderLineSide.inverted,
          BorderCardinalDirection.north,
        ),
        (
          BorderLineSide.inverted,
          BorderLineSide.inverted,
          BorderCardinalDirection.south,
        ),
      ]) {
        final faces = deriveBorderJumpFaceCandidates(
          _request(geometry, featureSide: featureSide, jumpSide: jumpSide),
        );
        expect(faces, hasLength(2));
        expect(faces.map((face) => face.topologicalNormal).toSet(), {expected});
        expect(faces.map((face) => face.potentialCarrierCells.single), [
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
        ]);
      }
    },
  );

  test('a turn never invents a diagonal or chooses one competing normal', () {
    final faces = deriveBorderJumpFaceCandidates(
      _request(
        _stroke([
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 3, y: 4),
          GridPos(x: 3, y: 5),
        ]),
      ),
    );
    expect(faces, hasLength(3));
    expect(
      faces.expand((face) => face.potentialCarrierCells),
      isNot(contains(GridPos(x: 3, y: 3))),
    );
    expect(faces.last.topologicalNormal, BorderCardinalDirection.west);
  });

  test(
    'one grid edge preserves its physical line and both potential carriers',
    () {
      final horizontal = _stroke([
        GridPos(x: 2, y: 3),
        GridPos(x: 3, y: 3),
      ], gridEdges: true);
      final vertical = _stroke([
        GridPos(x: 3, y: 2),
        GridPos(x: 3, y: 3),
      ], gridEdges: true);
      for (final (geometry, side, normal) in [
        (horizontal, BorderLineSide.primary, BorderCardinalDirection.south),
        (horizontal, BorderLineSide.inverted, BorderCardinalDirection.north),
        (vertical, BorderLineSide.primary, BorderCardinalDirection.west),
        (vertical, BorderLineSide.inverted, BorderCardinalDirection.east),
      ]) {
        final face = deriveBorderJumpFaceCandidates(
          _request(geometry, jumpSide: side),
        ).single;
        expect(face.kind, BorderJumpFaceKind.gridEdge);
        expect(face.topologicalNormal, normal);
        expect(face.potentialCarrierCells, hasLength(2));
        final p = geometry.strokes.single.points;
        expect(
          face.startWorldPx,
          BorderPixelPos(x: p.first.x * 32, y: p.first.y * 32),
        );
        expect(
          face.endWorldPx,
          BorderPixelPos(x: p.last.x * 32, y: p.last.y * 32),
        );
      }
      expect(
        deriveBorderJumpFaceCandidates(
          _request(horizontal),
        ).single.potentialCarrierCells.toSet(),
        {GridPos(x: 2, y: 2), GridPos(x: 2, y: 3)},
      );
    },
  );

  test(
    'region faces keep the barrier cell and refuse convex corner ambiguity',
    () {
      final faces = deriveBorderJumpFaceCandidates(
        _request(_region((x, y) => x >= 2 && x <= 5 && y >= 2 && y <= 5)),
      );
      expect(faces, hasLength(8));
      expect(
        faces.expand((face) => face.potentialCarrierCells),
        isNot(contains(GridPos(x: 2, y: 2))),
      );
      final top = faces.singleWhere(
        (face) => face.potentialCarrierCells.single == GridPos(x: 3, y: 2),
      );
      expect(top.topologicalNormal, BorderCardinalDirection.north);
      expect(top.startWorldPx.y, 64);
      expect(top.endWorldPx.y, 64);
    },
  );

  test('the normal of a hole points into the original empty region', () {
    final geometry = _region(
      (x, y) =>
          x >= 2 &&
          x <= 8 &&
          y >= 2 &&
          y <= 8 &&
          !(x >= 4 && x <= 6 && y >= 4 && y <= 6),
    );
    final faces = deriveBorderJumpFaceCandidates(_request(geometry));
    final holeTop = faces.singleWhere(
      (face) => face.potentialCarrierCells.single == GridPos(x: 5, y: 3),
    );
    expect(holeTop.topologicalNormal, BorderCardinalDirection.south);
    expect(holeTop.startWorldPx.y, 128);
    expect(holeTop.endWorldPx.y, 128);
  });

  test(
    'a one-cell region or thin strip never becomes four inferred ledges',
    () {
      for (final geometry in [
        _region((x, y) => x == 3 && y == 3),
        _region((x, y) => x >= 3 && x <= 5 && y == 3),
      ]) {
        expect(deriveBorderJumpFaceCandidates(_request(geometry)), isEmpty);
      }
    },
  );

  test('ordinary Borders have no jump faces', () {
    expect(
      deriveBorderJumpFaceCandidates(
        _request(
          _stroke([GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)]),
          enabled: false,
        ),
      ),
      isEmpty,
    );
  });

  test('invalid map geometry and missing publication cannot imply a jump', () {
    final outside = _stroke([GridPos(x: -1, y: 3), GridPos(x: 0, y: 3)]);
    expect(
      () => deriveBorderJumpFaceCandidates(_request(outside)),
      throwsA(isA<ValidationException>()),
    );
    final mismatch = BorderRegionGeometry(width: 1, height: 1, cells: [true]);
    expect(
      () => deriveBorderJumpFaceCandidates(_request(mismatch)),
      throwsA(isA<ValidationException>()),
    );
    final request = _request(
      _stroke([GridPos(x: 2, y: 3), GridPos(x: 3, y: 3)]),
    );
    expect(
      () => deriveBorderJumpFaceCandidates(
        BorderResolutionRequest(
          mapSize: request.mapSize,
          tileSizePx: request.tileSizePx,
          blueprintId: request.blueprintId,
          blueprintRevision: null,
          feature: request.feature,
          visualSnapshots: [],
          resolverVersion: borderResolverVersion,
        ),
      ),
      throwsA(isA<ValidationException>()),
    );
  });
}

BorderStrokeGeometry _stroke(List<GridPos> points, {bool gridEdges = false}) =>
    BorderStrokeGeometry(
      strokes: [BorderStroke(id: 'line', points: points, closed: false)],
      alignment: gridEdges
          ? BorderStrokeAlignment.gridEdges
          : BorderStrokeAlignment.cellCenters,
    );

BorderRegionGeometry _region(bool Function(int, int) filled) =>
    BorderRegionGeometry(
      width: 12,
      height: 12,
      cells: [
        for (var y = 0; y < 12; y++)
          for (var x = 0; x < 12; x++) filled(x, y),
      ],
    );

BorderResolutionRequest _request(
  BorderFeatureGeometry geometry, {
  BorderLineSide featureSide = BorderLineSide.primary,
  BorderLineSide jumpSide = BorderLineSide.primary,
  bool enabled = true,
  GridSize mapSize = const GridSize(width: 12, height: 12),
  GridSize tileSize = const GridSize(width: 32, height: 32),
  BorderBlueprintTemplate? template,
  bool spatial = false,
}) => BorderResolutionRequest(
  mapSize: mapSize,
  tileSizePx: tileSize,
  blueprintId: 'ledge',
  blueprintRevision: BorderBlueprintRevision(
    revision: 1,
    definition: BorderBlueprintPublishedDefinition(
      name: 'Ledge',
      previewSeed: BorderSignedInt64.zero,
      template:
          template ??
          (geometry is BorderRegionGeometry
              ? BorderBlueprintTemplate.organicEdge
              : (geometry as BorderStrokeGeometry).alignment ==
                    BorderStrokeAlignment.gridEdges
              ? BorderBlueprintTemplate.stoneChainLine
              : BorderBlueprintTemplate.masonryLine),
      primitives: spatial
          ? [
              BorderPublishedPrimitive(
                id: 'model',
                sourceModelId: 'model',
                role: BorderPrimitiveRole.structureLarge,
                weight: 1,
                transforms: BorderTransformPolicy(
                  allowFlipX: false,
                  allowedQuarterTurns: [0],
                ),
              ),
            ]
          : [],
      defaults: BorderGenerationParams(
        irregularityPermille: 0,
        detailDensityPermille: 0,
        variationPermille: 0,
        maxOverlapPx: 0,
        gapTolerancePx: 0,
        depthRows: 1,
      ),
      sortOrder: 0,
      jumpBehavior: enabled ? BorderJumpBehavior(side: jumpSide) : null,
    ),
  ),
  feature: BorderFeature(
    id: 'ledge',
    name: 'Ledge',
    blueprintId: 'ledge',
    seed: BorderSignedInt64.zero,
    geometry: geometry,
    lineSide: featureSide,
    overrides: [],
    keepOutRegions: [],
  ),
  visualSnapshots: [],
  resolverVersion: borderResolverVersion,
);
