import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring.dart'
    show MapAuthoringException, smartTileCanonicalLayerActionRequiredCode;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/content_studio_providers.dart';
import '../../../app/providers/core_providers.dart';
import '../../../app/providers/editor_workspace_providers.dart';
import '../../../app/providers/use_case_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/editor_receipt_presenter.dart';
import '../../../application/services/map_dependency_preflight_service.dart';
import '../../../application/services/map_viewport_navigation.dart';
import '../../../application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart';
import '../../../application/use_cases/environment_generator_apply_use_cases.dart';
import '../../../application/use_cases/environment_generator_clear_use_cases.dart';
import '../../../application/use_cases/environment_generator_regenerate_use_cases.dart';
import '../../../application/use_cases/environment_generator_use_cases.dart';
import '../../../application/use_cases/environment_mask_use_cases.dart';
import '../../../application/use_cases/layer_use_cases.dart';
import '../../../application/use_cases/map_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_area_settings_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_attachment_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_clear_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_generation_use_cases.dart';
import '../../../application/use_cases/tile_layer_environment_regenerate_use_cases.dart';
import '../../../application/models/trainer_field_update.dart';
import '../../../application/models/map_tool_preview.dart';
import '../../../application/models/narrative_event_spatial_link_journal_models.dart';
import '../../../application/models/narrative_event_spatial_source_creation_models.dart';
import '../../../application/models/narrative_authoring_transaction.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/services/editor_map_session_coordinator.dart';
import '../../../application/services/editor_map_mutation_coordinator.dart';
import '../../../application/services/editor_palette_session_service.dart';
import '../../../application/services/element_collision_profile_generator.dart';
import '../../../application/services/environment_mask_paint_target_resolver.dart';
import '../../../application/services/entity_editing_service.dart';
import '../../../application/services/gameplay_zone_editing_service.dart';
import '../../../application/services/map_connection_editing_service.dart';
import '../../../application/services/narrative_event_legacy_authoring_guard.dart';
import '../../../application/services/narrative_event_source_dependency_guard.dart';
import '../../../application/services/narrative_document_session.dart';
import '../../../application/services/placed_element_instance_indexer.dart';
import '../../../application/services/placed_element_editing_service.dart';
import '../../../application/services/project_map_id_policy.dart';
import '../../../application/services/project_map_manifest_integrity_policy.dart';
import '../../../application/services/trigger_editing_service.dart';
import '../../../application/services/warp_editing_service.dart';
import '../../personalization/application/personalization_studio_session_controller.dart';
import '../application/deferred_smart_tile_gesture.dart';
import '../application/editor_workspace_controller.dart';
import '../application/map_activation_coordinator.dart';
import '../application/map_canvas_object_hit_test.dart';
import '../application/map_canvas_object_move_planner.dart';
import '../application/map_editing_controller.dart';
import '../application/map_layer_grouping.dart';
import '../application/map_placed_element_rotation_planner.dart';
import '../application/map_selection_controller.dart';
import '../application/project_content_controller.dart';
import '../application/project_session_controller.dart';
import '../application/project_session_models.dart';
import '../application/world_map_tool_activation.dart';
import '../tools/editor_tool.dart';
import 'editor_state.dart';
import 'environment_generated_placement_add_element_provider.dart';
import 'environment_mask_brush_size_provider.dart';
import '../../border_map_editing/application/active_border_feature_controller.dart';
import '../../border_map_editing/application/border_feature_authoring_controller.dart';
import '../../border_map_editing/application/border_preview_transaction.dart';
import '../../border_map_editing/application/pending_border_save_guard.dart';
import '../../border_map_editing/state/border_map_editing_providers.dart';
import '../../border_map_editing/state/border_preview_providers.dart';
import '../../smart_tiles_studio/application/smart_tile_publication_service.dart';
import '../application/smart_tile_mutation_identity.dart';
import '../application/smart_tile_variant_density.dart';

part 'editor_notifier.g.dart';
part 'editor_notifier_layer_preset_change.dart';
part 'editor_notifier_map_connections.dart';
part 'editor_notifier_placed_element_placement.dart';
part 'editor_notifier_tileset_library.dart';

/// Valeur sentinelle pour les paramètres optionnels nullable dans [EditorNotifier].
const Object _trainerUnset = Object();
const String _lastOpenedProjectManifestKey = 'lastOpenedProjectManifestPath';
const String _editorSessionFileName = 'editor_session_state.json';
const String _eventBuilderConditionLockedMessage =
    'Cette condition contient une partie avancée préservée. '
    'Elle ne peut pas être éditée partiellement.';
const MethodChannel _macOsFileAccessChannel =
    MethodChannel('map_editor/file_access');

String _nextCanonicalSmartTileLayerId(MapData map, String presetId) {
  final normalized = presetId
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[_-]+|[_-]+$'), '');
  final stem = '${normalized.isEmpty ? 'smart_tile' : normalized}_layer';
  final existing = map.layers.map((layer) => layer.id).toSet();
  if (!existing.contains(stem)) return stem;
  var suffix = 2;
  while (existing.contains('${stem}_$suffix')) {
    suffix++;
  }
  return '${stem}_$suffix';
}

/// Jeton de la session d'édition courante.
///
/// Les identités de gestes Smart Tile se construisent sur un compteur remis à
/// zéro au démarrage. Le journal d'idempotence, lui, est persistant : sans ce
/// jeton, le premier geste d'une session rejoue la clé du premier geste de la
/// session précédente et se fait refuser.
final String _smartTileEditorMutationSession =
    newSmartTileMutationSessionToken();

String _smartTileEditorMutationIdentity({
  required String purpose,
  required Map<String, Object?> values,
}) =>
    smartTileMutationIdentity(
      purpose: purpose,
      sessionToken: _smartTileEditorMutationSession,
      values: values,
    );

typedef _NarrativeEventSourceCleanupInterlock = ({
  String projectRootPath,
  String mapPath,
  String mapId,
  String operationId,
  NarrativeEventSourceRef source,
  String sourceOwnerFingerprint,
});
typedef _MapDiskMutationLease = ({
  Object token,
  String? projectRootPath,
  ProjectManifest? project,
  MapData? activeMap,
  String? activeMapPath,
});
typedef _PendingMapActivation = ({
  String targetPath,
  Object? projectIdentity,
  MapData? sourceMapIdentity,
  String? sourcePath,
});
typedef _PendingProjectReplacement = ({
  String targetKey,
  Object? projectIdentity,
  MapData? sourceMapIdentity,
  String? sourcePath,
});
typedef _ProjectReplacementAuthorizationBaseline = ({
  String? projectRootPath,
  ProjectManifest? projectIdentity,
  MapData? sourceMapIdentity,
  String? sourcePath,
  bool isDirty,
  bool isProjectDirty,
  bool hasPendingPreview,
});
typedef _ProjectReplacementAuthorization = ({
  MapActivationOutcome outcome,
  _ProjectReplacementAuthorizationBaseline? baseline,
});
typedef _MapDocumentRevisionAttestation = ({
  String revision,
  MapData sourceDocument,
});

final class _PendingSmartTileGesture {
  _PendingSmartTileGesture({
    required this.mapId,
    required this.layerId,
    required this.materialId,
    required this.rollbackState,
    this.selection,
  });

  final String mapId;
  final String layerId;
  final String? materialId;

  /// Re-anchored on every adopted snapshot: once a canonical write lands, the
  /// state captured before it no longer describes anything on disk.
  EditorState rollbackState;

  /// Cleared when clicks with different selections merge: the canonical action
  /// then carries the plain cell list, which describes the same edit.
  SmartTileGestureSelection? selection;
  final Set<GridPos> cells = <GridPos>{};
}

final class _CanonicalSmartTileHistoryEntry {
  const _CanonicalSmartTileHistoryEntry({
    required this.projectRootPath,
    required this.receiptId,
    required this.mapId,
    required this.layerId,
    required this.redoActionId,
    required this.redoParameters,
    this.selectedPlacedElementInstanceId,
    this.undoStatusMessage = 'Geste Smart Tile annulé.',
    this.redoStatusMessage = 'Geste Smart Tile réappliqué.',
  });

  final String projectRootPath;
  final String receiptId;
  final String mapId;
  final String layerId;
  final String redoActionId;
  final Map<String, Object?> redoParameters;
  final String? selectedPlacedElementInstanceId;
  final String undoStatusMessage;
  final String redoStatusMessage;

  _CanonicalSmartTileHistoryEntry withReceipt(String nextReceiptId) =>
      _CanonicalSmartTileHistoryEntry(
        projectRootPath: projectRootPath,
        receiptId: nextReceiptId,
        mapId: mapId,
        layerId: layerId,
        redoActionId: redoActionId,
        redoParameters: redoParameters,
        selectedPlacedElementInstanceId: selectedPlacedElementInstanceId,
        undoStatusMessage: undoStatusMessage,
        redoStatusMessage: redoStatusMessage,
      );
}

BorderPreviewContext? _borderPreviewContext(EditorState state) {
  final projectRootPath = state.projectRootPath;
  final project = state.project;
  final map = state.activeMap;
  final activeMapPath = state.activeMapPath;
  if (projectRootPath == null ||
      projectRootPath.trim().isEmpty ||
      project == null ||
      map == null ||
      activeMapPath == null ||
      activeMapPath.trim().isEmpty) {
    return null;
  }
  return createEditorBorderPreviewContext(
    projectRootPath: p.normalize(projectRootPath),
    activeMapPath: p.normalize(activeMapPath),
    project: project,
    map: map,
  );
}

ProjectMapEntry? _findMapEntryForPath(
  ProjectManifest? project,
  ProjectWorkspace workspace,
  String targetPath,
) {
  if (project == null) return null;
  final normalizedTargetPath = p.normalize(targetPath);
  for (final entry in project.maps) {
    try {
      if (p.normalize(workspace.resolveMapPath(entry.relativePath)) ==
          normalizedTargetPath) {
        return entry;
      }
    } on Object {
      // An unrelated malformed legacy entry must not prevent a valid target
      // from being selected; the target itself still has to resolve safely.
    }
  }
  return null;
}

/// How many times a canonical Smart Tile mutation replans after `plan.stale`.
///
/// The Studio autosaves drafts on a debounce, so a background write can land
/// between reading the project revision and planning against it. A debounce can
/// fire more than once while the author is clicking, and a single replan left
/// them retrying the button by hand; a persistent conflict is still reported
/// rather than looped on forever.
const int _canonicalStalePlanRetryBudget = 4;

/// Shown when the open session no longer matches the document on disk.
///
/// The revision guard is doing its job here, so the only cure is to reload;
/// [editorErrorRequiresReload] lets the shell offer that as a one-click action.
const String editorReloadRequiredMessage =
    'Cette carte a changé en dehors de l’éditeur : la session ouverte n’est '
    'plus à jour. Rechargez la carte pour reprendre l’édition.';

/// Whether [message] describes a desynchronised session the author can repair
/// by reloading the active map.
bool editorErrorRequiresReload(String? message) =>
    message == editorReloadRequiredMessage;

/// Shown while a canonical Smart Tile commit is still in flight.
///
/// Each gesture is committed through the authoring API, and a second gesture
/// cannot be planned against a revision the first one is about to move.
const String editorSmartTileCommitInProgressMessage =
    'Modification précédente en cours d’enregistrement. Relâchez une seconde, '
    'puis reprenez : rien n’est perdu.';

const String editorSmartTileMaterialUnavailableMessage =
    'Le matériau choisi n’est pas disponible dans ce calque Smart Tile.';

/// Turns a canonical Smart Tile failure into something an author can act on,
/// instead of surfacing the raw authoring code.
String canonicalSmartTileFailureMessage(
  EditorAuthoringMutationFailure failure,
) {
  switch (failure.code) {
    case 'plan.stale':
      return 'Le projet a changé pendant l’ajout du calque. '
          'Réessayez : la nouvelle révision sera prise en compte.';
    case 'smart_tile.cell.material_not_allowed':
      return editorSmartTileMaterialUnavailableMessage;
    // `authoring.unexpected_failure` is the untyped fallback. In practice the
    // canonical write path only reaches it once the session and the stored
    // document have diverged, so point at the recovery instead of the code.
    case 'authoring.unexpected_failure':
    case 'smart_tile.cell.reload_required':
      return editorReloadRequiredMessage;
    default:
      return failure.message;
  }
}

@Riverpod(keepAlive: true, name: 'editorNotifierProvider')
class EditorNotifier extends _$EditorNotifier
    with
        _EditorNotifierMapConnections,
        _EditorNotifierPlacedElementPlacement,
        _EditorNotifierTilesetLibrary
    implements WorldMapToolActivationHost {
  static const ProjectMapIdPolicy _projectMapIdPolicy = ProjectMapIdPolicy();
  static const ProjectMapManifestIntegrityPolicy
      _projectMapManifestIntegrityPolicy = ProjectMapManifestIntegrityPolicy();

  EditorState get currentState => state;

  @override
  MapData? get worldMapToolActivationMap => state.activeMap;

  @override
  WorldMapToolActivationSessionSnapshot
      get worldMapToolActivationSessionSnapshot => (
            projectRootPath: state.projectRootPath,
            activeMapPath: state.activeMapPath,
            activeMapId: state.activeMap?.id,
            activeLayerId: state.activeLayerId,
            activeTool: state.activeTool,
          );

  MapData? _confirmedBulkPlacementLossBaseline;
  _NarrativeEventSourceCleanupInterlock? _narrativeEventSourceCleanupInterlock;
  ProjectManifest? _narrativeEventSourceCleanupProjectIdentity;
  MapData? _narrativeEventSourceCleanupBaselineIdentity;
  _MapDiskMutationLease? _mapDiskMutationLease;
  _PendingMapActivation? _pendingMapActivation;
  _PendingProjectReplacement? _pendingProjectReplacement;
  ProjectManifest? _mapManifestIntegrityProjectIdentity;
  String? _mapManifestIntegrityRootPath;
  List<String> _mapManifestIntegrityDiagnostics = const <String>[];
  Object? _narrativeEventSourceMapWriteLeaseToken;
  Object? _narrativeAuthoringLeaseToken;
  Object _projectSessionIdentity = Object();
  int _projectSessionRevision = 0;
  _NarrativeAuthoringSaveInterlock? _narrativeAuthoringSaveInterlock;
  NarrativeDocumentSession<ProjectManifest>? _narrativeDocumentSession;
  ProjectManifest? _lastNarrativeDocument;
  NarrativeDocumentSessionStatus? _lastNarrativeDocumentStatus;
  String? _narrativeDocumentProjectPath;
  PersonalizationStudioSessionController? _personalizationStudioSession;
  ProjectManifest? _lastPersonalizationStudioDocument;
  NarrativeDocumentSessionStatus? _lastPersonalizationStudioStatus;
  String? _personalizationStudioProjectPath;
  int _personalizationStudioOperationSequence = 0;
  String? _lastCanvasObjectSelectionMapId;
  GridPos? _lastCanvasObjectSelectionPosition;
  List<MapCanvasObjectTarget> _lastCanvasObjectSelectionHits =
      const <MapCanvasObjectTarget>[];
  MapCanvasObjectTarget? _lastCanvasObjectSelectionTarget;
  bool _suppressBorderSelectionReconciliation = false;
  bool _registeredNarrativeDocumentDisposal = false;
  _PendingSmartTileGesture? _pendingSmartTileGesture;
  DeferredSmartTileGesture? _deferredSmartTileGesture;
  bool _smartTileAutosaveInProgress = false;

  /// Whether the map is only dirty because of Smart Tile work we already own.
  ///
  /// That work is on its way to disk, so refusing the next click over it would
  /// make ordinary clicking impossible. Unrelated unsaved edits still block,
  /// since a canonical gesture plans against the stored version.
  bool get _canonicalSmartTileGestureOwnsDirtyMap =>
      _smartTileGestureCommitInProgress || _pendingSmartTileGesture != null;
  bool _smartTileGestureCommitInProgress = false;
  bool _smartTileCanonicalRecoveryRequired = false;
  int _smartTileGestureSequence = 0;
  final List<_CanonicalSmartTileHistoryEntry> _canonicalSmartTileUndoStack =
      <_CanonicalSmartTileHistoryEntry>[];
  final List<_CanonicalSmartTileHistoryEntry> _canonicalSmartTileRedoStack =
      <_CanonicalSmartTileHistoryEntry>[];
  // An attestation binds the revision to the exact object returned by a load.
  // Path-only lookups are used only after that object has become the active
  // document; snapshot activation additionally checks object identity.
  final Map<String, _MapDocumentRevisionAttestation>
      _mapDocumentRevisionAttestations =
      <String, _MapDocumentRevisionAttestation>{};

  int get projectSessionRevision => _projectSessionRevision;

  EditorWorkspaceController get _editorWorkspaceController =>
      ref.read(editorWorkspaceControllerProvider);
  MapEditingController get _mapEditingController => MapEditingController(
        mutationCoordinator: _editorMapMutationCoordinator,
      );
  MapSelectionController get _mapSelectionController =>
      const MapSelectionController();
  ProjectContentController get _projectContentController =>
      ref.read(projectContentControllerProvider);
  @override
  ProjectSessionController get _projectSessionController =>
      const ProjectSessionController();
  @override
  EditorMapSessionCoordinator get _editorMapSessionCoordinator =>
      ref.read(editorMapSessionCoordinatorProvider);
  EditorMapMutationCoordinator get _editorMapMutationCoordinator =>
      ref.read(editorMapMutationCoordinatorProvider);
  ProjectWorkspaceFactory get _projectWorkspaceFactory =>
      ref.read(projectWorkspaceFactoryProvider);
  @override
  ProjectWorkspace? get _projectWorkspace {
    final projectRootPath = state.projectSession.projectRootPath;
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }
    return _projectWorkspaceFactory.create(projectRootPath);
  }

  WarpEditingService get _warpEditingService =>
      ref.read(warpEditingServiceProvider);
  EntityEditingService get _entityEditingService =>
      ref.read(entityEditingServiceProvider);
  TriggerEditingService get _triggerEditingService =>
      ref.read(triggerEditingServiceProvider);
  GameplayZoneEditingService get _gameplayZoneEditingService =>
      ref.read(gameplayZoneEditingServiceProvider);
  @override
  MapConnectionEditingService get _mapConnectionEditingService =>
      ref.read(mapConnectionEditingServiceProvider);
  ElementCollisionProfileGenerator get _elementCollisionProfileGenerator =>
      ref.read(elementCollisionProfileGeneratorProvider);
  PlacedElementInstanceIndexer get _placedElementInstanceIndexer =>
      ref.read(placedElementInstanceIndexerProvider);
  NarrativeEventSourceDependencyGuard
      get _narrativeEventSourceDependencyGuard =>
          const NarrativeEventSourceDependencyGuard();
  BorderFeatureAuthoringController get _borderFeatureAuthoringController =>
      const BorderFeatureAuthoringController();

  @override
  EditorState build() {
    if (!_registeredNarrativeDocumentDisposal) {
      _registeredNarrativeDocumentDisposal = true;
      ref.onDispose(() {
        _disposeNarrativeDocumentSession();
        _disposePersonalizationStudioSession();
      });
    }
    final activeBorderFeatureController =
        ref.read(activeBorderFeatureControllerProvider.notifier);
    final borderPreviewController =
        ref.read(borderPreviewControllerProvider.notifier);
    listenSelf((_, next) {
      if (_suppressBorderSelectionReconciliation ||
          _hasCanvasObjectSelection(next)) {
        activeBorderFeatureController.clear();
      } else {
        activeBorderFeatureController.reconcile(
          map: next.activeMap,
          activeLayerId: next.activeLayerId,
        );
      }
      if (borderPreviewController.current.hasPendingPreview) {
        borderPreviewController.reconcileContext(_borderPreviewContext(next));
      }
    });
    return const EditorState();
  }

  bool _hasCanvasObjectSelection(EditorState value) {
    return value.selectedPlacedElementInstanceId != null ||
        value.selectedEntityId != null ||
        value.selectedMapEventId != null ||
        value.selectedGameplayZoneId != null ||
        value.selectedTriggerId != null ||
        value.selectedWarpId != null;
  }

  /// Returns the persisted manifest path of the most recently opened project.
  ///
  /// This is intentionally tiny and file-based (single JSON file in app support)
  /// to keep startup deterministic and avoid introducing extra dependencies.
  Future<String?> getLastOpenedProjectManifestPath() async {
    try {
      final file = await _sessionStateFile();
      if (!await file.exists()) {
        return null;
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final value = decoded[_lastOpenedProjectManifestKey];
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      // Startup memory should never crash the editor. Any corrupted or
      // unreadable state is treated as "no remembered project".
      return null;
    }
  }

  /// Attempts to load the last opened project (if any).
  ///
  /// Returns true only when a project was actually restored.
  Future<bool> restoreLastOpenedProjectIfAny() async {
    // Do not override an already loaded project.
    if (state.project != null) {
      return false;
    }
    // On macOS sandbox, a plain path is not enough after restart.
    // We first ask native code to resolve a security-scoped bookmark if any.
    final manifestPath = await _resolveLastProjectManifestFromMacOsBookmark() ??
        await getLastOpenedProjectManifestPath();
    if (manifestPath == null) {
      return false;
    }
    if (!await File(manifestPath).exists()) {
      // Clear stale memory so the app won't re-check a dead path forever.
      await _clearLastOpenedProjectMemory();
      return false;
    }
    if (!await _isManifestReadable(manifestPath)) {
      // macOS can report that the path exists but still deny read access
      // (Desktop/Documents permission not granted to the app process).
      //
      // In that case we do NOT call `loadProject`, otherwise we'd surface a
      // noisy PathAccessException on every launch.
      await _clearLastOpenedProjectMemory();
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Dernier projet détecté, mais accès refusé par macOS. Ouvrez-le manuellement pour réautoriser l’accès.',
      );
      return false;
    }
    // Auto-restore must be resilient:
    // - no noisy startup error toast if macOS denies access to remembered path
    //   (common when the path is on Desktop/Documents and the app lost grant).
    // - no endless retry loop on next launch if access is denied.
    await loadProject(
      manifestPath,
      silentOnError: true,
      rememberAsRecent: false,
    );
    final restored = state.project != null;
    if (!restored) {
      // Important anti-loop guard:
      // if we failed to restore (permissions / deleted file / parse error),
      // drop the remembered path so startup stays clean next launch.
      await _clearLastOpenedProjectMemory();
    }
    return restored;
  }

  Future<void> createProject(String name, String directory) async {
    final outcome = await createAndActivateProject(name, directory);
    if (outcome == MapActivationOutcome.requiresDecision) {
      await createAndActivateProject(
        name,
        directory,
        dirtyDecision: DirtyMapActivationDecision.cancel,
      );
    }
  }

  Future<MapActivationOutcome> createAndActivateProject(
    String name,
    String directory, {
    DirtyMapActivationDecision? dirtyDecision,
  }) async {
    final targetKey = 'create:${p.normalize(directory)}:$name';
    final authorization = await _authorizeProjectReplacement(
      targetKey,
      dirtyDecision: dirtyDecision,
    );
    if (authorization.outcome != MapActivationOutcome.activated) {
      return authorization.outcome;
    }
    if (!_projectReplacementAuthorizationIsCurrent(authorization)) {
      return MapActivationOutcome.unavailable;
    }

    debugPrint('EditorNotifier: createProject($name, $directory)');
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return MapActivationOutcome.busy;
    var authoringCandidatePrepared = false;
    try {
      final useCase = ref.read(createProjectUseCaseProvider);
      final manifest = await useCase.execute(name, directory);
      await _prepareEditorAuthoringCandidate(directory);
      authoringCandidatePrepared = true;
      if (!_canAdoptMapDiskMutation(lease)) {
        await _discardEditorAuthoringSessions(directory);
        return MapActivationOutcome.unavailable;
      }
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: directory,
          project: manifest,
        ),
        statusMessage: 'Projet "$name" créé avec succès',
      );
      _renewProjectSessionIdentity();
      _narrativeAuthoringSaveInterlock = null;
      await _activateEditorAuthoringSessions(directory);
      await initializeNarrativeDocumentSession();
      await _rememberLastOpenedProjectManifest(
        p.join(directory, 'project.json'),
      );
      return MapActivationOutcome.activated;
    } catch (e) {
      final visibleRoot = state.projectRootPath;
      if (authoringCandidatePrepared &&
          (visibleRoot == null ||
              p.normalize(visibleRoot) != p.normalize(directory))) {
        await _discardEditorAuthoringSessions(directory);
      }
      debugPrint('EditorNotifier: Error creating project: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de créer le projet : $e');
      return MapActivationOutcome.failed;
    } finally {
      _endMapDiskMutationLease(lease);
    }
  }

  Future<void> loadProject(
    String manifestPath, {
    bool silentOnError = false,
    bool rememberAsRecent = true,
    Object? mapWriteLeaseToken,
  }) async {
    final outcome = await activateProject(
      manifestPath,
      silentOnError: silentOnError,
      rememberAsRecent: rememberAsRecent,
      mapWriteLeaseToken: mapWriteLeaseToken,
    );
    if (mapWriteLeaseToken == null &&
        outcome == MapActivationOutcome.requiresDecision) {
      await activateProject(
        manifestPath,
        dirtyDecision: DirtyMapActivationDecision.cancel,
        silentOnError: silentOnError,
        rememberAsRecent: rememberAsRecent,
      );
    }
  }

  Future<MapActivationOutcome> activateProject(
    String manifestPath, {
    DirtyMapActivationDecision? dirtyDecision,
    bool silentOnError = false,
    bool rememberAsRecent = true,
    Object? mapWriteLeaseToken,
  }) async {
    final ownsLease = mapWriteLeaseToken == null;
    if (ownsLease) {
      final authorization = await _authorizeProjectReplacement(
        'open:${p.normalize(manifestPath)}',
        dirtyDecision: dirtyDecision,
      );
      if (authorization.outcome != MapActivationOutcome.activated) {
        return authorization.outcome;
      }
      if (!_projectReplacementAuthorizationIsCurrent(authorization)) {
        return MapActivationOutcome.unavailable;
      }
    } else {
      // Recovery workflows already own the serialized disk transaction and
      // deliberately replace the session with freshly persisted state.
      _pendingProjectReplacement = null;
      _pendingMapActivation = null;
    }

    final _MapDiskMutationLease? operationLease;
    if (ownsLease) {
      operationLease = _beginMapDiskMutationLease();
      if (operationLease == null) return MapActivationOutcome.busy;
    } else {
      if (_rejectMapDiskMutationLease(
        allowedLeaseToken: mapWriteLeaseToken,
      )) {
        return MapActivationOutcome.busy;
      }
      operationLease = _mapDiskMutationLease;
      if (operationLease == null) return MapActivationOutcome.unavailable;
    }
    final effectiveLeaseToken = operationLease.token;
    // Keep this trace for explicit user actions, but avoid noisy startup logs
    // when running a silent auto-restore attempt.
    if (!silentOnError) {
      debugPrint('EditorNotifier: loadProject($manifestPath)');
    }
    var didAdoptProject = false;
    final projectDir = p.dirname(manifestPath);
    try {
      await _prepareEditorAuthoringCandidate(projectDir);
      final useCase = ref.read(loadProjectUseCaseProvider);
      final manifest = await useCase.execute(manifestPath);
      if (!_canAdoptMapDiskMutation(operationLease)) {
        await _discardEditorAuthoringSessions(projectDir);
        return MapActivationOutcome.unavailable;
      }
      final nonCanonicalMapIds = _projectMapIdPolicy.nonCanonicalIds(
        manifest.maps.map((entry) => entry.id),
      );
      final manifestDiagnostics =
          _projectMapManifestIntegrityPolicy.diagnostics(
        _projectWorkspaceFactory.create(projectDir),
        manifest,
      );
      final projectStatusMessage =
          nonCanonicalMapIds.isEmpty && manifestDiagnostics.isEmpty
              ? 'Projet « ${manifest.name} » chargé'
              : 'Projet « ${manifest.name} » chargé en mode protégé : '
                  '${nonCanonicalMapIds.length} identifiant(s) legacy, '
                  '${manifestDiagnostics.length} problème(s) de manifeste map.';
      state = _projectSessionController.openProjectSession(
        current: state,
        session: ProjectSessionLoadResult(
          projectRootPath: projectDir,
          project: manifest,
        ),
        statusMessage: projectStatusMessage,
      );
      _renewProjectSessionIdentity();
      _narrativeAuthoringSaveInterlock = null;
      await _activateEditorAuthoringSessions(projectDir);
      await initializeNarrativeDocumentSession();
      didAdoptProject = true;
      _refreshMapDiskMutationLeaseBaseline(effectiveLeaseToken);
      _republishNarrativeEventSourceMapWriteLease(effectiveLeaseToken);
      if (rememberAsRecent) {
        await _rememberLastOpenedProjectManifest(manifestPath);
      }
      return MapActivationOutcome.activated;
    } catch (e) {
      final visibleRoot = state.projectRootPath;
      if (!didAdoptProject &&
          (visibleRoot == null ||
              p.normalize(visibleRoot) != p.normalize(projectDir))) {
        await _discardEditorAuthoringSessions(projectDir);
      }
      final canReportFailure = didAdoptProject
          ? _ownsMapDiskMutationLease(effectiveLeaseToken)
          : _canAdoptMapDiskMutation(operationLease);
      if (!canReportFailure) return MapActivationOutcome.unavailable;
      if (!silentOnError) {
        debugPrint('EditorNotifier: Error loading project: $e');
      }
      if (silentOnError) {
        // Silent mode is used by startup auto-restore.
        // We intentionally avoid surfacing an intrusive error toast at launch.
        state = state.copyWith(
          errorMessage: null,
          statusMessage:
              'Impossible de rouvrir automatiquement le dernier projet. Ouvrez-le manuellement une fois pour réautoriser l’accès.',
        );
      } else {
        state = state.copyWith(
            errorMessage: 'Impossible de charger le projet : $e');
      }
      return MapActivationOutcome.failed;
    } finally {
      _republishNarrativeEventSourceMapWriteLease(effectiveLeaseToken);
      if (ownsLease) _endMapDiskMutationLease(operationLease);
    }
  }

  Future<void> _activateEditorAuthoringSessions(String projectRootPath) async {
    try {
      await ref
          .read(editorAuthoringSessionLifecycleProvider)
          .activate(projectRootPath);
    } on Object catch (error, stackTrace) {
      debugPrint(
        'EditorNotifier: Authoring session cleanup failed after activation: '
        '$error\n$stackTrace',
      );
      state = state.copyWith(
        statusMessage:
            'Projet ouvert, mais certaines ressources de l’ancien projet '
            'n’ont pas pu être libérées proprement.',
      );
    }
  }

  Future<void> _prepareEditorAuthoringCandidate(String projectRootPath) {
    return ref
        .read(editorAuthoringSessionLifecycleProvider)
        .prepareCandidate(projectRootPath);
  }

  Future<void> _discardEditorAuthoringSessions(String projectRootPath) async {
    try {
      await ref
          .read(editorAuthoringSessionLifecycleProvider)
          .discard(projectRootPath);
    } on Object catch (error, stackTrace) {
      debugPrint(
        'EditorNotifier: Authoring candidate cleanup failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<bool> _isManifestReadable(String manifestPath) async {
    final file = File(manifestPath);
    try {
      // A tiny read is enough to validate real OS-level authorization.
      // We do not rely only on `exists()` because TCC can still block reads.
      await file.openRead(0, 1).first;
      return true;
    } on FileSystemException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<File> _sessionStateFile() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final editorDir = Directory(
      p.join(appSupportDir.path, 'rpg_map_editor'),
    );
    if (!await editorDir.exists()) {
      await editorDir.create(recursive: true);
    }
    return File(p.join(editorDir.path, _editorSessionFileName));
  }

  Future<void> _rememberLastOpenedProjectManifest(String manifestPath) async {
    try {
      final file = await _sessionStateFile();
      final payload = <String, dynamic>{
        _lastOpenedProjectManifestKey: manifestPath,
      };
      await file.writeAsString(jsonEncode(payload));
      // Also remember a security-scoped bookmark when running on macOS.
      // This is the durable way to re-open a user-selected folder under sandbox.
      await _rememberMacOsProjectBookmark(manifestPath);
    } catch (_) {
      // Non-critical: failing to persist recent project must not block editing.
    }
  }

  Future<void> _clearLastOpenedProjectMemory() async {
    try {
      final file = await _sessionStateFile();
      if (await file.exists()) {
        await file.delete();
      }
      await _clearMacOsProjectBookmark();
    } catch (_) {
      // Best effort cleanup only.
    }
  }

  Future<void> _rememberMacOsProjectBookmark(String manifestPath) async {
    if (kIsWeb || !Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel.invokeMethod<void>(
        'rememberProjectPath',
        <String, dynamic>{'manifestPath': manifestPath},
      );
    } catch (_) {
      // Best effort only: path JSON persistence remains as fallback.
    }
  }

  Future<String?> _resolveLastProjectManifestFromMacOsBookmark() async {
    if (kIsWeb || !Platform.isMacOS) {
      return null;
    }
    try {
      final path = await _macOsFileAccessChannel
          .invokeMethod<String>('resolveLastProjectManifestPath');
      if (path == null) {
        return null;
      }
      final trimmed = path.trim();
      return trimmed.isEmpty ? null : trimmed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearMacOsProjectBookmark() async {
    if (kIsWeb || !Platform.isMacOS) {
      return;
    }
    try {
      await _macOsFileAccessChannel
          .invokeMethod<void>('clearRememberedProjectPath');
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> updateProjectSettings({
    required String name,
    required ProjectSettings settings,
  }) async {
    debugPrint('EditorNotifier: updateProjectSettings()');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(updateProjectSettingsUseCaseProvider);
      final updated =
          await useCase.execute(fs, project, name: name, settings: settings);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Project settings saved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating project settings: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update project settings: $e',
      );
    }
  }

  /// Remplace le manifest projet en mémoire (aucune écriture disque).
  ///
  /// Lot Environment-16 : [statusMessage] optionnel pour feedback shell ;
  /// [errorMessage] est effacé sur succès pour éviter un message obsolète.
  void applyInMemoryProjectManifest(
    ProjectManifest manifest, {
    String? statusMessage,
  }) {
    state = statusMessage == null
        ? state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
          )
        : state.copyWith(
            project: manifest,
            isProjectDirty: true,
            errorMessage: null,
            statusMessage: statusMessage,
          );
  }

  /// Accepte un snapshot déjà appliqué par l’API Authoring canonique.
  ///
  /// Contrairement à [applyInMemoryProjectManifest], cette projection ne crée
  /// aucune dette de sauvegarde locale : les octets disque sont déjà ceux du
  /// reçu transactionnel.
  void acceptCanonicalProjectManifest(
    ProjectManifest manifest, {
    String? statusMessage,
  }) {
    state = state.copyWith(
      project: manifest,
      isProjectDirty: false,
      errorMessage: null,
      statusMessage: statusMessage ?? state.statusMessage,
    );
  }

  /// Réécrit les poids d'une règle du preset et republie celui-ci.
  ///
  /// La portée est volontairement globale : c'est le défaut du preset, pas une
  /// surcharge de calque. Passe par le même chemin canonique que la
  /// publication du Studio, puis adopte le manifeste relu.
  Future<void> applySmartTilePresetVariantWeights({
    required String presetId,
    required String ruleId,
    required Map<String, int> weights,
  }) async {
    final project = state.project;
    final projectRootPath = state.projectRootPath;
    if (project == null || projectRootPath == null) return;

    final preset = project.smartTileCatalog.presets
        .where((candidate) => candidate.id == presetId)
        .firstOrNull;
    if (preset == null) return;

    final updated = applySmartTileVariantWeights(
      preset: preset,
      ruleId: ruleId,
      weights: weights,
    );
    // Le cœur refuse une mutation qui n'écrit rien (smart_tile.no_change). Un
    // arrondi qui retombe sur les mêmes entiers est un geste normal, pas une
    // erreur : on s'arrête ici plutôt que de faire remonter un échec.
    if (updated == preset) {
      state = state.copyWith(
        statusMessage: 'Densité inchangée.',
        errorMessage: null,
      );
      return;
    }

    try {
      final gateway = CanonicalSmartTilePublicationGateway(
        mutations: ref.read(authoringMutationAdapterProvider),
        queries: ref.read(authoringQueryAdapterProvider),
      );
      final service = SmartTilePublicationService(gateway: gateway);
      await service.publishPreset(
        projectRootPath: projectRootPath,
        preset: updated,
      );
      final canonical = await gateway.load(projectRootPath: projectRootPath);
      acceptCanonicalProjectManifest(
        canonical.manifest,
        statusMessage: 'Densité des variantes mise à jour.',
      );
    } catch (error) {
      debugPrint('EditorNotifier: variant weights publish failed: $error');
      state = state.copyWith(
        errorMessage: 'Densité non enregistrée : $error',
      );
    }
  }

  /// Écrit la surcharge de densité portée par un seul calque.
  ///
  /// Même chemin canonique que les gestes de peinture Smart Tile : plan,
  /// application, puis adoption du cliché renvoyé pour que la carte à l'écran
  /// reparte de la révision écrite.
  Future<void> applySmartTileLayerVariantWeights({
    required String mapId,
    required String layerId,
    required Map<String, int> weights,
  }) async {
    final projectRootPath = state.projectRootPath;
    if (projectRootPath == null) return;

    // Même garde que la portée preset : le cœur refuse une carte projetée
    // identique (map.no_change), et retomber sur la même table par arrondi
    // n'est pas une erreur d'auteur.
    final activeMap = state.activeMap;
    final currentLayer =
        activeMap == null ? null : _findLayerById(activeMap, layerId);
    if (currentLayer is SmartTileLayer &&
        mapEquals(currentLayer.candidateWeights, weights)) {
      state = state.copyWith(
        statusMessage: 'Densité inchangée.',
        errorMessage: null,
      );
      return;
    }

    final parameters = <String, Object?>{
      'mapId': mapId,
      'layerId': layerId,
      'weights': weights,
    };

    try {
      final before =
          await ref.read(authoringQueryAdapterProvider).open(projectRootPath);
      final identity = smartTileDensityMutationIdentity(
        revision: before.snapshotRevision,
        parameters: parameters,
      );
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        projectRootPath,
        actionId: 'smart_tile.layer.set_candidate_weights',
        parameters: parameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      final applied = await mutations.apply(
        plan,
        operationId: '$identity-apply',
      );
      await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: mapId,
        layerId: layerId,
        statusMessage: 'Densité des variantes mise à jour sur ce calque.',
      );
    } on Object catch (error) {
      debugPrint('EditorNotifier: layer variant weights failed: $error');
      state = state.copyWith(
        errorMessage: canonicalSmartTileFailureMessage(
          EditorAuthoringMutationFailure.capture(error),
        ),
      );
    }
  }

  Future<void> applySmartTileLayerAnimationActivation({
    required String mapId,
    required String layerId,
    required SmartTileAnimationActivation activation,
  }) async {
    final projectRootPath = state.projectRootPath;
    if (projectRootPath == null) return;
    final activeMap = state.activeMap;
    final currentLayer =
        activeMap == null ? null : _findLayerById(activeMap, layerId);
    if (currentLayer is! SmartTileLayer ||
        currentLayer.animationActivation == activation) {
      return;
    }
    final activationValue = switch (activation) {
      SmartTileAnimationActivation.always => 'always',
      SmartTileAnimationActivation.onEnter => 'on_enter',
    };
    final parameters = <String, Object?>{
      'mapId': mapId,
      'layerId': layerId,
      'activation': activationValue,
    };

    try {
      final before =
          await ref.read(authoringQueryAdapterProvider).open(projectRootPath);
      final identity = _smartTileEditorMutationIdentity(
        purpose: 'smart-tile-layer-animation-activation',
        values: <String, Object?>{
          ...parameters,
          'snapshotRevision': before.snapshotRevision,
        },
      );
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        projectRootPath,
        actionId: 'smart_tile.layer.set_animation_activation',
        parameters: parameters,
        expectedRevision: before.snapshotRevision,
        idempotencyKey: identity,
        requestId: identity,
      );
      final applied = await mutations.apply(
        plan,
        operationId: '$identity-apply',
      );
      await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: mapId,
        layerId: layerId,
        statusMessage: activation == SmartTileAnimationActivation.onEnter
            ? 'Animation déclenchée au passage du joueur.'
            : 'Animation continue activée.',
      );
    } on Object catch (error) {
      debugPrint('EditorNotifier: Smart Tile animation activation failed: '
          '$error');
      state = state.copyWith(
        errorMessage: canonicalSmartTileFailureMessage(
          EditorAuthoringMutationFailure.capture(error),
        ),
      );
    }
  }

  /// Adopts the authoritative manifest + active map returned by one atomic
  /// Authoring transaction, then focuses the newly-created layer.
  ///
  /// This is intentionally an adoption path, not a local edit: disk already
  /// contains these exact bytes and neither project nor map is marked dirty.
  bool acceptCanonicalSmartTilePublication({
    required ProjectManifest manifest,
    required MapData map,
    required String mapRevision,
    required String layerId,
    String? statusMessage,
    bool preservePaintTool = false,
    bool preserveCanonicalGestureHistory = false,
  }) {
    final activeMap = state.activeMap;
    final activeMapPath = state.activeMapPath;
    if (activeMap == null ||
        activeMap.id != map.id ||
        activeMapPath == null ||
        !map.layers.any((layer) => layer.id == layerId)) {
      state = state.copyWith(
        errorMessage: 'Le snapshot Smart Tile publié ne correspond plus à '
            'la map active.',
      );
      return false;
    }
    final activeTool = state.activeTool;
    final activeBrush = state.activeBrush;
    final eraserFootprint = state.eraserFootprint;
    state = _projectSessionController.openMapDocument(
      current: state.copyWith(
        project: manifest,
        isProjectDirty: false,
      ),
      document: MapDocumentLoadResult(
        map: map,
        activeMapPath: activeMapPath,
        selectedTilesetEditorId:
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(map),
      ),
      statusMessage:
          statusMessage ?? 'Smart Tile publié dans la couche « $layerId ».',
    );
    state = state.copyWith(
      activeLayerId: layerId,
      activeTool: preservePaintTool ? activeTool : state.activeTool,
      activeBrush: preservePaintTool ? activeBrush : state.activeBrush,
      eraserFootprint:
          preservePaintTool ? eraserFootprint : state.eraserFootprint,
      isDirty: false,
      isProjectDirty: false,
      errorMessage: null,
    );
    _rememberMapDocumentRevision(
      activeMapPath,
      revision: mapRevision,
      sourceDocument: map,
    );
    if (!preserveCanonicalGestureHistory) {
      _clearCanonicalSmartTileHistory();
    }
    _coerceActiveToolIfIncompatibleWithLayer();
    return true;
  }

  PersonalizationStudioSessionState? get personalizationStudioSessionState =>
      _personalizationStudioSession?.state;

  Future<bool> initializePersonalizationStudioSession() async {
    final workspace = _projectWorkspace;
    final project = state.project;
    if (workspace == null || project == null) {
      _disposePersonalizationStudioSession();
      return false;
    }
    final projectPath = workspace.projectManifestPath;
    final existing = _personalizationStudioSession;
    if (existing != null && _personalizationStudioProjectPath == projectPath) {
      await existing.initialize();
      return existing.state.isInitialized && !existing.state.hasFailed;
    }
    if (state.isProjectDirty) {
      state = state.copyWith(
        errorMessage: 'Enregistrez les autres modifications du projet avant '
            'de démarrer une session de personnalisation.',
      );
      return false;
    }

    _disposePersonalizationStudioSession();
    final factory =
        ref.read(personalizationStudioSessionControllerFactoryProvider);
    final session = factory(
      projectPath: projectPath,
      initialDocument: project,
    );
    _personalizationStudioSession = session;
    _personalizationStudioProjectPath = projectPath;
    _lastPersonalizationStudioDocument = project;
    _lastPersonalizationStudioStatus = null;
    session.addListener(_onPersonalizationStudioSessionChanged);
    await session.initialize();
    return identical(_personalizationStudioSession, session) &&
        session.state.isInitialized &&
        !session.state.hasFailed;
  }

  Future<bool> applyPersonalizationStudioProfile(
    ProjectPresentationProfile profile, {
    String label = 'Modifier la personnalisation',
  }) async {
    if (!await initializePersonalizationStudioSession()) {
      return false;
    }
    final session = _personalizationStudioSession!;
    if (state.project != session.state.document) {
      state = state.copyWith(
        errorMessage: 'Le projet contient des modifications extérieures au '
            'Personalization Studio. Enregistrez-les avant de continuer.',
      );
      return false;
    }
    final sequence = ++_personalizationStudioOperationSequence;
    return session.applyProfile(
      profile,
      operationId: 'personalization_edit_$sequence',
      label: label,
    );
  }

  Future<bool> savePersonalizationStudio() async {
    if (!await initializePersonalizationStudioSession()) {
      return false;
    }
    final session = _personalizationStudioSession!;
    if (state.project != session.state.document) {
      state = state.copyWith(
        errorMessage: 'Sauvegarde bloquée : le projet contient des '
            'modifications extérieures au Personalization Studio.',
      );
      return false;
    }
    final sequence = ++_personalizationStudioOperationSequence;
    final saved = await session.save(
      operationId: 'personalization_save_$sequence',
    );
    return saved;
  }

  Future<bool> undoPersonalizationStudio() async {
    if (!await initializePersonalizationStudioSession()) {
      return false;
    }
    final session = _personalizationStudioSession!;
    if (state.project != session.state.document) {
      state = state.copyWith(
        errorMessage: 'Undo bloqué : le projet a changé en dehors du '
            'Personalization Studio.',
      );
      return false;
    }
    return session.undo();
  }

  Future<bool> redoPersonalizationStudio() async {
    if (!await initializePersonalizationStudioSession()) {
      return false;
    }
    final session = _personalizationStudioSession!;
    if (state.project != session.state.document) {
      state = state.copyWith(
        errorMessage: 'Redo bloqué : le projet a changé en dehors du '
            'Personalization Studio.',
      );
      return false;
    }
    return session.redo();
  }

  Future<void> setPersonalizationStudioAutosaveEnabled(bool enabled) async {
    if (!await initializePersonalizationStudioSession()) {
      return;
    }
    _personalizationStudioSession!.setAutosaveEnabled(enabled);
  }

  void _onPersonalizationStudioSessionChanged() {
    final session = _personalizationStudioSession;
    if (session == null) return;
    final sessionState = session.state;
    final previousDocument = _lastPersonalizationStudioDocument;
    final previousStatus = _lastPersonalizationStudioStatus;
    final visibleProject = state.project;

    _lastPersonalizationStudioDocument = sessionState.document;
    _lastPersonalizationStudioStatus = sessionState.status;
    if (visibleProject != previousDocument &&
        visibleProject != sessionState.document) {
      return;
    }

    final errorMessage = switch (sessionState.status) {
      NarrativeDocumentSessionStatus.failed =>
        'Brouillon de personnalisation conservé : '
            '${sessionState.message ?? sessionState.code ?? 'échec inconnu'}',
      NarrativeDocumentSessionStatus.conflicted =>
        'Conflit de personnalisation détecté : '
            '${sessionState.message ?? 'une version externe existe.'}',
      _ => null,
    };
    final statusMessage = switch (sessionState.status) {
      NarrativeDocumentSessionStatus.dirty =>
        sessionState.message ?? 'Modifications de personnalisation en attente.',
      NarrativeDocumentSessionStatus.recovered =>
        'Brouillon de personnalisation non enregistré récupéré.',
      NarrativeDocumentSessionStatus.saved
          when previousStatus == NarrativeDocumentSessionStatus.saving =>
        'Personnalisation enregistrée.',
      _ => state.statusMessage,
    };
    final didFinishSaving =
        sessionState.status == NarrativeDocumentSessionStatus.saved &&
            previousStatus == NarrativeDocumentSessionStatus.saving;
    state = state.copyWith(
      project: sessionState.document,
      isProjectDirty: sessionState.isDirty,
      isSaving: sessionState.isSaving,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
    if (didFinishSaving && _narrativeDocumentSession != null) {
      _disposeNarrativeDocumentSession();
      unawaited(initializeNarrativeDocumentSession());
    }
  }

  void _disposePersonalizationStudioSession() {
    final session = _personalizationStudioSession;
    if (session != null) {
      session.removeListener(_onPersonalizationStudioSessionChanged);
      session.dispose();
    }
    _personalizationStudioSession = null;
    _personalizationStudioProjectPath = null;
    _lastPersonalizationStudioDocument = null;
    _lastPersonalizationStudioStatus = null;
  }

  NarrativeDocumentSessionStatus? get narrativeDocumentStatus =>
      _narrativeDocumentSession?.state.status;

  bool get canUndoNarrativeDocument {
    final session = _narrativeDocumentSession;
    return session != null &&
        state.project == session.state.document &&
        session.state.canUndo;
  }

  bool get canRedoNarrativeDocument {
    final session = _narrativeDocumentSession;
    return session != null &&
        state.project == session.state.document &&
        session.state.canRedo;
  }

  bool get narrativeDocumentBlocksNavigation =>
      _narrativeDocumentSession?.state.blocksNavigation ?? false;

  bool get narrativeDocumentAutosaveEnabled =>
      _narrativeDocumentSession?.state.autosaveEnabled ?? false;

  NarrativeDocumentComparison<ProjectManifest>?
      get narrativeDocumentComparison => _narrativeDocumentSession?.comparison;

  /// Starts or restores the crash-safe Narrative Studio document session.
  ///
  /// This is eager when a project is opened and remains callable for tests or
  /// embedders that install [EditorState] directly.
  Future<bool> initializeNarrativeDocumentSession() async {
    final workspace = _projectWorkspace;
    final project = state.project;
    if (workspace == null || project == null) {
      _disposeNarrativeDocumentSession();
      return false;
    }
    final projectPath = workspace.projectManifestPath;
    final existing = _narrativeDocumentSession;
    if (existing != null && _narrativeDocumentProjectPath == projectPath) {
      await existing.initialize();
      return existing.state.isInitialized;
    }

    _disposeNarrativeDocumentSession();
    final factory = ref.read(narrativeProjectDocumentSessionFactoryProvider);
    final session = factory(
      projectPath: projectPath,
      initialDocument: project,
    );
    _narrativeDocumentSession = session;
    _narrativeDocumentProjectPath = projectPath;
    _lastNarrativeDocument = project;
    _lastNarrativeDocumentStatus = null;
    session.addListener(_onNarrativeDocumentSessionChanged);
    await session.initialize();
    return identical(_narrativeDocumentSession, session) &&
        session.state.isInitialized;
  }

  Future<bool> applyNarrativeDocumentEdit(
    ProjectManifest document, {
    required String operationId,
    required String label,
    String? statusMessage,
  }) async {
    if (!await initializeNarrativeDocumentSession()) {
      state = state.copyWith(
        errorMessage: 'La session documentaire narrative est indisponible.',
      );
      return false;
    }
    final session = _narrativeDocumentSession!;
    if (state.project != session.state.document) {
      state = state.copyWith(
        errorMessage: 'Le projet contient des modifications extérieures à la '
            'session Cinématiques. Enregistrez-les avant de continuer.',
      );
      return false;
    }
    final applied = await session.apply(
      operationId: operationId,
      label: label,
      document: document,
    );
    if (applied && statusMessage != null) {
      state = state.copyWith(statusMessage: statusMessage, errorMessage: null);
    }
    return applied;
  }

  Future<bool> undoNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.undo();
  }

  Future<bool> redoNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.redo();
  }

  Future<bool> saveNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.save(
      operationId: 'cinematics_save_${DateTime.now().microsecondsSinceEpoch}',
    );
  }

  Future<bool> keepLocalNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.keepLocal();
  }

  Future<bool> reloadExternalNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.reloadExternal();
  }

  Future<bool> discardNarrativeDocument() async {
    if (!await initializeNarrativeDocumentSession()) return false;
    return _narrativeDocumentSession!.discard();
  }

  Future<void> setNarrativeDocumentAutosaveEnabled(bool enabled) async {
    if (!await initializeNarrativeDocumentSession()) return;
    _narrativeDocumentSession!.setAutosaveEnabled(enabled);
  }

  void _onNarrativeDocumentSessionChanged() {
    final session = _narrativeDocumentSession;
    if (session == null) return;
    final sessionState = session.state;
    final previousDocument = _lastNarrativeDocument;
    final previousStatus = _lastNarrativeDocumentStatus;
    final visibleProject = state.project;

    _lastNarrativeDocument = sessionState.document;
    _lastNarrativeDocumentStatus = sessionState.status;
    if (visibleProject != previousDocument &&
        visibleProject != sessionState.document) {
      // A newer non-session edit is visible. Never replace it from an async
      // autosave/session callback.
      return;
    }

    final isSaved = sessionState.status == NarrativeDocumentSessionStatus.saved;
    final isSaving =
        sessionState.status == NarrativeDocumentSessionStatus.saving;
    final errorMessage = switch (sessionState.status) {
      NarrativeDocumentSessionStatus.failed =>
        'Modification narrative locale conservée : '
            '${sessionState.message ?? sessionState.code ?? 'échec inconnu'}',
      NarrativeDocumentSessionStatus.conflicted => 'Conflit narratif détecté : '
          '${sessionState.message ?? 'une version externe existe.'}',
      _ => null,
    };
    final statusMessage = switch (sessionState.status) {
      NarrativeDocumentSessionStatus.dirty =>
        sessionState.message ?? 'Modifications narratives en attente.',
      NarrativeDocumentSessionStatus.saving =>
        'Enregistrement des modifications narratives…',
      NarrativeDocumentSessionStatus.recovered =>
        'Modifications Cinématiques non enregistrées récupérées.',
      NarrativeDocumentSessionStatus.saved
          when previousStatus == NarrativeDocumentSessionStatus.saving =>
        'Modifications narratives enregistrées.',
      _ => state.statusMessage,
    };
    state = state.copyWith(
      project: sessionState.document,
      isProjectDirty: !isSaved,
      isSaving: isSaving,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }

  void _disposeNarrativeDocumentSession() {
    final session = _narrativeDocumentSession;
    if (session != null) {
      session.removeListener(_onNarrativeDocumentSessionChanged);
      session.dispose();
    }
    _narrativeDocumentSession = null;
    _narrativeDocumentProjectPath = null;
    _lastNarrativeDocument = null;
    _lastNarrativeDocumentStatus = null;
  }

  void reportNarrativeNavigationFailure(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void _renewProjectSessionIdentity() {
    _pendingMapActivation = null;
    _pendingProjectReplacement = null;
    _mapDocumentRevisionAttestations.clear();
    _projectSessionIdentity = Object();
    _projectSessionRevision += 1;
  }

  String _mapDocumentRevisionKey(String path) => p.normalize(p.absolute(path));

  String? _mapDocumentRevisionFor(
    String path, {
    MapData? sourceDocument,
  }) {
    final attestation =
        _mapDocumentRevisionAttestations[_mapDocumentRevisionKey(path)];
    if (attestation == null) return null;
    if (sourceDocument != null &&
        !identical(attestation.sourceDocument, sourceDocument)) {
      return null;
    }
    return attestation.revision;
  }

  @override
  void _rememberMapDocumentRevision(
    String path, {
    required String? revision,
    required MapData sourceDocument,
  }) {
    final key = _mapDocumentRevisionKey(path);
    if (revision == null) {
      _mapDocumentRevisionAttestations.remove(key);
      return;
    }
    _mapDocumentRevisionAttestations[key] = (
      revision: revision,
      sourceDocument: sourceDocument,
    );
  }

  void _forgetMapDocumentRevision(String path) {
    _mapDocumentRevisionAttestations.remove(_mapDocumentRevisionKey(path));
  }

  bool _hasPendingBorderPreview() {
    return ref.read(borderPreviewControllerProvider).hasPendingPreview;
  }

  bool get hasPendingBorderPreview => _hasPendingBorderPreview();

  bool _rejectPendingBorderPreviewMapLifecycleMutation() {
    if (!_hasPendingBorderPreview()) return false;
    state = state.copyWith(
      errorMessage: 'Appliquez, ignorez ou annulez l’aperçu de bordure avant '
          'de modifier la liste des cartes.',
    );
    return true;
  }

  bool _rejectPendingBorderPreviewDirectMapWrite() {
    if (!_hasPendingBorderPreview()) return false;
    state = state.copyWith(
      errorMessage: 'Appliquez, ignorez ou annulez l’aperçu de bordure avant '
          'toute autre écriture de la carte.',
    );
    return true;
  }

  bool _rejectNonCanonicalActiveMapAuthoring({
    bool revalidateManifest = false,
  }) {
    final map = state.activeMap;
    if (map == null) return false;
    final visualComposition = buildMapVisualCompositionPlan(map);
    if (visualComposition.requiresReadOnly) {
      final detail = visualComposition.diagnostics
          .map((diagnostic) => diagnostic.message)
          .join(' ');
      state = state.copyWith(
        errorMessage: 'Cette carte utilise une version de pile visuelle '
            'inconnue et reste en lecture seule. $detail',
      );
      return true;
    }
    try {
      _projectMapIdPolicy.requireValid(map.id);
      final workspace = _projectWorkspace;
      final project = state.project;
      if (workspace != null && project != null) {
        final rootPath = state.projectRootPath;
        final cacheMiss = !identical(
              _mapManifestIntegrityProjectIdentity,
              project,
            ) ||
            !_sameNullableNormalizedPath(
              _mapManifestIntegrityRootPath,
              rootPath,
            );
        if (revalidateManifest || cacheMiss) {
          _mapManifestIntegrityDiagnostics =
              _projectMapManifestIntegrityPolicy.diagnostics(
            workspace,
            project,
          );
          _mapManifestIntegrityProjectIdentity = project;
          _mapManifestIntegrityRootPath = rootPath;
        }
        if (_mapManifestIntegrityDiagnostics.isNotEmpty) {
          throw EditorValidationException(
            _mapManifestIntegrityDiagnostics.first,
          );
        }
      }
      return false;
    } on EditorValidationException {
      state = state.copyWith(
        errorMessage: 'La carte ou son manifeste est ouvert en lecture seule. '
            'Corrigez les identifiants et chemins de map avant de la modifier.',
      );
      return true;
    }
  }

  Future<_ProjectReplacementAuthorization> _authorizeProjectReplacement(
    String targetKey, {
    DirtyMapActivationDecision? dirtyDecision,
  }) async {
    if (_mapDiskMutationLease != null || state.isSaving) {
      return _projectReplacementAuthorization(
        dirtyDecision == null
            ? MapActivationOutcome.busy
            : MapActivationOutcome.unavailable,
      );
    }

    // Map navigation and project replacement share one authoring document.
    // Never allow two independent dialogs to own competing stale answers.
    if (_pendingMapActivation != null) {
      return _projectReplacementAuthorization(
        dirtyDecision == null
            ? MapActivationOutcome.busy
            : MapActivationOutcome.unavailable,
      );
    }

    final pending = _pendingProjectReplacement;
    if (dirtyDecision == null && pending != null) {
      return _projectReplacementAuthorization(MapActivationOutcome.busy);
    }
    if (dirtyDecision != null) {
      if (pending == null) {
        return _projectReplacementAuthorization(
          MapActivationOutcome.unavailable,
        );
      }
      final sourceMapMatches =
          identical(pending.sourceMapIdentity, state.activeMap);
      final savedDocumentMayAdvanceIdentity =
          dirtyDecision == DirtyMapActivationDecision.save &&
              !state.isDirty &&
              !state.isProjectDirty &&
              !_hasPendingBorderPreview();
      final matchesPending = pending.targetKey == targetKey &&
          identical(pending.projectIdentity, state.project) &&
          (sourceMapMatches || savedDocumentMayAdvanceIdentity) &&
          _sameNullableNormalizedPath(
            pending.sourcePath,
            state.activeMapPath,
          );
      if (!matchesPending) {
        _pendingProjectReplacement = null;
        return _projectReplacementAuthorization(
          MapActivationOutcome.unavailable,
        );
      }
      _pendingProjectReplacement = null;
      if (dirtyDecision == DirtyMapActivationDecision.cancel) {
        return _projectReplacementAuthorization(
          MapActivationOutcome.cancelled,
        );
      }
    }

    final plan = const MapActivationCoordinator().plan(
      isDirty: state.isDirty || state.isProjectDirty,
      hasPendingPreview: state.activeMap != null && _hasPendingBorderPreview(),
      decision: dirtyDecision,
    );
    switch (plan) {
      case MapActivationPlan.requiresDecision:
        _pendingProjectReplacement = (
          targetKey: targetKey,
          projectIdentity: state.project,
          sourceMapIdentity: state.activeMap,
          sourcePath: state.activeMapPath,
        );
        return _projectReplacementAuthorization(
          MapActivationOutcome.requiresDecision,
        );
      case MapActivationPlan.stay:
        return _projectReplacementAuthorization(
          MapActivationOutcome.cancelled,
        );
      case MapActivationPlan.saveThenActivate:
        if (state.activeMap != null &&
            (state.isDirty || _hasPendingBorderPreview())) {
          final saveOutcome = await saveActiveMap();
          if (saveOutcome != ActiveMapSaveOutcome.saved) {
            return _projectReplacementAuthorization(
              MapActivationOutcome.saveBlocked,
            );
          }
        }
        if (state.isProjectDirty && !await saveProjectManifest()) {
          return _projectReplacementAuthorization(
            MapActivationOutcome.saveBlocked,
          );
        }
        if (state.isDirty ||
            state.isProjectDirty ||
            (state.activeMap != null && _hasPendingBorderPreview())) {
          return _projectReplacementAuthorization(
            MapActivationOutcome.saveBlocked,
          );
        }
        return _projectReplacementAuthorization(
          MapActivationOutcome.activated,
        );
      case MapActivationPlan.activate:
        return _projectReplacementAuthorization(
          MapActivationOutcome.activated,
        );
    }
  }

  _ProjectReplacementAuthorization _projectReplacementAuthorization(
    MapActivationOutcome outcome,
  ) {
    if (outcome != MapActivationOutcome.activated) {
      return (outcome: outcome, baseline: null);
    }
    return (
      outcome: outcome,
      baseline: (
        projectRootPath: state.projectRootPath,
        projectIdentity: state.project,
        sourceMapIdentity: state.activeMap,
        sourcePath: state.activeMapPath,
        isDirty: state.isDirty,
        isProjectDirty: state.isProjectDirty,
        hasPendingPreview:
            state.activeMap != null && _hasPendingBorderPreview(),
      ),
    );
  }

  bool _projectReplacementAuthorizationIsCurrent(
    _ProjectReplacementAuthorization authorization,
  ) {
    final baseline = authorization.baseline;
    if (authorization.outcome != MapActivationOutcome.activated ||
        baseline == null) {
      return false;
    }
    return _sameNullableNormalizedPath(
          baseline.projectRootPath,
          state.projectRootPath,
        ) &&
        identical(baseline.projectIdentity, state.project) &&
        identical(baseline.sourceMapIdentity, state.activeMap) &&
        _sameNullableNormalizedPath(
          baseline.sourcePath,
          state.activeMapPath,
        ) &&
        baseline.isDirty == state.isDirty &&
        baseline.isProjectDirty == state.isProjectDirty &&
        baseline.hasPendingPreview ==
            (state.activeMap != null && _hasPendingBorderPreview());
  }

  /// Executes one validated Narrative Studio mutation through the shared
  /// atomic persistence boundary.
  ///
  /// Applicable changes become visible and dirty before the write starts.
  /// They are only announced as saved after persistence confirmation. A
  /// conflict or I/O failure deliberately keeps the visible local document.
  Future<NarrativeAuthoringTransactionResult?>
      executeNarrativeAuthoringMutation(
    NarrativeAssetMutationResult Function(ProjectManifest project)
        buildMutation, {
    required String operationId,
  }) async {
    final workspace = _projectWorkspace;
    final project = state.project;
    if (workspace == null || project == null) {
      state = state.copyWith(
        errorMessage: 'Aucun projet ouvert pour modifier le récit.',
      );
      return null;
    }
    final projectPath = workspace.projectManifestPath;
    final projectSessionIdentity = _projectSessionIdentity;

    late final NarrativeAssetMutationResult mutation;
    try {
      mutation = buildMutation(project);
    } on Object catch (error) {
      state = state.copyWith(
        errorMessage: 'Modification narrative invalide : $error',
      );
      return null;
    }

    final transaction = NarrativeAuthoringTransaction.fromMutation(
      projectPath: projectPath,
      operationId: operationId,
      mutation: mutation,
    );
    if (mutation.isApplicable &&
        (_narrativeAuthoringLeaseToken != null ||
            state.isSaving ||
            state.isProjectDirty)) {
      final result = NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.busy,
        code: state.isProjectDirty ? 'dirtyProject' : 'transactionBusy',
        message: state.isProjectDirty
            ? 'Enregistrez les modifications projet en attente avant cette '
                'opération narrative.'
            : 'Une autre sauvegarde est déjà en cours.',
        transaction: transaction,
      );
      state = state.copyWith(errorMessage: result.message);
      return result;
    }

    if (mutation is NarrativeAssetNoChange && state.isProjectDirty) {
      final interlock = _narrativeAuthoringSaveInterlock;
      final result = NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.rejected,
        code: 'unsavedLocalSnapshot',
        message: interlock == null
            ? 'Cette version existe seulement dans les modifications locales '
                'non enregistrées.'
            : 'Cette version existe seulement localement après l’échec '
                '${interlock.code}. Rechargez le projet avant de réessayer.',
        transaction: transaction,
      );
      // A semantic no-op against dirty memory is not a persistence success.
      // Keeping it explicit prevents a retry from claiming that disk is saved.
      state = state.copyWith(errorMessage: result.message);
      return result;
    }

    final executor = ref.read(executeNarrativeAuthoringTransactionProvider);
    if (!mutation.isApplicable) {
      final result = await executor.execute(
        projectPath: projectPath,
        operationId: operationId,
        mutation: mutation,
      );
      final rejectionMessage = switch (mutation) {
        NarrativeAssetRejected(:final referencePaths)
            when referencePaths.isNotEmpty =>
          '${result.message} ${referencePaths.join(', ')}',
        _ => result.message,
      };
      state = switch (result.status) {
        NarrativeAuthoringTransactionStatus.noChange => state.copyWith(
            statusMessage: 'Aucune modification narrative à enregistrer.',
            errorMessage: null,
          ),
        _ => state.copyWith(errorMessage: rejectionMessage),
      };
      return result;
    }

    final token = Object();
    _narrativeAuthoringLeaseToken = token;
    final after = mutation.after;
    state = state.copyWith(
      project: after,
      isProjectDirty: true,
      isSaving: true,
      statusMessage: 'Modification narrative locale en attente…',
      errorMessage: null,
    );

    try {
      final result = await executor.execute(
        projectPath: projectPath,
        operationId: operationId,
        mutation: mutation,
      );
      if (!_canAdoptNarrativeAuthoringResult(
        token: token,
        projectSessionIdentity: projectSessionIdentity,
        projectPath: projectPath,
      )) {
        // The write belongs to a project session that is no longer visible.
        // Returning null prevents the old workspace callback from announcing
        // success or selecting an asset id inside the newly opened project.
        return null;
      }
      final exactSnapshotStillVisible = identical(state.project, after);
      switch (result.status) {
        case NarrativeAuthoringTransactionStatus.committed:
          _narrativeAuthoringSaveInterlock = null;
          state = state.copyWith(
            isSaving: false,
            isProjectDirty:
                exactSnapshotStillVisible ? false : state.isProjectDirty,
            statusMessage: exactSnapshotStillVisible
                ? 'Modification narrative enregistrée.'
                : 'Snapshot narratif enregistré ; des modifications locales '
                    'plus récentes restent à enregistrer.',
            errorMessage: null,
          );
          if (_narrativeDocumentSession != null && exactSnapshotStillVisible) {
            _disposeNarrativeDocumentSession();
            await initializeNarrativeDocumentSession();
          }
        case NarrativeAuthoringTransactionStatus.persistenceFailed:
        case NarrativeAuthoringTransactionStatus.recoveryRequired:
          _narrativeAuthoringSaveInterlock = _NarrativeAuthoringSaveInterlock(
            projectPath: projectPath,
            code: result.code,
            message: result.message,
          );
          state = state.copyWith(
            isSaving: false,
            isProjectDirty: true,
            errorMessage:
                'Modification locale conservée, mais non enregistrée : '
                '${result.message}',
          );
        case NarrativeAuthoringTransactionStatus.rejected:
        case NarrativeAuthoringTransactionStatus.noChange:
        case NarrativeAuthoringTransactionStatus.busy:
          _narrativeAuthoringSaveInterlock = _NarrativeAuthoringSaveInterlock(
            projectPath: projectPath,
            code: result.code,
            message: result.message,
          );
          state = state.copyWith(
            isSaving: false,
            isProjectDirty: true,
            errorMessage: result.message,
          );
      }
      return result;
    } finally {
      if (identical(_narrativeAuthoringLeaseToken, token)) {
        final canStillAdopt = _canAdoptNarrativeAuthoringResult(
          token: token,
          projectSessionIdentity: projectSessionIdentity,
          projectPath: projectPath,
        );
        _narrativeAuthoringLeaseToken = null;
        if (canStillAdopt && state.isSaving) {
          state = state.copyWith(isSaving: false);
        }
      }
    }
  }

  bool _canAdoptNarrativeAuthoringResult({
    required Object token,
    required Object projectSessionIdentity,
    required String projectPath,
  }) {
    return identical(_narrativeAuthoringLeaseToken, token) &&
        identical(_projectSessionIdentity, projectSessionIdentity) &&
        _projectWorkspace?.projectManifestPath == projectPath;
  }

  /// Adopts a registry already committed by the dedicated Event V2 writer.
  ///
  /// This intentionally changes no map document, selection or history field.
  /// The merge is accepted only while the same project and previous registry
  /// are still active. Unrelated dirty manifest fields remain untouched.
  bool applyPersistedNarrativeEventRegistry({
    required String expectedProjectRootPath,
    required NarrativeEventRegistry? expectedPreviousRegistry,
    required NarrativeEventRegistry nextRegistry,
  }) {
    final project = state.project;
    final projectRootPath = state.projectRootPath;
    if (project == null || projectRootPath == null) {
      return false;
    }
    if (p.normalize(projectRootPath) != p.normalize(expectedProjectRootPath) ||
        project.eventRegistry != expectedPreviousRegistry) {
      return false;
    }
    state = state.copyWith(
      project: project.copyWith(eventRegistry: nextRegistry),
      statusMessage: 'Registre Event V2 synchronisé.',
      errorMessage: null,
    );
    return true;
  }

  ProjectManifest? ensureDefaultShadowProfiles() {
    final project = state.project;
    if (project == null) return null;
    final updated = ensureDefaultGroundStaticShadowProfilesForProject(project);
    if (updated == project) {
      return project;
    }
    applyInMemoryProjectManifest(
      updated,
      statusMessage: 'Profils Shadow par défaut ajoutés',
    );
    return updated;
  }

  Future<void> applyElementAutoShadowSuggestions() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to update element shadows.',
      );
      return;
    }
    try {
      final useCase = ApplyElementAutoShadowSuggestionsUseCase(
        ref.read(projectRepositoryProvider),
      );
      final result = await useCase.execute(fs, project);
      if (!result.hasChanges) {
        state = state.copyWith(
          statusMessage: 'Aucune ombre automatique à appliquer.',
          errorMessage: null,
        );
        return;
      }
      final appliedCount = result.appliedCount;
      final clearedCount = result.clearedCount;
      state = state.copyWith(
        project: result.project,
        statusMessage:
            'Ombres automatiques mises à jour : $appliedCount appliquée(s), $clearedCount retirée(s).',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to apply automatic element shadows: $e',
      );
    }
  }

  @override
  Future<bool> saveProjectManifest() async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) {
      state = state.copyWith(
        errorMessage: 'No project open to save.',
      );
      return false;
    }
    final personalizationSession = _personalizationStudioSession;
    if (personalizationSession != null &&
        personalizationSession.state.status !=
            NarrativeDocumentSessionStatus.saved) {
      if (project != personalizationSession.state.document) {
        state = state.copyWith(
          errorMessage: 'Sauvegarde bloquée : le projet contient à la fois '
              'un brouillon de personnalisation et des modifications '
              'extérieures. Résolvez ou annulez le brouillon avant de '
              'continuer.',
        );
        return false;
      }
      return savePersonalizationStudio();
    }
    final narrativeSession = _narrativeDocumentSession;
    if (narrativeSession != null &&
        narrativeSession.state.status != NarrativeDocumentSessionStatus.saved) {
      if (project != narrativeSession.state.document) {
        state = state.copyWith(
          errorMessage: 'Sauvegarde bloquée : le projet contient à la fois '
              'une session Cinématiques et des modifications extérieures. '
              'Résolvez ou annulez la session narrative avant de continuer.',
        );
        return false;
      }
      return saveNarrativeDocument();
    }
    final interlock = _narrativeAuthoringSaveInterlock;
    if (interlock != null && interlock.projectPath == fs.projectManifestPath) {
      state = state.copyWith(
        errorMessage: 'Sauvegarde projet bloquée après un échec narratif '
            '(${interlock.code}) afin de ne pas écraser une version externe. '
            'Rechargez le projet avant de réessayer. ${interlock.message}',
      );
      return false;
    }
    if (state.isSaving) {
      state = state.copyWith(
        errorMessage: 'Une sauvegarde est déjà en cours.',
      );
      return false;
    }
    debugPrint('EditorNotifier: saveProjectManifest()');
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref.read(projectRepositoryProvider).saveProject(
            project,
            fs.projectManifestPath,
          );
      final savedSnapshotIsStillCurrent = identical(state.project, project);
      state = state.copyWith(
        isSaving: false,
        isProjectDirty:
            savedSnapshotIsStillCurrent ? false : state.isProjectDirty,
        statusMessage: savedSnapshotIsStillCurrent
            ? 'Projet sauvegardé via le flux projet existant.'
            : 'Snapshot sauvegardé ; des modifications locales plus récentes '
                'restent à enregistrer.',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving project manifest: $e');
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save project: $e',
      );
      return false;
    }
  }

  @override
  Future<ActiveMapSaveOutcome> saveActiveMap({
    bool confirmBulkPlacementLoss = false,
    PendingBorderSaveDecision? pendingBorderDecision,
  }) async {
    final map = state.activeMap;
    final path = state.activeMapPath;
    if (map == null || path == null) {
      return ActiveMapSaveOutcome.unavailable;
    }
    if (_smartTileGestureCommitInProgress) {
      return ActiveMapSaveOutcome.unavailable;
    }
    if (_smartTileCanonicalRecoveryRequired) {
      state = state.copyWith(
        errorMessage: editorReloadRequiredMessage,
      );
      return ActiveMapSaveOutcome.unavailable;
    }
    // The canvas arbiter still owns this gesture. Saving here would persist a
    // partial document and clear the rollback checkpoint behind its back.
    if (state.mapStrokeStart != null) {
      return ActiveMapSaveOutcome.unavailable;
    }
    if (_rejectNonCanonicalActiveMapAuthoring(revalidateManifest: true)) {
      return ActiveMapSaveOutcome.unavailable;
    }
    if (_rejectNarrativeEventSourceCleanupMapMutation()) {
      return ActiveMapSaveOutcome.unavailable;
    }

    final activeBorderFeature = ref.read(activeBorderFeatureControllerProvider);
    final preparation = ref.read(pendingBorderSaveGuardProvider).prepare(
          currentMap: map,
          previewState: ref.read(borderPreviewControllerProvider),
          currentContext: _borderPreviewContext(state),
          activeLayerId: state.activeLayerId,
          activeFeatureLayerId: activeBorderFeature.activeLayerId,
          activeFeatureId: activeBorderFeature.activeFeatureId,
          decision: pendingBorderDecision,
        );
    switch (preparation) {
      case PendingBorderSaveDecisionRequired():
        return ActiveMapSaveOutcome.pendingBorderDecisionRequired;
      case PendingBorderSaveCancelled():
        return ActiveMapSaveOutcome.cancelled;
      case PendingBorderSaveConflict(:final message, :final cause):
        state = state.copyWith(
          isSaving: false,
          errorMessage: cause == null ? message : '$message $cause',
        );
        return ActiveMapSaveOutcome.conflict;
      case PendingBorderSaveReady():
        break;
    }
    final ready = preparation;
    final candidateMap = ready.candidateMap;

    final savedPlacementCount = state.savedMapSnapshot?.placedElements.length;
    final currentPlacementCount = candidateMap.placedElements.length;
    final confirmedBaseline = _confirmedBulkPlacementLossBaseline;
    final isBulkPlacementLossConfirmed = confirmBulkPlacementLoss ||
        (confirmedBaseline != null &&
            identical(confirmedBaseline, state.savedMapSnapshot));
    if (!isBulkPlacementLossConfirmed &&
        savedPlacementCount != null &&
        savedPlacementCount > 0 &&
        currentPlacementCount < savedPlacementCount &&
        (savedPlacementCount - currentPlacementCount) * 4 >
            savedPlacementCount) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Sauvegarde bloquée : les placements passeraient de '
            '$savedPlacementCount à $currentPlacementCount (perte supérieure '
            'à 25 %). Confirmez explicitement cette suppression massive avant '
            'd’enregistrer.',
      );
      return ActiveMapSaveOutcome.bulkPlacementLossBlocked;
    }

    debugPrint('EditorNotifier: saveActiveMap()');
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return ActiveMapSaveOutcome.unavailable;

    try {
      final useCase = ref.read(saveMapUseCaseProvider);
      final savedRevision = await useCase.executeRevisioned(
        candidateMap,
        path,
        expectedRevision: _mapDocumentRevisionFor(path),
        projectDialogueContext: state.project,
      );

      if (!_canAdoptMapDiskMutation(lease)) {
        return ActiveMapSaveOutcome.unavailable;
      }
      _rememberMapDocumentRevision(
        path,
        revision: savedRevision,
        sourceDocument: candidateMap,
      );
      final authoringReceipt =
          ref.read(authoringMutationAdapterProvider).lastAppliedReceipt;
      final receiptMessage = authoringReceipt == null
          ? null
          : ref
              .read(editorReceiptPresenterProvider)
              .receipt(authoringReceipt)
              .message;
      endMapStroke();
      switch (ready.postSaveAction) {
        case PendingBorderPostSaveAction.none:
          break;
        case PendingBorderPostSaveAction.commitAppliedPreview:
          _applyMapMutation(
            previousMap: map,
            updatedMap: candidateMap,
            preferredActiveLayerId: ready.transaction?.layerId,
            statusMessage: 'Bordure appliquée',
            mapWriteLeaseToken: lease.token,
          );
        case PendingBorderPostSaveAction.discardPreview:
          break;
      }
      state = _projectSessionController.markMapSaved(
        current: state,
        map: candidateMap,
        statusMessage:
            receiptMessage ?? 'Carte « ${candidateMap.id} » enregistrée',
      );
      if (ready.postSaveAction != PendingBorderPostSaveAction.none) {
        ref.read(borderPreviewControllerProvider.notifier).cancel();
      }
      _confirmedBulkPlacementLossBaseline = null;
      return ActiveMapSaveOutcome.saved;
    } on EditorConflictException catch (e) {
      debugPrint('EditorNotifier: Map revision conflict while saving: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state = _projectSessionController.markMapSaveFailed(
          current: state,
          errorMessage: 'La carte a été modifiée en dehors de cet éditeur, '
              'ou sa révision locale n’est pas attestée. Vos modifications '
              'locales sont conservées : il faut recharger la carte avant de '
              'réessayer. $e',
        );
      }
      return ActiveMapSaveOutcome.conflict;
    } on MapAuthoringException catch (e) {
      if (e.code != 'map.no_change') {
        debugPrint('EditorNotifier: Error saving map: $e');
        if (_canAdoptMapDiskMutation(lease)) {
          state = _projectSessionController.markMapSaveFailed(
            current: state,
            errorMessage: 'Impossible d’enregistrer la carte : $e',
          );
        }
        return ActiveMapSaveOutcome.failed;
      }
      // Repainting a cell with the value it already holds leaves the session
      // dirty while producing an identical document. The durable state already
      // matches, so this is a completed save with nothing to write, not a
      // failure the author could act on.
      if (!_canAdoptMapDiskMutation(lease)) {
        return ActiveMapSaveOutcome.unavailable;
      }
      endMapStroke();
      state = _projectSessionController.markMapSaved(
        current: state,
        map: candidateMap,
        statusMessage: 'Carte « ${candidateMap.id} » déjà à jour',
      );
      return ActiveMapSaveOutcome.saved;
    } catch (e) {
      debugPrint('EditorNotifier: Error saving map: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state = _projectSessionController.markMapSaveFailed(
          current: state,
          errorMessage: 'Impossible d’enregistrer la carte : $e',
        );
      }
      return ActiveMapSaveOutcome.failed;
    } finally {
      _endMapDiskMutationLease(lease);
    }
  }

  Future<void> createMap(String id, int width, int height,
      {String? groupId, MapRole role = MapRole.exterior}) async {
    debugPrint(
        'EditorNotifier: createMap($id, $width, $height) in group $groupId');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    if (_rejectPendingBorderPreviewMapLifecycleMutation()) return;
    if (state.isDirty) {
      state = state.copyWith(
        errorMessage: 'Enregistrez ou abandonnez les modifications de la '
            'carte active avant d’en créer une autre.',
      );
      return;
    }
    if (_rejectNarrativeEventSourceCleanupMapMutation()) return;
    if (project.maps.any((entry) => entry.id == id)) {
      state = state.copyWith(
        errorMessage: 'Une carte avec l’identifiant « $id » existe déjà.',
      );
      return;
    }
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return;

    try {
      final useCase = ref.read(createMapUseCaseProvider);
      await useCase.execute(fs, project, id, width, height,
          groupId: groupId, role: role);
      if (!_canAdoptMapDiskMutation(lease)) return;
      final relativePath = fs.getMapRelativePath(id);
      final persistedDocument =
          await ref.read(loadMapUseCaseProvider).executeDocument(
                fs,
                relativePath,
              );
      if (!_canAdoptMapDiskMutation(lease)) return;
      final map = persistedDocument.map;
      final mapPath = fs.resolveMapPath(relativePath);
      final updatedProject = project.copyWith(maps: [
        ...project.maps,
        ProjectMapEntry(
          id: id,
          name: id,
          relativePath: fs.getMapRelativePath(id),
          groupId: groupId,
          role: role,
        )
      ]);
      final preservedPaletteSession = _rememberActivePaletteContext(state);
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(
          project: updatedProject,
          paletteSession: preservedPaletteSession,
        ),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: mapPath,
          selectedTilesetEditorId: preservedSelectedTilesetEditorId != null &&
                  updatedProject.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : updatedProject.tilesets.isNotEmpty
                  ? updatedProject.tilesets.first.id
                  : null,
        ),
        statusMessage: 'Carte « $id » créée avec succès',
      );
      _clearCanonicalSmartTileHistory();
      state = _activatePaletteContext(state);
      _rememberMapDocumentRevision(
        mapPath,
        revision: persistedDocument.revision,
        sourceDocument: map,
      );
      _coerceActiveToolIfIncompatibleWithLayer();
    } catch (e) {
      debugPrint('EditorNotifier: Error creating map: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state =
            state.copyWith(errorMessage: 'Impossible de créer la carte : $e');
      }
    } finally {
      _endMapDiskMutationLease(lease);
    }
  }

  /// Backward-compatible low-level reload command.
  ///
  /// It intentionally preserves the historical same-map reload behavior used
  /// by recovery workflows. User-facing navigation must call [activateMap].
  Future<void> loadMap(
    String relativePath, {
    Object? mapWriteLeaseToken,
    bool forceReload = true,
  }) async {
    await activateMap(
      relativePath,
      mapWriteLeaseToken: mapWriteLeaseToken,
      forceReload: forceReload,
    );
  }

  /// Canonical gateway for replacing the active map document.
  ///
  /// It resolves the dirty-document decision before acquiring a disk lease,
  /// loads the target into a temporary value, and adopts it only after every
  /// validation succeeds. Internal recovery reloads retain their existing
  /// lease-token path and deliberately bypass the authoring prompt.
  Future<MapActivationOutcome> activateMap(
    String relativePath, {
    DirtyMapActivationDecision? dirtyDecision,
    Object? mapWriteLeaseToken,
    bool forceReload = false,
  }) async {
    final fs = _projectWorkspace;
    if (fs == null) return MapActivationOutcome.unavailable;
    final isInternalReload = mapWriteLeaseToken != null;
    final bypassAuthoringGuard = isInternalReload || forceReload;
    late final String targetPath;
    try {
      targetPath = fs.resolveMapPath(relativePath);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de charger la carte : $e',
      );
      return MapActivationOutcome.failed;
    }

    if (!bypassAuthoringGuard && _pendingProjectReplacement != null) {
      return dirtyDecision == null
          ? MapActivationOutcome.busy
          : MapActivationOutcome.unavailable;
    }

    if (!isInternalReload &&
        !forceReload &&
        dirtyDecision == null &&
        _sameNullableNormalizedPath(state.activeMapPath, targetPath)) {
      return MapActivationOutcome.activated;
    }

    if (bypassAuthoringGuard) {
      _pendingMapActivation = null;
      _pendingProjectReplacement = null;
    } else {
      if (_mapDiskMutationLease != null || state.isSaving) {
        return dirtyDecision == null
            ? MapActivationOutcome.busy
            : MapActivationOutcome.unavailable;
      }
      final pending = _pendingMapActivation;
      if (dirtyDecision == null && pending != null) {
        return MapActivationOutcome.busy;
      }
      if (dirtyDecision != null && pending == null) {
        // A Save / Discard / Cancel answer is valid only for the exact
        // decision request that produced it. Accepting an answer after Cancel
        // or a project switch would let stale UI replace the current document.
        return MapActivationOutcome.unavailable;
      }
      if (dirtyDecision != null && pending != null) {
        final sourceMapMatches =
            identical(pending.sourceMapIdentity, state.activeMap);
        final savedMapMayAdvanceIdentity =
            dirtyDecision == DirtyMapActivationDecision.save &&
                !state.isDirty &&
                !_hasPendingBorderPreview();
        final matchesPending =
            p.normalize(pending.targetPath) == p.normalize(targetPath) &&
                identical(pending.projectIdentity, state.project) &&
                (sourceMapMatches || savedMapMayAdvanceIdentity) &&
                _sameNullableNormalizedPath(
                  pending.sourcePath,
                  state.activeMapPath,
                );
        if (!matchesPending) {
          _pendingMapActivation = null;
          return MapActivationOutcome.unavailable;
        }
        _pendingMapActivation = null;
      }
      if (dirtyDecision == DirtyMapActivationDecision.cancel) {
        return MapActivationOutcome.cancelled;
      }
    }

    final targetEntry = isInternalReload
        ? null
        : _findMapEntryForPath(
            state.project,
            fs,
            targetPath,
          );
    if (!isInternalReload && targetEntry == null) {
      state = state.copyWith(
        errorMessage: 'Impossible de charger une carte absente du projet.',
      );
      return MapActivationOutcome.failed;
    }

    if (!bypassAuthoringGuard) {
      final activationPlan = const MapActivationCoordinator().plan(
        isDirty: state.isDirty,
        hasPendingPreview: _hasPendingBorderPreview(),
        decision: dirtyDecision,
      );
      switch (activationPlan) {
        case MapActivationPlan.requiresDecision:
          _pendingMapActivation = (
            targetPath: targetPath,
            projectIdentity: state.project,
            sourceMapIdentity: state.activeMap,
            sourcePath: state.activeMapPath,
          );
          return MapActivationOutcome.requiresDecision;
        case MapActivationPlan.stay:
          return MapActivationOutcome.cancelled;
        case MapActivationPlan.saveThenActivate:
          final saveOutcome = await saveActiveMap();
          if (saveOutcome != ActiveMapSaveOutcome.saved) {
            return MapActivationOutcome.saveBlocked;
          }
          if (state.isDirty || _hasPendingBorderPreview()) {
            return MapActivationOutcome.saveBlocked;
          }
          break;
        case MapActivationPlan.activate:
          break;
      }
    }

    final ownsLease = mapWriteLeaseToken == null;
    final _MapDiskMutationLease? operationLease;
    if (ownsLease) {
      operationLease = _beginMapDiskMutationLease(
        allowCleanupInterlock: true,
      );
      if (operationLease == null) {
        return (_mapDiskMutationLease != null || state.isSaving)
            ? MapActivationOutcome.busy
            : MapActivationOutcome.unavailable;
      }
    } else {
      if (_rejectMapDiskMutationLease(
        allowedLeaseToken: mapWriteLeaseToken,
      )) {
        return MapActivationOutcome.busy;
      }
      operationLease = _mapDiskMutationLease;
      if (operationLease == null) return MapActivationOutcome.unavailable;
    }
    final effectiveLeaseToken = operationLease.token;
    debugPrint('EditorNotifier: activateMap($relativePath)');

    var didAdoptMap = false;
    try {
      final useCase = ref.read(loadMapUseCaseProvider);
      final project = state.project;
      final loadedDocument = await useCase.executeDocument(
        fs,
        relativePath,
        refreshSnapshot: forceReload,
      );
      final loadedMap = loadedDocument.map;
      if (!_canAdoptMapDiskMutation(operationLease)) {
        return MapActivationOutcome.unavailable;
      }
      if (targetEntry != null && loadedMap.id != targetEntry.id) {
        throw EditorValidationException(
          'La carte « ${targetEntry.name} » déclare l’identifiant '
          '« ${loadedMap.id} » au lieu de « ${targetEntry.id} ».',
        );
      }
      // Loading is a byte-faithful document operation, not an implicit
      // migration/reindex command. Derived tile instances are synchronized by
      // explicit authoring mutations; persisted authored placements must never
      // disappear merely because their TileLayer contains zeroes.
      final map = loadedMap;
      final preservedPaletteSession = _rememberActivePaletteContext(state);
      final preservedSelectedTilesetEditorId = state.selectedTilesetEditorId;
      final nextSelectedTilesetEditorId =
          preservedSelectedTilesetEditorId != null &&
                  preservedSelectedTilesetEditorId.isNotEmpty &&
                  project != null &&
                  project.tilesets.any(
                    (tileset) => tileset.id == preservedSelectedTilesetEditorId,
                  )
              ? preservedSelectedTilesetEditorId
              : project != null && project.tilesets.isNotEmpty
                  ? project.tilesets.first.id
                  : null;
      state = _projectSessionController.openMapDocument(
        current: state.copyWith(paletteSession: preservedPaletteSession),
        document: MapDocumentLoadResult(
          map: map,
          activeMapPath: targetPath,
          selectedTilesetEditorId: nextSelectedTilesetEditorId,
        ),
        statusMessage: 'Carte « ${map.id} » chargée',
      );
      _clearCanonicalSmartTileHistory();
      state = _activatePaletteContext(state);
      final visualComposition = buildMapVisualCompositionPlan(map);
      if (visualComposition.requiresReadOnly) {
        state = state.copyWith(
          statusMessage: 'Carte « ${map.id} » ouverte en lecture seule',
          errorMessage: 'Version de pile visuelle non prise en charge. '
              '${visualComposition.diagnostics.map((diagnostic) => diagnostic.message).join(' ')}',
        );
      }
      _rememberMapDocumentRevision(
        targetPath,
        revision: loadedDocument.revision,
        sourceDocument: map,
      );
      didAdoptMap = true;
      _clearNarrativeEventSourceCleanupInterlockAfterReload(
        map: map,
        mapPath: targetPath,
      );
      _refreshMapDiskMutationLeaseBaseline(effectiveLeaseToken);
      _republishNarrativeEventSourceMapWriteLease(effectiveLeaseToken);
      _coerceActiveToolIfIncompatibleWithLayer();
      return MapActivationOutcome.activated;
    } catch (e) {
      final canReportFailure = didAdoptMap
          ? _ownsMapDiskMutationLease(effectiveLeaseToken)
          : _canAdoptMapDiskMutation(operationLease);
      if (!canReportFailure) return MapActivationOutcome.unavailable;
      debugPrint('EditorNotifier: Error loading map: $e');
      state =
          state.copyWith(errorMessage: 'Impossible de charger la carte : $e');
      return MapActivationOutcome.failed;
    } finally {
      _republishNarrativeEventSourceMapWriteLease(effectiveLeaseToken);
      if (ownsLease) _endMapDiskMutationLease(operationLease);
    }
  }

  /// Charge une "snapshot" de map par id SANS changer la map active.
  ///
  /// Pourquoi cette API existe:
  /// - certains workspaces (ex: Cutscene Studio) doivent proposer des
  ///   dropdowns guidés (PNJ/triggers) pour n'importe quelle map du projet;
  /// - on ne veut pas forcer un changement de contexte utilisateur vers cette
  ///   map juste pour lire ses entités;
  /// - on garde donc une lecture non destructive (read-only) côté éditeur.
  ///
  /// Contrat:
  /// - retourne la `activeMap` si c'est déjà la bonne map (inclut les edits
  ///   non sauvegardés en cours, utile pour une UX cohérente);
  /// - sinon lit le fichier map depuis le disque;
  /// - retourne `null` si le contexte projet est incomplet ou en cas d'erreur.
  @override
  Future<MapData?> loadMapSnapshotById(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return null;
    }
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) {
      return null;
    }

    final activeMap = state.activeMap;
    if (activeMap != null && activeMap.id == normalizedMapId) {
      return activeMap;
    }

    ProjectMapEntry? entry;
    for (final mapEntry in project.maps) {
      if (mapEntry.id == normalizedMapId) {
        entry = mapEntry;
        break;
      }
    }
    if (entry == null) {
      return null;
    }

    try {
      final mapPath = workspace.resolveMapPath(entry.relativePath);
      final document = await ref.read(loadMapUseCaseProvider).executeDocument(
            workspace,
            entry.relativePath,
          );
      _rememberMapDocumentRevision(
        mapPath,
        revision: document.revision,
        sourceDocument: document.map,
      );
      return document.map;
    } catch (error) {
      debugPrint(
        'EditorNotifier: loadMapSnapshotById($normalizedMapId) failed: $error',
      );
      return null;
    }
  }

  /// Activates the single snapshot already read by the Event V2 map bridge.
  ///
  /// The active map is never re-opened: this preserves its dirty bytes,
  /// selections, viewport and undo/redo history. A cross-map activation is
  /// refused while the current map is dirty and performs no additional read.
  bool activateNarrativeEventMapSnapshot(MapData map) {
    if (_rejectMapDiskMutationLease()) return false;
    final activeMap = state.activeMap;
    if (activeMap?.id == map.id) {
      selectMapWorkspace();
      return true;
    }
    if (state.isDirty) return false;
    final project = state.project;
    final workspace = _projectWorkspace;
    if (project == null || workspace == null) return false;
    ProjectMapEntry? entry;
    for (final candidate in project.maps) {
      if (candidate.id == map.id) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) return false;
    final mapPath = workspace.resolveMapPath(entry.relativePath);
    if (_mapDocumentRevisionFor(
          mapPath,
          sourceDocument: map,
        ) ==
        null) {
      _forgetMapDocumentRevision(mapPath);
    }
    state = _projectSessionController.openMapDocument(
      current: state,
      document: MapDocumentLoadResult(
        map: map,
        activeMapPath: mapPath,
        selectedTilesetEditorId:
            _editorMapSessionCoordinator.resolveSelectedTilesetIdForMap(map),
      ),
      statusMessage: 'Carte « ${map.name} » ouverte depuis l’Event',
    );
    _coerceActiveToolIfIncompatibleWithLayer();
    return true;
  }

  /// Applies the exact typed Event V2 focus without mutating map content.
  bool focusNarrativeEventMapSource(NarrativeEditorFocusTarget focus) {
    final map = state.activeMap;
    if (map == null || focus.mapId != map.id) return false;
    switch (focus.kind) {
      case NarrativeEditorFocusTargetKind.map:
        if (focus.ownerId != null || focus.bounds != null) return false;
        state = state.copyWith(
          selectedEntityId: null,
          selectedTriggerId: null,
          workspaceMode: EditorWorkspaceMode.map,
          errorMessage: null,
        );
        return true;
      case NarrativeEditorFocusTargetKind.entity:
        final ownerId = focus.ownerId;
        if (ownerId == null) return false;
        MapEntity? entity;
        for (final candidate in map.entities) {
          if (candidate.id == ownerId) {
            entity = candidate;
            break;
          }
        }
        if (entity == null ||
            focus.bounds != MapRect(pos: entity.pos, size: entity.size)) {
          return false;
        }
        state = state.copyWith(
          selectedEntityId: entity.id,
          selectedEntityKind: entity.kind,
          selectedTriggerId: null,
          workspaceMode: EditorWorkspaceMode.map,
          errorMessage: null,
        );
        return true;
      case NarrativeEditorFocusTargetKind.trigger:
        final ownerId = focus.ownerId;
        if (ownerId == null) return false;
        MapTrigger? trigger;
        for (final candidate in map.triggers) {
          if (candidate.id == ownerId) {
            trigger = candidate;
            break;
          }
        }
        if (trigger == null || focus.bounds != trigger.area) return false;
        state = state.copyWith(
          selectedEntityId: null,
          selectedTriggerId: trigger.id,
          workspaceMode: EditorWorkspaceMode.map,
          errorMessage: null,
        );
        return true;
    }
  }

  /// Builds a real Map Editor owner without mutating the open document.
  ///
  /// Persistence is intentionally owned by the V2-25 two-commit workflow. The
  /// returned before/after pair is therefore safe to cancel before any write.
  NarrativeEventCreatedSourceProposal? proposeNarrativeEventSourceAt({
    required GridPos position,
    required NarrativeEventPhysicalSourceKind kind,
  }) {
    // Event V2 eventually persists this proposal through a direct map writer.
    // Refuse it at proposal time so the UI cannot offer a confirmation that
    // would bypass legacy read-only or silently discard a Border preview.
    if (_rejectNonCanonicalActiveMapAuthoring() ||
        _rejectPendingBorderPreviewDirectMapWrite()) {
      return null;
    }
    final beforeMap = state.activeMap;
    if (beforeMap == null) return null;

    try {
      if (kind == NarrativeEventPhysicalSourceKind.zone1x1) {
        final result = _triggerEditingService.addTriggerAt(beforeMap, position);
        final trigger = result.createdTrigger;
        return NarrativeEventCreatedSourceProposal(
          physicalKind: kind,
          source: NarrativeEventSourceRef.triggerEnter(
            beforeMap.id,
            trigger.id,
          ),
          beforeMap: beforeMap,
          afterMap: result.updatedMap,
          bounds: trigger.area,
          ownerJson: _narrativeEventOwnerEnvelope(
            ownerKind: 'mapTrigger',
            mapId: beforeMap.id,
            sourceId: trigger.id,
            owner: trigger.toJson(),
          ),
        );
      }

      final entityKind = switch (kind) {
        NarrativeEventPhysicalSourceKind.npc => MapEntityKind.npc,
        NarrativeEventPhysicalSourceKind.sign => MapEntityKind.sign,
        NarrativeEventPhysicalSourceKind.item => MapEntityKind.item,
        NarrativeEventPhysicalSourceKind.invisible => MapEntityKind.custom,
        NarrativeEventPhysicalSourceKind.zone1x1 => throw StateError(
            'zone1x1 is handled as a MapTrigger before entity creation.',
          ),
      };
      final added = _entityEditingService.addEntityAt(
        beforeMap,
        position,
        kind: entityKind,
      );
      var afterMap = added.updatedMap;
      var entity = added.createdEntity;
      if (kind == NarrativeEventPhysicalSourceKind.invisible) {
        afterMap = _entityEditingService
            .updateEntity(
              afterMap,
              entityId: entity.id,
              blocksMovement: false,
            )
            .updatedMap;
        entity = afterMap.entities.firstWhere(
          (candidate) => candidate.id == entity.id,
        );
      }

      return NarrativeEventCreatedSourceProposal(
        physicalKind: kind,
        source: NarrativeEventSourceRef.entityInteract(
          beforeMap.id,
          entity.id,
        ),
        beforeMap: beforeMap,
        afterMap: afterMap,
        bounds: MapRect(pos: entity.pos, size: entity.size),
        ownerJson: _narrativeEventOwnerEnvelope(
          ownerKind: 'mapEntity',
          mapId: beforeMap.id,
          sourceId: entity.id,
          owner: entity.toJson(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Synchronizes a proposal already persisted by the V2-25 workflow.
  ///
  /// Identity comparison is the narrow CAS: if any map mutation or document
  /// switch replaced the proposal baseline, the newer in-memory map wins.
  /// This method performs no file or registry write.
  bool adoptPersistedNarrativeEventSourceProposal(
    NarrativeEventCreatedSourceProposal proposal, {
    Object? mapWriteLeaseToken,
  }) {
    if (_rejectMapDiskMutationLease(
      allowedLeaseToken: mapWriteLeaseToken,
    )) {
      return false;
    }
    if (!identical(state.activeMap, proposal.beforeMap) ||
        state.mapStrokeStart != null ||
        proposal.beforeMap.id != proposal.afterMap.id) {
      return false;
    }

    String? selectedEntityId;
    String? selectedTriggerId;
    MapEntityKind? selectedEntityKind;
    final isSpatialOwner = proposal.source.when(
      entityInteract: (mapId, entityId) {
        if (mapId != proposal.afterMap.id) return false;
        MapEntity? owner;
        for (final candidate in proposal.afterMap.entities) {
          if (candidate.id == entityId) {
            owner = candidate;
            break;
          }
        }
        if (owner == null) return false;
        selectedEntityId = owner.id;
        selectedEntityKind = owner.kind;
        return true;
      },
      triggerEnter: (mapId, triggerId) {
        if (mapId != proposal.afterMap.id ||
            !proposal.afterMap.triggers.any(
              (candidate) => candidate.id == triggerId,
            )) {
          return false;
        }
        selectedTriggerId = triggerId;
        return true;
      },
      mapEnter: (_) => false,
      outcomeReceived: (_) => false,
    );
    if (!isSpatialOwner) return false;

    state = state.copyWith(
      activeMap: proposal.afterMap,
      savedMapSnapshot: proposal.afterMap,
      selectedEntityId: selectedEntityId,
      selectedEntityKind: selectedEntityKind ?? state.selectedEntityKind,
      selectedTriggerId: selectedTriggerId,
      isDirty: false,
    );
    return true;
  }

  _MapDiskMutationLease? _beginMapDiskMutationLease({
    bool allowCleanupInterlock = false,
  }) {
    if (!allowCleanupInterlock &&
        _narrativeEventSourceCleanupInterlock != null) {
      state = state.copyWith(
        errorMessage: 'Une map nettoyée doit être rechargée avant toute '
            'nouvelle écriture de map.',
      );
      return null;
    }
    if (_mapDiskMutationLease != null || state.isSaving) {
      state = state.copyWith(
        errorMessage: 'Une écriture de map est déjà en cours.',
      );
      return null;
    }
    final lease = (
      token: Object(),
      projectRootPath: state.projectRootPath,
      project: state.project,
      activeMap: state.activeMap,
      activeMapPath: state.activeMapPath,
    );
    _mapDiskMutationLease = lease;
    state = _projectSessionController.markMapSaving(state);
    return lease;
  }

  /// Publishes the Event V2 map writer through the same lease as normal saves.
  Object? beginNarrativeEventSourceMapWriteLease() {
    // Defense in depth: a proposal may have been prepared before the document
    // became read-only or before a Border preview started.
    if (_rejectNonCanonicalActiveMapAuthoring(revalidateManifest: true) ||
        _rejectPendingBorderPreviewDirectMapWrite()) {
      return null;
    }
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return null;
    _narrativeEventSourceMapWriteLeaseToken = lease.token;
    return lease.token;
  }

  void endNarrativeEventSourceMapWriteLease(Object token) {
    final lease = _mapDiskMutationLease;
    if (lease != null &&
        identical(lease.token, token) &&
        identical(_narrativeEventSourceMapWriteLeaseToken, token)) {
      _narrativeEventSourceMapWriteLeaseToken = null;
      _endMapDiskMutationLease(lease);
    }
  }

  bool _rejectMapDiskMutationLease({
    Object? allowedLeaseToken,
  }) {
    final token = _mapDiskMutationLease?.token;
    if (token == null && allowedLeaseToken == null) return false;
    if (token != null && identical(token, allowedLeaseToken)) return false;
    state = state.copyWith(
      errorMessage: 'Une écriture de map est en cours. '
          'Attendez sa fin avant de modifier ou recharger la map.',
    );
    return true;
  }

  bool _ownsMapDiskMutationLease(Object token) {
    return identical(_mapDiskMutationLease?.token, token);
  }

  void _refreshMapDiskMutationLeaseBaseline(Object token) {
    if (!_ownsMapDiskMutationLease(token)) return;
    _mapDiskMutationLease = (
      token: token,
      projectRootPath: state.projectRootPath,
      project: state.project,
      activeMap: state.activeMap,
      activeMapPath: state.activeMapPath,
    );
  }

  void _republishNarrativeEventSourceMapWriteLease(Object? token) {
    if (token == null ||
        !identical(_narrativeEventSourceMapWriteLeaseToken, token) ||
        !identical(_mapDiskMutationLease?.token, token) ||
        state.isSaving) {
      return;
    }
    state = _projectSessionController.markMapSaving(state);
  }

  bool _canAdoptMapDiskMutation(_MapDiskMutationLease lease) {
    return identical(_mapDiskMutationLease?.token, lease.token) &&
        _sameNullableNormalizedPath(
          state.projectRootPath,
          lease.projectRootPath,
        ) &&
        identical(state.project, lease.project) &&
        identical(state.activeMap, lease.activeMap) &&
        _sameNullableNormalizedPath(
          state.activeMapPath,
          lease.activeMapPath,
        );
  }

  void _endMapDiskMutationLease(_MapDiskMutationLease lease) {
    if (!identical(_mapDiskMutationLease?.token, lease.token)) return;
    _mapDiskMutationLease = null;
    if (state.isSaving) {
      state = state.copyWith(isSaving: false);
    }
  }

  static bool _sameNullableNormalizedPath(String? left, String? right) {
    if (left == null || right == null) return left == right;
    return p.normalize(left) == p.normalize(right);
  }

  /// Arms the stale-map write barrier before durable cleanup starts.
  bool beginNarrativeEventSourceCleanupInterlock({
    required String expectedProjectRootPath,
    required MapData expectedActiveMap,
    required NarrativeEventSpatialLinkJournal journal,
  }) {
    // Cleanup is a durable map writer. It must not bypass the same legacy and
    // transient-preview boundary enforced for source creation and tilesets.
    if (_rejectNonCanonicalActiveMapAuthoring(revalidateManifest: true) ||
        _rejectPendingBorderPreviewDirectMapWrite()) {
      return false;
    }
    final expectedRoot = p.normalize(expectedProjectRootPath);
    final expectedMapPath = p.normalize(journal.mapPath);
    final activeMapPath = state.activeMapPath;
    if (_mapDiskMutationLease != null ||
        state.isSaving ||
        state.projectRootPath == null ||
        p.normalize(state.projectRootPath!) != expectedRoot ||
        activeMapPath == null ||
        p.normalize(activeMapPath) != expectedMapPath ||
        !identical(state.activeMap, expectedActiveMap) ||
        expectedActiveMap.id != journal.mapId) {
      return false;
    }
    final nextInterlock = _narrativeEventSourceCleanupInterlockFor(
      expectedProjectRootPath: expectedRoot,
      journal: journal,
    );
    final currentInterlock = _narrativeEventSourceCleanupInterlock;
    if (currentInterlock != null) {
      return currentInterlock == nextInterlock &&
          identical(
            _narrativeEventSourceCleanupProjectIdentity,
            state.project,
          ) &&
          identical(
            _narrativeEventSourceCleanupBaselineIdentity,
            expectedActiveMap,
          );
    }
    _narrativeEventSourceCleanupInterlock = nextInterlock;
    _narrativeEventSourceCleanupProjectIdentity = state.project;
    _narrativeEventSourceCleanupBaselineIdentity = expectedActiveMap;
    return true;
  }

  void releaseNarrativeEventSourceCleanupInterlock({
    required String expectedProjectRootPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) {
    _clearNarrativeEventSourceCleanupInterlock(
      _narrativeEventSourceCleanupInterlockFor(
        expectedProjectRootPath: expectedProjectRootPath,
        journal: journal,
      ),
    );
  }

  /// Adopts the map snapshot durably cleaned by the Event V2 recovery flow.
  ///
  /// An exact CAS adopts the disk snapshot directly. When unrelated edits
  /// raced with cleanup, the exact owner deletion is rebased over the current
  /// map if its journal fingerprint is still unchanged. Otherwise stale
  /// writes stay blocked until a verified map reload.
  Future<bool> adoptPersistedNarrativeEventSourceCleanup({
    required String expectedProjectRootPath,
    required MapData expectedActiveMap,
    required NarrativeEventSpatialLinkJournal journal,
  }) async {
    final expectedRoot = p.normalize(expectedProjectRootPath);
    final expectedMapPath = p.normalize(journal.mapPath);
    final cleanupInterlock = _narrativeEventSourceCleanupInterlockFor(
      expectedProjectRootPath: expectedRoot,
      journal: journal,
    );
    final currentInterlock = _narrativeEventSourceCleanupInterlock;
    if (currentInterlock != null) {
      if (currentInterlock != cleanupInterlock ||
          !identical(
            _narrativeEventSourceCleanupProjectIdentity,
            state.project,
          ) ||
          !identical(
            _narrativeEventSourceCleanupBaselineIdentity,
            expectedActiveMap,
          )) {
        return false;
      }
    } else {
      _narrativeEventSourceCleanupProjectIdentity = state.project;
      _narrativeEventSourceCleanupBaselineIdentity = expectedActiveMap;
    }
    _narrativeEventSourceCleanupInterlock = cleanupInterlock;

    final activeMapPath = state.activeMapPath;
    final expectedProject = state.project;
    final expectedSavedMap = state.savedMapSnapshot;
    final exactBaselineBeforeLoad = state.projectRootPath != null &&
        p.normalize(state.projectRootPath!) == expectedRoot &&
        activeMapPath != null &&
        p.normalize(activeMapPath) == expectedMapPath &&
        identical(state.activeMap, expectedActiveMap) &&
        !state.isDirty &&
        !state.isSaving &&
        state.mapStrokeStart == null &&
        expectedActiveMap.id == journal.mapId &&
        expectedSavedMap == expectedActiveMap;
    final expectedCleaned = _removeExactNarrativeEventJournalOwner(
      expectedActiveMap,
      journal,
    );
    if (expectedCleaned == null) return false;

    late final LoadedMapDocumentResult diskDocument;
    try {
      diskDocument = await ref
          .read(loadMapUseCaseProvider)
          .executeAbsolutePath(expectedMapPath, refreshSnapshot: true);
    } on Object {
      return false;
    }
    final diskMap = diskDocument.map;
    if (!_sameNarrativeEventMap(diskMap, expectedCleaned)) {
      return false;
    }

    final exactBaselineStillCurrent = exactBaselineBeforeLoad &&
        state.projectRootPath != null &&
        p.normalize(state.projectRootPath!) == expectedRoot &&
        identical(state.project, expectedProject) &&
        identical(state.activeMap, expectedActiveMap) &&
        identical(state.savedMapSnapshot, expectedSavedMap) &&
        state.activeMapPath != null &&
        p.normalize(state.activeMapPath!) == expectedMapPath &&
        !state.isDirty &&
        !state.isSaving &&
        state.mapStrokeStart == null;
    if (exactBaselineStillCurrent) {
      _adoptNarrativeEventSourceCleanupMaps(
        activeMap: diskMap,
        savedMap: diskMap,
        journal: journal,
        isDirty: false,
      );
      _rememberMapDocumentRevision(
        expectedMapPath,
        revision: diskDocument.revision,
        sourceDocument: diskMap,
      );
      _clearNarrativeEventSourceCleanupInterlock(cleanupInterlock);
      return true;
    }

    final currentMap = state.activeMap;
    final canRebaseCurrentMap = state.projectRootPath != null &&
        p.normalize(state.projectRootPath!) == expectedRoot &&
        identical(state.project, expectedProject) &&
        state.activeMapPath != null &&
        p.normalize(state.activeMapPath!) == expectedMapPath &&
        currentMap != null &&
        currentMap.id == journal.mapId &&
        !state.isSaving &&
        state.mapStrokeStart == null;
    if (canRebaseCurrentMap) {
      final rebased = _removeExactNarrativeEventJournalOwner(
        currentMap,
        journal,
      );
      if (rebased != null) {
        final remainsDirty = !_sameNarrativeEventMap(rebased, diskMap);
        _adoptNarrativeEventSourceCleanupMaps(
          activeMap: rebased,
          savedMap: diskMap,
          journal: journal,
          isDirty: remainsDirty,
        );
        _rememberMapDocumentRevision(
          expectedMapPath,
          revision: diskDocument.revision,
          sourceDocument: diskMap,
        );
        _clearNarrativeEventSourceCleanupInterlock(cleanupInterlock);
        return true;
      }
    }
    return false;
  }

  void _adoptNarrativeEventSourceCleanupMaps({
    required MapData activeMap,
    required MapData savedMap,
    required NarrativeEventSpatialLinkJournal journal,
    required bool isDirty,
  }) {
    String? removedEntityId;
    String? removedTriggerId;
    journal.source.when(
      entityInteract: (_, entityId) => removedEntityId = entityId,
      triggerEnter: (_, triggerId) => removedTriggerId = triggerId,
      mapEnter: (_) {},
      outcomeReceived: (_) {},
    );
    state = state.copyWith(
      activeMap: activeMap,
      savedMapSnapshot: savedMap,
      selectedEntityId: state.selectedEntityId == removedEntityId
          ? null
          : state.selectedEntityId,
      selectedTriggerId: state.selectedTriggerId == removedTriggerId
          ? null
          : state.selectedTriggerId,
      mapUndoStack: const [],
      mapRedoStack: const [],
      mapStrokeStart: null,
      canUndoMap: false,
      canRedoMap: false,
      isDirty: isDirty,
      statusMessage: isDirty
          ? 'Source Event supprimée ; modifications locales préservées.'
          : 'Source Event supprimée et map resynchronisée.',
      errorMessage: null,
    );
    _confirmedBulkPlacementLossBaseline = null;
  }

  static MapData? _removeExactNarrativeEventJournalOwner(
    MapData map,
    NarrativeEventSpatialLinkJournal journal,
  ) {
    return journal.source.when(
      entityInteract: (mapId, entityId) {
        if (mapId != map.id) return null;
        final owners = map.entities
            .where((candidate) => candidate.id == entityId)
            .toList();
        if (owners.length != 1 ||
            !_matchesNarrativeEventJournalOwner(
              journal: journal,
              ownerKind: 'mapEntity',
              owner: owners.single.toJson(),
              sourceId: entityId,
            )) {
          return null;
        }
        return map.copyWith(
          entities: map.entities
              .where((candidate) => candidate.id != entityId)
              .toList(),
        );
      },
      triggerEnter: (mapId, triggerId) {
        if (mapId != map.id) return null;
        final owners = map.triggers
            .where((candidate) => candidate.id == triggerId)
            .toList();
        if (owners.length != 1 ||
            !_matchesNarrativeEventJournalOwner(
              journal: journal,
              ownerKind: 'mapTrigger',
              owner: owners.single.toJson(),
              sourceId: triggerId,
            )) {
          return null;
        }
        return map.copyWith(
          triggers: map.triggers
              .where((candidate) => candidate.id != triggerId)
              .toList(),
        );
      },
      mapEnter: (_) => null,
      outcomeReceived: (_) => null,
    );
  }

  static bool _matchesNarrativeEventJournalOwner({
    required NarrativeEventSpatialLinkJournal journal,
    required String ownerKind,
    required Map<String, Object?> owner,
    required String sourceId,
  }) {
    final envelope = <String, Object?>{
      'schemaVersion': 1,
      'ownerKind': ownerKind,
      'mapId': journal.mapId,
      'sourceId': sourceId,
      'owner': owner,
    };
    final bytes = canonicalizeNarrativeEventJsonUtf8(envelope);
    return narrativeEventBytesFingerprint(bytes) ==
            journal.sourceOwnerFingerprint &&
        listEquals(
          bytes,
          canonicalizeNarrativeEventJsonUtf8(journal.sourceOwnerJson),
        );
  }

  static bool _sameNarrativeEventMap(MapData left, MapData right) {
    return listEquals(
      canonicalizeNarrativeEventJsonUtf8(left.toJson()),
      canonicalizeNarrativeEventJsonUtf8(right.toJson()),
    );
  }

  static _NarrativeEventSourceCleanupInterlock
      _narrativeEventSourceCleanupInterlockFor({
    required String expectedProjectRootPath,
    required NarrativeEventSpatialLinkJournal journal,
  }) {
    return (
      projectRootPath: p.normalize(expectedProjectRootPath),
      mapPath: p.normalize(journal.mapPath),
      mapId: journal.mapId,
      operationId: journal.operationId,
      source: journal.source,
      sourceOwnerFingerprint: journal.sourceOwnerFingerprint,
    );
  }

  void _clearNarrativeEventSourceCleanupInterlock(
    _NarrativeEventSourceCleanupInterlock expected,
  ) {
    if (_narrativeEventSourceCleanupInterlock == expected) {
      _narrativeEventSourceCleanupInterlock = null;
      _narrativeEventSourceCleanupProjectIdentity = null;
      _narrativeEventSourceCleanupBaselineIdentity = null;
    }
  }

  void _clearNarrativeEventSourceCleanupInterlockAfterReload({
    required MapData map,
    required String mapPath,
  }) {
    final interlock = _narrativeEventSourceCleanupInterlock;
    final projectRootPath = state.projectRootPath;
    if (interlock == null ||
        projectRootPath == null ||
        p.normalize(projectRootPath) != interlock.projectRootPath ||
        p.normalize(mapPath) != interlock.mapPath ||
        map.id != interlock.mapId) {
      return;
    }
    if (_mapOwnsNarrativeEventSource(map, interlock.source)) {
      if (_mapOwnsExactNarrativeEventSource(map, interlock)) {
        _narrativeEventSourceCleanupProjectIdentity = state.project;
        _narrativeEventSourceCleanupBaselineIdentity = map;
      }
      return;
    }
    _narrativeEventSourceCleanupInterlock = null;
    _narrativeEventSourceCleanupProjectIdentity = null;
    _narrativeEventSourceCleanupBaselineIdentity = null;
  }

  bool _rejectNarrativeEventSourceCleanupMapMutation() {
    final interlock = _narrativeEventSourceCleanupInterlock;
    final projectRootPath = state.projectRootPath;
    final activeMapPath = state.activeMapPath;
    final activeMap = state.activeMap;
    if (interlock == null ||
        projectRootPath == null ||
        activeMapPath == null ||
        activeMap == null ||
        p.normalize(projectRootPath) != interlock.projectRootPath ||
        p.normalize(activeMapPath) != interlock.mapPath ||
        activeMap.id != interlock.mapId) {
      return false;
    }
    state = state.copyWith(
      errorMessage: 'Cette map a été nettoyée sur disque. Rechargez-la avant '
          'de la modifier ou de l’enregistrer.',
    );
    return true;
  }

  static bool _mapOwnsNarrativeEventSource(
    MapData map,
    NarrativeEventSourceRef source,
  ) {
    return source.when(
      entityInteract: (mapId, entityId) =>
          map.id == mapId &&
          map.entities.any((candidate) => candidate.id == entityId),
      triggerEnter: (mapId, triggerId) =>
          map.id == mapId &&
          map.triggers.any((candidate) => candidate.id == triggerId),
      mapEnter: (mapId) => map.id == mapId,
      outcomeReceived: (_) => true,
    );
  }

  static bool _mapOwnsExactNarrativeEventSource(
    MapData map,
    _NarrativeEventSourceCleanupInterlock interlock,
  ) {
    return interlock.source.when(
      entityInteract: (mapId, entityId) {
        if (map.id != mapId) return false;
        final owners = map.entities
            .where((candidate) => candidate.id == entityId)
            .toList();
        if (owners.length != 1) return false;
        final envelope = _narrativeEventOwnerEnvelope(
          ownerKind: 'mapEntity',
          mapId: mapId,
          sourceId: entityId,
          owner: owners.single.toJson(),
        );
        return narrativeEventBytesFingerprint(
              canonicalizeNarrativeEventJsonUtf8(envelope),
            ) ==
            interlock.sourceOwnerFingerprint;
      },
      triggerEnter: (mapId, triggerId) {
        if (map.id != mapId) return false;
        final owners = map.triggers
            .where((candidate) => candidate.id == triggerId)
            .toList();
        if (owners.length != 1) return false;
        final envelope = _narrativeEventOwnerEnvelope(
          ownerKind: 'mapTrigger',
          mapId: mapId,
          sourceId: triggerId,
          owner: owners.single.toJson(),
        );
        return narrativeEventBytesFingerprint(
              canonicalizeNarrativeEventJsonUtf8(envelope),
            ) ==
            interlock.sourceOwnerFingerprint;
      },
      mapEnter: (_) => false,
      outcomeReceived: (_) => false,
    );
  }

  static Map<String, Object?> _narrativeEventOwnerEnvelope({
    required String ownerKind,
    required String mapId,
    required String sourceId,
    required Map<String, Object?> owner,
  }) {
    return <String, Object?>{
      'schemaVersion': 1,
      'ownerKind': ownerKind,
      'mapId': mapId,
      'sourceId': sourceId,
      'owner': owner,
    };
  }

  /// Returns the same fail-closed plan used by [resizeActiveMap], without
  /// mutating editor state or history.
  MapResizePlan? planActiveMapResize(int width, int height) {
    final map = state.activeMap;
    if (map == null) return null;
    final project = state.project;
    final settings = project?.settings;
    return ref.read(resizeMapUseCaseProvider).plan(
          map,
          width,
          height,
          tileSizePx: settings == null
              ? null
              : GridSize(
                  width: settings.tileWidth,
                  height: settings.tileHeight,
                ),
          project: project,
        );
  }

  Future<void> resizeActiveMap(int width, int height) async {
    final map = state.activeMap;
    if (map == null) return;

    debugPrint('EditorNotifier: resizeActiveMap(${width}x$height)');
    ref.read(borderResizeFeedbackProvider.notifier).clear();
    try {
      final useCase = ref.read(resizeMapUseCaseProvider);
      final project = state.project;
      if (project == null && map.layers.any((layer) => layer is BorderLayer)) {
        state = state.copyWith(
          statusMessage: null,
          errorMessage: 'Impossible de redimensionner une carte avec des '
              'bordures sans les réglages de tuile du projet.',
        );
        return;
      }
      final settings = project?.settings ?? const ProjectSettings();
      final result = useCase.execute(
        map,
        width,
        height,
        tileSizePx: GridSize(
          width: settings.tileWidth,
          height: settings.tileHeight,
        ),
        project: project,
      );
      final resized = result.map;
      if (!result.canApply || resized == null) {
        if (result.diagnosticReport.hasDiagnostics) {
          ref
              .read(borderResizeFeedbackProvider.notifier)
              .setFeedback(BorderResizeFeedback(
                mapIdentity: map,
                diagnosticReport: result.diagnosticReport,
              ));
        }
        final impactCount = result.plan.impacts.length;
        final diagnosticCount = result.diagnosticReport.errorCount;
        final count = impactCount > 0 ? impactCount : diagnosticCount;
        final noun = impactCount > 0 ? 'impact' : 'diagnostic';
        state = state.copyWith(
          statusMessage: null,
          errorMessage: 'Impossible de redimensionner la carte : '
              '$count $noun${count > 1 ? 's' : ''} '
              'bloquant${count > 1 ? 's' : ''}.',
        );
        return;
      }

      if (identical(resized, map) || resized == map) {
        state = state.copyWith(
          statusMessage:
              'La carte « ${map.id} » est déjà de taille ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final committed = project == null
          ? resized
          : _placedElementInstanceIndexer.syncAllTileLayers(
              map: resized,
              project: project,
            );
      if (identical(committed, map) || committed == map) {
        state = state.copyWith(
          statusMessage:
              'La carte « ${map.id} » est déjà de taille ${width}x$height',
          errorMessage: null,
        );
        return;
      }

      final hovered = state.hoveredTile;
      final nextHovered = (hovered != null &&
              (hovered.x < 0 ||
                  hovered.y < 0 ||
                  hovered.x >= width ||
                  hovered.y >= height))
          ? null
          : hovered;
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        hoveredTile: nextHovered,
        updateHoveredTile: true,
        statusMessage: 'Carte « ${map.id} » redimensionnée en ${width}x$height',
      );
      final activeMap = state.activeMap;
      if (activeMap != null &&
          identical(activeMap, committed) &&
          result.diagnosticReport.hasDiagnostics) {
        ref
            .read(borderResizeFeedbackProvider.notifier)
            .setFeedback(BorderResizeFeedback(
              mapIdentity: activeMap,
              diagnosticReport: result.diagnosticReport,
            ));
      }
    } catch (e) {
      debugPrint('EditorNotifier: Error resizing map: $e');
      state = state.copyWith(
          errorMessage: 'Impossible de redimensionner la carte : $e');
    }
  }

  void updateMapMetadata(MapMetadata metadata) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(updateMapMetadataUseCaseProvider);
      final updated = useCase.execute(
        map,
        metadata,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Carte : propriétés enregistrées',
      );
    } catch (e) {
      debugPrint('EditorNotifier: updateMapMetadata failed: $e');
      state = state.copyWith(
        errorMessage: 'Échec des propriétés de carte : $e',
      );
    }
  }

  Future<MapDependencyPreflightResult?> renameMap(
    String oldId,
    String newId,
  ) async {
    debugPrint('EditorNotifier: renameMap($oldId -> $newId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return null;
    if (_rejectPendingBorderPreviewMapLifecycleMutation()) return null;
    if (state.isDirty && state.activeMap?.id == oldId) {
      state = state.copyWith(
        errorMessage: 'Enregistrez ou abandonnez les modifications de cette '
            'carte avant de la renommer.',
      );
      return null;
    }
    if (_rejectNarrativeEventSourceCleanupMapMutation()) return null;
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return null;

    try {
      final useCase = ref.read(renameMapUseCaseProvider);
      final sourceEntry = project.maps.firstWhere((entry) => entry.id == oldId);
      final oldPath = fs.resolveMapPath(sourceEntry.relativePath);
      final result = await useCase.executeRevisioned(fs, project, oldId, newId);
      if (!_canAdoptMapDiskMutation(lease)) return null;
      final newPath = fs.getMapPath(newId);
      state = _projectSessionController.afterMapRenamed(
        current: state,
        updatedProject: result.project,
        oldId: oldId,
        newId: newId,
        newPath: newPath,
        statusMessage: 'Carte renommée en « $newId »',
      );
      final renamedMap = result.map;
      if (renamedMap != null) {
        _forgetMapDocumentRevision(oldPath);
        _rememberMapDocumentRevision(
          newPath,
          revision: result.revision,
          sourceDocument: renamedMap,
        );
      }
    } on MapDependencyPreflightBlockedException catch (error) {
      debugPrint('EditorNotifier: Map rename preflight blocked: $error');
      if (_canAdoptMapDiskMutation(lease)) {
        state = state.copyWith(errorMessage: error.result.blockingMessage);
      }
      return error.result;
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming map: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state = state.copyWith(
          errorMessage: 'Impossible de renommer la carte : $e',
        );
      }
    } finally {
      _endMapDiskMutationLease(lease);
    }
    return null;
  }

  Future<MapDependencyPreflightResult?> deleteMap(String mapId) async {
    debugPrint('EditorNotifier: deleteMap($mapId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return null;
    if (_rejectPendingBorderPreviewMapLifecycleMutation()) return null;
    if (state.isDirty && state.activeMap?.id == mapId) {
      state = state.copyWith(
        errorMessage: 'Enregistrez ou abandonnez les modifications de cette '
            'carte avant de la supprimer.',
      );
      return null;
    }
    if (_rejectNarrativeEventSourceCleanupMapMutation()) return null;
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return null;

    try {
      final useCase = ref.read(deleteMapUseCaseProvider);
      final sourceEntry = project.maps.firstWhere((entry) => entry.id == mapId);
      final mapPath = fs.resolveMapPath(sourceEntry.relativePath);
      final updatedProject = await useCase.execute(fs, project, mapId);
      if (!_canAdoptMapDiskMutation(lease)) return null;
      state = _projectSessionController.afterMapDeleted(
        current: state,
        updatedProject: updatedProject,
        deletedMapId: mapId,
        statusMessage: 'Carte « $mapId » supprimée',
      );
      _forgetMapDocumentRevision(mapPath);
    } on MapDependencyPreflightBlockedException catch (error) {
      debugPrint('EditorNotifier: Map delete preflight blocked: $error');
      if (_canAdoptMapDiskMutation(lease)) {
        state = state.copyWith(errorMessage: error.result.blockingMessage);
      }
      return error.result;
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting map: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state = state.copyWith(
          errorMessage: 'Impossible de supprimer la carte : $e',
        );
      }
    } finally {
      _endMapDiskMutationLease(lease);
    }
    return null;
  }

  Future<void> duplicateMap(String sourceId) async {
    debugPrint('EditorNotifier: duplicateMap($sourceId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    if (_rejectPendingBorderPreviewMapLifecycleMutation()) return;
    if (_rejectNarrativeEventSourceCleanupMapMutation()) return;
    final lease = _beginMapDiskMutationLease();
    if (lease == null) return;

    try {
      final useCase = ref.read(duplicateMapUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, sourceId);
      if (!_canAdoptMapDiskMutation(lease)) return;

      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Carte « $sourceId » dupliquée',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error duplicating map: $e');
      if (_canAdoptMapDiskMutation(lease)) {
        state = state.copyWith(
          errorMessage: 'Impossible de dupliquer la carte : $e',
        );
      }
    } finally {
      _endMapDiskMutationLease(lease);
    }
  }

  Future<void> createGroup(String name, MapGroupType type,
      {String? parentId}) async {
    debugPrint('EditorNotifier: createGroup($name, $type, parent: $parentId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(createGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, name, type, parentId: parentId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group "$name" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating group: $e');
      state = state.copyWith(errorMessage: 'Failed to create group: $e');
    }
  }

  Future<void> deleteGroup(String groupId) async {
    debugPrint('EditorNotifier: deleteGroup($groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(deleteGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group deleted',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error deleting group: $e');
      state = state.copyWith(errorMessage: 'Failed to delete group: $e');
    }
  }

  Future<void> renameGroup(String groupId, String newName) async {
    debugPrint('EditorNotifier: renameGroup($groupId -> $newName)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(renameGroupUseCaseProvider);
      final updatedProject =
          await useCase.execute(fs, project, groupId, newName);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Group renamed',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error renaming group: $e');
      state = state.copyWith(errorMessage: 'Failed to rename group: $e');
    }
  }

  Future<void> moveMapToGroup(String mapId, String? groupId) async {
    debugPrint('EditorNotifier: moveMapToGroup($mapId -> $groupId)');
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;

    try {
      final useCase = ref.read(moveMapToGroupUseCaseProvider);
      final updatedProject = await useCase.execute(fs, project, mapId, groupId);
      state = state.copyWith(
        project: updatedProject,
        statusMessage: 'Map moved',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error moving map: $e');
      state = state.copyWith(errorMessage: 'Failed to move map: $e');
    }
  }

  List<ProjectTilesetEntry> getAssignableTilesetsForActiveMap() {
    final project = state.project;
    final activeMap = state.activeMap;
    if (project == null || activeMap == null) return const [];
    try {
      final useCase = ref.read(resolveAssignableTilesetsForMapUseCaseProvider);
      return useCase.execute(project, activeMap.id);
    } catch (_) {
      return const [];
    }
  }

  ProjectTilesetEntry? getActiveTilesetEntry() {
    return getSelectedTilesetEntry();
  }

  String? getActiveTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getActiveTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  void selectMapWorkspace() {
    state = _editorWorkspaceController.selectMapWorkspace(state);
  }

  void selectTilesetWorkspace(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }
    state = state.copyWith(
      workspaceMode: tilesetId == null
          ? EditorWorkspaceMode.map
          : EditorWorkspaceMode.tileset,
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
    );
  }

  /// Ouvre le workspace Pokédex des lots 12-13.
  ///
  /// Ce changement reste volontairement une simple navigation :
  /// - aucune donnee Pokemon n'est chargee ici ;
  /// - aucun service Pokemon n'est appele ici ;
  /// - l'ecran central gerera lui-meme la lecture simple necessaire au lot 13.
  ///
  /// Cela garde la responsabilite du notifier tres claire :
  /// il route vers un workspace, mais ne commence pas une logique Pokédex riche.
  void selectPokedexWorkspace() {
    state = _editorWorkspaceController.selectPokedexWorkspace(state);
  }

  void selectPokemonCatalogSection(PokemonCatalogSection section) {
    state = _editorWorkspaceController.selectPokemonCatalogSection(
      state,
      section,
    );
  }

  void selectEncounterWorkspace() {
    state = _editorWorkspaceController.selectEncounterWorkspace(state);
  }

  void selectEncounterStudioSection(EncounterStudioSection section) {
    state = _editorWorkspaceController.selectEncounterStudioSection(
      state,
      section,
    );
  }

  /// Ouvre la section Dresseurs du workspace central Encounter Studio.
  ///
  /// Cette navigation reste volontairement minimale :
  /// - aucun pipeline trainer parallèle n'est créé ici ;
  /// - aucune donnée locale n'est préchargée depuis le notifier ;
  /// - la surface centrale réutilise le même flux trainer que la sidebar,
  ///   via les méthodes existantes du notifier.
  void selectTrainerWorkspace() {
    state = _editorWorkspaceController.selectTrainerWorkspace(state);
  }

  void selectWildEncounterWorkspace() {
    state = _editorWorkspaceController.selectWildEncounterWorkspace(state);
  }

  void selectWildEncounterTableWorkspace(String tableId) {
    state = _editorWorkspaceController.selectWildEncounterTableWorkspace(
      state,
      tableId,
    );
  }

  /// Ouvre le workspace central "Aperçu" du Narrative Studio.
  ///
  /// Navigation pure de shell : les données affichées sont dérivées par le
  /// read model overview, pas recalculées dans le notifier.
  void selectNarrativeOverviewWorkspace() {
    state = _editorWorkspaceController.selectNarrativeOverviewWorkspace(state);
  }

  /// Ouvre le workspace central "Global Story".
  ///
  /// Ce changement est purement une navigation d'espace de travail:
  /// - aucune mutation map/tileset n'est exécutée,
  /// - aucune donnée narrative n'est modifiée ici.
  void selectGlobalStoryWorkspace() {
    state = _editorWorkspaceController.selectGlobalStoryWorkspace(state);
  }

  /// Ouvre le shell central "Scènes" sans mutation narrative.
  void selectScenesWorkspace() {
    state = _editorWorkspaceController.selectScenesWorkspace(state);
  }

  /// Ouvre le shell central "Événements" sans mutation narrative.
  void selectEventsWorkspace() {
    state = _editorWorkspaceController.selectEventsWorkspace(state);
  }

  /// Ouvre le workspace central "Step".
  void selectStepWorkspace() {
    state = _editorWorkspaceController.selectStepWorkspace(state);
  }

  /// Ouvre le workspace central "Cutscene".
  void selectCutsceneWorkspace() {
    state = _editorWorkspaceController.selectCutsceneWorkspace(state);
  }

  /// Bascule vers Dialogue Studio (bibliothèque + canvas + inspecteur).
  void selectDialogueWorkspace() {
    state = _editorWorkspaceController.selectDialogueWorkspace(state);
  }

  /// Bascule vers le manager Facts.
  void selectFactsWorkspace() {
    state = _editorWorkspaceController.selectFactsWorkspace(state);
  }

  /// Bascule vers le Shop Builder no-code.
  void selectShopsWorkspace() {
    state = _editorWorkspaceController.selectShopsWorkspace(state);
  }

  /// Bascule vers le manager des règles du monde.
  void selectWorldRulesWorkspace() {
    state = _editorWorkspaceController.selectWorldRulesWorkspace(state);
  }

  /// Ouvre le verdict global de jouabilité narrative sans muter le projet.
  void selectNarrativeValidatorWorkspace() {
    state = _editorWorkspaceController.selectNarrativeValidatorWorkspace(state);
  }

  /// Ouvre le studio natif unifié des terrains, chemins et forêts.
  void selectSmartTilesStudioWorkspace() {
    state = _editorWorkspaceController.selectSmartTilesStudioWorkspace(state);
  }

  /// Ouvre Smart Tiles Studio depuis l’explorateur sans cible de carte.
  void selectSmartTilesStudioLibraryWorkspace() {
    state = _editorWorkspaceController
        .selectSmartTilesStudioLibraryWorkspace(state);
  }

  /// Bascule vers Environment Studio.
  void selectEnvironmentStudioWorkspace() {
    state = _editorWorkspaceController.selectEnvironmentStudioWorkspace(state);
  }

  /// Ouvre le Personalization Studio sans muter le profil du projet.
  void selectPersonalizationStudioWorkspace() {
    state =
        _editorWorkspaceController.selectPersonalizationStudioWorkspace(state);
  }

  /// Bascule vers Border Studio sans exiger de carte active.
  void selectBorderStudioWorkspace() {
    state = _editorWorkspaceController.selectBorderStudioWorkspace(state);
  }

  /// Écrit uniquement le fichier `.yarn` (le manifest projet reste inchangé).
  Future<void> saveProjectDialogueYarnBody({
    required String dialogueId,
    required String yarnBody,
  }) async {
    state = await _projectContentController.saveProjectDialogueYarnBody(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      yarnBody: yarnBody,
    );
  }

  void selectTilesetEditorContext(String? tilesetId) {
    final project = state.project;
    if (project == null) return;
    if (tilesetId != null && !project.tilesets.any((t) => t.id == tilesetId)) {
      return;
    }

    if (state.workspaceMode == EditorWorkspaceMode.map &&
        state.activeMap != null &&
        state.activeLayerId != null) {
      if (tilesetId != null &&
          !getAssignableTilesetsForActiveMap()
              .any((tileset) => tileset.id == tilesetId)) {
        state = state.copyWith(
          errorMessage: 'Ce tileset n’est pas disponible pour la carte active.',
        );
        return;
      }
      final selectedTilesetId = tilesetId ?? _assignedTilesetIdForState(state);
      final brushTilesetId = getActiveBrushTilesetId();
      final keepBrush =
          brushTilesetId == null || brushTilesetId == selectedTilesetId;
      state = state.copyWith(
        activeBrush: keepBrush ? state.activeBrush : const EditorBrush.none(),
        selectedTilesetElementGroupId: null,
        errorMessage: null,
      );
      _setActivePaletteSelectedTileset(selectedTilesetId);
      return;
    }

    state = state.copyWith(
      selectedTilesetEditorId: tilesetId,
      selectedTilesetElementGroupId: null,
      errorMessage: null,
    );
  }

  ProjectTilesetEntry? getSelectedTilesetEntry() {
    final project = state.project;
    if (project == null) return null;

    final studioSelectedId = state.selectedTilesetEditorId;
    if (state.workspaceMode == EditorWorkspaceMode.tileset &&
        studioSelectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == studioSelectedId) {
          return tileset;
        }
      }
    }

    final map = state.activeMap;
    final activeLayerId = state.activeLayerId;
    if (map != null && activeLayerId != null) {
      final contextKey = EditorPaletteContextKey(
        mapId: map.id,
        layerId: activeLayerId,
      );
      final paletteSelectedId =
          state.paletteSession.contexts[contextKey]?.selectedTilesetId;
      if (paletteSelectedId != null) {
        for (final tileset in project.tilesets) {
          if (tileset.id == paletteSelectedId) {
            return tileset;
          }
        }
      }

      final activeLayer = _findLayerById(map, activeLayerId);
      if (activeLayer is TileLayer) {
        final layerTilesetId =
            _assignedTilesetIdForLayer(map, activeLayer)?.trim();
        if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
          for (final tileset in project.tilesets) {
            if (tileset.id == layerTilesetId) {
              return tileset;
            }
          }
        }
      }
    }

    if (state.workspaceMode == EditorWorkspaceMode.map &&
        map != null &&
        activeLayerId != null) {
      return null;
    }

    final brushTilesetId = getActiveBrushTilesetId();
    if (brushTilesetId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == brushTilesetId) {
          return tileset;
        }
      }
    }

    if (studioSelectedId != null) {
      for (final tileset in project.tilesets) {
        if (tileset.id == studioSelectedId) {
          return tileset;
        }
      }
    }

    if (project.tilesets.isEmpty) return null;
    return project.tilesets.first;
  }

  String? getSelectedTilesetAbsolutePath() {
    final fs = _projectWorkspace;
    final tileset = getSelectedTilesetEntry();
    if (fs == null || tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getTilesetAbsolutePathById(String tilesetId) {
    final fs = _projectWorkspace;
    if (fs == null) return null;
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    return fs.resolveTilesetPath(tileset.relativePath);
  }

  String? getActiveBrushTilesetId() {
    final brush = state.activeBrush;
    if (brush is TileEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is PaletteEntryEditorBrush) {
      return brush.tilesetId;
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      return element?.tilesetId;
    }
    return null;
  }

  EditorPaletteContextKey? _activePaletteContextKey(EditorState source) {
    final map = source.activeMap;
    final layerId = source.activeLayerId;
    if (map == null || layerId == null) return null;
    return EditorPaletteContextKey(mapId: map.id, layerId: layerId);
  }

  String? _assignedTilesetIdForLayer(MapData map, TileLayer layer) {
    final layerTilesetId = tileLayerSingleTilesetId(layer)?.trim();
    if (layerTilesetId != null && layerTilesetId.isNotEmpty) {
      return layerTilesetId;
    }
    final mapTilesetId = map.tilesetId.trim();
    return mapTilesetId.isEmpty ? null : mapTilesetId;
  }

  String? _assignedTilesetIdForState(EditorState source) {
    final map = source.activeMap;
    final layerId = source.activeLayerId;
    if (map == null || layerId == null) return null;
    final layer = _findLayerById(map, layerId);
    return layer is TileLayer ? _assignedTilesetIdForLayer(map, layer) : null;
  }

  EditorPaletteBrushMemory _paletteBrushMemory(EditorBrush brush) {
    if (brush is TileEditorBrush) {
      return EditorPaletteBrushMemory.tile(
        tileId: brush.tileId,
        tilesetId: brush.tilesetId,
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      return EditorPaletteBrushMemory.paletteEntry(
        entryId: brush.entryId,
        tilesetId: brush.tilesetId,
      );
    }
    if (brush is ProjectElementEditorBrush) {
      return EditorPaletteBrushMemory.projectElement(
        elementId: brush.elementId,
      );
    }
    return const EditorPaletteBrushMemory.none();
  }

  EditorBrush _editorBrush(EditorPaletteBrushMemory brush) {
    return brush.map(
      none: (_) => const EditorBrush.none(),
      tile: (tile) => EditorBrush.tile(
        tileId: tile.tileId,
        tilesetId: tile.tilesetId,
      ),
      paletteEntry: (entry) => EditorBrush.paletteEntry(
        entryId: entry.entryId,
        tilesetId: entry.tilesetId,
      ),
      projectElement: (element) => EditorBrush.projectElement(
        elementId: element.elementId,
      ),
    );
  }

  EditorPaletteSession _rememberActivePaletteContext(EditorState source) {
    final key = _activePaletteContextKey(source);
    if (key == null) return source.paletteSession;
    final assignedTilesetId = _assignedTilesetIdForState(source);
    final existing = source.paletteSession.contexts[key] ??
        EditorLayerPaletteContext(selectedTilesetId: assignedTilesetId);
    final context = existing.copyWith(
      selectedTilesetId: existing.selectedTilesetId ?? assignedTilesetId,
      selectedElementGroupId: source.selectedTilesetElementGroupId,
      paletteCategoryFilter: source.paletteCategoryFilter,
      activeBrush: _paletteBrushMemory(source.activeBrush),
      panelMode: source.tilesElementsPanelMode,
    );
    return const EditorPaletteSessionService().remember(
      source.paletteSession,
      key: key,
      context: context,
    );
  }

  @override
  EditorState _activatePaletteContext(EditorState source) {
    final project = source.project;
    final key = _activePaletteContextKey(source);
    if (project == null) return source;
    final sanitizedSession = const EditorPaletteSessionService().sanitize(
      source.paletteSession,
      project: project,
      activeMap: source.activeMap,
    );
    if (key == null) {
      return source.copyWith(
        paletteSession: sanitizedSession,
        activeBrush: const EditorBrush.none(),
        selectedTilesetElementGroupId: null,
        paletteCategoryFilter: null,
      );
    }
    final activation = const EditorPaletteSessionService().activate(
      sanitizedSession,
      key: key,
      project: project,
      assignedTilesetId: _assignedTilesetIdForState(source),
      activeMap: source.activeMap,
    );
    return source.copyWith(
      paletteSession: activation.session,
      selectedTilesetElementGroupId: activation.context.selectedElementGroupId,
      paletteCategoryFilter: activation.context.paletteCategoryFilter,
      activeBrush: _editorBrush(activation.context.activeBrush),
      tilesElementsPanelMode: activation.context.panelMode,
    );
  }

  void _syncActivePaletteContext() {
    state = state.copyWith(
      paletteSession: _rememberActivePaletteContext(state),
    );
  }

  void _setActivePaletteSelectedTileset(String? tilesetId) {
    final project = state.project;
    final key = _activePaletteContextKey(state);
    if (project == null || key == null) return;
    var session = _rememberActivePaletteContext(state);
    final existing = session.contexts[key] ??
        EditorLayerPaletteContext(
          selectedTilesetId: _assignedTilesetIdForState(state),
        );
    session = const EditorPaletteSessionService().remember(
      session,
      key: key,
      context: existing.copyWith(selectedTilesetId: tilesetId),
    );
    if (tilesetId != null) {
      session = const EditorPaletteSessionService().recordRecent(
        session,
        tilesetId: tilesetId,
        validTilesetIds: project.tilesets.map((tileset) => tileset.id).toSet(),
      );
    }
    state = state.copyWith(paletteSession: session);
  }

  void _updateActivePaletteContext(
    EditorLayerPaletteContext Function(EditorLayerPaletteContext current)
        update,
  ) {
    final key = _activePaletteContextKey(state);
    if (key == null) return;
    var session = _rememberActivePaletteContext(state);
    final current = session.contexts[key] ??
        EditorLayerPaletteContext(
          selectedTilesetId: _assignedTilesetIdForState(state),
        );
    session = const EditorPaletteSessionService().remember(
      session,
      key: key,
      context: update(current),
    );
    state = state.copyWith(
      paletteSession: session,
      errorMessage: null,
    );
  }

  void setPaletteBrowserQuery(String query) {
    _updateActivePaletteContext(
      (context) => context.copyWith(browserQuery: query),
    );
  }

  void setPaletteBrowserFolder(String? folderId) {
    final project = state.project;
    if (project == null) return;
    final normalized = folderId?.trim();
    final valid = normalized == null ||
        normalized.isEmpty ||
        normalized == kEditorPaletteUnclassifiedFolderId ||
        project.tilesetFolders.any((folder) => folder.id == normalized);
    if (!valid) {
      state = state.copyWith(
        errorMessage: 'Ce dossier de sources n’existe plus.',
      );
      return;
    }
    _updateActivePaletteContext(
      (context) => context.copyWith(
        browserFolderId:
            normalized == null || normalized.isEmpty ? null : normalized,
      ),
    );
  }

  void setPaletteBrowserElementCategory(String? categoryId) {
    final project = state.project;
    if (project == null) return;
    final normalized = categoryId?.trim();
    final valid = normalized == null ||
        normalized.isEmpty ||
        project.elementCategories.any((category) => category.id == normalized);
    if (!valid) {
      state = state.copyWith(
        errorMessage: 'Cette catégorie d’éléments n’existe plus.',
      );
      return;
    }
    _updateActivePaletteContext(
      (context) => context.copyWith(
        projectElementCategoryId:
            normalized == null || normalized.isEmpty ? null : normalized,
      ),
    );
  }

  void setPaletteBrowserCollection(EditorPaletteAssetCollection collection) {
    _updateActivePaletteContext(
      (context) => context.copyWith(browserCollection: collection),
    );
  }

  void setPaletteBrowserShowIncompatible(bool value) {
    _updateActivePaletteContext(
      (context) => context.copyWith(showIncompatible: value),
    );
  }

  void togglePaletteTilesetFavorite(String tilesetId) {
    final project = state.project;
    final normalized = tilesetId.trim();
    if (project == null ||
        normalized.isEmpty ||
        !project.tilesets.any((tileset) => tileset.id == normalized)) {
      state = state.copyWith(
        errorMessage: 'Cette source n’existe plus dans le projet.',
      );
      return;
    }
    final validIds = project.tilesets.map((tileset) => tileset.id).toSet();
    state = state.copyWith(
      paletteSession: const EditorPaletteSessionService().toggleFavorite(
        state.paletteSession,
        tilesetId: normalized,
        validTilesetIds: validIds,
      ),
      errorMessage: null,
    );
  }

  bool _canUsePaletteTileset(String tilesetId) {
    return state.project?.tilesets.any((entry) => entry.id == tilesetId) ??
        false;
  }

  List<TilesetElementGroup> getSelectedTilesetElementGroups() {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return const [];
    final groups = List<TilesetElementGroup>.from(
      tileset.elementGroups,
      growable: false,
    );
    groups.sort((a, b) {
      if (a.parentGroupId == b.parentGroupId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentGroupId ?? '';
      final parentB = b.parentGroupId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return groups;
  }

  void selectTilesetElementGroupFilter(String? groupId) {
    final tileset = getSelectedTilesetEntry();
    if (tileset == null) return;
    if (groupId != null &&
        !tileset.elementGroups.any((group) => group.id == groupId)) {
      return;
    }
    state = state.copyWith(selectedTilesetElementGroupId: groupId);
    _syncActivePaletteContext();
  }

  Future<void> createTilesetElementGroup(
    String tilesetId,
    String name, {
    String? parentGroupId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        name: name,
        parentGroupId: parentGroupId,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset group: $e',
      );
    }
  }

  Future<void> createTilesetElementSubgroup(
    String tilesetId,
    String parentGroupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createTilesetElementSubgroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        parentGroupId: parentGroupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset subgroup created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to create tileset subgroup: $e',
      );
    }
  }

  Future<void> renameTilesetElementGroup(
    String tilesetId,
    String groupId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameTilesetElementGroupUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tilesetId,
        groupId: groupId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        selectedTilesetEditorId: tilesetId,
        statusMessage: 'Tileset group renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to rename tileset group: $e',
      );
    }
  }

  List<ProjectElementEntry> getSelectedTilesetElements({
    String? tilesetGroupId,
    bool includeDescendants = true,
  }) {
    final project = state.project;
    final selectedTileset = getSelectedTilesetEntry();
    if (project == null || selectedTileset == null) return const [];
    try {
      final useCase = ref.read(resolveTilesetElementsUseCaseProvider);
      return useCase.execute(
        project,
        tilesetId: selectedTileset.id,
        tilesetGroupId: tilesetGroupId,
        includeDescendants: includeDescendants,
      );
    } catch (_) {
      return const [];
    }
  }

  List<ProjectElementCategory> getElementCategories() {
    final project = state.project;
    if (project == null) return const [];
    final categories = List<ProjectElementCategory>.from(
      project.elementCategories,
      growable: false,
    );
    categories.sort((a, b) {
      if (a.parentCategoryId == b.parentCategoryId) {
        final sortCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortCompare != 0) return sortCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final parentA = a.parentCategoryId ?? '';
      final parentB = b.parentCategoryId ?? '';
      final parentCompare = parentA.compareTo(parentB);
      if (parentCompare != 0) return parentCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return categories;
  }

  ProjectElementCategory? getElementCategoryById(String categoryId) {
    final project = state.project;
    if (project == null) return null;
    for (final category in project.elementCategories) {
      if (category.id == categoryId) {
        return category;
      }
    }
    return null;
  }

  ProjectElementEntry? getProjectElementById(String elementId) {
    final project = state.project;
    if (project == null) return null;
    for (final element in project.elements) {
      if (element.id == elementId) {
        return element;
      }
    }
    return null;
  }

  List<ProjectElementEntry> getVisibleProjectElementsForActiveMap({
    bool includeAll = false,
    bool globalOnly = false,
    bool acrossAllTilesets = false,
  }) {
    final project = state.project;
    final map = state.activeMap;
    if (project == null || map == null) return const [];

    List<ProjectElementEntry> resolved;
    final activeTilesetId = getSelectedTilesetEntry()?.id;
    if (includeAll) {
      resolved = project.elements.where((element) {
        if (!acrossAllTilesets && element.tilesetId != activeTilesetId) {
          return false;
        }
        return true;
      }).toList(growable: false);
    } else if (globalOnly) {
      resolved = project.elements
          .where(
            (element) =>
                (acrossAllTilesets || element.tilesetId == activeTilesetId) &&
                element.groupId == null,
          )
          .toList(growable: false);
    } else {
      if (!acrossAllTilesets && activeTilesetId == null) {
        return const [];
      }
      try {
        final useCase = ref.read(resolveVisibleProjectElementsUseCaseProvider);
        resolved = useCase.execute(
          project,
          tilesetId: acrossAllTilesets ? null : activeTilesetId,
          mapId: map.id,
        );
      } catch (_) {
        resolved = const [];
      }
    }

    resolved.sort((a, b) {
      final categoryCompare = a.categoryId.compareTo(b.categoryId);
      if (categoryCompare != 0) return categoryCompare;
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return resolved;
  }

  Future<void> createElementCategory(
    String name, {
    String? parentCategoryId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        parentCategoryId: parentCategoryId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create category: $e');
    }
  }

  Future<void> createElementSubcategory(
    String parentCategoryId,
    String name,
  ) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createElementSubcategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        parentCategoryId: parentCategoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element subcategory created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create subcategory: $e');
    }
  }

  Future<void> renameElementCategory(String categoryId, String name) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(renameElementCategoryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        categoryId: categoryId,
        name: name,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Element category renamed',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename category: $e');
    }
  }

  Future<void> createProjectElement({
    required String name,
    required String categoryId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    ElementCollisionProfile? collisionProfile,
    String? tilesetId,
    String? tilesetGroupId,
    String? groupId,
    String? recommendedLayerId,
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    final selectedTileset = getSelectedTilesetEntry();
    final effectiveTilesetId = tilesetId ?? selectedTileset?.id;
    if (effectiveTilesetId == null) {
      state = state.copyWith(errorMessage: 'Aucun tileset sélectionné');
      return;
    }
    try {
      final useCase = ref.read(createProjectElementUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: effectiveTilesetId,
        categoryId: categoryId,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        tilesetGroupId: tilesetGroupId,
        source: source,
        groupId: groupId,
        recommendedLayerId: recommendedLayerId,
        tags: tags,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.projectElement(elementId: result.element.id),
        selectedTilesetEditorId: result.element.tilesetId,
        selectedTilesetElementGroupId: result.element.tilesetGroupId,
        statusMessage: 'Element "${result.element.name}" created',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> updateProjectElement({
    required String elementId,
    String? name,
    ElementPresetKind? presetKind,
    ElementCollisionProfile? collisionProfile,
    bool clearCollisionProfile = false,
    String? categoryId,
    String? tilesetGroupId,
    bool clearTilesetGroupId = false,
    String? groupId,
    bool clearGroupId = false,
    String? recommendedLayerId,
    bool clearRecommendedLayerId = false,
    ProjectElementShadowConfig? shadow,
    bool clearShadow = false,
    TilesetSourceRect? source,
    List<TilesetVisualFrame>? frames,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
        name: name,
        presetKind: presetKind,
        collisionProfile: collisionProfile,
        clearCollisionProfile: clearCollisionProfile,
        categoryId: categoryId,
        tilesetGroupId: tilesetGroupId,
        clearTilesetGroupId: clearTilesetGroupId,
        groupId: groupId,
        clearGroupId: clearGroupId,
        recommendedLayerId: recommendedLayerId,
        clearRecommendedLayerId: clearRecommendedLayerId,
        shadow: shadow,
        clearShadow: clearShadow,
        source: source,
        frames: frames,
        tags: tags,
      );
      String? selectedTilesetElementGroupId =
          state.selectedTilesetElementGroupId;
      final selectedElementId = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId,
        orElse: () => null,
      );
      if (selectedElementId == elementId) {
        if (clearTilesetGroupId) {
          selectedTilesetElementGroupId = null;
        } else if (tilesetGroupId != null) {
          selectedTilesetElementGroupId = tilesetGroupId;
        }
      }
      state = state.copyWith(
        project: updated,
        selectedTilesetElementGroupId: selectedTilesetElementGroupId,
        statusMessage: 'Element updated',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update element: $e');
    }
  }

  Future<void> deleteProjectElement(String elementId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteProjectElementUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        elementId: elementId,
      );
      final activeBrush = state.activeBrush.maybeMap(
        projectElement: (brush) => brush.elementId == elementId
            ? const EditorBrush.none()
            : state.activeBrush,
        orElse: () => state.activeBrush,
      );
      state = state.copyWith(
        project: updated,
        activeBrush: activeBrush,
        statusMessage: 'Element deleted',
        errorMessage: null,
      );
      _resyncPlacedElementsForActiveMapFromProject();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete element: $e');
    }
  }

  Future<ElementCollisionProfile?> generateElementCollisionProfile({
    required String tilesetId,
    required TilesetSourceRect source,
    ElementPresetKind presetKind = ElementPresetKind.generic,
    WarpTriggerPadding padding = const WarpTriggerPadding(),
  }) async {
    final project = state.project;
    if (project == null) {
      state = state.copyWith(errorMessage: 'Aucun projet chargé');
      return null;
    }
    final tilesetPath = getTilesetAbsolutePathById(tilesetId);
    if (tilesetPath == null || tilesetPath.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Chemin de tileset introuvable');
      return null;
    }
    try {
      final profile = await _elementCollisionProfileGenerator.generate(
        tilesetImagePath: tilesetPath,
        source: source,
        tileWidth: project.settings.tileWidth,
        tileHeight: project.settings.tileHeight,
        presetKind: presetKind,
        padding: padding,
      );
      state = state.copyWith(
        statusMessage:
            'Collision auto-générée (${profile.cells.length} cellule${profile.cells.length > 1 ? 's' : ''})',
        errorMessage: null,
      );
      return profile;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to generate collision profile: $e',
      );
      return null;
    }
  }

  void _resyncPlacedElementsForActiveMapFromProject() {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return;
    }
    final synced = _placedElementInstanceIndexer.syncAllTileLayers(
      map: map,
      project: project,
    );
    if (identical(synced, map) || synced == map) {
      return;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: synced,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: 'Instances d’éléments synchronisées',
    );
  }

  List<TilesetPaletteEntry> getActivePaletteEntries() {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return const [];
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  ProjectTilesetEntry? getTilesetById(String tilesetId) {
    final project = state.project;
    if (project == null) return null;
    for (final tileset in project.tilesets) {
      if (tileset.id == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  List<TilesetPaletteEntry> getPaletteEntriesForTileset(String tilesetId) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return const [];
    return List<TilesetPaletteEntry>.unmodifiable(tileset.paletteEntries);
  }

  TilesetPaletteEntry? getPaletteEntryById({
    required String tilesetId,
    required String entryId,
  }) {
    final tileset = getTilesetById(tilesetId);
    if (tileset == null) return null;
    for (final entry in tileset.paletteEntries) {
      if (entry.id == entryId) {
        return entry;
      }
    }
    return null;
  }

  TilesetPaletteEntry? getActivePaletteEntryById(String entryId) {
    final tilesetId = getSelectedTilesetEntry()?.id;
    if (tilesetId == null) return null;
    return getPaletteEntryById(tilesetId: tilesetId, entryId: entryId);
  }

  void setPaletteCategoryFilter(PaletteCategory? category) {
    state = state.copyWith(paletteCategoryFilter: category);
    _syncActivePaletteContext();
  }

  void selectPaletteTile(int tileId) {
    if (tileId <= 0) return;
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    if (!_canUsePaletteTileset(selectedTileset.id)) return;
    state = state.copyWith(
      activeBrush: EditorBrush.tile(
        tileId: tileId,
        tilesetId: selectedTileset.id,
      ),
      errorMessage: null,
    );
    _setActivePaletteSelectedTileset(selectedTileset.id);
  }

  void selectPaletteEntry(String entryId) {
    final selectedTileset =
        getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (selectedTileset == null) return;
    final entry =
        getPaletteEntryById(tilesetId: selectedTileset.id, entryId: entryId);
    if (entry == null) return;
    if (!_canUsePaletteTileset(selectedTileset.id)) return;
    state = state.copyWith(
      activeBrush: EditorBrush.paletteEntry(
        entryId: entry.id,
        tilesetId: selectedTileset.id,
      ),
      errorMessage: null,
    );
    _setActivePaletteSelectedTileset(selectedTileset.id);
  }

  void selectProjectElement(String elementId) {
    final element = getProjectElementById(elementId);
    if (element == null) return;
    if (!_canUsePaletteTileset(element.tilesetId)) return;
    state = state.copyWith(
      activeBrush: EditorBrush.projectElement(elementId: element.id),
      selectedTilesetElementGroupId: element.tilesetGroupId,
      selectedPlacedElementInstanceId: null,
      errorMessage: null,
    );
    _setActivePaletteSelectedTileset(element.tilesetId);
  }

  bool cancelProjectElementPlacement() {
    if (state.activeTool != EditorToolType.tilePaint ||
        state.activeBrush is! ProjectElementEditorBrush) {
      return false;
    }
    state = state.copyWith(activeBrush: const EditorBrush.none());
    return true;
  }

  Future<void> createPaletteEntry({
    required String name,
    required PaletteCategory category,
    required TilesetSourceRect source,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;

    try {
      final useCase = ref.read(createTilesetPaletteEntryUseCaseProvider);
      final result = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        name: name,
        category: category,
        source: source,
        recommendedLayerId: recommendedLayerId,
      );
      state = state.copyWith(
        project: result.project,
        activeBrush: EditorBrush.paletteEntry(
          entryId: result.entry.id,
          tilesetId: tileset.id,
        ),
        statusMessage: 'Palette element "${result.entry.name}" created',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error creating palette entry: $e');
      state = state.copyWith(errorMessage: 'Failed to create element: $e');
    }
  }

  Future<void> upsertPaletteEntryForTile({
    required int tileId,
    required int columns,
    required PaletteCategory category,
    String? recommendedLayerId,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    final tileset = getSelectedTilesetEntry() ?? getActiveTilesetEntry();
    if (fs == null || project == null || tileset == null) return;
    if (tileId <= 0 || columns <= 0) return;

    final sourceIndex = tileId - 1;
    final sourceX = sourceIndex % columns;
    final sourceY = sourceIndex ~/ columns;

    TilesetPaletteEntry? existing;
    for (final entry in tileset.paletteEntries) {
      final ps = entry.frames.primarySource;
      if (ps.width == 1 &&
          ps.height == 1 &&
          ps.x == sourceX &&
          ps.y == sourceY) {
        existing = entry;
        break;
      }
    }

    final rect = TilesetSourceRect(x: sourceX, y: sourceY);
    final entry = TilesetPaletteEntry(
      id: existing?.id ?? 'tile_$tileId',
      name: existing?.name.isNotEmpty == true ? existing!.name : 'tile_$tileId',
      category: category,
      frames: existing == null
          ? [TilesetVisualFrame(source: rect)]
          : [
              TilesetVisualFrame(source: rect),
              ...existing.frames.skip(1),
            ],
      recommendedLayerId: recommendedLayerId,
    );

    try {
      final useCase = ref.read(upsertTilesetPaletteEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tilesetId: tileset.id,
        entry: entry,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Palette entry updated',
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('EditorNotifier: Error updating palette entry: $e');
      state =
          state.copyWith(errorMessage: 'Failed to update palette entry: $e');
    }
  }

  Future<void> paintSelectedBrushAt(
    GridPos pos, {
    required Map<String, int> tilesetColumnsById,
    bool partOfStroke = false,
  }) async {
    if (state.activeBrush is ProjectElementEditorBrush) {
      if (partOfStroke) return;
      final preview = resolveSelectedProjectElementPlacementPreview(pos);
      if (preview == null) {
        _setPaintError('Selected project element is no longer available');
        return;
      }
      if (preview.validity == MapToolPreviewValidity.invalid) {
        _setPaintError(preview.reason ?? 'Element placement is invalid');
        return;
      }
      await placeSelectedProjectElementAt(pos);
      return;
    }
    final layerContext = _resolveActiveTileLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final resolvedBrush = _resolveActiveBrushPattern(
      tilesetColumnsById: tilesetColumnsById,
      emitErrors: true,
    );
    if (resolvedBrush == null) return;
    _paintPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      pattern: resolvedBrush.pattern,
      failureLabel: resolvedBrush.failureLabel,
    );
  }

  void paintCollisionAt(GridPos pos) {
    final layerContext = _resolveActiveCollisionLayerContext(emitErrors: true);
    if (layerContext == null) return;
    final footprint = _resolveCollisionFootprint(emitErrors: true);
    if (footprint == null) return;
    _paintCollisionPattern(
      map: layerContext.map,
      layerId: layerContext.layerId,
      pos: pos,
      patternSize: footprint.size,
      failureLabel: footprint.failureLabel,
    );
  }

  void paintActiveSmartTileAt(
    GridPos pos, {
    String? materialId,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final project = state.project;
    if (map == null || layerId == null || project == null) {
      _setPaintError('No active Smart Tile layer selected');
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! SmartTileLayer) {
      _setPaintError('Active layer is not a Smart Tile layer');
      return;
    }
    ProjectSmartTilePreset? preset;
    for (final candidate in project.smartTileCatalog.presets) {
      if (candidate.id == layer.presetId) {
        preset = candidate;
        break;
      }
    }
    if (preset == null) {
      _setPaintError('Smart Tile preset not found: ${layer.presetId}');
      return;
    }
    final resolvedMaterialId = materialId ?? preset.defaultMaterialId;
    if (!preset.allowedMaterialIds.contains(resolvedMaterialId)) {
      _setPaintError(
        'Smart Tile material is not allowed: $resolvedMaterialId',
      );
      return;
    }
    paintSmartTileMaterialAt(pos, materialId: resolvedMaterialId);
  }

  void paintSmartTileMaterialAt(
    GridPos pos, {
    required String? materialId,
  }) {
    _paintSmartTileMaterialCells(
      <GridPos>[pos],
      materialId: materialId,
      partOfStroke: true,
    );
  }

  /// Applies one previewed no-code shape as one canonical undo boundary.
  void applyActiveSmartTileSelection(
    SmartTileGestureSelection selection, {
    String? materialId,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final project = state.project;
    if (map == null || layerId == null || project == null) {
      _setPaintError('No active Smart Tile layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! SmartTileLayer) {
      _setPaintError('Active layer is not a Smart Tile layer');
      return;
    }
    ProjectSmartTilePreset? preset;
    for (final candidate in project.smartTileCatalog.presets) {
      if (candidate.id == activeLayer.presetId) {
        preset = candidate;
        break;
      }
    }
    if (preset == null) {
      _setPaintError('Smart Tile preset not found: ${activeLayer.presetId}');
      return;
    }
    final resolvedMaterialId = switch (state.activeTool) {
      EditorToolType.terrainPaint => materialId ?? preset.defaultMaterialId,
      EditorToolType.eraser => null,
      _ => null,
    };
    if (state.activeTool != EditorToolType.terrainPaint &&
        state.activeTool != EditorToolType.eraser) {
      _setPaintError(
          'Choose Smart Tile paint or erase before applying a shape');
      return;
    }
    if (resolvedMaterialId != null &&
        !preset.allowedMaterialIds.contains(resolvedMaterialId)) {
      _setPaintError(
        'Smart Tile material is not allowed: $resolvedMaterialId',
      );
      return;
    }
    try {
      final cells = compileSmartTileGestureSelection(
        activeLayer,
        mapSize: map.size,
        selection: selection,
      );
      _paintSmartTileMaterialCells(
        cells,
        materialId: resolvedMaterialId,
        partOfStroke: false,
        selection: selection,
      );
    } on SmartTileGestureLimitException catch (error) {
      _setPaintError(
        'La forme dépasse la limite de ${error.maximumCellCount} cellules.',
      );
    } catch (error) {
      _setPaintError('Impossible de préparer la forme Smart Tile : $error');
    }
  }

  void _paintSmartTileMaterialCells(
    Iterable<GridPos> cells, {
    required String? materialId,
    required bool partOfStroke,
    SmartTileGestureSelection? selection,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active Smart Tile layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! SmartTileLayer) {
      _setPaintError('Active layer is not a Smart Tile layer');
      return;
    }
    final selectedCells = cells.toSet().toList(growable: false);
    if (selectedCells.isEmpty) return;
    if (_smartTileCanonicalRecoveryRequired) {
      _setPaintError(editorReloadRequiredMessage);
      return;
    }
    if (state.projectRootPath != null &&
        state.isDirty &&
        !_canonicalSmartTileGestureOwnsDirtyMap) {
      _deferSmartTileGestureUntilSaved(
        mapId: map.id,
        layerId: layerId,
        materialId: materialId,
        cells: selectedCells,
        selection: selection,
      );
      return;
    }
    try {
      final paintedLayer = applySmartTileMaterialGesture(
        activeLayer,
        mapSize: map.size,
        cells: selectedCells,
        materialId: materialId,
      );
      if (paintedLayer == activeLayer) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      final updated = replaceSmartTileLayer(map, layer: paintedLayer);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: materialId == null || materialId.trim().isEmpty
            ? '${selectedCells.length} cellule(s) Smart Tile effacée(s)'
            : '${selectedCells.length} cellule(s) Smart Tile peinte(s)',
        partOfStroke: partOfStroke,
      );
      _recordSmartTileGesture(
        mapId: map.id,
        layerId: layerId,
        materialId: materialId,
        cells: selectedCells,
        commitImmediately: !partOfStroke || state.mapStrokeStart == null,
        selection: selection,
      );
    } catch (e) {
      _setPaintError('Failed to paint Smart Tile material: $e');
    }
  }

  void _deferSmartTileGestureUntilSaved({
    required String mapId,
    required String layerId,
    required String? materialId,
    required Iterable<GridPos> cells,
    SmartTileGestureSelection? selection,
  }) {
    final projectRootPath = state.projectRootPath;
    if (projectRootPath == null) return;
    final deferred = _deferredSmartTileGesture;
    if (deferred == null) {
      _deferredSmartTileGesture = DeferredSmartTileGesture(
        projectRootPath: projectRootPath,
        mapId: mapId,
        layerId: layerId,
        materialId: materialId,
        cells: cells,
        selection: selection,
      );
    } else if (deferred.targets(
      projectRootPath: projectRootPath,
      mapId: mapId,
      layerId: layerId,
      materialId: materialId,
    )) {
      deferred.merge(cells, selection: selection);
    } else {
      _setPaintError(
        'Terminez le tracé Smart Tile en cours avant d’en créer un autre.',
      );
      return;
    }
    state = state.copyWith(
      errorMessage: null,
      statusMessage: 'Enregistrement automatique avant d’appliquer le tracé…',
    );
    if (!_smartTileAutosaveInProgress) {
      unawaited(_saveAndReplayDeferredSmartTileGesture());
    }
  }

  Future<void> _saveAndReplayDeferredSmartTileGesture() async {
    final deferred = _deferredSmartTileGesture;
    if (deferred == null) return;
    _smartTileAutosaveInProgress = true;
    try {
      if (!await _flushSessionForCanonicalSmartTileMutation()) {
        _deferredSmartTileGesture = null;
        return;
      }
      if (state.projectRootPath != deferred.projectRootPath ||
          state.activeMap?.id != deferred.mapId ||
          state.activeLayerId != deferred.layerId) {
        _deferredSmartTileGesture = null;
        _setPaintError('Le tracé a été annulé car la carte active a changé.');
        return;
      }
      _deferredSmartTileGesture = null;
      _paintSmartTileMaterialCells(
        deferred.cells,
        materialId: deferred.materialId,
        partOfStroke: false,
        selection: deferred.selection,
      );
    } finally {
      _smartTileAutosaveInProgress = false;
      if (_deferredSmartTileGesture != null) {
        unawaited(_saveAndReplayDeferredSmartTileGesture());
      }
    }
  }

  void eraseAt(GridPos pos) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      _setPaintError('No active layer selected');
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      _setPaintError('Active layer not found: $layerId');
      return;
    }
    final eraserFootprint = _resolveEraserFootprint(emitErrors: true);
    if (eraserFootprint == null) return;
    _eraseLayerArea(
      map: map,
      layer: activeLayer,
      pos: pos,
      patternSize: eraserFootprint.size,
      failureLabel: eraserFootprint.failureLabel,
      partOfStroke: true,
    );
  }

  /// Erases exactly one cell from an explicit compatible layer.
  ///
  /// Context actions use this command instead of [eraseAt], so the current
  /// eraser footprint and active layer cannot widen or redirect the edit.
  bool eraseCellAt({
    required String layerId,
    required GridPos pos,
  }) {
    final map = state.activeMap;
    if (map == null ||
        pos.x < 0 ||
        pos.y < 0 ||
        pos.x >= map.size.width ||
        pos.y >= map.size.height) {
      return false;
    }
    final layer = _findLayerById(map, layerId);
    if (layer == null ||
        layer is! TileLayer &&
            layer is! CollisionLayer &&
            layer is! SmartTileLayer) {
      return false;
    }
    return _eraseLayerArea(
      map: map,
      layer: layer,
      pos: pos,
      patternSize: const GridSize(width: 1, height: 1),
      failureLabel: 'cell',
      partOfStroke: false,
    );
  }

  bool _eraseLayerArea({
    required MapData map,
    required MapLayer layer,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
    required bool partOfStroke,
  }) {
    final layerId = layer.id;
    if (layer is TileLayer) {
      _erasePattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        failureLabel: failureLabel,
        partOfStroke: partOfStroke,
      );
    } else if (layer is CollisionLayer) {
      _eraseCollisionPattern(
        map: map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        failureLabel: failureLabel,
        partOfStroke: partOfStroke,
      );
    } else if (layer is SmartTileLayer) {
      try {
        final erasedCells = <GridPos>[];
        for (var y = 0; y < patternSize.height; y++) {
          for (var x = 0; x < patternSize.width; x++) {
            final targetX = pos.x + x;
            final targetY = pos.y + y;
            if (targetX < 0 ||
                targetY < 0 ||
                targetX >= map.size.width ||
                targetY >= map.size.height) {
              continue;
            }
            final hasAuthoredValue = smartTileCellHasAuthoredValue(
              layer,
              mapSize: map.size,
              x: targetX,
              y: targetY,
            );
            if (!hasAuthoredValue) continue;
            erasedCells.add(GridPos(x: targetX, y: targetY));
          }
        }
        if (erasedCells.isEmpty) {
          state = state.copyWith(errorMessage: null);
          return false;
        }
        if (_smartTileCanonicalRecoveryRequired) {
          _setPaintError(editorReloadRequiredMessage);
          return false;
        }
        if (state.projectRootPath != null &&
            state.isDirty &&
            !_canonicalSmartTileGestureOwnsDirtyMap) {
          _deferSmartTileGestureUntilSaved(
            mapId: map.id,
            layerId: layerId,
            materialId: null,
            cells: erasedCells,
          );
          return true;
        }
        final erasedLayer = applySmartTileMaterialGesture(
          layer,
          mapSize: map.size,
          cells: erasedCells,
          materialId: null,
        );
        if (erasedLayer == layer) {
          state = state.copyWith(errorMessage: null);
          return false;
        }
        final updated = replaceSmartTileLayer(map, layer: erasedLayer);
        MapValidator.validate(
          updated,
          projectDialogueContext: state.project,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: layerId,
          statusMessage: 'Smart Tile cells erased',
          partOfStroke: partOfStroke,
        );
        _recordSmartTileGesture(
          mapId: map.id,
          layerId: layerId,
          materialId: null,
          cells: erasedCells,
          commitImmediately: !partOfStroke,
        );
      } catch (e) {
        _setPaintError('Failed to erase Smart Tile material: $e');
      }
    } else {
      _setPaintError('Active layer "${layer.name}" is not editable');
      return false;
    }
    final updatedMap = state.activeMap;
    return updatedMap != null &&
        !identical(updatedMap, map) &&
        updatedMap != map;
  }

  MapWarp? getSelectedWarp() {
    return _warpEditingService.findSelectedWarp(
      state.activeMap,
      state.selectedWarpId,
    );
  }

  MapConnection? getMapConnection(MapConnectionDirection direction) {
    return _mapConnectionEditingService.findConnection(
      state.activeMap,
      direction,
    );
  }

  MapEntity? getSelectedEntity() {
    return _entityEditingService.findSelectedEntity(
      state.activeMap,
      state.selectedEntityId,
    );
  }

  MapTrigger? getSelectedTrigger() {
    return _triggerEditingService.findSelectedTrigger(
      state.activeMap,
      state.selectedTriggerId,
    );
  }

  MapEventDefinition? getSelectedMapEvent() {
    final map = state.activeMap;
    final selectedMapEventId = state.selectedMapEventId;
    if (map == null || selectedMapEventId == null) {
      return null;
    }
    return findMapEventById(map, selectedMapEventId);
  }

  void placeOrSelectMapEventAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = findMapEventAtPos(
      map,
      pos.x,
      pos.y,
      preferredLayerId: state.activeLayerId,
    );
    if (existing != null) {
      selectMapEvent(existing.id);
      return;
    }
    addMapEventAt(pos);
  }

  void addMapEventAt(GridPos pos) {
    if (_rejectLegacyMapEventMutationInV2Only()) return;
    final map = state.activeMap;
    if (map == null) return;
    final layerId = _resolveEventPlacementLayerId(map);
    if (layerId == null) {
      state = state.copyWith(
        errorMessage: 'No layer available to place a map event',
      );
      return;
    }
    final eventId = _generateUniqueMapEventId(map);
    final created = MapEventDefinition(
      id: eventId,
      title: eventId,
      position: EventPosition(layerId: layerId, x: pos.x, y: pos.y),
      pages: const [
        MapEventPage(
          pageNumber: 0,
          message: '',
        ),
      ],
    );
    try {
      final updated = addMapEventToMap(map, event: created);
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: created.id,
        statusMessage: 'Event "${created.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create event: $e');
    }
  }

  MapEventDefinition? createEventBuilderDraftEventAt({
    required EventPosition position,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return null;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour créer un brouillon d’événement.',
      );
      return null;
    }
    final layerId = position.layerId.trim();
    if (layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Couche de destination obligatoire pour l’événement.',
      );
      return null;
    }
    final layer = _findLayerById(map, layerId);
    if (layer == null) {
      state = state.copyWith(
        errorMessage:
            'Couche de destination introuvable pour l’événement : $layerId',
      );
      return null;
    }
    if (layer is! ObjectLayer) {
      state = state.copyWith(
        errorMessage: 'La couche de destination doit être une couche d’objets.',
      );
      return null;
    }

    try {
      final result = createEventBuilderDraftEventOnMap(
        map,
        title: 'Nouvel événement',
        position: position,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: result.createdEvent.id,
        statusMessage: 'Événement créé',
      );
      return result.createdEvent;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer l’événement : $e',
      );
      return null;
    }
  }

  String? ensureEventBuilderObjectLayer() {
    if (_rejectLegacyMapEventMutationInV2Only()) return null;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour préparer la couche d’événements.',
      );
      return null;
    }

    for (final layer in map.layers) {
      if (layer is ObjectLayer) {
        state = state.copyWith(
          activeLayerId: layer.id,
          statusMessage: 'Couche d’événements prête',
          errorMessage: null,
        );
        return layer.id;
      }
    }

    try {
      final result = ref.read(addMapLayerUseCaseProvider).execute(
            map,
            kind: MapLayerKind.object,
            name: 'Événements',
          );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Couche d’événements créée',
      );
      return result.layer.id;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer la couche d’événements : $e',
      );
      return null;
    }
  }

  bool renameEventBuilderEventTitle({
    required String eventId,
    required String title,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour renommer l’événement.',
      );
      return false;
    }
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: 'Titre d’événement obligatoire.');
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.title.trim() == trimmedTitle) {
      return true;
    }

    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        title: trimmedTitle,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Événement renommé',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de renommer l’événement : $e',
      );
      return false;
    }
  }

  bool updateEventBuilderTriggerType({
    required String eventId,
    required MapEventType type,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Aucune map active pour modifier le déclencheur.',
      );
      return false;
    }
    // NS-EVENT-15 exposes only the MVP trigger grammar. MapEventType.effect is
    // intentionally kept out of authoring because it mixes visual/effect intent
    // with event launch semantics for no-code users.
    if (!_isEventBuilderAuthorableTriggerType(type)) {
      state = state.copyWith(
        errorMessage: 'Ce type de déclencheur n’est pas éditable dans ce lot.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.type == type) {
      return true;
    }

    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        type: type,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Déclencheur d’événement mis à jour',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de modifier le déclencheur : $e',
      );
      return false;
    }
  }

  bool updateEventBuilderEventSceneAction({
    required String eventId,
    required String sceneId,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier la scène de l’événement.',
      );
      return false;
    }
    final project = state.project;
    if (project == null) {
      state = state.copyWith(
        errorMessage: 'Aucun projet actif pour choisir une scène.',
      );
      return false;
    }
    final trimmedSceneId = sceneId.trim();
    if (trimmedSceneId.isEmpty) {
      state = state.copyWith(errorMessage: 'Scène d’événement obligatoire.');
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }
    final sceneExists =
        project.scenes.any((scene) => scene.id == trimmedSceneId);
    if (!sceneExists) {
      state = state.copyWith(
        errorMessage: 'Scène introuvable : $trimmedSceneId',
      );
      return false;
    }

    // NS-EVENT-11 reste aligné avec le read model Event Builder : on écrit
    // uniquement la page authorable canonique, sans créer de page implicite.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    try {
      final updated = setMapEventPageSceneTarget(
        map,
        eventId: eventId,
        pageNumber: pageNumber,
        sceneId: trimmedSceneId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Scène d’événement mise à jour',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de mettre à jour la scène de l’événement : $e',
      );
      return false;
    }
  }

  bool updateEventBuilderEventReusePolicy({
    required String eventId,
    required EventBuilderReusePolicy reusePolicy,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier le comportement de l’événement.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    // NS-EVENT-12 édite uniquement les metadata Event Builder de la page
    // canonique. Les champs sceneTarget/condition/script/message restent
    // volontairement sous la responsabilité des lots dédiés.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final pageIndex =
        event.pages.indexWhere((page) => page.pageNumber == pageNumber);
    final page = event.pages[pageIndex];
    final nextMetadata = Map<String, String>.unmodifiable({
      ...page.metadata,
      EventBuilderMetadataKeys.schemaVersion:
          EventBuilderMetadataKeys.currentSchemaVersion,
      EventBuilderMetadataKeys.reusePolicy: reusePolicy.name,
    });
    try {
      final updated = updatePageOnMapEvent(
        map,
        eventId: eventId,
        pageIndex: pageIndex,
        metadata: nextMetadata,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Comportement d’événement mis à jour',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de mettre à jour le comportement de l’événement : $e',
      );
      return false;
    }
  }

  bool addEventBuilderFactCondition({
    required String eventId,
    required String factId,
    required bool expectedValue,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier les conditions de l’événement.',
      );
      return false;
    }
    final project = state.project;
    if (project == null) {
      state = state.copyWith(
        errorMessage: 'Aucun projet actif pour choisir un Fact.',
      );
      return false;
    }
    final trimmedFactId = factId.trim();
    if (trimmedFactId.isEmpty) {
      state = state.copyWith(errorMessage: 'Fact obligatoire.');
      return false;
    }
    final factExists = project.facts.any((fact) => fact.id == trimmedFactId);
    if (!factExists) {
      state = state.copyWith(
        errorMessage: 'Fact introuvable : $trimmedFactId',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    // NS-EVENT-13 ne compile que Fact vrai/faux. Le contrat core garde le
    // garde-fou legacyConditionToPreserve pour empêcher toute perte silencieuse
    // de conditions avancées.
    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final contract = readEventBuilderContractFromMapEvent(
      event,
      pageNumber: pageNumber,
    );
    if (contract.legacyConditionToPreserve != null) {
      state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
      return false;
    }
    final condition = expectedValue
        ? EventBuilderConditionBinding.factIsTrue(trimmedFactId)
        : EventBuilderConditionBinding.factIsFalse(trimmedFactId);

    try {
      final updatedContract = addEventBuilderCondition(contract, condition);
      final updated = _updateEventBuilderPageCondition(
        map: map,
        event: event,
        pageNumber: pageNumber,
        conditions: updatedContract.conditions,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Condition d’événement ajoutée',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter la condition d’événement : $e',
      );
      return false;
    }
  }

  bool addEventBuilderEventConsumedCondition({
    required String eventId,
    required String targetEventId,
    required bool expectedConsumed,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier les conditions de l’événement.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final contract = readEventBuilderContractFromMapEvent(
      event,
      pageNumber: pageNumber,
    );
    if (contract.legacyConditionToPreserve != null) {
      state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
      return false;
    }

    final trimmedTargetEventId = targetEventId.trim();
    if (trimmedTargetEventId.isEmpty) {
      state = state.copyWith(errorMessage: 'Événement cible obligatoire.');
      return false;
    }
    // NS-EVENT-14 exclut volontairement l'auto-cible : en V0, une condition
    // "cet événement est déjà consommé" sur l'événement lui-même est trop
    // ambiguë pour une expérience no-code guidée.
    if (trimmedTargetEventId == eventId) {
      state = state.copyWith(
        errorMessage:
            'Un événement ne peut pas se cibler lui-même dans ce lot.',
      );
      return false;
    }
    final targetEvent = findMapEventById(map, trimmedTargetEventId);
    if (targetEvent == null) {
      state = state.copyWith(
        errorMessage: 'Événement cible introuvable : $trimmedTargetEventId',
      );
      return false;
    }
    final condition = expectedConsumed
        ? EventBuilderConditionBinding.eventConsumed(trimmedTargetEventId)
        : EventBuilderConditionBinding.eventNotConsumed(trimmedTargetEventId);

    try {
      final updatedContract = addEventBuilderCondition(contract, condition);
      final updated = _updateEventBuilderPageCondition(
        map: map,
        event: event,
        pageNumber: pageNumber,
        conditions: updatedContract.conditions,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Condition d’événement ajoutée',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter la condition d’événement : $e',
      );
      return false;
    }
  }

  bool removeEventBuilderConditionAt({
    required String eventId,
    required int conditionIndex,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return false;
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage:
            'Aucune map active pour modifier les conditions de l’événement.',
      );
      return false;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Événement introuvable : $eventId');
      return false;
    }
    if (event.pages.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Cet événement ne contient aucune page authorable.',
      );
      return false;
    }

    final pageNumber = _eventBuilderAuthorablePageNumber(event);
    final contract = readEventBuilderContractFromMapEvent(
      event,
      pageNumber: pageNumber,
    );
    if (contract.legacyConditionToPreserve != null) {
      state = state.copyWith(errorMessage: _eventBuilderConditionLockedMessage);
      return false;
    }
    if (conditionIndex < 0 || conditionIndex >= contract.conditions.length) {
      state = state.copyWith(
        errorMessage: 'Condition introuvable : $conditionIndex',
      );
      return false;
    }
    final condition = contract.conditions[conditionIndex];
    if (!_isEventBuilderEditableConditionKind(condition.kind)) {
      state = state.copyWith(
        errorMessage:
            'Seules les conditions Fact ou Événement sont éditables dans ce lot.',
      );
      return false;
    }

    try {
      final updatedContract =
          removeEventBuilderCondition(contract, conditionIndex);
      final updated = _updateEventBuilderPageCondition(
        map: map,
        event: event,
        pageNumber: pageNumber,
        conditions: updatedContract.conditions,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: eventId,
        statusMessage: 'Condition d’événement retirée',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de retirer la condition d’événement : $e',
      );
      return false;
    }
  }

  void selectMapEvent(String? eventId) {
    final map = state.activeMap;
    if (map == null) return;
    if (eventId == null) {
      state = state.copyWith(
        selectedMapEventId: null,
        errorMessage: null,
      );
      return;
    }
    final event = findMapEventById(map, eventId);
    if (event == null) {
      state = state.copyWith(errorMessage: 'Event not found: $eventId');
      return;
    }
    state = state.copyWith(
      selectedMapEventId: event.id,
      errorMessage: null,
    );
  }

  /// Selects the visually uppermost authored object at [position].
  ///
  /// Repeated clicks cycle through the same deterministic hit stack. This path
  /// never calls placement commands and therefore cannot create map content.
  MapCanvasObjectTarget? selectCanvasObjectAt(
    GridPos position, {
    int editorAnimationTimeMs = 0,
  }) {
    final map = state.activeMap;
    if (map == null) return null;

    const hitTest = MapCanvasObjectHitTest();
    final hits = hitTest.hitStack(
      map: map,
      project: state.project,
      position: position,
      editorAnimationTimeMs: editorAnimationTimeMs,
    );
    final repeatsSameStack = _lastCanvasObjectSelectionMapId == map.id &&
        _lastCanvasObjectSelectionPosition == position &&
        _sameCanvasObjectHitStack(_lastCanvasObjectSelectionHits, hits) &&
        _lastCanvasObjectSelectionTarget != null &&
        _isCanvasObjectTargetSelected(_lastCanvasObjectSelectionTarget!);
    final target = repeatsSameStack
        ? hitTest.cycleTarget(
            hits: hits,
            current: _lastCanvasObjectSelectionTarget,
          )
        : hits.isEmpty
            ? null
            : hits.first;
    _lastCanvasObjectSelectionMapId = map.id;
    _lastCanvasObjectSelectionPosition = position;
    _lastCanvasObjectSelectionHits =
        List<MapCanvasObjectTarget>.unmodifiable(hits);
    _lastCanvasObjectSelectionTarget = target;
    _selectCanvasObjectTarget(target);
    return target;
  }

  /// Resolves a direct-manipulation drag target without advancing the
  /// repeated-click selection cycle.
  ///
  /// If an object in the hit stack is already selected, that exact object
  /// keeps ownership of the drag. Otherwise the visually uppermost hit wins.
  MapCanvasObjectTarget? selectCanvasObjectForDragAt(
    GridPos position, {
    int editorAnimationTimeMs = 0,
  }) {
    final map = state.activeMap;
    if (map == null) return null;

    const hitTest = MapCanvasObjectHitTest();
    final hits = hitTest.hitStack(
      map: map,
      project: state.project,
      position: position,
      editorAnimationTimeMs: editorAnimationTimeMs,
    );
    MapCanvasObjectTarget? target;
    for (final hit in hits) {
      if (_isCanvasObjectTargetSelected(hit)) {
        target = hit;
        break;
      }
    }
    if (target == null && hits.isNotEmpty) {
      target = hits.first;
    }
    _resetCanvasObjectSelectionCycle();
    _selectCanvasObjectTarget(target);
    return target;
  }

  /// Applies one exact object selection without invoking overlap cycling.
  void selectCanvasObjectTarget(MapCanvasObjectTarget? target) {
    _resetCanvasObjectSelectionCycle();
    _selectCanvasObjectTarget(target);
  }

  /// Commits one direct-manipulation move as one map-history transaction.
  ///
  /// The immutable [sourceMap] snapshot prevents a stale drag from overwriting
  /// any map mutation that happened after pointer-down.
  bool commitCanvasObjectMove({
    required MapData sourceMap,
    required MapCanvasObjectTarget target,
    required GridPos destinationAnchor,
  }) {
    final map = state.activeMap;
    if (map == null || !identical(map, sourceMap)) {
      state = state.copyWith(
        errorMessage:
            'Déplacement annulé : la carte a changé pendant le glisser.',
      );
      return false;
    }
    if (target.kind == MapCanvasObjectKind.mapEvent &&
        _rejectLegacyMapEventMutationInV2Only()) {
      return false;
    }

    const planner = MapCanvasObjectMovePlanner();
    final plan = planner.plan(
      map: map,
      project: state.project,
      target: target,
      destinationAnchor: destinationAnchor,
    );
    if (!plan.canCommit) {
      if (!plan.isNoOp) {
        state = state.copyWith(
          errorMessage: _canvasObjectMoveRejectionMessage(plan.rejection),
        );
      }
      return false;
    }
    final candidate = plan.candidateMap!;

    String? eventRevalidationMessage;
    if (target.kind == MapCanvasObjectKind.entity) {
      final current =
          map.entities.where((entry) => entry.id == target.id).firstOrNull;
      final next = candidate.entities
          .where((entry) => entry.id == target.id)
          .firstOrNull;
      if (current == null || next == null) {
        state = state.copyWith(
          errorMessage: 'Déplacement annulé : entité introuvable.',
        );
        return false;
      }
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectEntityUpdate(
        registry: state.project?.eventRegistry,
        mapId: map.id,
        current: current,
        next: next,
      );
      if (!dependencyDecision.isAllowed) {
        state = state.copyWith(errorMessage: dependencyDecision.message);
        return false;
      }
      eventRevalidationMessage = dependencyDecision.revalidationMessage;
    } else if (target.kind == MapCanvasObjectKind.trigger) {
      final current =
          map.triggers.where((entry) => entry.id == target.id).firstOrNull;
      final next = candidate.triggers
          .where((entry) => entry.id == target.id)
          .firstOrNull;
      if (current == null || next == null) {
        state = state.copyWith(
          errorMessage: 'Déplacement annulé : déclencheur introuvable.',
        );
        return false;
      }
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectTriggerUpdate(
        registry: state.project?.eventRegistry,
        mapId: map.id,
        current: current,
        next: next,
      );
      if (!dependencyDecision.isAllowed) {
        state = state.copyWith(errorMessage: dependencyDecision.message);
        return false;
      }
      eventRevalidationMessage = dependencyDecision.revalidationMessage;
    }

    try {
      MapValidator.validate(
        candidate,
        projectDialogueContext: state.project,
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Déplacement impossible : $error',
      );
      return false;
    }

    final previewTarget = plan.previewTarget!;
    _applyMapMutation(
      previousMap: map,
      updatedMap: candidate,
      preferredActiveLayerId: previewTarget.layerId ?? state.activeLayerId,
      preferredSelectedEntityId:
          target.kind == MapCanvasObjectKind.entity ? target.id : null,
      preferredSelectedMapEventId:
          target.kind == MapCanvasObjectKind.mapEvent ? target.id : null,
      preferredSelectedWarpId:
          target.kind == MapCanvasObjectKind.warp ? target.id : null,
      preferredSelectedTriggerId:
          target.kind == MapCanvasObjectKind.trigger ? target.id : null,
      statusMessage: '${_canvasObjectKindLabel(target.kind)} '
          '« ${target.id} » déplacé en '
          '(${destinationAnchor.x}, ${destinationAnchor.y})',
    );
    final committed = identical(state.activeMap, candidate);
    if (committed && eventRevalidationMessage != null) {
      state = state.copyWith(statusMessage: eventRevalidationMessage);
    }
    return committed;
  }

  String _canvasObjectMoveRejectionMessage(
    MapCanvasObjectMoveRejection? rejection,
  ) {
    return switch (rejection) {
      MapCanvasObjectMoveRejection.targetNotFound =>
        'Déplacement impossible : l’objet est introuvable.',
      MapCanvasObjectMoveRejection.boundsUnavailable =>
        'Déplacement impossible : l’empreinte de l’élément est inconnue.',
      MapCanvasObjectMoveRejection.sourceOutOfBounds =>
        'Déplacement impossible : la position actuelle est hors carte.',
      MapCanvasObjectMoveRejection.destinationOutOfBounds =>
        'Déplacement impossible : la destination dépasse la carte.',
      MapCanvasObjectMoveRejection.environmentGeneratedPlacement =>
        'Cet élément est généré par une zone Environment. '
            'Modifiez ou régénérez cette zone pour le déplacer.',
      MapCanvasObjectMoveRejection.tileIndexedSourceInvalid =>
        'Déplacement impossible : la projection de tuiles source '
            'n’est plus cohérente.',
      MapCanvasObjectMoveRejection.tileIndexedDestinationOccupied =>
        'Déplacement impossible : des tuiles occupent déjà la destination.',
      MapCanvasObjectMoveRejection.tileIndexedProjectionInvalid =>
        'Déplacement impossible : la projection de tuiles obtenue '
            'n’est pas valide.',
      null => 'Déplacement impossible.',
    };
  }

  bool _sameCanvasObjectHitStack(
    List<MapCanvasObjectTarget> previous,
    List<MapCanvasObjectTarget> next,
  ) {
    if (previous.length != next.length) {
      return false;
    }
    for (var index = 0; index < previous.length; index += 1) {
      if (!previous[index].sameIdentity(next[index])) {
        return false;
      }
    }
    return true;
  }

  void _resetCanvasObjectSelectionCycle() {
    _lastCanvasObjectSelectionMapId = null;
    _lastCanvasObjectSelectionPosition = null;
    _lastCanvasObjectSelectionHits = const <MapCanvasObjectTarget>[];
    _lastCanvasObjectSelectionTarget = null;
  }

  bool _isCanvasObjectTargetSelected(MapCanvasObjectTarget target) {
    return switch (target.kind) {
      MapCanvasObjectKind.placedElement =>
        state.selectedPlacedElementInstanceId == target.id,
      MapCanvasObjectKind.entity => state.selectedEntityId == target.id,
      MapCanvasObjectKind.mapEvent => state.selectedMapEventId == target.id,
      MapCanvasObjectKind.gameplayZone =>
        state.selectedGameplayZoneId == target.id,
      MapCanvasObjectKind.trigger => state.selectedTriggerId == target.id,
      MapCanvasObjectKind.warp => state.selectedWarpId == target.id,
    };
  }

  void _selectCanvasObjectTarget(MapCanvasObjectTarget? target) {
    final map = state.activeMap;
    if (map == null) return;

    var activeLayerId = state.activeLayerId;
    final targetLayerId = target?.layerId;
    if (targetLayerId != null &&
        map.layers.any((layer) => layer.id == targetLayerId)) {
      activeLayerId = targetLayerId;
    }

    var selectedEntityKind = state.selectedEntityKind;
    if (target?.kind == MapCanvasObjectKind.entity) {
      MapEntity? entity;
      for (final candidate in map.entities) {
        if (candidate.id == target!.id) {
          entity = candidate;
          break;
        }
      }
      if (entity != null) {
        selectedEntityKind = entity.kind;
      }
    }

    _suppressBorderSelectionReconciliation = true;
    try {
      state = state.copyWith(
        activeLayerId: activeLayerId,
        selectedPlacedElementInstanceId:
            target?.kind == MapCanvasObjectKind.placedElement
                ? target?.id
                : null,
        selectedEntityId:
            target?.kind == MapCanvasObjectKind.entity ? target?.id : null,
        selectedMapEventId:
            target?.kind == MapCanvasObjectKind.mapEvent ? target?.id : null,
        selectedGameplayZoneId: target?.kind == MapCanvasObjectKind.gameplayZone
            ? target?.id
            : null,
        selectedTriggerId:
            target?.kind == MapCanvasObjectKind.trigger ? target?.id : null,
        selectedWarpId:
            target?.kind == MapCanvasObjectKind.warp ? target?.id : null,
        selectedEntityKind: selectedEntityKind,
        selectedEnvironmentAreaId: null,
        npcWaypointPlacementEntityId: null,
        statusMessage: target == null
            ? 'Sélection effacée'
            : '${_canvasObjectKindLabel(target.kind)} « ${target.id} » '
                'sélectionné en (${target.anchor.x}, ${target.anchor.y})',
        errorMessage: null,
      );
    } finally {
      _suppressBorderSelectionReconciliation = false;
    }
    ref.read(activeBorderFeatureControllerProvider.notifier).clear();
    _coerceActiveToolIfIncompatibleWithLayer();
  }

  String _canvasObjectKindLabel(MapCanvasObjectKind kind) {
    return switch (kind) {
      MapCanvasObjectKind.placedElement => 'Élément',
      MapCanvasObjectKind.entity => 'Entité',
      MapCanvasObjectKind.mapEvent => 'Événement',
      MapCanvasObjectKind.gameplayZone => 'Zone',
      MapCanvasObjectKind.trigger => 'Déclencheur',
      MapCanvasObjectKind.warp => 'Téléporteur',
    };
  }

  void updateSelectedMapEvent({
    required String id,
    required String title,
    required MapEventType type,
    required String layerId,
    required int x,
    required int y,
    required List<MapEventPage> pages,
  }) {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    updateMapEvent(
      eventId: selectedMapEventId,
      id: id,
      title: title,
      type: type,
      position: EventPosition(layerId: layerId, x: x, y: y),
      pages: pages,
    );
  }

  void updateMapEvent({
    required String eventId,
    String? id,
    String? title,
    MapEventType? type,
    EventPosition? position,
    List<MapEventPage>? pages,
  }) {
    if (_rejectLegacyMapEventMutationInV2Only()) return;
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = updateMapEventOnMap(
        map,
        eventId: eventId,
        id: id,
        title: title,
        type: type,
        position: position,
        pages: pages,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId:
            id?.trim().isNotEmpty == true ? id!.trim() : eventId,
        statusMessage: 'Event updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update event: $e');
    }
  }

  void deleteSelectedMapEvent() {
    final selectedMapEventId = state.selectedMapEventId;
    if (selectedMapEventId == null) return;
    deleteMapEvent(selectedMapEventId);
  }

  void deleteMapEvent(String eventId) {
    if (_rejectLegacyMapEventMutationInV2Only()) return;
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = removeMapEventFromMap(
        map,
        eventId: eventId,
      );
      MapValidator.validate(
        updated,
        projectDialogueContext: state.project,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedMapEventId: state.selectedMapEventId == eventId
            ? null
            : state.selectedMapEventId,
        statusMessage: 'Event deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete event: $e');
    }
  }

  void placeOrSelectEntityAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _entityEditingService.findEntityAtPos(map, pos);
    if (existing != null) {
      selectEntity(existing.id);
      return;
    }
    addEntityAt(
      pos,
      kind: state.selectedEntityKind,
    );
  }

  void addEntityAt(
    GridPos pos, {
    required MapEntityKind kind,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _entityEditingService.addEntityAt(
        map,
        pos,
        kind: kind,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.createdEntity.id,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity "${result.createdEntity.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create entity: $e');
    }
  }

  void selectEntity(String? entityId) {
    final map = state.activeMap;
    if (map == null) return;
    if (entityId == null) {
      state = state.copyWith(
        selectedEntityId: null,
        npcWaypointPlacementEntityId: null,
        errorMessage: null,
      );
      return;
    }
    final entity = _entityEditingService.findSelectedEntity(map, entityId);
    if (entity == null) {
      state = state.copyWith(errorMessage: 'Entity not found: $entityId');
      return;
    }
    state = state.copyWith(
      selectedEntityId: entity.id,
      selectedEntityKind: entity.kind,
      npcWaypointPlacementEntityId:
          state.npcWaypointPlacementEntityId == entity.id
              ? state.npcWaypointPlacementEntityId
              : null,
      errorMessage: null,
    );
  }

  /// Active le mode "placement waypoint" sur l'entité NPC sélectionnée.
  ///
  /// Ce mode est volontairement porté par l'état éditeur (et non local panel),
  /// afin que le canvas puisse router le clic map de manière explicite.
  bool startNpcWaypointPlacementForSelectedEntity() {
    final map = state.activeMap;
    final selectedEntityId = state.selectedEntityId;
    if (map == null || selectedEntityId == null || selectedEntityId.isEmpty) {
      return false;
    }
    final entity =
        _entityEditingService.findSelectedEntity(map, selectedEntityId);
    if (entity == null || entity.kind != MapEntityKind.npc) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires a selected NPC.',
      );
      return false;
    }
    final movement = entity.npc?.movement ?? const MapEntityNpcMovementConfig();
    if (movement.mode != MapEntityNpcMovementMode.patrol) {
      state = state.copyWith(
        npcWaypointPlacementEntityId: null,
        errorMessage: 'Waypoint placement requires NPC movement mode "patrol".',
      );
      return false;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage: 'Waypoint placement enabled for "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  /// Désactive explicitement le mode placement waypoint.
  void cancelNpcWaypointPlacement({String? statusMessage}) {
    if (state.npcWaypointPlacementEntityId == null) {
      return;
    }
    state = state.copyWith(
      npcWaypointPlacementEntityId: null,
      statusMessage: statusMessage ?? 'Waypoint placement disabled',
      errorMessage: null,
    );
  }

  /// Traite un clic map en mode placement waypoint.
  ///
  /// Retourne `true` si le clic a été consommé par ce mode.
  /// Retourne `false` si aucun mode placement actif (ou session invalide).
  bool addNpcWaypointAt(GridPos position) {
    final placementEntityId = state.npcWaypointPlacementEntityId;
    if (placementEntityId == null || placementEntityId.trim().isEmpty) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) {
      cancelNpcWaypointPlacement(statusMessage: 'Waypoint placement cancelled');
      return false;
    }
    final entity = _entityEditingService.findSelectedEntity(
      map,
      placementEntityId,
    );
    if (entity == null || entity.kind != MapEntityKind.npc) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC no longer valid)',
      );
      return false;
    }
    final npc = entity.npc ?? const MapEntityNpcData();
    if (npc.movement.mode != MapEntityNpcMovementMode.patrol) {
      cancelNpcWaypointPlacement(
        statusMessage: 'Waypoint placement cancelled (NPC not in patrol mode)',
      );
      return false;
    }

    final nextWaypoints = <GridPos>[
      ...npc.movement.waypoints,
      position,
    ];
    final nextNpc = npc.copyWith(
      movement: npc.movement.copyWith(waypoints: nextWaypoints),
    );
    updateEntity(
      entityId: entity.id,
      npc: nextNpc,
    );
    state = state.copyWith(
      npcWaypointPlacementEntityId: entity.id,
      statusMessage:
          'Waypoint (${position.x}, ${position.y}) added to "${entity.id}"',
      errorMessage: null,
    );
    return true;
  }

  void selectEntityKind(MapEntityKind kind) {
    state = _mapSelectionController.selectEntityKind(
      current: state,
      kind: kind,
    );
  }

  void updateSelectedEntity({
    required String id,
    required String name,
    required MapEntityKind kind,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
    required bool blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    updateEntity(
      entityId: selectedEntityId,
      id: id,
      name: name,
      kind: kind,
      pos: GridPos(x: x, y: y),
      size: GridSize(width: width, height: height),
      properties: properties,
      blocksMovement: blocksMovement,
      npc: npc,
      sign: sign,
      item: item,
      spawn: spawn,
      editorVisual: editorVisual,
    );
  }

  void updateEntity({
    required String entityId,
    String? id,
    String? name,
    MapEntityKind? kind,
    GridPos? pos,
    GridSize? size,
    Map<String, String>? properties,
    bool? blocksMovement,
    MapEntityNpcData? npc,
    MapEntitySignData? sign,
    MapEntityItemData? item,
    MapEntitySpawnData? spawn,
    MapEntityEditorVisual? editorVisual,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      String? eventRevalidationMessage;
      final current = _entityEditingService.findSelectedEntity(map, entityId);
      if (current != null) {
        final dependencyDecision =
            _narrativeEventSourceDependencyGuard.inspectEntityUpdate(
          registry: state.project?.eventRegistry,
          mapId: map.id,
          current: current,
          next: current.copyWith(
            id: id ?? current.id,
            name: name ?? current.name,
            kind: kind ?? current.kind,
            pos: pos ?? current.pos,
            size: size ?? current.size,
            properties: properties ?? current.properties,
            blocksMovement: blocksMovement ?? current.blocksMovement,
            npc: npc ?? current.npc,
            sign: sign ?? current.sign,
            item: item ?? current.item,
            spawn: spawn ?? current.spawn,
            editorVisual: editorVisual ?? current.editorVisual,
          ),
        );
        if (!dependencyDecision.isAllowed) {
          state = state.copyWith(errorMessage: dependencyDecision.message);
          return;
        }
        eventRevalidationMessage = dependencyDecision.revalidationMessage;
      }
      final result = _entityEditingService.updateEntity(
        map,
        entityId: entityId,
        id: id,
        name: name,
        kind: kind,
        pos: pos,
        size: size,
        properties: properties,
        blocksMovement: blocksMovement,
        npc: npc,
        sign: sign,
        item: item,
        spawn: spawn,
        editorVisual: editorVisual,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId: result.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity updated',
      );
      if (kind != null && kind != state.selectedEntityKind) {
        state = state.copyWith(selectedEntityKind: kind);
      }
      if (eventRevalidationMessage != null) {
        state = state.copyWith(statusMessage: eventRevalidationMessage);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update entity: $e');
    }
  }

  void deleteSelectedEntity() {
    final selectedEntityId = state.selectedEntityId;
    if (selectedEntityId == null) return;
    deleteEntity(selectedEntityId);
  }

  void deleteEntity(String entityId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectEntityDelete(
        registry: state.project?.eventRegistry,
        mapId: map.id,
        entityId: entityId,
      );
      if (!dependencyDecision.isAllowed) {
        state = state.copyWith(errorMessage: dependencyDecision.message);
        return;
      }
      final updated = _entityEditingService.deleteEntity(
        map,
        entityId: entityId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedEntityId:
            state.selectedEntityId == entityId ? null : state.selectedEntityId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId,
        statusMessage: 'Entity deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete entity: $e');
    }
  }

  void placeOrSelectTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _triggerEditingService.findTriggerAtPos(map, pos);
    if (existing != null) {
      selectTrigger(existing.id);
      return;
    }
    addTriggerAt(pos);
  }

  void addTriggerAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _triggerEditingService.addTriggerAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.createdTrigger.id,
        statusMessage: 'Trigger "${result.createdTrigger.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trigger: $e');
    }
  }

  void selectTrigger(String? triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    if (triggerId == null) {
      state = state.copyWith(
        selectedTriggerId: null,
        errorMessage: null,
      );
      return;
    }
    final trigger = _triggerEditingService.findSelectedTrigger(map, triggerId);
    if (trigger == null) {
      state = state.copyWith(errorMessage: 'Trigger not found: $triggerId');
      return;
    }
    state = state.copyWith(
      selectedTriggerId: trigger.id,
      errorMessage: null,
    );
  }

  void updateSelectedTrigger({
    required String id,
    required String name,
    required TriggerType type,
    required int x,
    required int y,
    required int width,
    required int height,
    required Map<String, String> properties,
  }) {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    updateTrigger(
      triggerId: selectedTriggerId,
      id: id,
      name: name,
      type: type,
      area: MapRect(
        pos: GridPos(x: x, y: y),
        size: GridSize(width: width, height: height),
      ),
      properties: properties,
    );
  }

  void updateTrigger({
    required String triggerId,
    String? id,
    String? name,
    TriggerType? type,
    MapRect? area,
    Map<String, String>? properties,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      String? eventRevalidationMessage;
      final current = _triggerEditingService.findSelectedTrigger(
        map,
        triggerId,
      );
      if (current != null) {
        final dependencyDecision =
            _narrativeEventSourceDependencyGuard.inspectTriggerUpdate(
          registry: state.project?.eventRegistry,
          mapId: map.id,
          current: current,
          next: current.copyWith(
            id: id ?? current.id,
            name: name ?? current.name,
            type: type ?? current.type,
            area: area ?? current.area,
            properties: properties ?? current.properties,
          ),
        );
        if (!dependencyDecision.isAllowed) {
          state = state.copyWith(errorMessage: dependencyDecision.message);
          return;
        }
        eventRevalidationMessage = dependencyDecision.revalidationMessage;
      }
      final result = _triggerEditingService.updateTrigger(
        map,
        triggerId: triggerId,
        id: id,
        name: name,
        type: type,
        area: area,
        properties: properties,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: result.selectedTriggerId,
        statusMessage: 'Trigger updated',
      );
      if (eventRevalidationMessage != null) {
        state = state.copyWith(statusMessage: eventRevalidationMessage);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trigger: $e');
    }
  }

  void deleteSelectedTrigger() {
    final selectedTriggerId = state.selectedTriggerId;
    if (selectedTriggerId == null) return;
    deleteTrigger(selectedTriggerId);
  }

  void deleteTrigger(String triggerId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectTriggerDelete(
        registry: state.project?.eventRegistry,
        mapId: map.id,
        triggerId: triggerId,
      );
      if (!dependencyDecision.isAllowed) {
        state = state.copyWith(errorMessage: dependencyDecision.message);
        return;
      }
      final updated = _triggerEditingService.deleteTrigger(
        map,
        triggerId: triggerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: state.selectedWarpId,
        preferredSelectedTriggerId: state.selectedTriggerId == triggerId
            ? null
            : state.selectedTriggerId,
        statusMessage: 'Trigger deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trigger: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gameplay zones
  // ---------------------------------------------------------------------------

  MapGameplayZone? getSelectedGameplayZone() {
    return _gameplayZoneEditingService.findSelectedZone(
      state.activeMap,
      state.selectedGameplayZoneId,
    );
  }

  void placeOrSelectGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _gameplayZoneEditingService.findZoneAtPos(map, pos);
    if (existing != null) {
      selectGameplayZone(existing.id);
      return;
    }
    addGameplayZoneAt(pos);
  }

  void addGameplayZoneAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.addZoneAt(map, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" created',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  void selectGameplayZone(String? zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    if (zoneId == null) {
      state = state.copyWith(selectedGameplayZoneId: null);
      return;
    }
    final zone = _gameplayZoneEditingService.findSelectedZone(map, zoneId);
    if (zone == null) {
      state = state.copyWith(errorMessage: 'Zone not found: $zoneId');
      return;
    }
    state = state.copyWith(selectedGameplayZoneId: zone.id);
  }

  void updateSelectedGameplayZone({
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    updateGameplayZone(
      zoneId: selectedZoneId,
      id: id,
      name: name,
      kind: kind,
      area: area,
      priority: priority,
      encounter: encounter,
      movement: movement,
      movementEffect: movementEffect,
      hazard: hazard,
      special: special,
    );
  }

  void updateGameplayZone({
    required String zoneId,
    String? id,
    String? name,
    GameplayZoneKind? kind,
    MapRect? area,
    int? priority,
    Object? encounter,
    Object? movement,
    Object? movementEffect,
    Object? hazard,
    Object? special,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final result = _gameplayZoneEditingService.updateZone(
        map,
        zoneId: zoneId,
        id: id,
        name: name,
        kind: kind,
        area: area,
        priority: priority,
        encounter: encounter,
        movement: movement,
        movementEffect: movementEffect,
        hazard: hazard,
        special: special,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone updated',
      );
      state = state.copyWith(selectedGameplayZoneId: result.selectedZoneId);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update zone: $e');
    }
  }

  bool applyGeneratedGameplayZones({
    required SmartTileGameplayZoneGenerationPlan plan,
    String? selectZoneId,
    String? statusMessage,
  }) {
    final map = state.activeMap;
    final zones = plan.generatedZones;
    if (map == null || zones.isEmpty) return false;
    try {
      final synchronization = synchronizeSmartTileGameplayZones(
        map,
        generatedZones: zones,
      );
      final updatedMap = synchronization.map;

      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: statusMessage ??
            'Synchronized ${zones.length} gameplay ${zones.length == 1 ? 'zone' : 'zones'}',
      );

      final requestedSelection = selectZoneId?.trim();
      final hasRequestedSelection = requestedSelection != null &&
          requestedSelection.isNotEmpty &&
          updatedMap.gameplayZones.any(
            (zone) => zone.id == requestedSelection,
          );
      state = state.copyWith(
        selectedGameplayZoneId:
            hasRequestedSelection ? requestedSelection : zones.first.id,
      );
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to apply generated zones: $e');
      return false;
    }
  }

  void deleteSelectedGameplayZone() {
    final selectedZoneId = state.selectedGameplayZoneId;
    if (selectedZoneId == null) return;
    deleteGameplayZone(selectedZoneId);
  }

  void deleteGameplayZone(String zoneId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated =
          _gameplayZoneEditingService.deleteZone(map, zoneId: zoneId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone deleted',
      );
      if (state.selectedGameplayZoneId == zoneId) {
        state = state.copyWith(selectedGameplayZoneId: null);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete zone: $e');
    }
  }

  // Drag-to-draw ─────────────────────────────────────────────────────────────

  /// Met à jour l'aire de tracé en cours (fantôme visible sur le canvas).
  void setGameplayZoneDraftArea(MapRect area) {
    state = state.copyWith(gameplayZoneDraftArea: area);
  }

  /// Valide le tracé et crée la zone persistée.
  void commitGameplayZoneDraft() {
    final draft = state.gameplayZoneDraftArea;
    if (draft == null) return;
    state = state.copyWith(gameplayZoneDraftArea: null);
    final map = state.activeMap;
    if (map == null) return;
    // Clamp la zone dans les limites de la map
    final clampedArea = _clampRectToMap(draft, map.size);
    if (clampedArea == null) return;
    try {
      final result =
          _gameplayZoneEditingService.addZoneInRect(map, clampedArea);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Zone "${result.createdZone.id}" créée',
      );
      state = state.copyWith(selectedGameplayZoneId: result.createdZone.id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create zone: $e');
    }
  }

  /// Annule le tracé en cours sans créer de zone.
  void cancelGameplayZoneDraft() {
    state = state.copyWith(gameplayZoneDraftArea: null);
  }

  static MapRect? _clampRectToMap(MapRect rect, GridSize mapSize) {
    final x = rect.pos.x.clamp(0, mapSize.width - 1);
    final y = rect.pos.y.clamp(0, mapSize.height - 1);
    final w = rect.size.width.clamp(1, mapSize.width - x);
    final h = rect.size.height.clamp(1, mapSize.height - y);
    if (w <= 0 || h <= 0) return null;
    return MapRect(
        pos: GridPos(x: x, y: y), size: GridSize(width: w, height: h));
  }

  void placeOrSelectWarpAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) return;
    final existing = _warpEditingService.findWarpAtPos(map, pos);
    if (existing != null) {
      selectWarp(existing.id);
      return;
    }
    addWarpAt(pos);
  }

  void addWarpAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.addWarpAt(map, project, pos);
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.createdWarp.id,
        statusMessage: 'Warp "${result.createdWarp.id}" created',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create warp: $e');
    }
  }

  void selectWarp(String? warpId) {
    final map = state.activeMap;
    if (map == null) return;
    if (warpId == null) {
      state = state.copyWith(
        selectedWarpId: null,
        errorMessage: null,
      );
      return;
    }
    final warp = _warpEditingService.findSelectedWarp(map, warpId);
    if (warp == null) {
      state = state.copyWith(errorMessage: 'Warp not found: $warpId');
      return;
    }
    state = state.copyWith(
      selectedWarpId: warp.id,
      errorMessage: null,
    );
  }

  void updateSelectedWarp({
    required String id,
    required String targetMapId,
    required int targetPosX,
    required int targetPosY,
    required MapWarpTriggerMode triggerMode,
    required List<EntityFacing> allowedApproachFacings,
    required WarpTriggerPadding triggerPadding,
  }) {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    updateWarp(
      warpId: selectedWarpId,
      id: id,
      targetMapId: targetMapId,
      targetPos: GridPos(x: targetPosX, y: targetPosY),
      triggerMode: triggerMode,
      allowedApproachFacings: allowedApproachFacings,
      triggerPadding: triggerPadding,
    );
  }

  Future<void> createReciprocalWarpForSelectedWarp() async {
    final fs = _projectWorkspace;
    final project = state.project;
    final sourceMap = state.activeMap;
    final selectedWarpId = state.selectedWarpId;
    if (fs == null) {
      state = state.copyWith(
          errorMessage: 'Aucun système de fichiers de projet disponible');
      return;
    }
    if (project == null) {
      state = state.copyWith(errorMessage: 'Aucun projet chargé');
      return;
    }
    if (sourceMap == null) {
      state = state.copyWith(errorMessage: 'Aucune carte active chargée');
      return;
    }
    if (selectedWarpId == null) {
      state = state.copyWith(errorMessage: 'Aucun warp sélectionné');
      return;
    }
    // The reciprocal workflow can write another map directly or replace this
    // map in memory. Both paths must honor the same read-only/preview boundary
    // as every other authoring writer.
    if (_rejectNonCanonicalActiveMapAuthoring(revalidateManifest: true) ||
        _rejectPendingBorderPreviewDirectMapWrite()) {
      return;
    }
    if (_rejectNarrativeEventSourceCleanupMapMutation()) return;
    _MapDiskMutationLease? lease;
    try {
      final selectedWarp =
          _warpEditingService.requireSelectedWarp(sourceMap, selectedWarpId);
      try {
        _projectMapIdPolicy.requireValid(selectedWarp.targetMapId);
      } on EditorValidationException {
        state = state.copyWith(
          errorMessage: 'La carte cible legacy '
              '« ${selectedWarp.targetMapId} » est en lecture seule. '
              'Migrez-la vers un identifiant canonique avant de créer le '
              'warp retour.',
        );
        return;
      }
      if (selectedWarp.targetMapId.trim() != sourceMap.id) {
        lease = _beginMapDiskMutationLease();
        if (lease == null) return;
      }
      final result = await _warpEditingService.createReciprocalWarp(
        fs,
        project,
        sourceMap: sourceMap,
        sourceWarp: selectedWarp,
      );
      if (lease != null && !_canAdoptMapDiskMutation(lease)) return;

      if (result.targetIsSourceMap) {
        _applyMapMutation(
          previousMap: sourceMap,
          updatedMap: result.updatedTargetMap,
          preferredActiveLayerId: state.activeLayerId,
          preferredSelectedWarpId: selectedWarpId,
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
        );
      } else {
        state = state.copyWith(
          statusMessage:
              'Return warp "${result.reciprocalWarp.id}" created in map "${result.updatedTargetMap.id}"',
          errorMessage: null,
        );
      }
    } catch (e) {
      if (lease == null || _canAdoptMapDiskMutation(lease)) {
        state =
            state.copyWith(errorMessage: 'Failed to create return warp: $e');
      }
    } finally {
      if (lease != null) _endMapDiskMutationLease(lease);
    }
  }

  void updateWarp({
    required String warpId,
    String? id,
    GridPos? pos,
    String? targetMapId,
    GridPos? targetPos,
    MapWarpTriggerMode? triggerMode,
    List<EntityFacing>? allowedApproachFacings,
    WarpTriggerPadding? triggerPadding,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return;
    try {
      final result = _warpEditingService.updateWarp(
        map,
        project,
        warpId: warpId,
        id: id,
        pos: pos,
        targetMapId: targetMapId,
        targetPos: targetPos,
        triggerMode: triggerMode,
        allowedApproachFacings: allowedApproachFacings,
        triggerPadding: triggerPadding,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.updatedMap,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId: result.selectedWarpId,
        statusMessage: 'Warp updated',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update warp: $e');
    }
  }

  void deleteSelectedWarp() {
    final selectedWarpId = state.selectedWarpId;
    if (selectedWarpId == null) return;
    deleteWarp(selectedWarpId);
  }

  void deleteWarp(String warpId) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _warpEditingService.deleteWarp(
        map,
        warpId: warpId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        preferredSelectedWarpId:
            state.selectedWarpId == warpId ? null : state.selectedWarpId,
        statusMessage: 'Warp deleted',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete warp: $e');
    }
  }

  Future<void> openConnectedMap(MapConnectionDirection direction) async {
    await activateConnectedMap(direction);
  }

  Future<MapActivationOutcome> activateConnectedMap(
    MapConnectionDirection direction, {
    DirtyMapActivationDecision? dirtyDecision,
  }) async {
    final project = state.project;
    final connection = getMapConnection(direction);
    if (project == null || connection == null) {
      state = state.copyWith(
        errorMessage: 'No ${direction.name} connection available',
      );
      return MapActivationOutcome.unavailable;
    }
    try {
      final targetEntry = _mapConnectionEditingService.resolveTargetMapEntry(
        project,
        connection.targetMapId,
      );
      return await activateMap(
        targetEntry.relativePath,
        dirtyDecision: dirtyDecision,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to open connected map: $e',
      );
      return MapActivationOutcome.failed;
    }
  }

  MapToolPreview? resolveMapToolPreview({
    GridPos? hoveredTile,
    required Map<String, int> tilesetColumnsById,
  }) {
    if (hoveredTile == null) return null;
    final tool = state.activeTool;
    if (tool != EditorToolType.tilePaint &&
        tool != EditorToolType.terrainPaint &&
        tool != EditorToolType.collisionPaint &&
        tool != EditorToolType.eraser) {
      return null;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) return null;
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) return null;

    if (tool == EditorToolType.tilePaint) {
      if (activeLayer is! TileLayer) return null;
      if (state.activeBrush is ProjectElementEditorBrush) {
        return resolveSelectedProjectElementPlacementPreview(hoveredTile);
      }
      final resolvedBrush = _resolveActiveBrushPattern(
        tilesetColumnsById: tilesetColumnsById,
        emitErrors: false,
      );
      if (resolvedBrush == null) return null;
      return MapToolPreview.paint(
        origin: hoveredTile,
        size: resolvedBrush.pattern.size,
        tilesetId: resolvedBrush.tilesetId,
        tiles: resolvedBrush.pattern.tiles,
        validity: MapToolPreviewValidity.valid,
      );
    }

    if (tool == EditorToolType.terrainPaint) {
      if (activeLayer is SmartTileLayer) {
        return MapToolPreview.pathPaint(
          origin: hoveredTile,
          size: const GridSize(width: 1, height: 1),
          validity: MapToolPreviewValidity.valid,
        );
      }
      return null;
    }

    if (tool == EditorToolType.collisionPaint) {
      if (activeLayer is! CollisionLayer) return null;
      final collisionFootprint = _resolveCollisionFootprint(emitErrors: false);
      if (collisionFootprint == null) return null;
      return MapToolPreview.collisionPaint(
        origin: hoveredTile,
        size: collisionFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }

    final eraserFootprint = _resolveEraserFootprint(emitErrors: false);
    if (eraserFootprint == null) return null;
    if (activeLayer is TileLayer) {
      return MapToolPreview.erase(
        origin: hoveredTile,
        size: eraserFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is CollisionLayer) {
      return MapToolPreview.collisionErase(
        origin: hoveredTile,
        size: eraserFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    if (activeLayer is SmartTileLayer) {
      return MapToolPreview.pathErase(
        origin: hoveredTile,
        size: eraserFootprint.size,
        validity: MapToolPreviewValidity.valid,
      );
    }
    return null;
  }

  void paintSelectedTileAt(GridPos pos) {
    beginMapStroke();
    paintSelectedBrushAt(pos, tilesetColumnsById: const {});
    endMapStroke();
  }

  void beginMapStroke() {
    if (_rejectNonCanonicalActiveMapAuthoring() ||
        _rejectNarrativeEventSourceCleanupMapMutation() ||
        _rejectMapDiskMutationLease()) {
      return;
    }
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final activeLayer =
        map == null || layerId == null ? null : _findLayerById(map, layerId);
    if (activeLayer is SmartTileLayer && _smartTileCanonicalRecoveryRequired) {
      state = state.copyWith(
        errorMessage:
            'Rechargez la map avant de continuer la peinture Smart Tile.',
      );
      return;
    }
    if (activeLayer is SmartTileLayer &&
        state.isDirty &&
        !_canonicalSmartTileGestureOwnsDirtyMap) {
      return;
    }
    state = _mapEditingController.beginStroke(state);
  }

  void endMapStroke() {
    state = _mapEditingController.endStroke(state);
    _flushPendingSmartTileGesture();
  }

  void cancelMapStroke() {
    _pendingSmartTileGesture = null;
    _deferredSmartTileGesture = null;
    state = _mapEditingController.cancelStroke(state);
  }

  void _recordSmartTileGesture({
    required String mapId,
    required String layerId,
    required String? materialId,
    required Iterable<GridPos> cells,
    required bool commitImmediately,
    SmartTileGestureSelection? selection,
  }) {
    final additions = cells.toList(growable: false);
    if (additions.isEmpty) return;
    var gesture = _pendingSmartTileGesture;
    if (gesture == null) {
      final rollbackState = state.mapStrokeStart == null
          ? _mapEditingController.undo(state)?.copyWith(
              mapRedoStack: const [],
              canRedoMap: false,
            )
          : _mapEditingController.cancelStroke(state);
      if (rollbackState == null) {
        state = state.copyWith(
          errorMessage: 'smart_tile.cell.rollback_checkpoint_missing',
        );
        return;
      }
      gesture = _PendingSmartTileGesture(
        mapId: mapId,
        layerId: layerId,
        materialId: materialId,
        rollbackState: rollbackState,
        selection: selection,
      );
      _pendingSmartTileGesture = gesture;
    } else if (gesture.mapId != mapId ||
        gesture.layerId != layerId ||
        gesture.materialId != materialId) {
      state = state.copyWith(
        errorMessage: 'Un geste Smart Tile ne peut viser qu’une seule couche '
            'et un seul matériau.',
      );
      return;
    } else if (gesture.selection != selection) {
      // Same layer and material, different shapes: one edit over the union of
      // their cells. Drop the shape, keep every cell.
      gesture.selection = null;
    }
    gesture.cells.addAll(additions);
    if (!commitImmediately) return;
    _flushPendingSmartTileGesture();
  }

  /// Starts the canonical write for the pending gesture, unless one is running.
  ///
  /// A canonical write costs hundreds of milliseconds, so committing per click
  /// made ordinary clicking collide with itself. The write in flight *is* the
  /// coalescing window: clicks landing during it stay in the pending gesture
  /// and leave together with the next write, which also gives the author one
  /// undo step per burst instead of one per click.
  void _flushPendingSmartTileGesture() {
    if (_smartTileGestureCommitInProgress ||
        _smartTileCanonicalRecoveryRequired) {
      return;
    }
    // The canvas arbiter still owns the stroke; [endMapStroke] flushes it.
    if (state.mapStrokeStart != null) return;
    final gesture = _pendingSmartTileGesture;
    if (gesture == null || gesture.cells.isEmpty) return;
    _pendingSmartTileGesture = null;
    unawaited(_commitCanonicalSmartTileGesture(gesture));
  }

  Future<void> _commitCanonicalSmartTileGesture(
    _PendingSmartTileGesture gesture,
  ) async {
    final projectRootPath = state.projectRootPath;
    if (projectRootPath == null || gesture.cells.isEmpty) return;
    _smartTileGestureCommitInProgress = true;
    final cells = gesture.cells.toList(growable: false)
      ..sort((left, right) {
        final byY = left.y.compareTo(right.y);
        return byY != 0 ? byY : left.x.compareTo(right.x);
      });
    final actionId = gesture.materialId == null
        ? 'smart_tile.cell.erase'
        : 'smart_tile.cell.paint';
    final parameters = _smartTileGestureParameters(
      mapId: gesture.mapId,
      layerId: gesture.layerId,
      materialId: gesture.materialId,
      cells: cells,
      selection: gesture.selection,
    );
    final sequence = ++_smartTileGestureSequence;
    final identity = _smartTileEditorMutationIdentity(
      purpose: 'smart-tile-cell-gesture',
      values: <String, Object?>{
        'mapId': gesture.mapId,
        'layerId': gesture.layerId,
        'sequence': sequence,
      },
    );
    EditorAuthoringMutationResult? applied;
    try {
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      applied = await mutations.apply(
        plan,
        operationId: '$identity-apply',
      );
      final historyEntry = _CanonicalSmartTileHistoryEntry(
        projectRootPath: projectRootPath,
        receiptId: applied.receipt.receiptId,
        mapId: gesture.mapId,
        layerId: gesture.layerId,
        redoActionId: actionId,
        redoParameters: Map<String, Object?>.unmodifiable(parameters),
      );
      final adopted = await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: gesture.mapId,
        layerId: gesture.layerId,
        statusMessage: gesture.materialId == null
            ? '${cells.length} cellule(s) Smart Tile effacée(s).'
            : '${cells.length} cellule(s) Smart Tile peinte(s).',
      );
      _canonicalSmartTileUndoStack.add(historyEntry);
      _canonicalSmartTileRedoStack.clear();
      _smartTileCanonicalRecoveryRequired = false;
      if (adopted) {
        _replayPendingSmartTileGestureOverAdoptedMap();
        _syncCanonicalSmartTileHistoryFlags();
      }
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      // Rolling back restores the map from before this burst, which also undoes
      // the cells clicked while it was being written. Drop their gesture too
      // rather than commit cells the author can no longer see.
      _pendingSmartTileGesture = null;
      if (applied == null) {
        _rollbackOptimisticSmartTileGesture(
          gesture,
          canonicalSmartTileFailureMessage(failure),
        );
      } else {
        _smartTileCanonicalRecoveryRequired = true;
        state = state.copyWith(errorMessage: editorReloadRequiredMessage);
      }
    } finally {
      _smartTileGestureCommitInProgress = false;
      _flushPendingSmartTileGesture();
    }
  }

  Map<String, Object?> _smartTileGestureParameters({
    required String mapId,
    required String layerId,
    required String? materialId,
    required Iterable<GridPos> cells,
    SmartTileGestureSelection? selection,
  }) =>
      <String, Object?>{
        'mapId': mapId,
        'layerId': layerId,
        'materialId': ?materialId,
        if (selection == null)
          'cells': <Map<String, int>>[
            for (final cell in cells) <String, int>{'x': cell.x, 'y': cell.y},
          ]
        else
          'selection': _smartTileGestureSelectionParameters(selection),
      };

  Map<String, Object?> _smartTileGestureSelectionParameters(
    SmartTileGestureSelection selection,
  ) =>
      switch (selection.kind) {
        SmartTileGestureSelectionKind.line => <String, Object?>{
            'kind': 'line',
            'start': _smartTileGestureCoordinate(selection.start),
            'end': _smartTileGestureCoordinate(selection.end!),
          },
        SmartTileGestureSelectionKind.rectangle => <String, Object?>{
            'kind': 'rectangle',
            'start': _smartTileGestureCoordinate(selection.start),
            'end': _smartTileGestureCoordinate(selection.end!),
          },
        SmartTileGestureSelectionKind.floodFill => <String, Object?>{
            'kind': 'floodFill',
            'seed': _smartTileGestureCoordinate(selection.start),
          },
      };

  Map<String, int> _smartTileGestureCoordinate(GridPos cell) =>
      <String, int>{'x': cell.x, 'y': cell.y};

  void paintActiveSmartTilePattern(
    SmartTilePatternSelection selection, {
    required String patternId,
    String? collisionLayerId,
  }) {
    unawaited(
      _commitCanonicalSmartTilePattern(
        patternId: patternId,
        paintSelection: selection,
        collisionLayerId: collisionLayerId,
      ),
    );
  }

  void eraseActiveSmartTilePattern(
    SmartTileGestureSelection selection,
  ) {
    unawaited(
      _commitCanonicalSmartTilePattern(eraseSelection: selection),
    );
  }

  Future<void> _commitCanonicalSmartTilePattern({
    String? patternId,
    SmartTilePatternSelection? paintSelection,
    SmartTileGestureSelection? eraseSelection,
    String? collisionLayerId,
  }) async {
    final erase = eraseSelection != null;
    if (erase == (paintSelection != null) || erase == (patternId != null)) {
      state =
          state.copyWith(errorMessage: 'smart_tile.pattern.request_invalid');
      return;
    }
    if (_rejectNonCanonicalActiveMapAuthoring() ||
        _rejectNarrativeEventSourceCleanupMapMutation() ||
        _rejectMapDiskMutationLease()) {
      return;
    }
    if (state.isDirty ||
        _smartTileGestureCommitInProgress ||
        _smartTileCanonicalRecoveryRequired) {
      state = state.copyWith(
        errorMessage: _smartTileCanonicalRecoveryRequired
            ? 'smart_tile.pattern.reload_required'
            : _smartTileGestureCommitInProgress
                ? 'smart_tile.pattern.commit_in_progress'
                : 'smart_tile.pattern.save_map_first',
      );
      return;
    }
    final projectRootPath = state.projectRootPath;
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final project = state.project;
    if (projectRootPath == null ||
        map == null ||
        layerId == null ||
        project == null) {
      state =
          state.copyWith(errorMessage: 'smart_tile.pattern.context_missing');
      return;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! SmartTileLayer) {
      state = state.copyWith(errorMessage: 'smart_tile.layer_invalid');
      return;
    }
    if (!erase) {
      final pattern = project.smartTileCatalog.patterns
          .where((candidate) => candidate.id == patternId)
          .firstOrNull;
      if (pattern == null || pattern.usage != layer.usage) {
        state = state.copyWith(errorMessage: 'smart_tile.pattern.unknown');
        return;
      }
    }

    _smartTileGestureCommitInProgress = true;
    final sequence = ++_smartTileGestureSequence;
    final actionId =
        erase ? 'smart_tile.pattern.erase' : 'smart_tile.pattern.paint';
    final identity = _smartTileEditorMutationIdentity(
      purpose: erase ? 'smart-tile-pattern-erase' : 'smart-tile-pattern-paint',
      values: <String, Object?>{
        'mapId': map.id,
        'layerId': layer.id,
        'patternId': patternId,
        'sequence': sequence,
      },
    );
    final parameters = <String, Object?>{
      'mapId': map.id,
      'layerId': layer.id,
      if (erase)
        'selection': _smartTileGestureSelectionParameters(eraseSelection)
      else ...<String, Object?>{
        'patternId': patternId!,
        'strokeId': identity,
        'selection': _smartTilePatternSelectionParameters(paintSelection!),
        'collisionLayerId': ?collisionLayerId,
      },
    };
    EditorAuthoringMutationResult? applied;
    try {
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        projectRootPath,
        actionId: actionId,
        parameters: parameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      applied = await mutations.apply(plan, operationId: '$identity-apply');
      final historyEntry = _CanonicalSmartTileHistoryEntry(
        projectRootPath: projectRootPath,
        receiptId: applied.receipt.receiptId,
        mapId: map.id,
        layerId: layer.id,
        redoActionId: actionId,
        redoParameters: Map<String, Object?>.unmodifiable(parameters),
      );
      final adopted = await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: map.id,
        layerId: layer.id,
        statusMessage:
            erase ? 'Motif Smart Tile effacé.' : 'Motif Smart Tile appliqué.',
      );
      _canonicalSmartTileUndoStack.add(historyEntry);
      _canonicalSmartTileRedoStack.clear();
      _smartTileCanonicalRecoveryRequired = false;
      if (adopted) _syncCanonicalSmartTileHistoryFlags();
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      if (applied != null) _smartTileCanonicalRecoveryRequired = true;
      state = state.copyWith(
        errorMessage: applied == null
            ? failure.code
            : 'smart_tile.pattern.reload_required',
      );
    } finally {
      _smartTileGestureCommitInProgress = false;
      _syncCanonicalSmartTileHistoryFlags();
    }
  }

  Map<String, Object?> _smartTilePatternSelectionParameters(
    SmartTilePatternSelection selection,
  ) =>
      switch (selection.kind) {
        SmartTilePatternSelectionKind.stamp => <String, Object?>{
            'kind': 'stamp',
            'anchor': _smartTileGestureCoordinate(selection.start),
          },
        SmartTilePatternSelectionKind.line => <String, Object?>{
            'kind': 'line',
            'start': _smartTileGestureCoordinate(selection.start),
            'end': _smartTileGestureCoordinate(selection.end!),
          },
        SmartTilePatternSelectionKind.rectangle => <String, Object?>{
            'kind': 'rectangle',
            'start': _smartTileGestureCoordinate(selection.start),
            'end': _smartTileGestureCoordinate(selection.end!),
          },
      };

  Future<bool> _adoptCanonicalSmartTileSnapshot({
    required String projectRootPath,
    required String expectedSnapshotRevision,
    required String mapId,
    required String layerId,
    required String statusMessage,
  }) async {
    final canonical =
        await ref.read(authoringQueryAdapterProvider).open(projectRootPath);
    if (canonical.snapshotRevision != expectedSnapshotRevision) {
      throw const EditorAuthoringMutationFailure(
        code: 'smart_tile.cell.snapshot_stale',
        message: 'Le snapshot canonique du geste Smart Tile est obsolète.',
      );
    }
    final map = canonical.mapById(mapId);
    final mapRevision = canonical.resourceRevision('map:$mapId');
    if (map == null || mapRevision == null) {
      throw const EditorAuthoringMutationFailure(
        code: 'smart_tile.cell.snapshot_missing',
        message: 'La map modifiée est absente du snapshot canonique.',
      );
    }
    if (state.activeMap?.id != mapId ||
        state.projectRootPath != projectRootPath) {
      return false;
    }
    return acceptCanonicalSmartTilePublication(
      manifest: canonical.manifest,
      map: map,
      mapRevision: mapRevision,
      layerId: layerId,
      statusMessage: statusMessage,
      preservePaintTool: true,
      preserveCanonicalGestureHistory: true,
    );
  }

  /// Re-paints the cells clicked while the adopted snapshot was being written.
  ///
  /// An adopted snapshot is the disk truth for the burst that just landed and
  /// knows nothing of the clicks that arrived since, so adopting it on its own
  /// wipes them off the canvas until their own write lands — the author sees
  /// the path they just erased come back, then vanish again. Replaying them
  /// keeps the canvas continuous, and re-anchors the rollback checkpoint on the
  /// snapshot the next write will plan against, so it can no longer go stale.
  void _replayPendingSmartTileGestureOverAdoptedMap() {
    final pending = _pendingSmartTileGesture;
    if (pending == null || pending.cells.isEmpty) return;
    final map = state.activeMap;
    if (map == null || map.id != pending.mapId) return;
    final layer = _findLayerById(map, pending.layerId);
    if (layer is! SmartTileLayer) return;
    pending.rollbackState = state;
    try {
      final painted = applySmartTileMaterialGesture(
        layer,
        mapSize: map.size,
        cells: pending.cells.toList(growable: false),
        materialId: pending.materialId,
      );
      if (painted == layer) return;
      final updated = replaceSmartTileLayer(map, layer: painted);
      MapValidator.validate(updated, projectDialogueContext: state.project);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: pending.layerId,
        // A drag started over the write owns its own undo boundary; replaying
        // inside it must not open a second one.
        partOfStroke: state.mapStrokeStart != null,
      );
    } catch (error) {
      _pendingSmartTileGesture = null;
      _setPaintError('Failed to replay pending Smart Tile cells: $error');
    }
  }

  void _rollbackOptimisticSmartTileGesture(
    _PendingSmartTileGesture gesture,
    String errorMessage,
  ) {
    final rollback = gesture.rollbackState;
    if (state.activeMap?.id != gesture.mapId ||
        state.projectRootPath != rollback.projectRootPath) {
      state = state.copyWith(errorMessage: errorMessage);
      return;
    }
    state = state.copyWith(
      activeMap: rollback.activeMap,
      activeLayerId: rollback.activeLayerId,
      mapUndoStack: rollback.mapUndoStack,
      mapRedoStack: rollback.mapRedoStack,
      mapStrokeStart: null,
      savedMapSnapshot: rollback.savedMapSnapshot,
      canUndoMap: rollback.canUndoMap,
      canRedoMap: rollback.canRedoMap,
      isDirty: rollback.isDirty,
      errorMessage: errorMessage,
    );
    _syncCanonicalSmartTileHistoryFlags();
  }

  bool _canonicalSmartTileHistoryMatchesActiveMap(
    _CanonicalSmartTileHistoryEntry entry,
  ) =>
      state.projectRootPath == entry.projectRootPath &&
      state.activeMap?.id == entry.mapId;

  void _syncCanonicalSmartTileHistoryFlags() {
    final canUndoCanonical = _canonicalSmartTileUndoStack.isNotEmpty &&
        _canonicalSmartTileHistoryMatchesActiveMap(
          _canonicalSmartTileUndoStack.last,
        );
    final canRedoCanonical = _canonicalSmartTileRedoStack.isNotEmpty &&
        _canonicalSmartTileHistoryMatchesActiveMap(
          _canonicalSmartTileRedoStack.last,
        );
    state = state.copyWith(
      canUndoMap: state.mapUndoStack.isNotEmpty || canUndoCanonical,
      canRedoMap: state.mapRedoStack.isNotEmpty || canRedoCanonical,
    );
  }

  @override
  void _recordCanonicalPlacedElementPlacement({
    required String projectRootPath,
    required String receiptId,
    required String mapId,
    required String layerId,
    required PlacedElementMutationIntent intent,
  }) {
    _canonicalSmartTileUndoStack.add(
      _CanonicalSmartTileHistoryEntry(
        projectRootPath: projectRootPath,
        receiptId: receiptId,
        mapId: mapId,
        layerId: layerId,
        redoActionId: intent.actionId,
        redoParameters: intent.parameters,
        selectedPlacedElementInstanceId: intent.instanceId,
        undoStatusMessage: 'Placement de l’élément annulé.',
        redoStatusMessage: 'Placement de l’élément réappliqué.',
      ),
    );
    _canonicalSmartTileRedoStack.clear();
    _syncCanonicalSmartTileHistoryFlags();
  }

  @override
  void _clearCanonicalSmartTileHistory() {
    _canonicalSmartTileUndoStack.clear();
    _canonicalSmartTileRedoStack.clear();
    _smartTileCanonicalRecoveryRequired = false;
  }

  void undoMap() {
    // History commands must never terminate a gesture still owned by the
    // canvas. Pointer-up or cancellation remains its single terminal event.
    if (state.mapStrokeStart != null ||
        _smartTileGestureCommitInProgress ||
        _smartTileCanonicalRecoveryRequired ||
        _rejectNarrativeEventSourceCleanupMapMutation() ||
        _rejectMapDiskMutationLease()) {
      if (_smartTileCanonicalRecoveryRequired) {
        state = state.copyWith(errorMessage: editorReloadRequiredMessage);
      }
      return;
    }
    final initialState = state;
    final historyReadyState = _mapEditingController.endStroke(initialState);
    final outgoingPaletteSession =
        _rememberActivePaletteContext(historyReadyState);
    final restored = _mapEditingController.undo(historyReadyState);
    if (restored == null) {
      state = historyReadyState;
      final canUndoCanonical = !state.isDirty &&
          _canonicalSmartTileUndoStack.isNotEmpty &&
          _canonicalSmartTileHistoryMatchesActiveMap(
            _canonicalSmartTileUndoStack.last,
          );
      if (canUndoCanonical) {
        unawaited(_undoCanonicalSmartTileGesture());
      } else {
        _syncCanonicalSmartTileHistoryFlags();
      }
      return;
    }
    final currentMap = historyReadyState.activeMap;
    final candidateMap = restored.activeMap;
    if (currentMap != null && candidateMap != null) {
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectMapTransition(
        registry: historyReadyState.project?.eventRegistry,
        current: currentMap,
        candidate: candidateMap,
        operation: 'undo de la map ${currentMap.id}',
      );
      if (!dependencyDecision.isAllowed) {
        state = initialState.copyWith(errorMessage: dependencyDecision.message);
        return;
      }
    }
    final adopted =
        _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored.copyWith(paletteSession: outgoingPaletteSession),
    );
    state = _activatePaletteContext(adopted);
    _syncCanonicalSmartTileHistoryFlags();
  }

  void redoMap() {
    // In particular, finalizing here would clear a pre-existing redo stack
    // before the physical pointer session has ended.
    if (state.mapStrokeStart != null ||
        _smartTileGestureCommitInProgress ||
        _smartTileCanonicalRecoveryRequired ||
        _rejectNarrativeEventSourceCleanupMapMutation() ||
        _rejectMapDiskMutationLease()) {
      if (_smartTileCanonicalRecoveryRequired) {
        state = state.copyWith(errorMessage: editorReloadRequiredMessage);
      }
      return;
    }
    final initialState = state;
    final historyReadyState = _mapEditingController.endStroke(initialState);
    final outgoingPaletteSession =
        _rememberActivePaletteContext(historyReadyState);
    final restored = _mapEditingController.redo(historyReadyState);
    if (restored == null) {
      state = historyReadyState;
      final canRedoCanonical = !state.isDirty &&
          _canonicalSmartTileRedoStack.isNotEmpty &&
          _canonicalSmartTileHistoryMatchesActiveMap(
            _canonicalSmartTileRedoStack.last,
          );
      if (canRedoCanonical) {
        unawaited(_redoCanonicalSmartTileGesture());
      } else {
        _syncCanonicalSmartTileHistoryFlags();
      }
      return;
    }
    final currentMap = historyReadyState.activeMap;
    final candidateMap = restored.activeMap;
    if (currentMap != null && candidateMap != null) {
      final dependencyDecision =
          _narrativeEventSourceDependencyGuard.inspectMapTransition(
        registry: historyReadyState.project?.eventRegistry,
        current: currentMap,
        candidate: candidateMap,
        operation: 'redo de la map ${currentMap.id}',
      );
      if (!dependencyDecision.isAllowed) {
        state = initialState.copyWith(errorMessage: dependencyDecision.message);
        return;
      }
    }
    final adopted =
        _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      restored.copyWith(paletteSession: outgoingPaletteSession),
    );
    state = _activatePaletteContext(adopted);
    _syncCanonicalSmartTileHistoryFlags();
  }

  Future<void> _undoCanonicalSmartTileGesture() async {
    if (_canonicalSmartTileUndoStack.isEmpty) return;
    final entry = _canonicalSmartTileUndoStack.last;
    if (!_canonicalSmartTileHistoryMatchesActiveMap(entry) || state.isDirty) {
      _syncCanonicalSmartTileHistoryFlags();
      return;
    }
    _smartTileGestureCommitInProgress = true;
    final sequence = ++_smartTileGestureSequence;
    final identity = _smartTileEditorMutationIdentity(
      purpose: 'smart-tile-history-undo',
      values: <String, Object?>{
        'mapId': entry.mapId,
        'entryId': entry.receiptId,
        'sequence': sequence,
      },
    );
    EditorAuthoringMutationResult? applied;
    try {
      applied = await ref.read(authoringMutationAdapterProvider).undo(
            entry.projectRootPath,
            entryId: entry.receiptId,
            idempotencyKey: identity,
          );
      final adopted = await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: entry.projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: entry.mapId,
        layerId: entry.layerId,
        statusMessage: entry.undoStatusMessage,
      );
      if (_canonicalSmartTileUndoStack.isNotEmpty &&
          _canonicalSmartTileUndoStack.last.receiptId == entry.receiptId) {
        _canonicalSmartTileUndoStack.removeLast();
        _canonicalSmartTileRedoStack.add(entry);
      }
      _smartTileCanonicalRecoveryRequired = false;
      if (adopted) {
        if (entry.selectedPlacedElementInstanceId != null) {
          state = state.copyWith(selectedPlacedElementInstanceId: null);
        }
        _syncCanonicalSmartTileHistoryFlags();
      }
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      if (applied != null) _smartTileCanonicalRecoveryRequired = true;
      state = state.copyWith(
        errorMessage: applied == null
            ? canonicalSmartTileFailureMessage(failure)
            : editorReloadRequiredMessage,
      );
    } finally {
      _smartTileGestureCommitInProgress = false;
      _syncCanonicalSmartTileHistoryFlags();
    }
  }

  Future<void> _redoCanonicalSmartTileGesture() async {
    if (_canonicalSmartTileRedoStack.isEmpty) return;
    final entry = _canonicalSmartTileRedoStack.last;
    if (!_canonicalSmartTileHistoryMatchesActiveMap(entry) || state.isDirty) {
      _syncCanonicalSmartTileHistoryFlags();
      return;
    }
    _smartTileGestureCommitInProgress = true;
    final sequence = ++_smartTileGestureSequence;
    final identity = _smartTileEditorMutationIdentity(
      purpose: 'smart-tile-history-redo',
      values: <String, Object?>{
        'mapId': entry.mapId,
        'entryId': entry.receiptId,
        'sequence': sequence,
      },
    );
    EditorAuthoringMutationResult? applied;
    try {
      final mutations = ref.read(authoringMutationAdapterProvider);
      final plan = await mutations.plan(
        entry.projectRootPath,
        actionId: entry.redoActionId,
        parameters: entry.redoParameters,
        idempotencyKey: identity,
        requestId: identity,
      );
      applied = await mutations.apply(
        plan,
        operationId: '$identity-apply',
      );
      final adopted = await _adoptCanonicalSmartTileSnapshot(
        projectRootPath: entry.projectRootPath,
        expectedSnapshotRevision: applied.snapshotRevision,
        mapId: entry.mapId,
        layerId: entry.layerId,
        statusMessage: entry.redoStatusMessage,
      );
      if (_canonicalSmartTileRedoStack.isNotEmpty &&
          _canonicalSmartTileRedoStack.last.receiptId == entry.receiptId) {
        _canonicalSmartTileRedoStack.removeLast();
        _canonicalSmartTileUndoStack.add(
          entry.withReceipt(applied.receipt.receiptId),
        );
      }
      _smartTileCanonicalRecoveryRequired = false;
      if (adopted) {
        final selectedId = entry.selectedPlacedElementInstanceId;
        if (selectedId != null) {
          state = state.copyWith(selectedPlacedElementInstanceId: selectedId);
        }
        _syncCanonicalSmartTileHistoryFlags();
      }
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      if (applied != null) _smartTileCanonicalRecoveryRequired = true;
      state = state.copyWith(
        errorMessage: applied == null
            ? canonicalSmartTileFailureMessage(failure)
            : editorReloadRequiredMessage,
      );
    } finally {
      _smartTileGestureCommitInProgress = false;
      _syncCanonicalSmartTileHistoryFlags();
    }
  }

  @override
  EditorBrush _clearBrushIfTilesetRemoved(EditorBrush brush, String tilesetId) {
    if (brush is TileEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is PaletteEntryEditorBrush && brush.tilesetId == tilesetId) {
      return const EditorBrush.none();
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element != null && element.tilesetId == tilesetId) {
        return const EditorBrush.none();
      }
    }
    return brush;
  }

  _PaintPattern _buildPatternFromSource(
    TilesetSourceRect source, {
    required String tilesetId,
    required int tilesetColumns,
  }) {
    final tiles = List<TileLayerPaletteEntry?>.filled(
      source.width * source.height,
      null,
      growable: false,
    );
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final sourceX = source.x + x;
        final sourceY = source.y + y;
        tiles[y * source.width + x] = TileLayerPaletteEntry(
          tilesetId: tilesetId,
          localTileId: sourceY * tilesetColumns + sourceX,
        );
      }
    }
    return _PaintPattern(
      size: GridSize(width: source.width, height: source.height),
      tiles: tiles,
    );
  }

  _ResolvedBrushPattern? _resolveActiveBrushPattern({
    required Map<String, int> tilesetColumnsById,
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) return null;

    if (brush is TileEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError('Selected tile brush does not have a valid tileset');
        }
        return null;
      }
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'tile',
        pattern: _PaintPattern(
          size: const GridSize(width: 1, height: 1),
          tiles: <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(
              tilesetId: tilesetId,
              localTileId: brush.tileId - 1,
            ),
          ],
        ),
      );
    }

    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
              'Selected palette brush does not have a valid tileset');
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      final tilesetColumns = tilesetColumnsById[tilesetId] ?? 0;
      if (tilesetColumns <= 0) {
        if (emitErrors) {
          _setPaintError('Selected brush tileset image is not available');
        }
        return null;
      }
      return _ResolvedBrushPattern(
        tilesetId: tilesetId,
        failureLabel: 'palette entry',
        pattern: _buildPatternFromSource(
          entry.frames.primarySource,
          tilesetId: tilesetId,
          tilesetColumns: tilesetColumns,
        ),
      );
    }

    return null;
  }

  _ResolvedBrushFootprint? _resolveEraserFootprint({
    required bool emitErrors,
  }) {
    final configured = state.eraserFootprint;
    final size = configured.size;
    if (!_isValidEraserFootprintSize(size)) {
      if (emitErrors) {
        _setPaintError(
          'Eraser footprint must be between 1 and '
          '$kMaxEditorEraserFootprintDimension tiles per side',
        );
      }
      return null;
    }
    return _ResolvedBrushFootprint(
      size: size,
      failureLabel: switch (configured) {
        SingleTileEditorEraserFootprint() => 'tile',
        PreviousBrushEditorEraserFootprint() => 'previous brush footprint',
        CustomEditorEraserFootprint() => 'custom eraser footprint',
      },
    );
  }

  bool _isValidEraserFootprintSize(GridSize size) {
    return size.width >= 1 &&
        size.height >= 1 &&
        size.width <= kMaxEditorEraserFootprintDimension &&
        size.height <= kMaxEditorEraserFootprintDimension;
  }

  _ResolvedBrushFootprint? _resolveCurrentPaintFootprint({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    final activeLayer =
        map == null || layerId == null ? null : _findLayerById(map, layerId);
    if (activeLayer is TileLayer) {
      return _resolveBrushFootprint(emitErrors: emitErrors);
    }
    if (activeLayer is CollisionLayer) {
      return _resolveCollisionFootprint(emitErrors: emitErrors);
    }
    if (activeLayer is SmartTileLayer) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'Smart Tile cell',
      );
    }
    if (emitErrors) {
      _setPaintError('The active layer does not expose a paint footprint');
    }
    return null;
  }

  _ResolvedBrushFootprint? _resolveCollisionFootprint({
    required bool emitErrors,
  }) {
    if (state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    return _resolveBrushFootprint(emitErrors: emitErrors);
  }

  _ResolvedBrushFootprint? _resolveBrushFootprint({
    required bool emitErrors,
  }) {
    final brush = state.activeBrush;
    if (brush is NoEditorBrush) {
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is TileEditorBrush) {
      if (brush.tileId <= 0) {
        if (emitErrors) {
          _setPaintError('Selected tile brush is invalid');
        }
        return null;
      }
      return const _ResolvedBrushFootprint(
        size: GridSize(width: 1, height: 1),
        failureLabel: 'tile',
      );
    }
    if (brush is PaletteEntryEditorBrush) {
      final tilesetId = brush.tilesetId.trim();
      if (tilesetId.isEmpty) {
        if (emitErrors) {
          _setPaintError(
            'Selected palette brush does not have a valid tileset',
          );
        }
        return null;
      }
      final entry = getPaletteEntryById(
        tilesetId: tilesetId,
        entryId: brush.entryId,
      );
      if (entry == null) {
        if (emitErrors) {
          _setPaintError('Selected palette entry is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: entry.frames.primarySource.width,
          height: entry.frames.primarySource.height,
        ),
        failureLabel: 'palette entry',
      );
    }
    if (brush is ProjectElementEditorBrush) {
      final element = getProjectElementById(brush.elementId);
      if (element == null) {
        if (emitErrors) {
          _setPaintError('Selected project element is no longer available');
        }
        return null;
      }
      return _ResolvedBrushFootprint(
        size: GridSize(
          width: element.frames.primarySource.width,
          height: element.frames.primarySource.height,
        ),
        failureLabel: 'element',
      );
    }
    return null;
  }

  void _paintPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required _PaintPattern pattern,
    required String failureLabel,
  }) {
    try {
      final useCase = ref.read(paintTilePatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: pattern.size,
        tiles: pattern.tiles,
        clipToMapBounds: true,
      );
      final project = state.project;
      final committed = project == null
          ? painted
          : _placedElementInstanceIndexer.syncLayer(
              map: painted,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint $failureLabel: $e');
    }
  }

  void _erasePattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
    required bool partOfStroke,
  }) {
    try {
      final project = state.project;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        final committed = project == null
            ? erased
            : _placedElementInstanceIndexer.syncLayer(
                map: erased,
                project: project,
                layerId: layerId,
              );
        _applyMapMutation(
          previousMap: map,
          updatedMap: committed,
          preferredActiveLayerId: layerId,
          partOfStroke: partOfStroke,
        );
        return;
      }

      final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: layerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: layerId,
        partOfStroke: partOfStroke,
      );
    } catch (e) {
      _setPaintError('Failed to erase $failureLabel: $e');
    }
  }

  void _paintCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(paintCollisionOnMapUseCaseProvider);
        final painted = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: painted,
          preferredActiveLayerId: layerId,
          partOfStroke: true,
        );
        return;
      }
      final useCase = ref.read(paintCollisionPatternOnMapUseCaseProvider);
      final painted = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: painted,
        preferredActiveLayerId: layerId,
        partOfStroke: true,
      );
    } catch (e) {
      _setPaintError('Failed to paint collision $failureLabel: $e');
    }
  }

  void _eraseCollisionPattern({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
    required String failureLabel,
    required bool partOfStroke,
  }) {
    try {
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseCollisionOnMapUseCaseProvider);
        final erased = useCase.execute(
          map,
          layerId: layerId,
          pos: pos,
        );
        _applyMapMutation(
          previousMap: map,
          updatedMap: erased,
          preferredActiveLayerId: layerId,
          partOfStroke: partOfStroke,
        );
        return;
      }
      final useCase = ref.read(eraseCollisionPatternOnMapUseCaseProvider);
      final erased = useCase.execute(
        map,
        layerId: layerId,
        pos: pos,
        patternSize: patternSize,
        clipToMapBounds: true,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: erased,
        preferredActiveLayerId: layerId,
        partOfStroke: partOfStroke,
      );
    } catch (e) {
      _setPaintError('Failed to erase collision $failureLabel: $e');
    }
  }

  void _setPaintError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  _ActiveTileLayerContext? _resolveActiveTileLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active tile layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! TileLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a tile layer');
      }
      return null;
    }
    return _ActiveTileLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  _ActiveCollisionLayerContext? _resolveActiveCollisionLayerContext({
    required bool emitErrors,
  }) {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      if (emitErrors) {
        _setPaintError('No active collision layer selected');
      }
      return null;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer == null) {
      if (emitErrors) {
        _setPaintError('Active layer not found: $layerId');
      }
      return null;
    }
    if (activeLayer is! CollisionLayer) {
      if (emitErrors) {
        _setPaintError(
            'Active layer "${activeLayer.name}" is not a collision layer');
      }
      return null;
    }
    return _ActiveCollisionLayerContext(
      map: map,
      layerId: layerId,
      layer: activeLayer,
    );
  }

  void addMapLayer({
    required MapLayerKind kind,
    required String name,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(addMapLayerUseCaseProvider);
      // Border layers represent authored visual overlays. Their default
      // creation position is the end of the authored stack, independently of
      // whichever legacy layer happens to be active.
      final insertIndex = kind == MapLayerKind.border
          ? null
          : resolveAuthoredLayerInsertIndex(
              map,
              activeLayerId: state.activeLayerId,
            );
      final result = useCase.execute(
        map,
        kind: kind,
        name: name,
        insertIndex: insertIndex,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.layer.id,
        statusMessage: 'Layer "${result.layer.name}" added',
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add layer: $e');
    }
  }

  void addSmartTileLayer({
    required String presetId,
    required SmartTileUsage usage,
    required String defaultMaterialId,
    required String name,
    int layerSeed = 0,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    state = state.copyWith(
      errorMessage: smartTileCanonicalLayerActionRequiredCode,
    );
  }

  /// Creates one published Smart Tile layer through the canonical atomic
  /// Authoring action, then adopts the resulting manifest and active map.
  /// Re-reads the active map from disk, discarding the desynchronised session.
  ///
  /// Offered as the recovery for [editorReloadRequiredMessage]: once the stored
  /// document has moved ahead, no local mutation can be reconciled, so the only
  /// honest repair is to adopt the durable state.
  Future<bool> reloadActiveMapFromDisk() async {
    final path = state.activeMapPath;
    if (path == null || path.trim().isEmpty) return false;
    final outcome = await activateMap(
      path,
      forceReload: true,
      dirtyDecision: DirtyMapActivationDecision.discard,
    );
    return outcome == MapActivationOutcome.activated;
  }

  /// Saves editor-owned data before a canonical Smart Tile action reads disk.
  Future<bool> _flushSessionForCanonicalSmartTileMutation() async {
    if (state.isProjectDirty && !await saveProjectManifest()) {
      state = state.copyWith(
        errorMessage:
            'Le projet n’a pas pu être enregistré, donc la modification '
            'Smart Tile n’a pas été appliquée. Corrigez l’erreur, puis '
            'réessayez.',
      );
      return false;
    }
    if (!state.isDirty) return true;
    final outcome = await saveActiveMap();
    if (outcome == ActiveMapSaveOutcome.saved) return true;
    // A blocked save has already explained itself (border decision, bulk
    // placement loss, conflict…); only the silent outcomes need a message.
    if (state.errorMessage == null) {
      state = state.copyWith(
        errorMessage:
            'La carte n’a pas pu être enregistrée, donc la modification '
            'Smart Tile n’a pas été appliquée. Enregistrez la carte, puis '
            'réessayez.',
      );
    }
    return false;
  }

  Future<bool> createCanonicalSmartTileLayer({
    required ProjectSmartTilePreset preset,
    String? name,
  }) async {
    final projectRootPath = state.projectRootPath;
    if (state.activeMap == null || projectRootPath == null) return false;
    // The canonical action plans against the stored document, so a dirty
    // session would be planned away. Flushing it here is what the author would
    // do by hand anyway; refusing the click only made them do it twice.
    if (!await _flushSessionForCanonicalSmartTileMutation()) {
      return false;
    }
    final map = state.activeMap;
    if (map == null) return false;
    // A terrain provider fills the whole map, so creating one in front would
    // hide everything under it. Everything else belongs above the active layer.
    final insertIndex = resolveAuthoredLayerInsertIndex(
      map,
      activeLayerId: state.activeLayerId,
      sendToBack: preset.usage == SmartTileUsage.terrain,
    );
    final layerId = _nextCanonicalSmartTileLayerId(map, preset.id);
    final layerName = (name ?? preset.name).trim();
    if (layerName.isEmpty) return false;
    try {
      final queries = ref.read(authoringQueryAdapterProvider);
      final mutations = ref.read(authoringMutationAdapterProvider);
      // The Studio autosaves drafts on a debounce, so the project revision can
      // advance between reading it and planning against it. `plan.stale` is a
      // transient revision conflict — the canonical worker already classifies
      // it retryable — so replan from the latest revision instead of failing.
      late EditorAuthoringMutationResult applied;
      var attempt = 0;
      while (true) {
        final before = await queries.open(projectRootPath);
        final identity = _smartTileEditorMutationIdentity(
          purpose: 'smart-tile-layer-create',
          values: <String, Object?>{
            'mapId': map.id,
            'layerId': layerId,
            'revision': before.snapshotRevision,
          },
        );
        try {
          final plan = await mutations.plan(
            projectRootPath,
            actionId: 'smart_tile.layer.create',
            parameters: <String, Object?>{
              'mapId': map.id,
              'presetId': preset.id,
              'layerId': layerId,
              'name': layerName,
              'insertIndex': insertIndex,
            },
            expectedRevision: before.snapshotRevision,
            idempotencyKey: identity,
            requestId: identity,
          );
          applied = await mutations.apply(
            plan,
            operationId: '$identity-apply',
          );
          break;
        } on Object catch (error) {
          final failure = EditorAuthoringMutationFailure.capture(error);
          if (failure.code != 'plan.stale' ||
              attempt >= _canonicalStalePlanRetryBudget) {
            rethrow;
          }
          attempt++;
        }
      }
      final after = await queries.open(projectRootPath);
      if (after.snapshotRevision != applied.snapshotRevision) {
        throw const EditorAuthoringMutationFailure(
          code: 'smart_tile.layer.snapshot_stale',
          message: 'Le snapshot canonique du nouveau calque est obsolète.',
        );
      }
      final canonicalMap = after.mapById(map.id);
      final mapRevision = after.resourceRevision('map:${map.id}');
      if (canonicalMap == null || mapRevision == null) {
        throw const EditorAuthoringMutationFailure(
          code: 'smart_tile.layer.snapshot_missing',
          message: 'Le nouveau calque est absent du snapshot canonique.',
        );
      }
      return acceptCanonicalSmartTilePublication(
        manifest: after.manifest,
        map: canonicalMap,
        mapRevision: mapRevision,
        layerId: layerId,
        statusMessage: 'Calque Smart Tile « $layerName » ajouté.',
      );
    } on Object catch (error) {
      final failure = EditorAuthoringMutationFailure.capture(error);
      state = state.copyWith(
        errorMessage: canonicalSmartTileFailureMessage(failure),
      );
      return false;
    }
  }

  void setEnvironmentAreaPreset({
    required String environmentLayerId,
    required String areaId,
    required String presetId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      state = state.copyWith(
        errorMessage:
            'Cannot set environment area preset: no active map or project manifest.',
      );
      return;
    }
    try {
      final useCase = SetEnvironmentAreaPresetUseCase();
      final updated = useCase.execute(
        map,
        manifest: project,
        environmentLayerId: environmentLayerId,
        areaId: areaId,
        presetId: presetId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: 'Environment area preset updated',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set environment area preset: $e',
      );
    }
  }

  /// Lot Environment-20 : [EnvironmentLayerContent.targetTileLayerId] uniquement.
  void setEnvironmentLayerTargetTileLayer({
    required String environmentLayerId,
    required String? targetTileLayerId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = SetEnvironmentLayerTargetTileLayerUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: environmentLayerId,
        targetTileLayerId: targetTileLayerId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: environmentLayerId,
        statusMessage: targetTileLayerId == null
            ? 'Environment layer target tile layer cleared'
            : 'Environment layer target tile layer updated',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to set environment target tile layer: $e',
      );
    }
  }

  void enableEnvironmentForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour activer l’environnement.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour activer l’environnement.',
      );
      return;
    }

    try {
      final result = EnableTileLayerEnvironmentAttachmentUseCase().execute(
        map,
        tileLayerId: layerId,
      );
      if (!result.created) {
        state = state.copyWith(
          activeLayerId: layerId,
          selectedEnvironmentAreaId: null,
          environmentMaskEditMode: null,
          statusMessage: 'L’environnement est déjà activé sur ce layer.',
          errorMessage: null,
        );
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: layerId,
        statusMessage: 'Environnement activé sur "${activeLayer.name}"',
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’activer l’environnement : $e',
      );
    }
  }

  void createEnvironmentAreaForActiveTileLayer({
    required String presetId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter une zone : aucune carte ou projet actif.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour ajouter une zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour ajouter une zone.',
      );
      return;
    }

    final pid = presetId.trim();
    if (pid.isEmpty ||
        !project.environmentPresets.any((preset) => preset.id == pid)) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter une zone : choisissez un preset valide.',
      );
      return;
    }

    try {
      final result = CreateTileLayerEnvironmentAreaUseCase().execute(
        map,
        manifest: project,
        tileLayerId: layerId,
        presetId: pid,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: layerId,
        statusMessage: 'Zone d’environnement ajoutée sur "${activeLayer.name}"',
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter une zone : $e',
      );
    }
  }

  void setEnvironmentAreaParamsOverrideForActiveTileLayer(
    EnvironmentGenerationParams params,
  ) {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage: 'Paramètres locaux de génération mis à jour.',
      update: (map, layerId, areaId) {
        return SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
          paramsOverride: params,
        );
      },
    );
  }

  void resetEnvironmentAreaParamsOverrideForActiveTileLayer() {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage:
          'Paramètres locaux réinitialisés sur les valeurs du preset.',
      update: (map, layerId, areaId) {
        return ResetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
        );
      },
    );
  }

  void setEnvironmentAreaSeedForActiveTileLayer(int seed) {
    _updateEnvironmentAreaSettingsForActiveTileLayer(
      statusMessage: 'Seed de la zone d’environnement mis à jour.',
      update: (map, layerId, areaId) {
        return SetTileLayerEnvironmentAreaSeedForTileLayerUseCase().execute(
          map,
          tileLayerId: layerId,
          areaId: areaId,
          seed: seed,
        );
      },
    );
  }

  String? _effectiveEnvironmentAreaIdForActiveTileLayer(
    MapData map,
    String tileLayerId,
  ) {
    final selected = state.selectedEnvironmentAreaId?.trim();
    if (selected != null && selected.isNotEmpty) {
      return selected;
    }

    EnvironmentLayer? attachedEnvironmentLayer;
    var attachedCount = 0;
    for (final layer in map.layers) {
      if (layer is EnvironmentLayer &&
          layer.content.targetTileLayerId?.trim() == tileLayerId) {
        attachedEnvironmentLayer = layer;
        attachedCount++;
      }
    }
    if (attachedCount != 1) return null;

    final areas = attachedEnvironmentLayer!.content.areas;
    if (areas.length != 1) return null;
    return areas.single.id;
  }

  void _updateEnvironmentAreaSettingsForActiveTileLayer({
    required String statusMessage,
    required MapData Function(MapData map, String layerId, String areaId)
        update,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour modifier les paramètres de zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour modifier les paramètres de zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de modifier ses paramètres.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }
    final mode = state.environmentMaskEditMode;

    try {
      final updated = update(map, layerId, target.areaId);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: statusMessage,
      );
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: target.areaId,
        environmentMaskEditMode: mode,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible de modifier les paramètres de génération : $e',
      );
    }
  }

  void generateEnvironmentAreaPlacementsForActiveTileLayer() {
    final map = state.activeMap;
    final manifest = state.project;
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour générer cette zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez une zone d’environnement avant de générer.',
      );
      return;
    }

    try {
      final result =
          GenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
        map,
        manifest: manifest,
        tileLayerId: layerId,
        areaId: areaId,
      );
      if (result.generatedPlacementCount == 0) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: null,
          statusMessage: 'Aucun placement généré pour cette zone.',
          errorMessage: null,
        );
        return;
      }

      final count = result.generatedPlacementCount;
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage:
            '$count placement(s) généré(s) dans ce layer pour la zone « ${result.areaId} ».',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de générer cette zone : $e',
      );
    }
  }

  void clearEnvironmentGeneratedPlacementsForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’effacer : aucune carte active.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour effacer les placements générés.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour effacer les placements générés.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant d’effacer les placements générés.',
      );
      return;
    }

    try {
      final result =
          ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
        map,
        tileLayerId: layerId,
        areaId: areaId,
      );
      if (result.clearedReferenceCount == 0) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: null,
          statusMessage: 'Aucun placement généré à effacer pour cette zone.',
          errorMessage: null,
        );
        return;
      }

      final removedIds = result.removedPlacementIds.toSet();
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          removedIds.contains(selectionBefore);

      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: _clearTileLayerGeneratedPlacementsStatusMessage(result),
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’effacer les placements générés de cette zone : $e',
      );
    }
  }

  String _clearTileLayerGeneratedPlacementsStatusMessage(
    ClearTileLayerEnvironmentAreaGeneratedPlacementsResult result,
  ) {
    final removed = result.removedPlacementCount;
    final missing = result.clearedReferenceCount - removed;
    if (missing > 0) {
      return '$removed placement(s) effacé(s), $missing référence(s) '
          'introuvable(s) nettoyée(s).';
    }
    return '$removed placement(s) généré(s) effacé(s) pour la zone « ${result.areaId} ».';
  }

  void regenerateEnvironmentAreaPlacementsForActiveTileLayer() {
    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
      shuffle: false,
    );
  }

  void shuffleEnvironmentAreaPlacementsForActiveTileLayer() {
    _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer(
      shuffle: true,
    );
  }

  void _regenerateOrShuffleEnvironmentAreaPlacementsForActiveTileLayer({
    required bool shuffle,
  }) {
    final map = state.activeMap;
    final manifest = state.project;
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Impossible de shuffler : aucune carte active ou manifeste projet.'
            : 'Impossible de régénérer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez un TileLayer pour shuffler cette zone.'
            : 'Sélectionnez un TileLayer pour régénérer cette zone.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Sélectionnez une zone d’environnement avant de shuffler.'
            : 'Sélectionnez une zone d’environnement avant de régénérer.',
      );
      return;
    }

    try {
      final result = shuffle
          ? ShuffleTileLayerEnvironmentAreaPlacementsUseCase().execute(
              map,
              manifest: manifest,
              tileLayerId: layerId,
              areaId: areaId,
            )
          : RegenerateTileLayerEnvironmentAreaPlacementsUseCase().execute(
              map,
              manifest: manifest,
              tileLayerId: layerId,
              areaId: areaId,
            );

      final removedIds = result.removedPlacementIds.toSet();
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          removedIds.contains(selectionBefore);

      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: _tileLayerRegenerationStatusMessage(
          result,
          shuffle: shuffle,
        ),
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: null,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: shuffle
            ? 'Impossible de shuffler cette zone : $e'
            : 'Impossible de régénérer cette zone : $e',
      );
    }
  }

  String _tileLayerRegenerationStatusMessage(
    TileLayerEnvironmentRegenerationResult result, {
    required bool shuffle,
  }) {
    if (result.generatedPlacementCount == 0) {
      return shuffle
          ? 'Seed mélangée : aucun nouveau placement pour la zone « ${result.areaId} ».'
          : 'Les placements générés ont été effacés ; aucun nouveau placement n’a été généré pour la zone « ${result.areaId} ».';
    }
    return shuffle
        ? 'Seed mélangée : ${result.generatedPlacementCount} placement(s) régénéré(s) pour la zone « ${result.areaId} ».'
        : 'Zone « ${result.areaId} » régénérée : ${result.generatedPlacementCount} placement(s).';
  }

  void startEnvironmentMaskPaintingForActiveTileLayer() {
    _startEnvironmentMaskEditingForActiveTileLayer(
      mode: EnvironmentMaskEditMode.paint,
    );
  }

  void startEnvironmentMaskErasingForActiveTileLayer() {
    _startEnvironmentMaskEditingForActiveTileLayer(
      mode: EnvironmentMaskEditMode.erase,
    );
  }

  void _startEnvironmentMaskEditingForActiveTileLayer({
    required EnvironmentMaskEditMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sélectionnez une zone d’environnement avant de peindre.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }

    state = state.copyWith(
      activeLayerId: layerId,
      selectedEnvironmentAreaId: target.areaId,
      environmentMaskEditMode: mode,
      statusMessage: mode == EnvironmentMaskEditMode.erase
          ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
          : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
      errorMessage: null,
    );
  }

  void stopEnvironmentMaskPainting() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Peinture du masque arrêtée.',
      errorMessage: null,
    );
  }

  void startDeletingGeneratedEnvironmentPlacementForActiveTileLayer() {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
      );
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      final hasAttachment = map.layers.any(
        (layer) =>
            layer is EnvironmentLayer &&
            layer.content.targetTileLayerId?.trim() == layerId,
      );
      state = state.copyWith(
        errorMessage: hasAttachment
            ? 'La zone d’environnement sélectionnée est introuvable.'
            : 'Activez d’abord l’environnement sur ce layer.',
      );
      return;
    }
    if (target.area.generatedPlacementIds.isEmpty) {
      state = state.copyWith(
        activeLayerId: layerId,
        selectedEnvironmentAreaId: target.areaId,
        environmentMaskEditMode: null,
        statusMessage:
            'Aucun placement généré à supprimer individuellement pour cette zone.',
        errorMessage: null,
      );
      return;
    }

    state = state.copyWith(
      activeLayerId: layerId,
      selectedEnvironmentAreaId: target.areaId,
      environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
      statusMessage:
          'Suppression active : cliquez un élément généré pour le retirer.',
      errorMessage: null,
    );
  }

  void stopDeletingGeneratedEnvironmentPlacement() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Suppression des éléments générés arrêtée.',
      errorMessage: null,
    );
  }

  bool deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    if (state.environmentMaskEditMode !=
        EnvironmentMaskEditMode.generatedDelete) {
      state = state.copyWith(
        errorMessage:
            'Activez la suppression d’un élément généré avant de cliquer.',
      );
      return false;
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return false;
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez un TileLayer pour supprimer un élément généré.',
      );
      return false;
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      state = state.copyWith(
        errorMessage:
            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
      );
      return false;
    }

    try {
      final result =
          DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: state.project,
        tileLayerId: layerId,
        areaId: areaId,
        pos: pos,
      );
      if (!result.removed) {
        state = state.copyWith(
          activeLayerId: result.tileLayerId,
          selectedEnvironmentAreaId: result.areaId,
          environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
          statusMessage:
              'Aucun placement généré de cette zone à supprimer ici.',
          errorMessage: null,
        );
        return false;
      }

      final removedId = result.removedPlacementId!;
      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
      final clearSelection = selectionBefore != null &&
          selectionBefore.isNotEmpty &&
          selectionBefore == removedId;
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Placement généré supprimé.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        selectedPlacedElementInstanceId:
            clearSelection ? null : state.selectedPlacedElementInstanceId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de supprimer cet élément généré : $e',
      );
      return false;
    }
  }

  void selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
    String elementId,
  ) {
    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requestedElementId: elementId,
        requireGeneratedPlacements: false,
        allowImplicitSelection: false,
      );
      ref
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .select(selection.item.elementId);
      state = state.copyWith(
        activeLayerId: selection.tileLayerId,
        selectedEnvironmentAreaId: selection.areaId,
        statusMessage:
            'Élément à ajouter : ${selection.element.name.isEmpty ? selection.element.id : selection.element.name}.',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de sélectionner cet élément généré : $e',
      );
    }
  }

  void startAddingGeneratedEnvironmentPlacementForActiveTileLayer() {
    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requireGeneratedPlacements: true,
        allowImplicitSelection: true,
      );
      ref
          .read(environmentGeneratedPlacementAddElementProvider.notifier)
          .select(selection.item.elementId);
      state = state.copyWith(
        activeLayerId: selection.tileLayerId,
        selectedEnvironmentAreaId: selection.areaId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        statusMessage:
            'Ajout actif : cliquez sur la carte pour ajouter cet élément.',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        environmentMaskEditMode: null,
        errorMessage: 'Impossible d’activer l’ajout : $e',
      );
    }
  }

  void stopAddingGeneratedEnvironmentPlacement() {
    state = state.copyWith(
      environmentMaskEditMode: null,
      statusMessage: 'Ajout des éléments générés arrêté.',
      errorMessage: null,
    );
  }

  bool addGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    if (state.environmentMaskEditMode != EnvironmentMaskEditMode.generatedAdd) {
      state = state.copyWith(
        errorMessage: 'Activez l’ajout d’un élément généré avant de cliquer.',
      );
      return false;
    }

    try {
      final selection = _resolveGeneratedPlacementAddSelectionForTileLayer(
        requireGeneratedPlacements: true,
        allowImplicitSelection: true,
      );
      final result =
          AddTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: selection.project,
        tileLayerId: selection.tileLayerId,
        areaId: selection.areaId,
        elementId: selection.item.elementId,
        pos: pos,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: result.tileLayerId,
        statusMessage: 'Élément généré ajouté.',
      );
      state = state.copyWith(
        activeLayerId: result.tileLayerId,
        selectedEnvironmentAreaId: result.areaId,
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
        errorMessage:
            'Impossible d’ajouter ici : position hors carte ou footprint invalide. $e',
      );
      return false;
    }
  }

  void setEnvironmentMaskBrushSize(int size) {
    if (!isValidEnvironmentMaskBrushSize(size)) {
      state = state.copyWith(
        errorMessage: 'taille du pinceau invalide : choisissez 1, 3, 5 ou 7.',
      );
      return;
    }
    final current = ref.read(environmentMaskBrushSizeProvider);
    if (current == size) {
      state = state.copyWith(errorMessage: null);
      return;
    }
    ref.read(environmentMaskBrushSizeProvider.notifier).setSize(size);
    state = state.copyWith(errorMessage: null);
  }

  /// Lot Environment-22 : area sélectionnée pour édition masque, sans activer paint/erase.
  void selectEnvironmentAreaForMaskEditing({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layer = _findLayerById(map, environmentLayerId);
    if (layer is! EnvironmentLayer) return;
    if (!layer.content.areas.any((a) => a.id == areaId)) return;
    state = state.copyWith(
      activeLayerId: environmentLayerId,
      selectedEnvironmentAreaId: areaId,
      errorMessage: null,
    );
  }

  /// Lot Environment-22 : active la peinture du masque pour une zone.
  void startEnvironmentAreaMaskPaint({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.paint,
    );
  }

  /// Lot Environment-22 : active l’effacement du masque pour une zone.
  void startEnvironmentAreaMaskErase({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.erase,
    );
  }

  /// Active l’ajout manuel d’un placement généré pour une zone.
  void startEnvironmentAreaGeneratedPlacementAdd({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.generatedAdd,
    );
  }

  /// Active la suppression au clic d’un placement généré pour une zone.
  void startEnvironmentAreaGeneratedPlacementDelete({
    required String environmentLayerId,
    required String areaId,
  }) {
    _startEnvironmentAreaEditMode(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      mode: EnvironmentMaskEditMode.generatedDelete,
    );
  }

  void _startEnvironmentAreaEditMode({
    required String environmentLayerId,
    required String areaId,
    required EnvironmentMaskEditMode mode,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layer = _findLayerById(map, environmentLayerId);
    if (layer is! EnvironmentLayer) return;
    if (!layer.content.areas.any((a) => a.id == areaId)) return;
    state = state.copyWith(
      activeLayerId: environmentLayerId,
      selectedEnvironmentAreaId: areaId,
      environmentMaskEditMode: mode,
      errorMessage: null,
    );
  }

  /// Lot Environment-22 : quitte le mode d’édition sans changer l’area sélectionnée.
  void stopEnvironmentAreaMaskEditing() {
    state = state.copyWith(environmentMaskEditMode: null, errorMessage: null);
  }

  /// Lot Environment-25 : génère des candidats (Lot 23) puis les applique (Lot 24).
  ///
  /// Aucune sauvegarde disque. En cas d’échec ou zéro placement : pas de mutation
  /// de [EditorState.activeMap] (sauf messages).
  void generateEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    final manifest = state.project;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (map == null || manifest == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layer = _findLayerById(map, envId);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        errorMessage:
            'Impossible de générer : calque environnement introuvable.',
      );
      return;
    }
    EnvironmentArea? area;
    for (final a in layer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      state = state.copyWith(
        errorMessage: 'Impossible de générer : zone introuvable.',
      );
      return;
    }
    if (area.generatedPlacementIds.isNotEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage:
            'Cette zone possède déjà des placements générés. Utilisez '
            '« Effacer les placements générés », « Régénérer » ou '
            '« Mélanger et régénérer ».',
      );
      return;
    }

    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (gen.hasErrors) {
      final first = gen.issues.firstWhere(
        (i) => i.severity == EnvironmentGenerationIssueSeverity.error,
        orElse: () => gen.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible de générer cette zone : ${_environmentGenerationIssueMessage(first)}',
      );
      return;
    }
    if (gen.placements.isEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré pour cette zone.',
      );
      return;
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
      candidates: gen.placements,
    );
    if (apply.hasErrors) {
      final first = apply.issues.firstWhere(
        (i) => i.severity == EnvironmentApplyIssueSeverity.error,
        orElse: () => apply.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible d’appliquer les placements : ${_environmentApplyIssueMessage(first)}',
      );
      return;
    }

    final n = apply.appliedPlacementCount;
    _applyMapMutation(
      previousMap: map,
      updatedMap: apply.map,
      preferredActiveLayerId: envId,
      statusMessage: '$n placement(s) généré(s) pour la zone « $aid ».',
    );
    state = state.copyWith(
      selectedEnvironmentAreaId: aid,
      environmentMaskEditMode: null,
    );
  }

  String _environmentGenerationIssueMessage(EnvironmentGenerationIssue issue) {
    return issue.message;
  }

  String _environmentApplyIssueMessage(EnvironmentApplyIssue issue) {
    return issue.message;
  }

  /// Lot Environment-26 : retire les [MapPlacedElement] listés dans
  /// [EnvironmentArea.generatedPlacementIds] puis vide cette liste.
  void clearEnvironmentGeneratedPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    final map = state.activeMap;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (map == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’effacer : aucune carte active.',
      );
      return;
    }
    final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
    final result = ClearEnvironmentGeneratedPlacementsUseCase().execute(
      map,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (result.hasErrors) {
      final first = result.issues.firstWhere(
        (i) => i.severity == EnvironmentClearIssueSeverity.error,
        orElse: () => result.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible d’effacer les placements générés : ${first.message}',
      );
      return;
    }
    if (result
        .issuesForKind(EnvironmentClearIssueKind.noGeneratedPlacements)
        .isNotEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré à effacer pour cette zone.',
      );
      return;
    }

    final removedIds =
        result.clearedPlacements.map((c) => c.placedElementId).toSet();
    final clearSelection = selectionBefore != null &&
        selectionBefore.isNotEmpty &&
        removedIds.contains(selectionBefore);

    _applyMapMutation(
      previousMap: map,
      updatedMap: result.map,
      preferredActiveLayerId: envId,
      statusMessage: _clearGeneratedPlacementsStatusMessage(result, aid),
    );
    if (clearSelection) {
      state = state.copyWith(selectedPlacedElementInstanceId: null);
    }
  }

  String _clearGeneratedPlacementsStatusMessage(
    EnvironmentClearResult result,
    String areaId,
  ) {
    final n = result.clearedPlacementCount;
    final missing = result
        .issuesForKind(EnvironmentClearIssueKind.missingGeneratedPlacement)
        .length;
    if (missing > 0) {
      return '$n placement(s) effacé(s), $missing référence(s) introuvable(s) '
          'nettoyée(s).';
    }
    return '$n placement(s) généré(s) effacé(s) pour la zone « $areaId ».';
  }

  /// Lot Environment-27 : efface les placements générés, garde la seed, regénère et applique.
  void regenerateEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    _regenerateOrShuffleEnvironmentAreaPlacements(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      shuffle: false,
    );
  }

  /// Lot Environment-27 : optionnellement clear, nouvelle seed LCG, generate + apply.
  void shuffleEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
  }) {
    _regenerateOrShuffleEnvironmentAreaPlacements(
      environmentLayerId: environmentLayerId,
      areaId: areaId,
      shuffle: true,
    );
  }

  void _regenerateOrShuffleEnvironmentAreaPlacements({
    required String environmentLayerId,
    required String areaId,
    required bool shuffle,
  }) {
    final original = state.activeMap;
    final manifest = state.project;
    final envId = environmentLayerId.trim();
    final aid = areaId.trim();
    if (original == null || manifest == null) {
      state = state.copyWith(
        errorMessage: 'Impossible : aucune carte active ou manifeste projet.',
      );
      return;
    }
    final layer = _findLayerById(original, envId);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        errorMessage: 'Impossible : calque environnement introuvable.',
      );
      return;
    }
    EnvironmentArea? area;
    for (final a in layer.content.areas) {
      if (a.id == aid) {
        area = a;
        break;
      }
    }
    if (area == null) {
      state = state.copyWith(
        errorMessage: 'Impossible : zone introuvable.',
      );
      return;
    }

    if (!shuffle && area.generatedPlacementIds.isEmpty) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Aucun placement généré à régénérer pour cette zone.',
      );
      return;
    }

    var working = original;
    var staged = false;

    final shouldClear = shuffle ? area.generatedPlacementIds.isNotEmpty : true;

    if (shouldClear) {
      final clearR = ClearEnvironmentGeneratedPlacementsUseCase().execute(
        working,
        environmentLayerId: envId,
        areaId: aid,
      );
      if (clearR.hasErrors) {
        final first = clearR.issues.firstWhere(
          (i) => i.severity == EnvironmentClearIssueSeverity.error,
          orElse: () => clearR.issues.first,
        );
        state = state.copyWith(
          errorMessage:
              'Impossible de ${shuffle ? 'mélanger et régénérer' : 'régénérer'} '
              'cette zone : ${first.message}',
        );
        return;
      }
      working = clearR.map;
      staged = true;
    }

    if (shuffle) {
      final layerNow = _findLayerById(working, envId);
      if (layerNow is! EnvironmentLayer) {
        state = state.copyWith(
          errorMessage:
              'Impossible de mélanger : calque environnement introuvable.',
        );
        return;
      }
      EnvironmentArea? areaNow;
      for (final a in layerNow.content.areas) {
        if (a.id == aid) {
          areaNow = a;
          break;
        }
      }
      if (areaNow == null) {
        state = state.copyWith(
          errorMessage: 'Impossible de mélanger : zone introuvable.',
        );
        return;
      }
      final nextS = nextEnvironmentAreaSeed(areaNow.seed);
      final seedRes = SetEnvironmentAreaSeedUseCase().execute(
        working,
        environmentLayerId: envId,
        areaId: aid,
        seed: nextS,
      );
      if (!seedRes.isSuccess) {
        state = state.copyWith(
          errorMessage:
              'Impossible de mélanger la seed : ${seedRes.failureMessage}',
        );
        return;
      }
      working = seedRes.map!;
      staged = true;
    }

    final gen = GenerateEnvironmentAreaPlacementsUseCase().execute(
      working,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
    );
    if (gen.hasErrors) {
      final first = gen.issues.firstWhere(
        (i) => i.severity == EnvironmentGenerationIssueSeverity.error,
        orElse: () => gen.issues.first,
      );
      state = state.copyWith(
        errorMessage:
            'Impossible de ${shuffle ? 'mélanger et régénérer' : 'régénérer'} '
            'cette zone : ${_environmentGenerationIssueMessage(first)}',
      );
      return;
    }

    if (gen.placements.isEmpty) {
      if (!staged) {
        state = state.copyWith(
          errorMessage: null,
          statusMessage: 'Aucun placement généré pour cette zone.',
        );
        return;
      }
      _applyMapMutation(
        previousMap: original,
        updatedMap: working,
        preferredActiveLayerId: envId,
        statusMessage: shuffle
            ? 'Mélangé : seed mise à jour ; aucun nouveau placement pour la '
                'zone « $aid » (effacement des placements précédents effectué).'
            : 'Les placements générés ont été effacés ; aucun nouveau placement '
                'n’a été généré pour la zone « $aid ».',
      );
      state = state.copyWith(
        selectedEnvironmentAreaId: aid,
        environmentMaskEditMode: null,
      );
      return;
    }

    final apply = ApplyEnvironmentGeneratedPlacementsUseCase().execute(
      working,
      manifest: manifest,
      environmentLayerId: envId,
      areaId: aid,
      candidates: gen.placements,
    );
    if (apply.hasErrors) {
      final first = apply.issues.firstWhere(
        (i) => i.severity == EnvironmentApplyIssueSeverity.error,
        orElse: () => apply.issues.first,
      );
      state = state.copyWith(
        errorMessage: 'Impossible d’appliquer après '
            '${shuffle ? 'mélange' : 'régénération'} : '
            '${_environmentApplyIssueMessage(first)}',
      );
      return;
    }

    final n = apply.appliedPlacementCount;
    final status = shuffle
        ? 'Seed mélangée : $n placement(s) régénéré(s) pour la zone « $aid ».'
        : 'Zone « $aid » régénérée : $n placement(s).';
    _applyMapMutation(
      previousMap: original,
      updatedMap: apply.map,
      preferredActiveLayerId: envId,
      statusMessage: status,
    );
    state = state.copyWith(
      selectedEnvironmentAreaId: aid,
      environmentMaskEditMode: null,
    );
  }

  /// Lot Environment-22 : applique paint ou erase selon [environmentMaskEditMode].
  void paintEnvironmentAreaMaskAt(
    GridPos pos, {
    bool partOfStroke = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final layerId = state.activeLayerId;
    final areaId = state.selectedEnvironmentAreaId;
    final mode = state.environmentMaskEditMode;
    if (layerId == null || areaId == null || mode == null) {
      return;
    }
    if (mode != EnvironmentMaskEditMode.paint &&
        mode != EnvironmentMaskEditMode.erase) {
      return;
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      return;
    }
    final isActive = mode == EnvironmentMaskEditMode.paint;
    try {
      final useCase = PaintEnvironmentAreaMaskBrushStrokeUseCase();
      final updated = useCase.execute(
        map,
        environmentLayerId: target.environmentLayerId,
        areaId: target.areaId,
        center: pos,
        brushSize: ref.read(environmentMaskBrushSizeProvider),
        isActive: isActive,
      );
      if (identical(updated, map)) {
        return;
      }
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: target.activeLayerId,
        partOfStroke: partOfStroke,
        statusMessage: 'Masque d’environnement mis à jour',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible d’éditer le masque d’environnement : $e',
      );
    }
  }

  void renameMapLayer(String layerId, String name) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(renameMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        name: name,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Calque renommé',
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Impossible de renommer le calque : $e');
    }
  }

  void deleteMapLayer(String layerId, {bool confirmBulkPlacementLoss = false}) {
    final map = state.activeMap;
    if (map == null) return;
    final removedIndex = _findLayerIndexById(map, layerId);
    if (removedIndex < 0) return;
    try {
      final useCase = ref.read(deleteMapLayerUseCaseProvider);
      final updated = useCase.execute(map, layerId: layerId);
      final removedPlacements =
          updated.placedElements.length < map.placedElements.length;
      final nextActiveLayerId = state.activeLayerId == layerId
          ? _editorMapSessionCoordinator.resolveFallbackLayerIdAfterDeletion(
              updated,
              removedIndex: removedIndex,
            )
          : _editorMapSessionCoordinator.resolveActiveLayerId(
              updated,
              preferredLayerId: state.activeLayerId,
            );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: nextActiveLayerId,
        statusMessage: 'Calque supprimé',
      );
      // Deleting a layer drops the placements it hosted, which can trip the
      // save-time bulk placement loss guard. An author who confirmed this
      // deletion has already accepted that loss, so carry the confirmation
      // over instead of blocking the save with no way out.
      if (removedPlacements) {
        _confirmedBulkPlacementLossBaseline =
            confirmBulkPlacementLoss ? state.savedMapSnapshot : null;
      }
      _coerceEnvironmentMaskSelectionAfterMapChange();
    } on EditorValidationException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de supprimer le calque : $e');
    }
  }

  void deleteAllMapLayers({bool confirmBulkPlacementLoss = false}) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(deleteAllMapLayersUseCaseProvider);
      final updated = useCase.execute(map);
      final removedPlacements =
          updated.placedElements.length < map.placedElements.length;
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId:
            _editorMapSessionCoordinator.resolveActiveLayerId(updated),
        statusMessage: 'Tous les calques supprimés',
      );
      if (removedPlacements) {
        _confirmedBulkPlacementLossBaseline =
            confirmBulkPlacementLoss ? state.savedMapSnapshot : null;
      }
      _coerceEnvironmentMaskSelectionAfterMapChange();
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de supprimer tous les calques : $e');
    }
  }

  void moveMapLayerGroupUp(String layerId) {
    _moveMapLayerGroup(
      layerId,
      MapLayerGroupMoveDirection.up,
    );
  }

  void moveMapLayerGroupDown(String layerId) {
    _moveMapLayerGroup(
      layerId,
      MapLayerGroupMoveDirection.down,
    );
  }

  void _moveMapLayerGroup(
    String layerId,
    MapLayerGroupMoveDirection direction,
  ) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      const service = MapLayerGroupService();
      final updated = service.moveAdjacent(
        map: map,
        layerId: layerId,
        direction: direction,
      );
      if (updated == map) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _validateLayerGroupReorder(
        previousMap: map,
        updatedMap: updated,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Groupe de calques réorganisé',
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible de réorganiser le groupe de calques : '
            '$error',
      );
    }
  }

  /// Places one visible layer group before a top-first presentation slot.
  void moveMapLayerGroupBeforeVisibleIndex(
    String layerId,
    int beforeVisibleIndex,
  ) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      const service = MapLayerGroupService();
      final updated = service.moveBeforeGroupIndex(
        map: map,
        layerId: layerId,
        beforeGroupIndex: beforeVisibleIndex,
      );
      if (updated == map) {
        state = state.copyWith(errorMessage: null);
        return;
      }
      _validateLayerGroupReorder(
        previousMap: map,
        updatedMap: updated,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Groupe de calques réorganisé',
      );
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible de réorganiser le groupe de calques : '
            '$error',
      );
    }
  }

  void _validateLayerGroupReorder({
    required MapData previousMap,
    required MapData updatedMap,
  }) {
    try {
      MapValidator.validate(updatedMap);
    } catch (updatedError, updatedStackTrace) {
      try {
        MapValidator.validate(previousMap);
      } catch (_) {
        // Reordering preserves every layer instance and only changes their
        // order. Keep repairable legacy maps editable when they already carry
        // an unrelated validation error, such as an orphan Environment layer.
        return;
      }
      Error.throwWithStackTrace(updatedError, updatedStackTrace);
    }
  }

  void moveMapLayerUp(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void moveMapLayerDown(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerForward(String layerId) {
    _moveMapLayer(layerId, 1);
  }

  void moveMapLayerBackward(String layerId) {
    _moveMapLayer(layerId, -1);
  }

  void _moveMapLayer(String layerId, int direction) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(moveMapLayerUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        direction: direction,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Calque réorganisé',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de réorganiser le calque : $e');
    }
  }

  void reorderMapLayers(int oldIndex, int newIndex) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(reorderMapLayersUseCaseProvider);
      final updated = useCase.execute(
        map,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      if (updated != map) {
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Calque réorganisé',
        );
      } else {
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de réorganiser le calque : $e');
    }
  }

  /// Places [layerId] before [beforeIndex] (0 = top of list, [layers.length] = bottom).
  void moveMapLayerBeforeIndex(String layerId, int beforeIndex) {
    final map = state.activeMap;
    if (map == null) return;
    final oldIndex = map.layers.indexWhere((layer) => layer.id == layerId);
    if (oldIndex < 0) return;
    reorderMapLayers(oldIndex, beforeIndex);
  }

  void setMapLayerVisibility(String layerId, bool isVisible) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerVisibilityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        isVisible: isVisible,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: isVisible ? 'Calque affiché' : 'Calque masqué',
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Impossible de mettre à jour le calque : $e');
    }
  }

  void setMapLayerOpacity(
    String layerId,
    double opacity, {
    bool partOfStroke = false,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final useCase = ref.read(setMapLayerOpacityUseCaseProvider);
      final updated = useCase.execute(
        map,
        layerId: layerId,
        opacity: opacity,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: state.activeLayerId,
        partOfStroke: partOfStroke,
      );
    } catch (e) {
      state = state.copyWith(
          errorMessage:
              'Impossible de mettre à jour l\'opacité du calque : $e');
    }
  }

  void createBorderFeature({
    required String layerId,
    required String blueprintId,
    required String name,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final blueprint = _publishedBorderBlueprint(blueprintId);
      final result = _borderFeatureAuthoringController.createFeature(
        map: map,
        layerId: layerId,
        blueprint: blueprint,
        name: name.trim(),
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: layerId,
        statusMessage: 'Bordure « ${result.feature.name} » créée',
      );
      ref.read(activeBorderFeatureControllerProvider.notifier).selectFeature(
            map: result.map,
            layerId: layerId,
            featureId: result.feature.id,
          );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer la bordure : $e',
      );
    }
  }

  void selectBorderFeature({
    required String layerId,
    required String featureId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      ref.read(activeBorderFeatureControllerProvider.notifier).selectFeature(
            map: map,
            layerId: layerId,
            featureId: featureId,
          );
      _resetCanvasObjectSelectionCycle();
      state = state.copyWith(
        selectedPlacedElementInstanceId: null,
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedGameplayZoneId: null,
        selectedTriggerId: null,
        selectedWarpId: null,
        selectedEnvironmentAreaId: null,
        npcWaypointPlacementEntityId: null,
        statusMessage: 'Bordure sélectionnée',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de sélectionner la bordure : $e',
      );
    }
  }

  void renameBorderFeature({
    required String layerId,
    required String featureId,
    required String name,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Le nom de la bordure ne peut pas être vide.',
      );
      return;
    }
    try {
      final updated = _borderFeatureAuthoringController.renameFeature(
        map: map,
        layerId: layerId,
        featureId: featureId,
        name: normalizedName,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: 'Bordure renommée',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de renommer la bordure : $e',
      );
    }
  }

  void reorderBorderFeature({
    required String layerId,
    required String featureId,
    required int newIndex,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _borderFeatureAuthoringController.reorderFeature(
        map: map,
        layerId: layerId,
        featureId: featureId,
        newIndex: newIndex,
      );
      if (identical(updated, map) || updated == map) return;
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: 'Ordre des bordures mis à jour',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de réordonner la bordure : $e',
      );
    }
  }

  void deleteBorderFeature({
    required String layerId,
    required String featureId,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      final updated = _borderFeatureAuthoringController.deleteFeature(
        map: map,
        layerId: layerId,
        featureId: featureId,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: layerId,
        statusMessage: 'Bordure supprimée',
      );
      ref.read(activeBorderFeatureControllerProvider.notifier).reconcile(
            map: updated,
            activeLayerId: layerId,
          );
      if (state.activeTool == EditorToolType.borderPaint ||
          state.activeTool == EditorToolType.borderErase) {
        final activeFeature =
            ref.read(activeBorderFeatureControllerProvider).activeFeatureId;
        if (activeFeature == null) {
          state = state.copyWith(activeTool: EditorToolType.selection);
        }
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de supprimer la bordure : $e',
      );
    }
  }

  void changeBorderFeatureBlueprint(BorderBlueprintChangePreview preview) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      _assertBorderBlueprintPreviewCatalogCurrent(preview);
      final updated = _borderFeatureAuthoringController.applyBlueprintChange(
        map: map,
        preview: preview,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: preview.layerId,
        statusMessage: 'Blueprint de bordure modifié',
      );
      ref.read(activeBorderFeatureControllerProvider.notifier).selectFeature(
            map: updated,
            layerId: preview.layerId,
            featureId: preview.featureId,
          );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de changer le blueprint : $e',
      );
    }
  }

  void resetBorderFeatureBlueprint(BorderBlueprintChangePreview preview) {
    final map = state.activeMap;
    if (map == null) return;
    try {
      _assertBorderBlueprintPreviewCatalogCurrent(preview);
      final updated =
          _borderFeatureAuthoringController.resetFeatureForBlueprintChange(
        map: map,
        preview: preview,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: updated,
        preferredActiveLayerId: preview.layerId,
        statusMessage: 'Bordure remise à zéro pour le nouveau blueprint',
      );
      ref.read(activeBorderFeatureControllerProvider.notifier).selectFeature(
            map: updated,
            layerId: preview.layerId,
            featureId: preview.featureId,
          );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de remettre la bordure à zéro : $e',
      );
    }
  }

  void createBorderFeatureFromBlueprintChange({
    required BorderBlueprintChangePreview preview,
    required String name,
  }) {
    final map = state.activeMap;
    if (map == null) return;
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Le nom de la bordure ne peut pas être vide.',
      );
      return;
    }
    try {
      final targetBlueprint =
          _publishedBorderBlueprint(preview.afterBlueprintId);
      _assertBorderBlueprintPreviewCatalogCurrent(preview);
      final result =
          _borderFeatureAuthoringController.createFeatureFromBlueprintChange(
        map: map,
        preview: preview,
        targetBlueprint: targetBlueprint,
        name: normalizedName,
      );
      _applyMapMutation(
        previousMap: map,
        updatedMap: result.map,
        preferredActiveLayerId: preview.layerId,
        statusMessage: 'Bordure « ${result.feature.name} » créée séparément',
      );
      ref.read(activeBorderFeatureControllerProvider.notifier).selectFeature(
            map: result.map,
            layerId: preview.layerId,
            featureId: result.feature.id,
          );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Impossible de créer la bordure séparée : $e',
      );
    }
  }

  BorderBlueprintRecord _publishedBorderBlueprint(String blueprintId) {
    final record = state.project?.borderCatalog.recordById(blueprintId);
    if (record == null || record.latestPublished == null) {
      throw StateError('Le blueprint sélectionné n’est pas publié.');
    }
    if (record.isDeprecated) {
      throw StateError('Le blueprint sélectionné est obsolète.');
    }
    return record;
  }

  void _assertBorderBlueprintPreviewCatalogCurrent(
    BorderBlueprintChangePreview preview,
  ) {
    final current = _publishedBorderBlueprint(preview.afterBlueprintId);
    if (current.latestPublished != preview.targetRevision) {
      throw StateError(
        'La révision publiée a changé depuis la création de l’aperçu.',
      );
    }
  }

  void selectTool(EditorToolType tool) {
    state = _mapSelectionController.selectTool(
      current: state,
      tool: tool,
    );
  }

  @override
  WorldMapToolActivationResult activateWorldMapTool(
    WorldMapToolActivationRequest request,
  ) {
    final source = state;
    final preflight = assessWorldMapToolActivation(
      source: worldMapToolActivationSourceFromState(source),
      request: request,
      activeBorderFeatureId:
          ref.read(activeBorderFeatureControllerProvider).activeFeatureId,
    );
    if (preflight.rejectionReason case final reason?) {
      return WorldMapToolActivationResult(
        accepted: false,
        rejectionReason: reason,
      );
    }

    final candidate = _worldMapToolActivationCandidate(
      source: source,
      request: request,
      preflight: preflight,
    );
    if (request is! ActivateWorldMapSelection) {
      _resetCanvasObjectSelectionCycle();
    }
    state = candidate;
    return WorldMapToolActivationResult(
      accepted: true,
      resultingTool: preflight.resultingTool,
    );
  }

  @override
  WorldMapToolActivationResult setActiveWorldMapLayer({
    required String layerId,
    required WorldMapToolActivationRequest toolRequest,
  }) {
    final source = state;
    final map = source.activeMap;
    if (map == null) {
      return const WorldMapToolActivationResult(
        accepted: false,
        rejectionReason: 'No active map selected.',
      );
    }
    if (!map.layers.any((layer) => layer.id == layerId)) {
      final reason = 'Layer not found: $layerId';
      state = source.copyWith(errorMessage: reason);
      return WorldMapToolActivationResult(
        accepted: false,
        rejectionReason: reason,
      );
    }

    final paletteSession = _rememberActivePaletteContext(source);
    final destination = _activatePaletteContext(
      source.copyWith(
        activeLayerId: layerId,
        paletteSession: paletteSession,
        selectedPlacedElementInstanceId: null,
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
        errorMessage: null,
      ),
    );
    final destinationBorderSelection = resolveActiveBorderFeatureSelection(
      current: ref.read(activeBorderFeatureControllerProvider),
      map: destination.activeMap,
      activeLayerId: destination.activeLayerId,
    );
    final preflight = assessWorldMapToolActivation(
      source: worldMapToolActivationSourceFromState(destination),
      request: toolRequest,
      activeBorderFeatureId: destinationBorderSelection.activeFeatureId,
    );
    if (preflight.rejectionReason case final reason?) {
      const fallbackRequest = ActivateWorldMapSelection();
      final fallbackPreflight = assessWorldMapToolActivation(
        source: worldMapToolActivationSourceFromState(destination),
        request: fallbackRequest,
      );
      state = _worldMapToolActivationCandidate(
        source: destination,
        request: fallbackRequest,
        preflight: fallbackPreflight,
      );
      return WorldMapToolActivationResult(
        accepted: false,
        resultingTool: EditorToolType.selection,
        rejectionReason: reason,
      );
    }

    final candidate = _worldMapToolActivationCandidate(
      source: destination,
      request: toolRequest,
      preflight: preflight,
    );
    if (toolRequest is! ActivateWorldMapSelection) {
      _resetCanvasObjectSelectionCycle();
    }
    state = candidate;
    return WorldMapToolActivationResult(
      accepted: true,
      resultingTool: preflight.resultingTool,
    );
  }

  EditorState _worldMapToolActivationCandidate({
    required EditorState source,
    required WorldMapToolActivationRequest request,
    required WorldMapToolActivationAssessment preflight,
  }) {
    var candidate = source.copyWith(
      activeTool: preflight.resultingTool!,
      activeBrush: preflight.resultingBrush ?? source.activeBrush,
      tilesElementsPanelMode:
          preflight.tilesElementsPanelMode ?? source.tilesElementsPanelMode,
    );
    if (request is ActivateWorldMapSelection) {
      candidate = candidate.copyWith(
        npcWaypointPlacementEntityId: null,
        environmentMaskEditMode: null,
        gameplayZoneDraftArea: null,
      );
    } else {
      candidate = candidate.copyWith(
        selectedPlacedElementInstanceId: null,
        selectedEntityId: null,
        selectedMapEventId: null,
        selectedWarpId: null,
        selectedTriggerId: null,
        selectedGameplayZoneId: null,
        npcWaypointPlacementEntityId: null,
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
        gameplayZoneDraftArea: null,
      );
    }
    return candidate;
  }

  /// Resolves the current authored Border state into a transient repair preview.
  bool previewBorderFeatureUpdate({
    required String layerId,
    required String featureId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    final context = _borderPreviewContext(state);
    if (map == null || project == null || context == null) {
      return false;
    }
    try {
      final borderLayer = map.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == layerId)
          .firstOrNull;
      final feature = borderLayer?.content.featureById(featureId);
      if (feature == null) {
        throw StateError('Bordure introuvable : $layerId/$featureId');
      }
      final record = project.borderCatalog.recordById(feature.blueprintId);
      ref.read(borderPreviewControllerProvider.notifier).beginUpdatePreview(
            map: map,
            layerId: layerId,
            featureId: featureId,
            context: context,
            blueprintRevision: record?.latestPublished,
            tileSizePx: GridSize(
              width: project.settings.tileWidth,
              height: project.settings.tileHeight,
            ),
            visualSnapshots: project.borderCatalog.visualSnapshots,
            resolverVersion: borderResolverVersion,
          );
      state = state.copyWith(
        statusMessage: 'Aperçu de mise à jour de la bordure préparé',
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible de préparer la mise à jour : $error',
      );
      return false;
    }
  }

  /// Resolves one authored Border draft without writing it to the active map.
  bool previewBorderFeatureDraft({
    required String layerId,
    required String featureId,
    required BorderFeature draft,
  }) {
    final map = state.activeMap;
    final project = state.project;
    final context = _borderPreviewContext(state);
    if (map == null || project == null || context == null) {
      return false;
    }
    try {
      final borderLayer = map.layers
          .whereType<BorderLayer>()
          .where((layer) => layer.id == layerId)
          .firstOrNull;
      final persisted = borderLayer?.content.featureById(featureId);
      if (persisted == null) {
        throw StateError('Bordure introuvable : $layerId/$featureId');
      }
      if (draft.id != persisted.id ||
          draft.blueprintId != persisted.blueprintId) {
        throw StateError(
          'Le brouillon doit conserver la bordure et son blueprint.',
        );
      }
      final record = project.borderCatalog.recordById(persisted.blueprintId);
      final preview = ref.read(borderPreviewControllerProvider.notifier);
      preview.begin(
        map: map,
        layerId: layerId,
        featureId: featureId,
        context: context,
      );
      preview.previewFeatureDraft(
        draft,
        blueprintRevision: record?.latestPublished,
        tileSizePx: GridSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      state = state.copyWith(
        statusMessage: 'Correction locale préparée dans l’aperçu',
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible de préparer la correction : $error',
      );
      return false;
    }
  }

  /// Prepares the opposite side of a supported line without writing map history.
  bool previewBorderFeatureLineSideToggle({
    required String layerId,
    required String featureId,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return false;
    try {
      final layer = map.layers
          .whereType<BorderLayer>()
          .where((candidate) => candidate.id == layerId)
          .firstOrNull;
      final feature = layer?.content.featureById(featureId);
      if (feature == null) {
        throw StateError('Bordure introuvable : $layerId/$featureId');
      }
      final revision = project.borderCatalog
          .recordById(feature.blueprintId)
          ?.latestPublished;
      final template = revision?.definition.template;
      if (template == null || !borderTemplateSupportsLineSide(template)) {
        throw StateError(
          'Ce type de bordure ne prend pas en charge l’inversion du côté '
          'visuel.',
        );
      }
      final preview = ref.read(borderPreviewControllerProvider.notifier);
      final previewState = preview.current;
      final transaction = previewState.transaction;
      final refinesCurrentPreview = transaction?.layerId == layerId &&
          transaction?.featureId == featureId &&
          (previewState.phase == BorderPreviewPhase.resolved ||
              previewState.phase == BorderPreviewPhase.invalid);
      final source =
          refinesCurrentPreview ? transaction!.proposedFeature : feature;
      final draft =
          _borderFeatureAuthoringController.previewLineSideToggle(source);
      if (!refinesCurrentPreview) {
        return previewBorderFeatureDraft(
          layerId: layerId,
          featureId: featureId,
          draft: draft,
        );
      }
      preview.previewResolvedFeatureDraft(
        draft,
        blueprintRevision: revision,
        tileSizePx: GridSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      state = state.copyWith(
        statusMessage: 'Orientation visuelle préparée dans l’aperçu',
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible d’inverser le côté de la bordure : $error',
      );
      return false;
    }
  }

  /// Re-resolves an existing stone-chain preview with auto-rotation changed.
  ///
  /// This is a transient refinement seam used by deterministic visual QA. It
  /// requires an already resolved/invalid preview and never writes the active
  /// map or either history stack; Apply remains the sole commit boundary.
  bool previewBorderFeatureAutoRotation({
    required String layerId,
    required String featureId,
    required bool enabled,
  }) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) return false;
    try {
      final layer = map.layers
          .whereType<BorderLayer>()
          .where((candidate) => candidate.id == layerId)
          .firstOrNull;
      final persisted = layer?.content.featureById(featureId);
      if (persisted == null) {
        throw StateError('Bordure introuvable : $layerId/$featureId');
      }
      final revision = project.borderCatalog
          .recordById(persisted.blueprintId)
          ?.latestPublished;
      if (revision == null ||
          revision.definition.template !=
              BorderBlueprintTemplate.stoneChainLine) {
        throw StateError(
          'La rotation automatique exige une bordure en chaîne publiée.',
        );
      }
      final preview = ref.read(borderPreviewControllerProvider.notifier);
      final previewState = preview.current;
      final transaction = previewState.transaction;
      if (transaction == null ||
          transaction.layerId != layerId ||
          transaction.featureId != featureId ||
          (previewState.phase != BorderPreviewPhase.resolved &&
              previewState.phase != BorderPreviewPhase.invalid)) {
        throw StateError(
          'Un aperçu résolu de cette bordure est requis avant de changer la '
          'rotation automatique.',
        );
      }
      final source = transaction.proposedFeature;
      final current = source.paramsOverride ?? revision.definition.defaults;
      final draft = BorderFeature(
        id: source.id,
        name: source.name,
        blueprintId: source.blueprintId,
        seed: source.seed,
        geometry: source.geometry,
        lineSide: source.lineSide,
        paramsOverride: BorderGenerationParams(
          irregularityPermille: current.irregularityPermille,
          detailDensityPermille: current.detailDensityPermille,
          variationPermille: current.variationPermille,
          maxOverlapPx: current.maxOverlapPx,
          gapTolerancePx: current.gapTolerancePx,
          depthRows: current.depthRows,
          allowAutoRotation: enabled,
        ),
        overrides: source.overrides,
        keepOutRegions: source.keepOutRegions,
        materialization: null,
      );
      preview.previewResolvedFeatureDraft(
        draft,
        blueprintRevision: revision,
        tileSizePx: GridSize(
          width: project.settings.tileWidth,
          height: project.settings.tileHeight,
        ),
        visualSnapshots: project.borderCatalog.visualSnapshots,
        resolverVersion: borderResolverVersion,
      );
      state = state.copyWith(
        statusMessage: enabled
            ? 'Rotation automatique préparée dans l’aperçu'
            : 'Rotation automatique désactivée dans l’aperçu',
        errorMessage: null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible de modifier la rotation automatique : $error',
      );
      return false;
    }
  }

  /// Explicitly keeps the persisted materialization without touching the map.
  void keepBorderFeatureMaterialized() {
    ref.read(borderPreviewControllerProvider.notifier).keepMaterialized();
    state = state.copyWith(
      statusMessage: 'Matérialisation existante conservée',
      errorMessage: null,
    );
  }

  /// Commits one fully resolved Border preview as one map-history mutation.
  bool applyPendingBorderPreview() {
    final map = state.activeMap;
    if (map == null) return false;
    final preview = ref.read(borderPreviewControllerProvider.notifier);
    final transaction = preview.current.transaction;
    final context = _borderPreviewContext(state);
    final activeBorderFeature = ref.read(activeBorderFeatureControllerProvider);
    if (transaction == null ||
        context == null ||
        state.activeLayerId != transaction.layerId ||
        activeBorderFeature.activeLayerId != transaction.layerId ||
        activeBorderFeature.activeFeatureId != transaction.featureId) {
      state = state.copyWith(
        errorMessage:
            'La bordure active a changé depuis la création de l’aperçu.',
      );
      return false;
    }
    final BorderPreviewApplyOutcome outcome;
    try {
      outcome = preview.apply(map, context: context);
    } catch (error) {
      state = state.copyWith(
        errorMessage: 'Impossible d’appliquer l’aperçu de bordure : $error',
      );
      return false;
    }
    if (!outcome.applied) {
      state = state.copyWith(
        errorMessage: 'L’aperçu de bordure ne peut plus être appliqué.',
      );
      return false;
    }
    _applyMapMutation(
      previousMap: map,
      updatedMap: outcome.map,
      preferredActiveLayerId: transaction.layerId,
      statusMessage: 'Bordure appliquée',
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Encounter tables
  // ---------------------------------------------------------------------------

  Future<void> createEncounterTable({
    required String name,
    required EncounterKind encounterKind,
    double chancePerStep = defaultEncounterChancePerStep,
    List<ScriptCondition> conditions = const <ScriptCondition>[],
    List<String> tags = const [],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        encounterKind: encounterKind,
        chancePerStep: chancePerStep,
        conditions: conditions,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table created',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to create encounter table: $e');
    }
  }

  Future<void> updateEncounterTable({
    required String tableId,
    String? name,
    EncounterKind? encounterKind,
    double? chancePerStep,
    List<ScriptCondition>? conditions,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterTableUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        name: name,
        encounterKind: encounterKind,
        chancePerStep: chancePerStep,
        conditions: conditions,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter table: $e');
    }
  }

  Future<void> deleteEncounterTable(String tableId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterTableUseCaseProvider);
      final updated = await useCase.execute(fs, project, tableId: tableId);
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter table deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter table: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Project dialogues (bibliothèque)
  // ---------------------------------------------------------------------------

  void selectProjectDialogue(String? dialogueId) {
    state = _projectContentController.selectProjectDialogue(state, dialogueId);
  }

  Future<void> createProjectDialogue({
    required String name,
    String? folderId,
  }) async {
    state = await _projectContentController.createProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      folderId: folderId,
    );
  }

  Future<void> importProjectDialogue({
    required String absoluteSourcePath,
    required String displayName,
    String? folderId,
  }) async {
    state = await _projectContentController.importProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      absoluteSourcePath: absoluteSourcePath,
      displayName: displayName,
      folderId: folderId,
    );
  }

  Future<void> renameProjectDialogue({
    required String dialogueId,
    required String newName,
  }) async {
    state = await _projectContentController.renameProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      newName: newName,
    );
  }

  Future<bool> updateProjectDialogueDeclaredOutcomes({
    required String dialogueId,
    required List<DialogueDeclaredOutcome> declaredOutcomes,
  }) async {
    state =
        await _projectContentController.updateProjectDialogueDeclaredOutcomes(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      declaredOutcomes: declaredOutcomes,
    );
    if (state.errorMessage != null) {
      return false;
    }
    final project = state.project;
    if (project == null) {
      return false;
    }
    for (final dialogue in project.dialogues) {
      if (dialogue.id != dialogueId) {
        continue;
      }
      if (dialogue.declaredOutcomes.length != declaredOutcomes.length) {
        return false;
      }
      for (var index = 0; index < declaredOutcomes.length; index += 1) {
        if (dialogue.declaredOutcomes[index] != declaredOutcomes[index]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> updateProjectDialogueDefaultStartNode({
    required String dialogueId,
    required String? defaultStartNode,
  }) async {
    state =
        await _projectContentController.updateProjectDialogueDefaultStartNode(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      defaultStartNode: defaultStartNode,
    );
    if (state.errorMessage != null) return false;
    for (final dialogue
        in state.project?.dialogues ?? const <ProjectDialogueEntry>[]) {
      if (dialogue.id == dialogueId) {
        return dialogue.defaultStartNode == defaultStartNode;
      }
    }
    return false;
  }

  Future<void> deleteProjectDialogue(String dialogueId) async {
    state = await _projectContentController.deleteProjectDialogue(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  Future<void> createDialogueLibraryFolder({
    required String name,
    String? parentFolderId,
  }) async {
    state = await _projectContentController.createDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      name: name,
      parentFolderId: parentFolderId,
    );
  }

  Future<void> renameDialogueLibraryFolder({
    required String folderId,
    required String name,
  }) async {
    state = await _projectContentController.renameDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      name: name,
    );
  }

  Future<void> moveDialogueLibraryFolder({
    required String folderId,
    String? newParentFolderId,
  }) async {
    state = await _projectContentController.moveDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
      newParentFolderId: newParentFolderId,
    );
  }

  Future<void> deleteDialogueLibraryFolder(String folderId) async {
    state = await _projectContentController.deleteDialogueLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      folderId: folderId,
    );
  }

  Future<void> assignDialogueToLibraryFolder({
    required String dialogueId,
    required String folderId,
  }) async {
    state = await _projectContentController.assignDialogueToLibraryFolder(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
      folderId: folderId,
    );
  }

  Future<void> moveDialogueToLibraryRoot(String dialogueId) async {
    state = await _projectContentController.moveDialogueToLibraryRoot(
      current: state,
      workspace: _projectWorkspace,
      dialogueId: dialogueId,
    );
  }

  // ---------------------------------------------------------------------------
  // Narrative Studio - scénarios
  // ---------------------------------------------------------------------------
  //
  // Ce bloc réintroduit des mutations scénario ciblées, mais dans un cadre
  // beaucoup plus strict que l'ancien "Scenario Graph" générique:
  // - surface d'édition centrale (Cutscene Studio v1 guidé),
  // - opérations explicites create / update / delete,
  // - persistance via use-cases dédiés + validation `ProjectValidator`.
  //
  // Frontière volontaire:
  // - ce notifier orchestre la mutation et la UX (messages, sélection),
  // - la logique métier de validation/persistance reste dans les use-cases.
  // ---------------------------------------------------------------------------

  Future<void> createProjectScenario(ScenarioAsset scenario) async {
    state = await _projectContentController.createProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenario: scenario,
    );
  }

  Future<void> updateProjectScenario({
    required String scenarioId,
    required ScenarioAsset scenario,
  }) async {
    state = await _projectContentController.updateProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
      scenario: scenario,
    );
  }

  Future<void> deleteProjectScenario(String scenarioId) async {
    state = await _projectContentController.deleteProjectScenario(
      current: state,
      workspace: _projectWorkspace,
      scenarioId: scenarioId,
    );
  }

  Future<void> addEncounterEntry({
    required String tableId,
    required String speciesId,
    required int minLevel,
    required int maxLevel,
    int weight = 1,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(addEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry added',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add encounter entry: $e');
    }
  }

  Future<void> updateEncounterEntry({
    required String tableId,
    required int entryIndex,
    String? speciesId,
    int? minLevel,
    int? maxLevel,
    int? weight,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
        speciesId: speciesId,
        minLevel: minLevel,
        maxLevel: maxLevel,
        weight: weight,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry updated',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to update encounter entry: $e');
    }
  }

  Future<void> deleteEncounterEntry({
    required String tableId,
    required int entryIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteEncounterEntryUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        tableId: tableId,
        entryIndex: entryIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Encounter entry deleted',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to delete encounter entry: $e');
    }
  }

  void setCollisionBrushSizeMode(CollisionBrushSizeMode mode) {
    if (state.collisionBrushSizeMode == mode) return;
    state = state.copyWith(
      collisionBrushSizeMode: mode,
      statusMessage: mode == CollisionBrushSizeMode.singleTile
          ? 'Collision brush: 1x1'
          : 'Collision brush: brush footprint',
      errorMessage: null,
    );
  }

  void toggleCollisionBrushSizeMode() {
    setCollisionBrushSizeMode(
      state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
          ? CollisionBrushSizeMode.brushFootprint
          : CollisionBrushSizeMode.singleTile,
    );
  }

  GridSize? resolveCurrentCollisionBrushFootprint() {
    final map = state.activeMap;
    final layerId = state.activeLayerId;
    if (map == null || layerId == null) {
      return null;
    }
    final layer = _findLayerById(map, layerId);
    if (layer is! CollisionLayer) {
      return null;
    }
    return _resolveCollisionFootprint(emitErrors: false)?.size;
  }

  GridSize? resolveCurrentPaintFootprintForEraser() {
    final footprint = _resolveCurrentPaintFootprint(emitErrors: false);
    if (footprint == null || !_isValidEraserFootprintSize(footprint.size)) {
      return null;
    }
    return footprint.size;
  }

  void useSingleTileEraserFootprint() {
    if (state.eraserFootprint is SingleTileEditorEraserFootprint) {
      state = state.copyWith(errorMessage: null);
      return;
    }
    state = state.copyWith(
      eraserFootprint: const EditorEraserFootprint.singleTile(),
      statusMessage: 'Eraser footprint: 1x1',
      errorMessage: null,
    );
  }

  bool capturePreviousBrushEraserFootprint() {
    final footprint = _resolveCurrentPaintFootprint(emitErrors: true);
    if (footprint == null) return false;
    if (!_isValidEraserFootprintSize(footprint.size)) {
      _setPaintError(
        'The current brush footprint exceeds the '
        '$kMaxEditorEraserFootprintDimension tile eraser limit',
      );
      return false;
    }
    state = state.copyWith(
      eraserFootprint: EditorEraserFootprint.previousBrush(
        size: footprint.size,
      ),
      statusMessage:
          'Eraser footprint: ${footprint.size.width}x${footprint.size.height}',
      errorMessage: null,
    );
    return true;
  }

  bool setCustomEraserFootprint({
    required int width,
    required int height,
  }) {
    final size = GridSize(width: width, height: height);
    if (!_isValidEraserFootprintSize(size)) {
      _setPaintError(
        'Custom eraser size must be between 1 and '
        '$kMaxEditorEraserFootprintDimension tiles per side',
      );
      return false;
    }
    state = state.copyWith(
      eraserFootprint: EditorEraserFootprint.custom(size: size),
      statusMessage: 'Eraser footprint: ${size.width}x${size.height}',
      errorMessage: null,
    );
    return true;
  }

  @override
  void setActiveLayer(String layerId) {
    final map = state.activeMap;
    if (map == null) return;
    final selectedLayer = _findLayerById(map, layerId);
    if (selectedLayer == null) {
      state = state.copyWith(errorMessage: 'Layer not found: $layerId');
      return;
    }
    final paletteSession = _rememberActivePaletteContext(state);
    final paletteCandidate = _activatePaletteContext(
      state.copyWith(
        activeLayerId: layerId,
        paletteSession: paletteSession,
        selectedPlacedElementInstanceId: null,
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
        errorMessage: null,
      ),
    );
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      paletteCandidate,
    );
  }

  void setTilesElementsPanelMode(TilesElementsPanelMode mode) {
    if (state.tilesElementsPanelMode == mode) {
      return;
    }
    state = state.copyWith(
      tilesElementsPanelMode: mode,
      errorMessage: null,
    );
    _syncActivePaletteContext();
  }

  void selectPlacedElementInstance({
    required String? instanceId,
    String? elementId,
    String? layerId,
  }) {
    if (state.selectedPlacedElementInstanceId == instanceId) {
      return;
    }
    state = state.copyWith(
      selectedPlacedElementInstanceId: instanceId,
      errorMessage: null,
    );
    if (instanceId == null) {
      debugPrint('[editor][elements] selected placed instance cleared');
      return;
    }
    final safeElementId = elementId?.trim() ?? '';
    final safeLayerId = layerId?.trim() ?? '';
    debugPrint(
      '[editor][elements] selected placed instance id=$instanceId elementId=$safeElementId layer=$safeLayerId',
    );
  }

  void setPlacedElementInstanceCollisionApplied({
    required String instanceId,
    required bool applyCollision,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.applyCollision == applyCollision) {
      return;
    }
    final updatedMap = setMapPlacedElementCollisionApplied(
      map,
      instanceId: trimmedId,
      applyCollision: applyCollision,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage:
          'Collision ${applyCollision ? 'activée' : 'désactivée'} pour ${previous.elementId}',
    );
  }

  /// Commits one absolute quarter-turn value through the pure preview planner.
  ///
  /// Rotation is deliberately not a stroke: one accepted request maps to one
  /// editor mutation and therefore one exact undo record. Capability and
  /// validation failures stay outside history and use the normal error path.
  bool setPlacedElementInstanceQuarterTurns({
    required String instanceId,
    required int quarterTurns,
  }) {
    final plan = planMapPlacedElementRotation(
      map: state.activeMap,
      project: state.project,
      instanceId: instanceId,
      targetQuarterTurns: quarterTurns,
    );
    if (!plan.canCommit) {
      final rejection = plan.rejection;
      if (rejection != null) {
        state = state.copyWith(
          errorMessage: _mapPlacedElementRotationRejectionMessage(rejection),
        );
      }
      return false;
    }

    final sourceMap = plan.sourceMap!;
    final instance = plan.instance!;
    final candidateMap = plan.candidateMap!;
    _applyMapMutation(
      previousMap: sourceMap,
      updatedMap: candidateMap,
      preferredActiveLayerId: instance.layerId,
      partOfStroke: false,
      statusMessage: 'Rotation mise à jour pour ${instance.elementId}',
    );
    return identical(state.activeMap, candidateMap);
  }

  /// Rotates the selected authored placement by a relative number of turns.
  ///
  /// The delta is normalized before addition so the intermediate remains
  /// portable on Dart native and JavaScript even for a very large exact input.
  bool rotateSelectedPlacedElement({
    required int deltaQuarterTurns,
  }) {
    final selectedId = state.selectedPlacedElementInstanceId?.trim() ?? '';
    MapPlacedElement? selected;
    for (final instance
        in state.activeMap?.placedElements ?? const <MapPlacedElement>[]) {
      if (instance.id == selectedId) {
        selected = instance;
        break;
      }
    }
    final normalizedDelta = normalizeQuarterTurns(deltaQuarterTurns);
    final targetQuarterTurns = normalizeQuarterTurns(
      (selected?.quarterTurns ?? 0) + normalizedDelta,
    );
    return setPlacedElementInstanceQuarterTurns(
      instanceId: selectedId,
      quarterTurns: targetQuarterTurns,
    );
  }

  String _mapPlacedElementRotationRejectionMessage(
    MapPlacedElementRotationRejection rejection,
  ) {
    return switch (rejection) {
      MapPlacedElementRotationRejection.mapUnavailable =>
        'Rotation impossible : aucune map active.',
      MapPlacedElementRotationRejection.projectUnavailable =>
        'Rotation impossible : aucun projet actif.',
      MapPlacedElementRotationRejection.instanceMissing =>
        'Rotation impossible : l’élément placé est introuvable.',
      MapPlacedElementRotationRejection.elementMissing =>
        'Rotation impossible : la définition de l’élément est introuvable.',
      MapPlacedElementRotationRejection.layerMissing =>
        'Rotation impossible : le layer de l’élément est introuvable.',
      MapPlacedElementRotationRejection.unsupportedLayer =>
        'Rotation impossible : seuls les éléments placés sur un layer de '
            'tuiles sont compatibles.',
      MapPlacedElementRotationRejection.environmentGenerated =>
        'Cet élément est généré par une zone Environment. '
            'Modifiez ou régénérez cette zone pour changer son orientation.',
      MapPlacedElementRotationRejection.tileIndexed =>
        'Cet élément est dérivé du tile index. '
            'Modifiez les tuiles source pour changer sa projection.',
      MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange =>
        'Rotation impossible : la valeur absolue doit être comprise entre '
            '0 et 3 quarts de tour.',
      MapPlacedElementRotationRejection.destinationOutOfBounds =>
        'Rotation impossible : l’empreinte tournée dépasse la carte.',
      MapPlacedElementRotationRejection.candidateInvalid =>
        'Rotation impossible : la carte obtenue ne passe pas la validation.',
    };
  }

  void setPlacedElementInstanceOpacity({
    required String instanceId,
    required double opacity,
    bool partOfStroke = false,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    final normalizedOpacity = opacity.clamp(0.0, 1.0).toDouble();
    if (previous.opacity == normalizedOpacity) {
      return;
    }
    final updatedMap = setMapPlacedElementOpacity(
      map,
      instanceId: trimmedId,
      opacity: normalizedOpacity,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      partOfStroke: partOfStroke,
      statusMessage: 'Opacité mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceShadowOverride({
    required String instanceId,
    required MapPlacedElementShadowOverride? shadowOverride,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.shadowOverride == shadowOverride) {
      return;
    }
    final updatedMap = setMapPlacedElementShadowOverride(
      map,
      instanceId: trimmedId,
      shadowOverride: shadowOverride,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: shadowOverride == null
          ? 'Override d’ombre réinitialisé pour ${previous.elementId}'
          : 'Override d’ombre mis à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceAnimationConfig({
    required String instanceId,
    required MapPlacedElementAnimation? animation,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (previous.animation == animation) {
      return;
    }
    final updatedMap = setMapPlacedElementAnimation(
      map,
      instanceId: trimmedId,
      animation: animation,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: animation == null
          ? 'Animation réinitialisée pour ${previous.elementId}'
          : 'Animation mise à jour pour ${previous.elementId}',
    );
  }

  void setPlacedElementInstanceBehaviors({
    required String instanceId,
    required List<MapPlacedElementBehavior> behaviors,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    final previous = map.placedElements[index];
    if (listEquals(previous.behaviors, behaviors)) {
      return;
    }
    final updatedMap = setMapPlacedElementBehaviors(
      map,
      instanceId: trimmedId,
      behaviors: behaviors,
    );
    _applyMapMutation(
      previousMap: map,
      updatedMap: updatedMap,
      preferredActiveLayerId: state.activeLayerId,
      statusMessage: behaviors.isEmpty
          ? 'Comportements réinitialisés pour ${previous.elementId}'
          : 'Comportements mis à jour pour ${previous.elementId}',
    );
  }

  void deletePlacedElementInstance({
    required String instanceId,
    MapData? expectedMapIdentity,
    MapPlacedElement? expectedInstanceIdentity,
  }) {
    final map = state.activeMap;
    if (map == null) {
      return;
    }
    if (expectedMapIdentity != null && !identical(map, expectedMapIdentity)) {
      return;
    }
    final trimmedId = instanceId.trim();
    if (trimmedId.isEmpty) {
      return;
    }
    final index =
        map.placedElements.indexWhere((entry) => entry.id == trimmedId);
    if (index < 0) {
      state = state.copyWith(
        errorMessage: 'Placed element instance not found: $trimmedId',
      );
      return;
    }
    if (expectedInstanceIdentity != null &&
        !identical(map.placedElements[index], expectedInstanceIdentity)) {
      return;
    }
    final instance = map.placedElements[index];
    final generatedDeletion = _deleteEnvironmentGeneratedPlacedElement(
      map,
      placedElementId: trimmedId,
    );
    if (generatedDeletion != null) {
      try {
        MapValidator.validate(generatedDeletion);
        _applyMapMutation(
          previousMap: map,
          updatedMap: generatedDeletion,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Instance générée supprimée (${instance.elementId})',
        );
        debugPrint(
          '[editor][elements] deleted generated placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
        );
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Failed to delete generated placed element: $e',
        );
      }
      return;
    }

    final origin = instance.properties[pokemapPlacementOriginProperty]?.trim();
    if (origin != pokemapPlacementOriginTileIndex) {
      try {
        final updated = removeMapPlacedElement(
          map,
          instanceId: trimmedId,
        );
        MapValidator.validate(updated, projectDialogueContext: state.project);
        _applyMapMutation(
          previousMap: map,
          updatedMap: updated,
          preferredActiveLayerId: state.activeLayerId,
          statusMessage: 'Instance supprimée (${instance.elementId})',
        );
        debugPrint(
          '[editor][elements] deleted authored placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
        );
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Failed to delete placed element instance: $e',
        );
      }
      return;
    }

    final layer = _findLayerById(map, instance.layerId);
    if (layer is! TileLayer) {
      state = state.copyWith(
        errorMessage:
            'Placed element layer is not a tile layer: ${instance.layerId}',
      );
      return;
    }

    final project = state.project;
    var patternSize = const GridSize(width: 1, height: 1);
    if (project != null) {
      ProjectElementEntry? element;
      for (final entry in project.elements) {
        if (entry.id == instance.elementId) {
          element = entry;
          break;
        }
      }
      if (element != null) {
        final source = element.frames.primarySource;
        patternSize = GridSize(
          width: source.width > 0 ? source.width : 1,
          height: source.height > 0 ? source.height : 1,
        );
      }
    }

    try {
      late final MapData erased;
      if (patternSize.width == 1 && patternSize.height == 1) {
        final useCase = ref.read(eraseTileOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
        );
      } else {
        final useCase = ref.read(eraseTilePatternOnMapUseCaseProvider);
        erased = useCase.execute(
          map,
          layerId: instance.layerId,
          pos: instance.pos,
          patternSize: patternSize,
          clipToMapBounds: true,
        );
      }

      final committed = project == null
          ? erased
          : _placedElementInstanceIndexer.syncLayer(
              map: erased,
              project: project,
              layerId: instance.layerId,
            );

      _applyMapMutation(
        previousMap: map,
        updatedMap: committed,
        preferredActiveLayerId: state.activeLayerId,
        statusMessage: 'Instance supprimée (${instance.elementId})',
      );
      debugPrint(
        '[editor][elements] deleted placed instance id=$trimmedId elementId=${instance.elementId} layer=${instance.layerId} pos=(${instance.pos.x},${instance.pos.y})',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete placed element instance: $e',
      );
    }
  }

  bool addGeneratedEnvironmentPlacementAt(GridPos pos) {
    final map = state.activeMap;
    final project = state.project;
    if (map == null || project == null) {
      return false;
    }
    final activeLayerId = state.activeLayerId?.trim();
    final selectedAreaId = state.selectedEnvironmentAreaId?.trim();
    if (activeLayerId == null ||
        activeLayerId.isEmpty ||
        selectedAreaId == null ||
        selectedAreaId.isEmpty) {
      return false;
    }
    final activeLayer = _findLayerById(map, activeLayerId);
    if (activeLayer is TileLayer) {
      return addGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
    }
    if (activeLayer is! EnvironmentLayer) {
      return false;
    }

    EnvironmentArea? area;
    for (final candidate in activeLayer.content.areas) {
      if (candidate.id == selectedAreaId) {
        area = candidate;
        break;
      }
    }
    if (area == null) {
      return false;
    }

    final targetLayerId = activeLayer.content.targetTileLayerId?.trim();
    if (targetLayerId == null || targetLayerId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : aucun TileLayer cible.',
      );
      return false;
    }
    final targetLayer = _findLayerById(map, targetLayerId);
    if (targetLayer is! TileLayer) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : TileLayer cible introuvable.',
      );
      return false;
    }

    final preset = _environmentPresetById(project, area.presetId);
    if (preset == null) {
      state = state.copyWith(
        errorMessage: 'Impossible d’ajouter : preset introuvable.',
      );
      return false;
    }

    EnvironmentPaletteItem? item;
    ProjectElementEntry? element;
    for (final candidate in preset.palette) {
      final candidateElement = _projectElementById(
        project,
        candidate.elementId,
      );
      if (candidateElement == null) continue;
      item = candidate;
      element = candidateElement;
      break;
    }
    if (item == null || element == null) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter : aucun élément du preset ne correspond au TileLayer cible.',
      );
      return false;
    }

    final footprint = _elementFootprint(element);
    if (!_elementFootprintInBounds(
      pos: pos,
      footprint: footprint,
      mapSize: map.size,
    )) {
      state = state.copyWith(
        errorMessage:
            'Impossible d’ajouter : l’élément dépasserait les limites de la map.',
      );
      return false;
    }

    final placedId = _generatedEnvironmentPlacementId(
      areaId: area.id,
      pos: pos,
      elementId: item.elementId,
    );
    if (area.generatedPlacementIds.contains(placedId) ||
        map.placedElements.any((placed) => placed.id == placedId)) {
      state = state.copyWith(
        errorMessage: null,
        statusMessage: 'Placement généré déjà présent ici.',
      );
      return false;
    }

    final placed = MapPlacedElement(
      id: placedId,
      layerId: targetLayer.id,
      elementId: item.elementId,
      pos: pos,
      applyCollision: _applyCollisionFromEnvironmentMode(item.collisionMode),
      properties: const {
        pokemapPlacementOriginProperty: pokemapPlacementOriginEnvironment,
      },
    );
    final updatedMap = _addEnvironmentGeneratedPlacedElement(
      map,
      environmentLayerId: activeLayer.id,
      areaId: area.id,
      placed: placed,
    );

    try {
      MapValidator.validate(updatedMap, projectDialogueContext: project);
      _applyMapMutation(
        previousMap: map,
        updatedMap: updatedMap,
        preferredActiveLayerId: activeLayer.id,
        statusMessage: 'Placement généré ajouté (${item.elementId})',
      );
      debugPrint(
        '[editor][environment] added generated placement by click id=${placed.id} elementId=${placed.elementId} pos=(${pos.x},${pos.y})',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to add generated placement: $e',
      );
      return false;
    }
  }

  bool deleteGeneratedEnvironmentPlacementAt(GridPos pos) {
    final map = state.activeMap;
    if (map == null) {
      return false;
    }
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId == null || activeLayerId.isEmpty) {
      return false;
    }
    final activeLayer = _findLayerById(map, activeLayerId);
    if (activeLayer is TileLayer) {
      return deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
    }
    if (activeLayer is! EnvironmentLayer) {
      return false;
    }

    final generatedIds = <String>{};
    final selectedAreaId = state.selectedEnvironmentAreaId?.trim();
    for (final area in activeLayer.content.areas) {
      if (selectedAreaId != null &&
          selectedAreaId.isNotEmpty &&
          area.id != selectedAreaId) {
        continue;
      }
      generatedIds.addAll(area.generatedPlacementIds);
    }
    if (generatedIds.isEmpty) {
      return false;
    }

    final project = state.project;
    final elementById = <String, ProjectElementEntry>{
      if (project != null)
        for (final element in project.elements) element.id: element,
    };
    for (final instance in map.placedElements.reversed) {
      if (!generatedIds.contains(instance.id)) {
        continue;
      }
      if (!_placedElementContainsGridPos(
        instance: instance,
        element: elementById[instance.elementId],
        pos: pos,
      )) {
        continue;
      }

      final updatedMap = _deleteEnvironmentGeneratedPlacedElement(
        map,
        placedElementId: instance.id,
      );
      if (updatedMap == null) {
        return false;
      }
      try {
        MapValidator.validate(updatedMap);
        _applyMapMutation(
          previousMap: map,
          updatedMap: updatedMap,
          preferredActiveLayerId: activeLayer.id,
          statusMessage: 'Placement généré supprimé (${instance.elementId})',
        );
        debugPrint(
          '[editor][environment] deleted generated placement by click id=${instance.id} elementId=${instance.elementId} pos=(${instance.pos.x},${instance.pos.y})',
        );
        return true;
      } catch (e) {
        state = state.copyWith(
          errorMessage: 'Failed to delete generated placement: $e',
        );
        return false;
      }
    }
    return false;
  }

  bool _placedElementContainsGridPos({
    required MapPlacedElement instance,
    required ProjectElementEntry? element,
    required GridPos pos,
  }) {
    final source = element?.frames.primarySource;
    final width = source == null || source.width <= 0 ? 1 : source.width;
    final height = source == null || source.height <= 0 ? 1 : source.height;
    return pos.x >= instance.pos.x &&
        pos.y >= instance.pos.y &&
        pos.x < instance.pos.x + width &&
        pos.y < instance.pos.y + height;
  }

  MapData _addEnvironmentGeneratedPlacedElement(
    MapData map, {
    required String environmentLayerId,
    required String areaId,
    required MapPlacedElement placed,
  }) {
    final updatedLayers = <MapLayer>[];
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer || layer.id != environmentLayerId) {
        updatedLayers.add(layer);
        continue;
      }

      final updatedAreas = <EnvironmentArea>[];
      for (final area in layer.content.areas) {
        if (area.id != areaId) {
          updatedAreas.add(area);
          continue;
        }
        updatedAreas.add(
          EnvironmentArea(
            id: area.id,
            name: area.name,
            presetId: area.presetId,
            mask: area.mask,
            seed: area.seed,
            paramsOverride: area.paramsOverride,
            generatedPlacementIds: [
              ...area.generatedPlacementIds,
              placed.id,
            ],
          ),
        );
      }

      updatedLayers.add(
        MapLayer.environment(
          id: layer.id,
          name: layer.name,
          isVisible: layer.isVisible,
          opacity: layer.opacity,
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: updatedAreas,
          ),
          properties: layer.properties,
        ),
      );
    }

    return map.copyWith(
      layers: updatedLayers,
      placedElements: [
        ...map.placedElements,
        placed,
      ],
    );
  }

  MapData? _deleteEnvironmentGeneratedPlacedElement(
    MapData map, {
    required String placedElementId,
  }) {
    var didRemoveReference = false;
    final updatedLayers = <MapLayer>[];
    for (final layer in map.layers) {
      if (layer is! EnvironmentLayer) {
        updatedLayers.add(layer);
        continue;
      }

      var didUpdateLayer = false;
      final updatedAreas = <EnvironmentArea>[];
      for (final area in layer.content.areas) {
        if (!area.generatedPlacementIds.contains(placedElementId)) {
          updatedAreas.add(area);
          continue;
        }

        didRemoveReference = true;
        didUpdateLayer = true;
        updatedAreas.add(
          EnvironmentArea(
            id: area.id,
            name: area.name,
            presetId: area.presetId,
            mask: area.mask,
            seed: area.seed,
            paramsOverride: area.paramsOverride,
            generatedPlacementIds: [
              for (final id in area.generatedPlacementIds)
                if (id != placedElementId) id,
            ],
          ),
        );
      }

      if (!didUpdateLayer) {
        updatedLayers.add(layer);
        continue;
      }

      updatedLayers.add(
        MapLayer.environment(
          id: layer.id,
          name: layer.name,
          isVisible: layer.isVisible,
          opacity: layer.opacity,
          content: EnvironmentLayerContent(
            targetTileLayerId: layer.content.targetTileLayerId,
            areas: updatedAreas,
          ),
          properties: layer.properties,
        ),
      );
    }

    if (!didRemoveReference) {
      return null;
    }

    return map.copyWith(
      layers: updatedLayers,
      placedElements: [
        for (final placed in map.placedElements)
          if (placed.id != placedElementId) placed,
      ],
    );
  }

  _TileLayerGeneratedPlacementAddSelection
      _resolveGeneratedPlacementAddSelectionForTileLayer({
    String? requestedElementId,
    required bool requireGeneratedPlacements,
    required bool allowImplicitSelection,
  }) {
    final map = state.activeMap;
    if (map == null) {
      throw const EditorValidationException('Aucune carte active.');
    }
    final project = state.project;
    if (project == null) {
      throw const EditorValidationException('Aucun projet chargé.');
    }
    final layerId = state.activeLayerId?.trim();
    if (layerId == null || layerId.isEmpty) {
      throw const EditorValidationException(
        'Sélectionnez un TileLayer avant d’ajouter un élément généré.',
      );
    }
    final activeLayer = _findLayerById(map, layerId);
    if (activeLayer is! TileLayer) {
      throw const EditorValidationException(
        'Sélectionnez un TileLayer avant d’ajouter un élément généré.',
      );
    }
    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
    if (areaId == null || areaId.isEmpty) {
      throw const EditorValidationException(
        'Sélectionnez une zone d’environnement avant d’ajouter un élément généré.',
      );
    }
    final target = resolveEnvironmentMaskPaintTarget(
      map: map,
      activeLayerId: layerId,
      selectedAreaId: areaId,
    );
    if (target == null) {
      throw const EditorValidationException(
        'Activez d’abord l’environnement sur ce layer.',
      );
    }
    if (requireGeneratedPlacements &&
        target.area.generatedPlacementIds.isEmpty) {
      throw const EditorValidationException(
        'Générez d’abord la zone avant d’affiner manuellement.',
      );
    }
    final preset = _environmentPresetById(project, target.area.presetId);
    if (preset == null) {
      throw const EditorValidationException('Preset introuvable.');
    }

    final selectedId = (requestedElementId ??
            ref.read(environmentGeneratedPlacementAddElementProvider))
        ?.trim();
    if (selectedId != null && selectedId.isNotEmpty) {
      for (final item in preset.palette) {
        if (item.elementId != selectedId) continue;
        final element = _projectElementById(project, item.elementId);
        if (element == null) {
          throw const EditorValidationException(
            'Élément introuvable dans le projet.',
          );
        }
        return _TileLayerGeneratedPlacementAddSelection(
          project: project,
          tileLayerId: activeLayer.id,
          environmentLayerId: target.environmentLayerId,
          areaId: target.areaId,
          item: item,
          element: element,
        );
      }
      throw const EditorValidationException(
        'L’élément choisi n’appartient pas à la palette du preset.',
      );
    }

    if (!allowImplicitSelection) {
      throw const EditorValidationException(
        'Choisissez un élément à ajouter.',
      );
    }

    final available =
        <({EnvironmentPaletteItem item, ProjectElementEntry element})>[];
    for (final item in preset.palette) {
      final element = _projectElementById(project, item.elementId);
      if (element == null) continue;
      available.add((item: item, element: element));
    }
    if (available.length != 1) {
      throw const EditorValidationException(
        'Choisissez un élément à ajouter.',
      );
    }
    final implicit = available.single;
    return _TileLayerGeneratedPlacementAddSelection(
      project: project,
      tileLayerId: activeLayer.id,
      environmentLayerId: target.environmentLayerId,
      areaId: target.areaId,
      item: implicit.item,
      element: implicit.element,
    );
  }

  EnvironmentPreset? _environmentPresetById(
    ProjectManifest project,
    String presetId,
  ) {
    final normalizedId = presetId.trim();
    for (final preset in project.environmentPresets) {
      if (preset.id == normalizedId) {
        return preset;
      }
    }
    return null;
  }

  ProjectElementEntry? _projectElementById(
    ProjectManifest project,
    String elementId,
  ) {
    final normalizedId = elementId.trim();
    for (final element in project.elements) {
      if (element.id == normalizedId) {
        return element;
      }
    }
    return null;
  }

  GridSize _elementFootprint(ProjectElementEntry element) {
    final source = element.frames.primarySource;
    return GridSize(
      width: source.width <= 0 ? 1 : source.width,
      height: source.height <= 0 ? 1 : source.height,
    );
  }

  bool _elementFootprintInBounds({
    required GridPos pos,
    required GridSize footprint,
    required GridSize mapSize,
  }) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x + footprint.width <= mapSize.width &&
        pos.y + footprint.height <= mapSize.height;
  }

  bool _applyCollisionFromEnvironmentMode(EnvironmentCollisionMode mode) {
    switch (mode) {
      case EnvironmentCollisionMode.forceEnabled:
        return true;
      case EnvironmentCollisionMode.forceDisabled:
        return false;
      case EnvironmentCollisionMode.useElementDefault:
        return true;
    }
  }

  String _generatedEnvironmentPlacementId({
    required String areaId,
    required GridPos pos,
    required String elementId,
  }) {
    return 'env_gen_${_sanitizeEnvironmentIdPart(areaId)}_${pos.x}_${pos.y}_${_sanitizeEnvironmentIdPart(elementId)}';
  }

  String _sanitizeEnvironmentIdPart(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  /// Bascule vers la sélection si l’outil courant ne peut pas agir sur le calque actif.
  @override
  void _coerceActiveToolIfIncompatibleWithLayer() {
    state = _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      state,
    );
  }

  void updateHoveredTile(GridPos? pos) {
    if (state.hoveredTile != pos) {
      state = state.copyWith(hoveredTile: pos);
    }
  }

  void pan(Offset delta) {
    setMapViewport(
      MapViewport(
        zoom: state.zoom,
        panOffset: state.panOffset + delta,
      ),
    );
  }

  void setNarrativeEventMapPanOffset(Offset value) {
    setMapViewport(
      MapViewport(
        zoom: state.zoom,
        panOffset: value,
      ),
    );
  }

  void setMapViewport(MapViewport viewport) {
    if (state.zoom == viewport.zoom && state.panOffset == viewport.panOffset) {
      return;
    }
    state = state.copyWith(
      zoom: viewport.zoom,
      panOffset: viewport.panOffset,
    );
  }

  void zoom(double delta) {
    final newZoom = (state.zoom + delta).clamp(0.1, 5.0);
    setMapViewport(
      MapViewport(
        zoom: newZoom,
        panOffset: state.panOffset,
      ),
    );
  }

  void _applyMapMutation({
    required MapData previousMap,
    required MapData updatedMap,
    required String? preferredActiveLayerId,
    String? preferredSelectedEntityId,
    String? preferredSelectedMapEventId,
    String? preferredSelectedWarpId,
    String? preferredSelectedTriggerId,
    bool partOfStroke = false,
    bool updateSavedSnapshot = false,
    GridPos? hoveredTile,
    bool updateHoveredTile = false,
    String? statusMessage,
    Object? mapWriteLeaseToken,
  }) {
    if (_rejectNonCanonicalActiveMapAuthoring() ||
        _rejectNarrativeEventSourceCleanupMapMutation() ||
        _rejectMapDiskMutationLease(
          allowedLeaseToken: mapWriteLeaseToken,
        )) {
      return;
    }
    final outgoingPaletteSession = _rememberActivePaletteContext(state);
    final outgoingPaletteKey = _activePaletteContextKey(state);
    final next = _mapEditingController.applyMutation(
      current: state,
      previousMap: previousMap,
      updatedMap: updatedMap,
      preferredActiveLayerId: preferredActiveLayerId,
      preferredSelectedEntityId: preferredSelectedEntityId,
      preferredSelectedMapEventId: preferredSelectedMapEventId,
      preferredSelectedWarpId: preferredSelectedWarpId,
      preferredSelectedTriggerId: preferredSelectedTriggerId,
      partOfStroke: partOfStroke,
      updateSavedSnapshot: updateSavedSnapshot,
      hoveredTile: hoveredTile,
      updateHoveredTile: updateHoveredTile,
      statusMessage: statusMessage,
    );
    var adopted =
        _mapSelectionController.coerceActiveToolIfIncompatibleWithLayer(
      next.copyWith(paletteSession: outgoingPaletteSession),
    );
    final incomingPaletteKey = _activePaletteContextKey(adopted);
    final layerIdentityChanged = !listEquals(
      previousMap.layers.map((layer) => layer.id).toList(growable: false),
      updatedMap.layers.map((layer) => layer.id).toList(growable: false),
    );
    if (outgoingPaletteKey != incomingPaletteKey || layerIdentityChanged) {
      adopted = _activatePaletteContext(adopted);
    }
    state = adopted;
  }

  int _findLayerIndexById(MapData map, String layerId) {
    return map.layers.indexWhere((layer) => layer.id == layerId);
  }

  MapLayer? _findLayerById(MapData map, String layerId) {
    for (final layer in map.layers) {
      if (layer.id == layerId) {
        return layer;
      }
    }
    return null;
  }

  /// Retourne la même page cible que le contrat Event Builder.
  ///
  /// Les drafts actuels utilisent pageNumber 0, mais les anciens events peuvent
  /// contenir des pages non ordonnées ; on préserve donc la règle "plus petit
  /// pageNumber" au lieu de supposer que l'index 0 est toujours canonique.
  int _eventBuilderAuthorablePageNumber(MapEventDefinition event) {
    var selected = event.pages.first.pageNumber;
    for (final page in event.pages.skip(1)) {
      if (page.pageNumber < selected) {
        selected = page.pageNumber;
      }
    }
    return selected;
  }

  MapData _updateEventBuilderPageCondition({
    required MapData map,
    required MapEventDefinition event,
    required int pageNumber,
    required List<EventBuilderConditionBinding> conditions,
  }) {
    final compiled = compileEventBuilderConditionsToScriptCondition(conditions);
    if (compiled.hasErrors) {
      throw UnsupportedError(
        'Event Builder conditions contain unsupported entries for the current '
        'Event Builder authoring scope.',
      );
    }
    final pageIndex =
        event.pages.indexWhere((page) => page.pageNumber == pageNumber);
    if (pageIndex < 0) {
      throw ValidationException(
        'Map event page not found: event=${event.id} pageNumber=$pageNumber',
      );
    }
    // updatePageOnMapEvent is intentionally used instead of applying the whole
    // Event Builder contract: this lot owns only MapEventPage.condition and
    // must not rewrite sceneTarget, metadata, script or message.
    return updatePageOnMapEvent(
      map,
      eventId: event.id,
      pageIndex: pageIndex,
      condition: compiled.condition,
      clearCondition: compiled.condition == null,
    );
  }

  bool _rejectLegacyMapEventMutationInV2Only() {
    final reason = narrativeEventLegacyAuthoringBlockReason(
      state.project,
      kind: NarrativeEventLegacyAuthoringKind.mapEvent,
    );
    if (reason == null) return false;
    state = state.copyWith(errorMessage: reason);
    return true;
  }

  bool _isEventBuilderEditableConditionKind(EventBuilderConditionKind kind) {
    return switch (kind) {
      EventBuilderConditionKind.factIsTrue ||
      EventBuilderConditionKind.factIsFalse ||
      EventBuilderConditionKind.eventConsumed ||
      EventBuilderConditionKind.eventNotConsumed =>
        true,
      EventBuilderConditionKind.storyStepCompleted ||
      EventBuilderConditionKind.storyStepNotCompleted =>
        false,
    };
  }

  bool _isEventBuilderAuthorableTriggerType(MapEventType type) {
    return switch (type) {
      MapEventType.actor ||
      MapEventType.object ||
      MapEventType.triggerZone =>
        true,
      MapEventType.effect => false,
    };
  }

  /// Lot Environment-22 : évite une sélection masque fantôme si le layer ou l’area disparaît.
  void _coerceEnvironmentMaskSelectionAfterMapChange() {
    final map = state.activeMap;
    final lid = state.activeLayerId;
    if (map == null || lid == null) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
      return;
    }
    final layer = _findLayerById(map, lid);
    if (layer is! EnvironmentLayer) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
      return;
    }
    final sid = state.selectedEnvironmentAreaId?.trim();
    if (sid == null || sid.isEmpty) {
      return;
    }
    final stillExists = layer.content.areas.any((a) => a.id == sid);
    if (!stillExists) {
      state = state.copyWith(
        selectedEnvironmentAreaId: null,
        environmentMaskEditMode: null,
      );
    }
  }

  String? _resolveEventPlacementLayerId(MapData map) {
    final activeLayerId = state.activeLayerId?.trim();
    if (activeLayerId != null &&
        activeLayerId.isNotEmpty &&
        map.layers.any((layer) => layer.id == activeLayerId)) {
      return activeLayerId;
    }
    if (map.layers.isNotEmpty) {
      return map.layers.first.id;
    }
    return null;
  }

  String _generateUniqueMapEventId(MapData map) {
    final ids = map.events.map((event) => event.id).toSet();
    if (!ids.contains('event')) {
      return 'event';
    }
    var index = 1;
    while (ids.contains('event_$index')) {
      index++;
    }
    return 'event_$index';
  }

  // ---------------------------------------------------------------------------
  // Characters (bibliothèque personnages)
  // ---------------------------------------------------------------------------

  void selectCharacter(String? characterId) {
    state = state.copyWith(selectedCharacterId: characterId);
  }

  Future<void> createCharacter({
    required String name,
    required String tilesetId,
    int frameWidth = 1,
    int frameHeight = 2,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(createCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId:
            updated.characters.isNotEmpty ? updated.characters.last.id : null,
        statusMessage: 'Character created',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create character: $e');
    }
  }

  Future<void> updateCharacter({
    required String characterId,
    String? name,
    String? tilesetId,
    int? frameWidth,
    int? frameHeight,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(updateCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        name: name,
        tilesetId: tilesetId,
        frameWidth: frameWidth,
        frameHeight: frameHeight,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Character updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update character: $e');
    }
  }

  Future<void> deleteCharacter(String characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(deleteCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        selectedCharacterId: state.selectedCharacterId == characterId
            ? null
            : state.selectedCharacterId,
        statusMessage: 'Character deleted',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete character: $e');
    }
  }

  Future<void> upsertCharacterAnimation({
    required String characterId,
    required CharacterAnimationState animState,
    required EntityFacing direction,
    required List<CharacterAnimationFrame> frames,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(upsertCharacterAnimationUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
        animState: animState,
        direction: direction,
        frames: frames,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Animation updated',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update animation: $e');
    }
  }

  Future<void> setPlayerCharacter(String? characterId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return;
    try {
      final useCase = ref.read(setPlayerCharacterUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        characterId: characterId,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: characterId == null
            ? 'Player character cleared'
            : 'Player character set',
        errorMessage: null,
      );
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Failed to set player character: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Trainers (bibliothèque dresseurs)
  // ---------------------------------------------------------------------------

  void selectTrainer(String? trainerId) {
    state = state.copyWith(selectedTrainerId: trainerId);
  }

  Future<bool> createTrainer({
    required String name,
    required String trainerClass,
    int? battleDifficulty,
    String? battleBackgroundRelativePath,
    String? characterId,
    String? portraitElementId,
    String? battleThemeId,
    String? victoryThemeId,
    ProjectTrainerTemplateKind? templateKind,
    ProjectTrainerRematchPolicy? rematchPolicy,
    String? preBattleDialogueId,
    String? victoryDialogueId,
    String? defeatDialogueId,
    int moneyReward = 0,
    List<ProjectTrainerItemGrant> rewardItemGrants =
        const <ProjectTrainerItemGrant>[],
    List<String> rewardFlagIds = const <String>[],
    String? rewardBadgeId,
    FieldAbility? rewardFieldAbilityUnlock,
    List<String> tags = const <String>[],
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(createTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: battleDifficulty,
        battleBackgroundRelativePath: battleBackgroundRelativePath,
        characterId: characterId,
        portraitElementId: portraitElementId,
        battleThemeId: battleThemeId,
        victoryThemeId: victoryThemeId,
        templateKind: templateKind,
        rematchPolicy: rematchPolicy,
        preBattleDialogueId: preBattleDialogueId,
        victoryDialogueId: victoryDialogueId,
        defeatDialogueId: defeatDialogueId,
        moneyReward: moneyReward,
        rewardItemGrants: rewardItemGrants,
        rewardFlagIds: rewardFlagIds,
        rewardBadgeId: rewardBadgeId,
        rewardFieldAbilityUnlock: rewardFieldAbilityUnlock,
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId:
            updated.trainers.isNotEmpty ? updated.trainers.last.id : null,
        statusMessage: 'Trainer created',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create trainer: $e');
      return false;
    }
  }

  Future<bool> updateTrainer({
    required String trainerId,
    String? name,
    String? trainerClass,
    Object? battleDifficulty = _trainerUnset,
    Object? battleBackgroundRelativePath = _trainerUnset,
    Object? characterId = _trainerUnset,
    Object? portraitElementId = _trainerUnset,
    Object? battleThemeId = _trainerUnset,
    Object? victoryThemeId = _trainerUnset,
    Object? templateKind = _trainerUnset,
    Object? rematchPolicy = _trainerUnset,
    Object? preBattleDialogueId = _trainerUnset,
    Object? victoryDialogueId = _trainerUnset,
    Object? defeatDialogueId = _trainerUnset,
    int? moneyReward,
    List<ProjectTrainerItemGrant>? rewardItemGrants,
    List<String>? rewardFlagIds,
    Object? rewardBadgeId = _trainerUnset,
    Object? rewardFieldAbilityUnlock = _trainerUnset,
    List<String>? tags,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        name: name,
        trainerClass: trainerClass,
        battleDifficulty: _trainerFieldUpdate<int>(battleDifficulty),
        battleBackgroundRelativePath:
            _trainerFieldUpdate<String>(battleBackgroundRelativePath),
        characterId: _trainerFieldUpdate<String>(characterId),
        portraitElementId: _trainerFieldUpdate<String>(portraitElementId),
        battleThemeId: _trainerFieldUpdate<String>(battleThemeId),
        victoryThemeId: _trainerFieldUpdate<String>(victoryThemeId),
        templateKind:
            _trainerFieldUpdate<ProjectTrainerTemplateKind>(templateKind),
        rematchPolicy:
            _trainerFieldUpdate<ProjectTrainerRematchPolicy>(rematchPolicy),
        preBattleDialogueId: _trainerFieldUpdate<String>(preBattleDialogueId),
        victoryDialogueId: _trainerFieldUpdate<String>(victoryDialogueId),
        defeatDialogueId: _trainerFieldUpdate<String>(defeatDialogueId),
        moneyReward: moneyReward,
        rewardItemGrants: rewardItemGrants,
        rewardFlagIds: rewardFlagIds,
        rewardBadgeId: _trainerFieldUpdate<String>(rewardBadgeId),
        rewardFieldAbilityUnlock:
            _trainerFieldUpdate<FieldAbility>(rewardFieldAbilityUnlock),
        tags: tags,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Trainer updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update trainer: $e');
      return false;
    }
  }

  Future<bool> deleteTrainer(String trainerId) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
      );
      state = state.copyWith(
        project: updated,
        selectedTrainerId: state.selectedTrainerId == trainerId
            ? null
            : state.selectedTrainerId,
        statusMessage: 'Trainer deleted',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete trainer: $e');
      return false;
    }
  }

  Future<bool> addTrainerPokemon({
    required String trainerId,
    required String speciesId,
    required int level,
    List<String> moves = const <String>[],
    String? heldItemId,
    String? formId,
    String? gender,
    bool shiny = false,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(addTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: heldItemId,
        formId: formId,
        gender: gender,
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon added',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add Pokémon: $e');
      return false;
    }
  }

  Future<bool> updateTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
    String? speciesId,
    int? level,
    List<String>? moves,
    Object? heldItemId = _trainerUnset,
    Object? formId = _trainerUnset,
    Object? gender = _trainerUnset,
    bool? shiny,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(updateTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
        speciesId: speciesId,
        level: level,
        moves: moves,
        heldItemId: _trainerFieldUpdate<String>(heldItemId),
        formId: _trainerFieldUpdate<String>(formId),
        gender: _trainerFieldUpdate<String>(gender),
        shiny: shiny,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon updated',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update Pokémon: $e');
      return false;
    }
  }

  Future<bool> deleteTrainerPokemon({
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final fs = _projectWorkspace;
    final project = state.project;
    if (fs == null || project == null) return false;
    try {
      final useCase = ref.read(deleteTrainerPokemonUseCaseProvider);
      final updated = await useCase.execute(
        fs,
        project,
        trainerId: trainerId,
        pokemonIndex: pokemonIndex,
      );
      state = state.copyWith(
        project: updated,
        statusMessage: 'Pokémon removed',
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to remove Pokémon: $e');
      return false;
    }
  }
}

TrainerFieldUpdate<T> _trainerFieldUpdate<T>(Object? rawValue) {
  if (identical(rawValue, _trainerUnset)) {
    return TrainerFieldUpdate<T>.keep();
  }
  return TrainerFieldUpdate<T>.set(rawValue as T?);
}

/// Prevents a generic manifest save from bypassing the baseline-aware
/// narrative transaction after a failed or indeterminate commit.
final class _NarrativeAuthoringSaveInterlock {
  const _NarrativeAuthoringSaveInterlock({
    required this.projectPath,
    required this.code,
    required this.message,
  });

  final String projectPath;
  final String code;
  final String message;
}

class _PaintPattern {
  const _PaintPattern({
    required this.size,
    required this.tiles,
  });

  final GridSize size;
  final List<TileLayerPaletteEntry?> tiles;
}

class _ResolvedBrushPattern {
  const _ResolvedBrushPattern({
    required this.tilesetId,
    required this.failureLabel,
    required this.pattern,
  });

  final String tilesetId;
  final String failureLabel;
  final _PaintPattern pattern;
}

class _ResolvedBrushFootprint {
  const _ResolvedBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class _ActiveTileLayerContext {
  const _ActiveTileLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final TileLayer layer;
}

class _ActiveCollisionLayerContext {
  const _ActiveCollisionLayerContext({
    required this.map,
    required this.layerId,
    required this.layer,
  });

  final MapData map;
  final String layerId;
  final CollisionLayer layer;
}

class _TileLayerGeneratedPlacementAddSelection {
  const _TileLayerGeneratedPlacementAddSelection({
    required this.project,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.item,
    required this.element,
  });

  final ProjectManifest project;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final EnvironmentPaletteItem item;
  final ProjectElementEntry element;
}
