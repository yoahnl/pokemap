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
import '../application/smart_tile_publication_service.dart';
import '../application/smart_tile_pattern_authoring_service.dart';
import '../application/smart_tile_source_asset_import_service.dart';
import '../application/smart_tile_source_image_picker.dart';
import '../application/smart_tile_tiled_wang_import_service.dart';
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
          mapIsDirty: state.isDirty,
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
          launch.context.isCapturedMapAvailable(launch.activeMap) &&
              !launch.mapIsDirty,
      capturedMap: launch.context.isCapturedMapAvailable(launch.activeMap)
          ? launch.activeMap
          : null,
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
      onPickTiledWangSource: projectRootPath == null
          ? null
          : const FilePickerSmartTileTiledWangSourcePicker().pick,
      onImportTiledWang: projectRootPath == null
          ? null
          : (source, selections) => _importTiledWang(
                projectRootPath,
                source,
                selections,
              ),
      publicationService: projectRootPath == null
          ? null
          : SmartTilePublicationService(
              gateway: CanonicalSmartTilePublicationGateway(
                mutations: ref.read(authoringMutationAdapterProvider),
                queries: ref.read(authoringQueryAdapterProvider),
              ),
            ),
      onPublicationApplied:
          projectRootPath == null ? null : _acceptPublicationResult,
      onAddPresetToCapturedMap: projectRootPath == null ||
              !launch.context.isCapturedMapAvailable(launch.activeMap) ||
              launch.mapIsDirty
          ? null
          : (preset) => ref
              .read(editorNotifierProvider.notifier)
              .createCanonicalSmartTileLayer(preset: preset),
      onUpsertPattern: projectRootPath == null
          ? null
          : (pattern) => _upsertPattern(projectRootPath, pattern),
    );
  }

  Future<void> _acceptPublicationResult(
    SmartTilePublicationResult result,
  ) async {
    final coordinator = _coordinator;
    if (coordinator != null) await coordinator.close();
    _coordinator = null;
    _attachedRoot = null;
    _pendingDraft = null;
    _pendingRootPath = null;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = result.map;
    final layerId = result.layerId;
    final mapRevision = result.mapRevision;
    if (map != null && layerId != null && mapRevision != null) {
      notifier.acceptCanonicalSmartTilePublication(
        manifest: result.manifest,
        map: map,
        mapRevision: mapRevision,
        layerId: layerId,
      );
    } else {
      notifier.acceptCanonicalProjectManifest(
        result.manifest,
        statusMessage: 'Smart Tile publié dans la bibliothèque.',
      );
    }
    if (!mounted) return;
    setState(() {
      _canonicalDraft = null;
      _persistenceState = null;
    });
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

  Future<void> _upsertPattern(
    String projectRootPath,
    ProjectSmartTilePattern pattern,
  ) async {
    await _flushDraft();
    await _coordinator?.close();
    _coordinator = null;
    _attachedRoot = null;
    _pendingDraft = null;
    _pendingRootPath = null;
    final service = SmartTilePatternAuthoringService(
      gateway: CanonicalSmartTilePatternAuthoringGateway(
        mutations: ref.read(authoringMutationAdapterProvider),
        queries: ref.read(authoringQueryAdapterProvider),
      ),
    );
    final result = await service.upsert(
      projectRootPath: projectRootPath,
      pattern: pattern,
    );
    if (!mounted) return;
    ref.read(editorNotifierProvider.notifier).acceptCanonicalProjectManifest(
          result.manifest,
          statusMessage: 'Motif Smart Tile enregistré.',
        );
    setState(() {
      _canonicalDraft = null;
      _persistenceState = null;
    });
  }

  Future<SmartTileTiledWangImportResult> _importTiledWang(
    String projectRootPath,
    SmartTileTiledWangSource source,
    List<TiledWangSetSelection> selections,
  ) async {
    await _flushDraft();
    await _coordinator?.close();
    _coordinator = null;
    _attachedRoot = null;
    _pendingDraft = null;
    _pendingRootPath = null;
    final gateway = CanonicalSmartTileSourceAssetGateway(
      mutations: ref.read(authoringMutationAdapterProvider),
      queries: ref.read(authoringQueryAdapterProvider),
    );
    final sourceImport = SmartTileSourceAssetImportService(
      gateway: gateway,
      imageLoader: const FileSmartTileAtlasImageLoader(),
    );
    final service = SmartTileTiledWangImportService(
      gateway: gateway,
      importImage: sourceImport.importImage,
    );
    final result = await service.import(
      projectRootPath: projectRootPath,
      source: source,
      selections: selections,
    );
    if (!mounted) return result;
    ref.read(editorNotifierProvider.notifier).acceptCanonicalProjectManifest(
          result.manifest,
          statusMessage: result.presetIds.length == 1
              ? 'Wang Set importé dans Smart Tiles Studio.'
              : '${result.presetIds.length} Wang Sets importés dans Smart Tiles Studio.',
        );
    setState(() {
      _canonicalDraft = null;
      _persistenceState = null;
    });
    return result;
  }
}
