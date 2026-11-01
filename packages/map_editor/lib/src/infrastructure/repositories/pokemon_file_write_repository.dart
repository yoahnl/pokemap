import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/ports/pokemon_write_repository.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_media_id_policy.dart';
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
    final speciesId = _safeSpeciesId(learnset.speciesId, 'learnset');
    await _writeJsonObject(
      workspace,
      'data/pokemon/learnsets/$speciesId.json',
      learnset.toJson(),
      confinedKind: 'learnset',
    );
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) async {
    final speciesId = _safeSpeciesId(evolution.speciesId, 'evolution');
    await _writeJsonObject(
      workspace,
      'data/pokemon/evolutions/$speciesId.json',
      evolution.toJson(),
      confinedKind: 'evolution',
    );
  }

  String _safeSpeciesId(String value, String kind) {
    final id = value.trim();
    if (id.isEmpty) {
      throw EditorValidationException(
        'Pokemon $kind speciesId cannot be empty',
      );
    }
    if (id.contains('/') ||
        id.contains(r'\') ||
        id.contains('\u0000') ||
        (Platform.isWindows && id.contains(':'))) {
      throw EditorValidationException(
        'Pokemon $kind speciesId must be a single file name',
      );
    }
    return id;
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) async {
    final speciesId = requireSafePokemonMediaId(media.speciesId);
    final absolutePath = await _validatePokemonWritePath(
      workspace.projectRoot,
      workspace.resolveProjectRelativePath(
        'data/pokemon/media/$speciesId.json',
      ),
    );
    await workspace.ensureDirectoryExists(absolutePath);
    await File(
      absolutePath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(media.toJson()));
  }

  Future<String> _validatePokemonWritePath(
    String projectRoot,
    String absolutePath, {
    String kind = 'media',
  }) async {
    final lexicalRoot = p.normalize(p.absolute(projectRoot));
    final lexicalPath = p.normalize(p.absolute(absolutePath));
    if (!p.isWithin(lexicalRoot, lexicalPath)) {
      throw EditorValidationException(
        'Pokemon $kind path must stay inside the project',
      );
    }
    try {
      final canonicalRoot = await Directory(lexicalRoot).resolveSymbolicLinks();
      var current = canonicalRoot;
      final relative = p.relative(lexicalPath, from: lexicalRoot);
      for (final segment in p.split(relative)) {
        current = p.join(current, segment);
        if (await FileSystemEntity.type(current, followLinks: false) ==
            FileSystemEntityType.link) {
          current = await Link(current).resolveSymbolicLinks();
          if (current != canonicalRoot && !p.isWithin(canonicalRoot, current)) {
            throw EditorValidationException(
              'Pokemon $kind path resolves outside the project',
            );
          }
        }
      }
    } on FileSystemException {
      throw EditorValidationException(
        'Pokemon $kind path cannot be resolved safely',
      );
    }
    return lexicalPath;
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
    final portablePath = p.posix.normalize(
      normalizedRelativePath.replaceAll(r'\', '/'),
    );
    if (normalizedRelativePath.contains('\u0000') ||
        p.posix.isAbsolute(normalizedRelativePath) ||
        p.windows.rootPrefix(normalizedRelativePath).isNotEmpty ||
        RegExp(r'^[A-Za-z]:').hasMatch(normalizedRelativePath) ||
        portablePath == '..' ||
        portablePath.startsWith('../') ||
        (Platform.isWindows && normalizedRelativePath.contains(':'))) {
      throw const EditorValidationException(
        'Pokemon binary asset path must stay inside the project',
      );
    }
    if (bytes.isEmpty) {
      throw const EditorValidationException(
        'Pokemon binary asset bytes cannot be empty',
      );
    }
    final absolutePath = await _validatePokemonWritePath(
      workspace.projectRoot,
      workspace.resolveProjectRelativePath(normalizedRelativePath),
      kind: 'binary asset',
    );
    await workspace.ensureDirectoryExists(absolutePath);
    await File(absolutePath).writeAsBytes(bytes, flush: true);
  }

  Future<void> _writeJsonObject(
    ProjectWorkspace workspace,
    String relativePath,
    Map<String, Object?> payload, {
    String? confinedKind,
  }) async {
    final resolvedPath = workspace.resolveProjectRelativePath(relativePath);
    final absolutePath = confinedKind == null
        ? resolvedPath
        : await _validatePokemonWritePath(
            workspace.projectRoot,
            resolvedPath,
            kind: confinedKind,
          );
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
