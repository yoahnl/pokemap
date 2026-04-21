import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

class PokemonItemCatalogEntryView {
  const PokemonItemCatalogEntryView({
    required this.id,
    required this.name,
    this.shortDesc,
    this.aliases = const <String>[],
    this.categoryId,
    this.pocketId,
    this.cost,
    this.flingPower,
    this.flingEffectId,
    this.shortEffectText,
    this.effectText,
    this.flavorText,
    this.spriteUrl,
    this.localSpritePath,
  });

  final String id;
  final String name;
  final String? shortDesc;
  final List<String> aliases;
  final String? categoryId;
  final String? pocketId;
  final int? cost;
  final int? flingPower;
  final String? flingEffectId;
  final String? shortEffectText;
  final String? effectText;
  final String? flavorText;
  final String? spriteUrl;
  final String? localSpritePath;

  bool get hasSpriteMetadata {
    return (spriteUrl?.trim().isNotEmpty ?? false) ||
        (localSpritePath?.trim().isNotEmpty ?? false);
  }
}

enum PokemonItemsCatalogLoadState {
  ready,
  missingCatalog,
  loadError,
  noProject,
}

class PokemonItemsCatalogDiagnostic {
  const PokemonItemsCatalogDiagnostic({
    required this.message,
    this.entryId,
    this.entryIndex,
  });

  final String message;
  final String? entryId;
  final int? entryIndex;
}

class PokemonItemsCatalogView {
  const PokemonItemsCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
    this.loadState = PokemonItemsCatalogLoadState.ready,
    this.catalogRelativePath = 'data/pokemon/catalogs/items.json',
    this.diagnostics = const <PokemonItemsCatalogDiagnostic>[],
  });

  final List<PokemonItemCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
  final PokemonItemsCatalogLoadState loadState;
  final String catalogRelativePath;
  final List<PokemonItemsCatalogDiagnostic> diagnostics;

  int get ignoredEntriesCount => diagnostics.length;
}

