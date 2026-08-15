import '../models/pokemon_project_data.dart';
import '../models/pokemon_ruleset_profile.dart';

enum PokemonCatalogDiagnosticSeverity { error, warning }

final class PokemonCatalogDiagnostic {
  const PokemonCatalogDiagnostic({
    required this.code,
    required this.severity,
    required this.path,
    required this.message,
    required this.recommendedAction,
  });

  final String code;
  final PokemonCatalogDiagnosticSeverity severity;
  final String path;
  final String message;
  final String recommendedAction;

  String get location => path;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'severity': severity.name,
    'path': path,
    'message': message,
    'recommendedAction': recommendedAction,
  };
}

final class PokemonCatalogCoherenceReport {
  PokemonCatalogCoherenceReport(Iterable<PokemonCatalogDiagnostic> values)
    : diagnostics = List<PokemonCatalogDiagnostic>.unmodifiable(
        values.toList(growable: false)..sort(_compareDiagnostics),
      );

  final List<PokemonCatalogDiagnostic> diagnostics;

  List<PokemonCatalogDiagnostic> get issues => diagnostics;

  bool get isValid => canExport;

  bool get hasWarnings => warningCount > 0;

  int get errorCount => diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == PokemonCatalogDiagnosticSeverity.error,
      )
      .length;

  int get warningCount => diagnostics.length - errorCount;

  bool get canExport => errorCount == 0;

  bool get canPublish => canExport;

  bool get canPlaytest => errorCount == 0;

  Map<String, Object?> toJson() => <String, Object?>{
    'canExport': canExport,
    'canPlaytest': canPlaytest,
    'errorCount': errorCount,
    'warningCount': warningCount,
    'diagnostics': <Object?>[
      for (final diagnostic in diagnostics) diagnostic.toJson(),
    ],
  };
}

final class PokemonCatalogDocument<T> {
  PokemonCatalogDocument({required String path, required this.value})
    : path = _requirePath(path);

  final String path;
  final T value;
}

final class PokemonCatalogCoherenceSnapshot {
  PokemonCatalogCoherenceSnapshot({
    Iterable<PokemonCatalogDocument<PokemonCatalogFile>> catalogs = const [],
    Iterable<PokemonCatalogDocument<PokemonSpeciesFile>> species = const [],
    Iterable<PokemonCatalogDocument<PokemonLearnsetFile>> learnsets = const [],
    Iterable<PokemonCatalogDocument<PokemonEvolutionFile>> evolutions =
        const [],
    Iterable<PokemonCatalogDocument<PokemonMediaFile>> media = const [],
    Iterable<String> availableAssetPaths = const [],
    this.assetInventoryComplete = false,
    required this.ruleset,
  }) : catalogs = List.unmodifiable(catalogs),
       species = List.unmodifiable(species),
       learnsets = List.unmodifiable(learnsets),
       evolutions = List.unmodifiable(evolutions),
       media = List.unmodifiable(media),
       availableAssetPaths = Set.unmodifiable(
         availableAssetPaths
             .map((path) => path.trim())
             .where((path) => path.isNotEmpty),
       );

  final List<PokemonCatalogDocument<PokemonCatalogFile>> catalogs;
  final List<PokemonCatalogDocument<PokemonSpeciesFile>> species;
  final List<PokemonCatalogDocument<PokemonLearnsetFile>> learnsets;
  final List<PokemonCatalogDocument<PokemonEvolutionFile>> evolutions;
  final List<PokemonCatalogDocument<PokemonMediaFile>> media;
  final Set<String> availableAssetPaths;
  final bool assetInventoryComplete;
  final PokemonRulesetProfile ruleset;
}

final class PokemonCatalogCoherenceValidator {
  const PokemonCatalogCoherenceValidator();

  static const Set<String> supportedEvolutionMethods = <String>{
    'friendship',
    'item',
    'known_move',
    'level_up',
    'use_item',
  };

