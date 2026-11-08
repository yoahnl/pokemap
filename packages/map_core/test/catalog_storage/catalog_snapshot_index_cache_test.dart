import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'warm exact lookups schedule work for their path rather than unrelated siblings',
    () async {
      final scheduled = <int>[];
      for (final count in [128, 4096]) {
        final fixture = _Fixture(count: count, pageSize: 128);
        final snapshot = await fixture.open(
          limits: CatalogStorageLimits(indexPageSize: 128),
        );
        await snapshot.lookup(_key(0));
        var microtasks = 0;
        await runZoned(
          () async {
            for (var repeat = 0; repeat < 3; repeat++) {
              expect((await snapshot.lookup(_key(0)))!.key, _key(0));
            }
          },
          zoneSpecification: ZoneSpecification(
            scheduleMicrotask: (self, parent, zone, task) {
              microtasks++;
              parent.scheduleMicrotask(zone, task);
            },
          ),
        );
        scheduled.add(microtasks);
      }
      expect(
        scheduled.last,
        lessThanOrEqualTo(scheduled.first + 3 * 8),
        reason: 'scheduled microtasks for 128 and 4096 definitions: $scheduled',
      );
    },
  );

  test(
    'neighboring lookups reuse index pages but reread definition units',
    () async {
      final fixture = _Fixture();
      final snapshot = await fixture.open();
      await snapshot.lookup(_key(0));
      final warmed = Map<String, int>.of(fixture.reads);
      await snapshot.lookup(_key(1));
      for (final digest in fixture.indexDigests) {
        expect(
          fixture.reads[digest],
          warmed[digest],
          reason: fixture.type(digest),
        );
      }
      final unitDigest = fixture.unitDigest(0);
      await snapshot.lookup(_key(0));
      expect(fixture.reads[unitDigest], 2);
    },
  );

  test('parallel lookups share in-flight index page reads', () async {
    final fixture = _Fixture();
    final gate = Completer<void>();
    final entered = Completer<void>();
    final snapshot = await fixture.open(
      beforeRead: (reference) async {
        if (fixture.type(reference.sha256) == 'branch') {
          if (!entered.isCompleted) entered.complete();
          await gate.future;
        }
      },
    );
    final first = snapshot.lookup(_key(0));
    await entered.future;
    final second = snapshot.lookup(_key(1));
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    expect((await Future.wait([first, second])).map((unit) => unit!.key), [
      _key(0),
      _key(1),
    ]);
    for (final digest in fixture.indexDigests.where(
      fixture.reads.containsKey,
    )) {
      expect(fixture.reads[digest], 1, reason: fixture.type(digest));
    }
  });

  test('a corrupt index read is retried after storage is repaired', () async {
    final fixture = _Fixture();
    final damaged = fixture.indexDigests.first;
    final original = fixture.objects[damaged]!;
    fixture.objects[damaged] = List.filled(original.length, 32);
    final snapshot = await fixture.open();
    await expectLater(snapshot.lookup(_key(0)), throwsFormatException);
    fixture.objects[damaged] = original;
    expect((await snapshot.lookup(_key(0)))!.key, _key(0));
    expect(fixture.reads[damaged], 2);
  });

  test(
    'validation rereads warmed index pages and detects later corruption',
    () async {
      final fixture = _Fixture();
      final snapshot = await fixture.open();
      await snapshot.lookup(_key(0));
      final damaged = fixture.indexDigests.firstWhere(
        fixture.reads.containsKey,
      );
      fixture.objects[damaged] = List.filled(
        fixture.objects[damaged]!.length,
        32,
      );
      await expectLater(snapshot.validate(), throwsFormatException);
      expect(fixture.reads[damaged], 2);
    },
  );

  test('different snapshot roots do not share warmed index pages', () async {
    final fixture = _Fixture();
    final first = await fixture.open();
    await first.lookup(_key(0));
    final sharedLeaf = fixture.indexDigests.firstWhere(
      (digest) =>
          fixture.reads.containsKey(digest) && fixture.type(digest) == 'leaf',
    );
    final newer = _Fixture(count: 18);
    expect(newer.root, isNot(fixture.root));
    fixture.objects.addAll(newer.objects);
    final second = await fixture.open(root: newer.root);
    await second.lookup(_key(0));
    expect(fixture.reads[sharedLeaf], 2);
  });

  test('a small stored-byte limit evicts warmed index pages', () async {
    final fixture = _Fixture();
    final cap = fixture.indexDigests
        .map((digest) => fixture.objects[digest]!.length)
        .reduce((a, b) => a > b ? a : b);
    final snapshot = await fixture.open(
      limits: CatalogStorageLimits(indexPageSize: 2, maxStoredBytes: cap),
    );
    await snapshot.lookup(_key(0));
    final initial = fixture.indexDigests
        .where(fixture.reads.containsKey)
        .toSet();
    for (var index = 2; index < 16; index += 2) {
      await snapshot.lookup(_key(index));
    }
    final previous = Map<String, int>.of(fixture.reads);
    await snapshot.lookup(_key(0));
    expect(
      initial.any((digest) => fixture.reads[digest]! > previous[digest]!),
      isTrue,
    );
  });

  test(
    'a cached leaf still validates the requesting descriptor range',
    () async {
      final fixture = _Fixture(count: 4);
      final root = fixture.json(fixture.root.sha256);
      final index = root['index']! as Map<String, dynamic>;
      final branchReference = index['reference']! as Map<String, dynamic>;
      final branch = fixture.json(branchReference['sha256']! as String);
      final children = branch['children']! as List<dynamic>;
      final first = children[0] as Map<String, dynamic>;
      final second = children[1] as Map<String, dynamic>;
      second['reference'] = first['reference'];
      index['reference'] = fixture.store(branch).toJson();
      final snapshot = await fixture.open(root: fixture.store(root));
      expect((await snapshot.lookup(_key(0)))!.key, _key(0));
      await expectLater(snapshot.lookup(_key(2)), throwsFormatException);
      final leafDigest = (first['reference'] as Map)['sha256'] as String;
      expect(fixture.reads[leafDigest], 1);
    },
  );

  group('a shared index cache', () {
    test('lets another snapshot of the same root reread only units', () async {
      final fixture = _Fixture();
      final cache = CatalogIndexCache();
      final first = await fixture.open(indexCache: cache);
      final expected = await first.lookup(_key(5));
      final warmed = Map<String, int>.of(fixture.reads);
      final second = await fixture.open(indexCache: cache);
      final unit = await second.lookup(_key(5));
      expect(unit!.toJson(), expected!.toJson());
      expect(
        {
          for (final digest in fixture.reads.keys)
            if (fixture.reads[digest] != warmed[digest]) digest,
        },
        {fixture.unitDigest(5)},
      );
      expect(fixture.reads[fixture.root.sha256], 1);
      expect(
        (await (await fixture.open()).lookup(_key(5)))!.toJson(),
        unit.toJson(),
      );
    });

    test('lets a newer root reread only the index pages it changed', () async {
      final fixture = _Fixture(count: 32);
      final cache = CatalogIndexCache();
      final before = await fixture.open(indexCache: cache);
      for (var index = 0; index < 32; index++) {
        await before.lookup(_key(index));
      }
      final patch = await before.patch(
        upserts: [
          CatalogDefinitionUnit(
            key: _key(20),
            payload: {'id': _key(20).id, 'changed': true},
          ),
        ],
      );
      fixture.objects.addAll(patch.objects);
      fixture.reads.clear();
      final after = await fixture.open(root: patch.root, indexCache: cache);
      for (var index = 0; index < 32; index++) {
        await after.lookup(_key(index));
      }
      final pages = fixture.reads.keys.where(
        (digest) => fixture.type(digest) != 'unit',
      );
      expect(pages, isNotEmpty);
      expect(
        pages.where((digest) => !patch.objects.containsKey(digest)),
        isEmpty,
        reason: 'unchanged index pages come from the cache',
      );
      expect(fixture.reads.values.every((count) => count == 1), isTrue);
      expect((await after.lookup(_key(20)))!.payload['changed'], isTrue);
    });

    test('rereads and verifies every definition unit', () async {
      final fixture = _Fixture();
      final cache = CatalogIndexCache();
      await (await fixture.open(indexCache: cache)).lookup(_key(3));
      final damaged = fixture.unitDigest(3);
      fixture.objects[damaged] = List.filled(
        fixture.objects[damaged]!.length,
        32,
      );
      await expectLater(
        (await fixture.open(indexCache: cache)).lookup(_key(3)),
        throwsFormatException,
      );
      expect(fixture.reads[damaged], 2);
    });

    test('builds the same patch as an uncached snapshot', () async {
      final fixture = _Fixture(count: 32);
      final cache = CatalogIndexCache();
      final warmed = await fixture.open(indexCache: cache);
      for (var index = 0; index < 32; index++) {
        await warmed.lookup(_key(index));
      }
      final upserts = [
        CatalogDefinitionUnit(
          key: _key(7),
          payload: {'id': _key(7).id, 'name': 'seven'},
        ),
        CatalogDefinitionUnit(key: _key(40), payload: {'id': _key(40).id}),
      ];
      final cached = await (await fixture.open(
        indexCache: cache,
      )).patch(upserts: upserts, removals: [_key(30)]);
      final uncached = await (await fixture.open()).patch(
        upserts: upserts,
        removals: [_key(30)],
      );
      expect(cached.root, uncached.root);
      expect(cached.objects.keys.toSet(), uncached.objects.keys.toSet());
    });

    test('does not hide corruption from validation', () async {
      final fixture = _Fixture();
      final cache = CatalogIndexCache();
      final snapshot = await fixture.open(indexCache: cache);
      await snapshot.lookup(_key(0));
      final damaged = fixture.indexDigests.firstWhere(
        fixture.reads.containsKey,
      );
      fixture.objects[damaged] = List.filled(
        fixture.objects[damaged]!.length,
        32,
      );
      await expectLater(
        (await fixture.open(indexCache: cache)).validate(),
        throwsFormatException,
      );
      expect(fixture.reads[damaged], 2);
    });

    test('is not reused under different limits', () async {
      final fixture = _Fixture();
      final cache = CatalogIndexCache();
      await (await fixture.open(indexCache: cache)).lookup(_key(0));
      final warmed = Map<String, int>.of(fixture.reads);
      await (await fixture.open(
        indexCache: cache,
        limits: CatalogStorageLimits(indexPageSize: 2, maxJsonValues: 5000),
      )).lookup(_key(0));
      for (final digest in warmed.keys) {
        expect(fixture.reads[digest], warmed[digest]! + 1);
      }
    });

    test('refuses cached reads once its guard fails', () async {
      final fixture = _Fixture();
      final cache = CatalogIndexCache();
      await (await fixture.open(indexCache: cache)).lookup(_key(0));
      var open = true;
      final guarded = cache.guardedBy(() {
        if (!open) throw StateError('closed');
      });
      final snapshot = await fixture.open(indexCache: guarded);
      final idle = await fixture.open(indexCache: guarded);
      final warmed = Map<String, int>.of(fixture.reads);
      expect((await snapshot.lookup(_key(1)))!.key, _key(1));
      open = false;
      await expectLater(fixture.open(indexCache: guarded), throwsStateError);
      await expectLater(idle.lookup(_key(0)), throwsStateError);
      expect(fixture.reads.keys.where((digest) => warmed[digest] == null), [
        fixture.unitDigest(1),
      ]);
    });

    test('stays within its byte budget', () async {
      final fixture = _Fixture(count: 64);
      final largest = fixture.indexDigests
          .map((digest) => fixture.objects[digest]!.length)
          .reduce((a, b) => a > b ? a : b);
      final cache = CatalogIndexCache(maximumBytes: largest * 3);
      final snapshot = await fixture.open(indexCache: cache);
      await snapshot.lookup(_key(0));
      final first = Map<String, int>.of(fixture.reads);
      for (var index = 1; index < 64; index++) {
        await (await fixture.open(indexCache: cache)).lookup(_key(index));
        expect(cache.bytes, lessThanOrEqualTo(cache.maximumBytes));
      }
      await (await fixture.open(indexCache: cache)).lookup(_key(0));
      expect(
        first.keys
            .where((digest) => fixture.type(digest) != 'unit')
            .any((digest) => fixture.reads[digest]! > first[digest]!),
        isTrue,
      );
    });
  });
}

