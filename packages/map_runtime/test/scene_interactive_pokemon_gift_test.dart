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

  test(
    'one prepared receipt offers nickname and cancellation preserves gift',
    () async {
      final stages = <PokemonGiftInteractionStage>[];
      final names = <String>[];
      var receipts = 0;
      final catalog = giftCatalog();
      final result = await receiveScenePokemonFromCatalog(
        command: giftCommand(dex: true),
        operationId: 'receipt',
        project: project,
        readProjectedState: () => initial,
        catalog: catalog,
        present: (request) async {
          stages.add(request.stage);
          names.add(request.pokemon.nickname);
          expect(initial.party.members, isEmpty);
          final interaction = request.interaction;
          if (request.stage == PokemonGiftInteractionStage.received) {
            expect(interaction, isA<SceneChoiceInteractionRequest>());
            receipts += 1;
            return SceneInteractionResult.choiceSelected(
              requestId: interaction.requestId,
              revision: interaction.revision,
              selectedOptionId: receipts == 1 ? 'nickname' : 'continue',
            );
          }
          expect(request.stage, PokemonGiftInteractionStage.nickname);
          return SceneInteractionResult.cancelled(
            requestId: interaction.requestId,
            revision: interaction.revision,
            reason: SceneInteractionCancellationReason.user,
          );
        },
      );

      expect(stages, [
        PokemonGiftInteractionStage.received,
        PokemonGiftInteractionStage.nickname,
        PokemonGiftInteractionStage.received,
      ]);
      expect(names, ['', '', '']);
      final committed = result.prepared!.commit(
        initial,
        catalog: catalog,
        project: project,
      );
      expect(committed.party.members.single.nickname, '');
      expect(committed.progression.caughtSpeciesIds, contains('clockbird'));
      expect(committed.appliedPokemonGrantOperationIds, {'receipt'});
    },
  );

  test(
    'cancelling another nickname keeps the last validated name and identity',
    () async {
      var receipts = 0;
      var nicknameEntries = 0;
      String? individualId;
      final revisions = <int>[];
      final result = await receiveScenePokemonFromCatalog(
        command: giftCommand(),
        operationId: 'rename-again',
        project: project,
        readProjectedState: () => initial,
        catalog: giftCatalog(),
        present: (request) async {
          individualId ??= request.pokemon.individualId;
          expect(request.pokemon.individualId, individualId);
          expect(request.projectedState.party.members.single, request.pokemon);
          final interaction = request.interaction;
          revisions.add(interaction.revision);
          if (interaction is SceneChoiceInteractionRequest) {
            receipts += 1;
            if (receipts > 1) expect(request.pokemon.nickname, 'Pendule');
            return SceneInteractionResult.choiceSelected(
              requestId: interaction.requestId,
              revision: interaction.revision,
              selectedOptionId: receipts < 3 ? 'nickname' : 'continue',
            );
          }
          final text = interaction as SceneTextInteractionRequest;
          nicknameEntries += 1;
          if (nicknameEntries == 1) {
            expect(text.initialValue, '');
            return SceneInteractionResult.textSubmitted(
              requestId: text.requestId,
              revision: text.revision,
              value: 'Pendule',
            );
          }
          expect(text.initialValue, 'Pendule');
          return SceneInteractionResult.cancelled(
            requestId: text.requestId,
            revision: text.revision,
            reason: SceneInteractionCancellationReason.user,
          );
        },
      );
      expect(revisions, [0, 1, 2, 3, 4]);
      expect(initial.party.members, isEmpty);
      expect(result.prepared!.pokemon.nickname, 'Pendule');
      expect(result.prepared!.pokemon.individualId, individualId);
    },
  );

  test('stale nickname cancellation cannot preserve a prepared gift', () async {
    await expectLater(
      receiveScenePokemonFromCatalog(
        command: giftCommand(),
        operationId: 'stale-nickname',
        project: project,
        readProjectedState: () => initial,
        catalog: giftCatalog(),
        present: (request) async {
          final interaction = request.interaction;
          if (interaction is SceneChoiceInteractionRequest) {
            return SceneInteractionResult.choiceSelected(
              requestId: interaction.requestId,
              revision: interaction.revision,
              selectedOptionId: 'nickname',
            );
          }
          return SceneInteractionResult.cancelled(
            requestId: interaction.requestId,
            revision: interaction.revision - 1,
            reason: SceneInteractionCancellationReason.user,
          );
        },
      ),
      throwsStateError,
    );
    expect(initial.party.members, isEmpty);
    expect(initial.appliedPokemonGrantOperationIds, isEmpty);
  });

  for (final nickname in [
    null,
    '',
    '   ',
    ' Horloge ',
    'Horloge',
    '👩‍🚀' * 10,
  ]) {
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
            if (request.stage == PokemonGiftInteractionStage.received) {
              destinationPokemon = request.pokemon;
            }
            final interaction = request.interaction;
            return switch (interaction) {
              SceneChoiceInteractionRequest() =>
                SceneInteractionResult.choiceSelected(
                  requestId: interaction.requestId,
                  revision: interaction.revision,
                  selectedOptionId:
                      nickname != null && interaction.revision == 0
                      ? 'nickname'
                      : 'continue',
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
          if (nickname != null) ...['nickname', 'received'],
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
      final newEntries = <bool>[];
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
          newEntries.add(request.isNewPokedexEntry);
          expect(request.stage, PokemonGiftInteractionStage.received);
          return SceneInteractionResult.acknowledged(
            requestId: request.interaction.requestId,
            revision: request.interaction.revision,
          );
        },
      );
      expect(newEntries.single, ['visible', 'overrideVisible'].contains(mode));
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
            if (i is SceneChoiceInteractionRequest) {
              return SceneInteractionResult.choiceSelected(
                requestId: i.requestId,
                revision: i.revision,
                selectedOptionId: 'nickname',
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
