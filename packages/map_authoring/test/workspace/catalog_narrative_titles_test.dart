import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';

void main() {
  test('an unprepared catalog answers preparation required for every kind',
      () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    for (final kind in CatalogNarrativeTitles.kinds) {
      final read = await fixture.read(kind);
      expect(read, isA<CatalogNarrativeTitlesPreparationRequired>());
      expect(
          (read as CatalogNarrativeTitlesPreparationRequired).reason, 'absent');
    }
  });

  test('explicit preparation lists every kind in stored order, idempotently',
      () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    await fixture.prepare(null);
    await fixture.prepare();
    final scenes = await fixture.read('scenes') as CatalogNarrativeTitlePage;
    expect(scenes.total, 2);
    expect(scenes.entries.first.id, 'arrival');
    expect(scenes.entries.first.tags, ['intro']);
    expect(scenes.entries.first.category, isNull);
    expect(await fixture.titles('dialogues'), ['Greeting']);
    expect(await fixture.titles('facts'), ['Fact 0', 'Fact 1', 'Fact 2']);
    final facts = await fixture.read('facts') as CatalogNarrativeTitlePage;
    expect(
        facts.entries.map((entry) => entry.category), ['quest', null, 'quest']);
    expect(facts.entries.first.tags, ['main']);
    final storylines =
        await fixture.read('storylines') as CatalogNarrativeTitlePage;
    expect(storylines.entries.single.title, 'Main quest');
    expect(storylines.entries.single.tags, isEmpty);
    expect(storylines.entries.single.category, 'main');
    expect(await fixture.titles('narrativeEvents'), ['Wake up', 'Leave home']);
    expect(await fixture.titles('worldRules'), isEmpty);
    expect(await fixture.titles('cinematics'), isEmpty);
    expect(await fixture.titles('presentationCinematics'), isEmpty);

    final head = await fixture.snapshot();
    await fixture.prepare();
    expect((await fixture.snapshot()).root, head.root);
    final units = await head.readAllUnits();
    expect(_owned(units), _rows(CatalogNarrativeTitles.index.initialize(units)),
        reason: 'prepared rows equal the derivation of the same generation');
  });

  test('with 900 unrelated documents a list and an edit stay bounded',
      () async {
    final fixture = await NarrativeTitleFixture.create(unrelated: 900);
    addTearDown(fixture.close);
    await fixture.prepare();
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
    final page = await CatalogNarrativeTitles.read(snapshot, 'facts', 0)
        as CatalogNarrativeTitlePage;
    expect(page.total, 3);
    expect(units, hasLength(2));
    expect(units.where((key) => key.contains('projectDefinition')), isEmpty);

    final lookups = <CatalogDefinitionKey>[];
    final definition = (await snapshot
        .lookup(CatalogMetadataDocumentsKeys.definition('facts', 1)))!;
    final value = Map<String, Object?>.from(definition.payload['value'] as Map);
    final renamed = CatalogDefinitionUnit(key: definition.key, payload: {
      ...definition.payload,
      'value': {
        ...value,
        'definition': narrativeTitleFact(1, label: 'Renamed').toJson()
      }
    });
    final patch = await CatalogNarrativeTitles.index.maintain(
        lookup: (key) {
          lookups.add(key);
          return snapshot.lookup(key);
        },
        upserts: [renamed],
        removals: const []);
    expect(patch.upserts.map((unit) => unit.key),
        [CatalogNarrativeTitleKeys.page('facts', 0)]);
    expect(lookups, hasLength(lessThanOrEqualTo(4)));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('incremental edits rewrite one page and equal a fresh preparation',
      () async {
    final fixture = await NarrativeTitleFixture.create(facts: 200);
    addTearDown(fixture.close);
    await fixture.prepare();
    final before = _owned(await (await fixture.snapshot()).readAllUnits());

    await fixture.apply('fact.update',
        {'fact': narrativeTitleFact(130, label: 'Renamed').toJson()}, 'rename');
    final renamed = _owned(await (await fixture.snapshot()).readAllUnits());
    expect(_changed(before, renamed),
        {CatalogNarrativeTitleKeys.page('facts', 1)});
    final page = await fixture.read('facts', 1) as CatalogNarrativeTitlePage;
    expect(page.entries[2].title, 'Renamed');

    await fixture.apply(
        'fact.create', {'fact': narrativeTitleFact(200).toJson()}, 'append');
    final appended = _owned(await (await fixture.snapshot()).readAllUnits());
    expect(_changed(renamed, appended), {
      CatalogNarrativeTitleKeys.page('facts', 1),
      CatalogNarrativeTitles.markerKey,
    });
    expect((await fixture.read('facts', 1) as CatalogNarrativeTitlePage).total,
        201);

    final units = await (await fixture.snapshot()).readAllUnits();
    expect(appended, _rows(CatalogNarrativeTitles.index.initialize(units)));
  });

  test('event appends and deletions keep the event list exact', () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    await fixture.prepare();
    await fixture.prepare('narrativeEventConsumers');
    final appended = await fixture.apply(
        'event_v2.record_upsert',
        {
          'record': NarrativeEventRecord.draft(NarrativeEventDraft(
                  id: narrativeTitleEvent(3),
                  name: 'Meet rival',
                  conditions: const [],
                  priority: 0,
                  order: 3))
              .toJson()
        },
        'append-event');
    expect(await fixture.titles('narrativeEvents'),
        ['Wake up', 'Leave home', 'Meet rival']);
    await fixture.apply(
        'event_v2.delete', {'eventId': narrativeTitleEvent(1)}, 'delete-event',
        confirm: true);
    expect(
        await fixture.titles('narrativeEvents'), ['Leave home', 'Meet rival']);
    final units = await (await fixture.snapshot()).readAllUnits();
    expect(
        _owned(units), _rows(CatalogNarrativeTitles.index.initialize(units)));
    expect(appended, isNotEmpty);
  });

  test('a tail removal stays exact and an inconsistent one becomes stale',
      () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    await fixture.prepare();
    final snapshot = await fixture.snapshot();
    final last = (await snapshot
        .lookup(CatalogMetadataDocumentsKeys.definition('facts', 2)))!;
    final shifted = CatalogDefinitionUnit(
        key: CatalogMetadataDocumentsKeys.definition('facts', 1),
        payload: {
          ...last.payload,
          'id': CatalogMetadataDocumentsKeys.definition('facts', 1).id,
          'position': 1
        });
    final exact = await CatalogNarrativeTitles.index.maintain(
        lookup: snapshot.lookup,
        upserts: [shifted],
        removals: [CatalogMetadataDocumentsKeys.definition('facts', 2)]);
    expect(exact.removals, isEmpty);
    final page = exact.upserts.singleWhere(
        (unit) => unit.key == CatalogNarrativeTitleKeys.page('facts', 0));
    expect(
        [for (final entry in page.payload['entries'] as List) entry['title']],
        ['Fact 0', 'Fact 2']);
    final marker = exact.upserts
        .singleWhere((unit) => unit.key == CatalogNarrativeTitles.markerKey);
    expect((marker.payload['kinds'] as Map)['facts'], {'count': 2});

    final inconsistent = await CatalogNarrativeTitles.index.maintain(
        lookup: snapshot.lookup,
        upserts: const [],
        removals: [CatalogMetadataDocumentsKeys.definition('facts', 0)]);
    final stale = inconsistent.upserts.single;
    expect((stale.payload['kinds'] as Map)['facts'],
        {'stale': true, 'pageCount': 1});
    final patch = await snapshot.patch(upserts: [stale]);
    final next = await patch.nextSnapshot(
        readObject: (reference) async =>
            patch.objects[reference.sha256] ??
            await (await CatalogStorageStore.open(
                    projectRoot: fixture.root.path))
                .readObject(reference));
    final read = await CatalogNarrativeTitles.read(next, 'facts', 0);
    expect(read, isA<CatalogNarrativeTitlesPreparationRequired>());
    expect((read as CatalogNarrativeTitlesPreparationRequired).reason, 'stale');
    expect(await CatalogNarrativeTitles.read(next, 'scenes', 0),
        isA<CatalogNarrativeTitlePage>());
  });
}

final class CatalogMetadataDocumentsKeys {
  static CatalogDefinitionKey definition(String field, int position) =>
      CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
          '["projectDefinition","$field",$position]');
}

final class CatalogNarrativeTitleKeys {
  static CatalogDefinitionKey page(String kind, int page) =>
      CatalogDefinitionKey(CatalogDefinitionKind.workspaceState,
          '["narrativeTitles","$kind",$page]');
}

Map<CatalogDefinitionKey, String> _owned(List<CatalogDefinitionUnit> units) =>
    _rows([
      for (final unit in units)
        if (CatalogNarrativeTitles.index.owns(unit.key)) unit
    ]);

Map<CatalogDefinitionKey, String> _rows(
        Iterable<CatalogDefinitionUnit> units) =>
    {for (final unit in units) unit.key: canonicalAuthoringJson(unit.toJson())};

Set<CatalogDefinitionKey> _changed(Map<CatalogDefinitionKey, String> before,
        Map<CatalogDefinitionKey, String> after) =>
    {
      for (final key in {...before.keys, ...after.keys})
        if (before[key] != after[key]) key
    };
