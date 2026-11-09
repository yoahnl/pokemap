import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'preparation preserves legacy content and references follow replacements and removals',
    () async {
      final target = CatalogDefinitionKey(
        CatalogDefinitionKind.resourceFamily,
        'family',
      );
      final owner = CatalogDefinitionKey(
        CatalogDefinitionKind.element,
        'owner',
      );
      final original = CatalogStorageBuilder().build([
        CatalogDefinitionUnit(key: target, payload: {'name': 'Family'}),
        CatalogDefinitionUnit(key: owner, payload: {'name': 'Owner'}),
      ]);
      final objects = {...original.objects};
      var snapshot = await CatalogSnapshot.open(
        root: original.root,
        readObject: (ref) async => objects[ref.sha256]!,
      );
      expect(await CatalogReverseReferences.prepared(snapshot), isFalse);
      final prepared = await snapshot.prepareReverseReferences();
      objects.addAll(prepared.objects);
      snapshot = await prepared.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!,
      );
      expect((await snapshot.lookup(owner))!.payload['name'], 'Owner');
      expect((await snapshot.prepareReverseReferences()).isEmpty, isTrue);
      final linked = await snapshot.patch(
        upserts: [
          CatalogDefinitionUnit(
            key: owner,
            payload: {'name': 'Owner'},
            references: [target],
          ),
        ],
      );
      objects.addAll(linked.objects);
      snapshot = await linked.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!,
      );
      expect(await CatalogReverseReferences.consumers(snapshot, target), {
        owner,
      });
      await expectLater(
        snapshot.patch(removals: [target]),
        throwsFormatException,
      );
      final cleared = await snapshot.patch(
        upserts: [
          CatalogDefinitionUnit(key: owner, payload: {'name': 'Owner'}),
        ],
        removals: [target],
      );
      objects.addAll(cleared.objects);
      snapshot = await cleared.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!,
      );
      expect(
        await CatalogReverseReferences.consumers(snapshot, target),
        isEmpty,
      );
      expect(await snapshot.lookup(target), isNull);
      await snapshot.validate();
      final legacy = await CatalogSnapshot.open(
        root: original.root,
        readObject: (ref) async => objects[ref.sha256]!,
      );
      expect(await CatalogReverseReferences.prepared(legacy), isFalse);
      expect(await legacy.lookup(target), isNotNull);
    },
  );

  test(
    'an incomplete reverse index cannot be built or injected through a patch',
    () async {
      final target = CatalogDefinitionKey(
        CatalogDefinitionKind.resourceFamily,
        'family',
      );
      final units = [
        CatalogDefinitionUnit(key: target, payload: {'name': 'Family'}),
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(CatalogDefinitionKind.element, 'owner'),
          payload: {'name': 'Owner'},
          references: [target],
        ),
      ];
      final marker = CatalogDefinitionUnit(
        key: CatalogReverseReferences.marker,
        payload: {'schemaVersion': 1},
      );
      expect(
        () => CatalogStorageBuilder().build([...units, marker]),
        throwsFormatException,
      );
      final build = CatalogStorageBuilder().build(units);
      final snapshot = await CatalogSnapshot.open(
        root: build.root,
        readObject: (ref) async => build.objects[ref.sha256]!,
      );
      await expectLater(
        snapshot.patch(upserts: [marker]),
        throwsFormatException,
      );
    },
  );

  test(
    'removing an indexed family does not decode unrelated definitions',
    () async {
      final family = CatalogDefinitionUnit(
        key: CatalogDefinitionKey(
          CatalogDefinitionKind.resourceFamily,
          'empty',
        ),
        payload: {'name': 'Empty'},
      );
      final marker = CatalogDefinitionUnit(
        key: CatalogDefinitionKey(
          CatalogDefinitionKind.workspaceState,
          'reverseReferences',
        ),
        payload: {'schemaVersion': 1},
      );
      for (final count in [0, 300, 900]) {
        final built = CatalogStorageBuilder().build([
          family,
          marker,
          for (var i = 0; i < count; i++)
            CatalogDefinitionUnit(
              key: CatalogDefinitionKey(
                CatalogDefinitionKind.element,
                'unrelated-$i',
              ),
              payload: {'name': 'Unrelated $i'},
            ),
        ]);
        final decoded = <String>[];
        final snapshot = await CatalogSnapshot.open(
          root: built.root,
          readObject: (ref) async {
            final bytes = built.objects[ref.sha256]!;
            final json = jsonDecode(utf8.decode(bytes)) as Map;
            if (json['type'] == 'unit') decoded.add('${json['key']['id']}');
            return bytes;
          },
        );
        await snapshot.validate();
        decoded.clear();
        await snapshot.patch(removals: [family.key]);
        expect(decoded.where((id) => id.startsWith('unrelated-')), isEmpty);
      }
    },
  );
}
