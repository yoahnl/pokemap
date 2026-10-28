import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'studio_home_navigation.dart';
import '../../features/resources/application/working_catalog_controller.dart';
import '../../features/resources/data/local_working_catalog_adapter.dart';
import '../../platform/rendering/working_catalog_preview.dart';
import '../features/resources/working_catalog_workspace.dart';
import '../features/resources/project_catalog_partition_panel.dart';
import '../../features/project_session/data/local_project_catalog_partition_adapter.dart';

import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';

final workingCatalogControllerProvider = Provider.autoDispose
    .family<WorkingCatalogController, ProjectSession>((ref, session) {
      final controller = WorkingCatalogController(
        LocalWorkingCatalogAdapter(session),
        recoveryOperationIds: session.recoveryOperationIds,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

class StudioWorkspaceHost extends ConsumerWidget {
  const StudioWorkspaceHost({
    super.key,
    required this.session,
    required this.onClose,
    required this.registerExitGuard,
  });

  final ProjectSession session;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()?) registerExitGuard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (session.storage == ProjectSessionStorage.workingCatalog &&
        session.recoveryOperationIds.isEmpty) {
      return _StudioMapWorkspaceHost(
        session: session,
        onClose: onClose,
        registerExitGuard: registerExitGuard,
        publishHome: true,
      );
    }
    if (session.storage != ProjectSessionStorage.manifest) {
      return WorkingCatalogWorkspace(
        session: session,
        controller: ref.watch(workingCatalogControllerProvider(session)),
        home: StudioHomeScope.of(context),
        onClose: onClose,
        registerExitGuard: registerExitGuard,
        onRecovered: () async {
          final sessions = ref.read(projectSessionControllerProvider);
          await sessions.open(session.directoryPath);
          if (sessions.state.project?.sessionId == session.sessionId) {
            throw StateError('La nouvelle session ne peut pas être ouverte.');
          }
        },
        previewBuilder: (detail) =>
            WorkingCatalogPreview(session: session, detail: detail),
      );
    }
    final sessions = ref.read(projectSessionControllerProvider);
    return ProjectCatalogPartitionPanel(
      home: StudioHomeScope.of(context)!,
      registerExitGuard: registerExitGuard,
      partition: () => LocalProjectCatalogPartitionAdapter().partition(session),
      reopen: () async {
        await sessions.open(session.directoryPath);
        if (sessions.state.project?.storage !=
            ProjectSessionStorage.workingCatalog) {
          throw StateError('Rouvrez le projet pour terminer la conversion.');
        }
      },
      childBuilder: (guard) => _StudioMapWorkspaceHost(
        session: session,
        onClose: onClose,
        registerExitGuard: guard,
        publishHome: true,
      ),
    );
  }
}

class _StudioMapWorkspaceHost extends ConsumerWidget {
  const _StudioMapWorkspaceHost({
    required this.session,
    required this.onClose,
    required this.registerExitGuard,
    required this.publishHome,
  });

  final ProjectSession session;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()?) registerExitGuard;
  final bool publishHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(mapWorkspaceControllerProvider(session));
    final catalog = session.storage == ProjectSessionStorage.workingCatalog
        ? ref.watch(workingCatalogControllerProvider(session))
        : null;
    return MapWorkspaceScreen(
      key: ValueKey('map-workspace-${session.sessionId}'),
      home: publishHome ? StudioHomeScope.of(context) : null,
      controller: controller,
      resourceLibraryBuilder:
          session.storage == ProjectSessionStorage.workingCatalog
          ? (context, guard, onSaved, onOpenTools, onReplaceModelSource) =>
                WorkingCatalogWorkspace(
                  session: session,
                  controller: catalog!,
                  onClose: onClose,
                  registerExitGuard: guard,
                  embedded: true,
                  onSaved: onSaved,
                  onModelLightSaved: controller.acceptModelLight,
                  onOpenTools: onOpenTools,
                  onReplaceModelSource: onReplaceModelSource,
                  previewBuilder: (detail) =>
                      WorkingCatalogPreview(session: session, detail: detail),
                )
          : null,
      mapConnectionPort: ref.watch(mapConnectionPortProvider(session)),
      resourcePort: ref.watch(resourcePortProvider(session)),
      resourcePackPort: ref.watch(resourcePackPortProvider(session)),
      resourcePackLicensePicker: ref.watch(resourcePackLicensePickerProvider),
      resourcePackExportSink: ref.watch(resourcePackExportSinkProvider),
      resourcePackPicker: ref.watch(resourcePackPickerProvider),
      pokemonPort: ref.watch(pokemonPortProvider(session)),
      pokemonCommercePort: ref.watch(pokemonCommercePortProvider(session)),
      pokemonCombatPort: ref.watch(pokemonCombatPortProvider(session)),
      pokemonJsonPicker: ref.watch(pokemonJsonPickerProvider),
      pokemonPngPicker: ref.watch(pokemonPngPickerProvider),
      narrativePort: ref.watch(narrativePortProvider(session)),
      regionalMapPort: ref.watch(regionalMapPortProvider(session)),
      scenePort: ref.watch(scenePortProvider(session)),
      storyPort: ref.watch(storyPortProvider(session)),
      eventPort: ref.watch(eventPortProvider(session)),
      dialoguePort: ref.watch(dialoguePortProvider(session)),
      cinematicPort: ref.watch(cinematicPortProvider(session)),
      presentationPort: ref.watch(presentationPortProvider(session)),
      worldPort: ref.watch(worldPortProvider(session)),
      verificationPort: ref.watch(verificationPortProvider(session)),
      presentationMediaPicker: ref.watch(presentationMediaPickerProvider),
      audioPreview: ref.watch(projectAudioPreviewProvider(session)),
      imagePicker: ref.watch(resourceImagePickerProvider),
      gameExport: ref.watch(gameExportPortProvider(session)),
      gameExportPicker: ref.watch(gameExportPickerProvider),
      loadVisuals: ref.watch(workspaceVisualsLoaderProvider),
      runtimeBuilder: ref.watch(sessionRuntimeBuilderProvider(session)),
      visualTestBuilder: ref
          .watch(workspaceVisualTestBuilderProvider)
          ?.call(session, ref.watch(mapWorkspacePortProvider(session))),
      projectRuntimeBuilder: ref.watch(projectRuntimeBuilderProvider) == null
          ? null
          : (close) => ref.read(projectRuntimeBuilderProvider)!(session, close),
      onClose: onClose,
      registerExitGuard: registerExitGuard,
    );
  }
}
