import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:path/path.dart' as p;

void main() {
  for (final partitioned in [false, true]) {
    test(
      'typed and dynamic closures retain Studio support partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'runtime-typed-support-',
        );
        addTearDown(() => root.delete(recursive: true));
        final project = _project();
        final path = await _write(root, project, partitioned: partitioned);
        final catalog = await RuntimeProjectCatalog.open(path);
        addTearDown(catalog.dispose);
        final selected = await catalog.manifestForMap(
          _map,
          extraCharacterIds: ['hero'],
        );
        expect(selected.tilesets.map((value) => value.id).toSet(), {
          'sheet',
          'overlay',
          'dynamic',
        });
        expect(selected.elements.map((value) => value.id), ['decor']);
        expect(selected.characters.map((value) => value.id), ['hero']);
        expect(selected.elementCategories.map((value) => value.id).toSet(), {
          'child',
          'parent',
        });
        expect(selected.tilesetFolders.map((value) => value.id).toSet(), {
          'child',
          'parent',
        });
        expect(
          selected.characterStudioCatalog.portraitStates.map(
            (value) => value.id,
          ),
          ['happy'],
        );
        expect(
          selected.characterStudioCatalog.customAnimationDefinitions.map(
            (value) => value.id,
          ),
          ['wave'],
        );
        expect(
          selected.resourceLibraryCatalog.families
              .map((value) => value.id)
              .toSet(),
          {'child', 'parent'},
        );
        expect(
          selected.resourceLibraryCatalog.entries.single.resourceId,
          'decor',
        );
        expect(
          selected.characters.single.toJson(),
          project.characters.first.toJson(),
        );
        expect(
          selected.characterStudioCatalog.portraitStates.single.toJson(),
          project.characterStudioCatalog.portraitStates.first.toJson(),
        );
        expect(
          selected.characterStudioCatalog.customAnimationDefinitions.single
              .toJson(),
          project.characterStudioCatalog.customAnimationDefinitions.first
              .toJson(),
        );
        expect(RuntimeProjectCatalog.ownerOf(selected), same(catalog));
        expect(catalog.projectMetadata.characters, isEmpty);
        expect(
          catalog.projectMetadata.characterStudioCatalog.portraitStates,
          isEmpty,
        );
        if (partitioned) {
          final publication = PortableCatalogPublication.encodeProject(project);
          final units = PortableCatalogPublication.readSync(
            publication.descriptor,
            readObject: (reference) =>
                publication.storage.objects[reference.sha256]!,
          ).units;
          for (final key in [
            CatalogDefinitionKey(CatalogDefinitionKind.element, 'decor'),
            CatalogDefinitionKey(CatalogDefinitionKind.character, 'hero'),
          ]) {
            expect(
              units.singleWhere((unit) => unit.key == key).references,
              isEmpty,
            );
          }
        }
      },
    );
  }

  test(
    'a missing transitive Studio definition still rejects map hydration',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime-missing-studio-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = _project();
      final path = await _write(root, project, partitioned: true);
      final publication = PortableCatalogPublication.encodeProject(project);
      final object = publication.storage.objects.entries.singleWhere((entry) {
        final value = jsonDecode(utf8.decode(entry.value)) as Map;
        return value['payload'] is Map &&
            (value['payload'] as Map)['section'] ==
                'characterStudioCatalog.portraitStates' &&
            ((value['payload'] as Map)['value'] as Map)['id'] == 'happy';
      });
      await File(p.join(root.path, 'catalog/objects/${object.key}.json'))
          .delete();
      final catalog = await RuntimeProjectCatalog.open(path);
      addTearDown(catalog.dispose);
      await expectLater(
        catalog.manifestForMap(_map, extraCharacterIds: ['hero']),
        throwsA(isA<FileSystemException>()),
      );
    },
  );
}

const _map = MapData(
  id: 'later-map',
  name: 'Later map',
  size: GridSize(width: 2, height: 2),
  placedElements: [
    MapPlacedElement(
      id: 'placed',
      layerId: 'props',
      elementId: 'decor',
      pos: GridPos(x: 0, y: 0),
    ),
  ],
);

ProjectManifest _project() =>
    PortableCatalogPublication.withProjectDynamicDependencies(
      ProjectManifest(
        name: 'Typed support',
        maps: const [],
        tilesets: [
          for (final id in ['sheet', 'overlay', 'dynamic', 'unused'])
            ProjectTilesetEntry(
              id: id,
              name: id,
              relativePath: '$id.png',
              folderId: id == 'sheet' ? 'child' : null,
            ),
        ],
        tilesetFolders: const [
          ProjectTilesetFolder(id: 'parent', name: 'Parent'),
          ProjectTilesetFolder(
            id: 'child',
            name: 'Child',
            parentFolderId: 'parent',
          ),
          ProjectTilesetFolder(id: 'unused', name: 'Unused'),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'decor',
            name: 'Decor',
            tilesetId: 'sheet',
            categoryId: 'child',
            frames: [
              TilesetVisualFrame(
                tilesetId: 'overlay',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
        elementCategories: const [
          ProjectElementCategory(id: 'parent', name: 'Parent'),
          ProjectElementCategory(
            id: 'child',
            name: 'Child',
            parentCategoryId: 'parent',
          ),
          ProjectElementCategory(id: 'unused', name: 'Unused'),
        ],
        characters: const [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'sheet',
            portraits: [
              CharacterPortraitVariant(
                portraitStateId: 'happy',
                assetId: 'portrait',
              ),
            ],
            customAnimations: [
              CharacterCustomAnimationClip(
                definitionId: 'wave',
                sourceAssetId: 'wave',
                direction: EntityFacing.south,
              ),
            ],
          ),
        ],
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(id: 'happy', displayName: 'Happy'),
            CharacterPortraitStateDefinition(
              id: 'unused',
              displayName: 'Unused',
            ),
          ],
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Wave',
              mode: CharacterCustomAnimationMode.directional,
            ),
            CharacterCustomAnimationDefinition(
              id: 'unused',
              displayName: 'Unused',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(id: 'parent', name: 'Parent'),
            ResourceFamily(id: 'child', name: 'Child', parentId: 'parent'),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'decor',
              familyId: 'child',
            ),
          ],
        ),
      ),
      [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'sheet'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'dynamic'),
          ],
        ),
      ],
    );

Future<String> _write(
  Directory root,
  ProjectManifest project, {
  required bool partitioned,
}) async {
  final file = File(p.join(root.path, 'project.json'));
  if (!partitioned) {
    await file.writeAsString(jsonEncode(project.toJson()));
    return file.path;
  }
  final publication = PortableCatalogPublication.encodeProject(project);
  await file.writeAsString(jsonEncode(publication.descriptor));
  for (final object in publication.storage.objects.entries) {
    final target = File(
      p.join(root.path, 'catalog/objects/${object.key}.json'),
    );
    await target.parent.create(recursive: true);
    await target.writeAsBytes(object.value);
  }
  return file.path;
}
