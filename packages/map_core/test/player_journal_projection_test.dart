import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  PlayerJournalProjection project(
    ProjectManifest manifest, {
    Set<String> trueFacts = const {},
    List<String> completedStepIds = const [],
    String locale = 'fr',
  }) => projectPlayerJournal(
    project: manifest,
    gameState: GameState(
      saveId: 'save',
      progression: PlayerProgression(completedStepIds: completedStepIds),
    ),
    locale: locale,
    isConditionTrue: (condition) =>
        condition.type == ScriptConditionType.factEquals &&
        condition.params[ScriptConditionParams.value] == 'true' &&
        trueFacts.contains(condition.params[ScriptConditionParams.factId]),
  );

  test('the first open milestone of each storyline is in progress', () {
    final journal = project(_project());

    expect(_ids(journal, PlayerJournalEntryKind.inProgress), [
      'step:main:m1',
      'step:side:s1',
    ]);
    expect(journal.ofKind(PlayerJournalEntryKind.completed), isEmpty);
    expect(journal.entries.first.title, 'Arriver');
    expect(journal.entries.first.text, 'Le bourg vous attend.');
  });

  test('a milestone whose completion condition holds is completed', () {
    final journal = project(_project(), trueFacts: {'f_m1'});

    expect(_ids(journal, PlayerJournalEntryKind.completed), ['step:main:m1']);
    expect(
      _ids(journal, PlayerJournalEntryKind.inProgress),
      isNot(contains('step:main:m1')),
    );
  });

  test('chapter and milestone order determine the current journal entry', () {
    final manifest = _project().copyWith(
      storylines: [
        StorylineAsset(
          id: 'main',
          type: StorylineType.main,
          title: 'Trame',
          chapters: [
            StorylineChapter(
              id: 'later',
              title: 'Suite',
              order: 1,
              steps: [_step('later_step', 0)],
            ),
            StorylineChapter(
              id: 'first',
              title: 'Départ',
              order: 0,
              steps: [_step('second_step', 1), _step('first_step', 0)],
            ),
          ],
        ),
      ],
    );
    expect(_ids(project(manifest), PlayerJournalEntryKind.inProgress), [
      'step:main:first_step',
    ]);

    final reorderedSteps = reorderStorylineSteps(
      manifest,
      storylineId: 'main',
      chapterId: 'first',
      orderedStepIds: ['second_step', 'first_step'],
    );
    expect(reorderedSteps.isApplied, isTrue);
    expect(
      _ids(project(reorderedSteps.after), PlayerJournalEntryKind.inProgress),
      ['step:main:second_step'],
    );

    final reorderedChapters = reorderStorylineChapters(
      reorderedSteps.after,
      storylineId: 'main',
      orderedChapterIds: ['later', 'first'],
    );
    expect(reorderedChapters.isApplied, isTrue);
    expect(
      _ids(project(reorderedChapters.after), PlayerJournalEntryKind.inProgress),
      ['step:main:later_step'],
    );
    expect(_ids(project(manifest), PlayerJournalEntryKind.inProgress), [
      'step:main:first_step',
    ]);
  });

  test('a milestone recorded as completed in the save is completed', () {
    final journal = project(_project(), completedStepIds: ['s1']);

    expect(_ids(journal, PlayerJournalEntryKind.completed), ['step:side:s1']);
    expect(_ids(journal, PlayerJournalEntryKind.inProgress), ['step:main:m1']);
  });

  test('archived milestones, chapters and storylines are skipped', () {
    final journal = project(
      _project(),
      trueFacts: {'f_m1', 'f_m3', 'f_x', 'f_s1'},
    );

    expect(
      journal.entries.map((entry) => entry.stepId),
      isNot(contains(anyOf('m2', 'x1', 'a1'))),
    );
    expect(journal.ofKind(PlayerJournalEntryKind.inProgress), isEmpty);
  });

  test('an open milestone without journal text hides the storyline step', () {
    final journal = project(_project(), trueFacts: {'f_m1', 'f_m3'});

    expect(_ids(journal, PlayerJournalEntryKind.inProgress), ['step:side:s1']);
  });

  test('clue notes appear only once their fact is true', () {
    expect(project(_project()).ofKind(PlayerJournalEntryKind.clue), isEmpty);

    final journal = project(_project(), trueFacts: {'f_clue'});

    expect(_ids(journal, PlayerJournalEntryKind.clue), ['clue:main:tracks']);
    expect(journal.entries.last.title, 'Des traces au nord.');
  });

  test('texts resolve the language then fall back to the default text', () {
    final english = project(_project(), locale: 'en-GB');
    final german = project(_project(), locale: 'de');

    expect(english.entries.first.title, 'Arrive');
    expect(english.entries.first.text, 'Le bourg vous attend.');
    expect(german.entries.first.title, 'Arriver');
  });

  test(
    'decision 12: entry conditions never hide the milestone in progress',
    () {
      final gated = _project().copyWith(
        storylines: [
          for (final storyline in _project().storylines)
            storyline.id != 'side'
                ? storyline
                : storyline.copyWith(
                    chapters: [
                      for (final chapter in storyline.chapters)
                        chapter.copyWith(
                          steps: [
                            for (final step in chapter.steps)
                              step.copyWith(
                                entryCondition:
                                    ScriptConditionFactory.factEquals(
                                      'side_unlocked',
                                      const NarrativeValue.boolean(true),
                                    ),
                              ),
                          ],
                        ),
                    ],
                  ),
        ],
      );

      expect(
        _ids(project(gated), PlayerJournalEntryKind.inProgress),
        contains('step:side:s1'),
      );
    },
  );

  test('a project without journal data projects nothing', () {
    expect(
      project(ProjectManifest(name: 'Empty', maps: [], tilesets: [])).isEmpty,
      isTrue,
    );
  });
}

