import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _playerLeft = PsdkBattleSlotRef(bank: 0, position: 0);
const _playerRight = PsdkBattleSlotRef(bank: 0, position: 1);
const _opponentLeft = PsdkBattleSlotRef(bank: 1, position: 0);
const _opponentRight = PsdkBattleSlotRef(bank: 1, position: 1);

void main() {
  group('PSDK doubles engine targeting and damage', () {
    test('retargets a fainted opposing anchor to the remaining live foe', () {
      final state = _state(fainted: {_opponentLeft});

      expect(
        _targets(
          state: state,
          move: _move(target: PsdkBattleMoveTarget.adjacentFoe),
          requested: _opponentLeft,
        ),
        const [BattlePositionRef(bank: 1, position: 1)],
      );
    });

    test('spread targets remain live when the requested anchor has fainted',
        () {
      final state = _state(fainted: {_opponentLeft});

      expect(
        _targets(
          state: state,
          move: _move(),
          requested: _opponentLeft,
        ),
        const [BattlePositionRef(bank: 1, position: 1)],
      );
    });

    test('spread reduction multiplies Mod1 before the addition of two', () {
      final state = _state();

      expect(_damage(state: state, target: _opponentLeft), 5);
    });

    test('a spread move keeps full damage against the last live opposing slot',
        () {
      final state = _state(fainted: {_opponentRight});

      expect(_damage(state: state, target: _opponentLeft), 6);
    });
  });

  group('PSDK doubles engine requests', () {
    test(
        'doubles requires the explicit standard profile and keeps beta disabled',
        () {
      expect(
        () => PsdkBattleSetup.doubles(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          player: [_combatant(id: 'p0'), _combatant(id: 'p1')],
          opponent: [_combatant(id: 'o0'), _combatant(id: 'o1')],
          rngSeeds: _seeds,
        ),
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
      final setup = PsdkBattleSetup.doubles(
        ruleset: PokemonRulesetProfile.standardV1,
        player: [_combatant(id: 'p0'), _combatant(id: 'p1')],
        opponent: [_combatant(id: 'o0'), _combatant(id: 'o1')],
        rngSeeds: _seeds,
      );
      expect(setup.isSingles, isFalse);
      expect(setup.isTrainerBattle, isTrue);
      expect(setup.canCapture, isFalse);
      expect(setup.canFlee, isFalse);
      expect(
          BattleEngine.fromPsdk(setup: setup).snapshot().combatants.length, 4);
    });

    test(
        'doubles rejects missing, duplicate, fainted or oversized active parties',
        () {
      for (final player in [
        [_combatant(id: 'p0')],
        [_combatant(id: 'same'), _combatant(id: 'same')],
        [_combatant(id: 'p0', hp: 0), _combatant(id: 'p1')],
        [_combatant(id: 'p0'), _combatant(id: 'p1'), _combatant(id: 'p2')],
      ]) {
        expect(
            () => PsdkBattleSetup.doubles(
                  ruleset: PokemonRulesetProfile.standardV1,
                  player: player,
                  opponent: [_combatant(id: 'o0'), _combatant(id: 'o1')],
                  rngSeeds: _seeds,
                ),
            throwsArgumentError);
      }
      expect(
          () => PsdkBattleSetup.doubles(
                ruleset: PokemonRulesetProfile.standardV1,
                player: [_combatant(id: 'p0'), _combatant(id: 'p1')],
                opponent: [_combatant(id: 'o0'), _combatant(id: 'o1')],
                playerReserves:
                    List.generate(5, (i) => _combatant(id: 'reserve-$i')),
                rngSeeds: _seeds,
              ),
          throwsArgumentError);
    });

    test('collects two choices before changing PP, HP, RNG or turn', () {
      final engine = _engine();
      final before = engine.snapshot();
      final request = engine.currentRequest;
      expect(identical(engine.currentRequest, request), isTrue);
      expect(request.actor, _playerLeft);
      expect(request.actorCombatantId, 'player-left');

      final pending = engine.submit(
        const BattleDecision.fight(moveSlot: 0),
        request: request,
      );

      _expectUnchanged(before, pending.state);
      expect(pending.timeline.events, isEmpty);
      expect(pending.nextRequest?.actor, _playerRight);
      expect(pending.nextRequest!.requestRevision,
          greaterThan(request.requestRevision));
      expect(pending.nextRequest?.actorCombatantId, 'player-right');
    });

    test('doubles item preflight rejects an initially useless heal', () {
      final engine = _engine();
      final before = engine.snapshot();
      final request = engine.currentRequest;

      expect(
        () => engine.submit(
          const BattleDecision.item(
            itemId: 'potion',
            target: _playerLeft,
            effect: PsdkBattleHpHealItemEffect.flat(20),
          ),
          request: request,
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );

      expect(identical(engine.currentRequest, request), isTrue);
      _expectUnchanged(before, engine.snapshot());
    });

    test('doubles item resolution keeps a heal that makes the next useless',
        () {
      final wait = PsdkBattleMoveData(
        id: 'wait',
        dbSymbol: 'wait',
        name: 'Wait',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        pp: 10,
        priority: 0,
        battleEngineMethod: 's_status',
        target: PsdkBattleMoveTarget.self,
      );
      final engine = _engine(playerLeftHp: 90, opponentMoves: [wait]);
      final before = engine.snapshot();
      const potion = BattleDecision.item(
        itemId: 'potion',
        target: _playerLeft,
        effect: PsdkBattleHpHealItemEffect.flat(20),
      );

      final first = engine.submit(potion, request: engine.currentRequest);
      _expectUnchanged(before, first.state);
      expect(first.timeline.events, isEmpty);
      final result = engine.submit(potion, request: engine.currentRequest);

      expect(result.state.turnNumber, 1);
      expect(result.state.battlerAt(_playerLeft).currentHp, 100);
      expect(result.state.battlerAt(_playerLeft).moves.single.currentPp, 10);
      expect(result.state.battlerAt(_playerRight).moves.single.currentPp, 10);
      expect(result.state.battlerAt(_opponentLeft).moves.single.currentPp, 9);
      expect(result.state.battlerAt(_opponentRight).moves.single.currentPp, 9);
      expect(
          result.timeline.events
              .whereType<BattleHealTimelineEvent>()
              .single
              .amount,
          10);
      expect(
          result.timeline.events
              .whereType<BattleItemTimelineEvent>()
              .single
              .kind,
          'item_consumed');
    });

    test('rejects missing, foreign and already accepted request references',
        () {
      final engine = _engine();
      final request = engine.currentRequest;
      final before = engine.snapshot();
      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(
        () => engine.submit(
          const BattleDecision.fight(moveSlot: 0),
          request: _engine().currentRequest,
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      _expectUnchanged(before, engine.snapshot());
      engine.submit(const BattleDecision.fight(moveSlot: 0), request: request);
      final second = engine.currentRequest;
      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0),
            request: request),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(identical(engine.currentRequest, second), isTrue);
      _expectUnchanged(before, engine.snapshot());
    });

    test('rejects an old request for the same actor on a later turn', () {
      final engine = _engine();
      final old = engine.currentRequest;
      _turn(engine);
      final before = engine.snapshot();
      expect(engine.currentRequest.actor, old.actor);
      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0),
            request: old),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      _expectUnchanged(before, engine.snapshot());
    });

    test('resolves four distinct actors in speed order after both choices', () {
      final engine = _engine();
      final result = _turn(engine);
      final declared = result.timeline.events
          .whereType<BattleMoveDeclaredTimelineEvent>()
          .map((event) => event.user)
          .toList();
      expect(declared, const [
        BattlePositionRef(bank: 0, position: 0),
        BattlePositionRef(bank: 1, position: 0),
        BattlePositionRef(bank: 0, position: 1),
        BattlePositionRef(bank: 1, position: 1),
      ]);
      expect(result.state.turnNumber, 1);
      for (final battler in result.state.combatants.values) {
        expect(battler.moves.single.currentPp, 9);
      }
      expect(result.state.playerParticipantPartyIndexes, {0, 1});
    });

    test(
        'configured AI chooses once for each opposing actor and its target slot',
        () {
      final engine = _engine(
        opponentMoves: [
          _move(target: PsdkBattleMoveTarget.adjacentFoe).psdkMove
        ],
        opponentAi: const PsdkBattleAi(),
      );
      final result = _turn(engine);
      expect(result.state.battlerAt(_playerLeft).currentHp, lessThan(100));
      expect(result.state.battlerAt(_playerRight).currentHp, lessThan(100));
      expect(result.state.battlerAt(_opponentLeft).moves.single.currentPp, 9);
      expect(result.state.battlerAt(_opponentRight).moves.single.currentPp, 9);
    });

    test('self and allied moves expose only their own legal target slots', () {
      final self = _engine(
          playerMoves: [_move(target: PsdkBattleMoveTarget.self).psdkMove]);
      expect(
          self.currentRequest.fightChoices.single.legalTargets, [_playerLeft]);
      expect(
          self.currentRequest.allows(
              const BattleDecision.fight(moveSlot: 0, target: _opponentLeft)),
          isFalse);
      final ally = _engine(playerMoves: [
        _move(target: PsdkBattleMoveTarget.adjacentAlly).psdkMove
      ]);
      expect(
          ally.currentRequest.fightChoices.single.legalTargets, [_playerRight]);
      expect(
          ally.currentRequest.allows(
              const BattleDecision.fight(moveSlot: 0, target: _playerRight)),
          isTrue);
    });

    test('exposes legal target slots and rejects the allied target atomically',
        () {
      final engine = _engine(playerMoves: [
        _move(target: PsdkBattleMoveTarget.adjacentFoe).psdkMove
      ]);
      final request = engine.currentRequest;
      expect(request.fightChoices.single.legalTargets,
          [_opponentLeft, _opponentRight]);
      final before = engine.snapshot();
      expect(
        () => engine.submit(
          const BattleDecision.fight(moveSlot: 0, target: _playerRight),
          request: request,
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(identical(engine.currentRequest, request), isTrue);
      _expectUnchanged(before, engine.snapshot());
    });

    test(
        'a failed second action rolls back the complete turn and keeps its request',
        () {
      final engine = _engine(
          playerRightMoves: [_move(method: 'missing-l32-handler').psdkMove]);
      final before = engine.snapshot();
      engine.submit(const BattleDecision.fight(moveSlot: 0),
          request: engine.currentRequest);
      final second = engine.currentRequest;
      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0),
            request: second),
        throwsA(isA<UnsupportedPsdkBattleMoveBehavior>()),
      );
      _expectUnchanged(before, engine.snapshot());
      expect(identical(engine.currentRequest, second), isTrue);
    });

    test('switch choices exclude allies and the reserve already selected', () {
      final engine = _engine(playerReserves: [
        _combatant(id: 'reserve-a'),
        _combatant(id: 'reserve-b')
      ]);
      expect(
          engine.currentRequest.switchChoices.map((c) => c.partyIndex), [2, 3]);
      engine.submit(const BattleDecision.switchPokemon(partyIndex: 2),
          request: engine.currentRequest);
      expect(engine.currentRequest.switchChoices.map((c) => c.partyIndex), [3]);
      final result = engine.submit(
          const BattleDecision.switchPokemon(partyIndex: 3),
          request: engine.currentRequest);
      expect(result.state.battlerAt(_playerLeft).id, 'reserve-a');
      expect(result.state.battlerAt(_playerRight).id, 'reserve-b');
      expect(
          result.state.topology
              .battlerAt(const BattlePositionRef(bank: 0, position: 0))!
              .partyIndex,
          2);
      expect(
          result.state.topology
              .battlerAt(const BattlePositionRef(bank: 0, position: 1))!
              .partyIndex,
          3);
      expect(result.state.partyForBank(0).map((b) => b.id),
          ['player-left', 'player-right', 'reserve-a', 'reserve-b']);
    });

    test('a voluntary switch emits one canonical out and in for slot one', () {
      final engine = _engine(playerReserves: [_combatant(id: 'reserve-right')]);
      engine.submit(const BattleDecision.fight(moveSlot: 0),
          request: engine.currentRequest);

      final result = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 2),
        request: engine.currentRequest,
      );

      final outgoing = result.timeline.events
          .whereType<BattleSwitchOutTimelineEvent>()
          .single;
      final incoming = result.timeline.events
          .whereType<BattleSwitchInTimelineEvent>()
          .single;
      expect(outgoing.battler, const BattlePositionRef(bank: 0, position: 1));
      expect(outgoing.speciesId, 'player-right');
      expect(incoming.battler, outgoing.battler);
      expect(incoming.speciesId, 'reserve-right');
      expect(result.timeline.events.indexOf(outgoing),
          lessThan(result.timeline.events.indexOf(incoming)));
      expect(result.state.battlerAt(_playerRight).id, 'reserve-right');
      expect(
          result.timeline.events.where((event) => event.kind == 'switch_out'),
          hasLength(1));
      expect(result.timeline.events.where((event) => event.kind == 'switch_in'),
          hasLength(1));
    });

    test('a fainted anchor does not discard the later spread action', () {
      final engine = _engine(
        playerMoves: [
          _move(target: PsdkBattleMoveTarget.adjacentFoe, power: 500).psdkMove
        ],
        opponentLeftHp: 1,
      );
      final result = _turn(engine);
      final right = result.state.battlerAt(_opponentRight);
      expect(result.state.battlerAt(_opponentLeft).isFainted, isTrue);
      expect(right.currentHp, lessThan(100));
      expect(
          result.timeline.events
              .whereType<BattleMoveDeclaredTimelineEvent>()
              .any((e) =>
                  e.user == const BattlePositionRef(bank: 0, position: 1)),
          isTrue);
      expect(result.state.battlerAt(_playerRight).moves.single.currentPp, 9);
      expect(result.outcome, isNull);
    });

    test('two forced replacements are distinct and do not advance the turn',
        () {
      final engine = _engine(
        opponentMoves: [_move(power: 10000, priority: 2).psdkMove],
        playerReserves: [
          _combatant(id: 'reserve-a'),
          _combatant(id: 'reserve-b')
        ],
      );
      final knockedOut = _turn(engine);
      expect(knockedOut.outcome, isNull);
      expect(engine.currentRequest.kind,
          BattleEngineDecisionRequestKind.forcedReplacement);
      expect(engine.currentRequest.actor, _playerLeft);
      final first = engine.submit(
          const BattleDecision.switchPokemon(partyIndex: 2),
          request: engine.currentRequest);
      expect(first.state.turnNumber, 1);
      expect(engine.currentRequest.kind,
          BattleEngineDecisionRequestKind.forcedReplacement);
      expect(engine.currentRequest.actor, _playerRight);
      expect(engine.currentRequest.switchChoices.map((c) => c.partyIndex), [3]);
      final second = engine.submit(
          const BattleDecision.switchPokemon(partyIndex: 3),
          request: engine.currentRequest);
      expect(second.state.turnNumber, 1);
      expect(second.state.battlerAt(_playerLeft).id, 'reserve-a');
      expect(second.state.battlerAt(_playerRight).id, 'reserve-b');
      expect(
          second.timeline.events.whereType<BattleMoveDeclaredTimelineEvent>(),
          isEmpty);
    });

    test('single battles keep the immediate submission API with a full party',
        () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          player: _combatant(id: 'player'),
          opponent: _combatant(id: 'opponent'),
          playerReserves: List.generate(5, (i) => _combatant(id: 'reserve-$i')),
          rngSeeds: _seeds,
        ),
      );
      expect(engine.snapshot().combatants.length, 2);
      expect(
          engine
              .submit(const BattleDecision.fight(moveSlot: 0))
              .state
              .turnNumber,
          1);
    });

    test(
        'equal-speed four-actor ordering is replayable and consumes generic RNG',
        () {
      final actions = [
        for (final user in const [
          _playerLeft,
          _playerRight,
          _opponentLeft,
          _opponentRight
        ])
          PsdkBattleFightAction(
              user: user,
              target: _opponentLeft,
              moveSlot: 0,
              move: _move().psdkMove,
              speed: 50),
      ];
      final rules =
          PokemonBattleRules.fromProfile(PokemonRulesetProfile.standardV1);
      final first = const PsdkBattleActionOrdering()
          .order(actions: actions, rng: _rng(), rules: rules);
      final replay = const PsdkBattleActionOrdering()
          .order(actions: actions, rng: _rng(), rules: rules);
      expect(
          first.actions.map((a) => a.user), replay.actions.map((a) => a.user));
      expect(first.actions.map((a) => a.user).toSet(),
          {_playerLeft, _playerRight, _opponentLeft, _opponentRight});
      expect(first.rng.seeds.generic, isNot(_rng().seeds.generic));
    });

    test('slot-bearing presentation events keep position one', () {
      const switched = BattleSwitchEvent.switched(
          side: BattleSideId.player,
          slotIndex: 1,
          fromSpeciesId: 'old',
          toSpeciesId: 'new',
          wasForced: true);
      const stages = BattleTurnStatStageEvent(
          side: BattleSideId.enemy,
          slotIndex: 1,
          stat: BattleStatId.attack,
          amount: -1,
          currentStage: -1);
      expect(switched.slot,
          const BattleSlotRef(side: BattleSideId.player, slotIndex: 1));
      expect(stages.slot,
          const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1));
    });

    test('opponent faint replacements use two distinct reserves before victory',
        () {
      final engine = _engine(
        playerMoves: [_move(power: 10000, priority: 3).psdkMove],
        opponentReserves: [
          _combatant(id: 'foe-reserve-a'),
          _combatant(id: 'foe-reserve-b')
        ],
      );
      final first = _turn(engine);
      expect(first.outcome, isNull);
      expect(first.state.battlerAt(_opponentLeft).id, 'foe-reserve-a');
      expect(first.state.battlerAt(_opponentRight).id, 'foe-reserve-b');
      final second = _turn(engine);
      expect(second.outcome?.kind, BattleEngineOutcomeKind.victory);
      expect(second.state.partyForBank(1).every((b) => b.isFainted), isTrue);
    });

    test(
        'only the surviving player slot needs a decision when no reserve remains',
        () {
      final engine = _engine(
        opponentMoves: [
          _move(
                  target: PsdkBattleMoveTarget.adjacentFoe,
                  power: 10000,
                  priority: 2)
              .psdkMove
        ],
        opponentRightMoves: [],
      );
      final first = _turn(engine);
      expect(first.outcome, isNull);
      expect(engine.currentRequest.actor, _playerRight);
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0),
          request: engine.currentRequest);
      expect(second.state.turnNumber, 2);
      expect(second.outcome?.kind, BattleEngineOutcomeKind.defeat);
    });

    test(
        'multiple switches retain party identity, PP, HP and participant indices',
        () {
      final engine = _engine(playerReserves: [
        _combatant(id: 'reserve-a'),
        _combatant(id: 'reserve-b')
      ]);
      engine.submit(const BattleDecision.switchPokemon(partyIndex: 2),
          request: engine.currentRequest);
      final away = engine.submit(
          const BattleDecision.switchPokemon(partyIndex: 3),
          request: engine.currentRequest);
      final reserveHp =
          away.state.partyForBank(0).skip(2).map((b) => b.currentHp).toList();
      engine.submit(const BattleDecision.switchPokemon(partyIndex: 0),
          request: engine.currentRequest);
      final back = engine.submit(
          const BattleDecision.switchPokemon(partyIndex: 1),
          request: engine.currentRequest);
      expect(back.state.battlerAt(_playerLeft).id, 'player-left');
      expect(back.state.battlerAt(_playerRight).id, 'player-right');
      expect(back.state.partyForBank(0).skip(2).map((b) => b.currentHp),
          reserveHp);
      expect(back.state.partyForBank(0).map((b) => b.moves.single.currentPp),
          [10, 10, 10, 10]);
      expect(back.state.playerParticipantPartyIndexes, {0, 1, 2, 3});
      expect(
          back.state.topology
              .battlerAt(const BattlePositionRef(bank: 0, position: 0))!
              .partyIndex,
          0);
      expect(
          back.state.topology
              .battlerAt(const BattlePositionRef(bank: 0, position: 1))!
              .partyIndex,
          1);
      expect(() => back.state.partyForBank(0).clear(), throwsUnsupportedError);
    });

    test(
        'the facade forwards the exact request identity without accepting duplicates',
        () {
      final session = BattleSessionFacade(engine: _engine());
      final first = session.decisionRequest;
      session.submit(const BattleDecision.fight(moveSlot: 0), request: first);
      expect(
          () => session.submit(const BattleDecision.fight(moveSlot: 0),
              request: first),
          throwsA(isA<BattleDecisionRejectedError>()));
      final result = session.submit(const BattleDecision.fight(moveSlot: 0),
          request: session.decisionRequest);
      expect(result.state.turnNumber, 1);
    });
  });
}

