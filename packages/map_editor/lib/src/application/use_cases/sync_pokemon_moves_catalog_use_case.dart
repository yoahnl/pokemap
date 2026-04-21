import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/showdown_move_catalog_converter.dart';

/// Projection légère d'une entrée du catalogue local des attaques.
///
/// Cette vue existe pour deux besoins strictement 11B :
/// - afficher une liste locale lisible dans l'éditeur ;
/// - éviter que l'UI reparte du JSON brut pour interpréter les champs.
///
/// Non-objectifs assumés :
/// - ce n'est pas un nouveau modèle métier transverse ;
/// - ce n'est pas une "Move Library" complète ;
/// - on ne cherche pas à capturer toutes les subtilités battle de Showdown.
class PokemonMoveCatalogEntryView {
  const PokemonMoveCatalogEntryView({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.power,
    this.accuracy,
    this.accuracyText,
    this.pp,
    this.priority,
    this.target,
    this.shortDesc,
    this.shortEffectText,
    this.effectText,
    this.generation,
    this.generationId,
  });

  final String id;
  final String name;
  final String? type;
  final String? category;
  final int? power;
  final num? accuracy;
  final String? accuracyText;
  final int? pp;
  final int? priority;
  final String? target;
  final String? shortDesc;
  final String? shortEffectText;
  final String? effectText;
  final int? generation;
  final String? generationId;

  String get accuracyLabel {
    if (accuracy != null) {
      return accuracy!.toString();
    }
    if (accuracyText != null && accuracyText!.trim().isNotEmpty) {
      return accuracyText!;
    }
    return '-';
  }
}

enum PokemonMovesCatalogLoadState {
  ready,
  missingCatalog,
  loadError,
  noProject,
}

class PokemonMovesCatalogDiagnostic {
  const PokemonMovesCatalogDiagnostic({
    required this.message,
    this.entryId,
    this.entryIndex,
  });

  final String message;
  final String? entryId;
  final int? entryIndex;
}

/// État lisible du catalogue moves local pour l'éditeur.
///
/// L'UI a besoin d'une réponse honnête sur deux choses distinctes :
/// - le catalogue existe-t-il et a-t-il pu être lu ;
/// - quelles entrées locales sont effectivement disponibles.
///
/// On sépare donc clairement le message de statut des entrées elles-mêmes.
class PokemonMovesCatalogView {
  const PokemonMovesCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
    this.loadState = PokemonMovesCatalogLoadState.ready,
    this.catalogRelativePath = 'data/pokemon/catalogs/moves.json',
    this.diagnostics = const <PokemonMovesCatalogDiagnostic>[],
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
  final PokemonMovesCatalogLoadState loadState;
  final String catalogRelativePath;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;

  int get ignoredEntriesCount => diagnostics.length;
}

