import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_validation_report.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

class PokemonProjectValidator {
  const PokemonProjectValidator(
    this.repository, {
    this.validator = const PokemonCatalogCoherenceValidator(),
  });

  final PokemonReadRepository repository;
  final PokemonCatalogCoherenceValidator validator;

  Future<PokemonValidationReport> validate(ProjectWorkspace workspace) async {
    final adapterDiagnostics = <PokemonCatalogDiagnostic>[];
    final ruleset = await _loadRuleset(workspace);
    final species = await _loadSpecies(workspace, adapterDiagnostics);
    final learnsets = await _loadLearnsets(workspace, adapterDiagnostics);
    final evolutions = await _loadEvolutions(workspace, adapterDiagnostics);
    final media = await _loadMedia(workspace, adapterDiagnostics);
    final catalogs = await _loadCatalogs(workspace, adapterDiagnostics);
    final canonical = validator.validate(
      PokemonCatalogCoherenceSnapshot(
        ruleset: ruleset,
        catalogs: catalogs,
        species: species,
        learnsets: learnsets,
        evolutions: evolutions,
        media: media,
      ),
    );
    return PokemonCatalogCoherenceReport(<PokemonCatalogDiagnostic>[
      ...adapterDiagnostics,
      ...canonical.diagnostics,
    ]);
  }

  Future<PokemonRulesetProfile> _loadRuleset(ProjectWorkspace workspace) async {
    final manifestPath = workspace.projectManifestPath;
    if (!await workspace.fileExists(manifestPath)) {
      throw EditorPersistenceException(
        'Project manifest is required at $manifestPath.',
      );
    }
    final decoded = jsonDecode(await workspace.readTextFile(manifestPath));
    if (decoded is! Map<String, dynamic>) {
      throw EditorPersistenceException(
        'Project manifest is not a JSON object: $manifestPath',
      );
    }
    return ProjectManifest.fromJson(decoded).pokemon.ruleset;
  }

  Future<List<PokemonCatalogDocument<PokemonSpeciesFile>>> _loadSpecies(
    ProjectWorkspace workspace,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final paths = await _list(
      () => repository.listSpeciesFiles(workspace),
      family: 'species',
      path: 'species',
      diagnostics: diagnostics,
    );
    final documents = <PokemonCatalogDocument<PokemonSpeciesFile>>[];
    for (final path in paths) {
      final value = await _read(
        () => repository.readSpeciesByRelativePath(workspace, path),
        family: 'species',
        path: path,
        diagnostics: diagnostics,
      );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<PokemonCatalogDocument<PokemonLearnsetFile>>> _loadLearnsets(
    ProjectWorkspace workspace,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final ids = await _list(
      () => repository.listLearnsetIds(workspace),
      family: 'learnset',
      path: 'learnsets',
      diagnostics: diagnostics,
    );
    final documents = <PokemonCatalogDocument<PokemonLearnsetFile>>[];
    for (final id in ids) {
      final path = 'learnsets/$id.json';
      final value = await _read(
        () => repository.readLearnsetById(workspace, id),
        family: 'learnset',
        path: path,
        diagnostics: diagnostics,
      );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<PokemonCatalogDocument<PokemonEvolutionFile>>> _loadEvolutions(
    ProjectWorkspace workspace,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final ids = await _list(
      () => repository.listEvolutionIds(workspace),
      family: 'evolution',
      path: 'evolutions',
      diagnostics: diagnostics,
    );
    final documents = <PokemonCatalogDocument<PokemonEvolutionFile>>[];
    for (final id in ids) {
      final path = 'evolutions/$id.json';
      final value = await _read(
        () => repository.readEvolutionById(workspace, id),
        family: 'evolution',
        path: path,
        diagnostics: diagnostics,
      );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<PokemonCatalogDocument<PokemonMediaFile>>> _loadMedia(
    ProjectWorkspace workspace,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final ids = await _list(
      () => repository.listMediaIds(workspace),
      family: 'media',
      path: 'media',
      diagnostics: diagnostics,
    );
    final documents = <PokemonCatalogDocument<PokemonMediaFile>>[];
    for (final id in ids) {
      final path = 'media/$id.json';
      final value = await _read(
        () => repository.readMediaById(workspace, id),
        family: 'media',
        path: path,
        diagnostics: diagnostics,
      );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<PokemonCatalogDocument<PokemonCatalogFile>>> _loadCatalogs(
    ProjectWorkspace workspace,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final documents = <PokemonCatalogDocument<PokemonCatalogFile>>[];
    for (final key in const <String>[
      'types',
      'abilities',
      'moves',
      'growth_rates',
    ]) {
      final path = 'catalogs/$key.json';
      try {
        final value = await repository.readCatalogByKey(workspace, key);
        documents.add(PokemonCatalogDocument(path: path, value: value));
      } on EditorNotFoundException {
        continue;
      } on EditorApplicationException catch (error) {
        diagnostics.add(
          _readDiagnostic(family: 'catalog', path: path, error: error),
        );
      }
    }
    return documents;
  }

  Future<List<String>> _list(
    Future<List<String>> Function() read, {
    required String family,
    required String path,
    required List<PokemonCatalogDiagnostic> diagnostics,
  }) async {
    try {
      return await read();
    } on EditorApplicationException catch (error) {
      final code = switch (error.message) {
        final message when message.contains('same id') =>
          '$family.duplicate_id',
        final message when message.contains('non-empty id') =>
          '$family.id_empty',
        final message when message.contains('Invalid JSON') =>
          '$family.read_error',
        _ => '$family.directory_unreadable',
      };
      diagnostics.add(
        PokemonCatalogDiagnostic(
          code: code,
          severity: PokemonCatalogDiagnosticSeverity.error,
          path: path,
          message: error.message,
          recommendedAction: code.endsWith('duplicate_id')
              ? 'Keep exactly one document for each Pokemon id.'
              : code.endsWith('id_empty')
              ? 'Assign a stable non-empty Pokemon id.'
              : code.endsWith('read_error')
              ? 'Repair or replace the unreadable Pokemon JSON document.'
              : 'Restore the project directory and validate again.',
        ),
      );
      return const <String>[];
    }
  }

  Future<T?> _read<T>(
    Future<T> Function() read, {
    required String family,
    required String path,
    required List<PokemonCatalogDiagnostic> diagnostics,
  }) async {
    try {
      return await read();
    } on EditorApplicationException catch (error) {
      diagnostics.add(
        _readDiagnostic(family: family, path: path, error: error),
      );
      return null;
    }
  }

  PokemonCatalogDiagnostic _readDiagnostic({
    required String family,
    required String path,
    required EditorApplicationException error,
  }) {
    final unsupportedSchema = error.message.contains(
      'Unsupported Pokemon data schema',
    );
    return PokemonCatalogDiagnostic(
      code: unsupportedSchema
          ? '$family.schema_version_unsupported'
          : '$family.read_error',
      severity: PokemonCatalogDiagnosticSeverity.error,
      path: unsupportedSchema ? '$path.schemaVersion' : path,
      message: error.message,
      recommendedAction: unsupportedSchema
          ? 'Use schemaVersion $currentPokemonDataSchemaVersion.'
          : 'Repair or replace the unreadable Pokemon JSON document.',
    );
  }
}
