import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

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
    final layers = model.layers.where((layer) => layer.visible).toList();
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
                  child: layers.isEmpty
                      ? Center(
                          child: _BackdropMutedText(
                            'Aucune couche visuelle lisible.',
                            compact: compact,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final layer in layers.take(compact ? 3 : 5))
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: _BackdropLayerBand(
                                    layer: layer,
                                    compact: compact,
                                  ),
                                ),
                              ),
                          ],
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

class _BackdropLayerBand extends StatelessWidget {
  const _BackdropLayerBand({
    required this.layer,
    required this.compact,
  });

  final CinematicMapBackdropLayerPreview layer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final layerTone = _toneForLayerKind(layer.kind).resolve(context);
    final opacity = layer.opacity.clamp(0.18, 1.0).toDouble();
    return Align(
      alignment: Alignment.center,
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 220;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: layerTone.soft.withValues(alpha: 0.38 * opacity),
                border: Border.all(color: layerTone.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 12,
                  vertical: compact ? 3 : 5,
                ),
                child: Row(
                  children: [
                    if (!narrow) ...[
                      Icon(
                        _iconForLayerKind(layer.kind),
                        color: layerTone.icon,
                        size: compact ? 13 : 15,
                      ),
                      const SizedBox(width: 7),
                    ],
                    Expanded(
                      child: Text(
                        layer.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              color: colors.textPrimary,
                              fontSize: compact ? 10 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (!narrow) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Couche ${layer.kind.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              color: layerTone.text,
                              fontSize: compact ? 9 : 11,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                    if (!compact) ...[
                      const SizedBox(width: 8),
                      Text(
                        layer.summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DefaultTextStyle.of(context).style.copyWith(
                              color: colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

PokeMapTone _toneForLayerKind(CinematicMapBackdropLayerKind kind) {
  return switch (kind) {
    CinematicMapBackdropLayerKind.tile => PokeMapTone.map,
    CinematicMapBackdropLayerKind.terrain => PokeMapTone.success,
    CinematicMapBackdropLayerKind.path => PokeMapTone.warning,
    CinematicMapBackdropLayerKind.surface => PokeMapTone.info,
    CinematicMapBackdropLayerKind.object => PokeMapTone.cinematic,
    CinematicMapBackdropLayerKind.environment => PokeMapTone.narrative,
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

IconData _iconForLayerKind(CinematicMapBackdropLayerKind kind) {
  return switch (kind) {
    CinematicMapBackdropLayerKind.tile => CupertinoIcons.square_grid_2x2,
    CinematicMapBackdropLayerKind.terrain =>
      CupertinoIcons.leaf_arrow_circlepath,
    CinematicMapBackdropLayerKind.path => CupertinoIcons.arrow_turn_up_right,
    CinematicMapBackdropLayerKind.surface => CupertinoIcons.layers,
    CinematicMapBackdropLayerKind.object => CupertinoIcons.cube_box,
    CinematicMapBackdropLayerKind.environment => CupertinoIcons.sparkles,
  };
}
