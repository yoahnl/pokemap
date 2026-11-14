import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/storyline_trame_fixture.dart';

void main() {
  group('chapters', () {
    test('create inserts at the requested index and renumbers orders', () {
      final result = createStorylineChapter(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'prologue',
        title: ' Prologue ',
        index: 0,
      );

      expect(result.isApplied, isTrue);
      final chapters = result.after.storylines.first.chapters;
      expect(chapters.map((chapter) => (chapter.id, chapter.order)), [
        ('prologue', 0),
        ('act_1', 1),
      ]);
      expect(chapters.first.title, 'Prologue');
      expect(chapters.first.status, isNull);
    });

    test(
      'create rejects a reused id, a blank title and a missing storyline',
      () {
        final project = storylineTrameProject();
        for (final (storylineId, chapterId, title, code) in [
          ('main', 'side_act', 'Again', 'chapterIdAlreadyExists'),
          ('main', 'act_2', '  ', 'chapterTitleRequired'),
          ('main', ' act_2', 'Act 2', 'chapterIdInvalid'),
          ('missing', 'act_2', 'Act 2', 'storylineNotFound'),
        ]) {
          final result = createStorylineChapter(
            project,
            storylineId: storylineId,
            chapterId: chapterId,
            title: title,
          );
          expect(result.code, code);
          expect(result.after, same(project));
        }
      },
    );

    test('archive and unarchive toggle the archived status only', () {
      final archived = setStorylineChapterArchived(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        archived: true,
      );
      expect(
        archived.after.storylines.first.chapters.single.status,
        StorylineStatus.archived,
      );

      final restored = setStorylineChapterArchived(
        archived.after,
        storylineId: 'main',
        chapterId: 'act_1',
        archived: false,
      );
      expect(restored.after.storylines.first.chapters.single.status, isNull);

      final untouched = setStorylineChapterArchived(
        restored.after,
        storylineId: 'main',
        chapterId: 'act_1',
        archived: false,
      );
      expect(untouched.disposition, StorylineMutationDisposition.noChange);
    });
  });

  group('milestones', () {
    test('create adds a step completed by a new boolean fact', () {
      final result = createStorylineMilestone(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'leave_town',
        title: 'Leave town',
        index: 0,
      );

      expect(result.result.isApplied, isTrue);
      expect(result.fact!.id, 'fact_leave_town_2');
      expect(result.fact!.label, 'Leave town');
      expect(result.fact!.initialValue, const NarrativeValue.boolean(false));
      final steps = result.result.after.storylines.first.chapters.single.steps;
      expect(steps.map((step) => (step.id, step.order)), [
        ('leave_town', 0),
        ('meet_rival', 1),
      ]);
      expect(
        storylineMilestoneCompletionFactId(steps.first),
        'fact_leave_town_2',
      );
      expect(result.result.after.facts.map((fact) => fact.id), [
        'fact_leave_town',
        'fact_meet_rival',
        'fact_leave_town_2',
      ]);
      expect(result.result.before, storylineTrameProject());
    });

    test('create rejects a step id used by any storyline', () {
      final project = storylineTrameProject();
      final result = createStorylineMilestone(
        project,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'side_step',
        title: 'Clash',
      );

      expect(result.result.code, 'stepIdAlreadyExists');
      expect(result.result.after, same(project));
      expect(result.fact, isNull);
    });

    test('rename keeps the fact id and relabels an uncustomised fact', () {
      final renamed = renameStorylineMilestone(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        title: 'Beat the rival',
      );

      expect(renamed.previousFact!.label, 'Meet rival');
      expect(renamed.fact!.id, 'fact_meet_rival');
      expect(renamed.fact!.label, 'Beat the rival');
      final step =
          renamed.result.after.storylines.first.chapters.single.steps.single;
      expect(step.title, 'Beat the rival');
      expect(storylineMilestoneCompletionFactId(step), 'fact_meet_rival');
    });

    test('rename leaves a customised fact label alone', () {
      final project = storylineTrameProject();
      final custom = project.copyWith(
        facts: [
          project.facts.first,
          NarrativeFactDefinition(id: 'fact_meet_rival', label: 'Rival beaten'),
        ],
      );
      final renamed = renameStorylineMilestone(
        custom,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        title: 'Beat the rival',
      );

      expect(renamed.fact, isNull);
      expect(renamed.result.after.facts.last.label, 'Rival beaten');
    });

    test('archive then unarchive returns the milestone to no status', () {
      final archived = setStorylineMilestoneArchived(
        storylineTrameProject(),
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        archived: true,
      );
      final restored = setStorylineMilestoneArchived(
        archived.after,
        storylineId: 'main',
        chapterId: 'act_1',
        stepId: 'meet_rival',
        archived: false,
      );

      expect(
        archived.after.storylines.first.chapters.single.steps.single.status,
        StorylineStatus.archived,
      );
      expect(restored.after, storylineTrameProject());
    });
  });
}
