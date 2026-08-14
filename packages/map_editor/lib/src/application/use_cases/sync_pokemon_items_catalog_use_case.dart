import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../ports/pokemon_external_source_repository.dart';
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
    required this.writeRepository,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
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
      catalogRelativePath,
    );
    final externalCatalog = await _fetchExternalCatalog();
    final merge = await _mergeCatalogs(
      workspace,
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
      assetsRootRelativePath: assetsRootRelativePath,
      dryRun: dryRun,
      downloadSprites: downloadSprites,
      overwriteSprites: overwriteSprites,
    );

    if (!dryRun) {
      final absolutePath = workspace.resolveProjectRelativePath(
        catalogRelativePath,
      );
      await workspace.ensureDirectoryExists(p.dirname(absolutePath));
      await workspace.writeTextFile(
        absolutePath,
        const JsonEncoder.withIndent(
          '  ',
        ).convert(encodeProjectItemCatalog(merge.catalog)),
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

  Future<ProjectItemCatalog?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace,
    String catalogRelativePath,
  ) async {
    final absolutePath = workspace.resolveProjectRelativePath(
      catalogRelativePath,
    );
    if (!await workspace.fileExists(absolutePath)) {
      return null;
    }
    return decodeProjectItemCatalog(
      jsonDecode(await workspace.readTextFile(absolutePath)),
    );
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
      for (var index = 0; index < results.length; index += 1) {
        final itemId = _readItemResourceId(results[index]);
        if (itemId == null) {
          warnings.add(
            'Ignored external item resource at index ${offset + index}: missing id.',
          );
          continue;
        }
        if (!seenIds.add(itemId)) {
          warnings.add('Ignored duplicate external item resource "$itemId".');
          continue;
        }
        discoveredIds.add(itemId);
      }
      final next = page['next'];
      if (next == null || (next is String && next.trim().isEmpty)) {
        break;
      }
    }

    final entries = <_ExternalItemCandidate>[];
    for (final itemId in discoveredIds) {
      try {
        final payload = await externalSourceRepository.fetchPokeApiItemPayload(
          itemId,
        );
        final candidate = _convertExternalItemPayload(payload);
        entries.add(candidate);
        for (final field in candidate.unconsumedFields) {
          warnings.add(
            'External item "${candidate.definition.id}" field "$field" was not consumed.',
          );
        }
      } on EditorApplicationException catch (error) {
        warnings.add('Ignored external item "$itemId": ${error.message}');
      } catch (error) {
        warnings.add('Ignored external item "$itemId": $error');
      }
    }
    entries.sort(
      (left, right) => left.definition.id.compareTo(right.definition.id),
    );
    return _FetchedExternalItemsCatalog(
      entries: entries,
      externalEntryCount: discoveredIds.length,
      warnings: warnings,
    );
  }

  Future<_ItemsCatalogMerge> _mergeCatalogs(
    ProjectWorkspace workspace, {
    required ProjectItemCatalog? localCatalog,
    required _FetchedExternalItemsCatalog externalCatalog,
    required String assetsRootRelativePath,
    required bool dryRun,
    required bool downloadSprites,
    required bool overwriteSprites,
  }) async {
    final localById = <String, ProjectItemDefinition>{};
    for (final item
        in localCatalog?.entries ?? const <ProjectItemDefinition>[]) {
      if (localById.containsKey(item.id)) {
        throw ProjectItemCatalogCodecException(
          code: ProjectItemCatalogCodecErrorCode.invalidValue,
          message: 'Duplicate local item id: ${item.id}',
          path: r'$.entries',
          itemId: item.id,
        );
      }
      localById[item.id] = item;
    }

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final downloadedSpriteIds = <String>[];
    final skippedSpriteIds = <String>[];
    final failedSpriteIds = <String>[];
    final warnings = <String>[...externalCatalog.warnings];
    final mergedEntries = <ProjectItemDefinition>[];

    for (final candidate in externalCatalog.entries) {
      final externalItem = candidate.definition;
      final localItem = localById.remove(externalItem.id);
      final mergedItem = localItem == null
          ? externalItem
          : _mergeDefinition(localItem, externalItem);
      if (localItem == null) {
        createdIds.add(externalItem.id);
      } else if (localItem == mergedItem) {
        unchangedIds.add(externalItem.id);
      } else {
        updatedIds.add(externalItem.id);
      }
      mergedEntries.add(mergedItem);

      final spriteResult = await _syncSprite(
        workspace,
        candidate: candidate,
        assetsRootRelativePath: assetsRootRelativePath,
        dryRun: dryRun,
        downloadSprites: downloadSprites,
        overwriteSprites: overwriteSprites,
      );
      if (spriteResult.downloaded) {
        downloadedSpriteIds.add(externalItem.id);
      }
      if (spriteResult.skipped) {
        skippedSpriteIds.add(externalItem.id);
      }
      if (spriteResult.failed) {
        failedSpriteIds.add(externalItem.id);
      }
      if (spriteResult.warning case final warning?) {
        warnings.add(warning);
      }
    }

    final preservedLocalOnlyIds = localById.keys.toList(growable: false)
      ..sort();
    for (final itemId in preservedLocalOnlyIds) {
      mergedEntries.add(localById[itemId]!);
    }
    if (preservedLocalOnlyIds.isNotEmpty) {
      warnings.add(
        'Local item definitions absent from the external snapshot were preserved.',
      );
    }
    mergedEntries.sort((left, right) => left.id.compareTo(right.id));

    return _ItemsCatalogMerge(
      catalog: ProjectItemCatalog(
        schemaVersion: 1,
        entries: mergedEntries,
      ).normalized(),
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      downloadedSpriteIds: downloadedSpriteIds,
      skippedSpriteIds: skippedSpriteIds,
      failedSpriteIds: failedSpriteIds,
      warnings: warnings,
    );
  }

  ProjectItemDefinition _mergeDefinition(
    ProjectItemDefinition local,
    ProjectItemDefinition external,
  ) {
    return local.copyWith(
      displayName: external.displayName,
      aliases: {
        ...local.aliases,
        ...external.aliases,
      }.toList(growable: false),
      pocketId: external.pocketId,
      description: external.description ?? local.description,
      buyPrice: external.buyPrice ?? local.buyPrice,
      tags: {...local.tags, ...external.tags},
    ).normalized();
  }

  Future<_SpriteSyncResult> _syncSprite(
    ProjectWorkspace workspace, {
    required _ExternalItemCandidate candidate,
    required String assetsRootRelativePath,
    required bool dryRun,
    required bool downloadSprites,
    required bool overwriteSprites,
  }) async {
    if (!downloadSprites || dryRun) {
      return const _SpriteSyncResult();
    }
    final spriteUrl = candidate.spriteUrl;
    if (spriteUrl == null || spriteUrl.isEmpty) {
      return const _SpriteSyncResult(skipped: true);
    }
    final relativePath = p.normalize(
      p.join(assetsRootRelativePath, '${candidate.definition.id}.png'),
    );
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    if (await workspace.fileExists(absolutePath) && !overwriteSprites) {
      return const _SpriteSyncResult(skipped: true);
    }
    try {
      final asset = await externalSourceRepository.fetchBinaryAsset(spriteUrl);
      await writeRepository.saveBinaryAsset(
        workspace,
        relativePath: relativePath,
        bytes: asset.bytes,
      );
      if (!await workspace.fileExists(absolutePath)) {
        return _SpriteSyncResult(
          failed: true,
          warning:
              'Sprite download for "${candidate.definition.id}" produced no local file.',
        );
      }
      return const _SpriteSyncResult(downloaded: true);
    } catch (error) {
      return _SpriteSyncResult(
        failed: true,
        warning:
            'Sprite download for "${candidate.definition.id}" failed: $error',
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
        final manifest = PokemonDataManifest.fromJson(
          (jsonDecode(await workspace.readTextFile(manifestPath)) as Map)
              .cast<String, dynamic>(),
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
    return configuredPath == null || configuredPath.isEmpty
        ? 'data/pokemon/catalogs/items.json'
        : p.normalize(configuredPath);
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
}

final class _ExternalItemCandidate {
  const _ExternalItemCandidate({
    required this.definition,
    required this.unconsumedFields,
    this.spriteUrl,
  });

  final ProjectItemDefinition definition;
  final String? spriteUrl;
  final Set<String> unconsumedFields;
}

final class _FetchedExternalItemsCatalog {
  const _FetchedExternalItemsCatalog({
    required this.entries,
    required this.externalEntryCount,
    required this.warnings,
  });

  final List<_ExternalItemCandidate> entries;
  final int externalEntryCount;
  final List<String> warnings;
}

final class _ItemsCatalogMerge {
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

  final ProjectItemCatalog catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> downloadedSpriteIds;
  final List<String> skippedSpriteIds;
  final List<String> failedSpriteIds;
  final List<String> warnings;
}

final class _SpriteSyncResult {
  const _SpriteSyncResult({
    this.downloaded = false,
    this.skipped = false,
    this.failed = false,
    this.warning,
  });

  final bool downloaded;
  final bool skipped;
  final bool failed;
  final String? warning;
}

_ExternalItemCandidate _convertExternalItemPayload(
  Map<String, dynamic> payload,
) {
  final id = _readRequiredSlug(payload, 'name');
  final names = _readLocalizedNames(payload, id);
  final displayName = _preferredLocalizedName(names) ?? _formatDisplayName(id);
  final categoryId = _readNamedResource(payload, 'category', id);
  final pocketId =
      _readNamedResource(payload, 'pocket', id) ?? categoryId ?? 'items';
  final description = _readLocalizedText(
        payload,
        listKey: 'flavor_text_entries',
        textKey: 'text',
        id: id,
      ) ??
      _readLocalizedText(
        payload,
        listKey: 'effect_entries',
        textKey: 'effect',
        id: id,
      );
  final aliases = names.values
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty && name != displayName)
      .toSet()
      .toList(growable: false);
  final spriteUrl = _readSpriteUrl(payload, id);
  final consumedFields = {
    'id',
    'name',
    'names',
    'category',
    'pocket',
    'cost',
    'effect_entries',
    'flavor_text_entries',
    'sprites',
  };
  return _ExternalItemCandidate(
    definition: ProjectItemDefinition(
      id: id,
      displayName: displayName,
      aliases: aliases,
      pocketId: pocketId,
      description: description,
      buyPrice: _readOptionalInt(payload, 'cost', id),
      tags: {if (categoryId != null) 'category:$categoryId', 'source:pokeapi'},
    ).normalized(),
    spriteUrl: spriteUrl,
    unconsumedFields:
        payload.keys.where((field) => !consumedFields.contains(field)).toSet(),
  );
}

List<Map<String, dynamic>> _readResourceListResults(
  Map<String, dynamic> payload,
) {
  final rawResults = payload['results'];
  if (rawResults == null) {
    return const [];
  }
  if (rawResults is! List) {
    throw const EditorPersistenceException(
      'PokeAPI item list results must be a list.',
    );
  }
  return rawResults.map((entry) {
    if (entry is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI item list entries must be objects.',
      );
    }
    return entry.cast<String, dynamic>();
  }).toList(growable: false);
}

String? _readItemResourceId(Map<String, dynamic> resource) {
  final name = resource['name'];
  if (name is String && name.trim().isNotEmpty) {
    return name.trim().toLowerCase();
  }
  final url = resource['url'];
  if (url is! String) {
    return null;
  }
  final segments = Uri.tryParse(
    url,
  )?.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();
  return segments == null || segments.isEmpty
      ? null
      : segments.last.trim().toLowerCase();
}

String _readRequiredSlug(Map<String, dynamic> payload, String key) {
  final value = payload[key];
  if (value is! String || value.trim().isEmpty) {
    throw EditorPersistenceException(
      'External item field "$key" must be a non-empty string.',
    );
  }
  return value.trim().toLowerCase();
}

Map<String, String> _readLocalizedNames(
  Map<String, dynamic> payload,
  String id,
) {
  final rawNames = payload['names'];
  if (rawNames == null) {
    return const {};
  }
  if (rawNames is! List) {
    throw EditorPersistenceException(
      'External item "$id" names must be a list.',
    );
  }
  final names = <String, String>{};
  for (final rawName in rawNames) {
    if (rawName is! Map) {
      continue;
    }
    final language = rawName['language'];
    final languageId = language is Map ? language['name'] : null;
    final name = rawName['name'];
    if (languageId is String && name is String && name.trim().isNotEmpty) {
      names[languageId.trim()] = name.trim();
    }
  }
  return names;
}

String? _preferredLocalizedName(Map<String, String> names) {
  final english = names['en'];
  if (english != null && english.isNotEmpty) {
    return english;
  }
  return names.values.firstOrNull;
}

String _formatDisplayName(String id) {
  return id
      .split(RegExp('[-_]'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String? _readNamedResource(
  Map<String, dynamic> payload,
  String key,
  String id,
) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is! Map || value['name'] is! String) {
    throw EditorPersistenceException(
      'External item "$id" field "$key" must expose a name.',
    );
  }
  final name = (value['name'] as String).trim();
  return name.isEmpty ? null : name;
}

int? _readOptionalInt(Map<String, dynamic> payload, String key, String id) {
  final value = payload[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw EditorPersistenceException(
      'External item "$id" field "$key" must be numeric.',
    );
  }
  return value.toInt();
}

String? _readLocalizedText(
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
      'External item "$id" field "$listKey" must be a list.',
    );
  }
  String? fallback;
  for (final rawEntry in value) {
    if (rawEntry is! Map) {
      continue;
    }
    final text = rawEntry[textKey];
    if (text is! String || text.trim().isEmpty) {
      continue;
    }
    final language = rawEntry['language'];
    final languageId = language is Map ? language['name'] : null;
    if (languageId == 'en') {
      return text.trim();
    }
    fallback ??= text.trim();
  }
  return fallback;
}

String? _readSpriteUrl(Map<String, dynamic> payload, String id) {
  final sprites = payload['sprites'];
  if (sprites == null) {
    return null;
  }
  if (sprites is! Map) {
    throw EditorPersistenceException(
      'External item "$id" sprites must be an object.',
    );
  }
  final value = sprites['default'];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw EditorPersistenceException(
      'External item "$id" sprite URL must be a string.',
    );
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

Future<ProjectPokemonConfig> _readProjectPokemonConfig(
  ProjectWorkspace workspace,
) async {
  final manifestPath = workspace.projectManifestPath;
  if (!await workspace.fileExists(manifestPath)) {
    return const ProjectPokemonConfig();
  }
  final decoded = jsonDecode(await workspace.readTextFile(manifestPath));
  if (decoded is! Map<String, dynamic>) {
    throw EditorPersistenceException(
      'Project manifest is not a JSON object: $manifestPath',
    );
  }
  return ProjectManifest.fromJson(decoded).pokemon;
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
