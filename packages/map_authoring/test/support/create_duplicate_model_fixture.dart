import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'glb_fixture.dart';
import 'resource_index_fixture.dart';

Future<void> main(List<String> arguments) async {
  final bytes = triangleGlb();
  final inspection = const GlbModel3dInspector().inspect(bytes);
  final artifact = ContentArtifactRef.fromBytes(
      bytes, mediaType: 'model/gltf-binary');
  final models = [
    for (final id in ['keep', 'same', 'different'])
      ProjectModel3dEntry(
        id: id,
        name: 'Model',
        sourceAssetId: 'model3d_$id',
        relativePath: 'assets/models3d/$id.glb',
        inspection: inspection,
        scale: id == 'different' ? 2 : 1,
      ),
  ];
  final assets = [
    for (final model in models)
      AssetRecord(
          id: model.sourceAssetId,
          logicalPath: model.relativePath,
          artifact: artifact),
  ];
  final map = MapData(
      id: 'field',
      name: 'Field',
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [
        SpatialModelInstance(
            id: 'placed',
            modelId: 'keep',
            position: Model3dVector3(x: 1, y: 0, z: 1)),
      ]));
  final project = ProjectManifest(
      name: 'Duplicate model audit',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.standardV1),
      maps: const [
        ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'maps/field.json')
      ],
      tilesets: const [],
      models3d: models);
  final fixture = await ResourceIndexFixture.create(
      root: Directory(arguments.single),
      project: project,
      maps: [map],
      files: {
        assetCatalogStorageKey: utf8.encode(jsonEncode(AssetCatalog(records: assets).toJson())),
        assetBlobStorageKey(artifact): bytes,
        for (final model in models) model.relativePath: bytes,
      });
  await fixture.close();
}
