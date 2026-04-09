import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../models/pokemon_validation_report.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

class PokemonProjectValidator {
  const PokemonProjectValidator(this.repository);

  final PokemonReadRepository repository;

  Future<PokemonValidationReport> validate(ProjectWorkspace workspace) async {
    final collector = _PokemonValidationIssueCollector();

    final speciesRecords = await _loadSpecies(workspace, collector);
    final learnsetRecords = await _loadLearnsets(workspace, collector);
    final evolutionRecords = await _loadEvolutions(workspace, collector);

    final speciesIds = <String, int>{};
    for (final record in speciesRecords) {
      final speciesId = record.species.id.trim();
      if (speciesId.isEmpty) {
        continue;
      }
      speciesIds.update(speciesId, (count) => count + 1, ifAbsent: () => 1);
    }

    for (final entry in speciesIds.entries) {
      if (entry.value > 1) {
        collector.addError(
          'species.duplicate_id',
          'Multiple species files share the id "${entry.key}".',
          'species:${entry.key}',
        );
      }
    }

    final validSpeciesIds = speciesIds.keys.toSet();
    final validLearnsetIds = learnsetRecords
        .map((record) => record.learnset.speciesId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final validEvolutionIds = evolutionRecords
        .map((record) => record.evolution.speciesId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final record in speciesRecords) {
      final species = record.species;
      if (species.learnsetRef.trim().isNotEmpty &&
          !validLearnsetIds.contains(species.learnsetRef.trim())) {
        collector.addError(
          'species.learnset_ref_missing',
          'Species "${species.id}" references a missing learnset '
          '"${species.learnsetRef}".',
          record.location,
        );
      }
      if (species.evolutionRef.trim().isNotEmpty &&
          !validEvolutionIds.contains(species.evolutionRef.trim())) {
        collector.addError(
          'species.evolution_ref_missing',
          'Species "${species.id}" references a missing evolution '
          '"${species.evolutionRef}".',
          record.location,
        );
      }
    }

    for (final record in learnsetRecords) {
      final speciesId = record.learnset.speciesId.trim();
      if (speciesId.isNotEmpty && !validSpeciesIds.contains(speciesId)) {
        collector.addError(
          'learnset.species_missing',
          'Learnset "${record.fileId}" references missing species "$speciesId".',
          record.location,
        );
      }
    }

    for (final record in evolutionRecords) {
      final evolution = record.evolution;
      final speciesId = evolution.speciesId.trim();
      if (speciesId.isNotEmpty && !validSpeciesIds.contains(speciesId)) {
        collector.addError(
          'evolution.species_missing',
          'Evolution "${record.fileId}" references missing species "$speciesId".',
          record.location,
        );
      }

      for (final entry in evolution.evolutions) {
        final targetSpeciesId = entry.targetSpeciesId.trim();
        if (targetSpeciesId.isNotEmpty &&
            !validSpeciesIds.contains(targetSpeciesId)) {
          collector.addError(
            'evolution.target_species_missing',
            'Evolution "${speciesId.isEmpty ? record.fileId : speciesId}" '
            'targets missing species "$targetSpeciesId".',
            record.location,
          );
        }
      }
    }

    final movesCatalogIds = await _loadCatalogEntryIds(
      workspace,
      collector,
      catalogKey: 'moves',
      location: 'catalog:moves',
      missingCatalogCode: 'catalog.moves_missing',
      unreadableCatalogCode: 'catalog.moves_unreadable',
      missingCatalogMessage:
          'Moves catalog is unavailable; move reference validation was skipped.',
      unreadableCatalogMessage:
          'Moves catalog could not be read; move reference validation was skipped.',
    );

    if (movesCatalogIds != null) {
      for (final record in learnsetRecords) {
        final usedMoveIds = <String>{
          ...record.learnset.startingMoves.map((value) => value.trim()),
          ...record.learnset.relearnMoves.map((value) => value.trim()),
          ...record.learnset.levelUp.map((entry) => entry.moveId.trim()),
        }..remove('');

        for (final moveId in usedMoveIds) {
          if (!movesCatalogIds.contains(moveId)) {
            collector.addError(
              'learnset.move_missing_in_catalog',
              'Learnset "${record.fileId}" references move "$moveId" '
              'which is absent from the moves catalog.',
              record.location,
            );
          }
        }
      }
    }

    final typesCatalogIds = await _loadCatalogEntryIds(
      workspace,
      collector,
      catalogKey: 'types',
      location: 'catalog:types',
      missingCatalogCode: 'catalog.types_missing',
      unreadableCatalogCode: 'catalog.types_unreadable',
      missingCatalogMessage:
          'Types catalog is unavailable; type reference validation was skipped.',
      unreadableCatalogMessage:
          'Types catalog could not be read; type reference validation was skipped.',
    );

    if (typesCatalogIds != null) {
      for (final record in speciesRecords) {
        for (final typeId in record.species.typing.types.map((value) => value.trim())) {
          if (typeId.isEmpty) {
            continue;
          }
          if (!typesCatalogIds.contains(typeId)) {
            collector.addError(
              'species.type_missing_in_catalog',
              'Species "${record.species.id}" references type "$typeId" '
              'which is absent from the types catalog.',
              record.location,
            );
          }
        }
      }
    }

    return PokemonValidationReport(
      issues: collector.build(),
    );
  }

  Future<List<_LoadedSpeciesRecord>> _loadSpecies(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final speciesFiles = await _safeListFiles(
      collector,
      code: 'species.directory_unreadable',
      message:
          'Pokemon species directory could not be listed; species validation may be incomplete.',
      location: 'species',
      loader: () => repository.listSpeciesFiles(workspace),
    );

    final records = <_LoadedSpeciesRecord>[];
    for (final relativePath in speciesFiles) {
      try {
        final species = await repository.readSpeciesByRelativePath(
          workspace,
          relativePath,
        );
        final location = 'species:$relativePath';
        _validateSpecies(species, location, collector);
        records.add(
          _LoadedSpeciesRecord(
            relativePath: relativePath,
            location: location,
            species: species,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'species.read_error',
          error.message,
          'species:$relativePath',
        );
      }
    }
    return records;
  }

  Future<List<_LoadedLearnsetRecord>> _loadLearnsets(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final learnsetIds = await _safeListFiles(
      collector,
      code: 'learnsets.directory_unreadable',
      message:
          'Pokemon learnsets directory could not be listed; learnset validation may be incomplete.',
      location: 'learnsets',
      loader: () => repository.listLearnsetIds(workspace),
    );

    final records = <_LoadedLearnsetRecord>[];
    for (final fileId in learnsetIds) {
      try {
        final learnset = await repository.readLearnsetById(workspace, fileId);
        final location = 'learnset:$fileId';
        _validateLearnset(learnset, location, collector);
        records.add(
          _LoadedLearnsetRecord(
            fileId: fileId,
            location: location,
            learnset: learnset,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'learnset.read_error',
          error.message,
          'learnset:$fileId',
        );
      }
    }
    return records;
  }

  Future<List<_LoadedEvolutionRecord>> _loadEvolutions(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector,
  ) async {
    final evolutionIds = await _safeListFiles(
      collector,
      code: 'evolutions.directory_unreadable',
      message:
          'Pokemon evolutions directory could not be listed; evolution validation may be incomplete.',
      location: 'evolutions',
      loader: () => repository.listEvolutionIds(workspace),
    );

    final records = <_LoadedEvolutionRecord>[];
    for (final fileId in evolutionIds) {
      try {
        final evolution = await repository.readEvolutionById(workspace, fileId);
        final location = 'evolution:$fileId';
        _validateEvolution(evolution, location, collector);
        records.add(
          _LoadedEvolutionRecord(
            fileId: fileId,
            location: location,
            evolution: evolution,
          ),
        );
      } on EditorApplicationException catch (error) {
        collector.addError(
          'evolution.read_error',
          error.message,
          'evolution:$fileId',
        );
      }
    }
    return records;
  }

  Future<List<String>> _safeListFiles(
    _PokemonValidationIssueCollector collector, {
    required String code,
    required String message,
    required String location,
    required Future<List<String>> Function() loader,
  }) async {
    try {
      return await loader();
    } on EditorApplicationException catch (error) {
      collector.addError(
        code,
        '$message ${error.message}',
        location,
      );
      return const <String>[];
    }
  }

  Future<Set<String>?> _loadCatalogEntryIds(
    ProjectWorkspace workspace,
    _PokemonValidationIssueCollector collector, {
    required String catalogKey,
    required String location,
    required String missingCatalogCode,
    required String unreadableCatalogCode,
    required String missingCatalogMessage,
    required String unreadableCatalogMessage,
  }) async {
    try {
      final catalog = await repository.readCatalogByKey(workspace, catalogKey);
      return catalog.entries
          .map((entry) => (entry['id'] as String?)?.trim() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } on EditorNotFoundException catch (error) {
      collector.addWarning(
        missingCatalogCode,
        '$missingCatalogMessage ${error.message}',
        location,
      );
      return null;
    } on EditorApplicationException catch (error) {
      collector.addError(
        unreadableCatalogCode,
        '$unreadableCatalogMessage ${error.message}',
        location,
      );
      return null;
    }
  }

  void _validateSpecies(
    PokemonSpeciesFile species,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (species.id.trim().isEmpty) {
      collector.addError(
        'species.id_empty',
        'Species id cannot be empty.',
        location,
      );
    }

    if (species.nationalDex <= 0) {
      collector.addError(
        'species.national_dex_invalid',
        'Species "${species.id}" must have nationalDex > 0.',
        location,
      );
    }

    final primaryName = _pickPrimarySpeciesName(species);
    if (primaryName == null || primaryName.isEmpty) {
      collector.addError(
        'species.display_name_missing',
        'Species "${species.id}" does not expose a usable primary name.',
        location,
      );
    }

    final nonEmptyTypes = species.typing.types
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toList(growable: false);
    if (nonEmptyTypes.isEmpty) {
      collector.addError(
        'species.types_empty',
        'Species "${species.id}" must define at least one type.',
        location,
      );
    }

    final duplicateTypes = _findDuplicateValues(nonEmptyTypes);
    for (final duplicateType in duplicateTypes) {
      collector.addError(
        'species.type_duplicate',
        'Species "${species.id}" declares duplicate type "$duplicateType".',
        location,
      );
    }

    if (species.learnsetRef.trim().isEmpty) {
      collector.addError(
        'species.learnset_ref_empty',
        'Species "${species.id}" must define a learnsetRef.',
        location,
      );
    }

    if (species.evolutionRef.trim().isEmpty) {
      collector.addError(
        'species.evolution_ref_empty',
        'Species "${species.id}" must define an evolutionRef.',
        location,
      );
    }
  }

  void _validateLearnset(
    PokemonLearnsetFile learnset,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (learnset.speciesId.trim().isEmpty) {
      collector.addError(
        'learnset.species_id_empty',
        'Learnset speciesId cannot be empty.',
        location,
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        collector.addError(
          'learnset.starting_move_empty',
          'Learnset "${learnset.speciesId}" contains an empty starting move id.',
          location,
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        collector.addError(
          'learnset.relearn_move_empty',
          'Learnset "${learnset.speciesId}" contains an empty relearn move id.',
          location,
        );
      }
    }

    final levelUpKeys = <String>{};
    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        collector.addError(
          'learnset.level_up_move_empty',
          'Learnset "${learnset.speciesId}" contains a level-up entry with an empty moveId.',
          location,
        );
      }
      if (entry.level < 1) {
        collector.addError(
          'learnset.level_up_level_invalid',
          'Learnset "${learnset.speciesId}" contains a level-up entry with level < 1.',
          location,
        );
      }

      final key = '${entry.moveId.trim()}|${entry.level}|${entry.source.trim()}|'
          '${entry.versionGroup.trim()}';
      if (!levelUpKeys.add(key)) {
        collector.addError(
          'learnset.level_up_duplicate',
          'Learnset "${learnset.speciesId}" contains a duplicate level-up entry '
          'for (${entry.moveId}, ${entry.level}, ${entry.source}, ${entry.versionGroup}).',
          location,
        );
      }
    }
  }

  void _validateEvolution(
    PokemonEvolutionFile evolution,
    String location,
    _PokemonValidationIssueCollector collector,
  ) {
    if (evolution.speciesId.trim().isEmpty) {
      collector.addError(
        'evolution.species_id_empty',
        'Evolution speciesId cannot be empty.',
        location,
      );
    }

    for (final entry in evolution.evolutions) {
      final targetSpeciesId = entry.targetSpeciesId.trim();
      if (targetSpeciesId.isEmpty) {
        collector.addError(
          'evolution.target_species_empty',
          'Evolution "${evolution.speciesId}" contains an empty targetSpeciesId.',
          location,
        );
      }
      if (targetSpeciesId.isNotEmpty &&
          targetSpeciesId == evolution.speciesId.trim()) {
        collector.addError(
          'evolution.self_target',
          'Evolution "${evolution.speciesId}" cannot target itself.',
          location,
        );
      }
      if (entry.method.trim() == 'level_up' &&
          entry.minLevel != null &&
          entry.minLevel! < 1) {
        collector.addError(
          'evolution.min_level_invalid',
          'Evolution "${evolution.speciesId}" has level_up with minLevel < 1.',
          location,
        );
      }
    }
  }

  String? _pickPrimarySpeciesName(PokemonSpeciesFile species) {
    final englishName = species.names['en']?.trim();
    if (englishName != null && englishName.isNotEmpty) {
      return englishName;
    }

    final frenchName = species.names['fr']?.trim();
    if (frenchName != null && frenchName.isNotEmpty) {
      return frenchName;
    }

    final speciesId = species.id.trim();
    if (speciesId.isNotEmpty) {
      return speciesId;
    }

    return null;
  }

  Set<String> _findDuplicateValues(List<String> values) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final value in values) {
      if (!seen.add(value)) {
        duplicates.add(value);
      }
    }
    return duplicates;
  }
}

class _LoadedSpeciesRecord {
  const _LoadedSpeciesRecord({
    required this.relativePath,
    required this.location,
    required this.species,
  });

