import 'dart:typed_data';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const preset = ProjectSmartTilePreset(
  id: 'grass',
  name: 'Herbe',
  usage: SmartTileUsage.terrain,
  topology: SmartTileTopology.uniform,
  templateHint: SmartTileTemplateHint.simple,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  defaultMaterialId: 'grass',
  allowedMaterialIds: ['grass'],
);
final project = ProjectManifest(
  version: ProjectVersion.v9,
  name: 'Carte 3D',
  settings: ProjectSettings(
    dimension: ProjectDimension.threeD,
    spatialCamera: SpatialCameraProfile(),
  ),
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'map.json'),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Herbe',
        connectionGroupId: 'grass',
      ),
    ],
    presets: [preset],
  ),
);

class PaintingVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
