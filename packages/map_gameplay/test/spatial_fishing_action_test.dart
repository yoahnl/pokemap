import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'fishing_action_test.dart' as fixture;

MapData spatialMap({bool cliff = false}) => fixture.waterMap().copyWith(
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 8, depth: 8, heightLevels: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 8; x++) cliff && x >= 3 ? 2 : 0,
      ]),
    );

GameState spatialState() => fixture.state().copyWith(
      playerSpatialPosition: PlayerSpatialPosition(x: 2.75, z: 2.25),
    );

void main() {
  for (final kind in ProjectFishingRodKind.values) {
    test('3D $kind resolves front water with the existing encounter pipeline',
        () {
      final map = spatialMap(), state = spatialState();
      final project = fixture.project(), item = fixture.rod(kind);
      final random = fixture.CountingRandom(42);
      final result = resolveFishingAttempt(
        ticket: fixture.ticket(
            map: map, current: state, manifest: project, item: item),
        world: fixture.world(map, state),
        project: project,
        gameState: state,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random,
      );
      expect(result.reason, isNull);
      expect(result.encounterCheck?.triggered, isTrue);
      expect(result.encounterCheck?.encounter?.tableId, kind.name);
      expect(result.encounterCheck?.encounter?.playerPos, state.playerPosition);
      expect(random.doubleCalls, 1);
      expect(
          state.playerSpatialPosition, PlayerSpatialPosition(x: 2.75, z: 2.25));
      expect(state.bag, fixture.state().bag);
    });
  }

  test(
      '3D requires coherent continuous position and refuses a cliff before RNG',
      () {
    final project = fixture.project(),
        item = fixture.rod(ProjectFishingRodKind.oldRod);
    for (final entry in [
      (
        map: spatialMap(),
        state: spatialState().copyWith(playerSpatialPosition: null)
      ),
      (
        map: spatialMap(),
        state: spatialState().copyWith(
            playerSpatialPosition: PlayerSpatialPosition(x: 1.9, z: 2.25))
      ),
      (map: spatialMap(cliff: true), state: spatialState()),
      (
        map: spatialMap(),
        state: spatialState().copyWith(playerFacing: EntityFacing.west)
      ),
    ]) {
      final random = fixture.CountingRandom(1);
      final result = resolveFishingAttempt(
        ticket: fixture.ticket(
            map: entry.map,
            current: entry.state,
            manifest: project,
            item: item),
        world: fixture.world(entry.map, entry.state),
        project: project,
        gameState: entry.state,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random,
      );
      expect(result.reason, isNotNull);
      expect(random.doubleCalls + random.intCalls, 0);
    }
  });

  test(
      '3D movement or a replaced activation invalidates a reserved fishing ticket',
      () {
    final map = spatialMap(), state = spatialState();
    final project = fixture.project(),
        item = fixture.rod(ProjectFishingRodKind.oldRod);
    final ticket =
        fixture.ticket(map: map, current: state, manifest: project, item: item);
    final moved = state.copyWith(
        playerSpatialPosition: PlayerSpatialPosition(x: 2.8, z: 2.25));
    final random = fixture.CountingRandom(1);
    final result = resolveFishingAttempt(
        ticket: ticket,
        world: fixture.world(map, moved),
        project: project,
        gameState: moved,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random);
    expect(result.reason, FishingBlockReason.staleAttempt);
    expect(random.doubleCalls + random.intCalls, 0);
  });
}
