import 'dart:io';

import 'package:map_core/map_core.dart';

import 'resource_index_fixture.dart';

Future<void> main(List<String> arguments) async {
  final maps = [
    for (final id in ['alpha', 'beta'])
      MapData(
          id: id,
          name: id,
          size: const GridSize(width: 4, height: 4),
          tilesetId: id == 'alpha' ? 'sheet' : 'other')
  ];
  final project = ProjectManifest(
      name: 'Resource indexes',
      version: ProjectVersion.v8,
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.standardV1),
      maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ],
      tilesets: [
        for (final id in ['sheet', 'other'])
          ProjectTilesetEntry(id: id, name: id, relativePath: 'assets/$id.png')
      ]);
  final fixture = await ResourceIndexFixture.create(
      root: Directory(arguments.single), project: project, maps: maps);
  await fixture.close();
}
