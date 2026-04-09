import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/project_workspace.dart';

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  const PokemonProjectDataReader();

  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) async {
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    final manifest = await readManifest(workspace);
    final relativePath = manifest.catalogFiles[catalogKey];
    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in manifest: $catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/$relativePath',
      label: 'Pokemon catalog "$catalogKey"',
    );
    return PokemonCatalogFile.fromJson(json);
  }

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesPathEntry = await _resolveSpeciesIndexEntryById(workspace, trimmedId);
    final species = await _readSpeciesAtRelativePath(
      workspace,
      speciesPathEntry.relativePath,
    );
    if (species.id != trimmedId) {
      throw EditorPersistenceException(
        'Pokemon species file id mismatch for "$trimmedId": '
        '${speciesPathEntry.relativePath} contains "${species.id}"',
      );
    }
    return species;
  }

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/learnsets/$trimmedId.json',
      label: 'Pokemon learnset "$trimmedId"',
    );
    return PokemonLearnsetFile.fromJson(json);
  }

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/evolutions/$trimmedId.json',
      label: 'Pokemon evolution "$trimmedId"',
    );
    return PokemonEvolutionFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    return _listJsonRelativePaths(
      workspace,
      'data/pokemon/species',
      label: 'Pokemon species directory',
    );
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
  }

  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) {
    return _readSpeciesAtRelativePath(workspace, relativePath);
  }

  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/learnsets',
      label: 'Pokemon learnsets directory',
    );
  }

  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) async {
    return _listJsonFileStemIds(
      workspace,
      'data/pokemon/evolutions',
      label: 'Pokemon evolutions directory',
    );
  }

  Future<String?> resolveSpeciesRelativePathById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesDir = _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      return null;
    }

    final normalizedId = _sanitizeSpeciesFileSegment(trimmedId);
    final matches = <String>[];

    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;

      final basename = p.basename(entity.path).toLowerCase();
      if (basename == '$normalizedId.json' ||
          basename.endsWith('-$normalizedId.json')) {
        matches.add(
          p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
        );
      }
    }

    matches.sort();

    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files match the id "$trimmedId": '
        '${matches.join(', ')}',
      );
    }

    if (matches.isEmpty) {
      return null;
    }

    return matches.single;
  }

  Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = <PokemonSpeciesIndexEntry>[];
    for (final relativePath in await listSpeciesFiles(workspace)) {
      final json = await _readJsonFile(
        workspace,
        relativePath,
        label: 'Pokemon species index file',
      );
      entries.add(
        PokemonSpeciesIndexEntry.fromJson(
          json,
          relativePath: relativePath,
        ),
      );
    }
    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });
    return entries;
  }

  Future<PokemonSpeciesFile> _readSpeciesAtRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon species file',
    );
    return PokemonSpeciesFile.fromJson(json);
  }

  Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final matches = (await _buildSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == speciesId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$speciesId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    return matches.single;
  }

  Directory _speciesDirectory(ProjectWorkspace workspace) {
    return Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
  }

  Future<List<String>> _listJsonRelativePaths(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final directory = Directory(
      workspace.resolveProjectRelativePath(relativeDirectory),
    );
    if (!await directory.exists()) {
      throw EditorNotFoundException('$label not found in project workspace');
    }

    final relativePaths = <String>[];
    await for (final entity in directory.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      relativePaths.add(
        p.normalize(p.relative(entity.path, from: workspace.projectRoot)),
      );
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<String>> _listJsonFileStemIds(
    ProjectWorkspace workspace,
    String relativeDirectory, {
    required String label,
  }) async {
    final relativePaths = await _listJsonRelativePaths(
      workspace,
      relativeDirectory,
      label: label,
    );
    return relativePaths
        .map((relativePath) => p.basenameWithoutExtension(relativePath))
        .toList(growable: false);
  }

  String _sanitizeSpeciesFileSegment(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    final collapsed = safe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<Map<String, dynamic>> _readJsonFile(
    ProjectWorkspace workspace,
    String relativePath, {
    required String label,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw EditorNotFoundException('$label not found: $relativePath');
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          '$label is not a JSON object: $relativePath',
        );
      }
      return decoded;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read $label at $relativePath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in $label at $relativePath: $error',
      );
    }
  }
}
