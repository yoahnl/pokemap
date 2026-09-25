import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

const double kPlayerSplashTimelineMilliseconds = 7200;
const double kPlayerSplashHoldProgress = .82;
const Duration kPlayerSplashSlowLoadExitDuration = Duration(milliseconds: 1296);
const ColorFilter _artworkTone = ColorFilter.matrix(<double>[
  .36,
  .55,
  .09,
  0,
  0,
  .21,
  .70,
  .09,
  0,
  0,
  .21,
  .55,
  .24,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class PlayerRuntimeSplashSurface extends StatelessWidget {
  const PlayerRuntimeSplashSurface({
    super.key,
    required this.branding,
    required this.progress,
    required this.animationProgress,
    this.exitProgress = 0,
    this.ambientProgress,
    this.loadingLabel,
    this.logo,
    this.wordmark,
    this.reducedMotion = false,
  })  : assert(progress >= 0 && progress <= 1),
        assert(animationProgress >= 0 && animationProgress <= 1),
        assert(exitProgress >= 0 && exitProgress <= 1),
        assert(ambientProgress == null ||
            (ambientProgress >= 0 && ambientProgress <= 1));

  final RuntimeHostSplashBranding branding;
  final double progress;
  final double animationProgress;
  final double exitProgress;
  final double? ambientProgress;
  final String? loadingLabel;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final timelineProgress = reducedMotion
        ? kPlayerSplashHoldProgress
        : progress >= 1
            ? animationProgress
            : math.min(animationProgress, kPlayerSplashHoldProgress);
    return Scaffold(
      backgroundColor: _brandColor(
        branding.backgroundColorHex,
        const Color(0xFF02040A),
      ),
      body: PlayerSplashTimeline(
        key: const ValueKey<String>('startup-splash-timeline'),
        branding: branding,
        progress: timelineProgress,
        exitProgress: progress >= 1 ? exitProgress : 0,
        ambientProgress: ambientProgress ?? animationProgress,
        loadingProgress: progress,
        loadingLabel: loadingLabel,
        logo: logo,
        wordmark: wordmark,
        reducedMotion: reducedMotion,
      ),
    );
  }
}

class PlayerSplashTimeline extends StatelessWidget {
  const PlayerSplashTimeline({
    super.key,
    required this.branding,
    required this.progress,
    required this.exitProgress,
    required this.ambientProgress,
    required this.loadingProgress,
    required this.reducedMotion,
    this.loadingLabel,
    this.logo,
    this.wordmark,
  })  : assert(progress >= 0 && progress <= 1),
        assert(exitProgress >= 0 && exitProgress <= 1),
        assert(ambientProgress >= 0 && ambientProgress <= 1),
        assert(loadingProgress >= 0 && loadingProgress <= 1);

  final RuntimeHostSplashBranding branding;
  final double progress;
  final double exitProgress;
  final double ambientProgress;
  final double loadingProgress;
  final bool reducedMotion;
  final String? loadingLabel;
  final ImageProvider? logo;
  final ImageProvider? wordmark;

  @override
  Widget build(BuildContext context) {
    final background = _brandColor(
      branding.backgroundColorHex,
      const Color(0xFF02040A),
    );
    final departure = reducedMotion
        ? 0.0
        : Curves.easeInOutCubic.transform(
            _interval(progress, kPlayerSplashHoldProgress, 1),
          );
    final markEntrance = reducedMotion
        ? 1.0
        : Curves.easeOutCubic.transform(_interval(progress, .02, .37));
    final nameEntrance = reducedMotion
        ? 1.0
        : Curves.easeOutCubic.transform(_interval(progress, .23, .56));
    final loadingEntrance = reducedMotion
        ? 1.0
        : Curves.easeOut.transform(_interval(progress, .57, .77));
    return Semantics(
      label: '${branding.displayName}. ${branding.signature}',
      value: '${(loadingProgress * 100).round()} %',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final symbolSize = math.min(
            math.min(viewport.width * .39, viewport.height * .19),
            180.0,
          );
          final wordmarkWidth = math.min(viewport.width * .66, 340.0);
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return ColoredBox(
            color: background,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  key: const ValueKey<String>('startup-splash-atmosphere'),
                  painter: _BackdropPainter(
                    background: background,
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, -viewport.height * .025),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Opacity(
                          key: const ValueKey<String>('startup-splash-reveal'),
                          opacity: markEntrance * (1 - departure),
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - markEntrance)),
                            child: Transform.scale(
                              key: const ValueKey<String>(
                                'startup-splash-mark-zoom',
                              ),
                              scale: .96 + .04 * markEntrance,
                              child: SizedBox.square(
                                dimension: symbolSize,
                                child: logo == null
                                    ? const _FallbackMark()
                                    : ColorFiltered(
                                        colorFilter: _artworkTone,
                                        child: Image(
                                          key: const ValueKey<String>(
                                            'startup-splash-mark',
                                          ),
                                          image: logo!,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.medium,
                                          errorBuilder: (_, __, ___) =>
                                              const _FallbackMark(),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: math.min(viewport.height * .025, 25)),
                        Opacity(
                          key: const ValueKey<String>('startup-splash-name'),
                          opacity: nameEntrance * (1 - departure),
                          child: Transform.translate(
                            offset: Offset(0, 8 * (1 - nameEntrance)),
                            child: SizedBox(
                              width: wordmarkWidth,
                              height: wordmarkWidth * .34,
                              child: wordmark == null
                                  ? _FallbackWordmark(
                                      name: branding.displayName,
                                    )
                                  : ColorFiltered(
                                      colorFilter: _artworkTone,
                                      child: Image(
                                        key: const ValueKey<String>(
                                          'startup-splash-wordmark-image',
                                        ),
                                        image: wordmark!,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.medium,
                                        errorBuilder: (_, __, ___) =>
                                            _FallbackWordmark(
                                          name: branding.displayName,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: math.max(viewport.height * .075, bottomInset + 24),
                  child: Opacity(
                    opacity: loadingEntrance * (1 - departure),
                    child: Center(
                      child: _LoadingZone(
                        width: math.min(viewport.width * .72, 380.0),
                        progress: loadingProgress,
                        ambientProgress: ambientProgress,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: ColoredBox(
                    key: const ValueKey<String>('startup-splash-curtain'),
                    color: Colors.black.withValues(alpha: exitProgress),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark();

  @override
  Widget build(BuildContext context) => Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          key: const ValueKey<String>('startup-splash-fallback-mark'),
          size: 54,
          color: const Color(0xFFF8F5FF),
        ),
      );
}

class _FallbackWordmark extends StatelessWidget {
  const _FallbackWordmark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFF8F5FF),
            fontFamily: 'PokeMapSplashDMSans',
            package: 'map_player_ui',
            fontSize: 42,
            fontWeight: FontWeight.w400,
            letterSpacing: 7,
            decoration: TextDecoration.none,
          ),
        ),
      );
}

class _LoadingZone extends StatelessWidget {
  const _LoadingZone({
    required this.width,
    required this.progress,
    required this.ambientProgress,
  });

  final double width;
  final double progress;
  final double ambientProgress;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'CHARGEMENT',
                    key: ValueKey<String>('startup-splash-progress-label'),
                    style: TextStyle(
                      color: Color(0xFF777481),
                      fontFamily: 'PokeMapSplashDMSans',
                      package: 'map_player_ui',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (progress > 0 && progress < 1)
                  Text(
                    '${(progress * 100).round()}%',
                    key: const ValueKey<String>(
                      'startup-splash-progress-value',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF777481),
                      fontFamily: 'PokeMapSplashDMSans',
                      package: 'map_player_ui',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 11),
            SizedBox(
              height: 1,
              width: width,
              child: CustomPaint(
                key: const ValueKey<String>('startup-splash-progress'),
                painter: _ProgressPainter(progress, ambientProgress),
              ),
            ),
          ],
        ),
      );
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.progress, this.ambientProgress);

  final double progress;
  final double ambientProgress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF33313B),
    );
    final width = progress > 0 ? size.width * progress : size.width * .18;
    final start =
        progress > 0 ? 0.0 : (size.width + width) * ambientProgress - width;
    canvas.drawRect(
      Rect.fromLTWH(start, 0, width, size.height),
      Paint()..color = const Color(0xFFB9B3C6),
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ambientProgress != ambientProgress;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.background,
  });

  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final center = Offset(size.width * .5, size.height * .47);
    final radius = math.max(size.width, size.height) * .52;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          <Color>[
            const Color(0xFF52456C).withValues(alpha: .10),
            Colors.transparent,
          ],
        ),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.background != background;
}

double _interval(double value, double start, double end) =>
    ((value - start) / (end - start)).clamp(0.0, 1.0);

Color _brandColor(String hex, Color fallback) {
  final raw = hex.startsWith('#') ? hex.substring(1) : hex;
  if (raw.length != 6) return fallback;
  final value = int.tryParse(raw, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}
