import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final map = MapData(
      id: 'source',
      name: 'Source',
      size: const GridSize(width: 8, height: 8),
      connections: const [
        MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'first',
            offset: 0),
        MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'second',
            offset: 4),
      ]);
  test('an edge with unknown multiple neighbors blocks safely', () {
    final result = stepGameplayWorld(
        GameplayWorldState.initial(
            map: map, playerPos: const GridPos(x: 7, y: 5)),
        const MoveIntent(Direction.east));
    expect(result, isA<Blocked>());
  });
  final sizes = {
    'first': const GridSize(width: 4, height: 4),
    'second': const GridSize(width: 4, height: 4)
  };
  for (final direction in MapConnectionDirection.values) {
    test(
        '${direction.name} unknown single target requires an actual source border',
        () {
      final source = map.copyWith(
          connections: [map.connections.first.copyWith(direction: direction)]);
      for (final position in const [
        GridPos(x: 3, y: 3),
        GridPos(x: -1, y: 3),
        GridPos(x: 8, y: 3),
        GridPos(x: 3, y: -1),
        GridPos(x: 3, y: 8)
      ]) {
        expect(
            resolveMapConnectionForPosition(
                map: source,
                sourcePos: position,
                direction: direction,
                targetMapSizes: const {}),
            isNull,
            reason: '$direction $position cannot cross this edge');
      }
      final border = switch (direction) {
        MapConnectionDirection.east => const GridPos(x: 7, y: 3),
        MapConnectionDirection.west => const GridPos(x: 0, y: 3),
        MapConnectionDirection.north => const GridPos(x: 3, y: 0),
        MapConnectionDirection.south => const GridPos(x: 3, y: 7),
      };
      expect(
          resolveMapConnectionForPosition(
              map: source,
              sourcePos: border,
              direction: direction,
              targetMapSizes: const {}),
          source.connections.single);
    });
    for (final axis in [0, 3, 4, 7]) {
      test('${direction.name} selects the actual covered target at $axis', () {
        final source = map.copyWith(connections: [
          for (final connection in map.connections)
            connection.copyWith(direction: direction)
        ]);
        final position = switch (direction) {
          MapConnectionDirection.east => GridPos(x: 7, y: axis),
          MapConnectionDirection.west => GridPos(x: 0, y: axis),
          MapConnectionDirection.north => GridPos(x: axis, y: 0),
          MapConnectionDirection.south => GridPos(x: axis, y: 7),
        };
        final move = Direction.values
            .singleWhere((value) => value.name == direction.name);
        final result = stepGameplayWorld(
            GameplayWorldState.initial(map: source, playerPos: position),
            MoveIntent(move),
            connectionTargetSizes: sizes);
        expect(result, isA<ConnectionTriggered>());
        expect((result as ConnectionTriggered).connection.targetMapId,
            axis < 4 ? 'first' : 'second');
      });
    }
  }
  test('a gap, ambiguous span, or incomplete geometry blocks', () {
    for (final connections in [
      [map.connections.first, map.connections.last.copyWith(offset: 5)],
      [map.connections.first, map.connections.last.copyWith(offset: 3)],
    ]) {
      final result = stepGameplayWorld(
          GameplayWorldState.initial(
              map: map.copyWith(connections: connections),
              playerPos:
                  GridPos(x: 7, y: connections.last.offset == 5 ? 4 : 3)),
          const MoveIntent(Direction.east),
          connectionTargetSizes: sizes);
      expect(result, isA<Blocked>());
    }
    final result = stepGameplayWorld(
        GameplayWorldState.initial(
            map: map, playerPos: const GridPos(x: 7, y: 1)),
        const MoveIntent(Direction.east),
        connectionTargetSizes: {'first': sizes['first']!});
    expect(result, isA<Blocked>());
  });
}
