import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:image/image.dart' as image;

import 'package:map_authoring/map_authoring.dart';
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
    final orientations = BorderPrimitiveOrientation.values
        .where((orientation) =>
            orientation != BorderPrimitiveOrientation.legacyAxis)
        .toList();
    final atlas = image.Image(
        width: orientations.length * 32, height: 32, numChannels: 4);
    for (final (index, orientation) in orientations.indexed) {
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final opaque = switch (orientation) {
            BorderPrimitiveOrientation.north => y < 16,
            BorderPrimitiveOrientation.south => y >= 16,
            BorderPrimitiveOrientation.east => x >= 16,
            BorderPrimitiveOrientation.west => x < 16,
            BorderPrimitiveOrientation.legacyAxis => false,
          };
          atlas.setPixelRgba(
              index * 32 + x, y, x * 7, y * 7, index * 50, opaque ? 255 : 0);
        }
      }
    }
    atlasBytes = image.encodePng(atlas);
    for (final (index, orientation) in orientations.indexed) {
      final prepared = const CanonicalBorderSnapshotCompiler().prepare(
        sourceElementId: 'element-${orientation.name}',
        anchorPx: const BorderPixelPos(x: 11, y: 23),
        frames: [
          CanonicalBorderSourceFrame(
            sourceProjectRelativePath: atlasPath,
            encodedImageBytes: atlasBytes,
            sourceRectPx:
                BorderPixelRect(x: index * 32, y: 0, width: 32, height: 32),
          )
        ],
      );
      snapshots.add(prepared.snapshot);
      snapshotFiles.addAll(prepared.files);
      primitives.add(BorderPublishedPrimitive(
        id: orientation.name,
        sourceElementId: prepared.sourceElementId,
        visualSnapshotId: prepared.snapshot.id,
        role: BorderPrimitiveRole.structureLarge,
        authoredOrientation: orientation,
        weight: 1,
        anchorPx: const BorderPixelPos(x: 11, y: 23),
        transforms: BorderTransformPolicy(
          allowFlipX: false,
          allowedQuarterTurns: [0],
        ),
        publishedMetrics: prepared.metrics,
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
          relativePath: atlasPath,
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
  static const atlasPath = 'assets/original.png';
  late final Uint8List atlasBytes;
  final snapshotFiles = <CanonicalBorderSnapshotFile>[];

  GridPos get carrier => evidence.edges.single.expectedCarrierCell;
}

Future<BorderReplacementFixture> writeBorderReplacementFixture(
    Directory root) async {
  final f = BorderReplacementFixture(extraVariant: true);
  await Directory('${root.path}/maps').create(recursive: true);
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(f.project.toJson()), flush: true);
  await File('${root.path}/maps/original-map.pokemap.json')
      .writeAsString(jsonEncode(f.map.toJson()), flush: true);
  final records = <AssetRecord>[];
  for (final (id, path, bytes) in [
    ('original-image', BorderReplacementFixture.atlasPath, f.atlasBytes),
    for (final (index, snapshot) in f.snapshotFiles.indexed)
      ('snapshot-$index', snapshot.relativePath, snapshot.bytes),
  ]) {
    final artifact =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    records.add(AssetRecord(id: id, logicalPath: path, artifact: artifact));
    for (final relativePath in [path, assetBlobStorageKey(artifact)]) {
      final file = File('${root.path}/$relativePath');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  }
  final catalogFile = File('${root.path}/$assetCatalogStorageKey');
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
      jsonEncode(AssetCatalog(records: records).toJson()),
      flush: true);
  return f;
}
