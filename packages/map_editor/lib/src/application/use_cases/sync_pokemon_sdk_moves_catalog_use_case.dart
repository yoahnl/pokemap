import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/pokemon_sdk_move_catalog_converter.dart';

final class PokemonSdkMovesCatalogSyncResult {
  const PokemonSdkMovesCatalogSyncResult({
    required this.dryRun,
    required this.externalEntryCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.resultingEntryCount,
    this.warnings = const <String>[],
  });

  final bool dryRun;
  final int externalEntryCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final int resultingEntryCount;
  final List<String> warnings;
}

final class SyncPokemonSdkMovesCatalogUseCase {
  const SyncPokemonSdkMovesCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
    this.converter = const PokemonSdkMoveCatalogConverter(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;
  final PokemonSdkMoveCatalogConverter converter;

  Future<PokemonSdkMovesCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    required String psdkProjectRootPath,
    bool dryRun = false,
  }) async {
    final catalogRelativePath = await _resolveMovesCatalogRelativePath(
      workspace,
    );
    final studioPayload = await externalSourceRepository
        .fetchPokemonSdkStudioProjectPayload(psdkProjectRootPath);
    final externalCatalog = converter.convertCatalog(
      studioPayload.moves.cast<Map<String, Object?>>(),
    );
    final localCatalog = await _readLocalCatalogIfAvailable(
      workspace,
      catalogRelativePath: catalogRelativePath,
    );
    final merge = _mergeCatalogs(
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
    );

    if (!dryRun) {
      final absoluteCatalogPath = workspace.resolveProjectRelativePath(
        catalogRelativePath,
      );
      await workspace.writeTextFile(
        absoluteCatalogPath,
        const JsonEncoder.withIndent('  ').convert(merge.catalog.toJson()),
      );
    }

    return PokemonSdkMovesCatalogSyncResult(
      dryRun: dryRun,
      externalEntryCount: externalCatalog.entries.length,
      createdIds: merge.createdIds,
      updatedIds: merge.updatedIds,
      unchangedIds: merge.unchangedIds,
      preservedLocalOnlyIds: merge.preservedLocalOnlyIds,
      resultingEntryCount: merge.catalog.entries.length,
      warnings: merge.warnings,
    );
  }

  Future<PokemonCatalogFile?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace, {
    required String catalogRelativePath,
  }) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'moves');
    } on EditorNotFoundException {
      return _readCatalogAtResolvedPathIfPresent(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
    } on EditorApplicationException {
      return _readCatalogAtResolvedPathIfPresent(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
    }
  }

  Future<PokemonCatalogFile?> _readCatalogAtResolvedPathIfPresent(
    ProjectWorkspace workspace, {
    required String catalogRelativePath,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(
      catalogRelativePath,
    );
    if (!await workspace.fileExists(absolutePath)) {
      return null;
    }

    try {
      final raw = await workspace.readTextFile(absolutePath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          'Pokemon catalog "moves" is not a JSON object: $catalogRelativePath',
        );
      }
      return PokemonCatalogFile.fromJson(decoded);
    } on EditorApplicationException {
      rethrow;
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in Pokemon catalog "moves" at $catalogRelativePath: $error',
      );
    } catch (error) {
      throw EditorPersistenceException(
        'Failed to read Pokemon catalog "moves" at $catalogRelativePath: $error',
      );
    }
  }

  _PokemonSdkMovesCatalogMerge _mergeCatalogs({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localByDbSymbol = <String, Map<String, dynamic>>{};
    final localOnlyById = <String, Map<String, dynamic>>{};
    for (final entry
        in localCatalog?.entries ?? const <Map<String, dynamic>>[]) {
      final dbSymbol = _entryDbSymbol(entry);
      if (dbSymbol.isNotEmpty) {
        localByDbSymbol[dbSymbol] = _deepCopy(entry);
        continue;
      }
      final id = _entryId(entry);
      if (id.isNotEmpty) {
        localOnlyById[id] = _deepCopy(entry);
      }
    }

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    final externalEntries = externalCatalog.entries.toList(growable: false)
      ..sort((left, right) => _entryDbSymbol(left).compareTo(
            _entryDbSymbol(right),
          ));
    for (final externalEntry in externalEntries) {
      final dbSymbol = _entryDbSymbol(externalEntry);
      final id = _entryId(externalEntry);
      final localEntry = localByDbSymbol.remove(dbSymbol);
      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(_deepCopy(externalEntry));
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: externalEntry,
      );
      if (_jsonDeepEquals(localEntry, mergedEntry)) {
        unchangedIds.add(id);
      } else {
        updatedIds.add(id);
      }
      mergedEntries.add(mergedEntry);
    }

    final preservedLocalOnlyIds = <String>[
      ...localOnlyById.keys,
      ...localByDbSymbol.values.map(_entryId),
    ]..sort();
    for (final id in localOnlyById.keys.toList(growable: false)..sort()) {
      mergedEntries.add(_deepCopy(localOnlyById[id]!));
    }
    for (final entry in localByDbSymbol.values.toList(growable: false)
      ..sort((left, right) => _entryId(left).compareTo(_entryId(right)))) {
      mergedEntries.add(_deepCopy(entry));
    }

    mergedEntries.sort(
      (left, right) => _entryId(left).compareTo(_entryId(right)),
    );

    return _PokemonSdkMovesCatalogMerge(
      catalog: PokemonCatalogFile(
        schemaVersion: externalCatalog.schemaVersion,
        kind: externalCatalog.kind,
        catalog: externalCatalog.catalog,
        meta: _buildMergedMeta(
          localMeta: localCatalog?.meta,
          externalMeta: externalCatalog.meta,
        ),
        entries: mergedEntries,
      ),
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      warnings: preservedLocalOnlyIds.isEmpty
          ? const <String>[]
          : const <String>[
              'Local move entries absent from Pokemon SDK Studio were preserved unchanged.',
            ],
    );
  }

  PokemonDataMeta _buildMergedMeta({
    required PokemonDataMeta? localMeta,
    required PokemonDataMeta externalMeta,
  }) {
    final notes = <String>[
      ...externalMeta.notes,
      if (localMeta != null)
        ...localMeta.notes.where(
          (note) => !externalMeta.notes.contains(note),
        ),
    ];

    return PokemonDataMeta(
      description: externalMeta.description,
      sourcePriority: externalMeta.sourcePriority,
      notes: notes,
    );
  }

  Map<String, dynamic> _mergeEntry({
    required Map<String, dynamic> localEntry,
    required Map<String, dynamic> externalEntry,
  }) {
    final merged = <String, dynamic>{};
    for (final externalField in externalEntry.entries) {
      final key = externalField.key;
      final externalValue = externalField.value;
      final localValue = localEntry[key];
      if (key == 'names' &&
          localValue is Map &&
          externalValue is Map<String, dynamic>) {
        merged[key] = _mergeNames(localValue, externalValue);
        continue;
      }
      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      if (_obsoleteLegacyMoveFields.contains(localField.key)) {
        continue;
      }
      merged.putIfAbsent(
        localField.key,
        () => _deepCopyValue(localField.value),
      );
    }

    return merged;
  }

  Map<String, dynamic> _mergeNames(
    Map localValue,
    Map<String, dynamic> externalValue,
  ) {
    final merged = <String, dynamic>{
      for (final entry in localValue.entries)
        if (entry.key is String)
          entry.key as String: _deepCopyValue(entry.value),
    };
    for (final entry in externalValue.entries) {
      merged[entry.key] = _deepCopyValue(entry.value);
    }
    return merged;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  }

  Object? _deepCopyValue(Object? value) {
    if (value == null) return null;
    return jsonDecode(jsonEncode(value));
  }

  bool _jsonDeepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final key in left.keys) {
        if (!right.containsKey(key)) return false;
        if (!_jsonDeepEquals(left[key], right[key])) return false;
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_jsonDeepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    return left == right;
  }
}

