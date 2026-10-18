import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_inspection.dart';
import '../../../../map_core/test/fixtures/border/two_tier_stone_chain_fixture.dart';

const twoTierStoneChainVisualMapSize = GridSize(width: 16, height: 12);
const twoTierStoneChainVisualTileSizePx = 32;

final class SyntheticBorderInspectionCase {
  SyntheticBorderInspectionCase({
    required this.id,
    required this.geometryId,
    required Iterable<GridPos> points,
    required Iterable<GridPos> turnVertices,
    required this.closed,
    this.lineSide = BorderLineSide.primary,
    this.rotationEnabled = false,
  }) : points = List<GridPos>.unmodifiable(points),
       turnVertices = List<GridPos>.unmodifiable(turnVertices);

  final String id;
  final String geometryId;
  final List<GridPos> points;
  final List<GridPos> turnVertices;
  final bool closed;
  final BorderLineSide lineSide;
  final bool rotationEnabled;

  int get edgeCount => closed ? points.length : points.length - 1;
}

final class SyntheticBorderInspectionResolution {
  SyntheticBorderInspectionResolution({
    required this.visualCase,
    required this.request,
    required this.evidence,
    required this.parameters,
    required Map<String, BorderPublishedPrimitive> primitivesById,
  }) : primitivesById = Map<String, BorderPublishedPrimitive>.unmodifiable(
         primitivesById,
       );

  final SyntheticBorderInspectionCase visualCase;
  final BorderResolutionRequest request;
  final StoneChainLineBorderResolutionEvidence evidence;
  final BorderGenerationParams parameters;
  final Map<String, BorderPublishedPrimitive> primitivesById;

  BorderFeature get feature => request.feature;

  String get diagnostics => evidence.result.diagnostics
      .map((item) => '${item.severity.name}:${item.code} ${item.parameters}')
      .join(', ');

  List<BorderResolvedPlacement> get placements =>
      evidence.result.materialization?.placements ??
      const <BorderResolvedPlacement>[];

  List<BorderResolvedPlacement> get lipPlacements =>
      _placementsWithRole(BorderPrimitiveRole.structureLarge);

  List<BorderResolvedPlacement> get facePlacements =>
      _placementsWithRole(BorderPrimitiveRole.structureMedium);

  String nodeSlotKey({
    required GridPos vertex,
    required int passIndex,
    required BorderPrimitiveRole role,
    required int rank,
  }) => buildBorderStoneChainNodeSlotKey(
    featureId: feature.id,
    strokeId: borderStrokeLineageNamespaceV1(
      (feature.geometry as BorderStrokeGeometry).strokes.single.id,
    ),
    vertex: vertex,
    passIndex: passIndex,
    role: role,
    rank: rank,
  );

  BorderFeature get materializedFeature {
    final materialization = evidence.result.materialization;
    if (materialization == null) {
      throw StateError('${visualCase.id} is not materialized: $diagnostics');
    }
    final source = feature;
    return BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      lineSide: source.lineSide,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization,
    );
  }

  List<BorderResolvedPlacement> _placementsWithRole(BorderPrimitiveRole role) =>
      placements
          .where(
            (placement) => primitivesById[placement.primitiveId]?.role == role,
          )
          .toList(growable: false);
}

final class SyntheticBorderInspectionFixture {
  SyntheticBorderInspectionFixture._() {
    final fixture = TwoTierStoneChainFixture(irregularityPermille: 180);
    manifest = _projectForTwoTierFixture(fixture);
    blueprintId = fixture.request.blueprintId;
    publishedRevision = fixture.blueprintRevision;
    primitivesById = {
      for (final primitive in fixture.primitives) primitive.id: primitive,
    };
    cases = _visualCases();
  }

