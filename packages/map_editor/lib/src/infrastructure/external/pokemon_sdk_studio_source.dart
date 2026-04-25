import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'pokemon_sdk_studio_payload.dart';

final class PokemonSdkStudioSourceException implements Exception {
  const PokemonSdkStudioSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class PokemonSdkStudioSource {
  const PokemonSdkStudioSource();

  Future<PokemonSdkStudioProjectPayload> loadProject(
    String projectRootPath,
  ) async {
    final normalizedRoot = projectRootPath.trim();
    if (normalizedRoot.isEmpty) {
      throw const PokemonSdkStudioSourceException(
        'Pokemon SDK Studio project root path cannot be empty',
      );
    }

    final studioDirectory = Directory(
      p.join(normalizedRoot, 'Data', 'Studio'),
    );
    if (!await studioDirectory.exists()) {
      throw PokemonSdkStudioSourceException(
        'Pokemon SDK Studio Data/Studio folder not found: '
        '${studioDirectory.path}',
      );
    }

    return PokemonSdkStudioProjectPayload(
      moves: await _readStudioFolder(studioDirectory, 'moves'),
      abilities: await _readStudioFolder(studioDirectory, 'abilities'),
      items: await _readStudioFolder(studioDirectory, 'items'),
      types: await _readStudioFolder(studioDirectory, 'types'),
      pokemon: await _readStudioFolder(studioDirectory, 'pokemon'),
    );
  }

  Future<List<Map<String, dynamic>>> _readStudioFolder(
    Directory studioDirectory,
    String folderName,
  ) async {
    final directory = Directory(p.join(studioDirectory.path, folderName));
    if (!await directory.exists()) {
      return const <Map<String, dynamic>>[];
    }

    final files = <File>[];
    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.json') {
        files.add(entity);
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));

    final entries = <Map<String, dynamic>>[];
    for (final file in files) {
      entries.add(await _readStudioJsonFile(file));
    }
    return entries;
  }

  Future<Map<String, dynamic>> _readStudioJsonFile(File file) async {
    final contents = await file.readAsString();
    final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw PokemonSdkStudioSourceException(
        'Invalid Pokemon SDK Studio JSON file ${file.path}: ${error.message}',
      );
    }

    if (decoded is! Map) {
      throw PokemonSdkStudioSourceException(
        'Pokemon SDK Studio JSON file must contain an object: ${file.path}',
      );
    }

    return _sanitizeJsonMap(
      decoded.cast<Object?, Object?>(),
      context: file.path,
    );
  }

  Map<String, dynamic> _sanitizeJsonMap(
    Map<Object?, Object?> raw, {
    required String context,
  }) {
    final sanitized = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        throw PokemonSdkStudioSourceException(
          'Pokemon SDK Studio JSON object contains a non-string key at $context',
        );
      }
      sanitized[key] = _sanitizeJsonValue(
        entry.value,
        context: '$context.$key',
      );
    }
    return sanitized;
  }

  Object? _sanitizeJsonValue(
    Object? value, {
    required String context,
  }) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return value
          .map(
            (entry) => _sanitizeJsonValue(
              entry,
              context: '$context[]',
            ),
          )
          .toList(growable: false);
    }
    if (value is Map) {
      return _sanitizeJsonMap(
        value.cast<Object?, Object?>(),
        context: context,
      );
    }

    throw PokemonSdkStudioSourceException(
      'Pokemon SDK Studio JSON value at $context is not JSON-compatible',
    );
  }
}
