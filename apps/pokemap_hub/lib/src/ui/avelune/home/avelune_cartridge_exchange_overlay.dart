import 'dart:io';

import 'package:flutter/material.dart';

import '../avelune_cartridge.dart';
import '../avelune_theme.dart';
import 'avelune_home_view_data.dart';

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
    final curve = context.aveluneMotion.movementCurve;
    final curved = curve.transform(value);
    final oldRect = reducedMotion
        ? heroRect
        : RectTween(begin: heroRect, end: sourceShelfRect).transform(curved)!;
    final newRect = reducedMotion
        ? heroRect
        : RectTween(begin: targetShelfRect, end: heroRect).transform(curved)!;
    final connectorOpacity = _connectorOpacity(value);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned.fromRect(
              rect: oldRect,
              child: Opacity(
                opacity: _oldOpacity(value),
                child: SizedBox.expand(
                  key: const ValueKey<String>(
                    'avelune-exchange-old-cartridge',
                  ),
                  child: _cartridge(
                    sourceGame,
                    connectorOpacity: connectorOpacity,
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: newRect,
              child: Opacity(
                opacity: _newOpacity(value),
                child: SizedBox.expand(
                  key: const ValueKey<String>(
                    'avelune-exchange-new-cartridge',
                  ),
                  child: _cartridge(
                    targetGame,
                    connectorOpacity: connectorOpacity,
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

double _connectorOpacity(double progress) {
  final distanceFromMidpoint = (progress - 0.5).abs();
  return ((distanceFromMidpoint - 0.06) / 0.12).clamp(0, 1);
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}
