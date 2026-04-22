import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _neutralBattleStats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

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
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
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
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          stats: _neutralBattleStats,
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
        'createBattleSession preserves the additional honest battle contract fields transported by BE1 through BE9',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(primaryType: 'electric'),
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: const [
            BattleMoveData(
              id: 'protect',
              name: 'Protect',
              power: 0,
              type: 'normal',
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              accuracy: BattleMoveAccuracy.alwaysHits(),
              pp: 10,
              currentPp: 7,
              priority: 1,
              critRatio: 2,
              selfVolatileStatus: BattleVolatileStatusId.protect,
            ),
            BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              type: 'normal',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 5,
              currentPp: 3,
              requiresRecharge: true,
            ),
            BattleMoveData(
              id: 'solar_beam',
              name: 'Solar Beam',
              power: 120,
              type: 'grass',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 10,
              currentPp: 9,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'solar_charge',
              ),
            ),
            BattleMoveData(
              id: 'feint',
              name: 'Feint',
              power: 30,
              type: 'normal',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              breaksProtect: true,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(
            primaryType: 'water',
            secondaryType: 'ice',
          ),
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'tackle',
              chargeStateId: 'stored_charge',
            ),
          ),
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 2,
          ),
        ),
      );

      final session = createBattleSession(setup);
      final protect = session.state.player.moves[0];
      final hyperBeam = session.state.player.moves[1];
      final solarBeam = session.state.player.moves[2];
      final feint = session.state.player.moves[3];
      final playerTyping = session.state.player.typing!;
      final enemyTyping = session.state.enemy.typing!;

      expect(protect.type, equals('normal'));
      expect(protect.category, equals(BattleMoveCategory.status));
      expect(protect.target, equals(BattleMoveTarget.self));
      expect(protect.accuracy.kind, equals(BattleMoveAccuracyKind.alwaysHits));
      expect(protect.pp, equals(10));
      expect(protect.currentPp, equals(7));
      expect(protect.priority, equals(1));
      expect(protect.critRatio, equals(2));
      expect(
        protect.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(hyperBeam.requiresRecharge, isTrue);
      expect(solarBeam.chargeThenStrikeEffect?.chargeStateId,
          equals('solar_charge'));
      expect(feint.breaksProtect, isTrue);
      expect(playerTyping.primaryType, equals('electric'));
      expect(playerTyping.secondaryType, isNull);
      expect(enemyTyping.primaryType, equals('water'));
      expect(enemyTyping.secondaryType, equals('ice'));
      expect(session.state.player.volatileState.mustRecharge, isTrue);
      expect(
        session.state.enemy.volatileState.pendingCharge?.moveId,
        equals('tackle'),
      );
      expect(session.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(session.state.field.weather?.remainingTurns, equals(3));
      expect(
        session.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(session.state.field.pseudoWeather?.remainingTurns, equals(2));
    });

    test(
        'withUpdatedPlayerCombatant updates the active player combatant without mutating the enemy state',
        () {
      final session = createBattleSession(createTestSetup());

      final updatedSession = session.withUpdatedPlayerCombatant(
        session.state.player.withDamage(6),
      );

      expect(updatedSession.state.player.currentHp, equals(14));
      expect(updatedSession.state.enemy.currentHp, equals(25));
      expect(
        updatedSession.decisionRequest.runtimeType,
        equals(session.decisionRequest.runtimeType),
      );
    });

    test(
        'withUpdatedPlayerCombatant updates a reserve combatant by lineup identity',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            lineupIndex: 1,
            level: 5,
            maxHp: 20,
            currentHp: 10,
            stats: _neutralBattleStats,
            moves: const [
              BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            ],
          ),
          playerReservePokemon: const <BattleCombatantData>[
            BattleCombatantData(
              speciesId: 'pikachu',
              lineupIndex: 0,
              level: 5,
              maxHp: 20,
              currentHp: 8,
              stats: _neutralBattleStats,
              moves: [
                BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
              ],
            ),
          ],
          enemyPokemon: BattleCombatantData(
            speciesId: 'lapras',
            level: 5,
            maxHp: 25,
            stats: _neutralBattleStats,
            moves: const [
              BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            ],
          ),
          isTrainerBattle: true,
          trainerId: 'trainer',
        ),
      );

      final updatedReserveCombatant =
          session.state.playerReserve.single.withHeal(6);
      final updatedSession =
          session.withUpdatedPlayerCombatant(updatedReserveCombatant);

      expect(updatedSession.state.player.currentHp, equals(10));
      expect(updatedSession.state.player.lineupIndex, equals(1));
      expect(updatedSession.state.playerReserve.single.lineupIndex, equals(0));
      expect(updatedSession.state.playerReserve.single.currentHp, equals(14));
    });

    test(
        'createBattleSession preserves an explicit major status seed and move status effect',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          majorStatus: const BattleMajorStatusState.brn(),
          moves: const [
            BattleMoveData(
              id: 'thunder_wave',
              name: 'Thunder Wave',
              power: 0,
              category: BattleMoveCategory.status,
              majorStatusEffect: BattleMoveMajorStatusEffect(
                status: BattleMajorStatusId.par,
              ),
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.majorStatus?.id,
          equals(BattleMajorStatusId.brn));
      expect(
        session.state.player.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test('createBattleSession preserves reserves and stable lineup identities',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        playerReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            level: 5,
            maxHp: 22,
            currentHp: 18,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        enemyPokemon: BattleCombatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            level: 5,
            maxHp: 24,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        isTrainerBattle: true,
        trainerId: 'trainer-reserve',
      );

      final session = createBattleSession(setup);

      expect(session.state.player.lineupIndex, equals(0));
      expect(session.state.playerReserve.single.lineupIndex, equals(1));
      expect(session.state.playerReserve.single.currentHp, equals(18));
      expect(session.state.enemy.lineupIndex, equals(0));
      expect(session.state.enemyReserve.single.lineupIndex, equals(1));
    });

    test('BattleMoveData rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMoveData(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMove rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMove(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMoveData keeps a valid crit ratio unchanged', () {
      // Mini-fix BE6-2 :
      // - on supprime les faux tests qui contournaient le contrat par héritage ;
      // - le vrai contrat public doit maintenant être évalué tel qu'il est
      //   réellement exposé aux call sites : un DTO final, `const`, typé ;
      // - ce test vérifie simplement qu'une valeur valide reste stable.
      const move = BattleMoveData(
        id: 'slash',
        name: 'Slash',
        power: 50,
        critRatio: 2,
      );

      expect(move.critRatio, equals(2));
    });

    test('BattleMove.withConsumedPp preserves a valid crit ratio', () {
      // Ce test remplace honnêtement l'ancien scénario artificiel :
      // - on ne forge plus un move malformé via override ;
      // - on vérifie que le vrai contrat public battle conserve `critRatio`
      //   pendant une transition d'état normale du moteur.
      const move = BattleMove(
        id: 'slash',
        name: 'Slash',
        power: 50,
        pp: 10,
        currentPp: 3,
        critRatio: 3,
      );

      final consumed = move.withConsumedPp();

      expect(consumed.critRatio, equals(3));
      expect(consumed.currentPp, equals(2));
    });

    test('getAvailableChoices hides fight choices whose currentPp is zero', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
            BattleMoveData(
              id: 'scratch',
              name: 'Griffe',
              power: 4,
              pp: 10,
              currentPp: 3,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();
      final fightChoices =
          choices.whereType<PlayerBattleChoiceFight>().toList();

      expect(fightChoices, hasLength(1));
      expect(fightChoices.single.moveIndex, equals(1));
    });

    test('forcing a move with zero PP is rejected explicitly', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('n’a plus de PP'),
          ),
        ),
      );
    });

    test(
        'enemy with no configured move fails explicitly instead of masquerading as a run action',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('aucun move configuré'),
          ),
        ),
      );
    });

    test(
        'enemy with only zero-PP moves fails explicitly while Struggle stays out of scope',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Struggle est hors scope'),
          ),
        ),
      );
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

    test('getAvailableChoices exposes Continue for a forced recharge turn', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 5,
            maxHp: 20,
            stats: _neutralBattleStats,
            volatileState: const BattleVolatileState(
              mustRecharge: true,
            ),
            moves: const [
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 150,
                requiresRecharge: true,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'lapras',
            level: 5,
            maxHp: 25,
            stats: _neutralBattleStats,
            moves: const [
              BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices, hasLength(1));
      expect(choices.single, isA<PlayerBattleChoiceContinue>());
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Avec le contract de dégâts BE2, le move passe maintenant par les
      // vraies stats résolues au lieu de faire `damage = power`.
      expect(newSession.state.enemy.currentHp, equals(23));
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Même logique pour la contre-attaque : on attend désormais un dégât
      // déterministe issu de la formule BE2, pas la puissance brute.
      expect(newSession.state.player.currentHp, equals(18));
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 100,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          stats: _neutralBattleStats,
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
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
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
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          stats: _neutralBattleStats,
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
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(
        setup,
        rng: BattleScriptedRng(List<int>.filled(6, 2)),
      );

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

    test(
        'applyPotionTurn commits a real turn and the enemy still responds in the same turn flow',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: const BattleCombatantData(
            speciesId: 'sproutle',
            level: 10,
            maxHp: 40,
            currentHp: 12,
            lineupIndex: 0,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
            ],
          ),
          enemyPokemon: const BattleCombatantData(
            speciesId: 'sparkitten',
            level: 10,
            maxHp: 40,
            lineupIndex: 0,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(
                id: 'wait',
                name: 'Wait',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          isTrainerBattle: true,
          trainerId: 'trainer_1',
        ),
      );

      final updatedSession = session.applyPotionTurn(
        targetLineupIndex: 0,
        healAmount: 20,
      );

      expect(updatedSession.state.currentTurn, isNotNull);
      expect(updatedSession.state.player.currentHp, equals(32));
      expect(
        updatedSession.state.currentTurn!.playerAction,
        isA<BattleActionPotionUse>(),
      );
      expect(
        updatedSession.state.currentTurn!.enemyAction,
        isA<BattleActionFight>(),
      );
      expect(updatedSession.state.currentTurn!.potionEvents, hasLength(1));
      expect(
        updatedSession.state.currentTurn!.potionEvents.single.healedAmount,
        equals(20),
      );
      expect(
        updatedSession.state.currentTurn!.timeline.first,
        isA<BattleTurnPotionEvent>(),
      );
      expect(
        updatedSession.state.currentTurn!.timeline.last,
        isA<BattleTurnExecutionEvent>(),
      );
      expect(
        updatedSession.decisionRequest,
        isA<BattleTurnChoiceRequest>(),
      );
    });

    test(
        'applyPotionTurn rejects invalid targets instead of faking a committed item turn',
        () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: const BattleCombatantData(
            speciesId: 'sproutle',
            level: 10,
            maxHp: 40,
            currentHp: 40,
            lineupIndex: 0,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
            ],
          ),
          playerReservePokemon: const <BattleCombatantData>[
            BattleCombatantData(
              speciesId: 'benchmate',
              level: 10,
              maxHp: 35,
              currentHp: 0,
              lineupIndex: 1,
              stats: _neutralBattleStats,
              moves: <BattleMoveData>[
                BattleMoveData(id: 'wait', name: 'Wait', power: 0),
              ],
            ),
          ],
          enemyPokemon: const BattleCombatantData(
            speciesId: 'sparkitten',
            level: 10,
            maxHp: 40,
            lineupIndex: 0,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'wait', name: 'Wait', power: 0),
            ],
          ),
          isTrainerBattle: true,
          trainerId: 'trainer_1',
        ),
      );

      expect(
        () => session.applyPotionTurn(
          targetLineupIndex: 0,
          healAmount: 20,
        ),
        throwsA(isA<StateError>()),
      );
      expect(
        () => session.applyPotionTurn(
          targetLineupIndex: 1,
          healAmount: 20,
        ),
        throwsA(isA<StateError>()),
      );
      expect(session.state.currentTurn, isNull);
      expect(session.state.player.currentHp, equals(40));
      expect(session.state.playerReserve.single.currentHp, equals(0));
    });
  });
}
