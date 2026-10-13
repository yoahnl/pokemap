import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

final class BorderJumpFixture {
  BorderJumpFixture({
    Direction direction = Direction.south,
    BorderLineSide jumpSide = BorderLineSide.primary,
    ElementCollisionProfile? collisionProfile,
    List<BorderSlotOverride> overrides = const [],
    List<BorderKeepOutRegion> keepOut = const [],
    List<GridPos>? points,
    bool extraVariant = false,
    BorderLineSide lineSide = BorderLineSide.primary,
  }) {
    final authoredPoints = points ??
        switch (direction) {
          Direction.south => const [GridPos(x: 3, y: 3), GridPos(x: 4, y: 3)],
          Direction.north => const [GridPos(x: 4, y: 3), GridPos(x: 3, y: 3)],
          Direction.east => const [GridPos(x: 4, y: 4), GridPos(x: 4, y: 3)],
          Direction.west => const [GridPos(x: 4, y: 3), GridPos(x: 4, y: 4)],
        };
    final primitives = <BorderPublishedPrimitive>[];
    final snapshots = <BorderVisualSnapshot>[];
    final elements = <ProjectElementEntry>[];
    var index = 0;
    for (final orientation in BorderPrimitiveOrientation.values.where(
      (value) => value != BorderPrimitiveOrientation.legacyAxis,
    )) {
      final pixels = Uint8List(32 * 32 * 4);
      final mask = <bool>[];
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final opaque = switch (orientation) {
            BorderPrimitiveOrientation.north => y < 16,
            BorderPrimitiveOrientation.south => y >= 16,
            BorderPrimitiveOrientation.east => x >= 16,
            BorderPrimitiveOrientation.west => x < 16,
            BorderPrimitiveOrientation.legacyAxis => false,
          };
          mask.add(opaque);
          final offset = (y * 32 + x) * 4;
          pixels[offset] = x * 7;
          pixels[offset + 1] = y * 7;
          pixels[offset + 2] = index * 50;
          pixels[offset + 3] = opaque ? 255 : 0;
        }
      }
      final hash = computeBorderSnapshotContentFingerprint(frames: [
        BorderSnapshotContentFrame(
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
          durationMs: 100,
          rgbaBytes: pixels,
        ),
      ]);
      final snapshotId = 'border-snapshot-sha256:$hash';
      final metrics = BorderPrimitiveAssetMetrics(
        assetFingerprint: 'original-fixture-${orientation.name}',
        pixelSize: const GridSize(width: 32, height: 32),
        opaqueBounds: switch (orientation) {
          BorderPrimitiveOrientation.north =>
            BorderPixelRect(x: 0, y: 0, width: 32, height: 16),
          BorderPrimitiveOrientation.south =>
            BorderPixelRect(x: 0, y: 16, width: 32, height: 16),
          BorderPrimitiveOrientation.east =>
            BorderPixelRect(x: 16, y: 0, width: 16, height: 32),
          BorderPrimitiveOrientation.west ||
          BorderPrimitiveOrientation.legacyAxis =>
            BorderPixelRect(x: 0, y: 0, width: 16, height: 32),
        },
        defaultAnchorPx: const BorderPixelPos(x: 11, y: 23),
        occupancyMaskRle: encodeBorderRleMask(mask),
      );
      primitives.add(BorderPublishedPrimitive(
        id: orientation.name,
        sourceElementId: 'element-${orientation.name}',
        visualSnapshotId: snapshotId,
        role: BorderPrimitiveRole.structureLarge,
        authoredOrientation: orientation,
        weight: 1,
        anchorPx: const BorderPixelPos(x: 11, y: 23),
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: [0],
        ),
        publishedMetrics: metrics,
      ));
      snapshots.add(BorderVisualSnapshot(
        id: snapshotId,
        contentFingerprint: hash,
        frames: [
          BorderVisualFrameSnapshot(
            relativeAssetPath: 'assets/borders/snapshots/$hash.png',
            sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 32, height: 32),
            durationMs: 100,
          ),
        ],
      ));
      elements.add(ProjectElementEntry(
        id: 'element-${orientation.name}',
        name: 'Original ${orientation.name}',
        tilesetId: 'original-atlas',
        categoryId: 'original-modules',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: index, y: 0)),
        ],
        collisionProfile: collisionProfile ??
            const ElementCollisionProfile(cells: [GridPos(x: 0, y: 0)]),
      ));
      index++;
    }
    final parameters = BorderGenerationParams(
      irregularityPermille: 0,
      detailDensityPermille: 0,
      variationPermille: 1000,
      maxOverlapPx: 0,
      gapTolerancePx: 0,
      depthRows: 1,
      allowAutoRotation: false,
    );
    if (extraVariant) {
      final source = primitives.firstWhere((value) =>
          value.authoredOrientation == BorderPrimitiveOrientation.south);
      primitives.add(BorderPublishedPrimitive(
        id: 'south-alternate',
        sourceElementId: source.sourceElementId,
        visualSnapshotId: source.visualSnapshotId,
        role: source.role,
        authoredOrientation: source.authoredOrientation,
        weight: source.weight,
        anchorPx: source.anchorPx,
        transforms: source.transforms,
        publishedMetrics: source.publishedMetrics,
      ));
    }
    revision = BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Original ledge modules',
        previewSeed: BorderSignedInt64.fromInt(1),
        template: BorderBlueprintTemplate.ledgeLine,
        primitives: primitives,
        defaults: parameters,
        sortOrder: 0,
        jumpBehavior: BorderJumpBehavior(
          side: jumpSide,
          durationMs: 420,
          peakHeightPx: 19,
        ),
      ),
    );
    final base = BorderFeature(
      id: 'ledge-feature',
      name: 'Original ledge',
      blueprintId: 'ledge-blueprint',
      seed: BorderSignedInt64.fromInt(7),
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: [
          BorderStroke(
            id: buildBorderPreservedStrokeIdV1(
              authoredStrokeId: 'original-edge',
              sourceEdgeOffset: 0,
              wrapLength: null,
              orderedPoints: authoredPoints,
            ),
            points: authoredPoints,
            closed: false,
          ),
        ],
      ),
      overrides: overrides,
      keepOutRegions: keepOut,
      lineSide: lineSide,
    );
    request = BorderResolutionRequest(
      mapSize: const GridSize(width: 12, height: 12),
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: base.blueprintId,
      blueprintRevision: revision,
      feature: base,
      visualSnapshots: snapshots,
      resolverVersion: borderResolverVersion,
    );
    evidence = resolveLedgeLineBorderWithEvidence(request);
    if (!evidence.result.canApply) {
      throw StateError(
          evidence.result.diagnostics.map((value) => value.code).join(','));
    }
    feature = BorderFeature(
      id: base.id,
      name: base.name,
      blueprintId: base.blueprintId,
      seed: base.seed,
      geometry: base.geometry,
      overrides: base.overrides,
      keepOutRegions: base.keepOutRegions,
      lineSide: base.lineSide,
      materialization: evidence.result.materialization,
    );
    map = MapData(
      id: 'original-map',
      name: 'Original map',
      size: request.mapSize,
      layers: [
        MapLayer.border(
          id: 'original-borders',
          name: 'Borders',
          content: BorderLayerContent(formatVersion: 4, features: [feature]),
        ),
        MapLayer.tile(
            id: 'objects', name: 'Objects', cells: List.filled(144, 0)),
      ],
    );
    project = ProjectManifest(
      version: ProjectVersion.v8,
      name: 'Original synthetic project',
      maps: const [],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'original-atlas',
          name: 'Original cardinal modules',
          relativePath: 'assets/original.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'original-image',
            pixelWidth: 128,
            pixelHeight: 32,
            tileWidth: 32,
            tileHeight: 32,
          ),
        ),
      ],
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      elementCategories: const [
        ProjectElementCategory(
            id: 'original-modules', name: 'Original modules'),
      ],
      elements: elements,
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 7,
        records: [
          BorderBlueprintRecord(
            id: base.blueprintId,
            latestPublished: revision,
            draft: BorderBlueprintDraft(
              baseRevision: 1,
              definition: BorderBlueprintDraftDefinition(
                name: revision.definition.name,
                previewSeed: revision.definition.previewSeed,
                template: revision.definition.template,
                primitives: [
                  for (final primitive in primitives)
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
                defaults: parameters,
                sortOrder: 0,
                jumpBehavior: revision.definition.jumpBehavior,
              ),
            ),
          ),
        ],
        visualSnapshots: snapshots,
      ),
    );
    ProjectValidator.validate(project, maps: [map]);
    MapValidator.validate(map, projectDialogueContext: project);
  }

  late final BorderResolutionRequest request;
  late final LedgeLineBorderResolutionEvidence evidence;
  late final BorderBlueprintRevision revision;
  late final BorderFeature feature;
  late final MapData map;
  late final ProjectManifest project;

  GridPos get carrier => evidence.edges.single.expectedCarrierCell;

  GameplayWorldState world({
    required Direction direction,
    MapData? mapOverride,
    ProjectManifest? projectOverride,
    GridPos? playerPos,
    MovementMode mode = MovementMode.walk,
  }) =>
      GameplayWorldState.initial(
        map: mapOverride ?? map,
        project: projectOverride ?? project,
        playerPos: playerPos ??
            GridPos(
              x: carrier.x - direction.dx,
              y: carrier.y - direction.dy,
            ),
        playerMovementMode: mode,
        tileWidth: 32,
        tileHeight: 32,
      );
}
