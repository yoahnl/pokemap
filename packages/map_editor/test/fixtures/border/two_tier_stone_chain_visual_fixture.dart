import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_inspection.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:path/path.dart' as p;

const twoTierStoneChainVisualMapSize = GridSize(width: 16, height: 12);
const twoTierStoneChainVisualTileSizePx = 32;
const twoTierStoneChainVisualCanvasWidth = 512;
const twoTierStoneChainVisualCanvasHeight = 384;

final class TwoTierStoneChainVisualCase {
  TwoTierStoneChainVisualCase({
    required this.id,
    required this.geometryId,
    required this.goldenFile,
    required Iterable<GridPos> points,
    required Iterable<GridPos> turnVertices,
    required this.closed,
    this.lineSide = BorderLineSide.primary,
    this.rotationEnabled = false,
  })  : points = List<GridPos>.unmodifiable(points),
        turnVertices = List<GridPos>.unmodifiable(turnVertices);

  final String id;
  final String geometryId;
  final String goldenFile;
  final List<GridPos> points;
  final List<GridPos> turnVertices;
  final bool closed;
  final BorderLineSide lineSide;
  final bool rotationEnabled;

  int get edgeCount => closed ? points.length : points.length - 1;
}

final class TwoTierStoneChainVisualCaseResolution {
  TwoTierStoneChainVisualCaseResolution({
    required this.visualCase,
    required this.request,
    required this.evidence,
    required this.parameters,
    required Map<String, BorderPublishedPrimitive> primitivesById,
  }) : primitivesById =
            Map<String, BorderPublishedPrimitive>.unmodifiable(primitivesById);

  final TwoTierStoneChainVisualCase visualCase;
  final BorderResolutionRequest request;
  final StoneChainLineBorderResolutionEvidence evidence;
  final BorderGenerationParams parameters;
  final Map<String, BorderPublishedPrimitive> primitivesById;

  BorderFeature get feature => request.feature;

  String get diagnostics => evidence.result.diagnostics
      .map(
        (item) => '${item.severity.name}:${item.code} ${item.parameters}',
      )
      .join(', ');

  List<BorderResolvedPlacement> get placements =>
      evidence.result.materialization?.placements ??
      const <BorderResolvedPlacement>[];

  List<BorderResolvedPlacement> get lipPlacements => _placementsWithRole(
        BorderPrimitiveRole.structureLarge,
      );

  List<BorderResolvedPlacement> get facePlacements => _placementsWithRole(
        BorderPrimitiveRole.structureMedium,
      );

  String nodeSlotKey({
    required GridPos vertex,
    required int passIndex,
    required BorderPrimitiveRole role,
    required int rank,
  }) =>
      buildBorderStoneChainNodeSlotKey(
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

  List<BorderResolvedPlacement> _placementsWithRole(
    BorderPrimitiveRole role,
  ) =>
      placements
          .where(
            (placement) => primitivesById[placement.primitiveId]?.role == role,
          )
          .toList(growable: false);
}

/// Visual bench backed only by the real published `border-blueprint-4` and its
/// persisted snapshot files. It deliberately has no draft/in-memory publication
/// fallback: Task 11 must stay RED until the real Task 10 publication exists.
final class TwoTierStoneChainVisualFixture {
  TwoTierStoneChainVisualFixture._({
    required File projectFile,
    required List<int> projectBytesBefore,
    required this.projectRootPath,
    required this.manifest,
    required this.blueprintId,
    required this.publishedRevision,
    required this.frameImagesByKey,
    required this.publishedSnapshotRelativePaths,
  })  : _projectFile = projectFile,
        _projectBytesBefore = List<int>.unmodifiable(projectBytesBefore),
        cases = List<TwoTierStoneChainVisualCase>.unmodifiable(_visualCases()),
        primitivesById = Map<String, BorderPublishedPrimitive>.unmodifiable(
          <String, BorderPublishedPrimitive>{
            for (final primitive in publishedRevision.definition.primitives)
              primitive.id: primitive,
          },
        );

