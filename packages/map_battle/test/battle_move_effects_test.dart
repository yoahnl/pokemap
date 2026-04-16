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

BattleTypingSnapshot _typing(
  String primaryType, [
  String? secondaryType,
]) {
  return BattleTypingSnapshot(
    primaryType: primaryType,
    secondaryType: secondaryType,
  );
}

void main() {
  group('BattleSession BE2/BE3/BE4/BE5/BE6 combat contract', () {
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

    test('status moves still inflict zero damage while speed can affect order',
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

    test('higher priority acts before a faster opponent', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'quick_attack',
                name: 'Quick Attack',
                power: 40,
                category: BattleMoveCategory.physical,
                priority: 1,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('enemy higher priority acts before a faster player', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'quick_attack',
                name: 'Quick Attack',
                power: 40,
                category: BattleMoveCategory.physical,
                priority: 1,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'enemy');
    });

    test('higher effective speed acts first at equal priority', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 120),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'snorlax',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 20),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test(
        'equal priority and equal speed use the deterministic player tie-break',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 70),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'eevee',
            level: 20,
            maxHp: 50,
            stats: _stats(speed: 70),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('a self speed boost changes order only on the following turn', () {
      var session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 50),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'agility',
                name: 'Agility',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                selfStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.speed,
                    stages: 2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 80),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 5,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(session.state.currentTurn!.executions.first.attacker, 'enemy');
      expect(session.state.player.statStages.speed, 2);

      session = session.applyChoice(const PlayerBattleChoiceFight(1));

      expect(session.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('a target speed drop changes order only on the following turn', () {
      var session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 50),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'scary_face',
                name: 'Scary Face',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.speed,
                    stages: -2,
                  ),
                ],
              ),
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
            stats: _stats(speed: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tackle',
                name: 'Tackle',
                power: 5,
                category: BattleMoveCategory.physical,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(session.state.currentTurn!.executions.first.attacker, 'enemy');
      expect(session.state.enemy.statStages.speed, -2);

      session = session.applyChoice(const PlayerBattleChoiceFight(1));

      expect(session.state.currentTurn!.executions.first.attacker, 'player');
    });

    test('an alwaysHits move bypasses the hit check and still applies damage',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'swift',
                name: 'Swift',
                power: 40,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                pp: 20,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
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
        rng: const BattleScriptedRng(<int>[2]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, greaterThan(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(19));
    });

    test('a percent accuracy move can miss deterministically', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'mud_slap',
                name: 'Mud-Slap',
                power: 20,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 50),
                pp: 10,
                targetStatStageChanges: <BattleStatStageChange>[
                  BattleStatStageChange(
                    stat: BattleStatId.specialDefense,
                    stages: -1,
                  ),
                ],
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
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
        rng: const BattleScriptedRng(<int>[100]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isFalse);
      expect(execution.damage, equals(0));
      expect(afterTurn.state.enemy.currentHp, equals(70));
      expect(afterTurn.state.enemy.statStages.specialDefense, equals(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(9));
    });

    test('a percent accuracy move that hits still consumes one PP', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 75),
                pp: 15,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'electrode',
            level: 20,
            maxHp: 70,
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
        rng: const BattleScriptedRng(<int>[1, 2]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, greaterThan(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(14));
    });

    test('STAB increases damage for the same move and target', () {
      final withoutStab = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
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

      final withStab = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            typing: _typing('fire'),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
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

      final neutralTurn =
          withoutStab.applyChoice(const PlayerBattleChoiceFight(0));
      final stabTurn = withStab.applyChoice(const PlayerBattleChoiceFight(0));
      final neutralExecution = neutralTurn.state.currentTurn!.executions.first;
      final stabExecution = stabTurn.state.currentTurn!.executions.first;

      expect(stabExecution.damage, greaterThan(neutralExecution.damage));
      expect(neutralExecution.stabMultiplier, equals(1.0));
      expect(stabExecution.stabMultiplier, equals(1.5));
      expect(stabExecution.typeEffectivenessMultiplier, equals(2.0));
    });

    test('super-effective damage is greater than neutral damage', () {
      final neutral = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'neutral_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('normal'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final superEffective = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'grass_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('grass'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final neutralExecution = neutral
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final superExecution = superEffective
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(superExecution.damage, greaterThan(neutralExecution.damage));
      expect(neutralExecution.typeEffectivenessMultiplier, equals(1.0));
      expect(superExecution.typeEffectivenessMultiplier, equals(2.0));
    });

    test('resisted damage is lower than neutral damage', () {
      final neutral = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'neutral_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('normal'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final resisted = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'ember',
                name: 'Ember',
                power: 40,
                type: 'fire',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'water_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('water'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final neutralExecution = neutral
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final resistedExecution = resisted
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(resistedExecution.damage, lessThan(neutralExecution.damage));
      expect(resistedExecution.typeEffectivenessMultiplier, equals(0.5));
    });

    test('type immunity deals zero damage but still records a hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'thunder_shock',
                name: 'Thunder Shock',
                power: 40,
                type: 'electric',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isTrue);
      expect(execution.damage, equals(0));
      expect(execution.typeEffectivenessMultiplier, equals(0.0));
      expect(afterTurn.state.enemy.currentHp, equals(80));
    });

    test('double types combine multiplicatively for effectiveness', () {
      final singleWeakness = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'water_gun',
                name: 'Water Gun',
                power: 40,
                type: 'water',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final doubleWeakness = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 20,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'water_gun',
                name: 'Water Gun',
                power: 40,
                type: 'water',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'rock_ground_target',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('rock', 'ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final singleExecution = singleWeakness
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final doubleExecution = doubleWeakness
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(singleExecution.typeEffectivenessMultiplier, equals(2.0));
      expect(doubleExecution.typeEffectivenessMultiplier, equals(4.0));
      expect(doubleExecution.damage, greaterThan(singleExecution.damage));
    });

    test('a non-immune damaging move still deals at least 1 damage', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'caster',
            level: 1,
            maxHp: 10,
            stats: _stats(
                attack: 1, defense: 1, specialAttack: 1, specialDefense: 1),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leaf_tap',
                name: 'Leaf Tap',
                power: 1,
                type: 'grass',
                category: BattleMoveCategory.special,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'resistant_target',
            level: 50,
            maxHp: 200,
            stats: _stats(defense: 200, specialDefense: 200),
            typing: _typing('fire', 'flying'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.typeEffectivenessMultiplier, equals(0.25));
      expect(execution.damage, equals(1));
    });

    test('neutral crit ratio can still resolve to no crit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 60,
                category: BattleMoveCategory.physical,
                critRatio: 1,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[2]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
    });

    test('high crit ratio can trigger a real critical hit', () {
      final baseline = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'razor_leaf',
                name: 'Razor Leaf',
                power: 55,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 2,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[2]),
      );

      final critical = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'razor_leaf',
                name: 'Razor Leaf',
                power: 55,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 2,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[1]),
      );

      final baselineExecution = baseline
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;
      final criticalExecution = critical
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(baselineExecution.didCrit, isFalse);
      expect(criticalExecution.didCrit, isTrue);
      expect(criticalExecution.criticalMultiplier, equals(1.5));
      expect(criticalExecution.damage, greaterThan(baselineExecution.damage));
    });

    test('a miss never resolves a critical hit but still spends PP', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'mud_slap',
                name: 'Mud-Slap',
                power: 20,
                type: 'ground',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.percent(value: 50),
                pp: 10,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[100]),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final execution = afterTurn.state.currentTurn!.executions.first;

      expect(execution.didHit, isFalse);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
      expect(afterTurn.state.player.moves.single.currentPp, equals(9));
    });

    test('an immune hit never resolves a critical hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sparkitten',
            level: 25,
            maxHp: 70,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'thunderbolt',
                name: 'Thunderbolt',
                power: 40,
                type: 'electric',
                category: BattleMoveCategory.special,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'ground_target',
            level: 25,
            maxHp: 80,
            stats: _balancedStats,
            typing: _typing('ground'),
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
      expect(execution.typeEffectivenessMultiplier, equals(0.0));
    });

    test('a status move never resolves a critical hit', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'growl',
                name: 'Growl',
                power: 0,
                category: BattleMoveCategory.status,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isFalse);
      expect(execution.criticalMultiplier, equals(1.0));
      expect(execution.damage, equals(0));
    });

    test('crit ratio >= 4 guarantees a critical hit without consuming RNG', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'sproutle',
            level: 20,
            maxHp: 60,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'leaf_blade',
                name: 'Leaf Blade',
                power: 50,
                type: 'grass',
                category: BattleMoveCategory.physical,
                critRatio: 4,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'dummy',
            level: 20,
            maxHp: 80,
            stats: _balancedStats,
            moves: const <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        rng: const BattleScriptedRng(<int>[]),
      );

      final execution = session
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .first;

      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });
  });
}
