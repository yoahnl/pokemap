import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonStorage box migration', () {
    test('migrates legacy flat storage to a deterministic canonical box', () {
      final storage = PokemonStorage.fromJson(<String, dynamic>{
        'storedPokemon': <Map<String, dynamic>>[
          const PlayerPokemon(
            speciesId: 'pidgey',
            natureId: 'docile',
            abilityId: 'keen-eye',
          ).toJson(),
        ],
      }).normalized();

      final json = storage.toJson();

      expect(json, isNot(contains('storedPokemon')));
      expect(json['boxes'], isA<List<dynamic>>());
      expect(
        (json['boxes'] as List<dynamic>).first,
        containsPair('id', 'box-01'),
      );
    });

    test('creates stable bounded boxes and rejects duplicate ids or overflow',
        () {
      final storage = const PokemonStorage().normalized();

      expect(storage.boxes, hasLength(defaultPokemonBoxCount));
      expect(storage.boxes.first.id, 'box-01');
      expect(storage.boxes.last.id, 'box-08');
      expect(
        storage.boxes.every((box) => box.capacity == pokemonBoxCapacity),
        isTrue,
      );
      expect(
        () => PokemonStorage(
          boxes: <PokemonBox>[
            const PokemonBox(id: 'same', label: 'A'),
            const PokemonBox(id: 'same', label: 'B'),
          ],
        ).normalized(),
        throwsStateError,
      );
      expect(
        () => PokemonBox(
          id: 'box',
          label: 'Box',
          capacity: 1,
          pokemon: <PlayerPokemon>[
            _storedPokemon('one'),
            _storedPokemon('two'),
          ],
        ).normalized(),
        throwsStateError,
      );
    });

    test('round-trips box ids, order, capacity and Pokemon without loss', () {
      final storage = PokemonStorage(
        boxes: <PokemonBox>[
          PokemonBox(
            id: 'favorites',
            label: 'Favoris',
            capacity: 2,
            pokemon: <PlayerPokemon>[_storedPokemon('eevee')],
          ),
          const PokemonBox(id: 'reserve', label: 'Réserve', capacity: 4),
        ],
      ).normalized();

      final restored = PokemonStorage.fromJson(storage.toJson());

      expect(restored, storage);
      expect(restored.storedPokemon.single.speciesId, 'eevee');
    });
  });

  group('gameStateFromSaveData', () {
    test('migrates legacy save fields to GameState', () {
      const save = SaveData(
        saveId: 'legacy_1',
        currentMapId: 'vova_center',
        playerPosition: GridPos(x: 7, y: 9),
        playerFacing: EntityFacing.west,
        party: PlayerParty(
          members: [
            PlayerPokemon(
              speciesId: 'lapras',
              natureId: 'modest',
              abilityId: 'water-absorb',
              knownMoveIds: ['surf'],
            ),
          ],
        ),
        trainerProfile: TrainerProfile(
          name: 'Red',
          badgeIds: ['boulder'],
          money: 1200,
          playtimeSeconds: 42,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', quantity: 3),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['met_professor', 'starter_received'],
          completedStepIds: ['step_a'],
        ),
        properties: {'legacy': 'ok'},
      );

      final state = gameStateFromSaveData(save);

      expect(state.saveId, equals('legacy_1'));
      expect(state.currentMapId, equals('vova_center'));
      expect(state.playerPosition, equals(const GridPos(x: 7, y: 9)));
      expect(state.playerFacing, equals(EntityFacing.west));
      expect(state.party.members.length, equals(1));
      expect(state.trainerProfile.name, equals('Red'));
      expect(state.bag.entries.single.itemId, equals('poke-ball'));
      expect(state.progression.unlockedFieldAbilities,
          contains(FieldAbility.surf));
      expect(state.storyFlags.activeFlags,
          containsAll(['met_professor', 'starter_received']));
      expect(state.progression.completedStepIds, ['step_a']);
      expect(state.progression.caughtSpeciesIds, ['lapras']);
      expect(state.progression.seenSpeciesIds, ['lapras']);
      expect(state.metadata['legacy'], equals('ok'));
    });

    test('preserves Fact overrides without inferring legacy flags', () {
      final save = SaveData(
        saveId: 'fact_save',
        progression: const PlayerProgression(
          storyFlags: ['legacy_fact_alias'],
        ),
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_default_true': false,
            'fact_orphan': true,
          },
        ),
      );

      final state = gameStateFromSaveData(save);

      expect(state.narrativeFactRuntimeState, save.narrativeFactRuntimeState);
      expect(state.storyFlags.activeFlags, {'legacy_fact_alias'});
      expect(
        state.narrativeFactRuntimeState.overridesByFactId,
        isNot(contains('legacy_fact_alias')),
      );
      expect(state.consumedEventIds, isEmpty);
    });
  });

  group('saveDataFromGameState', () {
    test('keeps core fields and merges story flags in legacy slot', () {
      final state = GameState(
        saveId: 'save_2',
        currentMapId: 'route_1',
        playerPosition: const GridPos(x: 3, y: 4),
        playerFacing: EntityFacing.north,
        trainerProfile: const TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade', 'boulder'],
          money: 500,
          playtimeSeconds: 99,
        ),
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', quantity: 2),
            BagEntry(itemId: 'poke-ball', quantity: 5),
          ],
        ),
        progression: const PlayerProgression(
          storyFlags: ['from_progression'],
          completedStepIds: ['step_done'],
        ),
        storyFlags: const StoryFlags(activeFlags: {'from_story_flags'}),
      );

      final save = saveDataFromGameState(state);

      expect(save.saveId, equals('save_2'));
      expect(save.currentMapId, equals('route_1'));
      expect(save.playerPosition, equals(const GridPos(x: 3, y: 4)));
      expect(save.playerFacing, equals(EntityFacing.north));
      expect(save.trainerProfile.name, equals('Leaf'));
      expect(save.trainerProfile.badgeIds, equals(['boulder', 'cascade']));
      expect(save.bag.entries.length, equals(2));
      expect(
        save.progression.storyFlags.toSet(),
        containsAll(<String>{'from_progression', 'from_story_flags'}),
      );
      expect(save.progression.completedStepIds, ['step_done']);
    });

    test('syncs party species into caught and seen for persistence', () {
      const state = GameState(
        saveId: 'save_seen_caught',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'bold',
              abilityId: 'overgrow',
            ),
            PlayerPokemon(
              speciesId: 'charmander',
              natureId: 'timid',
              abilityId: 'blaze',
            ),
          ],
        ),
        progression: PlayerProgression(
          seenSpeciesIds: ['pikachu'],
          caughtSpeciesIds: ['pikachu'],
        ),
      );

      final save = saveDataFromGameState(state);

      expect(
        save.progression.caughtSpeciesIds,
        containsAll(<String>['bulbasaur', 'charmander', 'pikachu']),
      );
      expect(
        save.progression.seenSpeciesIds,
        containsAll(<String>['bulbasaur', 'charmander', 'pikachu']),
      );
    });

    test('preserves Pokemon experience and current PP through save reload', () {
      final pokemon = PlayerPokemon.fromJson({
        'speciesId': 'wartortle',
        'natureId': 'bold',
        'abilityId': 'torrent',
        'level': 16,
        'knownMoveIds': ['water_gun'],
        'experience': 2535,
        'currentPpByMoveId': {'water_gun': 12},
      });
      final state = GameState(
        saveId: 'pokemon_progression_round_trip',
        party: PlayerParty(members: [pokemon]),
      );

      final reloaded = gameStateFromSaveData(saveDataFromGameState(state));
      final reloadedJson = reloaded.party.members.single.toJson();

      expect(reloadedJson['experience'], 2535);
      expect(reloadedJson['currentPpByMoveId'], {'water_gun': 12});
    });

    test('syncs stored species into caught and seen for persistence', () {
      const state = GameState(
        saveId: 'save_storage_seen_caught',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'bold',
              abilityId: 'overgrow',
            ),
          ],
        ),
        pokemonStorage: PokemonStorage(
          storedPokemon: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'stored_pidgey',
              natureId: 'hardy',
              abilityId: 'keen-eye',
            ),
          ],
        ),
      );

      final save = saveDataFromGameState(state);
      final reloaded = normalizeLoadedGameState(gameStateFromSaveData(save));

      expect(
          save.pokemonStorage.storedPokemon.single.speciesId, 'stored_pidgey');
      expect(reloaded.pokemonStorage.storedPokemon.single.speciesId,
          'stored_pidgey');
      expect(
        reloaded.progression.caughtSpeciesIds,
        containsAll(<String>['bulbasaur', 'stored_pidgey']),
      );
      expect(
        reloaded.progression.seenSpeciesIds,
        containsAll(<String>['bulbasaur', 'stored_pidgey']),
      );
    });

    test('round-trips Fact overrides without repurposing legacy event IDs', () {
      final state = GameState(
        saveId: 'fact_round_trip',
        storyFlags: const StoryFlags(activeFlags: {'legacy_flag'}),
        consumedEventIds: const {'legacy_event'},
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_default_true': false,
            'fact_orphan': true,
          },
        ),
      );

      final save = saveDataFromGameState(state);
      final restored = gameStateFromSaveData(save);

      expect(
          restored.narrativeFactRuntimeState, state.narrativeFactRuntimeState);
      expect(restored.storyFlags.activeFlags, {'legacy_flag'});
      expect(state.consumedEventIds, {'legacy_event'});
      expect(restored.consumedEventIds, isEmpty);
    });
  });

  group('normalizeLoadedGameState', () {
    test('hydrates storyFlags from progression when storyFlags are empty', () {
      final state = GameState(
        saveId: 'save_3',
        progression: const PlayerProgression(
          storyFlags: ['trainer_defeated:gym_leader_1', 'badge_cascade'],
        ),
        storyFlags: const StoryFlags(activeFlags: <String>{}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(
        normalized.storyFlags.activeFlags,
        containsAll(['trainer_defeated:gym_leader_1', 'badge_cascade']),
      );
    });

    test('keeps explicit storyFlags as source of truth when already set', () {
      final state = GameState(
        saveId: 'save_4',
        progression: const PlayerProgression(storyFlags: ['legacy_flag']),
        storyFlags: const StoryFlags(activeFlags: {'runtime_flag'}),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.storyFlags.activeFlags, equals({'runtime_flag'}));
    });

    test('keeps Fact overrides and legacy flags unchanged', () {
      final state = GameState(
        saveId: 'fact_normalize',
        progression: const PlayerProgression(storyFlags: ['legacy_flag']),
        storyFlags: const StoryFlags(activeFlags: {'runtime_flag'}),
        consumedEventIds: const {'legacy_event'},
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {'fact_orphan': false},
        ),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.narrativeFactRuntimeState,
          state.narrativeFactRuntimeState);
      expect(normalized.storyFlags, state.storyFlags);
      expect(normalized.progression.storyFlags, state.progression.storyFlags);
      expect(normalized.consumedEventIds, state.consumedEventIds);
    });

    test('hydrates caught and seen from party for legacy states', () {
      const state = GameState(
        saveId: 'save_legacy_seen',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'mew',
              natureId: 'calm',
              abilityId: 'synchronize',
            ),
          ],
        ),
      );

      final normalized = normalizeLoadedGameState(state);

      expect(normalized.progression.caughtSpeciesIds, equals(['mew']));
      expect(normalized.progression.seenSpeciesIds, equals(['mew']));
    });

    test('markSpeciesSeenInGameState adds seen without inventing caught', () {
      const state = GameState(
        saveId: 'save_seen_only',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'bold',
              abilityId: 'overgrow',
            ),
          ],
        ),
      );

      final updated = markSpeciesSeenInGameState(state, 'zubat');

      expect(updated.progression.caughtSpeciesIds, equals(['bulbasaur']));
      expect(
        updated.progression.seenSpeciesIds,
        equals(['bulbasaur', 'zubat']),
      );
    });
  });

  group('NarrativeEventProgress persistence', () {
    test('propagates V2 progress without migrating legacy namespaces', () {
      final progress = NarrativeEventProgress(
        consumedNarrativeEventIds: const {
          'evt_019abcde-0000-7000-8000-000000000001',
        },
        pendingNarrativeOutcomeDeliveries: [
          NarrativeOutcomeDelivery(
            deliveryId: 'outd_019abcde-0000-7000-8000-000000000001',
            outcome: NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: 'scene',
              outcomeId: 'done',
            ),
            rootCorrelationId: 'corr_019abcde-0000-7000-8000-000000000001',
            depth: 0,
            attemptCount: 0,
          ),
        ],
      );
      final state = GameState(
        saveId: 'progress',
        consumedEventIds: const {'legacy_local'},
        storyFlags: const StoryFlags(activeFlags: {'legacy_flag'}),
        narrativeEventProgress: progress,
      );

      final save = saveDataFromGameState(state);
      final restored = gameStateFromSaveData(save);
      final normalized = normalizeLoadedGameState(restored);

      expect(save.narrativeEventProgress, progress);
      expect(restored.narrativeEventProgress, progress);
      expect(normalized.narrativeEventProgress, progress);
      expect(state.consumedEventIds, {'legacy_local'});
      expect(restored.consumedEventIds, isEmpty);
      expect(restored.storyFlags.activeFlags, {'legacy_flag'});
    });
  });
}

PlayerPokemon _storedPokemon(String speciesId) => PlayerPokemon(
      speciesId: speciesId,
      natureId: 'docile',
      abilityId: 'ability',
    );
