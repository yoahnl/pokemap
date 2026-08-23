import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';

void main() {
  group('RuntimeBattleRewardResolver', () {
    test('previews levels, loads crossed catalog data, then replays once',
        () async {
      final speciesLoader = _SpeciesLoader(<String, RuntimePokemonSpecies>{
        'hero': _species('hero', baseExp: 64),
        'foe': _species('foe', baseExp: 200),
        'hero_evolved': _species('hero_evolved', baseExp: 142),
      });
      final learnsetLoader = _LearnsetLoader(<PokemonMoveLearningCandidate>[
        const PokemonMoveLearningCandidate(
          opportunityId: 'hero:levelUp:0:6:quick_attack',
          moveId: 'quick_attack',
          learnedAtLevel: 6,
          maxPp: 30,
        ),
      ]);
      final evolutionLoader = _EvolutionLoader(<PokemonEvolutionCandidate>[
        PokemonEvolutionCandidate(
          opportunityId: 'hero:levelUp:0:6:hero_evolved',
          sourceSpeciesId: 'hero',
          targetSpeciesId: 'hero_evolved',
          minLevel: 6,
          targetBaseStats: const PokemonBaseStats(
            hp: 60,
            attack: 62,
            defense: 63,
            specialAttack: 80,
            specialDefense: 80,
            speed: 60,
          ),
          targetPrimaryAbilityId: 'hero_power',
          targetAbilityIds: const <String>['hero_power'],
        ),
      ]);
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: speciesLoader.load,
        loadMoveLearningCandidates: learnsetLoader.load,
        loadEvolutionCandidates: evolutionLoader.load,
      );
      final bundle = _bundle();

      final resolution = await resolver.resolve(
        bundle: bundle,
        postWriteBackState: _state(),
        runtimeContext: _context(const WildBattleStartRequest(
          requestId: 'wild-win',
          createdAtEpochMs: 1,
          returnContext: OverworldReturnContext(
            mapId: 'route',
            playerPos: GridPos(x: 1, y: 1),
            playerFacing: Direction.south,
          ),
          mapId: 'route',
          encounterSourceId: 'grass',
          encounterSourceKind: EncounterSourceKind.gameplayZone,
          tableId: 'grass',
          encounterKind: EncounterKind.walk,
          speciesId: 'foe',
          level: 50,
          minLevel: 50,
          maxLevel: 50,
          weight: 1,
          playerPos: GridPos(x: 1, y: 1),
        )),
        outcome: _outcome(level: 50),
      );

      expect(resolution.reward.sourceKind, BattleRewardSourceKind.wild);
      expect(
          resolution.progressionContext.defeatedOpponents.single.baseExperience,
          200);
      expect(resolution.progression.changes.single.oldLevel, 5);
      expect(resolution.progression.changes.single.newLevel, 11);
      expect(
        resolution.progression.rulesetReference,
        PokemonRulesetProfile.pokeMapBetaV1Reference,
      );
      expect(
        identical(
          resolution.progressionContext.ruleset,
          bundle.manifest.pokemon.ruleset,
        ),
        isTrue,
      );
      expect(
          resolution.progression.state.party.members.single.experience, 1553);
      expect(resolution.progression.state.trainerProfile.money, 0);
      expect(
        resolution.progression.moveLearningChanges.single.kind,
        BattleMoveLearningChangeKind.automaticallyLearned,
      );
      expect(resolution.progression.pendingEvolution, isNotNull);
      expect(learnsetLoader.requests.single, (oldLevel: 5, newLevel: 11));
      expect(evolutionLoader.sourceSpeciesIds, <String>['hero']);
    });

    test('maps exact authored trainer rewards but defers their application',
        () async {
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: _SpeciesLoader(<String, RuntimePokemonSpecies>{
          'hero': _species('hero', baseExp: 64),
          'foe': _species('foe', baseExp: 70),
        }).load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );
      final resolution = await resolver.resolve(
        bundle: _bundle(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'trainer_iris',
              name: 'Iris',
              trainerClass: 'Rivale',
              moneyReward: 480,
              rewardItemGrants: <ProjectTrainerItemGrant>[
                ProjectTrainerItemGrant(itemId: 'potion', quantity: 2),
              ],
              rewardFlagIds: <String>['story:iris_won'],
              rewardBadgeId: 'tide_badge',
              rewardFieldAbilityUnlock: FieldAbility.surf,
            ),
          ],
        ),
        postWriteBackState: _state(),
        runtimeContext: _context(_trainerRequest()),
        outcome: _outcome(level: 14),
      );

      expect(resolution.reward.trainerId, 'trainer_iris');
      expect(resolution.reward.money, 480);
      expect(
        resolution.reward.itemGrants,
        const <BattleRewardItemGrant>[
          BattleRewardItemGrant(itemId: 'potion', quantity: 2),
        ],
      );
      expect(resolution.reward.flagIds, <String>['story:iris_won']);
      expect(resolution.reward.badgeId, 'tide_badge');
      expect(resolution.reward.fieldAbilityUnlock, FieldAbility.surf);
      expect(resolution.progression.state.trainerProfile.money, 0);
      expect(resolution.progression.state.bag.entries, isEmpty);
      expect(resolution.progression.state.storyFlags.activeFlags, isEmpty);
    });

    test('static encounter grants wild progression without authored rewards',
        () async {
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: _SpeciesLoader(<String, RuntimePokemonSpecies>{
          'hero': _species('hero', baseExp: 64),
          'foe': _species('foe', baseExp: 70),
        }).load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );

      final resolution = await resolver.resolve(
        bundle: _bundle(),
        postWriteBackState: _state(),
        runtimeContext: _context(const StaticBattleStartRequest(
          requestId: 'static-boss',
          createdAtEpochMs: 1,
          returnContext: OverworldReturnContext(
            mapId: 'route',
            playerPos: GridPos(x: 1, y: 1),
            playerFacing: Direction.south,
          ),
          battleId: 'boss_lantern',
          opponentProfileId: 'profile_lantern',
          entityId: 'lantern',
          mapId: 'route',
          playerPos: GridPos(x: 1, y: 1),
        )),
        outcome: _outcome(level: 14),
      );

      expect(resolution.reward.sourceKind, BattleRewardSourceKind.wild);
      expect(resolution.reward.isEmpty, isTrue);
      expect(resolution.progression.changes.single.experienceAwarded, 140);
      expect(resolution.progression.state.party.members.single.experience, 265);
    });

    test('trainer victory sums every fainted enemy side member exactly once',
        () async {
      final speciesLoader = _SpeciesLoader(<String, RuntimePokemonSpecies>{
        'hero': _species('hero', baseExp: 64),
        'foe_a': _species('foe_a', baseExp: 70),
        'foe_b': _species('foe_b', baseExp: 42),
      });
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: speciesLoader.load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );
      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: _combatant('hero', level: 5, currentHp: 15, lineupIndex: 0),
          enemy: _combatant('foe_a', level: 14, currentHp: 0, lineupIndex: 0),
          enemyReserve: <BattleCombatant>[
            _combatant('foe_b', level: 10, currentHp: 0, lineupIndex: 1),
          ],
          playerParticipantLineupIndexes: const <int>{0},
        ),
      );

      final resolution = await resolver.resolve(
        bundle: _bundle(
          trainers: const <ProjectTrainerEntry>[
            ProjectTrainerEntry(
              id: 'trainer_iris',
              name: 'Iris',
              trainerClass: 'Rivale',
            ),
          ],
        ),
        postWriteBackState: _state(),
        runtimeContext: _context(_trainerRequest()),
        outcome: outcome,
      );

      expect(
        resolution.progressionContext.defeatedOpponents
            .map((opponent) => (opponent.level, opponent.baseExperience)),
        <(int, int)>[(14, 70), (10, 42)],
      );
      expect(resolution.progression.changes.single.experienceAwarded, 300);
      expect(resolution.progression.state.party.members.single.experience, 425);
      expect(speciesLoader.requestedIds, <String>['foe_a', 'foe_b', 'hero']);
    });

    test('missing defeated reserve catalogue entry fails closed', () async {
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: _SpeciesLoader(<String, RuntimePokemonSpecies>{
          'hero': _species('hero', baseExp: 64),
          'foe_a': _species('foe_a', baseExp: 70),
        }).load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );
      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: _combatant('hero', level: 5, currentHp: 15, lineupIndex: 0),
          enemy: _combatant('foe_a', level: 14, currentHp: 0, lineupIndex: 0),
          enemyReserve: <BattleCombatant>[
            _combatant('missing_foe', level: 10, currentHp: 0, lineupIndex: 1),
          ],
          playerParticipantLineupIndexes: const <int>{0},
        ),
      );

      await expectLater(
        resolver.resolve(
          bundle: _bundle(
            trainers: const <ProjectTrainerEntry>[
              ProjectTrainerEntry(
                id: 'trainer_iris',
                name: 'Iris',
                trainerClass: 'Rivale',
              ),
            ],
          ),
          postWriteBackState: _state(),
          runtimeContext: _context(_trainerRequest()),
          outcome: outcome,
        ),
        throwsA(
          isA<RuntimePostBattleResolutionException>().having(
            (error) => error.code,
            'code',
            RuntimePostBattleResolutionErrorCode.missingCatalogueData,
          ),
        ),
      );
    });

    test('maps every real participant to its exact party slot', () async {
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: _SpeciesLoader(<String, RuntimePokemonSpecies>{
          'hero': _species('hero', baseExp: 64),
          'ally': _species('ally', baseExp: 62),
          'foe': _species('foe', baseExp: 70),
        }).load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );
      final state = GameState(
        saveId: 'multi-participant',
        party: PlayerParty(
          members: <PlayerPokemon>[
            _state().party.members.single,
            const PlayerPokemon(
              speciesId: 'ally',
              natureId: 'hardy',
              abilityId: 'ally_power',
              level: 5,
              knownMoveIds: <String>['tackle'],
              currentPpByMoveId: <String, int>{'tackle': 35},
              experience: 125,
              currentHp: 15,
            ),
          ],
        ),
      );
      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: BattleState(
          phase: BattlePhase.finished,
          player: _combatant('hero', level: 5, currentHp: 15, lineupIndex: 0),
          enemy: _combatant('foe', level: 14, currentHp: 0, lineupIndex: 0),
          playerParticipantLineupIndexes: const <int>{0, 1},
        ),
      );

      final resolution = await resolver.resolve(
        bundle: _bundle(),
        postWriteBackState: state,
        runtimeContext: RuntimeActiveBattleContext.withLineupMapping(
          request: _wildRequest(),
          playerPartyIndex: 0,
          playerPartySlotIndicesByLineupIndex: const <int>[0, 1],
        ),
        outcome: outcome,
      );

      expect(
        resolution.progressionContext.playerParticipantPartySlots,
        const <int>{0, 1},
      );
      expect(
        resolution.progression.changes.map((change) => change.partySlot),
        <int>[0, 1],
      );
      expect(
        resolution.progression.state.party.members
            .map((pokemon) => pokemon.experience),
        everyElement(greaterThan(125)),
      );
    });

    test('fails closed when the authored trainer is missing', () async {
      final resolver = RuntimeBattleRewardResolver(
        loadSpecies: _SpeciesLoader(<String, RuntimePokemonSpecies>{
          'hero': _species('hero', baseExp: 64),
          'foe': _species('foe', baseExp: 70),
        }).load,
        loadMoveLearningCandidates:
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]).load,
        loadEvolutionCandidates:
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]).load,
      );

      await expectLater(
        resolver.resolve(
          bundle: _bundle(),
          postWriteBackState: _state(),
          runtimeContext: _context(_trainerRequest()),
          outcome: _outcome(level: 14),
        ),
        throwsA(isA<RuntimePostBattleResolutionException>()),
      );
    });

    for (final outcomeType in <BattleOutcomeType>[
      BattleOutcomeType.defeat,
      BattleOutcomeType.runaway,
      BattleOutcomeType.captured,
    ]) {
      test('${outcomeType.name} fabricates no reward or catalogue work',
          () async {
        final speciesLoader =
            _SpeciesLoader(const <String, RuntimePokemonSpecies>{});
        final learnsetLoader =
            _LearnsetLoader(const <PokemonMoveLearningCandidate>[]);
        final evolutionLoader =
            _EvolutionLoader(const <PokemonEvolutionCandidate>[]);
        final resolver = RuntimeBattleRewardResolver(
          loadSpecies: speciesLoader.load,
          loadMoveLearningCandidates: learnsetLoader.load,
          loadEvolutionCandidates: evolutionLoader.load,
        );

        final resolution = await resolver.resolve(
          bundle: _bundle(),
          postWriteBackState: _state(),
          runtimeContext: _context(_wildRequest()),
          outcome: _outcome(type: outcomeType),
        );

        expect(resolution.reward.isEmpty, isTrue);
        expect(resolution.progression.state, same(resolution.baseState));
        expect(speciesLoader.requestedIds, isEmpty);
        expect(learnsetLoader.requests, isEmpty);
        expect(evolutionLoader.sourceSpeciesIds, isEmpty);
      });
    }
  });
}

