import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart';
import 'package:map_editor/src/features/border_map_editing/presentation/border_preview_painter.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CanonicalCoastFixture fixture;
  var images = <String, ui.Image?>{};

  setUp(() async {
    fixture = _CanonicalCoastFixture();
    images = await fixture.loadSyntheticImages();
  });

  tearDown(() {
    for (final image in images.values.whereType<ui.Image>()) {
      image.dispose();
    }
  });

  test('canonical applied organic coast matches its tracked golden', () async {
    final applied = fixture.resolveFeature(seed: 271828);
    final map = fixture.mapWithFeature(applied);
    final image = await fixture.render(map: map, images: images);

    await expectLater(
      image,
      matchesGoldenFile('goldens/organic_coast_applied.png'),
    );
    image.dispose();
  });

  test('saved and transient preview comparison matches its tracked golden',
      () async {
    final saved = fixture.resolveFeature(seed: 271828);
    final proposed = fixture.feature(seed: 271829);
    final previewResult = fixture.resolve(proposed);
    expect(previewResult.canApply, isTrue);
    final map = fixture.mapWithFeature(saved);
    final preview = BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/golden',
        activeMapPath: '/golden/map.json',
        projectIdentity: fixture,
        mapIdentity: map,
        borderCatalogFingerprint: 'golden-catalog',
      ),
      mapId: map.id,
      mapSize: map.size,
      layerId: _borderLayerId,
      featureId: saved.id,
      baseFeatureFingerprint: 'golden-saved-feature',
      proposedFeature: proposed,
      variationOrdinal: 1,
      result: previewResult,
    );
    final image = await fixture.renderBeforeAfter(
      map: map,
      preview: preview,
      images: images,
    );

    await expectLater(
      image,
      matchesGoldenFile('goldens/organic_coast_before_after_preview.png'),
    );
    image.dispose();
  });

  test('organic warning and error diagnostics match their tracked golden',
      () async {
    final saved = fixture.resolveFeature(seed: 271828);
    final map = fixture.mapWithFeature(saved);
    final invalidPreview = BorderPreviewTransaction(
      context: BorderPreviewContext(
        projectRootPath: '/golden',
        activeMapPath: '/golden/map.json',
        projectIdentity: fixture,
        mapIdentity: map,
        borderCatalogFingerprint: 'golden-catalog',
      ),
      mapId: map.id,
      mapSize: map.size,
      layerId: _borderLayerId,
      featureId: saved.id,
      baseFeatureFingerprint: 'golden-saved-feature',
      proposedFeature: fixture.feature(seed: 271828),
      variationOrdinal: 0,
      result: BorderResolutionResult(
        materialization: null,
        diagnosticReport: BorderDiagnosticsReport(
          diagnostics: <BorderDiagnostic>[
            BorderDiagnostic(
              code: 'border.resolution.coverage_overlap',
              severity: BorderDiagnosticSeverity.warning,
              phase: BorderDiagnosticPhase.resolution,
              scope: BorderDiagnosticScope.feature,
              featureId: _featureId,
              cell: const GridPos(x: 9, y: 4),
              suggestedAction: 'border.action.reduce_overlap_or_adjust_assets',
            ),
            BorderDiagnostic(
              code: 'border.resolution.orientation_unavailable',
              severity: BorderDiagnosticSeverity.error,
              phase: BorderDiagnosticPhase.resolution,
              scope: BorderDiagnosticScope.feature,
              featureId: _featureId,
              cell: const GridPos(x: 7, y: 14),
              suggestedAction: 'border.action.allow_required_orientation',
            ),
          ],
        ),
      ),
    );
    final image = await fixture.render(
      map: map,
      images: images,
      preview: invalidPreview,
      diagnosticPalette: const EditorBorderDiagnosticOverlayPalette(
        warningFill: ui.Color(0xCCE6B449),
        warningStroke: ui.Color(0xFFFFD35A),
        errorFill: ui.Color(0xCCD34A5A),
        errorStroke: ui.Color(0xFFFF6577),
      ),
    );

    await expectLater(
      image,
      matchesGoldenFile('goldens/organic_coast_diagnostics.png'),
    );
    image.dispose();
  });
}

