import 'dart:convert';

import 'package:map_authoring/map_authoring.dart' show CatalogStorageStore;
import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_usages.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/narrative_usage_fixture.dart';

Future<List<String>> _facts(CatalogSnapshot snapshot, String factId) async =>
    switch (await CatalogNarrativeUsages.readFactUsers(snapshot, factId)) {
      CatalogNarrativeUsageEntries(:final entries) => [
          for (final entry in entries)
            '${entry['kind']}:${entry['id']}:${entry['role']}'
        ]..sort(),
      CatalogNarrativeUsagesPreparationRequired(:final reason) => [
          'preparation:$reason'
        ],
    };

Future<List<String>> _owners(
        CatalogSnapshot snapshot, String mapId, String elementId) async =>
    switch (await CatalogNarrativeUsages.readMapElementOwners(
        snapshot, mapId, elementId)) {
      CatalogNarrativeUsageEntries(:final entries) => [
          for (final entry in entries)
            '${entry['kind']}:${entry['id']}:${entry['sourceKind']}'
        ]..sort(),
      CatalogNarrativeUsagesPreparationRequired(:final reason) => [
          'preparation:$reason'
        ],
    };

Map<CatalogDefinitionKey, String> _owned(
        Iterable<CatalogDefinitionUnit> units) =>
    {
      for (final unit in units)
        if (CatalogNarrativeUsages.indexes.any((index) => index.owns(unit.key)))
          unit.key: jsonEncode(unit.payload)
    };

Set<CatalogDefinitionKey> _changed(Map<CatalogDefinitionKey, String> before,
        Map<CatalogDefinitionKey, String> after) =>
    {
      for (final key in {...before.keys, ...after.keys})
        if (before[key] != after[key]) key
    };

