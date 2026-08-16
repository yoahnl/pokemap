import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/cinematic_library_authoring_gateway.dart';
import '../../../application/models/narrative_document_route.dart';
import '../../../application/services/narrative_template_catalog.dart';
import '../../../features/character_studio/application/character_studio_media_resolver.dart';
import '../../../features/editor/state/models/editor_workspace_mode.dart';
import '../../design_system/design_system.dart';
import '../../../theme/theme.dart';
import '../narrative_studio/narrative_studio_route_presentation.dart';
import '../narrative_studio/narrative_studio_workspace_page.dart';
import 'cinematic_actor_sprite_preview_plan.dart';
import 'cinematic_actor_sprite_preview_resolver.dart';
import 'cinematic_builder_workspace.dart';
import 'cinematic_library_browser.dart';
import 'cinematic_library_dialogs.dart';
import 'cinematic_map_backdrop_layer_plan_loader.dart';
import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_tile_plan_loader.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_stage_preview_readiness.dart';

typedef CreateCinematicShellCallback = Future<String?> Function({
  required String title,
  NarrativeTemplateKind? templateKind,
});

typedef AdoptCanonicalCinematicLibraryManifest = void Function(
  ProjectManifest manifest, {
  required String statusMessage,
});

typedef UpdateCinematicMetadataCallback = Future<bool> Function({
  required String cinematicId,
  required String title,
  required String description,
  required String notes,
  required String? mapId,
  required String? storylineId,
  required String? chapterId,
  required List<String> tags,
  required bool archived,
});

typedef DuplicateCinematicCallback = Future<String?> Function(
    {required String cinematicId});

typedef ToggleCinematicArchiveCallback = Future<bool> Function({
  required String cinematicId,
  required bool archived,
});

typedef BulkTagCinematicsCallback = Future<bool> Function({
  required Set<String> cinematicIds,
  required List<String> tags,
});

typedef BulkArchiveCinematicsCallback = Future<bool> Function({
  required Set<String> cinematicIds,
  required bool archived,
});

typedef OpenCinematicSceneUsageCallback = void Function(
    {required String sceneId, required String nodeId});

typedef RemoveCinematicCallback = Future<bool> Function(
    {required String cinematicId});

typedef AddTimelineDraftCallback = Future<String?> Function({
  required String cinematicId,
  String? afterStepId,
});

typedef RemoveTimelineDraftCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef AddTimelineBasicBlockCallback = Future<String?> Function({
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
});

typedef UpdateTimelineBasicBlockCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
  CinematicTimelineCameraFocusBinding? cameraFocusBinding,
});

typedef AddRequiredActorCallback = Future<String?> Function(
    {required String cinematicId, String? label});

typedef RenameRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
  required String label,
});

typedef RemoveRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});

typedef AddMovementTargetCallback = Future<String?> Function(
    {required String cinematicId});

typedef UpdateMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
  required String label,
  String? description,
});

typedef RemoveMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
});

typedef AddTimelineActorFacingCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required CinematicTimelineActorFacingDirection direction,
  String? afterStepId,
});

typedef UpdateTimelineActorFacingCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
  int? durationMs,
});

typedef AddTimelineActorMoveCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String targetId,
  required int durationMs,
  required CinematicTimelineActorMovementMode movementMode,
  String? afterStepId,
});

typedef UpdateTimelineActorMoveCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
});

typedef AddTimelineActorEmoteCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String emoteId,
  int? durationMs,
  String? afterStepId,
});

typedef UpdateTimelineActorEmoteCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? emoteId,
  int? durationMs,
});

typedef UpsertTimelineActorAnimationCallback = Future<String?> Function({
  required String cinematicId,
  required CharacterCustomAnimationRuntimeCommand command,
  String? stepId,
  String? afterStepId,
  String? label,
});

typedef RemoveTimelineAuthoringStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef UpdateStageMapCallback = Future<bool> Function(
    {required String cinematicId, String? mapId});

typedef UpdateStageContextCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicStageContext stageContext,
});

typedef UpsertActorBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorBinding binding,
});

typedef UpsertActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
});

typedef RemoveActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});

typedef UpsertActorInitialPlacementCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorInitialPlacement placement,
});

typedef UpsertMovementTargetBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicMovementTargetBinding binding,
});

typedef LoadStageMapSnapshotCallback = Future<MapData?> Function(String mapId);

typedef BuildCinematicBackdropTileRenderPlanCallback
    = CinematicMapBackdropTileRenderPlan? Function({
  required CinematicAsset asset,
  required MapData? mapData,
  required CinematicMapBackdropPreviewModel? previewModel,
});

enum _CinematicsLibraryFilter { all, canonical }

class CinematicsLibraryWorkspace extends StatefulWidget {
  const CinematicsLibraryWorkspace({
    super.key,
    required this.project,
    this.projectRootPath,
    required this.onCreateCinematicShell,
    required this.onUpdateCinematicMetadata,
    required this.onDuplicateCinematic,
    required this.onToggleCinematicArchive,
    required this.onBulkTagCinematics,
    required this.onBulkArchiveCinematics,
    required this.onRemoveCinematic,
    required this.onAddTimelineDraft,
    required this.onRemoveTimelineDraft,
    required this.onAddTimelineBasicBlock,
    required this.onUpdateTimelineBasicBlock,
    required this.onAddRequiredActor,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onAddTimelineActorFacing,
    required this.onUpdateTimelineActorFacing,
    required this.onAddTimelineActorMove,
    required this.onUpdateTimelineActorMove,
    required this.onAddTimelineActorEmote,
    required this.onUpdateTimelineActorEmote,
    this.onUpsertTimelineActorAnimation,
    required this.onRemoveTimelineAuthoringStep,
    required this.onUpdateStageMap,
    required this.onUpdateStageContext,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onUpsertMovementTargetBinding,
    this.onUpdateCinematicAsset,
    this.onLoadStageMapSnapshot,
    this.onBuildBackdropTileRenderPlan,
    this.onResolveBackdropTilesetPath,
    this.startExpanded = false,
    this.requestedEntryId,
    this.requestedEntryNonce,
    this.openRequestedEntryInBuilder = false,
    this.onBuilderEntryChanged,
    this.onOpenSceneUsage,
    this.initialPresentationSource,
    this.onOpenPresentation,
    this.libraryAuthoringGateway,
    this.onCanonicalManifestChanged,
    this.startInAdvancedManager = false,
  });

  final bool startExpanded;
  final String? requestedEntryId;
  final int? requestedEntryNonce;
  final bool openRequestedEntryInBuilder;
  final ValueChanged<String?>? onBuilderEntryChanged;

  final ProjectManifest project;
  final String? projectRootPath;
  final CreateCinematicShellCallback onCreateCinematicShell;
  final UpdateCinematicMetadataCallback onUpdateCinematicMetadata;
  final DuplicateCinematicCallback onDuplicateCinematic;
  final ToggleCinematicArchiveCallback onToggleCinematicArchive;
  final BulkTagCinematicsCallback onBulkTagCinematics;
  final BulkArchiveCinematicsCallback onBulkArchiveCinematics;
  final OpenCinematicSceneUsageCallback? onOpenSceneUsage;
  final NarrativeLibrarySourceContext? initialPresentationSource;
  final OpenPresentationCinematicCallback? onOpenPresentation;
  final CinematicLibraryAuthoringGateway? libraryAuthoringGateway;
  final AdoptCanonicalCinematicLibraryManifest? onCanonicalManifestChanged;
  final bool startInAdvancedManager;
  final RemoveCinematicCallback onRemoveCinematic;
  final AddTimelineDraftCallback onAddTimelineDraft;
  final RemoveTimelineDraftCallback onRemoveTimelineDraft;
  final AddTimelineBasicBlockCallback onAddTimelineBasicBlock;
  final UpdateTimelineBasicBlockCallback onUpdateTimelineBasicBlock;
  final AddRequiredActorCallback onAddRequiredActor;
  final RenameRequiredActorCallback onRenameRequiredActor;
  final RemoveRequiredActorCallback onRemoveRequiredActor;
  final AddMovementTargetCallback onAddMovementTarget;
  final UpdateMovementTargetCallback onUpdateMovementTarget;
  final RemoveMovementTargetCallback onRemoveMovementTarget;
  final AddTimelineActorFacingCallback onAddTimelineActorFacing;
  final UpdateTimelineActorFacingCallback onUpdateTimelineActorFacing;
  final AddTimelineActorMoveCallback onAddTimelineActorMove;
  final UpdateTimelineActorMoveCallback onUpdateTimelineActorMove;
  final AddTimelineActorEmoteCallback onAddTimelineActorEmote;
  final UpdateTimelineActorEmoteCallback onUpdateTimelineActorEmote;
  final UpsertTimelineActorAnimationCallback? onUpsertTimelineActorAnimation;
  final RemoveTimelineAuthoringStepCallback onRemoveTimelineAuthoringStep;
  final UpdateStageMapCallback onUpdateStageMap;
  final UpdateStageContextCallback onUpdateStageContext;
  final UpsertActorBindingCallback onUpsertActorBinding;
  final UpsertActorAppearanceBindingCallback onUpsertActorAppearanceBinding;
  final RemoveActorAppearanceBindingCallback onRemoveActorAppearanceBinding;
  final UpsertActorInitialPlacementCallback onUpsertActorInitialPlacement;
  final UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;
  final UpdateCinematicAssetCallback? onUpdateCinematicAsset;
  final LoadStageMapSnapshotCallback? onLoadStageMapSnapshot;
  final BuildCinematicBackdropTileRenderPlanCallback?
      onBuildBackdropTileRenderPlan;
  final ResolveCinematicBackdropTilesetPath? onResolveBackdropTilesetPath;

