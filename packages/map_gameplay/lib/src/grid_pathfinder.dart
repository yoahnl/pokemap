import 'dart:collection';

import 'package:map_core/map_core.dart';

/// Ordre cardinal déterministe utilisé par le pathfinding.
///
/// On fixe explicitement l'ordre des voisins pour garantir qu'un même input
/// produit toujours le même chemin (important pour les tests, la reproductibilité
/// runtime et les futures cutscenes scriptées).
const List<GridPos> _kCardinalOffsets = <GridPos>[
  GridPos(x: 0, y: -1), // nord
  GridPos(x: 1, y: 0), // est
  GridPos(x: 0, y: 1), // sud
  GridPos(x: -1, y: 0), // ouest
];

/// Contrat minimal du pathfinding grille.
///
/// La passabilité est déléguée à un callback externe pour rester découplé
/// du runtime Flame et réutilisable dans différentes couches.
typedef GridCellPassability = bool Function(int x, int y);

/// Résultat d'une recherche de chemin.
///
/// - [path] contient toujours la case de départ et la case d'arrivée en cas
///   de succès;
/// - [path] est vide en cas d'échec;
/// - [failureReason] permet d'exposer un diagnostic simple.
class GridPathfindingResult {
  const GridPathfindingResult._({
    required this.path,
    required this.failureReason,
  });

  factory GridPathfindingResult.success(List<GridPos> path) {
    return GridPathfindingResult._(
      path: List<GridPos>.unmodifiable(path),
      failureReason: null,
    );
  }

  factory GridPathfindingResult.failure(String reason) {
    return GridPathfindingResult._(
      path: const <GridPos>[],
      failureReason: reason,
    );
  }

  final List<GridPos> path;
  final String? failureReason;

  bool get foundPath => path.isNotEmpty;
}

/// Pathfinder grille 4-directions (BFS), déterministe et testable.
///
/// Pourquoi BFS ici:
/// - MVP cutscene: on veut surtout robustesse + simplicité de debug;
/// - coûts homogènes sur grille (1 pas = 1 coût);
/// - résultat stable grâce à l'ordre fixe des voisins.
class GridPathfinder {
  const GridPathfinder();

  /// Recherche un chemin entre [start] et [goal] dans [bounds].
  ///
  /// Contraintes:
  /// - 4 directions cardinales uniquement;
  /// - la passabilité d'une cellule est donnée par [isPassable];
  /// - la case de départ est toujours autorisée (même si marquée "bloquée"
  ///   côté callback), pour gérer proprement les entités occupant leur
  ///   propre cellule.
  GridPathfindingResult findPath({
    required GridSize bounds,
    required GridPos start,
    required GridPos goal,
    required GridCellPassability isPassable,
  }) {
    if (!_isInside(bounds, start.x, start.y)) {
      return GridPathfindingResult.failure(
        'Start out of bounds: (${start.x}, ${start.y})',
      );
    }
    if (!_isInside(bounds, goal.x, goal.y)) {
      return GridPathfindingResult.failure(
        'Goal out of bounds: (${goal.x}, ${goal.y})',
      );
    }

    // Cas trivial : déjà à destination.
    if (start.x == goal.x && start.y == goal.y) {
      return GridPathfindingResult.success(<GridPos>[start]);
    }

    // Si la destination est bloquée, on échoue immédiatement avec une raison
    // explicite (plus lisible pour l'orchestration runtime).
    if (!isPassable(goal.x, goal.y)) {
      return GridPathfindingResult.failure(
        'Goal is not passable: (${goal.x}, ${goal.y})',
      );
    }

    final queue = ListQueue<GridPos>()..add(start);
    final visited = <int>{_key(bounds, start.x, start.y)};
    final parentByCell = <int, int>{};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.x == goal.x && current.y == goal.y) {
        return GridPathfindingResult.success(
          _rebuildPath(
            bounds: bounds,
            start: start,
            goal: goal,
            parentByCell: parentByCell,
          ),
        );
      }

      for (final offset in _kCardinalOffsets) {
        final nx = current.x + offset.x;
        final ny = current.y + offset.y;

        if (!_isInside(bounds, nx, ny)) {
          continue;
        }
        final nKey = _key(bounds, nx, ny);
        if (visited.contains(nKey)) {
          continue;
        }

        // La cellule de départ reste autorisée même si "bloquée", pour éviter
        // qu'une entité soit empêchée de partir de sa propre case.
        final isStartCell = nx == start.x && ny == start.y;
        if (!isStartCell && !isPassable(nx, ny)) {
          continue;
        }

        visited.add(nKey);
        parentByCell[nKey] = _key(bounds, current.x, current.y);
        queue.add(GridPos(x: nx, y: ny));
      }
    }

    return GridPathfindingResult.failure(
      'No path found from (${start.x}, ${start.y}) to (${goal.x}, ${goal.y})',
    );
  }

  bool _isInside(GridSize bounds, int x, int y) {
    return x >= 0 && y >= 0 && x < bounds.width && y < bounds.height;
  }

  int _key(GridSize bounds, int x, int y) => y * bounds.width + x;

  GridPos _fromKey(GridSize bounds, int key) {
    final x = key % bounds.width;
    final y = key ~/ bounds.width;
    return GridPos(x: x, y: y);
  }

  List<GridPos> _rebuildPath({
    required GridSize bounds,
    required GridPos start,
    required GridPos goal,
    required Map<int, int> parentByCell,
  }) {
    final startKey = _key(bounds, start.x, start.y);
    var cursor = _key(bounds, goal.x, goal.y);
    final reversed = <GridPos>[goal];

    // On remonte les parents jusqu'à la case de départ.
    while (cursor != startKey) {
      final parent = parentByCell[cursor];
      if (parent == null) {
        // Garde-fou de cohérence: ne devrait pas arriver si BFS a bien trouvé.
        return <GridPos>[start];
      }
      cursor = parent;
      reversed.add(_fromKey(bounds, cursor));
    }

    return reversed.reversed.toList(growable: false);
  }
}
