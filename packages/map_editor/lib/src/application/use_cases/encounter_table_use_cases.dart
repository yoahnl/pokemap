import 'package:map_core/map_core.dart';

import '../authoring_api/encounter_table_persistence_gateway.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

// ---------------------------------------------------------------------------
// Helpers internes
// ---------------------------------------------------------------------------

String _generateUniqueEncounterTableId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'table' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.encounterTables.map((t) => t.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

// ---------------------------------------------------------------------------
// Use cases — tables
// ---------------------------------------------------------------------------

class CreateEncounterTableUseCase {
  CreateEncounterTableUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required EncounterKind encounterKind,
    double chancePerStep = defaultEncounterChancePerStep,
    List<ScriptCondition> conditions = const <ScriptCondition>[],
    List<String> tags = const [],
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const EditorValidationException(
        'Encounter table name cannot be empty',
      );
    }
    final table = ProjectEncounterTable(
      id: _generateUniqueEncounterTableId(project, trimmed),
      name: trimmed,
      encounterKind: encounterKind,
      chancePerStep: chancePerStep,
      conditions: conditions,
      tags: tags,
    );
    final projected = project.copyWith(
      encounterTables: [...project.encounterTables, table],
    );
    ProjectValidator.validate(projected);
    return _persistence.upsert(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      table: table,
    );
  }
}

class UpdateEncounterTableUseCase {
  UpdateEncounterTableUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    double? chancePerStep,
    List<ScriptCondition>? conditions,
    List<String>? tags,
  }) async {
    final index = project.encounterTables.indexWhere((t) => t.id == tableId);
    if (index < 0) {
      throw EditorNotFoundException('Encounter table not found: $tableId');
    }
    final current = project.encounterTables[index];
    final trimmedName = name?.trim() ?? current.name;
    if (trimmedName.isEmpty) {
      throw const EditorValidationException(
        'Encounter table name cannot be empty',
      );
    }
    final updatedTable = current.copyWith(
      name: trimmedName,
      encounterKind: encounterKind ?? current.encounterKind,
      chancePerStep: chancePerStep ?? current.chancePerStep,
      conditions: conditions ?? current.conditions,
      tags: tags ?? current.tags,
    );
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[index] = updatedTable;
    ProjectValidator.validate(project.copyWith(encounterTables: tables));
    return _persistence.upsert(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      table: updatedTable,
    );
  }
}

class DeleteEncounterTableUseCase {
  DeleteEncounterTableUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
  }) async {
    final index = project.encounterTables.indexWhere((t) => t.id == tableId);
    if (index < 0) {
      throw EditorNotFoundException('Encounter table not found: $tableId');
    }
    final tables = List<ProjectEncounterTable>.from(project.encounterTables)
      ..removeAt(index);
    ProjectValidator.validate(project.copyWith(encounterTables: tables));
    return _persistence.remove(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      tableId: tableId,
    );
  }
}

// ---------------------------------------------------------------------------
// Use cases — entrées
// ---------------------------------------------------------------------------

class AddEncounterEntryUseCase {
  AddEncounterEntryUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
    ProjectEncounterPokemonOverrides? pokemonOverrides,
  }) async {
    final index = project.encounterTables.indexWhere((t) => t.id == tableId);
    if (index < 0) {
      throw EditorNotFoundException('Encounter table not found: $tableId');
    }
    final trimmedSpecies = speciesId.trim();
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    if (minLevel <= 0 || maxLevel <= 0) {
      throw const EditorValidationException('Levels must be positive');
    }
    if (minLevel > maxLevel) {
      throw EditorValidationException(
        'minLevel ($minLevel) > maxLevel ($maxLevel)',
      );
    }
    if (weight <= 0) {
      throw const EditorValidationException('Weight must be positive');
    }
    final entry = ProjectEncounterEntry(
      speciesId: trimmedSpecies,
      minLevel: minLevel,
      maxLevel: maxLevel,
      weight: weight,
      pokemonOverrides: pokemonOverrides,
    );
    final table = project.encounterTables[index];
    final updatedTable = table.copyWith(entries: [...table.entries, entry]);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[index] = updatedTable;
    ProjectValidator.validate(project.copyWith(encounterTables: tables));
    return _persistence.upsert(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      table: updatedTable,
    );
  }
}

class UpdateEncounterEntryUseCase {
  UpdateEncounterEntryUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
    ProjectEncounterPokemonOverrides? pokemonOverrides,
    bool clearPokemonOverrides = false,
  }) async {
    final tableIndex =
        project.encounterTables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) {
      throw EditorNotFoundException('Encounter table not found: $tableId');
    }
    final table = project.encounterTables[tableIndex];
    if (entryIndex < 0 || entryIndex >= table.entries.length) {
      throw EditorNotFoundException(
        'Entry index $entryIndex out of range for table $tableId',
      );
    }
    final current = table.entries[entryIndex];
    final trimmedSpecies = speciesId?.trim() ?? current.speciesId;
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    final newMin = minLevel ?? current.minLevel;
    final newMax = maxLevel ?? current.maxLevel;
    final newWeight = weight ?? current.weight;
    if (newMin <= 0 || newMax <= 0) {
      throw const EditorValidationException('Levels must be positive');
    }
    if (newMin > newMax) {
      throw EditorValidationException(
          'minLevel ($newMin) > maxLevel ($newMax)');
    }
    if (newWeight <= 0) {
      throw const EditorValidationException('Weight must be positive');
    }
    final updatedEntry = current.copyWith(
      speciesId: trimmedSpecies,
      minLevel: newMin,
      maxLevel: newMax,
      weight: newWeight,
      pokemonOverrides: clearPokemonOverrides
          ? null
          : pokemonOverrides ?? current.pokemonOverrides,
    );
    final entries = List<ProjectEncounterEntry>.from(table.entries);
    entries[entryIndex] = updatedEntry;
    final updatedTable = table.copyWith(entries: entries);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[tableIndex] = updatedTable;
    ProjectValidator.validate(project.copyWith(encounterTables: tables));
    return _persistence.upsert(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      table: updatedTable,
    );
  }
}

class DeleteEncounterEntryUseCase {
  DeleteEncounterEntryUseCase(this._persistence);

  final EncounterTablePersistenceGateway _persistence;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    required int entryIndex,
  }) async {
    final tableIndex =
        project.encounterTables.indexWhere((t) => t.id == tableId);
    if (tableIndex < 0) {
      throw EditorNotFoundException('Encounter table not found: $tableId');
    }
    final table = project.encounterTables[tableIndex];
    if (entryIndex < 0 || entryIndex >= table.entries.length) {
      throw EditorNotFoundException(
        'Entry index $entryIndex out of range for table $tableId',
      );
    }
    final entries = List<ProjectEncounterEntry>.from(table.entries)
      ..removeAt(entryIndex);
    final updatedTable = table.copyWith(entries: entries);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[tableIndex] = updatedTable;
    ProjectValidator.validate(project.copyWith(encounterTables: tables));
    return _persistence.upsert(
      projectRootPath: workspace.projectRoot,
      expectedProject: project,
      table: updatedTable,
    );
  }
}