  @override
  State<CinematicsLibraryWorkspace> createState() =>
      _CinematicsLibraryWorkspaceState();
}

class _CinematicsLibraryWorkspaceState
    extends State<CinematicsLibraryWorkspace> {
  final _createTitleController = TextEditingController();
  final _templateCatalog = NarrativeTemplateCatalog.canonical();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _bulkTagsController = TextEditingController();
  final _backdropLayerPlanLoader = CinematicMapBackdropLayerPlanLoader();
  final _characterStudioMediaResolver = CharacterStudioMediaResolver(
    source: const FileCharacterStudioMediaSource(),
  );

  _CinematicsLibraryFilter _filter = _CinematicsLibraryFilter.all;
  CinematicsLibraryVisibility _visibility = CinematicsLibraryVisibility.active;
  CinematicsLibrarySort _sort = CinematicsLibrarySort.titleAscending;
  String _searchText = '';
  final Set<String> _bulkSelection = <String>{};
  String _createTemplateId = 'cinematic.empty';
  String? _selectedEntryId;
  String? _builderEntryId;
  String? _loadedEditorId;
  String? _pendingDeleteId;
  String? _feedback;
  bool _requestedEntryUnavailable = false;
  String? _loadingStageMapSourceCatalogMapId;
  CinematicStageMapSourceCatalog? _stageMapSourceCatalog;
  MapData? _stageMapSnapshot;
  String? _stageMapSnapshotMapId;
  CinematicMapBackdropTileRenderPlan? _backdropTileRenderPlan;
  CinematicMapBackdropLayerRenderPlan? _backdropLayerRenderPlan;
  String? _backdropTileRenderPlanMapId;
  String? _backdropLayerRenderPlanMapId;
  String? _loadingBackdropTileRenderPlanMapId;
  int _stageMapSourceCatalogGeneration = 0;
  Map<String, CinematicResolvedTilesetAsset> _resolvedActorTilesets = const {};
  final Set<String> _loadingActorTilesetIds = {};
  int _actorTilesetGeneration = 0;
  late CinematicLibraryNavigationState _libraryNavigation;
  late bool _showAdvancedManager;

  @override
  void initState() {
    super.initState();
    _libraryNavigation = CinematicLibraryNavigationState.initial(
      restoredPresentation: widget.initialPresentationSource,
    );
    _showAdvancedManager = widget.startInAdvancedManager;
    _applyRequestedEntry();
  }

  @override
  void didUpdateWidget(covariant CinematicsLibraryWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project ||
        oldWidget.projectRootPath != widget.projectRootPath) {
      final previousRoot = oldWidget.projectRootPath?.trim();
      if (previousRoot != null && previousRoot.isNotEmpty) {
        _characterStudioMediaResolver.invalidateProject(previousRoot);
      }
      _actorTilesetGeneration++;
      _resolvedActorTilesets = const {};
      _loadingActorTilesetIds.clear();
    }
    final previousRequested = oldWidget.requestedEntryId?.trim();
    final requested = widget.requestedEntryId?.trim();
    final previousRequestId =
        previousRequested == null || previousRequested.isEmpty
            ? null
            : previousRequested;
    final requestId = requested == null || requested.isEmpty ? null : requested;
    final typedRequestChanged = previousRequestId != requestId ||
        (requestId != null &&
            (oldWidget.requestedEntryNonce != widget.requestedEntryNonce ||
                oldWidget.openRequestedEntryInBuilder !=
                    widget.openRequestedEntryInBuilder));
    final requestedEntryMayHaveChanged =
        requestId != null && oldWidget.project != widget.project;
    if (typedRequestChanged || requestedEntryMayHaveChanged) {
      _applyRequestedEntry();
    }
  }

  @override
  void dispose() {
    _createTitleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _bulkTagsController.dispose();
    _backdropLayerPlanLoader.clear();
    final projectRoot = widget.projectRootPath?.trim();
    if (projectRoot != null && projectRoot.isNotEmpty) {
      _characterStudioMediaResolver.invalidateProject(projectRoot);
    }
    _actorTilesetGeneration++;
    _loadingActorTilesetIds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readModel = buildCinematicsLibraryReadModel(widget.project);
    if (_requestedEntryUnavailable) {
      return _buildRequestedEntryUnavailable();
    }
    _ensureSelection(readModel);
    final selectedEntry = _selectedEntryId == null
        ? null
        : readModel.entryById(_selectedEntryId!);
    _syncMetadataEditor(selectedEntry);
    final builderEntry =
        _builderEntryId == null ? null : readModel.entryById(_builderEntryId!);
    final builderAsset = _builderEntryId == null
        ? null
        : findCinematicById(widget.project, _builderEntryId!);
    if (builderEntry != null &&
        builderEntry.kind == CinematicsLibraryEntryKind.canonical &&
        builderAsset != null) {
      _ensureStageMapSourceCatalog(builderAsset);
      _ensureActorTilesets(builderAsset);
      final backdropPreviewModel = _buildBackdropPreviewModel(builderAsset);
      final actorDisplayPreviewModel = _buildActorDisplayPreviewModel(
        builderAsset,
      );
      final backdropTileRenderPlan = _buildBackdropTileRenderPlan(
        builderAsset,
        backdropPreviewModel,
      );
      final backdropLayerRenderPlan = _buildBackdropLayerRenderPlan(
        builderAsset,
      );
      final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan =
          actorDisplayPreviewModel == null
              ? null
              : buildCinematicActorSpritePreviewPlan(
                  actorDisplayModel: actorDisplayPreviewModel,
                  project: widget.project,
                );
      final combinedTilesets = <String, CinematicResolvedTilesetAsset>{
        ...?backdropLayerRenderPlan?.tilesets,
        ...?backdropTileRenderPlan?.tilesets,
        ..._resolvedActorTilesets,
      };
      return CinematicBuilderWorkspace(
        entry: builderEntry,
        asset: builderAsset,
        stageMaps: widget.project.maps,
        groups: widget.project.groups,
        characters: widget.project.characters,
        animationDefinitions:
            widget.project.characterStudioCatalog.customAnimationDefinitions,
        dialogues: widget.project.dialogues,
        cinematicMediaAssets: widget.project.cinematicMediaAssets,
        projectRootPath: widget.projectRootPath,
        stageMapSourceCatalog: _stageMapSourceCatalog,
        backdropPreviewModel: backdropPreviewModel,
        backdropTileRenderPlan: backdropTileRenderPlan,
        backdropLayerRenderPlan: backdropLayerRenderPlan,
        actorDisplayPreviewModel: actorDisplayPreviewModel,
        actorSpritePreviewPlan: actorSpritePreviewPlan,
        tilesets: combinedTilesets,
        startExpanded: widget.startExpanded,
        onUpdateCinematicAsset: widget.onUpdateCinematicAsset,
        onBackToLibrary: _closeBuilder,
        onAddDraftStep: widget.onAddTimelineDraft,
        onRemoveDraftStep: widget.onRemoveTimelineDraft,
        onAddBasicBlockStep: widget.onAddTimelineBasicBlock,
        onUpdateBasicBlockStep: widget.onUpdateTimelineBasicBlock,
        onAddRequiredActor: widget.onAddRequiredActor,
        onRenameRequiredActor: widget.onRenameRequiredActor,
        onRemoveRequiredActor: widget.onRemoveRequiredActor,
        onAddMovementTarget: widget.onAddMovementTarget,
        onUpdateMovementTarget: widget.onUpdateMovementTarget,
        onRemoveMovementTarget: widget.onRemoveMovementTarget,
        onAddActorFacingStep: widget.onAddTimelineActorFacing,
        onUpdateActorFacingStep: widget.onUpdateTimelineActorFacing,
        onAddActorMoveStep: widget.onAddTimelineActorMove,
        onUpdateActorMoveStep: widget.onUpdateTimelineActorMove,
        onAddActorEmoteStep: widget.onAddTimelineActorEmote,
        onUpdateActorEmoteStep: widget.onUpdateTimelineActorEmote,
        onUpsertActorAnimationStep: widget.onUpsertTimelineActorAnimation ??
            ({
              required String cinematicId,
              required CharacterCustomAnimationRuntimeCommand command,
              String? stepId,
              String? afterStepId,
              String? label,
            }) async =>
                null,
        onRemoveAuthoringStep: widget.onRemoveTimelineAuthoringStep,
        onUpdateStageMap: widget.onUpdateStageMap,
        onUpdateStageContext: widget.onUpdateStageContext,
        onUpsertActorBinding: widget.onUpsertActorBinding,
        onUpsertActorAppearanceBinding: widget.onUpsertActorAppearanceBinding,
        onRemoveActorAppearanceBinding: widget.onRemoveActorAppearanceBinding,
        onUpsertActorInitialPlacement: widget.onUpsertActorInitialPlacement,
        onUpsertMovementTargetBinding: widget.onUpsertMovementTargetBinding,
      );
    }
    if (_builderEntryId != null) {
      _builderEntryId = null;
      _stageMapSourceCatalog = null;
      _stageMapSnapshot = null;
      _stageMapSnapshotMapId = null;
      _backdropTileRenderPlan = null;
      _backdropLayerRenderPlan = null;
      _backdropTileRenderPlanMapId = null;
      _backdropLayerRenderPlanMapId = null;
      _loadingBackdropTileRenderPlanMapId = null;
      _loadingStageMapSourceCatalogMapId = null;
    }
    if (!_showAdvancedManager) {
      return Material(
        type: MaterialType.transparency,
        child: NarrativeStudioWorkspacePage(
          presentation: narrativeStudioRoutePresentationFor(
            EditorWorkspaceMode.cinematics,
          )!,
          actions: [
            PokeMapButton(
              key: const ValueKey('cinematics-library-advanced-manager'),
              onPressed: () => setState(() => _showAdvancedManager = true),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.slider_horizontal_3),
              child: const Text('Gestion avancée'),
            ),
          ],
          body: PokeMapPageSurface(
            key: const ValueKey('cinematics-library-workspace'),
            child: CinematicLibraryBrowser(
              project: widget.project,
              navigation: _libraryNavigation,
              onNavigationChanged: (value) {
                setState(() => _libraryNavigation = value);
              },
              onOpenInGame: _openInGameFromLibrary,
              onOpenPresentation: widget.onOpenPresentation ??
                  ({required cinematicId, required source}) {},
              onCreate: _canUseLibraryCommands ? _createFromLibrary : null,
              onRename: _canUseLibraryCommands ? _renameFromLibrary : null,
              onMove: _canUseLibraryCommands ? _moveFromLibrary : null,
              onDuplicate:
                  _canUseLibraryCommands ? _duplicateFromLibrary : null,
              onArchive: _canUseLibraryCommands ? _archiveFromLibrary : null,
              onDelete: _canUseLibraryCommands ? _deleteFromLibrary : null,
            ),
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: NarrativeStudioWorkspacePage(
        presentation: narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.cinematics,
        )!,
        leading: PokeMapIconButton(
          key: const ValueKey('cinematics-advanced-manager-back'),
          onPressed: () => setState(() => _showAdvancedManager = false),
          tooltip: 'Retour aux bibliothèques de cinématiques',
          variant: PokeMapIconButtonVariant.soft,
          icon: const Icon(CupertinoIcons.chevron_left),
        ),
        body: PokeMapPageSurface(
          key: const ValueKey('cinematics-library-workspace'),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 720;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (compactHeight)
                    _CompactMetricsStrip(readModel: readModel)
                  else
                    SizedBox(
                      height: 126,
                      child: _MetricsStrip(readModel: readModel),
                    ),
                  const SizedBox(height: 12),
                  _buildFilterBar(context),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 310,
                          child: _buildExplorer(context, readModel),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildDetails(context, selectedEntry),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 300,
                          child: _buildUsageAndDiagnostics(
                            context,
                            selectedEntry,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openInGameFromLibrary(String cinematicId) {
    final entry = buildCinematicsLibraryReadModel(
      widget.project,
    ).entryById(cinematicId);
    if (entry == null || entry.kind != CinematicsLibraryEntryKind.canonical) {
      return;
    }
    setState(() {
      _selectedEntryId = cinematicId;
      _builderEntryId = cinematicId;
      _loadedEditorId = null;
    });
    widget.onBuilderEntryChanged?.call(cinematicId);
  }

  bool get _canUseLibraryCommands {
    final root = widget.projectRootPath?.trim();
    return widget.libraryAuthoringGateway != null &&
        widget.onCanonicalManifestChanged != null &&
        root != null &&
        root.isNotEmpty;
  }

  Future<String?> _createFromLibrary(
    CinematicLibraryCreateRequest request,
  ) async {
    final root = widget.projectRootPath?.trim();
    final gateway = widget.libraryAuthoringGateway;
    final adopt = widget.onCanonicalManifestChanged;
    if (root == null || root.isEmpty || gateway == null || adopt == null) {
      throw StateError('Le projet doit être enregistré avant la création.');
    }
    final result = await gateway.create(
      root,
      expectedProject: widget.project,
      family: request.family,
      title: request.title,
      folderId: request.folderId,
      worldStartingPoint: request.worldStartingPoint,
      presentationTemplateId: request.presentationTemplateId,
      presentationTemplateVersion: request.presentationTemplateVersion,
    );
    adopt(
      result.manifest,
      statusMessage: 'Cinématique « ${request.title} » créée',
    );
    if (!mounted) return result.cinematicId;
    final selectedNavigation = _libraryNavigation
        .switchFamily(request.family)
        .updateActive(
          folderId: request.folderId,
          selectedAssetId: result.cinematicId,
          scrollOffset: 0,
        );
    setState(() => _libraryNavigation = selectedNavigation);
    if (request.family == CinematicLibraryFamily.world) {
      setState(() {
        _selectedEntryId = result.cinematicId;
        _builderEntryId = result.cinematicId;
        _loadedEditorId = null;
      });
      widget.onBuilderEntryChanged?.call(result.cinematicId);
    } else {
      widget.onOpenPresentation?.call(
        cinematicId: result.cinematicId,
        source: selectedNavigation.active.toSourceContext(),
      );
    }
    return result.cinematicId;
  }

  Future<void> _renameFromLibrary({
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String title,
  }) async {
    final gateway = _requireLibraryGateway();
    final manifest = await gateway.rename(
      _requireProjectRoot(),
      expectedProject: widget.project,
      family: family,
      cinematicId: cinematicId,
      title: title,
    );
    _adoptLibraryManifest(manifest, 'Cinématique renommée');
  }

  Future<void> _moveFromLibrary({
    required CinematicLibraryFamily family,
    required String cinematicId,
    String? folderId,
  }) async {
    final manifest = await _requireLibraryGateway().move(
      _requireProjectRoot(),
      expectedProject: widget.project,
      family: family,
      cinematicId: cinematicId,
      folderId: folderId,
    );
    _adoptLibraryManifest(manifest, 'Cinématique déplacée');
  }

  Future<String?> _duplicateFromLibrary({
    required CinematicLibraryFamily family,
    required String cinematicId,
    String? folderId,
  }) async {
    final result = await _requireLibraryGateway().duplicate(
      _requireProjectRoot(),
      expectedProject: widget.project,
      family: family,
      cinematicId: cinematicId,
      folderId: folderId,
    );
    _adoptLibraryManifest(result.manifest, 'Cinématique dupliquée');
    return result.cinematicId;
  }

  Future<void> _archiveFromLibrary({
    required CinematicLibraryFamily family,
    required String cinematicId,
    required bool archived,
  }) async {
    final manifest = await _requireLibraryGateway().setArchived(
      _requireProjectRoot(),
      expectedProject: widget.project,
      family: family,
      cinematicId: cinematicId,
      archived: archived,
    );
    _adoptLibraryManifest(
      manifest,
      archived ? 'Cinématique archivée' : 'Cinématique restaurée',
    );
  }

  Future<void> _deleteFromLibrary({
    required CinematicLibraryFamily family,
    required String cinematicId,
  }) async {
    final manifest = await _requireLibraryGateway().delete(
      _requireProjectRoot(),
      expectedProject: widget.project,
      family: family,
      cinematicId: cinematicId,
    );
    _adoptLibraryManifest(manifest, 'Cinématique supprimée');
  }

  CinematicLibraryAuthoringGateway _requireLibraryGateway() {
    final gateway = widget.libraryAuthoringGateway;
    if (gateway == null) {
      throw StateError('Les commandes de bibliothèque sont indisponibles.');
    }
    return gateway;
  }

  String _requireProjectRoot() {
    final root = widget.projectRootPath?.trim();
    if (root == null || root.isEmpty) {
      throw StateError('Le projet doit être enregistré avant cette action.');
    }
    return root;
  }

  void _adoptLibraryManifest(ProjectManifest manifest, String message) {
    final adopt = widget.onCanonicalManifestChanged;
    if (adopt == null) {
      throw StateError('La projection canonique du projet est indisponible.');
    }
    adopt(manifest, statusMessage: message);
  }

  Widget _buildRequestedEntryUnavailable() {
    final requested = widget.requestedEntryId?.trim();
    return Material(
      type: MaterialType.transparency,
      child: NarrativeStudioWorkspacePage(
        presentation: narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.cinematics,
        )!,
        body: PokeMapPageSurface(
          key: const ValueKey('cinematics-library-requested-unavailable'),
          child: PokeMapEmptyState(
            title: 'Cinématique introuvable',
            description:
                'La cible $requested n’existe plus dans le projet. Revenez à la bibliothèque pour choisir une autre cinématique.',
            icon: const Icon(CupertinoIcons.exclamationmark_triangle),
          ),
        ),
      ),
    );
  }

  void _ensureStageMapSourceCatalog(CinematicAsset asset) {
    final mapId = asset.mapId?.trim();
    if (mapId == null || mapId.isEmpty) {
      if (_stageMapSourceCatalog != null ||
          _stageMapSnapshot != null ||
          _stageMapSnapshotMapId != null ||
          _loadingStageMapSourceCatalogMapId != null) {
        scheduleMicrotask(() {
          if (!mounted) {
            return;
          }
          setState(() {
            _stageMapSourceCatalog = null;
            _stageMapSnapshot = null;
            _stageMapSnapshotMapId = null;
            _backdropTileRenderPlan = null;
            _backdropLayerRenderPlan = null;
            _backdropTileRenderPlanMapId = null;
            _backdropLayerRenderPlanMapId = null;
            _loadingBackdropTileRenderPlanMapId = null;
            _loadingStageMapSourceCatalogMapId = null;
            _stageMapSourceCatalogGeneration++;
          });
        });
      }
      return;
    }
    if (_stageMapSourceCatalog?.stageMapId == mapId) {
      bool needsTilesetReload = false;
      if (widget.onBuildBackdropTileRenderPlan == null &&
          _stageMapSnapshotMapId == mapId &&
          _loadingBackdropTileRenderPlanMapId != mapId) {
        if (_backdropLayerRenderPlanMapId != mapId ||
            _backdropLayerRenderPlan == null) {
          needsTilesetReload = true;
        } else {
          final actorDisplayPreviewModel = _buildActorDisplayPreviewModel(
            asset,
          );
          if (actorDisplayPreviewModel != null) {
            final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
              actorDisplayModel: actorDisplayPreviewModel,
              project: widget.project,
            );
            for (final actor in actorSpritePreviewPlan.actors) {
              final tilesetId = actor.spriteRef?.tilesetId;
              if (tilesetId != null && tilesetId.isNotEmpty) {
                if (!_backdropLayerRenderPlan!.tilesets.containsKey(
                  tilesetId,
                )) {
                  needsTilesetReload = true;
                  break;
                }
              }
            }
          }
        }
      }

      if (needsTilesetReload) {
        unawaited(
          _loadBackdropTileRenderPlan(
            asset: asset,
            mapId: mapId,
            mapData: _stageMapSnapshot,
            previewModel: _buildBackdropPreviewModel(asset),
            generation: _stageMapSourceCatalogGeneration,
          ),
        );
      }
      return;
    }
    if (_loadingStageMapSourceCatalogMapId == mapId) {
      return;
    }

    final loader = widget.onLoadStageMapSnapshot;
    if (loader == null) {
      return;
    }

    final generation = ++_stageMapSourceCatalogGeneration;
    _loadingStageMapSourceCatalogMapId = mapId;
    _stageMapSourceCatalog = null;
    _stageMapSnapshot = null;
    _stageMapSnapshotMapId = mapId;
    _backdropTileRenderPlan = null;
    _backdropLayerRenderPlan = null;
    _backdropTileRenderPlanMapId = null;
    _backdropLayerRenderPlanMapId = null;
    _loadingBackdropTileRenderPlanMapId = null;
    unawaited(() async {
      final mapData = await loader(mapId);
      if (!mounted || generation != _stageMapSourceCatalogGeneration) {
        return;
      }
      final stageMap = _stageMapForId(widget.project.maps, mapId);
      final previewModel = _buildBackdropPreviewModelFor(
        asset: asset,
        stageMap: stageMap,
        mapData: mapData,
      );
      setState(() {
        _stageMapSourceCatalog = buildCinematicStageMapSourceCatalog(
          stageMap: stageMap,
          mapData: mapData,
        );
        _stageMapSnapshot = mapData;
        _stageMapSnapshotMapId = mapId;
        _loadingStageMapSourceCatalogMapId = null;
      });
      await _loadBackdropTileRenderPlan(
        asset: asset,
        mapId: mapId,
        mapData: mapData,
        previewModel: previewModel,
        generation: generation,
      );
    }());
  }

  CinematicMapBackdropPreviewModel? _buildBackdropPreviewModelFor({
    required CinematicAsset asset,
    required ProjectMapEntry? stageMap,
    required MapData? mapData,
  }) {
    if (asset.stageContext?.backdropMode !=
        CinematicStageBackdropMode.projectMap) {
      return null;
    }
    return buildCinematicMapBackdropPreviewModel(
      asset: asset,
      stageMap: stageMap,
      mapData: mapData,
      availableTilesetIds: _availableTilesetIds(widget.project),
      smartTileCatalog: widget.project.smartTileCatalog,
    );
  }

  CinematicMapBackdropPreviewModel? _buildBackdropPreviewModel(
    CinematicAsset asset,
  ) {
    final mapId = asset.mapId?.trim();
    final stageMap = mapId == null || mapId.isEmpty
        ? null
        : _stageMapForId(widget.project.maps, mapId);
    final mapData = _stageMapSnapshotMapId == mapId ? _stageMapSnapshot : null;
    return _buildBackdropPreviewModelFor(
      asset: asset,
      stageMap: stageMap,
      mapData: mapData,
    );
  }

  CinematicActorDisplayPreviewModel? _buildActorDisplayPreviewModel(
    CinematicAsset asset,
  ) {
    if (asset.stageContext?.backdropMode !=
        CinematicStageBackdropMode.projectMap) {
      return null;
    }
    final mapId = asset.mapId?.trim();
    final stageMap = mapId == null || mapId.isEmpty
        ? null
        : _stageMapForId(widget.project.maps, mapId);
    final mapData = _stageMapSnapshotMapId == mapId ? _stageMapSnapshot : null;
    final sourceCatalog = _stageMapSourceCatalog?.stageMapId == mapId
        ? _stageMapSourceCatalog
        : null;
    return buildCinematicActorDisplayPreviewModel(
      cinematic: asset,
      project: widget.project,
      stageMap: stageMap,
      mapData: mapData,
      stageMapSourceCatalog: sourceCatalog,
    );
  }

  ProjectTilesetEntry? _tilesetById(
    ProjectManifest manifest,
    String tilesetId,
  ) {
    for (final tileset in manifest.tilesets) {
      if (tileset.id.trim() == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  void _ensureActorTilesets(CinematicAsset asset) {
    final resolver = widget.onResolveBackdropTilesetPath;
    final requiredTilesetIds = <String>{};
    final requiredCustomAssetIds = <String>{};

    // 1. Scan actor appearance bindings
    final bindings = asset.stageContext?.actorAppearanceBindings ?? const [];
    for (final binding in bindings) {
      final characterId = binding.characterId.trim();
      if (characterId.isNotEmpty) {
        for (final character in widget.project.characters) {
          if (character.id.trim() == characterId) {
            final tilesetId = character.tilesetId.trim();
            if (resolver != null && tilesetId.isNotEmpty) {
              requiredTilesetIds.add(tilesetId);
            }
            break;
          }
        }
      }
    }

    // 2. Scan default player character settings as fallback
    final defaultPlayerCharId =
        widget.project.settings.defaultPlayerCharacterId?.trim();
    if (defaultPlayerCharId != null && defaultPlayerCharId.isNotEmpty) {
      for (final character in widget.project.characters) {
        if (character.id.trim() == defaultPlayerCharId) {
          final tilesetId = character.tilesetId.trim();
          if (resolver != null && tilesetId.isNotEmpty) {
            requiredTilesetIds.add(tilesetId);
          }
          break;
        }
      }
    }

    final projectRoot = widget.projectRootPath?.trim();
    if (projectRoot != null && projectRoot.isNotEmpty) {
      for (final character in widget.project.characters) {
        for (final clip in character.customAnimations) {
          final assetId = clip.sourceAssetId.trim();
          if (assetId.isNotEmpty) requiredCustomAssetIds.add(assetId);
        }
      }
    }

    final missingTilesetIds =
        {...requiredTilesetIds, ...requiredCustomAssetIds}.where((id) {
      return !_resolvedActorTilesets.containsKey(id) &&
          !_loadingActorTilesetIds.contains(id);
    }).toList();

    if (missingTilesetIds.isEmpty) {
      return;
    }

    _loadingActorTilesetIds.addAll(missingTilesetIds);
    final generation = _actorTilesetGeneration;

    unawaited(() async {
      final newResolved = Map<String, CinematicResolvedTilesetAsset>.from(
        _resolvedActorTilesets,
      );
      bool changed = false;
      for (final id in missingTilesetIds) {
        try {
          if (requiredCustomAssetIds.contains(id)) {
            final bytes = await _characterStudioMediaResolver.resolve(
              CharacterStudioMediaRequest(
                projectRootPath: projectRoot!,
                assetId: id,
                projectRevision: widget.project.hashCode.toString(),
              ),
            );
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            codec.dispose();
            newResolved[id] = CinematicResolvedTilesetAsset.available(
              tilesetId: id,
              image: frame.image,
              tileWidth: 1,
              tileHeight: 1,
            );
          } else if (resolver != null) {
            final tileset = _tilesetById(widget.project, id);
            final path = resolver(id);
            final resolved = await _backdropLayerPlanLoader.registry.resolve(
              tileset: tileset,
              absolutePath: path,
              tileWidth: widget.project.settings.tileWidth,
              tileHeight: widget.project.settings.tileHeight,
            );
            newResolved[id] = resolved;
          }
          changed = true;
        } catch (_) {
        } finally {
          _loadingActorTilesetIds.remove(id);
        }
      }

      if (changed && mounted && generation == _actorTilesetGeneration) {
        setState(() {
          _resolvedActorTilesets = Map.unmodifiable(newResolved);
        });
      }
    }());
  }

  Future<void> _loadBackdropTileRenderPlan({
    required CinematicAsset asset,
    required String mapId,
    required MapData? mapData,
    required CinematicMapBackdropPreviewModel? previewModel,
    required int generation,
  }) async {
    final resolver = widget.onResolveBackdropTilesetPath;
    if (resolver == null || mapData == null || previewModel == null) {
      return;
    }
    if (_loadingBackdropTileRenderPlanMapId == mapId) {
      return;
    }
    _loadingBackdropTileRenderPlanMapId = mapId;

    final additionalTilesetIds = <String>{};
    final actorDisplayPreviewModel = _buildActorDisplayPreviewModel(asset);
    if (actorDisplayPreviewModel != null) {
      final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: actorDisplayPreviewModel,
        project: widget.project,
      );
      for (final actor in actorSpritePreviewPlan.actors) {
        final tilesetId = actor.spriteRef?.tilesetId;
        if (tilesetId != null && tilesetId.isNotEmpty) {
          additionalTilesetIds.add(tilesetId);
        }
      }
    }

    final plan = await _backdropLayerPlanLoader.load(
      manifest: widget.project,
      mapData: mapData,
      previewModel: previewModel,
      resolveTilesetPath: resolver,
      additionalTilesetIds: additionalTilesetIds,
    );
    if (!mounted) {
      return;
    }
    if (generation != _stageMapSourceCatalogGeneration) {
      if (_loadingBackdropTileRenderPlanMapId == mapId) {
        _loadingBackdropTileRenderPlanMapId = null;
      }
      return;
    }
    setState(() {
      _backdropLayerRenderPlan = plan;
      _backdropLayerRenderPlanMapId = mapId;
      _loadingBackdropTileRenderPlanMapId = null;
    });
  }

  CinematicMapBackdropTileRenderPlan? _buildBackdropTileRenderPlan(
    CinematicAsset asset,
    CinematicMapBackdropPreviewModel? previewModel,
  ) {
    if (asset.stageContext?.backdropMode !=
        CinematicStageBackdropMode.projectMap) {
      return null;
    }
    final mapId = asset.mapId?.trim();
    final mapData = _stageMapSnapshotMapId == mapId ? _stageMapSnapshot : null;
    final builder = widget.onBuildBackdropTileRenderPlan;
    if (builder != null) {
      return builder(
        asset: asset,
        mapData: mapData,
        previewModel: previewModel,
      );
    }
    if (_backdropTileRenderPlanMapId == mapId) {
      return _backdropTileRenderPlan;
    }
    return null;
  }

  CinematicMapBackdropLayerRenderPlan? _buildBackdropLayerRenderPlan(
    CinematicAsset asset,
  ) {
    if (asset.stageContext?.backdropMode !=
        CinematicStageBackdropMode.projectMap) {
      return null;
    }
    if (widget.onBuildBackdropTileRenderPlan != null) {
      return null;
    }
    final mapId = asset.mapId?.trim();
    if (_backdropLayerRenderPlanMapId == mapId) {
      return _backdropLayerRenderPlan;
    }
    return null;
  }

  void _closeBuilder() {
    setState(() {
      _builderEntryId = null;
      _stageMapSourceCatalog = null;
      _stageMapSnapshot = null;
      _stageMapSnapshotMapId = null;
      _backdropTileRenderPlan = null;
      _backdropLayerRenderPlan = null;
      _backdropTileRenderPlanMapId = null;
      _backdropLayerRenderPlanMapId = null;
      _loadingBackdropTileRenderPlanMapId = null;
      _loadingStageMapSourceCatalogMapId = null;
      _stageMapSourceCatalogGeneration++;
      _actorTilesetGeneration++;
      _resolvedActorTilesets = const {};
      _loadingActorTilesetIds.clear();
    });
    widget.onBuilderEntryChanged?.call(null);
  }

  Widget _buildFilterBar(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PokeMapButton(
          onPressed: () =>
              setState(() => _filter = _CinematicsLibraryFilter.all),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          isSelected: _filter == _CinematicsLibraryFilter.all,
          child: const Text('Toutes'),
        ),
        PokeMapButton(
          onPressed: () =>
              setState(() => _filter = _CinematicsLibraryFilter.canonical),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          isSelected: _filter == _CinematicsLibraryFilter.canonical,
          child: const Text('Canoniques'),
        ),
        SizedBox(
          width: 210,
          child: PokeMapDropdownField<CinematicsLibrarySort>(
            key: const ValueKey('cinematics-library-sort'),
            label: 'Trier',
            value: _sort,
            compact: true,
            items: const [
              PokeMapDropdownItem(
                value: CinematicsLibrarySort.titleAscending,
                label: 'Titre A–Z',
              ),
              PokeMapDropdownItem(
                value: CinematicsLibrarySort.durationDescending,
                label: 'Durée décroissante',
              ),
              PokeMapDropdownItem(
                value: CinematicsLibrarySort.usageDescending,
                label: 'Usages décroissants',
              ),
              PokeMapDropdownItem(
                value: CinematicsLibrarySort.locationAscending,
                label: 'Storyline / lieu',
              ),
            ],
            onChanged: (value) => setState(() => _sort = value),
          ),
        ),
        SizedBox(
          width: 190,
          child: PokeMapDropdownField<CinematicsLibraryVisibility>(
            key: const ValueKey('cinematics-library-visibility'),
            label: 'Afficher',
            value: _visibility,
            compact: true,
            items: const [
              PokeMapDropdownItem(
                value: CinematicsLibraryVisibility.active,
                label: 'Actives',
              ),
              PokeMapDropdownItem(
                value: CinematicsLibraryVisibility.archived,
                label: 'Archivées',
              ),
              PokeMapDropdownItem(
                value: CinematicsLibraryVisibility.all,
                label: 'Toutes',
              ),
            ],
            onChanged: (value) => setState(() => _visibility = value),
          ),
        ),
      ],
    );
  }

  Widget _buildExplorer(
    BuildContext context,
    CinematicsLibraryReadModel readModel,
  ) {
    final entries = _filteredEntries(readModel);
    final groups = readModel.groupEntries(
      CinematicsLibraryQuery(
        searchText: _searchText,
        visibility: _visibility,
        sort: _sort,
        kind: switch (_filter) {
          _CinematicsLibraryFilter.all => null,
          _CinematicsLibraryFilter.canonical =>
            CinematicsLibraryEntryKind.canonical,
        },
      ),
    );
    final groupedEntries =
        <({CinematicsLibraryGroup group, CinematicsLibraryEntry entry})>[
      for (final group in groups)
        for (final entry in group.entries) (group: group, entry: entry),
    ];
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Bibliothèque',
            subtitle: '${readModel.metrics.canonicalCount} canonique(s)',
          ),
          const SizedBox(height: 10),
          PokeMapSearchField(
            key: const ValueKey('cinematics-library-search'),
            hintText: 'Titre, tag, map, Scene…',
            semanticLabel: 'Rechercher une cinématique',
            onChanged: (value) => setState(() => _searchText = value),
          ),
          const SizedBox(height: 10),
          _CreateCinematicPanel(
            controller: _createTitleController,
            templateId: _createTemplateId,
            templates: _templateCatalog.cinematicTemplates,
            onTemplateChanged: (value) {
              setState(() {
                _createTemplateId = value;
                final selected = _templateCatalog.cinematicTemplates
                    .where((template) => template.id == value)
                    .firstOrNull;
                if (selected != null &&
                    _createTitleController.text.trim().isEmpty) {
                  _createTitleController.text = selected.label;
                }
              });
            },
            onCreate: _createCinematic,
          ),
          const SizedBox(height: 12),
          if (_bulkSelection.isNotEmpty) ...[
            _CinematicBulkBar(
              selectedCount: _bulkSelection.length,
              tagsController: _bulkTagsController,
              onApplyTags: _applyBulkTags,
              onArchive: () => _archiveBulk(true),
              onRestore: () => _archiveBulk(false),
              onClear: () => setState(_bulkSelection.clear),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: entries.isEmpty || groupedEntries.isEmpty
                ? const _EmptyState(
                    title: 'Aucune cinématique canonique',
                    description:
                        'Créez une shell vide, puis remplissez sa timeline dans le futur Builder V2.',
                  )
                : ListView.builder(
                    key: const ValueKey('cinematics-library-list'),
                    scrollCacheExtent: const ScrollCacheExtent.pixels(300),
                    itemCount: groupedEntries.length,
                    itemBuilder: (context, index) {
                      final item = groupedEntries[index];
                      final entry = item.entry;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CinematicTreeHeader(group: item.group),
                          _CinematicEntryCard(
                            key: ValueKey('cinematic-entry-${entry.id}'),
                            entry: entry,
                            selected: _selectedEntryId == entry.id,
                            bulkSelected: _bulkSelection.contains(entry.id),
                            onToggleBulk: entry.kind ==
                                    CinematicsLibraryEntryKind.canonical
                                ? () => setState(() {
                                      if (!_bulkSelection.add(entry.id)) {
                                        _bulkSelection.remove(entry.id);
                                      }
                                    })
                                : null,
                            onTap: () {
                              setState(() {
                                _selectedEntryId = entry.id;
                                _pendingDeleteId = null;
                                _feedback = null;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context, CinematicsLibraryEntry? entry) {
    if (entry == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: _EmptyState(
          title: 'Aucune cinématique sélectionnée',
          description: 'Sélectionnez une cinématique pour inspecter son état.',
        ),
      );
    }
    return _buildCanonicalDetails(context, entry);
  }

  Widget _buildCanonicalDetails(
    BuildContext context,
    CinematicsLibraryEntry entry,
  ) {
    final asset = findCinematicById(widget.project, entry.id);
    final deleteLabel = _pendingDeleteId == entry.id
        ? 'Confirmer suppression'
        : 'Supprimer la cinématique';
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PanelHeader(
              title: entry.title,
              subtitle: entry.id,
              badge: const PokeMapBadge(
                label: 'Canonique',
                variant: PokeMapBadgeVariant.success,
              ),
            ),
            const SizedBox(height: 10),
            _buildCanonicalActions(entry, deleteLabel),
            const SizedBox(height: 12),
            const _FieldLabel('Titre'),
            CupertinoTextField(
              key: const ValueKey('cinematics-library-title-field'),
              controller: _titleController,
              placeholder: 'Titre auteur',
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Description'),
            CupertinoTextField(
              key: const ValueKey('cinematics-library-description-field'),
              controller: _descriptionController,
              placeholder: 'Description',
              minLines: 3,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Notes'),
            CupertinoTextField(
              key: const ValueKey('cinematics-library-notes-field'),
              controller: _notesController,
              placeholder: 'Notes auteur',
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            const _FieldLabel('Tags (séparés par des virgules)'),
            CupertinoTextField(
              key: const ValueKey('cinematics-library-tags-field'),
              controller: _tagsController,
              placeholder: 'port, rival, introduction',
            ),
            const SizedBox(height: 10),
            _CinematicClassificationPickers(
              project: widget.project,
              entry: entry,
              onChanged: ({mapId, storylineId, chapterId}) => _saveMetadata(
                entry,
                mapId: mapId,
                storylineId: storylineId,
                chapterId: chapterId,
              ),
            ),
            if (!entry.isRemovable) ...[
              const SizedBox(height: 8),
              const PokeMapBadge(
                label: 'Suppression bloquée : utilisée par une Scene',
                variant: PokeMapBadgeVariant.warning,
              ),
            ],
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              PokeMapBadge(
                label: _feedback!,
                variant: PokeMapBadgeVariant.info,
              ),
            ],
            const SizedBox(height: 16),
            _MetadataSummary(
              entry: entry,
              maps: widget.project.maps,
              characters: widget.project.characters,
              asset: asset,
              mapWidth: _stageMapSnapshotMapId == asset?.mapId
                  ? _stageMapSnapshot?.size.width
                  : null,
              mapHeight: _stageMapSnapshotMapId == asset?.mapId
                  ? _stageMapSnapshot?.size.height
                  : null,
            ),
            const SizedBox(height: 12),
            _TimelineSummaryPanel(timeline: entry.timeline),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageAndDiagnostics(
    BuildContext context,
    CinematicsLibraryEntry? entry,
  ) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: entry == null
          ? const _EmptyState(
              title: 'Aucun détail',
              description:
                  'Les usages et diagnostics apparaissent après sélection.',
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    title: 'Usages depuis Scenes',
                    subtitle: _usageLabel(entry.usages.length),
                  ),
                  const SizedBox(height: 10),
                  if (entry.usages.isEmpty)
                    const _EmptyState(
                      title: 'Aucun usage',
                      description:
                          'Cette cinématique n’est référencée par aucune scène.',
                    )
                  else
                    for (final usage in entry.usages) ...[
                      _UsageTile(
                        usage: usage,
                        onOpen: widget.onOpenSceneUsage == null
                            ? null
                            : () => widget.onOpenSceneUsage!(
                                  sceneId: usage.sceneId,
                                  nodeId: usage.nodeId,
                                ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 12),
                  _SectionTitle(
                    title: 'Problèmes',
                    subtitle: entry.diagnostics.isEmpty
                        ? 'Aucun problème'
                        : '${entry.diagnostics.length} diagnostic(s)',
                  ),
                  const SizedBox(height: 10),
                  if (entry.diagnostics.isEmpty)
                    const PokeMapBadge(
                      label: 'Aucun problème',
                      variant: PokeMapBadgeVariant.success,
                    )
                  else
                    for (final diagnostic in entry.diagnostics) ...[
                      _DiagnosticTile(diagnostic: diagnostic),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
            ),
    );
  }

  Widget _buildCanonicalActions(
    CinematicsLibraryEntry entry,
    String deleteLabel,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        PokeMapButton(
          key: const ValueKey('cinematics-library-open-builder-button'),
          onPressed: () {
            setState(() {
              _builderEntryId = entry.id;
              _pendingDeleteId = null;
              _feedback = null;
            });
            widget.onBuilderEntryChanged?.call(entry.id);
          },
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.slider_horizontal_3),
          child: const Text('Ouvrir le Builder'),
        ),
        PokeMapButton(
          key: const ValueKey('cinematics-library-duplicate-button'),
          onPressed: () => _duplicateCinematic(entry),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.doc_on_doc),
          child: const Text('Dupliquer'),
        ),
        PokeMapButton(
          key: const ValueKey('cinematics-library-archive-button'),
          onPressed: () => _toggleArchive(entry),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: Icon(
            entry.isArchived
                ? CupertinoIcons.arrow_up_bin
                : CupertinoIcons.archivebox,
          ),
          child: Text(entry.isArchived ? 'Restaurer' : 'Archiver'),
        ),
        PokeMapButton(
          key: const ValueKey('cinematics-library-save-button'),
          onPressed: () => _saveMetadata(entry),
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.check_mark_circled),
          child: const Text('Sauvegarder les métadonnées'),
        ),
        PokeMapButton(
          key: const ValueKey('cinematics-library-delete-button'),
          onPressed: () => _removeCinematic(entry),
          variant: PokeMapButtonVariant.danger,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.trash),
          child: Text(deleteLabel),
        ),
      ],
    );
  }

  List<CinematicsLibraryEntry> _filteredEntries(
    CinematicsLibraryReadModel readModel,
  ) {
    return readModel.queryEntries(
      CinematicsLibraryQuery(
        searchText: _searchText,
        visibility: _visibility,
        sort: _sort,
        kind: switch (_filter) {
          _CinematicsLibraryFilter.all => null,
          _CinematicsLibraryFilter.canonical =>
            CinematicsLibraryEntryKind.canonical,
        },
      ),
    );
  }

  void _ensureSelection(CinematicsLibraryReadModel readModel) {
    final current = _selectedEntryId;
    if (current != null && readModel.entryById(current) != null) {
      return;
    }
    final fallback = readModel.canonicalEntries.firstOrNull;
    _selectedEntryId = fallback?.id;
    _loadedEditorId = null;
  }

  void _applyRequestedEntry() {
    final requested = widget.requestedEntryId?.trim();
    if (requested == null || requested.isEmpty) {
      _requestedEntryUnavailable = false;
      _builderEntryId = null;
      return;
    }
    final entry = buildCinematicsLibraryReadModel(
      widget.project,
    ).entryById(requested);
    if (entry == null) {
      _requestedEntryUnavailable = true;
      _selectedEntryId = null;
      _loadedEditorId = null;
      _builderEntryId = null;
      return;
    }
    _requestedEntryUnavailable = false;
    _selectedEntryId = requested;
    _loadedEditorId = null;
    if (widget.openRequestedEntryInBuilder &&
        entry.kind == CinematicsLibraryEntryKind.canonical) {
      _builderEntryId = requested;
    } else {
      _builderEntryId = null;
    }
  }

  void _syncMetadataEditor(CinematicsLibraryEntry? entry) {
    if (entry == null ||
        entry.kind != CinematicsLibraryEntryKind.canonical ||
        _loadedEditorId == entry.id) {
      return;
    }
    _loadedEditorId = entry.id;
    _titleController.text = entry.title;
    _descriptionController.text = entry.description ?? '';
    _notesController.text = entry.notes ?? '';
    _tagsController.text = entry.tags.join(', ');
  }

  Future<void> _createCinematic() async {
    final title = _createTitleController.text.trim();
    if (title.isEmpty) {
      setState(() => _feedback = 'Titre requis.');
      return;
    }
    final selectedTemplate = _templateCatalog.cinematicTemplates
        .where((template) => template.id == _createTemplateId)
        .firstOrNull;
    final createdId = await widget.onCreateCinematicShell(
      title: title,
      templateKind: selectedTemplate?.kind,
    );
    if (!mounted) {
      return;
    }
    if (createdId == null) {
      setState(
        () => _feedback =
            'Création non enregistrée. Consultez le diagnostic du projet.',
      );
      return;
    }
    setState(() {
      _selectedEntryId = createdId;
      _loadedEditorId = null;
      _createTitleController.clear();
      _pendingDeleteId = null;
      _feedback = 'Cinématique créée.';
    });
  }

  Future<void> _saveMetadata(
    CinematicsLibraryEntry entry, {
    String? mapId,
    String? storylineId,
    String? chapterId,
  }) async {
    final saved = await widget.onUpdateCinematicMetadata(
      cinematicId: entry.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
      mapId: mapId == null ? entry.mapId : _optionalId(mapId),
      storylineId:
          storylineId == null ? entry.storylineId : _optionalId(storylineId),
      chapterId: chapterId == null ? entry.chapterId : _optionalId(chapterId),
      tags: _parseTags(_tagsController.text),
      archived: entry.isArchived,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedEditorId = null;
      _feedback = saved
          ? 'Métadonnées sauvegardées.'
          : 'Modification non enregistrée. Consultez le diagnostic du projet.';
    });
  }

  Future<void> _duplicateCinematic(CinematicsLibraryEntry entry) async {
    final createdId = await widget.onDuplicateCinematic(cinematicId: entry.id);
    if (!mounted) return;
    setState(() {
      _selectedEntryId = createdId ?? entry.id;
      _loadedEditorId = null;
      _feedback = createdId == null
          ? 'Duplication impossible.'
          : 'Cinématique dupliquée.';
    });
  }

  Future<void> _toggleArchive(CinematicsLibraryEntry entry) async {
    final saved = await widget.onToggleCinematicArchive(
      cinematicId: entry.id,
      archived: !entry.isArchived,
    );
    if (!mounted) return;
    setState(() {
      _loadedEditorId = null;
      _feedback = saved
          ? (entry.isArchived
              ? 'Cinématique restaurée.'
              : 'Cinématique archivée.')
          : 'Changement d’archive impossible.';
    });
  }

  Future<void> _applyBulkTags() async {
    final saved = await widget.onBulkTagCinematics(
      cinematicIds: Set<String>.from(_bulkSelection),
      tags: _parseTags(_bulkTagsController.text),
    );
    if (!mounted) return;
    setState(() {
      _loadedEditorId = null;
      _feedback =
          saved ? 'Tags appliqués à la sélection.' : 'Tags non appliqués.';
      if (saved) _bulkSelection.clear();
    });
  }

  Future<void> _archiveBulk(bool archived) async {
    final allSaved = await widget.onBulkArchiveCinematics(
      cinematicIds: Set<String>.from(_bulkSelection),
      archived: archived,
    );
    if (!mounted) return;
    setState(() {
      _loadedEditorId = null;
      _feedback = allSaved
          ? (archived ? 'Sélection archivée.' : 'Sélection restaurée.')
          : 'Une partie de la sélection n’a pas été modifiée.';
      if (allSaved) _bulkSelection.clear();
    });
  }

  Future<void> _removeCinematic(CinematicsLibraryEntry entry) async {
    if (_pendingDeleteId != entry.id) {
      setState(() {
        _pendingDeleteId = entry.id;
        _feedback = 'Confirmez la suppression.';
      });
      return;
    }
    final removed = await widget.onRemoveCinematic(cinematicId: entry.id);
    if (!mounted) {
      return;
    }
    setState(() {
      if (removed) {
        _selectedEntryId = null;
        _loadedEditorId = null;
        _pendingDeleteId = null;
        _feedback = 'Cinématique supprimée.';
      } else {
        _feedback =
            'Suppression non enregistrée. Consultez le diagnostic du projet.';
      }
    });
  }
}

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.readModel});

  final CinematicsLibraryReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PokeMapMetricCard(
            title: 'Canoniques',
            value: '${readModel.metrics.canonicalCount}',
            icon: CupertinoIcons.film,
            tone: PokeMapTone.cinematic,
            subtitle: 'CinematicAsset',
          ),
        ),
        Expanded(
          child: PokeMapMetricCard(
            title: 'Problèmes',
            value: '${readModel.metrics.diagnosticCount}',
            icon: CupertinoIcons.exclamationmark_triangle,
            tone: readModel.metrics.diagnosticCount == 0
                ? PokeMapTone.success
                : PokeMapTone.warning,
            subtitle: 'Library V0',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PokeMapMetricCard(
            title: 'Référencées',
            value: '${readModel.metrics.referencedCount}',
            icon: CupertinoIcons.link,
            tone: PokeMapTone.info,
            subtitle: 'depuis Scenes',
          ),
        ),
      ],
    );
  }
}

