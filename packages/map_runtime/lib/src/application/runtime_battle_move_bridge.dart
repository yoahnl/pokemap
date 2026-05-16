import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_move_bridge_diagnostics.dart';
import 'runtime_battle_setup_exception.dart';

/// Bridge runtime -> battle pour un sous-ensemble honnête de `PokemonMove`.
///
/// Frontière volontaire de M8 :
/// - le loader runtime charge le canonique sans faire de policy d'exécution ;
/// - ce bridge décide si un move canonique peut être projeté honnêtement vers
///   le moteur battle MVP actuel ;
/// - `map_battle` exécute ensuite uniquement ce petit contrat battle enrichi.
///
/// Le but n'est pas de "supporter un peu tout" :
/// - on garde le standard damage flow ;
/// - on supporte `modifyStats` déterministe pour un petit sous-ensemble utile ;
/// - on refuse explicitement le reste.
///
/// BE1 durcit ce bridge sur un autre axe :
/// - certaines dimensions canoniques étaient encore perdues silencieusement ;
/// - on transporte maintenant le petit supplément de contrat battle qui évite
///   cette perte (`type`, `target`, `pp`) ;
/// - et on refuse explicitement les dimensions non neutres qui resteraient
///   encore mensongères sans nouvelle couche moteur (`priority`, cibles hors
///   1v1 simple honnête).
///
/// BE3 recadre ensuite ce point :
/// - `priority` n'est plus refusée, parce que `map_battle` sait enfin
///   ordonner honnêtement deux actions `Fight` ;
/// - `speed` stage devient également supportée pour ce même besoin ;
/// - puis BE4 ouvre enfin l'accuracy battle minimale et les PP réels ;
/// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
/// - puis BE7 ouvre un petit sous-ensemble `applyStatus` pour les statuts
///   majeurs `par`, `brn`, `psn`, `tox` ;
/// - puis BE8 ouvre seulement quelques volatiles utiles strictement bornés :
///   `protect`, `breakProtect`, `requireRecharge`, `chargeThenStrike` ;
/// - puis BE9 ouvre seulement un petit sous-ensemble field réellement
///   consommé : `raindance`, `sandstorm`, `trickroom` ;
/// - le reste reste explicitement hors scope et donc refusé.
class RuntimeBattleMoveBridge {
  const RuntimeBattleMoveBridge();

  /// Projette un move canonique vers le contrat `BattleMoveData`.
  ///
  /// Le refus est explicite et descriptif :
  /// - pas de fallback silencieux ;
  /// - pas de `power: 0` mensonger pour un move que le moteur n'exécute pas ;
  /// - pas de mutation opportuniste de `engineSupportLevel`.
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    _ensureEngineSupportLevelAllowsBridge(
      move: move,
      combatantLabel: combatantLabel,
    );
    final target = _translateSupportedTarget(
      move: move,
      combatantLabel: combatantLabel,
    );
    final type = _translateType(
      move: move,
      combatantLabel: combatantLabel,
    );
    final accuracy = _translateAccuracy(move.accuracy);

