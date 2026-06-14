import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';
import '../../../theme/theme.dart';
import 'cinematic_actor_sprite_preview_plan.dart';
import 'cinematic_actor_sprite_preview_resolver.dart';
import 'cinematic_builder_workspace.dart';
import 'cinematic_map_backdrop_layer_plan_loader.dart';
import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_tile_plan_loader.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_stage_preview_readiness.dart';

typedef CreateCinematicShellCallback = Future<String?> Function({
  required String title,
});

typedef UpdateCinematicMetadataCallback = Future<bool> Function({
  required String cinematicId,
  required String title,
  required String description,
  required String notes,
});

typedef RemoveCinematicCallback = Future<bool> Function({
  required String cinematicId,
});

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
});

typedef AddRequiredActorCallback = Future<String?> Function({
  required String cinematicId,
  String? label,
});

typedef RenameRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
  required String label,
});

typedef RemoveRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});

typedef AddMovementTargetCallback = Future<String?> Function({
  required String cinematicId,
});

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

typedef RemoveTimelineAuthoringStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef UpdateStageMapCallback = Future<bool> Function({
  required String cinematicId,
  String? mapId,
});

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

enum _CinematicsLibraryFilter {
  all,
  canonical,
  bridge,
}

class CinematicsLibraryWorkspace extends StatefulWidget {
  const CinematicsLibraryWorkspace({
    super.key,
    required this.project,
    required this.onCreateCinematicShell,
    required this.onUpdateCinematicMetadata,
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
    this.onOpenLegacyCutsceneStudio,
    this.startExpanded = false,
  });

  final bool startExpanded;

  final ProjectManifest project;
  final CreateCinematicShellCallback onCreateCinematicShell;
  final UpdateCinematicMetadataCallback onUpdateCinematicMetadata;
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
  final VoidCallback? onOpenLegacyCutsceneStudio;

  @override
  State<CinematicsLibraryWorkspace> createState() =>
      _CinematicsLibraryWorkspaceState();
}

