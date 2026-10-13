import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _before = GridPos(x: 1, y: 1);
const _arrival = GridPos(x: 2, y: 1);

GameplayWorldState _world(
        {GridPos position = _arrival,
        List<MapWarp> warps = const [],
        List<MapGameplayZone> zones = const [],
        List<MapPlacedElement> placed = const [],
        ProjectManifest? project}) =>
    GameplayWorldState.initial(
        map: MapData(
            id: 'arrival',
            name: 'Arrival',
            size: const GridSize(width: 5, height: 4),
            warps: warps,
            gameplayZones: zones,
            layers: const [
              MapLayer.tile(id: 'objects', name: 'Objects', cells: [])
            ],
            placedElements: placed),
        playerPos: position,
        project: project,
        tileWidth: 32,
        tileHeight: 32);

GameplayStepResult _arrive(GameplayWorldState world,
        {GridPos previous = _before}) =>
    resolveGameplayArrival(world,
        previousPos: previous, direction: Direction.east);

void main() {
  test(
      'arrival resolves current warp without moving or bumping a neighboring warp',
      () {
    final world = _world(warps: [
      const MapWarp(
          id: 'landing',
          pos: _arrival,
          targetMapId: 'next',
          targetPos: GridPos(x: 1, y: 2)),
      const MapWarp(
          id: 'neighbor',
          pos: GridPos(x: 3, y: 1),
          targetMapId: 'wrong',
          targetPos: GridPos(x: 0, y: 0))
    ]);
    final result = _arrive(world);
    expect(result, isA<WarpTriggered>());
    expect((result as WarpTriggered).warp.warpId, 'landing');
    expect(result.world, same(world));
    expect(result.world.player.playerPositionPx,
        same(world.player.playerPositionPx));
  });

  test('arrival selects landing hazard without dispatching intermediate hazard',
      () {
    final world = _world(zones: [
      for (final (p, damage) in [(_before, 99), (_arrival, 3)])
        MapGameplayZone(
            id: 'hazard-${p.x}',
            name: 'Hazard',
            kind: GameplayZoneKind.hazard,
            area: MapRect(pos: p, size: const GridSize(width: 1, height: 1)),
            hazard: HazardZonePayload(
                hazardKind: HazardKind.poison, damagePerStep: damage))
    ]);
    final result = _arrive(world);
    expect(result, isA<Moved>());
    expect((result as Moved).hazardEffect!.position, _arrival);
    expect(result.hazardEffect!.damagePerStep, 3);
    expect(result.world, same(world));
  });

  test('arrival reuses once per enter behavior scope and activation identity',
      () {
    final project = ProjectManifest(
        name: 'Arrival',
        maps: const [],
        tilesets: const [],
        elements: const [
          ProjectElementEntry(
              id: 'message',
              name: 'Message',
              tilesetId: 'sprite',
              categoryId: 'test',
              frames: [
                TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
              ])
        ]);
    final world = _world(project: project, placed: [
      const MapPlacedElement(
          id: 'landing-object',
          layerId: 'objects',
          elementId: 'message',
          pos: _arrival,
          behaviors: [
            MapPlacedElementBehavior(
                id: 'enter',
                enabled: true,
                trigger: MapPlacedElementTriggerType.onEnter,
                triggerScope: MapPlacedElementTriggerScope.oncePerEnter,
                effect: MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.showMessage,
                    message: 'Arrived'))
          ])
    ]);
    final result = _arrive(world);
    expect(result, isA<PlacedElementInteracted>());
    expect((result as PlacedElementInteracted).element.id, 'landing-object');
    expect(result.behavior.id, 'enter');
    expect(_arrive(world, previous: _arrival), isA<Moved>());
  });

  test('ordinary walking and explicit arrival resolve the same landing outcome',
      () {
    const warp = MapWarp(
        id: 'landing',
        pos: _arrival,
        targetMapId: 'next',
        targetPos: GridPos(x: 0, y: 0));
    final walked = stepGameplayWorld(_world(position: _before, warps: [warp]),
        const MoveIntent(Direction.east, pixelsPerStep: 32)) as WarpTriggered;
    final arrived = _arrive(_world(warps: [warp])) as WarpTriggered;
    expect(walked.warp.warpId, arrived.warp.warpId);
    expect(walked.warp.targetMapId, arrived.warp.targetMapId);
    expect(walked.world.player.pos, arrived.world.player.pos);
  });
}
