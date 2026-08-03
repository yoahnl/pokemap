import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../border_map_editing/state/border_preview_providers.dart';
import '../../border_studio/state/border_studio_providers.dart';
import '../../editor/application/editor_unsaved_work_registry.dart';
import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_state.dart';
import '../domain/editor_exit_readiness.dart';
import '../domain/editor_native_updater.dart';
import '../domain/editor_update_catalog.dart';
import '../domain/editor_update_models.dart';
import '../infrastructure/github_release_update_catalog.dart';
import '../infrastructure/method_channel_editor_native_updater.dart';
import '../infrastructure/package_info_installed_version_reader.dart';
import '../infrastructure/method_channel_editor_update_link_opener.dart';
import 'editor_exit_readiness_resolver.dart';
import 'editor_update_controller.dart';

typedef EditorExitReadinessInputs = ({
  EditorState editorState,
  bool hasPendingBorderPreview,
  bool hasDirtyBorderStudio,
});

final editorUnsavedWorkRegistryProvider =
    Provider<EditorUnsavedWorkRegistry>((ref) {
  final registry = EditorUnsavedWorkRegistry();
  ref.onDispose(() => unawaited(registry.dispose()));
  return registry;
});

final editorUnsavedWorkChangesProvider =
    StreamProvider.autoDispose<void>((ref) {
  return ref.watch(editorUnsavedWorkRegistryProvider).changes;
});

final editorExitReadinessInputsProvider =
    Provider<EditorExitReadinessInputs>((ref) {
  return (
    editorState: ref.watch(editorNotifierProvider),
    hasPendingBorderPreview: ref.watch(
      borderPreviewControllerProvider.select(
        (preview) => preview.hasPendingPreview,
      ),
    ),
    hasDirtyBorderStudio: ref.watch(
      borderStudioDraftControllerProvider.select((draft) => draft.isDirty),
    ),
  );
});

final editorExitReadinessProvider = Provider<EditorExitReadiness>((ref) {
  ref.watch(editorUnsavedWorkChangesProvider);
  final inputs = ref.watch(editorExitReadinessInputsProvider);
  return resolveEditorExitReadiness(
    editorState: inputs.editorState,
    hasPendingBorderPreview: inputs.hasPendingBorderPreview,
    hasDirtyBorderStudio: inputs.hasDirtyBorderStudio,
    registry: ref.watch(editorUnsavedWorkRegistryProvider),
  );
});

final editorUpdateIndexUriProvider = Provider<Uri>((ref) {
  return Uri.parse(
    'https://github.com/yoahnl/pokemap/releases/download/'
    'pokemap-editor-update-stable/pokemap-update-index.json',
  );
});

final editorUpdateHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final editorUpdateCatalogProvider = Provider<EditorUpdateCatalog>((ref) {
  return GithubReleaseUpdateCatalog(
    client: ref.watch(editorUpdateHttpClientProvider),
    indexUri: ref.watch(editorUpdateIndexUriProvider),
  );
});

final editorInstalledVersionReaderProvider =
    Provider<EditorInstalledVersionReader>((ref) {
  return PackageInfoInstalledVersionReader();
});

final editorInstalledVersionProvider = FutureProvider((ref) {
  return ref.watch(editorInstalledVersionReaderProvider).read();
});

final editorNativeUpdaterProvider = Provider<EditorNativeUpdater>((ref) {
  return MethodChannelEditorNativeUpdater();
});

final editorUpdateLinkOpenerProvider = Provider((ref) {
  return const MethodChannelEditorUpdateLinkOpener();
});

final editorManualUpdateCheckRequestsProvider = StreamProvider<void>((ref) {
  return ref.watch(editorNativeUpdaterProvider).manualCheckRequests;
});

final editorUpdateTimerFactoryProvider =
    Provider<EditorUpdateTimerFactory>((ref) {
  return Timer.new;
});

final editorUpdateBackgroundFailureLoggerProvider =
    Provider<void Function(EditorUpdateFailure)>((ref) {
  return (failure) {
    debugPrint('Editor update check failed: ${failure.code}');
  };
});

final editorUpdateControllerProvider =
    Provider.autoDispose<EditorUpdateController>((ref) {
  final controller = EditorUpdateController(
    catalog: ref.watch(editorUpdateCatalogProvider),
    installedVersionReader: ref.watch(editorInstalledVersionReaderProvider),
    nativeUpdater: ref.watch(editorNativeUpdaterProvider),
    linkOpener: ref.watch(editorUpdateLinkOpenerProvider),
    readExitReadiness: () => ref.read(editorExitReadinessProvider),
    scheduleTimer: ref.watch(editorUpdateTimerFactoryProvider),
    onBackgroundFailure: ref.watch(
      editorUpdateBackgroundFailureLoggerProvider,
    ),
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final editorUpdateStateProvider =
    StreamProvider.autoDispose<EditorUpdateState>((ref) async* {
  final controller = ref.watch(editorUpdateControllerProvider);
  yield controller.state;
  yield* controller.stateChanges;
});