class _CompactMetricsStrip extends StatelessWidget {
  const _CompactMetricsStrip({required this.readModel});

  final CinematicsLibraryReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('cinematics-library-compact-metrics'),
      spacing: 6,
      runSpacing: 6,
      children: [
        PokeMapBadge(
          label: '${readModel.metrics.canonicalCount} canoniques',
          variant: PokeMapBadgeVariant.info,
        ),
        PokeMapBadge(
          label: '${readModel.metrics.referencedCount} référencées',
          variant: PokeMapBadgeVariant.success,
        ),
        PokeMapBadge(
          label: '${readModel.metrics.diagnosticCount} problèmes',
          variant: readModel.metrics.diagnosticCount == 0
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.warning,
        ),
      ],
    );
  }
}

class _CreateCinematicPanel extends StatelessWidget {
  const _CreateCinematicPanel({
    required this.controller,
    required this.templateId,
    required this.templates,
    required this.onTemplateChanged,
    required this.onCreate,
  });

  final TextEditingController controller;
  final String templateId;
  final List<NarrativeTemplateDefinition> templates;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Créer une cinématique',
            subtitle: 'Vide ou depuis un gabarit versionné',
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: const ValueKey('cinematics-library-create-template'),
            label: 'Gabarit',
            value: templateId,
            items: [
              const PokeMapDropdownItem(
                value: 'cinematic.empty',
                label: 'Cinématique vide',
              ),
              for (final template in templates)
                PokeMapDropdownItem(value: template.id, label: template.label),
            ],
            onChanged: onTemplateChanged,
          ),
          const SizedBox(height: 8),
          CupertinoTextField(
            key: const ValueKey('cinematics-library-create-title-field'),
            controller: controller,
            placeholder: 'Titre',
            onSubmitted: (_) => onCreate(),
          ),
          const SizedBox(height: 8),
          PokeMapButton(
            key: const ValueKey('cinematics-library-create-button'),
            onPressed: onCreate,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.plus),
            child: const Text('Créer une cinématique'),
          ),
        ],
      ),
    );
  }
}