  PokemonCatalogCoherenceReport validate(
    PokemonCatalogCoherenceSnapshot snapshot,
  ) {
    final collector = _DiagnosticCollector();
    final catalogIds = _validateCatalogs(snapshot.catalogs, collector);
    final speciesIds = _validateDocumentIdentities(
      snapshot.species,
      (value) => value.id,
      family: 'species',
      collector: collector,
    );
    final learnsetIds = _validateDocumentIdentities(
      snapshot.learnsets,
      (value) => value.speciesId,
      family: 'learnset',
      collector: collector,
    );
    final evolutionIds = _validateDocumentIdentities(
      snapshot.evolutions,
      (value) => value.speciesId,
      family: 'evolution',
      collector: collector,
    );
    final mediaIds = _validateDocumentIdentities(
      snapshot.media,
      (value) => value.speciesId,
      family: 'media',
      collector: collector,
    );
    final formIdsBySpecies = _validateFormGraph(snapshot.species, collector);

    for (final document in snapshot.species) {
      _validateSpecies(
        document,
        learnsetIds: learnsetIds,
        evolutionIds: evolutionIds,
        mediaIds: mediaIds,
        catalogIds: catalogIds,
        collector: collector,
      );
    }
    for (final document in snapshot.learnsets) {
      _validateLearnset(
        document,
        speciesIds: speciesIds,
        moveIds: catalogIds['moves'],
        maxLevel: snapshot.ruleset.maxLevel,
        collector: collector,
      );
    }
    for (final document in snapshot.evolutions) {
      _validateEvolution(
        document,
        speciesIds: speciesIds,
        moveIds: catalogIds['moves'],
        itemIds: catalogIds['items'],
        maxLevel: snapshot.ruleset.maxLevel,
        collector: collector,
      );
    }
    _validateEvolutionCycles(snapshot.evolutions, collector);
    for (final document in snapshot.media) {
      _validateMedia(
        document,
        speciesIds: speciesIds,
        formIds: formIdsBySpecies[document.value.speciesId],
        assetPaths: snapshot.availableAssetPaths,
        assetInventoryComplete: snapshot.assetInventoryComplete,
        collector: collector,
      );
    }

    return PokemonCatalogCoherenceReport(collector.diagnostics);
  }

  Map<String, Set<String>> _validateCatalogs(
    List<PokemonCatalogDocument<PokemonCatalogFile>> documents,
    _DiagnosticCollector collector,
  ) {
    final result = <String, Set<String>>{};
    final catalogDocuments = <String, List<String>>{};
    for (final document in documents) {
      final catalog = document.value;
      _validateSchemaVersion(
        catalog.schemaVersion,
        family: 'catalog',
        path: document.path,
        collector: collector,
      );
      final catalogId = catalog.catalog.trim();
      if (catalogId.isEmpty) {
        collector.error(
          code: 'catalog.id_empty',
          path: '${document.path}.catalog',
          message: 'A Pokemon catalog id cannot be empty.',
          action: 'Set a stable catalog id before publishing the project.',
        );
        continue;
      }
      catalogDocuments
          .putIfAbsent(catalogId, () => <String>[])
          .add(document.path);
      final ids = result.putIfAbsent(catalogId, () => <String>{});
      final duplicateIds = <String>{};
      for (var index = 0; index < catalog.entries.length; index += 1) {
        final id = (catalog.entries[index]['id'] as String?)?.trim() ?? '';
        if (id.isEmpty) {
          collector.error(
            code: 'catalog.entry_id_empty',
            path: '${document.path}.entries[$index].id',
            message: 'A Pokemon catalog entry id cannot be empty.',
            action: 'Assign a stable non-empty id to the catalog entry.',
          );
        } else if (!ids.add(id)) {
          duplicateIds.add(id);
        }
      }
      for (final id in duplicateIds.toList(growable: false)..sort()) {
        collector.error(
          code: 'catalog.entry_duplicate_id',
          path: '${document.path}.entries',
          message: 'Catalog "$catalogId" contains duplicate id "$id".',
          action: 'Keep exactly one catalog entry for id "$id".',
        );
      }
    }
    for (final entry in catalogDocuments.entries) {
      if (entry.value.length < 2) continue;
      entry.value.sort();
      collector.error(
        code: 'catalog.duplicate_id',
        path: entry.value.first,
        message: 'Multiple catalog documents declare id "${entry.key}".',
        action: 'Keep one canonical document for catalog "${entry.key}".',
      );
    }
    for (final requiredCatalog in const <String>[
      'types',
      'abilities',
      'moves',
      'growth_rates',
      'items',
    ]) {
      if (result.containsKey(requiredCatalog)) continue;
      collector.warning(
        code: 'catalog.${requiredCatalog}_missing',
        path: 'catalogs/$requiredCatalog',
        message:
            'The $requiredCatalog catalog is unavailable; '
            '${_catalogReferenceLabel(requiredCatalog)} references were not checked.',
        action:
            'Add the $requiredCatalog catalog before enabling authored '
            '${_catalogReferencePlural(requiredCatalog)}.',
      );
    }
    return result;
  }

