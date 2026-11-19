import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  test(
    'the local library loads partitioned resource metadata on an isolate',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'resource_library_',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final root = await temporary.resolveSymbolicLinks();
      final project = ProjectManifest(
        name: 'Bibliothèque partitionnée',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'tileset',
            name: 'Pavés',
            relativePath: 'assets/paves.png',
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [ResourceFamily(id: 'paving', name: 'Pavages')],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: 'tileset',
              familyId: 'paving',
              role: ResourceLibraryRole.component,
            ),
          ],
        ),
      );
      await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root),
        projectId: 'resource-library',
        project: project,
      );

      final result = await LocalMapWorkspaceAdapter().readResourceLibrary(
        ProjectSession(
          sessionId: 'resource-library',
          name: project.name,
          directoryPath: root,
          storage: ProjectSessionStorage.workingCatalog,
        ),
      );

      final item = result.items.single;
      expect(item.name, 'Pavés');
      expect(item.role, ResourceLibraryRole.component);
      expect(item.familyId, 'paving');
      expect(
        result.catalog.families
            .singleWhere((family) => family.id == 'paving')
            .name,
        'Pavages',
      );
    },
  );
}
