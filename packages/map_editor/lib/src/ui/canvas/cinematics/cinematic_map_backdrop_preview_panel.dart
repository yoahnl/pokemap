import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_visual_primitives_painter.dart';

class CinematicMapBackdropPreviewPanel extends StatelessWidget {
  const CinematicMapBackdropPreviewPanel({
    super.key,
    required this.model,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;

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
              ? _BackdropMapFrame(model: model, compact: compact)
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
        const PokeMapIconTile(
          icon: CupertinoIcons.map,
          tone: PokeMapTone.map,
          size: 32,
          iconSize: 16,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Décor map statique', style: titleStyle),
              const SizedBox(height: 3),
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
                ],
              ),
            ],
          ),
        ),
        const PokeMapBadge(
          label: 'Aperçu structurel read-only',
          variant: PokeMapBadgeVariant.info,
        ),
      ],
    );
  }
}

class _BackdropMapFrame extends StatelessWidget {
  const _BackdropMapFrame({
    required this.model,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final spatialPrimitives = _spatialPrimitives(model.visualPrimitives);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  border: Border.all(color: colors.controlBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 6 : 10),
                  child: spatialPrimitives.isEmpty
                      ? Center(
                          child: _BackdropMutedText(
                            'Aucune couche visuelle lisible.',
                            compact: compact,
                          ),
                        )
                      : _BackdropVisualPrimitiveMap(
                          model: model,
                          primitives: spatialPrimitives,
                          compact: compact,
                        ),
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PokeMapBadge(
                  label: _viewportModeLabel(model.viewportRecommendation.mode),
                  variant: PokeMapBadgeVariant.mapAccent,
                ),
                PokeMapBadge(
                  label:
                      'Zoom ${model.viewportRecommendation.zoom.toStringAsFixed(2)}',
                  variant: PokeMapBadgeVariant.neutral,
                ),
                const PokeMapBadge(
                  label: 'Preview réelle à venir.',
                  variant: PokeMapBadgeVariant.neutral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropVisualPrimitiveMap extends StatelessWidget {
  const _BackdropVisualPrimitiveMap({
    required this.model,
    required this.primitives,
    required this.compact,
  });

  final CinematicMapBackdropPreviewModel model;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final bool compact;

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
    return Stack(
      key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
      children: [
        Positioned.fill(
          child: ClipRect(
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
        Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              const PokeMapBadge(
                label: 'Aperçu spatial structurel',
                variant: PokeMapBadgeVariant.info,
              ),
              PokeMapBadge(
                label: '${primitives.length} primitive(s) spatiale(s)',
                variant: PokeMapBadgeVariant.mapAccent,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 5,
            children: [
              for (final entry in layerCounts.take(compact ? 3 : 4))
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceBase.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      '${entry.$1} · ${entry.$2}',
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
                label: 'Preview réelle à venir.',
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
          PokeMapBadge(
            label: diagnostic.message,
            variant: _diagnosticBadgeVariant(diagnostic.severity),
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

List<(String, int)> _primitiveLayerCounts(
  List<CinematicMapBackdropVisualPrimitive> primitives,
) {
  final counts = <String, int>{};
  for (final primitive in primitives) {
    counts.update(
      primitive.layerLabel,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  return [
    for (final entry in counts.entries) (entry.key, entry.value),
  ];
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
    CinematicMapBackdropPreviewStatus.available => 'Décor map statique',
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

PokeMapBadgeVariant _diagnosticBadgeVariant(
  CinematicMapBackdropPreviewDiagnosticSeverity severity,
) {
  return switch (severity) {
    CinematicMapBackdropPreviewDiagnosticSeverity.info =>
      PokeMapBadgeVariant.info,
    CinematicMapBackdropPreviewDiagnosticSeverity.warning =>
      PokeMapBadgeVariant.warning,
    CinematicMapBackdropPreviewDiagnosticSeverity.error =>
      PokeMapBadgeVariant.error,
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
