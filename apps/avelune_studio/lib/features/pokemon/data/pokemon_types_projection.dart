import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../domain/pokemon_workspace_models.dart';

Future<List<String>> loadPokemonTypes({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
  required List<PokemonSpeciesSummary> entries,
}) async {
  final values = <String>{for (final entry in entries) ...entry.types};
  final path = config.catalogFiles['types'];
  if (path != null && path.isNotEmpty) {
    try {
      final bytes = await reader.readBytes(
        projectRoot: projectRoot,
        relativePath: path,
      );
      final catalog = PokemonCatalogFile.fromJson(
        (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>(),
      );
      for (final entry in catalog.entries) {
        final id = entry['id'];
        if (id is String && id.trim().isNotEmpty) values.add(id);
      }
    } on Object {
      return List.unmodifiable(values.toList()..sort());
    }
  }
  return List.unmodifiable(values.toList()..sort());
}

Future<Map<String, String>> loadPokemonAbilityNames({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
  required String locale,
}) async {
  final path = config.catalogFiles['abilities'];
  if (path == null || path.isEmpty) return const {};
  try {
    final bytes = await reader.readBytes(
      projectRoot: projectRoot,
      relativePath: path,
    );
    final catalog = PokemonCatalogFile.fromJson(
      (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>(),
    );
    return Map.unmodifiable({
      for (final entry in catalog.entries)
        if (entry['id'] is String)
          entry['id'] as String: resolveLocalizedName(
            names: (entry['names'] as Map?)?.cast<String, String>() ?? {},
            locale: locale,
            fallback: (entry['name'] as String?) ?? entry['id'] as String,
          ),
    });
  } on Object {
    return const {};
  }
}

Future<Map<String, String>> loadPokemonItems({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
}) async {
  final path = config.catalogFiles['items'];
  if (path == null || path.isEmpty) return const {};
  try {
    final bytes = await reader.readBytes(
      projectRoot: projectRoot,
      relativePath: path,
    );
    final raw = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final entries = raw['entries'] as List? ?? const [];
    return Map.unmodifiable({
      for (final entry in entries.whereType<Map>())
        if (entry['id'] is String)
          entry['id'] as String: '${entry['displayName'] ?? entry['id']}',
    });
  } on Object {
    return const {};
  }
}
