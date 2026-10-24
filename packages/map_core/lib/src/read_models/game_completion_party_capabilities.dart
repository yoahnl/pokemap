import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';

abstract final class GameCompletionPartyCapabilities {
  static const capabilityId = 'game.completion-party-journal@1';

  static bool requiresCapability(ProjectManifest project) => project.scenes.any(
    (scene) => scene.graph.nodes.any((node) {
      final payload = node.payload;
      if (payload is! SceneActionPayload) return false;
      final consequence = payload.consequence;
      return consequence is SceneFinishGameConsequence &&
          consequence.recordParty;
    }),
  );
}
