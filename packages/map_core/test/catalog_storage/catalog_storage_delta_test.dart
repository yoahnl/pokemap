import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

CatalogDefinitionUnit _unit(
  String id, {
  int version = 1,
  Iterable<CatalogDefinitionKey> references = const [],
}) => CatalogDefinitionUnit(
  key: CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id),
  payload: {'id': id, 'version': version},
  references: references,
);

Future<CatalogSnapshot> _open(
  CatalogObjectReference root,
  Map<String, List<int>> objects,
  CatalogStorageLimits limits, [
  List<String>? reads,
]) => CatalogSnapshot.open(
  root: root,
  limits: limits,
  readObject: (reference) async {
    reads?.add(reference.sha256);
    return objects[reference.sha256]!;
  },
);

Object? _canonical(Object? value) {
  if (value is List) return value.map(_canonical).toList();
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  return value;
}

CatalogObjectReference _put(
  Map<String, dynamic> value,
  Map<String, List<int>> objects,
) {
  final bytes = utf8.encode(jsonEncode(_canonical(value)));
  final reference = CatalogObjectReference(
    sha256: sha256.convert(bytes).toString(),
    byteLength: bytes.length,
  );
  objects[reference.sha256] = bytes;
  return reference;
}

void main() {
  test('identity admission performs no object reads after opening', () async {
    final limits = CatalogStorageLimits(indexPageSize: 2);
    final built = CatalogStorageBuilder(limits: limits).build([_unit('a')]);
    final objects = {...built.objects};
    final source = await _open(built.root, objects, limits);
    await source.validate();
    final reads = <String>[];
    final target = await _open(built.root, objects, limits, reads);
    reads.clear();
    final delta = await target.admitFrom(source);
    expect(delta.upserts, isEmpty);
    expect(delta.removals, isEmpty);
    expect(delta.addedObjects, isEmpty);
    expect(delta.removedObjects, isEmpty);
    expect(reads, isEmpty);
  });

  test(
    'historical replacement admission skips unchanged trees and units',
    () async {
      for (final count in [256, 1024]) {
        final limits = CatalogStorageLimits(indexPageSize: 8);
        final built = CatalogStorageBuilder(limits: limits).build(
          List.generate(
            count,
            (index) => _unit('id-${index.toString().padLeft(4, '0')}'),
          ),
        );
        final objects = {...built.objects};
        final original = await _open(built.root, objects, limits);
        await original.validate();
        final patch = await original.patch(
          upserts: [_unit('id-0009', version: 2)],
        );
        objects.addAll(patch.objects);
        final current = await patch.nextSnapshot(
          readObject: (ref) async => objects[ref.sha256]!,
        );
        final reads = <String>[];
        final target = await _open(built.root, objects, limits, reads);
        final delta = await target.admitFrom(current);
        expect(delta.upserts.map((unit) => unit.key.id), ['id-0009']);
        expect(delta.removals, isEmpty);
        expect(
          target.admittedStoredBytes,
          built.objects.values.fold<int>(0, (sum, bytes) => sum + bytes.length),
        );
        expect(reads.length, lessThanOrEqualTo(12));
        expect(
          reads.where(
            (digest) =>
                (jsonDecode(utf8.decode(objects[digest]!)) as Map)['type'] ==
                'unit',
          ),
          hasLength(1),
        );
        final verifiedBytes = target.admittedStoredBytes;
        await target.validate();
        expect(target.admittedStoredBytes, verifiedBytes);
      }
    },
  );

  test(
    'delta reports all changed keys through splits and unequal heights',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 2);
      final built = CatalogStorageBuilder(
        limits: limits,
      ).build([_unit('a'), _unit('b')]);
      final objects = {...built.objects};
      final original = await _open(built.root, objects, limits);
      await original.validate();
      final patch = await original.patch(
        upserts: [_unit('b', version: 2), _unit('c'), _unit('d'), _unit('e')],
      );
      objects.addAll(patch.objects);
      final target = await _open(patch.root, objects, limits);
      final delta = await target.admitFrom(original);
      expect(delta.upserts.map((unit) => unit.key.id), ['b', 'c', 'd', 'e']);
      expect(delta.removals, isEmpty);
      final bytes = target.admittedStoredBytes;
      await target.validate();
      expect(target.admittedStoredBytes, bytes);
    },
  );

  test(
    'removal delta is available but cannot admit without incoming references proof',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 2);
      final built = CatalogStorageBuilder(
        limits: limits,
      ).build([_unit('a'), _unit('b'), _unit('c')]);
      final objects = {...built.objects};
      final original = await _open(built.root, objects, limits);
      await original.validate();
      final patch = await original.patch(removals: [_unit('b').key]);
      objects.addAll(patch.objects);
      final target = await _open(patch.root, objects, limits);
      final delta = await target.deltaFrom(original);
      expect(delta.removals, [_unit('b').key]);
      await expectLater(target.admitFrom(original), throwsFormatException);
      expect(target.admittedStoredBytes, isNull);
    },
  );

  test('admission rejects missing changed-unit dependencies', () async {
    final limits = CatalogStorageLimits(indexPageSize: 2);
    final before = CatalogStorageBuilder(limits: limits).build([_unit('a')]);
    final after = CatalogStorageBuilder(limits: limits).build([
      _unit('a', references: [_unit('missing').key]),
      _unit('missing'),
    ]);
    final objects = {...before.objects, ...after.objects};
    final current = await _open(before.root, objects, limits);
    await current.validate();
    final root =
        jsonDecode(utf8.decode(objects[after.root.sha256]!))
            as Map<String, dynamic>;
    final index = root['index'] as Map<String, dynamic>;
    final reference = index['reference'] as Map<String, dynamic>;
    final leaf =
        jsonDecode(utf8.decode(objects[reference['sha256']]!))
            as Map<String, dynamic>;
    (leaf['entries'] as List).removeWhere(
      (entry) => entry['key']['id'] == 'missing',
    );
    index['reference'] = _put(leaf, objects).toJson();
    index['last'] = index['first'];
    index['count'] = 1;
    root['definitionCount'] = 1;
    final target = await _open(_put(root, objects), objects, limits);
    await expectLater(target.admitFrom(current), throwsFormatException);
    expect(target.admittedStoredBytes, isNull);
  });

  test(
    'delta requires an admitted source and does not admit corrupt target bytes',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 2);
      final built = CatalogStorageBuilder(limits: limits).build([_unit('a')]);
      final objects = {...built.objects};
      final before = await _open(built.root, objects, limits);
      final same = await _open(built.root, objects, limits);
      await expectLater(same.admitFrom(before), throwsStateError);
      await before.validate();
      final patch = await before.patch(upserts: [_unit('a', version: 2)]);
      objects.addAll(patch.objects);
      final target = await _open(patch.root, objects, limits);
      final digest = patch.objects.entries
          .firstWhere(
            (entry) =>
                (jsonDecode(utf8.decode(entry.value)) as Map)['type'] == 'unit',
          )
          .key;
      objects[digest] = [0];
      await expectLater(target.admitFrom(before), throwsFormatException);
      expect(target.admittedStoredBytes, isNull);
    },
  );

  test('hash-identical subtree with altered descriptor is rejected', () async {
    final limits = CatalogStorageLimits(indexPageSize: 2);
    final built = CatalogStorageBuilder(
      limits: limits,
    ).build([_unit('a'), _unit('b')]);
    final objects = {...built.objects};
    final source = await _open(built.root, objects, limits);
    await source.validate();
    final root =
        jsonDecode(utf8.decode(objects[built.root.sha256]!))
            as Map<String, dynamic>;
    (root['index'] as Map)['last'] = _unit('c').key.toJson();
    final target = await _open(_put(root, objects), objects, limits);
    await expectLater(target.admitFrom(source), throwsFormatException);
    expect(target.admittedStoredBytes, isNull);
  });

  test(
    'changed summary cannot smuggle unchanged unit into admission',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 2);
      final built = CatalogStorageBuilder(limits: limits).build([_unit('a')]);
      final objects = {...built.objects};
      final source = await _open(built.root, objects, limits);
      await source.validate();
      final root =
          jsonDecode(utf8.decode(objects[built.root.sha256]!))
              as Map<String, dynamic>;
      final node = root['index'] as Map<String, dynamic>;
      final ref = node['reference'] as Map;
      final leaf =
          jsonDecode(utf8.decode(objects[ref['sha256']]!))
              as Map<String, dynamic>;
      ((leaf['entries'] as List).single['summary'] as Map)['name'] = 'forged';
      node['reference'] = _put(leaf, objects).toJson();
      final target = await _open(_put(root, objects), objects, limits);
      await expectLater(target.admitFrom(source), throwsFormatException);
      expect(target.admittedStoredBytes, isNull);
    },
  );

  test(
    'exact deltas and stored bytes survive repeated random tree mutations',
    () async {
      final random = Random(734);
      final limits = CatalogStorageLimits(indexPageSize: 3);
      final built = CatalogStorageBuilder(limits: limits).build([]);
      final objects = {...built.objects};
      var current = await _open(built.root, objects, limits);
      await current.validate();
      for (var step = 0; step < 80; step++) {
        final previous = current;
        final upserts = <CatalogDefinitionUnit>[];
        final removals = <CatalogDefinitionKey>[];
        for (var mutation = 0; mutation < 4; mutation++) {
          final unit = _unit(
            'id-${random.nextInt(30).toString().padLeft(2, '0')}',
            version: step + 2,
          );
          if (upserts.any((item) => item.key == unit.key) ||
              removals.contains(unit.key)) {
            continue;
          }
          if (random.nextInt(3) == 0) {
            if (await current.indexEntry(unit.key) != null) {
              removals.add(unit.key);
            }
          } else {
            upserts.add(unit);
          }
        }
        final patch = await previous.patch(
          upserts: upserts,
          removals: removals,
        );
        objects.addAll(patch.objects);
        current = await _open(patch.root, objects, limits);
        final delta = await current.deltaFrom(previous);
        expect(
          delta.upserts.map((unit) => unit.key).toSet(),
          upserts.map((unit) => unit.key).toSet(),
        );
        expect(delta.removals.toSet(), removals.toSet());
        final expectedBytes = delta.storedBytes;
        final refs = await current.objectReferences();
        final oldRefs = await previous.objectReferences();
        expect(
          delta.addedObjects.toSet(),
          refs.toSet().difference(oldRefs.toSet()),
        );
        expect(
          delta.removedObjects.toSet(),
          oldRefs.toSet().difference(refs.toSet()),
        );
        expect(current.admittedStoredBytes, expectedBytes);
      }
    },
  );
}