final class _CanonicalCoastFixture {
  _CanonicalCoastFixture() {
    primitives = <BorderPublishedPrimitive>[
      _primitive('rock-a', 'a'),
      _primitive('rock-b', 'b'),
      _primitive('rock-c', 'c'),
    ];
    snapshots = <BorderVisualSnapshot>[
      for (final primitive in primitives) _snapshot(primitive.visualSnapshotId),
      _snapshot(_groundSnapshotId),
    ];
    revision = BorderBlueprintRevision(
      revision: 7,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Côte organique canonique',
        previewSeed: BorderSignedInt64.fromInt(271828),
        template: BorderBlueprintTemplate.organicEdge,
        primitives: primitives,
        defaults: BorderGenerationParams(
          irregularityPermille: 350,
          detailDensityPermille: 0,
          variationPermille: 1000,
          maxOverlapPx: 0,
          gapTolerancePx: 0,
          depthRows: 1,
        ),
        ground: BorderPublishedGround(
          sourceSmartTilePresetId: 'synthetic-coast-ground',
          edgeBandCells: 2,
          visualSnapshotIdsByRole: <BorderGroundVariantRole, String>{
            for (final role in standardBorderGroundVariantRoleOrder)
              role: _groundSnapshotId,
          },
        ),
        sortOrder: 0,
      ),
    );
  }

  late final List<BorderPublishedPrimitive> primitives;
  late final List<BorderVisualSnapshot> snapshots;
  late final BorderBlueprintRevision revision;

  BorderRegionGeometry get geometry {
    const landStartByRow = <int>[
      8,
      7,
      7,
      8,
      9,
      8,
      10,
      11,
      9,
      8,
      7,
      8,
      9,
      7,
      6,
      7,
      8,
      9,
    ];
    const island = <(int, int)>{
      (2, 4),
      (3, 4),
      (2, 5),
      (3, 5),
      (2, 6),
    };
    return BorderRegionGeometry(
      width: _mapWidth,
      height: _mapHeight,
      cells: <bool>[
        for (var y = 0; y < _mapHeight; y += 1)
          for (var x = 0; x < _mapWidth; x += 1)
            x >= landStartByRow[y] || island.contains((x, y)),
      ],
    );
  }

  BorderFeature feature(
          {required int seed, BorderMaterialization? materialization}) =>
      BorderFeature(
        id: _featureId,
        name: 'Côte canonique',
        blueprintId: _blueprintId,
        seed: BorderSignedInt64.fromInt(seed),
        geometry: geometry,
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
        materialization: materialization,
      );

  BorderResolutionResult resolve(BorderFeature feature) =>
      resolveOrganicEdgeBorder(
        BorderResolutionRequest(
          mapSize: const GridSize(width: _mapWidth, height: _mapHeight),
          tileSizePx:
              const GridSize(width: _sourceTileSize, height: _sourceTileSize),
          blueprintId: _blueprintId,
          blueprintRevision: revision,
          feature: feature,
          visualSnapshots: snapshots,
          resolverVersion: 1,
        ),
      );

  BorderFeature resolveFeature({required int seed}) {
    final draft = feature(seed: seed);
    final result = resolve(draft);
    if (!result.canApply || result.materialization == null) {
      throw StateError('Canonical coast fixture must resolve successfully.');
    }
    return feature(seed: seed, materialization: result.materialization);
  }

  MapData mapWithFeature(BorderFeature feature) => MapData(
        id: 'canonical-organic-coast',
        name: 'Canonical organic coast',
        version: ProjectVersion.v6,
        size: const GridSize(width: _mapWidth, height: _mapHeight),
        properties: const <String, dynamic>{
          'tileLayerOrder': 'bottom_to_top',
        },
        layers: <MapLayer>[
          TileLayer(
            id: 'water',
            name: 'Water',
            tilesetId: _waterTilesetId,
            tiles: List<int>.filled(_mapWidth * _mapHeight, 1),
          ),
          TileLayer(
            id: 'land',
            name: 'Land',
            tilesetId: _landTilesetId,
            tiles: <int>[
              for (final cell in geometry.cells)
                if (cell) 1 else 0
            ],
          ),
          MapLayer.border(
            id: _borderLayerId,
            name: 'Côte',
            content: BorderLayerContent(features: <BorderFeature>[feature]),
          ),
        ],
      );

  ProjectManifest get project => ProjectManifest(
        name: 'Canonical coast golden',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        borderCatalog: ProjectBorderCatalog(visualSnapshots: snapshots),
      );

  Future<Map<String, ui.Image?>> loadSyntheticImages() async =>
      <String, ui.Image?>{
        _waterTilesetId: await _waterTile(),
        _landTilesetId: await _landTile(),
        editorBorderFrameImageKey(_snapshotId('a'), 0):
            await _rockTile(const ui.Color(0xFF6E675C)),
        editorBorderFrameImageKey(_snapshotId('b'), 0):
            await _rockTile(const ui.Color(0xFF82796A)),
        editorBorderFrameImageKey(_snapshotId('c'), 0):
            await _rockTile(const ui.Color(0xFF938878)),
        editorBorderFrameImageKey(_groundSnapshotId, 0): await _shoreTile(),
      };

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
      ui.Size(_canvasWidth.toDouble(), _canvasHeight.toDouble()),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(_canvasWidth, _canvasHeight);
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
      ui.Size(_canvasWidth.toDouble(), _canvasHeight.toDouble()),
    );
    canvas.save();
    canvas.translate((_canvasWidth + _panelGap).toDouble(), 0);
    _painter(map: map, images: images, preview: preview).paint(
      canvas,
      ui.Size(_canvasWidth.toDouble(), _canvasHeight.toDouble()),
    );
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      _canvasWidth * 2 + _panelGap,
      _canvasHeight,
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
        tileWidth: _displayTileSize,
        tileHeight: _displayTileSize,
        tilesetImagesById: images,
        sourceTileWidth: _sourceTileSize,
        sourceTileHeight: _sourceTileSize,
        tilesPerRowById: const <String, int>{
          _waterTilesetId: 1,
          _landTilesetId: 1,
        },
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        project: project,
        borderPreview: preview,
        borderDiagnosticOverlayPalette: diagnosticPalette,
      );
}

