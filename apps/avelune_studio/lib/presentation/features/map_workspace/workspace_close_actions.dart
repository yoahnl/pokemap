part of 'workspace_actions.dart';

extension _WorkspaceCloseActions on WorkspaceActions {
  Future<bool> _allowClose() async {
    if (!_flushDialogueEdit()) return false;
    if (!await _flushEventEdits()) return false;
    if (controller.saving || busy) return false;
    if (!hasPendingChanges) {
      return true;
    }
    closing = true;
    changed();
    try {
      final choice = await confirmStudioClose(context());
      if (!mounted() || choice == null || choice == 'cancel') return false;
      if (choice == 'save') return await _saveOwnedChanges();
      return choice == 'discard';
    } finally {
      closing = false;
      changed();
    }
  }

  Future<bool> _saveOwnedChanges() async {
    if (!_flushDialogueEdit() || !await _flushEventEdits()) return false;
    if (controller.saving || (busy && !closing) || !_validateWorldInputs()) {
      return false;
    }
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
    if (dialogues?.call() case final owner?) {
      if (!await owner.saveAll()) return false;
    }
    if (scenes?.call() case final owner?) {
      if (!await owner.saveAll()) return false;
    }
    if (resources() != null && !await resources()!.saveDrafts()) return false;
    if (narrative() != null && !await narrative()!.saveAll()) return false;
    if (events?.call() case final owner?) {
      if (!await owner.saveAll()) return false;
    }
    if (world?.call() case final owner?) {
      if (!await owner.saveAll()) {
        controller.error = owner.error;
        return false;
      }
    }
    if (!await controller.saveAll() || !_validateWorldInputs()) return false;
    if (hasPendingChanges) {
      controller.error =
          'Des documents ont encore changé pendant l’enregistrement. '
          'Les sauvegardes déjà terminées sont conservées avec vos brouillons.';
      return false;
    }
    return true;
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
