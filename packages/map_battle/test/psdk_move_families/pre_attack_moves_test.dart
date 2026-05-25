import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK pre-attack moves', () {
    test('s_pre_attack_base keeps the normal damage body', () {
      final result = _runPreAttackTurn(
        playerMove: _move(
          id: 'pre_attack_base',
          battleEngineMethod: 's_pre_attack_base',
          category: PsdkBattleMoveCategory.physical,
          power: 60,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      expect(_damageEvents(result, moveId: 'pre_attack_base'), hasLength(1));
      expect(_failed(result, moveId: 'pre_attack_base'), isFalse);
    });

    test('s_beak_blast burns a faster contact attacker before moving', () {
      final result = _runPreAttackTurn(
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_scratch',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_scratch'), hasLength(1));
      expect(_damageEvents(result, moveId: 'beak_blast'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
      expect(_statusEvents(result, moveId: 'effect:beak_blast'), hasLength(1));
    });

    test('s_beak_blast ignores faster non-contact damage', () {
      final result = _runPreAttackTurn(
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_swift',
          category: PsdkBattleMoveCategory.special,
          power: 30,
          contact: false,
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_swift'), hasLength(1));
      expect(_damageEvents(result, moveId: 'beak_blast'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(_statusEvents(result, moveId: 'effect:beak_blast'), isEmpty);
    });

    test('s_beak_blast does not burn after the user already moved', () {
      final result = _runPreAttackTurn(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_revenge_contact',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          priority: -6,
          contact: true,
        ),
      );

      expect(_damageEvents(result, moveId: 'beak_blast'), hasLength(1));
      expect(
        _damageEvents(result, moveId: 'opponent_revenge_contact'),
        hasLength(1),
      );
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(_statusEvents(result, moveId: 'effect:beak_blast'), isEmpty);
    });

    test('s_beak_blast does not prepare while asleep', () {
      final result = _runPreAttackTurn(
        playerStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_scratch',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_scratch'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(_statusEvents(result, moveId: 'effect:beak_blast'), isEmpty);
    });

    test('s_beak_blast respects Reflect on the target bank', () {
      final baseline = _runPreAttackTurn(
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );
      final reflected = _runPreAttackTurn(
        opponentEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            GenericBattleEffect(
              id: 'reflect',
              scope: BankBattleEffectScope(1),
            ),
          ],
        ),
        playerMove: _move(
          id: 'beak_blast',
          battleEngineMethod: 's_beak_blast',
          category: PsdkBattleMoveCategory.physical,
          power: 100,
          priority: -3,
          ballistics: true,
        ),
        opponentMove: _move(
          id: 'opponent_wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
        ),
      );

      final baselineDamage =
          _damageEvents(baseline, moveId: 'beak_blast').single.damage;
      final reflectedDamage =
          _damageEvents(reflected, moveId: 'beak_blast').single.damage;

      expect(reflectedDamage, baselineDamage ~/ 2);
    });

    test('s_shell_trap fails if no opposing physical damage opened the trap',
        () {
      final result = _runPreAttackTurn(
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_ember',
          category: PsdkBattleMoveCategory.special,
          power: 30,
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_ember'), hasLength(1));
      expect(_damageEvents(result, moveId: 'shell_trap'), isEmpty);
      expect(_failed(result, moveId: 'shell_trap'), isTrue);
    });

    test('s_shell_trap attacks after opposing physical damage opened the trap',
        () {
      final result = _runPreAttackTurn(
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_tackle'), hasLength(1));
      expect(_damageEvents(result, moveId: 'shell_trap'), hasLength(1));
      expect(_failed(result, moveId: 'shell_trap'), isFalse);
    });

    test('s_shell_trap stays closed after a Sheer Force boosted hit', () {
      final result = _runPreAttackTurn(
        opponentAbilityId: 'sheer_force',
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_fire_fang',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_fire_fang'), hasLength(1));
      expect(_damageEvents(result, moveId: 'shell_trap'), isEmpty);
      expect(_failed(result, moveId: 'shell_trap'), isTrue);
    });

    test('s_shell_trap stays closed after a Sheer Force flinch hit', () {
      final result = _runPreAttackTurn(
        opponentAbilityId: 'sheer_force',
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_bite',
          category: PsdkBattleMoveCategory.physical,
          power: 60,
          contact: true,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus.volatile(
              status: PsdkBattleVolatileStatus.flinch,
              chance: 100,
            ),
          ],
        ),
      );

      expect(_damageEvents(result, moveId: 'opponent_bite'), hasLength(1));
      expect(_damageEvents(result, moveId: 'shell_trap'), isEmpty);
      expect(_failed(result, moveId: 'shell_trap'), isTrue);
    });

    test('s_shell_trap respects Light Screen on the target bank', () {
      final baseline = _runPreAttackTurn(
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
        ),
      );
      final screened = _runPreAttackTurn(
        opponentEffects: PsdkBattleEffectStack(
          effects: const <BattleEffect>[
            GenericBattleEffect(
              id: 'light_screen',
              scope: BankBattleEffectScope(1),
            ),
          ],
        ),
        playerMove: _move(
          id: 'shell_trap',
          battleEngineMethod: 's_shell_trap',
          category: PsdkBattleMoveCategory.special,
          power: 150,
          priority: -3,
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          category: PsdkBattleMoveCategory.physical,
          power: 30,
          contact: true,
        ),
      );

      final baselineDamage =
          _damageEvents(baseline, moveId: 'shell_trap').single.damage;
      final screenedDamage =
          _damageEvents(screened, moveId: 'shell_trap').single.damage;

      expect(screenedDamage, baselineDamage ~/ 2);
    });
  });
}

PsdkBattleTurnResult _runPreAttackTurn({
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData opponentMove,
  int playerSpeed = 1,
  int opponentSpeed = 100,
  PsdkBattleMajorStatus? playerStatus,
  String? opponentAbilityId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        moves: <PsdkBattleMoveData>[playerMove],
        majorStatus: playerStatus,
        effects: playerEffects,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        moves: <PsdkBattleMoveData>[opponentMove],
        abilityId: opponentAbilityId,
        effects: opponentEffects,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 1,
        generic: 1,
      ),
    ),
  );

  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  String? abilityId,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleMajorStatus? majorStatus,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
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
    abilityId: abilityId,
    majorStatus: majorStatus,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  required PsdkBattleMoveCategory category,
  required int power,
  int accuracy = 100,
  int priority = 0,
  bool contact = false,
  bool ballistics = false,
  int? effectChance,
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
    priority: priority,
    effectChance: effectChance,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    contact: contact,
    ballistics: ballistics,
    statuses: statuses,
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

List<PsdkBattleStatusEvent> _statusEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

bool _failed(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
