import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_trainer.freezed.dart';
part 'project_trainer.g.dart';

/// Entrée Pokémon dans l'équipe d'un [ProjectTrainerEntry].
@freezed
class ProjectTrainerPokemonEntry with _$ProjectTrainerPokemonEntry {
  const factory ProjectTrainerPokemonEntry({
    required String speciesId,
    required int level,

    /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
    @Default([]) List<String> moves,
    String? heldItemId,
    String? formId,

    /// Genre libre : "male", "female", "any", ou null = non spécifié.
    String? gender,
    @Default(false) bool shiny,
  }) = _ProjectTrainerPokemonEntry;

  factory ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerPokemonEntryFromJson(json);
}

/// Fiche projet d'un dresseur, référencé depuis [MapEntityNpcData.trainerId].
@freezed
class ProjectTrainerEntry with _$ProjectTrainerEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTrainerEntry({
    required String id,
    required String name,

    /// Classe libre : "Pokémon Trainer", "Gym Leader", "Rival", etc.
    required String trainerClass,

    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    @Default([]) List<ProjectTrainerPokemonEntry> team,
    @Default([]) List<String> tags,
  }) = _ProjectTrainerEntry;

  factory ProjectTrainerEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerEntryFromJson(json);
}
