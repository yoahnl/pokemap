import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

class PokemonItemsCatalogSyncResult {
  const PokemonItemsCatalogSyncResult({
    required this.dryRun,
    required this.externalEntryCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.downloadedSpriteIds,
    required this.skippedSpriteIds,
    required this.failedSpriteIds,
    required this.resultingEntryCount,
    this.warnings = const <String>[],
  });

  final bool dryRun;
  final int externalEntryCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> downloadedSpriteIds;
  final List<String> skippedSpriteIds;
  final List<String> failedSpriteIds;
  final int resultingEntryCount;
  final List<String> warnings;
}

class SyncExternalPokemonItemsCatalogUseCase {
  const SyncExternalPokemonItemsCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonItemsCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    bool dryRun = false,
    bool downloadSprites = false,
    bool overwriteSprites = false,
  }) async {
    final catalogRelativePath = await _resolveCatalogRelativePath(workspace);
    final assetsRootRelativePath = await _resolveItemsAssetsRootRelativePath(
      workspace,
    );
    final localCatalog = await _readLocalCatalogIfAvailable(
      workspace,
      catalogRelativePath: catalogRelativePath,
    );
    final externalCatalog = await _fetchExternalCatalog();
    final merge = await _mergeCatalogs(
      workspace,
      localCatalog: localCatalog,
      externalCatalog: externalCatalog.catalog,
      catalogRelativePath: catalogRelativePath,
      assetsRootRelativePath: assetsRootRelativePath,
      dryRun: dryRun,
      downloadSprites: downloadSprites,
      overwriteSprites: overwriteSprites,
      warnings: externalCatalog.warnings,
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

    return PokemonItemsCatalogSyncResult(
      dryRun: dryRun,
      externalEntryCount: externalCatalog.externalEntryCount,
      createdIds: merge.createdIds,
      updatedIds: merge.updatedIds,
      unchangedIds: merge.unchangedIds,
      preservedLocalOnlyIds: merge.preservedLocalOnlyIds,
      downloadedSpriteIds: merge.downloadedSpriteIds,
      skippedSpriteIds: merge.skippedSpriteIds,
      failedSpriteIds: merge.failedSpriteIds,
      resultingEntryCount: merge.catalog.entries.length,
      warnings: merge.warnings,
    );
  }

  Future<PokemonCatalogFile?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace, {
    required String catalogRelativePath,
  }) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'items');
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
          'Pokemon catalog "items" is not a JSON object: $catalogRelativePath',
        );
      }
      return PokemonCatalogFile.fromJson(decoded);
    } on EditorApplicationException {
      rethrow;
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in Pokemon catalog "items" at $catalogRelativePath: $error',
      );
    } catch (error) {
      throw EditorPersistenceException(
        'Failed to read Pokemon catalog "items" at $catalogRelativePath: $error',
      );
    }
  }

  Future<String> _resolveCatalogRelativePath(ProjectWorkspace workspace) async {
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
        final declaredPath = manifest.catalogFiles['items']?.trim();
        if (declaredPath != null && declaredPath.isNotEmpty) {
          return _resolvePathWithinPokemonDataRoot(
            pokemonConfig: pokemonConfig,
            rawRelativePath: declaredPath,
          );
        }
      }
    } on Object {
      final configuredPath = pokemonConfig.catalogFiles['items']?.trim();
      if (configuredPath != null && configuredPath.isNotEmpty) {
        return p.normalize(configuredPath);
      }
      return 'data/pokemon/catalogs/items.json';
    }

    final configuredPath = pokemonConfig.catalogFiles['items']?.trim();
    if (configuredPath != null && configuredPath.isNotEmpty) {
      return p.normalize(configuredPath);
    }

    return 'data/pokemon/catalogs/items.json';
  }

  Future<String> _resolveItemsAssetsRootRelativePath(
    ProjectWorkspace workspace,
  ) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );
    return p.normalize(p.join(dataRoot, 'assets/items'));
  }

  Future<_FetchedExternalItemsCatalog> _fetchExternalCatalog() async {
    const pageLimit = 200;
    final warnings = <String>[];
    final discoveredIds = <String>[];
    final seenIds = <String>{};

    for (var offset = 0;; offset += pageLimit) {
      final page = await externalSourceRepository.fetchPokeApiItemsResourceList(
        limit: pageLimit,
        offset: offset,
      );
      final results = _readResourceListResults(page);
      if (results.isEmpty) {
        break;
      }

      for (var index = 0; index < results.length; index++) {
        final resource = results[index];
        final itemId = _readItemResourceId(resource);
        if (itemId == null) {
          warnings.add(
            'Ignored an external item resource at index ${offset + index} because it did not expose a usable name or URL.',
          );
          continue;
        }
        if (!seenIds.add(itemId)) {
          warnings.add(
            'Ignored duplicate external item resource for id "$itemId".',
          );
          continue;
        }
        discoveredIds.add(itemId);
      }

      final next = page['next'];
      if (next == null || (next is String && next.trim().isEmpty)) {
        break;
      }
    }

    final convertedEntries = <Map<String, dynamic>>[];
    for (final itemId in discoveredIds) {
      try {
        final payload = await externalSourceRepository.fetchPokeApiItemPayload(
          itemId,
        );
        convertedEntries.add(_convertExternalItemPayload(payload));
      } on EditorApplicationException catch (error) {
        warnings.add('Ignored external item "$itemId": ${error.message}');
      } catch (error) {
        warnings.add('Ignored external item "$itemId": $error');
      }
    }

    convertedEntries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    return _FetchedExternalItemsCatalog(
      catalog: PokemonCatalogFile(
        schemaVersion: 1,
        kind: 'pokemon_catalog',
        catalog: 'items',
        meta: const PokemonDataMeta(
          description: 'Catalogue local des objets synchronisé depuis PokéAPI.',
          sourcePriority: <String>['pokeapi', 'local'],
        ),
        entries: convertedEntries,
      ),
      externalEntryCount: discoveredIds.length,
      warnings: warnings,
    );
  }

  List<Map<String, dynamic>> _readResourceListResults(
    Map<String, dynamic> payload,
  ) {
    final rawResults = payload['results'];
    if (rawResults == null) {
      return const <Map<String, dynamic>>[];
    }
    if (rawResults is! List) {
      throw const EditorPersistenceException(
        'PokeAPI item list payload must contain a "results" array.',
      );
    }

    final results = <Map<String, dynamic>>[];
    for (final entry in rawResults) {
      if (entry is! Map) {
        throw const EditorPersistenceException(
          'PokeAPI item list payload must contain only object results.',
        );
      }
      results.add(entry.cast<String, dynamic>());
    }
    return results;
  }

  String? _readItemResourceId(Map<String, dynamic> resource) {
    final rawName = resource['name'];
    if (rawName is String) {
      final normalized = rawName.trim().toLowerCase();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    final rawUrl = resource['url'];
    if (rawUrl is! String) {
      return null;
    }
    final trimmedUrl = rawUrl.trim();
    if (trimmedUrl.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmedUrl);
    final segments = uri?.pathSegments.where((segment) => segment.isNotEmpty);
    if (segments == null || segments.isEmpty) {
      return null;
    }
    return segments.last.trim().toLowerCase();
  }

  Map<String, dynamic> _convertExternalItemPayload(Map<String, dynamic> payload) {
    final id = _readRequiredSlug(payload, 'name');
    final names = _readLocalizedNames(payload);
    final displayName =
        _preferredLocalizedName(names) ?? _formatFallbackDisplayName(id);
    if (displayName.trim().isEmpty) {
      throw EditorPersistenceException(
        'PokeAPI item "$id" does not expose a usable display name.',
      );
    }

    final spriteUrl = _readOptionalSpriteUrl(payload, id: id);
    final categoryId = _readOptionalNamedResource(
      payload,
      'category',
      id: id,
    );
    final pocketId = _readOptionalString(payload, 'pocketId') ??
        _readOptionalNamedResource(payload, 'pocket', id: id);
    final cost = _readOptionalInt(payload, 'cost', id: id);
    final flingPower = _readOptionalInt(payload, 'flingPower', id: id) ??
        _readOptionalInt(payload, 'fling_power', id: id);
    final flingEffectId = _readOptionalString(payload, 'flingEffectId') ??
        _readOptionalNamedResource(payload, 'fling_effect', id: id);
    final shortEffectText = _readOptionalString(payload, 'shortEffectText') ??
        _readLocalizedEntryText(
          payload,
          listKey: 'effect_entries',
          textKey: 'short_effect',
          id: id,
        );
    final effectText = _readOptionalString(payload, 'effectText') ??
        _readLocalizedEntryText(
          payload,
          listKey: 'effect_entries',
          textKey: 'effect',
          id: id,
        );
    final flavorText = _readOptionalString(payload, 'flavorText') ??
        _readPreferredFlavorText(payload, id: id);

    final entry = <String, dynamic>{
      'id': id,
      'name': displayName,
      'source': 'pokeapi',
      'sourceRefs': <String, dynamic>{
        'pokeApiName': id,
      },
    };

    final pokeApiId = _readOptionalInt(payload, 'id', id: id);
    if (pokeApiId != null) {
      entry['pokeApiId'] = pokeApiId;
      (entry['sourceRefs'] as Map<String, dynamic>)['pokeApiItemId'] =
          pokeApiId;
    }
    if (names.isNotEmpty) {
      entry['names'] = names;
    }
    if (categoryId != null) {
      entry['categoryId'] = categoryId;
    }
    if (pocketId != null) {
      entry['pocketId'] = pocketId;
    }
    if (cost != null) {
      entry['cost'] = cost;
    }
    if (flingPower != null) {
      entry['flingPower'] = flingPower;
    }
    if (flingEffectId != null) {
      entry['flingEffectId'] = flingEffectId;
    }
    if (shortEffectText != null) {
      entry['shortEffectText'] = shortEffectText;
    }
    if (effectText != null) {
      entry['effectText'] = effectText;
    }
    if (flavorText != null) {
      entry['flavorText'] = flavorText;
    }
    if (spriteUrl != null) {
      entry['spriteUrl'] = spriteUrl;
    }

    return entry;
  }

  Future<_ItemsCatalogMerge> _mergeCatalogs(
    ProjectWorkspace workspace, {
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
    required String catalogRelativePath,
    required String assetsRootRelativePath,
    required bool dryRun,
    required bool downloadSprites,
    required bool overwriteSprites,
    required List<String> warnings,
  }) async {
    final mergedWarnings = <String>[...warnings];
    final localById = <String, Map<String, dynamic>>{};
    for (final entry in localCatalog?.entries ?? const <Map<String, dynamic>>[]) {
      final id = ((entry['id'] as String?)?.trim() ?? '');
      if (id.isEmpty) {
        continue;
      }
      localById[id] = await _sanitizeLocalEntryForMerge(workspace, entry);
    }

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final downloadedSpriteIds = <String>[];
    final skippedSpriteIds = <String>[];
    final failedSpriteIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    for (final externalEntry in externalCatalog.entries) {
      final id = ((externalEntry['id'] as String?)?.trim() ?? '');
      if (id.isEmpty) {
        continue;
      }
      final localEntry = localById.remove(id);
      final spriteOutcome = await _prepareSpriteState(
        workspace,
        externalEntry: externalEntry,
        localEntry: localEntry,
        assetsRootRelativePath: assetsRootRelativePath,
        dryRun: dryRun,
        downloadSprites: downloadSprites,
        overwriteSprites: overwriteSprites,
      );
      if (spriteOutcome.downloadedId != null) {
        downloadedSpriteIds.add(spriteOutcome.downloadedId!);
      }
      if (spriteOutcome.skippedId != null) {
        skippedSpriteIds.add(spriteOutcome.skippedId!);
      }
      if (spriteOutcome.failedId != null) {
        failedSpriteIds.add(spriteOutcome.failedId!);
      }
      mergedWarnings.addAll(spriteOutcome.warnings);

      final normalizedExternalEntry = _deepCopy(externalEntry);
      if (spriteOutcome.localSpritePath != null) {
        normalizedExternalEntry['localSpritePath'] = spriteOutcome.localSpritePath;
      }

      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(normalizedExternalEntry);
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: normalizedExternalEntry,
      );
      if (_jsonDeepEquals(localEntry, mergedEntry)) {
        unchangedIds.add(id);
      } else {
        updatedIds.add(id);
      }
      mergedEntries.add(mergedEntry);
    }

    final preservedLocalOnlyIds = localById.keys.toList(growable: false)
      ..sort();
    for (final id in preservedLocalOnlyIds) {
      mergedEntries.add(_deepCopy(localById[id]!));
    }

    mergedEntries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    if (preservedLocalOnlyIds.isNotEmpty) {
      mergedWarnings.add(
        'Local item entries absent from the external snapshot were preserved unchanged.',
      );
    }

    return _ItemsCatalogMerge(
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
      downloadedSpriteIds: downloadedSpriteIds,
      skippedSpriteIds: skippedSpriteIds,
      failedSpriteIds: failedSpriteIds,
      warnings: mergedWarnings,
    );
  }

  Future<Map<String, dynamic>> _sanitizeLocalEntryForMerge(
    ProjectWorkspace workspace,
    Map<String, dynamic> entry,
  ) async {
    final sanitized = _deepCopy(entry);
    final localSpritePath = sanitized['localSpritePath'];
    if (localSpritePath is! String || localSpritePath.trim().isEmpty) {
      sanitized.remove('localSpritePath');
      return sanitized;
    }

    final absoluteSpritePath = workspace.resolveProjectRelativePath(
      localSpritePath,
    );
    if (!await workspace.fileExists(absoluteSpritePath)) {
      sanitized.remove('localSpritePath');
    }
    return sanitized;
  }

  Future<_ItemSpritePreparationResult> _prepareSpriteState(
    ProjectWorkspace workspace, {
    required Map<String, dynamic> externalEntry,
    required Map<String, dynamic>? localEntry,
    required String assetsRootRelativePath,
    required bool dryRun,
    required bool downloadSprites,
    required bool overwriteSprites,
  }) async {
    final id = (externalEntry['id'] as String).trim();
    final spriteUrl = (externalEntry['spriteUrl'] as String?)?.trim();
    final targetRelativePath = p.normalize(p.join(assetsRootRelativePath, '$id.png'));
    final absoluteTargetPath = workspace.resolveProjectRelativePath(
      targetRelativePath,
    );
    final localSpritePath = localEntry?['localSpritePath'] as String?;
    final hasExistingTarget = await workspace.fileExists(absoluteTargetPath);

    if (!downloadSprites || dryRun) {
      return const _ItemSpritePreparationResult();
    }

    if (spriteUrl == null || spriteUrl.isEmpty) {
      return _ItemSpritePreparationResult(
        skippedId: id,
        localSpritePath: localSpritePath,
      );
    }

    if (hasExistingTarget && !overwriteSprites) {
      return _ItemSpritePreparationResult(
        skippedId: id,
        localSpritePath: targetRelativePath,
      );
    }

    try {
      final asset = await externalSourceRepository.fetchBinaryAsset(spriteUrl);
      await writeRepository.saveBinaryAsset(
        workspace,
        relativePath: targetRelativePath,
        bytes: asset.bytes,
      );
      if (!await workspace.fileExists(absoluteTargetPath)) {
        return _ItemSpritePreparationResult(
          failedId: id,
          localSpritePath: localSpritePath,
          warnings: <String>[
            'Sprite download for "$id" completed but no local file was found afterwards.',
          ],
        );
      }
      return _ItemSpritePreparationResult(
        downloadedId: id,
        localSpritePath: targetRelativePath,
      );
    } on EditorApplicationException catch (error) {
      return _ItemSpritePreparationResult(
        failedId: id,
        localSpritePath: localSpritePath,
        warnings: <String>[
          'Sprite download failed for "$id": ${error.message}',
        ],
      );
    } catch (error) {
      return _ItemSpritePreparationResult(
        failedId: id,
        localSpritePath: localSpritePath,
        warnings: <String>[
          'Sprite download failed for "$id": $error',
        ],
      );
    }
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

      if ((key == 'names' || key == 'sourceRefs') &&
          localValue is Map &&
          externalValue is Map<String, dynamic>) {
        merged[key] = _mergeStringKeyedMaps(localValue, externalValue);
        continue;
      }

      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      merged.putIfAbsent(
        localField.key,
        () => _deepCopyValue(localField.value),
      );
    }

    return merged;
  }

  Map<String, dynamic> _mergeStringKeyedMaps(
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
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
  }

  bool _jsonDeepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }
      for (final key in left.keys) {
        if (!right.containsKey(key)) {
          return false;
        }
        if (!_jsonDeepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_jsonDeepEquals(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}

class _FetchedExternalItemsCatalog {
  const _FetchedExternalItemsCatalog({
    required this.catalog,
    required this.externalEntryCount,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final int externalEntryCount;
  final List<String> warnings;
}

class _ItemsCatalogMerge {
  const _ItemsCatalogMerge({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.downloadedSpriteIds,
    required this.skippedSpriteIds,
    required this.failedSpriteIds,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> downloadedSpriteIds;
  final List<String> skippedSpriteIds;
  final List<String> failedSpriteIds;
  final List<String> warnings;
}

class _ItemSpritePreparationResult {
  const _ItemSpritePreparationResult({
    this.downloadedId,
    this.skippedId,
    this.failedId,
    this.localSpritePath,
    this.warnings = const <String>[],
  });

  final String? downloadedId;
  final String? skippedId;
  final String? failedId;
  final String? localSpritePath;
  final List<String> warnings;
}

String _readRequiredSlug(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is! String) {
    throw EditorPersistenceException(
      'PokeAPI item payload field "$key" must be a non-empty string.',
    );
  }
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    throw EditorPersistenceException(
      'PokeAPI item payload field "$key" must be a non-empty string.',
    );
  }
  return normalized;
}

Map<String, String> _readLocalizedNames(Map<String, dynamic> payload) {
  final value = payload['names'];
  if (value == null) {
    return const <String, String>{};
  }
  if (value is Map) {
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const EditorPersistenceException(
          'PokeAPI item payload field "names" must be a string map or a list of localized entries.',
        );
      }
      final trimmedValue = (entry.value as String).trim();
      if (trimmedValue.isNotEmpty) {
        result[entry.key as String] = trimmedValue;
      }
    }
    return result;
  }
  if (value is! List) {
    throw const EditorPersistenceException(
      'PokeAPI item payload field "names" must be a string map or a list of localized entries.',
    );
  }

  final result = <String, String>{};
  for (final element in value) {
    if (element is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI item payload field "names" must be a string map or a list of localized entries.',
      );
    }
    final nameValue = element['name'];
    if (nameValue != null && nameValue is! String) {
      throw const EditorPersistenceException(
        'PokeAPI item payload field "names" contains an invalid localized name.',
      );
    }
    final language = element['language'];
    if (language != null && language is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI item payload field "names" contains an invalid language value.',
      );
    }
    final languageName = (language as Map?)?['name'];
    if (languageName != null && languageName is! String) {
      throw const EditorPersistenceException(
        'PokeAPI item payload field "names" contains an invalid language value.',
      );
    }
    final normalizedName = (nameValue as String?)?.trim();
    final normalizedLanguage = (languageName as String?)?.trim();
    if (normalizedName == null ||
        normalizedName.isEmpty ||
        normalizedLanguage == null ||
        normalizedLanguage.isEmpty) {
      continue;
    }
    result[normalizedLanguage] = normalizedName;
  }
  return result;
}

