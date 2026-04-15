import 'dart:convert';

import '../seeds/pokemon_moves_bootstrap_seed.dart';
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

  static const Map<String, String> _catalogDescriptions = <String, String>{
    'moves': 'Move catalog for the local Pokemon project database.',
    'abilities': 'Ability catalog for the local Pokemon project database.',
    'items': 'Item catalog for the local Pokemon project database.',
    'types': 'Type catalog for the local Pokemon project database.',
    'growth_rates':
        'Growth rate catalog for the local Pokemon project database.',
    'natures': 'Nature catalog for the local Pokemon project database.',
    'egg_groups': 'Egg group catalog for the local Pokemon project database.',
    'habitats': 'Habitat catalog for the local Pokemon project database.',
    'generations': 'Generation catalog for the local Pokemon project database.',
    'version_groups':
        'Version group catalog for the local Pokemon project database.',
    'encounter_rules':
        'Encounter rule catalog for the local Pokemon project database.',
  };

  static const Map<String, String> _catalogFiles = <String, String>{
    'moves': 'catalogs/moves.json',
    'abilities': 'catalogs/abilities.json',
    'items': 'catalogs/items.json',
    'types': 'catalogs/types.json',
    'growth_rates': 'catalogs/growth_rates.json',
    'natures': 'catalogs/natures.json',
    'egg_groups': 'catalogs/egg_groups.json',
    'habitats': 'catalogs/habitats.json',
    'generations': 'catalogs/generations.json',
    'version_groups': 'catalogs/version_groups.json',
    'encounter_rules': 'catalogs/encounter_rules.json',
  };

  static const List<String> _projectDirectories = <String>[
    'data/pokemon/species/.keep',
    'data/pokemon/learnsets/.keep',
    'data/pokemon/evolutions/.keep',
    'data/pokemon/media/.keep',
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
        'meta': <String, Object?>{
          'description':
              'Root manifest for the local Pokemon data stored inside a project workspace.',
          'notes': const <Object?>[],
        },
        'catalogFiles': _catalogFiles,
        'futureDataFolders': const <String, String>{
          'species': 'species/',
          'learnsets': 'learnsets/',
          'evolutions': 'evolutions/',
          'media': 'media/',
        },
      },
    );

    for (final entry in _catalogFiles.entries) {
      // M4 ouvre volontairement un seul seam spécial : `moves`.
      //
      // Tous les autres catalogues restent sur le scaffold vide historique.
      // On évite ainsi de transformer ce lot en framework de seed multi-
      // catalogues, tout en corrigeant le vrai trou produit : un projet frais
      // ne doit plus partir avec un `moves.json` vide.
      final payload = entry.key == 'moves'
          ? _movesBootstrapPayload()
          : <String, Object?>{
              'schemaVersion': 1,
              'kind': 'pokemon_catalog',
              'catalog': entry.key,
              'meta': <String, Object?>{
                'description': _catalogDescriptions[entry.key]!,
                'sourcePriority': const <String>['internal'],
                'notes': const <Object?>[],
              },
              'entries': const <Object?>[],
            };
      await _writeJsonIfAbsent(
        workspace,
        'data/pokemon/${entry.value}',
        payload,
      );
    }
  }

  /// Construit le payload bootstrap du catalogue moves.
  ///
  /// Invariants de M4 :
  /// - le bootstrap ne parse jamais Showdown à l'exécution ;
  /// - il ne télécharge rien ;
  /// - il réutilise un seed versionné localement dans `map_editor` ;
  /// - il écrit la copie projet uniquement si `moves.json` n'existe pas déjà.
  ///
  /// On laisse ici `project.json` totalement hors scope :
  /// le manifeste pointe déjà vers `data/pokemon/catalogs/moves.json`, et M4
  /// ne doit pas rouvrir ce contrat.
  Map<String, Object?> _movesBootstrapPayload() {
    return buildEmbeddedPokemonMovesBootstrapSeed().toJson();
  }

  Future<void> _writeJsonIfAbsent(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (await workspace.fileExists(absolutePath)) {
      // Garde-fou central : un fichier existant appartient deja au projet
      // utilisateur et ne doit pas etre ecrase par ce bootstrap.
      return;
    }
    await workspace.writeTextFile(
      absolutePath,
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }
}
