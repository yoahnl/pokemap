import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_transform_service.dart';
import '../../handler/battle_ability_change_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_terrain_change_handler.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import '../item/item_effect.dart';
import 'ability_effect.dart';

final class SwitchWeatherAbilityEffect extends BattleAbilityEffect {
  const SwitchWeatherAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.weather,
    required this.weatherMoveDbSymbol,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleWeatherId weather;
  final String weatherMoveDbSymbol;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwitchWeatherAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      weather: weather,
      weatherMoveDbSymbol: weatherMoveDbSymbol,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      weather: weather,
      remainingTurns: _weatherDuration(context),
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  int _weatherDuration(BattleEffectSwitchEventContext context) {
    final battler = context.state.battlerAt(context.replacement);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.weatherDuration(weatherMoveDbSymbol);
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}

final class SwitchTerrainAbilityEffect extends BattleAbilityEffect {
  const SwitchTerrainAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.terrain,
    required this.terrainMoveDbSymbol,
  }) : super(abilityId: abilityId, scope: scope);

  final PsdkBattleTerrainId terrain;
  final String terrainMoveDbSymbol;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwitchTerrainAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      terrain: terrain,
      terrainMoveDbSymbol: terrainMoveDbSymbol,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final result = const BattleTerrainChangeHandler().changeTerrain(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      terrain: terrain,
      remainingTurns: _terrainDuration(context),
    );
    if (!result.applied) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  int _terrainDuration(BattleEffectSwitchEventContext context) {
    final battler = context.state.battlerAt(context.replacement);
    for (final itemEffect in battler.activeItemEffects) {
      final duration = itemEffect.terrainDuration(terrainMoveDbSymbol);
      if (duration != null) {
        return duration;
      }
    }
    return 5;
  }
}

final class SwitchStatBoostAbilityEffect extends BattleAbilityEffect {
  const SwitchStatBoostAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.stat,
    required this.stages,
  }) : super(abilityId: abilityId, scope: scope);

  final String stat;
  final int stages;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SwitchStatBoostAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      stat: stat,
      stages: stages,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final result = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      target: context.replacement,
      stat: stat,
      stages: stages,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }
}

final class DownloadEffect extends BattleAbilityEffect {
  const DownloadEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'download', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return DownloadEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final target = _firstAliveFoe(context);
    if (target == null) {
      return null;
    }
    final targetBattler = context.state.battlerAt(target);
    final stat =
        targetBattler.stats.defense < targetBattler.stats.specialDefense
            ? 'attack'
            : 'specialAttack';

    final result = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.replacement,
      ),
      target: context.replacement,
      stat: stat,
      stages: 1,
    );
    if (!result.applied && result.events.isEmpty) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: result.state,
      rng: result.rng,
      events: result.events,
    );
  }

  PsdkBattleSlotRef? _firstAliveFoe(BattleEffectSwitchEventContext context) {
    for (final foe in context.state.foesOf(context.replacement)) {
      if (!context.state.battlerAt(foe).isFainted) {
        return foe;
      }
    }
    return null;
  }
}

final class IntimidateEffect extends BattleAbilityEffect {
  const IntimidateEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'intimidate', scope: scope);

  static const Set<String> _immuneAbilities = <String>{
    'own_tempo',
    'oblivious',
    'inner_focus',
    'scrappy',
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return IntimidateEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    var nextState = context.state;
    var nextRng = context.rng;
    final events = <PsdkBattleEvent>[];
    var changed = false;

    for (final target in context.state.foesOf(context.replacement)) {
      if (_immuneToIntimidate(nextState, target)) {
        continue;
      }
      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: context.turn,
          user: context.replacement,
        ),
        target: target,
        stat: 'attack',
        stages: -1,
        sourceAbilityId: 'intimidate',
      );
      nextState = result.state;
      nextRng = result.rng;
      events.addAll(result.events);
      changed = changed || result.applied || result.events.isNotEmpty;
    }

    if (!changed) {
      return null;
    }
    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }
}

final class FriskEffect extends BattleAbilityEffect {
  const FriskEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'frisk', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FriskEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    for (final foe in context.state.foesOf(context.replacement)) {
      final battler = context.state.battlerAt(foe);
      final itemId = battler.heldItemId;
      if (battler.isFainted || itemId == null || battler.itemConsumed) {
        continue;
      }
      return BattleEffectSwitchEventResult(
        state: context.state,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleEffectEvent.added(
            turn: context.turn,
            target: foe,
            effectId: 'frisk:item:$itemId',
            reason: 'ability:frisk',
          ),
        ],
      );
    }

    return null;
  }
}

final class ForewarnEffect extends BattleAbilityEffect {
  const ForewarnEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'forewarn', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ForewarnEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final candidates = <({PsdkBattleSlotRef foe, PsdkBattleMoveData move})>[];
    var strongestPower = 0;
    for (final foe in context.state.foesOf(context.replacement)) {
      final battler = context.state.battlerAt(foe);
      if (battler.isFainted) {
        continue;
      }
      for (final move in battler.moves) {
        if (move.power <= 0 || move.power < strongestPower) {
          continue;
        }
        if (move.power > strongestPower) {
          candidates.clear();
          strongestPower = move.power;
        }
        candidates.add((foe: foe, move: move));
      }
    }
    if (candidates.isEmpty) {
      return null;
    }

