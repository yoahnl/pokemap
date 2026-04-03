import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('GridPathfinder', () {
    const pathfinder = GridPathfinder();

    test('finds straight line path on empty grid', () {
      const bounds = GridSize(width: 6, height: 4);
      final result = pathfinder.findPath(
        bounds: bounds,
        start: const GridPos(x: 1, y: 1),
        goal: const GridPos(x: 4, y: 1),
        isPassable: (_, __) => true,
      );

      expect(result.foundPath, isTrue);
      expect(
        result.path,
        const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 4, y: 1),
        ],
      );
    });

    test('detours around an obstacle when destination remains reachable', () {
      const bounds = GridSize(width: 5, height: 5);
      final blocked = <GridPos>{
        const GridPos(x: 2, y: 1),
        const GridPos(x: 2, y: 2),
        const GridPos(x: 2, y: 3),
      };
      final result = pathfinder.findPath(
        bounds: bounds,
        start: const GridPos(x: 1, y: 2),
        goal: const GridPos(x: 3, y: 2),
        isPassable: (x, y) => !blocked.contains(GridPos(x: x, y: y)),
      );

      expect(result.foundPath, isTrue);
      // Le chemin attendu passe par le haut car l'ordre de voisinage est
      // déterministe (N, E, S, W).
      expect(
        result.path,
        const <GridPos>[
          GridPos(x: 1, y: 2),
          GridPos(x: 1, y: 1),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 3, y: 1),
          GridPos(x: 3, y: 2),
        ],
      );
    });

    test('fails cleanly when destination is unreachable', () {
      const bounds = GridSize(width: 5, height: 5);
      final blocked = <GridPos>{
        const GridPos(x: 2, y: 0),
        const GridPos(x: 2, y: 1),
        const GridPos(x: 2, y: 2),
        const GridPos(x: 2, y: 3),
        const GridPos(x: 2, y: 4),
      };
      final result = pathfinder.findPath(
        bounds: bounds,
        start: const GridPos(x: 1, y: 2),
        goal: const GridPos(x: 3, y: 2),
        isPassable: (x, y) => !blocked.contains(GridPos(x: x, y: y)),
      );

      expect(result.foundPath, isFalse);
      expect(result.path, isEmpty);
      expect(result.failureReason, contains('No path found'));
    });

    test('returns trivial path when start equals goal', () {
      const bounds = GridSize(width: 5, height: 5);
      final result = pathfinder.findPath(
        bounds: bounds,
        start: const GridPos(x: 2, y: 2),
        goal: const GridPos(x: 2, y: 2),
        isPassable: (_, __) => true,
      );

      expect(result.foundPath, isTrue);
      expect(result.path, const <GridPos>[GridPos(x: 2, y: 2)]);
    });
  });
}
