import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../support/map_directory_fixture.dart';
import '../support/narrative_title_fixture.dart';

void main() {
  Future<CatalogMapDirectoryRead> read(
          NarrativeTitleFixture fixture, List<String> mapIds) async =>
      CatalogMapDirectory.read(await fixture.snapshot(), mapIds);

  test('preparation lists the narrative elements of every map', () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    expect(
        await read(fixture, ['map_0']),
        isA<CatalogMapDirectoryPreparationRequired>()
            .having((value) => value.reason, 'reason', 'absent'));
    await fixture.prepare(CatalogMapDirectory.preparationScope);
    final head = (await fixture.snapshot()).root;
    await fixture.prepare(CatalogMapDirectory.preparationScope);
    expect((await fixture.snapshot()).root, head);

    final pages =
        await read(fixture, ['map_0', 'map_9']) as CatalogMapDirectoryPages;
    expect(pages.unknownMapIds, ['map_9']);
    final page = pages.pages.single;
    expect((page.mapId, page.name), ('map_0', 'Map 0'));
    expect(page.elements, [
      {
        'id': 'npc_0',
        'kind': 'entity',
        'name': 'Professor',
        'cell': [0, 2],
        'entityKind': 'npc',
        'characterId': 'character_0',
      },
      {
        'id': 'trigger_0',
        'kind': 'trigger',
        'name': 'Doorway',
        'cell': [3, 4],
      },
    ]);
  });

  test('saving one map rewrites only its page among many maps', () async {
    final fixture = await createMapDirectoryFixture(maps: 40);
    addTearDown(fixture.close);
    await fixture.prepare(CatalogMapDirectory.preparationScope);
    Future<Map<String, String>> pages() async => {
          for (final unit in await (await fixture.snapshot()).readAllUnits())
            if (unit.key.id.startsWith('["mapDirectory",'))
              unit.key.id: jsonEncode(unit.payload)
        };
    final before = await pages();
    expect(before, hasLength(40));

    await publishRenamedNpc(fixture, 7, 'Elm');
    final after = await pages();
    expect({
      for (final key in after.keys)
        if (before[key] != after[key]) key
    }, {
      CatalogMapDirectory.pageKey('map_7').id
    });
    final page = (await read(fixture, ['map_7']) as CatalogMapDirectoryPages)
        .pages
        .single;
    expect(page.elements.first['name'], 'Elm');
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a missing map refuses the preparation without writing', () async {
    final fixture = await createMapDirectoryFixture();
    addTearDown(fixture.close);
    await File('${fixture.root.path}/maps/map_1.json').delete();
    final head = (await fixture.snapshot()).root;
    await expectLater(
        fixture.prepare(CatalogMapDirectory.preparationScope),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.map_directory.map_missing')));
    expect((await fixture.snapshot()).root, head);
    expect(await read(fixture, ['map_0']),
        isA<CatalogMapDirectoryPreparationRequired>());
  });
}