  Set<String> _validateDocumentIdentities<T>(
    List<PokemonCatalogDocument<T>> documents,
    String Function(T value) identity, {
    required String family,
    required _DiagnosticCollector collector,
  }) {
    final pathsById = <String, List<String>>{};
    for (final document in documents) {
      final id = identity(document.value).trim();
      if (id.isEmpty) {
        collector.error(
          code: '$family.${family == 'species' ? 'id' : 'species_id'}_empty',
          path: '${document.path}.${family == 'species' ? 'id' : 'speciesId'}',
          message: '${_title(family)} id cannot be empty.',
          action: 'Assign the document to one stable Pokemon species id.',
        );
        continue;
      }
      pathsById.putIfAbsent(id, () => <String>[]).add(document.path);
    }
    for (final entry in pathsById.entries) {
      if (entry.value.length < 2) continue;
      entry.value.sort();
      collector.error(
        code: '$family.duplicate_id',
        path: entry.value.first,
        message: 'Multiple $family documents declare id "${entry.key}".',
        action: 'Keep exactly one $family document for "${entry.key}".',
      );
    }
    return pathsById.keys.toSet();
  }

  void _validateSpecies(
    PokemonCatalogDocument<PokemonSpeciesFile> document, {
    required Set<String> learnsetIds,
    required Set<String> evolutionIds,
    required Set<String> mediaIds,
    required Map<String, Set<String>> catalogIds,
    required _DiagnosticCollector collector,
  }) {
    final species = document.value;
    final path = document.path;
    _validateSchemaVersion(
      species.schemaVersion,
      family: 'species',
      path: path,
      collector: collector,
    );
    if (species.nationalDex <= 0) {
      collector.error(
        code: 'species.national_dex_invalid',
        path: '$path.nationalDex',
        message:
            'Species "${species.id}" must have nationalDex greater than 0.',
        action: 'Set nationalDex to a positive integer.',
      );
    }
    final stats = <String, int>{
      'hp': species.baseStats.hp,
      'atk': species.baseStats.atk,
      'def': species.baseStats.def,
      'spa': species.baseStats.spa,
      'spd': species.baseStats.spd,
      'spe': species.baseStats.spe,
    };
    for (final entry in stats.entries) {
      if (entry.value > 0) continue;
      collector.error(
        code: 'species.stat_invalid',
        path: '$path.baseStats.${entry.key}',
        message:
            'Species "${species.id}" has a non-positive ${entry.key} stat.',
        action: 'Set every base stat to a positive integer.',
      );
    }
    final statTotal = stats.values.fold<int>(0, (sum, value) => sum + value);
    if (species.baseStats.bst != statTotal) {
      collector.error(
        code: 'species.stat_total_mismatch',
        path: '$path.baseStats.bst',
        message:
            'Species "${species.id}" declares bst '
            '${species.baseStats.bst}, but its stats total $statTotal.',
        action: 'Set bst to the exact sum of the six base stats.',
      );
    }
    if (species.progression.catchRate < 1 ||
        species.progression.catchRate > 255) {
      collector.error(
        code: 'species.catch_rate_invalid',
        path: '$path.progression.catchRate',
        message: 'Species "${species.id}" has catchRate outside 1..255.',
        action: 'Set catchRate to an integer between 1 and 255.',
      );
    }
    if (species.progression.baseFriendship < 0 ||
        species.progression.baseFriendship > 255) {
      collector.error(
        code: 'species.friendship_invalid',
        path: '$path.progression.baseFriendship',
        message: 'Species "${species.id}" has friendship outside 0..255.',
        action: 'Set baseFriendship to an integer between 0 and 255.',
      );
    }
    _requireCatalogReferences(
      values: species.typing.types,
      catalogIds: catalogIds['types'],
      emptyCode: 'species.types_empty',
      missingCode: 'species.type_missing_in_catalog',
      path: '$path.typing.types',
      owner: species.id,
      label: 'type',
      collector: collector,
    );
    final abilityIds = <String>[
      species.abilities.primary,
      ?species.abilities.secondary,
      ?species.abilities.hidden,
    ];
    _requireCatalogReferences(
      values: abilityIds,
      catalogIds: catalogIds['abilities'],
      emptyCode: 'species.ability_empty',
      missingCode: 'species.ability_missing_in_catalog',
      path: '$path.abilities',
      owner: species.id,
      label: 'ability',
      collector: collector,
    );
    _validateReference(
      value: species.progression.growthRateId,
      knownIds: catalogIds['growth_rates'],
      emptyCode: 'species.growth_rate_empty',
      missingCode: 'species.growth_rate_missing_in_catalog',
      path: '$path.progression.growthRateId',
      label: 'growth rate',
      collector: collector,
    );
    _validateReference(
      value: species.refs.learnset,
      knownIds: learnsetIds,
      emptyCode: 'species.learnset_ref_empty',
      missingCode: 'species.learnset_ref_missing',
      path: '$path.refs.learnset',
      label: 'learnset',
      collector: collector,
    );
    _validateReference(
      value: species.refs.evolution,
      knownIds: evolutionIds,
      emptyCode: 'species.evolution_ref_empty',
      missingCode: 'species.evolution_ref_missing',
      path: '$path.refs.evolution',
      label: 'evolution document',
      collector: collector,
    );
    _validateReference(
      value: species.refs.media,
      knownIds: mediaIds,
      emptyCode: 'species.media_ref_empty',
      missingCode: 'species.media_ref_missing',
      path: '$path.refs.media',
      label: 'media document',
      collector: collector,
    );
  }

