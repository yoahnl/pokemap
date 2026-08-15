import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../ui/design_system/design_system.dart';
import '../../border_map_editing/application/pending_border_save_guard.dart';
import '../../border_map_editing/presentation/pending_border_save_dialog.dart';
import '../application/map_activation_coordinator.dart';
import '../state/editor_notifier.dart';

typedef MapActivationCommand =
    Future<MapActivationOutcome> Function(DirtyMapActivationDecision? decision);

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
        message:
            'La carte active contient des modifications. '
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
    activate: (decision) =>
        notifier.activateMap(relativePath, dirtyDecision: decision),
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
    activate: (decision) =>
        notifier.activateConnectedMap(direction, dirtyDecision: decision),
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

/// Saves the active map before following a visual inter-map connection.
///
/// Unlike ordinary tree navigation, clicking a neighboring map is an explicit
/// "save and open" shortcut. Any cancelled, unavailable, conflicting or
/// failed save keeps the current map active.
Future<MapActivationOutcome> requestEditorConnectedMapSaveAndActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required MapConnectionDirection direction,
}) async {
  final saveOutcome = await requestActiveMapSaveWithBorderPreviewGuard(
    context: context,
    notifier: notifier,
  );
  if (saveOutcome == ActiveMapSaveOutcome.cancelled) {
    return MapActivationOutcome.cancelled;
  }
  if (saveOutcome != ActiveMapSaveOutcome.saved) {
    return MapActivationOutcome.saveBlocked;
  }
  if (!context.mounted) return MapActivationOutcome.cancelled;
  return requestEditorConnectedMapActivation(
    context: context,
    notifier: notifier,
    direction: direction,
  );
}

Future<MapActivationOutcome> requestEditorProjectActivation({
  required BuildContext context,
  required EditorNotifier notifier,
  required String manifestPath,
  EditorProjectRulesetBootstrapGateway rulesetBootstrap =
      const LocalEditorProjectRulesetBootstrapGateway(),
}) async {
  return requestGuardedMapActivation(
    context: context,
    activate: (decision) async {
      final initial = await notifier.activateProject(
        manifestPath,
        dirtyDecision: decision,
      );
      if (initial != MapActivationOutcome.failed || !context.mounted) {
        return initial;
      }
      final repaired = await requestProjectRulesetBootstrapRepair(
        context: context,
        manifestPath: manifestPath,
        gateway: rulesetBootstrap,
      );
      if (!repaired || !context.mounted) return initial;
      return notifier.activateProject(manifestPath, dirtyDecision: decision);
    },
    save: () => _saveEditorBeforeProjectReplacement(
      context: context,
      notifier: notifier,
    ),
  );
}

abstract interface class EditorProjectRulesetBootstrapGateway {
  Future<ProjectPokemonRulesetBootstrapPreview> inspect(String projectRoot);

  Future<void> repair({
    required String projectRoot,
    required String expectedRevision,
  });
}

final class LocalEditorProjectRulesetBootstrapGateway
    implements EditorProjectRulesetBootstrapGateway {
  const LocalEditorProjectRulesetBootstrapGateway();

  @override
  Future<ProjectPokemonRulesetBootstrapPreview> inspect(
    String projectRoot,
  ) async {
    final service = await _service(projectRoot);
    return service.inspectProject(projectRoot);
  }

  @override
  Future<void> repair({
    required String projectRoot,
    required String expectedRevision,
  }) async {
    final service = await _service(projectRoot);
    await service.repairProject(
      projectRootPath: projectRoot,
      expectedRevision: expectedRevision,
      confirmation: ProjectPokemonRulesetBootstrapService.confirmation,
    );
  }

  Future<ProjectPokemonRulesetBootstrapService> _service(
    String projectRoot,
  ) async {
    const reader = LocalProjectFileReader();
    return ProjectPokemonRulesetBootstrapService(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [projectRoot],
        fileReader: reader,
      ),
      fileReader: reader,
      writer: const LocalProjectManifestBootstrapWriter(),
    );
  }
}

Future<bool> requestProjectRulesetBootstrapRepair({
  required BuildContext context,
  required String manifestPath,
  required EditorProjectRulesetBootstrapGateway gateway,
}) async {
  final projectRoot = p.dirname(manifestPath);
  late final ProjectPokemonRulesetBootstrapPreview preview;
  try {
    preview = await gateway.inspect(projectRoot);
  } on Object {
    return false;
  }
  if (!preview.repairRequired || !context.mounted) return false;
  final confirmed = await showPokeMapBinaryConfirmationDialog(
    context,
    title: 'Configuration Pokémon manquante',
    message:
        'Le projet « ${preview.projectName} » ne déclare pas son profil '
        'de règles Pokémon. PokeMap peut ajouter le profil canonique '
        '« PokeMap Beta v1 » sans modifier le catalogue. Une sauvegarde de '
        'project.json sera conservée dans le projet.',
    secondaryLabel: 'Annuler',
    primaryLabel: 'Réparer et ouvrir',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await gateway.repair(
      projectRoot: projectRoot,
      expectedRevision: preview.currentRevision,
    );
    return true;
  } on Object {
    return false;
  }
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
