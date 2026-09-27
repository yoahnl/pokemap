import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

const double kPlayerSplashTimelineMilliseconds = 7200;
const double kPlayerSplashHoldProgress = .82;
const Duration kPlayerSplashSlowLoadExitDuration = Duration(milliseconds: 1296);

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
    this.cinematic,
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
  final Widget? cinematic;
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
        cinematic: cinematic,
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
    this.cinematic,
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
  final Widget? cinematic;

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
    final eclipseTime = 3.4 * progress;
    final eclipseCollapse = _smooth(eclipseTime, .03, 1.55);
    final eclipseLogoOpacity = reducedMotion
        ? 0.0
        : _smooth(eclipseTime, .55, 1.1) *
            (1 - _smooth(eclipseTime, 1.35, 1.72));
    final markEntrance = reducedMotion ? 1.0 : _smooth(eclipseTime, 1.46, 2.04);
    final nameEntrance = reducedMotion ? 1.0 : _smooth(eclipseTime, 1.46, 2.04);
    final loadingEntrance =
        reducedMotion ? 1.0 : _smooth(eclipseTime, 2.16, 2.55);
    return Semantics(
      label: '${branding.displayName}. ${branding.signature}',
      value: '${(loadingProgress * 100).round()} %',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final stageWidth =
              math.min(viewport.width, viewport.height * 390 / 694);
          final lockupWidth = math.min(viewport.width * .74, 550.0);
          final symbolSize = math.min(
            math.min(lockupWidth * .24, viewport.height * .14),
            120.0,
          );
          final wordmarkWidth = lockupWidth - symbolSize - lockupWidth * .04;
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          return ColoredBox(
            color: background,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (cinematic != null)
                  Positioned.fill(child: cinematic!)
                else
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const ValueKey<String>('startup-splash-atmosphere'),
                      painter: _BackdropPainter(background: background),
                    ),
                  ),
                if (cinematic == null && !reducedMotion)
                  _EclipseMotion(
                    key: const ValueKey<String>('startup-splash-eclipse'),
                    time: eclipseTime,
                    departure: departure,
                    stageWidth: stageWidth,
                    viewportHeight: viewport.height,
                  ),
                if (cinematic == null && logo != null && !reducedMotion)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -viewport.height * .03),
                      child: Opacity(
                        key: const ValueKey<String>(
                          'startup-splash-eclipse-logo',
                        ),
                        opacity: eclipseLogoOpacity * (1 - departure),
                        child: Transform.rotate(
                          angle: ui.lerpDouble(
                            -9 * math.pi / 180,
                            0,
                            eclipseCollapse,
                          )!,
                          child: Transform.scale(
                            key: const ValueKey<String>(
                              'startup-splash-eclipse-scale',
                            ),
                            scale: ui.lerpDouble(
                              1.0,
                              .55,
                              _smooth(eclipseTime, .68, 1.45),
                            )!,
                            child: SizedBox.square(
                              dimension: stageWidth * .42,
                              child: Image(
                                image: logo!,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (cinematic == null)
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -viewport.height * .03),
                      child: SizedBox(
                        width: lockupWidth,
                        height: symbolSize,
                        child: Row(
                          children: <Widget>[
                            Opacity(
                              key: const ValueKey<String>(
                                  'startup-splash-reveal'),
                              opacity: markEntrance * (1 - departure),
                              child: SizedBox.square(
                                dimension: symbolSize,
                                child: logo == null
                                    ? const _FallbackMark()
                                    : Image(
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
                            SizedBox(width: lockupWidth * .04),
                            Opacity(
                              key:
                                  const ValueKey<String>('startup-splash-name'),
                              opacity: nameEntrance * (1 - departure),
                              child: SizedBox(
                                width: wordmarkWidth,
                                height: symbolSize,
                                child: wordmark == null
                                    ? _FallbackWordmark(
                                        name: branding.displayName,
                                      )
                                    : Image(
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
                          ],
                        ),
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

class _EclipseMotion extends StatelessWidget {
  const _EclipseMotion({
    super.key,
    required this.time,
    required this.departure,
    required this.stageWidth,
    required this.viewportHeight,
  });

  final double time;
  final double departure;
  final double stageWidth;
  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final collapse = _smooth(time, .03, 1.55);
    final orbitOpacity =
        .93 * _smooth(time, 0, .2) * (1 - _smooth(time, 1.42, 2.04));
    final softOpacity =
        .62 * _smooth(time, 0, .26) * (1 - _smooth(time, 1.35, 1.94));
    final discOpacity =
        _smooth(time, .08, .3) * (1 - _smooth(time, 1.35, 1.72));
    final crossing = _smooth(time, .2, 1.35);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _orbit(
          radius: stageWidth * .81,
          scale: ui.lerpDouble(.85, .58, collapse)!,
          rotation: ui.lerpDouble(40, 155, collapse)! * math.pi / 180,
          opacity: softOpacity * (1 - departure),
          soft: true,
        ),
        _orbit(
          radius: stageWidth * .725,
          scale: ui.lerpDouble(1.0, .55, collapse)!,
          rotation: ui.lerpDouble(-75, 42, collapse)! * math.pi / 180,
          opacity: orbitOpacity * (1 - departure),
          soft: false,
        ),
        Center(
          child: Transform.translate(
            offset: Offset(
              ui.lerpDouble(-stageWidth * .27, stageWidth * .37, crossing)!,
              -viewportHeight * .03,
            ),
            child: Opacity(
              opacity: discOpacity * (1 - departure),
              child: Transform.scale(
                scale: ui.lerpDouble(1.3, .76, collapse)!,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: RepaintBoundary(
                    child: SizedBox.square(
                      dimension: stageWidth * .485 * 2.5,
                      child: Image.asset(
                        'assets/splash/eclipse_disc.png',
                        package: 'map_player_ui',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _orbit({
    required double radius,
    required double scale,
    required double rotation,
    required double opacity,
    required bool soft,
  }) =>
      Center(
        child: Transform.translate(
          offset: Offset(0, -viewportHeight * .03),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  maxHeight: double.infinity,
                  child: RepaintBoundary(
                    child: SizedBox.square(
                      dimension: radius * 2.5,
                      child: Image.asset(
                        soft
                            ? 'assets/splash/eclipse_orbit_soft.png'
                            : 'assets/splash/eclipse_orbit_sharp.png',
                        package: 'map_player_ui',
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
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

double _smooth(double value, double start, double end) {
  final fraction = _interval(value, start, end);
  return fraction * fraction * (3 - 2 * fraction);
}

Color _brandColor(String hex, Color fallback) {
  final raw = hex.startsWith('#') ? hex.substring(1) : hex;
  if (raw.length != 6) return fallback;
  final value = int.tryParse(raw, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}
