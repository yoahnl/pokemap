import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

RuntimeScenePokemonCatalog giftCatalog() => RuntimeScenePokemonCatalog(
  entries: {
    'clockbird': RuntimeScenePokemonCatalogEntry(
      species: const WildPokemonGenerationSpecies(
        id: 'clockbird',
        formId: 'bronze',
        baseStats: PokemonBaseStats(
          hp: 81,
          attack: 72,
          defense: 63,
          specialAttack: 54,
          specialDefense: 45,
          speed: 36,
        ),
        primaryAbilityId: 'clockwork',
        standardAbilityIds: ['clockwork'],
        allowedAbilityIds: ['clockwork'],
        genderRatio: {'male': 1, 'female': 1},
        growthRateId: 'medium_fast',
        baseFriendship: 42,
      ),
      learnset: const WildPokemonGenerationLearnset(
        startingMoves: ['tick'],
        levelUp: [WildPokemonLevelUpMove(moveId: 'tock', level: 6)],
      ),
      maxPpByMoveId: const {'tick': 13, 'tock': 19},
    ),
  },
);

SceneReceivePokemonFromCatalogInteractiveCommand giftCommand({
  bool offer = true,
  bool dex = false,
}) => SceneReceivePokemonFromCatalogInteractiveCommand(
  speciesId: 'clockbird',
  formId: 'bronze',
  level: 7,
  nicknamePolicy: offer
      ? ScenePokemonGiftNicknamePolicy.offer
      : ScenePokemonGiftNicknamePolicy.disabled,
  nicknameMaxGraphemes: 10,
  pokedexPresentationPolicy: dex
      ? ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible
      : ScenePokemonGiftPokedexPresentationPolicy.never,
);

