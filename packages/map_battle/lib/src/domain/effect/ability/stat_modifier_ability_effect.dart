import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_item_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

typedef AbilityStatCondition = bool Function(BattleAbilityStatContext context);

final class StatModifierAbilityEffect extends BattleAbilityEffect {
  const StatModifierAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.statMultipliers,
    AbilityStatCondition? condition,
  })  : _condition = condition,
        super(abilityId: abilityId, scope: scope);

  final Map<String, double> statMultipliers;
  final AbilityStatCondition? _condition;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return StatModifierAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      statMultipliers: statMultipliers,
      condition: _condition,
    );
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    if (context.battler.abilityId != abilityId ||
        !(_condition?.call(context) ?? true)) {
      return 1;
    }
    return statMultipliers[context.stat] ?? 1;
  }
}

final class PlusMinusAbilityEffect extends BattleAbilityEffect {
  const PlusMinusAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  static const Set<String> _partnerAbilities = <String>{'plus', 'minus'};

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return PlusMinusAbilityEffect(abilityId: abilityId, scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final state = context.state;
    if (context.stat != 'specialAttack' ||
        ownerSlot == null ||
        context.battlerSlot != ownerSlot ||
        state == null ||
        context.battler.abilityId != abilityId) {
      return 1;
    }
    for (final allySlot in state.alliesOf(ownerSlot)) {
      final ally = state.battlerAt(allySlot);
      if (ally.effects.contains('ability_suppressed')) {
        continue;
      }
      final allyAbilityId = ally.abilityId;
      if (allyAbilityId != null && _partnerAbilities.contains(allyAbilityId)) {
        return 1.5;
      }
    }
    return 1;
  }
}

final class FlowerGiftStatAbilityEffect extends BattleAbilityEffect {
  const FlowerGiftStatAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'flower_gift', scope: scope);

  @override
  bool get affectsGlobalStats => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return FlowerGiftStatAbilityEffect(scope: scope);
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement) {
      return null;
    }
    return _calibrateCherrimForm(
      state: context.state,
      rng: context.rng,
      owner: context.owner,
    )?.toSwitchResult();
  }

  @override
  BattleEffectFieldChangeResult? onPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    return _calibrateCherrimForm(
      state: context.state,
      rng: context.rng,
      owner: context.owner,
    )?.toFieldResult();
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final battlerSlot = context.battlerSlot;
    if (ownerSlot == null ||
        battlerSlot == null ||
        ownerSlot.bank != battlerSlot.bank ||
        !hasSunnyWeather(context)) {
      return 1;
    }
    return switch (context.stat) {
      'attack' || 'specialDefense' => 1.5,
      _ => 1,
    };
  }

  _FlowerGiftFormResult? _calibrateCherrimForm({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef owner,
  }) {
    final battler = state.battlerAt(owner);
    if (_normalizedId(battler.speciesId) != 'cherrim') {
      return null;
    }
    final nextForm = hasSunnyWeather(
      BattleAbilityStatContext(
        field: state.field,
        battler: battler,
        stat: 'attack',
        state: state,
        battlerSlot: owner,
        weatherEffectsSuppressed: state.weatherEffectsSuppressed,
      ),
    )
        ? 1
        : 0;
    if (battler.form == nextForm) {
      return null;
    }
    return _FlowerGiftFormResult(
      state: state.updateBattler(
        owner,
        (current) => current.copyWith(form: nextForm),
      ),
      rng: rng,
    );
  }
}

final class _FlowerGiftFormResult {
  const _FlowerGiftFormResult({
    required this.state,
    required this.rng,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;

  BattleEffectSwitchEventResult toSwitchResult() {
    return BattleEffectSwitchEventResult(state: state, rng: rng);
  }

  BattleEffectFieldChangeResult toFieldResult() {
    return BattleEffectFieldChangeResult(state: state, rng: rng);
  }
}

enum ParadoxStatBoostTrigger {
  sunnyWeather,
  electricTerrain,
}

final class ParadoxStatBoostAbilityEffect extends BattleAbilityEffect {
  const ParadoxStatBoostAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.trigger,
  }) : super(abilityId: abilityId, scope: scope);

