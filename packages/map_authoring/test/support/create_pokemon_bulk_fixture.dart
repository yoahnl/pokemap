import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = arguments.single;
  final store = await CatalogStorageStore.open(projectRoot: root);
  final working = await WorkingProjectCatalog.create(
    store: store,
    projectId: 'pokemon-bulk',
    project: const ProjectManifest(name: 'Pokemon', maps: [], tilesets: []),
  );
  await working.close();
  final species = File('$root/data/pokemon/species/riolu.json');
  await species.parent.create(recursive: true);
  await species.writeAsString(jsonEncode({
    'schemaVersion': 1,
    'id': 'riolu',
    'nationalDex': 447,
    'forms': {'formId': 'base'},
    'refs': {'media': 'riolu'},
  }));
}
