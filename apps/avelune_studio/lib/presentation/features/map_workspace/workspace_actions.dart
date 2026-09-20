import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../../features/events/application/event_workspace_controller.dart';
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
    this.events,
    this.dialogues,
    this.cinematics,
    this.publishedCinematicContext,
    required this.runtimeBuilder,
  });
  final MapWorkspaceController controller;
  final BuildContext Function() context;
  final bool Function() mounted;
  final VoidCallback changed;
  final ResourceNavigation? Function() resources;
  final NarrativeWorkspaceController? Function() narrative;
  final SceneWorkspaceController? Function()? scenes;
  final EventWorkspaceController? Function()? events;
  final DialogueWorkspaceController? Function()? dialogues;
  final CinematicWorkspaceController? Function()? cinematics;
  final bool Function()? publishedCinematicContext;
  final StudioRuntimeBuilder runtimeBuilder;
  bool testing = false;
  bool closing = false;
  bool get busy =>
      testing ||
      closing ||
      dialogues?.call()?.busy == true ||
      cinematics?.call()?.busy == true ||
      events?.call()?.busy == true ||
      scenes?.call()?.busy == true ||
      resources()?.busy == true ||
      narrative()?.busy == true;

  Future<bool> allowClose() async {
    if (!_flushDialogueEdit()) return false;
    if (!await _flushEventEdits()) return false;
    if (controller.saving || busy) return false;
    if (!controller.dirty &&
        resources()?.dirty != true &&
        narrative()?.dirty != true &&
        dialogues?.call()?.dirty != true &&
        cinematics?.call()?.dirty != true &&
        events?.call()?.dirty != true &&
        scenes?.call()?.dirty != true) {
      return true;
    }
    closing = true;
    changed();
    try {
      final choice = await confirmStudioClose(context());
      if (!mounted() || choice == null || choice == 'cancel') return false;
      if (choice == 'save') {
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
        return await controller.saveAll();
      }
      return choice == 'discard';
    } finally {
      closing = false;
      changed();
    }
  }

  Future<void> test() async {
    if (cinematics?.call()?.dirty == true) {
      cinematics!.call()!.error =
          'Enregistrez les cinématiques avant de tester le jeu.';
      changed();
      return;
    }
    if (!_flushDialogueEdit()) return;
    if (dialogues?.call()?.dirty == true) {
      dialogues!.call()!.error =
          'Enregistrez les dialogues avant de tester le jeu.';
      changed();
      return;
    }
    if (!await _flushEventEdits()) return;
    if (events?.call()?.dirty == true) {
      events!.call()!.error = 'Enregistrez les événements avant de tester.';
      changed();
      return;
    }
    if (publishedCinematicContext?.call() == true) {
      final owner = cinematics?.call();
      final mapId = owner?.active?.asset.mapId;
      if (mapId == null || controller.active?.current.id != mapId) {
        owner?.error =
            'Rejoignez la carte de la cinématique avec Voir sur la carte avant de lancer sa version publiée.';
        changed();
        return;
      }
      if (controller.dirty ||
          scenes?.call()?.dirty == true ||
          narrative()?.dirty == true) {
        owner?.error =
            'Des cartes, scènes ou interactions ont un brouillon. Enregistrez-les dans leur éditeur avant ce test ; aucun brouillon n’a été publié.';
        changed();
        return;
      }
    }
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
      final narrativeController = narrative();
      if (events?.call()?.dirty == true) {
        events!.call()!.error =
            'Les événements ont changé pendant la préparation. Enregistrez-les avant de tester.';
        return;
      }
      if (narrativeController != null &&
          (narrativeController.pendingStories.isNotEmpty ||
              narrativeController.pendingStoryDeletions.isNotEmpty ||
              narrativeController.pendingFacts.isNotEmpty)) {
        narrativeController.publicationError =
            'Les histoires ou états ont encore changé. Enregistrez-les avant de tester.';
        return;
      }
      if (cinematics?.call()?.dirty == true) {
        cinematics!.call()!.error =
            'La cinématique a changé pendant la préparation. Enregistrez-la avant de tester.';
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

  Future<bool> _flushEventEdits() async {
    final owner = events?.call();
    try {
      await owner?.flushEdits?.call();
      return mounted() &&
          !controller.isDisposed &&
          identical(owner, events?.call());
    } catch (failure) {
      if (mounted() && !controller.isDisposed) {
        final message =
            'L’édition d’événement en cours ne peut pas être validée : $failure';
        owner?.error = message;
        controller.error = message;
        changed();
      }
      return false;
    }
  }

  bool _flushDialogueEdit() {
    final owner = dialogues?.call(), previous = dialogues?.call()?.error;
    final cinema = cinematics?.call(),
        previousCinema = cinematics?.call()?.error;
    cinema?.transport.pause();
    if (cinema?.flushEdits?.call() == false) return false;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    return (owner?.error == null || owner?.error == previous) &&
        (cinema?.error == null || cinema?.error == previousCinema);
  }
}
