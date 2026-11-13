import '../../events/domain/event_port.dart';
import '../domain/story_draft_entry.dart';

List<StoryDraftKind<Object>> storyPublicationOrder({required bool deletion}) {
  const written = <StoryDraftKind<Object>>[
    StoryDraftKind.fact,
    StoryDraftKind.dialogue,
    StoryDraftKind.scene,
    StoryDraftKind.story,
    StoryDraftKind.event,
    StoryDraftKind.worldRule,
  ];
  return deletion ? written.reversed.toList() : written;
}

int storyPublicationBatchSize(
  StoryDraftKind<Object> kind, {
  required bool deletion,
}) => kind == StoryDraftKind.event && !deletion ? EventBatchPort.maxRecords : 1;

final class StoryPublicationStep {
  StoryPublicationStep({
    required this.kind,
    required this.deletion,
    required List<StoryDraftEntry<Object>> entries,
  }) : entries = List.unmodifiable(entries);

  final StoryDraftKind<Object> kind;
  final bool deletion;
  final List<StoryDraftEntry<Object>> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryPublicationStep &&
          other.kind == kind &&
          other.deletion == deletion &&
          other.entries.length == entries.length &&
          Iterable<int>.generate(entries.length)
              .every((index) => other.entries[index] == entries[index]);

  @override
  int get hashCode => Object.hash(kind, deletion, Object.hashAll(entries));

  @override
  String toString() =>
      'StoryPublicationStep(${deletion ? 'delete' : 'write'} ${kind.name} '
      '${[for (final entry in entries) entry.id].join(', ')})';
}

List<StoryPublicationStep> planStoryPublication(
  Iterable<StoryDraftEntry<Object>> changes,
) {
  final pending = [
    for (final change in changes)
      if (change.touched) change,
  ];
  final plan = <StoryPublicationStep>[];
  for (final deletion in const [false, true]) {
    for (final kind in storyPublicationOrder(deletion: deletion)) {
      final entries = [
        for (final change in pending)
          if (change.kind == kind && (change.current == null) == deletion)
            change,
      ];
      final size = storyPublicationBatchSize(kind, deletion: deletion);
      for (var start = 0; start < entries.length; start += size) {
        final end = start + size < entries.length
            ? start + size
            : entries.length;
        plan.add(
          StoryPublicationStep(
            kind: kind,
            deletion: deletion,
            entries: entries.sublist(start, end),
          ),
        );
      }
    }
  }
  return plan;
}

final class StoryPublicationProgress {
  StoryPublicationProgress({
    required List<StoryDraftEntry<Object>> saved,
    required List<StoryDraftEntry<Object>> remaining,
    required this.failed,
  }) : saved = List.unmodifiable(saved),
       remaining = List.unmodifiable(remaining);

  final List<StoryDraftEntry<Object>> saved;
  final List<StoryDraftEntry<Object>> remaining;
  final StoryPublicationStep? failed;

  bool get complete => failed == null;
}

StoryPublicationProgress storyPublicationProgress(
  List<StoryPublicationStep> plan, {
  required int succeeded,
}) {
  RangeError.checkValueInInterval(succeeded, 0, plan.length, 'succeeded');
  return StoryPublicationProgress(
    saved: [for (final step in plan.take(succeeded)) ...step.entries],
    remaining: [for (final step in plan.skip(succeeded)) ...step.entries],
    failed: succeeded < plan.length ? plan[succeeded] : null,
  );
}
