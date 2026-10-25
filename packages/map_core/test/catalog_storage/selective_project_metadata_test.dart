import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final missing in [0, 1]) {
    test(
      'selected definition lists reject a missing position $missing before their tail',
      () async {
        final built = PortableCatalogPublication.encodeProject(
          ProjectManifest(
            name: 'Gap',
            maps: const [],
            tilesets: const [],
            groups: [
              for (var index = 0; index < 3; index++)
                ProjectMapGroup(
                  id: 'group-$index',
                  name: 'Group $index',
                  type: MapGroupType.city,
                ),
            ],
          ),
        );
        final original = PortableCatalogPublication.readSync(
          built.descriptor,
          readObject: (reference) => built.storage.objects[reference.sha256]!,
        );
        final changed = CatalogStorageBuilder().build(
          original.units.where(
            (unit) =>
                unit.payload['section'] != r'$projectDefinition' ||
                unit.payload['position'] != missing,
          ),
        );
        await expectLater(
          PortableProjectCatalog.open(
            {...built.descriptor, 'root': changed.root.toJson()},
            metadataFields: {'groups'},
            readObject: (reference) async => changed.objects[reference.sha256]!,
          ),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'selected aggregates reject chunks surviving beyond a missing header and first chunk',
    () async {
      final built = PortableCatalogPublication.encodeProject(
        ProjectManifest(
          name: 'Orphan',
          maps: const [],
          tilesets: const [],
          globalProperties: {'payload': 'x' * 150000},
        ),
      );
      final original = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (reference) => built.storage.objects[reference.sha256]!,
      );
      final changed = CatalogStorageBuilder().build(
        original.units.where(
          (unit) =>
              unit.payload['section'] != r'$projectAggregateHeader' &&
              (unit.payload['section'] != r'$projectAggregateChunk' ||
                  unit.payload['position'] != 0),
        ),
      );
      await expectLater(
        PortableProjectCatalog.open(
          {...built.descriptor, 'root': changed.root.toJson()},
          metadataFields: {'globalProperties'},
          readObject: (reference) async => changed.objects[reference.sha256]!,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'selected units retain digest, identity and aggregate completeness checks',
    () async {
      final built = PortableCatalogPublication.encodeProject(
        ProjectManifest(
          name: 'Integrity',
          maps: const [],
          tilesets: const [],
          globalProperties: {'selected': 'x' * 150000},
          groups: const [
            ProjectMapGroup(
              id: 'group',
              name: 'Group',
              type: MapGroupType.city,
            ),
          ],
        ),
      );
      final original = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (reference) => built.storage.objects[reference.sha256]!,
      );
      for (final omitted in [
        r'$projectAggregateHeader',
        r'$projectAggregateChunk',
      ]) {
        final changed = CatalogStorageBuilder().build(
          original.units.where(
            (unit) =>
                unit.payload['section'] != omitted ||
                unit.payload['position'] != 0,
          ),
        );
        await expectLater(
          PortableProjectCatalog.open(
            {...built.descriptor, 'root': changed.root.toJson()},
            metadataFields: {'globalProperties'},
            readObject: (reference) async => changed.objects[reference.sha256]!,
          ),
          throwsFormatException,
        );
      }
      final mismatched = CatalogStorageBuilder().build(
        original.units.map(
          (unit) => unit.payload['section'] != r'$projectDefinition'
              ? unit
              : CatalogDefinitionUnit(
                  key: unit.key,
                  references: unit.references,
                  payload: {
                    ...unit.payload,
                    'value': {
                      ...unit.payload['value']! as Map<String, Object?>,
                      'field': 'dialogueFolders',
                    },
                  },
                ),
        ),
      );
      await expectLater(
        PortableProjectCatalog.open(
          {...built.descriptor, 'root': mismatched.root.toJson()},
          metadataFields: {'groups'},
          readObject: (reference) async =>
              mismatched.objects[reference.sha256]!,
        ),
        throwsFormatException,
      );
      await expectLater(
        PortableProjectCatalog.open(
          built.descriptor,
          metadataFields: {'groups'},
          readObject: (reference) async {
            final bytes = built.storage.objects[reference.sha256]!;
            final object = jsonDecode(utf8.decode(bytes)) as Map;
            if (object['type'] == 'unit' &&
                (object['payload'] as Map)['section'] ==
                    r'$projectDefinition') {
              return [...bytes.take(bytes.length - 1), 32];
            }
            return bytes;
          },
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'scoped global properties retain dynamic declarations without unrelated units',
    () async {
      final owner = CatalogDefinitionKey(
        CatalogDefinitionKind.tileset,
        'owner',
      );
      final target = CatalogDefinitionKey(
        CatalogDefinitionKind.tileset,
        'target',
      );
      final project = PortableCatalogPublication.withProjectDynamicDependencies(
        ProjectManifest(
          name: 'Dynamic',
          maps: const [],
          tilesets: [
            for (final id in ['owner', 'target'])
              ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
          ],
          dialogueFolders: [
            for (var index = 0; index < 250; index++)
              ProjectDialogueFolder(id: 'folder-$index', name: 'Folder $index'),
          ],
        ),
        [
          CatalogDynamicDependency(owner: owner, targets: [target]),
        ],
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final sections = <String>[];
      final catalog = await PortableProjectCatalog.open(
        built.descriptor,
        metadataFields: {'globalProperties'},
        readObject: (reference) async {
          final bytes = built.storage.objects[reference.sha256]!;
          final object = jsonDecode(utf8.decode(bytes)) as Map;
          if (object['type'] == 'unit') {
            sections.add((object['payload'] as Map)['section'] as String);
          }
          return bytes;
        },
      );
      expect(
        catalog.projectMetadata.globalProperties,
        project.globalProperties,
      );
      expect(sections, [
        r'$shell',
        'globalProperties.${PortableCatalogPublication.projectDynamicDependenciesKey}',
      ]);
    },
  );
  test(
    'scoped metadata reads only requested definitions and aggregates',
    () async {
      for (final unrelatedCount in [0, 900]) {
        final project = ProjectManifest(
          name: 'Scoped project',
          maps: const [],
          tilesets: const [],
          groups: const [
            ProjectMapGroup(
              type: MapGroupType.city,
              id: 'selected',
              name: 'Selected',
            ),
          ],
          dialogueFolders: [
            for (var index = 0; index < unrelatedCount; index++)
              ProjectDialogueFolder(id: 'folder-$index', name: 'Folder $index'),
          ],
          globalProperties: {'unrelated': 'x' * 200000},
        );
        final built = PortableCatalogPublication.encodeProject(project);
        final unitsRead = <Map>[];
        for (var attempt = 0; attempt < 2; attempt++) {
          unitsRead.clear();
          var objectReads = 0;
          final catalog = await PortableProjectCatalog.open(
            built.descriptor,
            metadataFields: {'groups'},
            readObject: (reference) async {
              objectReads++;
              final bytes = built.storage.objects[reference.sha256]!;
              final object = jsonDecode(utf8.decode(bytes)) as Map;
              if (object['type'] == 'unit') unitsRead.add(object);
              return bytes;
            },
          );
          expect(catalog.projectMetadata.groups, project.groups);
          expect(catalog.projectMetadata.dialogueFolders, isEmpty);
          expect(catalog.projectMetadata.globalProperties, isEmpty);
          expect(unitsRead, hasLength(2));
          expect(objectReads, lessThanOrEqualTo(12));
        }
      }
    },
  );

  test('requested aggregates retain bytes and reject corruption', () async {
    final project = ProjectManifest(
      name: 'Aggregate',
      maps: const [],
      tilesets: const [],
      globalProperties: {'selected': 'x' * 150000},
    );
    final built = PortableCatalogPublication.encodeProject(project);
    final catalog = await PortableProjectCatalog.open(
      built.descriptor,
      metadataFields: {'globalProperties'},
      readObject: (reference) async => built.storage.objects[reference.sha256]!,
    );
    expect(catalog.projectMetadata.globalProperties, project.globalProperties);
    final original = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (reference) => built.storage.objects[reference.sha256]!,
    );
    final changed = CatalogStorageBuilder().build(
      original.units.map((unit) {
        if (unit.payload['section'] != r'$projectAggregateHeader') return unit;
        return CatalogDefinitionUnit(
          key: unit.key,
          references: unit.references,
          payload: {
            ...unit.payload,
            'value': <String, Object?>{
              ...unit.payload['value']! as Map<String, Object?>,
              'sha256': '0' * 64,
            },
          },
        );
      }),
    );
    await expectLater(
      PortableProjectCatalog.open(
        {...built.descriptor, 'root': changed.root.toJson()},
        metadataFields: {'globalProperties'},
        readObject: (reference) async => changed.objects[reference.sha256]!,
      ),
      throwsFormatException,
    );
  });

  test('scoped metadata preserves inline legacy fields and defaults', () async {
    final project = ProjectManifest(
      name: 'Legacy',
      maps: const [],
      tilesets: const [],
      groups: const [
        ProjectMapGroup(type: MapGroupType.city, id: 'legacy', name: 'Legacy'),
      ],
    );
    final built = PortableCatalogPublication.encodeProject(project);
    final original = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (reference) => built.storage.objects[reference.sha256]!,
    );
    final storage = CatalogStorageBuilder().build(
      original.units
          .where((unit) => unit.payload['section'] != r'$projectDefinition')
          .map(
            (unit) => unit.payload['section'] != r'$shell'
                ? unit
                : CatalogDefinitionUnit(
                    key: unit.key,
                    references: unit.references,
                    payload: {
                      ...unit.payload,
                      'value': <String, Object?>{
                        ...unit.payload['value']! as Map<String, Object?>,
                        'groups': [
                          for (final group in project.groups) group.toJson(),
                        ],
                      },
                    },
                  ),
          ),
    );
    final catalog = await PortableProjectCatalog.open(
      {...built.descriptor, 'root': storage.root.toJson()},
      metadataFields: {'groups'},
      readObject: (reference) async => storage.objects[reference.sha256]!,
    );
    expect(catalog.projectMetadata.groups, project.groups);
    expect(catalog.projectMetadata.name, project.name);
    expect(catalog.projectMetadata.settings, project.settings);
  });

  test(
    'default open and explicit export keep complete historical behavior',
    () async {
      final project = ProjectManifest(
        name: 'Full',
        maps: const [],
        tilesets: const [],
        groups: const [
          ProjectMapGroup(type: MapGroupType.city, id: 'group', name: 'Group'),
        ],
        globalProperties: {'preserved': 'value'},
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final full = await PortableProjectCatalog.open(
        built.descriptor,
        readObject: (reference) async =>
            built.storage.objects[reference.sha256]!,
      );
      expect(full.projectMetadata.toJson(), project.toJson());
      final scoped = await PortableProjectCatalog.fromSnapshot(
        full.snapshot,
        metadataFields: {},
      );
      expect(scoped.projectMetadata.groups, isEmpty);
      expect((await scoped.exportProject()).toJson(), project.toJson());
    },
  );

  test('unknown scoped fields fail explicitly', () async {
    final built = PortableCatalogPublication.encodeProject(
      ProjectManifest(name: 'Unknown', maps: const [], tilesets: const []),
    );
    await expectLater(
      PortableProjectCatalog.open(
        built.descriptor,
        metadataFields: {'typo'},
        readObject: (reference) async =>
            built.storage.objects[reference.sha256]!,
      ),
      throwsArgumentError,
    );
  });
}
