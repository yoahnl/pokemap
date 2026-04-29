import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK switch-effect move families', () {
    test('s_baton_pass marks the user for a Baton Pass switch request', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'baton_pass',
              battleEngineMethod: 's_baton_pass',
              target: PsdkBattleMoveTarget.user,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.switching, isTrue);
      expect(player.effects.contains('baton_pass'), isTrue);
      expect(
        player.effects.effects.singleWhere(
          (effect) => effect.id == 'baton_pass',
        ),
        isA<BatonPassEffect>(),
      );
    });

    test('s_u_turn damages the target then marks the user for switch', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 100,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final damage =
          result.timeline.events.whereType<PsdkBattleDamageEvent>().toList();

      expect(damage, hasLength(1));
      expect(damage.single.target, psdkOpponentSlot);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
    });

    test('s_u_turn does not mark the user for switch when it misses', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'u_turn',
              battleEngineMethod: 's_u_turn',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 70,
              accuracy: 1,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>(),
        isEmpty,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });

    test('s_volt_switch and s_flip_turn damage then mark the user for switch',
        () {
      for (final entry in const <({String method, String moveId})>[
        (method: 's_volt_switch', moveId: 'volt_switch'),
        (method: 's_flip_turn', moveId: 'flip_turn'),
      ]) {
        final engine = PsdkBattleEngine(
          setup: _setup(
            playerMoves: <PsdkBattleMoveData>[
              _move(
                id: entry.moveId,
                battleEngineMethod: entry.method,
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.special,
                power: 70,
                accuracy: 100,
              ),
            ],
          ),
        );

        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
        final damage =
            result.timeline.events.whereType<PsdkBattleDamageEvent>().toList();

        expect(damage, hasLength(1), reason: entry.method);
        expect(damage.single.target, psdkOpponentSlot, reason: entry.method);
        expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue,
            reason: entry.method);
      }
    });

    test('s_volt_switch and s_flip_turn do not switch when they miss', () {
      for (final entry in const <({String method, String moveId})>[
        (method: 's_volt_switch', moveId: 'volt_switch'),
        (method: 's_flip_turn', moveId: 'flip_turn'),
      ]) {
        final engine = PsdkBattleEngine(
          setup: _setup(
            playerMoves: <PsdkBattleMoveData>[
              _move(
                id: entry.moveId,
                battleEngineMethod: entry.method,
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.special,
                power: 70,
                accuracy: 1,
              ),
            ],
          ),
        );

        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

        expect(
            result.timeline.events.whereType<PsdkBattleDamageEvent>(), isEmpty,
            reason: entry.method);
        expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse,
            reason: entry.method);
      }
    });

    test('s_parting_shot marks the user for switch after offensive drops', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'parting_shot',
              battleEngineMethod: 's_parting_shot',
              target: PsdkBattleMoveTarget.adjacentFoe,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'attack',
                  stages: -1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: -1,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -1);
      expect(opponent.statStages.valueOf('specialAttack'), -1);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isTrue);
    });

    test('s_parting_shot does not mark the user when drops cannot apply', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentStatStages: PsdkBattleStatStages(
            values: const <String, int>{
              'attack': -6,
              'specialAttack': -6,
            },
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'parting_shot',
              battleEngineMethod: 's_parting_shot',
              target: PsdkBattleMoveTarget.adjacentFoe,
              stageMods: const <PsdkBattleMoveStageMod>[
                PsdkBattleMoveStageMod(
                  stat: 'attack',
                  stages: -1,
                  chance: 100,
                ),
                PsdkBattleMoveStageMod(
                  stat: 'specialAttack',
                  stages: -1,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = result.state.battlerAt(psdkOpponentSlot);

      expect(opponent.statStages.valueOf('attack'), -6);
      expect(opponent.statStages.valueOf('specialAttack'), -6);
      expect(result.state.battlerAt(psdkPlayerSlot).switching, isFalse);
    });
  });
}

PsdkBattleSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleStatStages? opponentStatStages,
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      moves: playerMoves,
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      statStages: opponentStatStages,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'splash',
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.none,
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
  required List<PsdkBattleMoveData> moves,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    statStages: statStages ?? PsdkBattleStatStages.neutral(),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.status,
  int power = 0,
  int accuracy = 0,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    stageMods: stageMods,
  );
}
