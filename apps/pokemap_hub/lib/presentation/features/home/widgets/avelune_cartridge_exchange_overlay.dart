import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';
import 'package:pokemap_hub/presentation/shared/artwork/local_artwork_image.dart';

class AveluneCartridgeExchangeOverlay extends StatelessWidget {
  const AveluneCartridgeExchangeOverlay({
    super.key,
    required this.progress,
    required this.sourceGame,
    required this.targetGame,
    required this.heroRect,
    required this.sourceShelfRect,
    required this.targetShelfRect,
    required this.reducedMotion,
  });

  final double progress;
  final AveluneGameViewData sourceGame;
  final AveluneGameViewData targetGame;
  final Rect heroRect;
  final Rect sourceShelfRect;
  final Rect targetShelfRect;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    final curve = context.aveluneMotion.exchangeCurve;
    final curved = curve.transform(value);
    final oldRect = reducedMotion
        ? heroRect
        : _arcRect(
            begin: heroRect,
            end: sourceShelfRect,
            progress: curved,
          );
    final newRect = reducedMotion
        ? heroRect
        : _arcRect(
            begin: targetShelfRect,
            end: heroRect,
            progress: curved,
          );

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned.fromRect(
              rect: oldRect,
              child: Opacity(
                opacity: reducedMotion ? _oldOpacity(value) : 1,
                child: SizedBox.expand(
                  key: const ValueKey<String>(
                    'avelune-exchange-old-cartridge',
                  ),
                  child: _cartridge(
                    sourceGame,
                    connectorOpacity: 1,
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: newRect,
              child: Opacity(
                opacity: reducedMotion ? _newOpacity(value) : 1,
                child: SizedBox.expand(
                  key: const ValueKey<String>(
                    'avelune-exchange-new-cartridge',
                  ),
                  child: _cartridge(
                    targetGame,
                    connectorOpacity: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartridge(
    AveluneGameViewData game, {
    required double connectorOpacity,
  }) =>
      AveluneCartridge(
        gameId: game.id,
        title: game.title,
        subtitle: game.subtitle,
        artwork: _artworkFor(game.artwork),
        shellColor: game.shellColor,
        selected: true,
        invalid: !game.isValid,
        displaySize: AveluneCartridgeDisplaySize.hero,
        connectorsOpacity: connectorOpacity,
      );
}

double _oldOpacity(double progress) =>
    1 - const Interval(0.3, 0.58, curve: Curves.easeIn).transform(progress);

double _newOpacity(double progress) =>
    const Interval(0.42, 0.72, curve: Curves.easeOut).transform(progress);

Rect _arcRect({
  required Rect begin,
  required Rect end,
  required double progress,
}) {
  if (progress <= 0) return begin;
  if (progress >= 1) return end;
  final travel = end.center - begin.center;
  final distance = travel.distance;
  final perpendicular = distance == 0
      ? Offset.zero
      : Offset(-travel.dy / distance, travel.dx / distance);
  final laneWidth = math.min(
    math.max(begin.width, end.width) * 0.46,
    48,
  );
  final arc = math.sin(math.pi * progress) * laneWidth;
  final center =
      Offset.lerp(begin.center, end.center, progress)! + (perpendicular * arc);
  return Rect.fromCenter(
    center: center,
    width: _lerp(begin.width, end.width, progress),
    height: _lerp(begin.height, end.height, progress),
  );
}

double _lerp(double begin, double end, double progress) =>
    begin + ((end - begin) * progress);

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return requireLocalArtworkImage(path);
}