    final selfChanges = <BattleStatStageChange>[];
    final targetChanges = <BattleStatStageChange>[];
    BattleStatStageEffect? selfStatStageRider;
    BattleStatStageEffect? targetStatStageRider;
    BattleMoveMajorStatusEffect? majorStatusEffect;
    BattleVolatileStatusId? selfVolatileStatus;
    BattleWeatherId? weatherEffect;
    BattlePseudoWeatherId? pseudoWeatherEffect;
    var setsStealthRock = false;
    var setsSpikes = false;
    var breaksProtect = false;
    var requiresRecharge = false;
    final copiesTargetOnHit = _isTransformMoveCandidate(move);
    BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:fixed_damage',
        ),
        multiHit: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:multi_hit',
        ),
        applyStatus: (effect) {
          if (majorStatusEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_apply_status_effects_not_supported',
            );
          }

          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_apply_status_target:${target.name}',
            );
          }

          if (effect.chance case final chance?) {
            if (chance < 1 || chance > 100) {
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit: 'invalid_apply_status_chance:$chance',
              );
            }
          }

          majorStatusEffect = BattleMoveMajorStatusEffect(
            status: _translateSupportedMajorStatus(
              move: move,
              combatantLabel: combatantLabel,
              statusId: effect.statusId,
            ),
            chancePercent: effect.chance,
          );
        },
        applyVolatileStatus: (effect) {
          // BE8 n'ouvre surtout pas tout `applyVolatileStatus`.
          // Le bridge accepte uniquement le plus petit seam devenu exécutable :
          // - `protect` auto-appliqué au lanceur ;
          // - déterministe ;
          // - aucune autre taxonomie de volatile.
          //
          // Les dégâts + rider de confusion probabiliste type `water_pulse`
          // restent bridgeables comme dégâts purs tant que le contrat battle
          // ne transporte pas encore les volatiles appliqués à la cible.
          if (_isDroppableTargetConfusionRider(
            move: move,
            target: target,
            effect: effect,
          )) {
            return;
          }

          if (selfVolatileStatus != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'multiple_apply_volatile_status_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_apply_volatile_status_not_supported',
            );
          }

          selfVolatileStatus = _translateSupportedSelfVolatileStatus(
            move: move,
            combatantLabel: combatantLabel,
            volatileStatusId: effect.volatileStatusId,
          );
        },
        modifyStats: (effect) {
          if (effect.stageChanges.isEmpty) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'empty_modify_stats_not_supported',
            );
          }

          final translated = effect.stageChanges
              .map(
                (change) => _translateStageChange(
                  change: change,
                  move: move,
                  combatantLabel: combatantLabel,
                ),
              )
              .toList(growable: false);

          if (effect.chance case final chance?) {
            if (chance < 1 || chance > 100) {
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit: 'invalid_modify_stats_chance:$chance',
              );
            }

            final rider = BattleStatStageEffect(
              chancePercent: chance,
              changes: List<BattleStatStageChange>.unmodifiable(translated),
            );
            switch (effect.targetScope) {
              case PokemonMoveEffectTargetScope.self:
                if (selfStatStageRider != null) {
                  _rejectMove(
                    move: move,
                    combatantLabel: combatantLabel,
                    bridgeLimit:
                        'multiple_probabilistic_self_stat_riders_not_supported',
                  );
                }
                selfStatStageRider = rider;
              case PokemonMoveEffectTargetScope.target:
                if (targetStatStageRider != null) {
                  _rejectMove(
                    move: move,
                    combatantLabel: combatantLabel,
                    bridgeLimit:
                        'multiple_probabilistic_target_stat_riders_not_supported',
                  );
                }
                targetStatStageRider = rider;
              case PokemonMoveEffectTargetScope.field:
              case PokemonMoveEffectTargetScope.allySide:
              case PokemonMoveEffectTargetScope.foeSide:
              case PokemonMoveEffectTargetScope.slot:
                _rejectMove(
                  move: move,
                  combatantLabel: combatantLabel,
                  bridgeLimit:
                      'unsupported_modify_stats_scope:${effect.targetScope.name}',
                );
            }
            return;
          }

          switch (effect.targetScope) {
            case PokemonMoveEffectTargetScope.self:
              selfChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.target:
              targetChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.field:
            case PokemonMoveEffectTargetScope.allySide:
            case PokemonMoveEffectTargetScope.foeSide:
            case PokemonMoveEffectTargetScope.slot:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_modify_stats_scope:${effect.targetScope.name}',
              );
          }
        },
        heal: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:heal',
        ),
        drain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:drain',
        ),
        recoil: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:recoil',
        ),
        setWeather: (effect) {
          if (weatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_move_shape',
            );
          }
          weatherEffect = _translateSupportedWeather(
            move: move,
            combatantLabel: combatantLabel,
            weatherId: effect.weatherId,
          );
        },
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (effect) {
          if (pseudoWeatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_pseudo_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_pseudo_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_pseudo_weather_move_shape',
            );
          }
          pseudoWeatherEffect = _translateSupportedPseudoWeather(
            move: move,
            combatantLabel: combatantLabel,
            pseudoWeatherId: effect.pseudoWeatherId,
          );
        },
        selfSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:self_switch',
        ),
        forceSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:force_switch',
        ),
        breakProtect: (effect) {
          if (breaksProtect) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_break_protect_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_break_protect_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_break_protect_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_break_protect_not_supported',
            );
          }
          breaksProtect = true;
        },
        requireRecharge: (effect) {
          if (requiresRecharge) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_require_recharge_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_require_recharge_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_require_recharge_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_require_recharge_move_shape',
            );
          }
          requiresRecharge = true;
        },
        chargeThenStrike: (effect) {
          if (chargeThenStrikeEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_charge_then_strike_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_charge_then_strike_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_charge_then_strike_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_charge_then_strike_move_shape',
            );
          }
          chargeThenStrikeEffect = BattleChargeThenStrikeEffect(
            chargeStateId: _normalizeOptionalId(effect.chargeStateId),
          );
        },
        setSideCondition: (effect) {
          if (setsStealthRock || setsSpikes) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_side_condition_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.foeSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponentSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_side_condition_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_side_condition_move_shape',
            );
          }
          final normalizedConditionId = effect.conditionId.trim().toLowerCase();
          switch (normalizedConditionId) {
            case 'stealthrock':
              setsStealthRock = true;
            case 'spikes':
              setsSpikes = true;
            default:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_side_condition:$normalizedConditionId',
              );
          }
        },
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // BE8 revendique un sous-ensemble exact, pas une "approximation large".
    // On refuse donc explicitement les combinaisons d'effets qui ne font pas
    // partie du petit contrat local ouvert par ce lot, même si chaque brique
    // isolée serait supportée séparément.
    if (requiresRecharge && chargeThenStrikeEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_charge_then_recharge',
      );
    }
    if ((weatherEffect != null || pseudoWeatherEffect != null) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_field_effect_move',
      );
    }
    if (weatherEffect != null && pseudoWeatherEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'multiple_field_effect_kinds_not_supported',
      );
    }
    if ((setsStealthRock || setsSpikes) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            weatherEffect != null ||
            pseudoWeatherEffect != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_side_condition_move',
      );
    }
    if (copiesTargetOnHit && target != BattleMoveTarget.opponent) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_transform_target:${target.name}',
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit un effet `applyStatus` BE7 réellement supporté ;
    // - soit une pose de champ réellement consommée en BE9 ;
    // - soit une combinaison de ces chemins-là quand elle est explicitement
    //   autorisée plus haut.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty &&
        majorStatusEffect == null &&
        selfVolatileStatus == null &&
        weatherEffect == null &&
        pseudoWeatherEffect == null &&
        !setsStealthRock &&
        !setsSpikes &&
        !copiesTargetOnHit) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'no_supported_execution_path',
      );
    }

    // Le moteur battle actuel sait seulement :
    // - infliger des dégâts à l'adversaire actif ;
    // - ou appliquer des boosts/baisses déterministes sur `self` / target.
    //
    // Un move auto-ciblé qui ferait malgré tout des dégâts standards serait
    // donc encore projeté mensongèrement : `map_battle` le résoudrait contre
    // l'adversaire faute de vrai contrat "self damage".
    //
    // On préfère refuser explicitement ce cas tant qu'un lot ultérieur n'ouvre
    // pas une sémantique battle claire pour ce type d'exécution.
    if (move.usesStandardDamageFlow && target == BattleMoveTarget.self) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_standard_damage_target:self',
      );
    }

    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.usesStandardDamageFlow ? move.basePower : 0,
      type: type,
      category: _translateCategory(move.category),
      target: target,
      accuracy: accuracy,
      pp: move.pp,
      priority: move.priority,
      critRatio: move.critRatio,
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      setsStealthRock: setsStealthRock,
      setsSpikes: setsSpikes,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      copiesTargetOnHit: copiesTargetOnHit,
      selfStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(selfChanges),
      targetStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(targetChanges),
      selfStatStageRider: selfStatStageRider,
      targetStatStageRider: targetStatStageRider,
    );
  }

  RuntimeBattleMoveBridgeDiagnostics inspectMove({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final battleEngineMethod = _resolveBattleEngineMethod(move);
    final psdkRegistryStatus = _psdkRegistryStatusFor(battleEngineMethod);
    try {
      toBattleMoveData(move: move, combatantLabel: combatantLabel);
      return RuntimeBattleMoveBridgeDiagnostics(
        moveId: move.id,
        bridgeable: true,
        reason: 'bridgeable',
        engineSupportLevel: move.engineSupportLevel,
        unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
        battleEngineMethod: battleEngineMethod,
        psdkRegistryStatus: psdkRegistryStatus,
      );
    } on RuntimeBattleSetupException catch (error) {
      final bridgeLimit = _extractDebugDetailValue(
        error.debugDetails,
        'bridgeLimit=',
      );
      return RuntimeBattleMoveBridgeDiagnostics(
        moveId: move.id,
        bridgeable: false,
        reason: bridgeLimit ?? 'runtime_bridge_rejected',
        engineSupportLevel: move.engineSupportLevel,
        unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
        battleEngineMethod: battleEngineMethod,
        psdkRegistryStatus: psdkRegistryStatus,
        debugDetails: error.debugDetails,
      );
    }
  }

  void _ensureEngineSupportLevelAllowsBridge({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
            PokemonMoveEngineSupportLevel.structuredSupported ||
        _isCatalogOnlyProtectMoveCandidate(move) ||
        _isTransformMoveCandidate(move) ||
        _allowsBridgeableStructuredPartialMove(move)) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'engine_support_level_not_bridgeable',
    );
  }

  BattleMoveAccuracy _translateAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => BattleMoveAccuracy.percent(value: accuracy.value),
      alwaysHits: (_) => const BattleMoveAccuracy.alwaysHits(),
    );
  }

  String _translateType({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'invalid_type:empty',
      );
    }

    // Même règle qu'au chargement des espèces :
    // - la liste des types réellement supportés ne doit vivre qu'à un seul
    //   endroit ;
    // - le bridge réutilise donc `BattleTypeChart.supportedTypes` au lieu de
    //   maintenir une seconde liste locale ;
    // - cela permet de rejeter le move au bon seam runtime -> battle, avec
    //   une erreur actionnable, plutôt que de laisser `map_battle` exploser
    //   plus tard par `StateError`.
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_type:$normalizedType',
      );
    }

    return normalizedType;
  }

  BattleMoveCategory _translateCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => BattleMoveCategory.physical,
      PokemonMoveCategory.special => BattleMoveCategory.special,
      PokemonMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _translateSupportedTarget({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // BE1 ne promet toujours pas un système de targeting complet.
    // En revanche, on peut déjà arrêter de perdre silencieusement l'intention
    // canonique quand elle reste honnête en 1v1 simple actif :
    // - `self` -> self ;
    // - `normal`, `any`, `adjacentFoe`, `allAdjacentFoes`, `randomNormal`
    //   -> opponent.
    //
    // Les autres formes (`all`, `allySide`, `foeSide`, etc.) exigent une
    // sémantique de terrain/sides/slots ou de multibattle absente aujourd'hui.
    if (_isPureFieldMoveCandidate(move)) {
      return switch (move.target) {
        // Recadrage BE9 après review :
        // - le sous-ensemble honnête réellement seedé dans ce repo pose la
        //   météo / Trick Room avec `target: all` ;
        // - accepter aussi `self` élargissait inutilement le contrat et
        //   laissait passer un faux field move malformé ;
        // - on garde donc un bridge strict au lieu d'une tolérance qui ne
        //   sert aucun cas réel confirmé par l'audit.
        PokemonMoveTarget.all => BattleMoveTarget.field,
        _ => _rejectMove(
            move: move,
            combatantLabel: combatantLabel,
            bridgeLimit: 'unsupported_field_target:${move.target.name}',
          ),
      };
    }

    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.any ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      PokemonMoveTarget.foeSide
          when _isPureFoeSideConditionMoveCandidate(move) =>
        BattleMoveTarget.opponentSide,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_target:${move.target.name}',
        ),
    };
  }

  BattleStatStageChange _translateStageChange({
    required PokemonMoveStatStageChange change,
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final stat = switch (change.stat) {
      PokemonMoveStatId.attack => BattleStatId.attack,
      PokemonMoveStatId.defense => BattleStatId.defense,
      PokemonMoveStatId.specialAttack => BattleStatId.specialAttack,
      PokemonMoveStatId.specialDefense => BattleStatId.specialDefense,
      // BE3 ouvre ici la plus petite extension honnête possible :
      // - `speed` stage devient enfin utile car le moteur ordonne désormais
      //   les deux actions `Fight` par vitesse effective ;
      // - on ne profite pas de cette ouverture pour accepter accuracy/evasion,
      //   qui resteraient mensongères sans hit pipeline réel.
      PokemonMoveStatId.speed => BattleStatId.speed,
      PokemonMoveStatId.accuracy => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
      PokemonMoveStatId.evasion => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
    };

    return BattleStatStageChange(
      stat: stat,
      stages: change.stages,
    );
  }

  BattleMajorStatusId _translateSupportedMajorStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String statusId,
  }) {
    final normalizedStatusId = statusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'par' => BattleMajorStatusId.par,
      'brn' => BattleMajorStatusId.brn,
      'psn' => BattleMajorStatusId.psn,
      'tox' => BattleMajorStatusId.tox,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_major_status:$normalizedStatusId',
        ),
    };
  }

  BattleVolatileStatusId _translateSupportedSelfVolatileStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String volatileStatusId,
  }) {
    final normalizedStatusId = volatileStatusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'protect' => BattleVolatileStatusId.protect,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_volatile_status:$normalizedStatusId',
        ),
    };
  }

  BattleWeatherId _translateSupportedWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String weatherId,
  }) {
    final normalizedWeatherId = weatherId.trim().toLowerCase();
    return switch (normalizedWeatherId) {
      'raindance' => BattleWeatherId.rain,
      'sandstorm' => BattleWeatherId.sandstorm,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_weather:$normalizedWeatherId',
        ),
    };
  }

  BattlePseudoWeatherId _translateSupportedPseudoWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String pseudoWeatherId,
  }) {
    final normalizedPseudoWeatherId = pseudoWeatherId.trim().toLowerCase();
    return switch (normalizedPseudoWeatherId) {
      'trickroom' => BattlePseudoWeatherId.trickRoom,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_pseudo_weather:$normalizedPseudoWeatherId',
        ),
    };
  }

  bool _isPureFieldMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow) {
      return false;
    }
    if (move.effects.isEmpty) {
      return false;
    }
    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => true,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => true,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _allowsBridgeableStructuredPartialMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }

    // Ce seam reste volontairement très fermé :
    // - R2 puis ce mini-lot n'ouvrent pas un bridge "un peu permissif" pour
    //   tous les moves partiels ;
    // - on autorise seulement deux sous-cas explicitement prouvés par le repo :
    //   1. les vieux field moves type `Trick Room` déjà réellement exécutables ;
    //   2. les catalogues locaux plus anciens qui ont déclassé à tort un move
    //      simple uniquement à cause de la métadonnée Showdown `zMove`.
    // - tout autre `structuredPartial` continue à être refusé par défaut.
    return _allowsStructuredPartialFieldMove(move) ||
        _allowsStructuredPartialMetadataOnlyMove(move);
  }

  bool _isTransformMoveCandidate(PokemonMove move) {
    final normalizedMoveId = move.id.trim().toLowerCase();
    final normalizedShowdownMoveId =
        move.sourceRefs.showdownMoveId?.trim().toLowerCase();
    final isTransformId = normalizedMoveId == 'transform' ||
        normalizedShowdownMoveId == 'transform';

    return isTransformId &&
        move.category == PokemonMoveCategory.status &&
        move.basePower <= 0 &&
        move.effects.isEmpty;
  }

  bool _isCatalogOnlyProtectMoveCandidate(PokemonMove move) {
    if (move.engineSupportLevel != PokemonMoveEngineSupportLevel.catalogOnly) {
      return false;
    }

    final normalizedMoveId = move.id.trim().toLowerCase();
    final normalizedShowdownMoveId =
        move.sourceRefs.showdownMoveId?.trim().toLowerCase();
    final isProtectId =
        normalizedMoveId == 'protect' || normalizedShowdownMoveId == 'protect';
    if (!isProtectId ||
        move.category != PokemonMoveCategory.status ||
        move.target != PokemonMoveTarget.self ||
        move.basePower != 0 ||
        move.effects.length != 1) {
      return false;
    }

    return move.effects.single.map(
      fixedDamage: (_) => false,
      multiHit: (_) => false,
      applyStatus: (_) => false,
      applyVolatileStatus: (effect) =>
          effect.targetScope == PokemonMoveEffectTargetScope.self &&
          effect.chance == null &&
          effect.volatileStatusId.trim().toLowerCase() == 'protect',
      modifyStats: (_) => false,
      heal: (_) => false,
      drain: (_) => false,
      recoil: (_) => false,
      setWeather: (_) => false,
      setTerrain: (_) => false,
      setPseudoWeather: (_) => false,
      selfSwitch: (_) => false,
      forceSwitch: (_) => false,
      breakProtect: (_) => false,
      requireRecharge: (_) => false,
      chargeThenStrike: (_) => false,
      setSideCondition: (_) => false,
      setSlotCondition: (_) => false,
    );
  }

  bool _isDroppableTargetConfusionRider({
    required PokemonMove move,
    required BattleMoveTarget target,
    required PokemonMoveEffectApplyVolatileStatus effect,
  }) {
    final chance = effect.chance;
    return move.usesStandardDamageFlow &&
        target == BattleMoveTarget.opponent &&
        effect.targetScope == PokemonMoveEffectTargetScope.target &&
        chance != null &&
        chance >= 1 &&
        chance <= 100 &&
        effect.volatileStatusId.trim().toLowerCase() == 'confusion';
  }

  bool _allowsStructuredPartialFieldMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }
    if (!_isPureFieldMoveCandidate(move)) {
      return false;
    }

    // Recadrage BE9 :
    // - on n'ouvre pas globalement tous les moves `structuredPartial` ;
    // - on autorise uniquement les vieux catalogues qui marquaient encore
    //   `Trick Room` comme partiel faute de couche de champ/durée ;
    // - tout autre motif de partial support reste refusé par défaut.
    const allowedReasons = <String>{
      'unsupported_mechanic:turn_order_inversion',
      'unsupported_mechanic:condition',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
    };
    return move.unsupportedReasons.every(allowedReasons.contains);
  }

  bool _allowsStructuredPartialMetadataOnlyMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }

    // Mini-lot starter coverage :
    // - certains catalogues locaux déjà convertis portent encore
    //   `unsupported_mechanic:zMove` sur des moves de base pourtant déjà
    //   totalement compatibles avec le bridge (`tail_whip`, `withdraw`, etc.) ;
    // - cette raison n'exprime pas une limite du move de base dans le slice
    //   singles local, mais seulement l'absence volontaire de support Z-Move ;
    // - autoriser ce cas précis répare donc une sous-déclaration de support
    //   sans élargir la famille de mécaniques réellement exécutées.
    const allowedReasons = <String>{
      'unsupported_mechanic:zMove',
      'unsupported_mechanic:probabilistic_modify_stats',
    };
    if (move.unsupportedReasons.isEmpty ||
        !move.unsupportedReasons.every(allowedReasons.contains)) {
      return false;
    }

    // Garde-fou de périmètre :
    // - on ne rouvre surtout pas "tous les partials zMove-only" ;
    // - certains vieux labels locaux peuvent aussi toucher des status moves
    //   vides ou non-op comme `teleport`, qui ne deviendraient pas honnêtes
    //   juste parce que la cause du partial est une métadonnée Showdown ;
    // - ce mini-lot starter coverage n'autorise donc que le sous-ensemble
    //   déjà réellement exécutable aujourd'hui : un `modifyStats`
    //   déterministe sur `self` ou `target`.
    return _isPureDeterministicStatMoveCandidate(move) ||
        _isSupportedProbabilisticStatRiderCandidate(move);
  }

  bool _isPureDeterministicStatMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow || move.effects.isEmpty) {
      return false;
    }

    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (effect) =>
            effect.chance == null &&
            effect.stageChanges.isNotEmpty &&
            (effect.targetScope == PokemonMoveEffectTargetScope.self ||
                effect.targetScope == PokemonMoveEffectTargetScope.target),
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _isSupportedProbabilisticStatRiderCandidate(PokemonMove move) {
    if (move.effects.isEmpty) {
      return false;
    }

    var hasSupportedProbabilisticModifyStats = false;
    final allEffectsSupported = move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (effect) {
          final chance = effect.chance;
          final supported = chance != null &&
              chance >= 1 &&
              chance <= 100 &&
              effect.stageChanges.isNotEmpty &&
              (effect.targetScope == PokemonMoveEffectTargetScope.self ||
                  effect.targetScope == PokemonMoveEffectTargetScope.target) &&
              _areBattleBridgeableStageChanges(effect.stageChanges);
          if (supported) {
            hasSupportedProbabilisticModifyStats = true;
          }
          return supported;
        },
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );

    return allEffectsSupported && hasSupportedProbabilisticModifyStats;
  }

  bool _areBattleBridgeableStageChanges(
    List<PokemonMoveStatStageChange> changes,
  ) {
    return changes.every(
      (change) => switch (change.stat) {
        PokemonMoveStatId.attack ||
        PokemonMoveStatId.defense ||
        PokemonMoveStatId.specialAttack ||
        PokemonMoveStatId.specialDefense ||
        PokemonMoveStatId.speed =>
          true,
        PokemonMoveStatId.accuracy || PokemonMoveStatId.evasion => false,
      },
    );
  }

  bool _isPureFoeSideConditionMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow || move.effects.isEmpty) {
      return false;
    }

    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (effect) =>
            effect.targetScope == PokemonMoveEffectTargetScope.foeSide &&
            effect.chance == null,
        setSlotCondition: (_) => false,
      ),
    );
  }

  String? _normalizeOptionalId(String? value) {
    if (value == null) {
      return null;
    }
    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  Never _rejectUnsupportedStat({
    required PokemonMove move,
    required String combatantLabel,
    required PokemonMoveStatId stat,
  }) {
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_stat_stage:${stat.name}',
    );
  }

  Never _rejectMove({
    required PokemonMove move,
    required String combatantLabel,
    required String bridgeLimit,
  }) {
    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons, bridgeLimit=$bridgeLimit',
    );
  }
}

