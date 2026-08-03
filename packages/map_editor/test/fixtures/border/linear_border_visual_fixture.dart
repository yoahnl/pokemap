import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

const linearGoldenMapSize = GridSize(width: 20, height: 14);
const linearGoldenSourceTileSize = 16;
const linearGoldenDisplayTileSize = 16.0;
const linearGoldenCanvasWidth = 320;
const linearGoldenCanvasHeight = 224;
const linearGoldenPanelGap = 8;
const linearGoldenCanvasSize = ui.Size(320.0, 224.0);

const linearGoldenDiagnosticPalette = EditorBorderDiagnosticOverlayPalette(
  warningFill: ui.Color(0xCCE6B449),
  warningStroke: ui.Color(0xFFFFD35A),
  errorFill: ui.Color(0xCCD34A5A),
  errorStroke: ui.Color(0xFFFF6577),
);

final class MasonryVisualGoldenFixture {
  MasonryVisualGoldenFixture() {
    primitives = <BorderPublishedPrimitive>[
      _primitive(
        id: 'strict-stone-a',
        fingerprintCharacter: '1',
        role: BorderPrimitiveRole.structureLarge,
        width: 12,
        height: 10,
        anchorPx: const BorderPixelPos(x: 6, y: 5),
        opaqueRects: _masonryStoneOpaqueRects,
      ),
      _primitive(
        id: 'strict-stone-b',
        fingerprintCharacter: '2',
        role: BorderPrimitiveRole.structureLarge,
        width: 12,
        height: 10,
        anchorPx: const BorderPixelPos(x: 6, y: 5),
        opaqueRects: _masonryStoneOpaqueRects,
      ),
    ];
    snapshots = <BorderVisualSnapshot>[
      for (final primitive in primitives) _snapshotFor(primitive),
    ];
    revision = BorderBlueprintRevision(
      revision: 4,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Muret strict visuel',
        previewSeed: BorderSignedInt64.fromInt(31415),
        template: BorderBlueprintTemplate.masonryLine,
        primitives: primitives,
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 1000,
          maxOverlapPx: 2,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        sortOrder: 0,
      ),
    );
  }

  static const blueprintId = 'golden-strict-masonry';
  static const featureId = 'strict-masonry-feature';
  static const layerId = 'strict-masonry-border-layer';

  late final List<BorderPublishedPrimitive> primitives;
  late final List<BorderVisualSnapshot> snapshots;
  late final BorderBlueprintRevision revision;

  BorderStrokeGeometry get appliedGeometry => BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'straight',
            points: <GridPos>[
              for (var x = 3; x <= 16; x += 1) GridPos(x: x, y: 6),
            ],
            closed: false,
          ),
        ],
      );

  BorderStrokeGeometry get previewGeometry => BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'preview-straight',
            points: <GridPos>[
              for (var x = 2; x <= 17; x += 1) GridPos(x: x, y: 8),
            ],
            closed: false,
          ),
        ],
      );

  BorderFeature feature({
    required BorderStrokeGeometry geometry,
    required int seed,
    BorderMaterialization? materialization,
  }) =>
      BorderFeature(
        id: featureId,
        name: 'Muret strict',
        blueprintId: blueprintId,
        seed: BorderSignedInt64.fromInt(seed),
        geometry: geometry,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
        materialization: materialization,
      );

  BorderResolutionResult resolve(BorderFeature feature) =>
      resolveMasonryLineBorder(
        BorderResolutionRequest(
          mapSize: linearGoldenMapSize,
          tileSizePx: const GridSize(
            width: linearGoldenSourceTileSize,
            height: linearGoldenSourceTileSize,
          ),
          blueprintId: blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: snapshots,
          resolverVersion: borderResolverVersion,
        ),
      );

  BorderFeature resolveFeature({
    required BorderStrokeGeometry geometry,
    required int seed,
  }) {
    final draft = feature(geometry: geometry, seed: seed);
    final result = resolve(draft);
    if (!result.canApply || result.materialization == null) {
      throw StateError(
        'Strict masonry visual fixture must resolve: '
        '${result.diagnostics.map((item) => item.code).join(', ')}',
      );
    }
    return feature(
      geometry: geometry,
      seed: seed,
      materialization: result.materialization,
    );
  }

  MapData mapWithFeature(BorderFeature feature) => _mapWithFeature(
        mapId: 'golden-strict-masonry-map',
        mapName: 'Strict masonry golden',
        layerId: layerId,
        layerName: 'Muret',
        feature: feature,
      );

  ProjectManifest get project => _project(
        name: 'Strict masonry golden',
        snapshots: snapshots,
      );

  Future<Map<String, ui.Image?>> loadSyntheticImages() async =>
      <String, ui.Image?>{
        linearGoldenGroundTilesetId: await _groundTile(),
        editorBorderFrameImageKey(primitives[0].visualSnapshotId, 0):
            await _masonryStone(
          base: const ui.Color(0xFF7F7465),
          highlight: const ui.Color(0xFFA99B88),
        ),
        editorBorderFrameImageKey(primitives[1].visualSnapshotId, 0):
            await _masonryStone(
          base: const ui.Color(0xFF665E55),
          highlight: const ui.Color(0xFF918577),
        ),
      };
}

