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
  final String? loadingLabel;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final displayName = branding.displayName.trim();
    final background = _brandColor(
      branding.backgroundColorHex,
      const Color(0xFF02040A),
    );
    final primary = _brandColor(
      branding.primaryColorHex,
      const Color(0xFFF2D9B2),
    );
    final secondary = _brandColor(
      branding.secondaryColorHex,
      const Color(0xFF9E79D7),
    );
    final loadingText = loadingProgress >= 1
        ? 'PRÊT'
        : (loadingLabel?.trim().isNotEmpty ?? false)
            ? loadingLabel!.trim().toUpperCase()
            : 'PRÉPARATION DU VOYAGE';
    return Semantics(
      label: '$displayName. ${branding.signature}',
      value: '${(loadingProgress * 100).round()} %',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = constraints.biggest;
          final camera = reducedMotion
              ? const _CameraFrame(scale: 1, dx: 0, dy: 0, rotation: 0)
              : _cameraFrame(progress, viewport);
          final chroma = reducedMotion
              ? 0.0
              : (1 - _interval(progress, 0, .22)).clamp(0.0, 1.0);
          final logoOpacity = reducedMotion
              ? 1.0
              : Curves.easeInOut.transform(_interval(progress, 0, .1));
          final loadingOpacity = reducedMotion
              ? 1.0
              : Curves.easeOut.transform(_interval(progress, .43, .58));
          final curtain = reducedMotion
              ? 0.0
              : (_exitOpacity(progress) + exitProgress * .14).clamp(0.0, 1.0);
          final bottomPadding = MediaQuery.paddingOf(context).bottom;
          final loadingWidth = math.min(viewport.width * .76, 460.0);
          return ColoredBox(
            color: background,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  key: const ValueKey<String>('startup-splash-atmosphere'),
                  painter: _BackdropPainter(
                    progress: reducedMotion ? .6 : progress,
                    ambientProgress: ambientProgress,
                    background: background,
                  ),
                ),
                Center(
                  child: Opacity(
                    key: const ValueKey<String>('startup-splash-reveal'),
                    opacity: logoOpacity,
                    child: Transform.translate(
                      offset: Offset(camera.dx, camera.dy),
                      child: Transform.rotate(
                        angle: camera.rotation,
                        child: Transform.scale(
                          key: const ValueKey<String>(
                            'startup-splash-mark-zoom',
                          ),
                          scale: camera.scale,
                          child: _BrandLockup(
                            viewport: viewport,
                            branding: branding,
                            logo: logo,
                            wordmark: wordmark,
                            chroma: chroma,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: math.max(
                    viewport.height * (viewport.width < 760 ? .075 : .085),
                    bottomPadding + 24,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: loadingOpacity,
                      child: _LoadingZone(
                        width: loadingWidth,
                        label: loadingText,
                        progress: loadingProgress,
                        primary: primary,
                        secondary: secondary,
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: ColoredBox(
                    key: const ValueKey<String>('startup-splash-curtain'),
                    color: Colors.black.withValues(alpha: curtain),
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

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({
    required this.viewport,
    required this.branding,
    required this.logo,
    required this.wordmark,
    required this.chroma,
  });

  final Size viewport;
  final RuntimeHostSplashBranding branding;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final double chroma;

  @override
  Widget build(BuildContext context) {
    final width = math.min(viewport.width * .78, 640.0);
    final markWidth = width * .27;
    final wordmarkWidth = width * .68;
    final gap = width * .05;
    final lockup = RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Opacity(
            key: const ValueKey<String>('startup-splash-mark'),
            opacity: 1,
            child: SizedBox.square(
              dimension: markWidth,
              child: logo == null
                  ? const _FallbackMark()
                  : Image(
                      image: logo!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => const _FallbackMark(),
                    ),
            ),
          ),
          SizedBox(width: gap),
          Opacity(
            key: const ValueKey<String>('startup-splash-wordmark'),
            opacity: 1,
            child: SizedBox(
              width: wordmarkWidth,
              height: markWidth,
              child: wordmark == null
                  ? _FallbackWordmark(name: branding.displayName)
                  : Image(
                      key: const ValueKey<String>(
                        'startup-splash-wordmark-image',
                      ),
                      image: wordmark!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) =>
                          _FallbackWordmark(name: branding.displayName),
                    ),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      width: width,
      height: markWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          if (chroma > .001 && logo != null && wordmark != null) ...<Widget>[
            Transform.translate(
              offset: Offset(-5 * chroma, 0),
              child: _EchoLockup(
                markWidth: markWidth,
                wordmarkWidth: wordmarkWidth,
                gap: gap,
                logo: logo!,
                wordmark: wordmark!,
                tint: const Color(0xFFFF4B85).withValues(alpha: .26 * chroma),
              ),
            ),
            Transform.translate(
              offset: Offset(5 * chroma, 0),
              child: _EchoLockup(
                markWidth: markWidth,
                wordmarkWidth: wordmarkWidth,
                gap: gap,
                logo: logo!,
                wordmark: wordmark!,
                tint: const Color(0xFF54BBFF).withValues(alpha: .26 * chroma),
              ),
            ),
          ],
          lockup,
        ],
      ),
    );
  }
}

class _EchoLockup extends StatelessWidget {
  const _EchoLockup({
    required this.markWidth,
    required this.wordmarkWidth,
    required this.gap,
    required this.logo,
    required this.wordmark,
    required this.tint,
  });

  final double markWidth;
  final double wordmarkWidth;
  final double gap;
  final ImageProvider logo;
  final ImageProvider wordmark;
  final Color tint;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Image(
            image: logo,
            width: markWidth,
            height: markWidth,
            fit: BoxFit.contain,
            color: tint,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => SizedBox.square(dimension: markWidth),
          ),
          SizedBox(width: gap),
          Image(
            image: wordmark,
            width: wordmarkWidth,
            height: markWidth,
            fit: BoxFit.contain,
            color: tint,
            colorBlendMode: BlendMode.srcIn,
            errorBuilder: (_, __, ___) => SizedBox(
              width: wordmarkWidth,
              height: markWidth,
            ),
          ),
        ],
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
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
          ),
        ),
      );
}

class _LoadingZone extends StatelessWidget {
  const _LoadingZone({
    required this.width,
    required this.label,
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double width;
  final String label;
  final double progress;
  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    key: const ValueKey<String>(
                      'startup-splash-progress-label',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFAAA9B4),
                      fontFamily: 'PokeMapSplashDMSans',
                      package: 'map_player_ui',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(progress * 100).round()}%',
                  key: const ValueKey<String>('startup-splash-progress-value'),
                  style: const TextStyle(
                    color: Color(0xFFAAA9B4),
                    fontFamily: 'PokeMapSplashDMSans',
                    package: 'map_player_ui',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: width,
              height: 2,
              child: CustomPaint(
                key: const ValueKey<String>('startup-splash-progress'),
                painter: _ProgressPainter(progress, primary, secondary),
              ),
            ),
          ],
        ),
      );
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.progress, this.primary, this.secondary);

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF44434F),
    );
    if (progress <= 0) return;
    final fill = Rect.fromLTWH(0, 0, size.width * progress, size.height);
    canvas.drawRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[secondary, primary],
        ).createShader(fill),
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.progress,
    required this.ambientProgress,
    required this.background,
  });

  final double progress;
  final double ambientProgress;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = background,
    );
    final center = Offset(size.width * .5, size.height * .48);
    final ambient = .035 + math.sin(ambientProgress * math.pi * 2) * .006;
    canvas.drawCircle(
      center,
      math.max(size.width, size.height) * .54,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          math.max(size.width, size.height) * .54,
          <Color>[
            const Color(0xFF4D3B7C).withValues(alpha: ambient),
            Colors.transparent,
          ],
        ),
    );
    final sweep = 1 - _interval(progress, .03, .44);
    if (sweep <= 0) return;
    final x = ui.lerpDouble(-size.width * .28, size.width * 1.2,
        Curves.easeOutCubic.transform(_interval(progress, 0, .44)))!;
    final rect = Rect.fromCenter(
      center: Offset(x, size.height * .48),
      width: size.width * .65,
      height: size.height * 1.8,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(
          rect.center,
          rect.width * .5,
          <Color>[
            const Color(0xFF718AFF).withValues(alpha: .065 * sweep),
            const Color(0xFF9B54BE).withValues(alpha: .025 * sweep),
            Colors.transparent,
          ],
          <double>[0, .55, 1],
        ),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ambientProgress != ambientProgress ||
      oldDelegate.background != background;
}

class _CameraFrame {
  const _CameraFrame({
    required this.scale,
    required this.dx,
    required this.dy,
    required this.rotation,
  });

  final double scale;
  final double dx;
  final double dy;
  final double rotation;
}

_CameraFrame _cameraFrame(double progress, Size viewport) {
  final travel = Curves.easeOutCubic.transform(_interval(progress, 0, .48));
  return _CameraFrame(
    scale: ui.lerpDouble(5.2, 1, travel)!,
    dx: ui.lerpDouble(viewport.width * 1.27, 0, travel)!,
    dy: ui.lerpDouble(viewport.height * .06, 0, travel)!,
    rotation: ui.lerpDouble(-.035, 0, travel)!,
  );
}

double _exitOpacity(double progress) =>
    Curves.easeInCubic
        .transform(_interval(progress, kPlayerSplashHoldProgress, 1)) *
    .86;

double _interval(double value, double start, double end) =>
    ((value - start) / (end - start)).clamp(0.0, 1.0);

Color _brandColor(String hex, Color fallback) {
  final raw = hex.startsWith('#') ? hex.substring(1) : hex;
  if (raw.length != 6) return fallback;
  final value = int.tryParse(raw, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}
