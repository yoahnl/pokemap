import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/catalog_storage/catalog_history_compatibility.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/narrative_usage_fixture.dart';

Future<List<String>> _users(
        NarrativeTitleFixture fixture, String factId) async =>
    switch (await CatalogNarrativeUsages.readFactUsers(
        await fixture.snapshot(), factId)) {
      CatalogNarrativeUsageEntries(:final entries) => [
          for (final entry in entries) '${entry['kind']}:${entry['role']}'
        ]..sort(),
      CatalogNarrativeUsagesPreparationRequired(:final reason) => [reason],
    };

void main() {
  Future<({NarrativeTitleFixture fixture, String moved})> edit() async {
    final fixture = await NarrativeTitleFixture.create(
        project: narrativeUsageProject().copyWith(tilesets: const []));
    addTearDown(fixture.close);
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final moved = await fixture.apply(
        'scene.upsert',
        {'scene': narrativeUsageScene('gate', read: 'fact_fact_3').toJson()},
        'move-read');
    return (fixture: fixture, moved: moved);
  }

  test('usages follow edits, undo, redo, reopening and history maintenance',
      () async {
    final (:fixture, :moved) = await edit();
    expect(await _users(fixture, 'fact_fact_0'), ['storyline:read']);
    await fixture.undo(moved, 'undo');
    expect(
        await _users(fixture, 'fact_fact_0'), ['scene:read', 'storyline:read']);
    await fixture.redo(moved, 'redo');
    await fixture.reattach();
    expect(await _users(fixture, 'fact_fact_0'), ['storyline:read']);
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

  test('a copied project undoes and redoes an edit that moves a Fact user',
      () async {
    final (:fixture, :moved) = await edit();
    final copy = await fixture.copy();
    addTearDown(copy.close);
    await copy.prepare(null);
    await copy.undo(moved, 'copy-undo');
    expect(await _users(copy, 'fact_fact_0'), ['scene:read', 'storyline:read']);
    await copy.redo(moved, 'copy-redo');
    expect(await _users(copy, 'fact_fact_0'), ['storyline:read']);
  });

  test('tampered, stale or orphan usage rows are refused at admission',
      () async {
    final fixture = await NarrativeTitleFixture.create(
        project: narrativeUsageProject().copyWith(tilesets: const []));
    addTearDown(fixture.close);
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final unprepared = await fixture.snapshot();
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final prepared = await fixture.snapshot();
    final units = await prepared.readAllUnits();
    final index = CatalogNarrativeUsages.factUsers;
    final bucket = index.bucketKey(index.bucketOf('fact_fact_0'));
    List<CatalogDefinitionUnit> replace(CatalogDefinitionKey key,
            Map<String, Object?> Function(Map<String, Object?>) change) =>
        [
          for (final unit in units)
            unit.key == key
                ? CatalogDefinitionUnit(key: key, payload: change(unit.payload))
                : unit
        ];
    final tampered = replace(
        bucket,
        (payload) => {
              ...payload,
              'entries': {
                ...Map<String, Object?>.from(payload['entries'] as Map),
                'fact_fact_0': <Object?>[
                  {'kind': 'scene', 'id': 'forged', 'role': 'write'}
                ],
              }
            });
    final stale =
        replace(index.marker, (payload) => {...payload, 'stale': true});
    final orphan = [
      for (final unit in units)
        if (unit.key != index.marker) unit
    ];

    expect(await _convert(store, await _publish(store, _legacy(units))),
        isNotNull);
    for (final refused in [tampered, stale, orphan]) {
      expect(await _convert(store, await _publish(store, _legacy(refused))),
          isNull);
    }
    Future<List<CatalogDefinitionUnit>?> admit(
            CatalogSnapshot before, CatalogSnapshot next) async =>
        CatalogDerivableIndexes.admitDelta(
            before: before,
            next: next,
            upserts: (await next.deltaFrom(before)).upserts);
    await unprepared.validate();
    await prepared.validate();
    expect(await admit(unprepared, prepared), isNotNull);
    for (final refused in [tampered, stale]) {
      expect(await admit(prepared, await _publish(store, refused)), isNull);
    }
    expect(await admit(unprepared, await _publish(store, orphan)), isNull);
  });
}

List<CatalogDefinitionUnit> _legacy(List<CatalogDefinitionUnit> units) => [
      for (final unit in units)
        if (!unit.key.id.startsWith('["factRuntimeIdentity",'))
          unit.key.id == '["metadataField","facts"]'
              ? CatalogDefinitionUnit(
                  key: unit.key,
                  payload: {...unit.payload}
                    ..remove('factRuntimeIdentitiesVersion'))
              : unit
    ];

Future<CatalogSnapshot> _publish(
    CatalogStorageStore store, List<CatalogDefinitionUnit> units) async {
  final storage = CatalogStorageBuilder(limits: store.limits).build(units);
  await store.gateway.withExclusiveWriteLock(
      () => store.publishObjectsUnderLock(storage.objects));
  final snapshot = (await store.openRoot(storage.root)).snapshot;
  await snapshot.validate();
  return snapshot;
}

Future<CatalogPreparedHistoryConversion?> _convert(
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
