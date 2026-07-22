import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  test('all 986 Selbrume species satisfy the runtime progression contract', () {
    final speciesDirectory = Directory(
      p.join(
        Directory.current.path,
        '..',
        '..',
        'selbrume',
        'data',
        'pokemon',
        'species',
      ),
    );
    final files = speciesDirectory
        .listSync(followLinks: false)
        .whereType<File>()
        .where((file) => p.extension(file.path) == '.json')
        .toList(growable: false)
      ..sort((left, right) => left.path.compareTo(right.path));

    expect(files, hasLength(986));

    final invalidRecords = <String>[];
    for (final file in files) {
      final rawJson = jsonDecode(file.readAsStringSync());
      if (rawJson is! Map<String, dynamic>) {
        invalidRecords.add('${p.basename(file.path)}: root is not an object');
        continue;
      }
      final fileName = p.basenameWithoutExtension(file.path);
      final separatorIndex = fileName.indexOf('-');
      final expectedId = separatorIndex < 0
          ? fileName
          : fileName.substring(separatorIndex + 1);
      try {
        parseRuntimePokemonSpeciesProgression(
          rawJson,
          expectedSpeciesId: expectedId,
          filePath: file.path,
        );
      } on Object catch (error) {
        invalidRecords.add('${p.basename(file.path)}: $error');
      }
    }

    expect(
      invalidRecords,
      isEmpty,
      reason: 'Invalid Selbrume species:\n${invalidRecords.join('\n')}',
    );
  });

  test('keeps the 37 sourced Selbrume base experience values exact', () {
    final speciesById = <String, Map<String, dynamic>>{};
    for (final entity in _selbrumeSpeciesDirectory.listSync(
      followLinks: false,
    )) {
      if (entity is! File || p.extension(entity.path) != '.json') continue;
      final decoded = jsonDecode(entity.readAsStringSync());
      if (decoded is! Map<String, dynamic>) continue;
      final id = decoded['id'];
      if (id is String) speciesById[id] = decoded;
    }

    expect(_pokeApiBaseExpSnapshot20260722, hasLength(37));
    for (final expected in _pokeApiBaseExpSnapshot20260722.entries) {
      final actual = speciesById[expected.key];
      expect(actual, isNotNull, reason: 'Missing species ${expected.key}');
      expect(
        actual!['nationalDex'],
        expected.value.nationalDex,
        reason: 'Unexpected nationalDex for ${expected.key}',
      );
      final progression = actual['progression'] as Map<String, dynamic>;
      expect(
        progression['baseExp'],
        expected.value.baseExp,
        reason: 'Unexpected sourced baseExp for ${expected.key}',
      );
    }
  });
}

Directory get _selbrumeSpeciesDirectory => Directory(
      p.join(
        Directory.current.path,
        '..',
        '..',
        'selbrume',
        'data',
        'pokemon',
        'species',
      ),
    );

/// Reproducible PokéAPI snapshot collected on 2026-07-22.
///
/// Source: `GET https://pokeapi.co/api/v2/pokemon/{nationalDex}`.
/// For every entry we verified response `id == nationalDex`,
/// `is_default == true`, `species.name == speciesId`, then copied only the
/// integer `base_experience`. Tests stay offline and pin those sourced values.
const _pokeApiBaseExpSnapshot20260722 =
    <String, ({int nationalDex, int baseExp})>{
  'deoxys': (nationalDex: 386, baseExp: 270),
  'wormadam': (nationalDex: 413, baseExp: 148),
  'giratina': (nationalDex: 487, baseExp: 306),
  'shaymin': (nationalDex: 492, baseExp: 270),
  'basculin': (nationalDex: 550, baseExp: 161),
  'darmanitan': (nationalDex: 555, baseExp: 168),
  'frillish': (nationalDex: 592, baseExp: 67),
  'jellicent': (nationalDex: 593, baseExp: 168),
  'tornadus': (nationalDex: 641, baseExp: 261),
  'thundurus': (nationalDex: 642, baseExp: 261),
  'landorus': (nationalDex: 645, baseExp: 270),
  'keldeo': (nationalDex: 647, baseExp: 261),
  'meloetta': (nationalDex: 648, baseExp: 270),
  'pyroar': (nationalDex: 668, baseExp: 177),
  'meowstic': (nationalDex: 678, baseExp: 163),
  'aegislash': (nationalDex: 681, baseExp: 234),
  'pumpkaboo': (nationalDex: 710, baseExp: 67),
  'gourgeist': (nationalDex: 711, baseExp: 173),
  'zygarde': (nationalDex: 718, baseExp: 270),
  'oricorio': (nationalDex: 741, baseExp: 167),
  'lycanroc': (nationalDex: 745, baseExp: 170),
  'wishiwashi': (nationalDex: 746, baseExp: 61),
  'minior': (nationalDex: 774, baseExp: 154),
  'mimikyu': (nationalDex: 778, baseExp: 167),
  'toxtricity': (nationalDex: 849, baseExp: 176),
  'eiscue': (nationalDex: 875, baseExp: 165),
  'indeedee': (nationalDex: 876, baseExp: 166),
  'morpeko': (nationalDex: 877, baseExp: 153),
  'urshifu': (nationalDex: 892, baseExp: 275),
  'basculegion': (nationalDex: 902, baseExp: 265),
  'enamorus': (nationalDex: 905, baseExp: 116),
  'oinkologne': (nationalDex: 916, baseExp: 171),
  'maushold': (nationalDex: 925, baseExp: 165),
  'squawkabilly': (nationalDex: 931, baseExp: 146),
  'palafin': (nationalDex: 964, baseExp: 160),
  'tatsugiri': (nationalDex: 978, baseExp: 166),
  'dudunsparce': (nationalDex: 982, baseExp: 182),
};
