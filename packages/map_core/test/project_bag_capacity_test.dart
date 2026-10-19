import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('unlimited default is omitted from project JSON', () {
    const manifest = ProjectManifest(name: 'Capacity', maps: [], tilesets: []);
    expect(manifest.bagCapacity.isUnlimited, isTrue);
    expect(manifest.toJson(), isNot(contains('bagCapacity')));
    expect(
      ProjectManifest.fromJson(manifest.toJson()).bagCapacity.isUnlimited,
      isTrue,
    );
  });

  test('limits round trip independently for arbitrary pocket identifiers', () {
    final capacity = ProjectBagCapacity.fromJson({
      'pockets': {
        'supplies': {'maxDistinctItems': 20, 'maxQuantityPerItem': 99},
        'documents': {'maxDistinctItems': null, 'maxQuantityPerItem': 1},
        'miscellaneous': {},
      },
    });
    expect(capacity.pockets.keys, ['supplies', 'documents']);
    expect(capacity.pockets['supplies']!.maxDistinctItems, 20);
    expect(capacity.pockets['documents']!.maxDistinctItems, isNull);
    final manifest = ProjectManifest(
      name: 'Capacity',
      maps: [],
      tilesets: [],
      bagCapacity: capacity,
    );
    expect(ProjectManifest.fromJson(manifest.toJson()).bagCapacity, capacity);
    expect(capacity.toJson(), {
      'pockets': {
        'supplies': {'maxDistinctItems': 20, 'maxQuantityPerItem': 99},
        'documents': {'maxQuantityPerItem': 1},
      },
    });
  });

  for (final key in ['maxDistinctItems', 'maxQuantityPerItem']) {
    for (final value in [0, -1, 1.0, '20', true, maximumBagEntryQuantity + 1]) {
      test('rejects $key $value (${value.runtimeType})', () {
        expect(
          () => ProjectBagCapacity.fromJson({
            'pockets': {
              'supplies': {key: value},
            },
          }),
          throwsFormatException,
        );
      });
    }
  }

  for (final json in <Map<String, dynamic>>[
    {'weight': 10},
    {'pockets': null},
    {'pockets': []},
    {
      'pockets': {
        '': {'maxDistinctItems': 2},
      },
    },
    {
      'pockets': {
        ' supplies ': {'maxDistinctItems': 2},
      },
    },
    {
      'pockets': {'supplies': null},
    },
    {
      'pockets': {
        'supplies': {'maxWeight': 2},
      },
    },
  ]) {
    test('rejects invalid configuration $json', () {
      expect(() => ProjectBagCapacity.fromJson(json), throwsFormatException);
    });
  }

  test('constructor configuration validates before serialization', () {
    const capacity = ProjectBagCapacity(
      pockets: {'supplies': BagPocketCapacity(maxDistinctItems: 0)},
    );
    expect(capacity.toJson, throwsFormatException);
  });

  test('explicit null manifest configuration is rejected', () {
    const manifest = ProjectManifest(name: 'Capacity', maps: [], tilesets: []);
    expect(
      () =>
          ProjectManifest.fromJson({...manifest.toJson(), 'bagCapacity': null}),
      throwsFormatException,
    );
  });

  test(
    'bag validation reports both violations without truncating its contents',
    () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'tonic', quantity: 100),
          BagEntry(itemId: 'herb', quantity: 1),
        ],
      );
      const capacity = ProjectBagCapacity(
        pockets: {
          'supplies': BagPocketCapacity(
            maxDistinctItems: 1,
            maxQuantityPerItem: 99,
          ),
        },
      );
      const catalog = ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'tonic',
            displayName: 'Tonic',
            pocketId: 'supplies',
          ),
          ProjectItemDefinition(
            id: 'herb',
            displayName: 'Herb',
            pocketId: 'supplies',
          ),
        ],
      );
      final issues = validateBagCapacity(
        bag: bag,
        capacity: capacity,
        itemCatalog: catalog,
        path: r'$.newGame.initialBag',
      );
      expect(
        issues.map((i) => i.code),
        containsAll(['bag.capacity.stackFull', 'bag.capacity.pocketFull']),
      );
      expect(
        issues.every((i) => i.path.startsWith(r'$.newGame.initialBag')),
        isTrue,
      );
      expect(
        issues.singleWhere((i) => i.code == 'bag.capacity.stackFull').path,
        r'$.newGame.initialBag.entries[0].quantity',
      );
      expect(bag.entries.first.quantity, 100);
      expect(bag.entries, hasLength(2));
    },
  );

  for (final reversed in [false, true]) {
    for (final duplicateId in ['tonic', ' tonic ']) {
      test(
        'duplicate catalog identity is rejected: reversed=$reversed id=$duplicateId',
        () {
          const bag = Bag(entries: [BagEntry(itemId: 'tonic', quantity: 100)]);
          const capacity = ProjectBagCapacity(
            pockets: {'supplies': BagPocketCapacity(maxQuantityPerItem: 99)},
          );
          final definitions = [
            const ProjectItemDefinition(
              id: 'tonic',
              displayName: 'Tonic',
              pocketId: 'supplies',
            ),
            ProjectItemDefinition(
              id: duplicateId,
              displayName: 'Other tonic',
              pocketId: 'documents',
            ),
          ];
          final catalog = ProjectItemCatalog(
            schemaVersion: 1,
            entries: reversed ? definitions.reversed.toList() : definitions,
          );
          final issues = validateBagCapacity(
            bag: bag,
            capacity: capacity,
            itemCatalog: catalog,
          );
          expect(issues, hasLength(1));
          expect(issues.single.code, 'bag.capacity.invalidItemCatalog');
          expect(issues.single.itemId, 'tonic');
          expect(issues.single.message, contains('duplicate'));
          expect(bag.entries.single.quantity, 100);
          expect(catalog.entries, hasLength(2));
        },
      );
    }
  }

  test('validation is honest about missing or unknown catalog entries', () {
    const bag = Bag(entries: [BagEntry(itemId: 'unknown', quantity: 1)]);
    const capacity = ProjectBagCapacity(
      pockets: {'supplies': BagPocketCapacity(maxDistinctItems: 1)},
    );
    expect(
      validateBagCapacity(
        bag: bag,
        capacity: capacity,
        itemCatalog: null,
      ).single.code,
      'bag.capacity.missingItemCatalog',
    );
    expect(
      validateBagCapacity(
        bag: bag,
        capacity: capacity,
        itemCatalog: const ProjectItemCatalog(schemaVersion: 1, entries: []),
      ).single.code,
      'bag.capacity.unknownItem',
    );
    expect(
      validateBagCapacity(
        bag: bag,
        capacity: const ProjectBagCapacity.unlimited(),
        itemCatalog: null,
      ),
      isEmpty,
    );
  });
}
