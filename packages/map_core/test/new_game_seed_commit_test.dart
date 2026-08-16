import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('New Game seed commit', () {
    test('commits a complete draft without mutating project configuration', () {
      final config = _config();
      final configBefore = _deepCopy(config.toJson());
      final draft = _completeDraft(config);
      final journal = NewGameSeedCommitJournal.empty();

      final result = commitNewGameDraft(
        journal: journal,
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      expect(result.status, NewGameSeedCommitStatus.committed);
      expect(result.journal, isNot(same(journal)));
      expect(journal.receipts, isEmpty);
      expect(config.toJson(), configBefore);
      final receipt = result.receipt!;
      expect(receipt.status, NewGameSeedCommitReceiptStatus.committed);
      expect(receipt.operationId, 'new-game-commit-1');
      expect(receipt.token.projectRevision, 'project-r1');
      expect(receipt.token.slotId, 'slot-1');
      expect(receipt.token.draftRevision, draft.revision);
      expect(receipt.seed, isNotNull);
      expect(
        receipt.seed!.saveId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(receipt.seed!.draftId, draft.draftId);
      expect(receipt.seed!.playerName, 'Élodie');
      expect(receipt.seed!.avatarCharacterId, 'hero-a');
      expect(receipt.seed!.pronounSet, PlayerPronounSet.feminine);
      expect(receipt.seed!.starterOptionId, 'starter-leaf');
      expect(receipt.seed!.variables, <String, NarrativeValue>{
        'difficulty': const NarrativeValue.string('story'),
      });
      expect(
        () => receipt.seed!.variables['late'] = const NarrativeValue.boolean(
          true,
        ),
        throwsUnsupportedError,
      );
      expect(
        result.journal.receiptForOperation('new-game-commit-1'),
        same(receipt),
      );
    });

    test('replays one terminal receipt for the same operation and token', () {
      final draft = _completeDraft(_config());
      final first = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      final replay = commitNewGameDraft(
        journal: first.journal,
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      expect(replay.status, NewGameSeedCommitStatus.replayed);
      expect(replay.journal, same(first.journal));
      expect(replay.receipt, same(first.receipt));
      expect(replay.journal.receipts, hasLength(1));
    });

    test('refuses a second operation for an already committed token', () {
      final draft = _completeDraft(_config());
      final first = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      final duplicate = commitNewGameDraft(
        journal: first.journal,
        operationId: 'new-game-commit-2',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      expect(duplicate.status, NewGameSeedCommitStatus.conflict);
      expect(duplicate.journal, same(first.journal));
      expect(duplicate.receipt, same(first.receipt));
      expect(
        duplicate.issues.single.code,
        NewGameSeedCommitIssueCode.tokenAlreadyUsed,
      );
      expect(duplicate.journal.receipts, hasLength(1));
    });

    test('rejects stale project and draft revisions without a seed', () {
      final draft = _completeDraft(_config());
      final cases =
          <
            ({
              String operationId,
              String projectRevision,
              int draftRevision,
              NewGameSeedCommitIssueCode issue,
            })
          >[
            (
              operationId: 'stale-project',
              projectRevision: 'project-r2',
              draftRevision: draft.revision,
              issue: NewGameSeedCommitIssueCode.staleProjectRevision,
            ),
            (
              operationId: 'stale-draft',
              projectRevision: 'project-r1',
              draftRevision: draft.revision - 1,
              issue: NewGameSeedCommitIssueCode.staleDraftRevision,
            ),
          ];

      for (final entry in cases) {
        final source = NewGameSeedCommitJournal.empty();
        final result = commitNewGameDraft(
          journal: source,
          operationId: entry.operationId,
          currentProjectRevision: entry.projectRevision,
          expectedDraftRevision: entry.draftRevision,
          draft: draft,
        );

        expect(result.status, NewGameSeedCommitStatus.rejected);
        expect(result.receipt!.seed, isNull);
        expect(result.receipt!.issues.single.code, entry.issue);
        expect(source.receipts, isEmpty);
        expect(result.journal.receipts, hasLength(1));
      }
    });

    test('rejects an incomplete draft and replays the rejection', () {
      final draft = NewGameDraft.start(
        draftId: 'draft-incomplete',
        projectRevision: 'project-r1',
        slotId: 'slot-1',
        config: _config(),
      );

      final first = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'new-game-incomplete',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );
      final replay = commitNewGameDraft(
        journal: first.journal,
        operationId: 'new-game-incomplete',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      expect(first.status, NewGameSeedCommitStatus.rejected);
      expect(first.receipt!.seed, isNull);
      expect(first.receipt!.issues.map((issue) => issue.code).toSet(), {
        NewGameSeedCommitIssueCode.draftIncomplete,
      });
      expect(first.receipt!.issues.map((issue) => issue.field).toSet(), {
        'avatarCharacterId',
        'starterOptionId',
      });
      expect(replay.status, NewGameSeedCommitStatus.replayed);
      expect(replay.receipt, same(first.receipt));
    });

    test(
      'an injected exception leaves no receipt and can be retried safely',
      () {
        final draft = _completeDraft(_config());
        final source = NewGameSeedCommitJournal.empty();

        final failed = commitNewGameDraft(
          journal: source,
          operationId: 'new-game-retry',
          currentProjectRevision: 'project-r1',
          expectedDraftRevision: draft.revision,
          draft: draft,
          seedBuilder:
              ({required operationId, required token, required draft}) {
                throw StateError('injected');
              },
        );

        expect(failed.status, NewGameSeedCommitStatus.failed);
        expect(failed.journal, same(source));
        expect(failed.receipt, isNull);
        expect(
          failed.issues.single.code,
          NewGameSeedCommitIssueCode.seedBuildFailed,
        );
        expect(source.receipts, isEmpty);

        final retry = commitNewGameDraft(
          journal: failed.journal,
          operationId: 'new-game-retry',
          currentProjectRevision: 'project-r1',
          expectedDraftRevision: draft.revision,
          draft: draft,
        );

        expect(retry.status, NewGameSeedCommitStatus.committed);
        expect(retry.receipt!.seed, isNotNull);
        expect(retry.journal.receipts, hasLength(1));
      },
    );

    test('refuses operation id reuse with a different commit token', () {
      final draft = _completeDraft(_config());
      final first = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      final conflict = commitNewGameDraft(
        journal: first.journal,
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r2',
        expectedDraftRevision: draft.revision,
        draft: draft,
      );

      expect(conflict.status, NewGameSeedCommitStatus.conflict);
      expect(conflict.journal, same(first.journal));
      expect(conflict.receipt, same(first.receipt));
      expect(
        conflict.issues.single.code,
        NewGameSeedCommitIssueCode.operationConflict,
      );
    });

    test('refuses operation id reuse with different draft content', () {
      final firstDraft = _completeDraft(_config());
      final changedDraft = _completeDraft(_config(), playerName: 'Nora');
      final first = commitNewGameDraft(
        journal: NewGameSeedCommitJournal.empty(),
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: firstDraft.revision,
        draft: firstDraft,
      );

      final conflict = commitNewGameDraft(
        journal: first.journal,
        operationId: 'new-game-commit-1',
        currentProjectRevision: 'project-r1',
        expectedDraftRevision: changedDraft.revision,
        draft: changedDraft,
      );

      expect(conflict.status, NewGameSeedCommitStatus.conflict);
      expect(conflict.receipt, same(first.receipt));
      expect(
        conflict.issues.single.code,
        NewGameSeedCommitIssueCode.operationConflict,
      );
      expect(conflict.journal.receipts, hasLength(1));
    });

    test('cancelling before commit leaves the journal and draft unchanged', () {
      final draft = _completeDraft(_config());
      final journal = NewGameSeedCommitJournal.empty();

      final cancelled = draft.apply(
        NewGameDraftCommand.cancel(expectedRevision: draft.revision),
      );

      expect(cancelled.status, NewGameDraftCommandStatus.cancelled);
      expect(cancelled.draft, same(draft));
      expect(journal.receipts, isEmpty);
    });
  });
}

ProjectNewGameConfig _config() => ProjectNewGameConfig(
  playerName: 'Ari',
  playerAvatarCharacterIds: const <String>['hero-a'],
  playerPronounSet: PlayerPronounSet.neutral,
  starterOptions: <ProjectStarterOption>[
    ProjectStarterOption(
      id: 'starter-leaf',
      label: 'Leaf',
      pokemon: const PlayerPokemon(
        speciesId: 'leafmon',
        natureId: 'calm',
        abilityId: 'grow',
        level: 5,
        currentHp: 20,
      ),
    ),
  ],
);

NewGameDraft _completeDraft(
  ProjectNewGameConfig config, {
  String playerName = 'Élodie',
}) {
  var draft = NewGameDraft.start(
    draftId: 'draft-1',
    projectRevision: 'project-r1',
    slotId: 'slot-1',
    config: config,
    variableKinds: const <String, NarrativeValueKind>{
      'difficulty': NarrativeValueKind.string,
    },
  );
  draft = draft
      .apply(
        NewGameDraftCommand.setPlayerName(
          expectedRevision: draft.revision,
          playerName: playerName,
        ),
      )
      .draft;
  draft = draft
      .apply(
        NewGameDraftCommand.selectAvatar(
          expectedRevision: draft.revision,
          avatarCharacterId: 'hero-a',
        ),
      )
      .draft;
  draft = draft
      .apply(
        NewGameDraftCommand.setPronouns(
          expectedRevision: draft.revision,
          pronounSet: PlayerPronounSet.feminine,
        ),
      )
      .draft;
  draft = draft
      .apply(
        NewGameDraftCommand.selectStarter(
          expectedRevision: draft.revision,
          starterOptionId: 'starter-leaf',
        ),
      )
      .draft;
  return draft
      .apply(
        NewGameDraftCommand.assignVariable(
          expectedRevision: draft.revision,
          variableId: 'difficulty',
          value: const NarrativeValue.string('story'),
        ),
      )
      .draft;
}

Map<String, dynamic> _deepCopy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
