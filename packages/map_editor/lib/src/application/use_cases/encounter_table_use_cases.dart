import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
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
  CreateEncounterTableUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required EncounterKind encounterKind,
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
      tags: tags,
    );
    final updated = project.copyWith(
      encounterTables: [...project.encounterTables, table],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateEncounterTableUseCase {
  UpdateEncounterTableUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
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
    final updated_table = current.copyWith(
      name: trimmedName,
      encounterKind: encounterKind ?? current.encounterKind,
      tags: tags ?? current.tags,
    );
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[index] = updated_table;
    final updated = project.copyWith(encounterTables: tables);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteEncounterTableUseCase {
  DeleteEncounterTableUseCase(this._repo);

  final ProjectRepository _repo;

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
    final updated = project.copyWith(encounterTables: tables);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

// ---------------------------------------------------------------------------
// Use cases — entrées
// ---------------------------------------------------------------------------

class AddEncounterEntryUseCase {
  AddEncounterEntryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
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
    );
    final table = project.encounterTables[index];
    final updated_table =
        table.copyWith(entries: [...table.entries, entry]);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[index] = updated_table;
    final updated = project.copyWith(encounterTables: tables);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateEncounterEntryUseCase {
  UpdateEncounterEntryUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
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
      throw EditorValidationException('minLevel ($newMin) > maxLevel ($newMax)');
    }
    if (newWeight <= 0) {
      throw const EditorValidationException('Weight must be positive');
    }
    final updated_entry = current.copyWith(
      speciesId: trimmedSpecies,
      minLevel: newMin,
      maxLevel: newMax,
      weight: newWeight,
    );
    final entries = List<ProjectEncounterEntry>.from(table.entries);
    entries[entryIndex] = updated_entry;
    final updated_table = table.copyWith(entries: entries);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[tableIndex] = updated_table;
    final updated = project.copyWith(encounterTables: tables);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteEncounterEntryUseCase {
  DeleteEncounterEntryUseCase(this._repo);

  final ProjectRepository _repo;

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
    final updated_table = table.copyWith(entries: entries);
    final tables = List<ProjectEncounterTable>.from(project.encounterTables);
    tables[tableIndex] = updated_table;
    final updated = project.copyWith(encounterTables: tables);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
