import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';

final class ZMoveBehavior implements BattleMoveUserPreventionBehavior {
  const ZMoveBehavior.offensiveSignature({
    required BattleMoveBehaviorResolver resolveBasic,
  }) : _resolveBasic = resolveBasic;

  @override
  String get battleEngineMethod => 's_z_move';

  final BattleMoveBehaviorResolver _resolveBasic;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    return signatureZMoveUserPrevention(
      state: context.state,
      user: context.user,
      move: context.move,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
      );
    }

    final normalizedMove = _normalizedTargetMove(context.move);
    final normalizedTarget = _normalizedTarget(
      user: context.user,
      target: context.target,
      move: normalizedMove,
    );
    return _resolveBasic(
      BattleMoveBehaviorContext(
        state: context.state.markZMoveUsed(context.user.bank),
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: normalizedTarget,
        move: normalizedMove,
        canFlee: context.canFlee,
        moveSlot: context.moveSlot,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
        announcedMoveFor: context.announcedMoveFor,
      ),
    );
  }
}

BattleMoveUserPreventionResult? signatureZMoveUserPrevention({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required BattleMoveDefinition move,
}) {
  final spec = signatureZMoveSpecFor(move.dbSymbol);
  if (spec == null) {
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
      message: 'unsupported_z_move',
    );
  }

  if (state.hasZMoveUsedBank(user.bank)) {
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
      message: 'z_move_already_used',
    );
  }

  final battler = state.battlerAt(user);
  if (_normalizedId(battler.heldItemId) != spec.crystalItemId) {
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
      message: 'z_crystal_mismatch',
    );
  }

  if (!spec.speciesIds.contains(_normalizedId(battler.speciesId))) {
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
      message: 'z_species_mismatch',
    );
  }

  final hasSourceMove = battler.moves.any((candidate) {
    return _normalizedId(candidate.id) == spec.sourceMoveId ||
        _normalizedId(candidate.dbSymbol) == spec.sourceMoveId;
  });
  if (!hasSourceMove) {
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
      message: 'z_source_move_missing',
    );
  }

  return null;
}

bool isSignatureZMoveSelectable({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required BattleMoveDefinition move,
}) {
  return signatureZMoveUserPrevention(
        state: state,
        user: user,
        move: move,
      ) ==
      null;
}

SignatureZMoveSpec? signatureZMoveSpecFor(String dbSymbol) {
  return _signatureZMoves[_normalizedId(dbSymbol)];
}

final class SignatureZMoveSpec {
  const SignatureZMoveSpec({
    required this.moveId,
    required this.crystalItemId,
    required this.sourceMoveId,
    required this.speciesIds,
    this.correctUserTarget = false,
  });

  final String moveId;
  final String crystalItemId;
  final String sourceMoveId;
  final Set<String> speciesIds;
  final bool correctUserTarget;
}

BattleMoveDefinition _normalizedTargetMove(BattleMoveDefinition move) {
  final spec = signatureZMoveSpecFor(move.dbSymbol);
  if (spec == null || !spec.correctUserTarget) {
    return move;
  }
  return move.copyWith(target: PsdkBattleMoveTarget.adjacentFoe);
}

PsdkBattleSlotRef _normalizedTarget({
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required BattleMoveDefinition move,
}) {
  final spec = signatureZMoveSpecFor(move.dbSymbol);
  if (spec == null || !spec.correctUserTarget || target != user) {
    return target;
  }
  return psdkSinglesFoeOf(user);
}

String _normalizedId(String? id) {
  return id?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}

const _signatureZMoves = <String, SignatureZMoveSpec>{
  'catastropika': SignatureZMoveSpec(
    moveId: 'catastropika',
    crystalItemId: 'pikanium_z',
    sourceMoveId: 'volt_tackle',
    speciesIds: <String>{'pikachu'},
  ),
  'let_s_snuggle_forever': SignatureZMoveSpec(
    moveId: 'let_s_snuggle_forever',
    crystalItemId: 'mimikium_z',
    sourceMoveId: 'play_rough',
    speciesIds: <String>{'mimikyu', 'mimikyu_disguised', 'mimikyu_busted'},
  ),
  'menacing_moonraze_maelstrom': SignatureZMoveSpec(
    moveId: 'menacing_moonraze_maelstrom',
    crystalItemId: 'lunalium_z',
    sourceMoveId: 'moongeist_beam',
    speciesIds: <String>{'lunala', 'necrozma_dawn_wings'},
  ),
  'oceanic_operetta': SignatureZMoveSpec(
    moveId: 'oceanic_operetta',
    crystalItemId: 'primarium_z',
    sourceMoveId: 'sparkling_aria',
    speciesIds: <String>{'primarina'},
  ),
  'pulverizing_pancake': SignatureZMoveSpec(
    moveId: 'pulverizing_pancake',
    crystalItemId: 'snorlium_z',
    sourceMoveId: 'giga_impact',
    speciesIds: <String>{'snorlax'},
  ),
  's10_000_000_volt_thunderbolt': SignatureZMoveSpec(
    moveId: 's10_000_000_volt_thunderbolt',
    crystalItemId: 'pikashunium_z',
    sourceMoveId: 'thunderbolt',
    speciesIds: <String>{
      'pikachu',
      'pikachu_original_cap',
      'pikachu_hoenn_cap',
      'pikachu_sinnoh_cap',
      'pikachu_unova_cap',
      'pikachu_kalos_cap',
      'pikachu_alola_cap',
      'pikachu_partner_cap',
      'pikachu_world_cap',
    },
  ),
  'searing_sunraze_smash': SignatureZMoveSpec(
    moveId: 'searing_sunraze_smash',
    crystalItemId: 'solganium_z',
    sourceMoveId: 'sunsteel_strike',
    speciesIds: <String>{'solgaleo', 'necrozma_dusk_mane'},
    correctUserTarget: true,
  ),
  'sinister_arrow_raid': SignatureZMoveSpec(
    moveId: 'sinister_arrow_raid',
    crystalItemId: 'decidium_z',
    sourceMoveId: 'spirit_shackle',
    speciesIds: <String>{'decidueye'},
  ),
  'soul_stealing_7_star_strike': SignatureZMoveSpec(
    moveId: 'soul_stealing_7_star_strike',
    crystalItemId: 'marshadium_z',
    sourceMoveId: 'spectral_thief',
    speciesIds: <String>{'marshadow'},
  ),
  'stoked_sparksurfer': SignatureZMoveSpec(
    moveId: 'stoked_sparksurfer',
    crystalItemId: 'aloraichium_z',
    sourceMoveId: 'thunderbolt',
    speciesIds: <String>{'raichu_alola', 'alolan_raichu'},
  ),
};
