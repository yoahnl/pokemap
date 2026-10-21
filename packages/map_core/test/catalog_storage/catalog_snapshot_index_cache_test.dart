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
    Future<void> Function(CatalogObjectReference)? beforeRead,
  }) => CatalogSnapshot.open(
    root: root ?? this.root,
    limits: limits ?? CatalogStorageLimits(indexPageSize: 2),
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
