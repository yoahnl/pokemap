import '../models/game_state.dart';
import '../models/narrative_value.dart';
import '../models/project_manifest.dart';
import '../models/script_conditions.dart';
import '../models/storyline_asset.dart';

typedef PlayerJournalConditionTest = bool Function(ScriptCondition condition);

enum PlayerJournalEntryKind { inProgress, completed, clue }

final class PlayerJournalEntry {
  const PlayerJournalEntry({
    required this.id,
    required this.kind,
    required this.storylineId,
    required this.title,
    this.stepId,
    this.text,
  });

  final String id;
  final PlayerJournalEntryKind kind;
  final String storylineId;
  final String? stepId;
  final String title;
  final String? text;
}

final class PlayerJournalProjection {
  PlayerJournalProjection(List<PlayerJournalEntry> entries)
    : entries = List<PlayerJournalEntry>.unmodifiable(entries);

  final List<PlayerJournalEntry> entries;

  bool get isEmpty => entries.isEmpty;

  List<PlayerJournalEntry> ofKind(PlayerJournalEntryKind kind) =>
      List<PlayerJournalEntry>.unmodifiable(
        entries.where((entry) => entry.kind == kind),
      );
}

PlayerJournalProjection projectPlayerJournal({
  required ProjectManifest project,
  required GameState gameState,
  required String locale,
  required PlayerJournalConditionTest isConditionTrue,
}) {
  final completedStepIds = {
    for (final id in gameState.progression.completedStepIds) id.trim(),
  };
  bool isCompleted(StorylineStep step) =>
      completedStepIds.contains(step.id) ||
      (step.completionCondition != null &&
          isConditionTrue(step.completionCondition!));

  final inProgress = <PlayerJournalEntry>[];
  final completed = <PlayerJournalEntry>[];
  final clues = <PlayerJournalEntry>[];
  for (final storyline in _orderedStorylines(project.storylines)) {
    if (storyline.status == StorylineStatus.archived) continue;
    var currentFound = false;
    for (final step in _orderedSteps(storyline)) {
      if (isCompleted(step)) {
        if (_entry(storyline, step, PlayerJournalEntryKind.completed, locale)
            case final entry?) {
          completed.add(entry);
        }
      } else if (!currentFound) {
        currentFound = true;
        if (_entry(storyline, step, PlayerJournalEntryKind.inProgress, locale)
            case final entry?) {
          inProgress.add(entry);
        }
      }
    }
    for (final clue in storyline.journalClues) {
      final revealed = isConditionTrue(
        ScriptConditionFactory.factEquals(
          clue.factId,
          const NarrativeValue.boolean(true),
        ),
      );
      if (!revealed) continue;
      final text = clue.text.resolve(locale);
      clues.add(
        PlayerJournalEntry(
          id: 'clue:${storyline.id}:${clue.id}',
          kind: PlayerJournalEntryKind.clue,
          storylineId: storyline.id,
          title: text,
        ),
      );
    }
  }
  return PlayerJournalProjection([...inProgress, ...completed, ...clues]);
}

PlayerJournalEntry? _entry(
  StorylineAsset storyline,
  StorylineStep step,
  PlayerJournalEntryKind kind,
  String locale,
) {
  final journal = step.journal;
  if (journal == null) return null;
  return PlayerJournalEntry(
    id: 'step:${storyline.id}:${step.id}',
    kind: kind,
    storylineId: storyline.id,
    stepId: step.id,
    title: journal.title.resolve(locale),
    text: journal.text.resolve(locale),
  );
}

List<StorylineAsset> _orderedStorylines(List<StorylineAsset> storylines) {
  final indexed = storylines.indexed.toList()
    ..sort((a, b) {
      final left = a.$2.sortOrder;
      final right = b.$2.sortOrder;
      if (left != null && right != null && left != right) {
        return left.compareTo(right);
      }
      if (left != null && right == null) return -1;
      if (left == null && right != null) return 1;
      return a.$1.compareTo(b.$1);
    });
  return [for (final (_, storyline) in indexed) storyline];
}

Iterable<StorylineStep> _orderedSteps(StorylineAsset storyline) sync* {
  final chapters = [
    for (final chapter in storyline.chapters)
      if (chapter.status != StorylineStatus.archived) chapter,
  ]..sort((a, b) => _compare(a.order, a.id, b.order, b.id));
  for (final chapter in chapters) {
    final steps = [
      for (final step in chapter.steps)
        if (step.status != StorylineStatus.archived) step,
    ]..sort((a, b) => _compare(a.order, a.id, b.order, b.id));
    yield* steps;
  }
}

int _compare(int leftOrder, String leftId, int rightOrder, String rightId) {
  final order = leftOrder.compareTo(rightOrder);
  return order == 0 ? leftId.compareTo(rightId) : order;
}
