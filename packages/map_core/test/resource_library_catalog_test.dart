import 'dart:collection';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('target validation visits each resource list once', () {
    final tilesets = _CountingList([
      for (var index = 0; index < 400; index++)
        ProjectTilesetEntry(
          id: 'tile-$index',
          name: 'Tile $index',
          relativePath: 'tile.png',
        ),
    ]);
    final project = ProjectManifest(
      name: 'Large classified project',
      maps: [],
      tilesets: tilesets,
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (var index = 0; index < 400; index++)
            ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: 'tile-$index',
            ),
        ],
      ),
    );
    tilesets.reads = 0;
    expect(() => validateResourceLibraryTargets(project), returnsNormally);
    expect(tilesets.reads, lessThanOrEqualTo(800));
    expect(
      resourceLibraryResourceExists(project, 'tileset', 'tile-399'),
      isTrue,
    );
    expect(
      resourceLibraryResourceExists(project, 'tileset', 'missing'),
      isFalse,
    );
    expect(
      resourceLibraryResourceExists(project, 'unsupported', 'tile-399'),
      isFalse,
    );
  });

  test(
    'individual descriptions roundtrip and distinguish resource identities',
    () {
      final base = {'resourceKind': 'element', 'resourceId': 'chair'};
      final entry = ResourceLibraryEntry.fromJson({
        ...base,
        'description': 'Chaise de cuisine.\nÀ placer près de la table.',
      });
      expect(
        entry.toJson()['description'],
        'Chaise de cuisine.\nÀ placer près de la table.',
      );
      expect(ResourceLibraryEntry.fromJson(entry.toJson()), entry);
      expect(entry, isNot(ResourceLibraryEntry.fromJson(base)));
      expect(
        ResourceLibraryEntry.fromJson({
          ...base,
          'description': null,
        }).toJson().containsKey('description'),
        isFalse,
      );
    },
  );

  test('description parsing rejects invalid text and types strictly', () {
    for (final value in ['', ' ', ' padded ', 'x' * 2001, 1, false, [], {}]) {
      expect(
        () => ResourceLibraryCatalog.fromJson({
          'formatVersion': 2,
          'families': [],
          'entries': [
            {
              'resourceKind': 'element',
              'resourceId': 'chair',
              'description': value,
            },
          ],
        }),
        throwsFormatException,
        reason: '$value',
      );
    }
  });

  test('context-only entry roundtrips independently from scope', () {
    final entry = ResourceLibraryEntry(
      resourceKind: 'element',
      resourceId: 'chair',
      placementContext: ResourcePlacementContext.interior,
    );
    final catalog = ResourceLibraryCatalog(entries: [entry]);
    expect(ResourceLibraryCatalog.fromJson(catalog.toJson()), catalog);
    expect(catalog.availableForMap('element', 'chair', 'outside'), isTrue);
  });

  test(
    'placement context values participate in strict codec equality and hash',
    () {
      final entries = [
        for (final context in ResourcePlacementContext.values)
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'chair',
            placementContext: context,
          ),
      ];
      for (final entry in entries) {
        final decoded = ResourceLibraryEntry.fromJson(entry.toJson());
        expect(decoded, entry);
        expect(decoded.hashCode, entry.hashCode);
        expect(
          entry.toJson()['placementContext'],
          entry.placementContext!.name,
        );
      }
      expect(entries.toSet(), hasLength(3));
      final unspecified = ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'chair',
      );
      expect(unspecified.toJson().containsKey('placementContext'), isFalse);
      expect(ResourceLibraryEntry.fromJson(unspecified.toJson()), unspecified);
      expect(
        ResourceLibraryEntry.fromJson({
          ...unspecified.toJson(),
          'placementContext': null,
        }),
        unspecified,
      );
      for (final value in ['unknown', '', ' interior ', 1, false, [], {}]) {
        expect(
          () => ResourceLibraryEntry.fromJson({
            ...unspecified.toJson(),
            'placementContext': value,
          }),
          throwsFormatException,
          reason: '$value',
        );
        expect(
          () => ResourceLibraryCatalog.fromJson({
            'formatVersion': 2,
            'families': [],
            'entries': [
              {...unspecified.toJson(), 'placementContext': value},
            ],
          }),
          throwsFormatException,
          reason: '$value',
        );
      }
    },
  );

  test('catalog v2 rejects v1 explicitly without migrating entries', () {
    expect(const ResourceLibraryCatalog.empty().toJson()['formatVersion'], 2);
    expect(
      () => ResourceLibraryCatalog.fromJson({
        'formatVersion': 1,
        'families': [],
        'entries': [],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('expected 2'),
        ),
      ),
    );
  });

  test(
    'component role is explicit persisted and independent from map scope',
    () {
      final component = ResourceLibraryEntry(
        resourceKind: 'model3d',
        resourceId: 'phase',
        role: ResourceLibraryRole.component,
      );
      final standard = ResourceLibraryEntry(
        resourceKind: 'model3d',
        resourceId: 'phase',
      );
      final catalog = ResourceLibraryCatalog(entries: [component]);
      expect(ResourceLibraryCatalog.fromJson(catalog.toJson()), catalog);
      expect(component.toJson()['role'], 'component');
      expect(standard.toJson().containsKey('role'), isFalse);
      expect(
        ResourceLibraryEntry.fromJson(standard.toJson()).role,
        ResourceLibraryRole.standard,
      );
      expect(component, isNot(standard));
      expect(catalog.availableForMap('model3d', 'phase', 'any-map'), isTrue);
      for (final role in [null, 'unknown', 2]) {
        expect(
          () => ResourceLibraryCatalog.fromJson({
            'formatVersion': 2,
            'families': [],
            'entries': [
              {...standard.toJson(), 'role': role},
            ],
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'empty catalog exposes immutable predefined families without inferred entries',
    () {
      const catalog = ResourceLibraryCatalog.empty();
      expect(catalog.families, isEmpty);
      expect(catalog.entries, isEmpty);
      expect(
        catalog.effectiveFamilies.map((family) => family.id),
        containsAll(['trees', 'ground', 'fences']),
      );
      expect(() => catalog.effectiveFamilies.clear(), throwsUnsupportedError);
    },
  );

  test('hierarchy resolves descendants and typed identities independently', () {
    final catalog = ResourceLibraryCatalog(
      families: [
        ResourceFamily(id: 'forest-a', name: 'Forêt A', parentId: 'trees'),
        ResourceFamily(id: 'conifers', name: 'Conifères', parentId: 'forest-a'),
      ],
      entries: [
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'tree',
          familyId: 'forest-a',
          mapId: 'route19',
        ),
        ResourceLibraryEntry(
          resourceKind: 'model3d',
          resourceId: 'tree',
          familyId: 'conifers',
        ),
      ],
    );
    expect(catalog.descendantFamilyIds('trees'), {
      'trees',
      'forest-a',
      'conifers',
    });
    expect(catalog.availableForMap('element', 'tree', 'route19'), isTrue);
    expect(catalog.availableForMap('element', 'tree', 'other'), isFalse);
    expect(catalog.availableForMap('model3d', 'tree', 'other'), isTrue);
    expect(catalog.availableForMap('element', 'unclassified', 'other'), isTrue);
    expect(ResourceLibraryCatalog.fromJson(catalog.toJson()), catalog);
  });

  test(
    'rejects missing parents cycles reserved roots and duplicate identities',
    () {
      for (final families in [
        [ResourceFamily(id: 'a', name: 'A', parentId: 'missing')],
        [
          ResourceFamily(id: 'a', name: 'A', parentId: 'b'),
          ResourceFamily(id: 'b', name: 'B', parentId: 'a'),
        ],
        [ResourceFamily(id: 'trees', name: 'Override')],
      ]) {
        expect(
          () => ResourceLibraryCatalog(families: families),
          throwsArgumentError,
        );
      }
      final entry = ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'same',
      );
      expect(
        () => ResourceLibraryCatalog(entries: [entry, entry]),
        throwsArgumentError,
      );
      expect(
        () => ResourceLibraryEntry(resourceKind: 'unknown', resourceId: 'same'),
        throwsArgumentError,
      );
    },
  );

  test('strict persistence rejects unknown fields and unsupported format', () {
    for (final json in [
      {'formatVersion': 3, 'families': [], 'entries': []},
      {'formatVersion': 2, 'families': [], 'entries': [], 'unknown': true},
      {
        'formatVersion': 2,
        'families': [
          {'id': 'a', 'name': 'A', 'extra': 1},
        ],
        'entries': [],
      },
    ]) {
      expect(
        () => ResourceLibraryCatalog.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test(
    'manifest roundtrip retains catalog and validates typed target and owner map',
    () {
      final project = ProjectManifest(
        name: 'Library',
        maps: const [
          ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
        ],
        tilesets: const [
          ProjectTilesetEntry(
            id: 'sheet',
            name: 'Sheet',
            relativePath: 'sheet.png',
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: 'sheet',
              familyId: 'ground',
              mapId: 'a',
            ),
          ],
        ),
      );
      expect(
        ProjectManifest.fromJson(project.toJson()).resourceLibraryCatalog,
        project.resourceLibraryCatalog,
      );
      expect(() => validateResourceLibraryTargets(project), returnsNormally);
      expect(
        () => validateResourceLibraryTargets(project.copyWith(maps: [])),
        throwsArgumentError,
      );
      expect(
        () => validateResourceLibraryTargets(project.copyWith(tilesets: [])),
        throwsArgumentError,
      );
      final empty = project.copyWith(
        resourceLibraryCatalog: const ResourceLibraryCatalog.empty(),
      );
      expect(empty.toJson().containsKey('resourceLibraryCatalog'), isFalse);
    },
  );
}

final class _CountingList<T> extends ListBase<T> {
  _CountingList(this.items);

  final List<T> items;
  int reads = 0;

  @override
  int get length => items.length;

  @override
  set length(int value) => throw UnsupportedError('Read only');

  @override
  T operator [](int index) {
    reads++;
    return items[index];
  }

  @override
  void operator []=(int index, T value) => throw UnsupportedError('Read only');
}