CatalogDefinitionKey _key(int index) => CatalogDefinitionKey(
  CatalogDefinitionKind.element,
  'element-${index.toString().padLeft(3, '0')}',
);

final class _Fixture {
  _Fixture({int count = 16, int pageSize = 2}) {
    final build =
        CatalogStorageBuilder(
          limits: CatalogStorageLimits(indexPageSize: pageSize),
        ).build([
          for (var index = 0; index < count; index++)
            CatalogDefinitionUnit(
              key: _key(index),
              payload: {'id': _key(index).id},
            ),
        ]);
    root = build.root;
    objects.addAll(build.objects);
  }

  late final CatalogObjectReference root;
  final objects = <String, List<int>>{};
  final reads = <String, int>{};

  Map<String, dynamic> json(String digest) =>
      jsonDecode(utf8.decode(objects[digest]!)) as Map<String, dynamic>;

  String type(String digest) => json(digest)['type']! as String;

  Iterable<String> get indexDigests => objects.keys.where(
    (digest) => type(digest) == 'leaf' || type(digest) == 'branch',
  );

  String unitDigest(int index) => objects.keys.singleWhere(
    (digest) =>
        type(digest) == 'unit' &&
        (json(digest)['key'] as Map)['id'] == _key(index).id,
  );

  Future<CatalogSnapshot> open({
    CatalogObjectReference? root,
    CatalogStorageLimits? limits,
    CatalogIndexCache? indexCache,
    Future<void> Function(CatalogObjectReference)? beforeRead,
  }) => CatalogSnapshot.open(
    root: root ?? this.root,
    limits: limits ?? CatalogStorageLimits(indexPageSize: 2),
    indexCache: indexCache,
    readObject: (reference) async {
      reads.update(reference.sha256, (count) => count + 1, ifAbsent: () => 1);
      await beforeRead?.call(reference);
      return objects[reference.sha256]!;
    },
  );

  CatalogObjectReference store(Map<String, dynamic> value) {
    Object? canonical(Object? value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: canonical(value[key])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    final bytes = utf8.encode(jsonEncode(canonical(value)));
    final digest = crypto.sha256.convert(bytes).toString();
    objects[digest] = bytes;
    return CatalogObjectReference(sha256: digest, byteLength: bytes.length);
  }
}