final class OpenFenceVisualGoldenFixture {
  OpenFenceVisualGoldenFixture() {
    primitives = <BorderPublishedPrimitive>[
      _primitive(
        id: 'open-fence-post',
        fingerprintCharacter: '3',
        role: BorderPrimitiveRole.post,
        width: 8,
        height: 16,
        anchorPx: const BorderPixelPos(x: 4, y: 8),
        allowedQuarterTurns: const <int>[0],
        opaqueRects: _fencePostOpaqueRects,
      ),
      _primitive(
        id: 'open-fence-rail',
        fingerprintCharacter: '4',
        role: BorderPrimitiveRole.span,
        width: 16,
        height: 6,
        anchorPx: const BorderPixelPos(x: 8, y: 3),
        allowedQuarterTurns: const <int>[0],
        opaqueRects: _fenceRailOpaqueRects,
      ),
    ];
    snapshots = <BorderVisualSnapshot>[
      for (final primitive in primitives) _snapshotFor(primitive),
    ];
    revision = BorderBlueprintRevision(
      revision: 3,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Clôture ouverte visuelle',
        previewSeed: BorderSignedInt64.fromInt(27182),
        template: BorderBlueprintTemplate.postAndRailLine,
        primitives: primitives,
        defaults: BorderGenerationParams(
          irregularityPermille: 0,
          detailDensityPermille: 0,
          variationPermille: 0,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        sortOrder: 0,
      ),
    );
  }

  static const blueprintId = 'golden-open-fence';
  static const featureId = 'open-fence-feature';
  static const layerId = 'open-fence-border-layer';

  late final List<BorderPublishedPrimitive> primitives;
  late final List<BorderVisualSnapshot> snapshots;
  late final BorderBlueprintRevision revision;

  BorderStrokeGeometry get appliedGeometry => _horizontalOpening(
        leftEnd: 7,
        rightStart: 11,
      );

  BorderStrokeGeometry get previewGeometry => _horizontalOpening(
        leftEnd: 6,
        rightStart: 12,
      );