class _CinematicEntryCard extends StatelessWidget {
  const _CinematicEntryCard({
    super.key,
    required this.entry,
    required this.selected,
    required this.bulkSelected,
    required this.onTap,
    this.onToggleBulk,
  });

  final CinematicsLibraryEntry entry;
  final bool selected;
  final bool bulkSelected;
  final VoidCallback onTap;
  final VoidCallback? onToggleBulk;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _CinematicGeneratedThumbnail(entry: entry),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (onToggleBulk != null)
                PokeMapIconButton(
                  key: ValueKey('cinematic-bulk-select-${entry.id}'),
                  tooltip: bulkSelected
                      ? 'Retirer de la sélection'
                      : 'Ajouter à la sélection',
                  onPressed: onToggleBulk,
                  variant: PokeMapIconButtonVariant.soft,
                  isSelected: bulkSelected,
                  icon: Icon(
                    bulkSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    size: 15,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Canonique • ${_durationLabel(entry.timeline)} • '
            '${_usageLabel(entry.usages.length)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (entry.isArchived) ...[
            const SizedBox(height: 6),
            const PokeMapBadge(
              label: 'Archivée',
              variant: PokeMapBadgeVariant.neutral,
            ),
          ],
        ],
      ),
    );
  }
}

class _CinematicGeneratedThumbnail extends StatelessWidget {
  const _CinematicGeneratedThumbnail({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = PokeMapTone.cinematic.resolve(context);
    return Semantics(
      label: 'Aperçu généré de ${entry.title}',
      image: true,
      child: Container(
        key: ValueKey('cinematic-thumbnail-${entry.id}'),
        width: 46,
        height: 34,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: tone.soft,
          border: Border.all(color: tone.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: entry.timeline.stepCount == 0
            ? Icon(CupertinoIcons.film, size: 15, color: tone.icon)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0;
                      index < entry.timeline.stepCount.clamp(1, 5);
                      index++) ...[
                    Expanded(
                      child: Container(
                        height: 8.0 + (index % 3) * 5,
                        decoration: BoxDecoration(
                          color: index.isEven ? tone.icon : colors.brandPrimary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    if (index < entry.timeline.stepCount.clamp(1, 5) - 1)
                      const SizedBox(width: 2),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CinematicTreeHeader extends StatelessWidget {
  const _CinematicTreeHeader({required this.group});

  final CinematicsLibraryGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: Text(
        '${group.storylineLabel}  /  ${group.chapterLabel}  /  ${group.locationLabel}',
        key: ValueKey(
          'cinematic-tree-${group.storylineLabel}-${group.chapterLabel}-${group.locationLabel}',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CinematicBulkBar extends StatelessWidget {
  const _CinematicBulkBar({
    required this.selectedCount,
    required this.tagsController,
    required this.onApplyTags,
    required this.onArchive,
    required this.onRestore,
    required this.onClear,
  });

  final int selectedCount;
  final TextEditingController tagsController;
  final VoidCallback onApplyTags;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$selectedCount sélectionnée(s)'),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const ValueKey('cinematics-library-bulk-tags'),
            controller: tagsController,
            placeholder: 'tags, communs',
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              PokeMapButton(
                key: const ValueKey('cinematics-library-bulk-apply-tags'),
                onPressed: onApplyTags,
                size: PokeMapButtonSize.small,
                child: const Text('Appliquer tags'),
              ),
              PokeMapIconButton(
                key: const ValueKey('cinematics-library-bulk-archive'),
                tooltip: 'Archiver la sélection',
                onPressed: onArchive,
                icon: const Icon(CupertinoIcons.archivebox, size: 14),
              ),
              PokeMapIconButton(
                key: const ValueKey('cinematics-library-bulk-restore'),
                tooltip: 'Restaurer la sélection',
                onPressed: onRestore,
                icon: const Icon(CupertinoIcons.arrow_up_bin, size: 14),
              ),
              PokeMapIconButton(
                key: const ValueKey('cinematics-library-bulk-clear'),
                tooltip: 'Vider la sélection',
                onPressed: onClear,
                icon: const Icon(CupertinoIcons.xmark, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetadataSummary extends StatelessWidget {
  const _MetadataSummary({
    required this.entry,
    required this.maps,
    required this.characters,
    required this.asset,
    this.mapWidth,
    this.mapHeight,
  });

  final CinematicsLibraryEntry entry;
  final List<ProjectMapEntry> maps;
  final List<ProjectCharacterEntry> characters;
  final CinematicAsset? asset;
  final int? mapWidth;
  final int? mapHeight;

  @override
  Widget build(BuildContext context) {
    final stageDiagnostics = _stageDiagnosticsFor(entry);
    final readiness = asset == null
        ? null
        : buildCinematicStagePreviewReadiness(
            asset: asset!,
            entry: entry,
            maps: maps,
            characters: characters,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
          );
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'Métadonnées', subtitle: 'Lecture auteur'),
          const SizedBox(height: 8),
          _KeyValue(label: 'Statut', value: entry.statusLabel),
          _KeyValue(label: 'Map stage', value: _stageMapLabel(entry, maps)),
          if (readiness != null)
            _KeyValue(label: 'Preview', value: readiness.libraryStatusLabel),
          _KeyValue(
            label: 'Storyline',
            value: entry.storylineId ?? 'Aucune storyline',
          ),
          _KeyValue(
            label: 'Chapitre',
            value: entry.chapterId ?? 'Aucun chapitre',
          ),
          _KeyValue(
            label: 'Acteurs requis',
            value: entry.requiredActors.isEmpty
                ? 'Aucun acteur requis'
                : entry.requiredActors
                    .map((actor) => actor.displayLabel)
                    .join(', '),
          ),
          if (entry.requiredActors.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final actor in entry.requiredActors)
                  PokeMapBadge(
                    label: actor.actorId,
                    variant: PokeMapBadgeVariant.narrative,
                  ),
              ],
            ),
          if (stageDiagnostics.isNotEmpty) ...[
            const SizedBox(height: 8),
            PokeMapBadge(
              label: stageDiagnostics.length == 1
                  ? '1 diagnostic stage'
                  : '${stageDiagnostics.length} diagnostics stage',
              variant: PokeMapBadgeVariant.warning,
            ),
          ],
        ],
      ),
    );
  }
}

String _stageMapLabel(
  CinematicsLibraryEntry entry,
  List<ProjectMapEntry> maps,
) {
  final mapId = entry.mapId;
  if (mapId == null || mapId.trim().isEmpty) {
    return 'Aucune map';
  }
  for (final map in maps) {
    if (map.id == mapId) {
      return map.name.trim().isEmpty ? map.id : map.name;
    }
  }
  return mapId;
}

List<CinematicsLibraryDiagnosticView> _stageDiagnosticsFor(
  CinematicsLibraryEntry entry,
) {
  return entry.diagnostics
      .where((diagnostic) => _stageDiagnosticCodes.contains(diagnostic.code))
      .toList(growable: false);
}

const _stageDiagnosticCodes = <String>{
  'stageMapUnknown',
  'stageBackdropRequiresMap',
  'actorBindingUnknownActor',
  'actorBindingMissing',
  'actorBindingDuplicatePlayer',
  'actorBindingRequiresStageMap',
  'actorBindingMapEntityMissingSource',
  'actorAppearanceBindingUnknownActor',
  'actorAppearanceBindingUnknownCharacter',
  'actorAppearanceBindingRequiresCinematicOnly',
  'cinematicOnlyCharacterMissing',
  'characterLibraryUnavailable',
  'characterAssetMissingSprite',
  'characterAssetMissingPreviewData',
  'actorInitialPlacementUnknownActor',
  'actorInitialPlacementMissing',
  'actorInitialPlacementTargetUnknown',
  'actorInitialPlacementRequiresBinding',
  'movementTargetBindingUnknownTarget',
  'movementTargetBindingRequiresStageMap',
  'movementTargetBindingMissingSource',
};

typedef _CinematicClassificationChanged = void Function(
    {String? mapId, String? storylineId, String? chapterId});

class _CinematicClassificationPickers extends StatelessWidget {
  const _CinematicClassificationPickers({
    required this.project,
    required this.entry,
    required this.onChanged,
  });

  final ProjectManifest project;
  final CinematicsLibraryEntry entry;
  final _CinematicClassificationChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedStoryline = project.storylines
        .where((storyline) => storyline.id == entry.storylineId)
        .firstOrNull;
    final chapterIds = {
      for (final chapter
          in selectedStoryline?.chapters ?? const <StorylineChapter>[])
        chapter.id,
    };
    final chapterValue =
        chapterIds.contains(entry.chapterId) ? entry.chapterId! : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapDropdownField<String>(
          key: const ValueKey('cinematics-library-map-picker'),
          label: 'Lieu / map',
          value: entry.mapId ?? '',
          items: [
            const PokeMapDropdownItem(value: '', label: 'Sans lieu'),
            for (final map in project.maps)
              PokeMapDropdownItem(value: map.id, label: map.name),
          ],
          onChanged: (value) => onChanged(mapId: value),
        ),
        const SizedBox(height: 8),
        PokeMapDropdownField<String>(
          key: const ValueKey('cinematics-library-storyline-picker'),
          label: 'Storyline',
          value: entry.storylineId ?? '',
          items: [
            const PokeMapDropdownItem(value: '', label: 'Sans storyline'),
            for (final storyline in project.storylines)
              PokeMapDropdownItem(value: storyline.id, label: storyline.title),
          ],
          onChanged: (value) => onChanged(storylineId: value, chapterId: ''),
        ),
        const SizedBox(height: 8),
        PokeMapDropdownField<String>(
          key: const ValueKey('cinematics-library-chapter-picker'),
          label: 'Chapitre',
          value: chapterValue,
          enabled: selectedStoryline != null,
          items: [
            const PokeMapDropdownItem(value: '', label: 'Sans chapitre'),
            for (final chapter
                in selectedStoryline?.chapters ?? const <StorylineChapter>[])
              PokeMapDropdownItem(value: chapter.id, label: chapter.title),
          ],
          onChanged: (value) => onChanged(chapterId: value),
        ),
      ],
    );
  }
}

class _TimelineSummaryPanel extends StatelessWidget {
  const _TimelineSummaryPanel({required this.timeline});

  final CinematicTimelineSummary timeline;

  @override
  Widget build(BuildContext context) {
    if (timeline.isEmpty) {
      return const PokeMapCard(
        child: _EmptyState(
          title: 'Timeline vide',
          description:
              'Timeline vide — elle sera remplie dans le futur Cinematic Builder V2.',
        ),
      );
    }
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(title: 'Résumé timeline', subtitle: 'Déroulé'),
          const SizedBox(height: 8),
          _KeyValue(label: 'Actions', value: '${timeline.stepCount} action(s)'),
          _KeyValue(
            label: 'Durée',
            value: timeline.estimatedDurationMs == null
                ? 'Non calculable'
                : '${timeline.estimatedDurationMs} ms estimé(s)',
          ),
          _KeyValue(label: 'Types', value: timeline.stepKindLabels.join(', ')),
          _KeyValue(
            label: 'Acteurs utilisés',
            value: timeline.actorIds.isEmpty
                ? 'Aucun acteur dans les actions'
                : timeline.actorIds.join(', '),
          ),
          if (timeline.previewLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final label in timeline.previewLabels)
                  PokeMapBadge(label: label, variant: PokeMapBadgeVariant.info),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({required this.usage, this.onOpen});

  final CinematicsLibraryUsage usage;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: ValueKey('cinematic-usage-${usage.sceneId}-${usage.nodeId}'),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KeyValue(label: 'Scene', value: usage.sceneTitle),
          _KeyValue(label: 'Node', value: usage.nodeTitle),
          if (usage.outcomeLabels.isNotEmpty)
            _KeyValue(label: 'Sorties', value: usage.outcomeLabels.join(', ')),
          PokeMapBadge(
            label: switch (usage.referenceStatus) {
              CinematicsLibraryReferenceStatus.canonical =>
                'Référence canonique',
              CinematicsLibraryReferenceStatus.unknown => 'Référence inconnue',
            },
            variant: switch (usage.referenceStatus) {
              CinematicsLibraryReferenceStatus.canonical =>
                PokeMapBadgeVariant.success,
              CinematicsLibraryReferenceStatus.unknown =>
                PokeMapBadgeVariant.error,
            },
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 6),
            const _BodyText('Cliquer pour ouvrir la Scene et le nœud.'),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticTile extends StatelessWidget {
  const _DiagnosticTile({required this.diagnostic});

  final CinematicsLibraryDiagnosticView diagnostic;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapBadge(
            label: switch (diagnostic.severity) {
              CinematicsLibraryDiagnosticSeverity.error => 'Erreur',
              CinematicsLibraryDiagnosticSeverity.warning => 'Warning',
              CinematicsLibraryDiagnosticSeverity.info => 'Info',
            },
            variant: switch (diagnostic.severity) {
              CinematicsLibraryDiagnosticSeverity.error =>
                PokeMapBadgeVariant.error,
              CinematicsLibraryDiagnosticSeverity.warning =>
                PokeMapBadgeVariant.warning,
              CinematicsLibraryDiagnosticSeverity.info =>
                PokeMapBadgeVariant.info,
            },
          ),
          const SizedBox(height: 6),
          _KeyValue(label: 'Code', value: diagnostic.code),
          _BodyText(diagnostic.message),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PokeMapIconTile(
          icon: CupertinoIcons.film,
          tone: PokeMapTone.cinematic,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        style: DefaultTextStyle.of(context).style.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              textAlign: TextAlign.center,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _usageLabel(int count) {
  if (count == 0) {
    return '0 scène';
  }
  if (count == 1) {
    return '1 scène';
  }
  return '$count scènes';
}

String _durationLabel(CinematicTimelineSummary timeline) {
  final duration = timeline.estimatedDurationMs;
  if (duration == null) return '${timeline.stepCount} action(s)';
  if (duration < 1000) return '$duration ms';
  final seconds = duration / 1000;
  return '${seconds.toStringAsFixed(seconds == seconds.roundToDouble() ? 0 : 1)} s';
}

List<String> _parseTags(String value) {
  final seen = <String>{};
  return [
    for (final raw in value.split(','))
      if (raw.trim().isNotEmpty && seen.add(raw.trim())) raw.trim(),
  ];
}

String? _optionalId(String value) {
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}

Set<String>? _availableTilesetIds(ProjectManifest project) {
  final ids = project.tilesets
      .map((tileset) => tileset.id.trim())
      .where((tilesetId) => tilesetId.isNotEmpty)
      .toSet();
  if (ids.isEmpty) {
    return null;
  }
  return ids;
}

ProjectMapEntry? _stageMapForId(List<ProjectMapEntry> maps, String mapId) {
  for (final map in maps) {
    if (map.id == mapId) {
      return map;
    }
  }
  return null;
}
