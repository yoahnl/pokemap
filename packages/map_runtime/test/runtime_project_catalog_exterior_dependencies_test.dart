import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';

void main() {
  test(
    'exterior roots admit only their selected model without loading its bytes',
    () async {
      final root = await Directory.systemTemp.createTemp('exterior-catalog-');
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v9,
        size: const GridSize(width: 4, height: 4),
        spatialScene: MapSpatialScene(width: 4, depth: 4),
      );
      final model = ProjectModel3dEntry(
        id: 'exterior-only',
        name: 'Exterior',
        sourceAssetId: 'exterior-source',
        relativePath: 'assets/models3d/exterior-only.glb',
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3.zero,
            max: Model3dVector3(x: 1, y: 1, z: 1),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      );
      final project = ProjectManifest(
        name: 'Exterior',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        maps: const [
          ProjectMapEntry(
            id: 'route',
            name: 'Route',
            relativePath: 'maps/route.json',
          ),
        ],
        tilesets: const [],
        models3d: [model],
      );
      await Directory('${root.path}/maps').create();
      await File('${root.path}/maps/route.json')
          .writeAsString(jsonEncode(map.toJson()));
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      final catalog = await RuntimeProjectCatalog.open(
        '${root.path}/project.json',
      );
      addTearDown(() => catalog.dispose());
      final ProjectManifest regular = await catalog.manifestForMaps([map]);
      expect(regular.models3d, isEmpty);
      final ProjectManifest exterior = await catalog.manifestForMaps(
        [map],
        extraDefinitionKeys: [
          CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'exterior-only'),
        ],
      );
      expect(exterior.models3d.single, model);
      expect(await File('${root.path}/assets/exterior.glb').exists(), isFalse);
    },
  );
}
