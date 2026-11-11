import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_document_editing.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

import 'm3_story_fixture.dart';
import 'pokemon_authoring_fixture.dart';

const pokemonImportPackPath =
    '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
const pokemonGoldenMovesPath =
    '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/moves.json';

Future<Map<String, dynamic>> readPokemonPackDocument(
  String folder,
  String file,
) async {
  final json = jsonDecode(
    await File('$pokemonImportPackPath/$folder/$file').readAsString(),
  ) as Map<String, dynamic>;
  json['schemaVersion'] = 1;
  return json;
}

Future<void> writePokemonDocument(
  M3StoryFixture source,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final file = File('${source.directory.path}/data/pokemon/$relativePath');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(json));
}

Future<void> seedPokemonMovesCatalog(M3StoryFixture source) async {
  final moves = File(
    '${source.directory.path}/data/pokemon/catalogs/moves.json',
  );
  await moves.parent.create(recursive: true);
  await File(pokemonGoldenMovesPath).copy(moves.path);
}

Future<void> seedPokemonSpeciesDocuments(M3StoryFixture source) async {
  for (final (folder, file) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    await writePokemonDocument(
      source,
      '$folder/$file',
      await readPokemonPackDocument(folder, file),
    );
  }
  await seedPokemonMovesCatalog(source);
}

File pokemonProjectFile(PokemonAuthoringFixture host, String relativePath) =>
    File('${host.source.directory.path}/data/pokemon/$relativePath');

Future<Map<String, dynamic>> readPokemonProjectDocument(
  PokemonAuthoringFixture host,
  String relativePath,
) async =>
    jsonDecode(await pokemonProjectFile(host, relativePath).readAsString())
        as Map<String, dynamic>;

void writePokemonDraftField(
  PokemonWorkspaceController pokemon,
  PokemonDocumentFamily family,
  List<String> path,
  Object? value,
) => pokemon.edit(
  family,
  (json) => PokemonDocumentEditing.write(json, path, value),
);

Future<PokemonSpeciesBundle> reopenPokemonSpecies(
  PokemonAuthoringFixture host,
  String id,
) async {
  final session = ProjectSession(
    sessionId: 'reopened-pokemon-$id',
    name: host.source.session.name,
    directoryPath: host.source.directory.path,
    storage: host.source.session.storage,
  );
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(session);
  final owner = LocalPokemonWorkspaceAdapter(
    session: session,
    mapAdapter: maps,
  );
  try {
    final entry = (await owner.loadIndex()).entries.singleWhere(
      (entry) => entry.id == id,
    );
    return await owner.loadSpecies(entry);
  } finally {
    await owner.close();
  }
}
