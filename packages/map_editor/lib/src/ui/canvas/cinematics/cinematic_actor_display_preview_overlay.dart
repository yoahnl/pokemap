import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'cinematic_map_backdrop_viewport_transform.dart';

class CinematicActorDisplayPreviewOverlay extends StatelessWidget {
  const CinematicActorDisplayPreviewOverlay({
    super.key,
    required this.model,
    required this.mapWidth,
    required this.mapHeight,
    required this.compact,
  });

  final CinematicActorDisplayPreviewModel model;
  final int mapWidth;
  final int mapHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final actors = model.actors.where((actor) => actor.isRenderable).toList();
    if (actors.isEmpty || mapWidth <= 0 || mapHeight <= 0) {
      return const SizedBox.shrink(
        key: ValueKey('cinematic-builder-actor-display-overlay'),
      );
    }
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          if (size.isEmpty || !size.isFinite) {
            return const SizedBox.shrink(
              key: ValueKey('cinematic-builder-actor-display-overlay'),
            );
          }
          final transform = CinematicMapBackdropViewportTransform.fill(
            viewportSize: size,
            mapWidth: mapWidth,
            mapHeight: mapHeight,
          );
          return Stack(
            key: const ValueKey('cinematic-builder-actor-display-overlay'),
            clipBehavior: Clip.hardEdge,
            children: [
              for (final actor in actors)
                _ActorDisplayPlaceholder(
                  actor: actor,
                  anchor: transform.tileCenterBottom(
                    tileX: actor.position.x ?? 0,
                    tileY: actor.position.y ?? 0,
                  ),
                  compact: compact,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActorDisplayPlaceholder extends StatelessWidget {
  const _ActorDisplayPlaceholder({
    required this.actor,
    required this.anchor,
    required this.compact,
  });

  final CinematicActorDisplayPreviewActor actor;
  final Offset anchor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 70.0 : 92.0;
    final height = compact ? 34.0 : 44.0;
    return Positioned(
      left: anchor.dx - width / 2,
      top: anchor.dy - height,
      width: width,
      height: height,
      child: Semantics(
        label: 'Acteur statique ${actor.label}',
        child: Tooltip(
          message: actor.label,
          child: _ActorDisplayMarker(
            key: ValueKey<String>(
              'cinematic-builder-actor-display-actor-${actor.actorId}',
            ),
            actor: actor,
            compact: compact,
          ),
        ),
      ),
    );
  }
}

class _ActorDisplayMarker extends StatelessWidget {
  const _ActorDisplayMarker({
    super.key,
    required this.actor,
    required this.compact,
  });

  final CinematicActorDisplayPreviewActor actor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForActor(actor).resolve(context);
    final labelStyle = DefaultTextStyle.of(context).style.copyWith(
          color: tone.text,
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w900,
          height: 1,
        );
    final glyphStyle = DefaultTextStyle.of(context).style.copyWith(
          color: tone.text,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w900,
          height: 1,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          DecoratedBox(
            decoration: BoxDecoration(
              color: tone.soft,
              border: Border.all(color: tone.border),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: Text(
                actor.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
          ),
        if (!compact) const SizedBox(height: 3),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceBase.withValues(alpha: 0.9),
                border: Border.all(color: tone.border, width: 1.4),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: tone.border.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: SizedBox.square(
                dimension: compact ? 18 : 22,
                child: Center(
                  child: Text(
                    _glyphForActor(actor),
                    style: glyphStyle,
                  ),
                ),
              ),
            ),
            Positioned(
              right: compact ? -7 : -8,
              bottom: compact ? -5 : -6,
              child: _DirectionHint(
                actor: actor,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DirectionHint extends StatelessWidget {
  const _DirectionHint({
    required this.actor,
    required this.compact,
  });

  final CinematicActorDisplayPreviewActor actor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final tone = _toneForActor(actor).resolve(context);
    final isFallback =
        actor.directionSource == CinematicActorPreviewDirectionSource.fallback;
    return DecoratedBox(
      key: ValueKey<String>(
        'cinematic-builder-actor-display-direction-${actor.actorId}',
      ),
      decoration: BoxDecoration(
        color:
            isFallback ? colors.surfaceBase.withValues(alpha: 0.95) : tone.soft,
        border: Border.all(
          color: isFallback ? colors.borderSubtle : tone.border,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox.square(
        dimension: compact ? 14 : 16,
        child: Center(
          child: Text(
            _directionGlyph(actor.direction),
            style: DefaultTextStyle.of(context).style.copyWith(
                  color: isFallback ? colors.textMuted : tone.text,
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
        ),
      ),
    );
  }
}

PokeMapTone _toneForActor(CinematicActorDisplayPreviewActor actor) {
  return switch (actor.bindingStatus) {
    CinematicActorDisplayBindingStatus.player => PokeMapTone.brand,
    CinematicActorDisplayBindingStatus.mapEntity => PokeMapTone.map,
    CinematicActorDisplayBindingStatus.cinematicOnly => PokeMapTone.cinematic,
    CinematicActorDisplayBindingStatus.unbound ||
    CinematicActorDisplayBindingStatus.missing =>
      PokeMapTone.neutral,
  };
}

String _glyphForActor(CinematicActorDisplayPreviewActor actor) {
  return switch (actor.bindingStatus) {
    CinematicActorDisplayBindingStatus.player => 'P',
    CinematicActorDisplayBindingStatus.mapEntity => 'M',
    CinematicActorDisplayBindingStatus.cinematicOnly => 'C',
    CinematicActorDisplayBindingStatus.unbound ||
    CinematicActorDisplayBindingStatus.missing =>
      '?',
  };
}

String _directionGlyph(CinematicActorPreviewDirection direction) {
  return switch (direction) {
    CinematicActorPreviewDirection.north => 'N',
    CinematicActorPreviewDirection.south => 'S',
    CinematicActorPreviewDirection.east => 'E',
    CinematicActorPreviewDirection.west => 'W',
    CinematicActorPreviewDirection.unknown => '?',
  };
}
