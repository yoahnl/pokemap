import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Transform move family', () {
    test('s_transform copies target battle form, stats, stages and moves', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speciesId: 'ditto',
            displayName: 'Ditto',
            abilityId: 'limber',
            currentHp: 37,
            speed: 100,
            types: const PsdkBattleTypes(primary: 'normal'),
            stats: const PsdkBattleStats(
              attack: 10,
              defense: 12,
              specialAttack: 14,
              specialDefense: 16,
              speed: 100,
            ),
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'transform',
                battleEngineMethod: 's_transform',
                target: PsdkBattleMoveTarget.adjacentFoe,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speciesId: 'vaporeon',
            displayName: 'Vaporeon',
            abilityId: 'water_absorb',
            speed: 1,
            types: const PsdkBattleTypes(primary: 'water'),
            stats: const PsdkBattleStats(
              attack: 65,
              defense: 60,
              specialAttack: 110,
              specialDefense: 95,
              speed: 65,
            ),
            statStages: PsdkBattleStatStages(
              values: const <String, int>{
                'attack': 2,
                'speed': -1,
              },
            ),
            currentWeightKg: 29,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'splash',
                battleEngineMethod: 's_splash',
                target: PsdkBattleMoveTarget.none,
              ),
              _move(
                id: 'water_gun',
                battleEngineMethod: 's_basic',
                category: PsdkBattleMoveCategory.special,
                power: 40,
                type: 'water',
                target: PsdkBattleMoveTarget.adjacentFoe,
              ),
            ],
          ),
          rngSeeds: const PsdkBattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 3,
            generic: 4,
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.speciesId, 'vaporeon');
      expect(player.displayName, 'Vaporeon');
      expect(player.abilityId, 'water_absorb');
      expect(player.types.primary, 'water');
      expect(player.types.secondary, isNull);
      expect(player.stats.specialAttack, 110);
      expect(player.statStages.valueOf('attack'), 2);
      expect(player.statStages.valueOf('speed'), -1);
      expect(player.currentHp, 37);
      expect(player.level, 20);
      expect(player.currentWeightKg, 29);
      expect(player.transformState.isTransformed, isTrue);
      expect(player.transformState.transformedFromSpeciesId, 'ditto');
      expect(player.effects.contains('transform'), isTrue);
      expect(player.moves.map((move) => move.id), <String>[
        'splash',
        'water_gun',
      ]);
      expect(player.moves.every((move) => move.pp == 5), isTrue);
      expect(player.moves.every((move) => move.currentPp == 5), isTrue);
    });

    test('s_transform fails against a target that is already transformed', () {
      final engine = PsdkBattleEngine(
        setup: PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player',
            speciesId: 'ditto',
            displayName: 'Ditto',
            abilityId: 'limber',
            speed: 100,
            types: const PsdkBattleTypes(primary: 'normal'),
            stats: const PsdkBattleStats(
              attack: 10,
              defense: 12,
              specialAttack: 14,
              specialDefense: 16,
              speed: 100,
            ),
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'transform',
                battleEngineMethod: 's_transform',
                target: PsdkBattleMoveTarget.adjacentFoe,
              ),
            ],
          ),
          opponent: _combatant(
            id: 'opponent',
            speciesId: 'vaporeon',
            displayName: 'Vaporeon',
            abilityId: 'water_absorb',
            speed: 1,
            types: const PsdkBattleTypes(primary: 'water'),
            stats: const PsdkBattleStats(
              attack: 65,
              defense: 60,
              specialAttack: 110,
              specialDefense: 95,
              speed: 65,
            ),
            transformState: const PsdkBattleTransformState(
              transformedFromSpeciesId: 'eevee',
            ),
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
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.speciesId, 'ditto');
      expect(player.transformState.isTransformed, isFalse);
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        hasLength(1),
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required String displayName,
  required String abilityId,
  required int speed,
  required PsdkBattleTypes types,
  required PsdkBattleStats stats,
  required List<PsdkBattleMoveData> moves,
  int currentHp = 80,
  PsdkBattleStatStages? statStages,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
  double currentWeightKg = 1,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: displayName,
    level: 20,
    maxHp: 80,
    currentHp: currentHp,
    types: types,
    stats: stats,
    abilityId: abilityId,
    statStages: statStages,
    transformState: transformState,
    baseWeightKg: currentWeightKg,
    currentWeightKg: currentWeightKg,
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String battleEngineMethod,
  required PsdkBattleMoveTarget target,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.status,
  int power = 0,
  String type = 'normal',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 0,
    pp: 10,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}
