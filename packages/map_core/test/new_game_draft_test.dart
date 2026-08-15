import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NewGameDraft', () {
    test('starts from an immutable copy of the authored configuration', () {
      final avatarIds = <String>['hero-a', 'hero-b'];
      final config = ProjectNewGameConfig(
        playerName: 'Ari',
        playerAvatarCharacterIds: avatarIds,
        playerPronounSet: PlayerPronounSet.neutral,
        starterOptions: <ProjectStarterOption>[
          ProjectStarterOption(
            id: 'starter-leaf',
            label: 'Leaf',
            pokemon: _pokemon('leafmon'),
          ),
        ],
      );

      final draft = NewGameDraft.start(
        draftId: 'draft-1',
        projectRevision: 'project-r1',
        slotId: 'slot-1',
        config: config,
        variableKinds: const <String, NarrativeValueKind>{
          'difficulty': NarrativeValueKind.string,
        },
      );
      avatarIds.add('late-avatar');

      expect(draft.schemaVersion, newGameDraftSchemaVersion);
      expect(draft.revision, 0);
      expect(draft.playerName, 'Ari');
      expect(draft.pronounSet, PlayerPronounSet.neutral);
      expect(draft.avatarCharacterId, isNull);
      expect(draft.starterOptionId, isNull);
      expect(draft.variables, isEmpty);
      expect(draft.allowedAvatarCharacterIds, ['hero-a', 'hero-b']);
      expect(draft.allowedStarterOptionIds, ['starter-leaf']);
      expect(draft.variableKinds, <String, NarrativeValueKind>{
        'difficulty': NarrativeValueKind.string,
      });
      expect(config.playerAvatarCharacterIds, [
        'hero-a',
        'hero-b',
        'late-avatar',
      ]);
    });

    test('rejects empty transaction identity fields', () {
      expect(
        () => NewGameDraft.start(
          draftId: ' ',
          projectRevision: 'project-r1',
          slotId: 'slot-1',
          config: const ProjectNewGameConfig(),
        ),
        throwsArgumentError,
      );
    });

    test('applies typed commands without mutating prior revisions', () {
      final original = _draft();

      final named = original.apply(
        NewGameDraftCommand.setPlayerName(
          expectedRevision: 0,
          playerName: '  Élodie  ',
        ),
      );
      final avatar = named.draft.apply(
        NewGameDraftCommand.selectAvatar(
          expectedRevision: 1,
          avatarCharacterId: 'hero-a',
        ),
      );
      final pronouns = avatar.draft.apply(
        NewGameDraftCommand.setPronouns(
          expectedRevision: 2,
          pronounSet: PlayerPronounSet.feminine,
        ),
      );
      final starter = pronouns.draft.apply(
        NewGameDraftCommand.selectStarter(
          expectedRevision: 3,
          starterOptionId: 'starter-leaf',
        ),
      );
      final variable = starter.draft.apply(
        NewGameDraftCommand.assignVariable(
          expectedRevision: 4,
          variableId: 'difficulty',
          value: const NarrativeValue.string('story'),
        ),
      );

      expect(variable.status, NewGameDraftCommandStatus.applied);
      expect(variable.draft.revision, 5);
      expect(variable.draft.playerName, 'Élodie');
      expect(variable.draft.avatarCharacterId, 'hero-a');
      expect(variable.draft.pronounSet, PlayerPronounSet.feminine);
      expect(variable.draft.starterOptionId, 'starter-leaf');
      expect(variable.draft.variables, <String, NarrativeValue>{
        'difficulty': const NarrativeValue.string('story'),
      });
      expect(original.revision, 0);
      expect(original.playerName, 'Ari');
      expect(original.variables, isEmpty);
    });

    test('rejects stale commands without producing a new draft', () {
      final current = _draft()
          .apply(
            NewGameDraftCommand.setPlayerName(
              expectedRevision: 0,
              playerName: 'Nora',
            ),
          )
          .draft;

      final result = current.apply(
        NewGameDraftCommand.selectAvatar(
          expectedRevision: 0,
          avatarCharacterId: 'hero-a',
        ),
      );

      expect(result.status, NewGameDraftCommandStatus.stale);
      expect(identical(result.draft, current), isTrue);
      expect(result.issues.single.code, NewGameDraftIssueCode.staleRevision);
      expect(result.issues.single.toJson(), <String, dynamic>{
        'code': 'staleRevision',
        'diagnosticCode': 'new_game.draft_stale',
        'field': 'revision',
        'arguments': <String, String>{'expected': '0', 'actual': '1'},
      });
    });

    test('rejects invalid fields with redacted diagnostics', () {
      final draft = _draft();
      final invalidName = draft.apply(
        NewGameDraftCommand.setPlayerName(
          expectedRevision: 0,
          playerName: '   ',
        ),
      );
      final invalidAvatar = draft.apply(
        NewGameDraftCommand.selectAvatar(
          expectedRevision: 0,
          avatarCharacterId: 'secret-avatar-value',
        ),
      );
      final invalidStarter = draft.apply(
        NewGameDraftCommand.selectStarter(
          expectedRevision: 0,
          starterOptionId: 'secret-starter-value',
        ),
      );
      final invalidVariable = draft.apply(
        NewGameDraftCommand.assignVariable(
          expectedRevision: 0,
          variableId: 'difficulty',
          value: NarrativeValue.integer(3),
        ),
      );

      expect(
        invalidName.issues.single.code,
        NewGameDraftIssueCode.playerNameEmpty,
      );
      expect(
        invalidAvatar.issues.single.code,
        NewGameDraftIssueCode.avatarUnknown,
      );
      expect(
        invalidStarter.issues.single.code,
        NewGameDraftIssueCode.starterUnknown,
      );
      expect(
        invalidVariable.issues.single.code,
        NewGameDraftIssueCode.variableKindMismatch,
      );
      expect(invalidName.draft.revision, 0);
      expect(invalidAvatar.draft.revision, 0);
      expect(
        <Object>[
          invalidName,
          invalidAvatar,
          invalidStarter,
          invalidVariable,
        ].join(' '),
        isNot(contains('secret-')),
      );
    });

    test('global validation reports required guided selections', () {
      final draft = _draft();

      expect(
        draft.validate().map((issue) => issue.code),
        <NewGameDraftIssueCode>[
          NewGameDraftIssueCode.avatarRequired,
          NewGameDraftIssueCode.starterRequired,
        ],
      );

      final completed = draft
          .apply(
            NewGameDraftCommand.selectAvatar(
              expectedRevision: 0,
              avatarCharacterId: 'hero-a',
            ),
          )
          .draft
          .apply(
            NewGameDraftCommand.selectStarter(
              expectedRevision: 1,
              starterOptionId: 'starter-leaf',
            ),
          )
          .draft;

      expect(completed.validate(), isEmpty);
    });

    test('cancel and retry never mutate project configuration', () {
      final config = ProjectNewGameConfig(
        playerName: 'Ari',
        playerAvatarCharacterIds: <String>['hero-a'],
      );
      final before = config.toJson();
      final draft = NewGameDraft.start(
        draftId: 'run-1',
        projectRevision: 'project-r1',
        slotId: 'slot-1',
        config: config,
      );

      final cancelled = draft.apply(
        NewGameDraftCommand.cancel(expectedRevision: 0),
      );
      final retry = NewGameDraft.start(
        draftId: 'run-2',
        projectRevision: 'project-r1',
        slotId: 'slot-1',
        config: config,
      );

      expect(cancelled.status, NewGameDraftCommandStatus.cancelled);
      expect(identical(cancelled.draft, draft), isTrue);
      expect(retry.revision, 0);
      expect(retry.draftId, 'run-2');
      expect(config.toJson(), before);
      expect(draft.toString(), isNot(contains('Ari')));
      expect(draft.toString(), isNot(contains('hero-a')));
    });
  });
}

NewGameDraft _draft() => NewGameDraft.start(
  draftId: 'draft-1',
  projectRevision: 'project-r1',
  slotId: 'slot-1',
  config: ProjectNewGameConfig(
    playerName: 'Ari',
    playerAvatarCharacterIds: const <String>['hero-a', 'hero-b'],
    starterOptions: <ProjectStarterOption>[
      ProjectStarterOption(
        id: 'starter-leaf',
        label: 'Leaf',
        pokemon: _pokemon('leafmon'),
      ),
    ],
  ),
  variableKinds: const <String, NarrativeValueKind>{
    'difficulty': NarrativeValueKind.string,
  },
);

PlayerPokemon _pokemon(String speciesId) => PlayerPokemon(
  speciesId: speciesId,
  natureId: 'hardy',
  abilityId: 'overgrow',
);
