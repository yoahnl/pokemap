import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('all compact pattern tags survive indexed storage and search', () async {
    final tags = [for (var index = 0; index < 40; index++) 'tag-$index'];
    final key = CatalogDefinitionKey(
      CatalogDefinitionKind.smartTilePattern,
      'frlg-pattern',
    );
    final build = CatalogStorageBuilder().build([
      CatalogDefinitionUnit(
        key: key,
        payload: {'id': key.id, 'name': 'FRLG', 'tags': tags},
      ),
    ]);
    final snapshot = await CatalogSnapshot.open(
      root: build.root,
      readObject: (reference) async => build.objects[reference.sha256]!,
    );
    await snapshot.validate();
    final entry = (await snapshot.search(text: tags.last)).items.single;
    expect(entry.key, key);
    expect(entry.summary.tags, tags);
    expect(
      CatalogDefinitionSummary.fromJson(entry.summary.toJson()).tags,
      tags,
    );
  });

  test('summary metadata remains bounded by encoded byte size', () {
    final tags = [for (var index = 0; index < 50; index++) 'é' * 100];
    final json = <String, Object?>{'name': 'FRLG', 'tags': tags};
    expect(utf8.encode(jsonEncode(json)).length, greaterThan(8192));
    expect(
      () => CatalogDefinitionSummary(name: 'FRLG', tags: tags),
      throwsFormatException,
    );
    expect(
      () => CatalogDefinitionSummary.fromJson(json),
      throwsFormatException,
    );
  });

  test('border summaries use the editable draft name', () {
    final summary = CatalogDefinitionSummary.fromUnit(
      CatalogDefinitionUnit(
        key: CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, 'border'),
        payload: {
          'id': 'border',
          'value': {
            'draft': {
              'definition': {'name': 'Mur'},
            },
          },
        },
      ),
    );
    expect(summary.name, 'Mur');
  });
  test('wide summaries split index leaves within their byte ceiling', () async {
    final build = CatalogStorageBuilder().build([
      for (var index = 0; index < 200; index++)
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(
            CatalogDefinitionKind.element,
            'wide$index',
          ),
          payload: {
            'id': 'wide$index',
            'name': '$index',
            'description': 'x' * 2000,
          },
        ),
    ]);
    final snapshot = await CatalogSnapshot.open(
      root: build.root,
      readObject: (reference) async => build.objects[reference.sha256]!,
    );
    expect((await snapshot.search(limit: 5)).totalAvailable, 200);
    await snapshot.validate();
  });
  test('search scans summaries without reading unit payloads', () async {
    final build = CatalogStorageBuilder().build([
      for (var index = 0; index < 150; index++)
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(CatalogDefinitionKind.element, 'e$index'),
          payload: {
            'id': 'e$index',
            'name': index.isEven ? 'Maison $index' : 'Arbre $index',
            'tags': ['extérieur'],
          },
        ),
    ]);
    var unitReads = 0;
    final snapshot = await CatalogSnapshot.open(
      root: build.root,
      readObject: (reference) async {
        final bytes = build.objects[reference.sha256]!;
        if ((jsonDecode(utf8.decode(bytes)) as Map)['type'] == 'unit') {
          unitReads++;
        }
        return bytes;
      },
    );
    final first = await snapshot.search(text: 'MAISON', limit: 7);
    final indexed = await snapshot.indexEntry(first.items.first.key);
    expect(indexed!.summary.name, first.items.first.summary.name);
    expect(first.items, hasLength(7));
    expect(first.totalAvailable, 75);
    expect(first.items.first.summary.name, startsWith('Maison'));
    expect(unitReads, 0);
    final second = await snapshot.search(
      text: 'maison',
      limit: 7,
      cursor: first.nextCursor,
    );
    expect(second.items.first.key, isNot(first.items.last.key));
    await expectLater(
      snapshot.search(text: 'arbre', cursor: first.nextCursor),
      throwsFormatException,
    );
    expect(unitReads, 0);
  });

  test(
    'index summaries are bounded and metadata edits refresh search',
    () async {
      final key = CatalogDefinitionKey(CatalogDefinitionKind.element, 'one');
      final original = CatalogDefinitionUnit(
        key: key,
        payload: {'id': 'one', 'name': 'Before'},
      );
      final build = CatalogStorageBuilder().build([original]);
      final objects = {...build.objects};
      final snapshot = await CatalogSnapshot.open(
        root: build.root,
        readObject: (reference) async => objects[reference.sha256]!,
      );
      await snapshot.validate();
      final patch = await snapshot.patch(
        upserts: [
          CatalogDefinitionUnit(
            key: key,
            payload: {'id': 'one', 'name': 'After'},
          ),
        ],
      );
      objects.addAll(patch.objects);
      final next = await patch.nextSnapshot(
        readObject: (reference) async => objects[reference.sha256]!,
      );
      expect((await next.search(text: 'after')).items.single.key, key);
      expect((await next.search(text: 'before')).items, isEmpty);
      expect(
        () => CatalogStorageBuilder().build([
          CatalogDefinitionUnit(
            key: key,
            payload: {'id': 'one', 'name': 'a' * 513},
          ),
        ]),
        throwsFormatException,
      );
    },
  );
}