const _seeds = PsdkBattleRngSeeds(
    moveDamage: 14, moveCritical: 99999, moveAccuracy: 1, generic: 1);

BattleEngine _engine({
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? playerRightMoves,
  List<PsdkBattleMoveData>? opponentMoves,
  List<PsdkBattleMoveData>? opponentRightMoves,
  int playerLeftHp = 100,
  int opponentLeftHp = 100,
  List<PsdkBattleCombatantSetup> playerReserves = const [],
  List<PsdkBattleCombatantSetup> opponentReserves = const [],
  PsdkBattleAi? opponentAi,
}) =>
    BattleEngine.fromPsdk(
      opponentAi: opponentAi,
      setup: PsdkBattleSetup.doubles(
        ruleset: PokemonRulesetProfile.standardV1,
        player: [
          _combatant(
              id: 'player-left',
              hp: playerLeftHp,
              speed: 40,
              moves: playerMoves),
          _combatant(id: 'player-right', speed: 20, moves: playerRightMoves),
        ],
        opponent: [
          _combatant(
              id: 'opponent-left',
              hp: opponentLeftHp,
              speed: 30,
              moves: opponentMoves),
          _combatant(
              id: 'opponent-right',
              speed: 10,
              moves: opponentRightMoves ?? opponentMoves),
        ],
        playerReserves: playerReserves,
        opponentReserves: opponentReserves,
        rngSeeds: _seeds,
      ),
    );