/// Résultat d'une preview ou d'une synchronisation réelle du catalogue moves.
///
/// Le use case reste volontairement déterministe :
/// - aucune merge policy "UI-configurable" supplémentaire n'est introduite ;
/// - la stratégie retenue est un merge par id, avec préservation des entrées
///   locales absentes de la source distante et des champs locaux non gérés ;
/// - le résultat expose donc uniquement les compteurs et ids utiles à l'UI.
class PokemonMovesCatalogSyncResult {
  const PokemonMovesCatalogSyncResult({
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

  int get createdCount => createdIds.length;
  int get updatedCount => updatedIds.length;
  int get unchangedCount => unchangedIds.length;
  int get preservedLocalOnlyCount => preservedLocalOnlyIds.length;
}

/// Charge le catalogue local des attaques pour la surface éditeur minimale.
///
/// Ce use case reste volontairement simple :
/// - il lit exclusivement `catalogs/moves.json` via le repository existant ;
/// - il projette des entrées lisibles ;
/// - il ne tente aucune réparation automatique ni enrichissement externe.
class LoadPokemonMovesCatalogUseCase {
  const LoadPokemonMovesCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonMovesCatalogView> execute(ProjectWorkspace workspace) async {
    final catalogRelativePath = await _resolveCatalogRelativePath(workspace);
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      final projectedCatalog = _projectEntries(catalog);
      return PokemonMovesCatalogView(
        entries: projectedCatalog.entries,
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
        loadState: PokemonMovesCatalogLoadState.ready,
        catalogRelativePath: catalogRelativePath,
        diagnostics: projectedCatalog.diagnostics,
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
        loadState: PokemonMovesCatalogLoadState.missingCatalog,
        catalogRelativePath: catalogRelativePath,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
        loadState: PokemonMovesCatalogLoadState.loadError,
        catalogRelativePath: catalogRelativePath,
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

  _ProjectedMovesCatalog _projectEntries(PokemonCatalogFile catalog) {
    final diagnostics = <PokemonMovesCatalogDiagnostic>[];
    final entriesById = <String, PokemonMoveCatalogEntryView>{};

    for (var index = 0; index < catalog.entries.length; index++) {
      final entry = catalog.entries[index];
      try {
        final projectedEntry = _projectEntry(entry);
        if (entriesById.containsKey(projectedEntry.id)) {
          diagnostics.add(
            PokemonMovesCatalogDiagnostic(
              message:
                  'Moves catalog duplicate entry ignored for id "${projectedEntry.id}".',
              entryId: projectedEntry.id,
              entryIndex: index,
            ),
          );
          continue;
        }
        entriesById[projectedEntry.id] = projectedEntry;
      } on EditorApplicationException catch (error) {
        diagnostics.add(
          PokemonMovesCatalogDiagnostic(
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

    return _ProjectedMovesCatalog(
      entries: entries,
      diagnostics: diagnostics,
    );
  }

  PokemonMoveCatalogEntryView _projectEntry(Map<String, dynamic> entry) {
    // M3 introduit des entrées canoniques `PokemonMove.toJson()`, mais le
    // catalogue projet peut encore contenir des entrées legacy locales non
    // resynchronisées.
    //
    // M3-bis durcit volontairement la frontière :
    // - la détection canonique devient large ;
    // - la détection legacy devient étroite ;
    // - si une entrée "sent" le canonique, on la traite comme canonique ;
    // - si le parse canonique échoue, on remonte une erreur explicite ;
    // - le fallback legacy ne sert plus qu'aux vraies formes legacy.
    //
    // Cette asymétrie est voulue :
    // - mieux vaut échouer tôt sur une entrée canonique cassée ;
    // - que la dégrader silencieusement vers la vieille projection legacy.
    if (_looksLikeCanonicalMoveEntry(entry)) {
      try {
        final move = PokemonMove.fromJson(entry);
        final shortEffectText =
            move.shortDescription.trim().isEmpty ? null : move.shortDescription;
        final effectText =
            move.description.trim().isEmpty ? null : move.description;
        return PokemonMoveCatalogEntryView(
          id: move.id,
          name: move.name,
          type: move.type,
          category: move.category.name,
          power: move.usesStandardDamageFlow ? move.basePower : null,
          accuracy: move.accuracy.map(
            percent: (value) => value.value,
            alwaysHits: (_) => null,
          ),
          accuracyText: move.accuracy.maybeMap(
            alwaysHits: (_) => 'always',
            orElse: () => null,
          ),
          pp: move.pp,
          priority: move.priority,
          target: _encodeTarget(move.target),
          shortDesc: shortEffectText,
          shortEffectText: shortEffectText,
          effectText: effectText,
          generation: move.generation,
          generationId: _generationIdFromNumber(move.generation),
        );
      } on Object catch (error) {
        throw EditorPersistenceException(
          'Moves catalog contains an invalid canonical PokemonMove entry: $error',
        );
      }
    }

    if (!_looksLikeLegacyMoveEntry(entry)) {
      throw const EditorPersistenceException(
        'Moves catalog contains an entry with an unknown or unsupported move shape.',
      );
    }

    final id = _readOptionalString(entry, 'id') ?? '';
    if (id.isEmpty) {
      throw const EditorPersistenceException(
        'Moves catalog contains an entry with an empty id.',
      );
    }

    final explicitName = _readOptionalString(entry, 'name');
    final localizedNames = _readOptionalStringMap(entry, 'names');
    final fallbackName = localizedNames?['en']?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;
    if (name == null || name.isEmpty) {
      throw EditorPersistenceException(
        'Moves catalog entry "$id" has an empty name.',
      );
    }

    final type = _readOptionalString(entry, 'typeId') ??
        _readOptionalString(entry, 'type');
    final category = _normalizeDamageClass(
      _readOptionalString(entry, 'damageClass') ??
          _readOptionalString(entry, 'category'),
    );
    final shortEffectText = _readOptionalString(entry, 'shortEffectText') ??
        _readOptionalString(entry, 'shortDesc');
    final effectText = _readOptionalString(entry, 'effectText') ??
        _readOptionalString(entry, 'description');
    final generationId = _readOptionalString(entry, 'generationId');

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name,
      type: type,
      category: category,
      power: _readOptionalInt(entry, 'power', id: id),
      accuracy: _readOptionalNum(entry, 'accuracy', id: id),
      accuracyText: _readOptionalString(entry, 'accuracyText'),
      pp: _readOptionalInt(entry, 'pp', id: id),
      priority: _readOptionalInt(entry, 'priority', id: id),
      target: _readOptionalString(entry, 'target'),
      shortDesc: shortEffectText,
      shortEffectText: shortEffectText,
      effectText: effectText,
      generation: _readOptionalInt(entry, 'generation', id: id),
      generationId: generationId,
    );
  }
}

/// Synchronise le catalogue local `moves.json` depuis la source externe retenue.
///
/// Choix produit et technique de la 11B :
/// - on réutilise le port externe 11A existant, étendu minimalement ;
/// - la source bulk retenue est Showdown `moves.json` ;
/// - l'écriture locale continue de passer par le repository Pokémon existant ;
/// - `project.json` n'est jamais touché ;
/// - aucun pipeline parallèle n'est créé.
class SyncExternalPokemonMovesCatalogUseCase {
  const SyncExternalPokemonMovesCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
    this.converter = const ShowdownMoveCatalogConverter(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownMoveCatalogConverter converter;

  Future<PokemonMovesCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    bool dryRun = false,
  }) async {
    final externalCatalog = converter.convert(
      await externalSourceRepository.fetchShowdownMovesSnapshot(),
    );
    final localCatalog = await _readLocalCatalogIfAvailable(workspace);
    final merge = _mergeCatalogs(
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
    );

    if (!dryRun) {
      await writeRepository.saveCatalogByKey(workspace, 'moves', merge.catalog);
    }

    return PokemonMovesCatalogSyncResult(
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
    ProjectWorkspace workspace,
  ) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'moves');
    } on EditorNotFoundException {
      // Le storage 11A/11B initialise normalement le fichier, mais on garde ce
      // fallback local pour éviter qu'une absence de catalogue ne bloque
      // complètement un premier sync sur un workspace partiellement initialisé.
      return null;
    }
  }

  _MovesCatalogMerge _mergeCatalogs({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localById = <String, Map<String, dynamic>>{
      for (final entry
          in localCatalog?.entries ?? const <Map<String, dynamic>>[])
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');
    final externalById = <String, Map<String, dynamic>>{
      for (final entry in externalCatalog.entries)
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    for (final externalEntry in externalById.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))) {
      final id = externalEntry.key;
      final localEntry = localById.remove(id);
      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(_deepCopy(externalEntry.value));
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: externalEntry.value,
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

    final catalog = PokemonCatalogFile(
      schemaVersion: externalCatalog.schemaVersion,
      kind: externalCatalog.kind,
      catalog: externalCatalog.catalog,
      meta: _buildMergedMeta(
        localMeta: localCatalog?.meta,
        externalMeta: externalCatalog.meta,
      ),
      entries: mergedEntries,
    );

    return _MovesCatalogMerge(
      catalog: catalog,
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      warnings: preservedLocalOnlyIds.isEmpty
          ? const <String>[]
          : <String>[
              'Local move entries absent from the external snapshot were preserved unchanged.',
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

      // Règle de merge locale et volontairement conservative :
      // - l'externe garde la priorité sur les champs qu'on sait produire ;
      // - si la valeur externe vaut `null`, on conserve une valeur locale
      //   existante plutôt que d'effacer une information déjà utile ;
      // - les champs purement locaux non gérés par 11B sont préservés plus bas.
      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      if (_looksLikeCanonicalMoveEntry(externalEntry) &&
          _obsoleteLegacyMoveFields.contains(localField.key)) {
        // M3 ne doit pas laisser les anciens alias légers (`power`,
        // `accuracyText`, `shortDesc`) se réinjecter sur une entrée maintenant
        // canonique. On continue toutefois de préserver les vrais champs
        // locaux additionnels (`names.fr`, `editorNote`, etc.).
        continue;
      }
      merged.putIfAbsent(
          localField.key, () => _deepCopyValue(localField.value));
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

String _encodeTarget(PokemonMoveTarget target) {
  switch (target) {
    case PokemonMoveTarget.adjacentAlly:
      return 'adjacentAlly';
    case PokemonMoveTarget.adjacentAllyOrSelf:
      return 'adjacentAllyOrSelf';
    case PokemonMoveTarget.adjacentFoe:
      return 'adjacentFoe';
    case PokemonMoveTarget.all:
      return 'all';
    case PokemonMoveTarget.allAdjacent:
      return 'allAdjacent';
    case PokemonMoveTarget.allAdjacentFoes:
      return 'allAdjacentFoes';
    case PokemonMoveTarget.allies:
      return 'allies';
    case PokemonMoveTarget.allySide:
      return 'allySide';
    case PokemonMoveTarget.allyTeam:
      return 'allyTeam';
    case PokemonMoveTarget.any:
      return 'any';
    case PokemonMoveTarget.foeSide:
      return 'foeSide';
    case PokemonMoveTarget.normal:
      return 'normal';
    case PokemonMoveTarget.randomNormal:
      return 'randomNormal';
    case PokemonMoveTarget.scripted:
      return 'scripted';
    case PokemonMoveTarget.self:
      return 'self';
  }
}

bool _looksLikeCanonicalMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement large :
  // - toute présence d'un vrai marqueur canonique doit suffire ;
  // - une entrée partiellement migrée ou partiellement cassée doit être
  //   traitée comme une candidate canonique, puis échouer explicitement ;
  // - on évite ainsi tout downgrade silencieux vers le fallback legacy.
  return entry.containsKey('basePower') ||
      entry.containsKey('effects') ||
      entry.containsKey('sourceRefs') ||
      entry.containsKey('engineSupportLevel') ||
      entry.containsKey('unsupportedReasons') ||
      entry.containsKey('noPpBoosts') ||
      entry.containsKey('critRatio') ||
      entry['accuracy'] is Map;
}

bool _looksLikeLegacyMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement étroite :
  // - on ne classe legacy que les formes explicitement héritées de l'ancien
  //   catalogue léger ;
  // - la présence d'un signal canonique exclut immédiatement le chemin legacy ;
  // - `accuracy` scalaire seule n'est acceptée en legacy que s'il n'existe
  //   aucun signal canonique concurrent.
  if (_looksLikeCanonicalMoveEntry(entry)) {
    return false;
  }

  return entry.containsKey('id') ||
      entry.containsKey('name') ||
      entry.containsKey('typeId') ||
      entry.containsKey('damageClass') ||
      entry.containsKey('generationId') ||
      entry.containsKey('effectText') ||
      entry.containsKey('shortEffectText') ||
      entry.containsKey('power') ||
      entry.containsKey('accuracyText') ||
      entry.containsKey('shortDesc') ||
      entry['accuracy'] is num;
}

const Set<String> _obsoleteLegacyMoveFields = <String>{
  'power',
  'accuracyText',
  'shortDesc',
};

class _MovesCatalogMerge {
  const _MovesCatalogMerge({
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

class _ProjectedMovesCatalog {
  const _ProjectedMovesCatalog({
    required this.entries,
    required this.diagnostics,
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;
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
      'Moves catalog field "$key" must be a string when present.',
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
      'Moves catalog field "$key" must be a string map when present.',
    );
  }

  final result = <String, String>{};
  for (final mapEntry in value.entries) {
    final mapKey = mapEntry.key;
    final mapValue = mapEntry.value;
    if (mapKey is! String || mapValue is! String) {
      throw EditorPersistenceException(
        'Moves catalog field "$key" must be a string map when present.',
      );
    }
    result[mapKey] = mapValue;
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
      'Moves catalog entry "$id" has an invalid "$key" value.',
    );
  }
  return value.toInt();
}

num? _readOptionalNum(
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
      'Moves catalog entry "$id" has an invalid "$key" value.',
    );
  }
  return value;
}

String? _normalizeDamageClass(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized == 'physical' ||
      normalized == 'special' ||
      normalized == 'status') {
    return normalized;
  }
  return 'unknown';
}

String? _generationIdFromNumber(int? generation) {
  return switch (generation) {
    1 => 'generation-i',
    2 => 'generation-ii',
    3 => 'generation-iii',
    4 => 'generation-iv',
    5 => 'generation-v',
    6 => 'generation-vi',
    7 => 'generation-vii',
    8 => 'generation-viii',
    9 => 'generation-ix',
    _ => null,
  };
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
