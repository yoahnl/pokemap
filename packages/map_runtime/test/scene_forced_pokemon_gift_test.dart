import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/runtime_scene_pokemon_catalog.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_write_result.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_interactive_pokemon_gift.dart';

import 'support/scene_catalog_pokemon_gift_fixture.dart';

void main() {
  const state = GameState(saveId: 'forced-gift', currentMapId: 'lab');
  const project = ProjectManifest(name: 'Forced gift', maps: [], tilesets: []);

  test(
    'forced moves replace the learnset in exact order with catalog PP',
    () async {
      final gifts = [
        _gift(null),
        _gift(['echo-gift', 'swift-gift']),
        _gift(['swift-gift']),
        _gift(['echo-gift'], level: 1),
        _gift(['echo-gift', 'tick', 'swift-gift', 'tock']),
      ];
      final catalog = await _load(gifts);
      final generated = [
        for (final gift in gifts)
          catalog.generate(
            consequence: gift,
            state: state,
            operationId: 'same-operation',
            ruleset: project.pokemon.ruleset,
          ),
      ];
      expect(generated[0].knownMoveIds, ['tick', 'tock']);
      expect(generated[0].currentPpByMoveId, {'tick': 13, 'tock': 19});
      expect(generated[1].knownMoveIds, ['echo-gift', 'swift-gift']);
      expect(generated[1].currentPpByMoveId, {'echo-gift': 7, 'swift-gift': 5});
      expect(generated[2].knownMoveIds, ['swift-gift']);
      expect(generated[2].currentPpByMoveId, {'swift-gift': 5});
      expect(generated[3].level, 1);
      expect(generated[3].knownMoveIds, ['echo-gift']);
      expect(generated[3].currentPpByMoveId, {'echo-gift': 7});
      expect(generated[4].knownMoveIds, [
        'echo-gift',
        'tick',
        'swift-gift',
        'tock',
      ]);
      expect(generated[4].currentPpByMoveId, {
        'echo-gift': 7,
        'tick': 13,
        'swift-gift': 5,
        'tock': 19,
      });
      for (final pokemon
          in generated.skip(1).where((pokemon) => pokemon.level == 7)) {
        expect(pokemon.ivs, generated.first.ivs);
        expect(pokemon.currentHp, generated.first.currentHp);
        expect(pokemon.natureId, generated.first.natureId);
        expect(pokemon.abilityId, generated.first.abilityId);
      }
    },
  );

  for (final id in ['missing', 'zero-gift']) {
    test(
      'invalid forced move $id fails atomically without consuming the gift',
      () async {
        final gift = _gift([id]);
        final catalog = await _load([gift]);
        final result =
            SceneConsequenceRuntimeWriter(
              project: project,
              pokemonCatalog: catalog,
            ).applyAll(
              state,
              [SceneConsequence.giveMoney(amount: 3), gift],
              pokemonGrantOperationIds: [null, 'forced'],
            );
        expect(result.success, isFalse);
        expect(
          result.errorCode,
          SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        );
        expect(result.gameState, same(state));
        expect(result.appliedConsequences, isEmpty);
        expect(result.gameState.appliedPokemonGrantOperationIds, isEmpty);
      },
    );
  }

  test(
    'interactive gift keeps forced moves through nickname and save replay',
    () async {
      final gift = _gift(['swift-gift', 'echo-gift']);
      final command = SceneInteractiveCommand.fromJson({
        'kind': 'receivePokemonFromCatalog',
        'speciesId': 'clockbird',
        'formId': 'bronze',
        'level': 7,
        'moveIds': ['swift-gift', 'echo-gift'],
        'nicknamePolicy': 'offer',
        'nicknameMaxGraphemes': 12,
        'pokedexPresentationPolicy': 'never',
      }) as SceneReceivePokemonFromCatalogInteractiveCommand;
      final catalog = await _load([gift], interactive: command);
      final result = await receiveScenePokemonFromCatalog(
        command: command,
        operationId: 'interactive',
        project: project,
        readProjectedState: () => state,
        catalog: catalog,
        present: (request) async {
          expect(request.pokemon.knownMoveIds, ['swift-gift', 'echo-gift']);
          final interaction = request.interaction;
          return switch (interaction) {
            SceneConfirmationInteractionRequest() =>
              SceneInteractionResult.confirmed(
                requestId: interaction.requestId,
                revision: interaction.revision,
                value: true,
              ),
            SceneTextInteractionRequest() =>
              SceneInteractionResult.textSubmitted(
                requestId: interaction.requestId,
                revision: interaction.revision,
                value: 'Pendule',
              ),
            _ => SceneInteractionResult.acknowledged(
              requestId: interaction.requestId,
              revision: interaction.revision,
            ),
          };
        },
      );
      final committed = result.prepared!.commit(
        state,
        catalog: catalog,
        project: project,
      );
      final pokemon = committed.party.members.single;
      expect(pokemon.nickname, 'Pendule');
      expect(pokemon.knownMoveIds, ['swift-gift', 'echo-gift']);
      expect(pokemon.currentPpByMoveId, {'swift-gift': 5, 'echo-gift': 7});
      final restored = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(committed).toJson()),
      );
      final replay = await receiveScenePokemonFromCatalog(
        command: command,
        operationId: 'interactive',
        project: project,
        readProjectedState: () => restored,
        catalog: catalog,
        present: (_) =>
            throw StateError('An applied gift must not be presented again.'),
      );
      expect(replay.outputPortId, 'party');
      expect(replay.prepared, isNull);
      expect(restored.party.members.single, pokemon);
    },
  );
}

SceneGivePokemonFromCatalogConsequence _gift(
  List<String>? moves, {
  int level = 7,
}) => SceneConsequence.fromJson({
  'kind': 'givePokemonFromCatalog',
  'speciesId': 'clockbird',
  'formId': 'bronze',
  'level': level,
  'moveIds': ?moves,
}) as SceneGivePokemonFromCatalogConsequence;

Future<RuntimeScenePokemonCatalog> _load(
  List<SceneGivePokemonFromCatalogConsequence> gifts, {
  SceneReceivePokemonFromCatalogInteractiveCommand? interactive,
}) async {
  final root = await Directory.systemTemp.createTemp('forced-gift-');
  try {
    final config = await writeSceneCatalogPokemonGiftFixture(root);
    final file = File('${root.path}/custom/moves.json');
    final document =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    (document['entries'] as List<dynamic>).addAll([
      for (final entry in {
        'swift-gift': 5,
        'echo-gift': 7,
        'zero-gift': 0,
      }.entries)
        PokemonMove(
          id: entry.key,
          name: entry.key,
          type: 'steel',
          category: PokemonMoveCategory.physical,
          accuracy: const PokemonMoveAccuracy.percent(value: 100),
          pp: entry.value,
        ).toJson(),
    ]);
    await file.writeAsString(jsonEncode(document));
    final loaded = await loadRuntimeScenePokemonCatalog(
      scene: SceneAsset(
        id: 'forced-gift',
        name: 'Forced gift',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            for (var index = 0; index < gifts.length; index++)
              SceneNode(
                id: 'gift-$index',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(gifts[index]),
              ),
            if (interactive != null)
              SceneNode(
                id: 'interactive',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(interactive),
              ),
          ],
        ),
      ),
      projectRootDirectory: root.path,
      pokemonConfig: config,
    );
    expect(loaded!.failures, isEmpty);
    return loaded;
  } finally {
    await root.delete(recursive: true);
  }
}
