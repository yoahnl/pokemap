import '../models/project_manifest.dart';
import '../models/storyline_asset.dart';
import '../models/storyline_journal.dart';
import '../read_models/player_journal_capabilities.dart';
import 'storyline_authoring_operations.dart';

StorylineMutationResult setStorylineMilestoneJournal(
  ProjectManifest project, {
  required String storylineId,
  required String chapterId,
  required String stepId,
  required StorylineMilestoneJournal? journal,
}) {
  final step = _step(project, storylineId, chapterId, stepId);
  if (step == null) {
    return _rejected(project, 'stepNotFound', 'The milestone does not exist.');
  }
  return updateStorylineStep(
    project,
    storylineId: storylineId,
    chapterId: chapterId,
    stepId: stepId,
    step: step.copyWith(journal: journal),
  );
}

StorylineMutationResult setStorylineJournalClues(
  ProjectManifest project, {
  required String storylineId,
  required List<StorylineJournalClue> clues,
}) {
  final storyline = project.storylines
      .where((candidate) => candidate.id == storylineId)
      .firstOrNull;
  if (storyline == null) {
    return _rejected(
      project,
      'storylineNotFound',
      'The StorylineAsset does not exist.',
    );
  }
  for (final clue in clues) {
    if (journalClueFactError(project.facts, clue) case final error?) {
      return _rejected(project, 'journalClueFactInvalid', error);
    }
  }
  if (clues.map((clue) => clue.id).toSet().length != clues.length) {
    return _rejected(
      project,
      'journalClueDuplicate',
      'Each clue note needs a distinct id.',
    );
  }
  return updateStoryline(
    project,
    storylineId: storyline.id,
    storyline: storyline.copyWith(journalClues: clues),
  );
}

StorylineStep? _step(
  ProjectManifest project,
  String storylineId,
  String chapterId,
  String stepId,
) {
  for (final storyline in project.storylines) {
    if (storyline.id != storylineId) continue;
    for (final chapter in storyline.chapters) {
      if (chapter.id != chapterId) continue;
      for (final step in chapter.steps) {
        if (step.id == stepId) return step;
      }
    }
  }
  return null;
}

StorylineMutationResult _rejected(
  ProjectManifest project,
  String code,
  String message,
) => StorylineMutationResult(
  before: project,
  after: project,
  disposition: StorylineMutationDisposition.rejected,
  code: code,
  message: message,
);
