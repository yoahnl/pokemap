import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';
import 'ability_effect.dart';

enum AbilityMoveTypeChangeMode {
  normalToType,
  anyToNormal,
  soundToWater,
}

final class MoveTypeChangeAbilityEffect extends BattleAbilityEffect {
  const MoveTypeChangeAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
    required this.mode,
    this.convertedType,
    this.powerMultiplier = 1,
  }) : super(abilityId: abilityId, scope: scope);

  final AbilityMoveTypeChangeMode mode;
  final String? convertedType;
  final double powerMultiplier;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return MoveTypeChangeAbilityEffect(
      abilityId: abilityId,
      scope: scope,
      mode: mode,
      convertedType: convertedType,
      powerMultiplier: powerMultiplier,
    );
  }

  @override
  String? moveTypeOverride(BattleAbilityMoveTypeContext context) {
    if (_isWeatherBall(context.move.battleEngineMethod)) {
      return null;
    }
    return switch (mode) {
      AbilityMoveTypeChangeMode.normalToType =>
        context.currentType == 'normal' ? convertedType : null,
      AbilityMoveTypeChangeMode.anyToNormal => 'normal',
      AbilityMoveTypeChangeMode.soundToWater =>
        context.move.flags.sound ? 'water' : null,
    };
  }

  @override
  double damageBasePowerMultiplier(BattleAbilityDamageContext context) {
    if (powerMultiplier == 1 ||
        _isWeatherBall(context.move.battleEngineMethod)) {
      return 1;
    }
    return switch (mode) {
      AbilityMoveTypeChangeMode.normalToType
          when context.move.type.toLowerCase() == 'normal' &&
              context.moveType == convertedType =>
        powerMultiplier,
      _ => 1,
    };
  }
}

final class ProteanTypeChangeAbilityEffect extends BattleAbilityEffect {
  const ProteanTypeChangeAbilityEffect({
    required String abilityId,
    required BattleEffectScope scope,
  }) : super(abilityId: abilityId, scope: scope);

  static const Set<String> _noActivationMethods = <String>{
    's_struggle',
    's_metronome',
    's_me_first',
    's_assist',
    's_mirror_move',
    's_nature_power',
    's_sleep_talk',
  };

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ProteanTypeChangeAbilityEffect(
      abilityId: abilityId,
      scope: scope,
    );
  }

  @override
  BattleEffectPreAccuracyResult? onPreAccuracy(
    BattleEffectPreAccuracyContext context,
  ) {
    if (!isOwnedBy(context.user) ||
        context.owner != context.user ||
        _noActivationMethods.contains(_normalizedId(
          context.move.battleEngineMethod,
        )) ||
        context.move.category == PsdkBattleMoveCategory.status) {
      return null;
    }
    final nextType = _normalizedId(context.move.type);
    if (nextType.isEmpty || nextType == 'none') {
      return null;
    }
    final user = context.state.battlerAt(context.user);
    if (_isSingleType(user) && user.hasType(nextType)) {
      return null;
    }
    return BattleEffectPreAccuracyResult(
      state: context.state.updateBattler(
        context.user,
        (battler) => battler.copyWith(
          types: PsdkBattleTypes(primary: nextType),
          type3: null,
          temporaryTypes: const <String>[],
        ),
      ),
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleEffectEvent.added(
          turn: context.turn,
          target: context.user,
          effectId: '$abilityId:$nextType',
          reason: 'ability:$abilityId',
        ),
      ],
    );
  }
}

bool _isWeatherBall(String battleEngineMethod) {
  return battleEngineMethod == 's_weather_ball';
}

bool _isSingleType(PsdkBattleCombatant battler) {
  return battler.types.secondary == null &&
      battler.type3 == null &&
      battler.temporaryTypes.isEmpty;
}

String _normalizedId(String id) {
  return id.trim().toLowerCase().replaceAll('-', '_');
}
