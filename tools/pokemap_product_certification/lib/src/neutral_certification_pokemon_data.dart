import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'neutral_certification_pokemon_seed.dart';

Future<void> writeNeutralCertificationPokemonData(Directory root) async {
  final seed =
      jsonDecode(neutralCertificationPokemonSeed) as Map<String, dynamic>;
  final documents = <String, Object?>{
    ...seed,
    'catalogs/items.json': encodeProjectItemCatalog(mvpItemCatalog),
  };
  for (final entry in documents.entries) {
    final file = File(p.join(root.path, 'data', 'pokemon', entry.key));
    if (await file.exists()) continue;
    await _writeJson(file, entry.value);
  }
}

Future<void> writeNeutralCertificationSpeciesCatalog(
  Directory root, {
  required int count,
}) async {
  if (count < 2 || count > 10000) {
    throw ArgumentError.value(count, 'count', 'must be between 2 and 10000');
  }
  final pokemonPath = p.join(root.path, 'data', 'pokemon');
  final generatedNames = <String, RegExp>{
    'species': RegExp(r'^\d+-clockling\.json$'),
    'learnsets': RegExp(r'^clockling_\d+\.json$'),
    'evolutions': RegExp(r'^clockling_\d+\.json$'),
    'media': RegExp(r'^clockling_\d+\.json$'),
  };
  for (final entry in generatedNames.entries) {
    final documents = Directory(p.join(pokemonPath, entry.key));
    await for (final file in documents.list(followLinks: false)) {
      if (file is File && entry.value.hasMatch(p.basename(file.path))) {
        await file.delete();
      }
    }
  }
  final species = await _readJson(
    p.join(pokemonPath, 'species/0001-bulbasaur.json'),
  );
  final learnset = await _readJson(
    p.join(pokemonPath, 'learnsets/bulbasaur.json'),
  );
  final media = await _readJson(p.join(pokemonPath, 'media/bulbasaur.json'));
  for (var start = 2; start < count; start += 32) {
    final end = (start + 32).clamp(0, count);
    await Future.wait([
      for (var index = start; index < end; index++)
        _writeClockling(pokemonPath, index, species, learnset, media),
    ]);
  }
}

Future<void> _writeClockling(
  String pokemonPath,
  int index,
  Map<String, dynamic> species,
  Map<String, dynamic> learnset,
  Map<String, dynamic> media,
) async {
  final id = 'clockling_$index';
  final dexNumber = (index + 1).toString().padLeft(4, '0');
  final documents = <String, Object?>{
    'species/$dexNumber-clockling.json': <String, Object?>{
      ...species,
      'id': id,
      'slug': 'clockling-$index',
      'nationalDex': index + 1,
      'names': {'en': 'Clockling $index', 'fr': 'Horlogre $index'},
      'forms': {...species['forms'] as Map<String, dynamic>, 'baseFormId': id},
      'refs': {'learnset': id, 'evolution': id, 'media': id},
    },
    'learnsets/$id.json': {...learnset, 'speciesId': id},
    'evolutions/$id.json': <String, Object?>{
      'schemaVersion': currentPokemonDataSchemaVersion,
      'speciesId': id,
      'evolutions': [],
    },
    'media/$id.json': {...media, 'speciesId': id},
  };
  await Future.wait([
    for (final entry in documents.entries)
      _writeJson(File(p.join(pokemonPath, entry.key)), entry.value),
  ]);
}

Future<Map<String, dynamic>> _readJson(String path) async =>
    jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;

Future<void> _writeJson(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(value), flush: true);
}
