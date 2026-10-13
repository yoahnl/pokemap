import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as image;

import 'package:map_core/map_core.dart';

final class BorderReplacementFixture {
  BorderReplacementFixture({
    BorderLineSide jumpSide = BorderLineSide.primary,
    ElementCollisionProfile? collisionProfile,
    List<BorderSlotOverride> overrides = const [],
    List<BorderKeepOutRegion> keepOut = const [],
    List<GridPos>? points,
    bool extraVariant = false,
    BorderLineSide lineSide = BorderLineSide.primary,
  }) {
    final authoredPoints =
        points ?? const [GridPos(x: 3, y: 3), GridPos(x: 4, y: 3)];
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
      maps: const [
        ProjectMapEntry(
            id: 'original-map',
            name: 'Original map',
            relativePath: 'maps/original-map.pokemap.json')
      ],
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
}

Future<void> writeBorderReplacementFixture(Directory root) async {
  final f = BorderReplacementFixture(extraVariant: true);
  await Directory('${root.path}/maps').create(recursive: true);
  await Directory('${root.path}/assets/borders/snapshots')
      .create(recursive: true);
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(f.project.toJson()), flush: true);
  await File('${root.path}/maps/original-map.pokemap.json')
      .writeAsString(jsonEncode(f.map.toJson()), flush: true);
  final atlas = image.Image(width: 128, height: 32, numChannels: 4);
  var index = 0;
  for (final primitive in f.revision.definition.primitives
      .where((p) => p.id != 'south-alternate')) {
    final png = image.Image(width: 32, height: 32, numChannels: 4);
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final opaque = switch (primitive.authoredOrientation) {
          BorderPrimitiveOrientation.north => y < 16,
          BorderPrimitiveOrientation.south => y >= 16,
          BorderPrimitiveOrientation.east => x >= 16,
          BorderPrimitiveOrientation.west => x < 16,
          BorderPrimitiveOrientation.legacyAxis => false,
        };
        png.setPixelRgba(x, y, x * 7, y * 7, index * 50, opaque ? 255 : 0);
        atlas.setPixelRgba(
            index * 32 + x, y, x * 7, y * 7, index * 50, opaque ? 255 : 0);
      }
    }
    final snapshot = f.project.borderCatalog.visualSnapshots
        .singleWhere((s) => s.id == primitive.visualSnapshotId);
    await File('${root.path}/${snapshot.frames.single.relativeAssetPath}')
        .writeAsBytes(image.encodePng(png), flush: true);
    index++;
  }
  await File('${root.path}/assets/original.png')
      .writeAsBytes(image.encodePng(atlas), flush: true);
}
