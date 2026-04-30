import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_transparent_color.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Tiled TSX transparent color', () {
    test('parser exposes the TSX trans color', () {
      final audit = parseTiledTsxAnimatedTileset(_readTechAnimationsTsx());

      expect(audit.summary.transparentColor, 'f05ba1');
    });

    test('applies transparent color case-insensitively to PNG bytes', () {
      final lower = applyTiledTsxTransparentColorToPngBytes(
        imageBytes: _twoPixelPng(),
        transparentColor: 'f05ba1',
      );
      final upper = applyTiledTsxTransparentColorToPngBytes(
        imageBytes: _twoPixelPng(),
        transparentColor: 'F05BA1',
      );

      for (final bytes in [lower, upper]) {
        final decoded = img.decodePng(bytes);
        expect(decoded, isNotNull);
        expect(decoded!.getPixel(0, 0).a.toInt(), 0);
        expect(decoded.getPixel(1, 0).a.toInt(), 255);
        expect(decoded.getPixel(1, 0).b.toInt(), 255);
      }
    });

    test('leaves image bytes unchanged without a valid transparent color', () {
      final original = _twoPixelPng();

      expect(
        applyTiledTsxTransparentColorToPngBytes(
          imageBytes: original,
          transparentColor: null,
        ),
        same(original),
      );
      expect(
        applyTiledTsxTransparentColorToPngBytes(
          imageBytes: original,
          transparentColor: 'not-hex',
        ),
        same(original),
      );
    });

    testWidgets('workspace summarizes and applies TSX transparency',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          TiledTsxWorkspace(
            catalog: ProjectSurfaceCatalog(),
            projectTilesets: const [
              ProjectTilesetEntry(
                id: 'tech-nature-animations',
                name: 'TECH Nature Animations',
                relativePath: 'Data/Tiled/Assets/TECH-Nature-animations.png',
              ),
            ],
            fileLoader: _FakeTsxFileLoader(_readTechAnimationsTsx()),
            atlasImageBytes: _twoPixelPng(),
          ),
        ),
      );

      await tester
          .tap(find.byKey(const ValueKey('tiled_tsx_workspace.import')));
      await tester.pumpAndSettle();

      expect(find.text('Couleur transparente : #F05BA1'), findsOneWidget);
      expect(
        find.text('Transparence appliquée aux previews.'),
        findsOneWidget,
      );
    });
  });
}

Uint8List _twoPixelPng() {
  final image = img.Image(width: 2, height: 1, numChannels: 4);
  image.setPixel(0, 0, img.ColorRgba8(0xF0, 0x5B, 0xA1, 255));
  image.setPixel(1, 0, img.ColorRgba8(0, 0, 255, 255));
  return Uint8List.fromList(img.encodePng(image));
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 1300,
        height: 900,
        child: child,
      ),
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

final class _FakeTsxFileLoader implements TiledTsxFileLoader {
  const _FakeTsxFileLoader(this.xml);

  final String xml;

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async {
    return TiledTsxLoadedFile(
      path: '/tmp/TECH-Animations.tsx',
      fileName: 'TECH-Animations.tsx',
      xml: xml,
    );
  }
}
