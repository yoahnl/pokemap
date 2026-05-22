import '../../psdk/domain/psdk_battle_combatant.dart';
import '../../psdk/domain/psdk_battle_field.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';
import '../battler/battle_grounding_resolver.dart';
import '../effect/ability/ability_effect.dart';
import '../effect/battle_effect_scope.dart';
import '../effect/item/item_effect.dart';
import '../rng/battle_rng_streams.dart';
import 'battle_move_critical_resolver.dart';
import 'battle_move_data.dart';
import 'battle_move_type_processor.dart';

final class BattleMoveDamageCalculator {
  const BattleMoveDamageCalculator({
    BattleMoveTypeProcessor typeProcessor = const BattleMoveTypeProcessor(),
    BattleMoveCriticalResolver criticalResolver =
        const BattleMoveCriticalResolver(),
    BattleGroundingResolver groundingResolver = const BattleGroundingResolver(),
  })  : _typeProcessor = typeProcessor,
        _criticalResolver = criticalResolver,
        _groundingResolver = groundingResolver;

  final BattleMoveTypeProcessor _typeProcessor;
  final BattleMoveCriticalResolver _criticalResolver;
  final BattleGroundingResolver _groundingResolver;

  BattleMoveDamageResult calculate(BattleMoveDamageContext context) {
    final move = context.move;
    final moveType = _effectiveMoveType(context);
    final resolvedPower = _effectivePower(context);
    if (move.category == PsdkBattleMoveCategory.status || resolvedPower <= 0) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: 1,
        typeEffectivenessMultiplier: 1,
      );
    }
    if (_hardWeatherBlocksMove(context, moveType)) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: 1,
        typeEffectivenessMultiplier: 1,
      );
    }

    final stabMultiplier = _typeProcessor.resolveStabMultiplier(
      moveType: moveType,
      userTypes: context.user.types,
      extraUserTypes: _extraTypes(context.user),
    );
    final effectiveness = _typeProcessor.resolveEffectiveness(
      moveType: moveType,
      targetTypes: context.target.types,
      extraTargetTypes: _extraTypes(context.target),
      forceGrounded: moveType == 'ground' &&
          _groundingResolver.isGrounded(
            context.target,
            state: context.state,
            slot: context.targetSlot,
          ),
      foresight: context.target.effects.contains('foresight'),
      miracleEye: context.target.effects.contains('miracle_eye'),
      neutralizeFlyingWeaknesses: _strongWindsNeutralizesFlyingWeaknesses(
        context,
      ),
    );
    if (effectiveness.isImmune) {
      return BattleMoveDamageResult.zero(
        rng: context.rng,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: effectiveness.multiplier,
      );
    }

    final critical = _criticalResolver.resolve(
      move: move,
      rng: context.rng,
      criticalRate: _effectiveCriticalRate(context),
    );
    final damageRoll = critical.rng.moveDamage.nextDamagePercent();
    final rng = critical.rng.copyWith(moveDamage: damageRoll.next);

    // PSDK move subclasses often override only one formula input, for example
    // Brine's base power or Body Press' offensive stat source. These overrides
    // are deliberately scoped to one calculation so catalog definitions remain
    // immutable import data instead of becoming per-hit scratch objects.
    final offensiveStat = _positiveStat(
      _abilityAdjustedOffensiveStat(
        context.overrides?.offensiveStatFor(critical.isCritical) ??
            _offensiveStat(context),
        context,
        moveType,
      ),
    );
    final defensiveStat = _positiveStat(
      context.overrides?.defensiveStatFor(critical.isCritical) ??
          _defensiveStat(context),
    );
    final levelFactor = ((2 * context.user.level) ~/ 5) + 2;
    var formulaDamage = levelFactor;
    formulaDamage = (formulaDamage * resolvedPower).floor();
    formulaDamage = (formulaDamage * offensiveStat).floor() ~/ 50;
    formulaDamage = (formulaDamage ~/ defensiveStat).floor();
    formulaDamage =
        (formulaDamage * _mod1Multiplier(context, moveType)).floor() + 2;
    final criticalDamage = (formulaDamage * critical.multiplier).floor();
    final randomDamage = ((criticalDamage * damageRoll.value) / 100).floor();
    final stabDamage = (randomDamage * stabMultiplier).floor();
    final typeEffectivenessMultiplier = _applyLocalEffectivenessModifiers(
      effectiveness.multiplier,
      context,
      moveType,
    );
    final typedDamage = (stabDamage * typeEffectivenessMultiplier).floor();
    final heldItemDamage = _applyHeldItemFinalDamageModifiers(
      typedDamage,
      context,
      moveType,
      typeEffectivenessMultiplier,
    );
    final abilityDamage = _applyAbilityFinalDamageModifiers(
      heldItemDamage,
      context,
      moveType,
      typeEffectivenessMultiplier,
    );
    final damage = abilityDamage < 1 ? 1 : abilityDamage;

    return BattleMoveDamageResult(
      rng: rng,
      damage: damage,
      isCritical: critical.isCritical,
      criticalMultiplier: critical.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    );
  }
}

