import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/map_visual_stack_migration_use_case.dart';
import 'package:map_editor/src/ui/canvas/map_visual_stack_migration_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const useCase = MapVisualStackMigrationUseCase();

  test(
      'real painter comparison detects a semi-transparent layer revealed by '
      'migration', () async {
    final preview = await useCase.preview(
      _alphaReorderMap(),
      compareRenderedPixels: MapGridPainterVisualStackMigrationComparator(
        inputs: _renderInputs(
          assetPathsById: const <String, String>{
            'red': '/virtual/red.png',
            'blue': '/virtual/blue.png',
          },
        ),
        imageLoader: (paths, transparentColors) async => <String, ui.Image?>{
          'red': await _solidImage(const ui.Color(0xFFFF0000)),
          'blue': await _solidImage(const ui.Color(0xFF0000FF)),
        },
      ).compare,
    );
    final pixels = preview.pixelComparison!;

    expect(preview.canApply, isTrue);
    expect(pixels.width, 1);
    expect(pixels.height, 1);
    expect(pixels.changedPixelCount, 1);
    expect(pixels.changedBounds?.left, 0);
    expect(pixels.changedBounds?.top, 0);
    expect(pixels.changedBounds?.right, 0);
    expect(pixels.changedBounds?.bottom, 0);
    expect(pixels.beforeFingerprint, isNot(pixels.afterFingerprint));
    expect(
      pixels.limitations,
      contains(contains('rendu statique')),
    );
  });

  test('real painter comparison honors a multi-cell placed footprint',
      () async {
    const map = MapData(
      id: 'multi-cell',
      name: 'Multi-cell',
      size: GridSize(width: 2, height: 1),
      version: ProjectVersion.v2,
      properties: <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[
        TileLayer(
          id: 'top',
          name: 'Top',
          tiles: <int>[0, 0],
        ),
        TileLayer(
          id: 'bottom',
          name: 'Bottom',
          tilesetId: 'blue',
          tiles: <int>[1, 1],
        ),
      ],
      placedElements: <MapPlacedElement>[
        MapPlacedElement(
          id: 'wide-element',
          layerId: 'top',
          elementId: 'wide',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final preview = await useCase.preview(
      map,
      compareRenderedPixels: MapGridPainterVisualStackMigrationComparator(
        inputs: _renderInputs(
          assetPathsById: const <String, String>{
            'blue': '/virtual/blue.png',
            'green': '/virtual/green.png',
          },
          elements: const <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'wide',
              name: 'Wide',
              tilesetId: 'green',
              categoryId: 'fixture',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 2),
                ),
              ],
            ),
          ],
        ),
        imageLoader: (paths, transparentColors) async {
          expect(paths.keys.toSet(), <String>{'blue', 'green'});
          return <String, ui.Image?>{
            for (final id in paths.keys)
              id: await _solidImage(
                id == 'green'
                    ? const ui.Color(0xFF00FF00)
                    : const ui.Color(0xFF0000FF),
                width: 2,
              ),
          };
        },
      ).compare,
    );

    expect(preview.canApply, isTrue);
    expect(preview.pixelComparison?.changedPixelCount, 2);
    expect(preview.pixelComparison?.changedBounds?.left, 0);
    expect(preview.pixelComparison?.changedBounds?.right, 1);
  });

  test('real painter comparison excludes editor overlays and map outline',
      () async {
    const map = MapData(
      id: 'overlay-only',
      name: 'Overlay only',
      size: GridSize(width: 2, height: 2),
      version: ProjectVersion.v2,
      triggers: <MapTrigger>[
        MapTrigger(
          id: 'trigger',
          name: 'Editor overlay',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 0, y: 0),
            size: GridSize(width: 2, height: 2),
          ),
        ),
      ],
      connections: <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.north,
          targetMapId: 'other',
        ),
      ],
      events: <MapEventDefinition>[
        MapEventDefinition(
          id: 'event',
          pages: <MapEventPage>[],
          position: EventPosition(layerId: 'none', x: 0, y: 0),
        ),
      ],
    );
    final preview = await useCase.preview(
      map,
      compareRenderedPixels: MapGridPainterVisualStackMigrationComparator(
        inputs: _renderInputs(),
        imageLoader: (paths, transparentColors) async => const {},
      ).compare,
    );
    final pixels = preview.pixelComparison!;
    final transparentFingerprint = _transparentRgbaFingerprint(
      pixels.width * pixels.height,
    );

    expect(preview.canApply, isTrue);
    expect(pixels.changedPixelCount, 0);
    expect(pixels.beforeFingerprint, transparentFingerprint);
    expect(pixels.afterFingerprint, transparentFingerprint);
  });

  test('missing render asset fails closed and blocks apply', () async {
    final map = _singleTileMap(tilesetId: 'missing');
    final preview = await useCase.preview(
      map,
      compareRenderedPixels: MapGridPainterVisualStackMigrationComparator(
        inputs: _renderInputs(),
        imageLoader: (paths, transparentColors) async => const {},
      ).compare,
    );

    expect(preview.migration.status, MapVisualStackMigrationStatus.ready);
    expect(preview.pixelComparison, isNull);
    expect(preview.pixelComparisonError, contains('asset'));
    expect(preview.pixelComparisonError, contains('missing'));
    expect(preview.canApply, isFalse);
    expect(
      () => useCase.apply(map: map, preview: preview),
      throwsStateError,
    );
  });

  test('oversized real render fails closed before loading images', () async {
    var loadCalled = false;
    const map = MapData(
      id: 'oversized',
      name: 'Oversized',
      size: GridSize(width: 2, height: 1),
    );
    final preview = await useCase.preview(
      map,
      compareRenderedPixels: MapGridPainterVisualStackMigrationComparator(
        inputs: _renderInputs(),
        maxRenderedPixelCount: 1,
        imageLoader: (paths, transparentColors) async {
          loadCalled = true;
          return const {};
        },
      ).compare,
    );

    expect(loadCalled, isFalse);
    expect(preview.migration.status, MapVisualStackMigrationStatus.ready);
    expect(preview.pixelComparison, isNull);
    expect(preview.pixelComparisonError, contains('limite sûre'));
    expect(preview.canApply, isFalse);
    expect(
      () => useCase.apply(map: map, preview: preview),
      throwsStateError,
    );
  });

  test('apply is stale-safe and rerun is an exact no-op', () async {
    final map = _singleTileMap(tilesetId: 'tile');
    final comparator = _opaqueComparator(
      assetPathsById: const <String, String>{
        'tile': '/virtual/tile.png',
      },
    );
    final preview = await useCase.preview(
      map,
      compareRenderedPixels: comparator.compare,
    );

    expect(
      () => useCase.apply(
        map: map.copyWith(name: 'Changed'),
        preview: preview,
      ),
      throwsStateError,
    );

    final migrated = useCase.apply(map: map, preview: preview);
    final rerun = await useCase.preview(
      migrated,
      compareRenderedPixels: comparator.compare,
    );
    final unchanged = useCase.apply(map: migrated, preview: rerun);

    expect(migrated.version, ProjectVersion.v3);
    expect(migrated.visualStack, MapVisualStackConfig.canonicalV1);
    expect(rerun.migration.status, MapVisualStackMigrationStatus.noChange);
    expect(unchanged, same(migrated));
  });

  test('future semantics are blocked without a rendered-pixel fallback',
      () async {
    final map = MapData(
      id: 'future',
      name: 'Future',
      size: const GridSize(width: 1, height: 1),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig(semanticsVersion: 99),
    );
    var comparisonCalled = false;

    final preview = await useCase.preview(
      map,
      compareRenderedPixels: ({required before, required after}) async {
        comparisonCalled = true;
        throw StateError('must not be called');
      },
    );

    expect(comparisonCalled, isFalse);
    expect(preview.canApply, isFalse);
    expect(
      preview.migration.status,
      MapVisualStackMigrationStatus.blocked,
    );
    expect(preview.pixelComparison, isNull);
    expect(preview.pixelComparisonError, isNull);
  });
}

