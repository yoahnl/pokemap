import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_derivable_indexes.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_owner_analysis.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/narrative_title_fixture.dart';
import '../support/narrative_usage_fixture.dart';

void main() {
  test('only executed writers write a Fact; outcome effects only cite it', () {
    for (final (path, role) in [
      ('scenes[a].graph.nodes[2].payload.consequence.factId', 'write'),
      ('scenes[a].graph.nodes[2].payload.consequence.factIds[1]', 'write'),
      ('scenes[a].graph.nodes[3].payload.interactiveCommand.factId', 'write'),
      (
        'storylines[main].sceneLinks[0].outcomeLinks[0].effects[0].targetId',
        'cite'
      ),
      ('scenes[a].graph.nodes[1].payload.conditionSource.sourceId', 'read'),
      ('worldRules[r].source.sourceId', 'read'),
    ]) {
      expect(CatalogNarrativeOwnerAnalysis.role(path), role, reason: path);
    }
  });

  final pending = <String, List<int>>{};
  Future<CatalogSnapshot> withUnits(NarrativeTitleFixture fixture,
      CatalogSnapshot snapshot, List<CatalogDefinitionUnit> upserts) async {
    final store =
        await CatalogStorageStore.open(projectRoot: fixture.root.path);
    final patch = await snapshot.patch(upserts: upserts);
    pending.addAll(patch.objects);
    return patch.nextSnapshot(
        readObject: (reference) async =>
            pending[reference.sha256] ?? await store.readObject(reference));
  }

  Map<String, String> owned(Iterable<CatalogDefinitionUnit> units) => {
        for (final unit in units)
          if (CatalogNarrativeUsages.factUsers.owns(unit.key))
            unit.key.id: canonicalAuthoringJson(unit.payload)
      };

  Future<List<String>> users(CatalogSnapshot snapshot) async => switch (
          await CatalogNarrativeUsages.readFactUsers(snapshot, 'fact_fact_3')) {
        CatalogNarrativeUsageEntries(:final entries) => [
            for (final entry in entries)
              '${entry['kind']}:${entry['id']}:${entry['role']}'
          ]..sort(),
        CatalogNarrativeUsagesPreparationRequired(:final reason) => [
            'preparation:$reason'
          ],
      };

  test('a version 1 Fact user index stays exact, reads stale and is rebuilt',
      () async {
    final fixture = await createNarrativeUsageFixture();
    addTearDown(fixture.close);
    await fixture.prepare(CatalogNarrativeUsages.preparationScope);
    final head = await fixture.snapshot();
    expect(await users(head),
        ['storyline:main:cite', 'worldRule:world_rule_tree:read']);
    final units = await head.readAllUnits();
    final marker = units.singleWhere(
        (unit) => unit.key == CatalogNarrativeUsages.factUsers.marker);
    final versionOne = CatalogNarrativeUsages.factUsers.initialize([
      for (final unit in units)
        if (!CatalogNarrativeUsages.factUsers.owns(unit.key)) unit,
      CatalogDefinitionUnit(
          key: marker.key, payload: {...marker.payload, 'schemaVersion': 1}),
    ]);
    expect(
        versionOne
            .where((row) => row.payload['entries'] is Map)
            .expand((row) => (row.payload['entries'] as Map).values)
            .expand((entries) => entries as List)
            .where((entry) => (entry as Map)['kind'] == 'storyline')
            .map((entry) => (entry as Map)['role'])
            .toSet(),
        {'read', 'write'});
    final old = await withUnits(fixture, head, versionOne);
    expect(await users(old), ['preparation:stale']);
    final oldUnits = await old.readAllUnits();
    expect(owned(CatalogDerivableIndexes.expected(oldUnits)), owned(oldUnits),
        reason: 'history recomputes a version 1 generation exactly');

    final rebuilt = await CatalogNarrativeUsages.prepare(old);
    final upgraded = await withUnits(fixture, old, rebuilt.upserts);
    expect(await users(upgraded),
        ['storyline:main:cite', 'worldRule:world_rule_tree:read']);
    final upgradedUnits = await upgraded.readAllUnits();
    expect(owned(CatalogDerivableIndexes.expected(upgradedUnits)),
        owned(upgradedUnits));
    expect((await CatalogNarrativeUsages.prepare(upgraded)).upserts, isEmpty);
  });
}
