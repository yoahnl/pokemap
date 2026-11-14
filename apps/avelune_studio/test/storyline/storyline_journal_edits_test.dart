import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import 'storyline_fakes.dart';

SceneLocalizedText _text(String fallback, String english) =>
    SceneLocalizedText(fallback: fallback, translations: {'en': english});

StorylineAsset _translated() {
  final story = mainStoryline();
  final chapter = story.chapters.first;
  return story.copyWith(
    journalClues: [
      StorylineJournalClue(
        id: 'clue_code',
        factId: 'met',
        text: _text('Léo connaît le code.', 'Leo knows the code.'),
      ),
    ],
    chapters: [
      chapter.copyWith(
        steps: [
          chapter.steps.first.copyWith(
            journal: StorylineMilestoneJournal(
              title: _text('La porte', 'The gate'),
              text: _text('Léo garde la porte.', 'Leo guards the gate.'),
            ),
          ),
          ...chapter.steps.skip(1),
        ],
      ),
      ...story.chapters.skip(1),
    ],
  );
}

void main() {
  late FakeMemoryStaging staging;
  late StorylineTrameController trame;

  setUp(() {
    staging = FakeMemoryStaging();
    trame = StorylineTrameController(
      port: FakeStorylineRead(
        stories: [_translated()],
        facts: [memoryFact('met', 'Rencontrer Léo')],
      ),
      index: FakeNarrativeIndex()
        ..addFacts([
          memoryFact('met', 'Rencontrer Léo'),
          memoryFact('coins', 'Pièces', value: NarrativeValue.integer(3)),
        ]),
      staging: staging,
      source: FakeBehaviourSource.new,
      changed: () {},
    );
  });

  StorylineAsset current() =>
      staging.draft.entryOf(StoryDraftKind.story, 'main')!.current!;

  test('editing the journal keeps the existing translations', () async {
    await trame.open();
    expect(trame.fullMilestone('main', 'chapter_one', 'meet'), isNull);
    expect(await trame.prepare(), isTrue);
    expect(
      trame.fullMilestone('main', 'chapter_one', 'meet')!.journal!.title,
      _text('La porte', 'The gate'),
    );
    expect(trame.booleanFacts.map((fact) => fact.id), ['met']);

    expect(
      await trame.setMilestoneJournal(
        'main',
        'chapter_one',
        'meet',
        journal: (title: 'La grande porte', text: 'Léo garde la porte.'),
      ),
      isTrue,
    );
    expect(
      await trame.updateJournalClue(
        'main',
        'clue_code',
        text: 'Léo a le code.',
      ),
      isTrue,
    );

    final journal = current().chapters.first.steps.first.journal!;
    expect(journal.title, _text('La grande porte', 'The gate'));
    expect(journal.text, _text('Léo garde la porte.', 'Leo guards the gate.'));
    expect(
      current().journalClues.single.text,
      _text('Léo a le code.', 'Leo knows the code.'),
    );
  });

  test('a removed journal, a removed clue and refused edits', () async {
    await trame.open();

    expect(
      await trame.setMilestoneJournal(
        'main',
        'chapter_one',
        'meet',
        journal: null,
      ),
      isTrue,
    );
    expect(await trame.removeJournalClue('main', 'clue_code'), isTrue);
    expect(current().chapters.first.steps.first.journal, isNull);
    expect(current().journalClues, isEmpty);

    expect(
      await trame.addJournalClue('main', text: 'x' * 501, factId: 'met'),
      isFalse,
    );
    expect(trame.refusal, 'storyline.journal_text_too_long');
    expect(
      await trame.addJournalClue('main', text: 'Trois pièces', factId: 'coins'),
      isFalse,
    );
    expect(trame.refusal, 'journalClueFactInvalid');
    expect(current().journalClues, isEmpty);
  });
}