BattleEngineTurnResult _turn(BattleEngine engine) {
  engine.submit(const BattleDecision.fight(moveSlot: 0),
      request: engine.currentRequest);
  return engine.submit(const BattleDecision.fight(moveSlot: 0),
      request: engine.currentRequest);
}

void _expectUnchanged(BattlePublicState before, BattlePublicState after) {
  expect(after.turnNumber, before.turnNumber);
  expect(after.rngSeeds.moveDamage, before.rngSeeds.moveDamage);
  expect(after.rngSeeds.moveCritical, before.rngSeeds.moveCritical);
  expect(after.rngSeeds.moveAccuracy, before.rngSeeds.moveAccuracy);
  expect(after.rngSeeds.generic, before.rngSeeds.generic);
  for (final slot in before.combatants.keys) {
    expect(after.battlerAt(slot).id, before.battlerAt(slot).id);
    expect(after.battlerAt(slot).currentHp, before.battlerAt(slot).currentHp);
    expect(after.battlerAt(slot).moves.map((m) => m.currentPp),
        before.battlerAt(slot).moves.map((m) => m.currentPp));
  }
}

PsdkBattleState _state({
  Set<PsdkBattleSlotRef> fainted = const {},
}) {
  return PsdkBattleState(
    ruleset: PokemonRulesetProfile.standardV1,
    combatants: {
      for (final slot in const [
        _playerLeft,
        _playerRight,
        _opponentLeft,
        _opponentRight,
      ])
        slot: PsdkBattleCombatant.fromSetup(
          _combatant(
            id: 'bank-${slot.bank}-position-${slot.position}',
            hp: fainted.contains(slot) ? 0 : 100,
          ),
        ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int hp = 100,
  int speed = 10,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'fighting'),
    stats: PsdkBattleStats(
      attack: 11,
      defense: 12,
      specialAttack: 11,
      specialDefense: 12,
      speed: speed,
    ),
    moves: moves ?? [_move().psdkMove],
  );
}

BattleMoveDefinition _move({
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.allAdjacentFoes,
  int power = 10,
  int priority = 0,
  String method = 's_basic',
}) {
  return BattleMoveDefinition(
    id: 'spread-hit',
    dbSymbol: 'spread_hit',
    name: 'Spread hit',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 10,
    priority: priority,
    criticalRate: 0,
    battleEngineMethod: method,
    target: target,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 14,
    moveCriticalSeed: 99999,
    moveAccuracySeed: 1,
    genericSeed: 1,
  );
}

int _damage({
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
}) {
  return const BattleMoveDamageCalculator()
      .calculate(
        BattleMoveDamageContext(
          user: state.battlerAt(_playerLeft),
          target: state.battlerAt(target),
          move: _move(),
          state: state,
          userSlot: _playerLeft,
          targetSlot: target,
          rng: _rng(),
        ),
      )
      .damage;
}

List<BattlePositionRef> _targets({
  required PsdkBattleState state,
  required BattleMoveDefinition move,
  required PsdkBattleSlotRef requested,
}) {
  return const BattleTargetResolver().resolve(
    BattleMoveProcedureExecution(
      context: BattleMoveBehaviorContext(
        state: state,
        rng: _rng(),
        turn: 1,
        user: _playerLeft,
        target: requested,
        move: move,
      ),
      timeline: BattleTimelineBuilder(),
      user: const BattlePositionRef(bank: 0, position: 0),
      move: move,
      requestedTarget: BattlePositionRef(
        bank: requested.bank,
        position: requested.position,
      ),
    ),
  );
}
