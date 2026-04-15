import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _balancedStats = BattleStatsSnapshot(
  attack: 60,
  defense: 60,
  specialAttack: 60,
  specialDefense: 60,
  speed: 50,
);

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

void main() {
  group('BattleSession BE2 damage contract', () {
    test('createBattleSession preserves the resolved stats snapshot', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 12,
            maxHp: 40,
            stats: _stats(
              attack: 16,
              defense: 14,
              specialAttack: 20,
              specialDefense: 18,
              speed: 15,
            ),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 10,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'bulbasaur',
            level: 12,
            maxHp: 40,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      expect(session.state.player.stats.attack, equals(16));
      expect(session.state.player.stats.specialAttack, equals(20));
      expect(session.state.player.stats.speed, equals(15));
    });

    test('physical damage uses attack versus defense', () {
      final weakAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 40, defense: 60, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(defense: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final strongAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, defense: 60, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(defense: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final weakAfterTurn =
          weakAttacker.applyChoice(const PlayerBattleChoiceFight(0));
      final strongAfterTurn =
          strongAttacker.applyChoice(const PlayerBattleChoiceFight(0));

      final weakDamage = 80 - weakAfterTurn.state.enemy.currentHp;
      final strongDamage = 80 - strongAfterTurn.state.enemy.currentHp;
      expect(strongDamage, greaterThan(weakDamage));
    });

    test('special damage uses specialAttack versus specialDefense', () {
      final weakSpecialAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, specialAttack: 40),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(specialDefense: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final strongSpecialAttacker = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _stats(attack: 120, specialAttack: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _stats(specialDefense: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final weakAfterTurn =
          weakSpecialAttacker.applyChoice(const PlayerBattleChoiceFight(0));
      final strongAfterTurn =
          strongSpecialAttacker.applyChoice(const PlayerBattleChoiceFight(0));

      final weakDamage = 80 - weakAfterTurn.state.enemy.currentHp;
      final strongDamage = 80 - strongAfterTurn.state.enemy.currentHp;
      expect(strongDamage, greaterThan(weakDamage));
    });

    test('physical stages do not affect the special damage path', () {
      var neutralSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leer',
                name: 'Leer',
                power: 0,
                category: BattleMoveCategory.status,
              ),
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scratch',
                name: 'Scratch',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      var boostedPhysicalStageSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'swords_dance',
                name: 'Swords Dance',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.attack,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scratch',
                name: 'Scratch',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      neutralSession =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(0));
      boostedPhysicalStageSession = boostedPhysicalStageSession
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(neutralSession.state.player.statStages.attack, equals(0));
      expect(boostedPhysicalStageSession.state.player.statStages.attack,
          equals(2));

      final neutralAfterTurn =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(1));
      final boostedAfterTurn = boostedPhysicalStageSession
          .applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        boostedAfterTurn.state.enemy.currentHp,
        equals(neutralAfterTurn.state.enemy.currentHp),
      );
    });

    test('special stages do not affect the physical damage path', () {
      var neutralSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leer',
                name: 'Leer',
                power: 0,
                category: BattleMoveCategory.status,
              ),
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      var boostedSpecialStageSession = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 50,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'nasty_plot',
                name: 'Nasty Plot',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.specialAttack,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 50,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'aquafi',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      neutralSession =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(0));
      boostedSpecialStageSession = boostedSpecialStageSession
          .applyChoice(const PlayerBattleChoiceFight(0));

      expect(neutralSession.state.player.statStages.specialAttack, equals(0));
      expect(
        boostedSpecialStageSession.state.player.statStages.specialAttack,
        equals(2),
      );

      final neutralAfterTurn =
          neutralSession.applyChoice(const PlayerBattleChoiceFight(1));
      final boostedAfterTurn = boostedSpecialStageSession
          .applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        boostedAfterTurn.state.enemy.currentHp,
        equals(neutralAfterTurn.state.enemy.currentHp),
      );
    });

    test('status moves still inflict zero damage and speed stays informational',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 40,
            stats: _stats(speed: 200),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.attack,
                    stages: -1,
                  ),
                ],
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'bulbasaur',
            level: 20,
            maxHp: 40,
            stats: _stats(speed: 10),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.currentHp, equals(40));
      expect(afterTurn.state.player.currentHp, equals(40));
      expect(afterTurn.state.player.stats.speed, equals(200));
      expect(afterTurn.state.enemy.stats.speed, equals(10));
      expect(
        afterTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });
  });
}
