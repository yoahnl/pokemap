import 'package:map_core/map_core.dart';

enum ElementCollisionTruthMode {
  fineMask,
  legacyCells,
  empty,
}

final class ElementCollisionTruthSummary {
  const ElementCollisionTruthSummary({
    required this.mode,
    required this.title,
    required this.description,
    required this.detail,
    required this.hasCollisionMask,
    required this.hasLegacyCells,
    required this.hasVisualMask,
    required this.hasOcclusionMask,
    this.notes = const <String>[],
  });

  final ElementCollisionTruthMode mode;
  final String title;
  final String description;
  final String detail;
  final bool hasCollisionMask;
  final bool hasLegacyCells;
  final bool hasVisualMask;
  final bool hasOcclusionMask;
  final List<String> notes;

  bool get hasActiveCollision => mode != ElementCollisionTruthMode.empty;
}

ElementCollisionTruthSummary summarizeElementCollisionTruth(
  ElementCollisionProfile? profile,
) {
  final hasCollisionMask = profile?.collisionMask != null;
  final hasLegacyCells = profile?.cells.isNotEmpty ?? false;
  final hasVisualMask = profile?.visualMask != null;
  final hasOcclusionMask = profile?.occlusionMask != null;
  final notes = <String>[
    if (hasVisualMask)
      'Masque visuel disponible pour l’aperçu/analyse : il ne bloque pas le joueur.',
    if (hasOcclusionMask)
      'Masque d’occlusion disponible : il sert au rendu devant/derrière et ne bloque pas le joueur.',
  ];

  if (hasCollisionMask) {
    return ElementCollisionTruthSummary(
      mode: ElementCollisionTruthMode.fineMask,
      title: 'Collision fine active',
      description: 'Le gameplay utilise le masque de collision fin.',
      detail:
          'La grille sert de projection de compatibilité et d’aperçu grossier.',
      hasCollisionMask: hasCollisionMask,
      hasLegacyCells: hasLegacyCells,
      hasVisualMask: hasVisualMask,
      hasOcclusionMask: hasOcclusionMask,
      notes: notes,
    );
  }

  if (hasLegacyCells) {
    return ElementCollisionTruthSummary(
      mode: ElementCollisionTruthMode.legacyCells,
      title: 'Collision par grille',
      description:
          'Aucun masque fin n’est défini. Le gameplay utilise les cellules de la grille comme fallback.',
      detail: 'La précision est limitée à la grille de l’élément.',
      hasCollisionMask: hasCollisionMask,
      hasLegacyCells: hasLegacyCells,
      hasVisualMask: hasVisualMask,
      hasOcclusionMask: hasOcclusionMask,
      notes: notes,
    );
  }

  return ElementCollisionTruthSummary(
    mode: ElementCollisionTruthMode.empty,
    title: 'Aucune collision active',
    description: 'Cet élément ne bloque pas le joueur.',
    detail: 'Aucun masque fin ni cellule de collision n’est défini.',
    hasCollisionMask: hasCollisionMask,
    hasLegacyCells: hasLegacyCells,
    hasVisualMask: hasVisualMask,
    hasOcclusionMask: hasOcclusionMask,
    notes: notes,
  );
}
