import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_battle_audio.freezed.dart';
part 'project_battle_audio.g.dart';

/// Les musiques par défaut du combat, au niveau projet — BETA-BAT-015.
///
/// Chemins relatifs au projet, comme `battleBackgroundRelativePath` : la même
/// sémantique de fichier que le reste des assets authorés, aucune indirection
/// de catalogue. La chaîne de sélection runtime les consulte en dernier, après
/// l'override du dresseur puis celui de la carte — c'est la précédence de la
/// référence, où les `Configs.sounds.base*` ne parlent que quand rien de plus
/// précis n'a rien dit.
///
/// Tous les champs sont optionnels : un projet sans musique reste exportable
/// et joue en silence, exactement comme avant ce lot.
@freezed
abstract class ProjectBattleAudioConfig with _$ProjectBattleAudioConfig {
  const factory ProjectBattleAudioConfig({
    /// Combat contre un Pokémon sauvage.
    @JsonKey(includeIfNull: false) String? wildBattleMusicPath,

    /// Combat contre un dresseur, quand le dresseur n'en porte pas.
    @JsonKey(includeIfNull: false) String? trainerBattleMusicPath,

    /// Thème de victoire d'un combat sauvage.
    @JsonKey(includeIfNull: false) String? wildVictoryMusicPath,

    /// Thème de victoire d'un combat de dresseur.
    @JsonKey(includeIfNull: false) String? trainerVictoryMusicPath,

    /// Musique de rencontre, jouée au repérage (le « ! ») avant le combat.
    @JsonKey(includeIfNull: false) String? encounterMusicPath,

    /// Son de début de combat, joué au premier instant de la transition —
    /// BETA-BAT-016. Optionnel et ABSENT PAR DÉFAUT : parité avec la
    /// référence, dont le `battle_start_se` du projet de référence est vide.
    @JsonKey(includeIfNull: false) String? battleStartSePath,
  }) = _ProjectBattleAudioConfig;

  factory ProjectBattleAudioConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectBattleAudioConfigFromJson(json);
}
