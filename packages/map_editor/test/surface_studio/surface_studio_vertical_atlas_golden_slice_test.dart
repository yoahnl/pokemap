// Golden slice vertical atlas — chaîne authoring Lots 70–80 + wizard V2.1.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('Lot 80 — golden slice vertical atlas', () {
    test(
        '23×32 + suggestion standard : 20 animations prêtes puis preset cohérent',
        () {
      const cols = 23;
      const rows = 32;
      const duration = 120;
      final mapping = SurfaceStudioColumnRoleMappingDraft.suggested(cols);
      expect(mapping.assignments.length, 20);

      final existingIds = <String>{};
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: mapping,
        tileWidth: 32,
        tileHeight: 32,
        columns: cols,
        rows: rows,
        durationMsPerFrame: duration,
        existingAnimationIds: existingIds,
      );
      expect(plan.summary.readyAnimationCount, 20);
      expect(plan.gridValid, isTrue);

      final outcome = surfaceStudioCollectNewAnimationsFromReadyPlan(
        plan: plan,
        atlasIdForTileRefs: 'eau',
        animationDisplayNamePrefix: 'Eau',
        categoryId: null,
        sortOrderBase: 0,
      );
      expect(outcome.newAnimations.length, 20);

      var catalog = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'eau',
            name: 'Eau',
            tilesetId: 'dummy',
            geometry: SurfaceAtlasGeometry(
              tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
              gridSize: SurfaceAtlasGridSize(columns: cols, rows: rows),
              layout: SurfaceAtlasLayout.grid,
            ),
          ),
        ],
      );
      catalog = surfaceStudioAppendAnimationsToWorkCatalog(
        catalog: catalog,
        newAnimations: outcome.newAnimations,
      );
      expect(catalog.animations.length, 20);

      final presetPlan = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: catalog,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: mapping,
        gridValid: true,
      );
      expect(presetPlan.canCreate, isTrue);
      expect(presetPlan.missingAnimationCount, 0);

      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: catalog,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: mapping,
        gridValid: true,
      );
      expect(preset.id, 'eau-surface-preset');
      expect(preset.variantCount, 20);

      final animIds = {for (final a in catalog.animations) a.id};
      for (final ref in preset.variantAnimations.refs) {
        expect(animIds.contains(ref.animationId), isTrue,
            reason: 'preset ref ${ref.role} -> ${ref.animationId}');
      }

      final plein =
          catalog.animations.firstWhere((a) => a.id == 'eau-plein-loop');
      expect(plein.timeline.frameCount, rows);
      expect(plein.timeline.frames.first.tileRef.column, 0);
      expect(plein.timeline.frames.first.tileRef.row, 0);
      expect(plein.timeline.frames.last.tileRef.row, rows - 1);
      expect(plein.timeline.frames.first.durationMs, duration);
    });

    testWidgets(
        'V2.1 UI : atlas → suggestion review → animations → preset → save prep',
        (tester) async {
      ProjectSurfaceCatalog? saved;
      await pumpSurfaceStudioForTest(
        tester,
        readModel: buildSurfaceStudioReadModelFromCatalog(
          ProjectSurfaceCatalog(),
        ),
        onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
      );
      await tester.pump();

      final idF = find.byKey(const ValueKey('surfaceStudio.import.atlasId'));
      final nameF =
          find.byKey(const ValueKey('surfaceStudio.import.atlasName'));
      final tsF = find.byKey(const ValueKey('surfaceStudio.import.tilesetId'));

      await tester.ensureVisible(idF);
      await tester.enterText(idF, 'eau');
      await tester.enterText(nameF, 'Eau');
      await tester.enterText(tsF, 't');
      await tester.pump();

      final createAtlas =
          find.byKey(const ValueKey('surfaceStudio.import.createAtlas'));
      await tester.ensureVisible(createAtlas);
      await tester.pumpAndSettle();
      await tester.tap(createAtlas);
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final autoSuggest =
          find.byKey(const ValueKey('surfaceStudio.action.autoSuggest'));
      await tester.ensureVisible(autoSuggest);
      await tester.pumpAndSettle();
      await tester.tap(autoSuggest);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));
      expect(find.text('Suggestions détectées'), findsOneWidget);
      await tester.tap(find.text('Tout appliquer'));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final generatePreview = find
          .byKey(const ValueKey('surfaceStudio.preview.generateAnimations'));
      await tester.ensureVisible(generatePreview);
      await tester.pumpAndSettle();
      await tester.tap(generatePreview);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await tester.tap(find.byKey(const ValueKey('surfaceStudio.action.next')));
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final createPreset =
          find.byKey(const ValueKey('surfaceStudio.save.createPreset'));
      await tester.ensureVisible(createPreset);
      await tester.pumpAndSettle();
      await tester.tap(createPreset);
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      final saveCatalog =
          find.byKey(const ValueKey('surfaceStudio.action.saveCatalog')).last;
      await tester.ensureVisible(saveCatalog);
      await tester.pumpAndSettle();
      await tester.tap(saveCatalog);
      await tester.pumpAndSettle(const Duration(milliseconds: 150));

      expect(saved, isNotNull);
      expect(saved!.atlases.length, 1);
      expect(saved!.atlases.first.id, 'eau');
      expect(saved!.animations.length, greaterThan(0));
      expect(saved!.presets.length, 1);

      final preset = saved!.presets.first;
      expect(preset.id, 'eau-surface-preset');

      final animById = {
        for (final a in saved!.animations) a.id: a,
      };
      for (final ref in preset.variantAnimations.refs) {
        expect(animById.containsKey(ref.animationId), isTrue);
      }

      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        isNotNull,
      );
    });
  });
}
