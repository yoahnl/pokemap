import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/spatial_trainer_spotting.dart';
import 'package:test/test.dart';

void main() {
  final trainer = MapEntity(
      id: 'guard',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 2, y: 2),
      npc: const MapEntityNpcData(
          characterId: 'actor',
          trainerId: 'challenger',
          facing: EntityFacing.south,
          lineOfSightRange: 4));
  SpatialTrainerSpot? spot(
          {double x = 2.5,
          double z = 5.5,
          bool allowed = true,
          bool clear = true,
          SpatialActorRuntimeState? pose}) =>
      findSpatialTrainerSpot(
          entities: [trainer],
          playerX: x,
          playerZ: z,
          eligible: (_) => allowed,
          actorState: (_) => pose,
          canTraverse: (_, fromX, fromZ, toX, toZ) => clear);
  test('stops one cell before player without moving the player', () {
    final result = spot()!;
    expect(result.entity.id, 'guard');
    expect(result.targetX, 2.5);
    expect(result.targetZ, 4.5);
    expect(result.playerFacing, EntityFacing.north);
  });
  test('rejects behind, diagonal, beyond range and non finite positions', () {
    for (final p in [(2.5, 1.5), (3.5, 5.5), (2.5, 7.5), (double.nan, 4.5)]) {
      expect(spot(x: p.$1, z: p.$2), isNull);
    }
  });
  test('obstacles and caller eligibility prevent detection', () {
    expect(spot(clear: false), isNull);
    expect(spot(allowed: false), isNull);
  });
  test('does not resolve narrative eligibility outside the sight corridor', () {
    var checks = 0;
    expect(
        findSpatialTrainerSpot(
            entities: [trainer],
            playerX: 15,
            playerZ: 20,
            eligible: (_) {
              checks++;
              return true;
            },
            canTraverse: (_, a, b, c, d) => true),
        isNull);
    expect(checks, 0);
  });
  test('uses moved actor orientation and current pose', () {
    final pose =
        SpatialActorRuntimeState(x: 4.5, z: 5.5, facing: EntityFacing.west);
    expect(spot(pose: pose)!.targetX, 3.5);
    expect(spot(pose: pose)!.playerFacing, EntityFacing.east);
  });
  test('disabled trainers and overlapping actors cannot spot', () {
    expect(spot(z: 2.5), isNull);
    expect(
        findSpatialTrainerSpot(
            entities: [
              trainer.copyWith(npc: trainer.npc!.copyWith(lineOfSightRange: 0))
            ],
            playerX: 2.5,
            playerZ: 5.5,
            eligible: (_) => true,
            canTraverse: (_, a, b, c, d) => true),
        isNull);
  });
}
