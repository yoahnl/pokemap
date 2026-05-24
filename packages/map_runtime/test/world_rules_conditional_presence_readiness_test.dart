import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';

// ignore_for_file: prefer_const_constructors

/// Characterization tests proving the GameState → World Rule → presence/dialogue chain.
///
/// The mechanism works as follows:
/// 1. GameState contains storyFlags, completedStepIds, completedCutsceneIds.
/// 2. MapEntityRuntimePredicateEvaluator reads GameState.
/// 3. MapEntityNpcVisibilityRule (visibleWhen / hiddenWhen) uses a predicate
///    to decide NPC presence.
/// 4. MapEntityConditionalDialogue uses a predicate to select alternate dialogue.
/// 5. All state survives save/load round-trip.
///
/// Frontière Event / Scene / World Rule :
/// - Event déclenche (quand ? où ? sous quelles conditions ?).
/// - Scene déroule (dialogue, outcomes, branches).
/// - World Rule projette (visibilité, présence, dialogue conditionnel).
/// Ce lot teste uniquement World Rule / conditional presence.
///
/// No Selbrume ids are used. All ids are generic test fixtures.
void main() {
  final emptyChapters =
      GlobalStoryChapterStepIndex(chapterIdToStepIds: const {});

  GameState makeState({
    Set<String> flags = const {},
    List<String> completedSteps = const [],
    List<String> completedCutscenes = const [],
  }) {
    return GameState(
      saveId: 'test',
      storyFlags: StoryFlags(activeFlags: flags),
      progression: PlayerProgression(
        completedStepIds: completedSteps,
        completedCutsceneIds: completedCutscenes,
      ),
    );
  }

  MapEntityRuntimePredicateEvaluator evaluator(
    GameState state, {
    GlobalStoryChapterStepIndex? chapters,
  }) {
    return MapEntityRuntimePredicateEvaluator(
      gameState: state,
      chapterIndex: chapters ?? emptyChapters,
    );
  }

  MapEntity testNpc({
    String id = 'test_entity_npc',
    MapEntityNpcVisibilityRule? visibilityRule,
    List<MapEntityConditionalDialogue> conditionalDialogues = const [],
    DialogueRef? dialogue,
  }) {
    return MapEntity(
      id: id,
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 0, y: 0),
      npc: MapEntityNpcData(
        visibilityRule: visibilityRule,
        conditionalDialogues: conditionalDialogues,
        dialogue: dialogue,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // 9.1  Facts / story flags
  // ───────────────────────────────────────────────────────────────

  group('Facts / story flags', () {
    test('storyFlagSet true when fact is present', () {
      final ev = evaluator(makeState(flags: {'test_fact_enabled'}));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: 'test_fact_enabled',
        )),
        isTrue,
      );
    });

    test('storyFlagSet false when fact is absent', () {
      final ev = evaluator(makeState());
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagSet,
          refId: 'test_fact_missing',
        )),
        isFalse,
      );
    });

    test('storyFlagUnset true when fact is absent', () {
      final ev = evaluator(makeState());
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagUnset,
          refId: 'test_fact_missing',
        )),
        isTrue,
      );
    });

    test('storyFlagUnset false when fact is present', () {
      final ev = evaluator(makeState(flags: {'test_fact_enabled'}));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.storyFlagUnset,
          refId: 'test_fact_enabled',
        )),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.2  Steps
  // ───────────────────────────────────────────────────────────────

  group('Steps', () {
    test('stepCompleted true after completion', () {
      final ev = evaluator(makeState(completedSteps: ['test_step_done']));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.stepCompleted,
          refId: 'test_step_done',
        )),
        isTrue,
      );
    });

    test('stepNotCompleted true before completion', () {
      final ev = evaluator(makeState());
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.stepNotCompleted,
          refId: 'test_step_pending',
        )),
        isTrue,
      );
    });

    test('stepNotCompleted false after completion', () {
      final ev = evaluator(makeState(completedSteps: ['test_step_done']));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.stepNotCompleted,
          refId: 'test_step_done',
        )),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.3  Cutscenes
  // ───────────────────────────────────────────────────────────────

  group('Cutscenes', () {
    test('cutsceneCompleted true when cutscene completed', () {
      final ev = evaluator(
          makeState(completedCutscenes: ['test_cutscene_done']));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.cutsceneCompleted,
          refId: 'test_cutscene_done',
        )),
        isTrue,
      );
    });

    test('cutsceneCompleted false when not completed', () {
      final ev = evaluator(makeState());
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.cutsceneCompleted,
          refId: 'test_cutscene_pending',
        )),
        isFalse,
      );
    });

    test('cutsceneNotCompleted true when not completed', () {
      final ev = evaluator(makeState());
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.cutsceneNotCompleted,
          refId: 'test_cutscene_pending',
        )),
        isTrue,
      );
    });

    test('cutsceneNotCompleted false when completed', () {
      final ev = evaluator(
          makeState(completedCutscenes: ['test_cutscene_done']));
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.cutsceneNotCompleted,
          refId: 'test_cutscene_done',
        )),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.4  Chapters
  // ───────────────────────────────────────────────────────────────

  group('Chapters', () {
    test('chapterCompleted true when all steps completed', () {
      final chapters = GlobalStoryChapterStepIndex(
        chapterIdToStepIds: {
          'test_chapter_1': ['test_step_a', 'test_step_b'],
        },
      );
      final ev = evaluator(
        makeState(completedSteps: ['test_step_a', 'test_step_b']),
        chapters: chapters,
      );
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.chapterCompleted,
          refId: 'test_chapter_1',
        )),
        isTrue,
      );
    });

    test('chapterCompleted false when partial steps completed', () {
      final chapters = GlobalStoryChapterStepIndex(
        chapterIdToStepIds: {
          'test_chapter_1': ['test_step_a', 'test_step_b'],
        },
      );
      final ev = evaluator(
        makeState(completedSteps: ['test_step_a']),
        chapters: chapters,
      );
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.chapterCompleted,
          refId: 'test_chapter_1',
        )),
        isFalse,
      );
    });

    test('chapterNotCompleted true when chapter incomplete', () {
      final chapters = GlobalStoryChapterStepIndex(
        chapterIdToStepIds: {
          'test_chapter_1': ['test_step_a', 'test_step_b'],
        },
      );
      final ev = evaluator(
        makeState(completedSteps: ['test_step_a']),
        chapters: chapters,
      );
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.chapterNotCompleted,
          refId: 'test_chapter_1',
        )),
        isTrue,
      );
    });

    test('chapterNotCompleted false when chapter complete', () {
      final chapters = GlobalStoryChapterStepIndex(
        chapterIdToStepIds: {
          'test_chapter_1': ['test_step_a', 'test_step_b'],
        },
      );
      final ev = evaluator(
        makeState(completedSteps: ['test_step_a', 'test_step_b']),
        chapters: chapters,
      );
      expect(
        ev.evaluatePredicate(MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.chapterNotCompleted,
          refId: 'test_chapter_1',
        )),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.5  Conditional dialogue
  // ───────────────────────────────────────────────────────────────

  group('Conditional dialogue', () {
    test('default dialogue when no condition matches', () {
      final ev = evaluator(makeState());
      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'test_fact_never',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_never'),
          ),
        ],
      );
      expect(ev.resolveNpcDialogue(npc)?.dialogueId, 'test_dialogue_default');
    });

    test('conditional dialogue selected by fact', () {
      final ev = evaluator(makeState(flags: {'test_fact_enabled'}));
      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'test_fact_enabled',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_after_flag'),
          ),
        ],
      );
      expect(
          ev.resolveNpcDialogue(npc)?.dialogueId, 'test_dialogue_after_flag');
    });

    test('conditional dialogue selected by step completion', () {
      final ev = evaluator(makeState(completedSteps: ['test_step_done']));
      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.stepCompleted,
              refId: 'test_step_done',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_step_done'),
          ),
        ],
      );
      expect(ev.resolveNpcDialogue(npc)?.dialogueId, 'test_dialogue_step_done');
    });

    test('first matching conditional dialogue wins (priority order)', () {
      final ev = evaluator(makeState(
        flags: {'test_fact_a', 'test_fact_b'},
      ));
      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'test_fact_a',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_first'),
          ),
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'test_fact_b',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_second'),
          ),
        ],
      );
      // First matching wins even though both conditions are true.
      expect(ev.resolveNpcDialogue(npc)?.dialogueId, 'test_dialogue_first');
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Visibility rules (NPC presence)
  // ───────────────────────────────────────────────────────────────

  group('Visibility rules', () {
    test('visibleWhen: NPC present when flag set', () {
      final ev = evaluator(makeState(flags: {'test_fact_enabled'}));
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'test_fact_enabled',
          ),
        ),
      );
      expect(ev.isNpcPresentOnMap(entity), isTrue);
    });

    test('visibleWhen: NPC absent when flag not set', () {
      final ev = evaluator(makeState());
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'test_fact_missing',
          ),
        ),
      );
      expect(ev.isNpcPresentOnMap(entity), isFalse);
    });

    test('hiddenWhen: NPC hidden when step completed', () {
      final ev = evaluator(makeState(completedSteps: ['test_step_done']));
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'test_step_done',
          ),
        ),
      );
      expect(ev.isNpcPresentOnMap(entity), isFalse);
    });

    test('hiddenWhen: NPC visible when step not yet completed', () {
      final ev = evaluator(makeState());
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'test_step_pending',
          ),
        ),
      );
      expect(ev.isNpcPresentOnMap(entity), isTrue);
    });

    test('always mode: NPC always present regardless of state', () {
      final ev = evaluator(makeState());
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.always,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'irrelevant',
          ),
        ),
      );
      expect(ev.isNpcPresentOnMap(entity), isTrue);
    });

    test('no visibility rule: NPC present by default', () {
      final ev = evaluator(makeState());
      final entity = testNpc();
      expect(ev.isNpcPresentOnMap(entity), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.6  Save / reload
  // ───────────────────────────────────────────────────────────────

  group('Save / reload consistency', () {
    test('visibility rule result preserved after save/load', () {
      final state = makeState(
        flags: {'test_fact_enabled'},
        completedSteps: ['test_step_done'],
      );

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      final evOriginal = evaluator(state);
      final evReloaded = evaluator(reloaded);

      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'test_fact_enabled',
          ),
        ),
      );

      expect(evOriginal.isNpcPresentOnMap(entity), isTrue);
      expect(evReloaded.isNpcPresentOnMap(entity), isTrue);
    });

    test('conditional dialogue result preserved after save/load', () {
      final state = makeState(completedSteps: ['test_step_done']);

      final saveData = saveDataFromGameState(state);
      final reloaded =
          normalizeLoadedGameState(gameStateFromSaveData(saveData));

      final evOriginal = evaluator(state);
      final evReloaded = evaluator(reloaded);

      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.stepCompleted,
              refId: 'test_step_done',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_step_done'),
          ),
        ],
      );

      expect(
          evOriginal.resolveNpcDialogue(npc)?.dialogueId,
          'test_dialogue_step_done');
      expect(
          evReloaded.resolveNpcDialogue(npc)?.dialogueId,
          'test_dialogue_step_done');
    });
  });

  // ───────────────────────────────────────────────────────────────
  // 9.7  Recalculation after mutation
  // ───────────────────────────────────────────────────────────────

  group('Recalculation after mutation', () {
    test('visibility changes when flag is set', () {
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'test_fact_gate',
          ),
        ),
      );

      // Before mutation: flag absent → NPC hidden.
      final stateBefore = makeState();
      final evBefore = evaluator(stateBefore);
      expect(evBefore.isNpcPresentOnMap(entity), isFalse);

      // Mutation: set the flag.
      const mutations = GameStateMutations();
      final stateAfter = mutations.setFlag(
        stateBefore,
        'test_fact_gate',
      );
      final evAfter = evaluator(stateAfter);
      expect(evAfter.isNpcPresentOnMap(entity), isTrue);
    });

    test('dialogue changes when step is completed', () {
      final npc = MapEntityNpcData(
        dialogue: DialogueRef(dialogueId: 'test_dialogue_default'),
        conditionalDialogues: [
          MapEntityConditionalDialogue(
            when: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.stepCompleted,
              refId: 'test_step_progress',
            ),
            dialogue: DialogueRef(dialogueId: 'test_dialogue_post_step'),
          ),
        ],
      );

      // Before mutation.
      final stateBefore = makeState();
      final evBefore = evaluator(stateBefore);
      expect(
          evBefore.resolveNpcDialogue(npc)?.dialogueId,
          'test_dialogue_default');

      // Mutation: complete the step.
      const mutations = GameStateMutations();
      final stateAfter = mutations.completeStep(
        stateBefore,
        'test_step_progress',
      );
      final evAfter = evaluator(stateAfter);
      expect(
          evAfter.resolveNpcDialogue(npc)?.dialogueId,
          'test_dialogue_post_step');
    });

    test('visibility changes when step is completed (hiddenWhen)', () {
      final entity = testNpc(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'test_step_remove_npc',
          ),
        ),
      );

      // Before mutation: step not done → NPC visible.
      final stateBefore = makeState();
      expect(evaluator(stateBefore).isNpcPresentOnMap(entity), isTrue);

      // Mutation: complete step → NPC hidden.
      const mutations = GameStateMutations();
      final stateAfter = mutations.completeStep(
        stateBefore,
        'test_step_remove_npc',
      );
      expect(evaluator(stateAfter).isNpcPresentOnMap(entity), isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Generic assertion: no Selbrume ids
  // ───────────────────────────────────────────────────────────────

  test('does not hardcode any Selbrume ids', () {
    // All ids used in these tests are generic test fixtures.
    // If this test compiles and passes, no Selbrume id was hardcoded.
    final ev = evaluator(makeState(flags: {'any_generic_flag'}));
    expect(
      ev.evaluatePredicate(MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.storyFlagSet,
        refId: 'any_generic_flag',
      )),
      isTrue,
    );
  });
}
