import 'package:map_core/map_core.dart';

import '../../transactions/plan_store.dart';
import '../../workspace/project_snapshot.dart';

void requireScopedNarrativePublicationSafety(
  ProjectSnapshot snapshot, {
  required List<NarrativeFactDefinition> facts,
  required List<ProjectDialogueEntry> dialogues,
  required List<SceneAsset> scenes,
  required List<StorylineAsset> storylines,
}) {
  Never unsupported(String reason) => throw AuthoringPlanException(
      code: 'catalog.mutation_scope_required',
      message:
          'Narrative publication requires $reason. Preserve the draft and prepare its incoming references explicitly.');
  for (final fact in facts) {
    final before = snapshot.manifest.facts
        .where((value) => value.id == fact.id)
        .firstOrNull;
    if (before != null &&
        (before.valueKind != fact.valueKind ||
            before.legacyFlagName != fact.legacyFlagName)) {
      unsupported(
          'a complete incoming Fact reference index for its type or identity alias');
    }
  }
  for (final entry in dialogues) {
    final before = snapshot.manifest.dialogues
        .where((value) => value.id == entry.id)
        .firstOrNull;
    if (before != null &&
        before.declaredOutcomes.any((old) =>
            !entry.declaredOutcomes.any((next) => next.id == old.id))) {
      unsupported('a complete incoming dialogue outcome reference index');
    }
  }
  for (final scene in scenes) {
    final before = snapshot.manifest.scenes
        .where((value) => value.id == scene.id)
        .firstOrNull;
    if (before != null &&
        before.declaredOutcomes.any((old) =>
            !scene.declaredOutcomes.any((next) => next.id == old.id))) {
      unsupported('a complete incoming Scene outcome reference index');
    }
  }
  for (final story in storylines) {
    final before = snapshot.manifest.storylines
        .where((value) => value.id == story.id)
        .firstOrNull;
    final ids = {
      for (final chapter in story.chapters) chapter.id,
      for (final chapter in story.chapters)
        for (final step in chapter.steps) step.id
    };
    if (before != null &&
        [
          for (final chapter in before.chapters) chapter.id,
          for (final chapter in before.chapters)
            for (final step in chapter.steps) step.id
        ].any((id) => !ids.contains(id))) {
      unsupported('a complete incoming chapter and step reference index');
    }
  }
}
