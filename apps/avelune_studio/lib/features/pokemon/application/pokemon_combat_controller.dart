import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_combat_port.dart';
import '../domain/pokemon_workspace_models.dart';

part 'pokemon_combat_validation.dart';
part 'pokemon_combat_drafts.dart';

enum PokemonCombatView { wild, trainers, unique }

final class PokemonCombatController {
  PokemonCombatController(
    this.port, {
    required this.changed,
    this.projectChanged,
  });

  final PokemonCombatPort port;
  final void Function() changed;
  final void Function(ProjectManifest manifest)? projectChanged;
  PokemonCombatSnapshot? snapshot;
  PokemonEncounterDraft? table;
  PokemonTrainerDraft? trainer;
  PokemonCombatView view = PokemonCombatView.wild;
  String search = '';
  String? error;
  String? notice;
  final numericInputs = <String, String>{};
  final fieldErrors = <String, String>{};
  bool loading = false;
  bool saving = false;
  bool _disposed = false;
  int _generation = 0;

  bool get dirty =>
      table?.dirty == true || trainer?.dirty == true || fieldErrors.isNotEmpty;
  bool get operationActive => loading || saving;

  List<ProjectEncounterTable> get visibleTables {
    final needle = search.trim().toLowerCase();
    return [
      for (final value
          in snapshot?.project.encounterTables ??
              const <ProjectEncounterTable>[])
        if (value.tags.contains('studio:unique') ==
                (view == PokemonCombatView.unique) &&
            (needle.isEmpty ||
                value.name.toLowerCase().contains(needle) ||
                value.id.toLowerCase().contains(needle)))
          value,
    ];
  }

  List<ProjectTrainerEntry> get visibleTrainers {
    final needle = search.trim().toLowerCase();
    return [
      for (final value
          in snapshot?.project.trainers ?? const <ProjectTrainerEntry>[])
        if (needle.isEmpty ||
            value.name.toLowerCase().contains(needle) ||
            value.id.toLowerCase().contains(needle))
          value,
    ];
  }

  Future<void> load({bool refresh = false}) async {
    if ((snapshot != null || loading) && !refresh) return;
    if (dirty || saving) {
      error = 'Actualisation reportée : votre brouillon est conservé.';
      changed();
      return;
    }
    final generation = ++_generation;
    loading = true;
    error = null;
    changed();
    try {
      final loaded = await port.load();
      if (_disposed || generation != _generation) return;
      snapshot = loaded;
      projectChanged?.call(loaded.project);
      final tableId = table?.current.id;
      final trainerId = trainer?.current.id;
      table = tableId == null
          ? null
          : loaded.project.encounterTables
                .where((value) => value.id == tableId)
                .map((value) => PokemonEncounterDraft(value))
                .firstOrNull;
      trainer = trainerId == null
          ? null
          : loaded.project.trainers
                .where((value) => value.id == trainerId)
                .map((value) => PokemonTrainerDraft(value))
                .firstOrNull;
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) error = '$failure';
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        changed();
      }
    }
  }

  bool setView(PokemonCombatView value) {
    if (dirty || saving) return false;
    view = value;
    table = null;
    trainer = null;
    search = '';
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
    return true;
  }

  bool selectTable(ProjectEncounterTable value) {
    if (dirty || saving) return false;
    table = PokemonEncounterDraft(value);
    trainer = null;
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
    return true;
  }

  bool selectTrainer(ProjectTrainerEntry value) {
    if (dirty || saving) return false;
    trainer = PokemonTrainerDraft(value);
    table = null;
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
    return true;
  }

  bool createTable(String name, {bool unique = false}) {
    if (dirty || saving || snapshot == null) return false;
    final title = name.trim();
    if (title.isEmpty) {
      error = 'Donnez un nom à la rencontre.';
      changed();
      return false;
    }
    final normalized = _newCombatId(
      title,
      snapshot!.project.encounterTables.map((value) => value.id),
    );
    table = PokemonEncounterDraft(
      ProjectEncounterTable(
        id: normalized,
        name: title,
        encounterKind: unique ? EncounterKind.special : EncounterKind.walk,
        chancePerStep: unique ? 0 : defaultEncounterChancePerStep,
        tags: unique ? const ['studio:unique'] : const [],
      ),
      created: true,
    );
    trainer = null;
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
    return true;
  }

  bool createTrainer(String name) {
    if (dirty || saving || snapshot == null) return false;
    final title = name.trim();
    if (title.isEmpty) {
      error = 'Donnez un nom au dresseur.';
      changed();
      return false;
    }
    final normalized = _newCombatId(
      title,
      snapshot!.project.trainers.map((value) => value.id),
    );
    trainer = PokemonTrainerDraft(
      ProjectTrainerEntry(
        id: normalized,
        name: title,
        trainerClass: 'Dresseur',
      ),
      created: true,
    );
    table = null;
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
    return true;
  }

  void editTable(ProjectEncounterTable Function(ProjectEncounterTable) edit) {
    if (_disposed || saving || table == null) return;
    table!.current = edit(table!.current);
    notice = null;
    changed();
  }

  void editTrainer(ProjectTrainerEntry Function(ProjectTrainerEntry) edit) {
    if (_disposed || saving || trainer == null) return;
    trainer!.current = edit(trainer!.current);
    notice = null;
    changed();
  }

  void discard() {
    if (saving) return;
    if (table?.created == true) table = null;
    if (trainer?.created == true) trainer = null;
    table?.reset();
    trainer?.reset();
    error = null;
    numericInputs.clear();
    fieldErrors.clear();
    changed();
  }

  String numericValue(String key, int current) =>
      numericInputs[key] ?? '$current';

  void editNumber(String key, String raw, void Function(int value) apply) {
    numericInputs[key] = raw;
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      fieldErrors[key] = 'Saisissez un nombre entier.';
    } else {
      fieldErrors.remove(key);
      apply(parsed);
    }
    changed();
  }

  Future<bool> save(PokemonWorkspaceIndex index) async {
    if (saving || !dirty) return false;
    if (fieldErrors.isNotEmpty) {
      error = 'Corrigez les nombres invalides avant l’enregistrement.';
      changed();
      return false;
    }
    final selectedTable = table;
    final selectedTrainer = trainer;
    error = _validate(index);
    if (error != null) {
      changed();
      return false;
    }
    saving = true;
    changed();
    try {
      if (selectedTable != null) {
        await port.saveTable(selectedTable.base, selectedTable.current);
      } else if (selectedTrainer != null) {
        await port.saveTrainer(selectedTrainer.base, selectedTrainer.current);
      }
      if (_disposed) return false;
      if (selectedTable != null) selectedTable.markSaved();
      if (selectedTrainer != null) selectedTrainer.markSaved();
      notice = 'Modifications enregistrées.';
      numericInputs.clear();
      saving = false;
      await load(refresh: true);
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = 'Enregistrement refusé : $failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
