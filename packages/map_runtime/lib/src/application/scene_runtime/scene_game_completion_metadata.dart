import 'package:map_core/map_core.dart';

const String sceneGameCompletionEndingMetadataKey =
    'pokemap.gameCompletion.endingId';
const String sceneGameCompletionPostGamePolicyMetadataKey =
    'pokemap.gameCompletion.postGamePolicy';

bool gameStateAllowsPostGameContinue(Map<String, Object?> state) {
  final metadata = state['metadata'];
  if (metadata is! Map) return false;
  return metadata[sceneGameCompletionPostGamePolicyMetadataKey] ==
      ScenePostGamePolicy.continueGame.name;
}
