import 'dart:io';

import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/features/home/widgets/avelune_cartridge.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/presentation/design_system/motion/avelune_interaction_state.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_geometry.dart';
import 'package:pokemap_hub/presentation/features/home/state/avelune_home_view_data.dart';

class AveluneCartridgeInsertionOverlay extends StatelessWidget {
  const AveluneCartridgeInsertionOverlay({
    super.key,
    required this.game,
    required this.state,
    required this.heroRect,
    required this.trajectory,
    required this.motion,
    required this.reducedMotion,
  });

  final AveluneGameViewData game;
  final AveluneInteractionState state;
  final Rect heroRect;
  final AveluneInsertionTrajectory trajectory;
  final AveluneMotionTokens motion;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final duration = _durationFor(state, motion);
    final targetRect = _targetRect();
    final latched = state == AveluneInteractionState.latched ||
        state == AveluneInteractionState.launching;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            AnimatedPositioned.fromRect(
              rect: targetRect,
              duration: duration,
              curve: _curveFor(state, motion),
              child: AnimatedOpacity(
                opacity: _opacityFor(state, reducedMotion),
                duration: duration,
                curve: motion.movementCurve,
                child: AnimatedScale(
                  scale: latched ? 0.975 : 1,
                  duration: duration,
                  curve: motion.pressCurve,
                  child: AnimatedContainer(
                    key: const ValueKey<String>(
                      'avelune-cartridge-insertion-overlay',
                    ),
                    duration: duration,
                    curve: motion.movementCurve,
                    decoration: BoxDecoration(
                      boxShadow: latched
                          ? context.aveluneDepth.contact
                          : context.aveluneDepth.floatingObject,
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: _connectorOpacityFor(state)),
                      duration: duration,
                      curve: motion.movementCurve,
                      builder: (context, connectorOpacity, _) =>
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Rect _targetRect() {
    if (reducedMotion && state != AveluneInteractionState.idle) {
      return _rectAround(trajectory.latchedCenter);
    }
    return switch (state) {
      AveluneInteractionState.aligning => _rectAround(trajectory.alignedCenter),
      AveluneInteractionState.descending ||
      AveluneInteractionState.latched ||
      AveluneInteractionState.launching =>
        _rectAround(trajectory.latchedCenter),
      _ => heroRect,
    };
  }

  Rect _rectAround(Offset center) => Rect.fromCenter(
        center: center,
        width: heroRect.width,
        height: heroRect.height,
      );
}

Duration _durationFor(
  AveluneInteractionState state,
  AveluneMotionTokens motion,
) =>
    switch (state) {
      AveluneInteractionState.aligning => motion.insertionAlign,
      AveluneInteractionState.descending => motion.insertionDescend,
      AveluneInteractionState.latched => motion.insertionLatch,
      AveluneInteractionState.launching => motion.insertionLaunchDelay,
      AveluneInteractionState.error ||
      AveluneInteractionState.recovering ||
      AveluneInteractionState.idle =>
        motion.selection,
      _ => Duration.zero,
    };

Curve _curveFor(
  AveluneInteractionState state,
  AveluneMotionTokens motion,
) =>
    state == AveluneInteractionState.descending
        ? motion.descentCurve
        : motion.movementCurve;

/// Connectors stay visible on the way down and fade as they enter the slot,
/// rather than blinking out the moment the descent starts.
double _connectorOpacityFor(AveluneInteractionState state) => switch (state) {
      AveluneInteractionState.latched || AveluneInteractionState.launching => 0,
      _ => 1,
    };

double _opacityFor(AveluneInteractionState state, bool reducedMotion) {
  // The cartridge used to fade out while launching, which read as the game
  // eating it. It stays seated in the slot until the player screen takes over.
  if (reducedMotion && state == AveluneInteractionState.descending) return 0.4;
  return 1;
}

ImageProvider<Object>? _artworkFor(AveluneArtworkViewData artwork) {
  final path = artwork.path;
  if (path == null || path.trim().isEmpty) return null;
  return FileImage(File(path));
}
