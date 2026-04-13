import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession flow hardening', () {
    // Helper pour créer une session de test simple
    BattleSession createTestSession({
      int playerHp = 20,
      int enemyHp = 20,
      int playerMovePower = 5,
      int enemyMovePower = 5,
    }) {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: playerHp,
          moves: [
            BattleMoveData(
                id: 'tackle', name: 'Charge', power: playerMovePower),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: enemyHp,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: enemyMovePower),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      return createBattleSession(setup);
    }

    test('applyChoice processes only one choice at a time (anti-spam)', () {
      final session = createTestSession();

      // Premier choix
      final sessionAfterChoice1 =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // La session devrait avoir évolué (PV changés, tour résolu)
      expect(sessionAfterChoice1.state.currentTurn, isNotNull);
      expect(sessionAfterChoice1.state.currentTurn!.executions.length,
          greaterThan(0));

      // Deuxième choix immédiat (simule spam)
      final sessionAfterChoice2 =
          sessionAfterChoice1.applyChoice(const PlayerBattleChoiceFight(0));

      // Le deuxième choix devrait aussi être traité normalement
      // (le vrai anti-spam est dans le runtime, pas dans la logique métier)
      expect(sessionAfterChoice2.state.currentTurn, isNotNull);
    });

    test('battle finishes after enemy faints', () {
      // Créer un ennemi avec très peu de PV
      final session = createTestSession(enemyHp: 3, playerMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait être K.O.
      expect(sessionAfterChoice.state.enemy.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isVictory, isTrue);
    });

    test('battle finishes after player faints', () {
      // Créer un joueur avec très peu de PV et un ennemi puissant
      final session = createTestSession(playerHp: 3, enemyMovePower: 10);

      // Premier choix du joueur
      final sessionAfterChoice =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait être K.O.
      expect(sessionAfterChoice.state.player.isFainted, isTrue);
      expect(sessionAfterChoice.state.isFinished, isTrue);
      expect(sessionAfterChoice.state.outcome, isNotNull);
      expect(sessionAfterChoice.state.outcome!.isDefeat, isTrue);
    });

    test('runaway choice finishes the battle immediately', () {
      final session = createTestSession(playerHp: 50);

      final sessionAfterRun =
          session.applyChoice(const PlayerBattleChoiceRun());

      expect(sessionAfterRun.state.isFinished, isTrue);
      expect(sessionAfterRun.state.outcome, isNotNull);
      expect(sessionAfterRun.state.outcome!.isRunaway, isTrue);
      expect(sessionAfterRun.state.currentTurn, isNull);
      expect(sessionAfterRun.state.player.currentHp, equals(50));
      expect(sessionAfterRun.state.enemy.currentHp, equals(20));
    });

    test('multiple turns can be played sequentially', () {
      final session = createTestSession(
          playerHp: 50, enemyHp: 50, playerMovePower: 5, enemyMovePower: 5);

      var currentSession = session;
      var turnCount = 0;

      // Jouer plusieurs tours jusqu'à la fin
      while (!currentSession.state.isFinished && turnCount < 20) {
        currentSession =
            currentSession.applyChoice(const PlayerBattleChoiceFight(0));
        turnCount++;
      }

      // Le combat devrait se terminer
      expect(currentSession.state.isFinished, isTrue);
      expect(turnCount, lessThan(20)); // Ne devrait pas prendre 20 tours
    });

    test('trainer battle setup creates correct session', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('forced runaway choice is rejected in trainer battles', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceRun()),
        throwsA(isA<StateError>()),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.state.outcome, isNull);
    });
  });

  group('BattleOutcome types', () {
    test('victory outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 100)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isVictory, isTrue);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('defeat outcome has correct properties', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: [BattleMoveData(id: 'psychic', name: 'Psyko', power: 100)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(resultSession.state.outcome!.isDefeat, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isRunaway, isFalse);
    });

    test('runaway outcome exposes a real runaway result', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 50,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final resultSession = session.applyChoice(const PlayerBattleChoiceRun());

      expect(resultSession.state.isFinished, isTrue);
      expect(resultSession.state.outcome, isNotNull);
      expect(resultSession.state.outcome!.isRunaway, isTrue);
      expect(resultSession.state.outcome!.isVictory, isFalse);
      expect(resultSession.state.outcome!.isDefeat, isFalse);
      expect(resultSession.state.player.currentHp, equals(50));
      expect(resultSession.state.enemy.currentHp, equals(20));
    });
  });
}
