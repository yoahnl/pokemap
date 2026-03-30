import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'geometry.dart';

part 'save_data.freezed.dart';
part 'save_data.g.dart';

/// Un Pokémon possédé par le joueur — modèle minimal pour raisonner
/// sur les field moves et l'état de l'équipe.
@freezed
class PlayerPokemon with _$PlayerPokemon {
  @JsonSerializable(explicitToJson: true)
  const factory PlayerPokemon({
    required String id,
    required String speciesId,
    @Default('') String nickname,
    @Default(1) int level,
    @Default([]) List<String> knownMoveIds,
    @Default(false) bool isFainted,
  }) = _PlayerPokemon;

  factory PlayerPokemon.fromJson(Map<String, dynamic> json) =>
      _$PlayerPokemonFromJson(json);
}

/// Équipe active du joueur (max 6 en pratique, non contraint ici).
@freezed
class PlayerParty with _$PlayerParty {
  @JsonSerializable(explicitToJson: true)
  const factory PlayerParty({
    @Default([]) List<PlayerPokemon> members,
  }) = _PlayerParty;

  factory PlayerParty.fromJson(Map<String, dynamic> json) =>
      _$PlayerPartyFromJson(json);
}

/// Progression du joueur — field abilities débloquées, flags scénaristiques.
@freezed
class PlayerProgression with _$PlayerProgression {
  @JsonSerializable(explicitToJson: true)
  const factory PlayerProgression({
    @Default([]) List<FieldAbility> unlockedFieldAbilities,
    @Default([]) List<String> storyFlags,
  }) = _PlayerProgression;

  factory PlayerProgression.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressionFromJson(json);
}

/// Racine de l'état persistant de la partie.
///
/// Sérialisable JSON, immutable, indépendant du runtime.
/// Pensé pour évoluer vers une vraie sauvegarde disque.
@freezed
class SaveData with _$SaveData {
  @JsonSerializable(explicitToJson: true)
  const factory SaveData({
    required String saveId,
    @Default('') String currentMapId,
    @Default(GridPos(x: 0, y: 0)) GridPos playerPosition,
    @Default(EntityFacing.south) EntityFacing playerFacing,
    @Default(PlayerParty()) PlayerParty party,
    @Default(PlayerProgression()) PlayerProgression progression,
    @Default({}) Map<String, String> properties,
  }) = _SaveData;

  factory SaveData.fromJson(Map<String, dynamic> json) =>
      _$SaveDataFromJson(json);
}
