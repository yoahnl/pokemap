import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart';
import 'package:map_editor/src/features/border_map_editing/application/active_border_feature_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/border_studio/application/border_studio_draft_controller.dart';
import 'package:map_editor/src/features/border_studio/state/border_studio_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';
import 'package:riverpod/misc.dart' show Override;

/// Mounts migrated Notifiers in a real Riverpod container for unit tests.
///
/// Riverpod 3 Notifiers only acquire [Ref] and initialized state through their
/// provider. Centralizing the container teardown prevents tests from silently
/// exercising unmounted controller instances.
T _mountNotifier<T>({
  required Override override,
  required T Function(ProviderContainer container) read,
}) {
  final container = ProviderContainer(overrides: <Override>[override]);
  addTearDown(container.dispose);
  return read(container);
}

ActiveBorderFeatureController mountActiveBorderFeatureController() {
  return _mountNotifier(
    override: activeBorderFeatureControllerProvider.overrideWith(
      ActiveBorderFeatureController.new,
    ),
    read: (container) =>
        container.read(activeBorderFeatureControllerProvider.notifier),
  );
}

BorderPreviewController mountBorderPreviewController({
  BorderFeatureResolver? resolver,
  BorderPreviewMapApplier? applier,
}) {
  return _mountNotifier(
    override: borderPreviewControllerProvider.overrideWith(
      () => BorderPreviewController(resolver: resolver, applier: applier),
    ),
    read: (container) => container.read(borderPreviewControllerProvider.notifier),
  );
}

/// Creates a Notifier that the calling test will mount through its own
/// [ProviderContainer] override.
BorderPreviewController createBorderPreviewControllerForOverride({
  BorderFeatureResolver? resolver,
  BorderPreviewMapApplier? applier,
}) {
  return BorderPreviewController(resolver: resolver, applier: applier);
}

BorderStudioDraftController mountBorderStudioDraftController({
  ProjectManifest? manifest,
}) {
  return _mountNotifier(
    override: borderStudioDraftControllerProvider.overrideWith(
      () => BorderStudioDraftController(manifest: manifest),
    ),
    read: (container) =>
        container.read(borderStudioDraftControllerProvider.notifier),
  );
}

NarrativeEventMapBridgeController mountNarrativeEventMapBridgeController({
  required CreateNarrativeEventFromMapSourceUseCase useCase,
  String? projectRootPath,
  String Function()? requestIdFactory,
  NarrativeEventSpatialSourceLinkUseCase? sourceLinkUseCase,
  NarrativeEventExplicitSourceCreationUseCase? explicitSourceCreationUseCase,
}) {
  return _mountNotifier(
    override: narrativeEventMapBridgeControllerProvider.overrideWith(
      () => NarrativeEventMapBridgeController(
        useCase: useCase,
        projectRootPath: projectRootPath,
        requestIdFactory: requestIdFactory,
        sourceLinkUseCase: sourceLinkUseCase,
        explicitSourceCreationUseCase: explicitSourceCreationUseCase,
      ),
    ),
    read: (container) =>
        container.read(narrativeEventMapBridgeControllerProvider.notifier),
  );
}

NarrativeWorkspaceController mountNarrativeWorkspaceController() {
  return _mountNotifier(
    override: narrativeWorkspaceControllerProvider.overrideWith(
      NarrativeWorkspaceController.new,
    ),
    read: (container) =>
        container.read(narrativeWorkspaceControllerProvider.notifier),
  );
}

NarrativeStudioNavigationController mountNarrativeStudioNavigationController() {
  return _mountNotifier(
    override: narrativeStudioNavigationControllerProvider.overrideWith(
      NarrativeStudioNavigationController.new,
    ),
    read: (container) =>
        container.read(narrativeStudioNavigationControllerProvider.notifier),
  );
}
