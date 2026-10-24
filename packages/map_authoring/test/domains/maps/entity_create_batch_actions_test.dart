import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

MapEntity _entity(String id, {int x = 1, int y = 1}) => MapEntity(
      id: id,
      name: 'Object $id',
      kind: MapEntityKind.custom,
      pos: GridPos(x: x, y: y),
      properties: const {'origin': 'authored'},
    );

Map<String, Object?> _json(MapEntity entity) =>
    (jsonDecode(jsonEncode(entity.toJson())) as Map).cast<String, Object?>();

AuthoringMutationDraft _build(MapData map, Object? entities,
        {Map<String, Object?> extra = const {}, ProjectManifest? project}) =>
    const EntityActions().build(catalogContext(
        catalogSnapshot([map], project: project), 'entity.create_batch', {
      'mapId': map.id,
      'entities': entities,
      ...extra,
    }));

MapData _result(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);

Matcher _failure(String code) => throwsA(
    isA<MapAuthoringException>().having((error) => error.code, 'code', code));

void main() {
  test('batch exposes its bounded atomic create-only domain contract', () {
    final descriptor = EntityActions.descriptors
        .singleWhere((action) => action.id == 'entity.create_batch');
    expect(descriptor.extensions['batch'], {
      'minEntities': 1,
      'maxEntities': 128,
      'uniqueBy': ['id'],
      'semantics': 'createOnly',
      'atomic': true,
      'singleMap': true,
    });
  });

  test('batch produces one reversible map change and preserves prior content',
      () {
    final map = catalogMap('route').copyWith(entities: [_entity('old')]);
    final entities = [_entity('first', x: 2), _entity('last', x: 3)];
    final draft = _build(map, entities.map(_json).toList());
    final after = _result(draft);
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.changeSet.changes.single.storageKey, 'maps/route.json');
    expect(draft.changeSet.changes.single.beforeBytes,
        utf8.encode(jsonEncode(map.toJson())));
    expect(draft.preview['changedItemCount'], 2);
    expect(after, map.copyWith(entities: [...map.entities, ...entities]));
    expect(map.entities.map((entity) => entity.id), ['old']);
  });

  for (final length in [1, 128]) {
    test('batch accepts the $length entity boundary', () {
      final map = catalogMap('route', width: 128, height: 2);
      final entries = [
        for (var index = 0; index < length; index++)
          _json(_entity('entity-$index', x: index, y: 0))
      ];
      expect(_result(_build(map, entries)).entities, hasLength(length));
    });
  }

  for (final length in [0, 129]) {
    test('batch refuses $length entities without touching its preimage', () {
      final map = catalogMap('route', width: 129, height: 2);
      final before = jsonEncode(map.toJson());
      expect(
          () => _build(map, [
                for (var index = 0; index < length; index++)
                  _json(_entity('entity-$index', x: index, y: 0))
              ]),
          _failure('entity.batch_invalid'));
      expect(jsonEncode(map.toJson()), before);
    });
  }

  test('batch refuses duplicate identities after canonical trimming atomically',
      () {
    final map = catalogMap('route');
    expect(
        () => _build(map, [_json(_entity('same')), _json(_entity(' same '))]),
        _failure('entity.batch_duplicate_id'));
    expect(map.entities, isEmpty);
  });

  test('batch refuses an existing identity without replacing it', () {
    final map = catalogMap('route').copyWith(entities: [_entity('old')]);
    expect(
        () => _build(map, [_json(_entity('new')), _json(_entity('old', x: 2))]),
        _failure('entity.mutation_invalid'));
    expect(map.entities, [_entity('old')]);
  });

  test('invalid last footprint refuses every addition', () {
    final map = catalogMap('route');
    expect(
        () => _build(map, [
              _json(_entity('valid')),
              _json(_entity('invalid', x: 5)
                  .copyWith(size: const GridSize(width: 2, height: 1)))
            ]),
        _failure('entity.mutation_invalid'));
    expect(map.entities, isEmpty);
  });

  test('batch keeps single-create normalization and occupancy semantics', () {
    final map = catalogMap('route');
    final entities = [
      _entity(' first ')
          .copyWith(name: ' First ', properties: {' key ': ' value '}),
      _entity('second'),
    ];
    var singles = map;
    for (final entity in entities) {
      singles = const EntityActions().create(singles, entity);
    }
    final batch = _result(_build(map, entities.map(_json).toList()));
    expect(batch, singles);
    expect(batch.entities.first.id, 'first');
    expect(batch.entities.first.properties, {'key': 'value'});
  });

  test('mismatched typed payload refuses all batch entries', () {
    final map = catalogMap('route');
    expect(
        () => _build(map, [
              _json(_entity('valid')),
              _json(_entity('invalid').copyWith(
                  item: const MapEntityItemData(gameItemId: 'potion')))
            ]),
        _failure('entity.payload_kind_mismatch'));
    expect(map.entities, isEmpty);
  });

  test('batch preserves typed NPC schedules readiness and movement', () {
    final map = catalogMap('route');
    final npc = _entity('guard').copyWith(
        kind: MapEntityKind.npc,
        npc: const MapEntityNpcData(
            displayName: 'Guard',
            trainerId: 'guard-trainer',
            facing: EntityFacing.west,
            trainerBattleWhen: MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.localTimeWindow,
                timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240)),
            trainerBattleReadyWhen: MapEntityRuntimePredicate(
                kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
                minimumCount: 2),
            trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'refusal'),
            movement: MapEntityNpcMovementConfig(
                mode: MapEntityNpcMovementMode.fixedRoute,
                routeSteps: [
                  MapEntityNpcFaceStep(direction: EntityFacing.east)
                ],
                pauseDurationsMs: [533, 1067],
                movementArea: MapRect(
                    pos: GridPos(x: 0, y: 0),
                    size: GridSize(width: 3, height: 3)))));
    final project = catalogSnapshot([map]).manifest.copyWith(trainers: const [
      ProjectTrainerEntry(
          id: 'guard-trainer', name: 'Guard', trainerClass: 'Police')
    ], dialogues: const [
      ProjectDialogueEntry(
          id: 'refusal',
          name: 'Refusal',
          relativePath: 'dialogues/refusal.yarn')
    ]);
    final after = _result(_build(map, [_json(npc)], project: project));
    expect(after.entities.single, npc);
    expect(const EntityActions().createBatch(map, entities: [npc]), after);
  });

  test(
      'member failure identifies its index while preserving single-create code',
      () {
    final map = catalogMap('route');
    expect(
        () => const EntityActions().createBatch(map,
            entities: [_entity('valid'), _entity('invalid', x: -1)]),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'entity.mutation_invalid')
            .having((error) => error.details['index'], 'index', 1)
            .having(
                (error) => error.details['entityId'], 'entityId', 'invalid')));
    expect(map.entities, isEmpty);
  });

  for (final entities in [
    null,
    true,
    {},
    ['invalid']
  ]) {
    test('batch refuses malformed entities $entities', () {
      expect(() => _build(catalogMap('route'), entities),
          _failure('map.request_invalid'));
    });
  }

  test('batch refuses extra parameters', () {
    expect(
        () => _build(catalogMap('route'), [_json(_entity('new'))],
            extra: {'unexpected': true}),
        _failure('map.request_invalid'));
  });

  test('batch validates the final project references before exposing a draft',
      () {
    final map = catalogMap('route');
    expect(
        () => _build(map, [
              _json(_entity('valid')),
              _json(_entity('npc').copyWith(
                  kind: MapEntityKind.npc,
                  npc: const MapEntityNpcData(
                      dialogue: DialogueRef(dialogueId: 'missing'))))
            ]),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.details['validationState'],
            'validationState',
            'projected')));
    expect(map.entities, isEmpty);
  });
}
