import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/global_story_chapter_runtime.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/map_entity_runtime_predicate_evaluator.dart';
import 'package:map_runtime/src/application/runtime_trainer_lifecycle_policy.dart';

const ready = MapEntityRuntimePredicate(
  kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
  minimumCount: 2,
);
const trainer = ProjectTrainerEntry(
  id: 'pair',
  name: 'Duo',
  trainerClass: 'Duo',
  preBattleDialogueId: 'intro',
  victoryDialogueId: 'result',
);
const npc = MapEntityNpcData(
  trainerId: 'pair',
  dialogue: DialogueRef(dialogueId: 'day'),
  defeatDialogueRef: DialogueRef(dialogueId: 'after'),
  trainerBattleReadyWhen: ready,
  trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'refusal'),
);
PlayerPokemon mon(String id, int hp) => PlayerPokemon(
  individualId: id,
  speciesId: 'rattata',
  natureId: 'hardy',
  abilityId: 'run_away',
  currentHp: hp,
);
MapEntityRuntimePredicateEvaluator evaluator(List<int> hp) =>
    MapEntityRuntimePredicateEvaluator(
      gameState: GameState(
        saveId: 'ready',
        party: PlayerParty(
          members: [for (var i = 0; i < hp.length; i++) mon('$i', hp[i])],
        ),
      ),
      chapterIndex: const GlobalStoryChapterStepIndex(chapterIdToStepIds: {}),
    );
void main() {
  test('a fainted lead is skipped for both active double battle slots', () {
    final current = evaluator([0, 1, 1]);
    expect(current.evaluatePredicate(ready), isTrue);
    final selection = RuntimeBattleSetupMapper().selectPlayerBattleLineup(
      current.gameState.party,
      activeCount: 2,
    );
    expect(selection.activeIndex, 1);
    expect(selection.lineupPartyIndices, [1, 2, 0]);
    expect(
      selection.lineupPartyIndices
          .take(2)
          .map((index) => current.gameState.party.members[index].isFainted),
      everyElement(isFalse),
    );
  });

  test(
    'availability, defeated lifecycle and readiness have explicit priority',
    () {
      for (final defeated in [false, true]) {
        for (final allowed in [false, true]) {
          for (final isReady in [false, true]) {
            final plan = resolveRuntimeTrainerInteractionPlan(
              trainer: trainer,
              npc: npc,
              isDefeated: defeated,
              battleAllowed: allowed,
              battleReady: isReady,
            );
            expect(
              plan.dialogue?.dialogueId,
              !allowed
                  ? 'day'
                  : defeated
                  ? 'after'
                  : !isReady
                  ? 'refusal'
                  : 'intro',
            );
            expect(
              plan.disposition,
              allowed && !defeated && isReady
                  ? RuntimeTrainerInteractionDisposition.dialogueThenBattle
                  : RuntimeTrainerInteractionDisposition.dialogueOnly,
            );
          }
        }
      }
    },
  );
  test(
    'a newly fainted or withdrawn member changes the next readiness decision',
    () {
      expect(evaluator([1, 1]).evaluatePredicate(ready), isTrue);
      for (final hp in [
        [1, 0],
        [1],
        <int>[],
      ]) {
        final current = evaluator(hp);
        expect(current.evaluatePredicate(ready), isFalse);
        final plan = resolveRuntimeTrainerInteractionPlan(
          trainer: trainer,
          npc: npc,
          isDefeated: false,
          battleReady: current.evaluatePredicate(ready),
        );
        expect(plan.dialogue?.dialogueId, 'refusal');
        expect(
          plan.disposition,
          RuntimeTrainerInteractionDisposition.dialogueOnly,
        );
      }
    },
  );
  test('missing readiness decision and malformed thresholds fail closed', () {
    expect(
      resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: false,
      ).dialogue?.dialogueId,
      'refusal',
    );
    for (final count in [null, 0, 7]) {
      final bad = MapEntityRuntimePredicate(
        kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
        minimumCount: count,
      );
      expect(evaluator([1, 1]).evaluatePredicate(bad), isFalse);
      for (final mode in [
        MapEntityNpcVisibilityMode.visibleWhen,
        MapEntityNpcVisibilityMode.hiddenWhen,
      ]) {
        expect(
          evaluator([1, 1]).isNpcPresentOnMap(
            MapEntity(
              id: 'n',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 0, y: 0),
              npc: MapEntityNpcData(
                visibilityRule: MapEntityNpcVisibilityRule(
                  mode: mode,
                  predicate: bad,
                ),
              ),
            ),
          ),
          isFalse,
        );
      }
    }
  });
  test(
    'refusal is optional and an explicit rematch still requires readiness',
    () {
      expect(
        resolveRuntimeTrainerInteractionPlan(
          trainer: trainer,
          npc: npc.copyWith(trainerBattleNotReadyDialogue: null),
          isDefeated: false,
          battleReady: false,
        ).disposition,
        RuntimeTrainerInteractionDisposition.blocked,
      );
      expect(
        resolveRuntimeTrainerInteractionPlan(
          trainer: trainer.copyWith(
            rematchPolicy: ProjectTrainerRematchPolicy.allowed,
          ),
          npc: npc,
          isDefeated: true,
          battleReady: false,
        ).dialogue?.dialogueId,
        'refusal',
      );
    },
  );
}
