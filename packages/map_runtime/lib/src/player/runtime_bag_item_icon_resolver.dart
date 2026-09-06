import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class RuntimeBagItemIconResolver {
  RuntimeBagItemIconResolver({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;
  Future<Map<String, String>>? _paths;

  Future<String?> resolve(String itemId) async {
    if (!RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(itemId)) {
      return null;
    }
    final paths = await (_paths ??= _loadPaths());
    final explicitPath = paths[itemId];
    if (explicitPath != null) return _existingLocalPath(explicitPath);
    return _existingLocalPath('data/pokemon/assets/items/$itemId.png');
  }

  Future<Map<String, String>> _loadPaths() async {
    try {
      final catalogPath = await _existingLocalPath(
        pokemonConfig.catalogFiles['items'],
      );
      if (catalogPath == null) return const {};
      final decoded = jsonDecode(await File(catalogPath).readAsString());
      final entries = decoded is Map ? decoded['entries'] : null;
      if (entries is! List) return const {};
      return {
        for (final entry in entries)
          if (entry is Map &&
              entry['id'] is String &&
              entry['localSpritePath'] is String)
            entry['id'] as String: entry['localSpritePath'] as String,
      };
    } on Object {
      return const {};
    }
  }

  Future<String?> _existingLocalPath(String? rawPath) async {
    final relativePath = rawPath?.trim().replaceAll('\\', '/');
    if (relativePath == null ||
        relativePath.isEmpty ||
        p.posix.isAbsolute(relativePath) ||
        p.windows.isAbsolute(relativePath) ||
        p.posix.split(relativePath).contains('..') ||
        Uri.tryParse(relativePath)?.hasScheme == true) {
      return null;
    }
    try {
      final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
      final file = File(p.join(root, relativePath));
      if (!await file.exists()) return null;
      final resolved = await file.resolveSymbolicLinks();
      return p.isWithin(root, resolved) ? resolved : null;
    } on FileSystemException {
      return null;
    }
  }
}
