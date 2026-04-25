import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _HealMoveKind {
  half,
  weather,
  floralHealing,
  roost,
  shoreUp,
  quarter,
  jungleHealing,
}

/// Ports the base PSDK `HealMove` behavior: heal each actual target by half of
/// its max HP after the shared move procedure succeeds.
///
/// Local ratio variants are kept here because their PSDK Ruby classes only
/// change the heal fraction. They still remain partial in the registry until
/// Heal Block, Substitute, Mega Launcher and persistent move effects exist as
/// first-class hooks.
final class HealMoveBehavior implements BattleMoveBehavior {
  const HealMoveBehavior()
      : battleEngineMethod = 's_heal',
        _kind = _HealMoveKind.half;

  const HealMoveBehavior.weather()
      : battleEngineMethod = 's_heal_weather',
        _kind = _HealMoveKind.weather;

  const HealMoveBehavior.floralHealing()
      : battleEngineMethod = 's_floral_healing',
        _kind = _HealMoveKind.floralHealing;

  const HealMoveBehavior.roost()
      : battleEngineMethod = 's_roost',
        _kind = _HealMoveKind.roost;

  const HealMoveBehavior.shoreUp()
      : battleEngineMethod = 's_shore_up',
        _kind = _HealMoveKind.shoreUp;

  const HealMoveBehavior.lifeDew()
      : battleEngineMethod = 's_life_dew',
        _kind = _HealMoveKind.quarter;

  const HealMoveBehavior.jungleHealing()
      : battleEngineMethod = 's_jungle_healing',
        _kind = _HealMoveKind.jungleHealing;

  @override
  final String battleEngineMethod;
  final _HealMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final target in prepared.psdkTargets) {
      final battler = state.battlerAt(target);
      final amount = _healAmount(prepared.state, battler.maxHp);
      final heal = applyDirectHeal(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: amount,
      );
      state = heal.state;
      rng = heal.rng;
      if (heal.event != null) {
        events.add(heal.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  int _healAmount(
    PsdkBattleState state,
    int maxHp,
  ) {
    return switch (_kind) {
      _HealMoveKind.half || _HealMoveKind.roost => maxHp ~/ 2,
      _HealMoveKind.weather => _weatherHealAmount(state, maxHp),
      _HealMoveKind.floralHealing => state.field.isTerrainActive(
          PsdkBattleTerrainId.grassyTerrain,
        )
            ? _ratio(maxHp, 2, 3)
            : maxHp ~/ 2,
      _HealMoveKind.shoreUp =>
        state.isWeatherEffectActive(PsdkBattleWeatherId.sandstorm)
            ? _ratio(maxHp, 2, 3)
            : maxHp ~/ 2,
      _HealMoveKind.quarter || _HealMoveKind.jungleHealing => maxHp ~/ 4,
    };
  }

  int _weatherHealAmount(
    PsdkBattleState state,
    int maxHp,
  ) {
    final weather =
        state.weatherEffectsSuppressed ? null : state.field.weather?.id;
    return switch (weather) {
      PsdkBattleWeatherId.sunny ||
      PsdkBattleWeatherId.hardsun =>
        _ratio(maxHp, 2, 3),
      null || PsdkBattleWeatherId.strongWinds => maxHp ~/ 2,
      _ => maxHp ~/ 4,
    };
  }
}

int _ratio(int value, int numerator, int denominator) {
  return (value * numerator) ~/ denominator;
}
