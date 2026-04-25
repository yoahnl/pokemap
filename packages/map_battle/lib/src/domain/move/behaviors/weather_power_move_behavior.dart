import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

final class WeatherPowerMoveBehavior implements BattleMoveBehavior {
  const WeatherPowerMoveBehavior.weatherBall()
      : battleEngineMethod = 's_weather_ball';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final effectiveMove = _weatherBallMove(context.state, context.move);
    final prepared = prepareBattleMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: effectiveMove,
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
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
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
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }
}

BattleMoveDefinition _weatherBallMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  final weather = state.field.weather?.id;
  return _copyMove(
    move,
    type: state.weatherEffectsSuppressed
        ? move.type
        : _weatherBallType(weather, move.type),
    power: weather == null ? move.power : 100,
  );
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
  required String type,
  required int power,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: type,
    category: move.category,
    power: power,
    accuracy: move.accuracy,
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
