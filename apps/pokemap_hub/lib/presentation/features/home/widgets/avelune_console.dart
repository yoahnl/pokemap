import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/assets/avelune_material_catalog.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';

/// Aspect ratio of the console hardware, taken from its own art.
///
/// Every layer is painted with `BoxFit.fill`, which maps the whole canvas onto
/// the box, so this has to match `console/body.webp` (1200x360). It used to be
/// 3.08, stretching the hardware vertically by 8 percent.
const double kAveluneConsoleAspectRatio = 1200 / 360;

/// Fraction of the console box height at which the feet actually rest.
///
/// `console/body.webp` carries 36 px of transparent padding below the feet on
/// its 360 px canvas, so the box bottom sits a tenth of the console height below
/// the hardware. Anything that seats the console on a surface has to use this,
/// not `Rect.bottom`, or the console floats.
const double kAveluneConsoleFootlineFraction = 324 / 360;

/// Centre of the slot opening, as a fraction of the console box height.
///
/// The dark cavity in `console/body.webp` runs from y=87 to y=108 on its 360 px
/// canvas. The geometry used to place the slot at 0.16, which is up on the deck
/// well above the opening.
const double kAveluneConsoleSlotCenterFraction = 97.5 / 360;

/// The near lip of the slot opening: the line at which a descending cartridge
/// is swallowed.
///
/// Cartridges are drawn over the console and clipped here, so they disappear
/// into the cavity. Drawing them behind the whole console instead hid them at
/// its top silhouette — above the opening — which read as sliding behind the
/// hardware rather than into it.
const double kAveluneConsoleSlotMouthFraction = 108 / 360;

enum AveluneConsoleState { idle, inserting, latched, launching, error }

class AveluneConsole extends StatelessWidget {
  const AveluneConsole({
    super.key,
    this.insertionProgress = 0,
    this.state,
  });