RuntimeMapBundle _bundle({
  List<ProjectTrainerEntry> trainers = const <ProjectTrainerEntry>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Post battle fixture',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'route.json'),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      trainers: trainers,
    ),
    map: const MapData(
      id: 'route',
      name: 'Route',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[],
    ),
    projectRootDirectory: '/tmp/post-battle-fixture',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameState _state() {
  return const GameState(
    saveId: 'post-battle',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'hero_power',
          level: 5,
          knownMoveIds: <String>['tackle'],
          currentPpByMoveId: <String, int>{'tackle': 35},
          experience: 125,
          currentHp: 15,
        ),
      ],
    ),
  );
}

RuntimeActiveBattleContext _context(BattleStartRequest request) {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: request,
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'route',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'route',
    encounterSourceId: 'grass',
    encounterSourceKind: EncounterSourceKind.gameplayZone,
    tableId: 'grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'foe',
    level: 14,
    minLevel: 14,
    maxLevel: 14,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'route',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'route',
    trainerId: 'trainer_iris',
    npcEntityId: 'npc_iris',
    playerPos: GridPos(x: 1, y: 1),
  );
}

BattleOutcome _outcome({
  BattleOutcomeType type = BattleOutcomeType.victory,
  int level = 14,
}) {
  return BattleOutcome(
    type: type,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _combatant('hero', level: 5, currentHp: 15, lineupIndex: 0),
      enemy: _combatant('foe', level: level, currentHp: 0, lineupIndex: 0),
      playerParticipantLineupIndexes: const <int>{0},
    ),
    captureItemId: type == BattleOutcomeType.captured ? 'poke-ball' : null,
    captureAttemptId:
        type == BattleOutcomeType.captured ? 'capture-attempt-1' : null,
  );
}

