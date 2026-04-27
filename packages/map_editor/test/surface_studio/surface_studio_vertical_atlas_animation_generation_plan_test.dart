import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('surfaceStudioSlug / proposed id', () {
    test('id stable eau + plein', () {
      expect(
        surfaceStudioProposedAnimationId(
          atlasIdRaw: 'eau',
          role: SurfaceVariantRole.isolated,
        ),
        'eau-plein-loop',
      );
    });

    test('slug atlas retire accents et espaces', () {
      expect(
        surfaceStudioProposedAnimationId(
          atlasIdRaw: 'Mon Atlas É',
          role: SurfaceVariantRole.endNorth,
        ),
        'mon-atlas-e-bord-haut-loop',
      );
    });
  });

  group('buildSurfaceStudioVerticalAtlasAnimationGenerationPlan', () {
    test('plan vide si aucune colonne assignée', () {
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: const SurfaceStudioColumnRoleMappingDraft.empty(5),
        tileWidth: 32,
        tileHeight: 32,
        columns: 5,
        rows: 10,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items, isEmpty);
      expect(plan.summary.assignedColumnCount, 0);
    });

    test('23×32 après suggestion : 20 animations, 3 colonnes non assignées', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 23,
        rows: 32,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items.length, 20);
      expect(plan.summary.assignedColumnCount, 20);
      expect(plan.summary.readyAnimationCount, 20);
      expect(plan.summary.errorAnimationCount, 0);
      expect(draft.columnCount - plan.summary.assignedColumnCount, 3);
    });

    test('source rects colonne 0 frames 0, 1, 31 et durée totale 32×120', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 23,
        rows: 32,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      final col0 = plan.items.firstWhere((i) => i.columnIndex == 0);
      expect(col0.frameCount, 32);
      expect(col0.totalDurationMs, 3840);
      expect(col0.sourceRects.length, 32);
      expect(col0.sourceRects[0].sourceX, 0);
      expect(col0.sourceRects[0].sourceY, 0);
      expect(col0.sourceRects[1].sourceY, 32);
      expect(col0.sourceRects[31].sourceY, 992);
    });

    test('durée par frame invalide → items invalides', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(2);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'a',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 2,
        rows: 4,
        durationMsPerFrame: 0,
        existingAnimationIds: const {},
      );
      expect(plan.summary.durationFieldValid, isFalse);
      expect(plan.summary.readyAnimationCount, 0);
      expect(plan.summary.errorAnimationCount, 2);
      for (final it in plan.items) {
        expect(it.isReady, isFalse);
        expect(it.status, SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
      }
    });

    test('dimensions invalides → items invalides', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(2);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'a',
        mappingDraft: draft,
        tileWidth: null,
        tileHeight: 32,
        columns: 2,
        rows: 4,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.gridValid, isFalse);
      expect(plan.items.every((i) => !i.isReady), isTrue);
    });

    test('doublon d’id détecté', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 1,
        rows: 1,
        durationMsPerFrame: 120,
        existingAnimationIds: {'eau-plein-loop'},
      );
      expect(plan.items.single.status,
          SurfaceStudioVerticalAtlasAnimationPlanItemStatus.duplicate);
      expect(plan.items.single.problems.first,
          contains('Une animation existe déjà avec cet id.'));
    });

    test('atlas id vide → invalide', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: '   ',
        mappingDraft: draft,
        tileWidth: 32,
        tileHeight: 32,
        columns: 1,
        rows: 1,
        durationMsPerFrame: 120,
        existingAnimationIds: const {},
      );
      expect(plan.items.single.status,
          SurfaceStudioVerticalAtlasAnimationPlanItemStatus.invalid);
    });
  });

  group('SurfaceStudioVerticalAtlasAnimationGenerationPlanSection', () {
    testWidgets('section et résumé visibles après suggestion', (tester) async {
      final rm = buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection(
              label: Colors.white,
              subtle: Colors.grey,
              readModel: rm,
              atlasIdDraft: 'eau',
              mappingDraft: draft,
              tileWidth: 32,
              tileHeight: 32,
              columns: 23,
              rows: 32,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Plan de génération des animations'), findsOneWidget);
      expect(find.textContaining('Animations prêtes : 20'), findsOneWidget);
      expect(find.textContaining('Colonnes non assignées : 3'), findsOneWidget);
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
      await tester.pump();
      expect(find.textContaining('eau-plein-loop'), findsWidgets);
    });

    testWidgets('catalogue inchangé après interaction', (tester) async {
      final anim = ProjectSurfaceAnimation(
        id: 'x',
        name: 'X',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
              durationMs: 1,
            ),
          ],
        ),
      );
      final cat = ProjectSurfaceCatalog(animations: [anim]);
      final rm = buildSurfaceStudioReadModelFromCatalog(cat);
      final before = rm.catalog.animations.length;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioVerticalAtlasAnimationGenerationPlanSection(
              label: Colors.white,
              subtle: Colors.grey,
              readModel: rm,
              atlasIdDraft: 'eau',
              mappingDraft: SurfaceStudioColumnRoleMappingDraft.suggested(1),
              tileWidth: 32,
              tileHeight: 32,
              columns: 1,
              rows: 2,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('surface_studio_gen_plan_duration_ms')),
        '50',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surface_studio_gen_plan_preview')));
      await tester.pump();
      expect(rm.catalog.animations.length, before);
    });
  });
}
