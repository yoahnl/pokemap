import 'package:map_battle/map_battle.dart';
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
  });
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