  final ParadoxStatBoostTrigger trigger;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ParadoxStatBoostAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      trigger: trigger,
    );
  }

  @override
  BattleEffectSwitchEventResult? onSwitchEvent(
    BattleEffectSwitchEventContext context,
  ) {
    if (context.owner != context.replacement) {
      return null;
    }
    final fieldActive = switch (trigger) {
      ParadoxStatBoostTrigger.sunnyWeather =>
        _paradoxSunny(context.state.field.weather?.id),
      ParadoxStatBoostTrigger.electricTerrain =>
        context.state.field.terrain?.id == PsdkBattleTerrainId.electricTerrain,
    };
    return _resolveActivation(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      fieldActive: fieldActive,
      clearExistingFieldBoost: false,
      clearReason: null,
    )?.toSwitchResult();
  }

  @override
  BattleEffectFieldChangeResult? onPostWeatherChange(
    BattleEffectWeatherChangeContext context,
  ) {
    if (trigger != ParadoxStatBoostTrigger.sunnyWeather) {
      return null;
    }
    return _resolveActivation(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      fieldActive: _paradoxSunny(context.weather),
      clearExistingFieldBoost: _paradoxSunny(context.lastWeather),
      clearReason: 'weather_cleared',
    )?.toFieldResult();
  }

  @override
  BattleEffectFieldChangeResult? onPostTerrainChange(
    BattleEffectTerrainChangeContext context,
  ) {
    if (trigger != ParadoxStatBoostTrigger.electricTerrain) {
      return null;
    }
    return _resolveActivation(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      owner: context.owner,
      fieldActive: context.terrain == PsdkBattleTerrainId.electricTerrain,
      clearExistingFieldBoost:
          context.lastTerrain == PsdkBattleTerrainId.electricTerrain,
      clearReason: 'terrain_cleared',
    )?.toFieldResult();
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    if (ownerSlot == null ||
        context.battlerSlot != ownerSlot ||
        context.battler.abilityId != abilityId) {
      return 1;
    }
    final boostedStat = _currentParadoxBoostStat(context.battler, abilityId);
    if (boostedStat != context.stat) {
      return 1;
    }
    return boostedStat == 'speed' ? 1.5 : 1.3;
  }

  _ParadoxActivationResult? _resolveActivation({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
    required bool fieldActive,
    required bool clearExistingFieldBoost,
    required String? clearReason,
  }) {
    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[];

    if (fieldActive) {
      return _activateBoost(
        state: nextState,
        rng: nextRng,
        turn: turn,
        owner: owner,
        source: 'field',
        initialEvents: events,
      );
    }

    if (clearExistingFieldBoost) {
      final cleared = _clearBoost(
        state: nextState,
        owner: owner,
        turn: turn,
        reason: clearReason ?? 'field_cleared',
      );
      nextState = cleared.state;
      events.addAll(cleared.events);
    }

    final booster = _activateBoost(
      state: nextState,
      rng: nextRng,
      turn: turn,
      owner: owner,
      source: 'booster_energy',
      initialEvents: events,
      consumeBoosterEnergy: true,
    );
    if (booster != null) {
      return booster;
    }
    if (events.isEmpty) {
      return null;
    }
    return _ParadoxActivationResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  _ParadoxActivationResult? _activateBoost({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef owner,
    required String source,
    required List<PsdkBattleEvent> initialEvents,
    bool consumeBoosterEnergy = false,
  }) {
    final battler = state.battlerAt(owner);
    final boostStat = _highestParadoxStat(battler);
    final currentBoost = _currentParadoxBoostStat(battler, abilityId);
    if (currentBoost == boostStat) {
      return null;
    }
    if (consumeBoosterEnergy && battler.heldItemId != 'booster_energy') {
      return null;
    }

    var nextState = state;
    var nextRng = rng;
    final events = <PsdkBattleEvent>[...initialEvents];
    if (consumeBoosterEnergy) {
      final itemResult = const BattleItemChangeHandler().consumeHeldItem(
        context: BattleHandlerContext(
          state: nextState,
          rng: nextRng,
          turn: turn,
          user: owner,
        ),
        target: owner,
      );
      nextState = itemResult.state;
      nextRng = itemResult.rng;
      events.addAll(itemResult.events);
    }

    final markerId = _paradoxBoostMarker(abilityId, boostStat);
    nextState = nextState.updateBattler(
      owner,
      (current) => current.copyWith(
        effects: _withoutParadoxBoost(current.effects, abilityId).add(markerId),
      ),
    );
    events.add(
      PsdkBattleEffectEvent.added(
        turn: turn,
        target: owner,
        effectId: markerId,
        reason: 'ability:$abilityId:$source',
      ),
    );
    return _ParadoxActivationResult(
      state: nextState,
      rng: nextRng,
      events: events,
    );
  }

  _ParadoxClearResult _clearBoost({
    required PsdkBattleState state,
    required PsdkBattleSlotRef owner,
    required int turn,
    required String reason,
  }) {
    final battler = state.battlerAt(owner);
    final currentBoost = _currentParadoxBoostStat(battler, abilityId);
    if (currentBoost == null) {
      return _ParadoxClearResult(state: state);
    }
    final markerId = _paradoxBoostMarker(abilityId, currentBoost);
    return _ParadoxClearResult(
      state: state.updateBattler(
        owner,
        (current) => current.copyWith(
          effects: current.effects.remove(markerId),
        ),
      ),
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.removed(
          turn: turn,
          target: owner,
          effectId: markerId,
          reason: reason,
        ),
      ],
    );
  }
}

