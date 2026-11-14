import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectManifest familyCatalogProject() => workspaceProject.copyWith(
  elements: [
    workspaceElement.copyWith(id: 'shared', name: 'Chêne', tags: ['Canopée']),
    workspaceElement.copyWith(id: 'map-a', name: 'Bouleau'),
    workspaceElement.copyWith(id: 'map-b', name: 'Cèdre'),
    workspaceElement.copyWith(id: 'unclassified', name: 'Banc'),
  ],
  resourceLibraryCatalog: ResourceLibraryCatalog(
    families: [
      ResourceFamily(id: 'conifers', name: 'Conifères', parentId: 'trees'),
      ResourceFamily(id: 'cedars', name: 'Cèdres', parentId: 'conifers'),
      ResourceFamily(id: 'empty', name: 'Vide', parentId: 'trees'),
    ],
    entries: [
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'shared',
        familyId: 'trees',
      ),
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'map-a',
        familyId: 'conifers',
        mapId: 'a',
      ),
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'map-b',
        familyId: 'cedars',
        mapId: 'b',
      ),
    ],
  ),
);
