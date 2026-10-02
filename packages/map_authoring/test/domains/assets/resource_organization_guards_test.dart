import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_information_fixture.dart';
import 'resource_information_actions_test.dart' show informationFixture;

AuthoringMutationDraft organize(ProjectManifest manifest, String action,
        Map<String, Object?> parameters) =>
    const ResourceManagementActions().analyze(catalogContext(
        catalogSnapshot(const [], project: manifest), action, parameters));

ProjectManifest projected(AuthoringMutationDraft draft) =>
    ProjectManifest.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!)));

void main() {
  test('all three taxonomies create rename delete empty with stable ownership',
      () {
    for (final family in [
      'tileset_folder',
      'element_category',
      'smart_tile.category'
    ]) {
      final field = family == 'tileset_folder' ? 'folder' : 'category';
      final created =
          projected(organize(smartInformationFixture(), '$family.upsert', {
        field: {'id': 'empty', 'name': ' Dépôt été ', 'sortOrder': 12},
      }));
      final renamed = projected(organize(created, '$family.upsert', {
        field: {'id': 'empty', 'name': 'Façades', 'sortOrder': 12},
      }));
      final removed = projected(organize(renamed, '$family.delete', {
        '${field}Id': 'empty',
      }));
      expect(removed, smartInformationFixture());
    }
  });

  test('folder parent relocation preserves IDs and other container order', () {
    final manifest = informationFixture();
    final result = projected(organize(manifest, 'tileset_folder.upsert', {
      'folder': manifest.tilesetFolders.last
          .copyWith(parentFolderId: null, sortOrder: 8)
          .toJson(),
    }));
    expect(result.tilesetFolders.last.parentFolderId, isNull);
    expect(result.tilesetFolders.last.id, 'child');
    expect(result.tilesetFolders.first, manifest.tilesetFolders.first);
    expect(result.tilesets, manifest.tilesets);
  });

  test('occupied decor container returns actual resource identities', () {
    expect(
        () => organize(informationFixture(), 'element_category.delete',
            {'categoryId': 'shared'}),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.details['references'],
            'references',
            ['element:decor'])));
  });

  test('families permit homonyms without treating them as identity', () {
    final after =
        projected(organize(informationFixture(), 'tileset_folder.upsert', {
      'folder': {'id': 'homonym', 'name': 'Images'},
    }));
    expect(after.tilesetFolders.where((entry) => entry.name == 'Images').length,
        2);
    expect(after.elementCategories.first.id, 'shared');
  });

  test('strict folder fields reject unexpected hierarchy and noninteger order',
      () {
    for (final object in [
      {'id': 'new', 'name': 'Nouveau', 'sortOrder': 1.5},
      {'id': 'new', 'name': 'Nouveau', 'parentFolderId': ''},
      {
        'id': 'new',
        'name': 'Nouveau',
        'tags': ['injected']
      },
    ]) {
      expect(
          () => organize(informationFixture(), 'tileset_folder.upsert',
              {'folder': object}),
          throwsA(isA<VisualLibraryException>()));
    }
  });

  test('Smart Tile taxonomy remains flat and cannot receive folder parent', () {
    expect(
        () =>
            organize(smartInformationFixture(), 'smart_tile.category.upsert', {
              'category': {
                'id': 'new',
                'name': 'Nouveau',
                'parentFolderId': 'shared'
              },
            }),
        throwsA(isA<VisualLibraryException>()));
  });

  test('terrain category removal blocks persisted draft material references',
      () {
    final original = smartInformationFixture();
    final draft = original.smartTileCatalog.drafts.single
        .copyWith(categoryId: '', materials: [
      const ProjectSmartTileMaterial(
          id: 'draft-material',
          name: 'Brouillon',
          connectionGroupId: 'draft',
          categoryId: 'shared')
    ]);
    final withoutPublishedUses = original.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
      categories: original.smartTileCatalog.categories,
      drafts: [draft],
    ));
    expect(
        () => organize(withoutPublishedUses, 'smart_tile.category.delete',
            {'categoryId': 'shared'}),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.details['references'],
            'references',
            ['smartTileDraft:editing:material:draft-material'])));
  });

  test('same published terrain destination does not change persisted draft',
      () {
    final result = organize(
        smartInformationFixture(),
        'smart_tile.preset.category.assign',
        {'presetId': 'ground', 'categoryId': 'shared'});
    expect(result.changeSet.changes, isEmpty);
  });

  test(
      'schema exposes explicit null folder and keeps read-only identity fields absent',
      () {
    final descriptor = ResourceInformationActions.descriptors.first;
    final schema = descriptor.extensions['inputSchema'] as Map;
    final properties = schema['properties'] as Map;
    expect((properties['folderId'] as Map)['type'], ['string', 'null']);
    expect(properties.keys.toSet(), {'tilesetId', 'name', 'folderId'});
    expect(properties, isNot(contains('tags')));
    expect(properties, isNot(contains('relativePath')));
    expect(properties, isNot(contains('source')));
  });
}