String? _preferredLocalizedName(Map<String, String> names) {
  final english = names['en']?.trim();
  if (english != null && english.isNotEmpty) {
    return english;
  }
  for (final value in names.values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return null;
}

String _formatFallbackDisplayName(String slug) {
  return slug
      .split(RegExp(r'[-_]+'))
      .where((segment) => segment.trim().isNotEmpty)
      .map(
        (segment) =>
            '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String? _readOptionalString(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw EditorPersistenceException(
      'PokeAPI item payload field "$key" must be a string when present.',
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _readOptionalInt(
  Map<String, dynamic> payload,
  String key, {
  required String id,
}) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "$key" value.',
    );
  }
  return value.toInt();
}

String? _readOptionalNamedResource(
  Map<String, dynamic> payload,
  String key, {
  required String id,
}) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is! Map) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "$key" value.',
    );
  }
  final name = value['name'];
  if (name == null) {
    return null;
  }
  if (name is! String) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "$key" value.',
    );
  }
  final trimmed = name.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _readLocalizedEntryText(
  Map<String, dynamic> payload, {
  required String listKey,
  required String textKey,
  required String id,
}) {
  final value = payload[listKey];
  if (value == null) {
    return null;
  }
  if (value is! List) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "$listKey" value.',
    );
  }

  String? fallback;
  for (final element in value) {
    if (element is! Map) {
      throw EditorPersistenceException(
        'PokeAPI item "$id" has an invalid "$listKey" value.',
      );
    }
    final textValue = element[textKey];
    if (textValue != null && textValue is! String) {
      throw EditorPersistenceException(
        'PokeAPI item "$id" has an invalid "$listKey" value.',
      );
    }
    final normalizedText = (textValue as String?)?.trim();
    if (normalizedText == null || normalizedText.isEmpty) {
      continue;
    }
    final languageName = _readLanguageName(element);
    if (languageName == 'en') {
      return normalizedText;
    }
    fallback ??= normalizedText;
  }
  return fallback;
}

