import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK action queue', () {
    test('orders switch actions before regular fight actions', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(
            user: psdkPlayerSlot,
            moveId: 'quick_attack',
            priority: 1,
            speed: 200,
          ),
          const PsdkBattleSwitchAction(
            user: psdkOpponentSlot,
            partyIndex: 1,
          ),
        ],
      ).ordered(rng: _rng(), rules: _rules).actions;

      expect(ordered.first.kind, PsdkBattleActionKind.switchPokemon);
      expect(ordered.last.kind, PsdkBattleActionKind.fight);
    });

    test('orders fight actions by move priority then speed', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(
            user: psdkPlayerSlot,
            moveId: 'tackle',
            priority: 0,
            speed: 200,
          ),
          _fight(
            user: psdkOpponentSlot,
            moveId: 'quick_attack',
            priority: 1,
            speed: 1,
          ),
        ],
      ).ordered(rng: _rng(), rules: _rules).actions;

      expect((ordered.first as PsdkBattleFightAction).move.id, 'quick_attack');
      expect((ordered.last as PsdkBattleFightAction).move.id, 'tackle');
    });

    test('reverses speed only under Trick Room', () {
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'fast', speed: 100),
          _fight(user: psdkOpponentSlot, moveId: 'slow', speed: 1),
        ],
      ).ordered(rng: _rng(), rules: _rules, trickRoom: true).actions;

      expect((ordered.first as PsdkBattleFightAction).move.id, 'slow');
      expect((ordered.last as PsdkBattleFightAction).move.id, 'fast');
    });

    test('uses the ruleset RNG for exact fight ties', () {
      final result = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'player_tackle', speed: 50),
          _fight(user: psdkOpponentSlot, moveId: 'opponent_tackle', speed: 50),
        ],
      ).ordered(
        rng: _rng(genericSeed: 0),
        rules: _rules,
      );

      expect(result.actions.first.user, psdkOpponentSlot);
      expect(result.actions.last.user, psdkPlayerSlot);
      expect(result.rng.generic.seed, 1013904223);

      final opposite = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'player_tackle', speed: 50),
          _fight(user: psdkOpponentSlot, moveId: 'opponent_tackle', speed: 50),
        ],
      ).ordered(
        rng: _rng(genericSeed: 1),
        rules: _rules,
      );
      expect(opposite.actions.first.user, psdkPlayerSlot);
      expect(opposite.rng.generic.seed, 1015568748);
    });

    test('the same seed replays the identical order and RNG state', () {
      // Le départage seedé n'a de valeur que s'il rejoue à l'identique : sans
      // cette garantie, un replay de combat divergerait au premier tour où
      // deux actions sont à égalité exacte.
      List<Object> run() {
        final result = PsdkBattleActionQueue(
          actions: <PsdkBattleAction>[
            _fight(user: psdkPlayerSlot, moveId: 'player_tackle', speed: 50),
            _fight(user: psdkOpponentSlot, moveId: 'opponent_tackle', speed: 50),
          ],
        ).ordered(rng: _rng(genericSeed: 7), rules: _rules);
        return <Object>[
          result.actions.first.user,
          result.actions.last.user,
          result.rng.generic.seed,
        ];
      }

      expect(run(), run());
    });

    test('an exact tie consumes exactly one generic draw', () {
      // Le compte de tirages est l'invariant qui rend le replay possible. On le
      // compare à un unique resolvePsdkSpeedTie depuis le même état : deux
      // tirages, ou zéro, désynchroniseraient tout ce qui suit dans le tour.
      final start = _rng(genericSeed: 7);
      final singleDraw = _rules.resolvePsdkSpeedTie(start);

      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'player_tackle', speed: 50),
          _fight(user: psdkOpponentSlot, moveId: 'opponent_tackle', speed: 50),
        ],
      ).ordered(rng: start, rules: _rules);

      expect(
        ordered.rng.generic.seed,
        singleDraw.nextRng.generic.seed,
        reason: 'ordering must advance the generic stream by one draw, no more',
      );
    });

    test('no tie consumes no generic draw at all', () {
      // Deux cas où il n'y a pas d'égalité exacte : vitesses différentes, et
      // vitesses égales mais priorités différentes. Consommer un tirage dans
      // l'un ou l'autre ferait dériver le RNG à chaque tour d'un combat
      // pourtant sans égalité.
      final start = _rng(genericSeed: 7);

      final differentSpeed = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'fast', speed: 100),
          _fight(user: psdkOpponentSlot, moveId: 'slow', speed: 20),
        ],
      ).ordered(rng: start, rules: _rules);

      final differentPriority = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(
            user: psdkPlayerSlot,
            moveId: 'tackle',
            priority: 0,
            speed: 50,
          ),
          _fight(
            user: psdkOpponentSlot,
            moveId: 'quick_attack',
            priority: 1,
            speed: 50,
          ),
        ],
      ).ordered(rng: start, rules: _rules);

      expect(differentSpeed.rng.generic.seed, start.generic.seed);
      expect(
        differentPriority.rng.generic.seed,
        start.generic.seed,
        reason: 'equal speed with unequal priority is not a tie',
      );
    });

    test('inserts slower allied Round immediately after the first allied Round',
        () {
      const playerAllySlot = PsdkBattleSlotRef(bank: 0, position: 1);
      final ordered = PsdkBattleActionQueue(
        actions: <PsdkBattleAction>[
          _fight(user: psdkPlayerSlot, moveId: 'round_fast', speed: 100),
          _fight(user: playerAllySlot, moveId: 'round_slow', speed: 20),
          _fight(user: psdkOpponentSlot, moveId: 'opponent_fast', speed: 90),
        ],
      ).ordered(rng: _rng(), rules: _rules).actions;

      expect(
        ordered.map((action) => (action as PsdkBattleFightAction).move.id),
        <String>['round_fast', 'round_slow', 'opponent_fast'],
      );
    });

    test('defers a pending opened Shell Trap action behind remaining actions',
        () {
      final actions = <PsdkBattleAction>[
        _fight(
          user: psdkOpponentSlot,
          moveId: 'opener',
          speed: 100,
        ),
        _fight(
          user: psdkPlayerSlot,
          moveId: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          speed: 90,
        ),
        _fight(
          user: const PsdkBattleSlotRef(bank: 1, position: 1),
          moveId: 'later_action',
          speed: 80,
        ),
      ];

      final deferred = PsdkBattleActionQueue.deferPendingShellTrapActionToEnd(
        actions: actions,
        currentIndex: 0,
        user: psdkPlayerSlot,
      );

      expect(
        deferred.map((action) => (action as PsdkBattleFightAction).move.id),
        <String>['opener', 'later_action', 'shell_trap'],
      );
      expect(
        actions.map((action) => (action as PsdkBattleFightAction).move.id),
        <String>['opener', 'shell_trap', 'later_action'],
      );
    });

    test('decision mapper builds a fight action from PSDK state', () {
      final state = PsdkBattleState.fromSetup(_setup());

      final action = const PsdkBattleActionDecisionMapper().map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleDecision.fight(moveSlot: 0),
      );

      expect(action, isA<PsdkBattleFightAction>());
      final fight = action as PsdkBattleFightAction;
      expect(fight.user, psdkPlayerSlot);
      expect(fight.target, psdkOpponentSlot);
      expect(fight.move.id, 'tackle');
      expect(fight.speed, 50);
    });

    test('decision mapper accepts an all-adjacent move in singles', () {
      final state = PsdkBattleState.fromSetup(
        _setup(playerMoveTarget: PsdkBattleMoveTarget.allAdjacent),
      );

      final action = const PsdkBattleActionDecisionMapper().map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleDecision.fight(moveSlot: 0),
      );

      expect(action, isA<PsdkBattleFightAction>());
      expect((action as PsdkBattleFightAction).target, psdkOpponentSlot);
      expect(action.move.target, PsdkBattleMoveTarget.allAdjacent);
    });
  });
}

