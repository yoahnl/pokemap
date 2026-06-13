import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_actor_display_preview_overlay.dart';
import 'cinematic_actor_sprite_preview_plan.dart';
import 'cinematic_backdrop_preview_framing.dart';
import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_layer_renderer.dart';
import 'cinematic_map_backdrop_render_pass.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_map_backdrop_tile_renderer.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';
import 'cinematic_map_backdrop_visual_primitives_painter.dart';
import 'cinematic_playback_preview_fallback_summary.dart';
import 'cinematic_preview_playback_actor_overlay_adapter.dart';
import 'cinematic_stage_point_preview_overlay.dart';
import 'cinematic_stage_preview_readiness.dart';
import 'cinematic_manual_path_preview_overlay.dart';

final class CinematicPlaybackPreviewStatus {
  const CinematicPlaybackPreviewStatus({
    required this.playbackLabel,
    required this.playbackTone,
    required this.actorAnimationLabel,
    required this.actorAnimationTone,
    this.fallbackSummary =
        const CinematicPlaybackPreviewFallbackSummary.empty(),
  });

  const CinematicPlaybackPreviewStatus.staticPreview()
      : playbackLabel = 'Aperçu statique',
        playbackTone = PokeMapTone.neutral,
        actorAnimationLabel = 'Animation acteur prête',
        actorAnimationTone = PokeMapTone.info,
        fallbackSummary = const CinematicPlaybackPreviewFallbackSummary.empty();

  final String playbackLabel;
  final PokeMapTone playbackTone;
  final String actorAnimationLabel;
  final PokeMapTone actorAnimationTone;
  final CinematicPlaybackPreviewFallbackSummary fallbackSummary;
}

