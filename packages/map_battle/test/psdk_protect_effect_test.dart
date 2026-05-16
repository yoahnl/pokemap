import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK clean Protect effect', () {
    test('s_protect blocks a slower incoming attack during the same turn', () {
      final engine = BattleEngine(setup: _setup());

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final events = result.timeline.events;

      expect(player.currentHp, 100);
      expect(player.effects.contains(PsdkBattleEffectIds.protect), isFalse);
      expect(player.moves[0].currentPp, 9);
      expect(player.moveHistory.lastSuccessfulMoveId, 'protect');
      expect(opponent.moves.single.currentPp, 34);
      expect(opponent.moveHistory.lastMoveId, 'opponent_tackle');
      expect(opponent.moveHistory.lastSuccessfulMoveId, isNull);
      expect(
        events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'move_pp_spent',
          'move_declared',
          'move_failed',
        ]),
      );

      final opponentEvents = events
          .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
          .toList(growable: false);
      expect(opponentEvents.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
      ]);
      expect(opponentEvents.last.toJson()['reason'], 'protected');
      expect(
        opponentEvents.map((event) => event.kind),
        isNot(contains('animation_cue')),
      );
      expect(
        opponentEvents.map((event) => event.kind),
        isNot(contains('damage')),
      );
    });

    test('protect expires before the next turn', () {
      final engine = BattleEngine(setup: _setup());

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 1));

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(second.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
      expect(
        second.timeline.events
            .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
            .map((event) => event.kind),
        contains('damage'),
      );
      expect(
        second.timeline.events
            .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
            .map((event) => event.kind),
        isNot(contains('move_failed')),
      );
    });

    test('consecutive Protect can fail from the PSDK success-rate decay', () {
      final engine = BattleEngine(setup: _setup());

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final protectEvents = second.timeline.events
          .where((event) => event.toJson()['moveId'] == 'protect')
          .toList(growable: false);
      final opponentEvents = second.timeline.events
          .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
          .toList(growable: false);

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(second.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
      expect(second.state.battlerAt(psdkPlayerSlot).moves[0].currentPp, 8);
      expect(protectEvents.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_failed',
      ]);
      expect(protectEvents.last.toJson()['reason'], 'unusable_by_user');
      expect(opponentEvents.map((event) => event.kind), contains('damage'));
    });

    test('a non-Protect action resets the Protect success-rate decay', () {
      final engine = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'opponent_tackle',
            type: 'normal',
            power: 10,
          ),
        ),
      );

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 1));
      final third = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final thirdOpponentEvents = third.timeline.events
          .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
          .toList(growable: false);

      expect(first.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(second.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
      expect(third.state.battlerAt(psdkPlayerSlot).currentHp,
          second.state.battlerAt(psdkPlayerSlot).currentHp);
      expect(
        thirdOpponentEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'move_failed',
        ]),
      );
      expect(thirdOpponentEvents.last.toJson()['reason'], 'protected');
    });

    test('a pre-seeded protect effect is immutable and cleared at turn end',
        () {
      final engine = BattleEngine(
        setup: _setup(
          playerEffects: PsdkBattleEffectStack(
            values: const <String>[PsdkBattleEffectIds.protect],
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 1));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 100);
      expect(player.effects.values, isEmpty);
      expect(
        result.timeline.events
            .where((event) => event.toJson()['moveId'] == 'opponent_tackle')
            .map((event) => event.kind),
        contains('move_failed'),
      );
    });

    test('Protect blocks an incoming status move that targets the user', () {
      final engine = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'opponent_growl',
            type: 'normal',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 100,
            battleEngineMethod: 's_status',
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final opponentEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'opponent_growl')
          .toList(growable: false);
      expect(opponentEvents.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
      ]);
      expect(opponentEvents.last.toJson()['reason'], 'protected');
    });

    test('Protect failure is visible when the user acts last', () {
      final engine = BattleEngine(
        setup: _setup(
          playerSpeed: 1,
          protectPriority: 0,
          opponentSpeed: 100,
          opponentMove: _move(
            id: 'opponent_quick_attack',
            type: 'normal',
            power: 40,
            priority: 1,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);
      final protectEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'protect')
          .toList(growable: false);

      expect(player.currentHp, lessThan(100));
      expect(player.moves[0].currentPp, 9);
      expect(player.moveHistory.lastMoveId, 'protect');
      expect(player.moveHistory.lastSuccessfulMoveId, isNull);
      expect(protectEvents.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_failed',
      ]);
      expect(protectEvents.last.toJson()['reason'], 'unusable_by_user');
    });

    test('type immunity is reported before Protect target prevention', () {
      final engine = BattleEngine(
        setup: _setup(
          playerTypes: const PsdkBattleTypes(primary: 'ground'),
          opponentMove: _move(
            id: 'opponent_thunder_shock',
            type: 'electric',
            category: PsdkBattleMoveCategory.special,
            power: 40,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final opponentEvents = result.timeline.events
          .where(
              (event) => event.toJson()['moveId'] == 'opponent_thunder_shock')
          .toList(growable: false);
      expect(opponentEvents.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_immune',
      ]);
      expect(
        opponentEvents.map((event) => event.kind),
        isNot(contains('move_failed')),
      );
    });

    test('a non-protectable move can pass through Protect', () {
      final engine = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'opponent_feint',
            type: 'normal',
            power: 40,
            protectable: false,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final opponentEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'opponent_feint')
          .toList(growable: false);
      expect(
        opponentEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
    });

    test('s_feint passes through Protect even when imported as protectable',
        () {
      final engine = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'feint',
            type: 'normal',
            power: 30,
            protectable: true,
            battleEngineMethod: 's_feint',
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final feintEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'feint')
          .toList(growable: false);

      expect(
        feintEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
      expect(
        feintEvents.map((event) => event.kind),
        isNot(contains('move_failed')),
      );
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
    });

    test('s_feint uses increased power against same-turn Protect', () {
      final feint = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'feint',
            type: 'normal',
            power: 30,
            protectable: true,
            battleEngineMethod: 's_feint',
          ),
        ),
      ).submit(const BattleDecision.fight(moveSlot: 0));
      final reference = BattleEngine(
        setup: _setup(
          opponentMove: _move(
            id: 'reference_hit',
            type: 'normal',
            power: 50,
            protectable: false,
          ),
        ),
      ).submit(const BattleDecision.fight(moveSlot: 0));

      expect(
        feint.state.battlerAt(psdkPlayerSlot).currentHp,
        reference.state.battlerAt(psdkPlayerSlot).currentHp,
      );
    });

    test('Endure lets a damaging move land but prevents the KO', () {
      final engine = BattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'endure',
              type: 'normal',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              pp: 10,
              priority: 4,
              battleEngineMethod: 's_protect',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
          opponentMove: _move(
            id: 'opponent_crush',
            type: 'normal',
            power: 600,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final opponentEvents = result.timeline.events
          .where((event) => event.toJson()['moveId'] == 'opponent_crush')
          .toList(growable: false);

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 1);
      expect(
        opponentEvents.map((event) => event.kind),
        containsAllInOrder(<String>[
          'move_pp_spent',
          'move_declared',
          'animation_cue',
          'damage',
        ]),
      );
      expect(
        opponentEvents.map((event) => event.kind),
        isNot(contains('move_failed')),
      );
    });
  });
}

BattleEngineSetup _setup({
  int playerSpeed = 1,
  int opponentSpeed = 100,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleEffectStack? playerEffects,
  List<PsdkBattleMoveData>? playerMoves,
  PsdkBattleMoveData? opponentMove,
  int protectPriority = 4,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speed: playerSpeed,
      types: playerTypes,
      effects: playerEffects,
      moves: playerMoves ??
          <PsdkBattleMoveData>[
            _move(
              id: 'protect',
              type: 'normal',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              pp: 10,
              priority: protectPriority,
              battleEngineMethod: 's_protect',
              target: PsdkBattleMoveTarget.user,
            ),
            _move(
              id: 'player_wait',
              type: 'normal',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_status',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: opponentSpeed,
      types: const PsdkBattleTypes(primary: 'normal'),
      moves: <PsdkBattleMoveData>[
        opponentMove ??
            _move(
              id: 'opponent_tackle',
              type: 'normal',
              power: 40,
            ),
      ],
    ),
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
  required int speed,
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int pp = 35,
  int priority = 0,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  bool protectable = true,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: pp,
    priority: priority,
    battleEngineMethod: battleEngineMethod,
    target: target,
    protectable: protectable,
  );
}