  static Future<TwoTierStoneChainVisualFixture> load() async {
    final projectRootPath = p.normalize(
      p.absolute(p.join(Directory.current.path, '..', '..', 'selbrume')),
    );
    final projectFile = File(p.join(projectRootPath, 'project.json'));
    final projectBytesBefore = await projectFile.readAsBytes();
    final projectJson =
        jsonDecode(utf8.decode(projectBytesBefore)) as Map<String, Object?>;
    final manifest = ProjectManifest.fromJson(projectJson);
    const blueprintId = 'border-blueprint-4';
    final record = manifest.borderCatalog.recordById(blueprintId);
    if (record == null) {
      throw StateError('$blueprintId is missing from Selbrume project.json');
    }
    final publishedRevision = record.latestPublished;
    if (publishedRevision == null || publishedRevision.revision < 1) {
      throw StateError(
        '$blueprintId requires a real latestPublished revision in '
        'selbrume/project.json before Task 11 can compare or update goldens. '
        'Publish it through the real Task 10 flow first; draft publication '
        'fallbacks are forbidden.',
      );
    }

    final definition = publishedRevision.definition;
    if (definition.template != BorderBlueprintTemplate.stoneChainLine ||
        definition.defaults.depthRows != 2) {
      throw StateError(
        '$blueprintId must publish stoneChainLine with depthRows=2.',
      );
    }
    final activeDraftIds = <String>{
      for (final primitive in record.draft.definition.primitives)
        if (primitive.weight > 0) primitive.id,
    };
    final publishedIds = <String>{
      for (final primitive in definition.primitives) primitive.id,
    };
    if (definition.primitives.length != 24 ||
        publishedIds.length != 24 ||
        publishedIds.difference(activeDraftIds).isNotEmpty ||
        activeDraftIds.difference(publishedIds).isNotEmpty) {
      throw StateError(
        '$blueprintId must publish exactly the 24 active V2 primitives; '
        'draft=$activeDraftIds published=$publishedIds.',
      );
    }

    final snapshotIds = <String>{
      for (final primitive in definition.primitives) primitive.visualSnapshotId,
    };
    if (snapshotIds.length != 24) {
      throw StateError(
        '$blueprintId must reference 24 distinct published snapshots, got '
        '${snapshotIds.length}.',
      );
    }

    final frameImagesByKey = <String, ui.Image?>{};
    final snapshotRelativePaths = <String>[];
    try {
      for (final primitive in definition.primitives) {
        final snapshot = manifest.borderCatalog.visualSnapshotById(
          primitive.visualSnapshotId,
        );
        if (snapshot == null || snapshot.frames.length != 1) {
          throw StateError(
            '${primitive.id} must reference one real published visual frame.',
          );
        }
        final frame = snapshot.frames.single;
        final relativePath = frame.relativeAssetPath;
        final frameFile = File(p.join(projectRootPath, relativePath));
        if (!frameFile.existsSync()) {
          throw StateError(
            '${primitive.id} published snapshot is missing: $relativePath',
          );
        }
        final image = await _decodePng(
          Uint8List.fromList(await frameFile.readAsBytes()),
        );
        if (image.width != 32 || image.height != 32) {
          final dimensions = '${image.width}x${image.height}';
          image.dispose();
          throw StateError(
            '${primitive.id} published snapshot must be 32x32, got '
            '$dimensions.',
          );
        }
        frameImagesByKey[editorBorderFrameImageKey(snapshot.id, 0)] = image;
        snapshotRelativePaths.add(relativePath);
      }
    } catch (_) {
      for (final image in frameImagesByKey.values.whereType<ui.Image>()) {
        image.dispose();
      }
      rethrow;
    }
    if (snapshotRelativePaths.toSet().length != 24) {
      for (final image in frameImagesByKey.values.whereType<ui.Image>()) {
        image.dispose();
      }
      throw StateError(
        '$blueprintId must persist 24 distinct snapshot frame paths.',
      );
    }

    return TwoTierStoneChainVisualFixture._(
      projectFile: projectFile,
      projectBytesBefore: projectBytesBefore,
      projectRootPath: projectRootPath,
      manifest: manifest,
      blueprintId: blueprintId,
      publishedRevision: publishedRevision,
      frameImagesByKey: frameImagesByKey,
      publishedSnapshotRelativePaths:
          List<String>.unmodifiable(snapshotRelativePaths),
    );
  }

  final File _projectFile;
  final List<int> _projectBytesBefore;
  final String projectRootPath;
  final ProjectManifest manifest;
  final String blueprintId;
  final BorderBlueprintRevision publishedRevision;
  final Map<String, ui.Image?> frameImagesByKey;
  final List<String> publishedSnapshotRelativePaths;
  final List<TwoTierStoneChainVisualCase> cases;
  final Map<String, BorderPublishedPrimitive> primitivesById;

