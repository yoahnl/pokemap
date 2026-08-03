import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../ui/design_system/design_system.dart';
import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../application/smart_tile_draft_persistence_coordinator.dart';
import '../application/smart_tile_draft_persistence_state.dart';
import '../application/smart_tile_atlas_image_loader.dart';
import '../application/smart_tile_source_asset_import_service.dart';
import '../application/smart_tile_source_image_picker.dart';
import 'smart_tiles_studio_panel.dart';

/// Riverpod orchestration boundary for the native Studio.
///
/// The panel emits semantic draft documents only. This workspace serializes
/// them through map_authoring and projects successful canonical snapshots back
/// into EditorState; it never writes a manifest or map directly.
class SmartTilesStudioWorkspace extends ConsumerStatefulWidget {
  const SmartTilesStudioWorkspace({super.key});

  @override
  ConsumerState<SmartTilesStudioWorkspace> createState() =>
      _SmartTilesStudioWorkspaceState();
}

class _SmartTilesStudioWorkspaceState
    extends ConsumerState<SmartTilesStudioWorkspace> {
  SmartTileDraftPersistenceCoordinator? _coordinator;
  Future<void>? _attachment;
  ProjectSmartTileAuthoringDraft? _pendingDraft;
  String? _pendingRootPath;
  ProjectSmartTileAuthoringDraft? _canonicalDraft;
  SmartTileDraftPersistenceState? _persistenceState;
  String? _attachedRoot;

  @override
  void dispose() {
    final coordinator = _coordinator;
    if (coordinator != null) unawaited(coordinator.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final manifest = ref.watch(editorProjectManifestProvider);
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    final launch = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          context: state.smartTilesStudioLaunchContext,
          activeMap: state.activeMap,
        ),
      ),
    );
    if (manifest == null) {
      return const Center(
        child: PokeMapEmptyState(
          key: Key('smart-tiles-studio-missing-project'),
          title: 'Aucun projet chargé',
          description:
              'Chargez un projet pour ouvrir la bibliothèque Smart Tiles.',
          icon: Icon(CupertinoIcons.square_grid_3x2),
        ),
      );
    }
    return SmartTilesStudioPanel(
      manifest: manifest,
      projectRootPath: projectRootPath,
      launchContext: launch.context,
      isCapturedMapAvailable:
          launch.context.isCapturedMapAvailable(launch.activeMap),
      canonicalDraft: _canonicalDraft,
      persistenceState: _persistenceState,
      onDraftChanged: projectRootPath == null
          ? null
          : (draft) => unawaited(
                _queueDraft(projectRootPath, draft),
              ),
      onDraftFlush: projectRootPath == null ? null : _flushDraft,
      onImportProjectImage: projectRootPath == null
          ? null
          : () => _importProjectImage(projectRootPath),
    );
  }

  Future<void> _queueDraft(
    String projectRootPath,
    ProjectSmartTileAuthoringDraft draft,
  ) async {
    _pendingDraft = draft;
    _pendingRootPath = projectRootPath;
    final coordinator = _coordinator;
    if (coordinator != null &&
        _attachedRoot == projectRootPath &&
        coordinator.draft.id == draft.id) {
      coordinator.updateDraft(draft);
      return;
    }
    final activeAttachment = _attachment;
    if (activeAttachment != null) {
      await activeAttachment;
      final latest = _pendingDraft;
      if (latest != null && _pendingRootPath == projectRootPath && mounted) {
        await _queueDraft(projectRootPath, latest);
      }
      return;
    }
    final completer = Completer<void>();
    _attachment = completer.future;
    try {
      await coordinator?.close();
      final latest = _pendingDraft;
      if (latest == null || _pendingRootPath != projectRootPath || !mounted) {
        return;
      }
      final gateway = CanonicalSmartTileDraftPersistenceGateway(
        mutations: ref.read(authoringMutationAdapterProvider),
        queries: ref.read(authoringQueryAdapterProvider),
      );
      final attached = await SmartTileDraftPersistenceCoordinator.attach(
        projectRootPath: projectRootPath,
        localDraft: latest,
        gateway: gateway,
        onStateChanged: _acceptPersistenceState,
        onCanonicalSnapshot: _acceptCanonicalSnapshot,
      );
      if (!mounted) {
        await attached.close();
        return;
      }
      _coordinator = attached;
      _attachedRoot = projectRootPath;
      if (smartTileDraftCanonicalFingerprint(attached.draft) !=
          smartTileDraftCanonicalFingerprint(latest)) {
        attached.updateDraft(latest);
      } else if (attached.state.phase == SmartTileDraftPersistencePhase.saved) {
        setState(() => _canonicalDraft = attached.draft);
      }
    } finally {
      _attachment = null;
      if (!completer.isCompleted) completer.complete();
    }
  }

  Future<void> _flushDraft() async {
    await _attachment;
    await _coordinator?.flush();
  }

  void _acceptPersistenceState(SmartTileDraftPersistenceState state) {
    if (!mounted) return;
    final draft = _coordinator?.draft;
    setState(() {
      _persistenceState = state;
      if (state.phase == SmartTileDraftPersistencePhase.saved &&
          draft != null) {
        _canonicalDraft = draft;
      }
    });
  }

  void _acceptCanonicalSnapshot(SmartTileDraftCanonicalSnapshot snapshot) {
    if (!mounted) return;
    ref.read(editorNotifierProvider.notifier).acceptCanonicalProjectManifest(
          snapshot.manifest,
          statusMessage: 'Brouillon Smart Tile sauvegardé.',
        );
  }

  Future<SmartTileSourceImportResult?> _importProjectImage(
    String projectRootPath,
  ) async {
    final picked = await const FilePickerSmartTileSourceImagePicker().pick();
    if (picked == null || !mounted) return null;
    await _flushDraft();
    await _coordinator?.close();
    _coordinator = null;
    _attachedRoot = null;
    final service = SmartTileSourceAssetImportService(
      gateway: CanonicalSmartTileSourceAssetGateway(
        mutations: ref.read(authoringMutationAdapterProvider),
        queries: ref.read(authoringQueryAdapterProvider),
      ),
      imageLoader: const FileSmartTileAtlasImageLoader(),
    );
    final result = await service.importImage(
      projectRootPath: projectRootPath,
      sourcePath: picked.path,
      displayName: picked.displayName,
    );
    if (!mounted) return null;
    ref.read(editorNotifierProvider.notifier).acceptCanonicalProjectManifest(
          result.manifest,
          statusMessage: 'Image Smart Tile importée.',
        );
    return result;
  }
}