  BorderStrokeGeometry get diagnosticGeometry => BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'upper',
            points: <GridPos>[
              for (var y = 2; y <= 5; y += 1) GridPos(x: 9, y: y),
            ],
            closed: false,
          ),
          BorderStroke(
            id: 'lower',
            points: <GridPos>[
              for (var y = 8; y <= 11; y += 1) GridPos(x: 9, y: y),
            ],
            closed: false,
          ),
        ],
      );

  BorderFeature feature({
    required BorderStrokeGeometry geometry,
    required int seed,
    BorderMaterialization? materialization,
  }) =>
      BorderFeature(
        id: featureId,
        name: 'Clôture avec ouverture',
        blueprintId: blueprintId,
        seed: BorderSignedInt64.fromInt(seed),
        geometry: geometry,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
        materialization: materialization,
      );

  BorderResolutionResult resolve(BorderFeature feature) =>
      resolvePostAndRailLineBorder(
        BorderResolutionRequest(
          mapSize: linearGoldenMapSize,
          tileSizePx: const GridSize(
            width: linearGoldenSourceTileSize,
            height: linearGoldenSourceTileSize,
          ),
          blueprintId: blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: snapshots,
          resolverVersion: borderResolverVersion,
        ),
      );

  BorderFeature resolveFeature({
    required BorderStrokeGeometry geometry,
    required int seed,
  }) {
    final draft = feature(geometry: geometry, seed: seed);
    final result = resolve(draft);
    if (!result.canApply || result.materialization == null) {
      throw StateError(
        'Open fence visual fixture must resolve: '
        '${result.diagnostics.map((item) => item.code).join(', ')}',
      );
    }
    return feature(
      geometry: geometry,
      seed: seed,
      materialization: result.materialization,
    );
  }

  MapData mapWithFeature(BorderFeature feature) => _mapWithFeature(
        mapId: 'golden-open-fence-map',
        mapName: 'Open fence golden',
        layerId: layerId,
        layerName: 'Clôture',
        feature: feature,
      );

  ProjectManifest get project => _project(
        name: 'Open fence golden',
        snapshots: snapshots,
      );

  Future<Map<String, ui.Image?>> loadSyntheticImages() async =>
      <String, ui.Image?>{
        linearGoldenGroundTilesetId: await _groundTile(),
        editorBorderFrameImageKey(primitives[0].visualSnapshotId, 0):
            await _fencePost(),
        editorBorderFrameImageKey(primitives[1].visualSnapshotId, 0):
            await _fenceRail(),
      };

  BorderStrokeGeometry _horizontalOpening({
    required int leftEnd,
    required int rightStart,
  }) =>
      BorderStrokeGeometry(
        strokes: <BorderStroke>[
          BorderStroke(
            id: 'left',
            points: <GridPos>[
              for (var x = 2; x <= leftEnd; x += 1) GridPos(x: x, y: 7),
            ],
            closed: false,
          ),
          BorderStroke(
            id: 'right',
            points: <GridPos>[
              for (var x = rightStart; x <= 17; x += 1) GridPos(x: x, y: 7),
            ],
            closed: false,
          ),
        ],
      );
}

final class LinearBorderVisualRenderer {
  const LinearBorderVisualRenderer({required this.project});

  final ProjectManifest project;

  Future<ui.Image> render({
    required MapData map,
    required Map<String, ui.Image?> images,
    BorderPreviewTransaction? preview,
    EditorBorderDiagnosticOverlayPalette? diagnosticPalette,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    _painter(
      map: map,
      images: images,
      preview: preview,
      diagnosticPalette: diagnosticPalette,
    ).paint(
      canvas,
      linearGoldenCanvasSize,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      linearGoldenCanvasWidth,
      linearGoldenCanvasHeight,
    );
    picture.dispose();
    return image;
  }

  Future<ui.Image> renderBeforeAfter({
    required MapData map,
    required BorderPreviewTransaction preview,
    required Map<String, ui.Image?> images,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    _painter(map: map, images: images).paint(
      canvas,
      linearGoldenCanvasSize,
    );
    canvas.save();
    canvas.translate(
        (linearGoldenCanvasWidth + linearGoldenPanelGap).toDouble(), 0);
    _painter(map: map, images: images, preview: preview).paint(
      canvas,
      linearGoldenCanvasSize,
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      linearGoldenCanvasWidth * 2 + linearGoldenPanelGap,
      linearGoldenCanvasHeight,
    );
    picture.dispose();
    return image;
  }

  MapGridPainter _painter({
    required MapData map,
    required Map<String, ui.Image?> images,
    BorderPreviewTransaction? preview,
    EditorBorderDiagnosticOverlayPalette? diagnosticPalette,
  }) =>
      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: linearGoldenDisplayTileSize,
        tileHeight: linearGoldenDisplayTileSize,
        tilesetImagesById: images,
        sourceTileWidth: linearGoldenSourceTileSize,
        sourceTileHeight: linearGoldenSourceTileSize,
        tilesPerRowById: const <String, int>{
          linearGoldenGroundTilesetId: 1,
        },
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        project: project,
        borderPreview: preview,
        borderDiagnosticOverlayPalette: diagnosticPalette,
      );
}

BorderPreviewTransaction linearGoldenPreview({
  required Object projectIdentity,
  required MapData map,
  required String layerId,
  required String featureId,
  required BorderFeature proposedFeature,
  required BorderResolutionResult result,
  required int variationOrdinal,
}) =>
    BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/golden',
        activeMapPath: '/golden/map.json',
        projectIdentity: projectIdentity,
        mapIdentity: map,
        borderCatalogFingerprint: 'golden-linear-catalog',
      ),
      mapId: map.id,
      mapSize: map.size,
      layerId: layerId,
      featureId: featureId,
      baseFeatureFingerprint: 'golden-linear-saved-feature',
      proposedFeature: proposedFeature,
      variationOrdinal: variationOrdinal,
      result: result,
    );

