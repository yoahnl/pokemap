import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

MapData _map() => catalogMap('center').copyWith(entities: [
      MapEntity(
          id: 'nurse',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 2, y: 1),
          npc: const MapEntityNpcData(displayName: 'Nurse')),
    ]);

void main() {
  test('counter action is discoverable with its closed cardinal side contract',
      () {
    final descriptor = EntityActions.descriptors.singleWhere(
        (action) => action.id == 'npc.set_counter_interaction_sides');
    expect(descriptor.extensions['counterInteraction'], {
      'relativeTo': 'npc',
      'directions': ['north', 'south', 'east', 'west'],
      'distanceCells': 2,
      'intermediateCell': 'blockingAndWithoutEntity',
      'npcFootprint': {'width': 1, 'height': 1},
      'mapMode': '2d',
      'parameters': ['mapId', 'entityId', 'sides'],
    });
  });

  test('counter action changes only the declared NPC sides', () {
    final map = _map();
    final snapshot = catalogSnapshot([map]);
    final draft = const EntityActions()
        .build(catalogContext(snapshot, 'npc.set_counter_interaction_sides', {
      'mapId': map.id,
      'entityId': 'nurse',
      'sides': ['south']
    }));
    final result = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>);
    expect(result.entities.single.npc!.counterInteractionSides,
        [EntityFacing.south]);
    expect(result.entities.single.npc!.displayName, 'Nurse');
    expect(result.entities.single.pos, map.entities.single.pos);
    expect(result.layers, map.layers);
  });

  for (final value in <Object?>[
    ['diagonal'],
    ['south', 'south'],
    ['south', 'north', 'east', 'west', 'south'],
    'south',
    [null],
    [2],
  ]) {
    test('counter action rejects malformed or duplicate sides $value', () {
      final map = _map();
      expect(
          () => const EntityActions().build(catalogContext(
              catalogSnapshot([map]),
              'npc.set_counter_interaction_sides',
              {'mapId': map.id, 'entityId': 'nurse', 'sides': value})),
          throwsA(isA<MapAuthoringException>().having(
              (error) => error.code,
              'code',
              anyOf(
                  'map.request_invalid', 'npc.counter_interaction_invalid'))));
    });
  }

  test('counter authoring refuses nonempty sides on spatial maps and wide NPCs',
      () {
    final map = _map();
    final spatial = map.copyWith(
        spatialScene: MapSpatialScene(
            width: map.size.width,
            depth: map.size.height,
            heightLevels: List.filled(map.size.width * map.size.height, 0)));
    final wide = map.copyWith(entities: [
      map.entities.single.copyWith(size: const GridSize(width: 2, height: 1))
    ]);
    for (final unsupported in [spatial, wide]) {
      expect(
          () => const EntityActions().setCounterInteractionSides(unsupported,
              entityId: 'nurse', sides: [EntityFacing.south]),
          throwsA(isA<MapAuthoringException>()));
    }
  });

  test('counter sides can be cleared through the typed canonical action', () {
    final map = _map();
    final set = const EntityActions().setCounterInteractionSides(map,
        entityId: 'nurse', sides: [EntityFacing.south]);
    final cleared = const EntityActions()
        .setCounterInteractionSides(set, entityId: 'nurse', sides: []);
    expect(cleared.entities.single.npc!.counterInteractionSides, isEmpty);
    expect(cleared.entities.single.pos, map.entities.single.pos);
  });

  test('typed counter sides do not alias the caller mutable list', () {
    final sides = [EntityFacing.south];
    final updated = const EntityActions()
        .setCounterInteractionSides(_map(), entityId: 'nurse', sides: sides);
    sides.add(EntityFacing.north);
    expect(updated.entities.single.npc!.counterInteractionSides,
        [EntityFacing.south]);
    expect(
        () => updated.entities.single.npc!.counterInteractionSides
            .add(EntityFacing.east),
        throwsUnsupportedError);
  });

  test('parity catalog points to the exact counter API and JSONL proof', () {
    final action = AuthoringFullParityCatalog.canonical()
        .mutationActions
        .singleWhere(
            (entry) => entry.actionId == 'npc.set_counter_interaction_sides');
    expect(action.contractTestPath,
        'test/domains/maps/npc_counter_interaction_actions_test.dart');
    expect(action.endToEndEvidence[AuthoringTransport.directApi],
        'test/domains/maps/npc_counter_interaction_transport_test.dart');
    expect(action.endToEndEvidence[AuthoringTransport.cli],
        'test/domains/maps/npc_counter_interaction_transport_test.dart');
  });
}
