import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_pokemon_species_loader.dart';

import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  final gift = SceneConsequence.givePokemonFromCatalog(
    speciesId: 'clockbird',
    formId: 'bronze',
    level: 7,
  );
  const project = ProjectManifest(name: 'Gift', maps: [], tilesets: []);
  const state = GameState(saveId: 'save-a', currentMapId: 'lab');
  final catalog = RuntimeScenePokemonCatalog(
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
          standardAbilityIds: ['clockwork', 'solid'],
          allowedAbilityIds: ['clockwork', 'solid'],
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
  final writer = SceneConsequenceRuntimeWriter(
    project: project,
    pokemonCatalog: catalog,
  );

  test('catalog preload contains filesystem failures and propagates programming errors', () async {
    final scene = SceneAsset(
      id: 'gift',
      name: 'Gift',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'gift',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(gift),
          ),
        ],
      ),
    );
    final loaded = await loadRuntimeScenePokemonCatalog(
      scene: scene,
      projectRootDirectory: '/unused',
      pokemonConfig: project.pokemon,
      speciesLoader: _ThrowingSpeciesLoader(
        const FileSystemException('read denied'),
      ),
    );
    expect(loaded!.failures['clockbird'], contains('read denied'));
    final rejected = SceneConsequenceRuntimeWriter(
      project: project,
      pokemonCatalog: loaded,
    ).applyOne(state, gift, pokemonGrantOperationId: 'gift');
    expect(rejected.success, isFalse);
    expect(rejected.gameState, same(state));
    final programmerError = StateError(
      'unexpected loader implementation defect',
    );
    await expectLater(
      loadRuntimeScenePokemonCatalog(
        scene: scene,
        projectRootDirectory: '/unused',
        pokemonConfig: project.pokemon,
        speciesLoader: _ThrowingSpeciesLoader(programmerError),
      ),
      throwsA(same(programmerError)),
    );
  });

  for (final malformed in [true, false]) {
    test(
      'catalog gift preload contains ${malformed ? 'malformed shape' : 'missing species'} data failures',
      () async {
        final root = await Directory.systemTemp.createTemp('gift-bad-data-');
        addTearDown(() => root.delete(recursive: true));
        final config = await writeSceneCatalogPokemonGiftFixture(root);
        final file = File('${root.path}/custom/species/not-a-builtin.json');
        if (malformed) {
          final data =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          data['baseStats'] = 'malformed';
          await file.writeAsString(jsonEncode(data));
        } else {
          await file.delete();
        }
        final loaded = await loadRuntimeScenePokemonCatalog(
          scene: SceneAsset(
            id: 'gift',
            name: 'Gift',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'gift',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.consequence(gift),
                ),
              ],
            ),
          ),
          projectRootDirectory: root.path,
          pokemonConfig: config,
        );
        expect(loaded!.failures, contains('clockbird'));
        final failed =
            SceneConsequenceRuntimeWriter(
              project: project,
              pokemonCatalog: loaded,
            ).applyAll(
              state,
              [SceneConsequence.giveMoney(amount: 7), gift],
              pokemonGrantOperationIds: [null, 'gift'],
            );
        expect(failed.success, isFalse);
        expect(
          failed.errorCode,
          SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        );
        expect(failed.gameState, same(state));
        expect(failed.gameState.progression.caughtSpeciesIds, isEmpty);
        expect(failed.gameState.appliedPokemonGrantOperationIds, isEmpty);
      },
    );
  }

  test('missing resolver fails explicitly without consuming the grant', () {
    final result = const SceneConsequenceRuntimeWriter(project: project)
        .applyOne(state, gift, pokemonGrantOperationId: 'gift');
    expect(result.success, isFalse);
    expect(
      result.errorCode,
      SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
    );
    expect(result.gameState, same(state));
  });

  test(
    'catalog gift builds native attributes, provenance, dex and owned identity',
    () {
      final result = writer.applyOne(
        state,
        gift,
        pokemonGrantOperationId: 'gift',
      );
      expect(result.success, isTrue);
      final pokemon = result.gameState.party.members.single;
      expect(pokemon.formId, 'bronze');
      expect(
        pokemon.currentHp,
        const PokemonStatCalculator()
            .calculate(
              baseStats: catalog.entries['clockbird']!.species.baseStats,
              ivs: pokemon.ivs,
              evs: pokemon.evs,
              level: 7,
              naturePolicy: PokemonNatureStatPolicy.canonical,
              natureId: pokemon.natureId,
            )
            .maxHp,
      );
      expect(pokemon.knownMoveIds, ['tick', 'tock']);
      expect(pokemon.currentPpByMoveId, {'tick': 13, 'tock': 19});
      expect(pokemon.experience, 343);
      expect(pokemon.evs, const PokemonStatSpread());
      expect(pokemon.abilityId, isIn(['clockwork', 'solid']));
      expect(pokemon.friendship, 42);
      expect(pokemon.provenance!.kind, PlayerPokemonOriginKind.gift);
      expect(pokemon.provenance!.mapId, 'lab');
      expect(pokemon.provenance!.sourceId, 'gift');
      expect(pokemon.individualId, startsWith('pkm_'));
      expect(result.gameState.progression.caughtSpeciesIds, ['clockbird']);
      expect(result.gameState.progression.seenSpeciesIds, ['clockbird']);
      final again = writer.applyOne(
        state,
        gift,
        pokemonGrantOperationId: 'gift',
      );
      expect(again.gameState, result.gameState);
      final saved = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(result.gameState).toJson()),
      );
      expect(
        writer.applyOne(saved, gift, pokemonGrantOperationId: 'gift').gameState,
        saved,
      );
      expect(
        const SceneConsequenceRuntimeWriter(project: project)
            .applyOne(saved, gift, pokemonGrantOperationId: 'gift')
            .gameState,
        same(saved),
      );
      final otherSave = writer.applyOne(
        state.copyWith(saveId: 'save-b'),
        gift,
        pokemonGrantOperationId: 'gift',
      );
      final otherOp = writer.applyOne(
        state,
        gift,
        pokemonGrantOperationId: 'gift-b',
      );
      expect(otherSave.gameState.party.members.single.ivs, isNot(pokemon.ivs));
      expect(otherOp.gameState.party.members.single.ivs, isNot(pokemon.ivs));
    },
  );

  test('party overflow uses storage; all full can retry without consuming operation', () {
    final members = [
      for (var index = 0; index < 6; index++)
        PlayerPokemon(
          individualId: 'owned-$index',
          speciesId: 'other',
          natureId: 'hardy',
          abilityId: 'clockwork',
          level: 1,
          currentHp: 10,
        ),
    ];
    final fullParty = state.copyWith(party: PlayerParty(members: members));
    final stored = writer.applyOne(
      fullParty,
      gift,
      pokemonGrantOperationId: 'gift',
    );
    expect(stored.success, isTrue);
    expect(stored.gameState.party.members, members);
    expect(
      stored.gameState.pokemonStorage.boxes
          .expand((box) => box.pokemon)
          .single
          .speciesId,
      'clockbird',
    );
    final full = fullParty.copyWith(
      pokemonStorage: PokemonStorage(
        boxes: [
          PokemonBox(
            id: 'box-1',
            label: 'Box',
            capacity: 1,
            pokemon: [members.first.copyWith(individualId: 'stored')],
          ),
        ],
      ),
    );
    final refused = writer.applyOne(
      full,
      gift,
      pokemonGrantOperationId: 'gift',
    );
    expect(refused.success, isFalse);
    expect(
      refused.errorCode,
      SceneConsequenceRuntimeWriteErrorCode.pokemonGrantRejected,
    );
    expect(refused.gameState, same(full));
    expect(refused.gameState.appliedPokemonGrantOperationIds, isEmpty);
    expect(refused.gameState.progression.caughtSpeciesIds, isEmpty);
    expect(refused.gameState.progression.seenSpeciesIds, isEmpty);
    final freed = full.copyWith(party: const PlayerParty());
    expect(
      writer.applyOne(freed, gift, pokemonGrantOperationId: 'gift').success,
      isTrue,
    );
  });

  test('later failure rolls back Pokemon, dex and operation', () {
    final result = writer.applyAll(
      state,
      [gift, SceneConsequence.takeItem(itemId: 'missing', quantity: 1)],
      pokemonGrantOperationIds: ['gift', null],
    );
    expect(result.success, isFalse);
    expect(result.gameState, same(state));
    expect(result.appliedConsequences, isEmpty);
  });

  test('explicit authored gift preserves HP nature and ability exactly', () {
    final consequence = SceneConsequence.givePokemon(
      speciesId: 'clockbird',
      formId: 'bronze',
      level: 7,
      currentHp: 3,
      natureId: 'brave',
      abilityId: 'authored-exact',
    );
    final result = writer.applyOne(
      state,
      consequence,
      pokemonGrantOperationId: 'explicit',
    );
    expect(result.success, isTrue);
    expect(result.gameState.party.members.single.currentHp, 3);
    expect(result.gameState.party.members.single.natureId, 'brave');
    expect(result.gameState.party.members.single.abilityId, 'authored-exact');
  });

  test('unknown catalog species or mismatched form fail cleanly', () {
    for (final consequence in [
      SceneConsequence.givePokemonFromCatalog(
        speciesId: 'missing',
        formId: 'bronze',
        level: 7,
      ),
      SceneConsequence.givePokemonFromCatalog(
        speciesId: 'clockbird',
        formId: 'wrong',
        level: 7,
      ),
    ]) {
      final result = writer.applyOne(
        state,
        consequence,
        pokemonGrantOperationId: 'gift',
      );
      expect(result.success, isFalse);
      expect(result.gameState, same(state));
    }
  });

  test(
    'active project files drive native gift without IO during projection',
    () async {
      final root = await Directory.systemTemp.createTemp('scene-native-gift-');
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final pokemonConfig = await writeSceneCatalogPokemonGiftFixture(root);
      final loaded = await loadRuntimeScenePokemonCatalog(
        scene: SceneAsset(
          id: 'gift-scene',
          name: 'Gift',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'gift',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(gift),
              ),
            ],
          ),
        ),
        projectRootDirectory: root.path,
        pokemonConfig: pokemonConfig,
      );
      expect(loaded!.failures, isEmpty);
      await root.delete(recursive: true);
      final result = SceneConsequenceRuntimeWriter(
        project: project.copyWith(pokemon: pokemonConfig),
        pokemonCatalog: loaded,
      ).applyOne(state, gift, pokemonGrantOperationId: 'gift');
      expect(result.success, isTrue);
      expect(
        result.gameState.party.members.single,
        writer
            .applyOne(state, gift, pokemonGrantOperationId: 'gift')
            .gameState
            .party
            .members
            .single,
      );
      expect(
        await loadRuntimeScenePokemonCatalog(
          scene: null,
          projectRootDirectory: root.path,
          pokemonConfig: pokemonConfig,
        ),
        isNull,
      );
    },
  );
}

final class _ThrowingSpeciesLoader extends RuntimePokemonSpeciesLoader {
  _ThrowingSpeciesLoader(this.error);
  final Object error;

  @override
  Future<RuntimePokemonSpecies> loadById({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesId,
  }) async {
    throw error;
  }
}