  Map<String, Set<String>> _validateFormGraph(
    List<PokemonCatalogDocument<PokemonSpeciesFile>> documents,
    _DiagnosticCollector collector,
  ) {
    final sorted = documents.toList(growable: false)
      ..sort((left, right) => left.path.compareTo(right.path));
    final speciesById = <String, PokemonCatalogDocument<PokemonSpeciesFile>>{};
    for (final document in sorted) {
      final speciesId = document.value.id.trim();
      if (speciesId.isNotEmpty) {
        speciesById.putIfAbsent(speciesId, () => document);
      }
    }
    final groups = <String, List<_PokemonFormNode>>{};
    for (final document in sorted) {
      final species = document.value;
      final speciesId = species.id.trim();
      final declaredBaseId = species.forms.baseFormId.trim();
      final formId = species.forms.formId.trim();
      final baseSpeciesId = species.forms.isBaseForm
          ? speciesId
          : declaredBaseId;
      if (declaredBaseId.isEmpty) {
        collector.error(
          code: 'species.form_base_id_empty',
          path: '${document.path}.forms.baseFormId',
          message: 'Species "$speciesId" has no base form species id.',
          action: 'Set baseFormId to the canonical base species id.',
        );
      }
      if (formId.isEmpty) {
        collector.error(
          code: 'species.form_id_empty',
          path: '${document.path}.forms.formId',
          message: 'Species "$speciesId" has no stable form id.',
          action: 'Assign a stable formId within the base species graph.',
        );
      }
      if (species.forms.isBaseForm && declaredBaseId != speciesId) {
        collector.error(
          code: 'species.form_base_identity_mismatch',
          path: '${document.path}.forms.baseFormId',
          message: 'Base species "$speciesId" must reference its own id.',
          action: 'Set baseFormId to "$speciesId".',
        );
      }
      if (!species.forms.isBaseForm) {
        final baseDocument = speciesById[declaredBaseId];
        if (baseDocument == null || !baseDocument.value.forms.isBaseForm) {
          collector.error(
            code: 'species.form_base_missing',
            path: '${document.path}.forms.baseFormId',
            message: 'Form "$speciesId" references an unknown base species.',
            action:
                'Reference an existing base species or mark this as a base form.',
          );
        }
      }
      if (baseSpeciesId.isNotEmpty) {
        groups
            .putIfAbsent(baseSpeciesId, () => <_PokemonFormNode>[])
            .add(_PokemonFormNode(document: document, formId: formId));
      }
    }

    final result = <String, Set<String>>{};
    final groupIds = groups.keys.toList(growable: false)..sort();
    for (final groupId in groupIds) {
      final nodes = groups[groupId]!
        ..sort(
          (left, right) => left.document.path.compareTo(right.document.path),
        );
      final nodesByFormId = <String, List<_PokemonFormNode>>{};
      for (final node in nodes) {
        if (node.formId.isEmpty) continue;
        nodesByFormId
            .putIfAbsent(node.formId, () => <_PokemonFormNode>[])
            .add(node);
      }
      final formIds = Set<String>.unmodifiable(nodesByFormId.keys);
      for (final node in nodes) {
        final speciesId = node.document.value.id.trim();
        if (speciesId.isNotEmpty) result[speciesId] = formIds;
      }
      final sortedFormIds = nodesByFormId.keys.toList(growable: false)..sort();
      for (final formId in sortedFormIds) {
        final duplicates = nodesByFormId[formId]!;
        if (duplicates.length > 1) {
          collector.error(
            code: 'species.form_id_duplicate',
            path: '${duplicates.first.document.path}.forms.formId',
            message:
                'Base species "$groupId" declares formId "$formId" more than once.',
            action: 'Keep one species document for each formId.',
          );
        }
      }
      for (final node in nodes) {
        final forms = node.document.value.forms;
        final seen = <String>{};
        for (var index = 0; index < forms.otherForms.length; index += 1) {
          final otherFormId = forms.otherForms[index].trim();
          final path = '${node.document.path}.forms.otherForms[$index]';
          if (otherFormId.isEmpty || !nodesByFormId.containsKey(otherFormId)) {
            collector.error(
              code: 'species.other_form_missing',
              path: path,
              message:
                  'Form "${node.formId}" references unknown form "$otherFormId".',
              action:
                  'Reference a formId declared for base species "$groupId".',
            );
            continue;
          }
          if (!seen.add(otherFormId)) {
            collector.error(
              code: 'species.other_form_duplicate',
              path: path,
              message:
                  'Form "${node.formId}" references form "$otherFormId" more than once.',
              action: 'Keep each otherForms reference only once.',
            );
            continue;
          }
          final target = nodesByFormId[otherFormId]!.first.document.value.forms;
          if (!target.otherForms
              .map((value) => value.trim())
              .contains(node.formId)) {
            collector.error(
              code: 'species.other_form_not_reciprocal',
              path: path,
              message:
                  'Form "$otherFormId" does not reference "${node.formId}" back.',
              action: 'Make otherForms links reciprocal within the form graph.',
            );
          }
        }
      }
    }
    return Map<String, Set<String>>.unmodifiable(result);
  }

