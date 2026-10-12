import 'package:map_core/map_core.dart';

import 'map_workspace_fixture.dart';

ProjectManifest spatialEnvironmentProject() => workspaceProject.copyWith(
  version: ProjectVersion.v9,
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  models3d: [
    ProjectModel3dEntry(
      id: 'oak',
      name: 'Chêne unitaire',
      sourceAssetId: 'oak-source',
      relativePath: 'assets/models3d/oak.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.4, y: 0, z: -.4),
          max: Model3dVector3(x: .4, y: 2, z: .4),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    ),
  ],
  environmentPresets: [
    EnvironmentPreset(
      id: 'woodland',
      name: 'Bosquet 3D',
      templateId: 'manual',
      sortOrder: 0,
      palette: [EnvironmentPaletteItem(modelId: 'oak', weight: 1)],
      defaultParams: EnvironmentGenerationParams(
        density: 1,
        variation: 0,
        edgeDensity: 1,
        minSpacingCells: 0,
      ),
    ),
  ],
);

MapData spatialEnvironmentMap() => MapData(
  id: 'a',
  name: 'Bosquet pilote',
  version: ProjectVersion.v9,
  size: const GridSize(width: 12, height: 10),
  spatialScene: MapSpatialScene(
    width: 12,
    depth: 10,
    heightLevels: List.generate(120, (index) => index ~/ 12 == 5 ? 2 : 0),
  ),
);
