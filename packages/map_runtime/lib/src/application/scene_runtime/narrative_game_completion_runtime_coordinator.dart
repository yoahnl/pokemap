import 'package:map_core/map_core.dart';

import '../../session/game_session_contract.dart';
import 'scene_finish_game_runtime_mapper.dart';
import 'scene_game_completion_metadata.dart';

typedef GameCompletionRequestEmitter = Future<void> Function(
  GameCompletionRequest request,
);

final class NarrativeGameCompletionRuntimeCoordinator {
  NarrativeGameCompletionRuntimeCoordinator({
    required this.project,
    required this.locale,
    required this.emitCompletion,
    this.mapper = const SceneFinishGameRuntimeMapper(),
  });

  final ProjectManifest project;
  final String locale;
  final GameCompletionRequestEmitter emitCompletion;
  final SceneFinishGameRuntimeMapper mapper;

  final Map<String, SceneFinishGameConsequence> _pendingByEndingId =
      <String, SceneFinishGameConsequence>{};
  final Set<String> _emittedEndingIds = <String>{};

  void queue(SceneFinishGameConsequence consequence) {
    if (_emittedEndingIds.contains(consequence.endingId)) return;
    _pendingByEndingId.putIfAbsent(consequence.endingId, () => consequence);
  }

  Future<void> onGameStateCommitted(GameState gameState) async {
    final endingId = gameState.metadata[sceneGameCompletionEndingMetadataKey];
    if (endingId == null || _emittedEndingIds.contains(endingId)) return;
    final consequence = _pendingByEndingId.remove(endingId);
    if (consequence == null) return;
    try {
      await emitCompletion(
        mapper.map(
          consequence: consequence,
          project: project,
          locale: locale,
        ),
      );
      _emittedEndingIds.add(endingId);
    } catch (_) {
      _pendingByEndingId.putIfAbsent(endingId, () => consequence);
      rethrow;
    }
  }
}