final class RuinStatAbilityEffect extends BattleAbilityEffect {
  const RuinStatAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.stat,
  }) : super(abilityId: abilityId, scope: scope);

  final String stat;

  @override
  bool get affectsGlobalStats => true;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return RuinStatAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      stat: stat,
    );
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    final ownerSlot = owner;
    final battlerSlot = context.battlerSlot;
    if (ownerSlot == null ||
        battlerSlot == null ||
        battlerSlot == ownerSlot ||
        context.stat != _effectiveRuinStat(context) ||
        context.battler.abilityId == abilityId) {
      return 1;
    }
    return 0.75;
  }

  String _effectiveRuinStat(BattleAbilityStatContext context) {
    if (!_wonderRoomActive(context)) {
      return stat;
    }
    return switch (abilityId) {
      'beads_of_ruin' => 'defense',
      'sword_of_ruin' => 'specialDefense',
      _ => stat,
    };
  }

  bool _wonderRoomActive(BattleAbilityStatContext context) {
    final state = context.state;
    if (state == null) {
      return false;
    }
    for (final slot in state.aliveSlots()) {
      if (state.battlerAt(slot).effects.contains('wonder_room')) {
        return true;
      }
    }
    return false;
  }
}

final class SlowStartAbilityEffect extends BattleAbilityEffect {
  const SlowStartAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'slow_start', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return SlowStartAbilityEffect(scope: scope);
  }

  @override
  double statMultiplier(BattleAbilityStatContext context) {
    if (context.battler.abilityId != abilityId ||
        context.battler.battleTurnCount >= 5) {
      return 1;
    }
    return switch (context.stat) {
      'attack' || 'speed' => 0.5,
      _ => 1,
    };
  }
}

