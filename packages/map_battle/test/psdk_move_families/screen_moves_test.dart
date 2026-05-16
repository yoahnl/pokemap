import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK screen move families', () {
    test('Reflect reduces incoming physical damage on the protected bank', () {
      final baseline = _runTurn(
        playerMove: _move(
          id: 'player_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );
      final reflected = _runTurn(
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );

      final baselineDamage = _damage(baseline, moveId: 'opponent_tackle');
      final reflectedDamage = _damage(reflected, moveId: 'opponent_tackle');

      expect(reflectedDamage, baselineDamage ~/ 2);
    });

    test('Light Clay extends screen duration', () {
      final result = _runTurn(
        playerHeldItemId: 'light_clay',
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      final reflect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'reflect');

      expect(reflect.remainingTurns, 7);
    });

    test('Infiltrator bypasses screen damage reduction', () {
      final baseline = _runTurn(
        playerMove: _move(
          id: 'player_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentAbilityId: 'infiltrator',
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );
      final reflected = _runTurn(
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentAbilityId: 'infiltrator',
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 80,
        ),
      );

      expect(
        _damage(reflected, moveId: 'opponent_tackle'),
        _damage(baseline, moveId: 'opponent_tackle'),
      );
    });

    test('Light Screen reduces incoming special damage on the protected bank',
        () {
      final baseline = _runTurn(
        playerMove: _move(
          id: 'player_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
          target: PsdkBattleMoveTarget.self,
        ),
        opponentMove: _move(
          id: 'opponent_swift',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
      );
      final screened = _runTurn(
        playerMove: _move(
          id: 'light_screen',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_swift',
          category: PsdkBattleMoveCategory.special,
          power: 80,
        ),
      );

      expect(
        _damage(screened, moveId: 'opponent_swift'),
        _damage(baseline, moveId: 'opponent_swift') ~/ 2,
      );
    });

    test('Safeguard blocks slower opposing major status', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'safeguard',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_safe_guard',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'thunder_wave',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_status',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        result.timeline.events.whereType<PsdkBattleStatusEvent>(),
        isEmpty,
      );
    });

    test('Infiltrator bypasses Safeguard status prevention', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'safeguard',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_safe_guard',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentAbilityId: 'infiltrator',
        opponentMove: _move(
          id: 'thunder_wave',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_status',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleStatusEvent>(),
        hasLength(1),
      );
    });

    test('Safeguard blocks slower opposing Confusion', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'safeguard',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_safe_guard',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'confuse_ray',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_status',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus.volatile(
              status: PsdkBattleVolatileStatus.confusion,
              chance: 100,
            ),
          ],
        ),
      );

      expect(
        result.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains(PsdkBattleEffectIds.confusion),
        isFalse,
      );
    });

    test('side protection moves fail when already active', () {
      for (final entry in <({String method, String moveId, String effectId})>[
        (method: 's_safe_guard', moveId: 'safeguard', effectId: 'safeguard'),
        (method: 's_mist', moveId: 'mist', effectId: 'mist'),
        (
          method: 's_lucky_chant',
          moveId: 'lucky_chant',
          effectId: 'lucky_chant',
        ),
      ]) {
        final result = _runTurn(
          playerEffects: PsdkBattleEffectStack(
            effects: <BattleEffect>[
              GenericBattleEffect(
                id: entry.effectId,
                scope: const BankBattleEffectScope(0),
                remainingTurns: 3,
              ),
            ],
          ),
          playerMove: _move(
            id: entry.moveId,
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
            battleEngineMethod: entry.method,
            target: PsdkBattleMoveTarget.allAllies,
          ),
          opponentMove: _move(
            id: 'opponent_wait',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            accuracy: 0,
          ),
        );

        expect(
          result.timeline.events
              .whereType<PsdkBattleMoveFailedEvent>()
              .where((event) => event.moveId == entry.moveId),
          hasLength(1),
        );
        expect(
          result.state
              .battlerAt(psdkPlayerSlot)
              .effects
              .effects
              .singleWhere((effect) => effect.id == entry.effectId)
              .remainingTurns,
          2,
        );
      }
    });

    test('Mist protects its whole bank from opposing stat drops', () {
      const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'player',
              speed: 100,
              move: _move(id: 'splash', power: 0),
            ),
          ),
          allySlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'ally',
              speed: 90,
              move: _move(id: 'splash', power: 0),
              effects: const PsdkBattleEffectStack.empty().addEffect(
                const GenericBattleEffect(
                  id: 'mist',
                  scope: BankBattleEffectScope(0),
                ),
              ),
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent',
              speed: 1,
              move: _move(id: 'tail_whip', power: 0),
            ),
          ),
        },
      );

      final result = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
        stat: 'defense',
        stages: -1,
      );

      expect(result.applied, isFalse);
      expect(result.reason, 'mist');
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        0,
      );
    });

    test('s_baddy_bad damages then installs Reflect on the user bank', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'baddy_bad',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_baddy_bad',
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(_damage(result, moveId: 'baddy_bad'), greaterThan(0));
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('reflect'),
        isTrue,
      );
    });

    test('s_glitzy_glow damages then installs Light Screen with Light Clay',
        () {
      final result = _runTurn(
        playerHeldItemId: 'light_clay',
        playerMove: _move(
          id: 'glitzy_glow',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_glitzy_glow',
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      final lightScreen = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'light_screen');

      expect(_damage(result, moveId: 'glitzy_glow'), greaterThan(0));
      expect(lightScreen.remainingTurns, 7);
    });

    test('Aurora Veil fails without active snow or hail', () {
      final result = _runTurn(
        playerMove: _move(
          id: 'aurora_veil',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'aurora_veil'),
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).effects.contains('aurora_veil'),
        isFalse,
      );
    });

    test('screen moves fail when the same screen is already active', () {
      final result = _runTurn(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          GenericBattleEffect(
            id: 'reflect',
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            remainingTurns: 3,
          ),
        ),
        playerMove: _move(
          id: 'reflect',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_reflect',
          target: PsdkBattleMoveTarget.allAllies,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().single,
        isA<PsdkBattleMoveFailedEvent>()
            .having((event) => event.moveId, 'moveId', 'reflect'),
      );
      final reflect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'reflect');
      expect(reflect.remainingTurns, 2);
    });
  });
}

PsdkBattleTurnResult _runTurn({
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData opponentMove,
  String? playerHeldItemId,
  String? opponentAbilityId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        heldItemId: playerHeldItemId,
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove,
        abilityId: opponentAbilityId,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 0,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  String? heldItemId,
  String? abilityId,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
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
    heldItemId: heldItemId,
    abilityId: abilityId,
    moves: <PsdkBattleMoveData>[move],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
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
    statuses: statuses,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .single
      .damage;
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
