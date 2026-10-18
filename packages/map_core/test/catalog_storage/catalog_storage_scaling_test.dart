import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'one definition lookup stays targeted as unrelated catalog grows',
    () async {
      final observations = <(int, int)>[];
      for (final size in [1024, 2048, 4096]) {
        final build = CatalogStorageBuilder().build([
          for (var index = 0; index < size; index++)
            CatalogDefinitionUnit(
              key: _key(index),
              payload: {'id': _id(index), 'name': 'Décor $index'},
            ),
        ]);
        final reads = <String>[];
        var bytesRead = 0;
        final snapshot = await CatalogSnapshot.open(
          root: build.root,
          readObject: (reference) async {
            reads.add(reference.sha256);
            final bytes = build.objects[reference.sha256]!;
            bytesRead += bytes.length;
            return bytes;
          },
        );
        expect(reads, hasLength(1));
        reads.clear();
        bytesRead = 0;
        final resolved = await snapshot.lookup(_key(size - 1));
        expect(resolved!.payload['name'], 'Décor ${size - 1}');
        expect(reads.length, lessThanOrEqualTo(3));
        expect(bytesRead, lessThan(65536));
        expect(reads.length, lessThan(build.objects.length ~/ 100));
        observations.add((reads.length, bytesRead));
        final unitReads = reads.where(
          (digest) =>
              (jsonDecode(utf8.decode(build.objects[digest]!))
                  as Map)['type'] ==
              'unit',
        );
        expect(unitReads, hasLength(1));
        reads.clear();
        final page = await snapshot.page(
          kind: CatalogDefinitionKind.element,
          limit: 7,
        );
        expect(page.items.map((entry) => entry.key), [
          for (var index = 0; index < 7; index++) _key(index),
        ]);
        expect(page.nextCursor, isNotNull);
        expect(
          reads.every(
            (digest) =>
                (jsonDecode(utf8.decode(build.objects[digest]!))
                    as Map)['type'] !=
                'unit',
          ),
          isTrue,
        );
      }
      expect(observations.map((observation) => observation.$1).toSet(), {3});
    },
  );

  test('a snapshot cannot mix a dependency from a newer generation', () async {
    CatalogStorageBuild build(String revision) =>
        CatalogStorageBuilder().build([
          CatalogDefinitionUnit(
            key: _key(0),
            payload: {
              'id': _id(0),
              'frames': [
                {'durationMs': 120},
              ],
            },
            references: [_key(1)],
          ),
          CatalogDefinitionUnit(
            key: _key(1),
            payload: {'id': _id(1), 'revision': revision},
            references: [_key(0)],
          ),
        ]);
    final first = build('old');
    final second = build('new');
    final objects = {...first.objects, ...second.objects};
    Future<List<int>> read(CatalogObjectReference reference) async =>
        objects[reference.sha256]!;
    final oldSnapshot = await CatalogSnapshot.open(
      root: first.root,
      readObject: read,
    );
    final newSnapshot = await CatalogSnapshot.open(
      root: second.root,
      readObject: read,
    );
    final oldClosure = await oldSnapshot.closure([_key(0)]);
    final newClosure = await newSnapshot.closure([_key(0)]);
    expect(oldClosure, hasLength(2));
    expect(newClosure, hasLength(2));
    expect(
      oldClosure.singleWhere((unit) => unit.key == _key(1)).payload['revision'],
      'old',
    );
    expect(
      newClosure.singleWhere((unit) => unit.key == _key(1)).payload['revision'],
      'new',
    );
  });
}

String _id(int index) => 'decor-${index.toString().padLeft(5, '0')}';
CatalogDefinitionKey _key(int index) =>
    CatalogDefinitionKey(CatalogDefinitionKind.element, _id(index));
