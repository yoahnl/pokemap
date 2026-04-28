import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_preview.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('surfaceStudioVerticalAtlasAnimationPreviewSummary', () {
    test('colonne 0, frame 5, 32×32, 32 lignes → source x=0 y=160', () {
      final s = surfaceStudioVerticalAtlasAnimationPreviewSummary(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
        frameIndex: 5,
        tileWidth: 32,
        tileHeight: 32,
        rows: 32,
      );
      expect(s, isNotNull);
      expect(s!.frameCount, 32);
      expect(s.currentFrameIndex, 5);
      expect(s.sourceRect.sourceX, 0);
      expect(s.sourceRect.sourceY, 160);
      expect(s.sourceRect.sourceWidth, 32);
      expect(s.sourceRect.sourceHeight, 32);
    });

    test('frameIndex est ramené modulo rows', () {
      final s = surfaceStudioVerticalAtlasAnimationPreviewSummary(
        columnIndex: 2,
        role: SurfaceVariantRole.isolated,
        frameIndex: 40,
        tileWidth: 32,
        tileHeight: 32,
        rows: 32,
      );
      expect(s, isNotNull);
      expect(s!.currentFrameIndex, 8);
      expect(s.sourceRect.sourceX, 64);
      expect(s.sourceRect.sourceY, 256);
    });

    test('dimensions invalides → null', () {
      expect(
        surfaceStudioVerticalAtlasAnimationPreviewSummary(
          columnIndex: 0,
          role: SurfaceVariantRole.isolated,
          frameIndex: 0,
          tileWidth: 0,
          tileHeight: 32,
          rows: 10,
        ),
        isNull,
      );
    });
  });

  group('SurfaceStudioVerticalAtlasAnimationPreview', () {
    testWidgets('titre de section visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(1),
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Aperçu animation par colonne'), findsOneWidget);
    });

    testWidgets('grille invalide : message sans jargon interdit',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(3),
              tileWidth: null,
              tileHeight: 32,
              columns: 3,
              rows: 10,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining('Corrigez la grille avant de prévisualiser'),
        findsOneWidget,
      );
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
    });

    testWidgets('sans rôle assigné : invite à assigner', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.empty(5),
              tileWidth: 32,
              tileHeight: 32,
              columns: 5,
              rows: 10,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(
          'Assignez un rôle à une colonne pour prévisualiser son animation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'suggestion standard : frames, navigation modulo, source rect',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioVerticalAtlasAnimationPreview(
                label: Colors.white,
                subtle: Colors.grey,
                mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(2),
                tileWidth: 32,
                tileHeight: 32,
                columns: 2,
                rows: 4,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Frames : 4'), findsOneWidget);
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);
        expect(
          find.textContaining('Source rect : x=0, y=0, 32×32'),
          findsOneWidget,
        );

        await tester.tap(find.text('Frame suivante'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 2 / 4'), findsOneWidget);
        expect(
          find.textContaining('Source rect : x=0, y=32, 32×32'),
          findsOneWidget,
        );

        await tester.tap(find.text('Frame précédente'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);

        await tester.tap(find.text('Frame précédente'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 4 / 4'), findsOneWidget);

        await tester.tap(find.text('Frame suivante'));
        await tester.pump();
        expect(find.textContaining('Frame courante : 1 / 4'), findsOneWidget);
      },
    );

    testWidgets('23 colonnes × 32 lignes : 32 frames affichées',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationPreview(
              label: Colors.white,
              subtle: Colors.grey,
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(23),
              tileWidth: 32,
              tileHeight: 32,
              columns: 23,
              rows: 32,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Frames : 32'), findsOneWidget);
    });

    testWidgets('preview controls stay constrained on narrow width',
        (tester) async {
      tester.view.physicalSize = const Size(420, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 260,
                child: SurfaceStudioVerticalAtlasAnimationPreview(
                  label: Colors.white,
                  subtle: Colors.grey,
                  mappingDraft:
                      SurfaceStudioColumnRoleMappingDraft.suggested(2),
                  tileWidth: 32,
                  tileHeight: 32,
                  columns: 2,
                  rows: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('surface_animation_preview_actions')),
          findsOneWidget);
      final preview =
          find.byKey(const ValueKey('surface_animation_preview_tile_box'));
      expect(preview, findsOneWidget);
      final size = tester.getSize(preview);
      expect(size.width, lessThanOrEqualTo(96));
      expect(size.height, lessThanOrEqualTo(96));
    });
  });
}
