part of 'workspace_actions.dart';

extension _WorkspaceCloseActions on WorkspaceActions {
  Future<bool> _allowClose() async {
    if (!_flushDialogueEdit()) return false;
    if (!await _flushEventEdits()) return false;
    if (controller.saving || busy) return false;
    if (!controller.dirty &&
        resources()?.dirty != true &&
        narrative()?.dirty != true &&
        dialogues?.call()?.dirty != true &&
        cinematics?.call()?.dirty != true &&
        presentations?.call()?.dirty != true &&
        events?.call()?.dirty != true &&
        scenes?.call()?.dirty != true &&
        world?.call()?.hasRuleDraft != true &&
        worldInputsValid?.call() != false) {
      return true;
    }
    closing = true;
    changed();
    try {
      final choice = await confirmStudioClose(context());
      if (!mounted() || choice == null || choice == 'cancel') return false;
      if (choice == 'save') {
        if (!_validateWorldInputs()) return false;
        if (world?.call() case final owner?) {
          if (!await owner.saveNewFacts()) {
            controller.error = owner.error;
            return false;
          }
        }
        if (presentations?.call() case final owner?) {
          if (!await owner.saveAll()) return false;
        }
        if (cinematics?.call() case final owner?) {
          if (!await owner.saveAll()) return false;
        }
        if (dialogues?.call() case final dialogueController?) {
          if (!await dialogueController.saveAll()) return false;
        }
        if (scenes?.call() case final sceneController?) {
          if (!await sceneController.saveAll()) return false;
        }
        if (resources() != null && !await resources()!.saveDrafts()) {
          return false;
        }
        if (narrative() != null && !await narrative()!.saveAll()) return false;
        if (events?.call() case final eventController?) {
          if (!await eventController.saveAll()) return false;
        }
        if (world?.call() case final worldController?) {
          if (!await worldController.saveAll()) {
            controller.error = worldController.error;
            return false;
          }
        }
        if (!await controller.saveAll()) return false;
        if (!_validateWorldInputs()) return false;
        if (world?.call()?.dirty == true) {
          controller.error =
              'Des états ou règles ont encore changé. Leurs brouillons '
              'sont conservés ; enregistrez-les avant de fermer.';
          return false;
        }
        return true;
      }
      return choice == 'discard';
    } finally {
      closing = false;
      changed();
    }
  }

  bool _validateWorldInputs() {
    if (worldInputsValid?.call() != false) return true;
    const message =
        'Corrigez les champs invalides des états ou des règles avant '
        'd’enregistrer. Aucune saisie refusée n’a été publiée.';
    world?.call()?.error = message;
    controller.error = message;
    return false;
  }
}
