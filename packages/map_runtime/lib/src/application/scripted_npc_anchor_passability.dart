import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

/// Résultat d'évaluation de passabilité pour une position d'ancrage NPC.
///
/// L'ancrage est la position logique `MapEntity.pos` (coin haut-gauche de
/// l'entité dans le modèle). La collision réelle peut utiliser un offset
/// (cas NPC 2x2 avec collision par défaut 1x1 sur les "pieds"), d'où
/// l'importance de valider le *footprint collision* plutôt qu'une seule case.
class ScriptedNpcAnchorPassabilityResult {
  const ScriptedNpcAnchorPassabilityResult({
    required this.passable,
    required this.reason,
    required this.evaluatedCollisionCells,
  });

  final bool passable;
  final String reason;
  final List<GridPos> evaluatedCollisionCells;
}

/// Valide si un NPC peut occuper [anchorPos] dans [world].
///
/// Règles:
/// - l'entité doit exister;
/// - toutes les cellules collision de la position candidate doivent rester
///   dans les bornes map;
/// - toutes ces cellules doivent être non bloquées, sauf les cellules déjà
///   occupées par cette même entité (auto-ignore pour éviter l'auto-collision
///   pendant le pathfinding).
///
/// Ce helper sert à fiabiliser la patrouille:
/// - waypoints suivis exactement (pas de remap silencieux),
/// - échec explicite si la cible est invalide/inatteignable.
ScriptedNpcAnchorPassabilityResult evaluateScriptedNpcAnchorPassability({
  required GameplayWorldState world,
  required String entityId,
  required GridPos anchorPos,
  Iterable<GridPos> dynamicBlockedCells = const <GridPos>[],
  MovementMode movementMode = MovementMode.walk,
}) {
  final normalizedId = entityId.trim();
  if (normalizedId.isEmpty) {
    return const ScriptedNpcAnchorPassabilityResult(
      passable: false,
      reason: 'Empty entityId.',
      evaluatedCollisionCells: <GridPos>[],
    );
  }
  final entity = world.map.entities
      .where((candidate) => candidate.id == normalizedId)
      .cast<MapEntity?>()
      .firstWhere(
        (candidate) => candidate != null,
        orElse: () => null,
      );
  if (entity == null) {
    return ScriptedNpcAnchorPassabilityResult(
      passable: false,
      reason: 'Unknown entity "$normalizedId".',
      evaluatedCollisionCells: const <GridPos>[],
    );
  }

  final moved = entity.copyWith(pos: anchorPos);
  final collisionCells =
      resolveEntityCollisionCells(moved).toList(growable: false);
  final dynamicBlocked = dynamicBlockedCells.toSet();
  for (final cell in collisionCells) {
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= world.map.size.width ||
        cell.y >= world.map.size.height) {
      return ScriptedNpcAnchorPassabilityResult(
        passable: false,
        reason:
            'Collision footprint out of bounds at (${cell.x}, ${cell.y}) for anchor (${anchorPos.x}, ${anchorPos.y}).',
        evaluatedCollisionCells: collisionCells,
      );
    }

    final occupant = world.entityAt(cell.x, cell.y);
    if (occupant != null && occupant.id == normalizedId) {
      // Auto-ignore: la case est actuellement occupée par ce NPC. On autorise
      // ce recouvrement partiel pendant le calcul de chemin.
      continue;
    }

    if (dynamicBlocked.contains(cell)) {
      return ScriptedNpcAnchorPassabilityResult(
        passable: false,
        reason:
            'Dynamic blocker at (${cell.x}, ${cell.y}) for anchor (${anchorPos.x}, ${anchorPos.y}).',
        evaluatedCollisionCells: collisionCells,
      );
    }

    final movementBlockReason = world.movementBlockReasonAt(
      x: cell.x,
      y: cell.y,
      movementMode: movementMode,
    );
    if (movementBlockReason != null) {
      return ScriptedNpcAnchorPassabilityResult(
        passable: false,
        reason:
            'Blocked collision cell (${cell.x}, ${cell.y}) for anchor (${anchorPos.x}, ${anchorPos.y}) reason=${movementBlockReason.name}.',
        evaluatedCollisionCells: collisionCells,
      );
    }
  }

  return ScriptedNpcAnchorPassabilityResult(
    passable: true,
    reason: 'Anchor is passable.',
    evaluatedCollisionCells: collisionCells,
  );
}
