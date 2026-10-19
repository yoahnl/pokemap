import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  CatalogDefinitionUnit unit(
    String id, {
    List<CatalogDefinitionKey> refs = const [],
  }) => CatalogDefinitionUnit(
    key: CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id),
    payload: {
      'id': id,
      'nested': {
        'value': [1, 2],
      },
    },
    references: refs,
  );

  test(
    'deterministic hierarchical snapshot reads only the chosen path',
    () async {
      final units = List.generate(
        100,
        (i) => unit('id-${i.toString().padLeft(3, '0')}'),
      );
      final limits = CatalogStorageLimits(indexPageSize: 4);
      final built = CatalogStorageBuilder(limits: limits).build(units);
      final reverse = CatalogStorageBuilder(
        limits: limits,
      ).build(units.reversed);
      expect(built.root, reverse.root);
      final reads = <String>[];
      final snapshot = await CatalogSnapshot.open(
        root: built.root,
        limits: limits,
        readObject: (ref) async {
          reads.add(ref.sha256);
          return built.objects[ref.sha256]!;
        },
      );
      expect(reads.length, 1);
      final found = await snapshot.lookup(units[50].key);
      expect(found!.key, units[50].key);
      expect(reads.length, lessThan(10));
      await snapshot.validate();
    },
  );

  test('page is index only and cursor pins snapshot and kind', () async {
    final built =
        CatalogStorageBuilder(
          limits: CatalogStorageLimits(indexPageSize: 4),
        ).build(
          List.generate(60, (i) => unit('id-${i.toString().padLeft(3, '0')}')),
        );
    final unitDigests = built.objects.entries
        .where((e) => String.fromCharCodes(e.value).contains('"type":"unit"'))
        .map((e) => e.key)
        .toSet();
    final read = <String>[];
    final snapshot = await CatalogSnapshot.open(
      root: built.root,
      readObject: (ref) async {
        read.add(ref.sha256);
        return built.objects[ref.sha256]!;
      },
    );
    final first = await snapshot.page(limit: 50);
    expect(first.items.length, 50);
    expect(read.any(unitDigests.contains), isFalse);
    final second = await snapshot.page(limit: 50, cursor: first.nextCursor);
    expect(second.items.length, 10);
    expect(second.nextCursor, isNull);
    expect(first.items.last.key.compareTo(second.items.first.key), lessThan(0));
    await expectLater(
      snapshot.page(
        cursor: first.nextCursor,
        kind: CatalogDefinitionKind.element,
      ),
      throwsFormatException,
    );
  });

  test(
    'semantic cycles close once and missing or duplicate references fail',
    () async {
      final a = unit('a', refs: [unit('b').key]);
      final b = unit('b', refs: [a.key]);
      final built = CatalogStorageBuilder().build([a, b]);
      final snapshot = await CatalogSnapshot.open(
        root: built.root,
        readObject: (r) async => built.objects[r.sha256]!,
      );
      expect((await snapshot.closure([a.key])).map((e) => e.key).toSet(), {
        a.key,
        b.key,
      });
      expect(() => CatalogStorageBuilder().build([a]), throwsFormatException);
      expect(
        () => CatalogStorageBuilder().build([a, a]),
        throwsFormatException,
      );
    },
  );

  test('payload and stored bytes are copied and deeply immutable', () async {
    final nested = <Object?>[1];
    final payload = <String, Object?>{'id': 'a', 'nested': nested};
    final definition = CatalogDefinitionUnit(
      key: unit('a').key,
      payload: payload,
    );
    nested.add(2);
    expect(definition.payload['nested'], [1]);
    expect(
      () => (definition.payload['nested'] as List).add(3),
      throwsUnsupportedError,
    );
    final built = CatalogStorageBuilder().build([definition]);
    expect(() => built.objects.values.first.add(3), throwsUnsupportedError);
  });

  test('corrupt lengths and hashes are rejected before use', () async {
    final built = CatalogStorageBuilder().build([unit('a')]);
    await expectLater(
      CatalogSnapshot.open(root: built.root, readObject: (r) async => [1]),
      throwsFormatException,
    );
    await expectLater(
      CatalogSnapshot.open(
        root: built.root,
        readObject: (r) async => List.filled(r.byteLength, 32),
      ),
      throwsFormatException,
    );
    expect(
      () => CatalogStorageLimits(maxUnitBytes: 999999999),
      throwsArgumentError,
    );
    expect(
      () => CatalogDefinitionUnit(key: unit('a').key, payload: {'id': 'b'}),
      throwsFormatException,
    );
  });

  test('bounded admission rejects stored bytes and closure depth', () async {
    expect(
      () => CatalogStorageBuilder(
        limits: CatalogStorageLimits(maxStoredBytes: 100),
      ).build([unit('a')]),
      throwsFormatException,
    );
    final a = unit('a', refs: [unit('b').key]);
    final b = unit('b', refs: [unit('c').key]);
    final built = CatalogStorageBuilder().build([a, b, unit('c')]);
    final snapshot = await CatalogSnapshot.open(
      root: built.root,
      readObject: (r) async => built.objects[r.sha256]!,
      limits: CatalogStorageLimits(maxClosureDepth: 1),
    );
    await expectLater(snapshot.closure([a.key]), throwsFormatException);
  });

  test(
    'old snapshots and pagination remain pinned after a new build',
    () async {
      final old = CatalogStorageBuilder().build([unit('a'), unit('b')]);
      final newer = CatalogStorageBuilder().build([unit('a'), unit('c')]);
      final objects = {...old.objects, ...newer.objects};
      final oldSnapshot = await CatalogSnapshot.open(
        root: old.root,
        readObject: (r) async => objects[r.sha256]!,
      );
      final newSnapshot = await CatalogSnapshot.open(
        root: newer.root,
        readObject: (r) async => objects[r.sha256]!,
      );
      final first = await oldSnapshot.page(limit: 1);
      await expectLater(
        newSnapshot.page(limit: 1, cursor: first.nextCursor),
        throwsFormatException,
      );
      expect(await oldSnapshot.lookup(unit('b').key), isNotNull);
      expect(await newSnapshot.lookup(unit('b').key), isNull);
    },
  );

  test(
    'strict root rejects version type unknown fields and duplicate JSON keys',
    () async {
      final built = CatalogStorageBuilder().build([]);
      final source = utf8.decode(built.objects[built.root.sha256]!);
      for (final invalid in [
        source.replaceFirst('"version":2', '"version":3'),
        source.replaceFirst('"version":2', '"version":2.0'),
        source.replaceFirst('"type":"root"', '"type":"unit"'),
        source.replaceFirst('{', '{"unknown":0,'),
        source.replaceFirst('"version":2', '"version":0,"version":2'),
        ' $source',
      ]) {
        final bytes = utf8.encode(invalid);
        final ref = CatalogObjectReference(
          sha256: crypto.sha256.convert(bytes).toString(),
          byteLength: bytes.length,
        );
        await expectLater(
          CatalogSnapshot.open(root: ref, readObject: (r) async => bytes),
          throwsFormatException,
        );
      }
    },
  );

  test('JSON depth value budgets and malformed inputs are bounded', () async {
    Object? nested = 0;
    for (var i = 0; i < 70; i++) {
      nested = [nested];
    }
    expect(
      () =>
          CatalogDefinitionUnit(key: unit('a').key, payload: {'value': nested}),
      throwsFormatException,
    );
    expect(
      () => CatalogDefinitionUnit(
        key: unit('a').key,
        payload: {'value': double.nan},
      ),
      throwsFormatException,
    );
    expect(
      () => CatalogStorageBuilder(
        limits: CatalogStorageLimits(maxJsonValues: 5),
      ).build([unit('a')]),
      throwsFormatException,
    );
    expect(
      () => CatalogDefinitionUnit(
        key: unit('a').key,
        payload: {},
        references: [unit('b').key, unit('b').key],
      ),
      throwsFormatException,
    );
    final empty = CatalogStorageBuilder().build([]);
    final snap = await CatalogSnapshot.open(
      root: empty.root,
      readObject: (r) async => empty.objects[r.sha256]!,
    );
    expect((await snap.page()).items, isEmpty);
    expect(await snap.lookup(unit('none').key), isNull);
    await snap.validate();
  });

  test(
    'rehashed unit and index corruption is rejected by full validation',
    () async {
      for (final corruption in [
        'unitField',
        'unitKind',
        'unitKey',
        'missingReference',
        'leafOrder',
        'leafCount',
        'branchOverlap',
      ]) {
        final fixture = _forged(corruption);
        final snapshot = await CatalogSnapshot.open(
          root: fixture.$1,
          readObject: (r) async => fixture.$2[r.sha256]!,
        );
        await expectLater(
          snapshot.validate(),
          throwsFormatException,
          reason: corruption,
        );
      }
    },
  );

  test('full validation applies total bytes including index pages', () async {
    final built = CatalogStorageBuilder().build([unit('a')]);
    final total = built.objects.values.fold<int>(0, (n, b) => n + b.length);
    final snapshot = await CatalogSnapshot.open(
      root: built.root,
      readObject: (r) async => built.objects[r.sha256]!,
      limits: CatalogStorageLimits(maxStoredBytes: total - 1),
    );
    await expectLater(snapshot.validate(), throwsFormatException);
  });

  test(
    'kind filter and page boundaries retain all entries exactly once',
    () async {
      final units = [
        for (final kind in CatalogDefinitionKind.values)
          for (var i = 0; i < 3; i++)
            CatalogDefinitionUnit(
              key: CatalogDefinitionKey(kind, 'item-$i'),
              payload: {'id': 'item-$i'},
            ),
      ];
      final built = CatalogStorageBuilder(
        limits: CatalogStorageLimits(indexPageSize: 2),
      ).build(units);
      final snapshot = await CatalogSnapshot.open(
        root: built.root,
        readObject: (r) async => built.objects[r.sha256]!,
      );
      final found = <CatalogDefinitionKey>[];
      String? cursor;
      do {
        final page = await snapshot.page(
          kind: CatalogDefinitionKind.smartTilePattern,
          limit: 1,
          cursor: cursor,
        );
        found.addAll(page.items.map((e) => e.key));
        cursor = page.nextCursor;
      } while (cursor != null);
      expect(found, [
        for (var i = 0; i < 3; i++)
          CatalogDefinitionKey(
            CatalogDefinitionKind.smartTilePattern,
            'item-$i',
          ),
      ]);
      await snapshot.validate();
    },
  );
  test(
    'cursor rejects duplicate keys whitespace and numeric version aliases',
    () async {
      final built = CatalogStorageBuilder().build([unit('a'), unit('b')]);
      final snapshot = await CatalogSnapshot.open(
        root: built.root,
        readObject: (r) async => built.objects[r.sha256]!,
      );
      final page = await snapshot.page(limit: 1);
      final source = utf8.decode(base64Url.decode(page.nextCursor!));
      for (final invalid in [
        source.replaceFirst('"version":2', '"version":0,"version":2'),
        source.replaceFirst('"version":2', '"version":2.0'),
        ' $source',
      ]) {
        await expectLater(
          snapshot.page(
            limit: 1,
            cursor: base64Url.encode(utf8.encode(invalid)),
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'closure admits unique root pages and units before reads at exact byte boundary',
    () async {
      final built = CatalogStorageBuilder().build([
        unit('a', refs: [unit('b').key]),
        unit('b', refs: [unit('a').key]),
      ]);
      final total = built.objects.values.fold<int>(0, (n, b) => n + b.length);
      for (final budget in [total, total - 1]) {
        final reads = <String>[];
        final snapshot = await CatalogSnapshot.open(
          root: built.root,
          limits: CatalogStorageLimits(maxStoredBytes: budget),
          readObject: (r) async {
            reads.add(r.sha256);
            return built.objects[r.sha256]!;
          },
        );
        if (budget == total) {
          expect((await snapshot.closure([unit('a').key])).length, 2);
        } else {
          await expectLater(
            snapshot.closure([unit('a').key]),
            throwsFormatException,
          );
          expect(reads.toSet().length, lessThan(built.objects.length));
        }
      }
    },
  );
}

(CatalogObjectReference, Map<String, List<int>>) _forged(String corruption) {
  final objects = <String, List<int>>{};
  Object? canonical(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return {for (final key in keys) key: canonical(value[key])};
    }
    if (value is List) return value.map(canonical).toList();
    return value;
  }

  CatalogObjectReference put(Map<String, Object?> value) {
    final bytes = utf8.encode(jsonEncode(canonical(value)));
    final ref = CatalogObjectReference(
      sha256: crypto.sha256.convert(bytes).toString(),
      byteLength: bytes.length,
    );
    objects[ref.sha256] = bytes;
    return ref;
  }

  final entries = <Map<String, Object?>>[];
  for (final id in ['a', 'b']) {
    final key = CatalogDefinitionKey(CatalogDefinitionKind.element, id);
    final json = CatalogDefinitionUnit(key: key, payload: {'id': id}).toJson();
    if (id == 'a') {
      switch (corruption) {
        case 'unitField':
          json['extra'] = true;
        case 'unitKind':
          json['key'] = {'kind': 'futureKind', 'id': id};
        case 'unitKey':
          json['key'] = CatalogDefinitionKey(
            CatalogDefinitionKind.element,
            'other',
          ).toJson();
        case 'missingReference':
          json['references'] = [
            CatalogDefinitionKey(
              CatalogDefinitionKind.element,
              'missing',
            ).toJson(),
          ];
      }
    }
    entries.add({
      'key': key.toJson(),
      'reference': put(json).toJson(),
      'summary': CatalogDefinitionSummary(name: id).toJson(),
    });
  }
  final leaf = put({
    'type': 'leaf',
    'version': 2,
    'entries': corruption == 'leafOrder' ? entries.reversed.toList() : entries,
  });
  final node = <String, Object?>{
    'first': entries.first['key'],
    'last': entries.last['key'],
    'height': 0,
    'count': corruption == 'leafCount' ? 3 : 2,
    'reference': leaf.toJson(),
  };
  if (corruption == 'branchOverlap') {
    final branch = put({
      'type': 'branch',
      'version': 2,
      'children': [node, node],
    });
    return (
      put({
        'type': 'root',
        'version': 2,
        'definitionCount': 4,
        'index': {
          ...node,
          'count': 4,
          'height': 1,
          'reference': branch.toJson(),
        },
      }),
      objects,
    );
  }
  return (
    put({
      'type': 'root',
      'version': 2,
      'definitionCount': corruption == 'leafCount' ? 3 : 2,
      'index': node,
    }),
    objects,
  );
}
