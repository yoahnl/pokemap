import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('emits once only after the terminal GameState is committed', () async {
    final requests = <GameCompletionRequest>[];
    final coordinator = NarrativeGameCompletionRuntimeCoordinator(
      project: const ProjectManifest(
        name: 'Selbrume',
        maps: [],
        tilesets: [],
      ),
      locale: 'fr-FR',
      emitCompletion: (request) async => requests.add(request),
    );
    final consequence = SceneConsequence.finishGame(
      endingId: 'ending.selbrume',
      outcome: SceneGameCompletionOutcome.victory,
      result: SceneFinishGameResult(
        title: SceneLocalizedText(fallback: 'Victoire'),
        summary: SceneLocalizedText(fallback: 'Selbrume est sauvée.'),
      ),
      postGamePolicy: ScenePostGamePolicy.returnToTitle,
    ) as SceneFinishGameConsequence;
    final committed = const SceneConsequenceRuntimeWriter(
      project: ProjectManifest(
        name: 'Selbrume',
        maps: [],
        tilesets: [],
      ),
    ).applyOne(const GameState(saveId: 'save'), consequence);

    coordinator.queue(consequence);
    await coordinator.onGameStateCommitted(
      const GameState(saveId: 'save'),
    );
    expect(requests, isEmpty);

    await coordinator.onGameStateCommitted(committed.gameState);
    await coordinator.onGameStateCommitted(committed.gameState);

    expect(requests, hasLength(1));
    expect(requests.single.endingId, 'ending.selbrume');
  });
}
