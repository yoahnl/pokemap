import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

const _day = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.localTimeWindow,
  timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200),
);
const _night = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.localTimeWindow,
  timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240),
);
const _chapters = GlobalStoryChapterStepIndex(chapterIdToStepIds: {});
const _guard = MapEntityNpcData(
  trainerId: 'guard',
  dialogue: DialogueRef(dialogueId: 'day_talk'),
  defeatDialogueRef: DialogueRef(dialogueId: 'night_defeated'),
  trainerBattleWhen: _night,
);
const _trainer = ProjectTrainerEntry(
  id: 'guard',
  name: 'Guard',
  trainerClass: 'Police',
  preBattleDialogueId: 'night_challenge',
);

void main() {
  for (final (minute, day, night) in [
    (0, false, true),
    (239, false, true),
    (240, true, false),
    (1199, true, false),
    (1200, false, true),
    (1439, false, true),
  ]) {
    test('NPC presence, dialogue and battle share boundary minute $minute', () {
      final evaluator = MapEntityRuntimePredicateEvaluator(
        gameState: const GameState(saveId: 'hours'),
        chapterIndex: _chapters,
        localMinuteOfDay: minute,
      );
      const npc = MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: _day,
        ),
      );
      const entity = MapEntity(
        id: 'day_npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
        npc: npc,
      );
      expect(evaluator.isNpcPresentOnMap(entity), day);
      expect(evaluator.evaluatePredicate(_night), night);
      expect(
        evaluator
            .resolveNpcDialogue(
              const MapEntityNpcData(
                dialogue: DialogueRef(dialogueId: 'day'),
                conditionalDialogues: [
                  MapEntityConditionalDialogue(
                    when: _night,
                    dialogue: DialogueRef(dialogueId: 'night'),
                  ),
                ],
              ),
            )
            ?.dialogueId,
        night ? 'night' : 'day',
      );
      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: _trainer,
        npc: _guard,
        isDefeated: false,
        battleAllowed: evaluator.evaluatePredicate(_night),
      );
      expect(
        plan.disposition,
        night
            ? RuntimeTrainerInteractionDisposition.dialogueThenBattle
            : RuntimeTrainerInteractionDisposition.dialogueOnly,
      );
      expect(plan.dialogue?.dialogueId, night ? 'night_challenge' : 'day_talk');
    });
  }

  test(
    'an authored battle rule without a clock decision fails closed to talk',
    () {
      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: _trainer,
        npc: _guard,
        isDefeated: false,
      );
      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueOnly,
      );
      expect(plan.dialogue?.dialogueId, 'day_talk');
    },
  );

  for (final minute in [null, -1, 1440]) {
    test(
      'missing or invalid clock $minute hides both conditional presence modes',
      () {
        final evaluator = MapEntityRuntimePredicateEvaluator(
          gameState: const GameState(saveId: 'hours'),
          chapterIndex: _chapters,
          localMinuteOfDay: minute,
        );
        for (final mode in [
          MapEntityNpcVisibilityMode.visibleWhen,
          MapEntityNpcVisibilityMode.hiddenWhen,
        ]) {
          final entity = MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              visibilityRule: MapEntityNpcVisibilityRule(
                mode: mode,
                predicate: _day,
              ),
            ),
          );
          expect(evaluator.isNpcPresentOnMap(entity), isFalse);
        }
        expect(evaluator.evaluatePredicate(_night), isFalse);
      },
    );
  }

  test(
    'invalid programmatic windows and mixed reference fields fail closed',
    () {
      final evaluator = MapEntityRuntimePredicateEvaluator(
        gameState: const GameState(saveId: 'hours'),
        chapterIndex: _chapters,
        localMinuteOfDay: 300,
      );
      for (final predicate in [
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagUnset,
          refId: 'unexpected',
          timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200),
        ),
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
        ),
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
          refId: 'unexpected',
          timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 1200),
        ),
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
          timeWindow: LocalTimeWindow(startMinute: 240, endMinute: 240),
        ),
      ]) {
        expect(evaluator.evaluatePredicate(predicate), isFalse);
        for (final mode in [
          MapEntityNpcVisibilityMode.visibleWhen,
          MapEntityNpcVisibilityMode.hiddenWhen,
        ]) {
          final entity = MapEntity(
            id: 'invalid',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(
              visibilityRule: MapEntityNpcVisibilityRule(
                mode: mode,
                predicate: predicate,
              ),
            ),
          );
          expect(evaluator.isNpcPresentOnMap(entity), isFalse);
        }
      }
    },
  );

  test('a null battle rule keeps the normal trainer lifecycle', () {
    final npc = _guard.copyWith(trainerBattleWhen: null);
    expect(
      resolveRuntimeTrainerInteractionPlan(
        trainer: _trainer,
        npc: npc,
        isDefeated: false,
      ).disposition,
      RuntimeTrainerInteractionDisposition.dialogueThenBattle,
    );
  });

  test('time gates also apply after victory and before an allowed rematch', () {
    for (final rematch in [null, ProjectTrainerRematchPolicy.allowed]) {
      final trainer = _trainer.copyWith(rematchPolicy: rematch);
      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: _guard,
        isDefeated: true,
        battleAllowed: false,
      );
      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueOnly,
      );
      expect(plan.dialogue?.dialogueId, 'day_talk');
    }
  });

  test(
    'save reload restores progress and reevaluates the current local clock',
    () {
      final state = const StoryFlagsManager().markTrainerDefeated(
        const GameState(saveId: 'hours'),
        'guard',
      );
      final restored = gameStateFromStrictSaveJson(
        strictGameStateSaveJson(state),
      );
      final evaluator = MapEntityRuntimePredicateEvaluator(
        gameState: restored,
        chapterIndex: _chapters,
        localMinuteOfDay: 1200,
      );
      expect(evaluator.evaluatePredicate(_night), isTrue);
      expect(
        const StoryFlagsManager().isTrainerDefeated(restored, 'guard'),
        isTrue,
      );
      expect(
        strictGameStateSaveJson(restored).toString(),
        isNot(contains('localMinuteOfDay')),
      );
    },
  );
}
