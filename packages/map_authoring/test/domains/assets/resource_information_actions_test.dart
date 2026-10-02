import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';

ProjectManifest informationFixture() => ProjectManifest(
      name: 'Information',
      version: ProjectVersion.v8,
      maps: const [],
      tilesetFolders: const [
        ProjectTilesetFolder(id: 'shared', name: 'Images'),
        ProjectTilesetFolder(
            id: 'child', name: 'Enfant', parentFolderId: 'shared'),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'sheet',
          name: 'Planche',
          relativePath: 'assets/source.png',
          sortOrder: 7,
          folderId: 'shared',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'image',
            pixelWidth: 64,
            pixelHeight: 64,
            tileWidth: 32,
            tileHeight: 32,
          ),
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'shared', name: 'Décors'),
        ProjectElementCategory(id: 'other', name: 'Autres'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'decor',
          name: 'Décor',
          tilesetId: 'sheet',
          categoryId: 'shared',
          tags: ['préservé'],
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
        ),
      ],
    );

void main() {
  test('metadata name and folder preserve identity source and all other fields',
      () {
    final before = informationFixture();
    final snapshot = catalogSnapshot(const [], project: before);
    final result = const ResourceInformationActions().build(catalogContext(
      snapshot,
      'tileset.metadata.update',
      {
        'tilesetId': 'sheet',
        'name': '  Planche été du village  ',
        'folderId': null
      },
    ));
    final after = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(result.changeSet.changes.single.afterBytes!)));
    expect(after.tilesets.single.name, 'Planche été du village');
    expect(after.tilesets.single.folderId, isNull);
    final original = before.tilesets.single.toJson()
      ..remove('name')
      ..remove('folderId');
    final modified = after.tilesets.single.toJson()
      ..remove('name')
      ..remove('folderId');
    expect(modified, original);
    expect(after.elements, before.elements);
    expect(result.referenceImpact['pixelContentUnchanged'], true);
  });

  test('normalized identical metadata is a true no-op', () {
    final snapshot = catalogSnapshot(const [], project: informationFixture());
    final result = const ResourceInformationActions().build(catalogContext(
      snapshot,
      'tileset.metadata.update',
      {'tilesetId': 'sheet', 'name': '  Planche  ', 'folderId': 'shared'},
    ));
    expect(result.changeSet.changes, isEmpty);
  });

  test('metadata missing folder unsupported tags and invalid name refuse', () {
    final snapshot = catalogSnapshot(const [], project: informationFixture());
    for (final values in [
      {'tilesetId': 'sheet', 'name': 'Planche', 'folderId': 'missing'},
      {'tilesetId': 'missing', 'name': 'Planche', 'folderId': null},
      {'tilesetId': 'sheet', 'name': '  ', 'folderId': null},
      {
        'tilesetId': 'sheet',
        'name': 'Planche',
        'folderId': null,
        'tags': ['new']
      },
    ]) {
      expect(
          () => const ResourceInformationActions().build(catalogContext(
                snapshot,
                'tileset.metadata.update',
                values,
              )),
          throwsA(isA<VisualLibraryException>()));
    }
  });

  test('decor move touches only its category and refuses empty destination',
      () {
    final before = informationFixture();
    final snapshot = catalogSnapshot(const [], project: before);
    final result = const ResourceInformationActions().build(catalogContext(
      snapshot,
      'element.category.assign',
      {'elementId': 'decor', 'categoryId': 'other'},
    ));
    final after = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(result.changeSet.changes.single.afterBytes!)));
    expect(after.elements.single,
        before.elements.single.copyWith(categoryId: 'other'));
    expect(after.tilesets, before.tilesets);
    expect(
        () => const ResourceInformationActions().build(catalogContext(
              snapshot,
              'element.category.assign',
              {'elementId': 'decor', 'categoryId': ''},
            )),
        throwsA(isA<VisualLibraryException>()));
  });

  test('empty folder deletion preserves other taxonomy with same identity', () {
    final before = informationFixture();
    final after = const VisualOrganizationActions()
        .deleteTilesetFolder(before, folderId: 'child');
    expect(after.elementCategories, before.elementCategories);
    expect(after.tilesets, before.tilesets);
    expect(
        () => const VisualOrganizationActions()
            .deleteTilesetFolder(before, folderId: 'shared'),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.details['references'],
            'references',
            hasLength(2))));
  });

  test('same folder values are no-op without changing storage order', () {
    final before = informationFixture();
    final result = const VisualOrganizationActions().build(catalogContext(
      catalogSnapshot(const [], project: before),
      'tileset_folder.upsert',
      {'folder': before.tilesetFolders.first.toJson()},
    ));
    expect(result.changeSet.changes, isEmpty);
  });

  test('folder upsert refuses missing parent at canonical owner', () {
    expect(
      () => const VisualOrganizationActions().upsertTilesetFolder(
        informationFixture(),
        folder: const ProjectTilesetFolder(
            id: 'new', name: 'Nouveau', parentFolderId: 'missing'),
      ),
      throwsA(isA<VisualLibraryException>()),
    );
  });

  test('folder upsert refuses cycle at canonical owner', () {
    expect(
      () => const VisualOrganizationActions().upsertTilesetFolder(
        informationFixture(),
        folder: const ProjectTilesetFolder(
            id: 'shared', name: 'Images', parentFolderId: 'child'),
      ),
      throwsA(isA<VisualLibraryException>()),
    );
  });

  test('category upsert refuses missing parent at canonical owner', () {
    expect(
      () => const VisualOrganizationActions().upsertElementCategory(
        informationFixture(),
        category: const ProjectElementCategory(
            id: 'new', name: 'Nouveau', parentCategoryId: 'missing'),
      ),
      throwsA(isA<VisualLibraryException>()),
    );
  });
}
