import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const snapshot = PostBattlePresentationSnapshot(
    revision: 5,
    messageIndex: 2,
    messageCount: 4,
    messageKind: RuntimePostBattleMessageKind.moveLearned,
    message: 'Pikachu apprend Tonnerre.',
    choices: <PostBattlePresentationChoice>[
      PostBattlePresentationChoice(
        index: 0,
        label: 'Apprendre',
        selected: true,
      ),
      PostBattlePresentationChoice(
        index: 1,
        label: 'Ne pas apprendre',
        selected: false,
      ),
    ],
    completed: false,
    hasFailure: false,
  );

  test('accepts a current direct decision', () {
    expect(
      validatePostBattlePresentationCommand(
        snapshot,
        const PostBattleSelectDecisionCommand(
          snapshotRevision: 5,
          decisionIndex: 1,
        ),
      ).accepted,
      isTrue,
    );
  });

  test('rejects stale and missing post-battle decisions', () {
    expect(
      validatePostBattlePresentationCommand(
        snapshot,
        const PostBattleAdvanceCommand(snapshotRevision: 4),
      ).rejection,
      PostBattlePresentationCommandRejection.staleSnapshot,
    );
    expect(
      validatePostBattlePresentationCommand(
        snapshot,
        const PostBattleSelectDecisionCommand(
          snapshotRevision: 5,
          decisionIndex: 7,
        ),
      ).rejection,
      PostBattlePresentationCommandRejection.decisionMissing,
    );
  });
}