void main() {
  test('explicit preparation answers Fact users and map element owners',
      () async {
    final fixture = await createNarrativeUsageFixture();
    addTearDown(fixture.close);
    final unprepared = await fixture.snapshot();
    expect(await _facts(unprepared, 'fact_fact_0'), ['preparation:absent']);
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final snapshot = await fixture.snapshot();
    final event1 = narrativeTitleEvent(1);
    final event2 = narrativeTitleEvent(2);
    expect(await _facts(snapshot, 'fact_fact_0'),
        ['scene:gate:read', 'storyline:main:read']);
    expect(await _facts(snapshot, 'fact_fact_1'),
        ['event:$event1:read', 'event:$event2:read', 'scene:gate:write']);
    expect(await _facts(snapshot, 'fact_fact_2'), isEmpty);
    expect(await _facts(snapshot, 'fact_fact_3'),
        ['storyline:main:write', 'worldRule:world_rule_tree:read']);
    expect(await _facts(snapshot, 'unknown'), isEmpty);
    expect(await _owners(snapshot, 'town', 'npc'),
        ['cinematic:arrival:entity', 'event:$event1:entity']);
    expect(await _owners(snapshot, 'town', 'tree'),
        ['worldRule:world_rule_tree:entity']);
    expect(await _owners(snapshot, 'town', 'sign'), ['event:$event2:entity']);

    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    expect((await fixture.snapshot()).root, snapshot.root);
    final units = await snapshot.readAllUnits();
    expect(_owned(units), _owned(CatalogDerivableIndexes.expected(units)));
  });

  test('owner edits rewrite only the buckets of the facets they change',
      () async {
    final fixture = await createNarrativeUsageFixture();
    addTearDown(fixture.close);
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final start = _owned(await (await fixture.snapshot()).readAllUnits());

    await fixture.apply(
        'scene.upsert',
        {'scene': narrativeUsageScene('gate', read: 'fact_fact_3').toJson()},
        'scene-read');
    final scene = await fixture.snapshot();
    final afterScene = _owned(await scene.readAllUnits());
    expect(_changed(start, afterScene), {
      for (final fact in ['fact_fact_0', 'fact_fact_3'])
        CatalogNarrativeUsages.factUsers
            .bucketKey(CatalogNarrativeUsages.factUsers.bucketOf(fact))
    });
    expect(await _facts(scene, 'fact_fact_0'), ['storyline:main:read']);
    expect(await _facts(scene, 'fact_fact_3'), [
      'scene:gate:read',
      'storyline:main:write',
      'worldRule:world_rule_tree:read'
    ]);

    await fixture.apply(
        'event_v2.record_upsert',
        {'record': narrativeUsageEvent(2, entity: 'well').toJson()},
        'event-move');
    final event = await fixture.snapshot();
    final afterEvent = _owned(await event.readAllUnits());
    final map = CatalogNarrativeUsages.mapElementOwners;
    expect(_changed(afterScene, afterEvent), {
      for (final element in ['sign', 'well'])
        map.bucketKey(map
            .bucketOf(CatalogNarrativeUsages.mapElementFacet('town', element)))
    });
    expect(await _owners(event, 'town', 'sign'), isEmpty);
    expect(await _owners(event, 'town', 'well'),
        ['event:${narrativeTitleEvent(2)}:entity']);

    await fixture.apply(
        'world_rule.update',
        {'rule': narrativeUsageRule(fact: 'fact_fact_2').toJson()},
        'rule-fact');
    final units = await (await fixture.snapshot()).readAllUnits();
    expect(_owned(units), _owned(CatalogDerivableIndexes.expected(units)));
  });

  test('with 900 unrelated documents a read and an owner edit stay bounded',
      () async {
    final fixture = await createNarrativeUsageFixture(unrelated: 900);
    addTearDown(fixture.close);
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final units = <String>[];
    final snapshot = (await store.openRoot((await store.readHead())!,
            readObject: (reference) async {
      final bytes = await store.readObject(reference);
      final value = jsonDecode(utf8.decode(bytes));
      if (value is Map && value['type'] == 'unit') {
        units.add(jsonEncode(value['key']));
      }
      return bytes;
    }))
        .snapshot;
    expect(await _facts(snapshot, 'fact_fact_0'),
        ['scene:gate:read', 'storyline:main:read']);
    expect(units, hasLength(2));
    expect(units.where((key) => key.contains('projectDefinition')), isEmpty);

    final scene = (await snapshot.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata,
        '["projectDefinition","scenes",0]')))!;
    final value = Map<String, Object?>.from(scene.payload['value'] as Map);
    final moved = CatalogDefinitionUnit(key: scene.key, payload: {
      ...scene.payload,
      'value': {
        ...value,
        'definition': narrativeUsageScene('gate', read: 'fact_fact_3').toJson()
      }
    });
    final lookups = <CatalogDefinitionKey>[];
    final patch = await CatalogDerivableIndexes.maintain(
        lookup: (key) {
          lookups.add(key);
          return snapshot.lookup(key);
        },
        upserts: [moved],
        removals: const []);
    expect(patch.upserts, hasLength(2));
    expect(lookups.where((key) => key.id.contains('projectDefinition')).toSet(),
        {scene.key});
    expect(lookups, hasLength(lessThanOrEqualTo(7)));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('maintenance reads only the marker when the indexes are absent',
      () async {
    final fixture = await createNarrativeUsageFixture();
    addTearDown(fixture.close);
    final snapshot = await fixture.snapshot();
    final scene = (await snapshot.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata,
        '["projectDefinition","scenes",0]')))!;
    for (final index in CatalogNarrativeUsages.indexes) {
      final lookups = <CatalogDefinitionKey>[];
      final patch = await index.maintain(
          lookup: (key) {
            lookups.add(key);
            return snapshot.lookup(key);
          },
          upserts: [scene],
          removals: const []);
      expect(patch.upserts, isEmpty);
      expect(lookups, [index.marker]);
    }
  });
}