class _CinematicsLibraryWorkspaceState
    extends State<CinematicsLibraryWorkspace> {
  final _createTitleController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _backdropLayerPlanLoader = CinematicMapBackdropLayerPlanLoader();

  _CinematicsLibraryFilter _filter = _CinematicsLibraryFilter.all;
  String? _selectedEntryId;
  String? _builderEntryId;
  String? _loadedEditorId;
  String? _pendingDeleteId;
  String? _feedback;
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

  @override
  void dispose() {
    _createTitleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _backdropLayerPlanLoader.clear();
    _loadingActorTilesetIds.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readModel = buildCinematicsLibraryReadModel(widget.project);
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

    return Material(
      type: MaterialType.transparency,
      child: PokeMapPageSurface(
        key: const ValueKey('cinematics-library-workspace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
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
                    child: _buildUsageAndDiagnostics(context, selectedEntry),
                  ),
                ],
              ),
            ),
          ],
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
          final actorDisplayPreviewModel =
              _buildActorDisplayPreviewModel(asset);
          if (actorDisplayPreviewModel != null) {
            final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
              actorDisplayModel: actorDisplayPreviewModel,
              project: widget.project,
            );
            for (final actor in actorSpritePreviewPlan.actors) {
              final tilesetId = actor.spriteRef?.tilesetId;
              if (tilesetId != null && tilesetId.isNotEmpty) {
                if (!_backdropLayerRenderPlan!.tilesets
                    .containsKey(tilesetId)) {
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
      ProjectManifest manifest, String tilesetId) {
    for (final tileset in manifest.tilesets) {
      if (tileset.id.trim() == tilesetId) {
        return tileset;
      }
    }
    return null;
  }

  void _ensureActorTilesets(CinematicAsset asset) {
    final resolver = widget.onResolveBackdropTilesetPath;
    if (resolver == null) {
      return;
    }

    final requiredTilesetIds = <String>{};

    // 1. Scan actor appearance bindings
    final bindings = asset.stageContext?.actorAppearanceBindings ?? const [];
    for (final binding in bindings) {
      final characterId = binding.characterId.trim();
      if (characterId.isNotEmpty) {
        for (final character in widget.project.characters) {
          if (character.id.trim() == characterId) {
            final tilesetId = character.tilesetId.trim();
            if (tilesetId.isNotEmpty) {
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
          if (tilesetId.isNotEmpty) {
            requiredTilesetIds.add(tilesetId);
          }
          break;
        }
      }
    }

    final missingTilesetIds = requiredTilesetIds.where((id) {
      return !_resolvedActorTilesets.containsKey(id) &&
          !_loadingActorTilesetIds.contains(id);
    }).toList();

    if (missingTilesetIds.isEmpty) {
      return;
    }

    _loadingActorTilesetIds.addAll(missingTilesetIds);

    unawaited(() async {
      final newResolved = Map<String, CinematicResolvedTilesetAsset>.from(
          _resolvedActorTilesets);
      bool changed = false;
      for (final id in missingTilesetIds) {
        try {
          final tileset = _tilesetById(widget.project, id);
          final path = resolver(id);
          final asset = await _backdropLayerPlanLoader.registry.resolve(
            tileset: tileset,
            absolutePath: path,
            tileWidth: widget.project.settings.tileWidth,
            tileHeight: widget.project.settings.tileHeight,
          );
          newResolved[id] = asset;
          changed = true;
        } catch (_) {
          // Ignore error and continue
        } finally {
          _loadingActorTilesetIds.remove(id);
        }
      }

      if (changed && mounted) {
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
      _resolvedActorTilesets = const {};
      _loadingActorTilesetIds.clear();
    });
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
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
                'Cinématiques',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Séquences visuelles linéaires jouées depuis les Scènes.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        PokeMapButton(
          key: const ValueKey('cinematics-library-open-legacy-button'),
          onPressed: widget.onOpenLegacyCutsceneStudio,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.archivebox),
          child: const Text('Ouvrir l’ancien Cutscene Studio'),
        ),
      ],
    );
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
        PokeMapButton(
          onPressed: () =>
              setState(() => _filter = _CinematicsLibraryFilter.bridge),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          isSelected: _filter == _CinematicsLibraryFilter.bridge,
          child: const Text('Bridge legacy'),
        ),
        const PokeMapBadge(
          label: 'Bridge non canonique',
          variant: PokeMapBadgeVariant.warning,
        ),
      ],
    );
  }

  Widget _buildExplorer(
    BuildContext context,
    CinematicsLibraryReadModel readModel,
  ) {
    final entries = _filteredEntries(readModel);
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
            title: 'Bibliothèque',
            subtitle: '${readModel.metrics.canonicalCount} canonique(s) • '
                '${readModel.metrics.bridgeCount} bridge(s)',
          ),
          const SizedBox(height: 10),
          _CreateCinematicPanel(
            controller: _createTitleController,
            onCreate: _createCinematic,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: entries.isEmpty
                ? const _EmptyState(
                    title: 'Aucune cinématique canonique',
                    description:
                        'Créez une shell vide, puis remplissez sa timeline dans le futur Builder V2.',
                  )
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _CinematicEntryCard(
                        key: ValueKey('cinematic-entry-${entry.id}'),
                        entry: entry,
                        selected: _selectedEntryId == entry.id,
                        onTap: () {
                          setState(() {
                            _selectedEntryId = entry.id;
                            _pendingDeleteId = null;
                            _feedback = null;
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    CinematicsLibraryEntry? entry,
  ) {
    if (entry == null) {
      return const PokeMapPanel(
        expandChild: true,
        child: _EmptyState(
          title: 'Aucune cinématique sélectionnée',
          description:
              'Sélectionnez une entrée canonique ou bridge pour inspecter son état.',
        ),
      );
    }
    if (entry.kind == CinematicsLibraryEntryKind.scenarioBridge) {
      return _BridgeDetailsPanel(entry: entry);
    }
    return _buildCanonicalDetails(context, entry);
  }

  Widget _buildCanonicalDetails(
    BuildContext context,
    CinematicsLibraryEntry entry,
  ) {
    final asset = findCinematicById(widget.project, entry.id);
    final deleteEnabled = entry.isRemovable;
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PokeMapButton(
                  key: const ValueKey(
                    'cinematics-library-open-builder-button',
                  ),
                  onPressed: () {
                    setState(() {
                      _builderEntryId = entry.id;
                      _pendingDeleteId = null;
                      _feedback = null;
                    });
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.slider_horizontal_3),
                  child: const Text('Ouvrir le Builder'),
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
                  onPressed:
                      deleteEnabled ? () => _removeCinematic(entry) : null,
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.trash),
                  child: Text(deleteLabel),
                ),
              ],
            ),
            if (!deleteEnabled) ...[
              const SizedBox(height: 8),
              const PokeMapBadge(
                label: 'Utilisée par une scène',
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
                      _UsageTile(usage: usage),
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

  List<CinematicsLibraryEntry> _filteredEntries(
    CinematicsLibraryReadModel readModel,
  ) {
    return switch (_filter) {
      _CinematicsLibraryFilter.all => readModel.allEntries,
      _CinematicsLibraryFilter.canonical => readModel.canonicalEntries,
      _CinematicsLibraryFilter.bridge => readModel.bridgeEntries,
    };
  }

  void _ensureSelection(CinematicsLibraryReadModel readModel) {
    final current = _selectedEntryId;
    if (current != null && readModel.entryById(current) != null) {
      return;
    }
    final fallback = readModel.canonicalEntries.isNotEmpty
        ? readModel.canonicalEntries.first
        : readModel.bridgeEntries.isNotEmpty
            ? readModel.bridgeEntries.first
            : null;
    _selectedEntryId = fallback?.id;
    _loadedEditorId = null;
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
  }

  Future<void> _createCinematic() async {
    final title = _createTitleController.text.trim();
    if (title.isEmpty) {
      setState(() => _feedback = 'Titre requis.');
      return;
    }
    final createdId = await widget.onCreateCinematicShell(title: title);
    if (!mounted) {
      return;
    }
    if (createdId == null) {
      setState(() => _feedback = 'Création refusée.');
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

  Future<void> _saveMetadata(CinematicsLibraryEntry entry) async {
    final saved = await widget.onUpdateCinematicMetadata(
      cinematicId: entry.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      notes: _notesController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loadedEditorId = null;
      _feedback = saved ? 'Métadonnées sauvegardées.' : 'Sauvegarde refusée.';
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
        _feedback = 'Suppression refusée.';
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
        const SizedBox(width: 8),
        Expanded(
          child: PokeMapMetricCard(
            title: 'Bridges legacy',
            value: '${readModel.metrics.bridgeCount}',
            icon: CupertinoIcons.archivebox,
            tone: PokeMapTone.warning,
            subtitle: 'Scenario/Cutscene',
          ),
        ),
        const SizedBox(width: 8),
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

class _CreateCinematicPanel extends StatelessWidget {
  const _CreateCinematicPanel({
    required this.controller,
    required this.onCreate,
  });

  final TextEditingController controller;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Créer une cinématique',
            subtitle: 'Shell metadata-only',
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
    required this.onTap,
  });

  final CinematicsLibraryEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isBridge = entry.kind == CinematicsLibraryEntryKind.scenarioBridge;
    return PokeMapCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              PokeMapIconTile(
                icon:
                    isBridge ? CupertinoIcons.archivebox : CupertinoIcons.film,
                tone: isBridge ? PokeMapTone.warning : PokeMapTone.cinematic,
                size: 30,
                iconSize: 15,
              ),
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
            '${isBridge ? 'Bridge legacy' : 'Canonique'} • '
            '${entry.timeline.stepCount} step(s) • '
            '${_usageLabel(entry.usages.length)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BridgeDetailsPanel extends StatelessWidget {
  const _BridgeDetailsPanel({required this.entry});

  final CinematicsLibraryEntry entry;

  @override
  Widget build(BuildContext context) {
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
                label: 'Bridge legacy',
                variant: PokeMapBadgeVariant.warning,
              ),
            ),
            const SizedBox(height: 12),
            _KeyValue(label: 'Statut', value: entry.statusLabel),
            const SizedBox(height: 8),
            const _EmptyState(
              title: 'Bridge legacy — pas un CinematicAsset canonique',
              description:
                  'Les bridges legacy viennent de l’ancien Cutscene Studio / ScenarioAsset. Ils restent lisibles, mais ne sont pas des CinematicAsset canoniques.',
            ),
            const SizedBox(height: 12),
            const PokeMapBadge(
              label: 'Migration future',
              variant: PokeMapBadgeVariant.neutral,
            ),
            const SizedBox(height: 10),
            const PokeMapButton(
              key:
                  ValueKey('cinematics-library-legacy-builder-disabled-button'),
              onPressed: null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: Icon(CupertinoIcons.lock_fill),
              child: Text('Builder canonique indisponible'),
            ),
          ],
        ),
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
          const _SectionTitle(
            title: 'Métadonnées',
            subtitle: 'Lecture auteur',
          ),
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
          const _SectionTitle(
            title: 'Résumé timeline',
            subtitle: 'Déroulé',
          ),
          const SizedBox(height: 8),
          _KeyValue(label: 'Actions', value: '${timeline.stepCount} action(s)'),
          _KeyValue(
            label: 'Durée',
            value: timeline.estimatedDurationMs == null
                ? 'Non calculable'
                : '${timeline.estimatedDurationMs} ms estimé(s)',
          ),
          _KeyValue(
            label: 'Types',
            value: timeline.stepKindLabels.join(', '),
          ),
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
                  PokeMapBadge(
                    label: label,
                    variant: PokeMapBadgeVariant.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({required this.usage});

  final CinematicsLibraryUsage usage;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KeyValue(label: 'Scene', value: usage.sceneTitle),
          _KeyValue(label: 'Node', value: usage.nodeTitle),
          PokeMapBadge(
            label: switch (usage.referenceStatus) {
              CinematicsLibraryReferenceStatus.canonical =>
                'Référence canonique',
              CinematicsLibraryReferenceStatus.bridgeLegacy =>
                'Référence bridge',
              CinematicsLibraryReferenceStatus.unknown => 'Référence inconnue',
            },
            variant: switch (usage.referenceStatus) {
              CinematicsLibraryReferenceStatus.canonical =>
                PokeMapBadgeVariant.success,
              CinematicsLibraryReferenceStatus.bridgeLegacy =>
                PokeMapBadgeVariant.warning,
              CinematicsLibraryReferenceStatus.unknown =>
                PokeMapBadgeVariant.error,
            },
          ),
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
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
  const _KeyValue({
    required this.label,
    required this.value,
  });

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
  const _EmptyState({
    required this.title,
    required this.description,
  });

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
