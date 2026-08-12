import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('indexes normalized definitions from first to last and missing', () {
    final snapshot = ItemCatalogSnapshot.fromCatalog(
      ProjectItemCatalog(
        schemaVersion: 1,
        entries: <ProjectItemDefinition>[
          for (var index = 0; index < 5000; index++)
            ProjectItemDefinition(
              id: ' item_${index.toString().padLeft(4, '0')} ',
              displayName: 'Item $index',
              pocketId: 'items',
            ),
        ],
      ),
    );

    expect(snapshot.definitionFor('item_0000')?.displayName, 'Item 0');
    expect(snapshot.definitionFor(' item_2500 ')?.displayName, 'Item 2500');
    expect(snapshot.definitionFor('item_4999')?.displayName, 'Item 4999');
    expect(snapshot.definitionFor('missing'), isNull);
    expect(snapshot.definitions, hasLength(5000));
  });

  test('owns an immutable normalized catalog and rejects duplicate ids', () {
    final sourceEntries = <ProjectItemDefinition>[
      const ProjectItemDefinition(
        id: ' potion ',
        displayName: 'Potion',
        pocketId: 'medicine',
      ),
    ];
    final snapshot = ItemCatalogSnapshot.fromCatalog(
      ProjectItemCatalog(schemaVersion: 1, entries: sourceEntries),
    );
    sourceEntries.add(
      const ProjectItemDefinition(
        id: 'ether',
        displayName: 'Ether',
        pocketId: 'medicine',
      ),
    );

    expect(snapshot.definitionFor('potion')?.id, 'potion');
    expect(snapshot.definitionFor('ether'), isNull);
    expect(
      () => snapshot.catalog.entries.add(sourceEntries.last),
      throwsUnsupportedError,
    );
    expect(
      () => ItemCatalogSnapshot.fromCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: <ProjectItemDefinition>[
            ProjectItemDefinition(
              id: 'duplicate',
              displayName: 'First',
              pocketId: 'items',
            ),
            ProjectItemDefinition(
              id: ' duplicate ',
              displayName: 'Second',
              pocketId: 'items',
            ),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test('definition lookup remains a direct immutable map access', () {
    final source = File(
      'lib/src/items/item_catalog_snapshot.dart',
    ).readAsStringSync();
    final lookup = RegExp(
      r'ProjectItemDefinition\? definitionFor\(String itemId\)\s*=>\s*([^;]+);',
    ).firstMatch(source);

    expect(lookup, isNotNull);
    expect(lookup!.group(1), contains('_definitionsById[itemId.trim()]'));
    expect(lookup.group(1), isNot(contains('catalog.entries')));
    expect(lookup.group(1), isNot(contains('firstWhere')));
  });
}
