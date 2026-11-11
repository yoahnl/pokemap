import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'glb_fixture.dart';
import 'resource_index_fixture.dart';

Future<void> main(List<String> arguments) async {
  final inspection = const GlbModel3dInspector().inspect(triangleGlb());
  final map = MapData(id: 'field', name: 'Field',
      size: const GridSize(width: 4, height: 4), tilesetId: 'sheet');
  final project = ProjectManifest(
    name: 'Bulk model transport',
    version: ProjectVersion.v8,
    pokemon: const ProjectPokemonConfig(
        enabled: false, ruleset: PokemonRulesetProfile.standardV1),
    maps: const [ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'maps/field.json')],
    tilesets: const [ProjectTilesetEntry(id: 'sheet', name: 'Sheet', relativePath: 'assets/sheet.png')],
    models3d: [
      for (var index = 0; index < 1001; index++)
        ProjectModel3dEntry(id: 'model-$index', name: 'Model $index',
            sourceAssetId: 'asset-$index', relativePath: 'assets/models3d/model-$index.glb',
            inspection: inspection),
    ],
  );
  final fixture = await ResourceIndexFixture.create(
      root: Directory(arguments.single), project: project, maps: [map]);
  await fixture.close();
}
