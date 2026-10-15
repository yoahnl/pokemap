import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  for (final actual in Direction.values) {
    for (final direction in EntityFacing.values) {
      for (final expected in [true, false]) {
        test('reads live $actual against $direction expected $expected', () {
          final world = GameplayWorldState.initial(
            map: MapData(
                id: 'map',
                name: 'Map',
                size: const GridSize(width: 3, height: 3)),
            playerPos: const GridPos(x: 1, y: 1),
            playerFacing: actual,
          );
          final source = SceneConditionSource.playerFacing(
              direction: direction, expected: expected);
          expect(evaluateScenePlayerFacing(source: source, world: world),
              (actual.asFacing == direction) == expected);
          expect(world.player.facing, actual);
          expect(world.player.pos, const GridPos(x: 1, y: 1));
        });
      }
    }
  }
  test('rejects another kind instead of interpreting its source ID', () {
    final world = GameplayWorldState.initial(
        map: MapData(
            id: 'map', name: 'Map', size: const GridSize(width: 3, height: 3)),
        playerPos: const GridPos(x: 1, y: 1));
    expect(
        () => evaluateScenePlayerFacing(
            source: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.factLikeStoryFlag,
                sourceId: 'north',
                operator: SceneConditionOperator.isTrue),
            world: world),
        throwsArgumentError);
  });
}
