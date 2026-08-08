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
  final probe = PreparedScriptedNpcAnchorProbe.forEntity(
    world: world,
    entityId: normalizedId,
  );
  if (probe == null) {
    return ScriptedNpcAnchorPassabilityResult(
      passable: false,
      reason: 'Unknown entity "$normalizedId".',
      evaluatedCollisionCells: const <GridPos>[],
    );
  }
  final dynamicBlocked =
      dynamicBlockedCells is Set<GridPos> ? dynamicBlockedCells : dynamicBlockedCells.toSet();
  return probe.evaluate(
    world: world,
    anchorPos: anchorPos,
    isDynamicallyBlocked:
        dynamicBlocked.isEmpty ? null : dynamicBlocked.contains,
    movementMode: movementMode,
  );
}

/// Prédicat de blocage dynamique interrogé cellule par cellule.
typedef ScriptedNpcDynamicCellBlocked = bool Function(GridPos cell);

/// Sonde de passabilité préparée pour une entité d'un monde donné.
///
/// Le callback `isPassable` du pathfinder est appelé une fois par nœud A*
/// expansé : résoudre l'entité (scan linéaire), la cloner via `copyWith` et
/// re-résoudre son footprint par nœud dominait le coût de chaque re-path de
/// patrouille. La footprint collision est translationnelle (offsets constants
/// par rapport à l'ancre), donc elle se fige ici une seule fois.
final class PreparedScriptedNpcAnchorProbe {
  PreparedScriptedNpcAnchorProbe._({
    required this.entityId,
    required List<GridPos> collisionCellOffsets,
  }) : _collisionCellOffsets = collisionCellOffsets;

  static PreparedScriptedNpcAnchorProbe? forEntity({
    required GameplayWorldState world,
    required String entityId,
  }) {
    final normalizedId = entityId.trim();
    if (normalizedId.isEmpty) {
      return null;
    }
    MapEntity? entity;
    for (final candidate in world.map.entities) {
      if (candidate.id == normalizedId) {
        entity = candidate;
        break;
      }
    }
    if (entity == null) {
      return null;
    }
    final anchor = entity.pos;
    final offsets = <GridPos>[
      for (final cell in resolveEntityCollisionCells(entity))
        GridPos(x: cell.x - anchor.x, y: cell.y - anchor.y),
    ];
    return PreparedScriptedNpcAnchorProbe._(
      entityId: normalizedId,
      collisionCellOffsets: List<GridPos>.unmodifiable(offsets),
    );
  }

  final String entityId;
  final List<GridPos> _collisionCellOffsets;

  ScriptedNpcAnchorPassabilityResult evaluate({
    required GameplayWorldState world,
    required GridPos anchorPos,
    ScriptedNpcDynamicCellBlocked? isDynamicallyBlocked,
    MovementMode movementMode = MovementMode.walk,
  }) {
    final collisionCells = List<GridPos>.generate(
      _collisionCellOffsets.length,
      (index) {
        final offset = _collisionCellOffsets[index];
        return GridPos(x: anchorPos.x + offset.x, y: anchorPos.y + offset.y);
      },
      growable: false,
    );
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
      if (occupant != null && occupant.id == entityId) {
        // Auto-ignore: la case est actuellement occupée par ce NPC. On
        // autorise ce recouvrement partiel pendant le calcul de chemin.
        continue;
      }

      if (isDynamicallyBlocked != null && isDynamicallyBlocked(cell)) {
        return ScriptedNpcAnchorPassabilityResult(
          passable: false,
          reason:
              'Dynamic blocker at (${cell.x}, ${cell.y}) for anchor (${anchorPos.x}, ${anchorPos.y}).',
          evaluatedCollisionCells: collisionCells,
        );
      }

      final movementBlockReason =
          world.movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(
        cellX: cell.x,
        cellY: cell.y,
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
}
