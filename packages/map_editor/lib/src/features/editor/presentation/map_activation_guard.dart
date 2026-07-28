import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../../border_map_editing/application/pending_border_save_guard.dart';
import '../../border_map_editing/presentation/pending_border_save_dialog.dart';
import '../application/map_activation_coordinator.dart';
import '../state/editor_notifier.dart';

typedef MapActivationCommand = Future<MapActivationOutcome> Function(
  DirtyMapActivationDecision? decision,
);

/// Runs the shared Save / Discard / Cancel interaction for map navigation.
///
/// The command is injectable so the decision workflow remains widget-testable
/// without constructing an entire editor session.
Future<MapActivationOutcome> requestGuardedMapActivation({
  required BuildContext context,
  required MapActivationCommand activate,
  required Future<ActiveMapSaveOutcome> Function() save,
}) async {
  final initialOutcome = await activate(null);
  if (initialOutcome != MapActivationOutcome.requiresDecision) {
    return initialOutcome;
  }
  if (!context.mounted) {
    await activate(DirtyMapActivationDecision.cancel);
    return MapActivationOutcome.cancelled;
  }

  final decision =
      await showPokeMapConfirmationDialog<DirtyMapActivationDecision>(
    context: context,
    title: 'Modifications non enregistrées',
    message: 'La carte active contient des modifications. '
        'Enregistrez-les avant d’ouvrir une autre carte, ignorez-les '
        'explicitement, ou restez ici.',
    actions: const <PokeMapDialogAction<DirtyMapActivationDecision>>[
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Rester ici',
        value: DirtyMapActivationDecision.cancel,
      ),
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Ignorer les modifications',
        value: DirtyMapActivationDecision.discard,
        variant: PokeMapButtonVariant.danger,
      ),
      PokeMapDialogAction<DirtyMapActivationDecision>(
        label: 'Enregistrer et ouvrir',
        value: DirtyMapActivationDecision.save,
        variant: PokeMapButtonVariant.success,
      ),
    ],
  );

  switch (decision ?? DirtyMapActivationDecision.cancel) {
    case DirtyMapActivationDecision.cancel:
      return activate(DirtyMapActivationDecision.cancel);
    case DirtyMapActivationDecision.discard:
      return activate(DirtyMapActivationDecision.discard);
    case DirtyMapActivationDecision.save:
      final saveOutcome = await save();
      if (saveOutcome == ActiveMapSaveOutcome.cancelled) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.cancelled;
      }
      if (saveOutcome != ActiveMapSaveOutcome.saved) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.saveBlocked;
      }
      if (!context.mounted) {
        await activate(DirtyMapActivationDecision.cancel);
        return MapActivationOutcome.cancelled;
      }
      // The save decision is also the acknowledgement token for this exact
      // handshake. The coordinator sees a clean document and does not save a
      // second time, while stale Discard answers remain strictly rejected.
      return activate(DirtyMapActivationDecision.save);
  }
}

/// Product-facing adapter used by every World Maps navigation surface.
Future<MapActivationOutcome> requestEditorMapActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String relativePath,
}) async {
  final outcome = await requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateMap(
      relativePath,
      dirtyDecision: decision,
    ),
    save: () => requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    ),
  );
  if (outcome == MapActivationOutcome.activated) {
    notifier.selectMapWorkspace();
  }
  return outcome;
}

Future<MapActivationOutcome> requestEditorConnectedMapActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required MapConnectionDirection direction,
}) async {
  final outcome = await requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateConnectedMap(
      direction,
      dirtyDecision: decision,
    ),
    save: () => requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    ),
  );
  if (outcome == MapActivationOutcome.activated) {
    notifier.selectMapWorkspace();
  }
  return outcome;
}

Future<MapActivationOutcome> requestEditorProjectActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String manifestPath,
}) {
  return requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.activateProject(
      manifestPath,
      dirtyDecision: decision,
    ),
    save: () => _saveEditorBeforeProjectReplacement(
      context: context,
      notifier: notifier,
    ),
  );
}

Future<MapActivationOutcome> requestEditorProjectCreation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String name,
  required String directory,
}) {
  return requestGuardedMapActivation(
    context: context,
    activate: (decision) => notifier.createAndActivateProject(
      name,
      directory,
      dirtyDecision: decision,
    ),
    save: () => _saveEditorBeforeProjectReplacement(
      context: context,
      notifier: notifier,
    ),
  );
}

Future<ActiveMapSaveOutcome> _saveEditorBeforeProjectReplacement({
  required BuildContext context,
  required EditorNotifier notifier,
}) async {
  final editor = notifier.currentState;
  if (editor.activeMap != null &&
      (editor.isDirty || notifier.hasPendingBorderPreview)) {
    final mapOutcome = await requestActiveMapSaveWithBorderPreviewGuard(
      context: context,
      notifier: notifier,
    );
    if (mapOutcome != ActiveMapSaveOutcome.saved) return mapOutcome;
  }
  if (notifier.currentState.isProjectDirty &&
      !await notifier.saveProjectManifest()) {
    return ActiveMapSaveOutcome.failed;
  }
  return ActiveMapSaveOutcome.saved;
}
