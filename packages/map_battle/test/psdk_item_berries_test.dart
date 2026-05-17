import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK berry item effects', () {
    test('Oran Berry heals after damage at the PSDK half HP threshold', () {
      final result = _damagePlayer(
        playerHeldItemId: 'oran_berry',
        rawDamage: 60,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 50);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'oran_berry');
      expect(player.itemConsumed, isTrue);
      expect(_healEvents(result, moveId: 'item:oran_berry').single.amount, 10);
      expect(_itemEvents(result).single.itemId, 'oran_berry');
    });

    test('Sitrus Berry heals at end turn and is consumed only once', () {
      final first = _tickEndTurn(
        playerHeldItemId: 'sitrus_berry',
        playerCurrentHp: 40,
      );
      final second = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: first.state,
          rng: first.rng,
          turn: 3,
          user: psdkPlayerSlot,
        ),
      );

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 65);
      expect(first.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
          first.state.battlerAt(psdkPlayerSlot).consumedItemId, 'sitrus_berry');
      expect(_healEvents(first, moveId: 'item:sitrus_berry').single.amount, 25);
      expect(_healEvents(second, moveId: 'item:sitrus_berry'), isEmpty);
      expect(_itemEvents(second), isEmpty);
    });

    test('Rawst Berry cures burn immediately after the status is applied', () {
      final result = _applyStatus(
        playerHeldItemId: 'rawst_berry',
        status: PsdkBattleMajorStatus.burn,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, isNull);
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'rawst_berry');
      expect(_statusCureEvents(result, moveId: 'status_move').single.status,
          PsdkBattleMajorStatus.burn);
      expect(_itemEvents(result).single.itemId, 'rawst_berry');
    });

    test('Lum Berry cures any major status and Pecha Berry cures toxic', () {
      final lum = _applyStatus(
        playerHeldItemId: 'lum_berry',
        status: PsdkBattleMajorStatus.sleep,
      );
      final pecha = _applyStatus(
        playerHeldItemId: 'pecha_berry',
        status: PsdkBattleMajorStatus.toxic,
      );

      expect(lum.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(lum.state.battlerAt(psdkPlayerSlot).consumedItemId, 'lum_berry');
      expect(pecha.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
          pecha.state.battlerAt(psdkPlayerSlot).consumedItemId, 'pecha_berry');
    });

    test('Liechi Berry raises attack at pinch threshold', () {
      final result = _tickEndTurn(
        playerHeldItemId: 'liechi_berry',
        playerCurrentHp: 25,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'liechi_berry');
      expect(player.statStages.valueOf('attack'), 1);
      expect(_statEvents(result).single.stat, 'attack');
      expect(_itemEvents(result).single.itemId, 'liechi_berry');
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

BattleHandlerResult _damagePlayer({
  required String playerHeldItemId,
  required int rawDamage,
}) {
  final state = _state(playerHeldItemId: playerHeldItemId);
  return const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 1,
      user: psdkOpponentSlot,
    ),
    target: psdkPlayerSlot,
    moveId: 'tackle',
    rawDamage: rawDamage,
    move: BattleMoveDefinition.fromPsdk(_move(id: 'tackle', power: 40)),
  );
}

BattleHandlerResult _tickEndTurn({
  required String playerHeldItemId,
  required int playerCurrentHp,
}) {
  final state = _state(
    playerHeldItemId: playerHeldItemId,
    playerCurrentHp: playerCurrentHp,
  );
  return const BattleEndTurnHandler().resolveEndTurn(
    BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 2,
      user: psdkPlayerSlot,
    ),
  );
}

BattleHandlerResult _applyStatus({
  required String playerHeldItemId,
  required PsdkBattleMajorStatus status,
}) {
  final state = _state(playerHeldItemId: playerHeldItemId);
  return const BattleStatusChangeHandler().applyMajorStatus(
    context: BattleHandlerContext(
      state: state,
      rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      turn: 1,
      user: psdkOpponentSlot,
    ),
    target: psdkPlayerSlot,
    moveId: 'status_move',
    status: status,
  );
}

PsdkBattleState _state({
  required String playerHeldItemId,
  int playerCurrentHp = 100,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        heldItemId: playerHeldItemId,
        currentHp: playerCurrentHp,
        move: _move(id: 'tackle', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'status_move', power: 0),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? heldItemId,
  int currentHp = 100,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    heldItemId: heldItemId,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: power > 0
        ? PsdkBattleMoveCategory.physical
        : PsdkBattleMoveCategory.status,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: power > 0 ? 's_basic' : 's_status',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleHealEvent> _healEvents(
  BattleHandlerResult result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleItemEvent> _itemEvents(BattleHandlerResult result) {
  return result.events.whereType<PsdkBattleItemEvent>().toList(growable: false);
}

List<PsdkBattleStatusCureEvent> _statusCureEvents(
  BattleHandlerResult result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleStatusCureEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

List<PsdkBattleStatStageEvent> _statEvents(BattleHandlerResult result) {
  return result.events
      .whereType<PsdkBattleStatStageEvent>()
      .toList(growable: false);
}
