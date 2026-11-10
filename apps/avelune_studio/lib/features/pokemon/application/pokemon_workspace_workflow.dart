import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_external_import_models.dart';
import 'pokemon_workspace_controller.dart';

enum PokemonDraftDecision { stay, discard, save }

class PokemonWorkspaceWorkflow {
  PokemonWorkspaceWorkflow({
    required this.current,
    required this.isActive,
    required this.confirmDraft,
  });

  final PokemonWorkspaceController? Function() current;
  final bool Function() isActive;
  final Future<PokemonDraftDecision?> Function() confirmDraft;
  bool changingView = false;
  bool choosingMedia = false;
  String? refusal;
  bool _disposed = false;

  bool _owns(PokemonWorkspaceController controller) =>
      !_disposed && isActive() && identical(current(), controller);

  Future<bool> chooseMenuPng({
    required String formId,
    required String role,
    required Future<String?> Function() picker,
    required bool Function() isCurrentSelection,
  }) async {
    final controller = current();
    final draft = controller?.selectedDraft;
    if (controller == null ||
        draft == null ||
        !_owns(controller) ||
        choosingMedia ||
        controller.operationActive ||
        controller.hasPendingChanges ||
        !isCurrentSelection()) {
      return false;
    }
    choosingMedia = true;
    try {
      final path = await picker();
      if (path == null ||
          !_owns(controller) ||
          !isCurrentSelection() ||
          !identical(controller.selectedDraft, draft) ||
          controller.operationActive ||
          controller.hasPendingChanges) {
        return false;
      }
      return await controller.importMenuPng(
            sourcePath: path,
            formId: formId,
            role: role,
          ) &&
          _owns(controller);
    } finally {
      choosingMedia = false;
    }
  }

  Future<bool> requestSpecies(String id) async {
    final controller = current();
    if (controller == null ||
        !_owns(controller) ||
        changingView ||
        controller.mutationActive) {
      return false;
    }
    changingView = true;
    try {
      if (controller.selectedId != id && controller.hasPendingChanges) {
        final selected = controller.selectedDraft;
        final decision = await confirmDraft();
        if (!_owns(controller) ||
            !identical(controller.selectedDraft, selected) ||
            controller.mutationActive) {
          return false;
        }
        if (decision == PokemonDraftDecision.save) {
          if (!await controller.saveActiveOwner()) return false;
        } else if (decision == PokemonDraftDecision.discard) {
          controller.discardSelectedSpecies();
        } else {
          return false;
        }
      }
      if (!_owns(controller)) return false;
      return await controller.selectSpecies(id) && _owns(controller);
    } finally {
      changingView = false;
    }
  }

  Future<bool> applyJsonImport(Future<bool> Function() confirmOverwrite) async {
    final controller = current();
    final preview = controller?.importPreview;
    if (controller == null ||
        preview == null ||
        !_owns(controller) ||
        changingView ||
        controller.operationActive) {
      return false;
    }
    changingView = true;
    try {
      if (preview.hasConflicts && !await confirmOverwrite()) return false;
      if (!_owns(controller) ||
          !identical(controller.importPreview, preview) ||
          controller.operationActive) {
        return false;
      }
      return await controller.applyJsonImport(
            confirmOverwrite: preview.hasConflicts,
          ) &&
          _owns(controller);
    } finally {
      changingView = false;
    }
  }

  Future<bool> applyExternal(
    PokemonExternalConflictPolicy policy,
    Future<bool> Function() confirmOverwrite,
  ) async {
    final controller = current();
    final preview = controller?.externalPreview;
    if (controller == null ||
        preview == null ||
        !_owns(controller) ||
        changingView ||
        controller.operationActive) {
      return false;
    }
    changingView = true;
    try {
      if (policy == PokemonExternalConflictPolicy.overwriteExisting &&
          preview.hasConflicts &&
          !await confirmOverwrite()) {
        return false;
      }
      if (!_owns(controller) ||
          !identical(controller.externalPreview, preview) ||
          controller.operationActive) {
        return false;
      }
      return await controller.applyExternal(policy) && _owns(controller);
    } finally {
      changingView = false;
    }
  }

  Future<bool> requestLeave() async {
    final controller = current();
    if (controller == null) return !_disposed && isActive();
    if (!_owns(controller) || changingView || controller.mutationActive) {
      return false;
    }
    changingView = true;
    try {
      if (controller.hasPendingChanges) {
        final decision = await confirmDraft();
        if (!_owns(controller) || controller.mutationActive) return false;
        if (decision == PokemonDraftDecision.save) {
          if (!await controller.saveActiveOwner()) return false;
        } else if (decision == PokemonDraftDecision.discard) {
          if (!controller.discardActiveOwner()) return false;
        } else {
          return false;
        }
      }
      return _owns(controller) &&
          !controller.mutationActive &&
          !controller.hasPendingChanges;
    } finally {
      changingView = false;
    }
  }

  Future<bool> requestView(PokemonWorkspaceView next) async {
    final controller = current();
    if (controller == null ||
        !_owns(controller) ||
        changingView ||
        controller.operationActive) {
      return false;
    }
    if (controller.view == next) return true;
    changingView = true;
    try {
      if (controller.hasPendingChanges) {
        final decision = await confirmDraft();
        if (!_owns(controller)) return false;
        if (decision == PokemonDraftDecision.save &&
            !await controller.saveActiveOwner()) {
          return false;
        }
        if (decision == PokemonDraftDecision.discard &&
            !controller.discardActiveOwner()) {
          return false;
        }
        if (decision == null || decision == PokemonDraftDecision.stay) {
          return false;
        }
      }
      if (!_owns(controller)) return false;
      return controller.setView(next);
    } finally {
      changingView = false;
    }
  }

  Future<bool> pickJson(Future<String?> Function() picker) async {
    final controller = current();
    refusal = null;
    if (controller == null ||
        !_owns(controller) ||
        controller.operationActive) {
      return false;
    }
    if (controller.hasPendingChanges) {
      refusal = 'Enregistrez ou annulez la fiche avant l’import.';
      return false;
    }
    final path = await picker();
    if (!_owns(controller) || path == null) return false;
    await controller.prepareJsonImport(path);
    return _owns(controller) && controller.importPreview != null;
  }

  void dispose() => _disposed = true;
}
