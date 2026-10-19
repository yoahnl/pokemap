import 'package:freezed_annotation/freezed_annotation.dart';

import '../operations/trainer_pokemon_stats.dart';
import 'enums.dart';
import 'save_data.dart';

part 'project_trainer.freezed.dart';
part 'project_trainer.g.dart';

const trainerBattleItemMaxDistinctCount = 16;
const trainerBattleItemMinQuantity = 1;
const trainerBattleItemMaxQuantity = 99;

Map<String, int> _projectTrainerBattleItemsFromJson(Object? value) {
  if (value is! Map) {
    throw FormatException(
      'ProjectTrainerEntry.battleItems must be an object',
      value,
    );
  }
  final stock = <String, int>{};
  for (final entry in value.entries) {
    if (entry.key is! String || entry.value is! int) {
      throw FormatException(
        'ProjectTrainerEntry.battleItems requires string IDs and integer quantities',
        value,
      );
    }
    stock[entry.key as String] = entry.value as int;
  }
  return stock;
}

Map<String, dynamic> _projectTrainerEntryJson(Map<String, dynamic> json) {
  if (json.containsKey('battleItems')) {
    _projectTrainerBattleItemsFromJson(json['battleItems']);
  }
  return _rejectExplicitNullInteger(
    json,
    key: 'moneyReward',
    owner: 'ProjectTrainerEntry',
  );
}

PokemonStatSpread? _projectTrainerStatSpreadFromJson(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! Map ||
      value.length != trainerPokemonStatKeys.length ||
      !trainerPokemonStatKeys.every(value.containsKey) ||
      value.values.any((stat) => stat is! int)) {
    throw FormatException(
      'Trainer ivs/evs must contain exactly six integer stat values.',
      value,
    );
  }
  return PokemonStatSpread.fromJson(Map<String, dynamic>.from(value));
}

Map<String, dynamic> _projectTrainerPokemonJson(Map<String, dynamic> json) {
  final natureId = json['natureId'];
  if (natureId != null && natureId is! String) {
    throw FormatException('Trainer natureId must be a string.', natureId);
  }
  return json;
}

ProjectTrainerPokemonEntry _validatedTrainerPokemonEntry(
  ProjectTrainerPokemonEntry member,
) {
  final issues = validateTrainerPokemonStats(member);
  if (issues.isNotEmpty) {
    throw FormatException(issues.first.message);
  }
  return member;
}

/// Preset auteur optionnel d'un dresseur.
///
/// `null` sur [ProjectTrainerEntry.templateKind] reste le trainer générique
/// historique. Les presets spécialisés activent des invariants de validation
/// supplémentaires sans introduire de moteur de scénario dans `map_core`.
enum ProjectTrainerTemplateKind {
  @JsonValue('gym_leader')
  gymLeader,
  @JsonValue('rival')
  rival,
}

/// Politique MVP de réaffrontement.
///
/// `null` reste strictement one-shot pour préserver les projets historiques.
/// La valeur [allowed] autorise un nouveau combat après le dialogue de victoire,
/// tout en conservant le flag `trainer_defeated:<id>` comme preuve persistante.
enum ProjectTrainerRematchPolicy {
  @JsonValue('allowed')
  allowed,
}

int _projectTrainerItemQuantityFromJson(Object? value) {
  if (value is! int) {
    throw FormatException(
      'ProjectTrainerItemGrant.quantity must be an integer',
      value,
    );
  }
  return value;
}

int _projectTrainerMoneyRewardFromJson(Object? value) {
  if (value is! int) {
    throw FormatException(
      'ProjectTrainerEntry.moneyReward must be an integer',
      value,
    );
  }
  return value;
}

Map<String, dynamic> _rejectExplicitNullInteger(
  Map<String, dynamic> json, {
  required String key,
  required String owner,
}) {
  if (json.containsKey(key) && json[key] == null) {
    throw FormatException('$owner.$key must be an integer', null);
  }
  return json;
}

/// Item accordé par un trainer vaincu.
@freezed
abstract class ProjectTrainerItemGrant with _$ProjectTrainerItemGrant {
  const factory ProjectTrainerItemGrant({
    required String itemId,
    @JsonKey(fromJson: _projectTrainerItemQuantityFromJson)
    @Default(1)
    int quantity,
  }) = _ProjectTrainerItemGrant;

  factory ProjectTrainerItemGrant.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerItemGrantFromJson(
        _rejectExplicitNullInteger(
          json,
          key: 'quantity',
          owner: 'ProjectTrainerItemGrant',
        ),
      );
}

