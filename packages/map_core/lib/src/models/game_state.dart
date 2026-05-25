import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';
import 'save_data.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// Valeur scalaire pour les variables de script.
///
/// Types supportés : bool, int, string.
/// Le double est exclu volontairement pour éviter les problèmes de précision
/// dans les comparaisons de conditions.
@freezed
class ScriptVariableValue with _$ScriptVariableValue {
  const factory ScriptVariableValue.bool(bool value) = ScriptVariableValueBool;
  const factory ScriptVariableValue.int(int value) = ScriptVariableValueInt;
  const factory ScriptVariableValue.string(String value) =
      ScriptVariableValueString;

  factory ScriptVariableValue.fromJson(Map<String, dynamic> json) =>
      _$ScriptVariableValueFromJson(json);
}

/// Collection de variables de script.
///
/// Clés : identifiants alphanumériques (ex: "rival_defeated", "starter_chosen").
/// Valeurs : [ScriptVariableValue] (bool/int/string).
@freezed
class ScriptVariables with _$ScriptVariables {
  @JsonSerializable(explicitToJson: true)
  const factory ScriptVariables({
    @Default({}) Map<String, ScriptVariableValue> values,
  }) = _ScriptVariables;

  factory ScriptVariables.fromJson(Map<String, dynamic> json) =>
      _$ScriptVariablesFromJson(json);
}

/// Flags narratifs / progression.
///
/// Contrairement aux variables, les flags sont purement booléens
/// et représentent des états binaires (accompli / non accompli).
///
/// Exemples : "professor_met", "starter_received", "surf_unlocked".
@freezed
class StoryFlags with _$StoryFlags {
  const factory StoryFlags({
    @Default({}) Set<String> activeFlags,
  }) = _StoryFlags;

  factory StoryFlags.fromJson(Map<String, dynamic> json) =>
      _$StoryFlagsFromJson(json);
}

/// État de partie complet.
///
/// Inclut :
/// - identité de la save
/// - état du monde (map, position, facing)
/// - équipe du joueur
/// - progression (flags, variables, field abilities)
/// - état des événements consommés
///
/// Immutable, sérialisable JSON, indépendant du runtime.
@freezed
class GameState with _$GameState {
  @JsonSerializable(explicitToJson: true)
  const factory GameState({
    /// Identifiant unique de la sauvegarde.
    required String saveId,

    /// Map actuelle du joueur.
    @Default('') String currentMapId,

    /// Position du joueur sur la map.
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,

    /// Orientation du joueur.
    @Default(EntityFacing.south) EntityFacing playerFacing,

    /// Mode de déplacement actuel (walk / surf).
    @Default(MovementMode.walk) MovementMode playerMovementMode,

    /// Équipe du joueur.
    @Default(PlayerParty()) PlayerParty party,
    @Default(PokemonStorage()) PokemonStorage pokemonStorage,
    @Default(TrainerProfile(name: 'Player')) TrainerProfile trainerProfile,
    @Default(Bag()) Bag bag,

    /// Progression narrative et capacités.
    @Default(PlayerProgression()) PlayerProgression progression,

    /// Variables de script (int/bool/string).
    @Default(ScriptVariables()) ScriptVariables scriptVariables,

    /// Flags narratifs (booléens).
    @Default(StoryFlags()) StoryFlags storyFlags,

    /// IDs d'événements déjà consommés (objets ramassés, etc.).
    @Default({}) Set<String> consumedEventIds,

    /// Métadonnées internes (timestamp, version, etc.).
    @Default({}) Map<String, String> metadata,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}
