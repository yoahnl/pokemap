import 'package:avelune_studio/features/storyline/application/storyline_condition_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_journal_edits.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_controller.dart';
import 'package:avelune_studio/features/storyline/application/storyline_trame_edits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../game_memory/game_memory_fakes.dart';
import 'storyline_fakes.dart';

void main() {
  late StorylineTrameController trame;
  late FakeMemoryStaging staging;
  late FakeStorylineRead reads;

  setUp(() {
    reads = FakeStorylineRead(stories: [mainStoryline()]);
    staging = FakeMemoryStaging();
    final source = FakeBehaviourSource();
    trame = StorylineTrameController(
      port: reads,
      index: FakeNarrativeIndex()..addFacts([memoryFact('met', 'Rencontre')]),
      staging: staging,
      source: () => source,
      changed: () {},
    );
  });

  test('completion fact labels and choices follow an unsaved milestone across renaming and undo', () async {
    await trame.open();
    expect(
      await trame.createMilestone('main', 'chapter_two', 'Retour'),
      isTrue,
    );
    final created = trame.view!.milestones
        .singleWhere((at) => at.milestone.title == 'Retour')
        .milestone;
    final factId = created.completionFactId!;
    expect(trame.factName(factId), 'Retour');
    expect(
      trame.booleanFacts.singleWhere((fact) => fact.id == factId).title,
      'Retour',
    );
    expect(
      await trame.renameMilestone(
        'main',
        'chapter_two',
        created.id,
        'Rentrer',
        completionFactId: factId,
      ),
      isTrue,
    );
    final renamedId = trame.view!
        .milestone(created.id)!
        .milestone
        .completionFactId!;
    expect(trame.factName(renamedId), 'Rentrer');
    expect(
      trame.booleanFacts.singleWhere((fact) => fact.id == renamedId).title,
      'Rentrer',
    );
    staging.draft.undo();
    expect(trame.factName(factId), 'Retour');
    expect(
      trame.booleanFacts.singleWhere((fact) => fact.id == factId).title,
      'Retour',
    );
    expect(trame.factName('met'), 'Rencontre');
  });

  test(
    'a simple condition preserves the other slot and undoes as one edit',
    () async {
      await trame.open();
      final completion =
          reads.stories.single.chapters.first.steps.first.completionCondition;
      expect(
        await trame.setSimpleCondition(
          'main',
          'chapter_one',
          'meet',
          entry: true,
          factId: 'met',
          expected: false,
        ),
        isTrue,
      );
      expect(
        trame.fullMilestone('main', 'chapter_one', 'meet')!.entryCondition,
        ScriptConditionFactory.factEquals(
          'met',
          const NarrativeValue.boolean(false),
        ),
      );
      expect(
        trame.fullMilestone('main', 'chapter_one', 'meet')!.completionCondition,
        completion,
      );
      staging.draft.undo();
      expect(
        trame.fullMilestone('main', 'chapter_one', 'meet')!.entryCondition,
        isNull,
      );
      expect(
        trame.fullMilestone('main', 'chapter_one', 'meet')!.completionCondition,
        completion,
      );
      staging.draft.redo();
      expect(
        trame
            .fullMilestone('main', 'chapter_one', 'meet')!
            .entryCondition!
            .params['value'],
        'false',
      );
    },
  );

  test(
    'unknown facts and unavailable milestones refuse without a transaction',
    () async {
      await trame.open();
      expect(
        await trame.setSimpleCondition(
          'main',
          'chapter_one',
          'meet',
          entry: true,
          factId: 'unknown',
        ),
        isFalse,
      );
      expect(
        await trame.setSimpleCondition(
          'main',
          'chapter_one',
          'unknown',
          entry: true,
          factId: 'met',
        ),
        isFalse,
      );
      expect(staging.draft.canUndo, isFalse);
    },
  );

  test(
    'a composed condition cannot be overwritten by the simple editor',
    () async {
      final story = reads.stories.single;
      final chapter = story.chapters.first;
      final complex = ScriptConditionFactory.anyOf([
        ScriptConditionFactory.moneyAtLeast(500),
        ScriptConditionFactory.moneyAtLeast(900),
      ]);
      reads.stories = [
        story.copyWith(
          chapters: [
            chapter.copyWith(
              steps: [
                chapter.steps.first.copyWith(entryCondition: complex),
                chapter.steps.last,
              ],
            ),
            story.chapters.last,
          ],
        ),
      ];
      await trame.open();
      expect(
        await trame.setSimpleCondition(
          'main',
          'chapter_one',
          'meet',
          entry: true,
          factId: 'met',
        ),
        isFalse,
      );
      expect(
        trame.fullMilestone('main', 'chapter_one', 'meet')!.entryCondition,
        complex,
      );
      expect(staging.draft.canUndo, isFalse);
    },
  );

  test('read-only authoring leaves both condition slots untouched', () async {
    staging.editable = false;
    await trame.open();
    expect(
      await trame.setSimpleCondition(
        'main',
        'chapter_one',
        'meet',
        entry: true,
        factId: 'met',
      ),
      isFalse,
    );
    expect(staging.draft.canUndo, isFalse);
    expect(reads.storylineReads, 0);
  });
}
