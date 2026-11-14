import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../game_memory/domain/narrative_index_port.dart';

import 'storyline_ids.dart';
import 'storyline_trame_controller.dart';
import 'storyline_trame_edits.dart';

extension StorylineJournalEdits on StorylineTrameController {
  void ensureStorylines() => unawaited(prepare());

  StorylineAsset? fullStoryline(String id) => saved.ready
      ? working().storylines.where((story) => story.id == id).firstOrNull
      : null;

  StorylineStep? fullMilestone(
    String storylineId,
    String chapterId,
    String stepId,
  ) => _step(fullStoryline(storylineId), chapterId, stepId);

  List<NarrativeTitle> get booleanFacts => [
    for (final fact in facts.value ?? const <NarrativeTitle>[])
      if (fact.value?.kind == NarrativeValueKind.boolean) fact,
  ];

  Future<bool> setMilestoneJournal(
    String storylineId,
    String chapterId,
    String stepId, {
    required ({String title, String text})? journal,
  }) => _journalEdit((p) {
    final current = _step(
      p.storylines.where((story) => story.id == storylineId).firstOrNull,
      chapterId,
      stepId,
    )?.journal;
    return setStorylineMilestoneJournal(
      p,
      storylineId: storylineId,
      chapterId: chapterId,
      stepId: stepId,
      journal: journal == null
          ? null
          : StorylineMilestoneJournal(
              title: _localized(current?.title, journal.title),
              text: _localized(current?.text, journal.text),
            ),
    );
  });

  Future<bool> addJournalClue(
    String storylineId, {
    required String text,
    required String factId,
  }) => _clues(storylineId, (clues) {
    final id = storylineItemId('clue', text, {
      for (final clue in clues) clue.id,
    });
    return [
      ...clues,
      StorylineJournalClue(
        id: id,
        factId: factId,
        text: SceneLocalizedText(fallback: text),
      ),
    ];
  });

  Future<bool> updateJournalClue(
    String storylineId,
    String clueId, {
    String? text,
    String? factId,
  }) => _clues(storylineId, (clues) {
    return [
      for (final clue in clues)
        clue.id == clueId
            ? StorylineJournalClue(
                id: clue.id,
                factId: factId ?? clue.factId,
                text: text == null ? clue.text : _localized(clue.text, text),
              )
            : clue,
    ];
  });

  Future<bool> removeJournalClue(String storylineId, String clueId) => _clues(
    storylineId,
    (clues) => [
      for (final clue in clues)
        if (clue.id != clueId) clue,
    ],
  );

  Future<bool> _clues(
    String storylineId,
    List<StorylineJournalClue> Function(List<StorylineJournalClue>) change,
  ) => _journalEdit((p) {
    final story = p.storylines
        .where((candidate) => candidate.id == storylineId)
        .firstOrNull;
    return setStorylineJournalClues(
      p,
      storylineId: storylineId,
      clues: change(story?.journalClues ?? const []),
    );
  });

  Future<bool> _journalEdit(
    StorylineMutationResult Function(ProjectManifest project) operation,
  ) async {
    try {
      return await edit((p) => StorylineMilestoneMutation(operation(p)));
    } on ValidationException catch (failure) {
      refusal = failure.code ?? 'invalid';
      changed();
      return false;
    }
  }
}

SceneLocalizedText _localized(SceneLocalizedText? current, String fallback) =>
    SceneLocalizedText(
      fallback: fallback,
      translations: current?.translations ?? const {},
    );

StorylineStep? _step(StorylineAsset? story, String chapterId, String stepId) {
  for (final chapter in story?.chapters ?? const <StorylineChapter>[]) {
    if (chapter.id != chapterId) continue;
    for (final step in chapter.steps) {
      if (step.id == stepId) return step;
    }
  }
  return null;
}
