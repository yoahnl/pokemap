import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../ports/project_file_reader.dart';
import '../../workspace/workspace_handle_store.dart';

final class PokemonCatalogCoherenceLoader {
  const PokemonCatalogCoherenceLoader({
    this.validator = const PokemonCatalogCoherenceValidator(),
  });

  final PokemonCatalogCoherenceValidator validator;

  Future<PokemonCatalogCoherenceReport> validate(
    ProjectWorkspaceAccess access,
    ProjectManifest manifest,
  ) =>
      _validate(
        manifest,
        readBytes: access.readBytes,
        listFiles: access.listFiles,
      );

  Future<PokemonCatalogCoherenceReport> validateProjectFiles({
    required ProjectFileReader reader,
    required String projectRoot,
    required ProjectManifest manifest,
  }) {
    final directoryReader = reader is ProjectDirectoryReader
        ? reader as ProjectDirectoryReader
        : null;
    return _validate(
      manifest,
      readBytes: (path) => reader.readBytes(
        projectRoot: projectRoot,
        relativePath: path,
      ),
      listFiles: (directory) async => directoryReader == null
          ? null
          : await directoryReader.listFiles(
              projectRoot: projectRoot,
              relativeDirectory: directory,
            ),
    );
  }

  Future<PokemonCatalogCoherenceReport> _validate(
    ProjectManifest manifest, {
    required _PokemonDocumentReader readBytes,
    required _PokemonDirectoryLister listFiles,
  }) async {
    if (!manifest.pokemon.enabled) {
      return PokemonCatalogCoherenceReport(const []);
    }
    final diagnostics = <PokemonCatalogDiagnostic>[];
    final catalogs = await _loadCatalogs(readBytes, manifest, diagnostics);
    final species = await _loadDirectory<PokemonSpeciesFile>(
      readBytes,
      listFiles,
      manifest.pokemon.speciesDir,
      family: 'species',
      decode: PokemonSpeciesFile.fromJson,
      diagnostics: diagnostics,
    );
    final learnsets = await _loadDirectory<PokemonLearnsetFile>(
      readBytes,
      listFiles,
      manifest.pokemon.learnsetsDir,
      family: 'learnset',
      decode: PokemonLearnsetFile.fromJson,
      diagnostics: diagnostics,
    );
    final evolutions = await _loadDirectory<PokemonEvolutionFile>(
      readBytes,
      listFiles,
      manifest.pokemon.evolutionsDir,
      family: 'evolution',
      decode: PokemonEvolutionFile.fromJson,
      diagnostics: diagnostics,
    );
    final media = await _loadDirectory<PokemonMediaFile>(
      readBytes,
      listFiles,
      manifest.pokemon.mediaDir,
      family: 'media',
      decode: PokemonMediaFile.fromJson,
      diagnostics: diagnostics,
    );
    final report = validator.validate(
      PokemonCatalogCoherenceSnapshot(
        catalogs: catalogs,
        species: species,
        learnsets: learnsets,
        evolutions: evolutions,
        media: media,
        ruleset: manifest.pokemon.ruleset,
      ),
    );
    return PokemonCatalogCoherenceReport(<PokemonCatalogDiagnostic>[
      ...diagnostics,
      ...report.diagnostics,
    ]);
  }

