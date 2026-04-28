import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_preset_generator.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

ProjectSurfaceAnimation _anim(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'eau',
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
  );
}

void main() {
  group('surfaceStudioProposedVerticalAtlasPresetId', () {
    test('eau → eau-surface-preset', () {
      expect(surfaceStudioProposedVerticalAtlasPresetId('eau'), 'eau-surface-preset');
    });
  });

  group('surfaceStudioPlanVerticalAtlasPresetAppend', () {
    test('sans mapping → bloqué', () {
      final cat = ProjectSurfaceCatalog();
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: const SurfaceStudioColumnRoleMappingDraft.empty(3),
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping);
    });

    test('grille invalide → bloqué', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: false,
      );
      expect(p.canCreate, isFalse);
      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid);
    });

    test('animation manquante → bloqué', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog();
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.missingAnimationCount, greaterThan(0));
      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations);
    });

    test('id preset déjà pris → bloqué', () {
      final existing = ProjectSurfacePreset(
        id: 'eau-surface-preset',
        name: 'X',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'eau-plein-loop',
            ),
          ],
        ),
      );
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(
        animations: [_anim('eau-plein-loop')],
        presets: [existing],
      );
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isFalse);
      expect(p.status, SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId);
    });

    test('plein + animation → prêt ou incomplet selon couverture standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final p = surfaceStudioPlanVerticalAtlasPresetAppend(
        catalog: cat,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(p.canCreate, isTrue);
      expect(p.missingAnimationCount, 0);
      expect(p.rolesCoveredCount, 1);
      expect(
        p.status == SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete ||
            p.status == SurfaceStudioVerticalAtlasPresetPlanStatus.ready,
        isTrue,
      );
    });
  });

  group('surfaceStudioBuildVerticalAtlasPreset + append', () {
    test('eau colonne 0 plein → preset eau-surface-preset + ref plein', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(1);
      final cat0 = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: cat0,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(preset.id, 'eau-surface-preset');
      expect(preset.name, 'Eau — Surface');
      expect(preset.variantCount, 1);
      expect(
        preset.animationIdForRole(SurfaceVariantRole.isolated),
        'eau-plein-loop',
      );
      final cat1 = surfaceStudioAppendPresetToWorkCatalog(
        catalog: cat0,
        preset: preset,
      );
      expect(cat1.presets.length, 1);
      expect(cat1.animations.length, 1);
      expect(cat1.atlases.length, 0);
    });

    test('deux colonnes même rôle → une seule ref', () {
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
      final cat0 = ProjectSurfaceCatalog(animations: [_anim('eau-plein-loop')]);
      final preset = surfaceStudioBuildVerticalAtlasPreset(
        catalog: cat0,
        atlasIdRaw: 'eau',
        atlasDisplayName: 'Eau',
        atlasCategoryDraft: null,
        mappingDraft: draft,
        gridValid: true,
      );
      expect(preset.variantCount, 1);
    });
  });
}