MapData _mapWithFeature({
  required String mapId,
  required String mapName,
  required String layerId,
  required String layerName,
  required BorderFeature feature,
}) =>
    MapData(
      id: mapId,
      name: mapName,
      version: ProjectVersion.v6,
      size: linearGoldenMapSize,
      properties: const <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[
        TileLayer(
          id: 'ground',
          name: 'Ground',
          tilesetId: linearGoldenGroundTilesetId,
          tiles: List<int>.filled(
            linearGoldenMapSize.width * linearGoldenMapSize.height,
            1,
          ),
        ),
        MapLayer.border(
          id: layerId,
          name: layerName,
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
      ],
    );

ProjectManifest _project({
  required String name,
  required List<BorderVisualSnapshot> snapshots,
}) =>
    ProjectManifest(
      name: name,
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: ProjectBorderCatalog(visualSnapshots: snapshots),
    );

typedef _SyntheticOpaqueRect = ({
  int x,
  int y,
  int width,
  int height,
});

const List<_SyntheticOpaqueRect> _masonryStoneOpaqueRects =
    <_SyntheticOpaqueRect>[
  (x: 0, y: 2, width: 12, height: 7),
  (x: 1, y: 1, width: 10, height: 7),
  (x: 2, y: 1, width: 8, height: 2),
  (x: 2, y: 7, width: 8, height: 2),
];

const List<_SyntheticOpaqueRect> _fencePostOpaqueRects = <_SyntheticOpaqueRect>[
  (x: 1, y: 2, width: 6, height: 14),
  (x: 2, y: 1, width: 4, height: 14),
  (x: 3, y: 2, width: 1, height: 12),
  (x: 1, y: 6, width: 6, height: 2),
];

const List<_SyntheticOpaqueRect> _fenceRailOpaqueRects = <_SyntheticOpaqueRect>[
  (x: 0, y: 1, width: 16, height: 5),
  (x: 0, y: 0, width: 16, height: 4),
  (x: 1, y: 1, width: 14, height: 1),
];

BorderPublishedPrimitive _primitive({
  required String id,
  required String fingerprintCharacter,
  required BorderPrimitiveRole role,
  required int width,
  required int height,
  required BorderPixelPos anchorPx,
  required List<_SyntheticOpaqueRect> opaqueRects,
  List<int> allowedQuarterTurns = const <int>[0, 1, 2, 3],
}) {
  final occupancy = _syntheticOccupancyMask(
    width: width,
    height: height,
    opaqueRects: opaqueRects,
  );
  return BorderPublishedPrimitive(
    id: id,
    sourceElementId: 'synthetic-$id',
    visualSnapshotId: _snapshotId(fingerprintCharacter),
    role: role,
    weight: 1,
    anchorPx: anchorPx,
    transforms: BorderTransformPolicy(
      allowFlipX: false,
      allowedQuarterTurns: allowedQuarterTurns,
    ),
    publishedMetrics: BorderPrimitiveAssetMetrics(
      assetFingerprint: 'synthetic-$id',
      pixelSize: GridSize(width: width, height: height),
      opaqueBounds: _opaqueBoundsForMask(
        occupancy,
        width: width,
        height: height,
      ),
      defaultAnchorPx: anchorPx,
      occupancyMaskRle: encodeBorderRleMask(occupancy),
    ),
  );
}

List<bool> _syntheticOccupancyMask({
  required int width,
  required int height,
  required List<_SyntheticOpaqueRect> opaqueRects,
}) =>
    <bool>[
      for (var y = 0; y < height; y += 1)
        for (var x = 0; x < width; x += 1)
          opaqueRects.any(
            (rect) =>
                x >= rect.x &&
                x < rect.x + rect.width &&
                y >= rect.y &&
                y < rect.y + rect.height,
          ),
    ];

BorderPixelRect _opaqueBoundsForMask(
  List<bool> occupancy, {
  required int width,
  required int height,
}) {
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      if (!occupancy[y * width + x]) continue;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < minX || maxY < minY) {
    throw StateError('A synthetic Border sprite must contain opaque pixels');
  }
  return BorderPixelRect(
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}

BorderVisualSnapshot _snapshotFor(BorderPublishedPrimitive primitive) {
  final fingerprint = primitive.visualSnapshotId.substring(
    'border-snapshot-sha256:'.length,
  );
  final size = primitive.publishedMetrics.pixelSize;
  return BorderVisualSnapshot(
    id: primitive.visualSnapshotId,
    contentFingerprint: fingerprint,
    frames: <BorderVisualFrameSnapshot>[
      BorderVisualFrameSnapshot(
        relativeAssetPath:
            'assets/borders/snapshots/synthetic/$fingerprint.png',
        sourceRectPx: BorderPixelRect(
          x: 0,
          y: 0,
          width: size.width,
          height: size.height,
        ),
        durationMs: 100,
      ),
    ],
  );
}

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

Future<ui.Image> _groundTile() => _syntheticImage(
      width: linearGoldenSourceTileSize,
      height: linearGoldenSourceTileSize,
      paint: (canvas) {
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 16, 16),
          ui.Paint()..color = const ui.Color(0xFF58784A),
        );
        canvas.drawRect(
          const ui.Rect.fromLTWH(2, 3, 2, 1),
          ui.Paint()..color = const ui.Color(0xFF6C8D56),
        );
        canvas.drawRect(
          const ui.Rect.fromLTWH(11, 11, 1, 2),
          ui.Paint()..color = const ui.Color(0xFF45633E),
        );
      },
    );

