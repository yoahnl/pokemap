import 'dart:convert';
import 'dart:io';

import '../ports/project_workspace.dart';

/// Initialise la structure locale Pokemon dans le workspace d'un projet
/// utilisateur.
///
/// Points importants pour ce lot :
/// - n'ecrit que sous [ProjectWorkspace.projectRoot]
/// - ne touche jamais au `project.json`
/// - ne remplace jamais un fichier JSON deja present
/// - reste idempotent si on le relance plusieurs fois
class InitializePokemonProjectStorageUseCase {
  const InitializePokemonProjectStorageUseCase();

  static const Map<String, String> _catalogFiles = <String, String>{
    'moves': 'catalogs/moves.json',
    'abilities': 'catalogs/abilities.json',
    'items': 'catalogs/items.json',
    'types': 'catalogs/types.json',
    'growthRates': 'catalogs/growth_rates.json',
    'natures': 'catalogs/natures.json',
    'eggGroups': 'catalogs/egg_groups.json',
    'habitats': 'catalogs/habitats.json',
    'generations': 'catalogs/generations.json',
    'versionGroups': 'catalogs/version_groups.json',
    'encounterRules': 'catalogs/encounter_rules.json',
  };

  static const List<String> _projectDirectories = <String>[
    'data/pokemon/species/.keep',
    'data/pokemon/learnsets/.keep',
    'data/pokemon/evolutions/.keep',
    'data/pokemon/sprite_sets/.keep',
    'data/pokemon/catalogs/.keep',
    'assets/pokemon/sprites/.keep',
    'assets/pokemon/cries/.keep',
    'assets/pokemon/portraits/.keep',
  ];

  Future<void> execute(ProjectWorkspace workspace) async {
    for (final markerPath in _projectDirectories) {
      final absoluteMarkerPath =
          workspace.resolveProjectRelativePath(markerPath);
      await workspace.ensureDirectoryExists(absoluteMarkerPath);
    }

    await _writeJsonIfAbsent(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_data_manifest',
        'catalogFiles': _catalogFiles,
      },
    );

    for (final entry in _catalogFiles.entries) {
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/${entry.value}',
        <String, Object?>{
          'schemaVersion': 1,
          'kind': 'pokemon_catalog',
          'catalog': _catalogNameForManifestKey(entry.key),
          'entries': const <Object?>[],
        },
      );
    }
  }

  Future<void> _writeJsonIfAbsent(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (await file.exists()) {
      // Garde-fou central : un fichier existant appartient deja au projet
      // utilisateur et ne doit pas etre ecrase par ce bootstrap.
      return;
    }
    await workspace.ensureDirectoryExists(absolutePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  String _catalogNameForManifestKey(String manifestKey) {
    switch (manifestKey) {
      case 'growthRates':
        return 'growth_rates';
      case 'eggGroups':
        return 'egg_groups';
      case 'versionGroups':
        return 'version_groups';
      case 'encounterRules':
        return 'encounter_rules';
      default:
        return manifestKey;
    }
  }
}
