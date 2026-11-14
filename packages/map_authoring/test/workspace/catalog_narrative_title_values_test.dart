import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';

void main() {
  Future<NarrativeTitleFixture> typedFacts() async {
    final base = narrativeTitleProject();
    final fixture = await NarrativeTitleFixture.create(
        project: base.copyWith(facts: [
      ...base.facts,
      NarrativeFactDefinition(
          id: 'fact_badges',
          label: 'Badges',
          initialValue: NarrativeValue.integer(2)),
      NarrativeFactDefinition(
          id: 'fact_rival_name',
          label: 'Rival name',
          initialValue: const NarrativeValue.string('Silver')),
    ]));
    addTearDown(fixture.close);
    return fixture;
  }

  final pending = <String, List<int>>{};
  Future<CatalogSnapshot> withUnits(NarrativeTitleFixture fixture,
      CatalogSnapshot snapshot, List<CatalogDefinitionUnit> upserts,
      [List<CatalogDefinitionKey> removals = const []]) async {
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final patch = await snapshot.patch(upserts: upserts, removals: removals);
    pending.addAll(patch.objects);
    return patch.nextSnapshot(
        readObject: (reference) async =>
            pending[reference.sha256] ?? await store.readObject(reference));
  }

  List<CatalogDefinitionUnit> versionOne(List<CatalogDefinitionUnit> units) {
    final marker = units
        .singleWhere((unit) => unit.key == CatalogNarrativeTitles.markerKey);
    return CatalogNarrativeTitles.index.initialize([
      for (final unit in units)
        if (!CatalogNarrativeTitles.index.owns(unit.key)) unit,
      CatalogDefinitionUnit(
          key: marker.key, payload: {...marker.payload, 'schemaVersion': 1}),
    ]);
  }

  test('fact titles carry their value kind and initial value', () async {
    final fixture = await typedFacts();
    await fixture.prepare();
    final page = await fixture.read('facts') as CatalogNarrativeTitlePage;

    expect([
      for (final entry in page.entries)
        (entry.id, entry.valueKind, entry.initialValue)
    ], [
      ('fact_fact_0', 'bool', false),
      ('fact_fact_1', 'bool', false),
      ('fact_fact_2', 'bool', false),
      ('fact_badges', 'int', 2),
      ('fact_rival_name', 'string', 'Silver'),
    ]);
    final scenes = await fixture.read('scenes') as CatalogNarrativeTitlePage;
    expect(scenes.entries.map((entry) => entry.valueKind), [null, null]);
  });

  test('a version 1 index reads as stale and re-preparation rebuilds it',
      () async {
    final fixture = await typedFacts();
    await fixture.prepare();
    final head = await fixture.snapshot();
    final oldRows = versionOne(await head.readAllUnits());
    expect(oldRows.first.payload['schemaVersion'], 1);
    expect(
        oldRows
            .where((row) => row.payload['kind'] == 'facts')
            .expand((row) => row.payload['entries'] as List)
            .any((entry) => (entry as Map).containsKey('valueKind')),
        isFalse);
    final old = await withUnits(fixture, head, oldRows);

    final stale = await CatalogNarrativeTitles.read(old, 'facts', 0);
    expect(
        (stale as CatalogNarrativeTitlesPreparationRequired).reason, 'stale');
    final units = await old.readAllUnits();
    expect(_owned(CatalogDerivableIndexes.expected(units)), _owned(units),
        reason: 'history recomputes a version 1 generation exactly');

    final rebuilt = await CatalogNarrativeTitles.prepare(old);
    expect(rebuilt.upserts.map((row) => row.payload['schemaVersion']).toSet(),
        {2});
    final upgraded =
        await withUnits(fixture, old, rebuilt.upserts, rebuilt.removals);
    final page = await CatalogNarrativeTitles.read(upgraded, 'facts', 0)
        as CatalogNarrativeTitlePage;
    expect(page.entries.last.initialValue, 'Silver');
    final upgradedUnits = await upgraded.readAllUnits();
    expect(_owned(CatalogDerivableIndexes.expected(upgradedUnits)),
        _owned(upgradedUnits));
    expect(
        await CatalogNarrativeTitles.prepare(upgraded),
        isA<CatalogDerivedPatch>()
            .having((patch) => patch.upserts, 'upserts', isEmpty));
  });

  test('an edit keeps a version 1 index exact in its own version', () async {
    final fixture = await typedFacts();
    await fixture.prepare();
    final head = await fixture.snapshot();
    final old =
        await withUnits(fixture, head, versionOne(await head.readAllUnits()));
    final definition = (await old.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.catalogMetadata,
        '["projectDefinition","facts",3]')))!;
    final value = Map<String, Object?>.from(definition.payload['value'] as Map);
    final renamed = CatalogDefinitionUnit(key: definition.key, payload: {
      ...definition.payload,
      'value': {
        ...value,
        'definition': NarrativeFactDefinition(
                id: 'fact_badges',
                label: 'Badge count',
                initialValue: NarrativeValue.integer(2))
            .toJson()
      }
    });
    final patch = await CatalogNarrativeTitles.index
        .maintain(lookup: old.lookup, upserts: [renamed], removals: const []);
    expect(patch.upserts.single.payload['schemaVersion'], 1);
    final edited = await withUnits(fixture, old, [renamed, ...patch.upserts]);
    final units = await edited.readAllUnits();
    expect(_owned(CatalogDerivableIndexes.expected(units)), _owned(units));
  });
}

Map<String, String> _owned(Iterable<CatalogDefinitionUnit> units) => {
      for (final unit in units)
        if (CatalogNarrativeTitles.index.owns(unit.key))
          unit.key.id: canonicalAuthoringJson(unit.payload)
    };
