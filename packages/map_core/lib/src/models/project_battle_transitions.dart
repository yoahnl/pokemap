import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_battle_transitions.freezed.dart';
part 'project_battle_transitions.g.dart';

/// Le choix des transitions de début de combat — BETA-BAT-016.
///
/// Ids libres résolus contre le registre moteur du runtime, avec un défaut
/// distinct par type de combat et un repli sûr : un id inconnu retombe sur le
/// défaut du type au lieu de casser l'entrée en combat — la sémantique des
/// registres à `.default` de la référence, en donnée de projet plutôt qu'en
/// variable de jeu.
@freezed
abstract class ProjectBattleTransitionConfig
    with _$ProjectBattleTransitionConfig {
  const factory ProjectBattleTransitionConfig({
    /// Transition des combats sauvages. Défaut moteur : `rby_wild`.
    @JsonKey(includeIfNull: false) String? wildTransitionId,

    /// Transition des combats de dresseurs. Défaut moteur : `dpp_trainer`.
    @JsonKey(includeIfNull: false) String? trainerTransitionId,
  }) = _ProjectBattleTransitionConfig;

  factory ProjectBattleTransitionConfig.fromJson(Map<String, dynamic> json) =>
      _$ProjectBattleTransitionConfigFromJson(json);
}