bool _hardWeatherBlocksMove(BattleMoveDamageContext context, String moveType) {
  if (_weatherEffectsSuppressed(context)) {
    return false;
  }
  return switch (context.field.weather?.id) {
    PsdkBattleWeatherId.hardrain when moveType == 'fire' => true,
    PsdkBattleWeatherId.hardsun when moveType == 'water' => true,
    _ => false,
  };
}

bool _strongWindsNeutralizesFlyingWeaknesses(
  BattleMoveDamageContext context,
) {
  return !_weatherEffectsSuppressed(context) &&
      context.field.isWeatherActive(PsdkBattleWeatherId.strongWinds);
}

int _effectivePower(BattleMoveDamageContext context) {
  var power = context.overrides?.power ?? context.move.power;
  final moveType = _effectiveMoveType(context);
  power = _abilityAdjustedPower(power, context, moveType);
  power = _itemAdjustedPower(power, context, moveType);
  if (context.user.effects.contains('charge') && moveType == 'electric') {
    power *= 2;
  }
  if (_hasBattleEffect(context, 'mud_sport') && moveType == 'electric') {
    power ~/= 2;
  }
  if (_hasBattleEffect(context, 'water_sport') && moveType == 'fire') {
    power ~/= 2;
  }
  return power;
}

double _mod1Multiplier(BattleMoveDamageContext context, String moveType) {
  var multiplier = 1.0;
  multiplier *= _burnMod1Multiplier(context);
  multiplier *= _weatherMod1Multiplier(context, moveType);
  multiplier *= _terrainMod1Multiplier(context, moveType);
  return multiplier;
}

double _burnMod1Multiplier(BattleMoveDamageContext context) {
  if (context.user.majorStatus != PsdkBattleMajorStatus.burn ||
      context.user.abilityId == 'guts' ||
      context.move.category != PsdkBattleMoveCategory.physical ||
      context.move.battleEngineMethod == 's_facade') {
    return 1.0;
  }
  return 0.5;
}

double _weatherMod1Multiplier(
  BattleMoveDamageContext context,
  String moveType,
) {
  if (_weatherEffectsSuppressed(context)) {
    return 1.0;
  }
  final weather = context.field.weather?.id;
  return switch (weather) {
    PsdkBattleWeatherId.rain when moveType == 'water' => 1.5,
    PsdkBattleWeatherId.rain when moveType == 'fire' => 0.5,
    PsdkBattleWeatherId.sunny
        when moveType == 'fire' || context.move.dbSymbol == 'hydro_steam' =>
      1.5,
    PsdkBattleWeatherId.sunny when moveType == 'water' => 0.5,
    PsdkBattleWeatherId.hardrain when moveType == 'water' => 1.5,
    PsdkBattleWeatherId.hardsun when moveType == 'fire' => 1.5,
    _ => 1.0,
  };
}

bool _weatherEffectsSuppressed(BattleMoveDamageContext context) {
  final state = context.state;
  if (state != null) {
    return state.weatherEffectsSuppressed;
  }
  return context.user.abilityEffects.any(
        (effect) => effect.suppressesWeatherEffects,
      ) ||
      context.target.abilityEffects.any(
        (effect) => effect.suppressesWeatherEffects,
      );
}

