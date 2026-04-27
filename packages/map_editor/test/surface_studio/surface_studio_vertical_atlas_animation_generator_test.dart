import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_animation_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('surfaceStudioProjectSurfaceAnimationFromReadyPlanItem', () {
    test('23×32 colonne 0 : 32 frames, row 31, durée 120', () {
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
      final it = plan.items.firstWhere((i) => i.columnIndex == 0);
      expect(it.isReady, isTrue);
      final anim = surfaceStudioProjectSurfaceAnimationFromReadyPlanItem(
        item: it,
        atlasIdForTileRefs: 'eau',
        animationDisplayNamePrefix: 'Eau',
        categoryId: null,
        sortOrder: 0,
      );
      expect(anim.id, 'eau-plein-loop');
      expect(anim.name, 'Eau — Plein');
      expect(anim.timeline.frameCount, 32);
      expect(anim.timeline.frames.last.tileRef.row, 31);
      expect(anim.timeline.frames.last.tileRef.column, 0);
      expect(anim.timeline.frames.last.durationMs, 120);
      expect(anim.syncGroupId, 'eau');
    });
  });

  group('surfaceStudioCollectNewAnimationsFromReadyPlan', () {
    test('deux colonnes même rôle → un seul id, une ignorée', () {
      const draft = SurfaceStudioColumnRoleMappingDraft(
        columnCount: 2,
        assignments: [
          SurfaceStudioColumnRoleAssignment(
            columnIndex: 0,
            role: SurfaceVariantRole.isolated,
          ),
          SurfaceStudioColumnRoleAssignment(
            columnIndex: 1,
            role: SurfaceVariantRole.isolated,
          ),
        ],
      );
      final plan = buildSurfaceStudioVerticalAtlasAnimationGenerationPlan(
        atlasIdRaw: 'eau',
        mappingDraft: draft,
        tileWidth: 16,
        tileHeight: 16,
        columns: 2,
        rows: 2,
        durationMsPerFrame: 100,
        existingAnimationIds: const {},
      );
      final out = surfaceStudioCollectNewAnimationsFromReadyPlan(
        plan: plan,
        atlasIdForTileRefs: 'eau',
        animationDisplayNamePrefix: 'Eau',
        categoryId: null,
        sortOrderBase: 0,
      );
      expect(out.newAnimations.length, 1);
      expect(out.ignoredReadyCount, 1);
    });
  });

  group('surfaceStudioAppendAnimationsToWorkCatalog', () {
    test('préserve atlas et presets', () {
      final preset = ProjectSurfacePreset(
        id: 'p',
        name: 'P',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'old',
            ),
          ],
        ),
      );
      final atlas = ProjectSurfaceAtlas(
        id: 'a',
        name: 'A',
        tilesetId: 't',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
          layout: SurfaceAtlasLayout.grid,
        ),
      );
      final existing = ProjectSurfaceAnimation(
        id: 'old',
        name: 'Old',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
              durationMs: 10,
            ),
          ],
        ),
      );
      final cat = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [existing],
        presets: [preset],
      );
      final newAnim = ProjectSurfaceAnimation(
        id: 'new',
        name: 'New',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
              durationMs: 10,
            ),
          ],
        ),
      );
      final next = surfaceStudioAppendAnimationsToWorkCatalog(
        catalog: cat,
        newAnimations: [newAnim],
      );
      expect(next.atlases.length, 1);
      expect(next.atlases.first.id, 'a');
      expect(next.presets.length, 1);
      expect(next.presets.first.id, 'p');
      expect(next.animations.length, 2);
      expect(next.animations.first.id, 'old');
      expect(next.animations.last.id, 'new');
    });
  });
}
