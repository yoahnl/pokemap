import '../../application/runtime_post_battle_decision_coordinator.dart';

class PostBattlePresentationChoice {
  const PostBattlePresentationChoice({
    required this.index,
    required this.label,
    required this.selected,
  });

  final int index;
  final String label;
  final bool selected;
}

class PostBattlePresentationSnapshot {
  const PostBattlePresentationSnapshot({
    required this.revision,
    required this.messageIndex,
    required this.messageCount,
    required this.messageKind,
    required this.message,
    required this.choices,
    required this.completed,
    required this.hasFailure,
  });

  final int revision;
  final int messageIndex;
  final int messageCount;
  final RuntimePostBattleMessageKind messageKind;
  final String message;
  final List<PostBattlePresentationChoice> choices;
  final bool completed;
  final bool hasFailure;

  double get progress =>
      messageCount <= 0 ? 0 : ((messageIndex + 1) / messageCount).clamp(0, 1);
}

sealed class PostBattlePresentationCommand {
  const PostBattlePresentationCommand({required this.snapshotRevision});

  final int snapshotRevision;
}

final class PostBattleAdvanceCommand extends PostBattlePresentationCommand {
  const PostBattleAdvanceCommand({required super.snapshotRevision});
}

final class PostBattleSelectDecisionCommand
    extends PostBattlePresentationCommand {
  const PostBattleSelectDecisionCommand({
    required super.snapshotRevision,
    required this.decisionIndex,
  });

  final int decisionIndex;
}

enum PostBattlePresentationCommandRejection {
  staleSnapshot,
  completed,
  decisionRequired,
  decisionMissing,
}

class PostBattlePresentationCommandValidation {
  const PostBattlePresentationCommandValidation._({
    required this.accepted,
    this.rejection,
  });

  const PostBattlePresentationCommandValidation.accepted()
      : this._(accepted: true);

  const PostBattlePresentationCommandValidation.rejected(
    PostBattlePresentationCommandRejection rejection,
  ) : this._(accepted: false, rejection: rejection);

  final bool accepted;
  final PostBattlePresentationCommandRejection? rejection;
}

PostBattlePresentationCommandValidation validatePostBattlePresentationCommand(
  PostBattlePresentationSnapshot snapshot,
  PostBattlePresentationCommand command,
) {
  if (snapshot.revision != command.snapshotRevision) {
    return const PostBattlePresentationCommandValidation.rejected(
      PostBattlePresentationCommandRejection.staleSnapshot,
    );
  }
  if (snapshot.completed) {
    return const PostBattlePresentationCommandValidation.rejected(
      PostBattlePresentationCommandRejection.completed,
    );
  }
  return switch (command) {
    PostBattleAdvanceCommand() => snapshot.choices.isEmpty
        ? const PostBattlePresentationCommandValidation.accepted()
        : const PostBattlePresentationCommandValidation.rejected(
            PostBattlePresentationCommandRejection.decisionRequired,
          ),
    PostBattleSelectDecisionCommand(:final decisionIndex) =>
      snapshot.choices.any((choice) => choice.index == decisionIndex)
          ? const PostBattlePresentationCommandValidation.accepted()
          : const PostBattlePresentationCommandValidation.rejected(
              PostBattlePresentationCommandRejection.decisionMissing,
            ),
  };
}
