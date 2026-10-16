import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const bike = ProjectItemDefinition(
    id: 'custom_cycle',
    displayName: 'Vélo',
    pocketId: 'key-items',
    tags: {
      'key-item'
    },
    uses: [
      ProjectItemUseDefinition(
          contexts: {ProjectItemUseContext.overworld},
          target: ProjectItemTargetKind.world,
          consumption: ProjectItemConsumptionPolicy.never,
          effect: ProjectItemEffectDefinition.bicycle())
    ]);
const route =
    MapData(id: 'route', name: 'Route', size: GridSize(width: 8, height: 8));
const state = GameState(
    saveId: 'save',
    currentMapId: 'route',
    bag: Bag(entries: [BagEntry(itemId: 'custom_cycle', quantity: 1)]));

void main() {
  BicycleBlockReason? attempt(
          {MapData map = route,
          GameState current = state,
          ProjectItemDefinition item = bike,
          bool clips = true}) =>
      evaluateBicycleToggle(
          map: map, state: current, item: item, hasAnimations: clips);

  test('arbitrary typed key item is reusable on land', () {
    expect(attempt(), isNull);
    expect(
        attempt(
            current: state.copyWith(playerMovementMode: MovementMode.bicycle)),
        isNull);
    expect(state.bag.entries.single.quantity, 1);
  });
  test('missing inventory, invalid capability and incomplete clips refuse', () {
    expect(attempt(current: state.copyWith(bag: const Bag())),
        BicycleBlockReason.insufficientQuantity);
    expect(
        attempt(item: bike.copyWith(tags: {})), BicycleBlockReason.invalidItem);
    expect(attempt(clips: false), BicycleBlockReason.missingAnimations);
  });
  test('indoor and explicit restrictions deny mounting and normalize arrival',
      () {
    for (final metadata in [
      const MapMetadata(isIndoor: true),
      const MapMetadata(allowBicycle: false)
    ]) {
      final map = route.copyWith(mapMetadata: metadata);
      expect(attempt(map: map), BicycleBlockReason.forbiddenMap);
      expect(bicycleArrivalMode(map, MovementMode.bicycle), MovementMode.walk);
      expect(
          attempt(
              map: map,
              current: state.copyWith(playerMovementMode: MovementMode.bicycle),
              clips: false),
          isNull);
    }
    expect(
        bicycleArrivalMode(route, MovementMode.bicycle), MovementMode.bicycle);
  });
  test('Surf and Dive forbid bicycle use and never hide a previous bicycle',
      () {
    for (final mode in [MovementMode.surf, MovementMode.dive]) {
      expect(attempt(current: state.copyWith(playerMovementMode: mode)),
          BicycleBlockReason.unavailableContext);
    }
    expect(
        resolveMovementModeAfterStep(
            currentMode: MovementMode.surf, isWaterCell: false),
        MovementMode.walk);
    expect(
        movementTerrainBlockReasonAt(
            map: route, x: 0, y: 0, mode: MovementMode.bicycle),
        isNull);
  });
  test('water, underwater, out of bounds and unsupported map refuse mounting',
      () {
    for (final mode in [MovementMode.surf, MovementMode.dive]) {
      final map = route.copyWith(gameplayZones: [
        MapGameplayZone(
            id: 'water',
            name: 'Water',
            kind: GameplayZoneKind.movement,
            area: const MapRect(
                pos: GridPos(x: 0, y: 0), size: GridSize(width: 2, height: 2)),
            movement: MovementZonePayload(requiredMode: mode))
      ]);
      expect(attempt(map: map), BicycleBlockReason.incompatibleTerrain);
      expect(
          movementTerrainBlockReasonAt(
              map: map, x: 0, y: 0, mode: MovementMode.bicycle),
          isNotNull);
    }
    expect(
        attempt(
            current:
                state.copyWith(playerPosition: const GridPos(x: -1, y: 0))),
        BicycleBlockReason.incompatibleTerrain);
    expect(attempt(map: route.copyWith(version: ProjectVersion.v9)),
        BicycleBlockReason.unsupportedMap);
  });
  test('terrestrial bicycle entry captures Rope anchor before auto dismount',
      () {
    final dungeon = route.copyWith(
        id: 'cave',
        mapMetadata:
            const MapMetadata(isIndoor: true, escapeRopeDungeonId: 'dungeon'));
    final source = state.copyWith(
        playerMovementMode: MovementMode.bicycle,
        playerPosition: const GridPos(x: 3, y: 4),
        playerFacing: EntityFacing.east);
    final anchor = escapeReturnPointAfterTransfer(
        sourceMap: route, targetMap: dungeon, sourceState: source);
    expect(anchor?.position, source.playerPosition);
    expect(anchor?.facing, EntityFacing.east);
    expect(bicycleArrivalMode(dungeon, source.playerMovementMode),
        MovementMode.walk);
  });
}
