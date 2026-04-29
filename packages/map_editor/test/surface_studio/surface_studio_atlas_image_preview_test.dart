import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_image_preview.dart';
import 'package:path/path.dart' as p;

/// PNG 1×1 pixel minimal (valide pour [Image.file]).
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
  group('resolveSurfaceStudioAtlasImagePreview', () {
    test('empty sans identifiant', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: const [],
        technicalTilesetId: null,
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.empty);
    });

    test('unresolved sans entrées tileset', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: const [],
        technicalTilesetId: 'x',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
    });

    test('unresolved identifiant inconnu', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: '/tmp',
        projectTilesets: [
          const ProjectTilesetEntry(
            id: 'a',
            name: 'A',
            relativePath: 'a.png',
            sortOrder: 0,
          ),
        ],
        technicalTilesetId: 'b',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
    });

    test('unresolved sans racine projet', () {
      final r = resolveSurfaceStudioAtlasImagePreview(
        projectRootPath: null,
        projectTilesets: [
          const ProjectTilesetEntry(
            id: 't1',
            name: 'Eau',
            relativePath: 'assets/eau.png',
            sortOrder: 0,
          ),
        ],
        technicalTilesetId: 't1',
      );
      expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.unresolved);
      expect(r.displayFileName, 'eau.png');
      expect(r.relativePathForUi, contains('assets/eau.png'));
    });

    test('missingFile racine + entrée mais fichier absent', () {
      final root = Directory.systemTemp.createTempSync('surf72_miss_').path;
      try {
        final r = resolveSurfaceStudioAtlasImagePreview(
          projectRootPath: root,
          projectTilesets: [
            const ProjectTilesetEntry(
              id: 't1',
              name: 'Eau',
              relativePath: 'nope.png',
              sortOrder: 0,
            ),
          ],
          technicalTilesetId: 't1',
        );
        expect(
            r.status, SurfaceStudioAtlasImagePreviewResolveStatus.missingFile);
        expect(r.displayFileName, 'nope.png');
        expect(r.relativePathForUi, 'nope.png');
      } finally {
        Directory(root).deleteSync(recursive: true);
      }
    });

    test('resolved quand le fichier existe', () async {
      final temp = await Directory.systemTemp.createTemp('surf72_ok_');
      try {
        final rel = p.join('sub', 'one.png');
        final abs = p.normalize(p.join(temp.path, rel));
        await Directory(p.dirname(abs)).create(recursive: true);
        await File(abs).writeAsBytes(_minimalPngBytes);

        final r = resolveSurfaceStudioAtlasImagePreview(
          projectRootPath: temp.path,
          projectTilesets: [
            ProjectTilesetEntry(
              id: 't1',
              name: 'Textures',
              relativePath: rel.replaceAll(r'\', '/'),
              sortOrder: 0,
            ),
          ],
          technicalTilesetId: 't1',
        );
        expect(r.status, SurfaceStudioAtlasImagePreviewResolveStatus.resolved);
        expect(r.resolvedAbsolutePath, abs);
        expect(r.displayFileName, 'one.png');
        expect(r.relativePathForUi, rel.replaceAll(r'\', '/'));
      } finally {
        await temp.delete(recursive: true);
      }
    });
  });

  group('SurfaceStudioAtlasImagePreview widget', () {
    testWidgets('état vide', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SurfaceStudioAtlasImagePreview(
            resolution: SurfaceStudioAtlasImagePreviewResolution(
              status: SurfaceStudioAtlasImagePreviewResolveStatus.empty,
              displayFileName: '',
              relativePathForUi: '',
            ),
            label: Colors.white,
            subtle: Colors.grey,
          ),
        ),
      );
      expect(find.byKey(kSurfaceStudioAtlasImagePreviewSectionKey),
          findsOneWidget);
      expect(find.text('Aperçu de l’image source'), findsOneWidget);
      expect(
        find.text('Choisissez une image source pour afficher l’aperçu.'),
        findsOneWidget,
      );
    });

    // Pas de test widget « image résolue » : le décodage async de [Image.memory]
    // dans flutter_test peut ne pas se terminer (idle) de façon fiable sur ce runner.
    // L’état résolu est couvert par le test unitaire « resolved quand le fichier existe »
    // et par l’usage réel dans Surface Studio.

    testWidgets('état fichier manquant (libellés UI)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SurfaceStudioAtlasImagePreview(
            resolution: SurfaceStudioAtlasImagePreviewResolution(
              status: SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
              displayFileName: 'absent.png',
              relativePathForUi: 'assets/tilesets/absent.png',
            ),
            label: Colors.white,
            subtle: Colors.grey,
          ),
        ),
      );
      expect(
        find.textContaining('Aperçu image indisponible'),
        findsOneWidget,
      );
      expect(
        find.text('La grille symbolique reste disponible.'),
        findsOneWidget,
      );
      expect(find.textContaining('assets/tilesets/absent.png'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MacosApp(
    theme: MacosThemeData.dark(),
    home: ColoredBox(
      color: const Color(0xFF0F1218),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    ),
  );
}