String _entryDbSymbol(Map<String, dynamic> entry) {
  final value = entry['dbSymbol'] ?? entry['db_symbol'];
  return value is String ? value.trim() : '';
}

String _entryId(Map<String, dynamic> entry) {
  final id = entry['id'];
  if (id is String && id.trim().isNotEmpty) return id.trim();
  return _entryDbSymbol(entry);
}

Future<String> _resolveMovesCatalogRelativePath(
  ProjectWorkspace workspace,
) async {
  final pokemonConfig = await _readProjectPokemonConfig(workspace);
  final dataRoot = _normalizeConfiguredRelativePath(
    pokemonConfig.dataRoot,
    fallback: 'data/pokemon',
  );

  try {
    final manifestPath = workspace.resolveProjectRelativePath(
      p.normalize(p.join(dataRoot, 'pokemon_data_manifest.json')),
    );
    if (await workspace.fileExists(manifestPath)) {
      final manifestRaw = await workspace.readTextFile(manifestPath);
      final manifest = PokemonDataManifest.fromJson(
        (jsonDecode(manifestRaw) as Map).cast<String, dynamic>(),
      );
      final declaredPath = manifest.catalogFiles['moves']?.trim();
      if (declaredPath != null && declaredPath.isNotEmpty) {
        return _resolvePathWithinPokemonDataRoot(
          pokemonConfig: pokemonConfig,
          rawRelativePath: declaredPath,
        );
      }
    }
  } on Object {
    final configuredPath = pokemonConfig.catalogFiles['moves']?.trim();
    if (configuredPath != null && configuredPath.isNotEmpty) {
      return p.normalize(configuredPath);
    }
    return 'data/pokemon/catalogs/moves.json';
  }

  final configuredPath = pokemonConfig.catalogFiles['moves']?.trim();
  if (configuredPath != null && configuredPath.isNotEmpty) {
    return p.normalize(configuredPath);
  }

  return 'data/pokemon/catalogs/moves.json';
}

