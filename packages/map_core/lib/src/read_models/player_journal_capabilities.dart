import '../models/narrative_fact.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/storyline_journal.dart';

abstract final class PlayerJournalCapabilities {
  static const capabilityId = 'project.player-journal@1';

  static bool requiresCapability(ProjectManifest project) =>
      project.storylines.any(
        (storyline) =>
            storyline.journalClues.isNotEmpty ||
            storyline.chapters.any(
              (chapter) => chapter.steps.any((step) => step.journal != null),
            ),
      );

  static List<String> referenceErrors(ProjectManifest project) => [
    for (final storyline in project.storylines)
      for (final clue in storyline.journalClues)
        if (journalClueFactError(project.facts, clue) case final error?)
          'Storyline ${storyline.id} clue ${clue.id}: $error',
  ];
}

String? journalClueFactError(
  List<NarrativeFactDefinition> facts,
  StorylineJournalClue clue,
) {
  final matches = facts.where((fact) => fact.id == clue.factId).toList();
  if (matches.isEmpty) return 'unknown Fact ${clue.factId}.';
  if (matches.first.initialValue.kind != NarrativeValueKind.boolean) {
    return 'Fact ${clue.factId} must be a boolean Fact.';
  }
  return null;
}
