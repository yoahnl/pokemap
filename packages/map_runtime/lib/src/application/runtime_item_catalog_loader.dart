import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

final class RuntimeItemCatalogLoader {
  const RuntimeItemCatalogLoader();

  Future<ProjectItemCatalog?> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    final relativePath = pokemonConfig.catalogFiles['items']?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      return null;
    }
    final file = _boundedFile(projectRootDirectory, relativePath);
    if (!await file.exists()) {
      return null;
    }

    try {
      return decodeProjectItemCatalog(
        jsonDecode(await file.readAsString()),
      );
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Le catalogue des objets du projet est invalide.',
        debugDetails: 'file=${file.path}, error=$error',
      );
    }
  }

  Future<ProjectItemDefinition?> loadDefinition({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String itemId,
  }) async {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty) {
      return null;
    }
    final catalog = await load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    if (catalog == null) {
      return null;
    }
    final matches = catalog.entries
        .where((entry) => entry.id == normalizedItemId)
        .toList(growable: false);
    if (matches.length > 1) {
      throw RuntimeBattleSetupException(
        'Le catalogue des objets contient des ids dupliqués.',
        debugDetails: 'itemId=$normalizedItemId',
      );
    }
    return matches.firstOrNull;
  }

  File _boundedFile(String projectRootDirectory, String relativePath) {
    if (p.isAbsolute(relativePath)) {
      throw const RuntimeBattleSetupException(
        'Le catalogue des objets doit appartenir au projet.',
      );
    }
    final root = p.normalize(p.absolute(projectRootDirectory));
    final filePath = p.normalize(p.join(root, relativePath));
    if (!p.isWithin(root, filePath)) {
      throw const RuntimeBattleSetupException(
        'Le catalogue des objets doit appartenir au projet.',
      );
    }
    return File(filePath);
  }
}
