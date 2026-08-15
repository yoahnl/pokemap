import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const writer = SceneConsequenceRuntimeWriter(
    project: ProjectManifest(
      name: 'Scene grant fixture',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    ),
  );
  final consequence = SceneConsequence.givePokemon(
    speciesId: 'bulbasaur',
    natureId: 'hardy',
    abilityId: 'overgrow',
    level: 5,
    currentHp: 10,
  );

  test('save/load then retry of one Scene grant stays idempotent', () {
    final first = writer.applyOne(
      const GameState(saveId: 'scene-grant'),
      consequence,
      pokemonGrantOperationId: 'scene:gift_scene:execution-a:gift-node',
    );
    final restored = gameStateFromSaveData(
      SaveData.fromJson(saveDataFromGameState(first.gameState).toJson()),
    );
    final replay = writer.applyOne(
      restored,
      consequence,
      pokemonGrantOperationId: 'scene:gift_scene:execution-a:gift-node',
    );

    expect(first.success, isTrue);
    expect(replay.success, isTrue);
    expect(replay.gameState.party.members, hasLength(1));
    expect(replay.gameState, restored);
    expect(replay.gameState.appliedPokemonGrantOperationIds, hasLength(1));
  });

  test('a new Scene execution may grant the same template again', () {
    final first = writer.applyOne(
      const GameState(saveId: 'scene-grant'),
      consequence,
      pokemonGrantOperationId: 'scene:gift_scene:execution-a:gift-node',
    );
    final second = writer.applyOne(
      first.gameState,
      consequence,
      pokemonGrantOperationId: 'scene:gift_scene:execution-b:gift-node',
    );

    expect(second.success, isTrue);
    expect(second.gameState.party.members, hasLength(2));
    expect(
      second.gameState.party.members
          .map((pokemon) => pokemon.individualId)
          .toSet(),
      hasLength(2),
    );
  });

  test('a gift without operation identity is rejected before mutation', () {
    const state = GameState(saveId: 'scene-grant');

    final result = writer.applyOne(state, consequence);

    expect(result.success, isFalse);
    expect(
      result.errorCode,
      SceneConsequenceRuntimeWriteErrorCode.missingPokemonGrantOperationId,
    );
    expect(result.gameState, state);
  });
}