  TwoTierStoneChainVisualCaseResolution resolve(
    TwoTierStoneChainVisualCase visualCase,
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
    return TwoTierStoneChainVisualCaseResolution(
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

  Map<String, Object?> inspect(
    TwoTierStoneChainVisualCaseResolution resolution,
  ) {
    final map = mapFor(resolution);
    return inspectBorderFeature(
      map: map,
      project: manifest,
      layerId: 'two-tier-stone-chain-visual-layer',
      featureId: resolution.feature.id,
    );
  }

  MapData mapFor(TwoTierStoneChainVisualCaseResolution resolution) {
    final layer = MapLayer.border(
      id: 'two-tier-stone-chain-visual-layer',
      name: 'Two-tier stone chain visual bench',
      content: BorderLayerContent(
        formatVersion: BorderLayerContent.formatVersionV3,
        features: <BorderFeature>[resolution.materializedFeature],
      ),
    ) as BorderLayer;
    return MapData(
      id: 'two-tier-stone-chain-visual-${resolution.visualCase.id}',
      name: resolution.visualCase.id,
      version: ProjectVersion.v6,
      size: twoTierStoneChainVisualMapSize,
      properties: const <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[layer],
    );
  }

  Future<ui.Image> render(
    TwoTierStoneChainVisualCaseResolution resolution,
  ) async {
    final map = mapFor(resolution);
    final layer = map.layers.single as BorderLayer;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(
        0,
        0,
        512,
        384,
      ),
      ui.Paint()..color = const ui.Color(0xFF29313A),
    );
    const BorderPreviewPainter().paintLayer(
      canvas,
      map: map,
      layer: layer,
      catalog: manifest.borderCatalog,
      frameImagesByKey: frameImagesByKey,
      sourceTileWidth: twoTierStoneChainVisualTileSizePx,
      sourceTileHeight: twoTierStoneChainVisualTileSizePx,
      displayScale: 1,
      elapsedMs: 0,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      twoTierStoneChainVisualCanvasWidth,
      twoTierStoneChainVisualCanvasHeight,
    );
    picture.dispose();
    return image;
  }

  Future<bool> projectBytesAreUnchanged() async {
    final current = await _projectFile.readAsBytes();
    if (current.length != _projectBytesBefore.length) return false;
    for (var index = 0; index < current.length; index += 1) {
      if (current[index] != _projectBytesBefore[index]) return false;
    }
    return true;
  }

  void dispose() {
    for (final image in frameImagesByKey.values.whereType<ui.Image>()) {
      image.dispose();
    }
  }
}

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

List<TwoTierStoneChainVisualCase> _visualCases() {
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
  return <TwoTierStoneChainVisualCase>[
    TwoTierStoneChainVisualCase(
      id: 'horizontal_primary',
      geometryId: 'horizontal-primary',
      goldenFile: 'goldens/two_tier_stone_chain_horizontal_primary.png',
      points: horizontal,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 'vertical_primary',
      geometryId: 'vertical-primary',
      goldenFile: 'goldens/two_tier_stone_chain_vertical_primary.png',
      points: vertical,
      turnVertices: const <GridPos>[],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 'l_convex_primary',
      geometryId: 'l-shape',
      goldenFile: 'goldens/two_tier_stone_chain_l_convex_primary.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 'l_concave_inverted',
      geometryId: 'l-shape',
      goldenFile: 'goldens/two_tier_stone_chain_l_concave_inverted.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    TwoTierStoneChainVisualCase(
      id: 's_primary',
      geometryId: 's-shape',
      goldenFile: 'goldens/two_tier_stone_chain_s_primary.png',
      points: s,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 2),
        GridPos(x: 7, y: 7),
      ],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 's_inverted',
      geometryId: 's-shape',
      goldenFile: 'goldens/two_tier_stone_chain_s_inverted.png',
      points: s,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 2),
        GridPos(x: 7, y: 7),
      ],
      closed: false,
      lineSide: BorderLineSide.inverted,
    ),
    TwoTierStoneChainVisualCase(
      id: 'closed_loop',
      geometryId: 'closed-loop',
      goldenFile: 'goldens/two_tier_stone_chain_closed_loop.png',
      points: loop,
      turnVertices: const <GridPos>[
        GridPos(x: 4, y: 3),
        GridPos(x: 11, y: 3),
        GridPos(x: 11, y: 8),
        GridPos(x: 4, y: 8),
      ],
      closed: true,
    ),
    TwoTierStoneChainVisualCase(
      id: 'one_cell_zigzag',
      geometryId: 'one-cell-zigzag',
      goldenFile: 'goldens/two_tier_stone_chain_one_cell_zigzag.png',
      points: zigzag,
      turnVertices: const <GridPos>[
        GridPos(x: 7, y: 5),
        GridPos(x: 7, y: 6),
        GridPos(x: 8, y: 6),
        GridPos(x: 8, y: 7),
      ],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 'rotation_off',
      geometryId: 'rotation-probe',
      goldenFile: 'goldens/two_tier_stone_chain_rotation_off.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
    ),
    TwoTierStoneChainVisualCase(
      id: 'rotation_on',
      geometryId: 'rotation-probe',
      goldenFile: 'goldens/two_tier_stone_chain_rotation_on.png',
      points: l,
      turnVertices: const <GridPos>[GridPos(x: 10, y: 2)],
      closed: false,
      rotationEnabled: true,
    ),
  ];
}
