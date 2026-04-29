import 'package:map_core/map_core.dart';

import '../surface_studio_vertical_atlas_role_mapping.dart';

final class TiledTsxSurfacePresetDraft {
  const TiledTsxSurfacePresetDraft({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.sortOrder,
    required this.roleAnimationIds,
  });

  final String id;
  final String name;
  final String? categoryId;
  final int sortOrder;
  final Map<SurfaceVariantRole, String> roleAnimationIds;
}

final class TiledTsxSurfacePresetDraftValidation {
  const TiledTsxSurfacePresetDraftValidation({
    required this.canCreate,
    required this.errors,
    required this.warnings,
  });

  final bool canCreate;
  final List<String> errors;
  final List<String> warnings;
}

TiledTsxSurfacePresetDraftValidation validateTiledTsxSurfacePresetDraft({
  required TiledTsxSurfacePresetDraft draft,
  required ProjectSurfaceCatalog catalog,
}) {
  final errors = <String>[];
  final warnings = <String>[];
  final presetId = draft.id.trim();
  final presetName = draft.name.trim();

  if (presetId.isEmpty) {
    errors.add('Identifiant surface obligatoire.');
  } else if (catalog.containsPreset(presetId)) {
    errors.add('Identifiant de preset déjà utilisé.');
  }
  if (presetName.isEmpty) {
    errors.add('Nom surface obligatoire.');
  }

  final cleaned = _cleanRoleAnimationIds(draft.roleAnimationIds);
  final isolatedAnimationId = cleaned[SurfaceVariantRole.isolated];
  if (isolatedAnimationId == null || isolatedAnimationId.isEmpty) {
    errors.add('Plein(center) obligatoire.');
  }

  for (final role in standardSurfaceVariantRoleOrder) {
    final animationId = cleaned[role];
    if (animationId == null || animationId.isEmpty) {
      continue;
    }
    if (!catalog.containsAnimation(animationId)) {
      errors.add(
        'Animation inconnue pour ${SurfaceStudioRoleLabels.labelForRole(role)} : $animationId.',
      );
    }
  }

  if (errors.isEmpty) {
    final missingCount = standardSurfaceVariantRoleOrder
        .where((role) => !cleaned.containsKey(role))
        .length;
    if (missingCount > 0) {
      warnings.add(
        'Surface partielle : $missingCount rôles standards ne sont pas mappés.',
      );
    }
  }

  return TiledTsxSurfacePresetDraftValidation(
    canCreate: errors.isEmpty,
    errors: List<String>.unmodifiable(errors),
    warnings: List<String>.unmodifiable(warnings),
  );
}

ProjectSurfacePreset buildTiledTsxSurfacePresetFromDraft({
  required TiledTsxSurfacePresetDraft draft,
  required ProjectSurfaceCatalog catalog,
}) {
  final validation = validateTiledTsxSurfacePresetDraft(
    draft: draft,
    catalog: catalog,
  );
  if (!validation.canCreate) {
    throw StateError(
      'buildTiledTsxSurfacePresetFromDraft: ${validation.errors.join(' ')}',
    );
  }

  final cleaned = _cleanRoleAnimationIds(draft.roleAnimationIds);
  final refs = <SurfaceVariantAnimationRef>[
    for (final role in standardSurfaceVariantRoleOrder)
      if (cleaned.containsKey(role))
        SurfaceVariantAnimationRef(
          role: role,
          animationId: cleaned[role]!,
        ),
  ];
  final category = draft.categoryId?.trim();
  return ProjectSurfacePreset(
    id: draft.id.trim(),
    name: draft.name.trim(),
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
    categoryId: category == null || category.isEmpty ? null : category,
    sortOrder: draft.sortOrder,
  );
}

Map<SurfaceVariantRole, String> _cleanRoleAnimationIds(
  Map<SurfaceVariantRole, String> source,
) {
  final cleaned = <SurfaceVariantRole, String>{};
  for (final role in standardSurfaceVariantRoleOrder) {
    final id = source[role]?.trim();
    if (id != null && id.isNotEmpty) {
      cleaned[role] = id;
    }
  }
  return cleaned;
}
