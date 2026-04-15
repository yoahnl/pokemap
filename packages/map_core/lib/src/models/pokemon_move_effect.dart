import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_move_effect.freezed.dart';
part 'pokemon_move_effect.g.dart';

/// Portée logique d'un effet structuré.
///
/// On ne copie pas ici la totalité du système de targeting Showdown :
/// - le move lui-même garde déjà son `target` natif ;
/// - les effets ont seulement besoin d'une portée de résolution lisible ;
/// - cela suffit pour la donnée projet et pour un futur bridge runtime -> battle.
enum PokemonMoveEffectTargetScope {
  @JsonValue('self')
  self,
  @JsonValue('target')
  target,
  @JsonValue('field')
  field,
  @JsonValue('ally_side')
  allySide,
  @JsonValue('foe_side')
  foeSide,
  @JsonValue('slot')
  slot,
}

/// Identifiant de stat utilisé par les effets de boost / baisse de stats.
///
/// Le modèle canonique reste volontairement plus lisible que les abréviations
/// internes de Showdown (`atk`, `spa`, etc.). Le convertisseur futur assumera
/// la traduction entre les deux représentations.
enum PokemonMoveStatId {
  @JsonValue('attack')
  attack,
  @JsonValue('defense')
  defense,
  @JsonValue('special_attack')
  specialAttack,
  @JsonValue('special_defense')
  specialDefense,
  @JsonValue('speed')
  speed,
  @JsonValue('accuracy')
  accuracy,
  @JsonValue('evasion')
  evasion,
}

/// Petite structure dédiée pour éviter un payload "Map<String, int>" flou.
///
/// Le lot M2 veut un modèle descriptif mais solide :
/// - un changement de stats doit être typé ;
/// - il doit rester simple à sérialiser ;
/// - il ne doit pas dépendre d'une clé texte magique.
@freezed
class PokemonMoveStatStageChange with _$PokemonMoveStatStageChange {
  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveStatStageChange({
    required PokemonMoveStatId stat,
    required int stages,
  }) = _PokemonMoveStatStageChange;

  factory PokemonMoveStatStageChange.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveStatStageChangeFromJson(json);
}

