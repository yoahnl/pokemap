import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
            'formatVersion': 1,
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
      {'formatVersion': 2, 'families': [], 'entries': []},
      {'formatVersion': 1, 'families': [], 'entries': [], 'unknown': true},
      {
        'formatVersion': 1,
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