  Future<List<PokemonCatalogDocument<PokemonCatalogFile>>> _loadCatalogs(
    _PokemonDocumentReader readBytes,
    ProjectManifest manifest,
    List<PokemonCatalogDiagnostic> diagnostics,
  ) async {
    final documents = <PokemonCatalogDocument<PokemonCatalogFile>>[];
    final entries = manifest.pokemon.catalogFiles.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    for (final entry in entries) {
      final path = _normalizePath(entry.value);
      final value = entry.key == 'items'
          ? await _readDocument<PokemonCatalogFile>(
              readBytes,
              path,
              family: 'catalog',
              decode: _decodeItemCatalog,
              diagnostics: diagnostics,
              missingIsWarning: true,
            )
          : await _readDocument<PokemonCatalogFile>(
              readBytes,
              path,
              family: 'catalog',
              decode: PokemonCatalogFile.fromJson,
              diagnostics: diagnostics,
              missingIsWarning: true,
            );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<PokemonCatalogDocument<T>>> _loadDirectory<T>(
    _PokemonDocumentReader readBytes,
    _PokemonDirectoryLister listFiles,
    String rawDirectory, {
    required String family,
    required T Function(Map<String, dynamic>) decode,
    required List<PokemonCatalogDiagnostic> diagnostics,
  }) async {
    final directory = _normalizePath(rawDirectory);
    final paths = await _listJsonFiles(
      listFiles,
      directory,
      family: family,
      diagnostics: diagnostics,
    );
    final documents = <PokemonCatalogDocument<T>>[];
    for (final path in paths) {
      final value = await _readDocument<T>(
        readBytes,
        path,
        family: family,
        decode: decode,
        diagnostics: diagnostics,
      );
      if (value != null) {
        documents.add(PokemonCatalogDocument(path: path, value: value));
      }
    }
    return documents;
  }

  Future<List<String>> _listJsonFiles(
    _PokemonDirectoryLister listFiles,
    String directory, {
    required String family,
    required List<PokemonCatalogDiagnostic> diagnostics,
  }) async {
    try {
      final listed = await listFiles(directory);
      if (listed == null) {
        diagnostics.add(
          PokemonCatalogDiagnostic(
            code: 'catalog.inventory_unavailable',
            severity: PokemonCatalogDiagnosticSeverity.warning,
            path: directory,
            message: 'The authoring reader cannot inventory Pokemon files.',
            recommendedAction:
                'Run validation through a reader with directory inventory support.',
          ),
        );
        return const [];
      }
      final paths = listed
          .where((path) => path.toLowerCase().endsWith('.json'))
          .map(_normalizePath)
          .toList(growable: false)
        ..sort();
      return paths;
    } on WorkspaceAccessException catch (error) {
      diagnostics.add(
        PokemonCatalogDiagnostic(
          code: '$family.directory_unreadable',
          severity: PokemonCatalogDiagnosticSeverity.warning,
          path: directory,
          message: error.message,
          recommendedAction:
              'Restore the Pokemon directory and validate again.',
        ),
      );
      return const [];
    }
  }

  Future<T?> _readDocument<T>(
    _PokemonDocumentReader readBytes,
    String path, {
    required String family,
    required T Function(Map<String, dynamic>) decode,
    required List<PokemonCatalogDiagnostic> diagnostics,
    bool missingIsWarning = false,
  }) async {
    try {
      final bytes = await readBytes(path);
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('Expected JSON object.');
      return decode(Map<String, dynamic>.from(decoded));
    } on UnsupportedPokemonDataSchema catch (error) {
      diagnostics.add(
        PokemonCatalogDiagnostic(
          code: '$family.schema_version_unsupported',
          severity: PokemonCatalogDiagnosticSeverity.error,
          path: '$path.schemaVersion',
          message: error.message,
          recommendedAction:
              'Use schemaVersion $currentPokemonDataSchemaVersion.',
        ),
      );
      return null;
    } on WorkspaceAccessException catch (error) {
      if (missingIsWarning && error.code == 'workspace.file_unavailable') {
        return null;
      }
      diagnostics.add(
        PokemonCatalogDiagnostic(
          code: '$family.read_error',
          severity: PokemonCatalogDiagnosticSeverity.error,
          path: path,
          message: error.message,
          recommendedAction: 'Restore the Pokemon document and validate again.',
        ),
      );
      return null;
    } on Object catch (error) {
      diagnostics.add(
        PokemonCatalogDiagnostic(
          code: '$family.read_error',
          severity: PokemonCatalogDiagnosticSeverity.error,
          path: path,
          message: 'Invalid JSON Pokemon document: $error',
          recommendedAction: 'Repair or replace the invalid Pokemon JSON.',
        ),
      );
      return null;
    }
  }
}

typedef _PokemonDocumentReader = Future<List<int>> Function(String path);
typedef _PokemonDirectoryLister = Future<List<String>?> Function(
  String directory,
);

PokemonCatalogFile _decodeItemCatalog(Map<String, dynamic> json) {
  if (json['schemaVersion'] != currentPokemonDataSchemaVersion) {
    throw UnsupportedPokemonDataSchema(
      actualVersion: json['schemaVersion'],
      path: r'$.schemaVersion',
    );
  }
  final catalog = ProjectItemCatalog.fromJson(json);
  return PokemonCatalogFile(
    schemaVersion: catalog.schemaVersion,
    kind: 'project_item_catalog',
    catalog: 'items',
    meta: const PokemonDataMeta(description: 'Project items'),
    entries: <Map<String, dynamic>>[
      for (final item in catalog.entries) <String, dynamic>{'id': item.id},
    ],
  );
}

String _normalizePath(String value) =>
    validateProjectRelativePath(value).join('/');