  void _validateLearnset(
    PokemonCatalogDocument<PokemonLearnsetFile> document, {
    required Set<String> speciesIds,
    required Set<String>? moveIds,
    required int maxLevel,
    required _DiagnosticCollector collector,
  }) {
    final learnset = document.value;
    final path = document.path;
    _validateSchemaVersion(
      learnset.schemaVersion,
      family: 'learnset',
      path: path,
      collector: collector,
    );
    final speciesId = learnset.speciesId.trim();
    if (speciesId.isNotEmpty && !speciesIds.contains(speciesId)) {
      collector.error(
        code: 'learnset.species_missing',
        path: '$path.speciesId',
        message: 'Learnset "$speciesId" references an unknown species.',
        action: 'Create the species or remove its orphan learnset.',
      );
    }
    final moveReferences = <({String code, String id, String path})>[
      for (var index = 0; index < learnset.startingMoves.length; index += 1)
        (
          code: 'learnset.starting_move_empty',
          id: learnset.startingMoves[index],
          path: '$path.startingMoves[$index]',
        ),
      for (var index = 0; index < learnset.relearnMoves.length; index += 1)
        (
          code: 'learnset.relearn_move_empty',
          id: learnset.relearnMoves[index],
          path: '$path.relearnMoves[$index]',
        ),
      for (var index = 0; index < learnset.levelUp.length; index += 1)
        (
          code: 'learnset.level_up_move_empty',
          id: learnset.levelUp[index].moveId,
          path: '$path.levelUp[$index].moveId',
        ),
      ..._moveEntryReferences(path, 'tm', learnset.tm),
      ..._moveEntryReferences(path, 'hm', learnset.hm),
      ..._moveEntryReferences(path, 'tutor', learnset.tutor),
      ..._moveEntryReferences(path, 'egg', learnset.egg),
      ..._moveEntryReferences(path, 'event', learnset.event),
      ..._moveEntryReferences(path, 'transfer', learnset.transfer),
    ];
    for (final reference in moveReferences) {
      final moveId = reference.id.trim();
      if (moveId.isEmpty) {
        collector.error(
          code: reference.code,
          path: reference.path,
          message: 'Learnset "$speciesId" contains an empty move id.',
          action: 'Select an existing move or delete the empty entry.',
        );
      } else if (moveIds != null && !moveIds.contains(moveId)) {
        collector.error(
          code: 'learnset.move_missing_in_catalog',
          path: reference.path,
          message: 'Learnset "$speciesId" references unknown move "$moveId".',
          action:
              'Add "$moveId" to the moves catalog or replace the reference.',
        );
      }
    }
    for (var index = 0; index < learnset.levelUp.length; index += 1) {
      final level = learnset.levelUp[index].level;
      if (level >= 1 && level <= maxLevel) continue;
      collector.error(
        code: 'learnset.level_up_level_invalid',
        path: '$path.levelUp[$index].level',
        message:
            'Learnset "$speciesId" uses level $level outside 1..$maxLevel.',
        action: 'Set the learned level within the active ruleset range.',
      );
    }
  }

