import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runtime trainer lifecycle policy', () {
    const npc = MapEntityNpcData(
      displayName: 'Lysa',
      dialogue: DialogueRef(dialogueId: 'npc_before'),
      trainerId: 'lysa',
      defeatDialogueRef: DialogueRef(dialogueId: 'npc_victory'),
    );

    test('undefeated trainer shows pre-battle dialogue then battles', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: false,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueThenBattle,
      );
      expect(plan.dialogue?.dialogueId, 'npc_before');
    });

    test('one-shot defeated trainer only shows victory dialogue', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: true,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueOnly,
      );
      expect(plan.dialogue?.dialogueId, 'npc_victory');
    });

    test('allowed rematch shows victory dialogue then battles again', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
        rematchPolicy: ProjectTrainerRematchPolicy.allowed,
      );

      final plan = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: npc,
        isDefeated: true,
      );

      expect(
        plan.disposition,
        RuntimeTrainerInteractionDisposition.dialogueThenBattle,
      );
      expect(plan.dialogue?.dialogueId, 'npc_victory');
    });

    test('trainer lifecycle dialogue ids override NPC fallback refs', () {
      const trainer = ProjectTrainerEntry(
        id: 'lysa',
        name: 'Lysa',
        trainerClass: 'Rival',
        preBattleDialogueId: 'trainer_before',
        victoryDialogueId: 'trainer_victory',
        defeatDialogueId: 'trainer_defeat',
      );

      expect(
        resolveRuntimeTrainerInteractionPlan(
          trainer: trainer,
          npc: npc,
          isDefeated: false,
        ).dialogue?.dialogueId,
        'trainer_before',
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: npc,
          result: RuntimeTrainerPostBattleResult.victory,
        )?.dialogueId,
        'trainer_victory',
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: npc,
          result: RuntimeTrainerPostBattleResult.defeat,
        )?.dialogueId,
        'trainer_defeat',
      );
    });

    test('missing dialogue falls back to a direct battle or no hook', () {
      const trainer = ProjectTrainerEntry(
        id: 'ace',
        name: 'Ace',
        trainerClass: 'Trainer',
      );

      final initial = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: const MapEntityNpcData(trainerId: 'ace'),
        isDefeated: false,
      );
      final defeated = resolveRuntimeTrainerInteractionPlan(
        trainer: trainer,
        npc: const MapEntityNpcData(trainerId: 'ace'),
        isDefeated: true,
      );

      expect(
        initial.disposition,
        RuntimeTrainerInteractionDisposition.battle,
      );
      expect(
        defeated.disposition,
        RuntimeTrainerInteractionDisposition.blocked,
      );
      expect(
        resolveRuntimeTrainerPostBattleDialogue(
          trainer: trainer,
          npc: const MapEntityNpcData(trainerId: 'ace'),
          result: RuntimeTrainerPostBattleResult.defeat,
        ),
        isNull,
      );
    });
  });
}
