import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK delayed attack move families', () {
    test('Future Sight damages the targeted position after its countdown', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'future_sight',
                type: 'psychic',
                category: PsdkBattleMoveCategory.special,
                power: 120,
                accuracy: 100,
                battleEngineMethod: 's_future_sight',
              ),
              _move(id: 'wait'),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'opponent_wait'),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      expect(_damageEvents(first, moveId: 'future_sight'), isEmpty);
      expect(
        first.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isTrue,
      );

      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      expect(_damageEvents(second, moveId: 'future_sight'), isEmpty);
      expect(
        second.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isTrue,
      );

      final third = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));
      final delayedDamage = _damageEvents(third, moveId: 'future_sight');

      expect(delayedDamage, hasLength(1));
      expect(delayedDamage.single.target, psdkOpponentSlot);
      expect(delayedDamage.single.damage, greaterThan(0));
      expect(
        third.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isFalse,
      );
    });

    test('Future Sight fails while the targeted position already has one', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'future_sight',
                type: 'psychic',
                category: PsdkBattleMoveCategory.special,
                power: 120,
                accuracy: 100,
                battleEngineMethod: 's_future_sight',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(id: 'opponent_wait'),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final blocked =
          engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      final failures = blocked.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .where((event) => event.moveId == 'future_sight')
          .toList();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'future_sight_already_active');
    });

    test('Future Sight stays on the target slot through replacement', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'future_sight',
                type: 'psychic',
                category: PsdkBattleMoveCategory.special,
                power: 120,
                accuracy: 100,
                battleEngineMethod: 's_future_sight',
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );
      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponentReserve = PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent-reserve',
          speed: 1,
          moves: <PsdkBattleMoveData>[_move(id: 'reserve_wait')],
        ),
      );

      final switched = const BattleSwitchHandler().switchCombatant(
        context: BattleHandlerContext(
          state: first.state.copyWith(
            parties: <int, List<PsdkBattleCombatant>>{
              0: first.state.partyForBank(0),
              1: <PsdkBattleCombatant>[
                first.state.battlerAt(psdkOpponentSlot),
                opponentReserve,
              ],
            },
          ),
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 1,
            genericSeed: 1,
          ),
          turn: 2,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
        partyIndex: 1,
      );

      expect(
        switched.state.battlerAt(psdkOpponentSlot).effects.contains(
              'future_sight',
            ),
        isTrue,
      );
    });

    test('Wish heals the replacement occupying the original slot', () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'wish',
                battleEngineMethod: 's_wish',
                target: PsdkBattleMoveTarget.user,
              ),
            ],
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player-reserve',
              speed: 100,
              currentHp: 20,
              moves: <PsdkBattleMoveData>[_move(id: 'reserve_wait')],
            ),
          ],
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      engine.submit(const BattleDecision.fight(moveSlot: 0));
      final healed = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      expect(healed.state.battlerAt(psdkPlayerSlot).id, 'player-reserve');
      expect(healed.state.battlerAt(psdkPlayerSlot).currentHp, 70);
      expect(_healEvents(healed, moveId: 'wish'), hasLength(1));
    });

    test('Wish fails while a previous Wish is still active on the slot', () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'wish',
                battleEngineMethod: 's_wish',
                target: PsdkBattleMoveTarget.user,
              ),
              _move(id: 'wait'),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      expect(first.state.battlerAt(psdkPlayerSlot).effects.contains('wish'), isTrue);
      final blocked = engine.submit(const BattleDecision.fight(moveSlot: 0));

      final failures = blocked.timeline.events
          .whereType<BattleMoveFailedTimelineEvent>()
          .where((event) => event.moveId == 'wish')
          .toList(growable: false);
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'wish_already_active');
    });

    test('Healing Wish restores the next replacement HP and status', () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'healing_wish',
                battleEngineMethod: 's_healing_wish',
                target: PsdkBattleMoveTarget.user,
              ),
            ],
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player-reserve',
              speed: 100,
              currentHp: 20,
              majorStatus: PsdkBattleMajorStatus.burn,
              moves: <PsdkBattleMoveData>[_move(id: 'reserve_wait')],
            ),
          ],
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final sacrifice = engine.submit(const BattleDecision.fight(moveSlot: 0));
      expect(sacrifice.state.battlerAt(psdkPlayerSlot).currentHp, 0);

      final switched = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );
      final replacement = switched.state.battlerAt(psdkPlayerSlot);

      expect(replacement.id, 'player-reserve');
      expect(replacement.currentHp, replacement.maxHp);
      expect(replacement.majorStatus, isNull);
    });

    test('Healing Wish fails when no replacement is available', () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'healing_wish',
                battleEngineMethod: 's_healing_wish',
                target: PsdkBattleMoveTarget.user,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final failures = result.timeline.events
          .whereType<BattleMoveFailedTimelineEvent>()
          .where((event) => event.moveId == 'healing_wish')
          .toList(growable: false);

      expect(failures, hasLength(1));
      expect(failures.single.reason, 'no_replacement');
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('Lunar Dance restores PP to the next replacement', () {
      final engine = BattleEngine.fromPsdk(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'lunar_dance',
                battleEngineMethod: 's_lunar_dance',
                target: PsdkBattleMoveTarget.user,
              ),
            ],
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player-reserve',
              speed: 100,
              currentHp: 20,
              majorStatus: PsdkBattleMajorStatus.burn,
              moves: <PsdkBattleMoveData>[
                _move(id: 'reserve_wait', pp: 20, currentPp: 3),
              ],
            ),
          ],
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[_move(id: 'opponent_wait')],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 1,
            generic: 1,
          ),
        ),
      );

      final sacrifice = engine.submit(const BattleDecision.fight(moveSlot: 0));
      expect(sacrifice.state.battlerAt(psdkPlayerSlot).currentHp, 0);

      final switched = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );
      final replacement = switched.state.battlerAt(psdkPlayerSlot);

      expect(replacement.id, 'player-reserve');
      expect(replacement.currentHp, replacement.maxHp);
      expect(replacement.majorStatus, isNull);
      expect(replacement.moves.single.currentPp, replacement.moves.single.pp);
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  int currentHp = 100,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    majorStatus: majorStatus,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.status,
  int power = 0,
  int accuracy = 0,
  int pp = 10,
  int? currentPp,
  String battleEngineMethod = 's_splash',
  PsdkBattleMoveTarget? target,
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
    currentPp: currentPp ?? pp,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target ??
        (category == PsdkBattleMoveCategory.status
            ? PsdkBattleMoveTarget.user
            : PsdkBattleMoveTarget.adjacentFoe),
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList();
}

List<PsdkBattleHealEvent> _healEvents(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return result.timeline.psdkTimeline.events
      .whereType<PsdkBattleHealEvent>()
      .where((event) => event.moveId == moveId)
      .toList();
}
