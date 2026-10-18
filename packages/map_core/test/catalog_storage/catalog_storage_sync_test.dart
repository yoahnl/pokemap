import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/src/catalog_storage/catalog_storage.dart';
import 'package:test/test.dart';

void main() {
  CatalogDefinitionUnit unit(String id) => CatalogDefinitionUnit(
    key: CatalogDefinitionKey(CatalogDefinitionKind.element, id),
    payload: {'id': id},
  );

  test('synchronous full admission accepts a copy on write index', () async {
    final limits = CatalogStorageLimits(indexPageSize: 2);
    final built = CatalogStorageBuilder(
      limits: limits,
    ).build([unit('a'), unit('c')]);
    final objects = {...built.objects};
    final snapshot = await CatalogSnapshot.open(
      root: built.root,
      readObject: (r) async => objects[r.sha256]!,
      limits: limits,
    );
    final patch = await snapshot.patch(
      upserts: [unit('b'), unit('d'), unit('e')],
    );
    objects.addAll(patch.objects);
    final read = CatalogSnapshot.readAllSync(
      root: patch.root,
      readObject: (r) => objects[r.sha256]!,
      limits: limits,
    );
    expect(read.units.map((u) => u.key.id), ['a', 'b', 'c', 'd', 'e']);
    expect(
      read.storedBytes,
      read.objectReferences.fold<int>(0, (s, r) => s + r.byteLength),
    );
    expect(
      () => CatalogSnapshot.readAllSync(
        root: patch.root,
        readObject: (r) => objects[r.sha256]!,
        limits: CatalogStorageLimits(
          indexPageSize: 2,
          maxStoredBytes: read.storedBytes - 1,
        ),
      ),
      throwsFormatException,
    );
    final damaged = {
      ...objects,
      patch.root.sha256: <int>[0],
    };
    expect(
      () => CatalogSnapshot.readAllSync(
        root: patch.root,
        readObject: (r) => damaged[r.sha256]!,
      ),
      throwsFormatException,
    );
  });
  test('sync admission refuses rehashed malformed index and dangling edge', () {
    final built = CatalogStorageBuilder().build([unit('a'), unit('b')]);
    for (final malformedIndex in [false, true]) {
      final objects = {...built.objects};
      CatalogObjectReference put(Object? value) {
        Object? canonical(Object? v) {
          if (v is Map<String, Object?>) {
            return {
              for (final key in (v.keys.toList()..sort()))
                key: canonical(v[key]),
            };
          }
          if (v is List) return v.map(canonical).toList();
          return v;
        }

        final bytes = utf8.encode(jsonEncode(canonical(value)));
        final reference = CatalogObjectReference(
          sha256: crypto.sha256.convert(bytes).toString(),
          byteLength: bytes.length,
        );
        objects[reference.sha256] = bytes;
        return reference;
      }

      final root =
          jsonDecode(utf8.decode(objects[built.root.sha256]!))
              as Map<String, dynamic>;
      final index = root['index'] as Map<String, dynamic>;
      final leafReference = CatalogObjectReference.fromJson(
        index['reference'] as Map<String, dynamic>,
      );
      final leaf =
          jsonDecode(utf8.decode(objects[leafReference.sha256]!))
              as Map<String, dynamic>;
      final entries = leaf['entries'] as List;
      if (malformedIndex) {
        leaf['entries'] = entries.reversed.toList();
      } else {
        final entry = entries.first as Map<String, dynamic>;
        final ref = CatalogObjectReference.fromJson(
          entry['reference'] as Map<String, dynamic>,
        );
        final definition =
            jsonDecode(utf8.decode(objects[ref.sha256]!))
                as Map<String, dynamic>;
        definition['references'] = [
          CatalogDefinitionKey(
            CatalogDefinitionKind.element,
            'missing',
          ).toJson(),
        ];
        entry['reference'] = put(definition).toJson();
      }
      index['reference'] = put(leaf).toJson();
      final forgedRoot = put(root);
      expect(
        () => CatalogSnapshot.readAllSync(
          root: forgedRoot,
          readObject: (r) => objects[r.sha256]!,
        ),
        throwsFormatException,
      );
    }
  });
}
