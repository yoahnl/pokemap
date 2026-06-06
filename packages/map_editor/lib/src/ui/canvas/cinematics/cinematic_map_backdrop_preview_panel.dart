import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_map_backdrop_tile_renderer.dart';
import 'cinematic_map_backdrop_visual_primitives_painter.dart';

class CinematicMapBackdropPreviewPanel extends StatelessWidget {
  const CinematicMapBackdropPreviewPanel({
    super.key,
    required this.model,
    required this.compact,
    this.tileRenderPlan,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('cinematic-builder-map-backdrop-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackdropHeader(model: model, compact: compact),
        SizedBox(height: compact ? 8 : 12),
        Expanded(
          child: model.isAvailable
              ? _BackdropMapFrame(
                  model: model,
                  compact: compact,
                  tileRenderPlan: tileRenderPlan,
                )
              : _BackdropFallback(model: model, compact: compact),
        ),
        if (!compact) ...[
          const SizedBox(height: 10),
          _BackdropDiagnostics(model: model),
        ],
      ],
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  const _BackdropHeader({
    required this.model,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
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
                  const PokeMapBadge(
                    label: 'Décor seul',
                    variant: PokeMapBadgeVariant.info,
                  ),
                  const PokeMapBadge(
                    label: 'Sans acteurs',
                    variant: PokeMapBadgeVariant.neutral,
                  ),
                  const PokeMapBadge(
                    label: 'Sans lecture',
                    variant: PokeMapBadgeVariant.neutral,
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
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final spatialPrimitives = _spatialPrimitives(model.visualPrimitives);
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
              child: bitmapPlan != null && bitmapPlan.hasBitmapInstructions
                  ? _BackdropBitmapMap(
                      model: model,
                      plan: bitmapPlan,
                      compact: compact,
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
  });

  final CinematicMapBackdropPreviewModel model;
  final CinematicMapBackdropTileRenderPlan plan;
  final bool compact;

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
                  final scale = math.min(
                    constraints.maxWidth / plan.pixelWidth,
                    constraints.maxHeight / plan.pixelHeight,
                  );
                  final viewportWidth = plan.pixelWidth * scale;
                  final viewportHeight = plan.pixelHeight * scale;
                  return Center(
                    child: RepaintBoundary(
                      key: const ValueKey(
                        'cinematic-builder-map-backdrop-bitmap-viewport',
                      ),
                      child: SizedBox(
                        width: viewportWidth,
                        height: viewportHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CustomPaint(
                            painter: CinematicMapBackdropTileRenderPainter(
                              plan: plan,
                              palette: palette,
                            ),
                            child: const SizedBox.expand(),
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
  });

  final CinematicMapBackdropPreviewModel model;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? tileRenderPlan;

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
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 330,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackdropMetaBar(
                  model: model,
                  primitiveCount: primitives.length,
                  compact: compact,
                  bitmapPlan: tileRenderPlan,
                ),
                const Spacer(),
                _BackdropPrimitiveLegend(
                  entries: layerCounts,
                  compact: compact,
                ),
              ],
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
        ),
        SizedBox(height: compact ? 6 : 8),
        Expanded(
          child: _BackdropPrimitiveCanvas(
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            primitives: primitives,
            palette: palette,
            compact: compact,
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
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;
  final bool compact;

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
            final scale = math.min(
              constraints.maxWidth / mapWidth,
              constraints.maxHeight / mapHeight,
            );
            final viewportWidth = mapWidth * scale;
            final viewportHeight = mapHeight * scale;
            return Center(
              child: SizedBox(
                key: const ValueKey(
                  'cinematic-builder-map-backdrop-visual-viewport',
                ),
                width: viewportWidth,
                height: viewportHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(
                    painter: CinematicMapBackdropVisualPrimitivesPainter(
                      mapWidth: mapWidth,
                      mapHeight: mapHeight,
                      primitives: primitives,
                      palette: palette,
                    ),
                    child: const SizedBox.expand(),
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
  });

  final CinematicMapBackdropPreviewModel model;
  final int primitiveCount;
  final bool compact;
  final CinematicMapBackdropTileRenderPlan? bitmapPlan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('cinematic-builder-map-backdrop-meta-bar'),
      spacing: 7,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BackdropMetaPill(
          label: bitmapPlan?.hasBitmapInstructions ?? false
              ? 'Tiles réelles affichées'
              : 'Fallback structurel',
          tone: bitmapPlan?.hasBitmapInstructions ?? false
              ? PokeMapTone.success
              : PokeMapTone.warning,
        ),
        _BackdropMetaPill(
          label: bitmapPlan?.hasBitmapInstructions ?? false
              ? '$primitiveCount tuile(s) bitmap'
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
        const _BackdropMetaPill(label: 'Décor seul'),
        const _BackdropMetaPill(label: 'Sans acteurs'),
        const _BackdropMetaPill(label: 'Sans lecture'),
        if (bitmapPlan != null && bitmapPlan!.diagnostics.isNotEmpty)
          _BackdropMetaPill(
            label: bitmapPlan!.diagnostics.first.message,
            tone: _toneForTileDiagnostic(
              bitmapPlan!.diagnostics.first.severity,
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
  const _BackdropDiagnostics({required this.model});

  final CinematicMapBackdropPreviewModel model;

  @override
  Widget build(BuildContext context) {
    final diagnostics = model.diagnostics;
    if (diagnostics.isEmpty) {
      return const Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          PokeMapBadge(
            label: 'Décor map prêt pour aperçu statique.',
            variant: PokeMapBadgeVariant.success,
          ),
        ],
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final diagnostic in diagnostics.take(3))
          _BackdropMetaPill(
            label: diagnostic.message,
            tone: _toneForDiagnostic(diagnostic.severity),
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
