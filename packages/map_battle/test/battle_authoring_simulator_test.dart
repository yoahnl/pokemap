import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _stats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('BattleAuthoringSimulator', () {
    test('replays the same seeded battle with the same trace and write-back',
        () {
      final request = BattleAuthoringSimulationRequest(
        setup: _oneHitSetup(),
        seed: 42,
        choices: const <BattleAuthoringChoice>[
          BattleAuthoringChoice.fight(moveIndex: 0),
        ],
      );

      final first = const BattleAuthoringSimulator().simulate(request);
      final second = const BattleAuthoringSimulator().simulate(request);

      expect(first.outcome.type, BattleOutcomeType.victory);
      expect(first.trace, hasLength(1));
      expect(first.trace.single.choice.kind, BattleAuthoringChoiceKind.fight);
      expect(first.trace.single.executions, hasLength(1));
      expect(first.writeBack.playerLineup.single.lineupIndex, 0);
      expect(first.writeBack.playerParticipantLineupIndexes, <int>{0});
      expect(first.receipt.id, second.receipt.id);
      expect(first.receipt.stepCount, 1);
      expect(first.toJson(), second.toJson());
    });

    test('builds and validates wild trainer and static setup identities', () {
      const factory = BattleAuthoringSetupFactory.pokeMapBetaV1ForTest();
      final fixture = _oneHitSetup();
      final wild = factory.wild(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
        allowCapture: false,
      );
      final trainer = factory.trainer(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
        trainerId: ' rival ',
      );
      final staticEncounter = factory.staticEncounter(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
      );

      expect(factory.validate(wild).kind, BattleAuthoringSetupKind.wild);
      expect(factory.validate(wild).isValid, isTrue);
      expect(factory.validate(trainer).kind, BattleAuthoringSetupKind.trainer);
      expect(trainer.trainerId, 'rival');
      expect(
        factory.validate(staticEncounter).kind,
        BattleAuthoringSetupKind.staticEncounter,
      );
      expect(staticEncounter.allowCapture, isFalse);
      expect(staticEncounter.allowFlee, isFalse);
    });

    test('rejects a scripted choice that is not legal for the current request',
        () {
      expect(
        () => const BattleAuthoringSimulator().simulate(
          BattleAuthoringSimulationRequest(
            setup: BattleSetup.pokeMapBetaV1ForTest(
              playerPokemon: BattleCombatantData(
                speciesId: 'hero',
                level: 5,
                maxHp: 20,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
                ],
              ),
              enemyPokemon: BattleCombatantData(
                speciesId: 'rival',
                level: 5,
                maxHp: 20,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
                ],
              ),
              isTrainerBattle: true,
              trainerId: 'rival',
            ),
            choices: <BattleAuthoringChoice>[
              BattleAuthoringChoice.run(),
            ],
          ),
        ),
        throwsA(isA<BattleAuthoringChoiceRejectedException>()),
      );
    });

    test('fails explicitly instead of returning a partial max-step outcome',
        () {
      expect(
        () => const BattleAuthoringSimulator().simulate(
          BattleAuthoringSimulationRequest(
            setup: BattleSetup.pokeMapBetaV1ForTest(
              playerPokemon: BattleCombatantData(
                speciesId: 'hero',
                level: 5,
                maxHp: 100,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tap', name: 'Tap', power: 1),
                ],
              ),
              enemyPokemon: BattleCombatantData(
                speciesId: 'wild',
                level: 5,
                maxHp: 100,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tap', name: 'Tap', power: 1),
                ],
              ),
              isTrainerBattle: false,
              trainerId: null,
              allowFlee: false,
            ),
            maxSteps: 1,
          ),
        ),
        throwsA(isA<BattleAuthoringSimulationLimitException>()),
      );
    });

    test('records a deterministic captured outcome and its attempt identity',
        () {
      final result = const BattleAuthoringSimulator().simulate(
        BattleAuthoringSimulationRequest(
          setup: const BattleSetup.pokeMapBetaV1ForTest(
            playerPokemon: BattleCombatantData(
              speciesId: 'hero',
              level: 10,
              maxHp: 100,
              stats: _stats,
              moves: <BattleMoveData>[
                BattleMoveData(id: 'wait', name: 'Wait', power: 0),
              ],
            ),
            enemyPokemon: BattleCombatantData(
              speciesId: 'wild',
              level: 10,
              maxHp: 100,
              currentHp: 1,
              catchRate: 255,
              majorStatus: BattleMajorStatusState.slp(),
              stats: _stats,
              moves: <BattleMoveData>[
                BattleMoveData(id: 'tap', name: 'Tap', power: 1),
              ],
            ),
            isTrainerBattle: false,
            trainerId: null,
            allowCapture: true,
          ),
          seed: 47,
          choices: const <BattleAuthoringChoice>[
            BattleAuthoringChoice.capture(),
          ],
        ),
      );

      expect(result.outcome.type, BattleOutcomeType.captured);
      expect(result.outcome.captureItemId, canonicalPokeBallItemId);
      expect(result.outcome.captureAttemptId, 'capture-attempt-1');
      expect(
          result.trace.single.choice.kind, BattleAuthoringChoiceKind.capture);
    });
    test('the receipt records the ruleset alongside the seed', () {
      // Critère d'acceptation de BETA-BAT-008 : « seed ET ruleset enregistrés
      // dans le receipt ». Le seed y était, le ruleset non, si bien que deux
      // runs conduits sous des profils de règles différents produisaient des
      // reçus indiscernables — alors que c'est exactement ce qui change le
      // résultat.
      final result = const BattleAuthoringSimulator().simulate(
        BattleAuthoringSimulationRequest(
          setup: _oneHitSetup(),
          seed: 42,
          choices: const <BattleAuthoringChoice>[
            BattleAuthoringChoice.fight(moveIndex: 0),
          ],
        ),
      );

      expect(result.receipt.seed, 42);
      expect(
        result.receipt.rulesetProfileId,
        PokemonRulesetProfile.pokeMapBetaV1.profileId,
      );
      expect(
        result.receipt.rulesetSchemaVersion,
        PokemonRulesetProfile.pokeMapBetaV1.schemaVersion,
      );

      final json = result.receipt.toJson();
      expect(json['rulesetProfileId'], isNotNull);
      expect(json['rulesetSchemaVersion'], isNotNull);
    });

    test('a foreign ruleset cannot reach a simulation at all', () {
      // POURQUOI L'EFFET DU RULESET SUR L'IDENTIFIANT N'EST PAS TESTÉ ICI, et
      // c'est une limite assumée plutôt qu'un oubli.
      //
      // Le ruleset entre bien dans le payload haché du reçu, mais le prouver
      // demanderait deux runs ne différant que par le profil — impossible : un
      // seul profil est publié, son constructeur est privé, et
      // `requireSupported` refuse tout autre profileId. C'est un durcissement
      // voulu de BETA-BAT-001, « version inconnue refusée avant le premier
      // tour », pas un manque.
      //
      // Une première version de ce cas prétendait le prouver en reconstruisant
      // le hash elle-même : elle comparait deux de ses propres calculs sans
      // jamais toucher au reçu de production, et le sabotage l'a démasquée.
      // Retirer le ruleset du payload ne la faisait pas broncher.
      //
      // Ce cas fige donc la raison. Le jour où un second profil sera publié, il
      // faudra revenir écrire la vraie comparaison de deux reçus.
      expect(
        () => PokemonRulesetProfile.fromJson(<String, Object?>{
          ...PokemonRulesetProfile.pokeMapBetaV1.toJson(),
          'profileId': 'someone-elses-rules',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('the write-back carries the persistent status and nothing volatile',
        () {
      // Critère d'acceptation de BETA-BAT-004 : 'le write-back sauvegarde
      // uniquement l'état persistant'. Le statut majeur doit ressortir du
      // combat, l'état volatile ne doit jamais y apparaître.
      final result = const BattleAuthoringSimulator().simulate(
        BattleAuthoringSimulationRequest(
          setup: _statusedSetup(),
          seed: 42,
          choices: const <BattleAuthoringChoice>[
            BattleAuthoringChoice.fight(moveIndex: 0),
          ],
        ),
      );

      final written = result.writeBack.playerLineup.single;
      expect(written.statusId, 'brn');

      final json = written.toJson();
      expect(json.keys, containsAll(<String>['currentHp', 'statusId']));
      // Le tri se lit sur la forme elle-même : rien de volatile n'a de place
      // où se glisser, même si le combat s'est terminé avec un protect actif
      // et une charge en attente.
      for (final volatileKey in <String>[
        'volatileState',
        'statStages',
        'toxicCounter',
        'protectActive',
        'pendingCharge',
        'effects',
      ]) {
        expect(
          json.containsKey(volatileKey),
          isFalse,
          reason: '$volatileKey is battle-only state',
        );
      }
    });

    test('a battler that ends without a status writes none', () {
      final result = const BattleAuthoringSimulator().simulate(
        BattleAuthoringSimulationRequest(
          setup: _oneHitSetup(),
          seed: 42,
          choices: const <BattleAuthoringChoice>[
            BattleAuthoringChoice.fight(moveIndex: 0),
          ],
        ),
      );

      final written = result.writeBack.playerLineup.single;
      expect(written.statusId, isNull);
      expect(written.toJson().containsKey('statusId'), isFalse);
    });

  });
}

BattleSetup _statusedSetup() {
  final base = _oneHitSetup();
  return BattleSetup.pokeMapBetaV1ForTest(
    playerPokemon: BattleCombatantData(
      speciesId: base.playerPokemon.speciesId,
      level: base.playerPokemon.level,
      maxHp: base.playerPokemon.maxHp,
      stats: base.playerPokemon.stats,
      moves: base.playerPokemon.moves,
      majorStatus: const BattleMajorStatusState.brn(),
      volatileState: const BattleVolatileState(protectActive: true),
    ),
    enemyPokemon: base.enemyPokemon,
    isTrainerBattle: false,
    trainerId: null,
  );
}

BattleSetup _oneHitSetup() {
  return const BattleSetup.pokeMapBetaV1ForTest(
    playerPokemon: BattleCombatantData(
      speciesId: 'hero',
      level: 5,
      maxHp: 20,
      stats: BattleStatsSnapshot(
        attack: 100,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 100,
      ),
      moves: <BattleMoveData>[
        BattleMoveData(id: 'finisher', name: 'Finisher', power: 100),
      ],
    ),
    enemyPokemon: BattleCombatantData(
      speciesId: 'wild',
      level: 5,
      maxHp: 5,
      stats: BattleStatsSnapshot(
        attack: 10,
        defense: 10,
        specialAttack: 10,
        specialDefense: 10,
        speed: 1,
      ),
      moves: <BattleMoveData>[
        BattleMoveData(id: 'tap', name: 'Tap', power: 1),
      ],
    ),
    isTrainerBattle: false,
    trainerId: null,
  );
}

