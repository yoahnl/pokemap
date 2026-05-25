import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_scope.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _WeatherPowerKind {
  weatherBall,
  thunder,
  hurricane,
  geniesStorm,
  solarBeam,
}

final class WeatherPowerMoveBehavior implements BattleMoveBehavior {
  const WeatherPowerMoveBehavior.weatherBall()
      : battleEngineMethod = 's_weather_ball',
        _kind = _WeatherPowerKind.weatherBall;

  const WeatherPowerMoveBehavior.thunder()
      : battleEngineMethod = 's_thunder',
        _kind = _WeatherPowerKind.thunder;

  const WeatherPowerMoveBehavior.hurricane()
      : battleEngineMethod = 's_hurricane',
        _kind = _WeatherPowerKind.hurricane;

  const WeatherPowerMoveBehavior.geniesStorm()
      : battleEngineMethod = 's_genies_storm',
        _kind = _WeatherPowerKind.geniesStorm;

  const WeatherPowerMoveBehavior.solarBeam()
      : battleEngineMethod = 's_solar_beam',
        _kind = _WeatherPowerKind.solarBeam;

  @override
  final String battleEngineMethod;
  final _WeatherPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    if (_kind == _WeatherPowerKind.solarBeam) {
      return _resolveSolarBeam(context);
    }

    final effectiveMove = switch (_kind) {
      _WeatherPowerKind.weatherBall =>
        _weatherBallMove(context.state, context.move),
      _WeatherPowerKind.thunder ||
      _WeatherPowerKind.hurricane =>
        _weatherAccuracyMove(context.state, context.move),
      _WeatherPowerKind.geniesStorm =>
        _geniesStormAccuracyMove(context.state, context.move),
      _WeatherPowerKind.solarBeam => context.move,
    };
    return _resolveDamage(context, effectiveMove);
  }

  BattleMoveBehaviorResolution _resolveSolarBeam(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (!_isSunny(context.state) &&
        !user.effects.contains(PsdkBattleEffectIds.twoTurnCharge)) {
      final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
      if (!prepared.shouldExecuteBehavior) {
        return prepared.toResolution();
      }
      return BattleMoveBehaviorResolution(
        state: prepared.state.updateBattler(
          context.user,
          (battler) => battler.copyWith(
            effects: battler.effects.addEffect(
              GenericBattleEffect(
                id: PsdkBattleEffectIds.twoTurnCharge,
                scope: BattlerBattleEffectScope(context.user),
              ),
            ),
          ),
        ),
        rng: prepared.rng,
        events: prepared.events,
      );
    }

    final releasedState =
        user.effects.contains(PsdkBattleEffectIds.twoTurnCharge)
            ? context.state.updateBattler(
                context.user,
                (battler) => battler.copyWith(
                  effects:
                      battler.effects.remove(PsdkBattleEffectIds.twoTurnCharge),
                ),
              )
            : context.state;
    return _resolveDamage(
      BattleMoveBehaviorContext(
        state: releasedState,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: context.move,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
      _solarBeamMove(releasedState, context.move),
    );
  }

  BattleMoveBehaviorResolution _resolveDamage(
    BattleMoveBehaviorContext context,
    BattleMoveDefinition effectiveMove,
  ) {
    final prepared = prepareBattleMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: effectiveMove,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: effectiveMove,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyMoveTargetDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      move: effectiveMove,
      moveCategory: effectiveMove.category,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: effectiveMove,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
      ],
    );
  }
}

BattleMoveDefinition _weatherAccuracyMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  return switch (_effectiveWeather(state)) {
    PsdkBattleWeatherId.rain ||
    PsdkBattleWeatherId.hardrain =>
      _copyMove(move, accuracy: 0),
    PsdkBattleWeatherId.sunny ||
    PsdkBattleWeatherId.hardsun =>
      _copyMove(move, accuracy: 50),
    _ => move,
  };
}

BattleMoveDefinition _geniesStormAccuracyMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  return switch (_effectiveWeather(state)) {
    PsdkBattleWeatherId.rain ||
    PsdkBattleWeatherId.hardrain =>
      _copyMove(move, accuracy: 0),
    _ => move,
  };
}

BattleMoveDefinition _weatherBallMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  final weather = _effectiveWeather(state);
  return _copyMove(
    move,
    type: _weatherBallType(weather, move.type),
    power: weather == null ? move.power : 100,
  );
}

BattleMoveDefinition _solarBeamMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  return _copyMove(
    move,
    power: _weakensSolarBeam(_effectiveWeather(state))
        ? (move.power / 2).floor()
        : move.power,
  );
}

PsdkBattleWeatherId? _effectiveWeather(PsdkBattleState state) {
  return state.weatherEffectsSuppressed ? null : state.field.weather?.id;
}

bool _isSunny(PsdkBattleState state) {
  return switch (_effectiveWeather(state)) {
    PsdkBattleWeatherId.sunny || PsdkBattleWeatherId.hardsun => true,
    _ => false,
  };
}

bool _weakensSolarBeam(PsdkBattleWeatherId? weather) {
  return switch (weather) {
    PsdkBattleWeatherId.rain ||
    PsdkBattleWeatherId.hardrain ||
    PsdkBattleWeatherId.sandstorm ||
    PsdkBattleWeatherId.hail ||
    PsdkBattleWeatherId.snow =>
      true,
    _ => false,
  };
}

String _weatherBallType(PsdkBattleWeatherId? weather, String fallback) {
  return switch (weather) {
    PsdkBattleWeatherId.rain || PsdkBattleWeatherId.hardrain => 'water',
    PsdkBattleWeatherId.sunny || PsdkBattleWeatherId.hardsun => 'fire',
    PsdkBattleWeatherId.hail || PsdkBattleWeatherId.snow => 'ice',
    PsdkBattleWeatherId.sandstorm => 'rock',
    _ => fallback,
  };
}

BattleMoveDefinition _copyMove(
  BattleMoveDefinition move, {
  String? type,
  int? power,
  int? accuracy,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: type ?? move.type,
    category: move.category,
    power: power ?? move.power,
    accuracy: accuracy ?? move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
