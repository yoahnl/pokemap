import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_grounding_resolver.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _TerrainPowerKind {
  expandingForce,
  grassyGlide,
  risingVoltage,
  terrainBoosting,
  terrainPulse,
}

/// Ports PSDK move classes whose damage formula reads the active terrain.
///
/// This behavior deliberately handles the local singles slice of PSDK terrain
/// damage moves. Multi-target expansion and full grounded edge cases stay
/// partial until the broader PSDK targeting/effect hooks are ported.
final class TerrainPowerMoveBehavior implements BattleMoveBehavior {
  const TerrainPowerMoveBehavior.expandingForce()
      : battleEngineMethod = 's_expanding_force',
        _kind = _TerrainPowerKind.expandingForce;

  const TerrainPowerMoveBehavior.grassyGlide()
      : battleEngineMethod = 's_grassy_glide',
        _kind = _TerrainPowerKind.grassyGlide;

  const TerrainPowerMoveBehavior.risingVoltage()
      : battleEngineMethod = 's_rising_voltage',
        _kind = _TerrainPowerKind.risingVoltage;

  const TerrainPowerMoveBehavior.terrainBoosting()
      : battleEngineMethod = 's_terrain_boosting',
        _kind = _TerrainPowerKind.terrainBoosting;

  const TerrainPowerMoveBehavior.terrainPulse()
      : battleEngineMethod = 's_terrain_pulse',
        _kind = _TerrainPowerKind.terrainPulse;

  @override
  final String battleEngineMethod;
  final _TerrainPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final effectiveMove = _effectiveMove(
      context.move,
      prepared.state.field,
    );
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      dbSymbol: context.move.dbSymbol,
      userGrounded: const BattleGroundingResolver().isGrounded(user),
      targetGrounded: const BattleGroundingResolver().isGrounded(target),
      field: prepared.state.field,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: effectiveMove,
        rng: prepared.rng,
        field: prepared.state.field,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
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

  int _resolvePower({
    required int movePower,
    required String dbSymbol,
    required bool userGrounded,
    required bool targetGrounded,
    required PsdkBattleFieldState field,
  }) {
    return switch (_kind) {
      _TerrainPowerKind.expandingForce =>
        field.isTerrainActive(PsdkBattleTerrainId.psychicTerrain) &&
                userGrounded
            ? (movePower * 1.5).floor()
            : movePower,
      _TerrainPowerKind.grassyGlide => movePower,
      _TerrainPowerKind.risingVoltage =>
        field.isTerrainActive(PsdkBattleTerrainId.electricTerrain) &&
                targetGrounded
            ? movePower * 2
            : movePower,
      _TerrainPowerKind.terrainBoosting =>
        _terrainBoostingPower(movePower, dbSymbol, field),
      _TerrainPowerKind.terrainPulse =>
        field.hasTerrain && userGrounded ? 100 : movePower,
    };
  }

  BattleMoveDefinition _effectiveMove(
    BattleMoveDefinition move,
    PsdkBattleFieldState field,
  ) {
    if (_kind != _TerrainPowerKind.terrainPulse || !field.hasTerrain) {
      return move;
    }
    return _copyMove(
      move,
      type: switch (field.terrain!.id) {
        PsdkBattleTerrainId.electricTerrain => 'electric',
        PsdkBattleTerrainId.grassyTerrain => 'grass',
        PsdkBattleTerrainId.mistyTerrain => 'fairy',
        PsdkBattleTerrainId.psychicTerrain => 'psychic',
      },
      power: 100,
    );
  }

  int _terrainBoostingPower(
    int movePower,
    String dbSymbol,
    PsdkBattleFieldState field,
  ) {
    final requiredTerrain = switch (dbSymbol) {
      'psyblade' => PsdkBattleTerrainId.electricTerrain,
      _ => null,
    };
    if (requiredTerrain == null || !field.isTerrainActive(requiredTerrain)) {
      return movePower;
    }
    return (movePower * 1.5).floor();
  }
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
