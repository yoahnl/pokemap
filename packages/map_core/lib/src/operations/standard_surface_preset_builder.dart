import '../models/surface.dart';

/// Construit un [ProjectSurfacePreset] à partir d’une **liste de rôles** (ordre
/// explicite) et d’une **stratégie** `animationId` par rôle, sans handballer
/// manuellement chaque [SurfaceVariantAnimationRef] et le
/// [SurfaceVariantAnimationRefSet].
///
/// * API d’**ergonomie** autour des modèles existants (Lot 31) : **aucune**
///   persistance, pas de [toJson], pas de raccrochage [ProjectManifest].
/// * Ne **résout** pas `animationId` vers un [ProjectSurfaceAnimation] ni ne
///   vérifie l’existence d’animations, d’atlas, de frames ou de durées.
/// * L’**ordre** de [roles] est préservé tel quel (pas de tri, pas de
///   [standardSurfaceVariantRoleOrder] appliqué en interne quand un argument est
///   passé) ; seulement la **valeur par défaut** du paramètre [roles] vaut
///   [standardSurfaceVariantRoleOrder].
/// * Les invariants (id/name non vides côté trim, set non vide, rôles uniques,
///   `animationId` non vide) sont laissés aux **value objects** existants ; ce
///   module ne recopie pas ces garde-fous.
/// * Pas de [SurfacePresetKind], pas de gameplay, pas d’eau / herbe : purement
///   le **raccord rôle → id d’animation** pour l’auteur.
ProjectSurfacePreset createStandardProjectSurfacePreset({
  required String id,
  required String name,
  required String Function(SurfaceVariantRole role) animationIdForRole,
  List<SurfaceVariantRole> roles = standardSurfaceVariantRoleOrder,
  String? categoryId,
  int sortOrder = 0,
}) {
  final refs = <SurfaceVariantAnimationRef>[
    for (final role in roles)
      SurfaceVariantAnimationRef(
        role: role,
        animationId: animationIdForRole(role),
      ),
  ];

  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}
