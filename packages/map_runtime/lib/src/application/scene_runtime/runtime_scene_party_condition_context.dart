import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../runtime_move_catalog_loader.dart';

const twoDSceneFieldAbilities = <FieldAbility>{
  FieldAbility.fly,
  FieldAbility.surf,
  FieldAbility.cut,
  FieldAbility.strength,
  FieldAbility.flash,
  FieldAbility.rockSmash,
  FieldAbility.waterfall,
  FieldAbility.whirlpool,
  FieldAbility.dive,
};

Future<ScenePartyConditionContext> loadRuntimeScenePartyConditionContext({
  required SceneAsset scene,
  required String projectRootDirectory,
  required ProjectPokemonConfig pokemonConfig,
  Iterable<FieldAbility> supportedFieldAbilities = const [],
  RuntimeMoveCatalogLoader? moveCatalogLoader,
  ProjectSettings? projectSettings,
}) async {
  final moveIds = <String>{
    for (final node in scene.graph.nodes)
      if (node.payload case SceneConditionPayload(
        conditionSource: final source,
      ))
        if (source?.partyMoveId case final String moveId) moveId,
  };
  if (moveIds.isEmpty) {
    return ScenePartyConditionContext(
      supportedFieldAbilities: supportedFieldAbilities,
      projectSettings: projectSettings,
    );
  }
  final moves = await (moveCatalogLoader ?? RuntimeMoveCatalogLoader()).load(
    projectRootDirectory: projectRootDirectory,
    pokemonConfig: pokemonConfig,
  );
  for (final moveId in moveIds) {
    if (!moves.entriesById.containsKey(moveId)) {
      throw FormatException('Unknown Scene party move reference: $moveId.');
    }
  }
  return ScenePartyConditionContext(
    availableMoveIds: moves.entriesById.keys,
    supportedFieldAbilities: supportedFieldAbilities,
    projectSettings: projectSettings,
  );
}
