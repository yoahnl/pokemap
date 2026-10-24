import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  test('canonical action stores fixed bounds and random pause choices', () {
    final next = _build(_map(), {..._parameters(),
      'pauseDurationsMs': [533, 1067, 1600, 2133],
      'movementArea': {'pos': {'x': 1, 'y': 0}, 'size': {'width': 3, 'height': 3}},
    });
    final movement = next.entities.single.npc!.movement;
    expect(movement.pauseDurationsMs, [533, 1067, 1600, 2133]);
    expect(movement.movementArea, const MapRect(pos: GridPos(x: 1, y: 0), size: GridSize(width: 3, height: 3)));
  });
  test('movement action describes closed native fixed-route semantics', () {
    final descriptor = EntityActions.descriptors
        .singleWhere((action) => action.id == 'npc.set_movement_mode');
    final movement = descriptor.extensions['npcMovement'] as Map;
    expect(movement['modes'], contains('fixedRoute'));
    expect(movement['fixedRoute'], {
      'mapMode': '2d_and_3d',
      'stepKinds': ['move', 'face', 'randomFacing', 'randomMove'],
      'directions': ['north', 'south', 'east', 'west'],
      'maximumSteps': 256,
      'skippable': false,
      'pathfinding': false,
      'initialPause': true,
      'pauseAfterCompletionOrObstruction': true,
      'suspensionScope': 'ownNpcCurrentMapInstanceBoolean',
    });
  });

  test(
      'typed API replaces movement without changing NPC identity or trainer data',
      () {
    final map = _map();
    final original = map.entities.single;
    final trainerMap = map.copyWith(entities: [
      original.copyWith(
          npc: original.npc!.copyWith(
              trainerId: 'native-trainer', characterId: 'native-character'))
    ]);
    final next = const EntityActions().setMovementConfiguration(trainerMap,
        entityId: 'actor', movement: _movement());
    expect(next.entities.single.npc!.movement, _movement());
    expect(next.entities.single.npc!.trainerId, 'native-trainer');
    expect(next.entities.single.npc!.characterId, 'native-character');
    expect(next.entities.single.pos, original.pos);
    expect(next.layers, map.layers);
    expect(trainerMap.entities.single.npc!.movement.mode,
        MapEntityNpcMovementMode.patrol);
  });

  test(
      'canonical movement action atomically sets steps and removes old patrol waypoints',
      () {
    final next = _build(_map(), _parameters());
    expect(next.entities.single.npc!.movement, _movement());
    expect(next.entities.single.npc!.displayName, 'Moving actor');
  });

  test('changing to idle removes fixed-route-only data atomically', () {
    final map = _map().copyWith(entities: [
      _map().entities.single.copyWith(
          npc: _map().entities.single.npc!.copyWith(movement: _movement()))
    ]);
    final next =
        _build(map, {'mapId': map.id, 'entityId': 'actor', 'mode': 'idle'});
    final movement = next.entities.single.npc!.movement;
    expect(movement.mode, MapEntityNpcMovementMode.idle);
    expect(movement.routeSteps, isEmpty);
    expect(movement.suspendWhenInstanceBoolean, isNull);
  });

  test('fixed-route preview keeps only direct authored translations', () {
    final map = _map().copyWith(entities: [
      _map().entities.single.copyWith(
          npc: _map().entities.single.npc!.copyWith(movement: _movement()))
    ]);
    final route = const EntityActions().previewNpcRoute(map, 'actor');
    expect(route,
        const [GridPos(x: 2, y: 1), GridPos(x: 3, y: 1), GridPos(x: 2, y: 1)]);
    expect(() => route.add(const GridPos(x: 1, y: 1)), throwsUnsupportedError);
  });

  test('typed fixed route supports 3D without changing source map data', () {
    final map = _map();
    final spatial = map.copyWith(
        spatialScene: MapSpatialScene(
            width: map.size.width,
            depth: map.size.height,
            heightLevels: List.filled(map.size.width * map.size.height, 0)));
    final next = const EntityActions().setMovementConfiguration(spatial,
            entityId: 'actor', movement: _movement());
    expect(next.entities.single.npc!.movement, _movement());
    expect(spatial.entities.single.npc!.movement.mode,
        MapEntityNpcMovementMode.patrol);
  });

  test('canonical fixed route refuses a 3D project even with a flat map', () {
    final map = _map();
    final base = catalogSnapshot([map]);
    final project = base.manifest.copyWith(
        settings: base.manifest.settings
            .copyWith(dimension: ProjectDimension.threeD));
    expect(
        () => const EntityActions().build(catalogContext(
            catalogSnapshot([map], project: project),
            'npc.set_movement_mode',
            _parameters())),
        throwsA(isA<MapAuthoringException>().having((error) => error.code,
            'code', 'map.semantic_projected_state_invalid')));
    expect(map.entities.single.npc!.movement.mode,
        MapEntityNpcMovementMode.patrol);
  });

  for (final invalid in [
    {'routeSteps': <Object>[]},
    {
      'routeSteps': List.filled(257, {'kind': 'randomFacing'})
    },
    {
      'routeSteps': [
        {'kind': 'script', 'source': 'anything'}
      ]
    },
    {
      'routeSteps': [
        {'kind': 'move', 'direction': 'east', 'through': true}
      ]
    },
    {
      'suspendWhenInstanceBoolean': {'key': 'flag', 'value': 'true'}
    },
    {
      'mode': 'idle',
      'routeSteps': [
        {'kind': 'randomFacing'}
      ]
    },
  ]) {
    test(
        'canonical action refuses malformed fixed route ${invalid.keys.join(',')}: $invalid',
        () {
      final map = _map();
      expect(() => _build(map, {..._parameters(), ...invalid}),
          throwsA(isA<MapAuthoringException>()));
      expect(map.entities.single.npc!.movement.mode,
          MapEntityNpcMovementMode.patrol);
    });
  }
}

MapData _map() => catalogMap('center').copyWith(entities: [
      const MapEntity(
          id: 'actor',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 1),
          npc: MapEntityNpcData(
              displayName: 'Moving actor',
              movement: MapEntityNpcMovementConfig(
                  mode: MapEntityNpcMovementMode.patrol,
                  waypoints: [GridPos(x: 2, y: 1), GridPos(x: 3, y: 1)]))),
    ]);

MapEntityNpcMovementConfig _movement() => MapEntityNpcMovementConfig.fromJson({
      'mode': 'fixedRoute',
      'routeSteps': [
        {'kind': 'move', 'direction': 'east'},
        {'kind': 'face', 'direction': 'west'},
        {'kind': 'randomFacing'},
        {'kind': 'move', 'direction': 'west'},
      ],
      'suspendWhenInstanceBoolean': {
        'key': 'npc.autonomousRouteStopped',
        'value': true
      },
      'loop': true,
      'pauseDurationMs': 1600,
      'stepDurationMs': 250,
    });

Map<String, Object?> _parameters() => {
      'mapId': 'center',
      'entityId': 'actor',
      'mode': 'fixedRoute',
      'routeSteps':
          _movement().routeSteps.map((step) => step.toJson()).toList(),
      'suspendWhenInstanceBoolean':
          _movement().suspendWhenInstanceBoolean!.toJson(),
      'loop': true,
      'pauseDurationMs': 1600,
      'stepDurationMs': 250,
    };

MapData _build(MapData map, Map<String, Object?> parameters) {
  final draft = const EntityActions().build(catalogContext(
      catalogSnapshot([map]), 'npc.set_movement_mode', parameters));
  return MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>);
}