  static Future<SyntheticBorderInspectionFixture> load() async =>
      SyntheticBorderInspectionFixture._();
  late final ProjectManifest manifest;
  late final String blueprintId;
  late final BorderBlueprintRevision publishedRevision;
  late final Map<String, BorderPublishedPrimitive> primitivesById;
  late final List<SyntheticBorderInspectionCase> cases;
  void dispose() {}
  SyntheticBorderInspectionResolution resolve(
    SyntheticBorderInspectionCase visualCase,
  ) {
    final defaults = publishedRevision.definition.defaults;
    final parameters = BorderGenerationParams(
      irregularityPermille: defaults.irregularityPermille,
      detailDensityPermille: defaults.detailDensityPermille,
      variationPermille: defaults.variationPermille,
      maxOverlapPx: defaults.maxOverlapPx,
      gapTolerancePx: defaults.gapTolerancePx,
      depthRows: defaults.depthRows,
      allowAutoRotation: visualCase.rotationEnabled,
    );
    final feature = BorderFeature(
      id: 'two-tier-stone-chain-visual-${visualCase.geometryId}',
      name: visualCase.id,
      blueprintId: blueprintId,
      seed: publishedRevision.definition.previewSeed,
      geometry: BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'two-tier-stone-chain-${visualCase.geometryId}',
            points: visualCase.points,
            closed: visualCase.closed,
          ),
        ],
        alignment: BorderStrokeAlignment.gridEdges,
      ),
      lineSide: visualCase.lineSide,
      paramsOverride: parameters,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
    final request = BorderResolutionRequest(
      mapSize: twoTierStoneChainVisualMapSize,
      tileSizePx: const GridSize(
        width: twoTierStoneChainVisualTileSizePx,
        height: twoTierStoneChainVisualTileSizePx,
      ),
      blueprintId: blueprintId,
      blueprintRevision: publishedRevision,
      feature: feature,
      visualSnapshots: manifest.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    );
    return SyntheticBorderInspectionResolution(
      visualCase: visualCase,
      request: request,
      evidence: resolveStoneChainLineBorderWithEvidence(request),
      parameters: parameters,
      primitivesById: primitivesById,
    );
  }

  BorderCanonicalGalleryResult resolveCanonicalGallery() =>
      resolveBorderCanonicalGallery(
        blueprintId: blueprintId,
        blueprintRevision: publishedRevision,
        visualSnapshots: manifest.borderCatalog.visualSnapshots,
        tileSizePx: const GridSize(
          width: twoTierStoneChainVisualTileSizePx,
          height: twoTierStoneChainVisualTileSizePx,
        ),
      );

  Map<String, Object?> inspect(SyntheticBorderInspectionResolution resolution) {
    final map = mapFor(resolution);
    return inspectBorderFeature(
      map: map,
      project: manifest,
      layerId: 'two-tier-stone-chain-visual-layer',
      featureId: resolution.feature.id,
    );
  }

  MapData mapFor(SyntheticBorderInspectionResolution resolution) {
    final layer =
        MapLayer.border(
              id: 'two-tier-stone-chain-visual-layer',
              name: 'Two-tier stone chain visual bench',
              content: BorderLayerContent(
                formatVersion: BorderLayerContent.formatVersionV3,
                features: <BorderFeature>[resolution.materializedFeature],
              ),
            )
            as BorderLayer;
    return MapData(
      id: 'two-tier-stone-chain-visual-${resolution.visualCase.id}',
      name: resolution.visualCase.id,
      version: ProjectVersion.v8,
      size: twoTierStoneChainVisualMapSize,
      properties: const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[layer],
    );
  }
}