BattleCombatant _combatant(
  String speciesId, {
  required int level,
  required int currentHp,
  required int lineupIndex,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    currentHp: currentHp,
    maxHp: 19,
    stats: const BattleStatsSnapshot(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    moves: const <BattleMove>[],
  );
}

RuntimePokemonSpecies _species(String id, {required int baseExp}) {
  return RuntimePokemonSpecies(
    id: id,
    typing: const <String>['normal'],
    baseHp: 45,
    baseAttack: 49,
    baseDefense: 49,
    baseSpecialAttack: 65,
    baseSpecialDefense: 65,
    baseSpeed: 45,
    primaryAbilityId: '${id}_power',
    abilityIds: <String>['${id}_power'],
    learnsetRef: id,
    growthRateId: 'medium',
    baseExp: baseExp,
    catchRate: 45,
  );
}

final class _SpeciesLoader {
  _SpeciesLoader(this.byId);

  final Map<String, RuntimePokemonSpecies> byId;
  final List<String> requestedIds = <String>[];

  Future<RuntimePokemonSpecies> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesId,
  }) async {
    requestedIds.add(speciesId);
    final species = byId[speciesId];
    if (species == null) {
      throw StateError('Missing species $speciesId');
    }
    return species;
  }
}

final class _LearnsetLoader {
  _LearnsetLoader(this.candidates);

  final List<PokemonMoveLearningCandidate> candidates;
  final List<({int oldLevel, int newLevel})> requests =
      <({int oldLevel, int newLevel})>[];

  Future<List<PokemonMoveLearningCandidate>> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
    required int oldLevel,
    required int newLevel,
  }) async {
    requests.add((oldLevel: oldLevel, newLevel: newLevel));
    return candidates;
  }
}

final class _EvolutionLoader {
  _EvolutionLoader(this.candidates);

  final List<PokemonEvolutionCandidate> candidates;
  final List<String> sourceSpeciesIds = <String>[];

  Future<List<PokemonEvolutionCandidate>> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String sourceSpeciesId,
  }) async {
    sourceSpeciesIds.add(sourceSpeciesId);
    return candidates;
  }
}
