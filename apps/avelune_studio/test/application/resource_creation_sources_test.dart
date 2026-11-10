import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../terrain_creation_test.dart' show terrainSource;
import 'spatial_terrain_draft_test.dart'
    show spatialPathDraft, spatialPathModel;

void main() {
  test('3D path sources retain shared components and family filtering excludes private models', () {
    final model = spatialPathDraft();
    final project = model.manifest.copyWith(
      models3d: [
        ...model.manifest.models3d,
        spatialPathModel('private', name: 'Herbe privée'),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(
            id: 'grass',
            name: 'Hautes herbes',
            parentId: 'vegetation',
          ),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            familyId: 'grass',
            role: ResourceLibraryRole.component,
          ),
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'private',
            familyId: 'grass',
            mapId: 'a',
          ),
        ],
      ),
    );
    final sources = resourceCreationSources(project);
    expect(sources.any((item) => item.id == 'private'), isFalse);
    final filtered = filterResourceCatalog(
      project,
      sources,
      ResourceCatalogFilterState(showComponents: true)..familyId = 'grass',
      forMapPicker: false,
    );
    expect(filtered.map((item) => item.id), ['oak']);
    expect(filtered.single.canonicalKind, 'model3d');
  });

  test(
    '2D path candidates keep compatible atlas sources and reject legacy images',
    () {
      final legacy = workspaceProject.tilesets.single.copyWith(id: 'legacy');
      final project = workspaceProject.copyWith(
        tilesets: [terrainSource, legacy],
        elements: [],
      );
      expect(resourceCreationSources(project).map((item) => item.id), [
        terrainSource.id,
      ]);
    },
  );

  test(
    'decor candidates enforce project grid and refuse margins and spacing',
    () {
      final regular = ProjectTilesetEntry(
        id: 'regular',
        name: 'Grille projet',
        relativePath: 'regular.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'image',
          pixelWidth: 64,
          pixelHeight: 64,
          tileWidth: workspaceProject.settings.tileWidth,
          tileHeight: workspaceProject.settings.tileHeight,
        ),
      );
      final project = workspaceProject.copyWith(
        tilesets: [regular, terrainSource],
        elements: [],
      );
      expect(
        resourceCreationSources(project, decor: true).map((item) => item.id),
        ['regular'],
      );
      expect(resourceCreationSources(project).map((item) => item.id), [
        'regular',
        terrainSource.id,
      ]);
    },
  );
}