  void _validateEvolution(
    PokemonCatalogDocument<PokemonEvolutionFile> document, {
    required Set<String> speciesIds,
    required Set<String>? moveIds,
    required Set<String>? itemIds,
    required int maxLevel,
    required _DiagnosticCollector collector,
  }) {
    final evolution = document.value;
    final path = document.path;
    _validateSchemaVersion(
      evolution.schemaVersion,
      family: 'evolution',
      path: path,
      collector: collector,
    );
    final speciesId = evolution.speciesId.trim();
    if (speciesId.isNotEmpty && !speciesIds.contains(speciesId)) {
      collector.error(
        code: 'evolution.species_missing',
        path: '$path.speciesId',
        message: 'Evolution "$speciesId" references an unknown species.',
        action: 'Create the species or remove its orphan evolution document.',
      );
    }
    for (var index = 0; index < evolution.evolutions.length; index += 1) {
      final entry = evolution.evolutions[index];
      final entryPath = '$path.evolutions[$index]';
      final targetId = entry.targetSpeciesId.trim();
      if (targetId.isEmpty || !speciesIds.contains(targetId)) {
        collector.error(
          code: 'evolution.target_species_missing',
          path: '$entryPath.targetSpeciesId',
          message: 'Evolution "$speciesId" targets an unknown species.',
          action: 'Reference an existing target species.',
        );
      }
      if (targetId.isNotEmpty && targetId == speciesId) {
        collector.error(
          code: 'evolution.self_target',
          path: '$entryPath.targetSpeciesId',
          message: 'Evolution "$speciesId" cannot target itself.',
          action: 'Select a different target species.',
        );
      }
      final method = entry.method.trim();
      if (!supportedEvolutionMethods.contains(method)) {
        collector.error(
          code: 'evolution.method_unsupported',
          path: '$entryPath.method',
          message: 'Evolution "$speciesId" uses unsupported method "$method".',
          action: 'Use one of: ${supportedEvolutionMethods.join(', ')}.',
        );
        continue;
      }
      if (method == 'level_up') {
        final level = entry.minLevel;
        if (level == null || level < 1) {
          collector.error(
            code: 'evolution.min_level_invalid',
            path: '$entryPath.minLevel',
            message: 'Level-up evolution "$speciesId" requires minLevel >= 1.',
            action: 'Set a positive minLevel for the evolution.',
          );
        } else if (level > maxLevel) {
          collector.error(
            code: 'evolution.level_above_ruleset_max',
            path: '$entryPath.minLevel',
            message:
                'Evolution "$speciesId" requires level $level above $maxLevel.',
            action: 'Set minLevel within the active ruleset range.',
          );
        }
      }
      if (method == 'friendship') {
        final friendship = entry.minFriendship;
        if (friendship == null || friendship < 0 || friendship > 255) {
          collector.error(
            code: 'evolution.friendship_invalid',
            path: '$entryPath.minFriendship',
            message: 'Friendship evolution "$speciesId" requires 0..255.',
            action: 'Set minFriendship between 0 and 255.',
          );
        }
      }
      if (method == 'known_move') {
        _validateOptionalConditionReference(
          value: entry.requiredMoveId,
          knownIds: moveIds,
          code: 'evolution.required_move_missing',
          path: '$entryPath.requiredMoveId',
          label: 'move',
          collector: collector,
        );
      }
      if (method == 'item' || method == 'use_item') {
        _validateOptionalConditionReference(
          value: entry.itemId,
          knownIds: itemIds,
          code: 'evolution.item_missing',
          path: '$entryPath.itemId',
          label: 'item',
          collector: collector,
        );
      }
    }
  }

  void _validateEvolutionCycles(
    List<PokemonCatalogDocument<PokemonEvolutionFile>> documents,
    _DiagnosticCollector collector,
  ) {
    final edges = <String, Set<String>>{};
    final paths = <String, String>{};
    for (final document in documents) {
      final source = document.value.speciesId.trim();
      if (source.isEmpty) continue;
      paths.putIfAbsent(source, () => document.path);
      final targets = edges.putIfAbsent(source, () => <String>{});
      for (final evolution in document.value.evolutions) {
        final target = evolution.targetSpeciesId.trim();
        if (target.isNotEmpty) targets.add(target);
      }
    }
    final reported = <String>{};
    final sources = edges.keys.toList(growable: false)..sort();
    for (final source in sources) {
      final targets = edges[source]!.toList(growable: false)..sort();
      for (final target in targets) {
        if (!_canReach(target, source, edges, <String>{})) continue;
        final key = <String>[source, target]..sort();
        if (!reported.add(key.join('|'))) continue;
        collector.error(
          code: 'evolution.cycle_detected',
          path: '${paths[source] ?? 'evolutions/$source'}.evolutions',
          message:
              'Evolution graph contains a cycle involving "$source" and "$target".',
          action: 'Remove one evolution edge so progression is acyclic.',
        );
      }
    }
  }

