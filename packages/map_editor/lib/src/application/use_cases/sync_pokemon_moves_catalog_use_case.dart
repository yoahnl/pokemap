import 'dart:convert';

import 'package:map_core/map_core.dart';

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
    this.generation,
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
  final int? generation;

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
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
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
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return PokemonMovesCatalogView(
        entries: _projectEntries(catalog),
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
      );
    }
  }

  List<PokemonMoveCatalogEntryView> _projectEntries(
      PokemonCatalogFile catalog) {
    final entries = catalog.entries
        .map(_projectEntry)
        .whereType<PokemonMoveCatalogEntryView>()
        .toList(growable: false)
      ..sort((left, right) {
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  PokemonMoveCatalogEntryView? _projectEntry(Map<String, dynamic> entry) {
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
          shortDesc:
              move.shortDescription.isEmpty ? null : move.shortDescription,
          generation: move.generation,
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

    final id = (entry['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final explicitName = (entry['name'] as String?)?.trim();
    final localizedNames = (entry['names'] as Map?)?.cast<String, dynamic>();
    final fallbackName = (localizedNames?['en'] as String?)?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name?.isNotEmpty == true ? name! : id,
      type: (entry['type'] as String?)?.trim(),
      category: (entry['category'] as String?)?.trim(),
      power: (entry['power'] as num?)?.toInt(),
      accuracy: entry['accuracy'] as num?,
      accuracyText: (entry['accuracyText'] as String?)?.trim(),
      pp: (entry['pp'] as num?)?.toInt(),
      priority: (entry['priority'] as num?)?.toInt(),
      target: (entry['target'] as String?)?.trim(),
      shortDesc: (entry['shortDesc'] as String?)?.trim(),
      generation: (entry['generation'] as num?)?.toInt(),
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

  return entry.containsKey('power') ||
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
