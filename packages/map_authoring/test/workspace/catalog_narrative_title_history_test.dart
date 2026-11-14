import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';

void main() {
  Future<({NarrativeTitleFixture fixture, String renamed, String appended})>
      edit() async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    await fixture.prepare();
    final renamed = await fixture.apply('fact.update',
        {'fact': narrativeTitleFact(1, label: 'Renamed').toJson()}, 'rename');
    final appended = await fixture.apply(
        'fact.create', {'fact': narrativeTitleFact(3).toJson()}, 'append');
    return (fixture: fixture, renamed: renamed, appended: appended);
  }

  test('titles follow edits, undo, redo, reopening and history maintenance',
      () async {
    final (:fixture, :renamed, :appended) = await edit();
    expect(await fixture.titles('facts'),
        ['Fact 0', 'Renamed', 'Fact 2', 'Fact 3']);
    await fixture.undo(appended, 'undo-1');
    await fixture.undo(renamed, 'undo-2');
    expect(await fixture.titles('facts'), ['Fact 0', 'Fact 1', 'Fact 2']);
    await fixture.redo(renamed, 'redo-1');
    await fixture.reattach();
    expect(await fixture.titles('facts'), ['Fact 0', 'Renamed', 'Fact 2']);
    await fixture.prepare(null);
    await fixture.prepare('metadataContext');
    final head = 'sha256:${(await fixture.snapshot()).root.sha256}';
    final preview = await fixture.api.maintainHistory(
        fixture.opened.projectHandle,
        expectedRevision: head,
        maxOperations: 1);
    final applied = await fixture.api.maintainHistory(
        fixture.opened.projectHandle,
        expectedRevision: head,
        maxOperations: 1,
        apply: true,
        expectedFingerprint: preview['fingerprint'] as String);
    expect(applied['historicalGenerationsRequiringPreparation'], isEmpty);
    expect(applied['preparedHistoricalGenerations'],
        applied['validatedHistoricalGenerations']);
  });

  test('a copied project undoes and redoes upsert-only title edits', () async {
    final (:fixture, :renamed, :appended) = await edit();
    await fixture.undo(appended, 'undo-append');
    final copy = await fixture.copy();
    addTearDown(copy.close);
    await copy.prepare(null);
    await copy.undo(renamed, 'copy-undo');
    expect(await copy.titles('facts'), ['Fact 0', 'Fact 1', 'Fact 2']);
    await copy.redo(renamed, 'copy-redo');
    expect(await copy.titles('facts'), ['Fact 0', 'Renamed', 'Fact 2']);
    await copy.apply('fact.update',
        {'fact': narrativeTitleFact(2, label: 'Moved').toJson()}, 'copy-edit');
    expect(await copy.titles('facts'), ['Fact 0', 'Renamed', 'Moved']);
  });

  test('a copied project redoes the preparation through a full derivation',
      () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    await fixture.prepare();
    final history = await fixture.api
        .listMutationHistory(fixture.opened.projectHandle, limit: 1);
    final preparation = history.entries.first.entryId;
    await fixture.undo(preparation, 'undo-preparation');
    expect(await fixture.titles('facts'), ['preparation:absent']);
    final copy = await fixture.copy();
    addTearDown(copy.close);
    await copy.prepare(null);
    await copy.redo(preparation, 'copy-redo-preparation');
    expect(await copy.titles('facts'), ['Fact 0', 'Fact 1', 'Fact 2']);
  });

  test('tampered, stale or orphan title rows are refused at admission',
      () async {
    final fixture = await NarrativeTitleFixture.create();
    addTearDown(fixture.close);
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final unprepared = await fixture.snapshot();
    await fixture.prepare();
    final prepared = await fixture.snapshot();
    final units = await prepared.readAllUnits();
    expect(_owned(CatalogDerivableIndexes.expected(units)), _owned(units));
    expect(CatalogDerivableIndexes.expected(await unprepared.readAllUnits()),
        isEmpty);
    final marker = CatalogNarrativeTitles.markerKey;
    final page = CatalogNarrativeTitles.index
        .rowKeys(units.singleWhere((unit) => unit.key == marker))
        .firstWhere((key) => key.id == '["narrativeTitles","facts",0]');
    List<CatalogDefinitionUnit> replace(CatalogDefinitionKey key,
            Map<String, Object?> Function(Map<String, Object?>) change) =>
        [
          for (final unit in units)
            unit.key == key
                ? CatalogDefinitionUnit(key: key, payload: change(unit.payload))
                : unit
        ];
    final tampered = replace(
        page,
        (payload) => {
              ...payload,
              'entries': <Object?>[
                {'id': 'fact_fact_0', 'title': 'Forged', 'tags': <String>[]},
                ...(payload['entries'] as List).skip(1),
              ]
            });
    final stale = replace(
        marker,
        (payload) => {
              ...payload,
              'kinds': {
                ...Map<String, Object?>.from(payload['kinds'] as Map),
                'facts': {'stale': true, 'pageCount': 1}
              }
            });
    final orphan = [
      for (final unit in units)
        if (unit.key != marker) unit
    ];

    expect(
        await convert(store, await publish(store, legacy(units))), isNotNull);
    expect(
        await convert(store,
            await publish(store, legacy(await unprepared.readAllUnits()))),
        isNotNull);
    for (final refused in [tampered, stale, orphan]) {
      expect(
          await convert(store, await publish(store, legacy(refused))), isNull);
    }

    Future<List<CatalogDefinitionUnit>?> admit(
            CatalogSnapshot before, CatalogSnapshot next) async =>
        CatalogDerivableIndexes.admitDelta(
            before: before,
            next: next,
            upserts: (await next.deltaFrom(before)).upserts);
    expect(await admit(unprepared, prepared), isNotNull);
    for (final refused in [tampered, stale]) {
      expect(await admit(prepared, await publish(store, refused)), isNull);
    }
    expect(await admit(unprepared, await publish(store, orphan)), isNull);
  });
}

List<CatalogDefinitionUnit> legacy(List<CatalogDefinitionUnit> units) => [
      for (final unit in units)
        if (!unit.key.id.startsWith('["factRuntimeIdentity",'))
          unit.key.id == '["metadataField","facts"]'
              ? CatalogDefinitionUnit(
                  key: unit.key,
                  payload: {...unit.payload}
                    ..remove('factRuntimeIdentitiesVersion'))
              : unit
    ];

Map<CatalogDefinitionKey, Map<String, Object?>> _owned(
        Iterable<CatalogDefinitionUnit> units) =>
    {
      for (final unit in units)
        if (CatalogNarrativeTitles.index.owns(unit.key)) unit.key: unit.payload
    };

Future<CatalogSnapshot> publish(
    CatalogStorageStore store, List<CatalogDefinitionUnit> units) async {
  final storage = CatalogStorageBuilder(limits: store.limits).build(units);
  await store.gateway.withExclusiveWriteLock(
      () => store.publishObjectsUnderLock(storage.objects));
  final snapshot = (await store.openRoot(storage.root)).snapshot;
  await snapshot.validate();
  return snapshot;
}

Future<CatalogPreparedHistoryConversion?> convert(
        CatalogStorageStore store, CatalogSnapshot snapshot) async =>
    CatalogHistoryCompatibility.prepare(
        store: store,
        source: snapshot,
        metadataUnits: [
          for (final unit in await snapshot.readAllUnits())
            if (unit.key.kind == CatalogDefinitionKind.catalogMetadata ||
                unit.key.kind == CatalogDefinitionKind.workspaceState)
              unit
        ]);
