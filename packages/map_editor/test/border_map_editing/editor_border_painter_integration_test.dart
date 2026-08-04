import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  test('paints a later Border above an earlier Tile', () async {
    final borderImage = await _solidImage(const ui.Color(0xFFFF0000));
    final tileImage = await _solidImage(const ui.Color(0xFF0000FF));
    final map = MapData(
      id: 'tile-before-border',
      name: 'Tile before Border',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      properties: const <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[
        const MapLayer.tile(
          id: 'tile',
          name: 'Tile',
          cells: <int>[1],
        ),
        MapLayer.border(
          id: 'border',
          name: 'Border',
          content: BorderLayerContent(features: <BorderFeature>[_feature()]),
        ),
      ],
    );

    final color = await _paintCenter(
      map,
      project: _manifest(),
      images: <String, ui.Image?>{
        'tiles': tileImage,
        editorBorderFrameImageKey(_snapshotId, 0): borderImage,
      },
    );

    expect(color, const ui.Color(0xFFFF0000));
    borderImage.dispose();
    tileImage.dispose();
  });

  test('paints two overlapping Border layers in authored order', () async {
    final red = await _solidImage(const ui.Color(0xFFFF0000));
    final green = await _solidImage(const ui.Color(0xFF00FF00));
    final map = MapData(
      id: 'two-borders',
      name: 'Two Borders',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      properties: const <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border-low',
          name: 'Border low',
          content: BorderLayerContent(
            features: <BorderFeature>[_feature(id: 'low')],
          ),
        ),
        MapLayer.border(
          id: 'border-high',
          name: 'Border high',
          content: BorderLayerContent(
            features: <BorderFeature>[
              _feature(id: 'high', snapshotId: _unusedSnapshotId),
            ],
          ),
        ),
      ],
    );

    final color = await _paintCenter(
      map,
      project: _manifest(
        snapshots: <BorderVisualSnapshot>[
          _snapshot(),
          _snapshot(id: _unusedSnapshotId, assetName: 'green'),
        ],
      ),
      images: <String, ui.Image?>{
        editorBorderFrameImageKey(_snapshotId, 0): red,
        editorBorderFrameImageKey(_unusedSnapshotId, 0): green,
      },
    );

    expect(color, const ui.Color(0xFF00FF00));
    red.dispose();
    green.dispose();
  });

  test('resolved preview replaces only its exact target until apply', () async {
    final red = await _solidImage(const ui.Color(0xFFFF0000));
    final blue = await _solidImage(const ui.Color(0xFF0000FF));
    final first = _feature(id: 'first', x: 0);
    final second = _feature(id: 'second', x: 1);
    final map = _borderMap(
      width: 2,
      features: <BorderFeature>[first, second],
    );
    final previewMaterialization = _materialization(
      x: 0,
      snapshotId: _previewSnapshotId,
    );
    final preview = BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/painter',
        activeMapPath: '/painter/map.json',
        projectIdentity: map,
        mapIdentity: map,
        borderCatalogFingerprint: 'painter-catalog',
      ),
      mapId: map.id,
      mapSize: map.size,
      layerId: 'border',
      featureId: first.id,
      baseFeatureFingerprint: 'saved-feature',
      proposedFeature: first,
      variationOrdinal: 0,
      result: BorderResolutionResult(
        materialization: previewMaterialization,
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
    );
    final manifest = _manifest(
      snapshots: <BorderVisualSnapshot>[
        _snapshot(),
        _snapshot(id: _previewSnapshotId, assetName: 'blue'),
      ],
    );
    final images = <String, ui.Image?>{
      editorBorderFrameImageKey(_snapshotId, 0): red,
      editorBorderFrameImageKey(_previewSnapshotId, 0): blue,
    };

    final saved = await _paintPixel(
      map,
      project: manifest,
      images: images,
      x: 8,
      y: 8,
    );
    final previewTarget = await _paintPixel(
      map,
      project: manifest,
      images: images,
      preview: preview,
      x: 8,
      y: 8,
    );
    final untouchedNeighbour = await _paintPixel(
      map,
      project: manifest,
      images: images,
      preview: preview,
      x: 24,
      y: 8,
    );

    expect(saved, const ui.Color(0xFFFF0000));
    expect(previewTarget, const ui.Color(0xFF0000FF));
    expect(untouchedNeighbour, const ui.Color(0xFFFF0000));
    red.dispose();
    blue.dispose();
  });

  test('preview materialization rejects a cloned map with the same id', () {
    final map = _borderMap(features: <BorderFeature>[_feature()]);
    final clone = MapData.fromJson(map.toJson());
    final preview = BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/painter',
        activeMapPath: '/painter/map.json',
        projectIdentity: map,
        mapIdentity: map,
        borderCatalogFingerprint: 'painter-catalog',
      ),
      mapId: map.id,
      mapSize: map.size,
      layerId: 'border',
      featureId: 'feature',
      baseFeatureFingerprint: 'saved-feature',
      proposedFeature: _feature(),
      variationOrdinal: 0,
      result: BorderResolutionResult(
        materialization: _materialization(x: 0, snapshotId: _snapshotId),
        diagnosticReport: const BorderDiagnosticsReport.empty(),
      ),
    );

    expect(
      editorBorderPreviewMaterializationForMap(map: map, preview: preview),
      isNotNull,
    );
    expect(
      editorBorderPreviewMaterializationForMap(map: clone, preview: preview),
      isNull,
    );
  });

  test('stale preview diagnostics never paint on another map', () async {
    final owner = _borderMap(features: <BorderFeature>[_feature()]);
    final current = MapData(
      id: owner.id,
      name: 'Other map with same id',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
    );
    final preview = BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/painter',
        activeMapPath: '/painter/map.json',
        projectIdentity: owner,
        mapIdentity: owner,
        borderCatalogFingerprint: 'painter-catalog',
      ),
      mapId: owner.id,
      mapSize: owner.size,
      layerId: 'border',
      featureId: 'feature',
      baseFeatureFingerprint: 'saved-feature',
      proposedFeature: _feature(),
      variationOrdinal: 0,
      result: BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            BorderDiagnostic(
              code: 'border.resolution.coverage_gap',
              severity: BorderDiagnosticSeverity.error,
              phase: BorderDiagnosticPhase.resolution,
              scope: BorderDiagnosticScope.feature,
              featureId: 'feature',
              cell: const GridPos(x: 0, y: 0),
              suggestedAction: 'border.action.edit_geometry',
            ),
          ],
        ),
      ),
    );
    const palette = EditorBorderDiagnosticOverlayPalette(
      warningFill: ui.Color(0xFFFFAA00),
      warningStroke: ui.Color(0xFFFFAA00),
      errorFill: ui.Color(0xFFFF0000),
      errorStroke: ui.Color(0xFFFF0000),
    );

    final baseline = await _paintPixel(
      current,
      project: _manifest(),
      images: const <String, ui.Image?>{},
      x: 8,
      y: 8,
    );
    final withStalePreview = await _paintPixel(
      current,
      project: _manifest(),
      images: const <String, ui.Image?>{},
      preview: preview,
      diagnosticPalette: palette,
      x: 8,
      y: 8,
    );

    expect(withStalePreview, baseline);
  });

  test('applies authored Border layer opacity to snapshot pixels', () async {
    final red = await _solidImage(const ui.Color(0xFFFF0000));
    final map = _borderMap(
      opacity: 0.5,
      features: <BorderFeature>[_feature()],
    );

    final color = await _paintPixel(
      map,
      project: _manifest(),
      images: <String, ui.Image?>{
        editorBorderFrameImageKey(_snapshotId, 0): red,
      },
      x: 8,
      y: 8,
    );

    // rawRgba is premultiplied, so 50% red is encoded as red=128, alpha=128.
    expect(color.toARGB32(), 0x80800000);
    red.dispose();
  });

  test('map with Border preserves the historical collision overlay pixels',
      () async {
    const collisionLow = CollisionLayer(
      id: 'collision-low',
      name: 'Collision low',
      collisions: <bool>[true],
    );
    const collisionHigh = CollisionLayer(
      id: 'collision-high',
      name: 'Collision high',
      collisions: <bool>[true],
    );
    const withoutBorder = MapData(
      id: 'collision-without-border',
      name: 'Collision without Border',
      size: GridSize(width: 1, height: 1),
      properties: <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[collisionLow, collisionHigh],
    );
    const withBorder = MapData(
      id: 'collision-with-border',
      name: 'Collision with Border',
      size: GridSize(width: 1, height: 1),
      properties: <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[
        collisionLow,
        BorderLayer(id: 'border-sentinel', name: 'Border sentinel'),
        collisionHigh,
      ],
    );

    final baseline = await _paintPixel(
      withoutBorder,
      project: _manifest(),
      images: const <String, ui.Image?>{},
      activeLayerId: collisionLow.id,
      x: 8,
      y: 8,
    );
    final authoredBorderPath = await _paintPixel(
      withBorder,
      project: _manifest(),
      images: const <String, ui.Image?>{},
      activeLayerId: collisionLow.id,
      x: 8,
      y: 8,
    );

    expect(authoredBorderPath, baseline);
    expect(authoredBorderPath.toARGB32(), isNot(0));
  });
}

