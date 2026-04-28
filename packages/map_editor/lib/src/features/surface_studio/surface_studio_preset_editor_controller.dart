import 'package:map_core/map_core.dart';

/// Remplace localement l'animation associée à un rôle d'une surface peignable.
///
/// Surface Studio édite ici le catalogue de travail uniquement : le manifest et
/// le disque restent inchangés jusqu'au save flow existant du panneau parent.
ProjectSurfaceCatalog surfaceStudioReplacePresetRoleAnimation({
  required ProjectSurfaceCatalog catalog,
  required String presetId,
  required SurfaceVariantRole role,
  required String animationId,
}) {
  final nextAnimationId = animationId.trim();
  if (nextAnimationId.isEmpty) {
    throw const ValidationException('animationId must be non-empty');
  }

  var replaced = false;
  final nextPresets = <ProjectSurfacePreset>[];
  for (final preset in catalog.presets) {
    if (preset.id != presetId) {
      nextPresets.add(preset);
      continue;
    }
    replaced = true;
    nextPresets.add(
      surfaceStudioReplacePresetRoleAnimationInPreset(
        preset: preset,
        role: role,
        animationId: nextAnimationId,
      ),
    );
  }

  if (!replaced) {
    throw StateError('Surface preset not found: $presetId');
  }

  return ProjectSurfaceCatalog(
    atlases: catalog.atlases,
    animations: catalog.animations,
    presets: nextPresets,
  );
}

/// Recrée un preset en conservant son identité et les autres rôles.
///
/// L'ordre des refs est stabilisé selon le vocabulaire standard pour rendre les
/// diffs de catalogue prévisibles après plusieurs corrections de mapping.
ProjectSurfacePreset surfaceStudioReplacePresetRoleAnimationInPreset({
  required ProjectSurfacePreset preset,
  required SurfaceVariantRole role,
  required String animationId,
}) {
  final nextAnimationId = animationId.trim();
  if (nextAnimationId.isEmpty) {
    throw const ValidationException('animationId must be non-empty');
  }

  final refsByRole = <SurfaceVariantRole, SurfaceVariantAnimationRef>{
    for (final ref in preset.variantAnimations.refs) ref.role: ref,
  };
  refsByRole[role] = SurfaceVariantAnimationRef(
    role: role,
    animationId: nextAnimationId,
  );

  final orderedRefs = <SurfaceVariantAnimationRef>[];
  for (final standardRole in standardSurfaceVariantRoleOrder) {
    final ref = refsByRole[standardRole];
    if (ref != null) {
      orderedRefs.add(ref);
    }
  }

  return ProjectSurfacePreset(
    id: preset.id,
    name: preset.name,
    categoryId: preset.categoryId,
    sortOrder: preset.sortOrder,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: orderedRefs),
  );
}