PsdkBattleFightAction _fight({
  required PsdkBattleSlotRef user,
  required String moveId,
  int priority = 0,
  int speed = 50,
  String? battleEngineMethod,
}) {
  return PsdkBattleFightAction(
    user: user,
    target: user == psdkPlayerSlot ? psdkOpponentSlot : psdkPlayerSlot,
    moveSlot: 0,
    move: _move(
      id: moveId,
      priority: priority,
      battleEngineMethod: battleEngineMethod ??
          (moveId.startsWith('round') ? 's_round' : 's_basic'),
    ),
    speed: speed,
  );
}

final _rules = PokemonBattleRules.fromProfile(
  PokemonRulesetProfile.pokeMapBetaV1,
);

BattleRngStreams _rng({int genericSeed = 1}) {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 1,
    moveAccuracySeed: 1,
    genericSeed: genericSeed,
  );
}

PsdkBattleSetup _setup({
  PsdkBattleMoveTarget playerMoveTarget = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      speed: 50,
      moveTarget: playerMoveTarget,
    ),
    opponent: _combatant(id: 'opponent', speed: 20),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 1,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  PsdkBattleMoveTarget moveTarget = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 20,
      defense: 20,
      specialAttack: 20,
      specialDefense: 20,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[
      _move(id: 'tackle', target: moveTarget),
    ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  int priority = 0,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: priority,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}
