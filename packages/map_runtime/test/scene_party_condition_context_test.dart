import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/application/scene_runtime/runtime_scene_party_condition_context.dart';

void main() {
  test('capacity and field gates do not load a Pokemon catalog', () async {
    final loader = _MoveLoader();
    for (final source in [
      SceneConditionSource.partyCanReceivePokemon(),
      SceneConditionSource.partyCanUseFieldAbility(ability: FieldAbility.surf),
      SceneConditionSource.partyCanUseFieldAbility(ability: FieldAbility.whirlpool),
    ]) {
      final context = await loadRuntimeScenePartyConditionContext(
        scene: _scene(source), projectRootDirectory: '/unused',
        pokemonConfig: _config, moveCatalogLoader: loader,
        supportedFieldAbilities: twoDSceneFieldAbilities,
      );
      expect(context.availableMoveIds, isNull);
      expect(context.supportedFieldAbilities, contains(FieldAbility.surf));
      expect(context.supportedFieldAbilities, contains(FieldAbility.whirlpool));
    }
    expect(loader.reads, 0);
  });

  test('a Scene without gifts receives the full active move catalog', () async {
    final loader = _MoveLoader();
    final context = await loadRuntimeScenePartyConditionContext(
      scene: _scene(SceneConditionSource.partyKnowsMove(moveId: 'selected')),
      projectRootDirectory: '/unused', pokemonConfig: _config,
      moveCatalogLoader: loader,
    );
    expect(loader.reads, 1);
    expect(context.availableMoveIds, {'selected', 'other'});
    expect(context.supportedFieldAbilities, isEmpty);
    expect(() => context.availableMoveIds!.clear(), throwsUnsupportedError);
  });

  test('an unknown move is refused while preparing the Scene', () async {
    final loader = _MoveLoader();
    await expectLater(loadRuntimeScenePartyConditionContext(
      scene: _scene(SceneConditionSource.partyHasUsableMove(moveId: 'missing')),
      projectRootDirectory: '/unused', pokemonConfig: _config,
      moveCatalogLoader: loader,
    ), throwsFormatException);
    expect(loader.reads, 1);
  });
}

final _config = const ProjectManifest(name: 'Fixture', maps: [], tilesets: []).pokemon;

SceneAsset _scene(SceneConditionSource source) => SceneAsset(
  id: 'party', name: 'Party context', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(id: 'condition', kind: SceneNodeKind.condition, payload: SceneConditionPayload(conditionSource: source)),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ], edges: const []),
);

final class _MoveLoader extends RuntimeMoveCatalogLoader {
  var reads = 0;

  @override
  Future<RuntimeMoveCatalog> load({required String projectRootDirectory, required ProjectPokemonConfig pokemonConfig}) async {
    reads++;
    return RuntimeMoveCatalog.fromEntries({
      for (final id in ['selected', 'other']) id: PokemonMove(id: id, name: id, type: 'fixture-type',
          category: PokemonMoveCategory.physical, accuracy: const PokemonMoveAccuracy.percent(value: 100), pp: 5),
    });
  }
}
