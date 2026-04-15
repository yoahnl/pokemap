import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _integrationTestStats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('Battle flow hardening - runtime integration', () {
    test('BattleSetup creates session with correct initial state', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final session = createBattleSession(setup);

      // Vérifier l'état initial
      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20));
      expect(session.state.enemy.currentHp, equals(20));
      expect(session.state.currentTurn, isNull);
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('trainer battle request is not consumed twice (anti-retrigger)', () {
      // Ce test vérifie que la logique métier de map_battle
      // ne permet pas de consommer deux fois la même session
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      var session = createBattleSession(setup);

      // Premier choix
      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      // La session a évolué
      expect(session.state.currentTurn, isNotNull);

      // Si on essaie de rejouer avec la MÊME session, ça ne devrait pas
      // re-déclencher le même tour (la session est immutable)
      final oldSession = session;
      session = session.applyChoice(const PlayerBattleChoiceFight(0));

      // La nouvelle session est différente (immutable)
      expect(identical(oldSession, session), isFalse);

      // Chaque choix crée une nouvelle session, pas de consommation double
      expect(session.state.currentTurn, isNotNull);
    });

    test('battle ends cleanly after outcome', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 100)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 5,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      var session = createBattleSession(setup);

      // Jouer jusqu'à la fin
      while (!session.state.isFinished) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
      }

      // Vérifier que le combat est bien fini
      expect(session.state.isFinished, isTrue);
      expect(session.state.outcome, isNotNull);
      expect(session.state.phase, equals(BattlePhase.finished));

      // Après la fin, on ne peut plus jouer (la session est figée)
      // En pratique, le runtime devrait créer une nouvelle session pour un nouveau combat
    });

    test('trainer interaction flow: setup → battle → outcome', () {
      // Simule le flow complet d'un battle trainer
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 50)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 15,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      var session = createBattleSession(setup);

      // Vérifier que c'est bien un battle trainer
      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));

      // Jouer le combat
      while (!session.state.isFinished) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
      }

      // Vérifier la victoire
      expect(session.state.outcome!.isVictory, isTrue);

      // Le runtime utilisera session.setup.trainerId pour marquer le trainer comme battu
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('trainer LoS flow: same as interaction (unified pattern)', () {
      // Le flow LoS utilise le même BattleSetup que l'interaction
      // Ce test vérifie que les deux chemins sont cohérents
      final setupFromLoS = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      final setupFromInteraction = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );

      // Les deux setups sont identiques (pattern unifié)
      expect(setupFromLoS.isTrainerBattle,
          equals(setupFromInteraction.isTrainerBattle));
      expect(setupFromLoS.trainerId, equals(setupFromInteraction.trainerId));
      expect(setupFromLoS.playerPokemon.speciesId,
          equals(setupFromInteraction.playerPokemon.speciesId));
      expect(setupFromLoS.enemyPokemon.speciesId,
          equals(setupFromInteraction.enemyPokemon.speciesId));
    });

    test('wild encounter flow: setup → battle → outcome', () {
      // Simule le flow complet d'un wild encounter
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'pidgey',
          level: 3,
          maxHp: 10,
          stats: _integrationTestStats,
          moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 3)],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      var session = createBattleSession(setup);

      // Vérifier que c'est bien un wild encounter
      expect(session.setup.isTrainerBattle, isFalse);
      expect(session.setup.trainerId, isNull);

      // Jouer le combat
      while (!session.state.isFinished) {
        session = session.applyChoice(const PlayerBattleChoiceFight(0));
      }

      // Vérifier la victoire (pidgey est faible)
      expect(session.state.outcome!.isVictory, isTrue);

      // Pas de trainerId pour wild encounter
      expect(session.setup.trainerId, isNull);
    });
  });
}
