import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_grid_overlay.dart';

/// PNG 1×1 minimal.
List<int> get _minimalPngBytes => <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ];

void main() {
  group('decodeRasterImageSizeFromBytes', () {
    test('PNG 1×1 → 1×1', () {
      final d = decodeRasterImageSizeFromBytes(
        Uint8List.fromList(_minimalPngBytes),
      );
      expect(d.width, 1);
      expect(d.height, 1);
    });

    test('octets vides → null', () {
      final d = decodeRasterImageSizeFromBytes(Uint8List(0));
      expect(d.width, isNull);
      expect(d.height, isNull);
    });
  });

  group('surfaceStudioAtlasGridOverlayDraftValid', () {
    test('refus si une valeur manque ou nulle', () {
      expect(surfaceStudioAtlasGridOverlayDraftValid(null, 1, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, null, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, null, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, 1, null), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(0, 1, 1, 1), isFalse);
      expect(surfaceStudioAtlasGridOverlayDraftValid(1, 1, 1, 1), isTrue);
    });
  });

  group('dimensions attendues', () {
    test('32×23 colonnes = 736', () {
      expect(surfaceStudioAtlasGridExpectedWidthPx(32, 23), 736);
      expect(surfaceStudioAtlasGridExpectedHeightPx(32, 32), 1024);
    });
  });

  group('SurfaceStudioAtlasImageGridPainter', () {
    testWidgets('CustomPaint sans crash', (tester) async {
      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: const ColoredBox(
            color: Color(0xFF0F1218),
            child: Center(
              child: CustomPaint(
                key: ValueKey<String>('surf73_grid_paint_test'),
                size: Size(80, 60),
                painter: SurfaceStudioAtlasImageGridPainter(
                  columns: 4,
                  rows: 3,
                  lineColor: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('surf73_grid_paint_test')), findsOneWidget);
    });

    testWidgets('pas de jargon dans le painter (aucun Text)', (tester) async {
      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: const ColoredBox(
            color: Color(0xFF0F1218),
            child: CustomPaint(
              size: Size(40, 40),
              painter: SurfaceStudioAtlasImageGridPainter(
                columns: 2,
                rows: 2,
                lineColor: Color(0xFFFFFFFF),
                stepX: 1,
                stepY: 1,
              ),
            ),
          ),
        ),
      );
      for (final term in const <String>[
        'ProjectSurfaceAtlas',
        'ProjectSurfaceCatalog',
        'SurfaceStudioReadModel',
        'callback',
        'copyWith',
        'tilesetId',
      ]) {
        expect(find.textContaining(term), findsNothing);
      }
    });
  });

  // Pas de test widget [SurfaceStudioAtlasImagePreview] + fichier réel : comme au Lot 72,
  // [Image.memory] peut laisser flutter_test en attente d’idle sur ce runner.
  // L’intégration image + overlay est couverte par les tests manuels et par la suite
  // [surface_studio_atlas_authoring_prep_test] / [test/surface_studio] en non-régression.
}
