import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

void main() {
  test('keeps the actual species path in the Pokédex index', () async {
    final suppliedRoot = Platform.environment['AVELUNE_QA_ROOT'];
    final home = Platform.environment['HOME'];
    if (Platform.isMacOS && (home == null || home.isEmpty)) {
      throw StateError('HOME is required to locate the Avelune QA directory.');
    }
    final qaRoot = Directory(
      suppliedRoot != null && suppliedRoot.isNotEmpty
          ? suppliedRoot
          : Platform.isMacOS
          ? p.join(home!, 'Library', 'Caches', 'AveluneQA')
          : Directory.systemTemp.path,
    );
    if (!p.isAbsolute(qaRoot.path)) {
      throw ArgumentError('AVELUNE_QA_ROOT must be absolute.');
    }
    final allowedRoot = Platform.isMacOS
        ? p.join(home!, 'Library', 'Caches', 'AveluneQA')
        : null;
    if (allowedRoot != null &&
        p.normalize(qaRoot.path) != allowedRoot &&
        !p.isWithin(allowedRoot, p.normalize(qaRoot.path))) {
      throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
    }
    await qaRoot.create(recursive: true);
    if (allowedRoot != null) {
      final canonicalRoot = await Directory(allowedRoot).resolveSymbolicLinks();
      final selectedRoot = await qaRoot.resolveSymbolicLinks();
      if (selectedRoot != canonicalRoot &&
          !p.isWithin(canonicalRoot, selectedRoot)) {
        throw ArgumentError('AVELUNE_QA_ROOT must be inside AveluneQA.');
      }
    }
    final root = await qaRoot.createTemp('pokedex-species-path-');
    addTearDown(() => root.delete(recursive: true));

    const config = ProjectPokemonConfig(
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      speciesDir: 'custom/species',
    );
    const project = ProjectManifest(
      name: 'Species path',
      maps: [],
      tilesets: [],
      pokemon: config,
    );
    final species = File('${root.path}/custom/species/0001-sproutle.json');
    await species.parent.create(recursive: true);
    await File('${root.path}/project.json').writeAsString(jsonEncode(project));
    await species.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'id': 'sproutle',
        'nationalDex': 1,
        'names': {'en': 'Sproutle'},
        'refs': {
          'learnset': 'sproutle',
          'evolution': 'sproutle',
          'media': 'sproutle',
        },
      }),
    );

    final entries = await PokemonProjectDataReader().listDatabaseIndexEntries(
      ProjectFileSystem(root.path),
      speciesDirectoryRelativePath: config.speciesDir,
    );

    expect(entries.single.id, 'sproutle');
    expect(
      entries.single.sourceRelativePath,
      'custom/species/0001-sproutle.json',
    );
  });
}
