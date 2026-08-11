import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
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
    this.machineKind,
    this.machineMoveId,
    this.machineConsumable,
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
  final String? machineKind;
  final String? machineMoveId;
  final bool? machineConsumable;

  bool get isMoveMachine => machineKind != null;

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
    this.canonicalCatalog,
    this.message,
    this.loadState = PokemonItemsCatalogLoadState.ready,
    this.catalogRelativePath = 'data/pokemon/catalogs/items.json',
    this.diagnostics = const <PokemonItemsCatalogDiagnostic>[],
  });

  final List<PokemonItemCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final ProjectItemCatalog? canonicalCatalog;
  final String? message;
  final PokemonItemsCatalogLoadState loadState;
  final String catalogRelativePath;
  final List<PokemonItemsCatalogDiagnostic> diagnostics;

  int get ignoredEntriesCount => diagnostics.length;
}

class LoadPokemonItemsCatalogUseCase {
  const LoadPokemonItemsCatalogUseCase();

  Future<PokemonItemsCatalogView> execute(ProjectWorkspace workspace) async {
    var catalogRelativePath = 'data/pokemon/catalogs/items.json';

    try {
      catalogRelativePath = await _resolveCatalogRelativePath(workspace);
      final catalog = await _readCatalogAtResolvedPath(
        workspace,
        catalogRelativePath: catalogRelativePath,
      );
      final validation = validateProjectItemCatalog(
        catalog,
        capabilityTruth: _editorCapabilityTruth(catalog),
      );
      final blockingDiagnostic = validation.diagnostics
          .where((diagnostic) => diagnostic.isBlocking)
          .firstOrNull;
      if (blockingDiagnostic != null) {
        throw EditorPersistenceException(
          'Invalid item catalog at ${blockingDiagnostic.path}: ${blockingDiagnostic.message}',
        );
      }
      final entries = await _projectEntries(
        workspace,
        catalog,
        catalogRelativePath: catalogRelativePath,
        validation: validation,
      );
      return PokemonItemsCatalogView(
        entries: entries,
        isAvailable: true,
        description: 'Catalogue local des objets.',
        canonicalCatalog: catalog,
        loadState: PokemonItemsCatalogLoadState.ready,
        catalogRelativePath: catalogRelativePath,
        diagnostics: validation.diagnostics
            .map(
              (diagnostic) => PokemonItemsCatalogDiagnostic(
                message: diagnostic.message,
                entryId: diagnostic.itemId,
                entryIndex: diagnostic.entryIndex,
              ),
            )
            .toList(growable: false),
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

  Future<ProjectItemCatalog> _readCatalogAtResolvedPath(
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
      return decodeProjectItemCatalog(
        jsonDecode(await workspace.readTextFile(absolutePath)),
      );
    } on EditorApplicationException {
      rethrow;
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid item catalog at $catalogRelativePath: $error',
      );
    } catch (error) {
      throw EditorPersistenceException(
        'Failed to read item catalog at $catalogRelativePath: $error',
      );
    }
  }

  Future<List<PokemonItemCatalogEntryView>> _projectEntries(
    ProjectWorkspace workspace,
    ProjectItemCatalog catalog, {
    required String catalogRelativePath,
    required ProjectItemCatalogValidationReport validation,
  }) async {
    final assetsRoot = p.normalize(
      p.join(p.dirname(p.dirname(catalogRelativePath)), 'assets', 'items'),
    );
    final entries = <PokemonItemCatalogEntryView>[];
    for (final item in catalog.entries) {
      final localSpritePath = p.normalize(p.join(assetsRoot, '${item.id}.png'));
      final hasLocalSprite = await workspace.fileExists(
        workspace.resolveProjectRelativePath(localSpritePath),
      );
      final assessment = validation.assessmentFor(item.id);
      entries.add(
        PokemonItemCatalogEntryView(
          id: item.id,
          name: item.displayName,
          shortDesc: item.description,
          aliases: item.aliases,
          pocketId: assessment?.presentationPocketId ?? item.pocketId,
          cost: item.buyPrice,
          effectText: item.description,
          localSpritePath: hasLocalSprite ? localSpritePath : null,
          machineKind: item.machine?.kind.name,
          machineMoveId: item.machine?.moveId,
          machineConsumable: item.machine?.consumable,
        ),
      );
    }
    entries.sort((left, right) {
      final nameCompare = left.name.toLowerCase().compareTo(
            right.name.toLowerCase(),
          );
      return nameCompare != 0 ? nameCompare : left.id.compareTo(right.id);
    });
    return entries;
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
}

ItemCapabilityTruth _editorCapabilityTruth(ProjectItemCatalog catalog) {
  final semanticActionIds = <String>{};
  final heldEffectIds = <String>{};
  for (final item in catalog.entries) {
    final heldEffectId = item.heldEffectId?.trim();
    if (heldEffectId != null && heldEffectId.isNotEmpty) {
      heldEffectIds.add(heldEffectId);
    }
    for (final use in item.uses) {
      if (use.effect
          case ProjectItemSemanticActionEffectDefinition(
            :final actionId,
          )) {
        semanticActionIds.add(actionId.trim());
      }
    }
  }
  return ItemCapabilityTruth(
    supportedUseContexts: ProjectItemUseContext.values.toSet(),
    supportedEffects: ProjectItemEffectCapability.values.toSet(),
    supportedSemanticActionIds: semanticActionIds,
    supportedHeldEffectIds: heldEffectIds,
    supportsCapture: true,
    supportsMoveMachines: true,
  );
}

Future<ProjectPokemonConfig> _readProjectPokemonConfig(
  ProjectWorkspace workspace,
) async {
  final manifestPath = workspace.projectManifestPath;
  try {
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
