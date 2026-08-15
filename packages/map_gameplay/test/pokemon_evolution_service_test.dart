import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const evolutionService = PokemonEvolutionService();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(
    const ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: 'leaf-stone',
          displayName: 'Leaf Stone',
          pocketId: 'items',
        ),
        ProjectItemDefinition(
          id: 'fire-stone',
          displayName: 'Fire Stone',
          pocketId: 'items',
        ),
        ProjectItemDefinition(
          id: 'vault-key',
          displayName: 'Vault Key',
          pocketId: 'key-items',
          tags: <String>{'key-item'},
        ),
      ],
    ),
  );

  group('PokemonEvolutionService', () {
    test('accept preserves identity fields and a compatible ability', () {
      final source = _pokemon(
        currentHp: 15,
        abilityId: 'shared_ability',
      );

      final result = evolutionService.evolve(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        pokemon: source,
        candidate: _candidate(
          minLevel: 5,
          targetHp: 135,
          targetAbilityIds: const <String>[
            'target_primary',
            'shared_ability',
          ],
        ),
        sourceMaxHp: 20,
      );

      final evolved = result.pokemon;
      expect(evolved.speciesId, 'bloomon');
      expect(evolved.natureId, source.natureId);
      expect(evolved.gender, source.gender);
      expect(evolved.ivs, source.ivs);
      expect(evolved.evs, source.evs);
      expect(evolved.isShiny, source.isShiny);
      expect(evolved.heldItemId, source.heldItemId);
      expect(evolved.knownMoveIds, source.knownMoveIds);
      expect(evolved.currentPpByMoveId, source.currentPpByMoveId);
      expect(evolved.experience, source.experience);
      expect(evolved.level, source.level);
      expect(evolved.statusId, source.statusId);
      expect(evolved.abilityId, 'shared_ability');
      expect(result.calculatedStats.maxHp, 30);
      // 15 / 20 of 30 = 22.5, rounded to the nearest integer.
      expect(evolved.currentHp, 23);
    });

    test('falls back to target primary ability when source is incompatible',
        () {
      final result = evolutionService.evolve(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        pokemon: _pokemon(currentHp: 20, abilityId: 'source_only'),
        candidate: _candidate(minLevel: 5),
        sourceMaxHp: 20,
      );

      expect(result.pokemon.abilityId, 'target_primary');
    });

    test('preserves KO, full HP, and clamps a living Pokemon to one HP', () {
      final fainted = evolutionService.evolve(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        pokemon: _pokemon(currentHp: 0),
        candidate: _candidate(minLevel: 5),
        sourceMaxHp: 20,
      );
      final full = evolutionService.evolve(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        pokemon: _pokemon(currentHp: 20),
        candidate: _candidate(minLevel: 5),
        sourceMaxHp: 20,
      );
      final barelyAlive = evolutionService.evolve(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        pokemon: _pokemon(currentHp: 1),
        candidate: _candidate(minLevel: 5, targetHp: 1),
        sourceMaxHp: 9999,
      );

      expect(fainted.pokemon.currentHp, 0);
      expect(full.pokemon.currentHp, full.calculatedStats.maxHp);
      expect(barelyAlive.pokemon.currentHp, 1);
    });

    test('fails closed on source identity, level, or invalid target abilities',
        () {
      expect(
        () => evolutionService.evolve(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          pokemon: _pokemon(currentHp: 20).copyWith(speciesId: 'other'),
          candidate: _candidate(),
          sourceMaxHp: 20,
        ),
        throwsStateError,
      );
      expect(
        () => evolutionService.evolve(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          pokemon: _pokemon(currentHp: 20).copyWith(level: 5),
          candidate: _candidate(minLevel: 6),
          sourceMaxHp: 20,
        ),
        throwsStateError,
      );
      expect(
        () => _candidate(
          targetPrimaryAbilityId: 'absent',
          targetAbilityIds: const <String>['target_primary'],
        ).validated(),
        throwsArgumentError,
      );
    });

    test('evaluates typed friendship, item, and known-move conditions', () {
      final friendly = _pokemon(currentHp: 20).copyWith(friendship: 220);
      final friendshipCandidate = _candidate(
        condition: const PokemonEvolutionCondition.friendship(
          minFriendship: 220,
          minLevel: 5,
        ),
      );
      final itemCandidate = _candidate(
        condition: const PokemonEvolutionCondition.item(
          itemId: 'leaf-stone',
        ),
      );
      final knownMoveCandidate = _candidate(
        condition: const PokemonEvolutionCondition.knownMove(
          moveId: 'growl',
          minLevel: 5,
        ),
      );

      expect(
        friendshipCandidate.isEligible(
          friendly,
          trigger: const PokemonEvolutionTrigger.levelUp(),
        ),
        isTrue,
      );
      expect(
        friendshipCandidate.isEligible(
          friendly.copyWith(friendship: 219),
          trigger: const PokemonEvolutionTrigger.levelUp(),
        ),
        isFalse,
      );
      expect(
        itemCandidate.isEligible(
          friendly,
          trigger: const PokemonEvolutionTrigger.itemUse('leaf-stone'),
        ),
        isTrue,
      );
      expect(
        itemCandidate.isEligible(
          friendly,
          trigger: const PokemonEvolutionTrigger.itemUse('fire-stone'),
        ),
        isFalse,
      );
      expect(
        knownMoveCandidate.isEligible(
          friendly,
          trigger: const PokemonEvolutionTrigger.levelUp(),
        ),
        isTrue,
      );
    });

    test('item evolution consumes one item and preserves ownership metadata',
        () {
      const operations = PokemonEvolutionItemOperations();
      final source = _pokemon(currentHp: 20).copyWith(
        nickname: 'Pousse',
        friendship: 187,
        provenance: const PlayerPokemonProvenance(
          kind: PlayerPokemonOriginKind.captured,
          mapId: 'forest',
          sourceId: 'encounter-1',
          ballItemId: 'poke-ball',
          metLevel: 5,
        ),
      );
      final state = GameState(
        saveId: 'item-evolution',
        party: PlayerParty(members: <PlayerPokemon>[source]),
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'leaf-stone',
              quantity: 2,
            ),
          ],
        ),
      );

      final result = operations.useItem(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        state,
        itemId: 'leaf-stone',
        partyIndex: 0,
        candidate: _candidate(
          condition: const PokemonEvolutionCondition.item(
            itemId: 'leaf-stone',
          ),
        ),
        sourceMaxHp: 20,
        itemCatalog: itemCatalog,
      );

      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.speciesId, 'bloomon');
      expect(result.state.party.members.single.nickname, 'Pousse');
      expect(result.state.party.members.single.friendship, 187);
      expect(result.state.party.members.single.provenance, source.provenance);
      expect(result.state.bag.entries.single.quantity, 1);
      expect(
        result.consumptionReceipt,
        const ItemConsumptionReceipt(
          itemId: 'leaf-stone',
          quantity: 1,
          quantityBefore: 2,
          quantityAfter: 1,
          reason: ItemConsumptionReason.appliedEffect,
        ),
      );
    });

    test('item evolution failure never consumes the item', () {
      const state = GameState(
        saveId: 'item-evolution-failure',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 20,
            ),
          ],
        ),
        bag: Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'fire-stone',
              quantity: 1,
            ),
          ],
        ),
      );

      final result = const PokemonEvolutionItemOperations().useItem(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        state,
        itemId: 'fire-stone',
        partyIndex: 0,
        candidate: _candidate(
          condition: const PokemonEvolutionCondition.item(
            itemId: 'leaf-stone',
          ),
        ),
        sourceMaxHp: 20,
        itemCatalog: itemCatalog,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, PokemonEvolutionItemUseFailure.conditionNotMet);
      expect(result.state, same(state));
      expect(result.state.bag.entries.single.quantity, 1);
      expect(result.consumptionReceipt, isNull);
    });

    test('item evolution cannot consume a key item', () {
      final state = GameState(
        saveId: 'key-item-evolution',
        party: PlayerParty(members: <PlayerPokemon>[_pokemon(currentHp: 20)]),
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(itemId: 'vault-key', quantity: 1),
          ],
        ),
      );

      final result = const PokemonEvolutionItemOperations().useItem(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        state,
        itemId: 'vault-key',
        partyIndex: 0,
        candidate: _candidate(
          condition: const PokemonEvolutionCondition.item(
            itemId: 'vault-key',
          ),
        ),
        sourceMaxHp: 20,
        itemCatalog: itemCatalog,
      );

      expect(result.failure, PokemonEvolutionItemUseFailure.protectedKeyItem);
      expect(result.state, same(state));
      expect(result.consumptionReceipt, isNull);
    });
  });

  group('BattleProgressionService evolution flow', () {
    const service = BattleProgressionService();

    test('offers level evolution only after a real level gain', () {
      final noLevel = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 1, baseExperience: 1),
          ],
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 5)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      final levelUp = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 6)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(noLevel.pendingEvolution, isNull);
      expect(levelUp.pendingEvolution!.opportunityId, 'sproutle:0:6:bloomon');
      expect(
        levelUp.pendingEvolution!.occurrenceId,
        'sproutle:0:6:bloomon:slot:0:levels:5->6',
      );
      expect(levelUp.pendingEvolution!.partySlot, 0);
      expect(levelUp.pendingEvolution!.sourceSpeciesId, 'sproutle');
      expect(levelUp.pendingEvolution!.targetSpeciesId, 'bloomon');
    });

    test('a level gain with no catalog candidate has no pending evolution', () {
      final result = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.state.party.members.single.level, 6);
      expect(result.pendingEvolution, isNull);
      expect(result.remainingEvolutionCount, 0);
    });

    test('friendship and known-move rules are offered after a real level gain',
        () {
      final result = service.apply(
        state: _state(<PlayerPokemon>[
          _pokemon(currentHp: 19).copyWith(friendship: 220),
        ]),
        context: _context(
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[
              _candidate(
                condition: const PokemonEvolutionCondition.friendship(
                  minFriendship: 220,
                  minLevel: 6,
                ),
              ),
              _candidate(
                opportunityId: 'sproutle:knownMove:growl:branchmon',
                targetSpeciesId: 'branchmon',
                condition: const PokemonEvolutionCondition.knownMove(
                  moveId: 'growl',
                  minLevel: 6,
                ),
              ),
            ],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.pendingEvolution, isNotNull);
      expect(result.remainingEvolutionCount, 1);
    });

    test(
        'multi-level gain crosses threshold and decline leaves state unchanged',
        () {
      final pending = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(
          opponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 50, baseExperience: 200),
          ],
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 10)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      final beforeDecline = pending.state;
      final declined = pending.resolvePendingEvolution(
        const BattleEvolutionDecision.refuse(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->11',
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
      );

      expect(pending.state.party.members.single.level, 11);
      expect(declined.state, same(beforeDecline));
      expect(declined.pendingEvolution, isNull);
      expect(
        declined.evolutionChanges.single.kind,
        BattleEvolutionChangeKind.refused,
      );
    });

    test('a refusal can be proposed again on the next later level-up', () {
      final first = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 6)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );
      final firstOccurrenceId = first.pendingEvolution!.occurrenceId;
      final declined = first.resolvePendingEvolution(
        BattleEvolutionDecision.refuse(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: firstOccurrenceId,
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
      );
      final nextLevel = service.apply(
        state: declined.state,
        context: _context(
          oldMaxHp: first.changes.single.calculatedStats.maxHp,
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 6)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(nextLevel.state.party.members.single.level, greaterThan(6));
      expect(nextLevel.pendingEvolution, isNotNull);
      expect(nextLevel.pendingEvolution!.opportunityId, 'sproutle:0:6:bloomon');
      expect(
          nextLevel.pendingEvolution!.occurrenceId, isNot(firstOccurrenceId));
      for (final oldDecision in <BattleEvolutionDecision>[
        BattleEvolutionDecision.accept(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: firstOccurrenceId,
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
        BattleEvolutionDecision.refuse(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: firstOccurrenceId,
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
      ]) {
        expect(
          () => nextLevel.resolvePendingEvolution(oldDecision),
          throwsStateError,
        );
      }
    });

    test('move-learning queue is fully resolved before evolution is exposed',
        () {
      final result = service.apply(
        state: _state(<PlayerPokemon>[
          _pokemon(
            currentHp: 19,
            knownMoveIds: const <String>['one', 'two', 'three', 'four'],
            currentPpByMoveId: const <String, int>{
              'one': 1,
              'two': 2,
              'three': 3,
              'four': 4,
            },
          ),
        ]),
        context: _context(
          moveCandidatesBySlot: const <int, List<PokemonMoveLearningCandidate>>{
            0: <PokemonMoveLearningCandidate>[
              PokemonMoveLearningCandidate(
                opportunityId: 'sproutle:move:6:new_move',
                moveId: 'new_move',
                learnedAtLevel: 6,
                maxPp: 10,
              ),
            ],
          },
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[_candidate(minLevel: 6)],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.pendingMoveLearning, isNotNull);
      expect(result.pendingEvolution, isNull);
      final afterMove = result.resolvePendingMoveLearning(
        const BattleMoveLearningDecision.decline(
          opportunityId: 'sproutle:move:6:new_move',
          partySlot: 0,
          moveId: 'new_move',
        ),
      );
      expect(afterMove.pendingMoveLearning, isNull);
      expect(afterMove.pendingEvolution, isNotNull);
    });

    test('accept uses exact identity, persists, and discards source branches',
        () {
      final pending = service.apply(
        state: _state(<PlayerPokemon>[_pokemon(currentHp: 19)]),
        context: _context(
          evolutionCandidatesBySlot: <int, List<PokemonEvolutionCandidate>>{
            0: <PokemonEvolutionCandidate>[
              _candidate(minLevel: 6),
              _candidate(
                opportunityId: 'sproutle:1:6:branchmon',
                targetSpeciesId: 'branchmon',
                minLevel: 6,
              ),
            ],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      for (final staleDecision in const <BattleEvolutionDecision>[
        BattleEvolutionDecision.accept(
          opportunityId: 'stale_token',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
        BattleEvolutionDecision.accept(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 1,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
        BattleEvolutionDecision.accept(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 0,
          sourceSpeciesId: 'stale_source',
          targetSpeciesId: 'bloomon',
        ),
        BattleEvolutionDecision.accept(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'stale_target',
        ),
      ]) {
        expect(
          () => pending.resolvePendingEvolution(staleDecision),
          throwsStateError,
        );
      }
      final accepted = pending.resolvePendingEvolution(
        const BattleEvolutionDecision.accept(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
      );

      expect(accepted.state.party.members.single.speciesId, 'bloomon');
      expect(accepted.pendingEvolution, isNull);
      expect(accepted.remainingEvolutionCount, 0);
      expect(
        accepted.evolutionChanges.single.kind,
        BattleEvolutionChangeKind.evolved,
      );
      final reloaded = normalizeLoadedGameState(
        gameStateFromSaveData(
          SaveData.fromJson(saveDataFromGameState(accepted.state).toJson()),
        ),
      );
      expect(reloaded.party.members.single.speciesId, 'bloomon');
    });

    test('orders multiple participant opportunities by party slot', () {
      final result = service.apply(
        state: _state(<PlayerPokemon>[
          _pokemon(currentHp: 19),
          _pokemon(
            speciesId: 'embercub',
            abilityId: 'blaze',
            currentHp: 19,
          ),
        ]),
        context: BattleProgressionContext(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          outcome: BattleProgressionOutcomeKind.victory,
          playerParticipantPartySlots: const <int>{1, 0},
          defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
            BattleProgressionDefeatedOpponent(level: 28, baseExperience: 70),
          ],
          partySlotMetadata: <BattleProgressionPartySlotMetadata>[
            _metadata(1),
            _metadata(0),
          ],
          evolutionCandidatesByPartySlot: <int,
              List<PokemonEvolutionCandidate>>{
            1: <PokemonEvolutionCandidate>[
              _candidate(
                opportunityId: 'embercub:0:6:pyromon',
                sourceSpeciesId: 'embercub',
                targetSpeciesId: 'pyromon',
                targetPrimaryAbilityId: 'blaze',
                targetAbilityIds: const <String>['blaze'],
              ),
            ],
            0: <PokemonEvolutionCandidate>[_candidate()],
          },
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(result.pendingEvolution!.partySlot, 0);
      final declinedFirst = result.resolvePendingEvolution(
        const BattleEvolutionDecision.refuse(
          opportunityId: 'sproutle:0:6:bloomon',
          occurrenceId: 'sproutle:0:6:bloomon:slot:0:levels:5->6',
          partySlot: 0,
          sourceSpeciesId: 'sproutle',
          targetSpeciesId: 'bloomon',
        ),
      );
      expect(declinedFirst.pendingEvolution!.partySlot, 1);
    });

    test('public result rejects duplicate occurrence identity per slot', () {
      final state = _state(<PlayerPokemon>[_pokemon(currentHp: 19)]);
      final candidate = _candidate(minLevel: 5);
      final opportunity = BattleEvolutionOpportunity(
        occurrenceId: 'battle:slot:0:levels:4->5',
        partySlot: 0,
        candidate: candidate,
        sourceMaxHp: 20,
      );

      expect(
        () => BattleProgressionResult(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
          state: state,
          appliedReward: BattleReward(
            sourceKind: BattleRewardSourceKind.wild,
          ),
          changes: const <BattlePokemonProgressionChange>[],
          evolutionOpportunities: <BattleEvolutionOpportunity>[
            opportunity,
            opportunity,
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

PokemonEvolutionCandidate _candidate({
  String opportunityId = 'sproutle:0:6:bloomon',
  String sourceSpeciesId = 'sproutle',
  String targetSpeciesId = 'bloomon',
  int minLevel = 6,
  PokemonEvolutionCondition? condition,
  int targetHp = 95,
  String targetPrimaryAbilityId = 'target_primary',
  List<String> targetAbilityIds = const <String>['target_primary'],
}) {
  return PokemonEvolutionCandidate(
    opportunityId: opportunityId,
    sourceSpeciesId: sourceSpeciesId,
    targetSpeciesId: targetSpeciesId,
    minLevel: condition == null ? minLevel : null,
    condition: condition,
    targetBaseStats: PokemonBaseStats(
      hp: targetHp,
      attack: 80,
      defense: 70,
      specialAttack: 90,
      specialDefense: 80,
      speed: 60,
    ),
    targetPrimaryAbilityId: targetPrimaryAbilityId,
    targetAbilityIds: targetAbilityIds,
  );
}

PlayerPokemon _pokemon({
  String speciesId = 'sproutle',
  String abilityId = 'overgrow',
  int currentHp = 19,
  List<String> knownMoveIds = const <String>['tackle', 'growl'],
  Map<String, int>? currentPpByMoveId = const <String, int>{
    'tackle': 7,
    'growl': 4,
  },
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'bold',
    abilityId: abilityId,
    gender: 'female',
    level: 5,
    ivs: const PokemonStatSpread(
      hp: 31,
      attack: 12,
      defense: 20,
      specialAttack: 24,
      specialDefense: 18,
      speed: 9,
    ),
    evs: const PokemonStatSpread(
      hp: 20,
      attack: 4,
      defense: 8,
      specialAttack: 12,
      specialDefense: 16,
      speed: 24,
    ),
    knownMoveIds: knownMoveIds,
    experience: 125,
    currentPpByMoveId: currentPpByMoveId,
    currentHp: currentHp,
    statusId: 'poison',
    isShiny: true,
    heldItemId: 'oran_berry',
  );
}

GameState _state(List<PlayerPokemon> members) {
  return GameState(
    saveId: 'evolution-test',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(members: members),
  );
}

BattleProgressionContext _context({
  List<BattleProgressionDefeatedOpponent> opponents =
      const <BattleProgressionDefeatedOpponent>[
    BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
  ],
  int oldMaxHp = 20,
  Map<int, List<PokemonMoveLearningCandidate>> moveCandidatesBySlot =
      const <int, List<PokemonMoveLearningCandidate>>{},
  Map<int, List<PokemonEvolutionCandidate>> evolutionCandidatesBySlot =
      const <int, List<PokemonEvolutionCandidate>>{},
}) {
  return BattleProgressionContext(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: opponents,
    partySlotMetadata: <BattleProgressionPartySlotMetadata>[
      _metadata(0, oldMaxHp: oldMaxHp),
    ],
    moveLearningCandidatesByPartySlot: moveCandidatesBySlot,
    evolutionCandidatesByPartySlot: evolutionCandidatesBySlot,
  );
}

BattleProgressionPartySlotMetadata _metadata(
  int slot, {
  int oldMaxHp = 20,
}) {
  return BattleProgressionPartySlotMetadata(
    partySlot: slot,
    growthRateId: 'medium',
    oldMaxHp: oldMaxHp,
    baseStats: const PokemonBaseStats(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
  );
}
