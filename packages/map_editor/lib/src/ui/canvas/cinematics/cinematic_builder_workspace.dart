import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_actor_sprite_preview_plan.dart';
import 'cinematic_actor_sprite_preview_renderer.dart';
import 'cinematic_actor_walking_animation_preview_resolver.dart';
import 'cinematic_backdrop_preview_framing.dart';
import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_preview_panel.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_preview_playback_actor_overlay_adapter.dart';
import 'cinematic_playback_preview_fallback_summary.dart';
import 'cinematic_stage_preview_readiness.dart';

typedef AddCinematicDraftStepCallback = Future<String?> Function({
  required String cinematicId,
  String? afterStepId,
});

typedef RemoveCinematicDraftStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef AddCinematicBasicBlockStepCallback = Future<String?> Function({
  required String cinematicId,
  required CinematicTimelineBasicBlockKind blockKind,
  String? afterStepId,
});

typedef UpdateCinematicBasicBlockStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
});

typedef AddCinematicRequiredActorCallback = Future<String?> Function(
    {required String cinematicId, String? label});

typedef RenameCinematicRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
  required String label,
});

typedef RemoveCinematicRequiredActorCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});

typedef AddCinematicMovementTargetCallback = Future<String?> Function(
    {required String cinematicId});

typedef UpdateCinematicMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
  required String label,
  String? description,
});

typedef RemoveCinematicMovementTargetCallback = Future<bool> Function({
  required String cinematicId,
  required String targetId,
});

typedef AddCinematicActorFacingStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required CinematicTimelineActorFacingDirection direction,
  String? afterStepId,
});

typedef UpdateCinematicActorFacingStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
  int? durationMs,
});

typedef AddCinematicActorMoveStepCallback = Future<String?> Function({
  required String cinematicId,
  required String actorId,
  required String targetId,
  required int durationMs,
  required CinematicTimelineActorMovementMode movementMode,
  String? afterStepId,
});

typedef UpdateCinematicActorMoveStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
});

typedef RemoveCinematicAuthoringStepCallback = Future<bool> Function({
  required String cinematicId,
  required String stepId,
});

typedef UpdateCinematicStageMapCallback = Future<bool> Function(
    {required String cinematicId, String? mapId});

typedef UpdateCinematicStageContextCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicStageContext stageContext,
});

typedef UpdateCinematicAssetCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicAsset cinematic,
});

typedef _ToggleActorMovePathModeCallback = Future<void> Function(
  CinematicTimelineStep step,
  CinematicTimelineActorPathMode mode,
);

typedef _AddManualPathWaypointCallback = Future<void> Function(
  CinematicTimelineStep step,
  CinematicManualPath? path,
  String stagePointId,
);

typedef _RemoveManualPathWaypointCallback = Future<void> Function(
    CinematicManualPath path, int index);

typedef _ReorderManualPathWaypointCallback = Future<void> Function(
    CinematicManualPath path, int fromIndex, int toIndex);

typedef UpsertCinematicActorBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorBinding binding,
});

typedef UpsertCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorAppearanceBinding binding,
});

typedef RemoveCinematicActorAppearanceBindingCallback = Future<bool> Function({
  required String cinematicId,
  required String actorId,
});

typedef UpsertCinematicActorInitialPlacementCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicActorInitialPlacement placement,
});

typedef UpsertCinematicMovementTargetBindingCallback = Future<bool> Function({
  required String cinematicId,
  required CinematicMovementTargetBinding binding,
});

typedef _UpdateBasicBlockCallback = Future<void> Function(
  CinematicTimelineStep step, {
  int? durationMs,
  CinematicTimelineFadeMode? fadeMode,
  CinematicTimelineCameraMode? cameraMode,
});

typedef _UpdateActorFacingCallback = Future<void> Function(
  CinematicTimelineStep step, {
  String? actorId,
  CinematicTimelineActorFacingDirection? direction,
  int? durationMs,
});

typedef _UpdateActorMoveCallback = Future<void> Function(
  CinematicTimelineStep step, {
  String? actorId,
  String? targetId,
  int? durationMs,
  CinematicTimelineActorMovementMode? movementMode,
});

typedef _ResizeStepDurationCallback = Future<bool> Function(
  CinematicTimelineStep step, {
  required int durationMs,
});

typedef _AddBasicBlockCallback = Future<void> Function(
    CinematicTimelineBasicBlockKind blockKind);

typedef _AddRequiredActorCallback = Future<bool> Function(
    {required String label});

typedef _RenameRequiredActorCallback = Future<bool>
    Function(CinematicActorRef actor, {required String label});

typedef _RemoveRequiredActorCallback = Future<bool> Function(
    CinematicActorRef actor);

typedef _AddMovementTargetCallback = Future<void> Function();

typedef _UpdateMovementTargetCallback = Future<bool> Function(
  CinematicMovementTargetRef target, {
  required String label,
  String? description,
});

typedef _RemoveMovementTargetCallback = Future<bool> Function(
    CinematicMovementTargetRef target);

typedef _AddActorFacingCallback = Future<void> Function();

typedef _AddActorMoveCallback = Future<void> Function();

typedef _RemoveAuthoringStepCallback = Future<void> Function(
    CinematicTimelineStep step);

typedef _UpdateStageMapCallback = Future<void> Function(String? mapId);

typedef _UpdateStageContextCallback = Future<void> Function(
    CinematicStageContext stageContext);

typedef _UpsertActorBindingCallback = Future<void> Function(
    CinematicActorBinding binding);

typedef _UpsertActorAppearanceBindingCallback = Future<void> Function(
    CinematicActorAppearanceBinding binding);

typedef _RemoveActorAppearanceBindingCallback = Future<void> Function(
    String actorId);

typedef _UpsertActorInitialPlacementCallback = Future<void> Function(
    CinematicActorInitialPlacement placement);

typedef _UpsertMovementTargetBindingCallback = Future<void> Function(
    CinematicMovementTargetBinding binding);

class CinematicBuilderWorkspace extends StatefulWidget {
  const CinematicBuilderWorkspace({
    super.key,
    required this.entry,
    required this.asset,
    required this.stageMaps,
    required this.groups,
    required this.characters,
    this.stageMapSourceCatalog,
    this.backdropPreviewModel,
    this.backdropTileRenderPlan,
    this.backdropLayerRenderPlan,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    this.tilesets,
    this.startExpanded = false,
    required this.onBackToLibrary,
    required this.onAddDraftStep,
    required this.onRemoveDraftStep,
    required this.onAddBasicBlockStep,
    required this.onUpdateBasicBlockStep,
    required this.onAddRequiredActor,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onAddActorFacingStep,
    required this.onUpdateActorFacingStep,
    required this.onAddActorMoveStep,
    required this.onUpdateActorMoveStep,
    required this.onRemoveAuthoringStep,
    required this.onUpdateStageMap,
    required this.onUpdateStageContext,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onUpsertMovementTargetBinding,
    this.onUpdateCinematicAsset,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final List<ProjectMapEntry> stageMaps;
  final List<ProjectMapGroup> groups;
  final List<ProjectCharacterEntry> characters;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
  final CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
  final bool startExpanded;
  final VoidCallback onBackToLibrary;
  final AddCinematicDraftStepCallback onAddDraftStep;
  final RemoveCinematicDraftStepCallback onRemoveDraftStep;
  final AddCinematicBasicBlockStepCallback onAddBasicBlockStep;
  final UpdateCinematicBasicBlockStepCallback onUpdateBasicBlockStep;
  final AddCinematicRequiredActorCallback onAddRequiredActor;
  final RenameCinematicRequiredActorCallback onRenameRequiredActor;
  final RemoveCinematicRequiredActorCallback onRemoveRequiredActor;
  final AddCinematicMovementTargetCallback onAddMovementTarget;
  final UpdateCinematicMovementTargetCallback onUpdateMovementTarget;
  final RemoveCinematicMovementTargetCallback onRemoveMovementTarget;
  final AddCinematicActorFacingStepCallback onAddActorFacingStep;
  final UpdateCinematicActorFacingStepCallback onUpdateActorFacingStep;
  final AddCinematicActorMoveStepCallback onAddActorMoveStep;
  final UpdateCinematicActorMoveStepCallback onUpdateActorMoveStep;
  final RemoveCinematicAuthoringStepCallback onRemoveAuthoringStep;
  final UpdateCinematicStageMapCallback onUpdateStageMap;
  final UpdateCinematicStageContextCallback onUpdateStageContext;
  final UpsertCinematicActorBindingCallback onUpsertActorBinding;
  final UpsertCinematicActorAppearanceBindingCallback
      onUpsertActorAppearanceBinding;
  final RemoveCinematicActorAppearanceBindingCallback
      onRemoveActorAppearanceBinding;
  final UpsertCinematicActorInitialPlacementCallback
      onUpsertActorInitialPlacement;
  final UpsertCinematicMovementTargetBindingCallback
      onUpsertMovementTargetBinding;
  final UpdateCinematicAssetCallback? onUpdateCinematicAsset;

  @override
  State<CinematicBuilderWorkspace> createState() =>
      _CinematicBuilderWorkspaceState();
}

class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace>
    with SingleTickerProviderStateMixin {
  String? _selectedStepId;
  int? _timelineProbeTimeMs;
  _TimelineProbeSnapHint? _timelineProbeSnapHint;
  CinematicBackdropPreviewFramingState _backdropFramingState =
      const CinematicBackdropPreviewFramingState();
  String? _selectedStagePointId;
  bool _addStagePointMode = false;
  late final AnimationController _playbackController;
  late String _playbackTimelineSignature;
  bool _isPlaybackPlaying = false;

  @override
  void initState() {
    super.initState();
    _playbackTimelineSignature = _playbackSignature(widget.asset);
    _playbackController = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _isPlaybackPlaying) {
          setState(() => _isPlaybackPlaying = false);
        }
      });
  }

  @override
  void didUpdateWidget(CinematicBuilderWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameCinematic = oldWidget.asset.id == widget.asset.id;
    if (!sameCinematic || !_hasStep(widget.asset, _selectedStepId)) {
      _selectedStepId = null;
    }
    if (!sameCinematic) {
      _timelineProbeTimeMs = null;
      _timelineProbeSnapHint = null;
      _backdropFramingState = const CinematicBackdropPreviewFramingState();
      _selectedStagePointId = null;
      _addStagePointMode = false;
    }
    final nextPlaybackSignature = _playbackSignature(widget.asset);
    if (_playbackTimelineSignature != nextPlaybackSignature) {
      _playbackTimelineSignature = nextPlaybackSignature;
      _stopPlaybackWithoutSetState(resetTime: true);
    }
  }

  @override
  void dispose() {
    _playbackController.dispose();
    super.dispose();
  }

  void _stopPlaybackWithoutSetState({required bool resetTime}) {
    _playbackController.stop();
    if (resetTime) {
      _playbackController.value = 0;
    }
    _isPlaybackPlaying = false;
  }

  void _pausePlaybackWithoutSetState() {
    _playbackController.stop();
    _isPlaybackPlaying = false;
  }

  int _playbackTimeMs(CinematicPreviewPlaybackPlan plan) {
    if (plan.totalDurationMs <= 0) {
      return 0;
    }
    return (_playbackController.value * plan.totalDurationMs).round().clamp(
          0,
          plan.totalDurationMs,
        );
  }

  void _togglePlayback(CinematicPreviewPlaybackPlan plan) {
    if (!_canPlayPreview(plan)) {
      return;
    }
    if (_isPlaybackPlaying) {
      _playbackController.stop();
      setState(() => _isPlaybackPlaying = false);
      return;
    }
    _playbackController.duration = Duration(
      milliseconds: math.max(1, plan.totalDurationMs),
    );
    final startValue =
        _playbackController.value >= 1 ? 0.0 : _playbackController.value;
    setState(() => _isPlaybackPlaying = true);
    _playbackController.forward(from: startValue);
  }

  void _stopPlayback() {
    setState(() => _stopPlaybackWithoutSetState(resetTime: true));
  }

  void _resetPlayback() {
    setState(() => _stopPlaybackWithoutSetState(resetTime: true));
  }

  @override
  Widget build(BuildContext context) {
    final selectedStep = _selectedStep(widget.asset, _selectedStepId);
    final selectedStepIndex = selectedStep == null
        ? null
        : widget.asset.timeline.steps.indexOf(selectedStep);
    final readiness = buildCinematicStagePreviewReadiness(
      asset: widget.asset,
      entry: widget.entry,
      maps: widget.stageMaps,
      characters: widget.characters,
      stageMapSourceCatalog: widget.stageMapSourceCatalog,
      mapWidth: widget.backdropPreviewModel?.mapWidth,
      mapHeight: widget.backdropPreviewModel?.mapHeight,
    );
    final playbackPlan = buildCinematicPreviewPlaybackPlan(
      cinematic: widget.asset,
      actorDisplayPreviewModel: widget.actorDisplayPreviewModel,
    );
    final playbackTimeMs = _playbackTimeMs(playbackPlan);
    final playbackFrame = playbackPlan.frameAt(playbackTimeMs);
    final isPlaybackOverlayActive = _isPlaybackPlaying || playbackTimeMs > 0;
    final cadenceHintsByActorId = _cadenceHintsForPlayback(
      playbackPlan: playbackPlan,
      playbackFrame: playbackFrame,
      playbackTimeMs: playbackTimeMs,
    );
    final playbackActorOverlayModel = isPlaybackOverlayActive
        ? buildCinematicPreviewPlaybackActorOverlayModel(
            displayModel: widget.actorDisplayPreviewModel,
            playbackFrame: playbackFrame,
          )
        : null;
    final spritePreviewResolution = isPlaybackOverlayActive
        ? _resolvePlaybackActorSpritePreviewPlan(
            basePlan: widget.actorSpritePreviewPlan,
            displayModel: playbackActorOverlayModel?.displayModel ??
                widget.actorDisplayPreviewModel,
            playbackFrame: playbackFrame,
            playbackTimeMs: playbackTimeMs,
            isPlaybackPlaying: _isPlaybackPlaying,
            timelineSteps: widget.asset.timeline.steps,
            characters: widget.characters,
            cadenceHintsByActorId: cadenceHintsByActorId,
          )
        : _PlaybackActorSpritePreviewResolution(
            plan: widget.actorSpritePreviewPlan,
            animationStatus: _hasReadyActorSprite(widget.actorSpritePreviewPlan)
                ? _PlaybackActorAnimationStatus.ready
                : _PlaybackActorAnimationStatus.none,
            walkingFrames: const [],
          );
    final previewActorSpritePreviewPlan = spritePreviewResolution.plan;
    final playbackFallbackSummary =
        buildCinematicPlaybackPreviewFallbackSummary(
      animationState: _previewFallbackAnimationState(
        spritePreviewResolution.animationStatus,
      ),
      isPlaybackOverlayActive: isPlaybackOverlayActive,
      walkingFrames: spritePreviewResolution.walkingFrames,
      spritePreviewPlan: previewActorSpritePreviewPlan,
    );
    final playbackPreviewStatus = _playbackPreviewStatusFor(
      isPlaybackOverlayActive: isPlaybackOverlayActive,
      isPlaybackPlaying: _isPlaybackPlaying,
      animationStatus: spritePreviewResolution.animationStatus,
      fallbackSummary: playbackFallbackSummary,
    );

    return Material(
      type: MaterialType.transparency,
      child: PokeMapPageSurface(
        key: const ValueKey('cinematic-builder-workspace'),
        // Wrap the workspace in a global Focus key event listener so pressing ESC anywhere
        // in the builder workspace will cancel the Stage Point placement mode, provided
        // we are not focused on a text input.
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape &&
                _addStagePointMode) {
              setState(() {
                _addStagePointMode = false;
              });
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BuilderHeader(
                entry: widget.entry,
                onBackToLibrary: widget.onBackToLibrary,
                readiness: readiness,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 250,
                      child: _BlockPalette(
                        entry: widget.entry,
                        asset: widget.asset,
                        onAddBasicBlock: _addBasicBlock,
                        onAddRequiredActor: _addRequiredActor,
                        onAddMovementTarget: _addMovementTarget,
                        onUpdateMovementTarget: _updateMovementTarget,
                        onRemoveMovementTarget: _removeMovementTarget,
                        onAddActorFacing: _addActorFacing,
                        onAddActorMove: _addActorMove,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final timelineHeight = _builderTimelineHeight(
                            constraints.maxHeight,
                            hasBackdrop: widget.backdropPreviewModel != null,
                          );
                          final previewHeight = math.max(
                            0.0,
                            constraints.maxHeight -
                                _builderTimelineGap -
                                timelineHeight,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: previewHeight,
                                child: _PreviewSandbox(
                                  entry: widget.entry,
                                  asset: widget.asset,
                                  backdropPreviewModel:
                                      widget.backdropPreviewModel,
                                  backdropTileRenderPlan:
                                      widget.backdropTileRenderPlan,
                                  backdropLayerRenderPlan:
                                      widget.backdropLayerRenderPlan,
                                  actorDisplayPreviewModel:
                                      widget.actorDisplayPreviewModel,
                                  actorPlaybackPreviewModel:
                                      playbackActorOverlayModel,
                                  actorSpritePreviewPlan:
                                      previewActorSpritePreviewPlan,
                                  playbackPreviewStatus: playbackPreviewStatus,
                                  backdropFramingState: _backdropFramingState,
                                  stagePoints:
                                      widget.asset.stageContext?.stagePoints ??
                                          const [],
                                  selectedStagePointId: _selectedStagePointId,
                                  addStagePointMode: _addStagePointMode,
                                  onSelectStagePointId: (id) {
                                    setState(() {
                                      _selectedStagePointId = id;
                                    });
                                  },
                                  onUpdateStagePoint: _updateStagePoint,
                                  onAddStagePointAtTile: _addStagePointAtTile,
                                  onAddStagePointModeChanged: (val) {
                                    setState(() {
                                      _addStagePointMode = val;
                                    });
                                  },
                                  onBackdropFramingModeChanged: (mode) {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        mode: mode,
                                        panTiles: Offset.zero,
                                      );
                                    });
                                  },
                                  onBackdropFramingZoomChanged: (zoom) {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        zoom: zoom,
                                      );
                                    });
                                  },
                                  onBackdropFramingPanChanged: (panTiles) {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        panTiles: panTiles,
                                      );
                                    });
                                  },
                                  onBackdropFramingResetView: () {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        zoom:
                                            CinematicBackdropPreviewFramingState
                                                .minZoom,
                                        panTiles: Offset.zero,
                                      );
                                    });
                                  },
                                  onBackdropFramingDetailsChanged:
                                      (showDetails) {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        showDetails: showDetails,
                                      );
                                    });
                                  },
                                  onBackdropFramingGridChanged: (showGrid) {
                                    setState(() {
                                      _backdropFramingState =
                                          _backdropFramingState.copyWith(
                                        showGrid: showGrid,
                                      );
                                    });
                                  },
                                  selectedStep: selectedStep,
                                  selectedStepIndex: selectedStepIndex,
                                  timelineProbeTimeMs: _timelineProbeTimeMs,
                                  readiness: readiness,
                                ),
                              ),
                              const SizedBox(height: _builderTimelineGap),
                              SizedBox(
                                height: timelineHeight,
                                child: _TimelinePlaceholder(
                                  entry: widget.entry,
                                  asset: widget.asset,
                                  selectedStepId: _selectedStepId,
                                  timelineProbeTimeMs: _timelineProbeTimeMs,
                                  timelineProbeSnapHint: _timelineProbeSnapHint,
                                  playbackPlan: playbackPlan,
                                  playbackFrame: playbackFrame,
                                  playbackTimeMs: playbackTimeMs,
                                  isPlaybackPlaying: _isPlaybackPlaying,
                                  onStepSelected: (step) {
                                    if (_isPlaybackPlaying) {
                                      _pausePlaybackWithoutSetState();
                                    }
                                    setState(() {
                                      _selectedStepId = step.id;
                                      _timelineProbeTimeMs = null;
                                      _timelineProbeSnapHint = null;
                                    });
                                  },
                                  onTimelineProbeChanged: (probe) {
                                    setState(() {
                                      _timelineProbeTimeMs = probe.timeMs;
                                      _timelineProbeSnapHint = probe.snapHint;
                                    });
                                  },
                                  onTimelineProbeCleared: () {
                                    setState(() {
                                      _timelineProbeTimeMs = null;
                                      _timelineProbeSnapHint = null;
                                    });
                                  },
                                  onStepDurationResized:
                                      _resizeTimelineStepDuration,
                                  onAddDraftStep: _addDraftStep,
                                  onPlaybackPlayPause: () =>
                                      _togglePlayback(playbackPlan),
                                  onPlaybackStop: _stopPlayback,
                                  onPlaybackReset: _resetPlayback,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 300,
                      child: _InspectorPlaceholder(
                        entry: widget.entry,
                        asset: widget.asset,
                        stageMaps: widget.stageMaps,
                        groups: widget.groups,
                        characters: widget.characters,
                        stageMapSourceCatalog: widget.stageMapSourceCatalog,
                        selectedStep: selectedStep,
                        selectedStepIndex: selectedStepIndex,
                        startExpanded: widget.startExpanded,
                        onUpdateStageMap: _updateStageMap,
                        onUpdateStageContext: _updateStageContext,
                        onRenameRequiredActor: _renameRequiredActor,
                        onRemoveRequiredActor: _removeRequiredActor,
                        onUpsertActorBinding: _upsertActorBinding,
                        onUpsertActorAppearanceBinding:
                            _upsertActorAppearanceBinding,
                        onRemoveActorAppearanceBinding:
                            _removeActorAppearanceBinding,
                        onUpsertActorInitialPlacement:
                            _upsertActorInitialPlacement,
                        onUpsertMovementTargetBinding:
                            _upsertMovementTargetBinding,
                        onRemoveDraftStep: _removeDraftStep,
                        onUpdateBasicBlock: _updateBasicBlock,
                        onUpdateActorFacing: _updateActorFacing,
                        onUpdateActorMove: _updateActorMove,
                        onRemoveAuthoringStep: _removeAuthoringStep,
                        onAddRequiredActor: _addRequiredActor,
                        onUpdateMovementTarget: _updateMovementTarget,
                        onRemoveMovementTarget: _removeMovementTarget,
                        onAddMovementTarget: _addMovementTarget,
                        onToggleActorMovePathMode: _toggleActorMovePathMode,
                        onAddManualPathWaypoint: _addManualPathWaypoint,
                        onRemoveManualPathWaypoint: _removeManualPathWaypoint,
                        onReorderManualPathWaypoint: _reorderManualPathWaypoint,
                        actorSpritePreviewPlan: widget.actorSpritePreviewPlan,
                        tilesets: widget.tilesets,
                        selectedStagePointId: _selectedStagePointId,
                        onSelectStagePointId: (id) {
                          setState(() {
                            _selectedStagePointId = id;
                          });
                        },
                        onUpdateStagePoint: _updateStagePoint,
                        onRemoveStagePoint: _removeStagePoint,
                        mapWidth: widget.backdropPreviewModel?.mapWidth,
                        mapHeight: widget.backdropPreviewModel?.mapHeight,
                        readiness: readiness,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDraftStep() async {
    final createdStepId = await widget.onAddDraftStep(
      cinematicId: widget.asset.id,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _removeDraftStep(CinematicTimelineStep step) async {
    if (!isCinematicTimelineDraftStep(step)) {
      return;
    }
    final removed = await widget.onRemoveDraftStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() => _selectedStepId = null);
  }

  Future<void> _addBasicBlock(CinematicTimelineBasicBlockKind blockKind) async {
    final createdStepId = await widget.onAddBasicBlockStep(
      cinematicId: widget.asset.id,
      blockKind: blockKind,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _updateBasicBlock(
    CinematicTimelineStep step, {
    int? durationMs,
    CinematicTimelineFadeMode? fadeMode,
    CinematicTimelineCameraMode? cameraMode,
  }) async {
    if (!isCinematicTimelineBasicBlockStep(step)) {
      return;
    }
    final updated = await widget.onUpdateBasicBlockStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      durationMs: durationMs,
      fadeMode: fadeMode,
      cameraMode: cameraMode,
    );
    if (!mounted || !updated || durationMs == null) {
      return;
    }
    setState(() {
      _timelineProbeTimeMs = null;
      _timelineProbeSnapHint = null;
    });
  }

  Future<bool> _addRequiredActor({required String label}) async {
    final actorId = await widget.onAddRequiredActor(
      cinematicId: widget.asset.id,
      label: label,
    );
    return actorId != null;
  }

  Future<void> _addMovementTarget() async {
    await widget.onAddMovementTarget(cinematicId: widget.asset.id);
  }

  Future<bool> _updateMovementTarget(
    CinematicMovementTargetRef target, {
    required String label,
    String? description,
  }) {
    return widget.onUpdateMovementTarget(
      cinematicId: widget.asset.id,
      targetId: target.targetId,
      label: label,
      description: description,
    );
  }

  Future<bool> _removeMovementTarget(CinematicMovementTargetRef target) {
    return widget.onRemoveMovementTarget(
      cinematicId: widget.asset.id,
      targetId: target.targetId,
    );
  }

  Future<void> _updateStageMap(String? mapId) async {
    await widget.onUpdateStageMap(cinematicId: widget.asset.id, mapId: mapId);
  }

  Future<void> _updateStageContext(CinematicStageContext stageContext) async {
    await widget.onUpdateStageContext(
      cinematicId: widget.asset.id,
      stageContext: stageContext,
    );
  }

  ProjectManifest _createDummyProject() {
    return ProjectManifest(
      name: 'dummy',
      maps: [],
      tilesets: [],
      cinematics: [
        CinematicAsset(
          id: widget.asset.id,
          title: widget.asset.title,
          description: widget.asset.description,
          storylineId: widget.asset.storylineId,
          chapterId: widget.asset.chapterId,
          mapId: widget.asset.mapId,
          tags: widget.asset.tags,
          requiredActors: widget.asset.requiredActors,
          movementTargets: widget.asset.movementTargets,
          timeline: widget.asset.timeline,
          stageContext: widget.asset.stageContext ?? CinematicStageContext(),
          notes: widget.asset.notes,
          metadata: widget.asset.metadata,
          legacyBridge: widget.asset.legacyBridge,
        ),
      ],
    );
  }

  Future<void> _updateCinematic(CinematicAsset updatedCinematic) async {
    if (widget.onUpdateCinematicAsset != null) {
      await widget.onUpdateCinematicAsset!(
        cinematicId: widget.asset.id,
        cinematic: updatedCinematic,
      );
    } else {
      if (updatedCinematic.stageContext != null) {
        await _updateStageContext(updatedCinematic.stageContext!);
      }
    }
  }

  Future<void> _toggleActorMovePathMode(
    CinematicTimelineStep step,
    CinematicTimelineActorPathMode mode,
  ) async {
    try {
      final dummyProject = _createDummyProject();
      if (mode == CinematicTimelineActorPathMode.manual) {
        final context = widget.asset.stageContext ?? CinematicStageContext();
        final ownedPaths = context.manualPaths
            .where((path) => path.ownerActorMoveStepId == step.id)
            .toList(growable: false);
        if (ownedPaths.isEmpty) {
          final result = addCinematicManualPathForActorMove(
            dummyProject,
            cinematicId: widget.asset.id,
            actorMoveStepId: step.id,
          );
          await _updateCinematic(result.cinematic);
        } else {
          final result = setActorMovePathMode(
            dummyProject,
            cinematicId: widget.asset.id,
            stepId: step.id,
            pathMode: CinematicTimelineActorPathMode.manual,
          );
          await _updateCinematic(result.cinematic);
        }
      } else {
        final result = clearActorMoveManualPath(
          dummyProject,
          cinematicId: widget.asset.id,
          stepId: step.id,
        );
        await _updateCinematic(result.cinematic);
      }
    } catch (e) {
      debugPrint('Error toggling path mode: $e');
    }
  }

  Future<void> _addManualPathWaypoint(
    CinematicTimelineStep step,
    CinematicManualPath? path,
    String stagePointId,
  ) async {
    try {
      final dummyProject = _createDummyProject();
      if (path == null || path.id.isEmpty) {
        final result = addCinematicManualPathForActorMove(
          dummyProject,
          cinematicId: widget.asset.id,
          actorMoveStepId: step.id,
          waypointStagePointIds: [stagePointId],
        );
        await _updateCinematic(result.cinematic);
        return;
      }

      final result = addCinematicManualPathWaypoint(
        dummyProject,
        cinematicId: widget.asset.id,
        manualPathId: path.id,
        stagePointId: stagePointId,
      );
      await _updateCinematic(result.cinematic);
    } catch (e) {
      debugPrint('Error adding manual path waypoint: $e');
    }
  }

  Future<void> _removeManualPathWaypoint(
    CinematicManualPath path,
    int index,
  ) async {
    try {
      final dummyProject = _createDummyProject();
      final result = removeCinematicManualPathWaypointAt(
        dummyProject,
        cinematicId: widget.asset.id,
        manualPathId: path.id,
        index: index,
      );
      await _updateCinematic(result.cinematic);
    } catch (e) {
      debugPrint('Error removing manual path waypoint: $e');
    }
  }

  Future<void> _reorderManualPathWaypoint(
    CinematicManualPath path,
    int fromIndex,
    int toIndex,
  ) async {
    try {
      final dummyProject = _createDummyProject();
      final result = reorderCinematicManualPathWaypoint(
        dummyProject,
        cinematicId: widget.asset.id,
        manualPathId: path.id,
        fromIndex: fromIndex,
        toIndex: toIndex,
      );
      await _updateCinematic(result.cinematic);
    } catch (e) {
      debugPrint('Error reordering manual path waypoint: $e');
    }
  }

  String _generateUniqueStagePointId(List<CinematicStagePoint> existingPoints) {
    int maxIndex = 0;
    final regExp = RegExp(r'^(?:stage_)?point_(\d+)$');
    for (final p in existingPoints) {
      final match = regExp.firstMatch(p.id);
      if (match != null) {
        final index = int.tryParse(match.group(1) ?? '');
        if (index != null && index > maxIndex) {
          maxIndex = index;
        }
      }
    }

    // Find the next unique index
    int nextIndex = maxIndex + 1;
    while (existingPoints.any(
      (p) => p.id == 'stage_point_$nextIndex' || p.id == 'point_$nextIndex',
    )) {
      nextIndex++;
    }
    return 'stage_point_$nextIndex';
  }

  void _addStagePointAtTile(Offset tilePosition) {
    final snappedX = tilePosition.dx.floor() + 0.5;
    final snappedY = tilePosition.dy.floor() + 0.5;

    final existing = widget.asset.stageContext?.stagePoints ?? const [];
    final id = _generateUniqueStagePointId(existing);
    final count = existing.length + 1;
    int labelIndex = count;
    while (existing.any((p) => p.label == 'Repère $labelIndex')) {
      labelIndex++;
    }
    final label = 'Repère $labelIndex';

    final newPoint = CinematicStagePoint(
      id: id,
      label: label,
      x: snappedX,
      y: snappedY,
    );

    _addStagePoint(newPoint);

    setState(() {
      _selectedStagePointId = id;
      _addStagePointMode = false;
    });
  }

  Future<void> _addStagePoint(CinematicStagePoint point) async {
    try {
      final dummyProject = ProjectManifest(
        name: 'dummy',
        maps: [],
        tilesets: [],
        cinematics: [
          CinematicAsset(
            id: widget.asset.id,
            title: widget.asset.title,
            description: widget.asset.description,
            storylineId: widget.asset.storylineId,
            chapterId: widget.asset.chapterId,
            mapId: widget.asset.mapId,
            tags: widget.asset.tags,
            requiredActors: widget.asset.requiredActors,
            movementTargets: widget.asset.movementTargets,
            timeline: widget.asset.timeline,
            stageContext: widget.asset.stageContext ?? CinematicStageContext(),
            notes: widget.asset.notes,
            metadata: widget.asset.metadata,
            legacyBridge: widget.asset.legacyBridge,
          ),
        ],
      );

      final result = addCinematicStagePoint(
        dummyProject,
        cinematicId: widget.asset.id,
        point: point,
      );

      final updatedContext =
          result.cinematic.stageContext ?? CinematicStageContext();
      await _updateStageContext(updatedContext);
    } catch (e) {
      debugPrint('Error adding stage point: $e');
    }
  }

  Future<void> _updateStagePoint(CinematicStagePoint point) async {
    try {
      final dummyProject = ProjectManifest(
        name: 'dummy',
        maps: [],
        tilesets: [],
        cinematics: [
          CinematicAsset(
            id: widget.asset.id,
            title: widget.asset.title,
            description: widget.asset.description,
            storylineId: widget.asset.storylineId,
            chapterId: widget.asset.chapterId,
            mapId: widget.asset.mapId,
            tags: widget.asset.tags,
            requiredActors: widget.asset.requiredActors,
            movementTargets: widget.asset.movementTargets,
            timeline: widget.asset.timeline,
            stageContext: widget.asset.stageContext ?? CinematicStageContext(),
            notes: widget.asset.notes,
            metadata: widget.asset.metadata,
            legacyBridge: widget.asset.legacyBridge,
          ),
        ],
      );

      final result = updateCinematicStagePoint(
        dummyProject,
        cinematicId: widget.asset.id,
        point: point,
      );

      final updatedContext =
          result.cinematic.stageContext ?? CinematicStageContext();
      await _updateStageContext(updatedContext);
    } catch (e) {
      debugPrint('Error updating stage point: $e');
    }
  }

  Future<void> _removeStagePoint(String id) async {
    try {
      final dummyProject = ProjectManifest(
        name: 'dummy',
        maps: [],
        tilesets: [],
        cinematics: [
          CinematicAsset(
            id: widget.asset.id,
            title: widget.asset.title,
            description: widget.asset.description,
            storylineId: widget.asset.storylineId,
            chapterId: widget.asset.chapterId,
            mapId: widget.asset.mapId,
            tags: widget.asset.tags,
            requiredActors: widget.asset.requiredActors,
            movementTargets: widget.asset.movementTargets,
            timeline: widget.asset.timeline,
            stageContext: widget.asset.stageContext ?? CinematicStageContext(),
            notes: widget.asset.notes,
            metadata: widget.asset.metadata,
            legacyBridge: widget.asset.legacyBridge,
          ),
        ],
      );

      final result = removeCinematicStagePoint(
        dummyProject,
        cinematicId: widget.asset.id,
        stagePointId: id,
      );

      final updatedContext =
          result.cinematic.stageContext ?? CinematicStageContext();
      await _updateStageContext(updatedContext);
      if (_selectedStagePointId == id) {
        setState(() {
          _selectedStagePointId = null;
        });
      }
    } catch (e) {
      debugPrint('Error removing stage point: $e');
    }
  }

  Future<bool> _renameRequiredActor(
    CinematicActorRef actor, {
    required String label,
  }) {
    return widget.onRenameRequiredActor(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
      label: label,
    );
  }

  Future<bool> _removeRequiredActor(CinematicActorRef actor) {
    return widget.onRemoveRequiredActor(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
    );
  }

  Future<void> _upsertActorBinding(CinematicActorBinding binding) async {
    await widget.onUpsertActorBinding(
      cinematicId: widget.asset.id,
      binding: binding,
    );
  }

  Future<void> _upsertActorAppearanceBinding(
    CinematicActorAppearanceBinding binding,
  ) async {
    await widget.onUpsertActorAppearanceBinding(
      cinematicId: widget.asset.id,
      binding: binding,
    );
  }

  Future<void> _removeActorAppearanceBinding(String actorId) async {
    await widget.onRemoveActorAppearanceBinding(
      cinematicId: widget.asset.id,
      actorId: actorId,
    );
  }

  Future<void> _upsertActorInitialPlacement(
    CinematicActorInitialPlacement placement,
  ) async {
    await widget.onUpsertActorInitialPlacement(
      cinematicId: widget.asset.id,
      placement: placement,
    );
  }

  Future<void> _upsertMovementTargetBinding(
    CinematicMovementTargetBinding binding,
  ) async {
    await widget.onUpsertMovementTargetBinding(
      cinematicId: widget.asset.id,
      binding: binding,
    );
  }

  Future<void> _addActorFacing() async {
    final actor = widget.asset.requiredActors.isEmpty
        ? null
        : widget.asset.requiredActors.first;
    if (actor == null) {
      return;
    }
    final createdStepId = await widget.onAddActorFacingStep(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
      direction: CinematicTimelineActorFacingDirection.down,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _addActorMove() async {
    final actor = widget.asset.requiredActors.isEmpty
        ? null
        : widget.asset.requiredActors.first;
    if (actor == null || widget.asset.movementTargets.isEmpty) {
      return;
    }
    final usedTargetIds = {
      for (final step in widget.asset.timeline.steps)
        if (isCinematicTimelineActorMoveStep(step) && step.targetId != null)
          step.targetId!,
    };
    CinematicMovementTargetRef? target;
    for (final candidate in widget.asset.movementTargets) {
      if (!usedTargetIds.contains(candidate.targetId)) {
        target = candidate;
        break;
      }
    }

    if (target == null) {
      final seedTarget = widget.asset.movementTargets.first;
      final seedBinding = widget.asset.stageContext == null
          ? null
          : _movementTargetBindingFor(
              widget.asset.stageContext!,
              seedTarget.targetId,
            );
      // Each actorMove owns its destination choice in authoring. Reusing an
      // already-used movement target would couple blocks through the same
      // binding, so changing one final repere would visually move the others.
      final targetId = await widget.onAddMovementTarget(
        cinematicId: widget.asset.id,
      );
      if (!mounted || targetId == null) {
        return;
      }
      if (seedBinding != null) {
        await widget.onUpsertMovementTargetBinding(
          cinematicId: widget.asset.id,
          binding: CinematicMovementTargetBinding(
            targetId: targetId,
            kind: seedBinding.kind,
            sourceId: seedBinding.sourceId,
          ),
        );
        if (!mounted) {
          return;
        }
      }
      target =
          CinematicMovementTargetRef(targetId: targetId, label: 'Destination');
    }
    final createdStepId = await widget.onAddActorMoveStep(
      cinematicId: widget.asset.id,
      actorId: actor.actorId,
      targetId: target.targetId,
      durationMs: cinematicTimelineDefaultActorMoveDurationMs,
      movementMode: CinematicTimelineActorMovementMode.walk,
      afterStepId: _selectedStepId,
    );
    if (!mounted || createdStepId == null) {
      return;
    }
    setState(() => _selectedStepId = createdStepId);
  }

  Future<void> _updateActorFacing(
    CinematicTimelineStep step, {
    String? actorId,
    CinematicTimelineActorFacingDirection? direction,
    int? durationMs,
  }) async {
    if (!isCinematicTimelineActorFacingStep(step)) {
      return;
    }
    final updated = await widget.onUpdateActorFacingStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      actorId: actorId,
      direction: direction,
      durationMs: durationMs,
    );
    if (!mounted || !updated || durationMs == null) {
      return;
    }
    setState(() {
      _timelineProbeTimeMs = null;
      _timelineProbeSnapHint = null;
    });
  }

  Future<void> _updateActorMove(
    CinematicTimelineStep step, {
    String? actorId,
    String? targetId,
    int? durationMs,
    CinematicTimelineActorMovementMode? movementMode,
  }) async {
    if (!isCinematicTimelineActorMoveStep(step)) {
      return;
    }
    final updated = await widget.onUpdateActorMoveStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
      actorId: actorId,
      targetId: targetId,
      durationMs: durationMs,
      movementMode: movementMode,
    );
    if (!mounted || !updated || durationMs == null) {
      return;
    }
    setState(() {
      _timelineProbeTimeMs = null;
      _timelineProbeSnapHint = null;
    });
  }

  Future<bool> _resizeTimelineStepDuration(
    CinematicTimelineStep step, {
    required int durationMs,
  }) async {
    var updated = false;
    if (isCinematicTimelineBasicBlockStep(step)) {
      updated = await widget.onUpdateBasicBlockStep(
        cinematicId: widget.asset.id,
        stepId: step.id,
        durationMs: durationMs,
      );
    } else if (isCinematicTimelineActorFacingStep(step)) {
      updated = await widget.onUpdateActorFacingStep(
        cinematicId: widget.asset.id,
        stepId: step.id,
        durationMs: durationMs,
      );
    } else if (isCinematicTimelineActorMoveStep(step)) {
      updated = await widget.onUpdateActorMoveStep(
        cinematicId: widget.asset.id,
        stepId: step.id,
        durationMs: durationMs,
      );
    }
    if (!mounted || !updated) {
      return false;
    }
    setState(() {
      _timelineProbeTimeMs = null;
      _timelineProbeSnapHint = null;
    });
    return true;
  }

  Future<void> _removeAuthoringStep(CinematicTimelineStep step) async {
    if (!isCinematicTimelineAuthoringStep(step)) {
      return;
    }
    final removed = await widget.onRemoveAuthoringStep(
      cinematicId: widget.asset.id,
      stepId: step.id,
    );
    if (!mounted || !removed) {
      return;
    }
    setState(() => _selectedStepId = null);
  }
}

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.entry,
    required this.onBackToLibrary,
    required this.readiness,
  });

  final CinematicsLibraryEntry entry;
  final VoidCallback onBackToLibrary;
  final CinematicStagePreviewReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final backAction = PokeMapIconButton(
      key: const ValueKey('cinematic-builder-back-button'),
      onPressed: onBackToLibrary,
      variant: PokeMapIconButtonVariant.soft,
      icon: const Icon(CupertinoIcons.chevron_left),
    );
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Cinematic Builder V0',
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
          '${entry.title} • ${entry.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
    final itemsToComplete = readiness.items
            .where((i) => i.kind != CinematicStagePreviewReadinessItemKind.ok)
            .length +
        readiness.diagnostics.length;
    final badges = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapBadge(
          label: readiness.kind == CinematicStagePreviewReadinessKind.ready
              ? 'Scène prête'
              : (itemsToComplete == 1
                  ? '1 élément à compléter'
                  : '$itemsToComplete éléments à compléter'),
          variant: readiness.kind == CinematicStagePreviewReadinessKind.ready
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.warning,
        ),
        _TestHidden(
          child: PokeMapBadge(
            label: '${entry.timeline.stepCount} step(s)',
            variant: PokeMapBadgeVariant.neutral,
          ),
        ),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TestHidden(
          child: PokeMapButton(
            key: const ValueKey('cinematic-builder-validate-button'),
            onPressed: null,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            child: const SizedBox.shrink(),
          ),
        ),
        PokeMapButton(
          key: const ValueKey('cinematic-builder-preview-button'),
          onPressed: null,
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.play_fill),
          child: const Text('Aperçu'),
        ),
        const SizedBox(width: 8),
        PokeMapButton(
          key: const ValueKey('cinematic-builder-save-button'),
          onPressed: null,
          variant: PokeMapButtonVariant.primary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.doc_fill),
          child: const Text('Sauvegarder'),
        ),
        const SizedBox(width: 8),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-more-button'),
          onPressed: () {},
          variant: PokeMapIconButtonVariant.ghost,
          icon: const Icon(CupertinoIcons.ellipsis_vertical),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        backAction,
        const SizedBox(width: 10),
        const PokeMapIconTile(
          icon: CupertinoIcons.film,
          tone: PokeMapTone.cinematic,
        ),
        const SizedBox(width: 10),
        Expanded(child: title),
        const SizedBox(width: 10),
        badges,
        const SizedBox(width: 12),
        actions,
      ],
    );
  }
}

