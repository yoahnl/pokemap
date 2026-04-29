import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animation_browser_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TiledTsxAnimationBrowser models', () {
    test('builds browser items from the 242 imported Pokemon SDK animations',
        () {
      final result = _importTechAnimations();

      final items = buildTiledTsxAnimationBrowserItems(
        animations: result.animations,
      );
      final tile99 = items.singleWhere(
        (item) => item.animationId == 'tech-animations-tile-99',
      );

      expect(items, hasLength(242));
      expect(tile99.name, 'TECH-Animations tile 99');
      expect(tile99.baseTileId, 99);
      expect(tile99.frameCount, 16);
      expect(tile99.durationTotalMs, 1600);
      expect(tile99.firstFrameColumn, 1);
      expect(tile99.firstFrameRow, 1);
    });

    test('filters by animation id, display name, and base tile id', () {
      final items = buildTiledTsxAnimationBrowserItems(
        animations: _importTechAnimations().animations,
      );

      expect(
        filterTiledTsxAnimationBrowserItems(
          items: items,
          filter: const TiledTsxAnimationBrowserFilter(query: 'tile-99'),
          selectedAnimationIds: const <String>{},
        ).map((item) => item.animationId),
        contains('tech-animations-tile-99'),
      );
      expect(
        filterTiledTsxAnimationBrowserItems(
          items: items,
          filter: const TiledTsxAnimationBrowserFilter(query: '99'),
          selectedAnimationIds: const <String>{},
        ).map((item) => item.animationId),
        contains('tech-animations-tile-99'),
      );
      expect(
        filterTiledTsxAnimationBrowserItems(
          items: items,
          filter: const TiledTsxAnimationBrowserFilter(query: 'not-a-tile'),
          selectedAnimationIds: const <String>{},
        ),
        isEmpty,
      );
    });
  });

  group('TiledTsxAnimationBrowser widget', () {
    testWidgets('selects and clears animations without mutating the catalog',
        (tester) async {
      final result = _importTechAnimations();
      final catalog = ProjectSurfaceCatalog(
        atlases: [result.atlas!],
        animations: result.animations,
      );
      Set<String> lastSelection = const <String>{};

      await tester.pumpWidget(
        _wrapBrowser(
          TiledTsxAnimationBrowser(
            atlas: result.atlas,
            animations: result.animations,
            sourceLabel: 'TECH-Animations.tsx',
            onSelectionChanged: (ids) => lastSelection = ids,
          ),
        ),
      );

      expect(find.text('242 animations'), findsOneWidget);
      expect(find.text('0 animations sélectionnées'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey(
              'tiled_tsx_animation_browser.checkbox.tech-animations-tile-99'),
        ),
      );
      await tester.pumpAndSettle();

      expect(lastSelection, contains('tech-animations-tile-99'));
      expect(find.text('1 animation sélectionnée'), findsOneWidget);
      expect(catalog.animationCount, 242);
      expect(catalog.presetCount, 0);

      await tester.tap(
        find.byKey(
            const ValueKey('tiled_tsx_animation_browser.clear_selection')),
      );
      await tester.pumpAndSettle();

      expect(lastSelection, isEmpty);
      expect(find.text('0 animations sélectionnées'), findsOneWidget);
      expect(catalog.animationCount, 242);
      expect(catalog.presetCount, 0);
    });

    testWidgets('searches by tile id in the browser UI', (tester) async {
      final result = _importTechAnimations();

      await tester.pumpWidget(
        _wrapBrowser(
          TiledTsxAnimationBrowser(
            atlas: result.atlas,
            animations: result.animations,
            sourceLabel: 'TECH-Animations.tsx',
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('tiled_tsx_animation_browser.search')),
        'tile-99',
      );
      await tester.pumpAndSettle();

      expect(find.text('tech-animations-tile-99'), findsWidgets);
      expect(find.text('tech-animations-tile-100'), findsNothing);
    });

    testWidgets('shows imported TSX frame details for tile 99', (tester) async {
      final result = _importTechAnimations();

      await tester.pumpWidget(
        _wrapBrowser(
          TiledTsxAnimationBrowser(
            atlas: result.atlas,
            animations: result.animations,
            sourceLabel: 'TECH-Animations.tsx',
          ),
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
              'tiled_tsx_animation_browser.item.tech-animations-tile-99'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('tech-animations-tile-99'), findsWidgets);
      expect(find.textContaining('16 frames'), findsWidgets);
      expect(find.text('Frame 1 / 16'), findsOneWidget);
      expect(find.text('column 1, row 1'), findsWidgets);
      expect(find.text('100 ms'), findsWidgets);
    });
  });

  group('TiledTsxSurfaceAnimationPreview', () {
    testWidgets('steps through explicit ProjectSurfaceAnimation frames',
        (tester) async {
      final atlas = _miniAtlas();
      final animation = _miniAnimation();

      await tester.pumpWidget(
        _wrapBrowser(
          SizedBox(
            width: 420,
            child: TiledTsxSurfaceAnimationPreview(
              atlas: atlas,
              animation: animation,
              atlasImageBytes: _miniAtlasPng(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Frame 1 / 3'), findsOneWidget);
      expect(find.text('column 1, row 0'), findsWidgets);
      expect(find.text('80 ms'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('tiled_tsx_animation_preview.next')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frame 2 / 3'), findsOneWidget);
      expect(find.text('column 3, row 0'), findsWidgets);
      expect(find.text('120 ms'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('tiled_tsx_animation_preview.next')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frame 3 / 3'), findsOneWidget);
      expect(find.text('column 1, row 1'), findsWidgets);
      expect(find.text('160 ms'), findsWidgets);
    });

    testWidgets('lists frames when atlas image bytes are unavailable',
        (tester) async {
      await tester.pumpWidget(
        _wrapBrowser(
          SizedBox(
            width: 420,
            child: TiledTsxSurfaceAnimationPreview(
              atlas: _miniAtlas(),
              animation: _miniAnimation(),
            ),
          ),
        ),
      );

      expect(
        find.text(
            'Image atlas indisponible — frames listées sans aperçu visuel.'),
        findsOneWidget,
      );
      expect(find.text('column 1, row 0'), findsWidgets);
      expect(find.text('column 3, row 0'), findsWidgets);
      expect(find.text('column 1, row 1'), findsWidgets);
    });
  });
}

Widget _wrapBrowser(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 1100,
          height: 760,
          child: child,
        ),
      ),
    ),
  );
}

TiledTsxSurfaceAnimationImportResult _importTechAnimations() {
  return importTiledTsxSurfaceAnimationsFromXml(
    xml: _readTechAnimationsTsx(),
    options: const TiledTsxSurfaceAnimationImportOptions(
      atlasId: 'tech-animations',
      tilesetId: 'tech-nature-animations',
      animationIdPrefix: 'tech-animations',
    ),
  );
}

String _readTechAnimationsTsx() {
  final repoRoot = Directory.current.parent.parent;
  final sdkProject = repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
  final tsxFile = File(
    p.join(
      sdkProject.path,
      'Data',
      'Tiled',
      'Tilesets',
      'TECH-Animations.tsx',
    ),
  );
  return tsxFile.readAsStringSync();
}

ProjectSurfaceAtlas _miniAtlas() {
  return ProjectSurfaceAtlas(
    id: 'mini',
    name: 'Mini',
    tilesetId: 'mini-tileset',
    geometry: SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 8, height: 8),
      gridSize: SurfaceAtlasGridSize(columns: 4, rows: 2),
      layout: SurfaceAtlasLayout.grid,
    ),
  );
}

ProjectSurfaceAnimation _miniAnimation() {
  return ProjectSurfaceAnimation(
    id: 'mini-tile-1',
    name: 'Mini tile 1',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(atlasId: 'mini', column: 1, row: 0),
          durationMs: 80,
        ),
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(atlasId: 'mini', column: 3, row: 0),
          durationMs: 120,
        ),
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(atlasId: 'mini', column: 1, row: 1),
          durationMs: 160,
        ),
      ],
    ),
  );
}

Uint8List _miniAtlasPng() {
  final image = img.Image(width: 32, height: 16, numChannels: 4);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final column = x ~/ 8;
      final row = y ~/ 8;
      final color = switch ((column, row)) {
        (1, 0) => img.ColorRgba8(255, 0, 0, 255),
        (3, 0) => img.ColorRgba8(0, 255, 0, 255),
        (1, 1) => img.ColorRgba8(0, 0, 255, 255),
        _ => img.ColorRgba8(32, 32, 32, 255),
      };
      image.setPixel(x, y, color);
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