/// Entrée Pokémon dans l'équipe d'un [ProjectTrainerEntry].
@Freezed(fromJson: true, toJson: true)
abstract class ProjectTrainerPokemonEntry with _$ProjectTrainerPokemonEntry {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectTrainerPokemonEntry({
    required String speciesId,
    required int level,

    /// IDs de capacités (ordre libre, max 4 recommandé — non enforced).
    @Default([]) List<String> moves,
    String? heldItemId,
    @JsonKey(includeIfNull: false) String? ballItemId,
    @JsonKey(includeIfNull: false) String? natureId,
    @JsonKey(
      includeIfNull: false,
      fromJson: _projectTrainerStatSpreadFromJson,
    )
    PokemonStatSpread? ivs,
    @JsonKey(
      includeIfNull: false,
      fromJson: _projectTrainerStatSpreadFromJson,
    )
    PokemonStatSpread? evs,

    /// Override d'ability authoré — BETA-TRN-003.
    ///
    /// Absent, le runtime retombe sur l'ability primaire de l'espèce, le
    /// comportement historique. Renseigné, il doit exister dans le catalogue
    /// d'abilities du projet : la validation de jouabilité le bloque sinon.
    String? abilityId,
    String? formId,

    /// Genre libre : "male", "female", "any", ou null = non spécifié.
    String? gender,
    @Default(false) bool shiny,
  }) = _ProjectTrainerPokemonEntry;

  factory ProjectTrainerPokemonEntry.fromJson(Map<String, dynamic> json) =>
      _validatedTrainerPokemonEntry(
        _$ProjectTrainerPokemonEntryFromJson(_projectTrainerPokemonJson(json)),
      );
}

/// Fiche projet d'un dresseur, référencé depuis [MapEntityNpcData.trainerId].
@freezed
abstract class ProjectTrainerEntry with _$ProjectTrainerEntry {
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
    @JsonKey(fromJson: _projectTrainerBattleItemsFromJson)
    @Default(<String, int>{})
    Map<String, int> battleItems,

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

    /// Sprite de combat du dresseur — BETA-BAT-017.
    ///
    /// La référence fait réapparaître le dresseur vaincu à la place de son
    /// Pokémon avec « Vous avez battu X ! ». Même contrat que
    /// [battleBackgroundRelativePath] : un chemin relatif au projet, optionnel,
    /// et le runtime retombe honnêtement sur le message seul quand il est
    /// absent ou illisible.
    @JsonKey(includeIfNull: false) String? battleSpriteRelativePath,

    /// Transition de début de combat de ce dresseur — BETA-BAT-019.
    ///
    /// Un id du registre moteur ; gagne sur la zone et le défaut projet.
    /// Absent ou inconnu = la chaîne continue (zone > projet > moteur).
    @JsonKey(includeIfNull: false) String? battleTransitionId,
    String? characterId,
    String? portraitElementId,

    /// Musiques du combat contre ce dresseur — BETA-BAT-015.
    ///
    /// Chemins relatifs au projet, comme `battleBackgroundRelativePath` :
    /// même sémantique, même chaîne « explicite > défaut projet > silence ».
    /// Ces champs s'appelaient `battleThemeId` / `victoryThemeId` alors que
    /// rien ne les consommait et qu'aucun catalogue ne résolvait ces « id » —
    /// des chemins qui disent leur nom remplacent des identifiants qui
    /// mentaient (politique pré-1.0.0 : pas de pont de compatibilité).
    String? battleMusicPath,
    String? victoryMusicPath,

    /// Récompenses auteur neutres par défaut pour préserver les projets
    /// historiques. Leur application runtime appartient aux lots suivants.
    @JsonKey(fromJson: _projectTrainerMoneyRewardFromJson)
    @Default(0)
    int moneyReward,
    @Default([]) List<ProjectTrainerItemGrant> rewardItemGrants,
    @Default([]) List<String> rewardFlagIds,
    @JsonKey(includeIfNull: false) String? rewardBadgeId,
    @JsonKey(includeIfNull: false) FieldAbility? rewardFieldAbilityUnlock,
    @JsonKey(includeIfNull: false) ProjectTrainerTemplateKind? templateKind,
    @JsonKey(includeIfNull: false) ProjectTrainerRematchPolicy? rematchPolicy,
    @JsonKey(includeIfNull: false) String? preBattleDialogueId,
    @JsonKey(includeIfNull: false) String? victoryDialogueId,
    @JsonKey(includeIfNull: false) String? defeatDialogueId,
    @Default([]) List<ProjectTrainerPokemonEntry> team,
    @Default([]) List<String> tags,
  }) = _ProjectTrainerEntry;

  factory ProjectTrainerEntry.fromJson(Map<String, dynamic> json) =>
      _$ProjectTrainerEntryFromJson(_projectTrainerEntryJson(json));
}
