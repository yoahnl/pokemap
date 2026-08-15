import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';

void main() {
  group('runtime PSDK canonical battle decision contract', () {
    test('run choice terminates the PSDK engine instead of display-only state',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(canFlee: true),
      );

      expect(
        adapter.allowsPlayerChoice(const PlayerBattleChoiceRun()),
        isTrue,
      );

      final result = adapter.submitPlayerChoice(const PlayerBattleChoiceRun());

      expect(result.outcome?.kind, BattleEngineOutcomeKind.fled);
      expect(adapter.state.isFinished, isTrue);
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
      expect(
        adapter.createLegacyOutcome(isTrainerBattle: false).isRunaway,
        isTrue,
      );
    });

    test('trainer run is rejected by the canonical request without mutation',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(isTrainerBattle: true),
      );

      expect(
        adapter.allowsPlayerChoice(const PlayerBattleChoiceRun()),
        isFalse,
      );
      expect(
        () => adapter.submitPlayerChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(adapter.state.turnNumber, 0);
      expect(adapter.state.isFinished, isFalse);
    });

    test('forced replacement is exposed and resolved without an enemy turn',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerHp: 0,
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'reserve', hp: 80),
          ],
        ),
      );

      expect(
        adapter.decisionRequest.kind,
        BattleEngineDecisionRequestKind.forcedReplacement,
      );

      final result = adapter.submitPlayerChoice(
        const PlayerBattleChoiceSwitch(0),
      );

      expect(result.state.turnNumber, 0);
      expect(result.state.battlerAt(psdkPlayerSlot).id, 'reserve');
      expect(
        result.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
        isEmpty,
      );
    });

    test('exhausted PP exposes and executes Struggle through the player menu',
        () {
      final adapter = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final displaySession = adapter.createLegacyDisplaySession(
        isTrainerBattle: true,
      );
      final struggleChoice = displaySession.decisionRequest.allowedChoices
          .whereType<PlayerBattleChoiceFight>()
          .single;
      final menu = buildBattleCommandMenuModel(
        session: displaySession,
        mode: BattleCommandMenuMode.fight,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(
        adapter.decisionRequest.kind,
        BattleEngineDecisionRequestKind.turnChoice,
      );
      expect(adapter.decisionRequest.canStruggle, isTrue);
      expect(
          displaySession.state.player.moves.last.id, canonicalStruggleMoveId);
      expect(menu.choiceEntries.single.title, 'Struggle');
      expect(menu.choiceEntries.single.subtitle, contains('Power 50'));
      expect(adapter.allowsPlayerChoice(struggleChoice), isTrue);

      final result = adapter.submitPlayerChoice(struggleChoice);
      final updatedPlayer = result.state.battlerAt(psdkPlayerSlot);
      final updatedDisplay = adapter.createLegacyDisplaySession(
        isTrainerBattle: true,
      );

      expect(updatedPlayer.moves, hasLength(1));
      expect(updatedPlayer.moves.single.id, 'empty');
      expect(updatedPlayer.moves.single.currentPp, 0);
      expect(
        updatedPlayer.writeBackMoves.map((move) => move.id),
        isNot(contains(canonicalStruggleMoveId)),
      );
      expect(
        updatedDisplay.state.currentTurn!.playerAction,
        isA<BattleActionFight>().having(
          (action) => action.move.id,
          'move.id',
          canonicalStruggleMoveId,
        ),
      );
    });
  });
}

PsdkBattleSetup _setup({
  bool canFlee = false,
  bool isTrainerBattle = false,
  int playerHp = 80,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleMoveData>? playerMoves,
}) {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      hp: playerHp,
      moves: playerMoves,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(id: 'opponent', hp: 80),
    canFlee: canFlee,
    isTrainerBattle: isTrainerBattle,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_move(id: '$id-move')],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int currentPp = 10,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 10,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