Future<ui.Color> _paintPixel(
  MapData map, {
  required ProjectManifest project,
  required Map<String, ui.Image?> images,
  required int x,
  required int y,
  BorderPreviewTransaction? preview,
  EditorBorderDiagnosticOverlayPalette? diagnosticPalette,
  String? activeLayerId,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    activeLayerId: activeLayerId,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: images,
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{'tiles': 1},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    project: project,
    borderPreview: preview,
    borderDiagnosticOverlayPalette: diagnosticPalette,
  ).paint(canvas, const ui.Size(16, 16));
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    map.size.width * 16,
    map.size.height * 16,
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = ((y * image.width) + x) * 4;
  final color = ui.Color.fromARGB(
    bytes!.getUint8(offset + 3),
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
  );
  picture.dispose();
  image.dispose();
  return color;
}

Future<ui.Color> _paintCenter(
  MapData map, {
  required ProjectManifest project,
  required Map<String, ui.Image?> images,
}) =>
    _paintPixel(
      map,
      project: project,
      images: images,
      x: 8,
      y: 8,
    );

Future<ui.Image> _solidImage(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 16, 16),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 16);
  picture.dispose();
  return image;
}

ProjectManifest _manifest({
  List<BorderBlueprintRecord> records = const <BorderBlueprintRecord>[],
  List<BorderVisualSnapshot>? snapshots,
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) =>
    ProjectManifest(
      name: 'Border order',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      elements: elements,
      borderCatalog: ProjectBorderCatalog(
        records: records,
        visualSnapshots: snapshots ?? <BorderVisualSnapshot>[_snapshot()],
      ),
    );

MapData _borderMap({
  int width = 1,
  double opacity = 1,
  required List<BorderFeature> features,
}) =>
    MapData(
      id: 'border-map',
      name: 'Border map',
      version: ProjectVersion.v6,
      size: GridSize(width: width, height: 1),
      properties: const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Border',
          opacity: opacity,
          content: BorderLayerContent(features: features),
        ),
      ],
    );

