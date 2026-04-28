import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'surface_studio_vertical_atlas_animation_generation_plan.dart';
import 'surface_studio_vertical_atlas_role_mapping.dart';

/// Statut local pour l’UI (aucune persistance).
enum SurfaceStudioVerticalAtlasPresetPlanStatus {
  blockedEmptyAtlasId,
  blockedInvalidGrid,
  blockedNoMapping,
  blockedMissingAnimations,
  blockedDuplicatePresetId,
  incomplete,
  ready,
}

/// Id preset V0 : `<slug-atlas>-surface-preset` (même slug que les ids d’animation).
String surfaceStudioProposedVerticalAtlasPresetId(String atlasIdRaw) {
  final s = surfaceStudioSlugForAnimationIdSegment(atlasIdRaw);
  return s.isEmpty ? '' : '$s-surface-preset';
}

@immutable
class SurfaceStudioVerticalAtlasPresetAppendPlan {
  const SurfaceStudioVerticalAtlasPresetAppendPlan({
    required this.proposedPresetId,
    required this.proposedPresetName,
    required this.rolesCoveredCount,
    required this.rolesNotCoveredCount,
    required this.missingAnimationCount,
    required this.status,
    required this.canCreate,
    this.partialPresetUserMessage,
  });

  final String proposedPresetId;
  final String proposedPresetName;
  final int rolesCoveredCount;
  final int rolesNotCoveredCount;
  final int missingAnimationCount;
  final SurfaceStudioVerticalAtlasPresetPlanStatus status;
  final bool canCreate;

  /// Affiché si le preset ne couvre pas tous les rôles standard (V0 partiel honnête).
  final String? partialPresetUserMessage;
}

String? _categoryIdForPreset({
  required ProjectSurfaceCatalog catalog,
  required String atlasId,
  required String? atlasCategoryDraft,
}) {
  for (final a in catalog.atlases) {
    if (a.id == atlasId) {
      final c = a.categoryId?.trim();
      if (c != null && c.isNotEmpty) {
        return c;
      }
      break;
    }
  }
  final d = atlasCategoryDraft?.trim();
  return (d == null || d.isEmpty) ? null : d;
}

/// Plan local : mapping + catalogue (animations déjà présentes) — ne crée rien.
SurfaceStudioVerticalAtlasPresetAppendPlan surfaceStudioPlanVerticalAtlasPresetAppend({
  required ProjectSurfaceCatalog catalog,
  required String atlasIdRaw,
  required String atlasDisplayName,
  required String? atlasCategoryDraft,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required bool gridValid,
}) {
  final atlasId = atlasIdRaw.trim();
  final presetId = surfaceStudioProposedVerticalAtlasPresetId(atlasIdRaw);
  final namePrefix = atlasDisplayName.trim().isEmpty ? atlasId : atlasDisplayName.trim();
  final proposedName = '$namePrefix — Surface';

  if (atlasId.isEmpty || presetId.isEmpty) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: 0,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedEmptyAtlasId,
      canCreate: false,
    );
  }
  if (!gridValid) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: 0,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedInvalidGrid,
      canCreate: false,
    );
  }

  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));
  if (assigned.isEmpty) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: 0,
      rolesNotCoveredCount: standardSurfaceVariantRoleOrder.length,
      missingAnimationCount: 0,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedNoMapping,
      canCreate: false,
    );
  }

  for (final p in catalog.presets) {
    if (p.id == presetId) {
      return SurfaceStudioVerticalAtlasPresetAppendPlan(
        proposedPresetId: presetId,
        proposedPresetName: proposedName,
        rolesCoveredCount: 0,
        rolesNotCoveredCount: 0,
        missingAnimationCount: 0,
        status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedDuplicatePresetId,
        canCreate: false,
      );
    }
  }

  final animationIds = <String>{for (final a in catalog.animations) a.id};
  final uniqueRolesOrdered = <SurfaceVariantRole>[];
  final seenRoles = <SurfaceVariantRole>{};
  for (final a in assigned) {
    final role = a.role!;
    if (!seenRoles.add(role)) {
      continue;
    }
    uniqueRolesOrdered.add(role);
  }
  var rolesWithAnimation = 0;
  for (final role in uniqueRolesOrdered) {
    final animId = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    if (animId.isNotEmpty && animationIds.contains(animId)) {
      rolesWithAnimation++;
    }
  }
  final missing = uniqueRolesOrdered.length - rolesWithAnimation;
  final covered = rolesWithAnimation;
  final assignedRoleSet = uniqueRolesOrdered.toSet();
  var notCovered = 0;
  for (final r in standardSurfaceVariantRoleOrder) {
    if (!assignedRoleSet.contains(r)) {
      notCovered++;
    }
  }

  String? partialMsg;
  if (notCovered > 0) {
    partialMsg =
        'Preset incomplet : certains rôles ne sont pas encore couverts par le mapping.';
  }

  if (missing > 0) {
    return SurfaceStudioVerticalAtlasPresetAppendPlan(
      proposedPresetId: presetId,
      proposedPresetName: proposedName,
      rolesCoveredCount: covered,
      rolesNotCoveredCount: notCovered,
      missingAnimationCount: missing,
      status: SurfaceStudioVerticalAtlasPresetPlanStatus.blockedMissingAnimations,
      canCreate: false,
      partialPresetUserMessage: partialMsg,
    );
  }

  final status = notCovered > 0
      ? SurfaceStudioVerticalAtlasPresetPlanStatus.incomplete
      : SurfaceStudioVerticalAtlasPresetPlanStatus.ready;

  return SurfaceStudioVerticalAtlasPresetAppendPlan(
    proposedPresetId: presetId,
    proposedPresetName: proposedName,
    rolesCoveredCount: covered,
    rolesNotCoveredCount: notCovered,
    missingAnimationCount: 0,
    status: status,
    canCreate: true,
    partialPresetUserMessage: partialMsg,
  );
}