  final double insertionProgress;
  final AveluneConsoleState? state;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    final materials = context.aveluneMaterials;
    final motion = context.aveluneMotion;
    final progress = insertionProgress.clamp(0.0, 1.0);
    final effectiveState = state ?? _stateForProgress(progress);
    final ledColor = _ledColor(colors, effectiveState);
    final ledStrength = _ledStrength(effectiveState);

    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: kAveluneConsoleAspectRatio,
        child: RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                key: const ValueKey<String>('avelune-console-silhouette'),
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: height * 0.34,
                    child: Image.asset(
                      AveluneMaterialCatalog.consoleContactShadow.path,
                      key: const ValueKey<String>(
                        'avelune-console-contact-shadow-layer',
                      ),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned.fill(
                    key: const ValueKey<String>('avelune-console-faceplate'),
                    child: Image.asset(
                      AveluneMaterialCatalog.consoleBody.path,
                      key: const ValueKey<String>(
                        'avelune-console-body-layer',
                      ),
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Positioned(
                    key: const ValueKey<String>(
                      'avelune-console-insertion-well',
                    ),
                    left: width * 0.295,
                    right: width * 0.295,
                    top: height * 0.205,
                    height: height * 0.15,
                    child: AnimatedContainer(
                      duration: motion.selection,
                      curve: motion.movementCurve,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height * 0.035),
                        gradient: RadialGradient(
                          radius: 1.1,
                          colors: <Color>[
                            ledColor.withValues(
                              alpha: _slotGlowOpacity(effectiveState, progress),
                            ),
                            colors.background.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    key: const ValueKey<String>('avelune-console-slot'),
                    left: width * 0.28,
                    right: width * 0.28,
                    top: height * 0.17,
                    height: height * 0.2,
                    child: KeyedSubtree(
                      key: const ValueKey<String>(
                        'avelune-console-slot-lip',
                      ),
                      child: Image.asset(
                        AveluneMaterialCatalog.consoleSlot.path,
                        key: const ValueKey<String>(
                          'avelune-console-slot-layer',
                        ),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * 0.37,
                    right: width * 0.37,
                    top: height * 0.4,
                    height: height * 0.13,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'AVELUNE',
                          maxLines: 1,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colors.textPrimary.withValues(alpha: 0.68),
                            fontSize: height * 0.105,
                            fontWeight: FontWeight.w800,
                            letterSpacing: height * 0.012,
                            shadows: <Shadow>[
                              Shadow(
                                color: colors.background.withValues(alpha: 0.9),
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: materials.consoleWearOpacity,
                      child: Image.asset(
                        AveluneMaterialCatalog.consoleWear.path,
                        key: const ValueKey<String>(
                          'avelune-console-wear-layer',
                        ),
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * 0.452,
                    width: width * 0.096,
                    top: height * 0.585,
                    height: height * 0.066,
                    child: AnimatedContainer(
                      key: const ValueKey<String>('avelune-console-led'),
                      duration: motion.selection,
                      curve: motion.movementCurve,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(height),
                        border: Border.all(
                          color: colors.background.withValues(alpha: 0.72),
                          width: 1,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color.lerp(ledColor, colors.textPrimary, 0.28)!,
                            ledColor,
                            Color.lerp(ledColor, colors.background, 0.34)!,
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: ledColor.withValues(
                              alpha: 0.72 * ledStrength,
                            ),
                            blurRadius: height * 0.065 * ledStrength,
                            spreadRadius: height * 0.006 * ledStrength,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class AveluneConsoleDock extends StatelessWidget {
  const AveluneConsoleDock({
    super.key,
    required this.consoleWidth,
    this.insertionProgress = 0,
    this.state,
  });

  final double consoleWidth;
  final double insertionProgress;
  final AveluneConsoleState? state;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Column(
      children: <Widget>[
        SizedBox(
          width: consoleWidth,
          child: AveluneConsole(
            insertionProgress: insertionProgress,
            state: state,
          ),
        ),
        Container(
          key: const ValueKey<String>('avelune-console-shelf'),
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.background.withValues(alpha: 0.96),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  kAveluneWalnutTextureAssetPath,
                  key: const ValueKey<String>('avelune-hero-wood-dock'),
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors.textPrimary.withValues(alpha: 0.2),
                        colors.woodHighlight.withValues(alpha: 0.12),
                        colors.background.withValues(alpha: 0.56),
                      ],
                      stops: const <double>[0, 0.3, 1],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: colors.textPrimary.withValues(alpha: 0.18),
                      ),
                      bottom: BorderSide(
                        color: colors.background.withValues(alpha: 0.84),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 9,
                  right: 9,
                  top: 6,
                  height: 1,
                  child: ColoredBox(
                    color: colors.woodHighlight.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

AveluneConsoleState _stateForProgress(double progress) {
  if (progress <= 0) return AveluneConsoleState.idle;
  if (progress >= 0.96) return AveluneConsoleState.latched;
  return AveluneConsoleState.inserting;
}

Color _ledColor(AveluneColors colors, AveluneConsoleState state) =>
    switch (state) {
      AveluneConsoleState.idle => colors.accent,
      AveluneConsoleState.inserting => colors.warning,
      AveluneConsoleState.latched => colors.success,
      AveluneConsoleState.launching => colors.accentBright,
      AveluneConsoleState.error => colors.error,
    };

double _ledStrength(AveluneConsoleState state) => switch (state) {
      AveluneConsoleState.idle => 0.45,
      AveluneConsoleState.inserting => 0.72,
      AveluneConsoleState.latched => 0.82,
      AveluneConsoleState.launching => 1,
      AveluneConsoleState.error => 0.9,
    };

double _slotGlowOpacity(AveluneConsoleState state, double progress) =>
    switch (state) {
      AveluneConsoleState.idle => 0.08,
      AveluneConsoleState.inserting => 0.18 + (progress * 0.42),
      AveluneConsoleState.latched => 0.62,
      AveluneConsoleState.launching => 0.78,
      AveluneConsoleState.error => 0.48,
    };