    var nextRng = context.rng;
    var chosen = candidates.single;
    if (candidates.length > 1) {
      final roll = context.rng.generic.nextIntInclusive(
        min: 0,
        max: candidates.length - 1,
      );
      nextRng = context.rng.copyWith(generic: roll.next);
      chosen = candidates[roll.value];
    }

    return BattleEffectSwitchEventResult(
      state: context.state,
      rng: nextRng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: chosen.foe,
          effectId: 'forewarn:move:${chosen.move.id}',
          reason: 'ability:forewarn',
        ),
      ],
    );
  }
}

final class TraceEffect extends BattleAbilityEffect {
  const TraceEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'trace', scope: scope);

  static const Set<String> _cantOverwriteAbilities = <String>{
    'as_one',
    'battle_bond',
    'comatose',
    'commander',
    'disguise',
    'gulp_missile',
    'hadron_engine',
    'hunger_switch',
    'ice_face',
    'imposter',
    'multitype',
    'orichalcum_pulse',
    'power_construct',
    'protosynthesis',
    'quark_drive',
    'rks_system',
    'schooling',
    'shields_down',
    'stance_change',
    'wonder_guard',
    'zen_mode',
    'zero_to_hero',
  };

  static const Set<String> _cantCopyAbilities = <String>{
    'as_one',
    'battle_bond',
    'comatose',
    'commander',
    'disguise',
    'flower_gift',
    'forecast',
    'gulp_missile',
    'hadron_engine',
    'hunger_switch',
    'ice_face',
    'illusion',
    'imposter',
    'multitype',
    'neutralizing_gas',
    'orichalcum_pulse',
    'poison_puppeteer',
    'power_construct',
    'power_of_alchemy',
    'prokosynthesis',
    'protosynthesis',
    'quark_drive',
    'receiver',
    'rks_system',
    'schooling',
    'shields_down',
    'stance_change',
    'trace',
    'wonder_guard',
    'zen_mode',
    'zero_to_hero',
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return TraceEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context) || !_canLoseAbility(context)) {
      return null;
    }

    final givers = <PsdkBattleSlotRef>[];
    for (final foe in context.state.foesOf(context.replacement)) {
      final battler = context.state.battlerAt(foe);
      final abilityId = battler.abilityId;
      if (battler.isFainted ||
          abilityId == null ||
          _cantCopyAbilities.contains(abilityId)) {
        continue;
      }
      givers.add(foe);
    }
    if (givers.isEmpty) {
      return null;
    }

    var nextRng = context.rng;
    var giver = givers.single;
    if (givers.length > 1) {
      final roll = context.rng.generic.nextIntInclusive(
        min: 0,
        max: givers.length - 1,
      );
      nextRng = context.rng.copyWith(generic: roll.next);
      giver = givers[roll.value];
    }
    final copiedAbilityId = context.state.battlerAt(giver).abilityId;
    if (copiedAbilityId == null) {
      return null;
    }

    final changed = const BattleAbilityChangeHandler().changeAbility(
      context: BattleHandlerContext(
        state: context.state,
        rng: nextRng,
        turn: context.turn,
        user: giver,
      ),
      target: context.replacement,
      abilityId: copiedAbilityId,
    );
    var nextState = changed.state;
    nextRng = changed.rng;
    final events = <PsdkBattleEvent>[
      PsdkBattleEffectEvent.added(
        turn: context.turn,
        target: context.replacement,
        effectId: 'trace:ability:$copiedAbilityId',
        reason: 'ability:trace',
      ),
    ];

    final copiedSwitch =
        nextState.battlerAt(context.replacement).effects.dispatchSwitchEvent(
              BattleEffectSwitchEventContext(
                state: nextState,
                rng: nextRng,
                turn: context.turn,
                owner: context.replacement,
                who: context.replacement,
                replacement: context.replacement,
              ),
            );
    nextState = copiedSwitch.state;
    nextRng = copiedSwitch.rng;
    events.addAll(copiedSwitch.events);

    return BattleEffectSwitchEventResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  bool _canLoseAbility(BattleEffectSwitchEventContext context) {
    final abilityId = context.state.battlerAt(context.replacement).abilityId;
    return abilityId == null || !_cantOverwriteAbilities.contains(abilityId);
  }
}

final class ImposterEffect extends BattleAbilityEffect {
  const ImposterEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'imposter', scope: scope);

  static const PsdkBattleTransformService _transformService =
      PsdkBattleTransformService();

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ImposterEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (!_isEnteringOwner(context)) {
      return null;
    }

    final user = context.state.battlerAt(context.replacement);
    if (!_transformService.canTransform(user)) {
      return null;
    }

    for (final targetSlot in context.state.foesOf(context.replacement)) {
      final target = context.state.battlerAt(targetSlot);
      if (!_transformService.canCopy(target)) {
        continue;
      }
      return BattleEffectSwitchEventResult(
        state: context.state.replaceBattler(
          context.replacement,
          _transformService.transform(
            user: user,
            target: target,
            userSlot: context.replacement,
          ),
        ),
        rng: context.rng,
      );
    }

    return null;
  }
}

bool _isEnteringOwner(BattleEffectSwitchEventContext context) {
  return context.owner == context.replacement;
}

bool _immuneToIntimidate(
  PsdkBattleState state,
  PsdkBattleSlotRef target,
) {
  final battler = state.battlerAt(target);
  if (battler.effects.contains('ability_suppressed')) {
    return false;
  }
  final abilityId = battler.abilityId?.trim().toLowerCase();
  return abilityId != null &&
      IntimidateEffect._immuneAbilities.contains(abilityId);
}