Future<ProjectPokemonConfig> _readProjectPokemonConfig(
  ProjectWorkspace workspace,
) async {
  final manifestPath = workspace.projectManifestPath;
  try {
    if (!await workspace.fileExists(manifestPath)) {
      return const ProjectPokemonConfig();
    }

    final raw = await workspace.readTextFile(manifestPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw EditorPersistenceException(
        'Project manifest is not a JSON object: $manifestPath',
      );
    }
    final project = ProjectManifest.fromJson(decoded);
    return project.pokemon;
  } on EditorPersistenceException {
    rethrow;
  } on FormatException catch (error) {
    throw EditorPersistenceException(
      'Invalid JSON in project manifest at $manifestPath: $error',
    );
  } catch (error) {
    throw EditorPersistenceException(
      'Invalid project manifest at $manifestPath: $error',
    );
  }
}

String _normalizeConfiguredRelativePath(
  String rawRelativePath, {
  required String fallback,
}) {
  final trimmed = rawRelativePath.trim();
  return p.normalize(trimmed.isEmpty ? fallback : trimmed);
}

String _resolvePathWithinPokemonDataRoot({
  required ProjectPokemonConfig pokemonConfig,
  required String rawRelativePath,
}) {
  final normalizedPath = p.normalize(rawRelativePath.trim());
  final dataRoot = _normalizeConfiguredRelativePath(
    pokemonConfig.dataRoot,
    fallback: 'data/pokemon',
  );
  if (normalizedPath == dataRoot || normalizedPath.startsWith('$dataRoot/')) {
    return normalizedPath;
  }
  return p.normalize(p.join(dataRoot, normalizedPath));
}

const Set<String> _obsoleteLegacyMoveFields = <String>{
  'power',
  'accuracyText',
  'shortDesc',
};

final class _PokemonSdkMovesCatalogMerge {
  const _PokemonSdkMovesCatalogMerge({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> warnings;
}
