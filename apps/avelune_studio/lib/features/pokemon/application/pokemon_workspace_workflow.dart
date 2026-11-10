import '../domain/pokemon_workspace_models.dart';
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
  String? refusal;
  bool _disposed = false;

  bool _owns(PokemonWorkspaceController controller) =>
      !_disposed && isActive() && identical(current(), controller);

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