List<SyntheticBorderInspectionCase> _visualCases() {
  final horizontal = <GridPos>[
    for (var x = 2; x <= 13; x += 1) GridPos(x: x, y: 6),
  ];
  final vertical = <GridPos>[
    for (var y = 1; y <= 10; y += 1) GridPos(x: 8, y: y),
  ];
  final l = <GridPos>[
    for (var x = 2; x <= 10; x += 1) GridPos(x: x, y: 2),
    for (var y = 3; y <= 9; y += 1) GridPos(x: 10, y: y),
  ];
  final s = <GridPos>[
    for (var x = 2; x <= 7; x += 1) GridPos(x: x, y: 2),
    for (var y = 3; y <= 7; y += 1) GridPos(x: 7, y: y),
    for (var x = 8; x <= 13; x += 1) GridPos(x: x, y: 7),
  ];
  final loop = <GridPos>[
    for (var x = 4; x <= 11; x += 1) GridPos(x: x, y: 3),
    for (var y = 4; y <= 8; y += 1) GridPos(x: 11, y: y),
    for (var x = 10; x >= 4; x -= 1) GridPos(x: x, y: 8),
    for (var y = 7; y >= 4; y -= 1) GridPos(x: 4, y: y),
  ];
  final zigzag = <GridPos>[
    for (var x = 3; x <= 7; x += 1) GridPos(x: x, y: 5),
    const GridPos(x: 7, y: 6),
    const GridPos(x: 8, y: 6),
    const GridPos(x: 8, y: 7),
    for (var x = 9; x <= 13; x += 1) GridPos(x: x, y: 7),
  ];
  return <SyntheticBorderInspectionCase>[
    SyntheticBorderInspectionCase(
      id: 'horizontal_primary',
      geometryId: 'horizontal-primary',
      points: horizontal,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 'vertical_primary',
      geometryId: 'vertical-primary',
      points: vertical,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 'l_convex_primary',
      geometryId: 'l-shape',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 'l_concave_inverted',
      geometryId: 'l-shape',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    SyntheticBorderInspectionCase(
      id: 's_primary',
      geometryId: 's-shape',
      points: s,
      turnVertices: const <GridPos>[GridPos(x: 7, y: 2), GridPos(x: 7, y: 7)],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 's_inverted',
      geometryId: 's-shape',
      points: s,
      turnVertices: const <GridPos>[GridPos(x: 7, y: 2), GridPos(x: 7, y: 7)],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    SyntheticBorderInspectionCase(
      id: 'closed_loop',
      geometryId: 'closed-loop',
      points: loop,
      turnVertices: const <GridPos>[
        GridPos(x: 4, y: 3),
        GridPos(x: 11, y: 3),
        GridPos(x: 11, y: 8),
        GridPos(x: 4, y: 8),
      ],
      closed: true,
    ),
    SyntheticBorderInspectionCase(
      id: 'one_cell_zigzag',
      geometryId: 'one-cell-zigzag',
      points: zigzag,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 5),
        GridPos(x: 7, y: 6),
        GridPos(x: 8, y: 6),
        GridPos(x: 8, y: 7),
      ],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 'rotation_off',
      geometryId: 'rotation-probe',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
    ),
    SyntheticBorderInspectionCase(
      id: 'rotation_on',
      geometryId: 'rotation-probe',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      rotationEnabled: true,
    ),
  ];
}

ProjectManifest _projectForTwoTierFixture(TwoTierStoneChainFixture fixture) {
  final published = fixture.blueprintRevision.definition;
  return ProjectManifest(
    name: 'Two-tier inspection project',
    version: ProjectVersion.v8,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.formatVersionV4,
      records: <BorderBlueprintRecord>[
        BorderBlueprintRecord(
          id: fixture.request.blueprintId,
          draft: BorderBlueprintDraft(
            baseRevision: fixture.blueprintRevision.revision,
            definition: BorderBlueprintDraftDefinition(
              name: published.name,
              previewSeed: published.previewSeed,
              template: published.template,
              primitives: <BorderPrimitiveDraft>[
                for (final primitive in published.primitives)
                  BorderPrimitiveDraft(
                    id: primitive.id,
                    sourceElementId: primitive.sourceElementId,
                    role: primitive.role,
                    authoredOrientation: primitive.authoredOrientation,
                    weight: primitive.weight,
                    anchorPx: primitive.anchorPx,
                    transforms: primitive.transforms,
                    currentMetrics: primitive.publishedMetrics,
                  ),
              ],
              defaults: published.defaults,
              ground: null,
              categoryId: published.categoryId,
              sortOrder: published.sortOrder,
            ),
          ),
          latestPublished: fixture.blueprintRevision,
        ),
      ],
      visualSnapshots: fixture.snapshots,
    ),
  );
}