/// Construit le preset à ajouter (refs **uniquement** pour animations présentes dans [catalog]).
ProjectSurfacePreset surfaceStudioBuildVerticalAtlasPreset({
  required ProjectSurfaceCatalog catalog,
  required String atlasIdRaw,
  required String atlasDisplayName,
  required String? atlasCategoryDraft,
  required SurfaceStudioColumnRoleMappingDraft mappingDraft,
  required bool gridValid,
}) {
  final plan = surfaceStudioPlanVerticalAtlasPresetAppend(
    catalog: catalog,
    atlasIdRaw: atlasIdRaw,
    atlasDisplayName: atlasDisplayName,
    atlasCategoryDraft: atlasCategoryDraft,
    mappingDraft: mappingDraft,
    gridValid: gridValid,
  );
  if (!plan.canCreate) {
    throw StateError('surfaceStudioBuildVerticalAtlasPreset: plan not creatable');
  }
  final atlasId = atlasIdRaw.trim();
  final assigned = mappingDraft.assignments
      .where((a) => a.role != null)
      .toList()
    ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));
  final animationIds = <String>{for (final a in catalog.animations) a.id};
  final byRole = <SurfaceVariantRole, String>{};
  for (final a in assigned) {
    final role = a.role!;
    final animId = surfaceStudioProposedAnimationId(
      atlasIdRaw: atlasIdRaw,
      role: role,
    );
    if (animId.isEmpty || !animationIds.contains(animId)) {
      continue;
    }
    byRole.putIfAbsent(role, () => animId);
  }
  final roles = byRole.keys.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  final refs = <SurfaceVariantAnimationRef>[
    for (final r in roles)
      SurfaceVariantAnimationRef(role: r, animationId: byRole[r]!),
  ];
  final refSet = SurfaceVariantAnimationRefSet(refs: refs);
  final catId = _categoryIdForPreset(
    catalog: catalog,
    atlasId: atlasId,
    atlasCategoryDraft: atlasCategoryDraft,
  );
  return ProjectSurfacePreset(
    id: plan.proposedPresetId,
    name: plan.proposedPresetName,
    variantAnimations: refSet,
    categoryId: catId,
    sortOrder: catalog.presets.length,
  );
}

/// Append **un** preset ; atlases et animations inchangés.
ProjectSurfaceCatalog surfaceStudioAppendPresetToWorkCatalog({
  required ProjectSurfaceCatalog catalog,
  required ProjectSurfacePreset preset,
}) {
  return ProjectSurfaceCatalog(
    atlases: List<ProjectSurfaceAtlas>.from(catalog.atlases),
    animations: List<ProjectSurfaceAnimation>.from(catalog.animations),
    presets: [...catalog.presets, preset],
  );
}
