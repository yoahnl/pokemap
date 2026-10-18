import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

CatalogDefinitionUnit _unit(
  String id, {
  int version = 1,
  List<CatalogDefinitionKey> references = const [],
}) => CatalogDefinitionUnit(
  key: CatalogDefinitionKey(CatalogDefinitionKind.smartTilePattern, id),
  payload: {
    'id': id,
    'version': version,
    'parts': [
      {'atlasId': 'atlas', 'x': 3, 'y': 4, 'layer': 'above'},
    ],
    'frames': [80, 120],
  },
  references: references,
);

Future<CatalogSnapshot> _open(
  CatalogStorageBuild build,
  Map<String, List<int>> objects, {
  CatalogStorageLimits? limits,
  List<String>? reads,
}) => CatalogSnapshot.open(
  root: build.root,
  limits: limits,
  readObject: (ref) async {
    reads?.add(ref.sha256);
    return objects[ref.sha256]!;
  },
);

void main() {
  test('replacement writes only unit and its index ancestors', () async {
    final limits = CatalogStorageLimits(indexPageSize: 4);
    for (final count in [64, 128, 256]) {
      final build = CatalogStorageBuilder(limits: limits).build(
        List.generate(
          count,
          (i) => _unit('id-${i.toString().padLeft(4, '0')}'),
        ),
      );
      final objects = {...build.objects};
      final reads = <String>[];
      final before = await _open(build, objects, limits: limits, reads: reads);
      await before.validate();
      reads.clear();
      final changed = _unit('id-0009', version: 2);
      final patch = await before.patch(upserts: [changed]);
      expect(patch.beforeRoot, build.root);
      expect(patch.definitionCount, count);
      expect(patch.objects.length, lessThanOrEqualTo(7));
      expect(reads.length, lessThanOrEqualTo(8));
      expect(
        patch.objects.keys.toSet().intersection(build.objects.keys.toSet()),
        isEmpty,
      );
      objects.addAll(patch.objects);
      final after = await patch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      expect((await after.lookup(changed.key))!.payload, changed.payload);
      expect((await before.lookup(changed.key))!.payload['version'], 1);
      await after.validate();
      expect(await after.objectReferences(), isNotEmpty);
    }
  });

  test('noop retains root and writes nothing', () async {
    final original = _unit('a');
    final built = CatalogStorageBuilder().build([original]);
    final snapshot = await _open(built, {...built.objects});
    for (final patch in [
      await snapshot.patch(),
      await snapshot.patch(upserts: [original]),
      await snapshot.patch(removals: [_unit('absent').key]),
    ]) {
      expect(patch.root, built.root);
      expect(patch.isEmpty, isTrue);
      expect(patch.objects, isEmpty);
    }
  });

  test('insert splits the index and deleting all collapses it', () async {
    final limits = CatalogStorageLimits(indexPageSize: 2);
    final built = CatalogStorageBuilder(limits: limits).build([]);
    final objects = {...built.objects};
    var snapshot = await _open(built, objects, limits: limits);
    final expected = <String>{};
    for (final id in ['d', 'a', 'b', 'e', 'c', 'f', 'g']) {
      final patch = await snapshot.patch(upserts: [_unit(id)]);
      objects.addAll(patch.objects);
      snapshot = await patch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      expected.add(id);
      expect(snapshot.definitionCount, expected.length);
      await snapshot.validate();
    }
    expect((await snapshot.page(limit: 2)).items.map((e) => e.key.id), [
      'a',
      'b',
    ]);
    for (final id in ['a', 'c', 'd', 'f', 'g', 'e', 'b']) {
      final patch = await snapshot.patch(removals: [_unit(id).key]);
      objects.addAll(patch.objects);
      snapshot = await patch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      expected.remove(id);
      expect(snapshot.definitionCount, expected.length);
      await snapshot.validate();
    }
    expect((await snapshot.page(limit: 2)).items, isEmpty);
    expect((await snapshot.objectReferences()).length, 1);
  });

  test(
    'a batch can create cyclic references while dangling references fail',
    () async {
      final built = CatalogStorageBuilder().build([]);
      final objects = {...built.objects};
      final snapshot = await _open(built, objects);
      final a = _unit('a', references: [_unit('b').key]);
      final b = _unit('b', references: [a.key]);
      await expectLater(snapshot.patch(upserts: [a]), throwsFormatException);
      final patch = await snapshot.patch(upserts: [a, b]);
      objects.addAll(patch.objects);
      final after = await patch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      expect((await after.closure([a.key])).length, 2);
      await expectLater(after.patch(removals: [b.key]), throwsFormatException);
      final safe = await after.patch(upserts: [_unit('a')], removals: [b.key]);
      objects.addAll(safe.objects);
      final last = await safe.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      await last.validate();
      expect(last.definitionCount, 1);
    },
  );

  test('duplicate and overlapping mutation keys fail', () async {
    final built = CatalogStorageBuilder().build([_unit('a')]);
    final snapshot = await _open(built, {...built.objects});
    await expectLater(
      snapshot.patch(upserts: [_unit('a'), _unit('a')]),
      throwsFormatException,
    );
    await expectLater(
      snapshot.patch(removals: [_unit('a').key, _unit('a').key]),
      throwsFormatException,
    );
    await expectLater(
      snapshot.patch(upserts: [_unit('a')], removals: [_unit('a').key]),
      throwsFormatException,
    );
  });

  test(
    'budgets apply to the final graph and a replacement can reduce size',
    () async {
      final a = _unit('a');
      final built = CatalogStorageBuilder().build([a]);
      final total = built.objects.values.fold(0, (n, v) => n + v.length);
      final limits = CatalogStorageLimits(maxStoredBytes: total);
      final snapshot = await _open(built, {...built.objects}, limits: limits);
      await expectLater(
        snapshot.patch(upserts: [_unit('b')]),
        throwsFormatException,
      );
      final smaller = CatalogDefinitionUnit(key: a.key, payload: {'id': 'a'});
      final patch = await snapshot.patch(upserts: [smaller]);
      expect(patch.objects, isNotEmpty);
      final maxOne = await _open(built, {
        ...built.objects,
      }, limits: CatalogStorageLimits(maxDefinitions: 1));
      await expectLater(
        maxOne.patch(upserts: [_unit('b')]),
        throwsFormatException,
      );
      final bounded = await _open(built, {
        ...built.objects,
      }, limits: CatalogStorageLimits(maxUnitBytes: 512));
      await expectLater(
        bounded.patch(
          upserts: [
            CatalogDefinitionUnit(
              key: a.key,
              payload: {'id': 'a', 'text': 'x' * 512},
            ),
          ],
        ),
        throwsFormatException,
      );
    },
  );

  test('patch admission refuses corruption outside the changed path', () async {
    final built =
        CatalogStorageBuilder(
          limits: CatalogStorageLimits(indexPageSize: 2),
        ).build(
          List.generate(12, (i) => _unit('id-${i.toString().padLeft(2, '0')}')),
        );
    final objects = {...built.objects};
    final entry = objects.entries.firstWhere((e) {
      final value = jsonDecode(utf8.decode(e.value)) as Map;
      return value['type'] == 'unit' && (value['key'] as Map)['id'] == 'id-11';
    });
    objects[entry.key] = [0];
    final snapshot = await _open(built, objects);
    await expectLater(
      snapshot.patch(upserts: [_unit('id-00', version: 2)]),
      throwsFormatException,
    );
    await expectLater(snapshot.objectReferences(), throwsFormatException);
  });

  test(
    'successive patches retain admission without a global payload cache',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 4);
      final built = CatalogStorageBuilder(limits: limits).build(
        List.generate(256, (i) => _unit('id-${i.toString().padLeft(4, '0')}')),
      );
      final objects = {...built.objects};
      final reads = <String>[];
      var snapshot = await _open(built, objects, limits: limits, reads: reads);
      await snapshot.validate();
      for (var version = 2; version < 6; version++) {
        reads.clear();
        final patch = await snapshot.patch(
          upserts: [_unit('id-0009', version: version)],
        );
        expect(reads.length, lessThanOrEqualTo(5));
        expect(patch.objects.length, 6);
        objects.addAll(patch.objects);
        snapshot = await patch.nextSnapshot(
          readObject: (reference) async {
            reads.add(reference.sha256);
            return objects[reference.sha256]!;
          },
        );
        final actual = await snapshot.objectReferences();
        expect(actual.map((ref) => ref.sha256).toSet().length, actual.length);
        expect(
          actual.every((ref) => objects[ref.sha256]!.length == ref.byteLength),
          isTrue,
        );
      }
    },
  );

  test(
    'payload byte depth value and index ceilings cannot be bypassed',
    () async {
      final key = _unit('a').key;
      final cases = [
        (
          CatalogStorageLimits(maxJsonDepth: 8),
          <String, Object?>{
            'id': 'a',
            'deep': [
              [
                [
                  [
                    [
                      [
                        [
                          [
                            [1],
                          ],
                        ],
                      ],
                    ],
                  ],
                ],
              ],
            ],
          },
        ),
        (
          CatalogStorageLimits(maxJsonValues: 40),
          <String, Object?>{'id': 'a', 'values': List.filled(45, 0)},
        ),
        (
          CatalogStorageLimits(maxIndexBytes: 200),
          <String, Object?>{'id': 'a'},
        ),
      ];
      for (final (limits, payload) in cases) {
        final built = CatalogStorageBuilder(limits: limits).build([]);
        final snapshot = await _open(built, {...built.objects}, limits: limits);
        await expectLater(
          snapshot.patch(
            upserts: [CatalogDefinitionUnit(key: key, payload: payload)],
          ),
          throwsFormatException,
        );
      }
      final limits = CatalogStorageLimits(indexPageSize: 2, maxIndexDepth: 1);
      final built = CatalogStorageBuilder(
        limits: limits,
      ).build([_unit('a'), _unit('b'), _unit('c'), _unit('d')]);
      final snapshot = await _open(built, {...built.objects}, limits: limits);
      await expectLater(
        snapshot.patch(upserts: [_unit('e')]),
        throwsFormatException,
      );
      final refLimits = CatalogStorageLimits(maxReferencesPerUnit: 1);
      final two = CatalogStorageBuilder(
        limits: refLimits,
      ).build([_unit('a'), _unit('b')]);
      final refs = await _open(two, {...two.objects}, limits: refLimits);
      await expectLater(
        refs.patch(
          upserts: [
            _unit('a', references: [_unit('a').key, _unit('b').key]),
          ],
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'the final byte ceiling remains exact across splits and removals',
    () async {
      final limits = CatalogStorageLimits(indexPageSize: 2);
      final built = CatalogStorageBuilder(
        limits: limits,
      ).build([_unit('a'), _unit('c')]);
      final objects = {...built.objects};
      var snapshot = await _open(built, objects, limits: limits);
      for (final id in ['b', 'd', 'e', 'f']) {
        final patch = await snapshot.patch(upserts: [_unit(id)]);
        objects.addAll(patch.objects);
        snapshot = await patch.nextSnapshot(
          readObject: (r) async => objects[r.sha256]!,
        );
      }
      final finalPatch = await snapshot.patch(
        removals: [_unit('b').key, _unit('d').key, _unit('f').key],
      );
      objects.addAll(finalPatch.objects);
      final last = await finalPatch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      final reachable = await last.objectReferences();
      final bytes = reachable.fold(0, (n, ref) => n + ref.byteLength);
      final exact = await CatalogSnapshot.open(
        root: last.root,
        readObject: (r) async => objects[r.sha256]!,
        limits: CatalogStorageLimits(indexPageSize: 2, maxStoredBytes: bytes),
      );
      await exact.validate();
      final equalSize = await exact.patch(upserts: [_unit('a', version: 2)]);
      objects.addAll(equalSize.objects);
      final next = await equalSize.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      await next.validate();
      await expectLater(
        next.patch(
          upserts: [
            CatalogDefinitionUnit(
              key: _unit('a').key,
              payload: {..._unit('a').payload, 'extra': 0},
            ),
          ],
        ),
        throwsFormatException,
      );
      final tooSmall = await CatalogSnapshot.open(
        root: next.root,
        readObject: (r) async => objects[r.sha256]!,
        limits: CatalogStorageLimits(
          indexPageSize: 2,
          maxStoredBytes: bytes - 1,
        ),
      );
      await expectLater(tooSmall.patch(), throwsFormatException);
    },
  );

  test(
    'patch objects are immutable and emitted objects are all reachable',
    () async {
      final built = CatalogStorageBuilder(
        limits: CatalogStorageLimits(indexPageSize: 2),
      ).build([_unit('a'), _unit('b')]);
      final objects = {...built.objects};
      final snapshot = await _open(
        built,
        objects,
        limits: CatalogStorageLimits(indexPageSize: 2),
      );
      final patch = await snapshot.patch(
        upserts: [_unit('c'), _unit('d'), _unit('e')],
        removals: [_unit('a').key],
      );
      expect(() => patch.objects.clear(), throwsUnsupportedError);
      expect(() => patch.objects.values.first[0] = 0, throwsUnsupportedError);
      objects.addAll(patch.objects);
      final after = await patch.nextSnapshot(
        readObject: (r) async => objects[r.sha256]!,
      );
      final reachable = (await after.objectReferences())
          .map((r) => r.sha256)
          .toSet();
      expect(patch.objects.keys.every(reachable.contains), isTrue);
      expect(patch.objects.keys.any(built.objects.containsKey), isFalse);
      final preserved = (await after.lookup(_unit('b').key))!;
      expect(preserved.payload, _unit('b').payload);
    },
  );

  test('mutation input is bounded before reading the base', () async {
    final limits = CatalogStorageLimits(maxDefinitions: 1);
    final built = CatalogStorageBuilder(limits: limits).build([]);
    final reads = <String>[];
    final snapshot = await _open(
      built,
      {...built.objects},
      limits: limits,
      reads: reads,
    );
    reads.clear();
    await expectLater(
      snapshot.patch(upserts: [_unit('a'), _unit('b')]),
      throwsFormatException,
    );
    await expectLater(
      snapshot.patch(removals: [_unit('a').key, _unit('b').key]),
      throwsFormatException,
    );
    expect(reads, isEmpty);
  });
}
