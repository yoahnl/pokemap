import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _TerrainPowerKind {
  terrainBoosting,
}

/// Ports PSDK move classes whose damage formula reads the active terrain.
///
/// This behavior deliberately handles only terrain power multipliers. Moves
/// that change type (`Terrain Pulse`), action order (`Grassy Glide`) or target
/// extra battlers (`Expanding Force`) need different engine seams and remain
/// missing in the manifest.
final class TerrainPowerMoveBehavior implements BattleMoveBehavior {
  const TerrainPowerMoveBehavior.terrainBoosting()
      : battleEngineMethod = 's_terrain_boosting',
        _kind = _TerrainPowerKind.terrainBoosting;

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
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      dbSymbol: context.move.dbSymbol,
      field: prepared.state.field,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
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
      move: context.move,
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
    required PsdkBattleFieldState field,
  }) {
    return switch (_kind) {
      _TerrainPowerKind.terrainBoosting =>
        _terrainBoostingPower(movePower, dbSymbol, field),
    };
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