BorderFeature _feature({
  String id = 'feature',
  int x = 0,
  String snapshotId = _snapshotId,
}) =>
    BorderFeature(
      id: id,
      name: 'Feature',
      blueprintId: 'blueprint',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: 1,
        height: 1,
        cells: const <bool>[true],
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: _materialization(x: x, snapshotId: snapshotId),
    );

BorderMaterialization _materialization({
  required int x,
  required String snapshotId,
}) =>
    BorderMaterialization(
      receipt: _receipt(),
      ground: <BorderResolvedGroundCell>[
        BorderResolvedGroundCell(
          x: x,
          y: 0,
          visualSnapshotId: snapshotId,
          resolvedRole: BorderGroundVariantRole.isolated,
        ),
      ],
      placements: const <BorderResolvedPlacement>[],
    );

BorderVisualSnapshot _snapshot({
  String id = _snapshotId,
  String assetName = 'red',
}) =>
    BorderVisualSnapshot(
      id: id,
      contentFingerprint: id.substring('border-snapshot-sha256:'.length),
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/$assetName/frame_0000.png',
          sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 16, height: 16),
          durationMs: 100,
        ),
      ],
    );

BorderResolutionReceipt _receipt() {
  const fingerprint =
      'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  return BorderResolutionReceipt(
    resolverVersion: 1,
    blueprintRevision: 1,
    components: BorderInputFingerprints(
      blueprint: fingerprint,
      geometryAndSeed: fingerprint,
      parameters: fingerprint,
      overrides: fingerprint,
      keepOutRegions: fingerprint,
      mapContext: fingerprint,
      visualSnapshots: fingerprint,
    ),
    inputFingerprint: fingerprint,
    outputFingerprint: fingerprint,
  );
}

const _snapshotId =
    'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _unusedSnapshotId =
    'border-snapshot-sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _previewSnapshotId =
    'border-snapshot-sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
