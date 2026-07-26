import 'package:map_core/map_core.dart';

/// Action autorisée avant de confier le combat au bridge runtime.
enum RuntimeTrainerInteractionDisposition {
  battle,
  dialogueThenBattle,
  dialogueOnly,
  blocked,
}

enum RuntimeTrainerPostBattleResult {
  victory,
  defeat,
}

final class RuntimeTrainerInteractionPlan {
  const RuntimeTrainerInteractionPlan({
    required this.disposition,
    this.dialogue,
  });

  final RuntimeTrainerInteractionDisposition disposition;
  final DialogueRef? dialogue;
}

/// Résout le cycle de vie sans dépendre de Flame.
///
/// Le flag persistant `trainer_defeated:<id>` est fourni par l'appelant via
/// [isDefeated]. Une valeur `null` de [ProjectTrainerEntry.rematchPolicy]
/// conserve le comportement historique one-shot ; seule la valeur explicite
/// `allowed` autorise un nouveau combat.
RuntimeTrainerInteractionPlan resolveRuntimeTrainerInteractionPlan({
  required ProjectTrainerEntry trainer,
  required MapEntityNpcData npc,
  required bool isDefeated,
}) {
  if (isDefeated) {
    final dialogue = _trainerDialogueRef(
          trainer.victoryDialogueId,
        ) ??
        npc.defeatDialogueRef;
    final rematchAllowed =
        trainer.rematchPolicy == ProjectTrainerRematchPolicy.allowed;
    if (rematchAllowed) {
      return RuntimeTrainerInteractionPlan(
        disposition: dialogue == null
            ? RuntimeTrainerInteractionDisposition.battle
            : RuntimeTrainerInteractionDisposition.dialogueThenBattle,
        dialogue: dialogue,
      );
    }
    return RuntimeTrainerInteractionPlan(
      disposition: dialogue == null
          ? RuntimeTrainerInteractionDisposition.blocked
          : RuntimeTrainerInteractionDisposition.dialogueOnly,
      dialogue: dialogue,
    );
  }

  final dialogue = _trainerDialogueRef(
        trainer.preBattleDialogueId,
      ) ??
      npc.dialogue;
  return RuntimeTrainerInteractionPlan(
    disposition: dialogue == null
        ? RuntimeTrainerInteractionDisposition.battle
        : RuntimeTrainerInteractionDisposition.dialogueThenBattle,
    dialogue: dialogue,
  );
}

/// Choisit le hook post-combat authoré pour un combat trainer direct.
///
/// Le fallback NPC de victoire reste accepté pour préserver les projets
/// historiques. La défaite joueur n'avait pas de fallback historique : elle
/// reste donc strictement opt-in via le contrat trainer.
DialogueRef? resolveRuntimeTrainerPostBattleDialogue({
  required ProjectTrainerEntry trainer,
  required MapEntityNpcData npc,
  required RuntimeTrainerPostBattleResult result,
}) {
  return switch (result) {
    RuntimeTrainerPostBattleResult.victory =>
      _trainerDialogueRef(trainer.victoryDialogueId) ?? npc.defeatDialogueRef,
    RuntimeTrainerPostBattleResult.defeat =>
      _trainerDialogueRef(trainer.defeatDialogueId),
  };
}

DialogueRef? _trainerDialogueRef(String? dialogueId) {
  final normalized = dialogueId?.trim();
  return normalized == null || normalized.isEmpty
      ? null
      : DialogueRef(dialogueId: normalized);
}
