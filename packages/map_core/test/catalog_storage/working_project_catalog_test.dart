import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'the first classification can be appended to an empty catalog',
    () async {
      final build = PortableCatalogPublication.encodeProject(
        ProjectManifest(name: 'Game', maps: const [], tilesets: const []),
      );
      final objects = {...build.storage.objects};
      final snapshot = await CatalogSnapshot.open(
        root: build.storage.root,
        readObject: (reference) async => objects[reference.sha256]!,
      );
      final catalog = await PortableProjectCatalog.fromSnapshot(snapshot);
      final patch = await snapshot.patch(
        upserts: [
          catalog.createResourceLibraryEntryUnit(
            ResourceLibraryEntry(resourceKind: 'element', resourceId: 'a'),
            position: 0,
          ),
        ],
      );
      objects.addAll(patch.objects);
      final next = await PortableProjectCatalog.fromSnapshot(
        await patch.nextSnapshot(
          readObject: (reference) async => objects[reference.sha256]!,
        ),
      );
      final selected = await next.lookup(
        CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          'element:a',
        ),
      );
      expect(
        next.projectWithDefinitions([selected!]).resourceLibraryCatalog.entries,
        hasLength(1),
      );
      expect(
        (await next.exportProject())
            .resourceLibraryCatalog
            .entries
            .single
            .resourceId,
        'a',
      );
    },
  );
  test(
    'classification append keeps physical positions and exports canonical identities',
    () async {
      final project = ProjectManifest(
        name: 'Game',
        maps: const [],
        tilesets: const [],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(resourceKind: 'element', resourceId: 'z'),
          ],
        ),
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final objects = {...build.storage.objects};
      final snapshot = await CatalogSnapshot.open(
        root: build.storage.root,
        readObject: (reference) async => objects[reference.sha256]!,
      );
      final catalog = await PortableProjectCatalog.fromSnapshot(snapshot);
      final added = catalog.createResourceLibraryEntryUnit(
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'a',
          placementContext: ResourcePlacementContext.exterior,
        ),
        position: 1,
      );
      final patch = await snapshot.patch(upserts: [added]);
      objects.addAll(patch.objects);
      final next = await PortableProjectCatalog.fromSnapshot(
        await patch.nextSnapshot(
          readObject: (reference) async => objects[reference.sha256]!,
        ),
      );
      final exported = await next.exportProject();
      expect(
        exported.resourceLibraryCatalog.entries.map(
          (entry) => entry.resourceId,
        ),
        ['a', 'z'],
      );
      final original = await next.lookup(
        CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          'element:z',
        ),
      );
      expect(original!.payload['position'], 0);
    },
  );
  test('working descriptor is strict and has no second mutable root', () {
    final descriptor = WorkingProjectCatalogDescriptor(projectId: 'game');
    expect(descriptor.toJson(), {
      'format': 'avelune.working-catalog',
      'version': 1,
      'kind': 'project',
      'projectId': 'game',
    });
    expect(
      () => WorkingProjectCatalogDescriptor.fromJson({
        ...descriptor.toJson(),
        'root': {},
      }),
      throwsFormatException,
    );
  });

  test(
    'typed replacement preserves position and rejects changed identity',
    () async {
      final project = ProjectManifest(
        name: 'Game',
        maps: const [],
        tilesets: [
          const ProjectTilesetEntry(
            id: 'tile',
            name: 'Before',
            relativePath: 'tile.png',
          ),
        ],
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final snapshot = await CatalogSnapshot.open(
        root: build.storage.root,
        readObject: (reference) async =>
            build.storage.objects[reference.sha256]!,
      );
      final catalog = await PortableProjectCatalog.fromSnapshot(snapshot);
      final current = (await catalog.lookup(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile'),
      ))!;
      final value = Map<String, Object?>.from(current.payload['value']! as Map);
      final next = catalog.replaceDefinitionValue(current, {
        ...value,
        'name': 'After',
      });
      expect(next.payload['position'], current.payload['position']);
      expect(next.key, current.key);
      expect((next.payload['value']! as Map)['name'], 'After');
      expect(
        () =>
            catalog.replaceDefinitionValue(current, {...value, 'id': 'other'}),
        throwsFormatException,
      );
      expect(
        () => catalog.replaceDefinitionValue(current, {
          ...value,
          'tileWidth': 'bad',
        }),
        throwsA(anything),
      );
      expect((await catalog.exportProject()).tilesets.single.name, 'Before');
    },
  );
}
