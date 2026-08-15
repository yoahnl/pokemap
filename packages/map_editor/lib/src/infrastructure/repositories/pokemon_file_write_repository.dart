import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/ports/pokemon_write_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_project_data_reader.dart';

class FilePokemonWriteRepository implements PokemonWriteRepository {
  FilePokemonWriteRepository({
    PokemonProjectDataReader? reader,
    this.invalidateSpeciesSnapshotAfterSave = true,
  }) : reader = reader ?? PokemonProjectDataReader();

  final PokemonProjectDataReader reader;
  final bool invalidateSpeciesSnapshotAfterSave;

  static const Map<String, String> _catalogRelativePaths = <String, String>{
    'moves': 'data/pokemon/catalogs/moves.json',
    'abilities': 'data/pokemon/catalogs/abilities.json',
    'items': 'data/pokemon/catalogs/items.json',
    'types': 'data/pokemon/catalogs/types.json',
    'growth_rates': 'data/pokemon/catalogs/growth_rates.json',
    'natures': 'data/pokemon/catalogs/natures.json',
    'egg_groups': 'data/pokemon/catalogs/egg_groups.json',
    'habitats': 'data/pokemon/catalogs/habitats.json',
    'generations': 'data/pokemon/catalogs/generations.json',
    'version_groups': 'data/pokemon/catalogs/version_groups.json',
    'encounter_rules': 'data/pokemon/catalogs/encounter_rules.json',
  };

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) async {
    final trimmedKey = catalogKey.trim();
    final payloadCatalog = catalog.catalog.trim();
    if (payloadCatalog != trimmedKey) {
      throw EditorValidationException(
        'Pokemon catalog key mismatch: requested "$trimmedKey" but payload is '
        '"$payloadCatalog"',
      );
    }
    final relativePath = _catalogRelativePaths[trimmedKey];
    if (relativePath == null) {
      throw EditorNotFoundException(
        'Pokemon catalog write path not declared for key: $catalogKey',
      );
    }
    await _writeJsonObject(workspace, relativePath, catalog.toJson());
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final relativePath = await _resolveSpeciesWritePath(workspace, species);
    await _writeJsonObject(workspace, relativePath, species.toJson());
    if (invalidateSpeciesSnapshotAfterSave) {
      reader.invalidateSpeciesSnapshot(workspace);
    }
  }

  Future<void> saveSpeciesAtRelativePath(
    ProjectWorkspace workspace, {
    required String relativePath,
    required PokemonSpeciesFile species,
  }) async {
    final normalizedPath = relativePath.trim();
    if (normalizedPath != relativePath ||
        p.posix.normalize(normalizedPath) != normalizedPath ||
        p.posix.isAbsolute(normalizedPath) ||
        p.posix.dirname(normalizedPath) != 'data/pokemon/species' ||
        p.posix.extension(normalizedPath).toLowerCase() != '.json') {
      throw EditorValidationException(
        'Pokemon species path must be a canonical JSON file in '
        'data/pokemon/species: $relativePath',
      );
    }
    if (species.id.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }
    await _writeJsonObject(workspace, normalizedPath, species.toJson());
    if (invalidateSpeciesSnapshotAfterSave) {
      reader.invalidateSpeciesSnapshot(workspace);
    }
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) async {
    final speciesId = learnset.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/learnsets/$speciesId.json',
      learnset.toJson(),
    );
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) async {
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/evolutions/$speciesId.json',
      evolution.toJson(),
    );
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) async {
    final speciesId = media.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media speciesId cannot be empty',
      );
    }
    await _writeJsonObject(
      workspace,
      'data/pokemon/media/$speciesId.json',
      media.toJson(),
    );
  }

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) async {
    final normalizedRelativePath = relativePath.trim();
    if (normalizedRelativePath.isEmpty) {
      throw const EditorValidationException(
        'Pokemon binary asset relativePath cannot be empty',
      );
    }
    if (bytes.isEmpty) {
      throw const EditorValidationException(
        'Pokemon binary asset bytes cannot be empty',
      );
    }
    final absolutePath = workspace.resolveProjectRelativePath(
      normalizedRelativePath,
    );
    await workspace.ensureDirectoryExists(absolutePath);
    await File(absolutePath).writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeJsonObject(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    await workspace.ensureDirectoryExists(absolutePath);
    await File(
      absolutePath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  }

  Future<String> _resolveSpeciesWritePath(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) async {
    final trimmedId = species.id.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }
    final speciesDirectory = Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
    if (!await speciesDirectory.exists()) {
      return 'data/pokemon/species/${_speciesFileName(species)}';
    }
    final existingPath = await reader.resolveSpeciesWriteRelativePathById(
      workspace,
      trimmedId,
    );
    if (existingPath != null) {
      return existingPath;
    }
    return 'data/pokemon/species/${_speciesFileName(species)}';
  }

  String _speciesFileName(PokemonSpeciesFile species) {
    final dex = species.nationalDex.toString().padLeft(4, '0');
    final slug = _sanitizeFileSegment(
      species.slug.isNotEmpty ? species.slug : species.id,
    );
    return '$dex-$slug.json';
  }

  String _sanitizeFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    final trimmed = collapsed.replaceAll(RegExp(r'^_|_$'), '');
    return trimmed.isEmpty ? 'pokemon' : p.basename(trimmed);
  }
}