  final String relativePath;
  final String location;
  final PokemonSpeciesFile species;
}

class _LoadedLearnsetRecord {
  const _LoadedLearnsetRecord({
    required this.fileId,
    required this.location,
    required this.learnset,
  });

  final String fileId;
  final String location;
  final PokemonLearnsetFile learnset;
}

class _LoadedEvolutionRecord {
  const _LoadedEvolutionRecord({
    required this.fileId,
    required this.location,
    required this.evolution,
  });

  final String fileId;
  final String location;
  final PokemonEvolutionFile evolution;
}

class _PokemonValidationIssueCollector {
  final List<PokemonValidationIssue> _issues = <PokemonValidationIssue>[];

  void addError(String code, String message, String location) {
    _issues.add(
      PokemonValidationIssue(
        severity: PokemonValidationSeverity.error,
        code: code,
        message: message,
        location: location,
      ),
    );
  }

  void addWarning(String code, String message, String location) {
    _issues.add(
      PokemonValidationIssue(
        severity: PokemonValidationSeverity.warning,
        code: code,
        message: message,
        location: location,
      ),
    );
  }

  List<PokemonValidationIssue> build() {
    final issues = List<PokemonValidationIssue>.from(_issues);
    issues.sort((left, right) {
      final severityCompare =
          _severityRank(left.severity).compareTo(_severityRank(right.severity));
      if (severityCompare != 0) {
        return severityCompare;
      }

      final locationCompare = left.location.compareTo(right.location);
      if (locationCompare != 0) {
        return locationCompare;
      }

      final codeCompare = left.code.compareTo(right.code);
      if (codeCompare != 0) {
        return codeCompare;
      }

      return left.message.compareTo(right.message);
    });
    return issues;
  }

  int _severityRank(PokemonValidationSeverity severity) {
    switch (severity) {
      case PokemonValidationSeverity.error:
        return 0;
      case PokemonValidationSeverity.warning:
        return 1;
    }
  }
}
