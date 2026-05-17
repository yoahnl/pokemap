import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Substitute and Focus Punch families', () {
    test('Substitute absorbs opposing damage before the user HP is touched',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
              _move(
                id: 'splash',
                battleEngineMethod: 's_splash',
                target: PsdkBattleMoveTarget.none,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'heavy_slam',
                battleEngineMethod: 's_basic',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.physical,
                power: 200,
                accuracy: 100,
              ),
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

      final afterSubstitute = engine.submit(
        const PsdkBattleDecision.fight(moveSlot: 0),
      );
      final player = afterSubstitute.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 75);
      expect(player.effects.contains('substitute'), isFalse);
      expect(
        _damage(afterSubstitute, moveId: 'heavy_slam'),
        greaterThanOrEqualTo(25),
      );
    });

    test('Substitute fails when the user max HP is below the PSDK cost floor',
        () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            maxHp: 3,
            currentHp: 3,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'splash',
                battleEngineMethod: 's_splash',
                target: PsdkBattleMoveTarget.none,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 3);
      expect(player.effects.contains('substitute'), isFalse);
      expect(_failed(result, moveId: 'substitute'), isTrue);
    });

    test('Substitute blocks opposing major status moves', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'toxic',
                battleEngineMethod: 's_status',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 100,
                statuses: <PsdkBattleMoveStatus>[
                  PsdkBattleMoveStatus(
                    status: PsdkBattleMajorStatus.toxic,
                    chance: 100,
                  ),
                ],
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 75);
      expect(player.majorStatus, isNull);
      expect(player.effects.contains('substitute'), isTrue);
      expect(_statusEvents(result, moveId: 'toxic'), isEmpty);
    });

    test('Substitute blocks regular opposing stat drops', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'tail_whip',
                battleEngineMethod: 's_stat',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 100,
                stageMods: const <PsdkBattleMoveStageMod>[
                  PsdkBattleMoveStageMod(
                    stat: 'defense',
                    stages: -1,
                    chance: 100,
                  ),
                ],
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.statStages.valueOf('defense'), 0);
      expect(_statEvents(result, stat: 'defense'), isEmpty);
    });

    test('Sound stat moves bypass Substitute', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'growl',
                battleEngineMethod: 's_stat',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 100,
                sound: true,
                stageMods: const <PsdkBattleMoveStageMod>[
                  PsdkBattleMoveStageMod(
                    stat: 'attack',
                    stages: -1,
                    chance: 100,
                  ),
                ],
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.statStages.valueOf('attack'), -1);
      expect(_statEvents(result, stat: 'attack'), hasLength(1));
      expect(player.effects.contains('substitute'), isTrue);
    });

    test('Infiltrator damage bypasses Substitute without breaking it', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'substitute',
                battleEngineMethod: 's_substitute',
                target: PsdkBattleMoveTarget.user,
                category: PsdkBattleMoveCategory.status,
                power: 0,
                accuracy: 0,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 1,
            abilityId: 'infiltrator',
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'shadow_sneak',
                battleEngineMethod: 's_basic',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.physical,
                power: 40,
                accuracy: 100,
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, lessThan(75));
      expect(player.effects.contains('substitute'), isTrue);
      expect(_damageEvents(result, moveId: 'shadow_sneak'), hasLength(1));
    });

    test('Focus Punch fails when the user was damaged earlier this turn', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speed: 1,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'focus_punch',
                battleEngineMethod: 's_focus_punch',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.physical,
                power: 150,
                accuracy: 100,
                priority: -3,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speed: 100,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'opponent_tackle',
                battleEngineMethod: 's_basic',
                target: PsdkBattleMoveTarget.adjacentFoe,
                category: PsdkBattleMoveCategory.physical,
                power: 40,
                accuracy: 100,
              ),
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

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(result, moveId: 'opponent_tackle'), hasLength(1));
      expect(_damageEvents(result, moveId: 'focus_punch'), isEmpty);
      expect(_failed(result, moveId: 'focus_punch'), isTrue);
    });
  });
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
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

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required List<PsdkBattleMoveData> moves,
  int maxHp = 100,
  int currentHp = 100,
  String? abilityId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    abilityId: abilityId,
    moves: moves,
  );
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}

PsdkBattleMoveData _move({
  required String id,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
  required PsdkBattleMoveCategory category,
  required int power,
  required int accuracy,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
  int priority = 0,
  bool sound = false,
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
    criticalRate: 1,
    statuses: statuses,
    stageMods: stageMods,
    sound: sound,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

List<PsdkBattleStatusEvent> _statusEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatusEvent>()
      .where((event) => event.moveId == moveId)
      .toList();
}

List<PsdkBattleStatStageEvent> _statEvents(
  PsdkBattleTurnResult result, {
  required String stat,
}) {
  return result.timeline.events
      .whereType<PsdkBattleStatStageEvent>()
      .where((event) => event.stat == stat)
      .toList();
}
