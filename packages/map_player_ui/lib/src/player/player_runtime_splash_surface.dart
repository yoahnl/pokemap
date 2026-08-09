import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../theme/pokemap_player_theme.dart';

/// Host-neutral startup splash. Branding is data supplied by the runtime host;
/// no editor or product-host identity is embedded in this surface.
class PlayerRuntimeSplashSurface extends StatelessWidget {
  const PlayerRuntimeSplashSurface({
    super.key,
    required this.branding,
    required this.progress,
    required this.animationProgress,
    this.logo,
    this.reducedMotion = false,
  })  : assert(progress >= 0 && progress <= 1),
        assert(animationProgress >= 0 && animationProgress <= 1);

  final RuntimeHostSplashBranding branding;
  final double progress;
  final double animationProgress;
  final ImageProvider? logo;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PlayerSplashTimeline(
          key: const ValueKey<String>('startup-splash-timeline'),
          branding: branding,
          progress: reducedMotion
              ? 1
              : progress >= 1
                  ? animationProgress
                  : math.min(animationProgress, .9),
          loadingProgress: progress,
          logo: logo,
          reducedMotion: reducedMotion,
        ),
      );
}

/// Deterministic, externally controlled composition used by the startup shell.
class PlayerSplashTimeline extends StatelessWidget {
  const PlayerSplashTimeline({
    super.key,
    required this.branding,
    required this.progress,
    required this.loadingProgress,
    required this.reducedMotion,
    this.logo,
  })  : assert(progress >= 0 && progress <= 1),
        assert(loadingProgress >= 0 && loadingProgress <= 1);

  final RuntimeHostSplashBranding branding;
  final double progress;
  final double loadingProgress;
  final ImageProvider? logo;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final primary = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          branding.primaryColorHex,
        ) ??
        colors.primary;
    final secondary = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          branding.secondaryColorHex,
        ) ??
        colors.focus;
    final background = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          branding.backgroundColorHex,
        ) ??
        colors.background;
    final haloOpacity = _interval(0, .45);
    final markOpacity = _interval(.18, .58);
    final wordmarkOpacity = _interval(.4, .72);
    final signatureOpacity = _interval(.58, .81);
    final progressOpacity = _interval(.7, .9);
    final curtainOpacity = reducedMotion ? 0.0 : _interval(.9, 1);

    return Semantics(
      label: '${branding.displayName}. ${branding.signature}',
      value: '${(loadingProgress * 100).round()} %',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.25,
            colors: <Color>[
              Color.lerp(background, primary, .09)!,
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Center(
                child: Opacity(
                  key: const ValueKey<String>('startup-splash-halos'),
                  opacity: haloOpacity,
                  child: _OrbitComposition(
                    progress: reducedMotion ? 0 : progress,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(PlayerSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Opacity(
                        key: const ValueKey<String>('startup-splash-mark'),
                        opacity: markOpacity,
                        child: _SplashMark(logo: logo, color: primary),
                      ),
                      const SizedBox(height: PlayerSpacing.lg),
                      Opacity(
                        opacity: wordmarkOpacity,
                        child: Text(
                          branding.displayName,
                          textAlign: TextAlign.center,
                          style: context.playerTypography.displayStyle(
                            (Theme.of(context).textTheme.displaySmall ??
                                    const TextStyle())
                                .copyWith(
                              color: colors.textPrimary,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: PlayerSpacing.xs),
                      Opacity(
                        opacity: signatureOpacity,
                        child: Text(
                          branding.signature,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.textSecondary,
                                    letterSpacing: 1.3,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Opacity(
                  opacity: progressOpacity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Padding(
                      padding: const EdgeInsets.all(PlayerSpacing.xl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(PlayerRadii.pill),
                        child: LinearProgressIndicator(
                          key: const ValueKey<String>(
                            'startup-splash-progress',
                          ),
                          minHeight: 3,
                          value: loadingProgress,
                          color: primary,
                          backgroundColor: colors.outline,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Opacity(
                  opacity: curtainOpacity,
                  child: ColoredBox(color: background),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _interval(double begin, double end) =>
      ((progress - begin) / (end - begin)).clamp(0, 1);
}

class _SplashMark extends StatelessWidget {
  const _SplashMark({required this.logo, required this.color});

  final ImageProvider? logo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = _FallbackMark(color: color);
    if (logo == null) return fallback;
    return SizedBox.square(
      dimension: 116,
      child: Image(
        image: logo!,
        fit: BoxFit.contain,
        semanticLabel: null,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey<String>('startup-splash-fallback-mark'),
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(Icons.nights_stay_rounded, size: 48, color: color),
      );
}

class _OrbitComposition extends StatelessWidget {
  const _OrbitComposition({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: 330,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.rotate(
              angle: progress * math.pi * 1.4,
              child: Container(
                width: 294,
                height: 294,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: .38),
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: -progress * math.pi * 1.8,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: secondary.withValues(alpha: .3),
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
