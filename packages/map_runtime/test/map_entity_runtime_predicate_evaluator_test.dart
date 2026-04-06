import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../lib/src/application/global_story_chapter_runtime.dart';
import '../lib/src/application/map_entity_runtime_predicate_evaluator.dart';

GameState _state({
  Set<String> flags = const {},
  List<String> completedSteps = const [],
  List<String> completedCutscenes = const [],
}) {
  return GameState(
    saveId: 't',
    storyFlags: StoryFlags(activeFlags: flags),
    progression: PlayerProgression(
      completedStepIds: completedSteps,
      completedCutsceneIds: completedCutscenes,
    ),
  );
}

MapEntity _npc(MapEntityNpcData npc) {
  return MapEntity(
    id: 'n1',
    kind: MapEntityKind.npc,
    pos: const GridPos(x: 0, y: 0),
    npc: npc,
  );
}

void main() {
  final emptyChapters =
      GlobalStoryChapterStepIndex(chapterIdToStepIds: const {});

  test('flag actif → visibleWhen true', () {
    final ev = MapEntityRuntimePredicateEvaluator(
      gameState: _state(flags: {'f1'}),
      chapterIndex: emptyChapters,
    );
    final entity = _npc(
      const MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'f1',
          ),
        ),
      ),
    );
    expect(ev.isNpcPresentOnMap(entity), isTrue);
  });

  test('step terminée → hiddenWhen masque le PNJ', () {
    final ev = MapEntityRuntimePredicateEvaluator(
      gameState: _state(completedSteps: ['s1']),
      chapterIndex: emptyChapters,
    );
    final entity = _npc(
      const MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 's1',
          ),
        ),
      ),
    );
    expect(ev.isNpcPresentOnMap(entity), isFalse);
  });

  test('chapitre terminé quand toutes les steps le sont', () {
    final chapters = GlobalStoryChapterStepIndex(
      chapterIdToStepIds: {
        'ch1': ['a', 'b'],
      },
    );
    final incomplete = MapEntityRuntimePredicateEvaluator(
      gameState: _state(completedSteps: ['a']),
      chapterIndex: chapters,
    );
    final complete = MapEntityRuntimePredicateEvaluator(
      gameState: _state(completedSteps: ['a', 'b']),
      chapterIndex: chapters,
    );
    const pred = MapEntityRuntimePredicate(
      kind: MapEntityRuntimePredicateKind.chapterCompleted,
      refId: 'ch1',
    );
    expect(incomplete.evaluatePredicate(pred), isFalse);
    expect(complete.evaluatePredicate(pred), isTrue);
  });

  test('résolution dialogue : première variante qui matche, sinon défaut', () {
    final ev = MapEntityRuntimePredicateEvaluator(
      gameState: _state(flags: {'x'}, completedSteps: ['s2']),
      chapterIndex: emptyChapters,
    );
    const npc = MapEntityNpcData(
      dialogue: DialogueRef(dialogueId: 'default_dlg'),
      conditionalDialogues: [
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 's1',
          ),
          dialogue: DialogueRef(dialogueId: 'first'),
        ),
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 's2',
          ),
          dialogue: DialogueRef(dialogueId: 'second'),
        ),
      ],
    );
    expect(ev.resolveNpcDialogue(npc)?.dialogueId, 'second');
  });

  test('fallback dialogue par défaut si aucune variante ne matche', () {
    final ev = MapEntityRuntimePredicateEvaluator(
      gameState: _state(),
      chapterIndex: emptyChapters,
    );
    const npc = MapEntityNpcData(
      dialogue: DialogueRef(dialogueId: 'only_default'),
      conditionalDialogues: [
        MapEntityConditionalDialogue(
          when: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagSet,
            refId: 'missing',
          ),
          dialogue: DialogueRef(dialogueId: 'never'),
        ),
      ],
    );
    expect(ev.resolveNpcDialogue(npc)?.dialogueId, 'only_default');
  });

  test('cutsceneCompleted lit completedCutsceneIds', () {
    final ev = MapEntityRuntimePredicateEvaluator(
      gameState: _state(completedCutscenes: ['local_cut']),
      chapterIndex: emptyChapters,
    );
    expect(
      ev.evaluatePredicate(
        const MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.cutsceneCompleted,
          refId: 'local_cut',
        ),
      ),
      isTrue,
    );
  });
}
