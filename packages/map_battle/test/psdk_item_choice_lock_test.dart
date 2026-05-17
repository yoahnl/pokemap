import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/disable_effect.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Choice item move lock', () {
    test('locks to the first attempted non-Struggle move while held', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHeldItemId: 'choice_band',
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
            _move(id: 'ember', type: 'fire', power: 40),
          ],
        ),
      );

      expect(
        engine.currentRequest.fightChoices.map((choice) => choice.moveId),
        <String>['tackle', 'ember'],
      );

      final firstTurn = engine.submit(
        const BattleDecision.fight(moveSlot: 0),
      );

      expect(
        firstTurn.nextRequest!.fightChoices.map((choice) => choice.moveId),
        <String>['tackle'],
      );

      final blocked = engine.submit(
        const BattleDecision.fight(moveSlot: 1),
      );
      final failures = _failedMoves(blocked);

      expect(failures, hasLength(1));
      expect(failures.single.moveId, 'ember');
      expect(
        failures.single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_damageEvents(blocked, moveId: 'ember'), isEmpty);
    });

    test('allows Struggle even when another move is locked', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHeldItemId: 'choice_scarf',
          playerMoveHistory: _attempts('tackle', turn: 1),
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
            _move(
              id: 'struggle',
              power: 50,
              battleEngineMethod: 's_struggle',
            ),
          ],
        ),
      );

      expect(
        engine.currentRequest.fightChoices.map((choice) => choice.moveId),
        <String>['tackle', 'struggle'],
      );
    });

    test('switch history clears the lock after the battler was sent again', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHeldItemId: 'choice_specs',
          playerLastSentTurn: 2,
          playerMoveHistory: _attempts('swift', turn: 1),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'swift',
              power: 60,
              category: PsdkBattleMoveCategory.special,
            ),
            _move(id: 'water_gun', type: 'water', power: 40),
          ],
        ),
      );

      expect(
        engine.currentRequest.fightChoices.map((choice) => choice.moveId),
        <String>['swift', 'water_gun'],
      );
    });

    test('item removal clears the lock immediately', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerHeldItemId: 'choice_band',
          playerMoveHistory: _attempts('tackle', turn: 1),
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
            _move(id: 'ember', type: 'fire', power: 40),
          ],
        ).psdkSetup,
      );
      final removed = const BattleItemChangeHandler().changeHeldItem(
        context: BattleHandlerContext(
          state: state,
          rng: BattleRngStreams.fromSeedSnapshot(_seeds),
          turn: 2,
          user: psdkPlayerSlot,
        ),
        target: psdkPlayerSlot,
        heldItemId: null,
      );

      final ember = BattleMoveDefinition.fromPsdk(
        removed.state.battlerAt(psdkPlayerSlot).moves[1],
      );

      expect(
        removed.state.battlerAt(psdkPlayerSlot).effects.moveSelectionPrevention(
              state: removed.state,
              user: psdkPlayerSlot,
              target: psdkOpponentSlot,
              move: ember,
            ),
        isNull,
      );
    });

    test('Disable can leave a Choice-locked battler with no legal move', () {
      final engine = BattleEngine(
        setup: _setup(
          playerHeldItemId: 'choice_band',
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            DisableEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
              disabledMoveId: 'tackle',
            ),
          ),
          playerMoveHistory: _attempts('tackle', turn: 1),
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40),
            _move(id: 'ember', type: 'fire', power: 40),
          ],
        ),
      );

      expect(
        engine.currentRequest.kind,
        BattleEngineDecisionRequestKind.noLegalChoice,
      );
      expect(engine.currentRequest.fightChoices, isEmpty);
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

BattleEngineSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  String? playerHeldItemId,
  int? playerLastSentTurn,
  PsdkBattleMoveHistory? playerMoveHistory,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      heldItemId: playerHeldItemId,
      lastSentTurn: playerLastSentTurn,
      moveHistory: playerMoveHistory,
      effects: playerEffects,
      moves: playerMoves,
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      currentHp: 200,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'opponent_wait',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ],
    ),
    rngSeeds: _seeds.psdkSeeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
  String? heldItemId,
  int currentHp = 100,
  int speed = 100,
  int? lastSentTurn,
  PsdkBattleMoveHistory? moveHistory,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 200,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    lastSentTurn: lastSentTurn,
    moveHistory: moveHistory,
    effects: effects,
    moves: moves,
  );
}

PsdkBattleMoveHistory _attempts(String moveId, {required int turn}) {
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      PsdkBattleMoveHistoryEntry(
        moveId: moveId,
        turn: turn,
        targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
      ),
    ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

List<PsdkBattleMoveFailedEvent> _failedMoves(BattleEngineTurnResult result) {
  return result.timeline.psdkTimeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .where((event) => event.user == psdkPlayerSlot)
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _damageEvents(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return result.timeline.psdkTimeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
