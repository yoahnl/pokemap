import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';

// ---------------------------------------------------------------------------
// Helpers internes
// ---------------------------------------------------------------------------

String _generateUniqueTrainerId(ProjectManifest project, String seed) {
  final normalized = seed
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = normalized.isEmpty ? 'trainer' : normalized;
  var candidate = base;
  var suffix = 1;
  final existing = project.trainers.map((t) => t.id).toSet();
  while (existing.contains(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

// ---------------------------------------------------------------------------
// Use cases — dresseurs
// ---------------------------------------------------------------------------

class CreateTrainerUseCase {
  CreateTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String name,
    required String trainerClass,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    List<String> tags = const [],
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Trainer name cannot be empty');
    }
    final trimmedClass = trainerClass.trim();
    if (trimmedClass.isEmpty) {
      throw const EditorValidationException('Trainer class cannot be empty');
    }
    final trainer = ProjectTrainerEntry(
      id: _generateUniqueTrainerId(project, trimmedName),
      name: trimmedName,
      trainerClass: trimmedClass,
      characterId: characterId?.trim().isEmpty == true ? null : characterId?.trim(),
      portraitElementId:
          portraitElementId?.trim().isEmpty == true ? null : portraitElementId?.trim(),
      battleThemeId:
          battleThemeId?.trim().isEmpty == true ? null : battleThemeId?.trim(),
      victoryThemeId:
          victoryThemeId?.trim().isEmpty == true ? null : victoryThemeId?.trim(),
      tags: tags,
    );
    final updated = project.copyWith(
      trainers: [...project.trainers, trainer],
    );
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateTrainerUseCase {
  UpdateTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? characterId = _unset,
    Object? portraitElementId = _unset,
    Object? battleThemeId = _unset,
    Object? victoryThemeId = _unset,
    List<String>? tags,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final current = project.trainers[index];
    final trimmedName = name?.trim() ?? current.name;
    if (trimmedName.isEmpty) {
      throw const EditorValidationException('Trainer name cannot be empty');
    }
    final trimmedClass = trainerClass?.trim() ?? current.trainerClass;
    if (trimmedClass.isEmpty) {
      throw const EditorValidationException('Trainer class cannot be empty');
    }
    var updated_trainer = current.copyWith(
      name: trimmedName,
      trainerClass: trimmedClass,
      tags: tags ?? current.tags,
    );
    if (!identical(characterId, _unset)) {
      final v = (characterId as String?)?.trim();
      updated_trainer = updated_trainer.copyWith(
        characterId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(portraitElementId, _unset)) {
      final v = (portraitElementId as String?)?.trim();
      updated_trainer = updated_trainer.copyWith(
        portraitElementId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(battleThemeId, _unset)) {
      final v = (battleThemeId as String?)?.trim();
      updated_trainer = updated_trainer.copyWith(
        battleThemeId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(victoryThemeId, _unset)) {
      final v = (victoryThemeId as String?)?.trim();
      updated_trainer = updated_trainer.copyWith(
        victoryThemeId: (v == null || v.isEmpty) ? null : v,
      );
    }
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[index] = updated_trainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

const Object _unset = Object();

class DeleteTrainerUseCase {
  DeleteTrainerUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainers = List<ProjectTrainerEntry>.from(project.trainers)
      ..removeAt(index);
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

// ---------------------------------------------------------------------------
// Use cases — équipe Pokémon
// ---------------------------------------------------------------------------

class AddTrainerPokemonUseCase {
  AddTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const [],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final index = project.trainers.indexWhere((t) => t.id == trainerId);
    if (index < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trimmedSpecies = speciesId.trim();
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    if (level <= 0) {
      throw const EditorValidationException('Level must be positive');
    }
    final pokemon = ProjectTrainerPokemonEntry(
      speciesId: trimmedSpecies,
      level: level,
      moves: moves,
      heldItemId: heldItemId?.trim().isEmpty == true ? null : heldItemId?.trim(),
      formId: formId?.trim().isEmpty == true ? null : formId?.trim(),
      gender: gender?.trim().isEmpty == true ? null : gender?.trim(),
      shiny: shiny,
    );
    final trainer = project.trainers[index];
    final updated_trainer =
        trainer.copyWith(team: [...trainer.team, pokemon]);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[index] = updated_trainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class UpdateTrainerPokemonUseCase {
  UpdateTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _unset,
    Object? formId = _unset,
    Object? gender = _unset,
    bool? shiny,
  }) async {
    final trainerIndex = project.trainers.indexWhere((t) => t.id == trainerId);
    if (trainerIndex < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainer = project.trainers[trainerIndex];
    if (pokemonIndex < 0 || pokemonIndex >= trainer.team.length) {
      throw EditorNotFoundException(
        'Pokemon index $pokemonIndex out of range for trainer $trainerId',
      );
    }
    final current = trainer.team[pokemonIndex];
    final trimmedSpecies = speciesId?.trim() ?? current.speciesId;
    if (trimmedSpecies.isEmpty) {
      throw const EditorValidationException('Species ID cannot be empty');
    }
    final newLevel = level ?? current.level;
    if (newLevel <= 0) {
      throw const EditorValidationException('Level must be positive');
    }
    var updated_pokemon = current.copyWith(
      speciesId: trimmedSpecies,
      level: newLevel,
      moves: moves ?? current.moves,
      shiny: shiny ?? current.shiny,
    );
    if (!identical(heldItemId, _unset)) {
      final v = (heldItemId as String?)?.trim();
      updated_pokemon = updated_pokemon.copyWith(
        heldItemId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(formId, _unset)) {
      final v = (formId as String?)?.trim();
      updated_pokemon = updated_pokemon.copyWith(
        formId: (v == null || v.isEmpty) ? null : v,
      );
    }
    if (!identical(gender, _unset)) {
      final v = (gender as String?)?.trim();
      updated_pokemon = updated_pokemon.copyWith(
        gender: (v == null || v.isEmpty) ? null : v,
      );
    }
    final team = List<ProjectTrainerPokemonEntry>.from(trainer.team);
    team[pokemonIndex] = updated_pokemon;
    final updated_trainer = trainer.copyWith(team: team);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[trainerIndex] = updated_trainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}

class DeleteTrainerPokemonUseCase {
  DeleteTrainerPokemonUseCase(this._repo);

  final ProjectRepository _repo;

  Future<ProjectManifest> execute(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final trainerIndex = project.trainers.indexWhere((t) => t.id == trainerId);
    if (trainerIndex < 0) {
      throw EditorNotFoundException('Trainer not found: $trainerId');
    }
    final trainer = project.trainers[trainerIndex];
    if (pokemonIndex < 0 || pokemonIndex >= trainer.team.length) {
      throw EditorNotFoundException(
        'Pokemon index $pokemonIndex out of range for trainer $trainerId',
      );
    }
    final team = List<ProjectTrainerPokemonEntry>.from(trainer.team)
      ..removeAt(pokemonIndex);
    final updated_trainer = trainer.copyWith(team: team);
    final trainers = List<ProjectTrainerEntry>.from(project.trainers);
    trainers[trainerIndex] = updated_trainer;
    final updated = project.copyWith(trainers: trainers);
    ProjectValidator.validate(updated);
    await _repo.saveProject(updated, workspace.projectManifestPath);
    return updated;
  }
}