  void _validateMedia(
    PokemonCatalogDocument<PokemonMediaFile> document, {
    required Set<String> speciesIds,
    required Set<String>? formIds,
    required Set<String> assetPaths,
    required bool assetInventoryComplete,
    required _DiagnosticCollector collector,
  }) {
    final media = document.value;
    final path = document.path;
    _validateSchemaVersion(
      media.schemaVersion,
      family: 'media',
      path: path,
      collector: collector,
    );
    final speciesId = media.speciesId.trim();
    if (speciesId.isNotEmpty && !speciesIds.contains(speciesId)) {
      collector.error(
        code: 'media.species_missing',
        path: '$path.speciesId',
        message: 'Media "$speciesId" references an unknown species.',
        action: 'Create the species or remove its orphan media document.',
      );
    }
    if (formIds != null) {
      final declaredVariants = media.variants.keys
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      final sortedFormIds = formIds.toList(growable: false)..sort();
      for (final formId in sortedFormIds) {
        if (declaredVariants.contains(formId)) continue;
        collector.error(
          code: 'media.form_variant_missing',
          path: '$path.variants.$formId',
          message: 'Media "$speciesId" has no variant for form "$formId".',
          action: 'Add a media variant for every declared Pokemon form.',
        );
      }
      final sortedVariants = declaredVariants.toList(growable: false)..sort();
      for (final formId in sortedVariants) {
        if (formIds.contains(formId)) continue;
        collector.error(
          code: 'media.form_variant_unknown',
          path: '$path.variants.$formId',
          message: 'Media "$speciesId" declares unknown form "$formId".',
          action:
              'Remove the variant or declare the form in the species graph.',
        );
      }
    }
    final defaultFormId = media.defaultFormId.trim();
    final variant = media.variants[defaultFormId];
    if (defaultFormId.isEmpty || variant == null) {
      collector.error(
        code: 'media.default_form_missing',
        path: '$path.defaultFormId',
        message: 'Media "$speciesId" has no variant for its default form.',
        action: 'Select an existing media variant as the default form.',
      );
      return;
    }
    _validateRequiredMediaPath(
      value: variant.frontStatic,
      code: 'media.front_static_missing',
      path: '$path.variants.$defaultFormId.frontStatic',
      label: 'front battle sprite',
      assetPaths: assetPaths,
      assetInventoryComplete: assetInventoryComplete,
      collector: collector,
    );
    _validateRequiredMediaPath(
      value: variant.backStatic,
      code: 'media.back_static_missing',
      path: '$path.variants.$defaultFormId.backStatic',
      label: 'back battle sprite',
      assetPaths: assetPaths,
      assetInventoryComplete: assetInventoryComplete,
      collector: collector,
    );
  }

  void _validateRequiredMediaPath({
    required String? value,
    required String code,
    required String path,
    required String label,
    required Set<String> assetPaths,
    required bool assetInventoryComplete,
    required _DiagnosticCollector collector,
  }) {
    final assetPath = value?.trim() ?? '';
    if (assetPath.isEmpty) {
      collector.error(
        code: code,
        path: path,
        message: 'The default Pokemon form is missing its $label.',
        action: 'Select a project-local asset for the $label.',
      );
      return;
    }
    if (assetInventoryComplete && !assetPaths.contains(assetPath)) {
      collector.error(
        code: 'media.asset_missing',
        path: path,
        message: 'Required Pokemon media asset "$assetPath" does not exist.',
        action: 'Import the asset or update the media reference.',
      );
    }
  }

  void _validateSchemaVersion(
    int actual, {
    required String family,
    required String path,
    required _DiagnosticCollector collector,
  }) {
    if (actual == currentPokemonDataSchemaVersion) return;
    collector.error(
      code: '$family.schema_version_unsupported',
      path: '$path.schemaVersion',
      message: '${_title(family)} schemaVersion $actual is unsupported.',
      action: 'Use schemaVersion $currentPokemonDataSchemaVersion.',
    );
  }

  void _requireCatalogReferences({
    required Iterable<String> values,
    required Set<String>? catalogIds,
    required String emptyCode,
    required String missingCode,
    required String path,
    required String owner,
    required String label,
    required _DiagnosticCollector collector,
  }) {
    final normalized = values.map((value) => value.trim()).toList();
    if (normalized.isEmpty || normalized.every((value) => value.isEmpty)) {
      collector.error(
        code: emptyCode,
        path: path,
        message: 'Species "$owner" must define at least one $label.',
        action: 'Select an existing $label from the project catalog.',
      );
      return;
    }
    final seen = <String>{};
    for (var index = 0; index < normalized.length; index += 1) {
      final value = normalized[index];
      if (value.isEmpty) {
        collector.error(
          code: emptyCode,
          path: '$path[$index]',
          message: 'Species "$owner" contains an empty $label reference.',
          action: 'Select an existing $label or remove the empty entry.',
        );
      } else if (!seen.add(value)) {
        collector.error(
          code: 'species.${label}_duplicate',
          path: '$path[$index]',
          message: 'Species "$owner" declares duplicate $label "$value".',
          action: 'Keep the $label reference only once.',
        );
      } else if (catalogIds != null && !catalogIds.contains(value)) {
        collector.error(
          code: missingCode,
          path: '$path[$index]',
          message: 'Species "$owner" references unknown $label "$value".',
          action:
              'Add "$value" to the ${label}s catalog or replace the reference.',
        );
      }
    }
  }

