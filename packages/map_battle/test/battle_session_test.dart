import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
      bool allowCapture = false,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test(
        'createBattleSession preserves the additional honest battle contract fields transported by BE1',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(
              id: 'vine_whip',
              name: 'Vine Whip',
              power: 45,
              type: 'grass',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              pp: 25,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);
      final move = session.state.player.moves.single;

      expect(move.type, equals('grass'));
      expect(move.category, equals(BattleMoveCategory.physical));
      expect(move.target, equals(BattleMoveTarget.opponent));
      expect(move.pp, equals(25));
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices exposes capture in wild battle when allowed', () {
      final setup = createTestSetup(allowCapture: true);
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(4));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceCapture>());
      expect(choices[3], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('getAvailableChoices does not expose capture in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
        allowCapture: true,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // L'ennemi devrait avoir pris 5 dégâts
      expect(newSession.state.enemy.currentHp, equals(20)); // 25 - 5 = 20
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Le joueur devrait avoir pris des dégâts de la contre-attaque (power=5)
      expect(newSession.state.player.currentHp, equals(15)); // 20 - 5 = 15
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(setup);

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}
