import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _manualSteps = CommittedMovementStepPolicy(
  forcedMovement: ForcedMovementStepPolicy.exclude,
);
const _allTraversedSteps = CommittedMovementStepPolicy(
  forcedMovement: ForcedMovementStepPolicy.include,
);

CommittedMovement _movement(
  CommittedMovementKind kind, {
  GridPos from = const GridPos(x: 4, y: 7),
  GridPos to = const GridPos(x: 5, y: 7),
}) =>
    CommittedMovement(kind: kind, fromCell: from, toCell: to);

void main() {
  for (final kind in CommittedMovementKind.values) {
    test('${kind.name} has an explicit movement unit policy', () {
      final movement = _movement(kind);
      final manualExpected = switch (kind) {
        CommittedMovementKind.walk ||
        CommittedMovementKind.bicycle ||
        CommittedMovementKind.surf =>
          1,
        _ => 0,
      };
      final allExpected =
          kind == CommittedMovementKind.forced ? 1 : manualExpected;

      expect(_manualSteps.unitsFor(movement), manualExpected);
      expect(_allTraversedSteps.unitsFor(movement), allExpected);
    });
  }

  for (final target in const [
    GridPos(x: 3, y: 7),
    GridPos(x: 5, y: 7),
    GridPos(x: 4, y: 6),
    GridPos(x: 4, y: 8),
    GridPos(x: 3, y: 6),
    GridPos(x: 3, y: 8),
    GridPos(x: 5, y: 6),
    GridPos(x: 5, y: 8),
  ]) {
    test('each committed neighboring cell counts once at $target', () {
      expect(
        _manualSteps
            .unitsFor(_movement(CommittedMovementKind.walk, to: target)),
        1,
      );
    });
  }

  for (final kind in const [
    CommittedMovementKind.walk,
    CommittedMovementKind.forced,
    CommittedMovementKind.bicycle,
    CommittedMovementKind.surf,
  ]) {
    for (final target in const [
      GridPos(x: 4, y: 7),
      GridPos(x: 6, y: 9),
      GridPos(x: 6, y: 7),
      GridPos(x: 4, y: 4),
    ]) {
      test('${kind.name} does not invent a traversed path to $target', () {
        expect(
          _allTraversedSteps.unitsFor(_movement(kind, to: target)),
          0,
        );
      });
    }
  }

  test('a connection boundary adds no unit to its committed approach cell', () {
    final journey = [
      _movement(CommittedMovementKind.walk),
      _movement(CommittedMovementKind.mapConnection),
      _movement(CommittedMovementKind.walk,
          from: const GridPos(x: 0, y: 7), to: const GridPos(x: 1, y: 7)),
    ];

    expect(
        journey.fold(0, (total, step) => total + _manualSteps.unitsFor(step)),
        2);
  });

  test('rejected attempts and warp arrival add no unit to a travelled cell',
      () {
    final journey = [
      _movement(CommittedMovementKind.blocked),
      _movement(CommittedMovementKind.walk),
      _movement(CommittedMovementKind.warp, to: const GridPos(x: 90, y: 20)),
    ];

    expect(
        journey.fold(0, (total, step) => total + _manualSteps.unitsFor(step)),
        1);
  });

  test('consumers can choose whether each cell of a forced route counts', () {
    final route = [
      _movement(CommittedMovementKind.forced),
      _movement(CommittedMovementKind.forced,
          from: const GridPos(x: 5, y: 7), to: const GridPos(x: 6, y: 7)),
    ];

    expect(
        route.fold(0, (total, step) => total + _manualSteps.unitsFor(step)), 0);
    expect(
        route.fold(
            0, (total, step) => total + _allTraversedSteps.unitsFor(step)),
        2);
  });
}