MapData _alphaReorderMap() => const MapData(
      id: 'alpha-reorder',
      name: 'Alpha reorder',
      size: GridSize(width: 1, height: 1),
      version: ProjectVersion.v2,
      properties: <String, dynamic>{
        'tileLayerOrder': 'bottom_to_top',
      },
      layers: <MapLayer>[
        TileLayer(
          id: 'top',
          name: 'Top',
          opacity: 0.5,
          tilesetId: 'red',
          tiles: <int>[1],
        ),
        TileLayer(
          id: 'bottom',
          name: 'Bottom',
          tilesetId: 'blue',
          tiles: <int>[1],
        ),
      ],
    );

MapData _singleTileMap({required String tilesetId}) => MapData(
      id: 'single-tile',
      name: 'Single tile',
      size: const GridSize(width: 1, height: 1),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        TileLayer(
          id: 'tile',
          name: 'Tile',
          tilesetId: tilesetId,
          tiles: const <int>[1],
        ),
      ],
    );

MapVisualStackMigrationRenderInputs _renderInputs({
  Map<String, String> assetPathsById = const <String, String>{},
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) =>
    MapVisualStackMigrationRenderInputs(
      project: ProjectManifest(
        name: 'Migration render fixture',
        version: ProjectVersion.v3,
        maps: const <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          for (final entry in assetPathsById.entries)
            ProjectTilesetEntry(
              id: entry.key,
              name: entry.key,
              relativePath: entry.value,
            ),
        ],
        elements: elements,
        settings: const ProjectSettings(
          tileWidth: 1,
          tileHeight: 1,
          displayScale: 1,
        ),
      ),
      projectRootPath: '/virtual',
      assetPathsById: assetPathsById,
      pathAutotileSetsByPresetId: const {},
      terrainPresetsByType: const {},
    );

MapGridPainterVisualStackMigrationComparator _opaqueComparator({
  required Map<String, String> assetPathsById,
}) =>
    MapGridPainterVisualStackMigrationComparator(
      inputs: _renderInputs(assetPathsById: assetPathsById),
      imageLoader: (paths, transparentColors) async => <String, ui.Image?>{
        for (final id in paths.keys)
          id: await _solidImage(const ui.Color(0xFFFFFFFF)),
      },
    );

Future<ui.Image> _solidImage(
  ui.Color color, {
  int width = 1,
  int height = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

String _transparentRgbaFingerprint(int pixelCount) {
  var hash = 0x811c9dc5;
  for (var index = 0; index < pixelCount * 4; index += 1) {
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 'fnv1a32:${hash.toRadixString(16).padLeft(8, '0')}';
}