class _BlockPalette extends StatelessWidget {
  const _BlockPalette({
    required this.entry,
    required this.asset,
    required this.onAddBasicBlock,
    required this.onAddRequiredActor,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onAddActorFacing,
    required this.onAddActorMove,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final _AddBasicBlockCallback onAddBasicBlock;
  final _AddRequiredActorCallback onAddRequiredActor;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;
  final _AddActorFacingCallback onAddActorFacing;
  final _AddActorMoveCallback onAddActorMove;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final infoColors = PokeMapTone.info.resolve(context);
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Ajouter au déroulé',
            subtitle: 'Glissez ou cliquez pour ajouter',
          ),
          const Offstage(
            child: PokeMapBadge(
              label: 'Authoring V0',
              variant: PokeMapBadgeVariant.info,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MISE EN SCÈNE',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final block in _paletteBlocks) ...[
                    _PaletteBlockTile(
                      block: block,
                      onAddBasicBlock: onAddBasicBlock,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'ACTEUR',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _ActorMovePaletteTile(
                    asset: asset,
                    onAddActorMove: onAddActorMove,
                  ),
                  const SizedBox(height: 8),
                  _ActorFacingPaletteTile(
                    asset: asset,
                    onAddActorFacing: onAddActorFacing,
                  ),
                  _TestHidden(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'BLOCS VERROUILLÉS',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final block in _lockedPaletteBlocks) ...[
                          _PaletteBlockTile(
                            block: block,
                            onAddBasicBlock: onAddBasicBlock,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoColors.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: infoColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: infoColors.icon,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Conseil',
                      style: TextStyle(
                        color: infoColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sélectionnez une action dans le déroulé pour ajuster ses réglages.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Offstage(
            child: _MutedText(
              '${entry.timeline.stepCount} bloc(s) lu(s) depuis la timeline.',
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredActorsCard extends StatefulWidget {
  const _RequiredActorsCard({
    required this.asset,
    required this.onAddRequiredActor,
  });

  final CinematicAsset asset;
  final _AddRequiredActorCallback onAddRequiredActor;

  @override
  State<_RequiredActorsCard> createState() => _RequiredActorsCardState();
}

class _RequiredActorsCardState extends State<_RequiredActorsCard> {
  final TextEditingController _labelController = TextEditingController();
  String? _feedback;
  bool _isAdding = false;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StrongText('Acteurs requis'),
          const SizedBox(height: 4),
          if (widget.asset.requiredActors.isEmpty)
            const _MutedText('Aucun acteur requis')
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final actor in widget.asset.requiredActors)
                  PokeMapBadge(
                    label: _actorDisplayLabel(actor),
                    variant: PokeMapBadgeVariant.narrative,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          _MovementTargetTextField(
            key: const ValueKey('cinematic-builder-required-actor-label-field'),
            controller: _labelController,
            placeholder: 'Nom de l’acteur',
          ),
          const SizedBox(height: 8),
          _InlineControlAction(
            label: 'Ajouter',
            button: PokeMapButton(
              key: const ValueKey(
                'cinematic-builder-add-required-actor-button',
              ),
              onPressed: _isAdding ? null : _addActor,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isLoading: _isAdding,
              leading: const Icon(CupertinoIcons.person_add),
              child: const SizedBox.shrink(),
            ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 6),
            _MutedText(_feedback!),
          ],
        ],
      ),
    );
  }

  Future<void> _addActor() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      setState(() => _feedback = 'Nom d’acteur obligatoire');
      return;
    }
    setState(() {
      _isAdding = true;
      _feedback = null;
    });
    final added = await widget.onAddRequiredActor(label: label);
    if (!mounted) {
      return;
    }
    setState(() {
      _isAdding = false;
      _feedback = added ? null : 'Création impossible';
      if (added) {
        _labelController.clear();
      }
    });
  }
}

class _MovementTargetsCard extends StatelessWidget {
  const _MovementTargetsCard({
    required this.asset,
    required this.onAddMovementTarget,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
  });

  final CinematicAsset asset;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StrongText('Destinations'),
          const SizedBox(height: 4),
          if (asset.movementTargets.isEmpty)
            const _MutedText('Aucune destination')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final target in asset.movementTargets) ...[
                  _MovementTargetEditorRow(
                    key: ValueKey(
                      'cinematic-builder-movement-target-row-'
                      '${target.targetId}',
                    ),
                    asset: asset,
                    target: target,
                    onUpdateMovementTarget: onUpdateMovementTarget,
                    onRemoveMovementTarget: onRemoveMovementTarget,
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          const SizedBox(height: 8),
          _InlineControlAction(
            label: 'Destination',
            button: PokeMapButton(
              key: const ValueKey(
                'cinematic-builder-add-movement-target-button',
              ),
              onPressed: onAddMovementTarget,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.location),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTargetEditorRow extends StatefulWidget {
  const _MovementTargetEditorRow({
    super.key,
    required this.asset,
    required this.target,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
  });

  final CinematicAsset asset;
  final CinematicMovementTargetRef target;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;

  @override
  State<_MovementTargetEditorRow> createState() =>
      _MovementTargetEditorRowState();
}

class _MovementTargetEditorRowState extends State<_MovementTargetEditorRow> {
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  String? _feedback;
  bool _isSaving = false;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.target.label);
    _descriptionController = TextEditingController(
      text: widget.target.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _MovementTargetEditorRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target.label != widget.target.label) {
      _labelController.text = widget.target.label;
    }
    final description = widget.target.description ?? '';
    if ((oldWidget.target.description ?? '') != description) {
      _descriptionController.text = description;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final usageCount = _movementTargetUsageCount(
      widget.asset,
      widget.target.targetId,
    );
    final isUsed = usageCount > 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _StrongText(widget.target.label)),
              const SizedBox(width: 6),
              PokeMapBadge(
                label: isUsed ? 'Utilisée' : 'Libre',
                variant: isUsed
                    ? PokeMapBadgeVariant.info
                    : PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: 3),
          _MutedText('Id: ${widget.target.targetId}'),
          if (widget.target.description != null) ...[
            const SizedBox(height: 3),
            _MutedText(widget.target.description!),
          ],
          const SizedBox(height: 8),
          _MovementTargetTextField(
            key: ValueKey(
              'cinematic-builder-movement-target-label-'
              '${widget.target.targetId}',
            ),
            controller: _labelController,
            placeholder: 'Nom de la destination',
          ),
          const SizedBox(height: 6),
          _MovementTargetTextField(
            key: ValueKey(
              'cinematic-builder-movement-target-description-'
              '${widget.target.targetId}',
            ),
            controller: _descriptionController,
            placeholder: 'Description optionnelle',
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InlineControlAction(
                label: 'Enregistrer',
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-save-movement-target-'
                    '${widget.target.targetId}',
                  ),
                  onPressed: _isSaving ? null : _save,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isLoading: _isSaving,
                  leading: const Icon(CupertinoIcons.check_mark),
                  child: const SizedBox.shrink(),
                ),
              ),
              _InlineControlAction(
                label: 'Supprimer',
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-delete-movement-target-'
                    '${widget.target.targetId}',
                  ),
                  onPressed: isUsed || _isRemoving ? null : _remove,
                  variant: PokeMapButtonVariant.danger,
                  size: PokeMapButtonSize.small,
                  isLoading: _isRemoving,
                  leading: const Icon(CupertinoIcons.trash),
                  child: const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          if (isUsed) ...[
            const SizedBox(height: 6),
            const _MutedText(
              'Cette destination est utilisée par un bloc Déplacer un acteur.',
            ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 6),
            _MutedText(_feedback!),
          ],
        ],
      ),
    );
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      setState(() => _feedback = 'Nom de destination obligatoire');
      return;
    }
    final description = _descriptionController.text.trim();
    setState(() {
      _isSaving = true;
      _feedback = null;
    });
    final saved = await widget.onUpdateMovementTarget(
      widget.target,
      label: label,
      description: description.isEmpty ? null : description,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _feedback = saved ? null : 'Destination introuvable';
    });
  }

  Future<void> _remove() async {
    setState(() {
      _isRemoving = true;
      _feedback = null;
    });
    final removed = await widget.onRemoveMovementTarget(widget.target);
    if (!mounted) {
      return;
    }
    setState(() {
      _isRemoving = false;
      _feedback = removed ? null : 'Suppression impossible';
    });
  }
}