void main() {
  const project = ProjectManifest(name: 'Gift', maps: [], tilesets: []);
  const initial = GameState(saveId: 'gift', currentMapId: 'lab');

  for (final nickname in [null, '', '   ', ' Horloge ', 'Horloge', '👩‍🚀' * 10]) {
    test(
      'stages nickname=$nickname without state write and commits exact native Pokemon',
      () async {
        final stages = <String>[];
        PlayerPokemon? destinationPokemon;
        final catalog = giftCatalog();
        final result = await receiveScenePokemonFromCatalog(
          command: giftCommand(),
          operationId: 'scene:gift:run:node',
          project: project,
          readProjectedState: () => initial,
          catalog: catalog,
          present: (request) async {
            stages.add(request.stage.name);
            if (request.stage == PokemonGiftInteractionStage.destination) {
              destinationPokemon = request.pokemon;
            }
            final interaction = request.interaction;
            return switch (interaction) {
              SceneConfirmationInteractionRequest() =>
                SceneInteractionResult.confirmed(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  value: nickname != null,
                ),
              SceneTextInteractionRequest() =>
                SceneInteractionResult.textSubmitted(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  value: nickname!,
                ),
              _ => SceneInteractionResult.acknowledged(
                requestId: interaction.requestId,
                revision: interaction.revision,
              ),
            };
          },
        );
        expect(initial.party.members, isEmpty);
        expect(result.outputPortId, 'party');
        expect(stages, [
          'received',
          'nicknameConfirmation',
          if (nickname != null) 'nickname',
          'destination',
        ]);
        final prepared = result.prepared!;
        final applied = prepared.commit(
          initial,
          catalog: catalog,
          project: project,
        );
        expect(applied.party.members.single, prepared.pokemon);
        expect(destinationPokemon, prepared.pokemon);
        expect(applied.party.members.single.nickname, nickname?.trim() ?? '');
        expect(applied.party.members.single.knownMoveIds, ['tick', 'tock']);
        expect(applied.progression.caughtSpeciesIds, contains('clockbird'));
        expect(applied.appliedPokemonGrantOperationIds, {
          'scene:gift:run:node',
        });
        final reloaded = GameState.fromJson(
          jsonDecode(jsonEncode(applied.toJson())) as Map<String, dynamic>,
        );
        expect(reloaded.party, applied.party);
        final replay = await receiveScenePokemonFromCatalog(
          command: giftCommand(),
          operationId: 'scene:gift:run:node',
          project: project,
          readProjectedState: () => reloaded,
          catalog: catalog,
          present: (_) => throw StateError('Replay must not redraw'),
        );
        expect(replay.outputPortId, 'party');
        expect(replay.prepared, isNull);
      },
    );
  }

  for (final mode in [
    'visible',
    'hidden',
    'caught',
    'projectHidden',
    'overrideVisible',
  ]) {
    test('Pokedex presentation obeys native availability mode=$mode', () async {
      final stages = <PokemonGiftInteractionStage>[];
      final manifest = project.copyWith(
        presentation: ProjectPresentationProfile(
          pause: ProjectPausePresentationProfile(
            actions: [
              ProjectPauseActionProfile(
                id: ProjectPauseActionId.pokedex,
                visible: mode != 'projectHidden' && mode != 'overrideVisible',
              ),
            ],
          ),
        ),
      );
      final state = initial.copyWith(
        progression: PlayerProgression(
          caughtSpeciesIds: mode == 'caught' ? ['clockbird'] : [],
        ),
        pauseMenuState: PlayerPauseMenuState(
          visibilityOverrides: {
            if (mode == 'hidden') ProjectPauseActionId.pokedex: false,
            if (mode == 'overrideVisible') ProjectPauseActionId.pokedex: true,
          },
        ),
      );
      final result = await receiveScenePokemonFromCatalog(
        command: giftCommand(offer: false, dex: true),
        operationId: 'dex',
        project: manifest,
        readProjectedState: () => state,
        catalog: giftCatalog(),
        present: (request) async {
          stages.add(request.stage);
          return SceneInteractionResult.acknowledged(
            requestId: request.interaction.requestId,
            revision: request.interaction.revision,
          );
        },
      );
      expect(
        stages.contains(PokemonGiftInteractionStage.pokedex),
        ['visible', 'overrideVisible'].contains(mode),
      );
      expect(result.prepared, isNotNull);
      expect(state.party.members, isEmpty);
    });
  }

  test(
    'invalid catalog stays a technical failure and is never noCapacity',
    () async {
      await expectLater(
        receiveScenePokemonFromCatalog(
          command: giftCommand(offer: false),
          operationId: 'bad',
          project: project,
          readProjectedState: () => initial,
          catalog: RuntimeScenePokemonCatalog(entries: {}),
          present: (_) => throw StateError('must not present'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'party then PC and storage full are typed with no consumption on refusal',
    () async {
      final catalog = giftCatalog();
      final seed = catalog.generate(
        consequence: SceneGivePokemonFromCatalogConsequence(
          speciesId: 'clockbird',
          formId: 'bronze',
          level: 7,
        ),
        state: initial,
        operationId: 'seed',
        ruleset: project.pokemon.ruleset,
      );
      var full = initial;
      for (var i = 0; i < 6; i++) {
        full = const GameStateMutations().givePokemonOnce(
          full,
          grantOperationId: 'seed$i',
          pokemon: seed,
        );
      }
      Future<SceneInteractionResult> acknowledge(
        OpenPokemonGiftInteractionService request,
      ) async => SceneInteractionResult.acknowledged(
        requestId: request.interaction.requestId,
        revision: request.interaction.revision,
      );
      final pc = await receiveScenePokemonFromCatalog(
        command: giftCommand(offer: false),
        operationId: 'pc',
        project: project,
        readProjectedState: () => full,
        catalog: catalog,
        present: acknowledge,
      );
      expect(pc.outputPortId, 'pc');
      final committed = pc.prepared!.commit(
        full,
        catalog: catalog,
        project: project,
      );
      expect(
        committed.pokemonStorage.storedPokemon.single,
        pc.prepared!.pokemon,
      );
      final noRoom = full.copyWith(
        pokemonStorage: PokemonStorage(
          boxes: [
            PokemonBox(
              id: 'full',
              label: 'Full',
              capacity: 1,
              pokemon: [seed.copyWith(individualId: 'box')],
            ),
          ],
        ),
      );
      final refused = await receiveScenePokemonFromCatalog(
        command: giftCommand(offer: false),
        operationId: 'refused',
        project: project,
        readProjectedState: () => noRoom,
        catalog: catalog,
        present: acknowledge,
      );
      expect(refused.outputPortId, 'noCapacity');
      expect(refused.prepared, isNull);
      expect(
        noRoom.appliedPokemonGrantOperationIds,
        isNot(contains('refused')),
      );
      expect(noRoom.progression, full.progression);
    },
  );

  test(
    'technical dismissal and stale replies fail without prepared mutation',
    () async {
      for (final stale in [false, true]) {
        await expectLater(
          receiveScenePokemonFromCatalog(
            command: giftCommand(),
            operationId: 'op',
            project: project,
            readProjectedState: () => initial,
            catalog: giftCatalog(),
            present: (request) async => stale
                ? SceneInteractionResult.acknowledged(
                    requestId: 'old',
                    revision: 0,
                  )
                : SceneInteractionResult.cancelled(
                    requestId: request.interaction.requestId,
                    revision: request.interaction.revision,
                    reason: SceneInteractionCancellationReason.disposed,
                  ),
          ),
          throwsStateError,
        );
      }
    },
  );

  test(
    'oversize nickname and changed capacity reject instead of noCapacity',
    () async {
      await expectLater(
        receiveScenePokemonFromCatalog(
          command: giftCommand(),
          operationId: 'op',
          project: project,
          readProjectedState: () => initial,
          catalog: giftCatalog(),
          present: (request) async {
            final i = request.interaction;
            if (i is SceneConfirmationInteractionRequest) {
              return SceneInteractionResult.confirmed(
                requestId: i.requestId,
                revision: i.revision,
                value: true,
              );
            }
            if (i is SceneTextInteractionRequest) {
              return SceneInteractionResult.textSubmitted(
                requestId: i.requestId,
                revision: i.revision,
                value: '12345678901',
              );
            }
            return SceneInteractionResult.acknowledged(
              requestId: i.requestId,
              revision: i.revision,
            );
          },
        ),
        throwsStateError,
      );
      final catalog = giftCatalog();
      final result = await receiveScenePokemonFromCatalog(
        command: giftCommand(offer: false),
        operationId: 'op',
        project: project,
        readProjectedState: () => initial,
        catalog: catalog,
        present: (r) async => SceneInteractionResult.acknowledged(
          requestId: r.interaction.requestId,
          revision: r.interaction.revision,
        ),
      );
      final unrelated = const GameStateMutations().addMoney(initial, 25);
      expect(
        result.prepared!
            .commit(unrelated, catalog: catalog, project: project)
            .trainerProfile
            .money,
        25,
      );
      final changed = const GameStateMutations().givePokemonOnce(
        initial,
        grantOperationId: 'other',
        pokemon: result.prepared!.pokemon,
      );
      expect(
        () => result.prepared!.commit(
          changed,
          catalog: catalog,
          project: project,
        ),
        throwsStateError,
      );
    },
  );
}
