import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_assistant.dart';

void main() {
  group('SurfaceStudioVerticalAtlasAssistant (Lot 74)', () {
    testWidgets('section et conventions visibles', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
            ),
          ),
        ),
      );
      expect(find.byKey(SurfaceStudioVerticalAtlasAssistant.sectionKey),
          findsOneWidget);
      expect(find.text('Assistant atlas vertical'), findsOneWidget);
      expect(find.text('Colonnes = variantes visuelles'), findsOneWidget);
      expect(find.text('Lignes = frames d’animation'), findsOneWidget);
    });

    testWidgets('23×32 affiche variantes frames et total', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );
      expect(find.text('Variantes détectées : 23 colonnes'), findsOneWidget);
      expect(find.text('Frames détectées : 32 lignes'), findsOneWidget);
      expect(find.text('Total : 736 tuiles'), findsOneWidget);
      expect(find.text('Taille de tuile : 32×32 px'), findsOneWidget);
      expect(
        find.textContaining('Structure probablement verticale'),
        findsOneWidget,
      );
    });

    testWidgets('1×1 atlas simple', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 1,
              draftRows: 1,
            ),
          ),
        ),
      );
      expect(
        find.text('Atlas simple : aucune structure animée détectée.'),
        findsOneWidget,
      );
    });

    testWidgets('colonnes > lignes : message horizontal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 16,
              draftTileHeight: 16,
              draftColumns: 8,
              draftRows: 4,
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Structure probablement horizontale'),
        findsOneWidget,
      );
    });

    testWidgets('pas de jargon dans l’UI', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAssistant(
              label: Color(0xFFE8E8EC),
              subtle: Color(0xFF9A9AA3),
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 2,
              draftRows: 2,
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
}