String? _readPreferredFlavorText(
  Map<String, dynamic> payload, {
  required String id,
}) {
  final value = payload['flavor_text_entries'];
  if (value == null) {
    return null;
  }
  if (value is! List) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "flavor_text_entries" value.',
    );
  }

  String? fallback;
  String? lastEnglish;
  for (final element in value) {
    if (element is! Map) {
      throw EditorPersistenceException(
        'PokeAPI item "$id" has an invalid "flavor_text_entries" value.',
      );
    }
    final textValue = element['text'];
    if (textValue != null && textValue is! String) {
      throw EditorPersistenceException(
        'PokeAPI item "$id" has an invalid "flavor_text_entries" value.',
      );
    }
    final normalizedText = (textValue as String?)?.trim();
    if (normalizedText == null || normalizedText.isEmpty) {
      continue;
    }
    final languageName = _readLanguageName(element);
    if (languageName == 'en') {
      lastEnglish = normalizedText;
    }
    fallback ??= normalizedText;
  }
  return lastEnglish ?? fallback;
}

String? _readOptionalSpriteUrl(
  Map<String, dynamic> payload, {
  required String id,
}) {
  final direct = _readOptionalString(payload, 'spriteUrl');
  if (direct != null) {
    return direct;
  }
  final sprites = payload['sprites'];
  if (sprites == null) {
    return null;
  }
  if (sprites is! Map) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "sprites" value.',
    );
  }
  final defaultUrl = sprites['default'];
  if (defaultUrl == null) {
    return null;
  }
  if (defaultUrl is! String) {
    throw EditorPersistenceException(
      'PokeAPI item "$id" has an invalid "sprites" value.',
    );
  }
  final trimmed = defaultUrl.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _readLanguageName(Map<Object?, Object?> entry) {
  final language = entry['language'];
  if (language == null) {
    return null;
  }
  if (language is! Map) {
    return null;
  }
  final name = language['name'];
  if (name is! String) {
    return null;
  }
  final trimmed = name.trim();
  return trimmed.isEmpty ? null : trimmed;
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
