import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';

void main() {
  test(
    'implicit Studio resource updates retain the complete project contract',
    () async {
      final root = Directory(
        '/Users/karim/Library/Caches/AveluneQA/hgss-mauville-maps/api/studio-resource-fixture',
      );
      await root.create(recursive: true);
      addTearDown(() => root.delete(recursive: true));
      final modelBytes = triangleGlb();
      await Directory('${root.path}/assets/models3d').create(recursive: true);
      await File('${root.path}/assets/models3d/tree.glb')
          .writeAsBytes(modelBytes);
      final artifact = ContentArtifactRef.fromBytes(
        modelBytes,
        mediaType: 'model/gltf-binary',
      );
      await File('${root.path}/$assetCatalogStorageKey').writeAsString(
        jsonEncode(
          AssetCatalog(
            records: [
              AssetRecord(
                id: 'tree-source',
                logicalPath: 'assets/models3d/tree.glb',
                artifact: artifact,
              ),
            ],
          ).toJson(),
        ),
      );
      final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(modelBytes);
      final map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        layers: const [],
        spatialScene: MapSpatialScene(width: 4, depth: 4),
      );
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/map.json')
          .writeAsString(jsonEncode(map.toJson()));
      EnvironmentPreset preset(String name) => EnvironmentPreset(
        id: 'garden',
        name: name,
        templateId: 'forest',
        palette: [EnvironmentPaletteItem(modelId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      );
      final project = ProjectManifest(
        name: 'Resource compatibility',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: [
          const ProjectMapEntry(
            id: 'map',
            name: 'Map',
            relativePath: 'maps/map.json',
          ),
        ],
        tilesets: [],
        models3d: [
          ProjectModel3dEntry(
            id: 'tree',
            name: 'Tree',
            sourceAssetId: 'tree-source',
            relativePath: 'assets/models3d/tree.glb',
            inspection: const GlbModel3dInspector().inspect(modelBytes),
          ),
        ],
        environmentPresets: [preset('Garden')],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            const ProjectSmartTileMaterial(
              id: 'foreign',
              name: 'Foreign',
              connectionGroupId: 'foreign',
            ),
          ],
        ),
      );
      await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root.path),
        projectId: 'resource-compatibility',
        project: project,
      );
      final session = ProjectSession(
        sessionId: 'compatibility',
        name: project.name,
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final adapter = LocalResourceAdapter(session: session, mapAdapter: maps);
      addTearDown(adapter.dispose);
      final mapBytes = await File('${root.path}/maps/map.json').readAsBytes();
      final receipt = await adapter.mutate('environment.preset.upsert', {
        'preset': encodeEnvironmentPreset(preset('Updated garden')),
      });
      expect(receipt.manifest.maps, project.maps);
      expect(receipt.manifest.environmentPresets.single.name, 'Updated garden');
      expect(receipt.manifest.smartTileCatalog.materials.single.id, 'foreign');
      expect(await File('${root.path}/maps/map.json').readAsBytes(), mapBytes);
      expect(
        await File('${root.path}/assets/models3d/tree.glb').readAsBytes(),
        modelBytes,
      );
    },
  );
}
