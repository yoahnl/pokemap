import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Résultat de [surfaceStudioAppendReadyVerticalAtlasAnimations] : animations
/// ajoutées et nombre d’items prêts ignorés (doublon interne au lot, etc.).
@immutable
class SurfaceStudioVerticalAtlasAnimationAppendOutcome {
  const SurfaceStudioVerticalAtlasAnimationAppendOutcome({
    required this.newAnimations,
    required this.ignoredReadyCount,
  });

  final List<ProjectSurfaceAnimation> newAnimations;
  final int ignoredReadyCount;
}

/// Construit une [ProjectSurfaceAnimation] pour un item **prêt** du plan.
ProjectSurfaceAnimation surfaceStudioProjectSurfaceAnimationFromReadyPlanItem({
  required SurfaceStudioVerticalAtlasAnimationGenerationItem item,
  required String atlasIdForTileRefs,
  required String animationDisplayNamePrefix,
  required String? categoryId,
  required int sortOrder,
}) {
  final frames = <SurfaceAnimationFrame>[];
  for (var r = 0; r < item.frameCount; r++) {
    frames.add(
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: atlasIdForTileRefs,
          column: item.columnIndex,
          row: r,
        ),
        durationMs: item.durationMsPerFrame,
      ),
    );
  }
  final timeline = SurfaceAnimationTimeline(frames: frames);
  final prefix = animationDisplayNamePrefix.trim().isEmpty
      ? atlasIdForTileRefs.trim()
      : animationDisplayNamePrefix.trim();
  final name =
      '$prefix — ${SurfaceStudioRoleLabels.labelForRole(item.role)}';
  return ProjectSurfaceAnimation(
    id: item.proposedAnimationId,
    name: name,
    timeline: timeline,
    syncGroupId: atlasIdForTileRefs.trim(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

/// À partir du plan, produit la liste des animations à **ajouter** (items
/// [isReady] uniquement, ids [proposedAnimationId] uniques dans le lot).
SurfaceStudioVerticalAtlasAnimationAppendOutcome
    surfaceStudioCollectNewAnimationsFromReadyPlan({
  required SurfaceStudioVerticalAtlasAnimationGenerationPlan plan,
  required String atlasIdForTileRefs,
  required String animationDisplayNamePrefix,
  required String? categoryId,
  required int sortOrderBase,
}) {
  final seen = <String>{};
  final out = <ProjectSurfaceAnimation>[];
  var ignored = 0;
  var sort = sortOrderBase;
  for (final it in plan.items) {
    if (!it.isReady ||
        it.status != SurfaceStudioVerticalAtlasAnimationPlanItemStatus.ready) {
      continue;
    }
    if (!seen.add(it.proposedAnimationId)) {
      ignored++;
      continue;
    }
    out.add(
      surfaceStudioProjectSurfaceAnimationFromReadyPlanItem(
        item: it,
        atlasIdForTileRefs: atlasIdForTileRefs.trim(),
        animationDisplayNamePrefix: animationDisplayNamePrefix,
        categoryId: categoryId,
        sortOrder: sort,
      ),
    );
    sort++;
  }
  return SurfaceStudioVerticalAtlasAnimationAppendOutcome(
    newAnimations: out,
    ignoredReadyCount: ignored,
  );
}

/// Fusionne les nouvelles animations en fin de liste (atlas / presets inchangés).
ProjectSurfaceCatalog surfaceStudioAppendAnimationsToWorkCatalog({
  required ProjectSurfaceCatalog catalog,
  required List<ProjectSurfaceAnimation> newAnimations,
}) {
  return ProjectSurfaceCatalog(
    atlases: List<ProjectSurfaceAtlas>.from(catalog.atlases),
    animations: [
      ...catalog.animations,
      ...newAnimations,
    ],
    presets: List<ProjectSurfacePreset>.from(catalog.presets),
  );
}