  void _validateReference({
    required String value,
    required Set<String>? knownIds,
    required String emptyCode,
    required String missingCode,
    required String path,
    required String label,
    required _DiagnosticCollector collector,
  }) {
    final id = value.trim();
    if (id.isEmpty) {
      collector.error(
        code: emptyCode,
        path: path,
        message: 'Pokemon data requires a $label reference.',
        action: 'Select an existing $label.',
      );
    } else if (knownIds != null && !knownIds.contains(id)) {
      collector.error(
        code: missingCode,
        path: path,
        message: 'Pokemon data references unknown $label "$id".',
        action: 'Create "$id" or replace the $label reference.',
      );
    }
  }

  void _validateOptionalConditionReference({
    required String? value,
    required Set<String>? knownIds,
    required String code,
    required String path,
    required String label,
    required _DiagnosticCollector collector,
  }) {
    final id = value?.trim() ?? '';
    if (id.isEmpty || (knownIds != null && !knownIds.contains(id))) {
      collector.error(
        code: code,
        path: path,
        message: 'Evolution condition references an unknown $label.',
        action: 'Select an existing $label for this evolution method.',
      );
    }
  }
}

final class _PokemonFormNode {
  const _PokemonFormNode({required this.document, required this.formId});

  final PokemonCatalogDocument<PokemonSpeciesFile> document;
  final String formId;
}

final class _DiagnosticCollector {
  final List<PokemonCatalogDiagnostic> diagnostics =
      <PokemonCatalogDiagnostic>[];

  void error({
    required String code,
    required String path,
    required String message,
    required String action,
  }) {
    _add(
      code: code,
      severity: PokemonCatalogDiagnosticSeverity.error,
      path: path,
      message: message,
      action: action,
    );
  }

  void warning({
    required String code,
    required String path,
    required String message,
    required String action,
  }) {
    _add(
      code: code,
      severity: PokemonCatalogDiagnosticSeverity.warning,
      path: path,
      message: message,
      action: action,
    );
  }

  void _add({
    required String code,
    required PokemonCatalogDiagnosticSeverity severity,
    required String path,
    required String message,
    required String action,
  }) {
    diagnostics.add(
      PokemonCatalogDiagnostic(
        code: code,
        severity: severity,
        path: path,
        message: message,
        recommendedAction: action,
      ),
    );
  }
}

List<({String code, String id, String path})> _moveEntryReferences(
  String path,
  String field,
  List<PokemonLearnsetMoveEntry> entries,
) => <({String code, String id, String path})>[
  for (var index = 0; index < entries.length; index += 1)
    (
      code: 'learnset.${field}_move_empty',
      id: entries[index].moveId,
      path: '$path.$field[$index].moveId',
    ),
];

bool _canReach(
  String current,
  String target,
  Map<String, Set<String>> edges,
  Set<String> visited,
) {
  if (current == target) return true;
  if (!visited.add(current)) return false;
  for (final next in edges[current] ?? const <String>{}) {
    if (_canReach(next, target, edges, visited)) return true;
  }
  return false;
}

int _compareDiagnostics(
  PokemonCatalogDiagnostic left,
  PokemonCatalogDiagnostic right,
) {
  final severity = left.severity.index.compareTo(right.severity.index);
  if (severity != 0) return severity;
  final path = left.path.compareTo(right.path);
  if (path != 0) return path;
  final code = left.code.compareTo(right.code);
  if (code != 0) return code;
  final message = left.message.compareTo(right.message);
  if (message != 0) return message;
  return left.recommendedAction.compareTo(right.recommendedAction);
}

String _catalogReferenceLabel(String catalog) => switch (catalog) {
  'growth_rates' => 'growth rate',
  'abilities' => 'ability',
  'types' => 'type',
  'moves' => 'move',
  'items' => 'item',
  _ => catalog,
};

String _catalogReferencePlural(String catalog) => switch (catalog) {
  'growth_rates' => 'growth rates',
  'abilities' => 'abilities',
  'types' => 'types',
  'moves' => 'moves',
  'items' => 'items',
  _ => catalog,
};

String _title(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

String _requirePath(String value) {
  final path = value.trim();
  if (path.isEmpty || path != value) {
    throw ArgumentError.value(value, 'path', 'must be a nonblank stable path');
  }
  return path;
}
