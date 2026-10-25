import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../domain/pokemon_combat_port.dart';
import '../domain/pokemon_workspace_models.dart';

part 'pokemon_combat_validation.dart';
part 'pokemon_combat_drafts.dart';
part 'pokemon_combat_character_references.dart';

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

  Future<void> analyzeReferences() =>
      load(refresh: true, analyzeReferences: true);

  Future<void> load({
    bool refresh = false,
    bool analyzeReferences = false,
  }) async {
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
      final loaded = analyzeReferences && port is PokemonCombatReferencePort
          ? await (port as PokemonCombatReferencePort).analyzeReferences()
          : await port.load();
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

  void setTrainerBattleFormat(BattleFormat value) {
    if (_disposed || operationActive || trainer == null) return;
    if (value == BattleFormat.doubles) {
      if (snapshot!.project.pokemon.ruleset.mechanics.disabledFeatures.contains(
        PokemonDisabledFeature.doubleBattles,
      )) {
        error = 'Choisissez les règles Standard pour les combats doubles.';
        changed();
        return;
      }
      if (trainer!.current.tags.contains('static-encounter')) {
        error = 'Les rencontres uniques utilisent un combat simple.';
        changed();
        return;
      }
    }
    error = null;
    editTrainer((current) => current.copyWith(battleFormat: value));
  }

  Future<void> setRuleset(PokemonRulesetProfile value) async {
    if (_disposed || snapshot == null || operationActive) return;
    if (dirty) {
      error = 'Enregistrez ou annulez la fiche avant de changer les règles.';
      changed();
      return;
    }
    final before = snapshot!.project.pokemon.ruleset;
    if (before == value) return;
    if (value.mechanics.disabledFeatures.contains(
          PokemonDisabledFeature.doubleBattles,
        ) &&
        snapshot!.project.trainers.any(
          (trainer) => trainer.battleFormat == BattleFormat.doubles,
        )) {
      error =
          'Repassez les combats doubles en simples avant de choisir Classique.';
      changed();
      return;
    }
    saving = true;
    error = null;
    changed();
    try {
      await port.setRuleset(before, value);
      if (_disposed) return;
      _acceptSavedProject(
        snapshot!.project.copyWith(
          pokemon: snapshot!.project.pokemon.copyWith(ruleset: value),
        ),
      );
      notice = 'Règles du projet enregistrées.';
    } on Object catch (failure) {
      if (!_disposed) error = 'Changement de règles refusé : $failure';
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }

  void addTrainerBattleItem(String itemId, PokemonWorkspaceIndex index) {
    final current = trainer?.current;
    if (current == null ||
        saving ||
        current.battleItems.length >= 16 ||
        current.battleItems.containsKey(itemId) ||
        !eligibleTrainerBattleItems(index.itemCatalog)
            .any((item) => item.id == itemId)) {
      return;
    }
    editTrainer(
      (value) => value.copyWith(battleItems: {...value.battleItems, itemId: 1}),
    );
  }

  void editTrainerBattleItemQuantity(String itemId, String raw) {
    if (trainer == null ||
        saving ||
        !trainer!.current.battleItems.containsKey(itemId)) {
      return;
    }
    final key = 'battleItem:$itemId';
    numericInputs[key] = raw;
    final quantity = int.tryParse(raw);
    if (!RegExp(r'^[0-9]+$').hasMatch(raw) ||
        quantity == null ||
        quantity < 1 ||
        quantity > 99) {
      fieldErrors[key] = 'La quantité doit être un entier entre 1 et 99.';
      changed();
      return;
    }
    fieldErrors.remove(key);
    editTrainer(
      (value) =>
          value.copyWith(battleItems: {...value.battleItems, itemId: quantity}),
    );
  }

  void removeTrainerBattleItem(String itemId) {
    if (trainer == null || saving) return;
    numericInputs.remove('battleItem:$itemId');
    fieldErrors.remove('battleItem:$itemId');
    editTrainer(
      (value) => value.copyWith(
        battleItems: {
          for (final item in value.battleItems.entries)
            if (item.key != itemId) item.key: item.value,
        },
      ),
    );
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

  void setTrainerStatsMode(int index, bool advanced) {
    final current = trainer?.current;
    if (current == null ||
        saving ||
        index < 0 ||
        index >= current.team.length) {
      return;
    }
    final member = current.team[index];
    if (advanced &&
        (member.natureId != null || member.ivs != null || member.evs != null)) {
      return;
    }
    numericInputs.removeWhere(
      (key, _) =>
          key.startsWith('team$index:ivs:') ||
          key.startsWith('team$index:evs:'),
    );
    fieldErrors.removeWhere(
      (key, _) =>
          key.startsWith('team$index:ivs:') ||
          key.startsWith('team$index:evs:') ||
          key == 'team$index:nature',
    );
    _editTrainerMember(
      index,
      member.copyWith(
        natureId: advanced
            ? member.natureId ?? standardTrainerPokemonNatureId
            : null,
        ivs: advanced ? member.ivs ?? standardTrainerPokemonIvs : null,
        evs: advanced ? member.evs ?? standardTrainerPokemonEvs : null,
      ),
    );
  }

  void setTrainerNature(int index, String natureId) {
    final current = trainer?.current;
    if (current == null || saving) return;
    _editTrainerMember(index, current.team[index].copyWith(natureId: natureId));
  }

  void editTrainerStat(int index, String group, String stat, String raw) {
    final current = trainer?.current;
    if (current == null ||
        saving ||
        !trainerPokemonStatKeys.contains(stat) ||
        (group != 'ivs' && group != 'evs')) {
      return;
    }
    final key = 'team$index:$group:$stat';
    numericInputs[key] = raw;
    final value = RegExp(r'^-?[0-9]+$').hasMatch(raw)
        ? int.tryParse(raw)
        : null;
    final max = group == 'ivs' ? 31 : 252;
    if (value == null || value < 0 || value > max) {
      fieldErrors[key] = 'Saisissez un entier de 0 à $max.';
      changed();
      return;
    }
    fieldErrors.remove(key);
    final member = current.team[index];
    final source = group == 'ivs'
        ? member.ivs ?? standardTrainerPokemonIvs
        : member.evs ?? standardTrainerPokemonEvs;
    final spread = PokemonStatSpread.fromJson({
      ...source.toJson(),
      stat: value,
    });
    final updated = group == 'ivs'
        ? member.copyWith(ivs: spread)
        : member.copyWith(evs: spread);
    final totalKey = 'team$index:evs:total';
    fieldErrors.remove(totalKey);
    if (validateTrainerPokemonStats(updated)
        .any((issue) => issue.code == 'trainer.pokemon.evs.total_exceeded')) {
      fieldErrors[totalKey] = 'Le total des EV ne doit pas dépasser 510.';
    }
    _editTrainerMember(index, updated);
  }

  void _editTrainerMember(int index, ProjectTrainerPokemonEntry member) {
    editTrainer(
      (value) => value.copyWith(
        team: [
          for (var i = 0; i < value.team.length; i++)
            if (i == index) member else value.team[i],
        ],
      ),
    );
  }

  void deleteTeamMember(int index) {
    final current = trainer?.current;
    if (current == null ||
        saving ||
        index < 0 ||
        index >= current.team.length) {
      return;
    }
    for (final values in [numericInputs, fieldErrors]) {
      final remapped = <String, String>{};
      for (final entry in values.entries) {
        final match = RegExp(r'^team([0-9]+):').firstMatch(entry.key);
        final owner = match == null ? null : int.parse(match.group(1)!);
        if (owner == index) continue;
        final key = owner != null && owner > index
            ? 'team${owner - 1}:${entry.key.substring(match!.end)}'
            : entry.key;
        remapped[key] = entry.value;
      }
      values
        ..clear()
        ..addAll(remapped);
    }
    editTrainer(
      (value) => value.copyWith(
        team: [
          for (var i = 0; i < value.team.length; i++)
            if (i != index) value.team[i],
        ],
      ),
    );
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
      final project = snapshot!.project;
      _acceptSavedProject(
        project.copyWith(
          encounterTables: selectedTable == null
              ? project.encounterTables
              : [
                  for (final value in project.encounterTables)
                    if (value.id == selectedTable.current.id)
                      selectedTable.current
                    else
                      value,
                  if (!project.encounterTables.any(
                    (value) => value.id == selectedTable.current.id,
                  ))
                    selectedTable.current,
                ],
          trainers: selectedTrainer == null
              ? project.trainers
              : [
                  for (final value in project.trainers)
                    if (value.id == selectedTrainer.current.id)
                      selectedTrainer.current
                    else
                      value,
                  if (!project.trainers.any(
                    (value) => value.id == selectedTrainer.current.id,
                  ))
                    selectedTrainer.current,
                ],
        ),
      );
      return !_disposed;
    } on Object catch (failure) {
      if (!_disposed) error = 'Enregistrement refusé : $failure';
      return false;
    } finally {
      saving = false;
      if (!_disposed) changed();
    }
  }

  void _acceptSavedProject(ProjectManifest project) {
    snapshot = PokemonCombatSnapshot(
      project: project,
      maps: snapshot!.maps,
      referencesComplete: false,
    );
    projectChanged?.call(project);
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
