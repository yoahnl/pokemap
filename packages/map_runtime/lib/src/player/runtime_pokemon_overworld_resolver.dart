import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class RuntimePokemonOverworldResolver {
  const RuntimePokemonOverworldResolver({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

  Future<String?> resolve(PlayerPokemon pokemon) async {
    if (!pokemonConfig.enabled || !_isId(pokemon.speciesId)) return null;
    final species = await _readJson(
      '${pokemonConfig.speciesDir}/${pokemon.speciesId}.json',
    );
    if (species != null && species['id'] != pokemon.speciesId) return null;
    final refs = species?['refs'];
    final mediaRef = refs is Map ? refs['media'] : null;
    final mediaId = mediaRef is String && mediaRef.trim().isNotEmpty
        ? mediaRef.trim()
        : pokemon.speciesId;
    if (!_isId(mediaId)) return null;
    final raw = await _readJson('${pokemonConfig.mediaDir}/$mediaId.json');
    if (raw == null) return null;
    try {
      final media = PokemonMediaFile.fromJson(raw);
      if (media.speciesId != mediaId) return null;
      final forms = species?['forms'];
      final speciesForm = forms is Map ? forms['formId'] : null;
      final requestedForm = pokemon.formId.trim().isNotEmpty
          ? pokemon.formId.trim()
          : speciesForm is String && speciesForm.trim().isNotEmpty
              ? speciesForm.trim()
              : media.defaultFormId;
      final selected = media.variants[requestedForm];
      final fallback = media.variants[media.defaultFormId];
      final variants = <PokemonMediaVariant>[
        ?selected,
        if (requestedForm != media.defaultFormId && fallback != null) fallback,
      ];
      for (final variant in variants) {
        for (final path in [
          if (pokemon.isShiny) variant.overworldShiny,
          variant.overworld,
        ]) {
          final file = await _localFile(path);
          if (file != null) return file.path;
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _readJson(String relativePath) async {
    final file = await _localFile(relativePath);
    if (file == null) return null;
    try {
      if (await file.length() > 2 * 1024 * 1024) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on Object {
      return null;
    }
  }

  Future<File?> _localFile(String? value) async {
    final path = value?.trim().replaceAll('\\', '/');
    if (path == null ||
        path.isEmpty ||
        p.posix.isAbsolute(path) ||
        p.windows.isAbsolute(path) ||
        p.posix.split(path).contains('..') ||
        Uri.tryParse(path)?.hasScheme == true) {
      return null;
    }
    try {
      final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
      final file = File(p.join(root, path));
      if (!await file.exists()) return null;
      final resolved = await file.resolveSymbolicLinks();
      return p.isWithin(root, resolved) ? File(resolved) : null;
    } on FileSystemException {
      return null;
    }
  }

  bool _isId(String value) =>
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(value);
}
