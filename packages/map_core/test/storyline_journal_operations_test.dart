import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final journal = StorylineMilestoneJournal(
    title: SceneLocalizedText(fallback: 'Le rival'),
    text: SceneLocalizedText(fallback: 'Il attend au labo.'),
  );
  StorylineJournalClue clue(String id, String factId) => StorylineJournalClue(
    id: id,
    factId: factId,
    text: SceneLocalizedText(fallback: 'Indice $id'),
  );

  test('sets then clears a milestone journal', () {
    final set = setStorylineMilestoneJournal(
      _project(),
      storylineId: 'main',
      chapterId: 'c1',
      stepId: 'm1',
      journal: journal,
    );

    expect(set.isApplied, isTrue);
    expect(_step(set.after).journal, journal);
    expect(PlayerJournalCapabilities.requiresCapability(set.after), isTrue);

    final cleared = setStorylineMilestoneJournal(
      set.after,
      storylineId: 'main',
      chapterId: 'c1',
      stepId: 'm1',
      journal: null,
    );

    expect(_step(cleared.after).journal, isNull);
    expect(cleared.after.storylines, _project().storylines);
    expect(
      PlayerJournalCapabilities.requiresCapability(cleared.after),
      isFalse,
    );
  });

  test('rejects an unknown milestone without changing the project', () {
    final project = _project();
    final result = setStorylineMilestoneJournal(
      project,
      storylineId: 'main',
      chapterId: 'c1',
      stepId: 'missing',
      journal: journal,
    );

    expect(result.disposition, StorylineMutationDisposition.rejected);
    expect(result.code, 'stepNotFound');
    expect(identical(result.after, project), isTrue);
  });

  test('sets clue notes tied to boolean facts', () {
    final result = setStorylineJournalClues(
      _project(),
      storylineId: 'main',
      clues: [clue('tracks', 'saw_tracks')],
    );

    expect(result.isApplied, isTrue);
    expect(result.after.storylines.single.journalClues.single.id, 'tracks');
    expect(PlayerJournalCapabilities.referenceErrors(result.after), isEmpty);
    expect(PlayerJournalCapabilities.requiresCapability(result.after), isTrue);
  });

  test('rejects clue notes on unknown or non boolean facts', () {
    for (final factId in ['missing', 'counter']) {
      final result = setStorylineJournalClues(
        _project(),
        storylineId: 'main',
        clues: [clue('tracks', factId)],
      );

      expect(result.disposition, StorylineMutationDisposition.rejected);
      expect(result.code, 'journalClueFactInvalid');
    }
    expect(
      setStorylineJournalClues(
        _project(),
        storylineId: 'main',
        clues: [clue('a', 'saw_tracks'), clue('a', 'saw_tracks')],
      ).code,
      'journalClueDuplicate',
    );
    expect(
      setStorylineJournalClues(_project(), storylineId: 'nope', clues: []).code,
      'storylineNotFound',
    );
  });

  test('reports clue notes whose fact disappeared from the project', () {
    final withClue = setStorylineJournalClues(
      _project(),
      storylineId: 'main',
      clues: [clue('tracks', 'saw_tracks')],
    ).after;
    final broken = withClue.copyWith(facts: const []);

    expect(PlayerJournalCapabilities.referenceErrors(broken), [
      'Storyline main clue tracks: unknown Fact saw_tracks.',
    ]);
  });

  test('a fact cited by a clue note cannot be removed while cited', () {
    final withClue = setStorylineJournalClues(
      _project(),
      storylineId: 'main',
      clues: [clue('tracks', 'saw_tracks')],
    ).after;
    final usages = buildNarrativeDependencyIndex(project: withClue).usagesFor(
      const NarrativeDependencyKey(
        NarrativeDependencyTargetKind.fact,
        'saw_tracks',
      ),
    );

    expect(
      [for (final usage in usages) usage.path],
      ['storylines[main].journalClues[0].factId'],
    );
    expect(
      () => removeNarrativeFact(withClue, factId: 'saw_tracks'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          contains('journalClues[0].factId'),
        ),
      ),
    );
    expect(
      removeNarrativeFact(_project(), factId: 'saw_tracks').removedFact.id,
      'saw_tracks',
    );
  });
}

StorylineStep _step(ProjectManifest project) =>
    project.storylines.single.chapters.single.steps.single;

ProjectManifest _project() => ProjectManifest(
  name: 'Journal',
  maps: [],
  tilesets: [],
  facts: [
    NarrativeFactDefinition(id: 'saw_tracks', label: 'Traces'),
    NarrativeFactDefinition(
      id: 'counter',
      label: 'Compteur',
      initialValue: NarrativeValue.integer(0),
    ),
  ],
  storylines: [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Trame',
      chapters: [
        StorylineChapter(
          id: 'c1',
          title: 'Un',
          order: 0,
          steps: [StorylineStep(id: 'm1', title: 'Rival', order: 0)],
        ),
      ],
    ),
  ],
);