int _abilityAdjustedPower(
  int power,
  BattleMoveDamageContext context,
  String moveType,
) {
  if (power <= 0) {
    return power;
  }
  final abilityContext = BattleAbilityDamageContext(
    field: context.field,
    user: context.user,
    target: context.target,
    move: context.move,
    moveType: moveType,
    typeEffectivenessMultiplier: 1,
    userSlot: context.userSlot,
    targetSlot: context.targetSlot,
    activeAbilityIds: _activeAbilityIds(context),
    weatherEffectsSuppressed: _weatherEffectsSuppressed(context),
    isLastActionOfTurn: context.isLastActionOfTurn,
  );
  var multiplier = 1.0;
  if (_sheerForceBoosts(context)) {
    multiplier *= 1.3;
  }
  for (final effect in context.user.abilityEffects) {
    multiplier *= effect.damageBasePowerMultiplier(abilityContext);
  }
  for (final effect in context.target.abilityEffects) {
    multiplier *= effect.incomingDamageBasePowerMultiplier(abilityContext);
  }
  for (final effect in _supportingAbilityEffects(context)) {
    multiplier *= effect.damageBasePowerMultiplier(abilityContext);
  }
  if (multiplier == 1.0) {
    return power;
  }
  final adjusted = (power * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

bool _sheerForceBoosts(BattleMoveDamageContext context) {
  if (context.user.abilityId != 'sheer_force' ||
      context.user.effects.contains('ability_suppressed') ||
      context.move.category == PsdkBattleMoveCategory.status) {
    return false;
  }
  if (context.move.statuses.any((status) => status.majorStatus != null) ||
      context.move.effectChance != null) {
    return true;
  }
  if (context.move.stageMods.isEmpty) {
    return false;
  }
  final onlyPositive = context.move.stageMods.every((mod) => mod.stages > 0);
  final onlyNegative = context.move.stageMods.every((mod) => mod.stages < 0);
  return switch (context.move.target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => onlyPositive,
    _ => onlyNegative,
  };
}

int _itemAdjustedPower(
  int power,
  BattleMoveDamageContext context,
  String moveType,
) {
  if (power <= 0) {
    return power;
  }
  final itemContext = BattleItemDamageModifierContext(
    user: context.user,
    target: context.target,
    move: context.move,
    moveType: moveType,
    typeEffectivenessMultiplier: 1,
    state: context.state,
    userSlot: context.userSlot,
    targetSlot: context.targetSlot,
  );
  var multiplier = 1.0;
  for (final effect in battleActiveItemEffects(
    battler: context.user,
    state: context.state,
    slot: context.userSlot,
  )) {
    multiplier *= effect.damageBasePowerMultiplier(itemContext);
  }
  if (multiplier == 1.0) {
    return power;
  }
  final adjusted = (power * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

double _terrainMod1Multiplier(
  BattleMoveDamageContext context,
  String moveType,
) {
  final terrain = context.field.terrain?.id;
  if (terrain == null) {
    return 1.0;
  }
  final grounding = const BattleGroundingResolver();
  final userGrounded = grounding.isGrounded(
    context.user,
    state: context.state,
    slot: context.userSlot,
  );
  final targetGrounded = grounding.isGrounded(
    context.target,
    state: context.state,
    slot: context.targetSlot,
  );
  return switch (terrain) {
    PsdkBattleTerrainId.electricTerrain when moveType == 'electric' =>
      userGrounded ? 1.5 : 1.0,
    PsdkBattleTerrainId.grassyTerrain when moveType == 'grass' =>
      userGrounded ? 1.5 : 1.0,
    PsdkBattleTerrainId.grassyTerrain
        when userGrounded && _isGrassyReducedMove(context.move.dbSymbol) =>
      0.5,
    PsdkBattleTerrainId.mistyTerrain when moveType == 'dragon' =>
      targetGrounded ? 0.5 : 1.0,
    PsdkBattleTerrainId.psychicTerrain when moveType == 'psychic' =>
      userGrounded ? 1.5 : 1.0,
    _ => 1.0,
  };
}

bool _isGrassyReducedMove(String dbSymbol) {
  return dbSymbol == 'earthquake' ||
      dbSymbol == 'magnitude' ||
      dbSymbol == 'bulldoze';
}

String _effectiveMoveType(BattleMoveDamageContext context) {
  var moveType = context.move.type.toLowerCase();
  if (context.user.effects.contains('electrify')) {
    moveType = 'electric';
  } else if (_hasBattleEffect(context, 'ion_deluge') && moveType == 'normal') {
    moveType = 'electric';
  }
  for (final effect in context.user.abilityEffects) {
    final overridden = effect.moveTypeOverride(
      BattleAbilityMoveTypeContext(
        user: context.user,
        target: context.target,
        move: context.move,
        currentType: moveType,
      ),
    );
    if (overridden != null) {
      moveType = overridden;
    }
  }
  for (final effect in battleActiveItemEffects(
    battler: context.user,
    state: context.state,
    slot: context.userSlot,
  )) {
    final overridden = effect.moveTypeOverride(
      BattleItemMoveTypeContext(
        user: context.user,
        target: context.target,
        move: context.move,
        currentType: moveType,
      ),
    );
    if (overridden != null) {
      moveType = overridden;
    }
  }
  return moveType;
}

bool _hasBattleEffect(BattleMoveDamageContext context, String id) {
  final state = context.state;
  return context.user.effects.contains(id) ||
      context.target.effects.contains(id) ||
      (state != null &&
          state.combatants.values.any(
            (battler) =>
                battler.effects.contains(id) ||
                battler.effects.effects.any(
                  (effect) =>
                      effect.id == id &&
                      effect.scope is FieldBattleEffectScope,
                ),
          ));
}

Iterable<String> _extraTypes(PsdkBattleCombatant battler) {
  return <String>[
    if (battler.type3 != null) battler.type3!,
    ...battler.temporaryTypes,
  ];
}

int _effectiveCriticalRate(BattleMoveDamageContext context) {
  final user = context.user;
  final target = context.target;
  if (target.effects.contains('lucky_chant')) {
    return 0;
  }
  if (user.abilityId == 'merciless' && _hasPoisonStatus(target)) {
    return 4;
  }
  if (user.effects.contains('laser_focus')) {
    return 4;
  }
  if (target.abilityId == 'battle_armor' || target.abilityId == 'shell_armor') {
    return 0;
  }

  var criticalRate = context.move.criticalRate;
  if (user.effects.contains('focus_energy')) {
    criticalRate += 2;
  }
  if (user.effects.contains('dragon_cheer')) {
    criticalRate += user.hasType('dragon') ? 2 : 1;
  }
  if (user.effects.contains('triple_arrows')) {
    criticalRate += 2;
  }
  if (user.abilityId == 'super_luck') {
    criticalRate += 1;
  }
  if (_hasCriticalItem(user)) {
    criticalRate += 1;
  }
  if (user.effects.contains('lansat_berry')) {
    criticalRate += 1;
  }
  return criticalRate;
}

bool _hasPoisonStatus(PsdkBattleCombatant battler) {
  return battler.majorStatus == PsdkBattleMajorStatus.poison ||
      battler.majorStatus == PsdkBattleMajorStatus.toxic;
}

bool _hasCriticalItem(PsdkBattleCombatant battler) {
  return battler.heldItemId == 'razor_claw' ||
      battler.heldItemId == 'scope_lens' ||
      (battler.heldItemId == 'leek' && battler.speciesId == 'farfetch_d') ||
      (battler.heldItemId == 'lucky_punch' && battler.speciesId == 'chansey');
}

double _applyLocalEffectivenessModifiers(
  double multiplier,
  BattleMoveDamageContext context,
  String moveType,
) {
  if (context.move.battleEngineMethod == 's_flying_press') {
    final flyingEffectiveness = const BattleMoveTypeProcessor()
        .resolveEffectiveness(
          moveType: 'flying',
          targetTypes: context.target.types,
          extraTargetTypes: _extraTypes(context.target),
          neutralizeFlyingWeaknesses: _strongWindsNeutralizesFlyingWeaknesses(
            context,
          ),
        )
        .multiplier;
    multiplier *= flyingEffectiveness;
  }
  if (moveType == 'fire' && context.target.effects.contains('tar_shot')) {
    return multiplier * 2;
  }
  if (context.target.effects.contains('glaive_rush')) {
    return multiplier * 2;
  }
  return multiplier;
}

int _applyHeldItemFinalDamageModifiers(
  int damage,
  BattleMoveDamageContext context,
  String moveType,
  double typeEffectivenessMultiplier,
) {
  if (damage <= 0) {
    return damage;
  }
  final itemContext = BattleItemDamageModifierContext(
    user: context.user,
    target: context.target,
    move: context.move,
    moveType: moveType,
    typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    state: context.state,
    userSlot: context.userSlot,
    targetSlot: context.targetSlot,
  );
  var multiplier = 1.0;
  for (final effect in battleActiveItemEffects(
    battler: context.user,
    state: context.state,
    slot: context.userSlot,
  )) {
    multiplier *= effect.damageFinalMultiplier(itemContext);
  }
  for (final effect in battleActiveItemEffects(
    battler: context.target,
    state: context.state,
    slot: context.targetSlot,
  )) {
    multiplier *= effect.damageFinalMultiplier(itemContext);
  }
  if (multiplier == 1.0) {
    return damage;
  }
  final adjusted = (damage * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

int _applyAbilityFinalDamageModifiers(
  int damage,
  BattleMoveDamageContext context,
  String moveType,
  double typeEffectivenessMultiplier,
) {
  if (damage <= 0) {
    return damage;
  }
  final abilityContext = BattleAbilityDamageContext(
    field: context.field,
    user: context.user,
    target: context.target,
    move: context.move,
    moveType: moveType,
    typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    userSlot: context.userSlot,
    targetSlot: context.targetSlot,
    activeAbilityIds: _activeAbilityIds(context),
    weatherEffectsSuppressed: _weatherEffectsSuppressed(context),
    isLastActionOfTurn: context.isLastActionOfTurn,
  );
  var multiplier = 1.0;
  for (final effect in context.user.abilityEffects) {
    multiplier *= effect.finalDamageMultiplier(abilityContext);
  }
  for (final effect in context.target.abilityEffects) {
    multiplier *= effect.finalDamageMultiplier(abilityContext);
  }
  for (final effect in _supportingAbilityEffects(context)) {
    multiplier *= effect.finalDamageMultiplier(abilityContext);
  }
  if (multiplier == 1.0) {
    return damage;
  }
  final adjusted = (damage * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

Set<String> _activeAbilityIds(BattleMoveDamageContext context) {
  return <String>{
    for (final effect in context.user.abilityEffects) effect.abilityId,
    for (final effect in context.target.abilityEffects) effect.abilityId,
    for (final effect in _supportingAbilityEffects(context)) effect.abilityId,
  };
}

int _abilityAdjustedOffensiveStat(
  int stat,
  BattleMoveDamageContext context,
  String moveType,
) {
  if (stat <= 0) {
    return stat;
  }
  final abilityContext = BattleAbilityDamageContext(
    field: context.field,
    user: context.user,
    target: context.target,
    move: context.move,
    moveType: moveType,
    typeEffectivenessMultiplier: 1,
    userSlot: context.userSlot,
    targetSlot: context.targetSlot,
    activeAbilityIds: _activeAbilityIds(context),
    weatherEffectsSuppressed: _weatherEffectsSuppressed(context),
    isLastActionOfTurn: context.isLastActionOfTurn,
  );
  var multiplier = 1.0;
  for (final effect in context.user.abilityEffects) {
    multiplier *= effect.offensiveStatMultiplier(abilityContext);
  }
  for (final effect in _supportingAbilityEffects(context)) {
    multiplier *= effect.offensiveStatMultiplier(abilityContext);
  }
  if (multiplier == 1.0) {
    return stat;
  }
  final adjusted = (stat * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

Iterable<BattleAbilityEffect> _supportingAbilityEffects(
  BattleMoveDamageContext context,
) sync* {
  yield* context.supportingAbilityEffects;

  final state = context.state;
  final userSlot = context.userSlot;
  final targetSlot = context.targetSlot;
  if (state == null || userSlot == null || targetSlot == null) {
    return;
  }
  for (final slot in state.aliveSlots()) {
    if (slot == userSlot || slot == targetSlot) {
      continue;
    }
    yield* state.battlerAt(slot).abilityEffects;
  }
}

final class BattleMoveDamageContext {
  const BattleMoveDamageContext({
    required this.user,
    required this.target,
    required this.move,
    required this.rng,
    this.field = const PsdkBattleFieldState(),
    this.state,
    this.userSlot,
    this.targetSlot,
    this.supportingAbilityEffects = const <BattleAbilityEffect>[],
    this.overrides,
    this.isLastActionOfTurn = false,
  });

  final PsdkBattleCombatant user;
  final PsdkBattleCombatant target;
  final BattleMoveDefinition move;
  final BattleRngStreams rng;
  final PsdkBattleFieldState field;
  final PsdkBattleState? state;
  final PsdkBattleSlotRef? userSlot;
  final PsdkBattleSlotRef? targetSlot;
  final Iterable<BattleAbilityEffect> supportingAbilityEffects;
  final BattleMoveDamageOverrides? overrides;
  final bool isLastActionOfTurn;
}

typedef BattleMoveStatResolver = int Function(bool isCritical);

/// Per-hit formula inputs resolved by PSDK move behaviors.
///
/// This object is intentionally narrow: it changes the values consumed by the
/// damage formula without changing move identity, PP, flags, targeting or any
/// other catalog fields.
final class BattleMoveDamageOverrides {
  const BattleMoveDamageOverrides({
    this.power,
    this.offensiveStat,
    this.defensiveStat,
    this.offensiveStatResolver,
    this.defensiveStatResolver,
  })  : assert(power == null || power >= 0),
        assert(offensiveStat == null || offensiveStat >= 1),
        assert(defensiveStat == null || defensiveStat >= 1),
        assert(offensiveStat == null || offensiveStatResolver == null),
        assert(defensiveStat == null || defensiveStatResolver == null);

  final int? power;
  final int? offensiveStat;
  final int? defensiveStat;
  final BattleMoveStatResolver? offensiveStatResolver;
  final BattleMoveStatResolver? defensiveStatResolver;

  int? offensiveStatFor(bool isCritical) {
    return offensiveStatResolver?.call(isCritical) ?? offensiveStat;
  }

  int? defensiveStatFor(bool isCritical) {
    return defensiveStatResolver?.call(isCritical) ?? defensiveStat;
  }
}

final class BattleMoveDamageResult {
  const BattleMoveDamageResult({
    required this.rng,
    required this.damage,
    required this.isCritical,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
  });

  factory BattleMoveDamageResult.zero({
    required BattleRngStreams rng,
    required double stabMultiplier,
    required double typeEffectivenessMultiplier,
  }) {
    return BattleMoveDamageResult(
      rng: rng,
      damage: 0,
      isCritical: false,
      criticalMultiplier: 1,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
    );
  }

  final BattleRngStreams rng;
  final int damage;
  final bool isCritical;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;

  bool get isImmune => typeEffectivenessMultiplier == 0.0;
}

int _offensiveStat(BattleMoveDamageContext context) {
  return switch (context.move.category) {
    PsdkBattleMoveCategory.physical => _physicalAttack(context),
    PsdkBattleMoveCategory.special => _adjustedStat(
        value: context.user.stats.specialAttack,
        battler: context.user,
        battlerSlot: context.userSlot,
        field: context.field,
        state: context.state,
        stat: 'specialAttack',
      ),
    PsdkBattleMoveCategory.status => context.user.stats.attack,
  };
}

int _physicalAttack(BattleMoveDamageContext context) {
  return _adjustedStat(
    value: context.user.stats.attack,
    battler: context.user,
    battlerSlot: context.userSlot,
    field: context.field,
    state: context.state,
    stat: 'attack',
  );
}

int _defensiveStat(BattleMoveDamageContext context) {
  final wonderRoomActive =
      (context.state?.hasFieldEffect('wonder_room') ?? false) ||
      _hasBattleEffect(context, 'wonder_room');
  final value = switch (context.move.category) {
    PsdkBattleMoveCategory.physical => _adjustedStat(
        value: wonderRoomActive
            ? context.target.stats.specialDefense
            : context.target.stats.defense,
        battler: context.target,
        battlerSlot: context.targetSlot,
        field: context.field,
        state: context.state,
        stat: 'defense',
      ),
    PsdkBattleMoveCategory.special => _adjustedStat(
        value: wonderRoomActive
            ? context.target.stats.defense
            : context.target.stats.specialDefense,
        battler: context.target,
        battlerSlot: context.targetSlot,
        field: context.field,
        state: context.state,
        stat: 'specialDefense',
      ),
    PsdkBattleMoveCategory.status => context.target.stats.defense,
  };
  return value < 1 ? 1 : value;
}

int _adjustedStat({
  required int value,
  required PsdkBattleCombatant battler,
  required PsdkBattleSlotRef? battlerSlot,
  required PsdkBattleFieldState field,
  required PsdkBattleState? state,
  required String stat,
}) {
  var multiplier = 1.0;
  for (final effect in battleActiveItemEffects(
    battler: battler,
    state: state,
    slot: battlerSlot,
  )) {
    multiplier *= effect.statMultiplier(battler, stat);
  }
  final abilityContext = BattleAbilityStatContext(
    field: field,
    battler: battler,
    stat: stat,
    state: state,
    battlerSlot: battlerSlot,
    weatherEffectsSuppressed: state?.weatherEffectsSuppressed ?? false,
  );
  for (final effect in battler.abilityEffects) {
    multiplier *= effect.statMultiplier(abilityContext);
  }
  if (state != null && battlerSlot != null) {
    for (final effect in state.activeAbilityEffects()) {
      if (effect.affectsGlobalStats && !effect.isOwnedBy(battlerSlot)) {
        multiplier *= effect.statMultiplier(abilityContext);
      }
    }
  }
  if (multiplier == 1.0) {
    return value;
  }
  final adjusted = (value * multiplier).floor();
  return adjusted < 1 ? 1 : adjusted;
}

int _positiveStat(int value) {
  return value < 1 ? 1 : value;
}
