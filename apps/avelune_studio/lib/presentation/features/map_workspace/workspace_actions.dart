import 'package:flutter/material.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shared/widgets/dialogs/confirm_studio_close.dart';
import '../resources/resource_navigation.dart';

typedef StudioRuntimeBuilder =
    Widget Function(
      ProjectMapEntry entry,
      String revision,
      VoidCallback onClose,
    );

class WorkspaceActions {
  WorkspaceActions({
    required this.controller,
    required this.context,
    required this.mounted,
    required this.changed,
    required this.resources,
    required this.narrative,
    this.scenes,
    required this.runtimeBuilder,
  });
  final MapWorkspaceController controller;
  final BuildContext Function() context;
  final bool Function() mounted;
  final VoidCallback changed;
  final ResourceNavigation? Function() resources;
  final NarrativeWorkspaceController? Function() narrative;
  final SceneWorkspaceController? Function()? scenes;
  final StudioRuntimeBuilder runtimeBuilder;
  bool testing = false;
  bool closing = false;
  bool get busy =>
      testing ||
      closing ||
      scenes?.call()?.busy == true ||
      resources()?.busy == true ||
      narrative()?.busy == true;

  Future<bool> allowClose() async {
    if (controller.saving || busy) return false;
    if (!controller.dirty &&
        resources()?.dirty != true &&
        narrative()?.dirty != true &&
        scenes?.call()?.dirty != true) {
      return true;
    }
    closing = true;
    changed();
    try {
      final choice = await confirmStudioClose(context());
      if (!mounted() || choice == null || choice == 'cancel') return false;
      if (choice == 'save') {
        if (scenes?.call() case final sceneController?) {
          if (!await sceneController.saveAll()) return false;
        }
        if (resources() != null && !await resources()!.saveDrafts()) {
          return false;
        }
        if (narrative() != null && !await narrative()!.saveAll()) return false;
        return await controller.saveAll();
      }
      return choice == 'discard';
    } finally {
      closing = false;
      changed();
    }
  }

  Future<void> test() async {
    final document = controller.active;
    if (document == null || busy || controller.loading) return;
    final entry = controller.project!.maps.firstWhere(
      (e) => e.id == document.base.mapId,
    );
    testing = true;
    changed();
    try {
      final sceneController = scenes?.call();
      if (sceneController?.dirty == true && !await sceneController!.saveAll()) {
        return;
      }
      if (!await (narrative()?.save(document: document) ??
              controller.save(document)) ||
          !mounted()) {
        return;
      }
      if (!identical(controller.active, document) || controller.loading) return;
      if (document.dirty) {
        document.error =
            'La carte a encore changé. Enregistrez-la avant de tester.';
        return;
      }
      if (sceneController?.dirty == true) {
        const message =
            'Une scène a encore changé. Enregistrez-la avant de tester.';
        sceneController!.error = message;
        sceneController.active?.error = message;
        return;
      }
      await Navigator.of(context()).push<void>(
        MaterialPageRoute(
          builder: (routeContext) => runtimeBuilder(
            entry,
            document.base.revision,
            () => Navigator.of(routeContext).pop(),
          ),
        ),
      );
    } finally {
      testing = false;
      changed();
    }
  }
}