/// Effet structuré d'un move.
///
/// Décision centrale de M2 :
/// - les comportements de résolution vivent ici ;
/// - les champs natifs (`type`, `basePower`, `accuracy`, etc.) restent sur
///   `PokemonMove` ;
/// - on ne duplique pas une mécanique à la fois en champ natif et en payload
///   libre concurrent.
///
/// Important :
/// - ceci est une capacité de représentation ;
/// - ce n'est pas encore un moteur d'exécution ;
/// - chaque variant embarque seulement le payload nécessaire à la donnée.
@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
class PokemonMoveEffect with _$PokemonMoveEffect {
  const PokemonMoveEffect._();

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.fixedDamage({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Valeur fixe exacte quand le move inflige un montant constant.
    int? value,

    /// Garde-fou minimal pour les cas "fixed damage = niveau du lanceur".
    @Default(false) bool usesUserLevel,
  }) = PokemonMoveEffectFixedDamage;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.multiHit({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int minHits,
    required int maxHits,
  }) = PokemonMoveEffectMultiHit;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.applyStatus({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String statusId,
  }) = PokemonMoveEffectApplyStatus;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.applyVolatileStatus({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String volatileStatusId,
  }) = PokemonMoveEffectApplyVolatileStatus;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.modifyStats({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    @Default(<PokemonMoveStatStageChange>[])
    List<PokemonMoveStatStageChange> stageChanges,
  }) = PokemonMoveEffectModifyStats;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.heal({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectHeal;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.drain({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectDrain;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.recoil({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required int numerator,
    required int denominator,
  }) = PokemonMoveEffectRecoil;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setWeather({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String weatherId,
  }) = PokemonMoveEffectSetWeather;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setTerrain({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String terrainId,
  }) = PokemonMoveEffectSetTerrain;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setPseudoWeather({
    @Default(PokemonMoveEffectTargetScope.field)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String pseudoWeatherId,
  }) = PokemonMoveEffectSetPseudoWeather;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.selfSwitch({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Exemples futurs : `copyvolatile`, `shedtail`, `simple`.
    String? mode,
  }) = PokemonMoveEffectSelfSwitch;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.forceSwitch({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectForceSwitch;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.breakProtect({
    @Default(PokemonMoveEffectTargetScope.target)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectBreakProtect;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.requireRecharge({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
  }) = PokemonMoveEffectRequireRecharge;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.chargeThenStrike({
    @Default(PokemonMoveEffectTargetScope.self)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,

    /// Permet plus tard d'associer un volatile ou un marqueur de charge.
    String? chargeStateId,
  }) = PokemonMoveEffectChargeThenStrike;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setSideCondition({
    @Default(PokemonMoveEffectTargetScope.foeSide)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String conditionId,
  }) = PokemonMoveEffectSetSideCondition;

  @JsonSerializable(explicitToJson: true)
  const factory PokemonMoveEffect.setSlotCondition({
    @Default(PokemonMoveEffectTargetScope.slot)
    PokemonMoveEffectTargetScope targetScope,
    int? chance,
    required String conditionId,
  }) = PokemonMoveEffectSetSlotCondition;

  factory PokemonMoveEffect.fromJson(Map<String, dynamic> json) =>
      _$PokemonMoveEffectFromJson(json).normalized();

  /// Normalisation et validation défensive minimale.
  ///
  /// M2-bis ne transforme pas ce modèle en moteur, mais il doit déjà éviter
  /// les payloads les plus incohérents :
  /// - ids et chaînes obligatoires non vides ;
  /// - `chance` dans une plage raisonnable ;
  /// - `multiHit` cohérent ;
  /// - fractions strictement positives ;
  /// - `fixedDamage` non ambigu.
  PokemonMoveEffect normalized() {
    void validateChance(int? chance) {
      if (chance == null) {
        return;
      }
      if (chance < 1 || chance > 100) {
        throw StateError('PokemonMoveEffect chance must be between 1 and 100');
      }
    }

    int normalizePositivePart(String label, int value) {
      if (value <= 0) {
        throw StateError('$label must be strictly positive');
      }
      return value;
    }

    String normalizeRequiredId(String label, String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        throw StateError('$label must not be empty');
      }
      return trimmed;
    }

    return map(
      fixedDamage: (effect) {
        validateChance(effect.chance);
        final normalizedValue = effect.value;
        if (effect.usesUserLevel) {
          if (normalizedValue != null) {
            throw StateError(
              'PokemonMoveEffect.fixedDamage cannot define both value and usesUserLevel',
            );
          }
          return effect;
        }
        final value = normalizedValue;
        if (value == null || value <= 0) {
          throw StateError(
            'PokemonMoveEffect.fixedDamage requires a strictly positive value when usesUserLevel is false',
          );
        }
        return effect.copyWith(value: value);
      },
      multiHit: (effect) {
        validateChance(effect.chance);
        final minHits = normalizePositivePart(
            'PokemonMoveEffect.multiHit minHits', effect.minHits);
        final maxHits = normalizePositivePart(
            'PokemonMoveEffect.multiHit maxHits', effect.maxHits);
        if (minHits > maxHits) {
          throw StateError(
            'PokemonMoveEffect.multiHit minHits must be less than or equal to maxHits',
          );
        }
        return effect.copyWith(
          minHits: minHits,
          maxHits: maxHits,
        );
      },
      applyStatus: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          statusId: normalizeRequiredId(
            'PokemonMoveEffect.applyStatus statusId',
            effect.statusId,
          ),
        );
      },
      applyVolatileStatus: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          volatileStatusId: normalizeRequiredId(
            'PokemonMoveEffect.applyVolatileStatus volatileStatusId',
            effect.volatileStatusId,
          ),
        );
      },
      modifyStats: (effect) {
        validateChance(effect.chance);
        final stageChanges = effect.stageChanges;
        if (stageChanges.isEmpty) {
          throw StateError(
            'PokemonMoveEffect.modifyStats stageChanges must not be empty',
          );
        }
        final seen = <PokemonMoveStatId>{};
        for (final stageChange in stageChanges) {
          if (stageChange.stages == 0) {
            throw StateError(
              'PokemonMoveEffect.modifyStats stageChanges must not contain zero stages',
            );
          }
          if (!seen.add(stageChange.stat)) {
            throw StateError(
              'PokemonMoveEffect.modifyStats stageChanges must not contain duplicate stats',
            );
          }
        }
        return effect;
      },
      heal: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
              'PokemonMoveEffect.heal numerator', effect.numerator),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.heal denominator',
            effect.denominator,
          ),
        );
      },
      drain: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
              'PokemonMoveEffect.drain numerator', effect.numerator),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.drain denominator',
            effect.denominator,
          ),
        );
      },
      recoil: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          numerator: normalizePositivePart(
            'PokemonMoveEffect.recoil numerator',
            effect.numerator,
          ),
          denominator: normalizePositivePart(
            'PokemonMoveEffect.recoil denominator',
            effect.denominator,
          ),
        );
      },
      setWeather: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          weatherId: normalizeRequiredId(
            'PokemonMoveEffect.setWeather weatherId',
            effect.weatherId,
          ),
        );
      },
      setTerrain: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          terrainId: normalizeRequiredId(
            'PokemonMoveEffect.setTerrain terrainId',
            effect.terrainId,
          ),
        );
      },
      setPseudoWeather: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          pseudoWeatherId: normalizeRequiredId(
            'PokemonMoveEffect.setPseudoWeather pseudoWeatherId',
            effect.pseudoWeatherId,
          ),
        );
      },
      selfSwitch: (effect) {
        validateChance(effect.chance);
        final normalizedMode = effect.mode?.trim();
        return effect.copyWith(
          mode: normalizedMode == null || normalizedMode.isEmpty
              ? null
              : normalizedMode,
        );
      },
      forceSwitch: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      breakProtect: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      requireRecharge: (effect) {
        validateChance(effect.chance);
        return effect;
      },
      chargeThenStrike: (effect) {
        validateChance(effect.chance);
        final normalizedChargeStateId = effect.chargeStateId?.trim();
        return effect.copyWith(
          chargeStateId:
              normalizedChargeStateId == null || normalizedChargeStateId.isEmpty
                  ? null
                  : normalizedChargeStateId,
        );
      },
      setSideCondition: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          conditionId: normalizeRequiredId(
            'PokemonMoveEffect.setSideCondition conditionId',
            effect.conditionId,
          ),
        );
      },
      setSlotCondition: (effect) {
        validateChance(effect.chance);
        return effect.copyWith(
          conditionId: normalizeRequiredId(
            'PokemonMoveEffect.setSlotCondition conditionId',
            effect.conditionId,
          ),
        );
      },
    );
  }
}
