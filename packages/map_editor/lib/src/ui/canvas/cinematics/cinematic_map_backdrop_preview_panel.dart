import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_actor_display_preview_overlay.dart';
import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_layer_renderer.dart';
import 'cinematic_map_backdrop_render_pass.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_map_backdrop_tile_renderer.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';
import 'cinematic_map_backdrop_visual_primitives_painter.dart';

class CinematicMapBackdropPreviewPanel extends StatelessWidget {
  const CinematicMapBackdropPreviewPanel({
    super.key,
    required this.model,
    required this.compact,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropHeader(
          model: model,
          actorDisplayPreviewModel: actorDisplayPreviewModel,
          compact: compact,
        ),
        SizedBox(height: compact ? 8 : 12),
        Expanded(
          child: model.isAvailable
              ? _BackdropMapFrame(
                  model: model,
                  compact: compact,
                  tileRenderPlan: tileRenderPlan,
                  layerRenderPlan: layerRenderPlan,
                  actorDisplayPreviewModel: actorDisplayPreviewModel,
                )
              : _BackdropFallback(model: model, compact: compact),
        ),
        if (!compact) ...[
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
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
  final bool compact;

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
                    label: _statusLabel(model.status),
                    variant: _statusBadgeVariant(model.status),
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
                    const _BackdropMetaPill(
                      label: 'Acteurs statiques',
                      tone: PokeMapTone.info,
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
                  const _BackdropMetaPill(
                    label: 'Sans lecture',
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
    required this.compact,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final spatialPrimitives = _spatialPrimitives(model.visualPrimitives);
    final layerBitmapPlan = layerRenderPlan;
    final bitmapPlan = tileRenderPlan;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 7 : 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: layerBitmapPlan != null &&
                      layerBitmapPlan.hasBitmapInstructions
                  ? _BackdropLayerBitmapMap(
                      model: model,
                      plan: layerBitmapPlan,
                      compact: compact,
                      actorDisplayPreviewModel: actorDisplayPreviewModel,
                    )
                  : bitmapPlan != null && bitmapPlan.hasBitmapInstructions
                      ? _BackdropBitmapMap(
                          model: model,
                          plan: bitmapPlan,
                          compact: compact,
                          actorDisplayPreviewModel: actorDisplayPreviewModel,
                        )
                      : spatialPrimitives.isEmpty
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                border: Border.all(color: colors.controlBorder),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: _BackdropMutedText(
                                  'Aucune couche visuelle lisible.',
                                  compact: compact,
                                ),
                              ),
                            )
                          : _BackdropVisualPrimitiveMap(
                              model: model,
                              primitives: spatialPrimitives,
                              compact: compact,
                              tileRenderPlan: bitmapPlan,
                              layerRenderPlan: layerBitmapPlan,
                              actorDisplayPreviewModel:
                                  actorDisplayPreviewModel,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropBitmapMap extends StatelessWidget {
  const _BackdropBitmapMap({
    required this.model,
    required this.plan,
    required this.compact,
    this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicMapBackdropTileRenderPlan plan;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final palette = CinematicMapBackdropTileRenderPalette(
      background: colors.controlSurface,
      border: colors.controlBorder,
      grid: colors.borderSubtle,
    );
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-bitmap'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropMetaBar(
          model: model,
          primitiveCount: plan.instructions.length,
          compact: compact,
          bitmapPlan: plan,
          actorDisplayPreviewModel: actorDisplayPreviewModel,
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: DecoratedBox(
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
                    mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
                  );
                  return Center(
                    child: RepaintBoundary(
                      key: const ValueKey(
                        'cinematic-builder-map-backdrop-bitmap-viewport',
                      ),
                      child: SizedBox(
                        width: viewportRect.width,
                        height: viewportRect.height,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: CinematicMapBackdropTileRenderPainter(
                                  plan: plan,
                                  palette: palette,
                                ),
                                child: const SizedBox.expand(),
                              ),
                              if (actorDisplayPreviewModel != null)
                                CinematicActorDisplayPreviewOverlay(
                                  model: actorDisplayPreviewModel!,
                                  mapWidth: plan.mapWidth,
                                  mapHeight: plan.mapHeight,
                                  compact: compact,
                                ),
                            ],
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
    required this.plan,
    required this.compact,
    this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicMapBackdropLayerRenderPlan plan;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

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
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-bitmap'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropMetaBar(
          model: model,
          primitiveCount: plan.instructions.length,
          compact: compact,
          layerBitmapPlan: plan,
          actorDisplayPreviewModel: actorDisplayPreviewModel,
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: DecoratedBox(
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
                    mapPixelSize: Size(plan.pixelWidth, plan.pixelHeight),
                  );
                  return Center(
                    child: RepaintBoundary(
                      key: const ValueKey(
                        'cinematic-builder-map-backdrop-bitmap-viewport',
                      ),
                      child: SizedBox(
                        width: viewportRect.width,
                        height: viewportRect.height,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              CustomPaint(
                                painter: CinematicMapBackdropLayerRenderPainter(
                                  plan: plan,
                                  palette: palette,
                                  passes: backgroundPasses,
                                  paintGridAndBorder: false,
                                ),
                                child: const SizedBox.expand(),
                              ),
                              if (actorDisplayPreviewModel != null)
                                CinematicActorDisplayPreviewOverlay(
                                  model: actorDisplayPreviewModel!,
                                  mapWidth: plan.mapWidth,
                                  mapHeight: plan.mapHeight,
                                  compact: compact,
                                ),
                              CustomPaint(
                                painter: CinematicMapBackdropLayerRenderPainter(
                                  plan: plan,
                                  palette: palette,
                                  passes: foregroundPasses,
                                  paintBackground: false,
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ],
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

class _BackdropVisualPrimitiveMap extends StatelessWidget {
  const _BackdropVisualPrimitiveMap({
    required this.model,
    required this.primitives,
    required this.compact,
    this.tileRenderPlan,
    this.layerRenderPlan,
    this.actorDisplayPreviewModel,
  });

  final CinematicMapBackdropPreviewModel model;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
  final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

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

class _BackdropPrimitiveCanvas extends StatelessWidget {
  const _BackdropPrimitiveCanvas({
    required this.mapWidth,
    required this.mapHeight,
    required this.primitives,
    required this.palette,
    required this.compact,
    this.actorDisplayPreviewModel,
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;
  final bool compact;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

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
                      if (actorDisplayPreviewModel != null)
                        CinematicActorDisplayPreviewOverlay(
                          model: actorDisplayPreviewModel!,
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
  });

  final CinematicMapBackdropPreviewModel model;
  final int primitiveCount;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? bitmapPlan;
  final CinematicMapBackdropLayerRenderPlan? layerBitmapPlan;
  final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;

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
    return Wrap(
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
          const _BackdropMetaPill(
            label: 'Acteurs statiques',
            tone: PokeMapTone.info,
          ),
          const _BackdropMetaPill(label: 'Placeholders'),
        ],
        const _BackdropMetaPill(label: 'Sans lecture'),
        if (firstDiagnostic != null)
          _BackdropMetaPill(
            label: firstDiagnostic.message,
            tone: _toneForTileDiagnostic(
              firstDiagnostic.severity,
            ),
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

String _statusLabel(CinematicMapBackdropPreviewStatus status) {
  return switch (status) {
    CinematicMapBackdropPreviewStatus.available => 'Décor disponible',
    CinematicMapBackdropPreviewStatus.backdropDisabled => 'Décor désactivé',
    CinematicMapBackdropPreviewStatus.missingStageMap => 'Map manquante',
    CinematicMapBackdropPreviewStatus.stageMapUnknown => 'Map inconnue',
    CinematicMapBackdropPreviewStatus.mapDataUnavailable =>
      'Données map absentes',
    CinematicMapBackdropPreviewStatus.mapDataMismatch => 'Map non alignée',
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      'Tileset indisponible',
  };
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

PokeMapBadgeVariant _statusBadgeVariant(
  CinematicMapBackdropPreviewStatus status,
) {
  return switch (status) {
    CinematicMapBackdropPreviewStatus.available => PokeMapBadgeVariant.success,
    CinematicMapBackdropPreviewStatus.backdropDisabled ||
    CinematicMapBackdropPreviewStatus.mapDataUnavailable ||
    CinematicMapBackdropPreviewStatus.tilesetUnavailable =>
      PokeMapBadgeVariant.warning,
    CinematicMapBackdropPreviewStatus.missingStageMap ||
    CinematicMapBackdropPreviewStatus.stageMapUnknown ||
    CinematicMapBackdropPreviewStatus.mapDataMismatch =>
      PokeMapBadgeVariant.error,
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
