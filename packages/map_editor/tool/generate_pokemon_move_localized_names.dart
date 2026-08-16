import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:map_editor/src/application/services/pokemon_move_local_id.dart';

/// Génère la table des noms d'attaques localisés depuis PokeAPI.
///
/// Le matching passe volontairement par le **nom anglais** et non par le slug
/// PokeAPI : le converter Showdown dérive son identifiant local du nom anglais,
/// et les slugs divergent sur la ponctuation (`10-000-000-volt-thunderbolt`
/// contre `10,000,000 Volt Thunderbolt`).
///
/// Une entrée sans aucune traduction hors anglais n'est pas émise : la table
/// est une table de traductions, pas un miroir de PokeAPI. Ces entrées sont
/// listées dans le rapport.
///
/// Usage :
///   dart run tool/generate_pokemon_move_localized_names.dart \
///     > lib/src/application/seeds/pokemon_move_localized_names.dart
///
/// Le rapport de génération est écrit sur stderr et ne pollue donc pas le
/// fichier produit.
const _languages = <String>['fr'];
const _baseUri = 'https://pokeapi.co/api/v2';
const _pageSize = 200;
const _concurrency = 8;

Future<void> main(List<String> arguments) async {
  final client = http.Client();
  try {
    final moveUrls = await _fetchAllMoveUrls(client);
    stderr.writeln('PokeAPI exposes ${moveUrls.length} moves.');

    final table = <String, Map<String, String>>{};
    final skippedNoEnglishName = <String>[];
    final collisions = <String, List<String>>{};
    final missingTranslation = <String>[];

    for (var start = 0; start < moveUrls.length; start += _concurrency) {
      final slice = moveUrls.skip(start).take(_concurrency);
      final payloads = await Future.wait(
        slice.map((url) => _fetchJson(client, url)),
      );

      for (final payload in payloads) {
        final names = _readNamesByLanguage(payload);
        final englishName = names['en'];
        final slug = (payload['name'] as String?)?.trim() ?? '';

        if (englishName == null || englishName.isEmpty) {
          skippedNoEnglishName.add(slug.isEmpty ? '<unnamed>' : slug);
          continue;
        }

        final localId = normalizePokemonMoveLocalId(englishName);
        if (localId.isEmpty) {
          skippedNoEnglishName.add(slug);
          continue;
        }

        final translations = <String, String>{
          'en': englishName,
          for (final language in _languages)
            if ((names[language] ?? '').isNotEmpty)
              language: names[language]!,
        };

        if (translations.length == 1) {
          missingTranslation.add(localId);
          continue;
        }

        final existing = table[localId];
        if (existing != null && existing['en'] != englishName) {
          collisions
              .putIfAbsent(localId, () => <String>[existing['en']!])
              .add(englishName);
          continue;
        }
        table[localId] = translations;
      }

      final done = (start + _concurrency).clamp(0, moveUrls.length);
      if (done % 200 < _concurrency || done == moveUrls.length) {
        stderr.writeln('Fetched $done/${moveUrls.length}');
      }
    }

    stdout.write(_renderDartFile(table));

    stderr.writeln('');
    stderr.writeln('=== Rapport de génération ===');
    stderr.writeln('Entrées produites          : ${table.length}');
    stderr
        .writeln('Sans nom anglais (ignorées): ${skippedNoEnglishName.length}');
    for (final slug in skippedNoEnglishName) {
      stderr.writeln('  - $slug');
    }
    stderr.writeln('Sans traduction française  : ${missingTranslation.length}');
    for (final localId in missingTranslation) {
      stderr.writeln('  - $localId');
    }
    stderr.writeln("Collisions d'identifiant   : ${collisions.length}");
    for (final entry in collisions.entries) {
      stderr.writeln('  - ${entry.key}: ${entry.value.join(" / ")}');
    }
  } finally {
    client.close();
  }
}

Future<List<String>> _fetchAllMoveUrls(http.Client client) async {
  final urls = <String>[];
  var offset = 0;
  while (true) {
    final payload = await _fetchJson(
      client,
      '$_baseUri/move?limit=$_pageSize&offset=$offset',
    );
    final results = payload['results'];
    if (results is! List || results.isEmpty) {
      break;
    }
    for (final result in results) {
      if (result is Map && result['url'] is String) {
        urls.add(result['url'] as String);
      }
    }
    if (payload['next'] == null) {
      break;
    }
    offset += _pageSize;
  }
  return urls;
}

Future<Map<String, dynamic>> _fetchJson(http.Client client, String url) async {
  final response = await client.get(
    Uri.parse(url),
    headers: const <String, String>{
      'User-Agent': 'PokeMapEditor/0.1 (+https://pokemap.local)',
    },
  ).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw StateError('GET $url failed with ${response.statusCode}');
  }
  return (jsonDecode(response.body) as Map).cast<String, dynamic>();
}

Map<String, String> _readNamesByLanguage(Map<String, dynamic> payload) {
  final raw = payload['names'];
  if (raw is! List) {
    return const <String, String>{};
  }
  final names = <String, String>{};
  for (final entry in raw) {
    if (entry is! Map) {
      continue;
    }
    final language = entry['language'];
    final languageId = language is Map ? language['name'] : null;
    final value = entry['name'];
    if (languageId is String && value is String && value.trim().isNotEmpty) {
      names[languageId.trim()] = value.trim();
    }
  }
  return names;
}

String _renderDartFile(Map<String, Map<String, String>> table) {
  final sortedIds = table.keys.toList()..sort();
  final buffer = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Régénérer avec :')
    ..writeln('//   cd packages/map_editor && dart run \\')
    ..writeln('//     tool/generate_pokemon_move_localized_names.dart \\')
    ..writeln(
        '//     > lib/src/application/seeds/pokemon_move_localized_names.dart')
    ..writeln('//')
    ..writeln('// Source : PokeAPI v2. Indexé par identifiant local du')
    ..writeln('// catalogue, dérivé du nom anglais via')
    ..writeln('// normalizePokemonMoveLocalId.')
    ..writeln('')
    ..writeln(
        'const Map<String, Map<String, String>> pokemonMoveLocalizedNames =')
    ..writeln('    <String, Map<String, String>>{');

  for (final id in sortedIds) {
    final translations = table[id]!;
    final languages = translations.keys.toList()..sort();
    buffer.writeln("  '$id': <String, String>{");
    for (final language in languages) {
      buffer.writeln(
        "    '$language': '${_escape(translations[language]!)}',",
      );
    }
    buffer.writeln('  },');
  }

  buffer
    ..writeln('};')
    ..writeln('')
    ..writeln('/// Traductions connues pour un identifiant local de move.')
    ..writeln('///')
    ..writeln('/// Renvoie une map vide quand le move est inconnu de la table,')
    ..writeln('/// ce qui laisse le libellé anglais canonique en place.')
    ..writeln('Map<String, String> localizedNamesForMove(String localId) =>')
    ..writeln(
        '    pokemonMoveLocalizedNames[localId] ?? const <String, String>{};');

  return buffer.toString();
}

String _escape(String value) =>
    value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