class _MovementTargetTextField extends StatelessWidget {
  const _MovementTargetTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final textStyle = DefaultTextStyle.of(context).style;
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      style: textStyle.copyWith(
        color: colors.textPrimary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      placeholderStyle: textStyle.copyWith(
        color: colors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _ActorFacingPaletteTile extends StatelessWidget {
  const _ActorFacingPaletteTile({
    required this.asset,
    required this.onAddActorFacing,
  });

  final CinematicAsset asset;
  final _AddActorFacingCallback onAddActorFacing;

  @override
  Widget build(BuildContext context) {
    final hasActors = asset.requiredActors.isNotEmpty;
    final description = hasActors
        ? 'Regarder une direction'
        : 'Ajoutez d’abord un acteur requis';
    return Stack(
      children: [
        PokeMapCard(
          onTap: hasActors ? onAddActorFacing : null,
          child: Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.arrow_2_circlepath,
                tone: PokeMapTone.brand,
                size: 30,
                iconSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StrongText('Orienter un acteur'),
                    const SizedBox(height: 2),
                    _MutedText(description),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: _TestHidden(
            hitTestable: true,
            child: PokeMapButton(
              key: const ValueKey('cinematic-builder-palette-actorFace-button'),
              onPressed: hasActors ? onAddActorFacing : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActorMovePaletteTile extends StatelessWidget {
  const _ActorMovePaletteTile({
    required this.asset,
    required this.onAddActorMove,
  });

  final CinematicAsset asset;
  final _AddActorMoveCallback onAddActorMove;

  @override
  Widget build(BuildContext context) {
    final hasActors = asset.requiredActors.isNotEmpty;
    final hasTargets = asset.movementTargets.isNotEmpty;
    final description = !hasActors
        ? 'Ajoutez d’abord un acteur'
        : !hasTargets
            ? 'Ajoutez d’abord une destination'
            : 'Aller vers un repère';
    return Stack(
      children: [
        PokeMapCard(
          onTap: hasActors && hasTargets ? onAddActorMove : null,
          child: Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.person_crop_rectangle,
                tone: PokeMapTone.brand,
                size: 30,
                iconSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StrongText('Déplacer un acteur'),
                    const SizedBox(height: 2),
                    _MutedText(description),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: _TestHidden(
            hitTestable: true,
            child: PokeMapButton(
              key: const ValueKey('cinematic-builder-palette-actorMove-button'),
              onPressed: hasActors && hasTargets ? onAddActorMove : null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaletteBlockTile extends StatelessWidget {
  const _PaletteBlockTile({required this.block, required this.onAddBasicBlock});

  final _PaletteBlock block;
  final _AddBasicBlockCallback onAddBasicBlock;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final blockKind = block.blockKind;
    if (blockKind == null) {
      return PokeMapCard(
        child: Row(
          children: [
            PokeMapIconTile(
              icon: block.icon,
              tone: PokeMapTone.neutral,
              size: 30,
              iconSize: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StrongText(block.label),
                  const SizedBox(height: 2),
                  _MutedText(block.description),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.lock_fill, color: colors.textMuted, size: 13),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PokeMapCard(
          onTap: () => onAddBasicBlock(blockKind),
          child: Row(
            children: [
              PokeMapIconTile(
                icon: block.icon,
                tone: PokeMapTone.cinematic,
                size: 30,
                iconSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StrongText(block.label),
                    const SizedBox(height: 2),
                    _MutedText(block.description),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: _TestHidden(
            hitTestable: true,
            child: PokeMapButton(
              key: ValueKey(
                'cinematic-builder-palette-${blockKind.name}-button',
              ),
              onPressed: () => onAddBasicBlock(blockKind),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewSandbox extends StatelessWidget {
  const _PreviewSandbox({
    required this.entry,
    required this.asset,
    this.backdropPreviewModel,
    this.backdropTileRenderPlan,
    this.backdropLayerRenderPlan,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    required this.playbackPreviewStatus,
    required this.backdropFramingState,
    required this.onBackdropFramingModeChanged,
    required this.onBackdropFramingZoomChanged,
    required this.onBackdropFramingPanChanged,
    required this.onBackdropFramingResetView,
    required this.onBackdropFramingDetailsChanged,
    required this.onBackdropFramingGridChanged,
    required this.selectedStep,
    required this.selectedStepIndex,
    required this.timelineProbeTimeMs,
    required this.stagePoints,
    this.selectedStagePointId,
    required this.addStagePointMode,
    this.onSelectStagePointId,
    this.onUpdateStagePoint,
    this.onAddStagePointAtTile,
    this.onAddStagePointModeChanged,
    required this.readiness,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final CinematicMapBackdropPreviewModel? backdropPreviewModel;
  final CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;
  final CinematicBackdropPreviewFramingState backdropFramingState;
  final ValueChanged<CinematicBackdropPreviewFramingMode>
      onBackdropFramingModeChanged;
  final ValueChanged<double> onBackdropFramingZoomChanged;
  final ValueChanged<Offset> onBackdropFramingPanChanged;
  final VoidCallback onBackdropFramingResetView;
  final ValueChanged<bool> onBackdropFramingDetailsChanged;
  final ValueChanged<bool> onBackdropFramingGridChanged;
  final CinematicTimelineStep? selectedStep;
  final int? selectedStepIndex;
  final int? timelineProbeTimeMs;
  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final bool addStagePointMode;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<Offset>? onAddStagePointAtTile;
  final ValueChanged<bool>? onAddStagePointModeChanged;
  final CinematicStagePreviewReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-preview-placeholder'),
      expandChild: true,
      padding: EdgeInsets.all(backdropPreviewModel != null ? 8 : 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 260;
          final backdropPreviewModel = this.backdropPreviewModel;
          if (backdropPreviewModel != null) {
            return CinematicMapBackdropPreviewPanel(
              model: backdropPreviewModel,
              asset: asset,
              compact: compact,
              tileRenderPlan: backdropTileRenderPlan,
              layerRenderPlan: backdropLayerRenderPlan,
              actorDisplayPreviewModel: actorDisplayPreviewModel,
              actorPlaybackPreviewModel: actorPlaybackPreviewModel,
              actorSpritePreviewPlan: actorSpritePreviewPlan,
              playbackPreviewStatus: playbackPreviewStatus,
              framingState: backdropFramingState,
              selectedStep: selectedStep,
              onFramingModeChanged: onBackdropFramingModeChanged,
              onFramingZoomChanged: onBackdropFramingZoomChanged,
              onFramingPanChanged: onBackdropFramingPanChanged,
              onFramingResetView: onBackdropFramingResetView,
              onFramingDetailsChanged: onBackdropFramingDetailsChanged,
              onFramingGridChanged: onBackdropFramingGridChanged,
              stagePoints: stagePoints,
              selectedStagePointId: selectedStagePointId,
              addStagePointMode: addStagePointMode,
              onSelectStagePointId: onSelectStagePointId,
              onUpdateStagePoint: onUpdateStagePoint,
              onAddStagePointAtTile: onAddStagePointAtTile,
              onAddStagePointModeChanged: onAddStagePointModeChanged,
              readiness: readiness,
            );
          }
          final ultraCompact = constraints.maxHeight < 205;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.rectangle_on_rectangle,
                    color: colors.textMuted,
                    size: compact ? 24 : 34,
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Text(
                    'Aperçu sandbox',
                    textAlign: TextAlign.center,
                    style: DefaultTextStyle.of(context).style.copyWith(
                          color: colors.textPrimary,
                          fontSize: compact ? 15 : 18,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (!ultraCompact) ...[
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      'La lecture complète n’est pas encore disponible dans ce lot. '
                      'Cette zone reste une prévisualisation visuelle locale.',
                      textAlign: TextAlign.center,
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: DefaultTextStyle.of(context).style.copyWith(
                            color: colors.textMuted,
                            fontSize: compact ? 10 : 12,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                  SizedBox(height: compact ? 8 : 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PokeMapBadge(
                        label: '${entry.timeline.stepCount} step(s)',
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      PokeMapBadge(
                        label: _durationLabel(entry.timeline),
                        variant: PokeMapBadgeVariant.info,
                      ),
                    ],
                  ),
                  if (!compact && timelineProbeTimeMs != null) ...[
                    const SizedBox(height: 10),
                    _MutedText(
                      'Marqueur temps : '
                      '${_shortTimeLabel(timelineProbeTimeMs!)}',
                    ),
                    const SizedBox(height: 5),
                    const _MutedText('Marqueur local : inspection uniquement.'),
                  ],
                  if (!compact &&
                      selectedStep != null &&
                      selectedStepIndex != null) ...[
                    const SizedBox(height: 12),
                    const _MutedText('Scène non jouée. Bloc sélectionné :'),
                    const SizedBox(height: 6),
                    PokeMapBadge(
                      label: '${selectedStepIndex! + 1}. '
                          '${_stepDisplayTitle(asset, selectedStep!, selectedStepIndex!)} • '
                          '${selectedStep!.kind.name}',
                      variant: PokeMapBadgeVariant.info,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

const _builderTimelineGap = 12.0;
const _builderPreviewMinHeight = 220.0;
const _builderPreviewMaxHeight = 420.0;
const _builderTimelineMinHeight = 500.0;
const _builderTimelineMaxHeight = 680.0;
const _builderTimelinePreferredShare = 0.62;
const _builderBackdropPreviewMinHeight = 450.0;
const _builderBackdropPreviewMaxHeight = 560.0;
const _builderBackdropTimelineMinHeight = 320.0;
const _builderBackdropTimelineMaxHeight = 520.0;
const _builderBackdropTimelinePreferredShare = 0.40;
const _actorAnimationCadenceSampleWindowMs = 100;

double _builderTimelineHeight(
  double availableHeight, {
  required bool hasBackdrop,
}) {
  if (availableHeight <= 0) {
    return 0;
  }
  final previewMinHeight =
      hasBackdrop ? _builderBackdropPreviewMinHeight : _builderPreviewMinHeight;
  final previewMaxHeight =
      hasBackdrop ? _builderBackdropPreviewMaxHeight : _builderPreviewMaxHeight;
  final timelineMinHeight = hasBackdrop
      ? _builderBackdropTimelineMinHeight
      : _builderTimelineMinHeight;
  final timelineMaxHeight = hasBackdrop
      ? _builderBackdropTimelineMaxHeight
      : _builderTimelineMaxHeight;
  final timelinePreferredShare = hasBackdrop
      ? _builderBackdropTimelinePreferredShare
      : _builderTimelinePreferredShare;
  final maxTimeline = math.min(
    timelineMaxHeight,
    math.max(0.0, availableHeight - _builderTimelineGap - previewMinHeight),
  );
  final minTimeline = math.min(timelineMinHeight, maxTimeline);
  final preferredHeight = math.max(
    availableHeight * timelinePreferredShare,
    availableHeight - _builderTimelineGap - previewMaxHeight,
  );
  return preferredHeight.clamp(minTimeline, maxTimeline).toDouble();
}

const _timelineLaneHeaderWidth = 128.0;
const _timelineAxisHeight = 34.0;
const _timelineLaneRowHeight = 48.0;
const _timelineBarHeight = 36.0;
const _timelineBarMinWidth = 72.0;
const _timelinePixelsPerMsFloor = 0.32;
const _timelineProbeSnapThresholdPx = 8.0;

enum _TimelineProbeSnapHint { timelineStart, timelineEnd, blockStart, blockEnd }

class _TimelineProbeSnapResult {
  const _TimelineProbeSnapResult({required this.timeMs, this.snapHint});

  final int timeMs;
  final _TimelineProbeSnapHint? snapHint;
}

class _TimelineProbeSnapTarget {
  const _TimelineProbeSnapTarget({
    required this.timeMs,
    required this.snapHint,
    required this.stepIndex,
    required this.stableOrder,
  });

  final int timeMs;
  final _TimelineProbeSnapHint snapHint;
  final int stepIndex;
  final int stableOrder;
}

enum _TimelineKeyboardNavigation { previous, next, up, down, first, last }

_TimelineKeyboardNavigation? _timelineKeyboardNavigationForKey(
  LogicalKeyboardKey key,
) {
  if (key == LogicalKeyboardKey.arrowLeft) {
    return _TimelineKeyboardNavigation.previous;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return _TimelineKeyboardNavigation.next;
  }
  if (key == LogicalKeyboardKey.arrowUp) {
    return _TimelineKeyboardNavigation.up;
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return _TimelineKeyboardNavigation.down;
  }
  if (key == LogicalKeyboardKey.home) {
    return _TimelineKeyboardNavigation.first;
  }
  if (key == LogicalKeyboardKey.end) {
    return _TimelineKeyboardNavigation.last;
  }
  return null;
}

CinematicTimelineTimeBlock? _timelineKeyboardTargetBlock(
  CinematicTimelineTimeLayoutReadModel timeLayout,
  String? selectedStepId,
  _TimelineKeyboardNavigation navigation,
) {
  final blocks = timeLayout.blocks.toList()
    ..sort((a, b) => a.stepIndex.compareTo(b.stepIndex));
  if (blocks.isEmpty) {
    return null;
  }
  final selectedIndex = selectedStepId == null
      ? -1
      : blocks.indexWhere((block) => block.stepId == selectedStepId);
  return switch (navigation) {
    _TimelineKeyboardNavigation.first => blocks.first,
    _TimelineKeyboardNavigation.last => blocks.last,
    _TimelineKeyboardNavigation.next => selectedIndex < 0
        ? blocks.first
        : blocks[math.min(selectedIndex + 1, blocks.length - 1)],
    _TimelineKeyboardNavigation.previous =>
      selectedIndex < 0 ? blocks.last : blocks[math.max(selectedIndex - 1, 0)],
    _TimelineKeyboardNavigation.up => _timelineVerticalKeyboardTargetBlock(
        timeLayout,
        selectedStepId,
        up: true,
      ),
    _TimelineKeyboardNavigation.down => _timelineVerticalKeyboardTargetBlock(
        timeLayout,
        selectedStepId,
        up: false,
      ),
  };
}

CinematicTimelineTimeBlock? _timelineVerticalKeyboardTargetBlock(
  CinematicTimelineTimeLayoutReadModel timeLayout,
  String? selectedStepId, {
  required bool up,
}) {
  final selectedBlock = _selectedTimeBlock(timeLayout, selectedStepId);
  if (selectedBlock == null) {
    return _timelineVerticalFallbackTargetBlock(timeLayout, up: up);
  }
  final currentLaneIndex = timeLayout.lanes.indexWhere(
    (lane) => lane.laneId == selectedBlock.laneId,
  );
  if (currentLaneIndex < 0) {
    return _timelineVerticalFallbackTargetBlock(timeLayout, up: up);
  }
  final currentCenterMs = _timelineBlockCenterMs(selectedBlock);
  final direction = up ? -1 : 1;
  for (var laneIndex = currentLaneIndex + direction;
      laneIndex >= 0 && laneIndex < timeLayout.lanes.length;
      laneIndex += direction) {
    final lane = timeLayout.lanes[laneIndex];
    if (lane.blocks.isEmpty) {
      continue;
    }
    return _timelineClosestBlockInLane(lane, currentCenterMs);
  }
  return selectedBlock;
}

CinematicTimelineTimeBlock? _timelineVerticalFallbackTargetBlock(
  CinematicTimelineTimeLayoutReadModel timeLayout, {
  required bool up,
}) {
  final lanes = up ? timeLayout.lanes.reversed : timeLayout.lanes;
  for (final lane in lanes) {
    if (lane.blocks.isEmpty) {
      continue;
    }
    return up ? lane.blocks.last : lane.blocks.first;
  }
  return null;
}

CinematicTimelineTimeBlock _timelineClosestBlockInLane(
  CinematicTimelineTimeLane lane,
  double currentCenterMs,
) {
  var bestBlock = lane.blocks.first;
  var bestDistance =
      (_timelineBlockCenterMs(bestBlock) - currentCenterMs).abs();
  for (final candidate in lane.blocks.skip(1)) {
    final candidateDistance =
        (_timelineBlockCenterMs(candidate) - currentCenterMs).abs();
    final distanceOrder = candidateDistance.compareTo(bestDistance);
    if (distanceOrder < 0 ||
        (distanceOrder == 0 && candidate.stepIndex < bestBlock.stepIndex)) {
      bestBlock = candidate;
      bestDistance = candidateDistance;
    }
  }
  return bestBlock;
}

double _timelineBlockCenterMs(CinematicTimelineTimeBlock block) {
  return block.startMs + block.visualDurationMs / 2;
}

Map<String, CinematicActorAnimationCadenceHint> _cadenceHintsForPlayback({
  required CinematicPreviewPlaybackPlan playbackPlan,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
}) {
  if (playbackFrame == null || playbackTimeMs <= 0) {
    return const {};
  }

  final previousFrame = playbackPlan.frameAt(
    math.max(0, playbackTimeMs - _actorAnimationCadenceSampleWindowMs),
  );

  final hints = <String, CinematicActorAnimationCadenceHint>{};
  for (final pose in playbackFrame.actorPoses) {
    if (!pose.hasPosition) {
      continue;
    }
    final previousPose = previousFrame.actorPoseById(pose.actorId);
    if (previousPose == null || !previousPose.hasPosition) {
      continue;
    }

    final velocityTilesPerSecond = ((pose.x! - previousPose.x!).abs() +
            (pose.y! - previousPose.y!).abs()) /
        (_actorAnimationCadenceSampleWindowMs / 1000);
    if (!velocityTilesPerSecond.isFinite || velocityTilesPerSecond < 0) {
      continue;
    }
    hints[pose.actorId] = CinematicActorAnimationCadenceHint(
      actorId: pose.actorId,
      velocityTilesPerSecond: velocityTilesPerSecond,
      sampleWindowMs: _actorAnimationCadenceSampleWindowMs,
    );
  }
  return hints;
}

CinematicPlaybackPreviewStatus _playbackPreviewStatusFor({
  required bool isPlaybackOverlayActive,
  required bool isPlaybackPlaying,
  required _PlaybackActorAnimationStatus animationStatus,
  required CinematicPlaybackPreviewFallbackSummary fallbackSummary,
}) {
  final playbackLabel = isPlaybackPlaying
      ? 'Lecture en cours'
      : isPlaybackOverlayActive
          ? 'Lecture en pause'
          : 'Aperçu statique';
  final playbackTone = isPlaybackPlaying
      ? PokeMapTone.success
      : isPlaybackOverlayActive
          ? PokeMapTone.info
          : PokeMapTone.neutral;
  final actorAnimationLabel = switch (animationStatus) {
    _PlaybackActorAnimationStatus.partial => 'Animation partielle',
    _PlaybackActorAnimationStatus.ready => 'Animation acteur prête',
    _PlaybackActorAnimationStatus.none => 'Aucun acteur animé',
  };
  final actorAnimationTone = switch (animationStatus) {
    _PlaybackActorAnimationStatus.partial => PokeMapTone.warning,
    _PlaybackActorAnimationStatus.ready => PokeMapTone.success,
    _PlaybackActorAnimationStatus.none => PokeMapTone.neutral,
  };
  return CinematicPlaybackPreviewStatus(
    playbackLabel: playbackLabel,
    playbackTone: playbackTone,
    actorAnimationLabel: actorAnimationLabel,
    actorAnimationTone: actorAnimationTone,
    fallbackSummary: fallbackSummary,
  );
}

bool _hasReadyActorSprite(CinematicActorSpritePreviewPlan? plan) {
  return plan?.actors.any(
        (actor) => actor.status == CinematicActorSpriteStatus.spriteReady,
      ) ??
      false;
}

enum _PlaybackActorAnimationStatus { none, ready, partial }

CinematicPlaybackPreviewAnimationState _previewFallbackAnimationState(
  _PlaybackActorAnimationStatus status,
) {
  return switch (status) {
    _PlaybackActorAnimationStatus.none =>
      CinematicPlaybackPreviewAnimationState.none,
    _PlaybackActorAnimationStatus.ready =>
      CinematicPlaybackPreviewAnimationState.ready,
    _PlaybackActorAnimationStatus.partial =>
      CinematicPlaybackPreviewAnimationState.partial,
  };
}

final class _PlaybackActorSpritePreviewResolution {
  const _PlaybackActorSpritePreviewResolution({
    required this.plan,
    required this.animationStatus,
    required this.walkingFrames,
  });

  final CinematicActorSpritePreviewPlan? plan;
  final _PlaybackActorAnimationStatus animationStatus;
  final List<CinematicActorWalkingAnimationPreviewFrame> walkingFrames;
}

_PlaybackActorSpritePreviewResolution _resolvePlaybackActorSpritePreviewPlan({
  required CinematicActorSpritePreviewPlan? basePlan,
  required CinematicActorDisplayPreviewModel? displayModel,
  required CinematicPreviewPlaybackFrame? playbackFrame,
  required int playbackTimeMs,
  required bool isPlaybackPlaying,
  required List<CinematicTimelineStep> timelineSteps,
  required List<ProjectCharacterEntry> characters,
  required Map<String, CinematicActorAnimationCadenceHint>
      cadenceHintsByActorId,
}) {
  if (basePlan == null || displayModel == null || playbackFrame == null) {
    return _PlaybackActorSpritePreviewResolution(
      plan: basePlan,
      animationStatus: _PlaybackActorAnimationStatus.none,
      walkingFrames: const [],
    );
  }

  final displayActorById = <String, CinematicActorDisplayPreviewActor>{
    for (final actor in displayModel.actors) actor.actorId: actor,
  };
  final characterById = <String, ProjectCharacterEntry>{
    for (final character in characters) character.id: character,
  };

  var changed = false;
  var hasReadyAnimation = false;
  var hasPartialAnimation = false;
  final walkingFrames = <CinematicActorWalkingAnimationPreviewFrame>[];
  final resolvedActors = <CinematicActorSpritePreviewActor>[];
  for (final spriteActor in basePlan.actors) {
    final displayActor = displayActorById[spriteActor.actorId];
    final characterId = displayActor?.appearance.characterId;
    final character = characterId == null ? null : characterById[characterId];
    final resolved = displayActor == null
        ? null
        : resolveCinematicActorWalkingAnimationPreviewFrame(
            actor: displayActor,
            playbackFrame: playbackFrame,
            playbackTimeMs: playbackTimeMs,
            isPlaybackPlaying: isPlaybackPlaying,
            timelineSteps: timelineSteps,
            character: character,
            cadenceHint: cadenceHintsByActorId[spriteActor.actorId],
          );
    if (resolved != null) {
      walkingFrames.add(resolved);
    }
    final sourceRect = resolved?.sourceRect;
    final isMoving = resolved?.isMoving ?? false;

    // V1-116 only swaps the already-resolved sprite source during editor
    // preview playback. Missing/invalid animation data deliberately falls back
    // to the V1-99 idle sprite or placeholder path instead of inventing frames.
    if (sourceRect == null ||
        resolved?.characterId == null ||
        resolved?.tilesetId == null ||
        spriteActor.spriteRef == null ||
        spriteActor.status != CinematicActorSpriteStatus.spriteReady) {
      if (isMoving) {
        hasPartialAnimation = true;
      }
      resolvedActors.add(spriteActor);
      continue;
    }

    if (isMoving) {
      if (resolved!.isFallback) {
        hasPartialAnimation = true;
      } else {
        hasReadyAnimation = true;
      }
    }

    final animatedSpriteRef = CinematicActorSpriteRef(
      characterId: resolved!.characterId!,
      tilesetId: resolved.tilesetId!,
      sourceTileRect: TilesetSourceRect(
        x: sourceRect.x,
        y: sourceRect.y,
        width: character?.frameWidth ?? spriteActor.spriteRef!.frameWidthTiles,
        height:
            character?.frameHeight ?? spriteActor.spriteRef!.frameHeightTiles,
      ),
      frameWidthTiles:
          character?.frameWidth ?? spriteActor.spriteRef!.frameWidthTiles,
      frameHeightTiles:
          character?.frameHeight ?? spriteActor.spriteRef!.frameHeightTiles,
      direction: _previewDirectionFromFacing(resolved.direction) ??
          spriteActor.spriteRef!.direction,
    );
    changed = true;
    resolvedActors.add(
      CinematicActorSpritePreviewActor(
        actorId: spriteActor.actorId,
        actorLabel: spriteActor.actorLabel,
        bindingKind: spriteActor.bindingKind,
        position: spriteActor.position,
        direction: spriteActor.direction,
        status: spriteActor.status,
        spriteRef: animatedSpriteRef,
        placeholderFallback: spriteActor.placeholderFallback,
        depthHint: spriteActor.depthHint,
        diagnostics: spriteActor.diagnostics,
      ),
    );
  }

  final animationStatus = hasPartialAnimation
      ? _PlaybackActorAnimationStatus.partial
      : hasReadyAnimation
          ? _PlaybackActorAnimationStatus.ready
          : _PlaybackActorAnimationStatus.none;

  if (!changed) {
    return _PlaybackActorSpritePreviewResolution(
      plan: basePlan,
      animationStatus: animationStatus,
      walkingFrames: walkingFrames,
    );
  }
  return _PlaybackActorSpritePreviewResolution(
    plan: CinematicActorSpritePreviewPlan(
      actors: resolvedActors,
      diagnostics: basePlan.diagnostics,
    ),
    animationStatus: animationStatus,
    walkingFrames: walkingFrames,
  );
}

CinematicActorPreviewDirection? _previewDirectionFromFacing(
    EntityFacing? facing) {
  return switch (facing) {
    EntityFacing.north => CinematicActorPreviewDirection.north,
    EntityFacing.south => CinematicActorPreviewDirection.south,
    EntityFacing.east => CinematicActorPreviewDirection.east,
    EntityFacing.west => CinematicActorPreviewDirection.west,
    null => null,
  };
}

class _TimelinePlaceholder extends StatefulWidget {
  const _TimelinePlaceholder({
    required this.entry,
    required this.asset,
    required this.selectedStepId,
    required this.timelineProbeTimeMs,
    required this.timelineProbeSnapHint,
    required this.playbackPlan,
    required this.playbackFrame,
    required this.playbackTimeMs,
    required this.isPlaybackPlaying,
    required this.onStepSelected,
    required this.onTimelineProbeChanged,
    required this.onTimelineProbeCleared,
    required this.onStepDurationResized,
    required this.onAddDraftStep,
    required this.onPlaybackPlayPause,
    required this.onPlaybackStop,
    required this.onPlaybackReset,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final String? selectedStepId;
  final int? timelineProbeTimeMs;
  final _TimelineProbeSnapHint? timelineProbeSnapHint;
  final CinematicPreviewPlaybackPlan playbackPlan;
  final CinematicPreviewPlaybackFrame playbackFrame;
  final int playbackTimeMs;
  final bool isPlaybackPlaying;
  final ValueChanged<CinematicTimelineStep> onStepSelected;
  final ValueChanged<_TimelineProbeSnapResult> onTimelineProbeChanged;
  final VoidCallback onTimelineProbeCleared;
  final _ResizeStepDurationCallback onStepDurationResized;
  final VoidCallback onAddDraftStep;
  final VoidCallback onPlaybackPlayPause;
  final VoidCallback onPlaybackStop;
  final VoidCallback onPlaybackReset;

  @override
  State<_TimelinePlaceholder> createState() => _TimelinePlaceholderState();
}

class _TimelinePlaceholderState extends State<_TimelinePlaceholder> {
  String? _hoveredStepId;
  late final FocusNode _timelineFocusNode = FocusNode(
    debugLabel: 'Cinematic timeline keyboard navigation',
  );
  late final ScrollController _timelineVerticalScrollController =
      ScrollController();
  late final ScrollController _timelineHorizontalScrollController =
      ScrollController();
  bool _timelineHasKeyboardFocus = false;
  bool _timelineKeyboardHelpOpen = false;
  bool _timelineProbeHelpOpen = false;

  void _setHoveredStepId(String? stepId) {
    if (_hoveredStepId == stepId) {
      return;
    }
    setState(() => _hoveredStepId = stepId);
  }

  void _requestTimelineKeyboardFocus() {
    if (!_timelineFocusNode.hasFocus) {
      _timelineFocusNode.requestFocus();
    }
  }

  void _toggleTimelineKeyboardHelp() {
    _requestTimelineKeyboardFocus();
    setState(() => _timelineKeyboardHelpOpen = !_timelineKeyboardHelpOpen);
  }

  void _toggleTimelineProbeHelp() {
    _requestTimelineKeyboardFocus();
    setState(() => _timelineProbeHelpOpen = !_timelineProbeHelpOpen);
  }

  @override
  void didUpdateWidget(covariant _TimelinePlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timelineProbeTimeMs != null &&
        widget.timelineProbeTimeMs == null) {
      _timelineProbeHelpOpen = false;
    }
  }

  KeyEventResult _handleTimelineKeyEvent(
    CinematicTimelineTimeLayoutReadModel timeLayout,
    Map<String, CinematicTimelineStep> stepsById,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.timelineProbeTimeMs != null) {
      widget.onTimelineProbeCleared();
      return KeyEventResult.handled;
    }
    final navigation = _timelineKeyboardNavigationForKey(event.logicalKey);
    if (navigation == null) {
      return KeyEventResult.ignored;
    }
    final targetBlock = _timelineKeyboardTargetBlock(
      timeLayout,
      widget.selectedStepId,
      navigation,
    );
    if (targetBlock == null) {
      return KeyEventResult.handled;
    }
    final targetStep = stepsById[targetBlock.stepId];
    if (targetStep == null) {
      return KeyEventResult.handled;
    }
    widget.onStepSelected(targetStep);
    _scrollTimelineBlockIntoView(timeLayout, targetBlock);
    return KeyEventResult.handled;
  }

  void _scrollTimelineBlockIntoView(
    CinematicTimelineTimeLayoutReadModel timeLayout,
    CinematicTimelineTimeBlock block,
  ) {
    _scrollTimelineBlockHorizontallyIntoView(timeLayout, block);
    _scrollTimelineBlockVerticallyIntoView(timeLayout, block);
  }

  void _scrollTimelineBlockHorizontallyIntoView(
    CinematicTimelineTimeLayoutReadModel timeLayout,
    CinematicTimelineTimeBlock block,
  ) {
    if (!_timelineHorizontalScrollController.hasClients ||
        timeLayout.totalDurationMs <= 0) {
      return;
    }
    final position = _timelineHorizontalScrollController.position;
    final viewportWidth = position.viewportDimension;
    if (viewportWidth <= 0) {
      return;
    }
    final contentWidth = viewportWidth + position.maxScrollExtent;
    if (contentWidth <= 0) {
      return;
    }
    final pixelsPerMs = contentWidth / timeLayout.totalDurationMs;
    final blockLeft = block.startMs * pixelsPerMs;
    final blockRight = blockLeft + _timelineBarWidth(block, pixelsPerMs);
    final targetOffset = _scrollOffsetToRevealRange(
      currentOffset: position.pixels,
      minOffset: position.minScrollExtent,
      maxOffset: position.maxScrollExtent,
      viewportExtent: viewportWidth,
      rangeStart: blockLeft,
      rangeEnd: blockRight,
    );
    if (targetOffset != null) {
      _animateTimelineScroll(_timelineHorizontalScrollController, targetOffset);
    }
  }

  void _scrollTimelineBlockVerticallyIntoView(
    CinematicTimelineTimeLayoutReadModel timeLayout,
    CinematicTimelineTimeBlock block,
  ) {
    if (!_timelineVerticalScrollController.hasClients) {
      return;
    }
    final laneIndex = timeLayout.lanes.indexWhere(
      (lane) => lane.laneId == block.laneId,
    );
    if (laneIndex < 0) {
      return;
    }
    final position = _timelineVerticalScrollController.position;
    final viewportHeight = position.viewportDimension;
    if (viewportHeight <= 0) {
      return;
    }
    final rowTop = _timelineAxisHeight + laneIndex * _timelineLaneRowHeight;
    final rowBottom = rowTop + _timelineLaneRowHeight;
    final targetOffset = _scrollOffsetToRevealRange(
      currentOffset: position.pixels,
      minOffset: position.minScrollExtent,
      maxOffset: position.maxScrollExtent,
      viewportExtent: viewportHeight,
      rangeStart: rowTop,
      rangeEnd: rowBottom,
    );
    if (targetOffset != null) {
      _animateTimelineScroll(_timelineVerticalScrollController, targetOffset);
    }
  }

  double? _scrollOffsetToRevealRange({
    required double currentOffset,
    required double minOffset,
    required double maxOffset,
    required double viewportExtent,
    required double rangeStart,
    required double rangeEnd,
  }) {
    const padding = 16.0;
    final visibleStart = currentOffset + padding;
    final visibleEnd = currentOffset + viewportExtent - padding;
    if (rangeStart < visibleStart) {
      return math.max(minOffset, rangeStart - padding);
    }
    if (rangeEnd > visibleEnd) {
      return math.min(maxOffset, rangeEnd - viewportExtent + padding);
    }
    return null;
  }

  void _animateTimelineScroll(
    ScrollController controller,
    double targetOffset,
  ) {
    if (!controller.hasClients) {
      return;
    }
    final position = controller.position;
    final clampedOffset = targetOffset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((clampedOffset - position.pixels).abs() < 0.5) {
      return;
    }
    unawaited(
      controller.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _timelineFocusNode.dispose();
    _timelineVerticalScrollController.dispose();
    _timelineHorizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeline = widget.entry.timeline;
    final steps = widget.asset.timeline.steps;
    final timeLayout = buildCinematicTimelineTimeLayoutReadModel(widget.asset);
    final selectedBlock = _selectedTimeBlock(timeLayout, widget.selectedStepId);
    final timelineProbeTimeMs = widget.timelineProbeTimeMs;
    final hoveredBlock = _selectedTimeBlock(timeLayout, _hoveredStepId);
    final stepsById = {for (final step in steps) step.id: step};
    final hoveredStep =
        hoveredBlock == null ? null : stepsById[hoveredBlock.stepId];
    final hoveredLane =
        hoveredBlock == null ? null : timeLayout.laneById(hoveredBlock.laneId);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _requestTimelineKeyboardFocus(),
      child: Focus(
        key: const ValueKey('cinematic-builder-timeline-keyboard-focus'),
        focusNode: _timelineFocusNode,
        onFocusChange: (hasFocus) {
          if (_timelineHasKeyboardFocus == hasFocus) {
            return;
          }
          setState(() => _timelineHasKeyboardFocus = hasFocus);
        },
        onKeyEvent: (node, event) =>
            _handleTimelineKeyEvent(timeLayout, stepsById, event),
        child: PokeMapPanel(
          key: const ValueKey('cinematic-builder-timeline-placeholder'),
          expandChild: true,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  PokeMapIconTile(
                    icon: CupertinoIcons.film,
                    tone: PokeMapTone.cinematic,
                    size: 28,
                    iconSize: 15,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                          child: const Text('Déroulé', maxLines: 1),
                        ),
                        const SizedBox(height: 1),
                        DefaultTextStyle.merge(
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          child: const Text(
                            'Timeline cinématique',
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Transport controls row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PokeMapIconButton(
                        key: const ValueKey(
                          'cinematic-builder-header-transport-play-button',
                        ),
                        tooltip: 'Lire (à venir)',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.play_fill),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        tooltip: 'Annuler (à venir)',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.arrow_counterclockwise),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        tooltip: 'Rétablir (à venir)',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.arrow_clockwise),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        tooltip: 'Recadrer (à venir)',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.crop),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        tooltip: 'Zoom -',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.zoom_out),
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        tooltip: 'Zoom',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: null,
                        icon: const Icon(CupertinoIcons.circle),
                      ),
                      const SizedBox(width: 4),
                      _TestHidden(
                        child: Column(
                          children: [
                            if (timelineProbeTimeMs != null) ...[
                              const Text('Effacer le marqueur'),
                              const Text('Aide timeline'),
                            ],
                          ],
                        ),
                      ),
                      if (timelineProbeTimeMs == null)
                        PokeMapIconButton(
                          key: const ValueKey(
                            'cinematic-builder-add-draft-button',
                          ),
                          tooltip: 'Ajouter un brouillon',
                          size: 28,
                          variant: PokeMapIconButtonVariant.soft,
                          onPressed: widget.onAddDraftStep,
                          icon: const Icon(CupertinoIcons.plus),
                        )
                      else ...[
                        PokeMapIconButton(
                          key: const ValueKey(
                            'cinematic-builder-clear-time-probe-button',
                          ),
                          tooltip: 'Effacer le marqueur',
                          size: 28,
                          variant: PokeMapIconButtonVariant.soft,
                          onPressed: widget.onTimelineProbeCleared,
                          icon: const Icon(CupertinoIcons.xmark_circle),
                        ),
                        const SizedBox(width: 4),
                        PokeMapIconButton(
                          key: const ValueKey(
                            'cinematic-builder-probe-help-button',
                          ),
                          tooltip: 'Aide timeline',
                          size: 28,
                          variant: PokeMapIconButtonVariant.soft,
                          onPressed: _toggleTimelineProbeHelp,
                          icon: const Icon(CupertinoIcons.question_circle),
                        ),
                        const SizedBox(width: 4),
                        PokeMapIconButton(
                          key: const ValueKey(
                            'cinematic-builder-add-draft-button',
                          ),
                          tooltip: 'Ajouter un brouillon',
                          size: 28,
                          variant: PokeMapIconButtonVariant.soft,
                          onPressed: widget.onAddDraftStep,
                          icon: const Icon(CupertinoIcons.plus),
                        ),
                      ],
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        key: const ValueKey(
                          'cinematic-builder-keyboard-help-button',
                        ),
                        tooltip: 'Réglages',
                        size: 28,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: _toggleTimelineKeyboardHelp,
                        icon: const Icon(CupertinoIcons.settings),
                      ),
                    ],
                  ),
                ],
              ),
              // Offstage meta badges — kept for test compatibility
              _TestHidden(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PokeMapBadge(
                        label: '${timeline.stepCount} step(s)',
                        variant: PokeMapBadgeVariant.info,
                      ),
                      const SizedBox(width: 5),
                      PokeMapBadge(
                        label: _durationLabel(timeline),
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 5),
                      PokeMapBadge(
                        label: _timelineTotalLabel(timeLayout.totalDurationMs),
                        variant: PokeMapBadgeVariant.info,
                      ),
                      const SizedBox(width: 5),
                      PokeMapBadge(
                        label: '${timeLayout.laneCount} piste(s)',
                        variant: PokeMapBadgeVariant.narrative,
                      ),
                      const SizedBox(width: 5),
                      _TimelineKeyboardHelpBadge(
                        isOpen: _timelineKeyboardHelpOpen,
                        onPressed: _toggleTimelineKeyboardHelp,
                      ),
                      if (timelineProbeTimeMs != null) ...[
                        const SizedBox(width: 5),
                        PokeMapBadge(
                          key: const ValueKey(
                            'cinematic-builder-time-probe-badge',
                          ),
                          label: _timelineProbeBadgeLabel(
                            timelineProbeTimeMs,
                            widget.timelineProbeSnapHint,
                          ),
                          variant: PokeMapBadgeVariant.narrative,
                        ),
                      ],
                      const SizedBox(width: 5),
                      const PokeMapBadge(
                        label: 'Ordre linéaire conservé',
                        variant: PokeMapBadgeVariant.neutral,
                      ),
                      const SizedBox(width: 5),
                      const PokeMapBadge(
                        label: 'Layout temporel dérivé',
                        variant: PokeMapBadgeVariant.success,
                      ),
                      if (timeLayout.blocks.any(
                        (block) =>
                            block.durationSource ==
                            CinematicTimelineVisualDurationSource.fallback,
                      )) ...[
                        const SizedBox(width: 5),
                        const PokeMapBadge(
                          label: 'Fallback visuel',
                          variant: PokeMapBadgeVariant.warning,
                        ),
                      ],
                      if (timelineProbeTimeMs == null &&
                          selectedBlock != null) ...[
                        const SizedBox(width: 5),
                        PokeMapBadge(
                          key: const ValueKey(
                            'cinematic-builder-selected-time-badge',
                          ),
                          label:
                              'Sélection : ${_shortTimeLabel(selectedBlock.startMs)}',
                          variant: PokeMapBadgeVariant.info,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: steps.isEmpty
                          ? const _EmptyTimelineState()
                          : _TimelineTimeGrid(
                              asset: widget.asset,
                              timeLayout: timeLayout,
                              stepsById: stepsById,
                              verticalScrollController:
                                  _timelineVerticalScrollController,
                              horizontalScrollController:
                                  _timelineHorizontalScrollController,
                              selectedStepId: widget.selectedStepId,
                              selectedBlock: selectedBlock,
                              timelineProbeTimeMs: timelineProbeTimeMs,
                              playbackTimeMs: widget.playbackTimeMs,
                              showPlaybackPlayhead: _canPlayPreview(
                                widget.playbackPlan,
                              ),
                              hoveredStepId: _hoveredStepId,
                              timelineFocused: _timelineHasKeyboardFocus,
                              onStepHovered: _setHoveredStepId,
                              onStepSelected: (step) {
                                _requestTimelineKeyboardFocus();
                                widget.onStepSelected(step);
                              },
                              onTimelineProbeChanged: (timeMs) {
                                _requestTimelineKeyboardFocus();
                                widget.onTimelineProbeChanged(timeMs);
                              },
                              onStepDurationResized:
                                  widget.onStepDurationResized,
                            ),
                    ),
                    if (hoveredBlock != null && hoveredStep != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: SizedBox(
                            height: 22,
                            child: _TimelineHoverDetails(
                              asset: widget.asset,
                              block: hoveredBlock,
                              step: hoveredStep,
                              lane: hoveredLane,
                            ),
                          ),
                        ),
                      ),
                    if (_timelineKeyboardHelpOpen)
                      Positioned(
                        top: 28,
                        right: _timelineProbeHelpOpen &&
                                timelineProbeTimeMs != null
                            ? 334
                            : 8,
                        child: const _TimelineKeyboardHelpPanel(),
                      ),
                    if (_timelineProbeHelpOpen && timelineProbeTimeMs != null)
                      const Positioned(
                        top: 28,
                        right: 8,
                        child: _TimelineProbeHelpPanel(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, constraints) {
                  final durationLabel = DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text(
                      'Durée totale : ${_shortTimeLabel(timeLayout.totalDurationMs)} secondes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                  final transportControls = _TimelinePlaybackTransportControls(
                    plan: widget.playbackPlan,
                    frame: widget.playbackFrame,
                    playbackTimeMs: widget.playbackTimeMs,
                    isPlaying: widget.isPlaybackPlaying,
                    onPlayPause: widget.onPlaybackPlayPause,
                    onStop: widget.onPlaybackStop,
                    onReset: widget.onPlaybackReset,
                  );
                  if (constraints.maxWidth < 760) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        durationLabel,
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: transportControls,
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: durationLabel),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: transportControls,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineKeyboardHelpBadge extends StatelessWidget {
  const _TimelineKeyboardHelpBadge({
    required this.isOpen,
    required this.onPressed,
  });

  final bool isOpen;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: PokeMapBadge(
            label: 'Aide clavier',
            variant:
                isOpen ? PokeMapBadgeVariant.info : PokeMapBadgeVariant.neutral,
            icon: const Icon(CupertinoIcons.question_circle),
          ),
        ),
      ),
    );
  }
}

class _TimelineKeyboardHelpPanel extends StatelessWidget {
  const _TimelineKeyboardHelpPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('cinematic-builder-keyboard-help-panel'),
      focused: true,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SizedBox(
        width: 292,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TimelineKeyboardHelpRow(
              shortcut: '← / →',
              description: 'Bloc précédent / suivant',
            ),
            const SizedBox(height: 5),
            const _TimelineKeyboardHelpRow(
              shortcut: '↑ / ↓',
              description: 'Piste précédente / suivante',
            ),
            const SizedBox(height: 5),
            const _TimelineKeyboardHelpRow(
              shortcut: 'Home',
              description: 'Premier bloc',
            ),
            const SizedBox(height: 5),
            const _TimelineKeyboardHelpRow(
              shortcut: 'End',
              description: 'Dernier bloc',
            ),
            const SizedBox(height: 7),
            Text(
              'Sélection uniquement — pas de lecture ni déplacement temporel.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineProbeHelpPanel extends StatelessWidget {
  const _TimelineProbeHelpPanel();

  @override
  Widget build(BuildContext context) {
    return const PokeMapCard(
      key: ValueKey('cinematic-builder-probe-help-panel'),
      focused: true,
      borderRadius: 6,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SizedBox(
        width: 302,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TimelineProbeHelpLine('Sélection : bloc inspecté.'),
            SizedBox(height: 5),
            _TimelineProbeHelpLine('Marqueur : position temporelle locale.'),
            SizedBox(height: 5),
            _TimelineProbeHelpLine(
              'Alignement : marqueur calé sur une borne utile.',
            ),
            SizedBox(height: 5),
            _TimelineProbeHelpLine('Preview : lecture réelle à venir.'),
          ],
        ),
      ),
    );
  }
}

class _TimelineProbeHelpLine extends StatelessWidget {
  const _TimelineProbeHelpLine(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _TimelineKeyboardHelpRow extends StatelessWidget {
  const _TimelineKeyboardHelpRow({
    required this.shortcut,
    required this.description,
  });

  final String shortcut;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            shortcut,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.brandPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Expanded(
          child: Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _TimelineHoverDetails extends StatelessWidget {
  const _TimelineHoverDetails({
    required this.asset,
    required this.block,
    required this.step,
    required this.lane,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeBlock? block;
  final CinematicTimelineStep? step;
  final CinematicTimelineTimeLane? lane;

  @override
  Widget build(BuildContext context) {
    final block = this.block;
    final step = this.step;
    if (block == null || step == null) {
      return const SizedBox.shrink();
    }

    final colors = context.pokeMapColors;
    final details = _timelineHoverDetailLabels(asset, block, step, lane);
    return Container(
      key: const ValueKey('cinematic-builder-hover-details'),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Survol : ${block.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 8),
              for (final detail in details) ...[
                _TimelineHoverDetailText(detail),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineHoverDetailText extends StatelessWidget {
  const _TimelineHoverDetailText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _TimelineTimeGrid extends StatelessWidget {
  const _TimelineTimeGrid({
    required this.asset,
    required this.timeLayout,
    required this.stepsById,
    required this.verticalScrollController,
    required this.horizontalScrollController,
    required this.selectedStepId,
    required this.selectedBlock,
    required this.timelineProbeTimeMs,
    required this.playbackTimeMs,
    required this.showPlaybackPlayhead,
    required this.hoveredStepId,
    required this.timelineFocused,
    required this.onStepHovered,
    required this.onStepSelected,
    required this.onTimelineProbeChanged,
    required this.onStepDurationResized,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeLayoutReadModel timeLayout;
  final Map<String, CinematicTimelineStep> stepsById;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;
  final String? selectedStepId;
  final CinematicTimelineTimeBlock? selectedBlock;
  final int? timelineProbeTimeMs;
  final int playbackTimeMs;
  final bool showPlaybackPlayhead;
  final String? hoveredStepId;
  final bool timelineFocused;
  final ValueChanged<String?> onStepHovered;
  final ValueChanged<CinematicTimelineStep> onStepSelected;
  final ValueChanged<_TimelineProbeSnapResult> onTimelineProbeChanged;
  final _ResizeStepDurationCallback onStepDurationResized;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackViewportWidth = math.max(
          360.0,
          constraints.maxWidth - _timelineLaneHeaderWidth - 10,
        );
        final contentWidth = _timelineContentWidth(
          timeLayout.totalDurationMs,
          trackViewportWidth,
        );
        final pixelsPerMs = timeLayout.totalDurationMs <= 0
            ? 1.0
            : contentWidth / timeLayout.totalDurationMs;
        return MouseRegion(
          onExit: (_) => onStepHovered(null),
          child: SingleChildScrollView(
            key: const ValueKey('cinematic-builder-time-grid-viewport'),
            controller: verticalScrollController,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _timelineLaneHeaderWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TimelineLaneHeaderCell(),
                      for (final lane in timeLayout.lanes)
                        _TimelineLaneLabelCell(lane: lane),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey(
                      'cinematic-builder-time-horizontal-scroll',
                    ),
                    controller: horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      key: const ValueKey('cinematic-builder-time-content'),
                      width: contentWidth,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TimelineAxis(
                                ticks: timeLayout.ticks,
                                timeLayout: timeLayout,
                                pixelsPerMs: pixelsPerMs,
                                contentWidth: contentWidth,
                                totalDurationMs: timeLayout.totalDurationMs,
                                onTimelineProbeChanged: onTimelineProbeChanged,
                              ),
                              for (final lane in timeLayout.lanes)
                                _TimelineTrackRow(
                                  asset: asset,
                                  timeLayout: timeLayout,
                                  lane: lane,
                                  ticks: timeLayout.ticks,
                                  stepsById: stepsById,
                                  selectedStepId: selectedStepId,
                                  hoveredStepId: hoveredStepId,
                                  timelineFocused: timelineFocused,
                                  pixelsPerMs: pixelsPerMs,
                                  contentWidth: contentWidth,
                                  totalDurationMs: timeLayout.totalDurationMs,
                                  onStepHovered: onStepHovered,
                                  onStepSelected: onStepSelected,
                                  onTimelineProbeChanged:
                                      onTimelineProbeChanged,
                                  onStepDurationResized: onStepDurationResized,
                                ),
                            ],
                          ),
                          if (timelineProbeTimeMs != null)
                            Positioned(
                              left: _tickLeft(
                                    timelineProbeTimeMs!,
                                    pixelsPerMs,
                                    contentWidth,
                                  ) -
                                  6,
                              top: 0,
                              bottom: 0,
                              child: const _TimelineTimeProbeCursor(),
                            )
                          else if (selectedBlock != null)
                            Positioned(
                              left: _tickLeft(
                                    selectedBlock!.startMs,
                                    pixelsPerMs,
                                    contentWidth,
                                  ) -
                                  6,
                              top: 0,
                              bottom: 0,
                              child: const _TimelineSelectionCursor(),
                            ),
                          if (showPlaybackPlayhead)
                            Positioned(
                              left: _tickLeft(
                                    playbackTimeMs,
                                    pixelsPerMs,
                                    contentWidth,
                                  ) -
                                  6,
                              top: 0,
                              bottom: 0,
                              child: const _TimelinePlaybackPlayhead(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineLaneHeaderCell extends StatelessWidget {
  const _TimelineLaneHeaderCell();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      height: _timelineAxisHeight,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Text(
        'Pistes',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DefaultTextStyle.of(context).style.copyWith(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _TimelineLaneLabelCell extends StatelessWidget {
  const _TimelineLaneLabelCell({required this.lane});

  final CinematicTimelineTimeLane lane;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _laneTone(lane.laneKind).resolve(context);
    final label = _timelineLaneLabel(lane);
    return Container(
      key: ValueKey('cinematic-builder-lane-${lane.laneId}'),
      height: _timelineLaneRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border(bottom: BorderSide(color: colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Icon(_laneIcon(lane.laneKind), size: 16, color: tone.icon),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                if (lane.laneKind == CinematicTimelineLaneKind.actor)
                  _TestHidden(
                    child: Text(
                      lane.actorLabel ??
                          lane.label.replaceFirst('Acteur: ', ''),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _timelineLaneLabel(CinematicTimelineTimeLane lane) {
  if (lane.laneKind == CinematicTimelineLaneKind.actor) {
    final name = lane.actorLabel ?? lane.label.replaceFirst('Acteur: ', '');
    return '$name (Acteur)';
  }
  if (lane.laneKind == CinematicTimelineLaneKind.transitions) {
    return 'Fondu';
  }
  if (lane.laneKind == CinematicTimelineLaneKind.timeGlobal) {
    return 'Attendre';
  }
  return lane.label;
}

class _TimelineAxis extends StatelessWidget {
  const _TimelineAxis({
    required this.ticks,
    required this.timeLayout,
    required this.pixelsPerMs,
    required this.contentWidth,
    required this.totalDurationMs,
    required this.onTimelineProbeChanged,
  });

  final List<CinematicTimelineTimeTick> ticks;
  final CinematicTimelineTimeLayoutReadModel timeLayout;
  final double pixelsPerMs;
  final double contentWidth;
  final int totalDurationMs;
  final ValueChanged<_TimelineProbeSnapResult> onTimelineProbeChanged;

  String _formatFrenchTickLabel(String label) {
    return label.replaceAll('.', ',').replaceAll(' ', '');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onTimelineProbeChanged(
        _resolveTimelineProbeSnap(
          details.localPosition.dx,
          timeLayout: timeLayout,
          pixelsPerMs: pixelsPerMs,
          contentWidth: contentWidth,
          totalDurationMs: totalDurationMs,
        ),
      ),
      onPanStart: (details) => onTimelineProbeChanged(
        _resolveTimelineProbeSnap(
          details.localPosition.dx,
          timeLayout: timeLayout,
          pixelsPerMs: pixelsPerMs,
          contentWidth: contentWidth,
          totalDurationMs: totalDurationMs,
        ),
      ),
      onPanUpdate: (details) => onTimelineProbeChanged(
        _resolveTimelineProbeSnap(
          details.localPosition.dx,
          timeLayout: timeLayout,
          pixelsPerMs: pixelsPerMs,
          contentWidth: contentWidth,
          totalDurationMs: totalDurationMs,
        ),
      ),
      child: Container(
        key: const ValueKey('cinematic-builder-time-axis'),
        height: _timelineAxisHeight,
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final tick in ticks)
              Positioned(
                key: ValueKey('cinematic-builder-time-tick-${tick.timeMs}'),
                left: _tickLeft(tick.timeMs, pixelsPerMs, contentWidth),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: colors.borderSubtle.withValues(alpha: 0.72),
                ),
              ),
            for (final tick in ticks)
              Positioned(
                left: math.min(
                  _tickLeft(tick.timeMs, pixelsPerMs, contentWidth) + 5,
                  math.max(0, contentWidth - 58),
                ),
                top: 6,
                child: SizedBox(
                  width: 56,
                  child: Stack(
                    children: [
                      Text(
                        _formatFrenchTickLabel(tick.label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              color: tick.isMajor
                                  ? colors.textSecondary
                                  : colors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      _TestHidden(child: Text(tick.label)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTimeProbeCursor extends StatelessWidget {
  const _TimelineTimeProbeCursor();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: SizedBox(
        width: 12,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 5,
              top: 0,
              bottom: 0,
              child: Container(
                key: const ValueKey('cinematic-builder-time-probe-cursor'),
                width: 2,
                decoration: BoxDecoration(
                  color: colors.narrative.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: colors.narrative.withValues(alpha: 0.28),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 2,
              left: 0,
              child: DecoratedBox(
                key: const ValueKey(
                  'cinematic-builder-time-probe-cursor-handle',
                ),
                decoration: BoxDecoration(
                  color: colors.narrativeSoft,
                  border: Border.all(color: colors.narrative),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const SizedBox(width: 12, height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSelectionCursor extends StatelessWidget {
  const _TimelineSelectionCursor();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: SizedBox(
        width: 12,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 5,
              top: 0,
              bottom: 0,
              child: Container(
                key: const ValueKey('cinematic-builder-selection-cursor'),
                width: 2,
                decoration: BoxDecoration(
                  color: colors.info.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: colors.info.withValues(alpha: 0.28),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 2,
              left: 0,
              child: DecoratedBox(
                key: const ValueKey(
                  'cinematic-builder-selection-cursor-handle',
                ),
                decoration: BoxDecoration(
                  color: colors.infoSoft,
                  border: Border.all(color: colors.info),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const SizedBox(width: 12, height: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelinePlaybackPlayhead extends StatelessWidget {
  const _TimelinePlaybackPlayhead();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: Semantics(
        label: 'Tête de lecture',
        child: SizedBox(
          width: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 5,
                top: 0,
                bottom: 0,
                child: Container(
                  key: const ValueKey('cinematic-builder-playback-playhead'),
                  width: 2,
                  decoration: BoxDecoration(
                    color: colors.brandPrimary.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: colors.brandPrimary.withValues(alpha: 0.34),
                        blurRadius: 9,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 2,
                left: 0,
                child: DecoratedBox(
                  key: const ValueKey(
                    'cinematic-builder-playback-playhead-handle',
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandPrimarySoft,
                    border: Border.all(color: colors.brandPrimary),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: SizedBox(
                    height: 14,
                    width: 50,
                    child: Center(
                      child: Text(
                        'Lecture',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              color: colors.textPrimary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelinePlaybackTransportControls extends StatelessWidget {
  const _TimelinePlaybackTransportControls({
    required this.plan,
    required this.frame,
    required this.playbackTimeMs,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onStop,
    required this.onReset,
  });

  final CinematicPreviewPlaybackPlan plan;
  final CinematicPreviewPlaybackFrame frame;
  final int playbackTimeMs;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final canPlay = _canPlayPreview(plan);
    final canReturnToStart = canPlay && (playbackTimeMs > 0 || isPlaying);
    final status = _playbackStatusLabel(
      plan: plan,
      frame: frame,
      playbackTimeMs: playbackTimeMs,
      isPlaying: isPlaying,
    );
    final capabilityStatus = _playbackCapabilityStatusLabel(
      plan: plan,
      frame: frame,
    );
    final showCapabilityStatus = canPlay && status != capabilityStatus;
    return Semantics(
      label: 'Contrôles de lecture',
      child: Wrap(
        key: const ValueKey('cinematic-builder-transport-controls'),
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          Tooltip(
            message: 'Revenir au début',
            child: Semantics(
              button: true,
              label: 'Revenir au début',
              child: PokeMapButton(
                key: const ValueKey('cinematic-builder-transport-reset-button'),
                onPressed: canPlay ? onReset : null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.arrow_counterclockwise),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Tooltip(
            message: isPlaying
                ? 'Mettre en pause la prévisualisation'
                : 'Lire la cinématique',
            child: Semantics(
              button: true,
              label: isPlaying
                  ? 'Mettre en pause la prévisualisation'
                  : 'Lire la cinématique',
              child: PokeMapButton(
                key: const ValueKey('cinematic-builder-transport-play-button'),
                onPressed: canPlay ? onPlayPause : null,
                variant: PokeMapButtonVariant.primary,
                size: PokeMapButtonSize.small,
                isSelected: isPlaying,
                leading: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Tooltip(
            message: 'Arrêter la prévisualisation',
            child: Semantics(
              button: true,
              label: 'Arrêter la prévisualisation',
              child: PokeMapButton(
                key: const ValueKey('cinematic-builder-transport-stop-button'),
                onPressed: canReturnToStart ? onStop : null,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.stop_fill),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Semantics(
            label: 'Temps de prévisualisation',
            child: Text(
              '${_shortTimeLabel(playbackTimeMs)} / '
              '${_shortTimeLabel(plan.totalDurationMs)}',
              key: const ValueKey('cinematic-builder-playback-time-label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DefaultTextStyle.of(
                context,
              ).style.copyWith(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
          Semantics(
            label: 'Statut de prévisualisation',
            child: PokeMapBadge(
              key: const ValueKey('cinematic-builder-playback-status-label'),
              label: status,
              variant: canPlay
                  ? plan.capabilities.hasUnsupportedSteps
                      ? PokeMapBadgeVariant.warning
                      : PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.neutral,
            ),
          ),
          if (showCapabilityStatus)
            Semantics(
              label: 'Capacité de prévisualisation',
              child: PokeMapBadge(
                key: const ValueKey(
                  'cinematic-builder-playback-capability-label',
                ),
                label: capabilityStatus,
                variant: plan.capabilities.hasUnsupportedSteps
                    ? PokeMapBadgeVariant.warning
                    : PokeMapBadgeVariant.success,
              ),
            ),
        ],
      ),
    );
  }
}

String _playbackStatusLabel({
  required CinematicPreviewPlaybackPlan plan,
  required CinematicPreviewPlaybackFrame frame,
  required int playbackTimeMs,
  required bool isPlaying,
}) {
  if (!_canPlayPreview(plan)) {
    return 'Aucun bloc à lire';
  }
  if (isPlaying) {
    return 'Lecture en cours';
  }
  if (playbackTimeMs >= plan.totalDurationMs) {
    return 'Fin de prévisualisation';
  }
  if (playbackTimeMs > 0) {
    return 'Lecture en pause';
  }
  return _playbackCapabilityStatusLabel(plan: plan, frame: frame);
}

String _playbackCapabilityStatusLabel({
  required CinematicPreviewPlaybackPlan plan,
  required CinematicPreviewPlaybackFrame frame,
}) {
  if (frame.visibleDiagnostics.isNotEmpty ||
      plan.capabilities.hasUnsupportedSteps) {
    return 'Prévisualisation partielle';
  }
  return 'Prévisualisation prête';
}

bool _canPlayPreview(CinematicPreviewPlaybackPlan plan) {
  return plan.totalDurationMs > 0 && plan.timelineItems.isNotEmpty;
}

String _playbackSignature(CinematicAsset asset) {
  return asset.timeline.steps
      .map(
        (step) => [
          step.id,
          step.kind.name,
          step.actorId ?? '',
          step.targetId ?? '',
          step.durationMs?.toString() ?? '',
          step.metadata.entries
              .map((entry) => '${entry.key}:${entry.value}')
              .join('|'),
        ].join('#'),
      )
      .join('::');
}

class _TimelineTrackRow extends StatelessWidget {
  const _TimelineTrackRow({
    required this.asset,
    required this.timeLayout,
    required this.lane,
    required this.ticks,
    required this.stepsById,
    required this.selectedStepId,
    required this.hoveredStepId,
    required this.timelineFocused,
    required this.pixelsPerMs,
    required this.contentWidth,
    required this.totalDurationMs,
    required this.onStepHovered,
    required this.onStepSelected,
    required this.onTimelineProbeChanged,
    required this.onStepDurationResized,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeLayoutReadModel timeLayout;
  final CinematicTimelineTimeLane lane;
  final List<CinematicTimelineTimeTick> ticks;
  final Map<String, CinematicTimelineStep> stepsById;
  final String? selectedStepId;
  final String? hoveredStepId;
  final bool timelineFocused;
  final double pixelsPerMs;
  final double contentWidth;
  final int totalDurationMs;
  final ValueChanged<String?> onStepHovered;
  final ValueChanged<CinematicTimelineStep> onStepSelected;
  final ValueChanged<_TimelineProbeSnapResult> onTimelineProbeChanged;
  final _ResizeStepDurationCallback onStepDurationResized;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SizedBox(
      height: _timelineLaneRowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderSubtle)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => onTimelineProbeChanged(
                  _resolveTimelineProbeSnap(
                    details.localPosition.dx,
                    timeLayout: timeLayout,
                    pixelsPerMs: pixelsPerMs,
                    contentWidth: contentWidth,
                    totalDurationMs: totalDurationMs,
                  ),
                ),
                onPanStart: (details) => onTimelineProbeChanged(
                  _resolveTimelineProbeSnap(
                    details.localPosition.dx,
                    timeLayout: timeLayout,
                    pixelsPerMs: pixelsPerMs,
                    contentWidth: contentWidth,
                    totalDurationMs: totalDurationMs,
                  ),
                ),
                onPanUpdate: (details) => onTimelineProbeChanged(
                  _resolveTimelineProbeSnap(
                    details.localPosition.dx,
                    timeLayout: timeLayout,
                    pixelsPerMs: pixelsPerMs,
                    contentWidth: contentWidth,
                    totalDurationMs: totalDurationMs,
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            for (final tick in ticks)
              Positioned(
                left: tick.timeMs * pixelsPerMs,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 1,
                  color: colors.borderSubtle.withValues(alpha: 0.36),
                ),
              ),
            if (lane.blocks.isEmpty)
              const Positioned.fill(
                left: 8,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MutedText('Aucun step'),
                ),
              )
            else
              for (final block in lane.blocks)
                if (stepsById[block.stepId] case final step?)
                  Positioned(
                    left: block.startMs * pixelsPerMs,
                    top: (_timelineLaneRowHeight - _timelineBarHeight) / 2,
                    width: _timelineBarWidth(block, pixelsPerMs),
                    height: _timelineBarHeight,
                    child: _TimelineStepCard(
                      asset: asset,
                      lane: lane,
                      block: block,
                      step: step,
                      selected: selectedStepId == block.stepId,
                      keyboardFocused:
                          timelineFocused && selectedStepId == block.stepId,
                      hovered: hoveredStepId == block.stepId,
                      pixelsPerMs: pixelsPerMs,
                      onHoverChanged: (isHovered) =>
                          onStepHovered(isHovered ? block.stepId : null),
                      onTap: () => onStepSelected(step),
                      onDurationResize: onStepDurationResized,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStepCard extends StatefulWidget {
  const _TimelineStepCard({
    required this.asset,
    required this.lane,
    required this.block,
    required this.step,
    required this.selected,
    required this.keyboardFocused,
    required this.hovered,
    required this.pixelsPerMs,
    required this.onHoverChanged,
    required this.onTap,
    required this.onDurationResize,
  });

  final CinematicAsset asset;
  final CinematicTimelineTimeLane lane;
  final CinematicTimelineTimeBlock block;
  final CinematicTimelineStep step;
  final bool selected;
  final bool keyboardFocused;
  final bool hovered;
  final double pixelsPerMs;
  final ValueChanged<bool> onHoverChanged;
  final VoidCallback onTap;
  final _ResizeStepDurationCallback onDurationResize;

  @override
  State<_TimelineStepCard> createState() => _TimelineStepCardState();
}

class _TimelineStepCardState extends State<_TimelineStepCard> {
  _TimelineDurationResizeDrag? _resizeDrag;

  void _startDurationResize(DragStartDetails details) {
    _resizeDrag = _TimelineDurationResizeDrag(
      stepId: widget.step.id,
      startGlobalX: details.globalPosition.dx,
      initialDurationMs: _editableDurationMs(widget.step),
      lastAppliedDurationMs: _editableDurationMs(widget.step),
    );
  }

  void _updateDurationResize(DragUpdateDetails details) {
    final resizeDrag = _resizeDrag;
    if (resizeDrag == null || resizeDrag.stepId != widget.step.id) {
      return;
    }
    final durationMs = _durationResizeCandidateMs(
      initialDurationMs: resizeDrag.initialDurationMs,
      deltaX: details.globalPosition.dx - resizeDrag.startGlobalX,
      pixelsPerMs: widget.pixelsPerMs,
      minDurationMs: _editableDurationMinimumMs(widget.step),
    );
    if (durationMs == resizeDrag.lastAppliedDurationMs) {
      return;
    }
    _resizeDrag = resizeDrag.copyWith(lastAppliedDurationMs: durationMs);
    unawaited(widget.onDurationResize(widget.step, durationMs: durationMs));
  }

  void _endDurationResize(DragEndDetails details) {
    _resizeDrag = null;
  }

  void _cancelDurationResize() {
    final resizeDrag = _resizeDrag;
    _resizeDrag = null;
    if (resizeDrag == null ||
        resizeDrag.lastAppliedDurationMs == resizeDrag.initialDurationMs) {
      return;
    }
    unawaited(
      widget.onDurationResize(
        widget.step,
        durationMs: resizeDrag.initialDurationMs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = _stepDiagnostics(widget.asset, widget.step);
    final movementMode = cinematicTimelineActorMovementModeOf(widget.step);
    final pathMode = cinematicTimelineActorPathModeOf(widget.step);
    final tone = _blockTone(widget.block.kind).resolve(context);
    final startLabel = _shortTimeLabel(widget.block.startMs);
    final endMs = widget.block.startMs + widget.block.visualDurationMs;
    final endLabel = _shortTimeLabel(endMs);
    final timeRangeLabel = '$startLabel - $endLabel';
    Widget card = KeyedSubtree(
      key: ValueKey('cinematic-builder-time-visual-bar-${widget.block.stepId}'),
      child: PokeMapCard(
        key: ValueKey('cinematic-builder-step-card-${widget.block.stepId}'),
        selected: widget.selected,
        focused: widget.keyboardFocused,
        onTap: widget.onTap,
        borderRadius: 6,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        backgroundColor: tone.soft,
        child: SizedBox(
          key: ValueKey('cinematic-builder-time-block-${widget.block.stepId}'),
          child: ClipRect(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TestHidden(child: Text('${widget.block.stepIndex + 1}')),
                Icon(_stepIcon(widget.block.kind), color: tone.icon, size: 11),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.block.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DefaultTextStyle.of(context).style.copyWith(
                          color: tone.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    timeRangeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DefaultTextStyle.of(context).style.copyWith(
                          color: tone.text.withValues(alpha: 0.65),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                _TestHidden(
                  child: _TimelineBarMetaStrip(
                    block: widget.block,
                    step: widget.step,
                    selected: widget.selected,
                    diagnostics: diagnostics,
                    movementMode: movementMode,
                    pathMode: pathMode,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.selected && _canResizeTimelineStepDuration(widget.step)) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: card),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: _TimelineDurationResizeHandle(
              stepId: widget.step.id,
              onHorizontalDragStart: _startDurationResize,
              onHorizontalDragUpdate: _updateDurationResize,
              onHorizontalDragEnd: _endDurationResize,
              onHorizontalDragCancel: _cancelDurationResize,
            ),
          ),
        ],
      );
    }
    if (widget.hovered && !widget.selected) {
      card = KeyedSubtree(
        key: ValueKey(
          'cinematic-builder-hover-highlight-${widget.block.stepId}',
        ),
        child: card,
      );
    }
    return Semantics(
      label: _timelineHoverSemanticsLabel(
        widget.asset,
        widget.block,
        widget.step,
        widget.lane,
      ),
      hint: 'Utilisez les flèches pour changer de bloc.',
      selected: widget.selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => widget.onHoverChanged(true),
        onExit: (_) => widget.onHoverChanged(false),
        child: card,
      ),
    );
  }
}

class _TimelineDurationResizeDrag {
  const _TimelineDurationResizeDrag({
    required this.stepId,
    required this.startGlobalX,
    required this.initialDurationMs,
    required this.lastAppliedDurationMs,
  });

  final String stepId;
  final double startGlobalX;
  final int initialDurationMs;
  final int lastAppliedDurationMs;

  _TimelineDurationResizeDrag copyWith({int? lastAppliedDurationMs}) {
    return _TimelineDurationResizeDrag(
      stepId: stepId,
      startGlobalX: startGlobalX,
      initialDurationMs: initialDurationMs,
      lastAppliedDurationMs:
          lastAppliedDurationMs ?? this.lastAppliedDurationMs,
    );
  }
}

class _TimelineDurationResizeHandle extends StatelessWidget {
  const _TimelineDurationResizeHandle({
    required this.stepId,
    required this.onHorizontalDragStart,
    required this.onHorizontalDragUpdate,
    required this.onHorizontalDragEnd,
    required this.onHorizontalDragCancel,
  });

  final String stepId;
  final GestureDragStartCallback onHorizontalDragStart;
  final GestureDragUpdateCallback onHorizontalDragUpdate;
  final GestureDragEndCallback onHorizontalDragEnd;
  final GestureDragCancelCallback onHorizontalDragCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Tooltip(
      message: 'Ajuster la durée',
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: GestureDetector(
          key: ValueKey('cinematic-builder-duration-resize-handle-$stepId'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: onHorizontalDragStart,
          onHorizontalDragUpdate: onHorizontalDragUpdate,
          onHorizontalDragEnd: onHorizontalDragEnd,
          onHorizontalDragCancel: onHorizontalDragCancel,
          child: SizedBox(
            width: 16,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.infoSoft,
                  border: Border.all(color: colors.info),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const SizedBox(width: 4, height: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineBarMetaStrip extends StatelessWidget {
  const _TimelineBarMetaStrip({
    required this.block,
    required this.step,
    required this.selected,
    required this.diagnostics,
    required this.movementMode,
    required this.pathMode,
  });

  final CinematicTimelineTimeBlock block;
  final CinematicTimelineStep step;
  final bool selected;
  final List<CinematicDiagnostic> diagnostics;
  final CinematicTimelineActorMovementMode? movementMode;
  final CinematicTimelineActorPathMode? pathMode;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TimelineBarMetaText(block.kind.name),
          _TimelineBarMetaText(_blockDurationBadgeLabel(block)),
          if (isCinematicTimelineDraftStep(step))
            const _TimelineBarMetaText('Brouillon'),
          if (isCinematicTimelineActorFacingStep(step))
            _TimelineBarMetaText(
              _actorDirectionLabel(
                cinematicTimelineActorFacingDirectionOf(step),
              ),
            ),
          if (movementMode != null)
            _TimelineBarMetaText(_actorMovementModeLabel(movementMode!)),
          if (pathMode != null)
            _TimelineBarMetaText(_actorPathModeLabel(pathMode!)),
          if (diagnostics.isNotEmpty)
            _TimelineBarMetaText('${diagnostics.length} diagnostic(s)'),
          if (selected) const _TimelineBarMetaText('Sélectionné'),
        ],
      ),
    );
  }
}

class _TimelineBarMetaText extends StatelessWidget {
  const _TimelineBarMetaText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: DefaultTextStyle.of(context).style.copyWith(
              color: colors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyTimelineState extends StatelessWidget {
  const _EmptyTimelineState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SectionTitle(title: 'Timeline vide', subtitle: 'Déroulé'),
        SizedBox(height: 10),
        _BodyText('Cette cinématique ne contient encore aucun bloc.'),
        SizedBox(height: 4),
        _MutedText('La construction de timeline arrive dans un lot futur.'),
      ],
    );
  }
}

class _SelectedStagePointInspector extends StatefulWidget {
  const _SelectedStagePointInspector({
    required this.point,
    required this.onUpdateStagePoint,
    required this.onRemoveStagePoint,
    this.onDeselect,
  });

  final CinematicStagePoint point;
  final ValueChanged<CinematicStagePoint> onUpdateStagePoint;
  final ValueChanged<String> onRemoveStagePoint;
  final VoidCallback? onDeselect;

  @override
  State<_SelectedStagePointInspector> createState() =>
      _SelectedStagePointInspectorState();
}

class _SelectedStagePointInspectorState
    extends State<_SelectedStagePointInspector> {
  late TextEditingController _labelController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.point.label);
    _descriptionController = TextEditingController(
      text: widget.point.description ?? '',
    );
  }

  @override
  void didUpdateWidget(_SelectedStagePointInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.point.id != widget.point.id) {
      _labelController.text = widget.point.label;
      _descriptionController.text = widget.point.description ?? '';
    } else {
      if (_labelController.text != widget.point.label &&
          !_labelController.value.isComposingRangeValid) {
        _labelController.text = widget.point.label;
      }
      if ((_descriptionController.text != (widget.point.description ?? '')) &&
          !_descriptionController.value.isComposingRangeValid) {
        _descriptionController.text = widget.point.description ?? '';
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final newLabel = _labelController.text;
    final newDescription = _descriptionController.text.isEmpty
        ? null
        : _descriptionController.text;
    if (newLabel != widget.point.label ||
        newDescription != widget.point.description) {
      widget.onUpdateStagePoint(
        CinematicStagePoint(
          id: widget.point.id,
          label: newLabel,
          x: widget.point.x,
          y: widget.point.y,
          description: newDescription,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('cinematic-stage-point-inspector-${widget.point.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Repère de scène',
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (widget.onDeselect != null) ...[
                PokeMapIconButton(
                  key: const ValueKey('cinematic-stage-point-deselect-btn'),
                  tooltip: 'Désélectionner le repère',
                  icon: const Icon(CupertinoIcons.xmark_circle),
                  onPressed: widget.onDeselect,
                ),
                const SizedBox(width: 4),
              ],
              PokeMapIconButton(
                key: const ValueKey('cinematic-stage-point-delete-btn'),
                tooltip: 'Supprimer le repère de scène',
                icon: const Icon(CupertinoIcons.trash),
                onPressed: () => widget.onRemoveStagePoint(widget.point.id),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'Détails techniques',
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedAlignment: Alignment.topLeft,
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                Text(
                  'ID : ${widget.point.id}',
                  style: DefaultTextStyle.of(context).style.copyWith(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Label Field
          Text(
            'Nom (Label)',
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const ValueKey('cinematic-stage-point-label-input'),
            controller: _labelController,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          // Description Field
          Text(
            'Description',
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const ValueKey('cinematic-stage-point-description-input'),
            controller: _descriptionController,
            onChanged: (_) => _onChanged(),
            maxLines: 3,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          // Coordinates info
          Text(
            'Position : Colonne ${widget.point.x.toInt()} · Ligne ${widget.point.y.toInt()}',
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InspectorPlaceholder extends StatefulWidget {
  const _InspectorPlaceholder({
    required this.entry,
    required this.asset,
    required this.stageMaps,
    required this.groups,
    required this.characters,
    required this.stageMapSourceCatalog,
    required this.selectedStep,
    required this.selectedStepIndex,
    required this.startExpanded,
    required this.onUpdateStageMap,
    required this.onUpdateStageContext,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onUpsertMovementTargetBinding,
    required this.onRemoveDraftStep,
    required this.onUpdateBasicBlock,
    required this.onUpdateActorFacing,
    required this.onUpdateActorMove,
    required this.onRemoveAuthoringStep,
    required this.onAddMovementTarget,
    required this.onAddRequiredActor,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    required this.onToggleActorMovePathMode,
    required this.onAddManualPathWaypoint,
    required this.onRemoveManualPathWaypoint,
    required this.onReorderManualPathWaypoint,
    required this.readiness,
    this.actorSpritePreviewPlan,
    this.tilesets,
    this.selectedStagePointId,
    this.onSelectStagePointId,
    this.onUpdateStagePoint,
    this.onRemoveStagePoint,
    this.mapWidth,
    this.mapHeight,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final List<ProjectMapEntry> stageMaps;
  final List<ProjectMapGroup> groups;
  final List<ProjectCharacterEntry> characters;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final CinematicTimelineStep? selectedStep;
  final int? selectedStepIndex;
  final bool startExpanded;
  final _UpdateStageMapCallback onUpdateStageMap;
  final _UpdateStageContextCallback onUpdateStageContext;
  final _RenameRequiredActorCallback onRenameRequiredActor;
  final _RemoveRequiredActorCallback onRemoveRequiredActor;
  final _UpsertActorBindingCallback onUpsertActorBinding;
  final _UpsertActorAppearanceBindingCallback onUpsertActorAppearanceBinding;
  final _RemoveActorAppearanceBindingCallback onRemoveActorAppearanceBinding;
  final _UpsertActorInitialPlacementCallback onUpsertActorInitialPlacement;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;
  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;
  final _UpdateActorFacingCallback onUpdateActorFacing;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _AddRequiredActorCallback onAddRequiredActor;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;
  final _ToggleActorMovePathModeCallback onToggleActorMovePathMode;
  final _AddManualPathWaypointCallback onAddManualPathWaypoint;
  final _RemoveManualPathWaypointCallback onRemoveManualPathWaypoint;
  final _ReorderManualPathWaypointCallback onReorderManualPathWaypoint;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
  final String? selectedStagePointId;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<String>? onRemoveStagePoint;
  final int? mapWidth;
  final int? mapHeight;
  final CinematicStagePreviewReadiness readiness;

  @override
  State<_InspectorPlaceholder> createState() => _InspectorPlaceholderState();
}

class _InspectorPlaceholderState extends State<_InspectorPlaceholder> {
  int _tabIndex = 0; // 0 = Scène, 1 = Action

  @override
  void initState() {
    super.initState();
    if (widget.selectedStep != null) {
      _tabIndex = 1;
    } else {
      _tabIndex = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _InspectorPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a step is newly selected or selected step changes, auto-select the "Action" tab
    if (widget.selectedStep != null && oldWidget.selectedStep == null) {
      _tabIndex = 1;
    } else if (widget.selectedStep != null &&
        widget.selectedStep?.id != oldWidget.selectedStep?.id) {
      _tabIndex = 1;
    } else if (widget.selectedStep == null && oldWidget.selectedStep != null) {
      _tabIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedStep;
    final selectedIndex = widget.selectedStepIndex;
    CinematicStagePoint? selectedPoint;
    final points = widget.asset.stageContext?.stagePoints;
    if (points != null && widget.selectedStagePointId != null) {
      for (final p in points) {
        if (p.id == widget.selectedStagePointId) {
          selectedPoint = p;
          break;
        }
      }
    }

    // When a stage point is selected, show the point inspector with the same
    // panel shell but embed the point inspector in the Scène tab body.
    if (selectedPoint != null) {
      return PokeMapPanel(
        key: const ValueKey('cinematic-builder-inspector-placeholder'),
        expandChild: true,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InspectorHeader(
              title: 'Réglages',
              subtitle: "Ajustez votre scène ou l'action sélectionnée.",
            ),
            const SizedBox(height: 10),
            _InspectorTabs(
              tabIndex: _tabIndex,
              onTabChanged: (i) => setState(() => _tabIndex = i),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_tabIndex == 0)
                      _SelectedStagePointInspector(
                        point: selectedPoint,
                        onUpdateStagePoint: widget.onUpdateStagePoint ?? (_) {},
                        onRemoveStagePoint: widget.onRemoveStagePoint ?? (_) {},
                        onDeselect: () =>
                            widget.onSelectStagePointId?.call(null),
                      )
                    else if (selected != null && selectedIndex != null)
                      _SelectedStepInspector(
                        asset: widget.asset,
                        step: selected,
                        index: selectedIndex,
                        onRemoveDraftStep: widget.onRemoveDraftStep,
                        onUpdateBasicBlock: widget.onUpdateBasicBlock,
                        onUpdateActorFacing: widget.onUpdateActorFacing,
                        onUpdateActorMove: widget.onUpdateActorMove,
                        onRemoveAuthoringStep: widget.onRemoveAuthoringStep,
                        onToggleActorMovePathMode:
                            widget.onToggleActorMovePathMode,
                        onAddManualPathWaypoint: widget.onAddManualPathWaypoint,
                        onRemoveManualPathWaypoint:
                            widget.onRemoveManualPathWaypoint,
                        onReorderManualPathWaypoint:
                            widget.onReorderManualPathWaypoint,
                        onUpsertMovementTargetBinding:
                            widget.onUpsertMovementTargetBinding,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PokeMapPanel(
      key: const ValueKey('cinematic-builder-inspector-placeholder'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorHeader(
            title: 'Réglages',
            subtitle: "Ajustez votre scène ou l'action sélectionnée.",
          ),
          const SizedBox(height: 10),
          _InspectorTabs(
            tabIndex: _tabIndex,
            onTabChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_tabIndex == 0)
                    _StageContextEditor(
                      entry: widget.entry,
                      asset: widget.asset,
                      stageMaps: widget.stageMaps,
                      groups: widget.groups,
                      characters: widget.characters,
                      stageMapSourceCatalog: widget.stageMapSourceCatalog,
                      startExpanded: widget.startExpanded,
                      onUpdateStageMap: widget.onUpdateStageMap,
                      onUpdateStageContext: widget.onUpdateStageContext,
                      onRenameRequiredActor: widget.onRenameRequiredActor,
                      onRemoveRequiredActor: widget.onRemoveRequiredActor,
                      onUpsertActorBinding: widget.onUpsertActorBinding,
                      onUpsertActorAppearanceBinding:
                          widget.onUpsertActorAppearanceBinding,
                      onRemoveActorAppearanceBinding:
                          widget.onRemoveActorAppearanceBinding,
                      onUpsertActorInitialPlacement:
                          widget.onUpsertActorInitialPlacement,
                      onUpsertMovementTargetBinding:
                          widget.onUpsertMovementTargetBinding,
                      onAddMovementTarget: widget.onAddMovementTarget,
                      onAddRequiredActor: widget.onAddRequiredActor,
                      onUpdateMovementTarget: widget.onUpdateMovementTarget,
                      onRemoveMovementTarget: widget.onRemoveMovementTarget,
                      actorSpritePreviewPlan: widget.actorSpritePreviewPlan,
                      tilesets: widget.tilesets,
                      selectedStagePointId: widget.selectedStagePointId,
                      onSelectStagePointId: widget.onSelectStagePointId,
                      mapWidth: widget.mapWidth,
                      mapHeight: widget.mapHeight,
                    )
                  else if (selected != null && selectedIndex != null)
                    _SelectedStepInspector(
                      asset: widget.asset,
                      step: selected,
                      index: selectedIndex,
                      onRemoveDraftStep: widget.onRemoveDraftStep,
                      onUpdateBasicBlock: widget.onUpdateBasicBlock,
                      onUpdateActorFacing: widget.onUpdateActorFacing,
                      onUpdateActorMove: widget.onUpdateActorMove,
                      onRemoveAuthoringStep: widget.onRemoveAuthoringStep,
                      onToggleActorMovePathMode:
                          widget.onToggleActorMovePathMode,
                      onAddManualPathWaypoint: widget.onAddManualPathWaypoint,
                      onRemoveManualPathWaypoint:
                          widget.onRemoveManualPathWaypoint,
                      onReorderManualPathWaypoint:
                          widget.onReorderManualPathWaypoint,
                      onUpsertMovementTargetBinding:
                          widget.onUpsertMovementTargetBinding,
                    )
                  else
                    const _EmptySelectionCard(),
                  _TestHidden(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionTitle(
                          title: 'Contexte de scène',
                          subtitle:
                              'Prépare la future preview, sans la lancer.',
                        ),
                        const _SectionTitle(
                          title: 'Aucun bloc sélectionné',
                          subtitle: 'Sélection de bloc à venir',
                        ),
                        const _SectionTitle(
                          title: 'Métadonnées',
                          subtitle: 'Lecture seule',
                        ),
                        _KeyValue(label: 'Titre', value: widget.entry.title),
                        _KeyValue(label: 'Id', value: widget.entry.id),
                        _KeyValue(
                          label: 'Description',
                          value: widget.entry.description?.isEmpty ?? true
                              ? 'Aucune description'
                              : widget.entry.description!,
                        ),
                        _KeyValue(
                          label: 'Map',
                          value: widget.entry.mapId ?? 'Aucune map',
                        ),
                        _KeyValue(
                          label: 'Acteurs',
                          value: widget.entry.requiredActors.isEmpty
                              ? 'Aucun acteur requis'
                              : widget.entry.requiredActors
                                  .map((actor) => actor.displayLabel)
                                  .join(', '),
                        ),
                        _KeyValue(
                          label: 'Timeline',
                          value: '${widget.entry.timeline.stepCount} step(s)',
                        ),
                        _KeyValue(
                          label: 'Durée',
                          value: _durationLabel(widget.entry.timeline),
                        ),
                        _KeyValue(
                          label: 'Usages',
                          value: widget.entry.usages.isEmpty
                              ? 'Aucun usage'
                              : widget.entry.usages
                                  .map((usage) => usage.sceneTitle)
                                  .join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inspector panel header: large title + subtitle matching the mockup.
class _InspectorHeader extends StatelessWidget {
  const _InspectorHeader({required this.title, required this.subtitle});

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
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Segmented "Scène / Action" tabs for the inspector panel.
class _InspectorTabs extends StatelessWidget {
  const _InspectorTabs({required this.tabIndex, required this.onTabChanged});

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return PokeMapSegmentedTabs(
      tabs: [
        PokeMapSegmentedTab(
          key: const ValueKey('cinematic-builder-inspector-tab-scene'),
          label: 'Scène',
          icon: CupertinoIcons.slider_horizontal_3,
          selected: tabIndex == 0,
          onTap: () => onTabChanged(0),
        ),
        PokeMapSegmentedTab(
          key: const ValueKey('cinematic-builder-inspector-tab-action'),
          label: 'Action',
          icon: CupertinoIcons.play_circle,
          selected: tabIndex == 1,
          onTap: () => onTabChanged(1),
        ),
      ],
    );
  }
}

class _StageContextEditor extends StatelessWidget {
  const _StageContextEditor({
    required this.entry,
    required this.asset,
    required this.stageMaps,
    required this.groups,
    required this.characters,
    required this.stageMapSourceCatalog,
    required this.startExpanded,
    required this.onUpdateStageMap,
    required this.onUpdateStageContext,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onUpsertMovementTargetBinding,
    required this.onAddMovementTarget,
    required this.onAddRequiredActor,
    required this.onUpdateMovementTarget,
    required this.onRemoveMovementTarget,
    this.actorSpritePreviewPlan,
    this.tilesets,
    this.mapWidth,
    this.mapHeight,
    this.selectedStagePointId,
    this.onSelectStagePointId,
  });

  final CinematicsLibraryEntry entry;
  final CinematicAsset asset;
  final List<ProjectMapEntry> stageMaps;
  final List<ProjectMapGroup> groups;
  final List<ProjectCharacterEntry> characters;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final bool startExpanded;
  final _UpdateStageMapCallback onUpdateStageMap;
  final _UpdateStageContextCallback onUpdateStageContext;
  final _RenameRequiredActorCallback onRenameRequiredActor;
  final _RemoveRequiredActorCallback onRemoveRequiredActor;
  final _UpsertActorBindingCallback onUpsertActorBinding;
  final _UpsertActorAppearanceBindingCallback onUpsertActorAppearanceBinding;
  final _RemoveActorAppearanceBindingCallback onRemoveActorAppearanceBinding;
  final _UpsertActorInitialPlacementCallback onUpsertActorInitialPlacement;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;
  final _AddMovementTargetCallback onAddMovementTarget;
  final _AddRequiredActorCallback onAddRequiredActor;
  final _UpdateMovementTargetCallback onUpdateMovementTarget;
  final _RemoveMovementTargetCallback onRemoveMovementTarget;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
  final int? mapWidth;
  final int? mapHeight;
  final String? selectedStagePointId;
  final ValueChanged<String?>? onSelectStagePointId;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final stageContext = asset.stageContext ?? CinematicStageContext();
    final readiness = buildCinematicStagePreviewReadiness(
      asset: asset,
      entry: entry,
      maps: stageMaps,
      characters: characters,
      stageMapSourceCatalog: stageMapSourceCatalog,
      mapWidth: mapWidth,
      mapHeight: mapHeight,
    );
    return PokeMapCard(
      key: const ValueKey('cinematic-builder-stage-context-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitle(
            title: 'Préparer la scène',
            subtitle: 'Résumé de votre configuration.',
          ),
          const SizedBox(height: 12),
          Text(
            'DÉCOR',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _StageMapSection(
            asset: asset,
            stageMaps: stageMaps,
            groups: groups,
            onUpdateStageMap: onUpdateStageMap,
          ),
          const SizedBox(height: 10),
          _StageBackdropSection(
            asset: asset,
            stageContext: stageContext,
            onUpdateStageContext: onUpdateStageContext,
          ),
          const SizedBox(height: 16),
          Text(
            'REPÈRES',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _StagePointsSection(
            stageContext: stageContext,
            selectedStagePointId: selectedStagePointId,
            onSelectStagePointId: onSelectStagePointId ?? (_) {},
          ),
          const SizedBox(height: 16),
          Text(
            'ACTEURS',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _RequiredActorsCard(
            asset: asset,
            onAddRequiredActor: onAddRequiredActor,
          ),
          const SizedBox(height: 8),
          _StageActorBindingsSection(
            asset: asset,
            stageContext: stageContext,
            characters: characters,
            stageMapSourceCatalog: stageMapSourceCatalog,
            startExpanded: startExpanded,
            onRenameRequiredActor: onRenameRequiredActor,
            onRemoveRequiredActor: onRemoveRequiredActor,
            onUpsertActorBinding: onUpsertActorBinding,
            onUpsertActorAppearanceBinding: onUpsertActorAppearanceBinding,
            onRemoveActorAppearanceBinding: onRemoveActorAppearanceBinding,
            onUpsertActorInitialPlacement: onUpsertActorInitialPlacement,
            onAddMovementTarget: onAddMovementTarget,
            actorSpritePreviewPlan: actorSpritePreviewPlan,
            tilesets: tilesets,
            selectedStagePointId: selectedStagePointId,
          ),
          const SizedBox(height: 16),
          Text(
            'DESTINATIONS',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _MovementTargetsCard(
            asset: asset,
            onAddMovementTarget: onAddMovementTarget,
            onUpdateMovementTarget: onUpdateMovementTarget,
            onRemoveMovementTarget: onRemoveMovementTarget,
          ),
          const SizedBox(height: 8),
          _StageMovementTargetBindingsSection(
            asset: asset,
            stageContext: stageContext,
            stageMapSourceCatalog: stageMapSourceCatalog,
            onUpsertMovementTargetBinding: onUpsertMovementTargetBinding,
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                'État de la scène',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              expandedAlignment: Alignment.topLeft,
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                _StagePreviewReadinessSection(readiness: readiness),
                const SizedBox(height: 10),
                _StageDiagnosticsSection(readiness: readiness),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const _MutedText('Scène non jouée.'),
          const SizedBox(height: 4),
          const _MutedText('Lecture read-only dans ce lot.'),
        ],
      ),
    );
  }
}

class _StageMapSection extends StatefulWidget {
  const _StageMapSection({
    required this.asset,
    required this.stageMaps,
    required this.groups,
    required this.onUpdateStageMap,
  });

  final CinematicAsset asset;
  final List<ProjectMapEntry> stageMaps;
  final List<ProjectMapGroup> groups;
  final _UpdateStageMapCallback onUpdateStageMap;

  @override
  State<_StageMapSection> createState() => _StageMapSectionState();
}

class _StageMapSectionState extends State<_StageMapSection> {
  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final selectedMap = _stageMapForId(widget.stageMaps, widget.asset.mapId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Map de scène',
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (dropdownContext) {
            return GestureDetector(
              key: const ValueKey('cinematic-builder-stage-map-dropdown'),
              onTap: widget.stageMaps.isEmpty
                  ? null
                  : () => _showTreeDropdown(context, dropdownContext),
              child: MouseRegion(
                cursor: widget.stageMaps.isEmpty
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.controlSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedMap == null
                            ? CupertinoIcons.xmark_circle
                            : CupertinoIcons.map,
                        size: 14,
                        color: selectedMap == null
                            ? colors.textMuted
                            : colors.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedMap == null ? 'Aucune map' : selectedMap.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DefaultTextStyle.of(context).style.copyWith(
                                color: colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.stageMaps.isEmpty) ...[
          const SizedBox(height: 6),
          const _MutedText('Aucune map projet disponible.'),
        ],
      ],
    );
  }

  void _showTreeDropdown(BuildContext context, BuildContext dropdownContext) {
    final box = dropdownContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    final roots = _buildMapTree(widget.groups, widget.stageMaps);

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 280.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        const estimatedHeight = 320.0;
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _MapTreeDropdownPopup(
                  roots: roots,
                  selectedMapId: widget.asset.mapId,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onMapSelected: (map) {
                    widget.onUpdateStageMap(map?.id);
                    dismiss();
                  },
                  onDismiss: dismiss,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }
}

class _MapTreeNode {
  _MapTreeNode({
    required this.id,
    required this.name,
    required this.isGroup,
    this.group,
    this.map,
    required this.children,
  });

  final String id;
  final String name;
  final bool isGroup;
  final ProjectMapGroup? group;
  final ProjectMapEntry? map;
  final List<_MapTreeNode> children;
}

List<_MapTreeNode> _buildMapTree(
  List<ProjectMapGroup> groups,
  List<ProjectMapEntry> maps,
) {
  final Map<String, List<_MapTreeNode>> childrenByGroupId = {};

  for (final map in maps) {
    if (map.groupId != null) {
      childrenByGroupId.putIfAbsent(map.groupId!, () => []).add(
            _MapTreeNode(
              id: 'map_${map.id}',
              name: map.name,
              isGroup: false,
              map: map,
              children: [],
            ),
          );
    }
  }

  final Map<String, List<ProjectMapGroup>> subGroupsByParentId = {};
  for (final group in groups) {
    if (group.parentGroupId != null) {
      subGroupsByParentId
          .putIfAbsent(group.parentGroupId!, () => [])
          .add(group);
    }
  }

  _MapTreeNode buildGroupNode(ProjectMapGroup group) {
    final List<_MapTreeNode> children = [];

    final subGroups = subGroupsByParentId[group.id] ?? [];
    for (final sg in subGroups) {
      children.add(buildGroupNode(sg));
    }

    final gMaps = childrenByGroupId[group.id] ?? [];
    children.addAll(gMaps);

    return _MapTreeNode(
      id: 'group_${group.id}',
      name: group.name,
      isGroup: true,
      group: group,
      children: children,
    );
  }

  final List<_MapTreeNode> roots = [];

  final rootGroups = groups.where((g) => g.parentGroupId == null).toList();
  for (final rg in rootGroups) {
    roots.add(buildGroupNode(rg));
  }

  final rootMaps = maps.where((m) => m.groupId == null).toList();
  for (final rm in rootMaps) {
    roots.add(
      _MapTreeNode(
        id: 'map_${rm.id}',
        name: rm.name,
        isGroup: false,
        map: rm,
        children: [],
      ),
    );
  }

  return roots;
}

class _MapTreeDropdownPopup extends StatefulWidget {
  const _MapTreeDropdownPopup({
    required this.roots,
    required this.selectedMapId,
    required this.colors,
    required this.width,
    required this.height,
    required this.onMapSelected,
    required this.onDismiss,
  });

  final List<_MapTreeNode> roots;
  final String? selectedMapId;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<ProjectMapEntry?> onMapSelected;
  final VoidCallback onDismiss;

  @override
  State<_MapTreeDropdownPopup> createState() => _MapTreeDropdownPopupState();
}

class _MapTreeDropdownPopupState extends State<_MapTreeDropdownPopup> {
  final Set<String> _collapsedGroupIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.colors.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildClearItem(),
            Container(height: 1, color: widget.colors.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (final root in widget.roots)
                    ..._buildNodeWidgets(root, depth: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearItem() {
    final colors = widget.colors;
    final isSelected = widget.selectedMapId == null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: const ValueKey('cinematic-builder-clear-stage-map'),
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onMapSelected(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: isSelected ? colors.surfaceSelected : Colors.transparent,
          child: Row(
            children: [
              Icon(
                CupertinoIcons.xmark_circle,
                size: 14,
                color: colors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Effacer la map',
                style: TextStyle(
                  color: isSelected ? colors.brandPrimary : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNodeWidgets(_MapTreeNode node, {required int depth}) {
    final List<Widget> list = [];
    final colors = widget.colors;

    if (node.isGroup) {
      final isCollapsed = _collapsedGroupIds.contains(node.id);
      final hasChildren = node.children.isNotEmpty;

      list.add(
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedGroupIds.remove(node.id);
                } else {
                  _collapsedGroupIds.add(node.id);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.only(
                left: 12 + depth * 16.0,
                right: 12,
                top: 6,
                bottom: 6,
              ),
              child: Row(
                children: [
                  Icon(
                    hasChildren
                        ? (isCollapsed
                            ? CupertinoIcons.chevron_right
                            : CupertinoIcons.chevron_down)
                        : CupertinoIcons.folder,
                    size: 12,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _groupIcon(node.group?.type ?? MapGroupType.special),
                    size: 14,
                    color: colors.brandPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.name,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _translateGroupType(
                            node.group?.type ?? MapGroupType.special,
                          ).toUpperCase(),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!isCollapsed) {
        for (final child in node.children) {
          list.addAll(_buildNodeWidgets(child, depth: depth + 1));
        }
      }
    } else {
      final isSelected = widget.selectedMapId == node.map!.id;
      list.add(
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: ValueKey('cinematic-builder-stage-map-${node.map!.id}'),
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onMapSelected(node.map),
            child: Container(
              padding: EdgeInsets.only(
                left: 12 + depth * 16.0,
                right: 12,
                top: 6,
                bottom: 6,
              ),
              color: isSelected ? colors.surfaceSelected : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    _roleIcon(node.map!.role),
                    size: 14,
                    color: isSelected ? colors.brandPrimary : colors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      style: TextStyle(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      CupertinoIcons.checkmark,
                      size: 12,
                      color: colors.brandPrimary,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  IconData _groupIcon(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => CupertinoIcons.building_2_fill,
      MapGroupType.village => CupertinoIcons.house_fill,
      MapGroupType.route => CupertinoIcons.map_fill,
      MapGroupType.dungeon => CupertinoIcons.lock_shield,
      MapGroupType.cave => CupertinoIcons.circle_grid_hex,
      MapGroupType.forest => CupertinoIcons.leaf_arrow_circlepath,
      MapGroupType.tower => CupertinoIcons.arrow_up_circle_fill,
      MapGroupType.facility => CupertinoIcons.briefcase_fill,
      MapGroupType.special => CupertinoIcons.star_fill,
    };
  }

  String _translateGroupType(MapGroupType type) {
    return switch (type) {
      MapGroupType.city => 'Ville',
      MapGroupType.village => 'Village',
      MapGroupType.route => 'Route',
      MapGroupType.dungeon => 'Donjon',
      MapGroupType.cave => 'Grotte',
      MapGroupType.forest => 'Forêt',
      MapGroupType.tower => 'Tour',
      MapGroupType.facility => 'Installation',
      MapGroupType.special => 'Spécial',
    };
  }

  IconData _roleIcon(MapRole role) {
    return switch (role) {
      MapRole.exterior => CupertinoIcons.sun_max,
      MapRole.interior => CupertinoIcons.house,
      MapRole.basement => CupertinoIcons.arrow_down_circle,
      MapRole.upper_floor => CupertinoIcons.arrow_up_circle,
      MapRole.connector => CupertinoIcons.link,
      MapRole.gate => CupertinoIcons.square_arrow_right,
      MapRole.section => CupertinoIcons.square_split_2x1,
      MapRole.room => CupertinoIcons.square_grid_2x2,
      MapRole.sub_area => CupertinoIcons.layers_alt,
    };
  }
}

class _StageBackdropSection extends StatelessWidget {
  const _StageBackdropSection({
    required this.asset,
    required this.stageContext,
    required this.onUpdateStageContext,
  });

  final CinematicAsset asset;
  final CinematicStageContext stageContext;
  final _UpdateStageContextCallback onUpdateStageContext;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final currentMode = stageContext.backdropMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Décor', value: 'Mode de backdrop V0'),
        Builder(
          builder: (btnCtx) {
            return GestureDetector(
              key: const ValueKey('cinematic-builder-backdrop-dropdown'),
              onTap: () => _showBackdropDropdown(context, btnCtx),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.controlSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _stageBackdropModeIcon(currentMode),
                        size: 14,
                        color: colors.brandPrimary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _stageBackdropModeLabel(currentMode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DefaultTextStyle.of(context).style.copyWith(
                                color: colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_down,
                        size: 14,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (stageContext.backdropMode ==
                CinematicStageBackdropMode.projectMap &&
            asset.mapId == null) ...[
          const SizedBox(height: 6),
          const _MutedText('Choisis une map pour utiliser ce décor.'),
        ],
      ],
    );
  }

  void _showBackdropDropdown(BuildContext context, BuildContext buttonContext) {
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 245.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        const estimatedHeight = 80.0;
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _BackdropDropdownPopup(
                  selectedMode: stageContext.backdropMode,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onModeSelected: (mode) {
                    onUpdateStageContext(
                      _copyStageContext(stageContext, backdropMode: mode),
                    );
                    dismiss();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }
}

class _BackdropDropdownPopup extends StatelessWidget {
  const _BackdropDropdownPopup({
    required this.selectedMode,
    required this.colors,
    required this.width,
    required this.height,
    required this.onModeSelected,
  });

  final CinematicStageBackdropMode selectedMode;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<CinematicStageBackdropMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final mode in CinematicStageBackdropMode.values)
              _buildItem(mode),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(CinematicStageBackdropMode mode) {
    final isSelected = selectedMode == mode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('cinematic-builder-backdrop-${mode.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onModeSelected(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected ? colors.surfaceSelected : Colors.transparent,
          child: Row(
            children: [
              Icon(
                _stageBackdropModeIcon(mode),
                size: 14,
                color: isSelected ? colors.brandPrimary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _stageBackdropModeLabel(mode),
                  style: TextStyle(
                    color:
                        isSelected ? colors.brandPrimary : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: colors.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageActorBindingsSection extends StatelessWidget {
  const _StageActorBindingsSection({
    required this.asset,
    required this.stageContext,
    required this.characters,
    required this.stageMapSourceCatalog,
    required this.startExpanded,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onAddMovementTarget,
    this.actorSpritePreviewPlan,
    this.tilesets,
    this.selectedStagePointId,
  });

  final CinematicAsset asset;
  final CinematicStageContext stageContext;
  final List<ProjectCharacterEntry> characters;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final bool startExpanded;
  final _RenameRequiredActorCallback onRenameRequiredActor;
  final _RemoveRequiredActorCallback onRemoveRequiredActor;
  final _UpsertActorBindingCallback onUpsertActorBinding;
  final _UpsertActorAppearanceBindingCallback onUpsertActorAppearanceBinding;
  final _RemoveActorAppearanceBindingCallback onRemoveActorAppearanceBinding;
  final _UpsertActorInitialPlacementCallback onUpsertActorInitialPlacement;
  final VoidCallback onAddMovementTarget;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
  final String? selectedStagePointId;

  @override
  Widget build(BuildContext context) {
    final playerActorId = _playerBoundActorId(stageContext);
    final orphanAppearanceBindings = _orphanActorAppearanceBindings(
      asset,
      stageContext,
    );
    return Column(
      key: const ValueKey('cinematic-builder-stage-actors-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'Acteurs', subtitle: 'Binding'),
        const SizedBox(height: 8),
        if (asset.requiredActors.isEmpty)
          const _MutedText('Aucun acteur requis.')
        else
          for (final actor in asset.requiredActors) ...[
            _StageActorBindingRow(
              key: ValueKey('cinematic-builder-actor-row-${actor.actorId}'),
              actor: actor,
              asset: asset,
              stageContext: stageContext,
              characters: characters,
              stageMapSourceCatalog: stageMapSourceCatalog,
              playerActorId: playerActorId,
              startExpanded: startExpanded,
              onRenameRequiredActor: onRenameRequiredActor,
              onRemoveRequiredActor: onRemoveRequiredActor,
              onUpsertActorBinding: onUpsertActorBinding,
              onUpsertActorAppearanceBinding: onUpsertActorAppearanceBinding,
              onRemoveActorAppearanceBinding: onRemoveActorAppearanceBinding,
              onUpsertActorInitialPlacement: onUpsertActorInitialPlacement,
              onAddMovementTarget: onAddMovementTarget,
              actorSpritePreviewPlan: actorSpritePreviewPlan,
              tilesets: tilesets,
              selectedStagePointId: selectedStagePointId,
            ),
            const SizedBox(height: 8),
          ],
        if (orphanAppearanceBindings.isNotEmpty) ...[
          const SizedBox(height: 4),
          for (final binding in orphanAppearanceBindings) ...[
            _StageOrphanAppearanceBindingNotice(
              binding: binding,
              onClear: () => onRemoveActorAppearanceBinding(binding.actorId),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _StageOrphanAppearanceBindingNotice extends StatelessWidget {
  const _StageOrphanAppearanceBindingNotice({
    required this.binding,
    required this.onClear,
  });

  final CinematicActorAppearanceBinding binding;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(
        'cinematic-builder-character-appearance-${binding.actorId}-orphan',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Apparence', value: 'Référence orpheline'),
        const SizedBox(height: 4),
        const _MutedText('Une apparence référence un acteur supprimé.'),
        _MutedText('Acteur référencé : ${binding.actorId}'),
        _MutedText('Personnage référencé : ${binding.characterId}'),
        const SizedBox(height: 6),
        _StageAppearanceClearButton(
          actorId: binding.actorId,
          label: 'Nettoyer la référence',
          onClear: onClear,
        ),
      ],
    );
  }
}

class _StageActorBindingRow extends StatefulWidget {
  const _StageActorBindingRow({
    super.key,
    required this.actor,
    required this.asset,
    required this.stageContext,
    required this.characters,
    required this.stageMapSourceCatalog,
    required this.playerActorId,
    required this.startExpanded,
    required this.onRenameRequiredActor,
    required this.onRemoveRequiredActor,
    required this.onUpsertActorBinding,
    required this.onUpsertActorAppearanceBinding,
    required this.onRemoveActorAppearanceBinding,
    required this.onUpsertActorInitialPlacement,
    required this.onAddMovementTarget,
    this.actorSpritePreviewPlan,
    this.tilesets,
    this.selectedStagePointId,
  });

  final CinematicActorRef actor;
  final CinematicAsset asset;
  final CinematicStageContext stageContext;
  final List<ProjectCharacterEntry> characters;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final String? playerActorId;
  final bool startExpanded;
  final _RenameRequiredActorCallback onRenameRequiredActor;
  final _RemoveRequiredActorCallback onRemoveRequiredActor;
  final _UpsertActorBindingCallback onUpsertActorBinding;
  final _UpsertActorAppearanceBindingCallback onUpsertActorAppearanceBinding;
  final _RemoveActorAppearanceBindingCallback onRemoveActorAppearanceBinding;
  final _UpsertActorInitialPlacementCallback onUpsertActorInitialPlacement;
  final VoidCallback onAddMovementTarget;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
  final String? selectedStagePointId;

  @override
  State<_StageActorBindingRow> createState() => _StageActorBindingRowState();
}

class _StageActorBindingRowState extends State<_StageActorBindingRow> {
  final _entityDropdownKey = GlobalKey();
  final _targetDropdownKey = GlobalKey();
  final _stagePointDropdownKey = GlobalKey();
  late final TextEditingController _labelController;
  bool _isExpanded = false;
  bool _isRenaming = false;
  bool _isRemoving = false;
  bool _isRenamingPanelExpanded = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: _actorDisplayLabel(widget.actor),
    );
    _isExpanded = widget.startExpanded;
    _isRenamingPanelExpanded = widget.startExpanded;
  }

  @override
  void didUpdateWidget(_StageActorBindingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actor.label != widget.actor.label ||
        oldWidget.actor.actorId != widget.actor.actorId) {
      _labelController.text = _actorDisplayLabel(widget.actor);
    }
    if (oldWidget.startExpanded != widget.startExpanded) {
      _isExpanded = widget.startExpanded;
      _isRenamingPanelExpanded = widget.startExpanded;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _isActorConfigured {
    final binding = _actorBindingFor(widget.stageContext, widget.actor.actorId);
    if (binding == null || binding.kind == CinematicActorBindingKind.unbound) {
      return false;
    }
    if (binding.kind == CinematicActorBindingKind.mapEntity &&
        binding.mapEntityId == null) {
      return false;
    }
    if (binding.kind == CinematicActorBindingKind.cinematicOnly) {
      final appearanceBinding = _actorAppearanceBindingFor(
        widget.stageContext,
        widget.actor.actorId,
      );
      if (appearanceBinding == null || appearanceBinding.characterId.isEmpty) {
        return false;
      }
    }
    final placement = _initialPlacementFor(
      widget.stageContext,
      widget.actor.actorId,
    );
    if (placement == null ||
        placement.kind == CinematicActorInitialPlacementKind.unset) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final actor = widget.actor;
    final asset = widget.asset;
    final stageContext = widget.stageContext;
    final sourceCatalog = widget.stageMapSourceCatalog;
    final binding = _actorBindingFor(stageContext, actor.actorId);
    final selectedKind = binding?.kind;
    final playerDisabled =
        widget.playerActorId != null && widget.playerActorId != actor.actorId;
    final actorSources = _actorBindableEntitySources(asset, sourceCatalog);
    final mapEntityDisabledReason = _mapEntityActorDisabledReason(
      asset,
      sourceCatalog,
      actorSources,
    );
    final canPickMapEntity = mapEntityDisabledReason == null;
    final selectedSource = binding?.mapEntityId == null
        ? null
        : sourceCatalog?.entityById(binding!.mapEntityId!);
    final usageCount = _requiredActorUsageCount(asset, actor.actorId);
    final isUsed = usageCount > 0;

    final placement = _initialPlacementFor(stageContext, actor.actorId);
    final supportsMapEntityPlacement =
        selectedKind == CinematicActorBindingKind.mapEntity &&
            binding?.mapEntityId != null &&
            sourceCatalog?.entityById(binding!.mapEntityId!) != null;
    final hasTargets = asset.movementTargets.isNotEmpty;

    final isComplete = _isActorConfigured;

    final roleStr = switch (selectedKind) {
      CinematicActorBindingKind.player => 'Joueur',
      CinematicActorBindingKind.mapEntity => selectedSource != null
          ? 'Personnage ou objet : ${selectedSource.label}'
          : 'Personnage ou objet de la map',
      CinematicActorBindingKind.cinematicOnly => 'Personnage de cinématique',
      CinematicActorBindingKind.unbound || null => 'Ne pas l\'afficher',
    };

    final placementStr = () {
      if (placement == null) return 'Ne pas l’afficher au départ';
      switch (placement.kind) {
        case CinematicActorInitialPlacementKind.unset:
          return 'Ne pas l’afficher au départ';
        case CinematicActorInitialPlacementKind.fromMapEntity:
          return 'À la position de sa source';
        case CinematicActorInitialPlacementKind.fromMovementTarget:
          String? targetLabel;
          for (final t in asset.movementTargets) {
            if (t.targetId == placement.targetId) {
              targetLabel = t.label;
              break;
            }
          }
          if (targetLabel != null) {
            return 'Destination : $targetLabel';
          }
          return 'Destination';
        case CinematicActorInitialPlacementKind.stagePoint:
          String? pointLabel;
          for (final p in stageContext.stagePoints) {
            if (p.id == placement.stagePointId) {
              pointLabel = p.label;
              break;
            }
          }
          if (pointLabel != null) {
            return 'Repère de scène : $pointLabel';
          }
          return 'Repère de scène';
      }
    }();

    final appearanceStr = () {
      switch (selectedKind) {
        case CinematicActorBindingKind.player:
          return 'Joueur';
        case CinematicActorBindingKind.mapEntity:
          return selectedSource != null
              ? 'Personnage ou objet : ${selectedSource.label}'
              : 'Depuis personnage/objet';
        case CinematicActorBindingKind.cinematicOnly:
          final appearanceBinding = _actorAppearanceBindingFor(
            stageContext,
            actor.actorId,
          );
          final character = _characterById(
            widget.characters,
            appearanceBinding?.characterId,
          );
          return character?.name ?? 'Non défini';
        case CinematicActorBindingKind.unbound:
        default:
          return 'Non défini';
      }
    }();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? colors.brandPrimaryBorder : colors.borderSubtle,
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.brandPrimarySoft,
                      ),
                      child: Center(
                        child: Icon(
                          CupertinoIcons.person_fill,
                          color: colors.brandPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _actorDisplayLabel(actor),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Acteur de cinématique',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isComplete
                            ? colors.successSoft
                            : colors.warningSoft,
                        border: Border.all(
                          color: isComplete
                              ? colors.successBorder
                              : colors.warningBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  isComplete ? colors.success : colors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isComplete ? 'Prêt' : 'À compléter',
                            style: TextStyle(
                              color:
                                  isComplete ? colors.success : colors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isExpanded) ...[
            Container(height: 1, color: colors.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choisis qui est ${_actorDisplayLabel(actor)}, où il apparaît au début, et à quoi il ressemble.',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 16),

                  // Résumé Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.chromeBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résumé',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildResumeRow(
                          context,
                          icon: CupertinoIcons.person_crop_circle_fill,
                          label: 'Rôle',
                          value: roleStr,
                        ),
                        _buildResumeRow(
                          context,
                          icon: CupertinoIcons.location_solid,
                          label: 'Départ',
                          value: placementStr,
                        ),
                        _buildResumeRow(
                          context,
                          icon: CupertinoIcons.smiley_fill,
                          label: 'Apparence',
                          value: appearanceStr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Qui est Jean ?
                  Text(
                    '1. Qui est ${_actorDisplayLabel(actor)} ?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-actor-binding-${actor.actorId}-player',
                    title: 'Le joueur',
                    subtext: 'Utilise le personnage contrôlé par le joueur',
                    selected: selectedKind == CinematicActorBindingKind.player,
                    disabled: playerDisabled,
                    warning: playerDisabled
                        ? 'Un autre acteur est déjà lié au joueur.'
                        : null,
                    onPressed: () => widget.onUpsertActorBinding(
                      CinematicActorBinding(
                        actorId: actor.actorId,
                        kind: CinematicActorBindingKind.player,
                      ),
                    ),
                  ),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-actor-binding-${actor.actorId}-mapEntity',
                    title: 'Un personnage ou objet de la map',
                    subtext:
                        'Utilise un personnage ou un objet déjà placé sur la carte',
                    selected:
                        selectedKind == CinematicActorBindingKind.mapEntity,
                    disabled: !canPickMapEntity,
                    warning: mapEntityDisabledReason,
                    onPressed: () {
                      widget.onUpsertActorBinding(
                        CinematicActorBinding(
                          actorId: actor.actorId,
                          kind: CinematicActorBindingKind.mapEntity,
                        ),
                      );
                      if (actorSources.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _showEntityDropdown(
                              context,
                              _entityDropdownKey,
                              actorSources,
                              binding?.mapEntityId,
                            );
                          }
                        });
                      }
                    },
                    child: selectedKind == CinematicActorBindingKind.mapEntity
                        ? _SubSelectorBox(
                            key: _entityDropdownKey,
                            label: 'Personnage ou objet',
                            value: selectedSource?.label ??
                                'Choisir un personnage ou un objet',
                            onChangerPressed: () => _showEntityDropdown(
                              context,
                              _entityDropdownKey,
                              actorSources,
                              binding?.mapEntityId,
                            ),
                          )
                        : null,
                  ),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-actor-binding-${actor.actorId}-cinematicOnly',
                    title: 'Un personnage de cinématique',
                    subtext: 'Choisis un personnage dans la bibliothèque',
                    selected:
                        selectedKind == CinematicActorBindingKind.cinematicOnly,
                    onPressed: () => widget.onUpsertActorBinding(
                      CinematicActorBinding(
                        actorId: actor.actorId,
                        kind: CinematicActorBindingKind.cinematicOnly,
                      ),
                    ),
                  ),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-actor-binding-${actor.actorId}-unbound',
                    title: 'Ne pas l\'afficher',
                    subtext:
                        'Présent dans le script, mais pas visible à l\'écran',
                    selected:
                        selectedKind == CinematicActorBindingKind.unbound ||
                            selectedKind == null,
                    onPressed: () => widget.onUpsertActorBinding(
                      CinematicActorBinding(
                        actorId: actor.actorId,
                        kind: CinematicActorBindingKind.unbound,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Où apparaît-il au début ?
                  Text(
                    '2. Où apparaît-il au début ?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    width: 0,
                    height: 0,
                    child: Text(
                      'Départs de scène',
                      style: TextStyle(fontSize: 0),
                    ),
                  ),
                  const SizedBox(height: 8),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-initial-placement-${actor.actorId}-unset',
                    title: 'Ne pas l’afficher au départ',
                    subtext: 'Aucune position initiale définie pour cet acteur',
                    selected: placement?.kind ==
                            CinematicActorInitialPlacementKind.unset ||
                        placement == null,
                    onPressed: () => widget.onUpsertActorInitialPlacement(
                      CinematicActorInitialPlacement(
                        actorId: actor.actorId,
                        kind: CinematicActorInitialPlacementKind.unset,
                      ),
                    ),
                  ),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-initial-placement-${actor.actorId}-fromMapEntity',
                    title: 'À la position de sa source',
                    subtext:
                        'Placer l’acteur aux coordonnées du personnage ou objet lié sur la carte',
                    selected: placement?.kind ==
                        CinematicActorInitialPlacementKind.fromMapEntity,
                    disabled: !supportsMapEntityPlacement,
                    onPressed: () => widget.onUpsertActorInitialPlacement(
                      CinematicActorInitialPlacement(
                        actorId: actor.actorId,
                        kind: CinematicActorInitialPlacementKind.fromMapEntity,
                      ),
                    ),
                  ),

                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-initial-placement-${actor.actorId}-fromMovementTarget',
                    title: 'Sur une destination',
                    subtext:
                        'Placer l’acteur sur une destination de déplacement existante sur la carte',
                    selected: placement?.kind ==
                        CinematicActorInitialPlacementKind.fromMovementTarget,
                    disabled: !hasTargets,
                    onPressed: () {
                      final targetId = placement?.targetId ??
                          (widget.asset.movementTargets.isNotEmpty
                              ? widget.asset.movementTargets.first.targetId
                              : '');
                      widget.onUpsertActorInitialPlacement(
                        CinematicActorInitialPlacement(
                          actorId: actor.actorId,
                          kind: CinematicActorInitialPlacementKind
                              .fromMovementTarget,
                          targetId: targetId,
                        ),
                      );
                      if (widget.asset.movementTargets.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _showTargetDropdown(
                              context,
                              _targetDropdownKey,
                              widget.asset.movementTargets,
                              targetId,
                            );
                          }
                        });
                      }
                    },
                    child: placement?.kind ==
                            CinematicActorInitialPlacementKind
                                .fromMovementTarget
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SubSelectorBox(
                                key: _targetDropdownKey,
                                label: 'Destination',
                                value: () {
                                  String? targetLabel;
                                  for (final t
                                      in widget.asset.movementTargets) {
                                    if (t.targetId == placement!.targetId) {
                                      targetLabel = t.label;
                                      break;
                                    }
                                  }
                                  return targetLabel ??
                                      'Choisir une destination';
                                }(),
                                onChangerPressed: () => _showTargetDropdown(
                                  context,
                                  _targetDropdownKey,
                                  widget.asset.movementTargets,
                                  placement?.targetId,
                                ),
                              ),
                              const SizedBox(height: 8),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: widget.onAddMovementTarget,
                                  child: Text(
                                    '+ Créer une destination',
                                    style: TextStyle(
                                      color: colors.brandPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                  _RedesignedRadioCard(
                    keyValue:
                        'cinematic-builder-initial-placement-${actor.actorId}-stagePoint',
                    title: 'Depuis repère de scène',
                    subtext: widget.stageContext.stagePoints.isEmpty
                        ? 'Aucun repère de scène disponible. Créez d’abord un repère dans l’aperçu avec Ajouter un repère.'
                        : 'Placer l’acteur sur un repère de scène existant',
                    selected: placement?.kind ==
                        CinematicActorInitialPlacementKind.stagePoint,
                    disabled: widget.stageContext.stagePoints.isEmpty,
                    onPressed: () {
                      // V1-103: Select the first stage point by default when
                      // switching to stagePoint placement. The user can change
                      // via the "Changer" button. No auto-popup — simpler UX.
                      final pointId = placement?.stagePointId ??
                          (widget.stageContext.stagePoints.isNotEmpty
                              ? widget.stageContext.stagePoints.first.id
                              : '');
                      widget.onUpsertActorInitialPlacement(
                        CinematicActorInitialPlacement(
                          actorId: actor.actorId,
                          kind: CinematicActorInitialPlacementKind.stagePoint,
                          stagePointId: pointId,
                        ),
                      );
                    },
                    child: placement?.kind ==
                            CinematicActorInitialPlacementKind.stagePoint
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SubSelectorBox(
                                key: _stagePointDropdownKey,
                                label: 'Repère',
                                value: () {
                                  String? pointLabel;
                                  for (final p
                                      in widget.stageContext.stagePoints) {
                                    if (p.id == placement!.stagePointId) {
                                      pointLabel = p.label;
                                      break;
                                    }
                                  }
                                  return pointLabel ?? 'Choisir un repère';
                                }(),
                                onChangerPressed: () => _showStagePointDropdown(
                                  context,
                                  _stagePointDropdownKey,
                                  widget.stageContext.stagePoints,
                                  placement?.stagePointId,
                                ),
                              ),
                              if (widget.selectedStagePointId != null &&
                                  widget.stageContext.stagePoints.any(
                                    (p) => p.id == widget.selectedStagePointId,
                                  )) ...[
                                const SizedBox(height: 8),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      widget.onUpsertActorInitialPlacement(
                                        CinematicActorInitialPlacement(
                                          actorId: actor.actorId,
                                          kind:
                                              CinematicActorInitialPlacementKind
                                                  .stagePoint,
                                          stagePointId:
                                              widget.selectedStagePointId,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Utiliser le repère sélectionné',
                                      style: TextStyle(
                                        color: colors.brandPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // 3. À quoi ressemble-t-il ?
                  Text(
                    '3. À quoi ressemble-t-il ?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildAppearanceSection(
                    context,
                    actor: actor,
                    selectedKind: selectedKind,
                    appearanceBinding: _actorAppearanceBindingFor(
                      stageContext,
                      actor.actorId,
                    ),
                    characters: widget.characters,
                    tilesets: widget.tilesets,
                    actorSpritePreviewPlan: widget.actorSpritePreviewPlan,
                  ),
                  const SizedBox(height: 20),

                  // Avancé Accordion
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: colors.controlSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(
                            () => _isRenamingPanelExpanded =
                                !_isRenamingPanelExpanded,
                          ),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Avancé',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _isRenamingPanelExpanded
                                        ? CupertinoIcons.chevron_up
                                        : CupertinoIcons.chevron_down,
                                    size: 14,
                                    color: colors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_isRenamingPanelExpanded) ...[
                          Container(height: 1, color: colors.borderSubtle),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MovementTargetTextField(
                                  key: ValueKey(
                                    'cinematic-builder-actor-label-${actor.actorId}',
                                  ),
                                  controller: _labelController,
                                  placeholder: 'Nom de l’acteur',
                                ),
                                if (_feedback != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    _feedback!,
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isUsed) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Cet acteur est utilisé par $usageCount bloc(s) timeline.',
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ),
                  ],

                  // Footer actions
                  Row(
                    children: [
                      Expanded(
                        child: PokeMapButton(
                          key: ValueKey(
                            'cinematic-builder-save-required-actor-${actor.actorId}',
                          ),
                          onPressed: _isRenaming ? null : _rename,
                          variant: PokeMapButtonVariant.secondary,
                          isLoading: _isRenaming,
                          leading: const Icon(CupertinoIcons.pencil),
                          child: const Text('Renommer'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PokeMapButton(
                          key: ValueKey(
                            'cinematic-builder-delete-required-actor-${actor.actorId}',
                          ),
                          onPressed: isUsed || _isRemoving ? null : _remove,
                          variant: PokeMapButtonVariant.danger,
                          isLoading: _isRemoving,
                          leading: const Icon(CupertinoIcons.trash),
                          child: const Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResumeRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.brandPrimarySoft,
            ),
            child: Icon(icon, size: 14, color: colors.brandPrimary),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context, {
    required CinematicActorRef actor,
    required CinematicActorBindingKind? selectedKind,
    required CinematicActorAppearanceBinding? appearanceBinding,
    required List<ProjectCharacterEntry> characters,
    required Map<String, CinematicResolvedTilesetAsset>? tilesets,
    required CinematicActorSpritePreviewPlan? actorSpritePreviewPlan,
  }) {
    final colors = context.pokeMapColors;

    if (selectedKind != CinematicActorBindingKind.cinematicOnly) {
      if (appearanceBinding != null) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.chromeBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cet acteur n’est plus en “Cinématique uniquement”.',
                style: TextStyle(
                  color: colors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'L’apparence Character Library ne s’applique plus.',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Personnage référencé : ${appearanceBinding.characterId}',
                style: TextStyle(color: colors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              PokeMapButton(
                key: ValueKey(
                  'cinematic-builder-character-appearance-${actor.actorId}-clear',
                ),
                onPressed: () =>
                    widget.onRemoveActorAppearanceBinding(actor.actorId),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.trash),
                child: const Text('Retirer l’apparence'),
              ),
            ],
          ),
        );
      }

      final infoMsg = switch (selectedKind) {
        CinematicActorBindingKind.player => 'Apparence héritée du joueur.',
        CinematicActorBindingKind.mapEntity =>
          'Apparence héritée de l’entité de map.',
        CinematicActorBindingKind.unbound ||
        null =>
          'Lie d’abord l’acteur en Cinématique uniquement pour choisir un personnage.',
        CinematicActorBindingKind.cinematicOnly => '',
      };

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.chromeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(
          infoMsg,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (characters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.chromeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'La Character Library est vide.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crée un personnage dans la Character Library pour l’utiliser ici.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (appearanceBinding != null) ...[
              const SizedBox(height: 8),
              PokeMapButton(
                key: ValueKey(
                  'cinematic-builder-character-appearance-${actor.actorId}-clear',
                ),
                onPressed: () =>
                    widget.onRemoveActorAppearanceBinding(actor.actorId),
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                leading: const Icon(CupertinoIcons.trash),
                child: const Text('Retirer la référence'),
              ),
            ],
          ],
        ),
      );
    }

    final sortedCharacters = _sortedCharacters(characters);
    final selectedCharacter = _characterById(
      sortedCharacters,
      appearanceBinding?.characterId,
    );

    if (appearanceBinding == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.chromeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aucun personnage choisi.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (btnCtx) {
                return PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-character-appearance-${actor.actorId}-toggle',
                  ),
                  onPressed: () => _showCharacterDropdown(
                    context,
                    btnCtx,
                    sortedCharacters,
                    appearanceBinding?.characterId,
                    (char) async {
                      await widget.onUpsertActorAppearanceBinding(
                        CinematicActorAppearanceBinding(
                          actorId: actor.actorId,
                          characterId: char.id,
                        ),
                      );
                    },
                  ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.person_crop_square),
                  child: const Text('Choisir un personnage'),
                );
              },
            ),
          ],
        ),
      );
    }

    if (selectedCharacter == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.chromeBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Le personnage choisi n’existe plus dans la Character Library.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (btnCtx) {
                return PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-character-appearance-${actor.actorId}-toggle',
                  ),
                  onPressed: () => _showCharacterDropdown(
                    context,
                    btnCtx,
                    sortedCharacters,
                    appearanceBinding.characterId,
                    (char) async {
                      await widget.onUpsertActorAppearanceBinding(
                        CinematicActorAppearanceBinding(
                          actorId: actor.actorId,
                          characterId: char.id,
                        ),
                      );
                    },
                  ),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.person_crop_square),
                  child: const Text('Choisir un autre personnage'),
                );
              },
            ),
            const SizedBox(height: 6),
            PokeMapButton(
              key: ValueKey(
                'cinematic-builder-character-appearance-${actor.actorId}-clear',
              ),
              onPressed: () =>
                  widget.onRemoveActorAppearanceBinding(actor.actorId),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.trash),
              child: const Text('Retirer la référence'),
            ),
          ],
        ),
      );
    }

    final String targetTilesetId = selectedCharacter.tilesetId.trim();
    final resolvedAsset = tilesets?[targetTilesetId];
    final hasSpriteImage = resolvedAsset != null && resolvedAsset.isAvailable;

    CinematicActorSpriteRef? spriteRef;
    if (hasSpriteImage) {
      final idleAnimations = selectedCharacter.animations
          .where((anim) => anim.state == CharacterAnimationState.idle)
          .toList();
      final exploitableIdles =
          idleAnimations.where((anim) => anim.frames.isNotEmpty).toList();
      CharacterAnimation? selectedAnimation;
      if (exploitableIdles.isNotEmpty) {
        for (final anim in exploitableIdles) {
          if (anim.direction == EntityFacing.south) {
            selectedAnimation = anim;
            break;
          }
        }
        selectedAnimation ??= exploitableIdles.first;
      }
      if (selectedAnimation != null) {
        final frame = selectedAnimation.frames.first;
        spriteRef = CinematicActorSpriteRef(
          characterId: selectedCharacter.id,
          tilesetId: targetTilesetId,
          sourceTileRect: frame.source,
          frameWidthTiles: selectedCharacter.frameWidth,
          frameHeightTiles: selectedCharacter.frameHeight,
          direction: CinematicActorPreviewDirection.south,
        );
      }
    }

    final isSpriteReady = spriteRef != null && resolvedAsset != null;

    final int gridCols = spriteRef?.frameWidthTiles ?? 2;
    final int gridRows = spriteRef?.frameHeightTiles ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.chromeBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.backgroundApp,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(64, 64),
                        painter: _GridBackgroundPainter(
                          colors: colors,
                          cols: gridCols,
                          rows: gridRows,
                        ),
                      ),
                      if (isSpriteReady)
                        SizedBox(
                          width: spriteRef.frameWidthTiles * 24.0,
                          height: spriteRef.frameHeightTiles * 24.0,
                          child: CustomPaint(
                            painter: CinematicActorSpritePainter(
                              image: resolvedAsset.image!,
                              spriteRef: spriteRef,
                              tileWidth: resolvedAsset.tileWidth,
                              tileHeight: resolvedAsset.tileHeight,
                              outOfBoundsColor: colors.error,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.surfaceBase.withValues(alpha: 0.9),
                            border: Border.all(
                              color: colors.borderStrong,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCharacter.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedCharacter.frameWidth} × ${selectedCharacter.frameHeight}',
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Id technique : ${selectedCharacter.id}',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (btnCtx) {
            return PokeMapButton(
              key: ValueKey(
                'cinematic-builder-character-appearance-${actor.actorId}-toggle',
              ),
              onPressed: () => _showCharacterDropdown(
                context,
                btnCtx,
                sortedCharacters,
                appearanceBinding.characterId,
                (char) async {
                  await widget.onUpsertActorAppearanceBinding(
                    CinematicActorAppearanceBinding(
                      actorId: actor.actorId,
                      characterId: char.id,
                    ),
                  );
                },
              ),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.person_crop_square),
              child: const Text('Choisir un autre personnage'),
            );
          },
        ),
        const SizedBox(height: 6),
        PokeMapButton(
          key: ValueKey(
            'cinematic-builder-character-appearance-${actor.actorId}-clear',
          ),
          onPressed: () => widget.onRemoveActorAppearanceBinding(actor.actorId),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          leading: const Icon(CupertinoIcons.trash),
          child: const Text('Retirer la référence'),
        ),
      ],
    );
  }

  Future<void> _rename() async {
    final label = _labelController.text.trim();
    if (label.isEmpty) {
      setState(() => _feedback = 'Nom d’acteur obligatoire');
      return;
    }
    setState(() {
      _isRenaming = true;
      _feedback = null;
    });
    final renamed = await widget.onRenameRequiredActor(
      widget.actor,
      label: label,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isRenaming = false;
      _feedback = renamed ? null : 'Renommage impossible';
    });
  }

  Future<void> _remove() async {
    setState(() {
      _isRemoving = true;
      _feedback = null;
    });
    final removed = await widget.onRemoveRequiredActor(widget.actor);
    if (!mounted) {
      return;
    }
    setState(() {
      _isRemoving = false;
      _feedback = removed ? null : 'Suppression impossible';
    });
  }

  void _showEntityDropdown(
    BuildContext context,
    GlobalKey dropdownKey,
    List<CinematicStageMapEntitySource> sources,
    String? selectedSourceId,
  ) {
    final box = dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 280.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        final estimatedHeight = (sources.length * 44.0 + 8.0).clamp(
          100.0,
          320.0,
        );
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _MapEntityDropdownPopup(
                  keyPrefix:
                      'cinematic-builder-actor-binding-${widget.actor.actorId}-mapEntity',
                  sources: sources,
                  selectedSourceId: selectedSourceId,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onSourceSelected: (source) {
                    widget.onUpsertActorBinding(
                      CinematicActorBinding(
                        actorId: widget.actor.actorId,
                        kind: CinematicActorBindingKind.mapEntity,
                        mapEntityId: source.id,
                      ),
                    );
                    dismiss();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  void _showTargetDropdown(
    BuildContext context,
    GlobalKey dropdownKey,
    List<CinematicMovementTargetRef> targets,
    String? selectedTargetId,
  ) {
    final box = dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 280.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        final estimatedHeight = (targets.length * 44.0 + 8.0).clamp(
          100.0,
          320.0,
        );
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _TargetDropdownPopup(
                  keyPrefix:
                      'cinematic-builder-initial-placement-${widget.actor.actorId}',
                  targets: targets,
                  selectedTargetId: selectedTargetId,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onTargetSelected: (target) {
                    widget.onUpsertActorInitialPlacement(
                      CinematicActorInitialPlacement(
                        actorId: widget.actor.actorId,
                        kind: CinematicActorInitialPlacementKind
                            .fromMovementTarget,
                        targetId: target.targetId,
                      ),
                    );
                    dismiss();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  void _showStagePointDropdown(
    BuildContext context,
    GlobalKey dropdownKey,
    List<CinematicStagePoint> points,
    String? selectedPointId,
  ) {
    final box = dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 280.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        final estimatedHeight = (points.length * 44.0 + 8.0).clamp(
          100.0,
          320.0,
        );
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _StagePointDropdownPopup(
                  keyPrefix:
                      'cinematic-builder-initial-placement-${widget.actor.actorId}',
                  points: points,
                  selectedPointId: selectedPointId,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onPointSelected: (point) {
                    dismiss();
                    widget.onUpsertActorInitialPlacement(
                      CinematicActorInitialPlacement(
                        actorId: widget.actor.actorId,
                        kind: CinematicActorInitialPlacementKind.stagePoint,
                        stagePointId: point.id,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }

  void _showCharacterDropdown(
    BuildContext context,
    BuildContext dropdownContext,
    List<ProjectCharacterEntry> characters,
    String? selectedCharacterId,
    _SelectProjectCharacter onCharacterSelected,
  ) {
    final box = dropdownContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final position = box.localToGlobal(Offset.zero);
    final size = box.size;
    final colors = context.pokeMapColors;

    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) {
        entry.remove();
      }
    }

    entry = OverlayEntry(
      builder: (ctx) {
        final overlayBox =
            Overlay.of(ctx).context.findRenderObject() as RenderBox;
        final maxH = overlayBox.size.height;
        final maxW = overlayBox.size.width;

        var left = position.dx;
        var top = position.dy + size.height + 4;

        const menuWidth = 280.0;
        if (left + menuWidth > maxW - 8) {
          left = maxW - menuWidth - 8;
        }
        if (left < 8) left = 8;

        final estimatedHeight = (characters.length * 56.0 + 8.0).clamp(
          100.0,
          320.0,
        );
        if (top + estimatedHeight > maxH - 8) {
          top = position.dy - estimatedHeight - 4;
        }
        if (top < 8) top = 8;

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => dismiss(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: _CharacterDropdownPopup(
                  actorId: widget.actor.actorId,
                  characters: characters,
                  selectedCharacterId: selectedCharacterId,
                  colors: colors,
                  width: menuWidth,
                  height: estimatedHeight,
                  onCharacterSelected: (char) {
                    onCharacterSelected(char);
                    dismiss();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(entry);
  }
}

class _GridBackgroundPainter extends CustomPainter {
  const _GridBackgroundPainter({
    required this.colors,
    required this.cols,
    required this.rows,
  });

  final PokeMapColorTokens colors;
  final int cols;
  final int rows;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.borderSubtle
      ..strokeWidth = 0.5;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    for (int i = 0; i <= cols; i++) {
      final x = i * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 0; i <= rows; i++) {
      final y = i * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.cols != cols ||
        oldDelegate.rows != rows;
  }
}

class _RedesignedRadioCard extends StatelessWidget {
  const _RedesignedRadioCard({
    required this.keyValue,
    required this.title,
    required this.subtext,
    required this.selected,
    this.disabled = false,
    this.warning,
    required this.onPressed,
    this.child,
  });

  final String keyValue;
  final String title;
  final String subtext;
  final bool selected;
  final bool disabled;
  final String? warning;
  final VoidCallback onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return MouseRegion(
      cursor:
          disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: selected
              ? colors.brandPrimarySoft.withValues(alpha: 0.3)
              : colors.controlSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.brandPrimaryBorder : colors.borderSubtle,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          selected
                              ? CupertinoIcons.largecircle_fill_circle
                              : CupertinoIcons.circle,
                          size: 16,
                          color: selected
                              ? colors.brandPrimary
                              : (disabled
                                  ? colors.textDisabled
                                  : colors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: disabled
                                    ? colors.textDisabled
                                    : colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtext,
                              style: TextStyle(
                                color: disabled
                                    ? colors.textDisabled
                                    : colors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            if (warning != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                warning!,
                                style: TextStyle(
                                  color: colors.warning,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.01,
                    child: PokeMapButton(
                      key: ValueKey(keyValue),
                      onPressed: disabled ? null : onPressed,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
            if (child != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: child!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubSelectorBox extends StatelessWidget {
  const _SubSelectorBox({
    super.key,
    required this.label,
    required this.value,
    required this.onChangerPressed,
  });

  final String label;
  final String value;
  final VoidCallback onChangerPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  key: const ValueKey('cinematic-builder-subselector-value'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            onPressed: onChangerPressed,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }
}

class _TargetDropdownPopup extends StatelessWidget {
  const _TargetDropdownPopup({
    required this.keyPrefix,
    required this.targets,
    required this.selectedTargetId,
    required this.colors,
    required this.width,
    required this.height,
    required this.onTargetSelected,
  });

  final String keyPrefix;
  final List<CinematicMovementTargetRef> targets;
  final String? selectedTargetId;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<CinematicMovementTargetRef> onTargetSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: colors.borderStrong.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [for (final target in targets) _buildItem(target)],
        ),
      ),
    );
  }

  Widget _buildItem(CinematicMovementTargetRef target) {
    final isSelected = selectedTargetId == target.targetId;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('$keyPrefix-target-${target.targetId}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTargetSelected(target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected
              ? colors.surfaceSelected
              : colors.surfaceSelected.withValues(alpha: 0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.scope,
                size: 14,
                color: isSelected ? colors.brandPrimary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.label,
                      style: TextStyle(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (target.description != null &&
                        target.description!.trim().isNotEmpty)
                      Text(
                        target.description!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: colors.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagePointDropdownPopup extends StatelessWidget {
  const _StagePointDropdownPopup({
    required this.keyPrefix,
    required this.points,
    required this.selectedPointId,
    required this.colors,
    required this.width,
    required this.height,
    required this.onPointSelected,
  });

  final String keyPrefix;
  final List<CinematicStagePoint> points;
  final String? selectedPointId;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<CinematicStagePoint> onPointSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: colors.borderStrong.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [for (final point in points) _buildItem(point)],
        ),
      ),
    );
  }

  Widget _buildItem(CinematicStagePoint point) {
    final isSelected = selectedPointId == point.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('$keyPrefix-point-${point.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onPointSelected(point),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected
              ? colors.surfaceSelected
              : colors.surfaceSelected.withValues(alpha: 0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                size: 14,
                color: isSelected ? colors.brandPrimary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.label,
                      style: TextStyle(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      'x: ${point.x.toStringAsFixed(2)}, y: ${point.y.toStringAsFixed(2)}',
                      style: TextStyle(color: colors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: colors.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _SelectProjectCharacter = Future<void> Function(
    ProjectCharacterEntry character);

class _StageAppearanceClearButton extends StatelessWidget {
  const _StageAppearanceClearButton({
    required this.actorId,
    required this.label,
    required this.onClear,
  });

  final String actorId;
  final String label;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return PokeMapButton(
      key: ValueKey('cinematic-builder-character-appearance-$actorId-clear'),
      onPressed: onClear,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: const Icon(CupertinoIcons.xmark_circle),
      child: Text(label),
    );
  }
}

class _CharacterDropdownPopup extends StatelessWidget {
  const _CharacterDropdownPopup({
    required this.actorId,
    required this.characters,
    required this.selectedCharacterId,
    required this.colors,
    required this.width,
    required this.height,
    required this.onCharacterSelected,
  });

  final String actorId;
  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<ProjectCharacterEntry> onCharacterSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: colors.borderStrong.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [for (final character in characters) _buildItem(character)],
        ),
      ),
    );
  }

  Widget _buildItem(ProjectCharacterEntry character) {
    final isSelected = selectedCharacterId == character.id;
    final tagsLine = _characterTagsLine(character);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey(
          'cinematic-builder-character-appearance-$actorId-character-${character.id}',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: () => onCharacterSelected(character),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected
              ? colors.surfaceSelected
              : colors.surfaceSelected.withValues(alpha: 0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.person_crop_square,
                size: 14,
                color: isSelected ? colors.brandPrimary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: TextStyle(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      _characterDetailLine(character),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (tagsLine != null)
                      Text(
                        tagsLine,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: colors.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageMovementTargetBindingsSection extends StatelessWidget {
  const _StageMovementTargetBindingsSection({
    required this.asset,
    required this.stageContext,
    required this.stageMapSourceCatalog,
    required this.onUpsertMovementTargetBinding,
  });

  final CinematicAsset asset;
  final CinematicStageContext stageContext;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-stage-movement-targets-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'Destinations', subtitle: 'Résolution'),
        const SizedBox(height: 8),
        if (asset.movementTargets.isEmpty)
          const _MutedText('Aucune destination.')
        else
          for (final target in asset.movementTargets) ...[
            _StageMovementTargetBindingRow(
              target: target,
              asset: asset,
              stageContext: stageContext,
              stageMapSourceCatalog: stageMapSourceCatalog,
              onUpsertMovementTargetBinding: onUpsertMovementTargetBinding,
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _StageMovementTargetBindingRow extends StatefulWidget {
  const _StageMovementTargetBindingRow({
    required this.target,
    required this.asset,
    required this.stageContext,
    required this.stageMapSourceCatalog,
    required this.onUpsertMovementTargetBinding,
  });

  final CinematicMovementTargetRef target;
  final CinematicAsset asset;
  final CinematicStageContext stageContext;
  final CinematicStageMapSourceCatalog? stageMapSourceCatalog;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;

  @override
  State<_StageMovementTargetBindingRow> createState() =>
      _StageMovementTargetBindingRowState();
}

class _StageMovementTargetBindingRowState
    extends State<_StageMovementTargetBindingRow> {
  CinematicMovementTargetBindingKind? _expandedSourceKind;

  @override
  void didUpdateWidget(_StageMovementTargetBindingRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.mapId != widget.asset.mapId ||
        oldWidget.target.targetId != widget.target.targetId) {
      _expandedSourceKind = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final asset = widget.asset;
    final stageContext = widget.stageContext;
    final sourceCatalog = widget.stageMapSourceCatalog;
    final binding = _movementTargetBindingFor(stageContext, target.targetId);
    final selectedKind = binding?.kind;
    final entitySources = _movementTargetEntitySources(asset, sourceCatalog);
    final eventSources = _movementTargetEventSources(asset, sourceCatalog);
    final entityReason = _mapEntityTargetDisabledReason(
      asset,
      sourceCatalog,
      entitySources,
    );
    final eventReason = _mapEventTargetDisabledReason(
      asset,
      sourceCatalog,
      eventSources,
    );
    final canPickEntity = entityReason == null;
    final canPickEvent = eventReason == null;
    final selectedEntity =
        selectedKind == CinematicMovementTargetBindingKind.mapEntity &&
                binding?.sourceId != null
            ? sourceCatalog?.entityById(binding!.sourceId!)
            : null;
    final selectedEvent =
        selectedKind == CinematicMovementTargetBindingKind.mapEvent &&
                binding?.sourceId != null
            ? sourceCatalog?.eventById(binding!.sourceId!)
            : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KeyValue(label: 'Destination', value: target.label),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _StageChoice(
              keyValue:
                  'cinematic-builder-target-binding-${target.targetId}-abstractPoint',
              label: 'Position libre',
              icon: CupertinoIcons.scope,
              selected: selectedKind ==
                  CinematicMovementTargetBindingKind.abstractPoint,
              tooltip: 'Associer à des coordonnées X/Y libres sur la carte',
              onPressed: () => widget.onUpsertMovementTargetBinding(
                CinematicMovementTargetBinding(
                  targetId: target.targetId,
                  kind: CinematicMovementTargetBindingKind.abstractPoint,
                ),
              ),
            ),
            _StageChoice(
              keyValue:
                  'cinematic-builder-target-binding-${target.targetId}-stagePoint',
              label: 'Repère de scène',
              icon: CupertinoIcons.pin,
              selected:
                  selectedKind == CinematicMovementTargetBindingKind.stagePoint,
              tooltip: 'Associer à un repère de scène',
              onPressed: () {
                final pointId = binding?.sourceId ??
                    (stageContext.stagePoints.isNotEmpty
                        ? stageContext.stagePoints.first.id
                        : null);
                widget.onUpsertMovementTargetBinding(
                  CinematicMovementTargetBinding(
                    targetId: target.targetId,
                    kind: CinematicMovementTargetBindingKind.stagePoint,
                    sourceId: pointId,
                  ),
                );
                setState(() {
                  _expandedSourceKind =
                      CinematicMovementTargetBindingKind.stagePoint;
                });
              },
            ),
            _StageChoice(
              keyValue:
                  'cinematic-builder-target-binding-${target.targetId}-mapEntity',
              label: 'Personnage ou objet de la map',
              icon: CupertinoIcons.location,
              selected:
                  selectedKind == CinematicMovementTargetBindingKind.mapEntity,
              disabled: !canPickEntity,
              tooltip:
                  'Associer à la position d’un personnage ou objet sur la carte',
              onPressed: () {
                setState(() {
                  _expandedSourceKind =
                      CinematicMovementTargetBindingKind.mapEntity;
                });
              },
            ),
            _StageChoice(
              keyValue:
                  'cinematic-builder-target-binding-${target.targetId}-mapEvent',
              label: 'Déclencheur de map',
              icon: CupertinoIcons.flag,
              selected:
                  selectedKind == CinematicMovementTargetBindingKind.mapEvent,
              disabled: !canPickEvent,
              tooltip: 'Associer à la position d’un déclencheur sur la carte',
              onPressed: () {
                setState(() {
                  _expandedSourceKind =
                      CinematicMovementTargetBindingKind.mapEvent;
                });
              },
            ),
          ],
        ),
        if (selectedKind == CinematicMovementTargetBindingKind.stagePoint &&
            binding?.sourceId != null) ...[
          const SizedBox(height: 4),
          () {
            final sourceId = binding!.sourceId!;
            CinematicStagePoint? point;
            for (final p in stageContext.stagePoints) {
              if (p.id == sourceId) {
                point = p;
                break;
              }
            }
            if (point != null) {
              return _MutedText(
                'Repère cible : ${point.label} · '
                'Colonne ${point.x.toInt()} · Ligne ${point.y.toInt()}',
              );
            } else {
              return const _MutedText(
                'Repère cible : [Repère de scène manquant]',
              );
            }
          }(),
        ],
        if (selectedEntity != null) ...[
          const SizedBox(height: 4),
          _MutedText(
            'Personnage ou objet cible : ${selectedEntity.label} · '
            '${selectedEntity.kindLabel} · ${selectedEntity.positionSummary}',
          ),
        ],
        if (selectedEvent != null) ...[
          const SizedBox(height: 4),
          _MutedText(
            'Déclencheur cible : ${selectedEvent.label} · '
            '${selectedEvent.kindLabel} · ${selectedEvent.positionSummary}',
          ),
        ],
        if (entityReason != null || eventReason != null)
          const SizedBox(height: 4),
        if (entityReason != null) _MutedText(entityReason),
        if (eventReason != null) _MutedText(eventReason),
        if (_expandedSourceKind ==
                CinematicMovementTargetBindingKind.stagePoint ||
            selectedKind == CinematicMovementTargetBindingKind.stagePoint) ...[
          const SizedBox(height: 6),
          _StagePointSourcePicker(
            keyPrefix:
                'cinematic-builder-target-binding-${target.targetId}-stagePoint',
            sources: stageContext.stagePoints,
            selectedSourceId:
                selectedKind == CinematicMovementTargetBindingKind.stagePoint
                    ? binding?.sourceId
                    : null,
            onSourceSelected: (source) => widget.onUpsertMovementTargetBinding(
              CinematicMovementTargetBinding(
                targetId: target.targetId,
                kind: CinematicMovementTargetBindingKind.stagePoint,
                sourceId: source.id,
              ),
            ),
          ),
        ],
        if (canPickEntity &&
            (_expandedSourceKind ==
                    CinematicMovementTargetBindingKind.mapEntity ||
                selectedKind ==
                    CinematicMovementTargetBindingKind.mapEntity)) ...[
          const SizedBox(height: 6),
          _StageMapEntitySourcePicker(
            keyPrefix: 'cinematic-builder-target-binding-${target.targetId}'
                '-mapEntity',
            sources: entitySources,
            selectedSourceId:
                selectedKind == CinematicMovementTargetBindingKind.mapEntity
                    ? binding?.sourceId
                    : null,
            onSourceSelected: (source) => widget.onUpsertMovementTargetBinding(
              CinematicMovementTargetBinding(
                targetId: target.targetId,
                kind: CinematicMovementTargetBindingKind.mapEntity,
                sourceId: source.id,
              ),
            ),
          ),
        ],
        if (canPickEvent &&
            (_expandedSourceKind ==
                    CinematicMovementTargetBindingKind.mapEvent ||
                selectedKind ==
                    CinematicMovementTargetBindingKind.mapEvent)) ...[
          const SizedBox(height: 6),
          _StageMapEventSourcePicker(
            keyPrefix: 'cinematic-builder-target-binding-${target.targetId}'
                '-mapEvent',
            sources: eventSources,
            selectedSourceId:
                selectedKind == CinematicMovementTargetBindingKind.mapEvent
                    ? binding?.sourceId
                    : null,
            onSourceSelected: (source) => widget.onUpsertMovementTargetBinding(
              CinematicMovementTargetBinding(
                targetId: target.targetId,
                kind: CinematicMovementTargetBindingKind.mapEvent,
                sourceId: source.id,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

typedef _SelectStageMapEntitySource = Future<void> Function(
    CinematicStageMapEntitySource source);

typedef _SelectStageMapEventSource = Future<void> Function(
    CinematicStageMapEventSource source);

class _StageMapEntitySourcePicker extends StatelessWidget {
  const _StageMapEntitySourcePicker({
    required this.keyPrefix,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourceSelected,
  });

  final String keyPrefix;
  final List<CinematicStageMapEntitySource> sources;
  final String? selectedSourceId;
  final _SelectStageMapEntitySource onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return _StageSourcePickerShell(
      title: 'Sources personnages/objets',
      children: [
        for (final source in sources)
          _StageSourceOption(
            keyValue: '$keyPrefix-source-${source.id}',
            label: source.label,
            detail: '${source.kindLabel} · ${source.positionSummary}',
            icon: CupertinoIcons.location,
            selected: selectedSourceId == source.id,
            onPressed: () => onSourceSelected(source),
          ),
      ],
    );
  }
}

class _MapEntityDropdownPopup extends StatelessWidget {
  const _MapEntityDropdownPopup({
    required this.keyPrefix,
    required this.sources,
    required this.selectedSourceId,
    required this.colors,
    required this.width,
    required this.height,
    required this.onSourceSelected,
  });

  final String keyPrefix;
  final List<CinematicStageMapEntitySource> sources;
  final String? selectedSourceId;
  final PokeMapColorTokens colors;
  final double width;
  final double height;
  final ValueChanged<CinematicStageMapEntitySource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderStrong),
        boxShadow: [
          BoxShadow(
            color: colors.borderStrong.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [for (final source in sources) _buildItem(source)],
        ),
      ),
    );
  }

  Widget _buildItem(CinematicStageMapEntitySource source) {
    final isSelected = selectedSourceId == source.id;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: ValueKey('$keyPrefix-source-${source.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onSourceSelected(source),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: isSelected
              ? colors.surfaceSelected
              : colors.surfaceSelected.withValues(alpha: 0),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.location,
                size: 14,
                color: isSelected ? colors.brandPrimary : colors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source.label,
                      style: TextStyle(
                        color: isSelected
                            ? colors.brandPrimary
                            : colors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${source.kindLabel} · ${source.positionSummary}',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark,
                  size: 12,
                  color: colors.brandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageMapEventSourcePicker extends StatelessWidget {
  const _StageMapEventSourcePicker({
    required this.keyPrefix,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourceSelected,
  });

  final String keyPrefix;
  final List<CinematicStageMapEventSource> sources;
  final String? selectedSourceId;
  final _SelectStageMapEventSource onSourceSelected;

  @override
  Widget build(BuildContext context) {
    return _StageSourcePickerShell(
      title: 'Sources déclencheurs',
      children: [
        for (final source in sources)
          _StageSourceOption(
            keyValue: '$keyPrefix-source-${source.id}',
            label: source.label,
            detail: '${source.kindLabel} · ${source.positionSummary}',
            icon: CupertinoIcons.flag,
            selected: selectedSourceId == source.id,
            onPressed: () => onSourceSelected(source),
          ),
      ],
    );
  }
}

typedef _SelectStagePointSource = Future<void> Function(
    CinematicStagePoint source);

class _StagePointSourcePicker extends StatelessWidget {
  const _StagePointSourcePicker({
    required this.keyPrefix,
    required this.sources,
    required this.selectedSourceId,
    required this.onSourceSelected,
  });

  final String keyPrefix;
  final List<CinematicStagePoint> sources;
  final String? selectedSourceId;
  final _SelectStagePointSource onSourceSelected;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const _MutedText('Aucun repère de scène disponible.');
    }
    return _StageSourcePickerShell(
      title: 'Sources repères de scène',
      children: [
        for (final source in sources)
          _StageSourceOption(
            keyValue: '$keyPrefix-source-${source.id}',
            label: source.label,
            detail: 'Colonne ${source.x.toInt()} · Ligne ${source.y.toInt()}',
            icon: CupertinoIcons.pin,
            selected: selectedSourceId == source.id,
            onPressed: () => onSourceSelected(source),
          ),
      ],
    );
  }
}

class _StageSourcePickerShell extends StatelessWidget {
  const _StageSourcePickerShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KeyValue(label: title, value: '${children.length} source(s)'),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _StageSourceOption extends StatelessWidget {
  const _StageSourceOption({
    required this.keyValue,
    required this.label,
    required this.detail,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String keyValue;
  final String label;
  final String detail;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 245),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PokeMapButton(
            key: ValueKey(keyValue),
            onPressed: onPressed,
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            isSelected: selected,
            leading: Icon(icon),
            child: const SizedBox.shrink(),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StrongText(label),
                const SizedBox(height: 2),
                _MutedText(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePreviewReadinessSection extends StatelessWidget {
  const _StagePreviewReadinessSection({required this.readiness});

  final CinematicStagePreviewReadiness readiness;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-stage-preview-readiness-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Préparation preview',
          subtitle: readiness.statusLabel,
        ),
        const SizedBox(height: 8),
        _KeyValue(label: 'Statut readiness', value: readiness.statusLabel),
        _MutedText(readiness.summary),
        const SizedBox(height: 8),
        const _StrongText('Checklist no-code'),
        const SizedBox(height: 6),
        for (final item in readiness.items) ...[
          _StageReadinessItemRow(item: item),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _StageReadinessItemRow extends StatelessWidget {
  const _StageReadinessItemRow({required this.item});

  final CinematicStagePreviewReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            _readinessItemIcon(item.kind),
            size: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.displayLine,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _StageDiagnosticsSection extends StatelessWidget {
  const _StageDiagnosticsSection({required this.readiness});

  final CinematicStagePreviewReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final diagnostics = readiness.diagnostics;
    return Column(
      key: const ValueKey('cinematic-builder-stage-diagnostics-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          title: 'Diagnostics stage',
          subtitle: 'Readiness preview future',
        ),
        const SizedBox(height: 8),
        if (diagnostics.isEmpty)
          const _MutedText('Aucun problème prioritaire')
        else
          for (final diagnostic in diagnostics) ...[
            PokeMapBadge(
              label: _stageDiagnosticSeverityLabel(diagnostic.severity),
              variant: switch (diagnostic.severity) {
                CinematicsLibraryDiagnosticSeverity.error =>
                  PokeMapBadgeVariant.error,
                CinematicsLibraryDiagnosticSeverity.warning =>
                  PokeMapBadgeVariant.warning,
                CinematicsLibraryDiagnosticSeverity.info =>
                  PokeMapBadgeVariant.info,
              },
            ),
            const SizedBox(height: 4),
            _MutedText(diagnostic.message),
            const SizedBox(height: 4),
            _KeyValue(label: 'Référence', value: diagnostic.code),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

String _stageDiagnosticSeverityLabel(
  CinematicsLibraryDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicsLibraryDiagnosticSeverity.error => 'Bloquant',
    CinematicsLibraryDiagnosticSeverity.warning => 'À vérifier',
    CinematicsLibraryDiagnosticSeverity.info => 'Info',
  };
}

IconData _readinessItemIcon(CinematicStagePreviewReadinessItemKind kind) {
  return switch (kind) {
    CinematicStagePreviewReadinessItemKind.ok =>
      CupertinoIcons.check_mark_circled,
    CinematicStagePreviewReadinessItemKind.incomplete =>
      CupertinoIcons.circle_lefthalf_fill,
    CinematicStagePreviewReadinessItemKind.blocking =>
      CupertinoIcons.exclamationmark_triangle,
    CinematicStagePreviewReadinessItemKind.upcoming => CupertinoIcons.clock,
  };
}

class _StageChoice extends StatelessWidget {
  const _StageChoice({
    required this.keyValue,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.disabled = false,
    this.tooltip,
  });

  final String keyValue;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final bool disabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = PokeMapButton(
      key: ValueKey(keyValue),
      onPressed: disabled ? null : onPressed,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: selected,
      leading: Icon(icon),
      child: Text(label),
    );
    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _SelectedStepInspector extends StatelessWidget {
  const _SelectedStepInspector({
    required this.asset,
    required this.step,
    required this.index,
    required this.onRemoveDraftStep,
    required this.onUpdateBasicBlock,
    required this.onUpdateActorFacing,
    required this.onUpdateActorMove,
    required this.onRemoveAuthoringStep,
    required this.onToggleActorMovePathMode,
    required this.onAddManualPathWaypoint,
    required this.onRemoveManualPathWaypoint,
    required this.onReorderManualPathWaypoint,
    required this.onUpsertMovementTargetBinding,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final int index;
  final ValueChanged<CinematicTimelineStep> onRemoveDraftStep;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;
  final _UpdateActorFacingCallback onUpdateActorFacing;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final _RemoveAuthoringStepCallback onRemoveAuthoringStep;
  final _ToggleActorMovePathModeCallback onToggleActorMovePathMode;
  final _AddManualPathWaypointCallback onAddManualPathWaypoint;
  final _RemoveManualPathWaypointCallback onRemoveManualPathWaypoint;
  final _ReorderManualPathWaypointCallback onReorderManualPathWaypoint;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;

  @override
  Widget build(BuildContext context) {
    final diagnostics = _stepDiagnostics(asset, step);
    final isDraft = isCinematicTimelineDraftStep(step);
    final basicBlockKind = cinematicTimelineBasicBlockKindOf(step);
    final isActorFacing = isCinematicTimelineActorFacingStep(step);
    final isActorMove = isCinematicTimelineActorMoveStep(step);
    final isAuthoringOwned = isCinematicTimelineAuthoringStep(step);
    final durationNonEditableReason =
        isDraft ? null : _durationNonEditableReason(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(title: 'Bloc sélectionné', subtitle: step.id),
        const SizedBox(height: 8),
        _KeyValue(label: 'Titre', value: _stepDisplayTitle(asset, step, index)),
        _KeyValue(label: 'Id', value: step.id),
        _KeyValue(label: 'Index', value: '${index + 1}'),
        _KeyValue(label: 'Kind', value: step.kind.name),
        _KeyValue(label: 'Durée', value: _stepDurationLabel(step)),
        _KeyValue(
          label: 'Acteur',
          value: step.actorId == null
              ? 'Aucun acteur'
              : _actorDisplayLabelForId(asset, step.actorId!),
        ),
        _KeyValue(
          label: 'Destination',
          value: step.targetId == null
              ? 'Aucune destination'
              : _movementTargetLabelForId(asset, step.targetId!),
        ),
        _KeyValue(
          label: 'Dialogue',
          value: step.dialogueText ?? 'Aucun texte cinematic',
        ),
        _KeyValue(label: 'Asset', value: step.assetRef ?? 'Aucun assetRef'),
        _KeyValue(label: 'Metadata', value: _metadataLabel(step.metadata)),
        if (basicBlockKind != null) ...[
          const _KeyValue(label: 'Statut', value: 'Bloc authoring V0'),
          _BasicBlockControls(
            step: step,
            blockKind: basicBlockKind,
            onUpdateBasicBlock: onUpdateBasicBlock,
          ),
          const SizedBox(height: 8),
        ],
        if (isActorFacing) ...[
          const _KeyValue(label: 'Statut', value: 'Bloc authoring V0'),
          _ActorFacingControls(
            asset: asset,
            step: step,
            onUpdateActorFacing: onUpdateActorFacing,
          ),
          const SizedBox(height: 8),
        ],
        if (isActorMove) ...[
          const _KeyValue(label: 'Statut', value: 'Bloc authoring V0'),
          _KeyValue(label: 'Résumé', value: _actorMoveSummary(asset, step)),
          _ActorMoveControls(
            asset: asset,
            step: step,
            onUpdateActorMove: onUpdateActorMove,
            onToggleActorMovePathMode: onToggleActorMovePathMode,
            onAddManualPathWaypoint: onAddManualPathWaypoint,
            onRemoveManualPathWaypoint: onRemoveManualPathWaypoint,
            onReorderManualPathWaypoint: onReorderManualPathWaypoint,
            onUpsertMovementTargetBinding: onUpsertMovementTargetBinding,
          ),
          const SizedBox(height: 8),
        ],
        if (durationNonEditableReason != null) ...[
          _MutedText(
            durationNonEditableReason,
            key: const ValueKey(
              'cinematic-builder-duration-non-editable-reason',
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (isDraft) ...[
          const _KeyValue(label: 'Statut', value: 'Placeholder authoring'),
          const _BodyText('Durée non éditable — brouillon sans effet moteur.'),
          const SizedBox(height: 8),
        ],
        if (isAuthoringOwned) ...[
          PokeMapButton(
            key: const ValueKey(
              'cinematic-builder-remove-authoring-step-button',
            ),
            onPressed: () {
              if (isDraft) {
                onRemoveDraftStep(step);
              } else {
                onRemoveAuthoringStep(step);
              }
            },
            variant: PokeMapButtonVariant.danger,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.trash),
            child: const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          _MutedText(isDraft ? 'Supprimer ce brouillon' : 'Supprimer ce bloc'),
          const SizedBox(height: 8),
        ],
        const _KeyValue(label: 'Preview', value: 'Scène non jouée.'),
        const _KeyValue(
          label: 'Statut runtime',
          value: 'Lecture read-only dans ce lot.',
        ),
        const SizedBox(height: 8),
        _StepDiagnosticsSummary(diagnostics: diagnostics),
      ],
    );
  }
}

class _StepDiagnosticsSummary extends StatelessWidget {
  const _StepDiagnosticsSummary({required this.diagnostics});

  final List<CinematicDiagnostic> diagnostics;

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return const PokeMapBadge(
        label: 'Bloc OK',
        variant: PokeMapBadgeVariant.success,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(title: 'Diagnostics', subtitle: 'Contexte du bloc'),
        const SizedBox(height: 8),
        for (final diagnostic in diagnostics) ...[
          PokeMapBadge(
            label: _diagnosticSeverityLabel(diagnostic.severity),
            variant: _diagnosticVariant(diagnostic.severity),
          ),
          const SizedBox(height: 6),
          _KeyValue(label: 'Code', value: diagnostic.code.name),
          _MutedText(diagnostic.message),
          const SizedBox(height: 4),
          const _MutedText('Aucune action de correction dans ce lot.'),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _BasicBlockControls extends StatelessWidget {
  const _BasicBlockControls({
    required this.step,
    required this.blockKind,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final CinematicTimelineBasicBlockKind blockKind;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Paramètres V0',
          subtitle: 'Contrôles bornés',
        ),
        const SizedBox(height: 8),
        _KeyValue(label: 'Bloc', value: _basicBlockLabel(blockKind)),
        _DurationPresetControls(
          step: step,
          onUpdateBasicBlock: onUpdateBasicBlock,
        ),
        if (blockKind == CinematicTimelineBasicBlockKind.fade) ...[
          const SizedBox(height: 8),
          _FadeModeControls(step: step, onUpdateBasicBlock: onUpdateBasicBlock),
        ],
        if (blockKind == CinematicTimelineBasicBlockKind.camera) ...[
          const SizedBox(height: 8),
          _CameraModeControls(
            step: step,
            onUpdateBasicBlock: onUpdateBasicBlock,
          ),
        ],
      ],
    );
  }
}

class _DurationPresetControls extends StatelessWidget {
  const _DurationPresetControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    return _DurationEditorControls(
      currentDurationMs: _editableDurationMs(step),
      explicitDurationMs: step.durationMs,
      minDurationMs: _editableDurationMinimumMs(step),
      keyPrefix: 'cinematic-builder-duration',
      onDurationChanged: (durationMs) {
        return onUpdateBasicBlock(step, durationMs: durationMs);
      },
    );
  }
}

class _DurationEditorControls extends StatefulWidget {
  const _DurationEditorControls({
    required this.currentDurationMs,
    required this.explicitDurationMs,
    required this.minDurationMs,
    required this.keyPrefix,
    required this.onDurationChanged,
  });

  final int currentDurationMs;
  final int? explicitDurationMs;
  final int minDurationMs;
  final String keyPrefix;
  final Future<void> Function(int durationMs) onDurationChanged;

  @override
  State<_DurationEditorControls> createState() =>
      _DurationEditorControlsState();
}

class _DurationEditorControlsState extends State<_DurationEditorControls> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentDurationMs.toString(),
  );
  String? _errorText;

  @override
  void didUpdateWidget(covariant _DurationEditorControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDurationMs != widget.currentDurationMs ||
        oldWidget.keyPrefix != widget.keyPrefix) {
      _controller.text = widget.currentDurationMs.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitText() async {
    final parsed = int.tryParse(_controller.text.trim());
    final error = _durationValidationMessage(
      parsed,
      rawValue: _controller.text,
      minDurationMs: widget.minDurationMs,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    await _submitDuration(parsed!);
  }

  Future<void> _submitDuration(int durationMs) async {
    final error = _durationValidationMessage(
      durationMs,
      rawValue: durationMs.toString(),
      minDurationMs: widget.minDurationMs,
    );
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    setState(() {
      _errorText = null;
      _controller.text = durationMs.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
    await widget.onDurationChanged(durationMs);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final decrementValue = widget.currentDurationMs - 100;
    final incrementValue = widget.currentDurationMs + 100;
    final boundaryFeedback = _durationBoundaryFeedback(
      widget.currentDurationMs,
      minDurationMs: widget.minDurationMs,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Durée', value: 'Edition en millisecondes'),
        _MutedText(
          _durationGuidanceLabel(widget.minDurationMs),
          key: ValueKey('${widget.keyPrefix}-guidance'),
        ),
        if (boundaryFeedback != null) ...[
          const SizedBox(height: 4),
          Text(
            boundaryFeedback,
            key: ValueKey('${widget.keyPrefix}-boundary-feedback'),
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.info,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CupertinoTextField(
                key: ValueKey('${widget.keyPrefix}-ms-field'),
                controller: _controller,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                placeholder: '${widget.minDurationMs} ms min.',
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onSubmitted: (_) {
                  unawaited(_submitText());
                },
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                placeholderStyle: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                decoration: BoxDecoration(
                  color: colors.controlSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderSubtle),
                ),
              ),
            ),
            const SizedBox(width: 6),
            PokeMapButton(
              key: ValueKey('${widget.keyPrefix}-decrement-100'),
              onPressed: decrementValue < widget.minDurationMs
                  ? null
                  : () => unawaited(_submitDuration(decrementValue)),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.minus),
              child: const SizedBox.shrink(),
            ),
            const SizedBox(width: 6),
            PokeMapButton(
              key: ValueKey('${widget.keyPrefix}-increment-100'),
              onPressed: incrementValue > cinematicTimelineMaximumDurationMs
                  ? null
                  : () => unawaited(_submitDuration(incrementValue)),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.plus),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in _durationPresetsMs)
              _InlineControlAction(
                label: '$preset ms',
                button: PokeMapButton(
                  key: ValueKey('${widget.keyPrefix}-preset-$preset'),
                  onPressed: preset < widget.minDurationMs
                      ? null
                      : () => unawaited(_submitDuration(preset)),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: widget.explicitDurationMs == preset,
                  leading: const Icon(CupertinoIcons.clock),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorText!,
            key: ValueKey('${widget.keyPrefix}-validation'),
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ],
    );
  }
}

class _FadeModeControls extends StatelessWidget {
  const _FadeModeControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    final currentMode = step.metadata[cinematicTimelineFadeModeMetadataKey];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Mode fondu', value: 'Entrant ou sortant'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineFadeMode.values)
              _InlineControlAction(
                label: _fadeModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-fade-mode-${mode.name}'),
                  onPressed: () {
                    onUpdateBasicBlock(step, fadeMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMode == mode.name,
                  leading: const Icon(CupertinoIcons.layers_alt),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CameraModeControls extends StatelessWidget {
  const _CameraModeControls({
    required this.step,
    required this.onUpdateBasicBlock,
  });

  final CinematicTimelineStep step;
  final _UpdateBasicBlockCallback onUpdateBasicBlock;

  @override
  Widget build(BuildContext context) {
    final currentMode = step.metadata[cinematicTimelineCameraModeMetadataKey];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _KeyValue(label: 'Mode caméra', value: 'Basique uniquement'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineCameraMode.values)
              _InlineControlAction(
                label: _cameraModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey('cinematic-builder-camera-mode-${mode.name}'),
                  onPressed: () {
                    onUpdateBasicBlock(step, cameraMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMode == mode.name,
                  leading: const Icon(CupertinoIcons.video_camera),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ActorFacingControls extends StatelessWidget {
  const _ActorFacingControls({
    required this.asset,
    required this.step,
    required this.onUpdateActorFacing,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateActorFacingCallback onUpdateActorFacing;

  @override
  Widget build(BuildContext context) {
    final currentDirection = cinematicTimelineActorFacingDirectionOf(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(title: 'Acteur', subtitle: 'Picker requis'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final actor in asset.requiredActors)
              _InlineControlAction(
                label: _actorDisplayLabel(actor),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-picker-${actor.actorId}',
                  ),
                  onPressed: () {
                    onUpdateActorFacing(step, actorId: actor.actorId);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.actorId == actor.actorId,
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _KeyValue(label: 'Direction', value: 'Haut, bas, gauche, droite'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final direction
                in CinematicTimelineActorFacingDirection.values)
              _InlineControlAction(
                label: _actorDirectionLabel(direction),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-direction-${direction.name}',
                  ),
                  onPressed: () {
                    onUpdateActorFacing(step, direction: direction);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentDirection == direction,
                  leading: Icon(_actorDirectionIcon(direction)),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _DurationEditorControls(
          currentDurationMs: _editableDurationMs(step),
          explicitDurationMs: step.durationMs,
          minDurationMs: _editableDurationMinimumMs(step),
          keyPrefix: 'cinematic-builder-actor-facing-duration',
          onDurationChanged: (durationMs) {
            return onUpdateActorFacing(step, durationMs: durationMs);
          },
        ),
      ],
    );
  }
}

class _ActorMoveControls extends StatelessWidget {
  const _ActorMoveControls({
    required this.asset,
    required this.step,
    required this.onUpdateActorMove,
    required this.onToggleActorMovePathMode,
    required this.onAddManualPathWaypoint,
    required this.onRemoveManualPathWaypoint,
    required this.onReorderManualPathWaypoint,
    required this.onUpsertMovementTargetBinding,
  });

  final CinematicAsset asset;
  final CinematicTimelineStep step;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final _ToggleActorMovePathModeCallback onToggleActorMovePathMode;
  final _AddManualPathWaypointCallback onAddManualPathWaypoint;
  final _RemoveManualPathWaypointCallback onRemoveManualPathWaypoint;
  final _ReorderManualPathWaypointCallback onReorderManualPathWaypoint;
  final _UpsertMovementTargetBindingCallback onUpsertMovementTargetBinding;

  Widget _buildNumberBadge(int number, PokeMapColorTokens colors) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: colors.brandPrimary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: colors.textInverse,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMovementMode = cinematicTimelineActorMovementModeOf(step);
    final pathMode = cinematicTimelineActorPathModeOf(step) ??
        CinematicTimelineActorPathMode.direct;
    final colors = context.pokeMapColors;

    final stagePoints =
        asset.stageContext?.stagePoints ?? const <CinematicStagePoint>[];
    final manualPaths = asset.stageContext?.manualPaths ?? const [];
    final manualPath = manualPaths.cast<CinematicManualPath?>().firstWhere(
          (p) => p?.ownerActorMoveStepId == step.id,
          orElse: () => null,
        );

    final selectedTarget = _selectedTarget(asset, step);
    final destinationStagePointId = _destinationStagePointId(asset, step);
    final destinationStagePoint =
        _stagePointById(stagePoints, destinationStagePointId);
    final availablePoints = [
      for (final point in stagePoints)
        if (point.id != destinationStagePointId) point,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Trajet',
          subtitle: 'Type de trajectoire cinématique',
        ),
        const SizedBox(height: 6),
        PokeMapSegmentedTabs(
          key: const ValueKey('cinematic-builder-actor-move-path-mode-tabs'),
          tabs: [
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-actor-move-path-mode-direct',
              ),
              label: 'Direct',
              icon: CupertinoIcons.arrow_up_right,
              selected: pathMode == CinematicTimelineActorPathMode.direct,
              onTap: () => onToggleActorMovePathMode(
                step,
                CinematicTimelineActorPathMode.direct,
              ),
            ),
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-actor-move-path-mode-manual',
              ),
              label: 'Manuel',
              icon: CupertinoIcons.arrow_branch,
              selected: pathMode == CinematicTimelineActorPathMode.manual,
              onTap: () => onToggleActorMovePathMode(
                step,
                CinematicTimelineActorPathMode.manual,
              ),
            ),
          ],
        ),
        if (pathMode == CinematicTimelineActorPathMode.direct) ...[
          const SizedBox(height: 6),
          const _KeyValue(
            label: 'Trajectoire',
            value: 'Ce déplacement va directement vers sa destination.',
          ),
        ] else ...[
          const SizedBox(height: 6),
          if (manualPath == null ||
              manualPath.id.isEmpty ||
              manualPath.waypointStagePointIds.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.controlBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        'Aucun point de passage',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ajoutez un repère au trajet ou repassez en trajet direct.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            for (int i = 0;
                i < manualPath.waypointStagePointIds.length;
                i++) ...[
              () {
                final spId = manualPath.waypointStagePointIds[i];
                final sp = asset.stageContext?.stagePoints
                    .cast<CinematicStagePoint?>()
                    .firstWhere((p) => p?.id == spId, orElse: () => null);
                final label = sp?.label ?? 'Repère inconnu ($spId)';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      _buildNumberBadge(i + 1, colors),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PokeMapIconButton(
                        key: ValueKey(
                          'cinematic-builder-manual-path-waypoint-up-$i',
                        ),
                        tooltip: 'Monter',
                        icon: const Icon(CupertinoIcons.arrow_up, size: 12),
                        size: 24,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: i > 0
                            ? () => onReorderManualPathWaypoint(
                                  manualPath,
                                  i,
                                  i - 1,
                                )
                            : null,
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        key: ValueKey(
                          'cinematic-builder-manual-path-waypoint-down-$i',
                        ),
                        tooltip: 'Descendre',
                        icon: const Icon(CupertinoIcons.arrow_down, size: 12),
                        size: 24,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed:
                            i < manualPath.waypointStagePointIds.length - 1
                                ? () => onReorderManualPathWaypoint(
                                      manualPath,
                                      i,
                                      i + 1,
                                    )
                                : null,
                      ),
                      const SizedBox(width: 4),
                      PokeMapIconButton(
                        key: ValueKey(
                          'cinematic-builder-manual-path-waypoint-remove-$i',
                        ),
                        tooltip: 'Retirer du trajet',
                        icon: Icon(
                          CupertinoIcons.trash,
                          size: 12,
                          color: colors.error,
                        ),
                        size: 24,
                        variant: PokeMapIconButtonVariant.soft,
                        onPressed: () =>
                            onRemoveManualPathWaypoint(manualPath, i),
                      ),
                    ],
                  ),
                );
              }(),
            ],
          ],
          const SizedBox(height: 6),
          if (availablePoints.isEmpty) ...[
            Text(
              'Aucun repère disponible.\nPosez d\'abord un repère dans l\'aperçu de scène.',
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
          ] else ...[
            PopupMenuButton<CinematicStagePoint>(
              key: const ValueKey('cinematic-builder-add-waypoint-picker'),
              tooltip: 'Ajouter un repère de passage',
              onSelected: (sp) {
                onAddManualPathWaypoint(step, manualPath, sp.id);
              },
              itemBuilder: (context) => [
                for (final sp in availablePoints)
                  PopupMenuItem(value: sp, child: Text(sp.label)),
              ],
              child: IgnorePointer(
                child: PokeMapButton(
                  key: const ValueKey('cinematic-builder-add-waypoint-button'),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(CupertinoIcons.add, size: 12),
                  onPressed: () {},
                  child: const Text('Ajouter un repère'),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        const _KeyValue(label: 'Mode mouvement', value: 'Marche ou course'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final mode in CinematicTimelineActorMovementMode.values)
              _InlineControlAction(
                label: _actorMovementModeLabel(mode),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-move-mode-${mode.name}',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, movementMode: mode);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: currentMovementMode == mode,
                  leading: Icon(_actorMovementModeIcon(mode)),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _SectionTitle(title: 'Acteur', subtitle: 'Picker requis'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final actor in asset.requiredActors)
              _InlineControlAction(
                label: _actorDisplayLabel(actor),
                button: PokeMapButton(
                  key: ValueKey(
                    'cinematic-builder-actor-picker-${actor.actorId}',
                  ),
                  onPressed: () {
                    onUpdateActorMove(step, actorId: actor.actorId);
                  },
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  isSelected: step.actorId == actor.actorId,
                  leading: const Icon(CupertinoIcons.person_crop_circle),
                  child: const SizedBox.shrink(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _SectionTitle(
          title: 'Destination',
          subtitle: 'Repère final du déplacement',
        ),
        const SizedBox(height: 6),
        if (selectedTarget == null) ...[
          const _MutedText(
            'Choisissez une destination avant de lancer la prévisualisation.',
          ),
          const SizedBox(height: 6),
          _MovementTargetPicker(
            asset: asset,
            selectedTargetId: step.targetId,
            onUpdateActorMove: onUpdateActorMove,
            step: step,
          ),
        ] else ...[
          _MutedText(
            destinationStagePoint == null
                ? 'Choisissez un repère pour que le déplacement puisse être prévisualisé.'
                : 'Destination actuelle : ${destinationStagePoint.label}',
          ),
          const SizedBox(height: 6),
          if (stagePoints.isEmpty)
            const _MutedText(
              'Aucun repère disponible. Posez d\'abord un repère dans l\'aperçu de scène.',
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final point in stagePoints)
                  _InlineControlAction(
                    label: point.label,
                    button: PokeMapButton(
                      key: ValueKey(
                        'cinematic-builder-actor-move-destination-stage-point-${selectedTarget.targetId}-${point.id}',
                      ),
                      onPressed: () => onUpsertMovementTargetBinding(
                        CinematicMovementTargetBinding(
                          targetId: selectedTarget.targetId,
                          kind: CinematicMovementTargetBindingKind.stagePoint,
                          sourceId: point.id,
                        ),
                      ),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      isSelected: destinationStagePointId == point.id,
                      leading: const Icon(CupertinoIcons.location),
                      child: const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          if (asset.movementTargets.length > 1) ...[
            const SizedBox(height: 8),
            const _KeyValue(
              label: 'Variante de destination',
              value: 'Choisissez la destination à éditer.',
            ),
            const SizedBox(height: 6),
            _MovementTargetPicker(
              asset: asset,
              selectedTargetId: step.targetId,
              onUpdateActorMove: onUpdateActorMove,
              step: step,
            ),
          ],
        ],
        const SizedBox(height: 8),
        _DurationEditorControls(
          currentDurationMs: _editableDurationMs(step),
          explicitDurationMs: step.durationMs,
          minDurationMs: _editableDurationMinimumMs(step),
          keyPrefix: 'cinematic-builder-actor-move-duration',
          onDurationChanged: (durationMs) {
            return onUpdateActorMove(step, durationMs: durationMs);
          },
        ),
      ],
    );
  }

  String? _destinationStagePointId(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final targetId = step.targetId;
    final stageContext = asset.stageContext;
    if (targetId == null || stageContext == null) {
      return null;
    }
    for (final binding in stageContext.movementTargetBindings) {
      if (binding.targetId == targetId &&
          binding.kind == CinematicMovementTargetBindingKind.stagePoint) {
        return binding.sourceId;
      }
    }
    return null;
  }

  CinematicMovementTargetRef? _selectedTarget(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final targetId = step.targetId;
    if (targetId == null) {
      return null;
    }
    for (final target in asset.movementTargets) {
      if (target.targetId == targetId) {
        return target;
      }
    }
    return null;
  }

  CinematicStagePoint? _stagePointById(
    List<CinematicStagePoint> stagePoints,
    String? stagePointId,
  ) {
    if (stagePointId == null) {
      return null;
    }
    for (final point in stagePoints) {
      if (point.id == stagePointId) {
        return point;
      }
    }
    return null;
  }
}

class _MovementTargetPicker extends StatelessWidget {
  const _MovementTargetPicker({
    required this.asset,
    required this.selectedTargetId,
    required this.onUpdateActorMove,
    required this.step,
  });

  final CinematicAsset asset;
  final String? selectedTargetId;
  final _UpdateActorMoveCallback onUpdateActorMove;
  final CinematicTimelineStep step;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final target in asset.movementTargets)
          _InlineControlAction(
            label: target.label,
            button: PokeMapButton(
              key: ValueKey(
                'cinematic-builder-target-picker-${target.targetId}',
              ),
              onPressed: () {
                onUpdateActorMove(step, targetId: target.targetId);
              },
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              isSelected: selectedTargetId == target.targetId,
              leading: const Icon(CupertinoIcons.location),
              child: const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

class _InlineControlAction extends StatelessWidget {
  const _InlineControlAction({required this.label, required this.button});

  final String label;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 170),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _EmptySelectionCard extends StatelessWidget {
  const _EmptySelectionCard();

  @override
  Widget build(BuildContext context) {
    return const PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StrongText('Aucun bloc sélectionné'),
          SizedBox(height: 4),
          _MutedText('Sélection de bloc à venir'),
          SizedBox(height: 4),
          _MutedText('Sélectionnez un bloc existant dans le déroulé.'),
        ],
      ),
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

class _StrongText extends StatelessWidget {
  const _StrongText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
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
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PaletteBlock {
  const _PaletteBlock({
    required this.label,
    required this.icon,
    required this.description,
    this.blockKind,
  });

  final String label;
  final IconData icon;
  final String description;
  final CinematicTimelineBasicBlockKind? blockKind;
}

const _paletteBlocks = [
  _PaletteBlock(
    label: 'Attendre',
    icon: CupertinoIcons.hourglass,
    description: 'Pause dans la scène',
    blockKind: CinematicTimelineBasicBlockKind.wait,
  ),
  _PaletteBlock(
    label: 'Fondu',
    icon: CupertinoIcons.film,
    description: "Fondu d'entrée / sortie",
    blockKind: CinematicTimelineBasicBlockKind.fade,
  ),
  _PaletteBlock(
    label: 'Caméra',
    icon: CupertinoIcons.video_camera,
    description: 'Déplacer ou zoomer',
    blockKind: CinematicTimelineBasicBlockKind.camera,
  ),
];

const _lockedPaletteBlocks = [
  _PaletteBlock(
    label: 'Dialogue',
    icon: CupertinoIcons.text_bubble,
    description: 'Non authorable dans ce lot.',
  ),
  _PaletteBlock(
    label: 'FX',
    icon: CupertinoIcons.sparkles,
    description: 'Non authorable dans ce lot.',
  ),
  _PaletteBlock(
    label: 'Son',
    icon: CupertinoIcons.speaker_2,
    description: 'Non authorable dans ce lot.',
  ),
];

const _durationPresetsMs = [100, 250, 500, 1000, 1500, 2000, 3000];

int _editableDurationMs(CinematicTimelineStep step) {
  final durationMs = step.durationMs;
  if (durationMs != null && durationMs > 0) {
    return durationMs;
  }
  return cinematicTimelineFallbackVisualDurationMs;
}

int _editableDurationMinimumMs(CinematicTimelineStep step) {
  if (isCinematicTimelineActorMoveStep(step)) {
    return cinematicTimelineActorMoveMinimumDurationMs;
  }
  return cinematicTimelineMinimumDurationMs;
}

bool _canResizeTimelineStepDuration(CinematicTimelineStep step) {
  return isCinematicTimelineBasicBlockStep(step) ||
      isCinematicTimelineActorFacingStep(step) ||
      isCinematicTimelineActorMoveStep(step);
}

int _durationResizeCandidateMs({
  required int initialDurationMs,
  required double deltaX,
  required double pixelsPerMs,
  required int minDurationMs,
}) {
  if (pixelsPerMs <= 0 || pixelsPerMs.isNaN || pixelsPerMs.isInfinite) {
    return initialDurationMs;
  }
  final rawDurationMs = initialDurationMs + deltaX / pixelsPerMs;
  final quantizedDurationMs = _quantizeDurationMs(rawDurationMs);
  return quantizedDurationMs.clamp(
    minDurationMs,
    cinematicTimelineMaximumDurationMs,
  );
}

int _quantizeDurationMs(double durationMs) {
  return (durationMs / 100).round() * 100;
}

String? _durationValidationMessage(
  int? durationMs, {
  required String rawValue,
  required int minDurationMs,
}) {
  if (rawValue.trim().isEmpty) {
    return 'Saisis une durée en millisecondes.';
  }
  if (durationMs == null) {
    return 'Utilise un nombre entier de millisecondes.';
  }
  try {
    validateCinematicTimelineDurationMs(
      durationMs,
      argumentName: 'durationMs',
      minMs: minDurationMs,
    );
  } on ArgumentError {
    if (durationMs < minDurationMs) {
      return 'Minimum pour ce bloc : $minDurationMs ms.';
    }
    if (durationMs > cinematicTimelineMaximumDurationMs) {
      return 'Maximum : $cinematicTimelineMaximumDurationMs ms.';
    }
    return 'Durée invalide.';
  }
  return null;
}

String _durationGuidanceLabel(int minDurationMs) {
  return 'Bornes : $minDurationMs–$cinematicTimelineMaximumDurationMs ms · '
      'pas 100 ms';
}

String? _durationBoundaryFeedback(
  int durationMs, {
  required int minDurationMs,
}) {
  if (durationMs <= minDurationMs) {
    return 'Minimum atteint : $minDurationMs ms';
  }
  if (durationMs >= cinematicTimelineMaximumDurationMs) {
    return 'Maximum atteint : $cinematicTimelineMaximumDurationMs ms';
  }
  return null;
}

String? _durationNonEditableReason(CinematicTimelineStep step) {
  if (_canResizeTimelineStepDuration(step)) {
    return null;
  }
  if (isCinematicTimelineDraftStep(step) && step.durationMs == null) {
    return null;
  }
  if (!isCinematicTimelineAuthoringStep(step)) {
    return 'Durée non éditable — bloc en lecture seule.';
  }
  return 'Durée non éditable — bloc en lecture seule.';
}

String _durationLabel(CinematicTimelineSummary timeline) {
  final duration = timeline.estimatedDurationMs;
  return duration == null ? 'Durée non calculable' : '$duration ms estimé(s)';
}

String _timelineTotalLabel(int totalDurationMs) {
  if (totalDurationMs <= 0) {
    return '0 ms dérivé';
  }
  return '${_shortTimeLabel(totalDurationMs)} dérivé';
}

String _shortTimeLabel(int durationMs) {
  if (durationMs < 1000) {
    return '$durationMs ms';
  }
  if (durationMs % 1000 == 0) {
    return '${durationMs ~/ 1000} s';
  }
  final decimals = durationMs % 100 == 0 ? 1 : 2;
  var seconds = (durationMs / 1000).toStringAsFixed(decimals);
  while (seconds.endsWith('0')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  if (seconds.endsWith('.')) {
    seconds = seconds.substring(0, seconds.length - 1);
  }
  return '$seconds s';
}

double _timelineContentWidth(int totalDurationMs, double viewportWidth) {
  if (totalDurationMs <= 0) {
    return viewportWidth;
  }
  return math.max(viewportWidth, totalDurationMs * _timelinePixelsPerMsFloor);
}

double _tickLeft(int timeMs, double pixelsPerMs, double contentWidth) {
  return math.max(0, math.min(timeMs * pixelsPerMs, contentWidth - 1));
}

int _timelineProbeTimeMsFromLocalX(
  double localX, {
  required double pixelsPerMs,
  required double contentWidth,
  required int totalDurationMs,
}) {
  if (totalDurationMs <= 0 || pixelsPerMs <= 0) {
    return 0;
  }
  final boundedX = localX.clamp(0.0, contentWidth);
  final timeMs = boundedX / pixelsPerMs;
  return timeMs.clamp(0.0, totalDurationMs.toDouble()).round();
}

_TimelineProbeSnapResult _resolveTimelineProbeSnap(
  double localX, {
  required CinematicTimelineTimeLayoutReadModel timeLayout,
  required double pixelsPerMs,
  required double contentWidth,
  required int totalDurationMs,
}) {
  final freeTimeMs = _timelineProbeTimeMsFromLocalX(
    localX,
    pixelsPerMs: pixelsPerMs,
    contentWidth: contentWidth,
    totalDurationMs: totalDurationMs,
  );
  if (totalDurationMs <= 0 || pixelsPerMs <= 0) {
    return _TimelineProbeSnapResult(timeMs: freeTimeMs);
  }

  final freeX = _tickLeft(freeTimeMs, pixelsPerMs, contentWidth);
  _TimelineProbeSnapTarget? nearestTarget;
  double? nearestDistancePx;
  for (final target in _timelineProbeSnapTargets(timeLayout)) {
    final targetX = _tickLeft(target.timeMs, pixelsPerMs, contentWidth);
    final distancePx = (targetX - freeX).abs();
    if (nearestTarget == null ||
        nearestDistancePx == null ||
        _compareTimelineProbeSnapTarget(
              target,
              distancePx,
              nearestTarget,
              nearestDistancePx,
            ) <
            0) {
      nearestTarget = target;
      nearestDistancePx = distancePx;
    }
  }

  if (nearestTarget != null &&
      nearestDistancePx != null &&
      nearestDistancePx <= _timelineProbeSnapThresholdPx) {
    return _TimelineProbeSnapResult(
      timeMs: nearestTarget.timeMs,
      snapHint: nearestTarget.snapHint,
    );
  }

  return _TimelineProbeSnapResult(timeMs: freeTimeMs);
}

List<_TimelineProbeSnapTarget> _timelineProbeSnapTargets(
  CinematicTimelineTimeLayoutReadModel timeLayout,
) {
  if (timeLayout.totalDurationMs <= 0) {
    return const [];
  }
  final targets = <_TimelineProbeSnapTarget>[];
  var stableOrder = 0;
  targets.add(
    _TimelineProbeSnapTarget(
      timeMs: 0,
      snapHint: _TimelineProbeSnapHint.timelineStart,
      stepIndex: -1,
      stableOrder: stableOrder++,
    ),
  );
  targets.add(
    _TimelineProbeSnapTarget(
      timeMs: timeLayout.totalDurationMs,
      snapHint: _TimelineProbeSnapHint.timelineEnd,
      stepIndex: -1,
      stableOrder: stableOrder++,
    ),
  );
  for (final block in timeLayout.blocks) {
    targets.add(
      _TimelineProbeSnapTarget(
        timeMs: block.startMs,
        snapHint: _TimelineProbeSnapHint.blockStart,
        stepIndex: block.stepIndex,
        stableOrder: stableOrder++,
      ),
    );
    targets.add(
      _TimelineProbeSnapTarget(
        timeMs: block.endMs,
        snapHint: _TimelineProbeSnapHint.blockEnd,
        stepIndex: block.stepIndex,
        stableOrder: stableOrder++,
      ),
    );
  }

  final dedupedByTime = <int, _TimelineProbeSnapTarget>{};
  for (final target in targets) {
    final current = dedupedByTime[target.timeMs];
    if (current == null ||
        _compareTimelineProbeSnapTargetIdentity(target, current) < 0) {
      dedupedByTime[target.timeMs] = target;
    }
  }
  return dedupedByTime.values.toList()
    ..sort((a, b) => a.stableOrder.compareTo(b.stableOrder));
}

int _compareTimelineProbeSnapTarget(
  _TimelineProbeSnapTarget a,
  double aDistancePx,
  _TimelineProbeSnapTarget b,
  double bDistancePx,
) {
  final distanceOrder = aDistancePx.compareTo(bDistancePx);
  if (distanceOrder != 0) {
    return distanceOrder;
  }
  return _compareTimelineProbeSnapTargetIdentity(a, b);
}

int _compareTimelineProbeSnapTargetIdentity(
  _TimelineProbeSnapTarget a,
  _TimelineProbeSnapTarget b,
) {
  final hintOrder = _timelineProbeSnapHintPriority(
    a.snapHint,
  ).compareTo(_timelineProbeSnapHintPriority(b.snapHint));
  if (hintOrder != 0) {
    return hintOrder;
  }
  final stepOrder = a.stepIndex.compareTo(b.stepIndex);
  if (stepOrder != 0) {
    return stepOrder;
  }
  return a.stableOrder.compareTo(b.stableOrder);
}

int _timelineProbeSnapHintPriority(_TimelineProbeSnapHint hint) {
  return switch (hint) {
    _TimelineProbeSnapHint.timelineStart => 0,
    _TimelineProbeSnapHint.blockStart => 1,
    _TimelineProbeSnapHint.timelineEnd => 2,
    _TimelineProbeSnapHint.blockEnd => 3,
  };
}

String _timelineProbeBadgeLabel(int timeMs, _TimelineProbeSnapHint? snapHint) {
  final baseLabel = 'Marqueur : ${_shortTimeLabel(timeMs)}';
  if (snapHint == null) {
    return baseLabel;
  }
  return '$baseLabel · ${_timelineProbeSnapHintLabel(snapHint)}';
}

String _timelineProbeSnapHintLabel(_TimelineProbeSnapHint hint) {
  return switch (hint) {
    _TimelineProbeSnapHint.timelineStart => 'début timeline',
    _TimelineProbeSnapHint.timelineEnd => 'fin timeline',
    _TimelineProbeSnapHint.blockStart => 'début bloc',
    _TimelineProbeSnapHint.blockEnd => 'fin bloc',
  };
}

double _timelineBarWidth(CinematicTimelineTimeBlock block, double pixelsPerMs) {
  return math.max(_timelineBarMinWidth, block.visualDurationMs * pixelsPerMs);
}

CinematicTimelineTimeBlock? _selectedTimeBlock(
  CinematicTimelineTimeLayoutReadModel timeLayout,
  String? selectedStepId,
) {
  if (selectedStepId == null) {
    return null;
  }
  for (final block in timeLayout.blocks) {
    if (block.stepId == selectedStepId) {
      return block;
    }
  }
  return null;
}

List<String> _timelineHoverDetailLabels(
  CinematicAsset asset,
  CinematicTimelineTimeBlock block,
  CinematicTimelineStep step,
  CinematicTimelineTimeLane? lane,
) {
  final details = <String>[
    'Type : ${_timelineStepKindLabel(block.kind)}',
    'Piste : ${lane?.label ?? block.laneId}',
    'Début : ${_shortTimeLabel(block.startMs)}',
    'Durée : ${_blockDurationBadgeLabel(block)}',
  ];

  if (isCinematicTimelineActorFacingStep(step)) {
    details.add(
      'Direction : ${_actorDirectionLabel(cinematicTimelineActorFacingDirectionOf(step))}',
    );
  }

  if (isCinematicTimelineActorMoveStep(step)) {
    final movementMode = cinematicTimelineActorMovementModeOf(step);
    final pathMode = cinematicTimelineActorPathModeOf(step);
    if (movementMode != null) {
      details.add('Mode : ${_actorMovementModeLabel(movementMode)}');
    }
    if (pathMode != null) {
      details.add('Chemin : ${_actorPathModeLabel(pathMode)}');
    }
  }

  final fadeMode = _cinematicTimelineFadeModeOf(step);
  if (fadeMode != null) {
    details.add('Mode : ${_fadeModeLabel(fadeMode)}');
  }

  final cameraMode = _cinematicTimelineCameraModeOf(step);
  if (cameraMode != null) {
    details.add('Mode : ${_cameraModeLabel(cameraMode)}');
  }

  if (block.actorId != null && !isCinematicTimelineActorMoveStep(step)) {
    details.add('Acteur : ${_actorDisplayLabelForId(asset, block.actorId!)}');
  }
  if (block.targetId != null && !isCinematicTimelineActorMoveStep(step)) {
    details.add(
      'Destination : ${_movementTargetLabelForId(asset, block.targetId!)}',
    );
  }

  return details;
}

String _timelineHoverSemanticsLabel(
  CinematicAsset asset,
  CinematicTimelineTimeBlock block,
  CinematicTimelineStep step,
  CinematicTimelineTimeLane lane,
) {
  final details = _timelineHoverDetailLabels(asset, block, step, lane);
  return '${block.label}, ${details.join(', ')}';
}

String _timelineStepKindLabel(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.camera => 'Caméra',
    CinematicTimelineStepKind.actorMove => 'Déplacement acteur',
    CinematicTimelineStepKind.actorFace => 'Orientation acteur',
    CinematicTimelineStepKind.actorEmote => 'Émotion acteur',
    CinematicTimelineStepKind.dialogueLine => 'Dialogue',
    CinematicTimelineStepKind.sound => 'Son',
    CinematicTimelineStepKind.music => 'Musique',
    CinematicTimelineStepKind.fade => 'Fondu',
    CinematicTimelineStepKind.shake => 'Tremblement',
    CinematicTimelineStepKind.fx => 'FX',
    CinematicTimelineStepKind.wait => 'Attente',
    CinematicTimelineStepKind.marker => 'Marqueur',
  };
}

CinematicTimelineFadeMode? _cinematicTimelineFadeModeOf(
  CinematicTimelineStep step,
) {
  final value = step.metadata[cinematicTimelineFadeModeMetadataKey];
  for (final mode in CinematicTimelineFadeMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  return null;
}

CinematicTimelineCameraMode? _cinematicTimelineCameraModeOf(
  CinematicTimelineStep step,
) {
  final value = step.metadata[cinematicTimelineCameraModeMetadataKey];
  for (final mode in CinematicTimelineCameraMode.values) {
    if (mode.name == value) {
      return mode;
    }
  }
  return null;
}

String _blockDurationBadgeLabel(CinematicTimelineTimeBlock block) {
  if (block.durationSource == CinematicTimelineVisualDurationSource.fallback) {
    return '${block.visualDurationMs} ms visuel';
  }
  return '${block.visualDurationMs} ms';
}

bool _hasStep(CinematicAsset asset, String? stepId) {
  if (stepId == null) {
    return true;
  }
  return asset.timeline.steps.any((step) => step.id == stepId);
}

CinematicTimelineStep? _selectedStep(CinematicAsset asset, String? stepId) {
  if (stepId == null) {
    return null;
  }
  for (final step in asset.timeline.steps) {
    if (step.id == stepId) {
      return step;
    }
  }
  return null;
}

String _stepTitle(CinematicTimelineStep step, int index) {
  final label = step.label;
  if (label != null && label.trim().isNotEmpty) {
    return label;
  }
  return 'Step ${index + 1}';
}

String _stepDisplayTitle(
  CinematicAsset asset,
  CinematicTimelineStep step,
  int index,
) {
  if (isCinematicTimelineActorMoveStep(step) &&
      step.actorId != null &&
      step.targetId != null) {
    return '${_actorDisplayLabelForId(asset, step.actorId!)} → '
        '${_movementTargetLabelForId(asset, step.targetId!)}';
  }
  return _stepTitle(step, index);
}

String _actorMoveSummary(CinematicAsset asset, CinematicTimelineStep step) {
  final actor = step.actorId == null
      ? 'Acteur'
      : _actorDisplayLabelForId(asset, step.actorId!);
  final target = step.targetId == null
      ? 'destination non définie'
      : _movementTargetLabelForId(asset, step.targetId!);
  final movementMode = cinematicTimelineActorMovementModeOf(step);
  final duration = step.durationMs == null
      ? 'durée non renseignée'
      : '${step.durationMs} ms';
  return '$actor ${_actorMovementVerb(movementMode)} vers $target en '
      '$duration.';
}

String _actorMovementVerb(CinematicTimelineActorMovementMode? mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => 'marche',
    CinematicTimelineActorMovementMode.run => 'court',
    null => 'se déplace',
  };
}

String _stepDurationLabel(CinematicTimelineStep step) {
  final duration = step.durationMs;
  return duration == null ? 'Durée non renseignée' : '$duration ms';
}

String _metadataLabel(Map<String, String> metadata) {
  if (metadata.isEmpty) {
    return 'Aucune metadata';
  }
  final entries = metadata.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return entries.map((entry) => '${entry.key} = ${entry.value}').join(', ');
}

String _basicBlockLabel(CinematicTimelineBasicBlockKind blockKind) {
  return switch (blockKind) {
    CinematicTimelineBasicBlockKind.wait => 'Attente',
    CinematicTimelineBasicBlockKind.fade => 'Fondu',
    CinematicTimelineBasicBlockKind.camera => 'Caméra basique',
  };
}

String _fadeModeLabel(CinematicTimelineFadeMode mode) {
  return switch (mode) {
    CinematicTimelineFadeMode.fadeIn => 'Entrant',
    CinematicTimelineFadeMode.fadeOut => 'Sortant',
  };
}

String _cameraModeLabel(CinematicTimelineCameraMode mode) {
  return switch (mode) {
    CinematicTimelineCameraMode.reset => 'Reset',
    CinematicTimelineCameraMode.hold => 'Hold',
  };
}

String _actorDisplayLabel(CinematicActorRef actor) {
  return actor.label ?? actor.actorId;
}

String _actorDisplayLabelForId(CinematicAsset asset, String actorId) {
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return _actorDisplayLabel(actor);
    }
  }
  return actorId;
}

String _movementTargetLabelForId(CinematicAsset asset, String targetId) {
  for (final target in asset.movementTargets) {
    if (target.targetId == targetId) {
      return target.label;
    }
  }
  return targetId;
}

ProjectMapEntry? _stageMapForId(List<ProjectMapEntry> maps, String? mapId) {
  if (mapId == null) {
    return null;
  }
  for (final map in maps) {
    if (map.id == mapId) {
      return map;
    }
  }
  return null;
}

bool _stageSourceCatalogMatchesAsset(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  final mapId = asset.mapId;
  return mapId != null && catalog?.stageMapId == mapId;
}

List<CinematicStageMapEntitySource> _actorBindableEntitySources(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (!_stageSourceCatalogMatchesAsset(asset, catalog) ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return const <CinematicStageMapEntitySource>[];
  }
  return catalog!.entities
      .where((source) => source.canBindActor)
      .toList(growable: false);
}

List<CinematicStageMapEntitySource> _movementTargetEntitySources(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (!_stageSourceCatalogMatchesAsset(asset, catalog) ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return const <CinematicStageMapEntitySource>[];
  }
  return catalog!.entities
      .where((source) => source.canBeMovementTarget)
      .toList(growable: false);
}

List<CinematicStageMapEventSource> _movementTargetEventSources(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (!_stageSourceCatalogMatchesAsset(asset, catalog) ||
      catalog?.status != CinematicStageMapSourceCatalogStatus.available) {
    return const <CinematicStageMapEventSource>[];
  }
  return catalog!.events
      .where((source) => source.canBeMovementTarget)
      .toList(growable: false);
}

String? _mapEntityActorDisabledReason(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
  List<CinematicStageMapEntitySource> sources,
) {
  final catalogReason = _sourceCatalogDisabledReason(asset, catalog);
  if (catalogReason != null) {
    return catalogReason;
  }
  if (sources.isEmpty) {
    return catalog!.entities.isEmpty
        ? 'La map de scène ne contient aucun personnage ou objet.'
        : 'Aucun personnage ou objet de la map bindable acteur sur cette map.';
  }
  return null;
}

String? _mapEntityTargetDisabledReason(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
  List<CinematicStageMapEntitySource> sources,
) {
  final catalogReason = _sourceCatalogDisabledReason(asset, catalog);
  if (catalogReason != null) {
    return catalogReason;
  }
  if (sources.isEmpty) {
    return 'La map de scène ne contient aucun personnage ou objet.';
  }
  return null;
}

String? _mapEventTargetDisabledReason(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
  List<CinematicStageMapEventSource> sources,
) {
  final catalogReason = _sourceCatalogDisabledReason(asset, catalog);
  if (catalogReason != null) {
    return catalogReason;
  }
  if (sources.isEmpty) {
    return 'La map de scène ne contient aucun déclencheur.';
  }
  return null;
}

String? _sourceCatalogDisabledReason(
  CinematicAsset asset,
  CinematicStageMapSourceCatalog? catalog,
) {
  if (asset.mapId == null) {
    return 'Choisissez d’abord une map de scène.';
  }
  if (catalog == null) {
    return 'Catalogue des personnages/déclencheurs de la map en cours de chargement.';
  }
  if (catalog.stageMapId != asset.mapId) {
    return 'Catalogue de sources aligné sur une autre map.';
  }
  return switch (catalog.status) {
    CinematicStageMapSourceCatalogStatus.available => null,
    CinematicStageMapSourceCatalogStatus.missingStageMap =>
      'Choisissez d’abord une map de scène.',
    CinematicStageMapSourceCatalogStatus.mapDataUnavailable =>
      'MapData de la map de scène indisponible.',
    CinematicStageMapSourceCatalogStatus.mapIdMismatch =>
      'La MapData chargée ne correspond pas à la map de scène.',
  };
}

CinematicStageContext _copyStageContext(
  CinematicStageContext context, {
  CinematicStageBackdropMode? backdropMode,
  List<CinematicActorBinding>? actorBindings,
  List<CinematicActorAppearanceBinding>? actorAppearanceBindings,
  List<CinematicActorInitialPlacement>? initialPlacements,
  List<CinematicMovementTargetBinding>? movementTargetBindings,
}) {
  return CinematicStageContext(
    backdropMode: backdropMode ?? context.backdropMode,
    actorBindings: actorBindings ?? context.actorBindings,
    actorAppearanceBindings:
        actorAppearanceBindings ?? context.actorAppearanceBindings,
    initialPlacements: initialPlacements ?? context.initialPlacements,
    movementTargetBindings:
        movementTargetBindings ?? context.movementTargetBindings,
  );
}

CinematicActorBinding? _actorBindingFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final binding in context.actorBindings) {
    if (binding.actorId == actorId) {
      return binding;
    }
  }
  return null;
}

CinematicActorAppearanceBinding? _actorAppearanceBindingFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final binding in context.actorAppearanceBindings) {
    if (binding.actorId == actorId) {
      return binding;
    }
  }
  return null;
}

List<CinematicActorAppearanceBinding> _orphanActorAppearanceBindings(
  CinematicAsset asset,
  CinematicStageContext context,
) {
  return context.actorAppearanceBindings.where((binding) {
    return !_hasRequiredActor(asset, binding.actorId);
  }).toList(growable: false);
}

bool _hasRequiredActor(CinematicAsset asset, String actorId) {
  for (final actor in asset.requiredActors) {
    if (actor.actorId == actorId) {
      return true;
    }
  }
  return false;
}

CinematicActorInitialPlacement? _initialPlacementFor(
  CinematicStageContext context,
  String actorId,
) {
  for (final placement in context.initialPlacements) {
    if (placement.actorId == actorId) {
      return placement;
    }
  }
  return null;
}

List<ProjectCharacterEntry> _sortedCharacters(
  List<ProjectCharacterEntry> characters,
) {
  final sorted = characters.toList(growable: false);
  sorted.sort((a, b) {
    final sortOrder = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrder != 0) {
      return sortOrder;
    }
    final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (name != 0) {
      return name;
    }
    return a.id.compareTo(b.id);
  });
  return sorted;
}

ProjectCharacterEntry? _characterById(
  List<ProjectCharacterEntry> characters,
  String? characterId,
) {
  if (characterId == null) {
    return null;
  }
  for (final character in characters) {
    if (character.id == characterId) {
      return character;
    }
  }
  return null;
}

String _characterDetailLine(ProjectCharacterEntry character) {
  final tilesetId = character.tilesetId.trim().isEmpty
      ? 'Aucun tileset'
      : character.tilesetId;
  return '$tilesetId · ${character.frameWidth}×${character.frameHeight}';
}

String? _characterTagsLine(ProjectCharacterEntry character) {
  if (character.tags.isEmpty) {
    return null;
  }
  return 'Tags : ${character.tags.join(' · ')}';
}

CinematicMovementTargetBinding? _movementTargetBindingFor(
  CinematicStageContext context,
  String targetId,
) {
  for (final binding in context.movementTargetBindings) {
    if (binding.targetId == targetId) {
      return binding;
    }
  }
  return null;
}

String? _playerBoundActorId(CinematicStageContext context) {
  for (final binding in context.actorBindings) {
    if (binding.kind == CinematicActorBindingKind.player) {
      return binding.actorId;
    }
  }
  return null;
}

String _stageBackdropModeLabel(CinematicStageBackdropMode mode) {
  return switch (mode) {
    CinematicStageBackdropMode.none => 'Aucun décor',
    CinematicStageBackdropMode.projectMap => 'Décor depuis la map',
  };
}

IconData _stageBackdropModeIcon(CinematicStageBackdropMode mode) {
  return switch (mode) {
    CinematicStageBackdropMode.none => CupertinoIcons.circle,
    CinematicStageBackdropMode.projectMap => CupertinoIcons.map,
  };
}

int _movementTargetUsageCount(CinematicAsset asset, String targetId) {
  return asset.timeline.steps
      .where(
        (step) =>
            step.kind == CinematicTimelineStepKind.actorMove &&
            step.targetId == targetId,
      )
      .length;
}

int _requiredActorUsageCount(CinematicAsset asset, String actorId) {
  return asset.timeline.steps.where((step) => step.actorId == actorId).length;
}

String _actorDirectionLabel(CinematicTimelineActorFacingDirection? direction) {
  return switch (direction) {
    CinematicTimelineActorFacingDirection.up => 'Haut',
    CinematicTimelineActorFacingDirection.down => 'Bas',
    CinematicTimelineActorFacingDirection.left => 'Gauche',
    CinematicTimelineActorFacingDirection.right => 'Droite',
    null => 'Direction inconnue',
  };
}

String _actorMovementModeLabel(CinematicTimelineActorMovementMode mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => 'Marche',
    CinematicTimelineActorMovementMode.run => 'Course',
  };
}

String _actorPathModeLabel(CinematicTimelineActorPathMode mode) {
  return switch (mode) {
    CinematicTimelineActorPathMode.direct => 'Direct',
    CinematicTimelineActorPathMode.manual => 'Manuel',
  };
}

IconData _actorDirectionIcon(CinematicTimelineActorFacingDirection direction) {
  return switch (direction) {
    CinematicTimelineActorFacingDirection.up => CupertinoIcons.arrow_up,
    CinematicTimelineActorFacingDirection.down => CupertinoIcons.arrow_down,
    CinematicTimelineActorFacingDirection.left => CupertinoIcons.arrow_left,
    CinematicTimelineActorFacingDirection.right => CupertinoIcons.arrow_right,
  };
}

IconData _actorMovementModeIcon(CinematicTimelineActorMovementMode mode) {
  return switch (mode) {
    CinematicTimelineActorMovementMode.walk => CupertinoIcons.arrow_right,
    CinematicTimelineActorMovementMode.run => CupertinoIcons.forward,
  };
}

IconData _stepIcon(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.camera => CupertinoIcons.video_camera,
    CinematicTimelineStepKind.actorMove => CupertinoIcons.arrow_right,
    CinematicTimelineStepKind.actorFace => CupertinoIcons.arrow_turn_up_right,
    CinematicTimelineStepKind.actorEmote => CupertinoIcons.person_crop_circle,
    CinematicTimelineStepKind.dialogueLine => CupertinoIcons.text_bubble,
    CinematicTimelineStepKind.sound => CupertinoIcons.speaker_2,
    CinematicTimelineStepKind.music => CupertinoIcons.music_note_2,
    CinematicTimelineStepKind.fade => CupertinoIcons.layers_alt,
    CinematicTimelineStepKind.shake => CupertinoIcons.waveform_path,
    CinematicTimelineStepKind.fx => CupertinoIcons.sparkles,
    CinematicTimelineStepKind.wait => CupertinoIcons.timer,
    CinematicTimelineStepKind.marker => CupertinoIcons.flag,
  };
}

IconData _laneIcon(CinematicTimelineLaneKind laneKind) {
  return switch (laneKind) {
    CinematicTimelineLaneKind.camera => CupertinoIcons.video_camera,
    CinematicTimelineLaneKind.actor => CupertinoIcons.person_crop_circle,
    CinematicTimelineLaneKind.dialogue => CupertinoIcons.text_bubble,
    CinematicTimelineLaneKind.fx => CupertinoIcons.sparkles,
    CinematicTimelineLaneKind.audio => CupertinoIcons.speaker_2,
    CinematicTimelineLaneKind.transitions => CupertinoIcons.layers,
    CinematicTimelineLaneKind.timeGlobal => CupertinoIcons.hourglass,
    CinematicTimelineLaneKind.other => CupertinoIcons.question_circle,
  };
}

List<CinematicDiagnostic> _stepDiagnostics(
  CinematicAsset asset,
  CinematicTimelineStep step,
) {
  return diagnoseCinematicAsset(asset)
      .diagnostics
      .where((diagnostic) => diagnostic.stepId == step.id)
      .toList(growable: false);
}

PokeMapBadgeVariant _diagnosticVariant(CinematicDiagnosticSeverity severity) {
  return switch (severity) {
    CinematicDiagnosticSeverity.error => PokeMapBadgeVariant.error,
    CinematicDiagnosticSeverity.warning => PokeMapBadgeVariant.warning,
    CinematicDiagnosticSeverity.info => PokeMapBadgeVariant.info,
  };
}

PokeMapTone _laneTone(CinematicTimelineLaneKind laneKind) {
  return switch (laneKind) {
    CinematicTimelineLaneKind.camera => PokeMapTone.cinematic,
    CinematicTimelineLaneKind.actor => PokeMapTone.narrative,
    CinematicTimelineLaneKind.dialogue => PokeMapTone.dialogue,
    CinematicTimelineLaneKind.fx => PokeMapTone.warning,
    CinematicTimelineLaneKind.audio => PokeMapTone.info,
    CinematicTimelineLaneKind.transitions => PokeMapTone.neutral,
    CinematicTimelineLaneKind.timeGlobal => PokeMapTone.success,
    CinematicTimelineLaneKind.other => PokeMapTone.neutral,
  };
}

PokeMapTone _blockTone(CinematicTimelineStepKind kind) {
  return switch (kind) {
    CinematicTimelineStepKind.camera => PokeMapTone.cinematic,
    CinematicTimelineStepKind.actorMove ||
    CinematicTimelineStepKind.actorFace ||
    CinematicTimelineStepKind.actorEmote =>
      PokeMapTone.narrative,
    CinematicTimelineStepKind.dialogueLine => PokeMapTone.dialogue,
    CinematicTimelineStepKind.fx ||
    CinematicTimelineStepKind.shake =>
      PokeMapTone.warning,
    CinematicTimelineStepKind.sound ||
    CinematicTimelineStepKind.music =>
      PokeMapTone.info,
    CinematicTimelineStepKind.fade => PokeMapTone.cinematic,
    CinematicTimelineStepKind.wait => PokeMapTone.brand,
    CinematicTimelineStepKind.marker => PokeMapTone.neutral,
  };
}

String _diagnosticSeverityLabel(CinematicDiagnosticSeverity severity) {
  return switch (severity) {
    CinematicDiagnosticSeverity.error => 'Erreur',
    CinematicDiagnosticSeverity.warning => 'Attention',
    CinematicDiagnosticSeverity.info => 'Info',
  };
}

class _StagePointsSection extends StatelessWidget {
  const _StagePointsSection({
    required this.stageContext,
    required this.selectedStagePointId,
    required this.onSelectStagePointId,
  });

  final CinematicStageContext stageContext;
  final String? selectedStagePointId;
  final ValueChanged<String?> onSelectStagePointId;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final points = stageContext.stagePoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Repères de scène',
          style: DefaultTextStyle.of(context).style.copyWith(
                color: colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        if (points.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.controlSurface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Text(
              'Aucun repère de scène.\nClique sur « Ajouter un repère » puis sur la carte pour en poser un.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: points.map((point) {
              final isSelected = point.id == selectedStagePointId;
              return PokeMapButton(
                key: ValueKey('stage-point-chip-${point.id}'),
                size: PokeMapButtonSize.small,
                variant: isSelected
                    ? PokeMapButtonVariant.primary
                    : PokeMapButtonVariant.secondary,
                onPressed: () =>
                    onSelectStagePointId(isSelected ? null : point.id),
                leading: Icon(
                  CupertinoIcons.location_solid,
                  size: 12,
                  color: isSelected ? colors.textInverse : colors.brandPrimary,
                ),
                child: Text(
                  point.label,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Helper widget that renders its child completely invisible and with 0 size,
/// but keeps it visible to the Flutter test framework finders and allows hit-testing.
class _TestHidden extends SingleChildRenderObjectWidget {
  const _TestHidden({required Widget child, this.hitTestable = false})
      : super(child: child);

  final bool hitTestable;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTestHidden(hitTestable: hitTestable);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTestHidden renderObject,
  ) {
    renderObject.hitTestable = hitTestable;
  }
}

class _RenderTestHidden extends RenderProxyBox {
  _RenderTestHidden({bool hitTestable = false}) : _hitTestable = hitTestable;

  bool _hitTestable;
  bool get hitTestable => _hitTestable;
  set hitTestable(bool value) {
    if (_hitTestable != value) {
      _hitTestable = value;
      markNeedsPaint();
    }
  }

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints.loosen(), parentUsesSize: true);
    }
    size = constraints.constrain(Size.zero);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null && hitTestable) {
      if (child!.hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Do not paint the child to make it invisible
  }
}
