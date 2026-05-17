import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK trapping move families', () {
    test('s_cantflee installs a switch-prevention effect on the target', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'mean_look',
              battleEngineMethod: 's_cantflee',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final opponent = turn.state.battlerAt(psdkOpponentSlot);
      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: turn.state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );

      expect(opponent.effects.contains('cant_switch'), isTrue);
      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'cant_switch');
    });

    test('s_jaw_lock installs switch-prevention effects on user and target',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'jaw_lock',
              battleEngineMethod: 's_jaw_lock',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 80,
              accuracy: 100,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = turn.state.battlerAt(psdkPlayerSlot);
      final opponent = turn.state.battlerAt(psdkOpponentSlot);

      expect(_damageEvents(turn, moveId: 'jaw_lock'), hasLength(1));
      expect(player.effects.contains('cant_switch'), isTrue);
      expect(opponent.effects.contains('cant_switch'), isTrue);
      expect(player.effects.effects.whereType<CantSwitchEffect>().single.origin,
          psdkPlayerSlot);
      expect(
          opponent.effects.effects.whereType<CantSwitchEffect>().single.origin,
          psdkPlayerSlot);
    });

    test('CantSwitch transfers through Baton Pass', () {
      const benchSlot = PsdkBattleSlotRef(bank: 1, position: -1);
      final stack = const PsdkBattleEffectStack.empty()
          .addEffect(
            const BatonPassEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
            ),
          )
          .addEffect(
            const CantSwitchEffect(
              scope: BattlerBattleEffectScope(psdkOpponentSlot),
              origin: psdkPlayerSlot,
            ),
          );

      final transferred = stack.batonPassTransferEffects(
        source: psdkOpponentSlot,
        target: benchSlot,
      );

      expect(transferred.values, <String>['cant_switch']);
      expect(
        transferred.effects.single,
        isA<CantSwitchEffect>()
            .having(
              (effect) => (effect.scope as BattlerBattleEffectScope).slot,
              'scope slot',
              benchSlot,
            )
            .having((effect) => effect.origin, 'origin', psdkPlayerSlot),
      );
    });

    test('CantSwitch no longer prevents switching when its origin fainted', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'origin',
              speed: 100,
              currentHp: 0,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'trapped',
              speed: 1,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ).copyWith(
            effects: const PsdkBattleEffectStack.empty().addEffect(
              const CantSwitchEffect(
                scope: BattlerBattleEffectScope(psdkOpponentSlot),
                origin: psdkPlayerSlot,
              ),
            ),
          ),
        },
      );

      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );

      expect(prevention.applied, isTrue);
      expect(prevention.reason, isNull);
    });

    test('CantSwitch clears during end turn when its origin fainted', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'origin',
              speed: 100,
              currentHp: 0,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'trapped',
              speed: 1,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ).copyWith(
            effects: const PsdkBattleEffectStack.empty().addEffect(
              const CantSwitchEffect(
                scope: BattlerBattleEffectScope(psdkOpponentSlot),
                origin: psdkPlayerSlot,
              ),
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        ),
      );

      expect(result.applied, isTrue);
      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains(
              PsdkBattleEffectIds.cantSwitch,
            ),
        isFalse,
      );
    });

    test('s_bind installs a timed trapping effect with residual damage', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'bind',
              battleEngineMethod: 's_bind',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 15,
              accuracy: 100,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final trapped = turn.state.battlerAt(psdkOpponentSlot);
      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: turn.state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );
      expect(trapped.effects.contains('bind'), isTrue);
      expect(
          trapped.effects.effects.singleWhere((effect) => effect.id == 'bind'),
          isA<BindEffect>().having(
            (effect) => effect.remainingTurns,
            'remaining turns',
            inInclusiveRange(3, 4),
          ));
      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'bind');
      expect(
        turn.timeline.events
            .whereType<PsdkBattleDamageEvent>()
            .singleWhere((event) => event.moveId == 'effect:bind')
            .damage,
        12,
      );
    });

    test('s_roar marks the target for a forced switch request', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'roar',
              battleEngineMethod: 's_roar',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(turn.state.battlerAt(psdkOpponentSlot).switching, isTrue);
    });

    test('s_roar does not force switch when the target has no replacement', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          includeOpponentReserve: false,
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'roar',
              battleEngineMethod: 's_roar',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(turn.state.battlerAt(psdkOpponentSlot).switching, isFalse);
    });

    test('s_dragon_tail damages then marks the target for forced switch', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'dragon_tail',
              battleEngineMethod: 's_dragon_tail',
              target: PsdkBattleMoveTarget.adjacentFoe,
              category: PsdkBattleMoveCategory.physical,
              power: 60,
              accuracy: 100,
            ),
          ],
        ),
      );

      final turn = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(turn, moveId: 'dragon_tail'), hasLength(1));
      expect(turn.state.battlerAt(psdkOpponentSlot).switching, isTrue);
    });
  });
}

PsdkBattleSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  bool includeOpponentReserve = true,
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
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'splash',
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.none,
        ),
      ],
    ),
    opponentReserves: includeOpponentReserve
        ? <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'opponent-reserve',
              speed: 50,
              moves: <PsdkBattleMoveData>[
                _move(
                  id: 'splash',
                  battleEngineMethod: 's_splash',
                  target: PsdkBattleMoveTarget.none,
                ),
              ],
            ),
          ]
        : const <PsdkBattleCombatantSetup>[],
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
  int currentHp = 100,
  required List<PsdkBattleMoveData> moves,
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
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