Future<ui.Image> _masonryStone({
  required ui.Color base,
  required ui.Color highlight,
}) =>
    _syntheticImage(
      width: 12,
      height: 10,
      paint: (canvas) {
        canvas.drawRect(
          _uiRect(_masonryStoneOpaqueRects[0]),
          ui.Paint()..color = const ui.Color(0xFF3F3933),
        );
        canvas.drawRect(
          _uiRect(_masonryStoneOpaqueRects[1]),
          ui.Paint()..color = base,
        );
        canvas.drawRect(
          _uiRect(_masonryStoneOpaqueRects[2]),
          ui.Paint()..color = highlight,
        );
        canvas.drawRect(
          _uiRect(_masonryStoneOpaqueRects[3]),
          ui.Paint()..color = const ui.Color(0xFF4A433C),
        );
      },
    );

Future<ui.Image> _fencePost() => _syntheticImage(
      width: 8,
      height: 16,
      paint: (canvas) {
        canvas.drawRect(
          _uiRect(_fencePostOpaqueRects[0]),
          ui.Paint()..color = const ui.Color(0xFF3D2718),
        );
        canvas.drawRect(
          _uiRect(_fencePostOpaqueRects[1]),
          ui.Paint()..color = const ui.Color(0xFF8D5D2D),
        );
        canvas.drawRect(
          _uiRect(_fencePostOpaqueRects[2]),
          ui.Paint()..color = const ui.Color(0xFFC18A46),
        );
        canvas.drawRect(
          _uiRect(_fencePostOpaqueRects[3]),
          ui.Paint()..color = const ui.Color(0xFFB8B0A3),
        );
      },
    );

Future<ui.Image> _fenceRail() => _syntheticImage(
      width: 16,
      height: 6,
      paint: (canvas) {
        canvas.drawRect(
          _uiRect(_fenceRailOpaqueRects[0]),
          ui.Paint()..color = const ui.Color(0xFF3D2718),
        );
        canvas.drawRect(
          _uiRect(_fenceRailOpaqueRects[1]),
          ui.Paint()..color = const ui.Color(0xFF7B4B26),
        );
        canvas.drawRect(
          _uiRect(_fenceRailOpaqueRects[2]),
          ui.Paint()..color = const ui.Color(0xFFB37839),
        );
      },
    );

ui.Rect _uiRect(_SyntheticOpaqueRect rect) => ui.Rect.fromLTWH(
      rect.x.toDouble(),
      rect.y.toDouble(),
      rect.width.toDouble(),
      rect.height.toDouble(),
    );

Future<ui.Image> _syntheticImage({
  required int width,
  required int height,
  required void Function(ui.Canvas canvas) paint,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

const linearGoldenGroundTilesetId = 'synthetic-linear-ground';