String? _extractUnsupportedReasonValue(List<String> reasons, String prefix) {
  for (final reason in reasons) {
    if (reason.startsWith(prefix)) {
      final value = reason.substring(prefix.length).trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
  }
  return null;
}

String? _resolveBattleEngineMethod(PokemonMove move) {
  final explicitMethod = _extractUnsupportedReasonValue(
    move.unsupportedReasons,
    'psdk_method:',
  );
  if (explicitMethod != null) {
    return explicitMethod;
  }

  final normalizedMoveId = move.id.trim().toLowerCase();
  final normalizedShowdownMoveId =
      move.sourceRefs.showdownMoveId?.trim().toLowerCase();
  final sourceIds = <String>{
    normalizedMoveId,
    if (normalizedShowdownMoveId != null && normalizedShowdownMoveId.isNotEmpty)
      normalizedShowdownMoveId,
  };

  for (final sourceId in sourceIds) {
    final method = _knownPsdkMethodByMoveId[sourceId];
    if (method != null) {
      return method;
    }
  }

  if (move.usesStandardDamageFlow) {
    return 's_basic';
  }

  return null;
}

String? _psdkRegistryStatusFor(String? battleEngineMethod) {
  if (battleEngineMethod == null) {
    return null;
  }
  for (final entry in psdkMoveRegistryManifest) {
    if (entry.battleEngineMethod == battleEngineMethod) {
      return entry.status.name;
    }
  }
  return null;
}

const _knownPsdkMethodByMoveId = <String, String>{
  'baton_pass': 's_baton_pass',
  'protect': 's_protect',
  'transform': 's_transform',
};

String? _extractDebugDetailValue(String? debugDetails, String prefix) {
  final details = debugDetails;
  if (details == null || details.isEmpty) {
    return null;
  }
  final start = details.indexOf(prefix);
  if (start < 0) {
    return null;
  }
  final valueStart = start + prefix.length;
  final comma = details.indexOf(',', valueStart);
  final value = (comma < 0
          ? details.substring(valueStart)
          : details.substring(valueStart, comma))
      .trim();
  return value.isEmpty ? null : value;
}
