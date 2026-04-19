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

    /// Difficulté produit battle exprimée sur l'échelle lisible `1..10`.
    ///
    /// Ce champ reste volontairement optionnel pour deux raisons :
    /// - préserver les anciens trainers du dépôt sans migration forcée ;
    /// - laisser le runtime retomber sur le comportement historique quand
    ///   aucune difficulté explicite n'a encore été authored.
    ///
    /// Interprétation de périmètre :
    /// - cette valeur ne décrit que la sélection d'action adverse en combat ;
    /// - elle n'ouvre ni scripts trainer, ni phases boss, ni switch/replacement
    ///   intelligents ;
    /// - le routing réel vers quelques profils battle-local reste fait côté
    ///   runtime + `map_battle`, pas dans ce modèle data.
    int? battleDifficulty,

    /// Image de fond de combat explicitement authored pour ce trainer.
    ///
    /// Ce champ reste volontairement petit et purement data :
    /// - il stocke un chemin relatif au projet, pas un asset handle global ;
    /// - il ne vit pas dans `map_battle` parce qu'il ne décrit aucune vérité
    ///   métier battle ;
    /// - il permet simplement au runtime de prioriser un fond explicite
    ///   trainer avant le fond contextuel du lot 2 ;
    /// - s'il est absent ou inutilisable, le runtime retombe honnêtement sur
    ///   sa chaîne `explicite > contextuel > fallback`.
    String? battleBackgroundRelativePath,

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
