import 'package:map_core/map_core.dart';

import '../../session/game_session_contract.dart';

final class SceneFinishGameRuntimeMapper {
  const SceneFinishGameRuntimeMapper();

  GameCompletionRequest map({
    required SceneFinishGameConsequence consequence,
    required ProjectManifest project,
    required String locale,
  }) {
    final result = consequence.result;
    final credits = consequence.credits;
    final resolvedResultTitle = result.title.resolve(locale);
    return GameCompletionRequest(
      endingId: consequence.endingId,
      outcome: switch (consequence.outcome) {
        SceneGameCompletionOutcome.completed => GameCompletionOutcome.completed,
        SceneGameCompletionOutcome.victory => GameCompletionOutcome.victory,
        SceneGameCompletionOutcome.alternateEnding =>
          GameCompletionOutcome.alternateEnding,
      },
      result: GameResultSnapshot(
        title: resolvedResultTitle,
        summary: result.summary.resolve(locale),
        details: [
          for (final detail in result.details) detail.resolve(locale),
        ],
      ),
      credits: credits == null
          ? GameCreditsSnapshot(
              title: project.name,
              author: _projectAuthor(project),
              endingLabel: resolvedResultTitle,
            )
          : GameCreditsSnapshot(
              title: credits.title.resolve(locale),
              author: credits.author,
              contributors: credits.contributors,
              licenses: credits.licenses,
              endingLabel: credits.endingLabel.resolve(locale),
              skippable: credits.skippable,
            ),
      destination: switch (consequence.postGamePolicy) {
        ScenePostGamePolicy.continueGame =>
          GameCompletionDestination.playerChoice,
        ScenePostGamePolicy.returnToTitle => GameCompletionDestination.title,
        ScenePostGamePolicy.returnToHub => GameCompletionDestination.hub,
      },
      allowPostGameContinue:
          consequence.postGamePolicy == ScenePostGamePolicy.continueGame,
    );
  }
}

String _projectAuthor(ProjectManifest project) {
  final author = project.globalProperties['author'];
  if (author is String && author.trim().isNotEmpty) return author.trim();
  return project.name;
}