class CinematicMapBackdropPreviewPanel extends StatelessWidget {
  const CinematicMapBackdropPreviewPanel({
    super.key,
    required this.model,
    this.asset,
    required this.compact,
    required this.readiness,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    this.playbackPreviewStatus =
        const CinematicPlaybackPreviewStatus.staticPreview(),
    this.framingState = const CinematicBackdropPreviewFramingState(),
    this.selectedStep,
    this.onFramingModeChanged,
    this.onFramingZoomChanged,
    this.onFramingPanChanged,
    this.onFramingResetView,
    this.onFramingDetailsChanged,
    this.onFramingGridChanged,
    this.stagePoints = const [],
    this.selectedStagePointId,
    this.addStagePointMode = false,
    this.onSelectStagePointId,
    this.onUpdateStagePoint,
    this.onAddStagePointAtTile,
    this.onAddStagePointModeChanged,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicAsset? asset;
  final bool compact;
  final CinematicStagePreviewReadiness readiness;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;
  final CinematicBackdropPreviewFramingState framingState;
  final CinematicTimelineStep? selectedStep;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
  final ValueChanged<double>? onFramingZoomChanged;
  final ValueChanged<Offset>? onFramingPanChanged;
  final VoidCallback? onFramingResetView;
  final ValueChanged<bool>? onFramingDetailsChanged;
  final ValueChanged<bool>? onFramingGridChanged;
  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final bool addStagePointMode;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<Offset>? onAddStagePointAtTile;
  final ValueChanged<bool>? onAddStagePointModeChanged;

  @override
  Widget build(BuildContext context) {
    final isSceneMode =
        framingState.mode == CinematicBackdropPreviewFramingMode.scene;
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isSceneMode) ...[
          _BackdropHeader(
            model: model,
            actorDisplayPreviewModel: actorDisplayPreviewModel,
            compact: compact,
            readiness: readiness,
            playbackPreviewStatus: playbackPreviewStatus,
          ),
          SizedBox(height: compact ? 8 : 12),
        ],
        Expanded(
          child: model.isAvailable
              ? _BackdropMapFrame(
                  model: model,
                  asset: asset,
                  compact: compact,
                  tileRenderPlan: tileRenderPlan,
                  layerRenderPlan: layerRenderPlan,
                  actorDisplayPreviewModel: actorDisplayPreviewModel,
                  actorPlaybackPreviewModel: actorPlaybackPreviewModel,
                  actorSpritePreviewPlan: actorSpritePreviewPlan,
                  playbackPreviewStatus: playbackPreviewStatus,
                  framingState: framingState,
                  selectedStep: selectedStep,
                  onFramingModeChanged: onFramingModeChanged,
                  onFramingZoomChanged: onFramingZoomChanged,
                  onFramingPanChanged: onFramingPanChanged,
                  onFramingResetView: onFramingResetView,
                  onFramingDetailsChanged: onFramingDetailsChanged,
                  onFramingGridChanged: onFramingGridChanged,
                  stagePoints: stagePoints,
                  selectedStagePointId: selectedStagePointId,
                  addStagePointMode: addStagePointMode,
                  onSelectStagePointId: onSelectStagePointId,
                  onUpdateStagePoint: onUpdateStagePoint,
                  onAddStagePointAtTile: onAddStagePointAtTile,
                  onAddStagePointModeChanged: onAddStagePointModeChanged,
                )
              : _BackdropFallback(model: model, compact: compact),
        ),
        if (!compact && !isSceneMode) ...[
          const SizedBox(height: 10),
          _BackdropDiagnostics(
            model: model,
            actorDisplayPreviewModel: actorDisplayPreviewModel,
          ),
        ],
      ],
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({
    required this.model,
    required this.actorDisplayPreviewModel,
    required this.compact,
    required this.readiness,
    required this.playbackPreviewStatus,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final bool compact;
  final CinematicStagePreviewReadiness readiness;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final titleStyle = DefaultTextStyle.of(context).style.copyWith(
          color: colors.textPrimary,
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w900,
        );
    final metaStyle = DefaultTextStyle.of(context).style.copyWith(
          color: colors.textMuted,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w700,
        );
    final itemsToComplete = readiness.items
            .where((i) => i.kind != CinematicStagePreviewReadinessItemKind.ok)
            .length +
        readiness.diagnostics.length;
    final hasActorDisplayEntries =
        _hasActorDisplayEntries(actorDisplayPreviewModel);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokeMapIconTile(
          icon: CupertinoIcons.map,
          tone: PokeMapTone.map,
          size: compact ? 26 : 28,
          iconSize: compact ? 14 : 15,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Carte du projet (statique)', style: titleStyle),
              const SizedBox(height: 2),
              Wrap(
                spacing: 7,
                runSpacing: 5,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (model.mapLabel != null)
                    Text(
                      model.mapLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  if (model.sizeSummary != null)
                    Text(
                      model.sizeSummary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle,
                    ),
                  PokeMapBadge(
                    label: readiness.kind ==
                            CinematicStagePreviewReadinessKind.ready
                        ? 'Scène prête'
                        : '$itemsToComplete élément(s) à compléter',
                    variant: readiness.kind ==
                            CinematicStagePreviewReadinessKind.ready
                        ? PokeMapBadgeVariant.success
                        : PokeMapBadgeVariant.warning,
                  ),
                  if (!hasActorDisplayEntries) ...[
                    const PokeMapBadge(
                      label: 'Décor seul',
                      variant: PokeMapBadgeVariant.info,
                    ),
                    const PokeMapBadge(
                      label: 'Sans acteurs',
                      variant: PokeMapBadgeVariant.neutral,
                    ),
                  ] else ...[
                    _BackdropMetaPill(
                      label: playbackPreviewStatus.actorAnimationLabel,
                      tone: playbackPreviewStatus.actorAnimationTone,
                    ),
                    _BackdropMetaPill(
                      label: _placedActorsLabel(actorDisplayPreviewModel!),
                      tone: PokeMapTone.success,
                    ),
                    if (_actorCompletionCount(actorDisplayPreviewModel!) > 0)
                      _BackdropMetaPill(
                        label:
                            '${_actorCompletionCount(actorDisplayPreviewModel!)} à compléter',
                        tone: PokeMapTone.warning,
                      ),
                    const _BackdropMetaPill(
                      label: 'Placeholders',
                    ),
                  ],
                  _BackdropMetaPill(
                    label: playbackPreviewStatus.playbackLabel,
                    tone: playbackPreviewStatus.playbackTone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackdropMapFrame extends StatelessWidget {
  const _BackdropMapFrame({
    required this.model,
    this.asset,
    required this.compact,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    required this.playbackPreviewStatus,
    required this.framingState,
    this.selectedStep,
    this.onFramingModeChanged,
    this.onFramingZoomChanged,
    this.onFramingPanChanged,
    this.onFramingResetView,
    this.onFramingDetailsChanged,
    this.onFramingGridChanged,
    required this.stagePoints,
    required this.selectedStagePointId,
    required this.addStagePointMode,
    required this.onSelectStagePointId,
    required this.onUpdateStagePoint,
    required this.onAddStagePointAtTile,
    this.onAddStagePointModeChanged,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicAsset? asset;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;
  final CinematicBackdropPreviewFramingState framingState;
  final CinematicTimelineStep? selectedStep;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
  final ValueChanged<double>? onFramingZoomChanged;
  final ValueChanged<Offset>? onFramingPanChanged;
  final VoidCallback? onFramingResetView;
  final ValueChanged<bool>? onFramingDetailsChanged;
  final ValueChanged<bool>? onFramingGridChanged;
  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final bool addStagePointMode;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<Offset>? onAddStagePointAtTile;
  final ValueChanged<bool>? onAddStagePointModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final spatialPrimitives = _spatialPrimitives(model.visualPrimitives);
    final layerBitmapPlan = layerRenderPlan;
    final bitmapPlan = tileRenderPlan;
    final isSceneMode =
        framingState.mode == CinematicBackdropPreviewFramingMode.scene;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSceneMode
            ? 4
            : compact
                ? 7
                : 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCompact = compact || constraints.maxHeight < 220;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: layerBitmapPlan != null &&
                          layerBitmapPlan.hasBitmapInstructions
                      ? _BackdropLayerBitmapMap(
                          model: model,
                          asset: asset,
                          plan: layerBitmapPlan,
                          compact: effectiveCompact,
                          actorDisplayPreviewModel: actorDisplayPreviewModel,
                          actorPlaybackPreviewModel: actorPlaybackPreviewModel,
                          actorSpritePreviewPlan: actorSpritePreviewPlan,
                          playbackPreviewStatus: playbackPreviewStatus,
                          framingState: framingState,
                          selectedStep: selectedStep,
                          onFramingModeChanged: onFramingModeChanged,
                          onFramingZoomChanged: onFramingZoomChanged,
                          onFramingPanChanged: onFramingPanChanged,
                          onFramingResetView: onFramingResetView,
                          onFramingDetailsChanged: onFramingDetailsChanged,
                          onFramingGridChanged: onFramingGridChanged,
                          stagePoints: stagePoints,
                          selectedStagePointId: selectedStagePointId,
                          addStagePointMode: addStagePointMode,
                          onSelectStagePointId: onSelectStagePointId,
                          onUpdateStagePoint: onUpdateStagePoint,
                          onAddStagePointAtTile: onAddStagePointAtTile,
                          onAddStagePointModeChanged:
                              onAddStagePointModeChanged,
                        )
                      : bitmapPlan != null && bitmapPlan.hasBitmapInstructions
                          ? _BackdropBitmapMap(
                              model: model,
                              asset: asset,
                              plan: bitmapPlan,
                              compact: effectiveCompact,
                              actorDisplayPreviewModel:
                                  actorDisplayPreviewModel,
                              actorPlaybackPreviewModel:
                                  actorPlaybackPreviewModel,
                              actorSpritePreviewPlan: actorSpritePreviewPlan,
                              playbackPreviewStatus: playbackPreviewStatus,
                              framingState: framingState,
                              selectedStep: selectedStep,
                              onFramingModeChanged: onFramingModeChanged,
                              onFramingZoomChanged: onFramingZoomChanged,
                              onFramingPanChanged: onFramingPanChanged,
                              onFramingResetView: onFramingResetView,
                              onFramingDetailsChanged: onFramingDetailsChanged,
                              onFramingGridChanged: onFramingGridChanged,
                              stagePoints: stagePoints,
                              selectedStagePointId: selectedStagePointId,
                              addStagePointMode: addStagePointMode,
                              onSelectStagePointId: onSelectStagePointId,
                              onUpdateStagePoint: onUpdateStagePoint,
                              onAddStagePointAtTile: onAddStagePointAtTile,
                              onAddStagePointModeChanged:
                                  onAddStagePointModeChanged,
                            )
                          : spatialPrimitives.isEmpty
                              ? DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: colors.surfaceSubtle,
                                    border: Border.all(
                                      color: colors.controlBorder,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: _BackdropMutedText(
                                      'Aucune couche visuelle lisible.',
                                      compact: effectiveCompact,
                                    ),
                                  ),
                                )
                              : _BackdropVisualPrimitiveMap(
                                  model: model,
                                  primitives: spatialPrimitives,
                                  compact: effectiveCompact,
                                  tileRenderPlan: bitmapPlan,
                                  layerRenderPlan: layerBitmapPlan,
                                  actorDisplayPreviewModel:
                                      actorDisplayPreviewModel,
                                  actorPlaybackPreviewModel:
                                      actorPlaybackPreviewModel,
                                  playbackPreviewStatus: playbackPreviewStatus,
                                ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackdropBitmapMap extends StatelessWidget {
  const _BackdropBitmapMap({
    required this.model,
    this.asset,
    required this.plan,
    required this.compact,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    required this.playbackPreviewStatus,
    required this.framingState,
    this.selectedStep,
    this.onFramingModeChanged,
    this.onFramingZoomChanged,
    this.onFramingPanChanged,
    this.onFramingResetView,
    this.onFramingDetailsChanged,
    this.onFramingGridChanged,
    required this.stagePoints,
    required this.selectedStagePointId,
    required this.addStagePointMode,
    required this.onSelectStagePointId,
    required this.onUpdateStagePoint,
    required this.onAddStagePointAtTile,
    this.onAddStagePointModeChanged,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicAsset? asset;
  final CinematicMapBackdropTileRenderPlan plan;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;
  final CinematicBackdropPreviewFramingState framingState;
  final CinematicTimelineStep? selectedStep;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
  final ValueChanged<double>? onFramingZoomChanged;
  final ValueChanged<Offset>? onFramingPanChanged;
  final VoidCallback? onFramingResetView;
  final ValueChanged<bool>? onFramingDetailsChanged;
  final ValueChanged<bool>? onFramingGridChanged;
  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final bool addStagePointMode;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<Offset>? onAddStagePointAtTile;
  final ValueChanged<bool>? onAddStagePointModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final palette = CinematicMapBackdropTileRenderPalette(
      background: colors.controlSurface,
      border: colors.controlBorder,
      grid: colors.borderSubtle,
    );
    final isSceneMode =
        framingState.mode == CinematicBackdropPreviewFramingMode.scene;
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-bitmap'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact && !isSceneMode) ...[
          _BackdropMetaBar(
            model: model,
            primitiveCount: plan.instructions.length,
            compact: compact,
            bitmapPlan: plan,
            actorDisplayPreviewModel: actorDisplayPreviewModel,
            playbackPreviewStatus: playbackPreviewStatus,
          ),
          const SizedBox(height: 8),
        ],
        _BackdropFramingControls(
          state: framingState,
          compact: compact,
          model: model,
          primitiveCount: plan.instructions.length,
          hasBitmapInstructions: plan.hasBitmapInstructions,
          onModeChanged: onFramingModeChanged,
          onZoomChanged: onFramingZoomChanged,
          onResetView: onFramingResetView,
          onDetailsChanged: onFramingDetailsChanged,
          onGridChanged: onFramingGridChanged,
          addStagePointMode: addStagePointMode,
          onAddStagePointModeChanged: onAddStagePointModeChanged,
        ),
        if (isSceneMode && framingState.showDetails) ...[
          SizedBox(height: compact ? 5 : 6),
          _BackdropDetailsPanel(
            child: _BackdropMetaBar(
              model: model,
              primitiveCount: plan.instructions.length,
              compact: true,
              bitmapPlan: plan,
              actorDisplayPreviewModel: actorDisplayPreviewModel,
              playbackPreviewStatus: playbackPreviewStatus,
            ),
          ),
        ],
        SizedBox(
            height: isSceneMode
                ? 3
                : compact
                    ? 6
                    : 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              border: Border.all(color: colors.controlBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSceneMode
                  ? 3
                  : compact
                      ? 4
                      : 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final focus = resolveCinematicBackdropPreviewFocus(
                    mapWidth: plan.mapWidth,
                    mapHeight: plan.mapHeight,
                    actorDisplayPreviewModel: actorDisplayPreviewModel,
                    selectedStep: selectedStep,
                  );
                  final framing = resolveCinematicBackdropPreviewFraming(
                    viewportSize: constraints.biggest,
                    mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
                    mapWidth: plan.mapWidth,
                    mapHeight: plan.mapHeight,
                    state: framingState,
                    focus: focus,
                  );
                  return MouseRegion(
                    cursor: addStagePointMode
                        ? SystemMouseCursors.precise
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        if (addStagePointMode &&
                            onAddStagePointAtTile != null) {
                          final localOffset = details.localPosition;
                          if (framing.transform.frame.contains(localOffset)) {
                            final tileCoord =
                                framing.transform.previewToTile(localOffset);
                            if (framing.transform
                                .isTileInsideMap(tileCoord.dx, tileCoord.dy)) {
                              final snappedX = tileCoord.dx.floor() + 0.5;
                              final snappedY = tileCoord.dy.floor() + 0.5;
                              onAddStagePointAtTile!(
                                  Offset(snappedX, snappedY));
                            }
                          }
                        } else {
                          onSelectStagePointId?.call(null);
                        }
                      },
                      onPanUpdate: isSceneMode && onFramingPanChanged != null
                          ? (details) {
                              onFramingPanChanged!(
                                framing.panTiles +
                                    _dragDeltaToPanTiles(
                                      details.delta,
                                      framing.transform.frame,
                                      plan.mapWidth,
                                      plan.mapHeight,
                                    ),
                              );
                            }
                          : null,
                      child: RepaintBoundary(
                        key: const ValueKey(
                          'cinematic-builder-map-backdrop-bitmap-viewport',
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ClipRect(
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned.fromRect(
                                  rect: framing.transform.frame,
                                  child: SizedBox(
                                    key: const ValueKey(
                                      'cinematic-builder-map-backdrop-map-frame',
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CustomPaint(
                                          painter:
                                              CinematicMapBackdropTileRenderPainter(
                                            plan: plan,
                                            palette: palette,
                                            paintGrid: !isSceneMode ||
                                                framingState.showGrid,
                                          ),
                                          child: const SizedBox.expand(),
                                        ),
                                        if ((actorPlaybackPreviewModel
                                                    ?.displayModel ??
                                                actorDisplayPreviewModel) !=
                                            null)
                                          CinematicActorDisplayPreviewOverlay(
                                            model: actorPlaybackPreviewModel
                                                    ?.displayModel ??
                                                actorDisplayPreviewModel!,
                                            playbackPoseOverrides:
                                                actorPlaybackPreviewModel
                                                        ?.poseOverrides ??
                                                    const {},
                                            spritePreviewPlan:
                                                actorSpritePreviewPlan,
                                            tilesets: plan.tilesets,
                                            mapWidth: plan.mapWidth,
                                            mapHeight: plan.mapHeight,
                                            compact: compact,
                                          ),
                                        CinematicStagePointPreviewOverlay(
                                          stagePoints: stagePoints,
                                          selectedStagePointId:
                                              selectedStagePointId,
                                          onSelectStagePointId:
                                              onSelectStagePointId ?? (_) {},
                                          onUpdateStagePoint:
                                              onUpdateStagePoint ?? (_) {},
                                          transform:
                                              CinematicMapBackdropViewportTransform
                                                  .fill(
                                            viewportSize:
                                                framing.transform.frame.size,
                                            mapWidth: plan.mapWidth,
                                            mapHeight: plan.mapHeight,
                                          ),
                                          compact: compact,
                                        ),
                                        if (selectedStep != null &&
                                            asset != null)
                                          CinematicManualPathPreviewOverlay(
                                            asset: asset!,
                                            selectedStep: selectedStep!,
                                            actorDisplayPreviewModel:
                                                actorDisplayPreviewModel,
                                            visualPrimitives:
                                                model.visualPrimitives,
                                            transform:
                                                CinematicMapBackdropViewportTransform
                                                    .fill(
                                              viewportSize:
                                                  framing.transform.frame.size,
                                              mapWidth: plan.mapWidth,
                                              mapHeight: plan.mapHeight,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSceneMode)
                                  Positioned(
                                    left: 8,
                                    bottom: 8,
                                    child: _BackdropPanBadge(
                                      panTiles: framing.panTiles,
                                    ),
                                  ),
                                if (addStagePointMode)
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 8,
                                    child: _AddStagePointInstructionOverlay(
                                      onCancel: () => onAddStagePointModeChanged
                                          ?.call(false),
                                    ),
                                  ),
                                if (stagePoints.isEmpty && !addStagePointMode)
                                  const Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 8,
                                    child: _EmptyStagePointsHelperOverlay(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropLayerBitmapMap extends StatelessWidget {
  const _BackdropLayerBitmapMap({
    required this.model,
    this.asset,
    required this.plan,
    required this.compact,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    this.actorSpritePreviewPlan,
    required this.playbackPreviewStatus,
    required this.framingState,
    this.selectedStep,
    this.onFramingModeChanged,
    this.onFramingZoomChanged,
    this.onFramingPanChanged,
    this.onFramingResetView,
    this.onFramingDetailsChanged,
    this.onFramingGridChanged,
    required this.stagePoints,
    required this.selectedStagePointId,
    required this.addStagePointMode,
    required this.onSelectStagePointId,
    required this.onUpdateStagePoint,
    required this.onAddStagePointAtTile,
    this.onAddStagePointModeChanged,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicAsset? asset;
  final CinematicMapBackdropLayerRenderPlan plan;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;
  final CinematicBackdropPreviewFramingState framingState;
  final CinematicTimelineStep? selectedStep;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
  final ValueChanged<double>? onFramingZoomChanged;
  final ValueChanged<Offset>? onFramingPanChanged;
  final VoidCallback? onFramingResetView;
  final ValueChanged<bool>? onFramingDetailsChanged;
  final ValueChanged<bool>? onFramingGridChanged;
  final List<CinematicStagePoint> stagePoints;
  final String? selectedStagePointId;
  final bool addStagePointMode;
  final ValueChanged<String?>? onSelectStagePointId;
  final ValueChanged<CinematicStagePoint>? onUpdateStagePoint;
  final ValueChanged<Offset>? onAddStagePointAtTile;
  final ValueChanged<bool>? onAddStagePointModeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final palette = CinematicMapBackdropTileRenderPalette(
      background: colors.controlSurface,
      border: colors.controlBorder,
      grid: colors.borderSubtle,
    );
    final backgroundPasses = {
      for (final pass in CinematicMapBackdropRenderPass.values)
        if (pass.paintsBeforeActorOverlay) pass,
    };
    final foregroundPasses = {
      for (final pass in CinematicMapBackdropRenderPass.values)
        if (pass.paintsAfterActorOverlay) pass,
    };
    final isSceneMode =
        framingState.mode == CinematicBackdropPreviewFramingMode.scene;
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-bitmap'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact && !isSceneMode) ...[
          _BackdropMetaBar(
            model: model,
            primitiveCount: plan.instructions.length,
            compact: compact,
            layerBitmapPlan: plan,
            actorDisplayPreviewModel: actorDisplayPreviewModel,
            playbackPreviewStatus: playbackPreviewStatus,
          ),
          const SizedBox(height: 8),
        ],
        _BackdropFramingControls(
          state: framingState,
          compact: compact,
          model: model,
          primitiveCount: plan.instructions.length,
          hasBitmapInstructions: plan.hasBitmapInstructions,
          onModeChanged: onFramingModeChanged,
          onZoomChanged: onFramingZoomChanged,
          onResetView: onFramingResetView,
          onDetailsChanged: onFramingDetailsChanged,
          onGridChanged: onFramingGridChanged,
          addStagePointMode: addStagePointMode,
          onAddStagePointModeChanged: onAddStagePointModeChanged,
        ),
        if (isSceneMode && framingState.showDetails) ...[
          SizedBox(height: compact ? 5 : 6),
          _BackdropDetailsPanel(
            child: _BackdropMetaBar(
              model: model,
              primitiveCount: plan.instructions.length,
              compact: true,
              layerBitmapPlan: plan,
              actorDisplayPreviewModel: actorDisplayPreviewModel,
              playbackPreviewStatus: playbackPreviewStatus,
            ),
          ),
        ],
        SizedBox(
            height: isSceneMode
                ? 3
                : compact
                    ? 6
                    : 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              border: Border.all(color: colors.controlBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSceneMode
                  ? 3
                  : compact
                      ? 4
                      : 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final focus = resolveCinematicBackdropPreviewFocus(
                    mapWidth: plan.mapWidth,
                    mapHeight: plan.mapHeight,
                    actorDisplayPreviewModel: actorDisplayPreviewModel,
                    selectedStep: selectedStep,
                  );
                  final framing = resolveCinematicBackdropPreviewFraming(
                    viewportSize: constraints.biggest,
                    mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
                    mapWidth: plan.mapWidth,
                    mapHeight: plan.mapHeight,
                    state: framingState,
                    focus: focus,
                  );
                  final transform = CinematicMapBackdropViewportTransform.fill(
                    viewportSize: framing.transform.frame.size,
                    mapWidth: plan.mapWidth,
                    mapHeight: plan.mapHeight,
                  );
                  return MouseRegion(
                    cursor: addStagePointMode
                        ? SystemMouseCursors.precise
                        : SystemMouseCursors.basic,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        if (addStagePointMode &&
                            onAddStagePointAtTile != null) {
                          final localOffset = details.localPosition;
                          if (framing.transform.frame.contains(localOffset)) {
                            final tileCoord =
                                framing.transform.previewToTile(localOffset);
                            if (framing.transform
                                .isTileInsideMap(tileCoord.dx, tileCoord.dy)) {
                              final snappedX = tileCoord.dx.floor() + 0.5;
                              final snappedY = tileCoord.dy.floor() + 0.5;
                              onAddStagePointAtTile!(
                                  Offset(snappedX, snappedY));
                            }
                          }
                        } else {
                          onSelectStagePointId?.call(null);
                        }
                      },
                      onPanUpdate: isSceneMode && onFramingPanChanged != null
                          ? (details) {
                              onFramingPanChanged!(
                                framing.panTiles +
                                    _dragDeltaToPanTiles(
                                      details.delta,
                                      framing.transform.frame,
                                      plan.mapWidth,
                                      plan.mapHeight,
                                    ),
                              );
                            }
                          : null,
                      child: RepaintBoundary(
                        key: const ValueKey(
                          'cinematic-builder-map-backdrop-bitmap-viewport',
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ClipRect(
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned.fromRect(
                                  rect: framing.transform.frame,
                                  child: SizedBox(
                                    key: const ValueKey(
                                      'cinematic-builder-map-backdrop-map-frame',
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        CustomPaint(
                                          painter:
                                              CinematicMapBackdropLayerRenderPainter(
                                            plan: plan,
                                            palette: palette,
                                            passes: backgroundPasses,
                                            paintGrid: false,
                                            paintBorder: false,
                                          ),
                                          child: const SizedBox.expand(),
                                        ),
                                        if ((actorPlaybackPreviewModel
                                                    ?.displayModel ??
                                                actorDisplayPreviewModel) !=
                                            null)
                                          CinematicActorDisplayPreviewOverlay(
                                            model: actorPlaybackPreviewModel
                                                    ?.displayModel ??
                                                actorDisplayPreviewModel!,
                                            playbackPoseOverrides:
                                                actorPlaybackPreviewModel
                                                        ?.poseOverrides ??
                                                    const {},
                                            spritePreviewPlan:
                                                actorSpritePreviewPlan,
                                            tilesets: plan.tilesets,
                                            mapWidth: plan.mapWidth,
                                            mapHeight: plan.mapHeight,
                                            compact: compact,
                                          ),
                                        CinematicStagePointPreviewOverlay(
                                          stagePoints: stagePoints,
                                          selectedStagePointId:
                                              selectedStagePointId,
                                          onSelectStagePointId:
                                              onSelectStagePointId ?? (_) {},
                                          onUpdateStagePoint:
                                              onUpdateStagePoint ?? (_) {},
                                          transform: transform,
                                          compact: compact,
                                        ),
                                        IgnorePointer(
                                          child: CustomPaint(
                                            painter:
                                                CinematicMapBackdropLayerRenderPainter(
                                              plan: plan,
                                              palette: palette,
                                              passes: foregroundPasses,
                                              paintBackground: false,
                                              paintGrid: !isSceneMode ||
                                                  framingState.showGrid,
                                              paintBorder: true,
                                            ),
                                            child: const SizedBox.expand(),
                                          ),
                                        ),
                                        if (selectedStep != null &&
                                            asset != null)
                                          CinematicManualPathPreviewOverlay(
                                            asset: asset!,
                                            selectedStep: selectedStep!,
                                            actorDisplayPreviewModel:
                                                actorDisplayPreviewModel,
                                            visualPrimitives:
                                                model.visualPrimitives,
                                            transform: transform,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSceneMode)
                                  Positioned(
                                    left: 8,
                                    bottom: 8,
                                    child: _BackdropPanBadge(
                                      panTiles: framing.panTiles,
                                    ),
                                  ),
                                if (addStagePointMode)
                                  Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 8,
                                    child: _AddStagePointInstructionOverlay(
                                      onCancel: () => onAddStagePointModeChanged
                                          ?.call(false),
                                    ),
                                  ),
                                if (stagePoints.isEmpty && !addStagePointMode)
                                  const Positioned(
                                    left: 8,
                                    right: 8,
                                    top: 8,
                                    child: _EmptyStagePointsHelperOverlay(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackdropFramingControls extends StatelessWidget {
  const _BackdropFramingControls({
    required this.state,
    required this.compact,
    required this.model,
    required this.primitiveCount,
    required this.hasBitmapInstructions,
    this.onModeChanged,
    this.onZoomChanged,
    this.onResetView,
    this.onDetailsChanged,
    this.onGridChanged,
    this.addStagePointMode = false,
    this.onAddStagePointModeChanged,
  });

  final CinematicBackdropPreviewFramingState state;
  final bool compact;
  final CinematicMapBackdropPreviewModel model;
  final int primitiveCount;
  final bool hasBitmapInstructions;
  final ValueChanged<CinematicBackdropPreviewFramingMode>? onModeChanged;
  final ValueChanged<double>? onZoomChanged;
  final VoidCallback? onResetView;
  final ValueChanged<bool>? onDetailsChanged;
  final ValueChanged<bool>? onGridChanged;
  final bool addStagePointMode;
  final ValueChanged<bool>? onAddStagePointModeChanged;

  @override
  Widget build(BuildContext context) {
    final isSceneMode = state.mode == CinematicBackdropPreviewFramingMode.scene;
    final zoom = state.clampedZoom;
    final canAdjustZoom = isSceneMode && onZoomChanged != null;
    final canAdjustSceneOptions = isSceneMode;
    final buttonSize = compact ? 28.0 : 30.0;
    return Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-framing-controls'),
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 5 : 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-map-backdrop-fit-map-mode',
              ),
              label: 'Carte entière',
              icon: CupertinoIcons.map,
              selected:
                  state.mode == CinematicBackdropPreviewFramingMode.fitMap,
              onTap: onModeChanged == null
                  ? null
                  : () {
                      onModeChanged!(
                        CinematicBackdropPreviewFramingMode.fitMap,
                      );
                    },
            ),
            PokeMapSegmentedTab(
              key: const ValueKey(
                'cinematic-builder-map-backdrop-scene-mode',
              ),
              label: 'Vue scène',
              icon: CupertinoIcons.viewfinder,
              selected: isSceneMode,
              onTap: onModeChanged == null
                  ? null
                  : () {
                      onModeChanged!(
                        CinematicBackdropPreviewFramingMode.scene,
                      );
                    },
            ),
          ],
        ),
        PokeMapButton(
          key: const ValueKey(
            'cinematic-builder-map-backdrop-add-stage-point-toggle',
          ),
          size: compact ? PokeMapButtonSize.small : PokeMapButtonSize.medium,
          variant: addStagePointMode
              ? PokeMapButtonVariant.primary
              : PokeMapButtonVariant.secondary,
          onPressed: (model.isAvailable &&
                  hasBitmapInstructions &&
                  onAddStagePointModeChanged != null)
              ? () => onAddStagePointModeChanged!(!addStagePointMode)
              : null,
          leading: Icon(
            addStagePointMode
                ? CupertinoIcons.location_solid
                : CupertinoIcons.location,
            size: compact ? 12 : 14,
          ),
          child: Text(
            addStagePointMode ? 'Annuler l’ajout' : 'Ajouter un repère',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-out'),
          tooltip: 'Zoom -',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom > CinematicBackdropPreviewFramingState.minZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.clampZoom(
                      zoom - CinematicBackdropPreviewFramingState.zoomStep,
                    ),
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.minus),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-reset'),
          tooltip: 'Réinitialiser le zoom',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom != CinematicBackdropPreviewFramingState.minZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.minZoom,
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.arrow_counterclockwise),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-reset-view'),
          tooltip: 'Recentrer la vue',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustSceneOptions ? onResetView : null,
          icon: const Icon(CupertinoIcons.scope),
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-in'),
          tooltip: 'Zoom +',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustZoom &&
                  zoom < CinematicBackdropPreviewFramingState.maxZoom
              ? () {
                  onZoomChanged!(
                    CinematicBackdropPreviewFramingState.clampZoom(
                      zoom + CinematicBackdropPreviewFramingState.zoomStep,
                    ),
                  );
                }
              : null,
          icon: const Icon(CupertinoIcons.plus),
        ),
        PokeMapBadge(
          key: const ValueKey('cinematic-builder-map-backdrop-zoom-label'),
          label: 'Zoom ${zoom.toStringAsFixed(2)}×',
          variant: isSceneMode
              ? PokeMapBadgeVariant.info
              : PokeMapBadgeVariant.neutral,
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-grid-toggle'),
          tooltip: state.showGrid ? 'Masquer la grille' : 'Afficher la grille',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: canAdjustSceneOptions && onGridChanged != null
              ? () => onGridChanged!(!state.showGrid)
              : null,
          icon: Icon(
            state.showGrid ? CupertinoIcons.grid : CupertinoIcons.square,
          ),
        ),
        PokeMapBadge(
          label: isSceneMode && !state.showGrid
              ? 'Grille masquée'
              : 'Grille visible',
          variant: isSceneMode && !state.showGrid
              ? PokeMapBadgeVariant.neutral
              : PokeMapBadgeVariant.info,
        ),
        PokeMapBadge(
          label: hasBitmapInstructions
              ? 'Décor disponible'
              : 'Fallback structurel',
          variant: hasBitmapInstructions
              ? PokeMapBadgeVariant.success
              : PokeMapBadgeVariant.warning,
        ),
        if (model.sizeSummary != null)
          PokeMapBadge(
            label: model.sizeSummary!,
            variant: PokeMapBadgeVariant.neutral,
          ),
        PokeMapBadge(
          label: '$primitiveCount couche(s)',
          variant: PokeMapBadgeVariant.neutral,
        ),
        PokeMapIconButton(
          key: const ValueKey('cinematic-builder-map-backdrop-details-toggle'),
          tooltip: state.showDetails ? 'Masquer les détails' : 'Détails',
          size: buttonSize,
          variant: PokeMapIconButtonVariant.soft,
          onPressed: onDetailsChanged == null
              ? null
              : () => onDetailsChanged!(!state.showDetails),
          icon: Icon(
            state.showDetails
                ? CupertinoIcons.chevron_up
                : CupertinoIcons.chevron_down,
          ),
        ),
      ],
    );
  }
}

class _BackdropDetailsPanel extends StatelessWidget {
  const _BackdropDetailsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: const ValueKey('cinematic-builder-map-backdrop-details'),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

class _BackdropPanBadge extends StatelessWidget {
  const _BackdropPanBadge({required this.panTiles});

  final Offset panTiles;

  @override
  Widget build(BuildContext context) {
    final panX = panTiles.dx.abs() < 0.05 ? 0.0 : panTiles.dx;
    final panY = panTiles.dy.abs() < 0.05 ? 0.0 : panTiles.dy;
    return PokeMapBadge(
      label: 'Pan ${panX.toStringAsFixed(1)}, ${panY.toStringAsFixed(1)}',
      variant: PokeMapBadgeVariant.neutral,
    );
  }
}

class _BackdropVisualPrimitiveMap extends StatelessWidget {
  const _BackdropVisualPrimitiveMap({
    required this.model,
    required this.primitives,
    required this.compact,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
    required this.playbackPreviewStatus,
  });

  final CinematicMapBackdropPreviewModel model;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mapTone = PokeMapTone.map.resolve(context);
    final terrainTone = PokeMapTone.success.resolve(context);
    final pathTone = PokeMapTone.warning.resolve(context);
    final surfaceTone = PokeMapTone.info.resolve(context);
    final objectTone = PokeMapTone.cinematic.resolve(context);
    final environmentTone = PokeMapTone.narrative.resolve(context);
    final palette = CinematicMapBackdropPrimitivePalette(
      background: colors.controlSurface,
      border: colors.controlBorder,
      grid: colors.borderSubtle,
      tile: mapTone.icon,
      terrain: terrainTone.icon,
      path: pathTone.icon,
      surface: surfaceTone.icon,
      object: objectTone.icon,
      environment: environmentTone.icon,
      summary: colors.textMuted,
    );
    final layerCounts = _primitiveLayerCounts(primitives);
    final mapWidth = model.mapWidth ?? _maxPrimitiveX(primitives);
    final mapHeight = model.mapHeight ?? _maxPrimitiveY(primitives);
    if (!compact) {
      return Row(
        key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _BackdropPrimitiveCanvas(
              mapWidth: mapWidth,
              mapHeight: mapHeight,
              primitives: primitives,
              palette: palette,
              compact: compact,
              actorDisplayPreviewModel: actorDisplayPreviewModel,
              actorPlaybackPreviewModel: actorPlaybackPreviewModel,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 330,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BackdropMetaBar(
                    model: model,
                    primitiveCount: primitives.length,
                    compact: compact,
                    bitmapPlan: tileRenderPlan,
                    layerBitmapPlan: layerRenderPlan,
                    actorDisplayPreviewModel: actorDisplayPreviewModel,
                    playbackPreviewStatus: playbackPreviewStatus,
                  ),
                  const SizedBox(height: 8),
                  _BackdropPrimitiveLegend(
                    entries: layerCounts,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropMetaBar(
          model: model,
          primitiveCount: primitives.length,
          compact: compact,
          bitmapPlan: tileRenderPlan,
          layerBitmapPlan: layerRenderPlan,
          actorDisplayPreviewModel: actorDisplayPreviewModel,
          playbackPreviewStatus: playbackPreviewStatus,
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: _BackdropPrimitiveCanvas(
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            primitives: primitives,
            palette: palette,
            compact: compact,
            actorDisplayPreviewModel: actorDisplayPreviewModel,
            actorPlaybackPreviewModel: actorPlaybackPreviewModel,
          ),
        ),
        SizedBox(height: compact ? 5 : 7),
        _BackdropPrimitiveLegend(
          entries: layerCounts,
          compact: compact,
        ),
      ],
    );
  }
}

Offset _dragDeltaToPanTiles(
  Offset delta,
  Rect mapFrame,
  int mapWidth,
  int mapHeight,
) {
  if (mapFrame.width <= 0 || mapFrame.height <= 0) {
    return Offset.zero;
  }
  return Offset(
    -delta.dx * mapWidth / mapFrame.width,
    -delta.dy * mapHeight / mapFrame.height,
  );
}

class _BackdropPrimitiveCanvas extends StatelessWidget {
  const _BackdropPrimitiveCanvas({
    required this.mapWidth,
    required this.mapHeight,
    required this.primitives,
    required this.palette,
    required this.compact,
    this.actorDisplayPreviewModel,
    this.actorPlaybackPreviewModel,
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicActorPlaybackOverlayModel? actorPlaybackPreviewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        border: Border.all(color: colors.controlBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 4 : 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportRect = fittedCinematicMapBackdropRect(
              availableSize: constraints.biggest,
              mapPixelSize: Size(mapWidth.toDouble(), mapHeight.toDouble()),
            );
            return Center(
              child: SizedBox(
                key: const ValueKey(
                  'cinematic-builder-map-backdrop-visual-viewport',
                ),
                width: viewportRect.width,
                height: viewportRect.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: CinematicMapBackdropVisualPrimitivesPainter(
                          mapWidth: mapWidth,
                          mapHeight: mapHeight,
                          primitives: primitives,
                          palette: palette,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      if ((actorPlaybackPreviewModel?.displayModel ??
                              actorDisplayPreviewModel) !=
                          null)
                        CinematicActorDisplayPreviewOverlay(
                          model: actorPlaybackPreviewModel?.displayModel ??
                              actorDisplayPreviewModel!,
                          playbackPoseOverrides:
                              actorPlaybackPreviewModel?.poseOverrides ??
                                  const {},
                          mapWidth: mapWidth,
                          mapHeight: mapHeight,
                          compact: compact,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackdropMetaBar extends StatelessWidget {
  const _BackdropMetaBar({
    required this.model,
    required this.primitiveCount,
    required this.compact,
    this.bitmapPlan,
    this.layerBitmapPlan,
    this.actorDisplayPreviewModel,
    required this.playbackPreviewStatus,
  });

  final CinematicMapBackdropPreviewModel model;
  final int primitiveCount;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? bitmapPlan;
  final CinematicMapBackdropLayerRenderPlan? layerBitmapPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final CinematicPlaybackPreviewStatus playbackPreviewStatus;

  @override
  Widget build(BuildContext context) {
    final hasActorDisplayEntries =
        _hasActorDisplayEntries(actorDisplayPreviewModel);
    final hasBitmapInstructions = layerBitmapPlan?.hasBitmapInstructions ??
        bitmapPlan?.hasBitmapInstructions ??
        false;
    final firstDiagnostic = (layerBitmapPlan?.diagnostics.isNotEmpty ?? false)
        ? layerBitmapPlan!.diagnostics.first
        : (bitmapPlan?.diagnostics.isNotEmpty ?? false)
            ? bitmapPlan!.diagnostics.first
            : null;
    final badges = Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-meta-bar'),
      spacing: 7,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BackdropMetaPill(
          label: hasBitmapInstructions
              ? 'Tiles réelles affichées'
              : 'Fallback structurel',
          tone:
              hasBitmapInstructions ? PokeMapTone.success : PokeMapTone.warning,
        ),
        _BackdropMetaPill(
          label: hasBitmapInstructions
              ? layerBitmapPlan != null
                  ? '$primitiveCount couche(s) bitmap'
                  : '$primitiveCount tuile(s) bitmap'
              : '$primitiveCount primitive(s) spatiale(s)',
          tone: PokeMapTone.map,
        ),
        _BackdropMetaPill(
          label: _viewportModeLabel(model.viewportRecommendation.mode),
        ),
        if (!compact)
          _BackdropMetaPill(
            label:
                'Zoom ${model.viewportRecommendation.zoom.toStringAsFixed(2)}',
          ),
        if (!hasActorDisplayEntries) ...[
          const _BackdropMetaPill(label: 'Décor seul'),
          const _BackdropMetaPill(label: 'Sans acteurs'),
        ] else ...[
          _BackdropMetaPill(
            label: _placedActorsLabel(actorDisplayPreviewModel!),
            tone: PokeMapTone.success,
          ),
          if (_actorCompletionCount(actorDisplayPreviewModel!) > 0)
            _BackdropMetaPill(
              label:
                  '${_actorCompletionCount(actorDisplayPreviewModel!)} à compléter',
              tone: PokeMapTone.warning,
            ),
          _BackdropMetaPill(
            label: playbackPreviewStatus.actorAnimationLabel,
            tone: playbackPreviewStatus.actorAnimationTone,
          ),
          const _BackdropMetaPill(label: 'Placeholders'),
        ],
        _BackdropMetaPill(
          label: playbackPreviewStatus.playbackLabel,
          tone: playbackPreviewStatus.playbackTone,
        ),
        if (firstDiagnostic != null)
          _BackdropMetaPill(
            label: firstDiagnostic.message,
            tone: _toneForTileDiagnostic(
              firstDiagnostic.severity,
            ),
          ),
      ],
    );

    if (!playbackPreviewStatus.fallbackSummary.hasDetails) {
      return badges;
    }

    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-meta-bar-details'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        badges,
        SizedBox(height: compact ? 5 : 6),
        _PlaybackFallbackDetails(
          summary: playbackPreviewStatus.fallbackSummary,
          compact: compact,
        ),
      ],
    );
  }
}

class _BackdropMetaPill extends StatelessWidget {
  const _BackdropMetaPill({
    required this.label,
    this.tone,
  });

  final String label;
  final PokeMapTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final resolvedTone = tone?.resolve(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedTone?.soft ?? colors.surfaceBase,
        border: Border.all(
          color: resolvedTone?.border ?? colors.borderSubtle,
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: resolvedTone?.text ?? colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}

class _PlaybackFallbackDetails extends StatelessWidget {
  const _PlaybackFallbackDetails({
    required this.summary,
    required this.compact,
  });

  final CinematicPlaybackPreviewFallbackSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      key: const ValueKey('cinematic-builder-playback-fallback-details'),
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 7 : 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: compact ? 12 : 14,
                  color: colors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Détails de prévisualisation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DefaultTextStyle.of(context).style.copyWith(
                          color: colors.textSecondary,
                          fontSize: compact ? 10 : 11,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 7),
            for (final message in summary.visibleMessages) ...[
              _PlaybackFallbackMessageRow(
                message: message,
                compact: compact,
              ),
              if (message != summary.visibleMessages.last)
                SizedBox(height: compact ? 3 : 4),
            ],
            if (summary.extraCount > 0) ...[
              SizedBox(height: compact ? 5 : 6),
              Align(
                alignment: Alignment.centerLeft,
                child: _BackdropMetaPill(
                  label: '+${summary.extraCount} autre(s) point(s) à vérifier',
                  tone: PokeMapTone.info,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaybackFallbackMessageRow extends StatelessWidget {
  const _PlaybackFallbackMessageRow({
    required this.message,
    required this.compact,
  });

  final CinematicPlaybackPreviewFallbackMessage message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone =
        _toneForPlaybackFallbackSeverity(message.severity).resolve(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: compact ? 4 : 5),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tone.icon,
              borderRadius: BorderRadius.circular(99),
            ),
            child: SizedBox(
              width: compact ? 5 : 6,
              height: compact ? 5 : 6,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: colors.textSecondary,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _BackdropPrimitiveLegend extends StatelessWidget {
  const _BackdropPrimitiveLegend({
    required this.entries,
    required this.compact,
  });

  final List<(String, int, CinematicMapBackdropLayerKind)> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-legend'),
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final entry in entries.take(compact ? 3 : 5))
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceBase.withValues(alpha: 0.78),
              border: Border.all(color: colors.borderSubtle),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                '${entry.$1} · ${entry.$2} · ${_layerKindLabel(entry.$3)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.textMuted,
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BackdropFallback extends StatelessWidget {
  const _BackdropFallback({
    required this.model,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForStatus(model.status).resolve(context);
    return DecoratedBox(
      key: const ValueKey('cinematic-builder-map-backdrop-fallback'),
      decoration: BoxDecoration(
        color: tone.soft,
        border: Border.all(color: tone.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconForStatus(model.status),
              color: tone.icon,
              size: compact ? 22 : 30,
            ),
            SizedBox(height: compact ? 8 : 12),
            Text(
              _fallbackTitle(model.status),
              textAlign: TextAlign.center,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textPrimary,
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: compact ? 5 : 8),
            Text(
              _fallbackMessage(model),
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: DefaultTextStyle.of(context).style.copyWith(
                    color: colors.textSecondary,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (model.status ==
                    CinematicMapBackdropPreviewStatus.missingStageMap ||
                model.status ==
                    CinematicMapBackdropPreviewStatus.stageMapUnknown ||
                model.status ==
                    CinematicMapBackdropPreviewStatus.mapDataUnavailable) ...[
              const SizedBox(height: 12),
              Text(
                'Choisis une map de scène avant de placer des points.',
                textAlign: TextAlign.center,
                style: DefaultTextStyle.of(context).style.copyWith(
                      color: colors.brandPrimary,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
            if (!compact) ...[
              const SizedBox(height: 12),
              const PokeMapBadge(
                label: 'Fallback structurel',
                variant: PokeMapBadgeVariant.neutral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BackdropDiagnostics extends StatelessWidget {
  const _BackdropDiagnostics({
    required this.model,
    required this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

  @override
  Widget build(BuildContext context) {
    final diagnostics = model.diagnostics;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (diagnostics.isEmpty)
          const _BackdropMetaPill(
            label: 'Décor map prêt pour aperçu statique.',
            tone: PokeMapTone.success,
          ),
        for (final diagnostic in diagnostics.take(3))
          _BackdropMetaPill(
            label: diagnostic.message,
            tone: _toneForDiagnostic(diagnostic.severity),
          ),
        if (actorDisplayPreviewModel != null)
          _ActorDisplayDiagnostics(model: actorDisplayPreviewModel!),
      ],
    );
  }
}

class _ActorDisplayDiagnostics extends StatelessWidget {
  const _ActorDisplayDiagnostics({required this.model});

  final CinematicActorDisplayPreviewModel model;

  @override
  Widget build(BuildContext context) {
    final diagnostics = _sortedActorDiagnostics(model);
    if (diagnostics.isEmpty) {
      return _BackdropMetaPill(
        label: '${_placedActorsLabel(model)} en pose initiale.',
        tone: PokeMapTone.success,
      );
    }
    return Wrap(
      key: const ValueKey('cinematic-builder-actor-display-diagnostics'),
      spacing: 6,
      runSpacing: 6,
      children: [
        _BackdropMetaPill(
          label: model.summary,
          tone: _toneForActorStatus(model.status),
        ),
        for (final diagnostic in diagnostics.take(6))
          _BackdropMetaPill(
            label: _actorDiagnosticLabel(model, diagnostic),
            tone: _toneForActorDiagnostic(diagnostic.severity),
          ),
      ],
    );
  }
}

class _BackdropMutedText extends StatelessWidget {
  const _BackdropMutedText(this.text, {required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: DefaultTextStyle.of(context).style.copyWith(
            color: colors.textMuted,
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

List<CinematicMapBackdropVisualPrimitive> _spatialPrimitives(
  List<CinematicMapBackdropVisualPrimitive> primitives,
) {
  return primitives
      .where((primitive) =>
          primitive.kind !=
              CinematicMapBackdropVisualPrimitiveKind.layerSummary &&
          primitive.kind !=
              CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer)
      .toList(growable: false);
}

List<(String, int, CinematicMapBackdropLayerKind)> _primitiveLayerCounts(
  List<CinematicMapBackdropVisualPrimitive> primitives,
) {
  final counts = <String, (int, CinematicMapBackdropLayerKind)>{};
  for (final primitive in primitives) {
    counts.update(
      primitive.layerLabel,
      (entry) => (entry.$1 + 1, entry.$2),
      ifAbsent: () => (1, primitive.layerKind),
    );
  }
  return [
    for (final entry in counts.entries)
      (entry.key, entry.value.$1, entry.value.$2),
  ];
}

String _layerKindLabel(CinematicMapBackdropLayerKind kind) {
  return switch (kind) {
    CinematicMapBackdropLayerKind.tile => 'tile',
    CinematicMapBackdropLayerKind.terrain => 'terrain',
    CinematicMapBackdropLayerKind.path => 'path',
    CinematicMapBackdropLayerKind.surface => 'surface',
    CinematicMapBackdropLayerKind.object => 'objet',
    CinematicMapBackdropLayerKind.environment => 'env',
  };
}

int _maxPrimitiveX(List<CinematicMapBackdropVisualPrimitive> primitives) {
  var maxX = 1;
  for (final primitive in primitives) {
    final right = primitive.x + primitive.width;
    if (right > maxX) {
      maxX = right;
    }
  }
  return maxX;
}

int _maxPrimitiveY(List<CinematicMapBackdropVisualPrimitive> primitives) {
  var maxY = 1;
  for (final primitive in primitives) {
    final bottom = primitive.y + primitive.height;
    if (bottom > maxY) {
      maxY = bottom;
    }
  }
  return maxY;
}

String _fallbackTitle(CinematicMapBackdropPreviewStatus status) {
  return switch (status) {
    CinematicMapBackdropPreviewStatus.backdropDisabled => 'Décor désactivé',
    CinematicMapBackdropPreviewStatus.missingStageMap => 'Map de scène requise',
    CinematicMapBackdropPreviewStatus.stageMapUnknown => 'Map introuvable',
    CinematicMapBackdropPreviewStatus.mapDataUnavailable =>
      'Données map indisponibles',
    CinematicMapBackdropPreviewStatus.mapDataMismatch =>
      'Données map invalides',
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      'Tileset indisponible',
    CinematicMapBackdropPreviewStatus.available => 'Carte du projet statique',
  };
}

String _fallbackMessage(CinematicMapBackdropPreviewModel model) {
  return switch (model.status) {
    CinematicMapBackdropPreviewStatus.backdropDisabled =>
      'Décor de map désactivé pour cette cinématique.',
    CinematicMapBackdropPreviewStatus.missingStageMap =>
      'Choisis une map de scène pour afficher le décor.',
    CinematicMapBackdropPreviewStatus.stageMapUnknown =>
      'La map de scène n’existe plus dans le projet.',
    CinematicMapBackdropPreviewStatus.mapDataUnavailable =>
      'Les données de cette map ne sont pas disponibles pour la preview.',
    CinematicMapBackdropPreviewStatus.mapDataMismatch =>
      'La map chargée ne correspond pas à la map de scène.',
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      'Le tileset de cette map n’est pas disponible pour la preview.',
    CinematicMapBackdropPreviewStatus.available =>
      'V1-84 affiche enfin un décor de map statique dans le Builder.',
  };
}

String _viewportModeLabel(CinematicMapBackdropViewportMode mode) {
  return switch (mode) {
    CinematicMapBackdropViewportMode.fitMap => 'Cadrage fitMap',
    CinematicMapBackdropViewportMode.centerMap => 'Cadrage centré map',
    CinematicMapBackdropViewportMode.centerActor => 'Cadrage acteur',
    CinematicMapBackdropViewportMode.centerTarget => 'Cadrage cible',
  };
}

String _placedActorsLabel(CinematicActorDisplayPreviewModel model) {
  return '${model.renderableActorCount} acteur(s) placés';
}

bool _hasActorDisplayEntries(CinematicActorDisplayPreviewModel? model) {
  return model != null &&
      model.status != CinematicActorDisplayPreviewStatus.noActors;
}

int _actorCompletionCount(CinematicActorDisplayPreviewModel model) {
  return model.actors.length - model.renderableActorCount;
}

List<CinematicActorDisplayPreviewDiagnostic> _sortedActorDiagnostics(
  CinematicActorDisplayPreviewModel model,
) {
  final diagnostics = [...model.diagnostics];
  diagnostics.sort((a, b) {
    final severityCompare =
        _actorDiagnosticRank(b.severity) - _actorDiagnosticRank(a.severity);
    if (severityCompare != 0) {
      return severityCompare;
    }
    return a.code.name.compareTo(b.code.name);
  });
  return diagnostics;
}

int _actorDiagnosticRank(
  CinematicActorDisplayPreviewDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicActorDisplayPreviewDiagnosticSeverity.error => 3,
    CinematicActorDisplayPreviewDiagnosticSeverity.warning => 2,
    CinematicActorDisplayPreviewDiagnosticSeverity.info => 1,
  };
}

String _actorDiagnosticLabel(
  CinematicActorDisplayPreviewModel model,
  CinematicActorDisplayPreviewDiagnostic diagnostic,
) {
  final actor =
      diagnostic.actorId == null ? null : model.actorById(diagnostic.actorId!);
  final label = actor?.label ?? diagnostic.actorId ?? 'Cet acteur';
  return switch (diagnostic.code) {
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors =>
      'Aucun acteur requis pour cette cinématique.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingBinding =>
      'Choisis comment $label est lié à la scène.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnboundActor =>
      '$label est volontairement hors scène.',
    CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayMissingInitialPlacement =>
      'Définis l’entrée de scène de $label pour l’afficher.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingMapEntity =>
      'L’entité liée à $label n’existe plus sur cette map.',
    CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayMissingMovementTarget =>
      'La cible de placement de $label est absente.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayAbstractTargetOnly =>
      '$label utilise une cible abstraite; ajoute une source map.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOutOfMapBounds =>
      '$label est placé hors du décor affiché.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingAppearance =>
      '$label est placé; son apparence reste à compléter.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnknownCharacter =>
      'Le personnage choisi pour $label n’existe plus.',
    CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayCharacterMissingTileset =>
      '$label a besoin d’un tileset preview.',
    CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayCharacterMissingIdleAnimation =>
      '$label a besoin d’une pose idle preview.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayDirectionFallback =>
      'Direction par défaut utilisée pour $label.',
    CinematicActorDisplayPreviewDiagnosticCode.actorDisplayRuntimeUnsupported =>
      'Aperçu statique uniquement pour $label.',
    _ => diagnostic.message,
  };
}

PokeMapTone _toneForActorStatus(CinematicActorDisplayPreviewStatus status) {
  return switch (status) {
    CinematicActorDisplayPreviewStatus.ready => PokeMapTone.success,
    CinematicActorDisplayPreviewStatus.incomplete => PokeMapTone.warning,
    CinematicActorDisplayPreviewStatus.blocked => PokeMapTone.danger,
    CinematicActorDisplayPreviewStatus.noActors => PokeMapTone.info,
  };
}

PokeMapTone _toneForActorDiagnostic(
  CinematicActorDisplayPreviewDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicActorDisplayPreviewDiagnosticSeverity.info => PokeMapTone.info,
    CinematicActorDisplayPreviewDiagnosticSeverity.warning =>
      PokeMapTone.warning,
    CinematicActorDisplayPreviewDiagnosticSeverity.error => PokeMapTone.danger,
  };
}

PokeMapTone _toneForDiagnostic(
  CinematicMapBackdropPreviewDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicMapBackdropPreviewDiagnosticSeverity.info => PokeMapTone.info,
    CinematicMapBackdropPreviewDiagnosticSeverity.warning =>
      PokeMapTone.warning,
    CinematicMapBackdropPreviewDiagnosticSeverity.error => PokeMapTone.danger,
  };
}

PokeMapTone _toneForTileDiagnostic(
  CinematicMapBackdropTileDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicMapBackdropTileDiagnosticSeverity.info => PokeMapTone.info,
    CinematicMapBackdropTileDiagnosticSeverity.warning => PokeMapTone.warning,
    CinematicMapBackdropTileDiagnosticSeverity.error => PokeMapTone.danger,
  };
}

PokeMapTone _toneForPlaybackFallbackSeverity(
  CinematicPlaybackPreviewFallbackSeverity severity,
) {
  return switch (severity) {
    CinematicPlaybackPreviewFallbackSeverity.info => PokeMapTone.info,
    CinematicPlaybackPreviewFallbackSeverity.warning => PokeMapTone.warning,
    CinematicPlaybackPreviewFallbackSeverity.error => PokeMapTone.danger,
  };
}

PokeMapTone _toneForStatus(CinematicMapBackdropPreviewStatus status) {
  return switch (status) {
    CinematicMapBackdropPreviewStatus.available => PokeMapTone.success,
    CinematicMapBackdropPreviewStatus.backdropDisabled ||
    CinematicMapBackdropPreviewStatus.mapDataUnavailable ||
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      PokeMapTone.warning,
    CinematicMapBackdropPreviewStatus.missingStageMap ||
    CinematicMapBackdropPreviewStatus.stageMapUnknown ||
    CinematicMapBackdropPreviewStatus.mapDataMismatch =>
      PokeMapTone.danger,
  };
}

IconData _iconForStatus(CinematicMapBackdropPreviewStatus status) {
  return switch (status) {
    CinematicMapBackdropPreviewStatus.available => CupertinoIcons.map,
    CinematicMapBackdropPreviewStatus.backdropDisabled =>
      CupertinoIcons.eye_slash,
    CinematicMapBackdropPreviewStatus.missingStageMap =>
      CupertinoIcons.map_pin_ellipse,
    CinematicMapBackdropPreviewStatus.stageMapUnknown ||
    CinematicMapBackdropPreviewStatus.mapDataUnavailable ||
    CinematicMapBackdropPreviewStatus.mapDataMismatch ||
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      CupertinoIcons.exclamationmark_triangle,
  };
}

class _AddStagePointInstructionOverlay extends StatelessWidget {
  const _AddStagePointInstructionOverlay({
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.brandPrimarySoft.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.brandPrimaryBorder),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: colors.brandPrimary,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode placement actif — Cliquez sur la carte pour poser un repère. Échap pour annuler.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: const ValueKey(
                'cinematic-builder-cancel-stage-point-placement-btn'),
            size: PokeMapButtonSize.small,
            variant: PokeMapButtonVariant.secondary,
            onPressed: onCancel,
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}

class _EmptyStagePointsHelperOverlay extends StatelessWidget {
  const _EmptyStagePointsHelperOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.controlSurface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.location,
              color: colors.brandPrimary,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucun repère de scène. Cliquez sur « Ajouter un repère », puis cliquez sur la carte.',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