BorderPublishedPrimitive _primitive(String id, String fingerprintCharacter) =>
    BorderPublishedPrimitive(
      id: id,
      sourceElementId: 'synthetic-$id',
      visualSnapshotId: _snapshotId(fingerprintCharacter),
      role: BorderPrimitiveRole.structureLarge,
      weight: 1,
      anchorPx: const BorderPixelPos(x: 8, y: 8),
      transforms: BorderTransformPolicy(
        allowFlipX: true,
        allowedQuarterTurns: const <int>[0, 1, 2, 3],
      ),
      publishedMetrics: BorderPrimitiveAssetMetrics(
        assetFingerprint: 'synthetic-$id',
        pixelSize:
            const GridSize(width: _sourceTileSize, height: _sourceTileSize),
        opaqueBounds: BorderPixelRect(
          x: 0,
          y: 0,
          width: _sourceTileSize,
          height: _sourceTileSize,
        ),
        defaultAnchorPx: const BorderPixelPos(x: 8, y: 8),
        occupancyMaskRle: encodeBorderRleMask(
          List<bool>.filled(_sourceTileSize * _sourceTileSize, true),
        ),
      ),
    );

BorderVisualSnapshot _snapshot(String id) => BorderVisualSnapshot(
      id: id,
      contentFingerprint: id.substring('border-snapshot-sha256:'.length),
      frames: <BorderVisualFrameSnapshot>[
        BorderVisualFrameSnapshot(
          relativeAssetPath:
              'assets/borders/snapshots/synthetic/${id.substring('border-snapshot-sha256:'.length)}.png',
          sourceRectPx: BorderPixelRect(
            x: 0,
            y: 0,
            width: _sourceTileSize,
            height: _sourceTileSize,
          ),
          durationMs: 100,
        ),
      ],
    );

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

Future<ui.Image> _waterTile() => _syntheticTile((canvas) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 16, 16),
        ui.Paint()..color = const ui.Color(0xFF1C69A8),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(2, 4, 6, 1),
        ui.Paint()..color = const ui.Color(0xFF4B9DD0),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(9, 11, 5, 1),
        ui.Paint()..color = const ui.Color(0xFF2E82BD),
      );
    });

Future<ui.Image> _landTile() => _syntheticTile((canvas) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 16, 16),
        ui.Paint()..color = const ui.Color(0xFF4F8A46),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(3, 3, 2, 2),
        ui.Paint()..color = const ui.Color(0xFF72A957),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(11, 9, 1, 3),
        ui.Paint()..color = const ui.Color(0xFF3E753B),
      );
    });

Future<ui.Image> _shoreTile() => _syntheticTile((canvas) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 16, 16),
        ui.Paint()..color = const ui.Color(0xFFD6BA78),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 16, 5),
        ui.Paint()..color = const ui.Color(0xFF6EA34F),
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(2, 10, 3, 2),
        ui.Paint()..color = const ui.Color(0xFFE8D397),
      );
    });

Future<ui.Image> _rockTile(ui.Color base) => _syntheticTile((canvas) {
      canvas.drawRect(
        const ui.Rect.fromLTWH(1, 3, 14, 11),
        ui.Paint()..color = base,
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(4, 1, 8, 4),
        ui.Paint()
          ..color = ui.Color.lerp(base, const ui.Color(0xFFFFFFFF), 0.24)!,
      );
      canvas.drawRect(
        const ui.Rect.fromLTWH(3, 11, 10, 3),
        ui.Paint()
          ..color = ui.Color.lerp(base, const ui.Color(0xFF000000), 0.24)!,
      );
    });

Future<ui.Image> _syntheticTile(void Function(ui.Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_sourceTileSize, _sourceTileSize);
  picture.dispose();
  return image;
}

const _mapWidth = 24;
const _mapHeight = 18;
const _sourceTileSize = 16;
const _displayTileSize = 8.0;
const _canvasWidth = 192;
const _canvasHeight = 144;
const _panelGap = 8;
const _blueprintId = 'canonical-organic-coast';
const _featureId = 'canonical-coast-feature';
const _borderLayerId = 'border';
const _waterTilesetId = 'synthetic-water';
const _landTilesetId = 'synthetic-land';
final _groundSnapshotId = _snapshotId('d');
