import '../../game_export/domain/studio_game_export_port.dart';
import '../../pokemon/application/pokemon_workspace_controller.dart';
import '../../resources/coordination/resource_navigation.dart';
import '../application/map_workspace_controller.dart';
import 'workspace_workflow.dart';

class WorkspacePublicationWorkflow {
  WorkspacePublicationWorkflow({
    required this.controller,
    required this.workflow,
    required this.isActive,
    required this.connectionBusy,
    required this.exporter,
    required this.resources,
    required this.pokemon,
  });

  final MapWorkspaceController controller;
  final WorkspaceWorkflow workflow;
  final bool Function() isActive, connectionBusy;
  final StudioGameExportPort? Function() exporter;
  final ResourceNavigation? Function() resources;
  final PokemonWorkspaceController? Function() pokemon;

  bool get _active => isActive() && !controller.isDisposed;
  bool get _exitBlocked =>
      !_active ||
      connectionBusy() ||
      controller.catalogBusy ||
      exporter()?.operationActive == true;
  bool get _preparationBlocked =>
      !_active ||
      resources()?.busy == true ||
      resources()?.packTransfer?.blocksClose == true ||
      controller.catalogBusy ||
      controller.pendingCatalogReceipt != null ||
      pokemon()?.operationActive == true;

  Future<bool> allowClose({
    required Future<bool> Function() leavePokemon,
    Future<bool> Function()? leaveLibrary,
  }) async {
    if (_exitBlocked || !await leavePokemon() || _exitBlocked) return false;
    if (leaveLibrary != null && !await leaveLibrary()) return false;
    if (_exitBlocked) return false;
    return workflow.allowClose();
  }

  Future<bool> prepareExport({
    required Future<bool> Function() confirmPokemonSave,
    required Future<bool> Function() confirmSave,
  }) async {
    if (_preparationBlocked) return false;
    final owner = pokemon();
    if (owner?.hasPendingChanges == true) {
      if (!await confirmPokemonSave() ||
          _preparationBlocked ||
          !identical(pokemon(), owner) ||
          !await owner!.saveActiveOwner() ||
          _preparationBlocked ||
          !identical(pokemon(), owner) ||
          owner.hasPendingChanges) {
        return false;
      }
    }
    if (!await workflow.flushEditors() || _preparationBlocked) return false;
    if (!workflow.hasPendingChanges) return true;
    if (!await confirmSave() || _preparationBlocked) return false;
    return workflow.saveForExport();
  }
}