final class GaleWingsAbilityEffect extends BattleAbilityEffect {
  const GaleWingsAbilityEffect({
    required BattleEffectScope scope,
  }) : super(abilityId: 'gale_wings', scope: scope);

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return GaleWingsAbilityEffect(scope: scope);
  }

  @override
  int movePriorityModifier(BattleAbilityMovePriorityContext context) {
    if (context.battler.abilityId != abilityId ||
        context.move.type != 'flying' ||
        context.battler.currentHp != context.battler.maxHp) {
      return 0;
    }
    return 1;
  }
}

bool hasMajorStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus != null;
}

final class _ParadoxActivationResult {
  const _ParadoxActivationResult({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;

  BattleEffectSwitchEventResult toSwitchResult() {
    return BattleEffectSwitchEventResult(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleEffectFieldChangeResult toFieldResult() {
    return BattleEffectFieldChangeResult(
      state: state,
      rng: rng,
      events: events,
    );
  }
}

final class _ParadoxClearResult {
  const _ParadoxClearResult({
    required this.state,
    this.events = const <PsdkBattleEvent>[],
  });

  final PsdkBattleState state;
  final List<PsdkBattleEvent> events;
}

const _paradoxStatOrder = <String>[
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
];

bool _paradoxSunny(PsdkBattleWeatherId? weather) {
  return weather == PsdkBattleWeatherId.sunny ||
      weather == PsdkBattleWeatherId.hardsun;
}

String _highestParadoxStat(PsdkBattleCombatant battler) {
  var highestStat = _paradoxStatOrder.first;
  var highestValue = battler.effectiveStat(highestStat);
  for (final stat in _paradoxStatOrder.skip(1)) {
    final value = battler.effectiveStat(stat);
    // Pokemon SDK uses Hash#key(max), so ties keep the earliest stat in the
    // atk/def/spa/spd/spe declaration order instead of replacing it.
    if (value > highestValue) {
      highestStat = stat;
      highestValue = value;
    }
  }
  return highestStat;
}

String? _currentParadoxBoostStat(
  PsdkBattleCombatant battler,
  String abilityId,
) {
  for (final stat in _paradoxStatOrder) {
    if (battler.effects.contains(_paradoxBoostMarker(abilityId, stat))) {
      return stat;
    }
  }
  return null;
}

PsdkBattleEffectStack _withoutParadoxBoost(
  PsdkBattleEffectStack effects,
  String abilityId,
) {
  var next = effects;
  for (final stat in _paradoxStatOrder) {
    next = next.remove(_paradoxBoostMarker(abilityId, stat));
  }
  return next;
}

String _paradoxBoostMarker(String abilityId, String stat) {
  return '$abilityId:boost:$stat';
}

bool hasBurnStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus == PsdkBattleMajorStatus.burn;
}

bool hasPoisonStatus(BattleAbilityStatContext context) {
  return context.battler.majorStatus == PsdkBattleMajorStatus.poison ||
      context.battler.majorStatus == PsdkBattleMajorStatus.toxic;
}

bool hasGrassyTerrain(BattleAbilityStatContext context) {
  return context.field.isTerrainActive(PsdkBattleTerrainId.grassyTerrain);
}

bool hasElectricTerrain(BattleAbilityStatContext context) {
  return context.field.isTerrainActive(PsdkBattleTerrainId.electricTerrain);
}

bool hasSunnyWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      (context.field.isWeatherActive(PsdkBattleWeatherId.sunny) ||
          context.field.isWeatherActive(PsdkBattleWeatherId.hardsun));
}

bool hasRainWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      (context.field.isWeatherActive(PsdkBattleWeatherId.rain) ||
          context.field.isWeatherActive(PsdkBattleWeatherId.hardrain));
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

bool hasSandstormWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      context.field.isWeatherActive(PsdkBattleWeatherId.sandstorm);
}

bool hasSnowingWeather(BattleAbilityStatContext context) {
  return !context.weatherEffectsSuppressed &&
      (context.field.isWeatherActive(PsdkBattleWeatherId.hail) ||
          context.field.isWeatherActive(PsdkBattleWeatherId.snow));
}
