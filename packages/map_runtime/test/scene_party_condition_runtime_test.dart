import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/spatial/spatial_scene_callbacks.dart';

void main() {
  test(
    'spatial reception condition reads live capacity and survives reload',
    () {
      var state = const GameState(saveId: 'party-condition');
      final host = _host(() => state);
      final source = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.partyState,
        sourceId: 'canReceivePokemon',
        operator: SceneConditionOperator.isTrue,
      );
      final intent = SceneRuntimePlanIntent.evaluateCondition(source: source);
      expect(host.evaluateCondition(intent), 'true');
      state = state.copyWith(
        party: PlayerParty(
          members: [for (var i = 0; i < 6; i++) _pokemon('$i')],
        ),
        pokemonStorage: PokemonStorage(
          boxes: [
            PokemonBox(
              id: 'box',
              label: 'Box',
              capacity: 1,
              pokemon: [_pokemon('stored')],
            ),
          ],
        ),
      );
      final before = state.toJson();
      expect(host.evaluateCondition(intent), 'false');
      expect(state.toJson(), before);
      state = GameState.fromJson(state.toJson());
      expect(host.evaluateCondition(intent), 'false');
      state = state.copyWith(
        party: state.party.copyWith(
          members: state.party.members.skip(1).toList(),
        ),
      );
      expect(host.evaluateCondition(intent), 'true');
    },
  );

  test(
    'spatial field condition refuses unsupported terrain despite unlock',
    () {
      final state = GameState(
        saveId: 'party-condition',
        party: PlayerParty(
          members: [
            _pokemon(
              'member',
            ).copyWith(knownMoveIds: ['surf'], currentPpByMoveId: {'surf': 0}),
          ],
        ),
        progression: const PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
        ),
      );
      final host = _host(() => state);
      final source = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.partyState,
        sourceId: 'canUseFieldAbility',
        field: 'ability',
        value: 'surf',
        operator: SceneConditionOperator.isTrue,
      );
      expect(
        host.evaluateCondition(
          SceneRuntimePlanIntent.evaluateCondition(source: source),
        ),
        'false',
      );
    },
  );
}

SpatialSceneCallbacks _host(GameState Function() read) => SpatialSceneCallbacks(
  project: const ProjectManifest(
    name: 'Condition fixture',
    maps: [],
    tilesets: [],
  ),
  runtimeSourceId: 'party-condition',
  readGameState: read,
  show: (_) async => const SceneDialogueRuntimeAwaitableResult.completed(),
  battle: (_) async => const SceneBattleRuntimeOutcomeResult.completed(
    port: SceneBattleRuntimeOutcomePort.victory,
  ),
  interactive: (_) async => 'completed',
);

PlayerPokemon _pokemon(String id) => PlayerPokemon(
  individualId: id,
  speciesId: 'fixture-species',
  natureId: 'fixture-nature',
  abilityId: 'fixture-ability',
  currentPpByMoveId: const {},
);
