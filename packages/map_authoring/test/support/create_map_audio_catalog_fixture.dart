import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.single;
  const project = ProjectManifest(
    name: 'Scoped map audio', version: ProjectVersion.v8, tilesets: [],
    pokemon: ProjectPokemonConfig(enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    maps: [ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ProjectMapEntry(id: 'foreign', name: 'Foreign', relativePath: 'maps/foreign.json')],
  );
  await WorkingProjectCatalog.create(store: await CatalogStorageStore.open(projectRoot: root), projectId: 'map-audio', project: project);
  await Directory('$root/maps').create(recursive: true);
  await File('$root/maps/map.json').writeAsString(jsonEncode(const MapData(
    id: 'map', name: 'Map', size: GridSize(width: 8, height: 6), properties: {'preserved': 'map content'},
  ).toJson()));
  await File('$root/maps/foreign.json').writeAsString('Foreign map must remain unread.');
}
