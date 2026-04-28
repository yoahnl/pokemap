// Golden slice vertical atlas — chaîne authoring Lots 70–79 (Lot 80).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart'
    show EditorState, EditorWorkspaceMode;
import 'package:path/path.dart' as p;

import '../shell_chrome_test_harness.dart';

void main() {
  group('Lot 80 — golden slice vertical atlas', () {
    test('23×32 + suggestion standard : 20 animations prêtes puis preset cohérent',
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
      '4×3 UI : atlas → mapping → animations → preset → save → project.json',
      (tester) async {
      final temp = Directory.systemTemp.createTempSync('map_editor_lot80_gs_');
      addTearDown(() {
        if (temp.existsSync()) {
          temp.deleteSync(recursive: true);
        }
      });

      final empty = ProjectManifest(
        name: 'Lot80 Golden',
        maps: const [],
        tilesets: const [],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      final manifestPath = p.join(temp.path, 'project.json');
      File(manifestPath).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(empty.toJson()),
      );

      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: temp.path,
          project: empty,
          workspaceMode: EditorWorkspaceMode.surfaceStudio,
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      Future<void> scrollTo(Finder f) async {
        await tester.ensureVisible(f);
        await tester.pump();
      }

      final idF = find.byKey(const ValueKey('atlas_draft_id'));
      final nameF = find.byKey(const ValueKey('atlas_draft_name'));
      final tsF = find.byKey(const ValueKey('atlas_draft_tileset_advanced'));
      final colsF = find.byKey(const ValueKey('atlas_draft_cols'));
      final rowsF = find.byKey(const ValueKey('atlas_draft_rows'));

      await scrollTo(idF);
      await tester.enterText(idF, 'eau');
      await tester.enterText(nameF, 'Eau');
      await tester.enterText(tsF, 't');
      await tester.enterText(colsF, '4');
      await tester.enterText(rowsF, '3');
      await tester.pump();

      await scrollTo(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_create_atlas_work_catalog')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      await scrollTo(find.text('Suggérer un mapping standard'));
      await tester.tap(find.text('Suggérer un mapping standard'));
      await tester.pumpAndSettle(const Duration(milliseconds: 80));

      await scrollTo(
        find.byKey(const ValueKey('surface_studio_gen_plan_append_ready')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_gen_plan_append_ready')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await scrollTo(
        find.byKey(const ValueKey('surface_studio_preset_append_vertical_atlas')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_preset_append_vertical_atlas')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 120));

      await scrollTo(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.tap(
        find.byKey(const ValueKey('surface_studio_save_prep_catalog')),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 150));

      expect(
        container.read(editorNotifierProvider).project!.surfaceCatalog.atlases
            .length,
        1,
      );
      expect(
        container.read(editorNotifierProvider).project!.surfaceCatalog.animations
            .length,
        4,
      );
      expect(
        container.read(editorNotifierProvider).project!.surfaceCatalog.presets
            .length,
        1,
      );

      var ok = false;
      await tester.runAsync(() async {
        ok = await container
            .read(editorNotifierProvider.notifier)
            .saveProjectManifest();
      });
      expect(ok, isTrue);

      final onDisk = File(manifestPath).readAsStringSync();
      final loaded = ProjectManifest.fromJson(
        jsonDecode(onDisk) as Map<String, dynamic>,
      );
      expect(loaded.name, empty.name);
      expect(loaded.surfaceCatalog.atlases.length, 1);
      expect(loaded.surfaceCatalog.atlases.first.id, 'eau');
      expect(loaded.surfaceCatalog.animations.length, 4);
      expect(loaded.surfaceCatalog.presets.length, 1);

      final preset = loaded.surfaceCatalog.presets.first;
      expect(preset.id, 'eau-surface-preset');

      final animById = {
        for (final a in loaded.surfaceCatalog.animations) a.id: a,
      };
      for (final ref in preset.variantAnimations.refs) {
        expect(animById.containsKey(ref.animationId), isTrue);
      }

      ProjectSurfaceAnimation anim(String id) => animById[id]!;

      void expectVerticalStrip(ProjectSurfaceAnimation a, int column) {
        expect(a.timeline.frameCount, 3);
        expect(a.timeline.frames.first.tileRef.column, column);
        expect(a.timeline.frames.first.tileRef.row, 0);
        expect(a.timeline.frames.last.tileRef.row, 2);
        for (final f in a.timeline.frames) {
          expect(f.durationMs, 120);
          expect(f.tileRef.column, column);
        }
      }

      expectVerticalStrip(anim('eau-plein-loop'), 0);
      expectVerticalStrip(anim('eau-bord-haut-loop'), 1);
      expectVerticalStrip(anim('eau-bord-droit-loop'), 2);
      expectVerticalStrip(anim('eau-bord-bas-loop'), 3);

      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        'eau-plein-loop',
      );
      expect(
        preset.animationIdForRole(SurfaceVariantRole.endNorth),
        'eau-bord-haut-loop',
      );
    });
  });
}
