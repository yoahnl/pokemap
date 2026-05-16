import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _FieldLocationMoveKind {
  camouflage,
  naturePower,
  pledge,
  secretPower,
  synchronoise,
}

/// Ports local PSDK field/location-sensitive move families.
///
/// The current battle state only exposes active terrain, not map biomes such as
/// cave, desert or water. This slice therefore models PSDK's terrain/default
/// branch and keeps broader location parity explicit in the manifest.
final class FieldLocationMoveBehavior implements BattleMoveBehavior {
  const FieldLocationMoveBehavior.camouflage()
      : battleEngineMethod = 's_camouflage',
        _kind = _FieldLocationMoveKind.camouflage;

  const FieldLocationMoveBehavior.naturePower()
      : battleEngineMethod = 's_nature_power',
        _kind = _FieldLocationMoveKind.naturePower;

  const FieldLocationMoveBehavior.pledge()
      : battleEngineMethod = 's_pledge',
        _kind = _FieldLocationMoveKind.pledge;

  const FieldLocationMoveBehavior.secretPower()
      : battleEngineMethod = 's_secret_power',
        _kind = _FieldLocationMoveKind.secretPower;

  const FieldLocationMoveBehavior.synchronoise()
      : battleEngineMethod = 's_synchronoise',
        _kind = _FieldLocationMoveKind.synchronoise;

  @override
  final String battleEngineMethod;
  final _FieldLocationMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    return switch (_kind) {
      _FieldLocationMoveKind.camouflage => _resolveCamouflage(context),
      _FieldLocationMoveKind.naturePower => _resolveNaturePower(context),
      _FieldLocationMoveKind.pledge => _resolveDamaging(context, context.move),
      _FieldLocationMoveKind.secretPower => _resolveSecretPower(context),
      _FieldLocationMoveKind.synchronoise => _resolveSynchronoise(context),
    };
  }

  BattleMoveBehaviorResolution _resolveCamouflage(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final nextType = _typeByTerrain(prepared.state.field);
    var state = prepared.state;
    for (final target in prepared.psdkTargets) {
      state = state.updateBattler(
        target,
        (battler) => battler.copyWith(
          types: PsdkBattleTypes(primary: nextType),
          type3: null,
          temporaryTypes: const <String>[],
        ),
      );
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: prepared.events,
    );
  }

  BattleMoveBehaviorResolution _resolveNaturePower(
    BattleMoveBehaviorContext context,
  ) {
    return _resolveDamaging(
      context,
      _naturePowerMove(context.move, context.state.field),
    );
  }

  BattleMoveBehaviorResolution _resolveSecretPower(
    BattleMoveBehaviorContext context,
  ) {
    return _resolveDamaging(
      context,
      _secretPowerMove(context.move, context.state.field),
    );
  }

  BattleMoveBehaviorResolution _resolveSynchronoise(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final user = prepared.state.battlerAt(context.user);
    final targets = prepared.psdkTargets
        .where(
            (target) => _sharesAnyType(user, prepared.state.battlerAt(target)))
        .toList(growable: false);
    if (targets.isEmpty) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
      );
    }

    return _resolvePreparedDamage(
      context: context,
      prepared: prepared,
      move: context.move,
      targetSlot: targets.single,
    );
  }

  BattleMoveBehaviorResolution _resolveDamaging(
    BattleMoveBehaviorContext context,
    BattleMoveDefinition move,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return _resolvePreparedDamage(
      context: context,
      prepared: prepared,
      move: move,
      targetSlot: prepared.psdkTargets.single,
    );
  }

  BattleMoveBehaviorResolution _resolvePreparedDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
    required BattleMoveDefinition move,
    required PsdkBattleSlotRef targetSlot,
  }) {
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: move,
        rng: prepared.rng,
        field: prepared.state.field,
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
      moveCategory: move.category,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
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

  BattleMoveDefinition _naturePowerMove(
    BattleMoveDefinition move,
    PsdkBattleFieldState field,
  ) {
    return switch (field.terrain?.id) {
      PsdkBattleTerrainId.electricTerrain => _copyMove(
          move,
          id: 'thunderbolt',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      PsdkBattleTerrainId.grassyTerrain => _copyMove(
          move,
          id: 'energy_ball',
          type: 'grass',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      PsdkBattleTerrainId.mistyTerrain => _copyMove(
          move,
          id: 'moonblast',
          type: 'fairy',
          category: PsdkBattleMoveCategory.special,
          power: 95,
        ),
      PsdkBattleTerrainId.psychicTerrain => _copyMove(
          move,
          id: 'psychic',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      null => _copyMove(
          move,
          id: 'tri_attack',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
    };
  }

  BattleMoveDefinition _secretPowerMove(
    BattleMoveDefinition move,
    PsdkBattleFieldState field,
  ) {
    return switch (field.terrain?.id) {
      PsdkBattleTerrainId.electricTerrain => _copyMove(
          move,
          effectChance: 30,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      PsdkBattleTerrainId.grassyTerrain => _copyMove(
          move,
          effectChance: 30,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.sleep,
              chance: 100,
            ),
          ],
        ),
      PsdkBattleTerrainId.mistyTerrain => _copyMove(
          move,
          effectChance: 30,
          stageMods: const <BattleStageMod>[
            BattleStageMod(stat: 'specialAttack', stages: -1),
          ],
        ),
      PsdkBattleTerrainId.psychicTerrain => _copyMove(
          move,
          effectChance: 30,
          stageMods: const <BattleStageMod>[
            BattleStageMod(stat: 'speed', stages: -1),
          ],
        ),
      null => _copyMove(
          move,
          effectChance: 30,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
    };
  }

  bool _sharesAnyType(PsdkBattleCombatant user, PsdkBattleCombatant target) {
    final userTypes = <String>{
      user.types.primary,
      if (user.types.secondary != null) user.types.secondary!,
      if (user.type3 != null) user.type3!,
      ...user.temporaryTypes,
    }.map((type) => type.toLowerCase());
    return userTypes.any(target.hasType);
  }

  String _typeByTerrain(PsdkBattleFieldState field) {
    return switch (field.terrain?.id) {
      PsdkBattleTerrainId.electricTerrain => 'electric',
      PsdkBattleTerrainId.grassyTerrain => 'grass',
      PsdkBattleTerrainId.mistyTerrain => 'fairy',
      PsdkBattleTerrainId.psychicTerrain => 'psychic',
      null => 'normal',
    };
  }
}

BattleMoveDefinition _copyMove(
  BattleMoveDefinition move, {
  String? id,
  String? type,
  PsdkBattleMoveCategory? category,
  int? power,
  int? effectChance,
  List<BattleStageMod>? stageMods,
  List<PsdkBattleMoveStatus>? statuses,
}) {
  final nextId = id ?? move.id;
  return BattleMoveDefinition(
    id: nextId,
    dbSymbol: nextId,
    name: nextId,
    type: type ?? move.type,
    category: category ?? move.category,
    power: power ?? move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: effectChance ?? move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: stageMods ?? move.stageMods,
    statuses: statuses ?? move.statuses,
  );
}
