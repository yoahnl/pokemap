import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class StorylineJournalActions {
  const StorylineJournalActions._();

  static const setMilestoneJournal = 'storyline.milestone.set_journal';
  static const setClues = 'storyline.clues.set';

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      setMilestoneJournal,
      'Set or clear the player journal title and text of a milestone',
      resourceKinds: const ['project', 'storyline'],
    ),
    narrativeActionDescriptor(
      setClues,
      'Replace the clue notes of a Storyline, each revealed by a boolean Fact',
      resourceKinds: const ['project', 'storyline'],
    ),
  ]);

  static final Set<String> ids = {
    for (final descriptor in descriptors) descriptor.id
  };

  static StorylineMutationResult mutate(
    String actionId,
    ProjectManifest project,
    Map<String, Object?> parameters,
  ) {
    final storylineId = narrativeStringParameter(parameters, 'storylineId');
    try {
      if (actionId == setMilestoneJournal) {
        rejectUnknownNarrativeParameters(parameters,
            const {'storylineId', 'chapterId', 'stepId', 'journal'});
        if (!parameters.containsKey('journal')) {
          throw ArgumentError.value(
              null, 'journal', 'is required; pass null to clear it');
        }
        final raw = parameters['journal'];
        return setStorylineMilestoneJournal(
          project,
          storylineId: storylineId,
          chapterId: narrativeStringParameter(parameters, 'chapterId'),
          stepId: narrativeStringParameter(parameters, 'stepId'),
          journal: raw == null
              ? null
              : StorylineMilestoneJournal.fromJson(
                  narrativeObjectParameter(parameters, 'journal')),
        );
      }
      rejectUnknownNarrativeParameters(
          parameters, const {'storylineId', 'clues'});
      final raw = parameters['clues'];
      if (raw is! List) {
        throw ArgumentError.value(raw, 'clues', 'must be a JSON list');
      }
      return setStorylineJournalClues(
        project,
        storylineId: storylineId,
        clues: [
          for (final item in raw)
            if (item is Map)
              StorylineJournalClue.fromJson(Map<String, dynamic>.from(item))
            else
              throw ArgumentError.value(item, 'clues', 'must hold objects'),
        ],
      );
    } on ValidationException catch (error) {
      throw NarrativeAuthoringException(
        'storyline.journal_invalid',
        error.message,
        details: {if (error.code case final code?) 'reason': code},
      );
    }
  }
}