List<String> _ids(PlayerJournalProjection journal, PlayerJournalEntryKind k) =>
    [for (final entry in journal.ofKind(k)) entry.id];

StorylineMilestoneJournal _journal(String title, [String? english]) =>
    StorylineMilestoneJournal(
      title: SceneLocalizedText(
        fallback: title,
        translations: {'en': ?english},
      ),
      text: SceneLocalizedText(fallback: 'Le bourg vous attend.'),
    );

StorylineStep _step(
  String id,
  int order, {
  StorylineStatus? status,
  bool journal = true,
}) => StorylineStep(
  id: id,
  title: id,
  order: order,
  status: status,
  completionCondition: ScriptConditionFactory.factEquals(
    'f_$id',
    const NarrativeValue.boolean(true),
  ),
  journal: journal ? _journal(id == 'm1' ? 'Arriver' : id, 'Arrive') : null,
);

ProjectManifest _project() => ProjectManifest(
  name: 'Journal',
  maps: [],
  tilesets: [],
  storylines: [
    StorylineAsset(
      id: 'archived',
      type: StorylineType.sideQuest,
      status: StorylineStatus.archived,
      title: 'Archivée',
      sortOrder: 0,
      chapters: [
        StorylineChapter(
          id: 'ca',
          title: 'A',
          order: 0,
          steps: [_step('a1', 0)],
        ),
      ],
    ),
    StorylineAsset(
      id: 'side',
      type: StorylineType.sideQuest,
      title: 'Quête',
      chapters: [
        StorylineChapter(
          id: 'cs',
          title: 'S',
          order: 0,
          steps: [_step('s1', 0)],
        ),
      ],
    ),
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Trame',
      sortOrder: 1,
      chapters: [
        StorylineChapter(
          id: 'c2',
          title: 'Deux',
          order: 1,
          steps: [_step('m3', 0, journal: false)],
        ),
        StorylineChapter(
          id: 'c1',
          title: 'Un',
          order: 0,
          steps: [
            _step('m2', 1, status: StorylineStatus.archived),
            _step('m1', 0),
          ],
        ),
        StorylineChapter(
          id: 'cx',
          title: 'Archivé',
          order: 2,
          status: StorylineStatus.archived,
          steps: [_step('x1', 0)],
        ),
      ],
      journalClues: [
        StorylineJournalClue(
          id: 'tracks',
          factId: 'f_clue',
          text: SceneLocalizedText(fallback: 'Des traces au nord.'),
        ),
      ],
    ),
  ],
);