class LoadPokemonItemsCatalogUseCase {
  const LoadPokemonItemsCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonItemsCatalogView> execute(ProjectWorkspace workspace) async {
    var catalogRelativePath = 'data/pokemon/catalogs/items.json';

    try {
      catalogRelativePath = await _resolveCatalogRelativePath(workspace);
      final catalog = await _readCatalog(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
      final projectedCatalog = _projectEntries(catalog);
      return PokemonItemsCatalogView(
        entries: projectedCatalog.entries,
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des objets.'
            : catalog.meta.description.trim(),
        loadState: PokemonItemsCatalogLoadState.ready,
        catalogRelativePath: catalogRelativePath,
        diagnostics: projectedCatalog.diagnostics,
      );
    } on EditorNotFoundException catch (error) {
      return PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message: error.message,
        loadState: PokemonItemsCatalogLoadState.missingCatalog,
        catalogRelativePath: catalogRelativePath,
      );
    } on EditorApplicationException catch (error) {
      return PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets illisible.',
        message: error.message,
        loadState: PokemonItemsCatalogLoadState.loadError,
        catalogRelativePath: catalogRelativePath,
      );
    }
  }

  Future<PokemonCatalogFile> _readCatalog(
    ProjectWorkspace workspace, {
    required String catalogRelativePath,
  }) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'items');
    } on EditorNotFoundException {
      return _readCatalogAtResolvedPath(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
    } on EditorApplicationException {
      return _readCatalogAtResolvedPath(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
    }
  }

  Future<PokemonCatalogFile> _readCatalogAtResolvedPath(
    ProjectWorkspace workspace, {
    required String catalogRelativePath,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(
      catalogRelativePath,
    );
    if (!await workspace.fileExists(absolutePath)) {
      throw EditorNotFoundException(
        'Pokemon catalog not found at $catalogRelativePath',
      );
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

  _ProjectedItemsCatalog _projectEntries(PokemonCatalogFile catalog) {
    final diagnostics = <PokemonItemsCatalogDiagnostic>[];
    final entriesById = <String, PokemonItemCatalogEntryView>{};

    for (var index = 0; index < catalog.entries.length; index++) {
      final entry = catalog.entries[index];
      try {
        final projectedEntry = _projectEntry(entry);
        if (entriesById.containsKey(projectedEntry.id)) {
          diagnostics.add(
            PokemonItemsCatalogDiagnostic(
              message:
                  'Items catalog duplicate entry ignored for id "${projectedEntry.id}".',
              entryId: projectedEntry.id,
              entryIndex: index,
            ),
          );
          continue;
        }
        entriesById[projectedEntry.id] = projectedEntry;
      } on EditorApplicationException catch (error) {
        diagnostics.add(
          PokemonItemsCatalogDiagnostic(
            message: error.message,
            entryId: _diagnosticEntryId(entry),
            entryIndex: index,
          ),
        );
      }
    }

    final entries = entriesById.values.toList(growable: false)
      ..sort((left, right) {
        final nameCompare =
            left.name.toLowerCase().compareTo(right.name.toLowerCase());
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });

    return _ProjectedItemsCatalog(
      entries: entries,
      diagnostics: diagnostics,
    );
  }

  PokemonItemCatalogEntryView _projectEntry(Map<String, dynamic> entry) {
    final id = _readOptionalString(entry, 'id') ?? '';
    if (id.isEmpty) {
      throw const EditorPersistenceException(
        'Items catalog contains an entry with an empty id.',
      );
    }

    final explicitName = _readOptionalString(entry, 'name');
    final localizedNames = _readOptionalStringMap(entry, 'names');
    final localizedName = _preferredLocalizedName(localizedNames);
    final name = localizedName ?? explicitName;
    if (name == null || name.isEmpty) {
      throw EditorPersistenceException(
        'Items catalog entry "$id" has an empty name.',
      );
    }

    final aliases = <String>{
      for (final value in localizedNames?.values ?? const <String>[])
        if (value.trim().isNotEmpty) value.trim(),
      for (final value in _readOptionalStringList(entry, 'aliases', id: id))
        if (value.trim().isNotEmpty) value.trim(),
    }.toList(growable: false);

    final shortEffectText = _readOptionalString(entry, 'shortEffectText') ??
        _readOptionalString(entry, 'shortDesc') ??
        _readLocalizedEntryText(
          entry,
          listKey: 'effect_entries',
          textKey: 'short_effect',
          id: id,
        );
    final effectText = _readOptionalString(entry, 'effectText') ??
        _readOptionalString(entry, 'description') ??
        _readLocalizedEntryText(
          entry,
          listKey: 'effect_entries',
          textKey: 'effect',
          id: id,
        );
    final flavorText = _readOptionalString(entry, 'flavorText') ??
        _readLocalizedEntryText(
          entry,
          listKey: 'flavor_text_entries',
          textKey: 'text',
          id: id,
        );

    return PokemonItemCatalogEntryView(
      id: id,
      name: name,
      shortDesc: shortEffectText,
      aliases: aliases,
      categoryId: _readOptionalString(entry, 'categoryId') ??
          _readOptionalNamedMapValue(entry, 'category', id: id),
      pocketId: _readOptionalString(entry, 'pocketId') ??
          _readOptionalNamedMapValue(entry, 'pocket', id: id),
      cost: _readOptionalInt(entry, 'cost', id: id),
      flingPower: _readOptionalInt(entry, 'flingPower', id: id) ??
          _readOptionalInt(entry, 'fling_power', id: id),
      flingEffectId: _readOptionalString(entry, 'flingEffectId') ??
          _readOptionalNamedMapValue(entry, 'fling_effect', id: id),
      shortEffectText: shortEffectText,
      effectText: effectText,
      flavorText: flavorText,
      spriteUrl: _readOptionalString(entry, 'spriteUrl') ??
          _readOptionalNamedMapValue(entry, 'sprites', id: id, nameKey: 'default'),
      localSpritePath: _readOptionalString(entry, 'localSpritePath'),
    );
  }
}

class _ProjectedItemsCatalog {
  const _ProjectedItemsCatalog({
    required this.entries,
    required this.diagnostics,
  });

  final List<PokemonItemCatalogEntryView> entries;
  final List<PokemonItemsCatalogDiagnostic> diagnostics;
}

String? _diagnosticEntryId(Map<String, dynamic> entry) {
  final value = entry['id'];
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _readOptionalString(Map<String, dynamic> entry, String key) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw EditorPersistenceException(
      'Items catalog field "$key" must be a string when present.',
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, String>? _readOptionalStringMap(
  Map<String, dynamic> entry,
  String key,
) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw EditorPersistenceException(
      'Items catalog field "$key" must be a string map when present.',
    );
  }

  final result = <String, String>{};
  for (final mapEntry in value.entries) {
    final mapKey = mapEntry.key;
    final mapValue = mapEntry.value;
    if (mapKey is! String || mapValue is! String) {
      throw EditorPersistenceException(
        'Items catalog field "$key" must be a string map when present.',
      );
    }
    result[mapKey] = mapValue;
  }
  return result;
}

List<String> _readOptionalStringList(
  Map<String, dynamic> entry,
  String key, {
  required String id,
}) {
  final value = entry[key];
  if (value == null) {
    return const <String>[];
  }
  if (value is! List) {
    throw EditorPersistenceException(
      'Items catalog entry "$id" has an invalid "$key" value.',
    );
  }
  final result = <String>[];
  for (final element in value) {
    if (element is! String) {
      throw EditorPersistenceException(
        'Items catalog entry "$id" has an invalid "$key" value.',
      );
    }
    final trimmed = element.trim();
    if (trimmed.isNotEmpty) {
      result.add(trimmed);
    }
  }
  return result;
}

int? _readOptionalInt(
  Map<String, dynamic> entry,
  String key, {
  required String id,
}) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw EditorPersistenceException(
      'Items catalog entry "$id" has an invalid "$key" value.',
    );
  }
  return value.toInt();
}

String? _readOptionalNamedMapValue(
  Map<String, dynamic> entry,
  String key, {
  required String id,
  String nameKey = 'name',
}) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw EditorPersistenceException(
      'Items catalog entry "$id" has an invalid "$key" value.',
    );
  }
  final nameValue = value[nameKey];
  if (nameValue == null) {
    return null;
  }
  if (nameValue is! String) {
    throw EditorPersistenceException(
      'Items catalog entry "$id" has an invalid "$key" value.',
    );
  }
  final trimmed = nameValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _readLocalizedEntryText(
  Map<String, dynamic> entry, {
  required String listKey,
  required String textKey,
  required String id,
}) {
  final value = entry[listKey];
  if (value == null) {
    return null;
  }
  if (value is! List) {
    throw EditorPersistenceException(
      'Items catalog entry "$id" has an invalid "$listKey" value.',
    );
  }

  String? fallback;
  for (final element in value) {
    if (element is! Map) {
      throw EditorPersistenceException(
        'Items catalog entry "$id" has an invalid "$listKey" value.',
      );
    }

    final textValue = element[textKey];
    if (textValue != null && textValue is! String) {
      throw EditorPersistenceException(
        'Items catalog entry "$id" has an invalid "$listKey" value.',
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

String? _preferredLocalizedName(Map<String, String>? names) {
  if (names == null || names.isEmpty) {
    return null;
  }
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
