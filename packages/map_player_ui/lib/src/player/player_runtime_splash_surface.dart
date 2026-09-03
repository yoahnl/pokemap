import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

const double kPlayerSplashTimelineMilliseconds = 7200;
const double kPlayerSplashHoldProgress = .82;
const Duration kPlayerSplashSlowLoadExitDuration = Duration(
  milliseconds: 1296,
);

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
        assert(
          ambientProgress == null ||
              (ambientProgress >= 0 && ambientProgress <= 1),
        );

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
      backgroundColor: const Color(0xFF02040A),
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
    final primary = _opaqueHex(branding.primaryColorHex, 0xFFF2D9B2);
    final secondary = _opaqueHex(branding.secondaryColorHex, 0xFF9E79D7);
    final background = _opaqueHex(branding.backgroundColorHex, 0xFF02040A);
    final time = progress * kPlayerSplashTimelineMilliseconds +
        exitProgress * branding.finalCurtainDuration.inMilliseconds;
    final ambientTime = ambientProgress * 10000;
    final label = loadingProgress >= 1
        ? 'PRÊT'
        : (loadingLabel?.trim().isNotEmpty ?? false)
            ? loadingLabel!.trim().toUpperCase()
            : 'PRÉPARATION DU VOYAGE';

    return Semantics(
      label: '${branding.displayName}. ${branding.signature}',
      value: '${(loadingProgress * 100).round()} %',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final mobile = size.width <= 760;
          final safeBottom = MediaQuery.paddingOf(context).bottom;
          return ColoredBox(
            color: background,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CustomPaint(
                  key: const ValueKey<String>('startup-splash-atmosphere'),
                  painter: _SplashBackdropPainter(
                    time: time,
                    ambientTime: ambientTime,
                    held: !reducedMotion &&
                        loadingProgress < 1 &&
                        progress >= kPlayerSplashHoldProgress,
                    background: background,
                  ),
                ),
                Center(
                  child: _SplashLogoStage(
                    viewport: size,
                    mobile: mobile,
                    time: time,
                    ambientTime: ambientTime,
                    held: !reducedMotion &&
                        loadingProgress < 1 &&
                        progress >= kPlayerSplashHoldProgress,
                    branding: branding,
                    logo: logo,
                    wordmark: wordmark,
                    primary: primary,
                    secondary: secondary,
                    reducedMotion: reducedMotion,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mobile
                      ? math.max(size.height * .09, safeBottom)
                      : size.height * .085,
                  child: Center(
                    child: _SplashLoadingZone(
                      width: mobile
                          ? size.width * .76
                          : math.min(size.width * .42, 470),
                      opacity: reducedMotion ? 1 : _loadingState(time).opacity,
                      translateY:
                          reducedMotion ? 0 : _loadingState(time).translateY,
                      label: label,
                      progress: loadingProgress,
                      primary: primary,
                      secondary: secondary,
                      viewportWidth: size.width,
                    ),
                  ),
                ),
                Positioned(
                  right: size.width * (mobile ? .05 : .03),
                  bottom: math.max(size.height * .03, mobile ? safeBottom : 0),
                  child: Opacity(
                    opacity: reducedMotion ? 0 : _skipOpacity(time),
                    child: _SplashSkipHint(viewportWidth: size.width),
                  ),
                ),
                IgnorePointer(
                  child: ColoredBox(
                    key: const ValueKey<String>('startup-splash-curtain'),
                    color: Colors.black.withValues(
                      alpha: reducedMotion ? 0 : _curtainOpacity(time),
                    ),
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

class _SplashLogoStage extends StatelessWidget {
  const _SplashLogoStage({
    required this.viewport,
    required this.mobile,
    required this.time,
    required this.ambientTime,
    required this.held,
    required this.branding,
    required this.logo,
    required this.wordmark,
    required this.primary,
    required this.secondary,
    required this.reducedMotion,
  });

  final Size viewport;
  final bool mobile;
  final double time;
  final double ambientTime;
  final bool held;
  final RuntimeHostSplashBranding branding;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final Color primary;
  final Color secondary;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final double width =
        mobile ? viewport.width * .88 : math.min(viewport.width * .48, 560.0);
    final double height =
        mobile ? viewport.height * .54 : math.min(viewport.height * .6, 500.0);
    final markSize = mobile
        ? (viewport.width * .34).clamp(110.0, 150.0)
        : (viewport.width * .11).clamp(104.0, 178.0);
    final wordmarkSize = mobile
        ? (viewport.width * .044).clamp(14.0, 18.0)
        : (viewport.width * .0135).clamp(15.0, 22.0);
    final signatureSize = (viewport.width * .0062).clamp(8.0, 10.0);
    final markState = reducedMotion ? _MarkState.staticState : _markState(time);
    final nameState = reducedMotion ? _NameState.staticState : _nameState(time);
    final signatureState = reducedMotion
        ? _VerticalRevealState.staticState
        : _signatureState(time);
    final name = _PaintedText(
      text: branding.displayName,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFF8F3E9),
        fontFamily: 'PokeMapSplashMarcellus',
        package: 'map_player_ui',
        fontSize: wordmarkSize,
        fontWeight: FontWeight.w400,
        height: 1.2,
        letterSpacing: nameState.letterSpacingEm * wordmarkSize,
        shadows: const <Shadow>[
          Shadow(color: Color(0x80EAD5FF), blurRadius: 28),
        ],
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              key: const ValueKey<String>('startup-splash-halos'),
              painter: _SplashLogoAtmospherePainter(
                viewportWidth: viewport.width,
                time: time,
                ambientTime: ambientTime,
                held: held,
                primary: primary,
                secondary: secondary,
                reducedMotion: reducedMotion,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Opacity(
                  key: const ValueKey<String>('startup-splash-mark'),
                  opacity: markState.opacity,
                  child: Transform.translate(
                    offset: Offset(0, markState.translateY),
                    child: Transform.scale(
                      scale: markState.scale,
                      child: _SplashMark(
                        logo: logo,
                        size: markSize,
                        brightness: markState.brightness,
                        saturation: markState.saturation,
                        blur: markState.blur,
                        shadowBlur: markState.shadowBlur,
                        shadowColor: markState.shadowColor,
                        fallbackColor: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Opacity(
                  key: const ValueKey<String>('startup-splash-wordmark'),
                  opacity: nameState.opacity,
                  child: Transform.translate(
                    offset: Offset(0, nameState.translateY),
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                        sigmaX: nameState.blur,
                        sigmaY: nameState.blur,
                      ),
                      child: wordmark == null
                          ? name
                          : Image(
                              key: const ValueKey<String>(
                                'startup-splash-wordmark-image',
                              ),
                              image: wordmark!,
                              width: wordmarkSize * 13,
                              height: wordmarkSize * 1.2,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              excludeFromSemantics: true,
                              errorBuilder: (_, __, ___) => name,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Opacity(
                  key: const ValueKey<String>('startup-splash-signature'),
                  opacity: signatureState.opacity,
                  child: Transform.translate(
                    offset: Offset(0, signatureState.translateY),
                    child: _PaintedText(
                      text: branding.signature.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFECE5DC).withValues(alpha: .54),
                        fontFamily: 'PokeMapSplashDMSans',
                        package: 'map_player_ui',
                        fontSize: signatureSize,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                        letterSpacing: signatureSize * .32,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark({
    required this.logo,
    required this.size,
    required this.brightness,
    required this.saturation,
    required this.blur,
    required this.shadowBlur,
    required this.shadowColor,
    required this.fallbackColor,
  });

  final ImageProvider? logo;
  final double size;
  final double brightness;
  final double saturation;
  final double blur;
  final double shadowBlur;
  final Color shadowColor;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final fallback = _FallbackMark(color: fallbackColor, size: size);
    if (logo == null) return fallback;
    final image = SizedBox.square(
      dimension: size,
      child: Image(
        image: logo!,
        fit: BoxFit.contain,
        semanticLabel: null,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
    final filtered = ColorFiltered(
      colorFilter: ColorFilter.matrix(
        _brightnessSaturationMatrix(brightness, saturation),
      ),
      child: blur <= .01
          ? image
          : ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: image,
            ),
    );
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: shadowBlur,
            sigmaY: shadowBlur,
          ),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(shadowColor, BlendMode.srcIn),
            child: SizedBox.square(
              dimension: size,
              child: Image(
                image: logo!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        filtered,
      ],
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey<String>('startup-splash-fallback-mark'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          'A',
          style: TextStyle(
            color: color,
            fontFamily: 'PokeMapSplashMarcellus',
            package: 'map_player_ui',
            fontSize: size * .54,
          ),
        ),
      );
}

class _SplashLoadingZone extends StatelessWidget {
  const _SplashLoadingZone({
    required this.width,
    required this.opacity,
    required this.translateY,
    required this.label,
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.viewportWidth,
  });

  final double width;
  final double opacity;
  final double translateY;
  final String label;
  final double progress;
  final Color primary;
  final Color secondary;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final fontSize = (viewportWidth * .0058).clamp(8.0, 10.0);
    final style = TextStyle(
      color: const Color(0xFFF2EBE2).withValues(alpha: .56),
      fontFamily: 'PokeMapSplashDMSans',
      package: 'map_player_ui',
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: fontSize * .24,
    );
    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _PaintedText(
                    key:
                        const ValueKey<String>('startup-splash-progress-label'),
                    text: label,
                    style: style,
                  ),
                  _PaintedText(
                    key:
                        const ValueKey<String>('startup-splash-progress-value'),
                    text:
                        '${(progress * 100).round().toString().padLeft(3, '0')}%',
                    style: style,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              SizedBox(
                key: const ValueKey<String>('startup-splash-progress'),
                width: width,
                height: 3,
                child: CustomPaint(
                  painter: _SplashProgressPainter(
                    progress: progress,
                    primary: primary,
                    secondary: secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashSkipHint extends StatelessWidget {
  const _SplashSkipHint({required this.viewportWidth});

  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final fontSize = (viewportWidth * .0058).clamp(8.0, 10.0);
    final style = TextStyle(
      color: const Color(0xFFEFEAE4).withValues(alpha: .36),
      fontFamily: 'PokeMapSplashDMSans',
      package: 'map_player_ui',
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      letterSpacing: fontSize * .12,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _PaintedText(
            text: 'ENTER',
            style: style.copyWith(fontSize: fontSize * .88),
          ),
        ),
        const SizedBox(width: 8),
        _PaintedText(text: 'PASSER', style: style),
      ],
    );
  }
}

class _PaintedText extends StatelessWidget {
  const _PaintedText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: direction,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    return Semantics(
      label: text,
      child: SizedBox(
        width: painter.width,
        height: painter.height,
        child: CustomPaint(
          painter: _TextCanvasPainter(
            text: text,
            style: style,
            textAlign: textAlign,
            textDirection: direction,
          ),
        ),
      ),
    );
  }
}

class _TextCanvasPainter extends CustomPainter {
  const _TextCanvasPainter({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.textDirection,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )
      ..layout(maxWidth: size.width)
      ..paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(_TextCanvasPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.textDirection != textDirection;
}

class _SplashProgressPainter extends CustomPainter {
  const _SplashProgressPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = Colors.white.withValues(alpha: .1));
    canvas.drawRect(
      rect.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: .025),
    );
    if (progress <= 0) return;
    final fill = Rect.fromLTWH(0, 0, size.width * progress, size.height);
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          <Color>[secondary, primary, const Color(0xFFFFF7E6)],
          <double>[0, .72, 1],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * progress - 8, size.height / 2),
        width: 26,
        height: 12,
      ),
      Paint()
        ..color = const Color(0xCCFFF6DE)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary;
}

class _SplashBackdropPainter extends CustomPainter {
  const _SplashBackdropPainter({
    required this.time,
    required this.ambientTime,
    required this.held,
    required this.background,
  });

  final double time;
  final double ambientTime;
  final bool held;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final center = Offset(size.width * .5, size.height * .44);
    final farthestX = math.max(center.dx, size.width - center.dx);
    final farthestY = math.max(center.dy, size.height - center.dy);
    final radius = math.sqrt(farthestX * farthestX + farthestY * farthestY);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          const <Color>[
            Color(0xAD2A2E55),
            Color(0xEB090C1B),
            Color(0xFF02040A),
          ],
          const <double>[0, .3, .72],
        ),
    );
    _paintField(canvas, size);
    _paintAurora(
      canvas,
      size,
      first: true,
      state: _auroraOneState(time, ambientTime, held),
    );
    _paintAurora(
      canvas,
      size,
      first: false,
      state: _auroraTwoState(time, ambientTime, held),
    );
    _paintStars(canvas, size);
    _paintLightPass(canvas, size);
  }

  void _paintField(Canvas canvas, Size size) {
    final p = (ambientTime / 10000).clamp(0.0, 1.0);
    final translate = Offset(
      ui.lerpDouble(-size.width * .02, size.width * .02, p)!,
      ui.lerpDouble(-size.height * .02, size.height * .02, p)!,
    );
    final scale = ui.lerpDouble(.96, 1.06, p)!;
    final angle = ui.lerpDouble(0, 7 * math.pi / 180, p)!;
    canvas.save();
    canvas.translate(
        size.width / 2 + translate.dx, size.height / 2 + translate.dy);
    canvas.rotate(angle);
    canvas.scale(scale);
    canvas.translate(-size.width / 2, -size.height / 2);
    final ringCenter = size.center(Offset.zero);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .0055);
    for (double radius = 49; radius < maxRadius; radius += 50) {
      canvas.drawCircle(ringCenter, radius, paint);
    }
    canvas.restore();
  }

  void _paintAurora(
    Canvas canvas,
    Size size, {
    required bool first,
    required _AuroraState state,
  }) {
    if (state.opacity <= 0) return;
    final rect = first
        ? Rect.fromLTWH(-size.width * .2, size.height * .2, size.width * .78,
            size.height * .42)
        : Rect.fromLTWH(size.width * .47, size.height * .46, size.width * .78,
            size.height * .42);
    canvas.save();
    final center = rect.center +
        Offset(state.translateX * rect.width, state.translateY * rect.height);
    canvas.translate(center.dx, center.dy);
    canvas.rotate((first ? -18 : 16) * math.pi / 180);
    canvas.scale(state.scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    final colors = first
        ? <Color>[
            Colors.transparent,
            const Color(0xFF6761D2).withValues(alpha: .18 * state.opacity),
            const Color(0xFFECB4FF).withValues(alpha: .11 * state.opacity),
            Colors.transparent,
          ]
        : <Color>[
            Colors.transparent,
            const Color(0xFFE7A668).withValues(alpha: .12 * state.opacity),
            const Color(0xFF9F5ECD).withValues(alpha: .16 * state.opacity),
            Colors.transparent,
          ];
    canvas.drawOval(
      rect,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          colors,
          const <double>[0, 1 / 3, 2 / 3, 1],
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 72),
    );
    canvas.restore();
  }

  void _paintStars(Canvas canvas, Size size) {
    const stars = <_Star>[
      _Star(.17, .27, 800),
      _Star(.28, .69, 1700),
      _Star(.39, .19, 2400),
      _Star(.63, .24, 1100),
      _Star(.76, .63, 2900),
      _Star(.84, .36, 1900),
      _Star(.11, .76, 3300),
      _Star(.69, .78, 400),
    ];
    for (final star in stars) {
      final state = _starState(ambientTime, star.delay);
      if (state.opacity <= 0) continue;
      final center = Offset(size.width * star.x, size.height * star.y);
      canvas.drawCircle(
        center,
        1,
        Paint()
          ..color =
              const Color(0xFFFFECC0).withValues(alpha: .9 * state.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        center,
        math.max(1, state.scale),
        Paint()
          ..color = const Color(0xFFFFF7DC).withValues(alpha: state.opacity),
      );
    }
  }

  void _paintLightPass(Canvas canvas, Size size) {
    final local = _localProgress(time, 2550, 2200);
    if (local <= 0 || local >= 1) return;
    final eased = const Cubic(.25, .6, .3, 1).transform(local);
    final opacity = local <= .3
        ? ui.lerpDouble(0, 1, local / .3)!
        : ui.lerpDouble(1, 0, (local - .3) / .7)!;
    final translate = ui.lerpDouble(-1.1, 1.1, eased)! * size.width;
    canvas.save();
    canvas.translate(translate, 0);
    canvas.rotate(22 * math.pi / 180);
    final rect = Rect.fromLTWH(
        -size.width, -size.height, size.width * 3, size.height * 3);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          <Color>[
            Colors.transparent,
            const Color(0xFFE9D1FF).withValues(alpha: .05 * opacity),
            Colors.transparent,
          ],
          const <double>[.2, .48, .7],
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashBackdropPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.ambientTime != ambientTime ||
      oldDelegate.held != held ||
      oldDelegate.background != background;
}

class _SplashLogoAtmospherePainter extends CustomPainter {
  const _SplashLogoAtmospherePainter({
    required this.viewportWidth,
    required this.time,
    required this.ambientTime,
    required this.held,
    required this.primary,
    required this.secondary,
    required this.reducedMotion,
  });

  final double viewportWidth;
  final double time;
  final double ambientTime;
  final bool held;
  final Color primary;
  final Color secondary;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = reducedMotion
        ? _GlowState.staticState
        : _glowState(time, ambientTime, held);
    final glowWidth = math.min(viewportWidth * .32, 410);
    final glowCenter = Offset(size.width / 2, size.height * .43);
    if (glow.opacity > 0) {
      final radius = glowWidth * glow.scale / 2;
      canvas.drawCircle(
        glowCenter,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(
            glowCenter,
            radius,
            <Color>[
              const Color(0xFFEED3FF).withValues(alpha: .28 * glow.opacity),
              const Color(0xFF7554B7).withValues(alpha: .12 * glow.opacity),
              Colors.transparent,
            ],
            const <double>[0, .44, .72],
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
      );
    }
    if (reducedMotion) return;
    _paintOrbit(
      canvas,
      center: Offset(size.width / 2, size.height * .48),
      state: _wideOrbitState(time, ambientTime, held),
      width: math.min(viewportWidth * .36, 440),
      aspectRatio: 1.9,
      color: const Color(0xFFF1DEFF).withValues(alpha: .16),
    );
    _paintOrbit(
      canvas,
      center: Offset(size.width / 2, size.height * .48),
      state: _tightOrbitState(time, ambientTime, held),
      width: math.min(viewportWidth * .25, 305),
      aspectRatio: 1,
      color: const Color(0xFFEEC598).withValues(alpha: .13),
    );
  }

  void _paintOrbit(
    Canvas canvas, {
    required Offset center,
    required _OrbitState state,
    required double width,
    required double aspectRatio,
    required Color color,
  }) {
    if (state.opacity <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(state.angle);
    canvas.scale(state.scale);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: width,
        height: width / aspectRatio,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: color.a * state.opacity),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashLogoAtmospherePainter oldDelegate) =>
      oldDelegate.viewportWidth != viewportWidth ||
      oldDelegate.time != time ||
      oldDelegate.ambientTime != ambientTime ||
      oldDelegate.held != held ||
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.reducedMotion != reducedMotion;
}

class _MarkState {
  const _MarkState({
    required this.opacity,
    required this.translateY,
    required this.scale,
    required this.brightness,
    required this.saturation,
    required this.blur,
    required this.shadowBlur,
    required this.shadowColor,
  });

  static const staticState = _MarkState(
    opacity: 1,
    translateY: 0,
    scale: 1,
    brightness: 1,
    saturation: .9,
    blur: 0,
    shadowBlur: 30,
    shadowColor: Color(0x57E1B4FF),
  );

  final double opacity;
  final double translateY;
  final double scale;
  final double brightness;
  final double saturation;
  final double blur;
  final double shadowBlur;
  final Color shadowColor;
}

class _NameState {
  const _NameState({
    required this.opacity,
    required this.letterSpacingEm,
    required this.blur,
    required this.translateY,
  });

  static const staticState = _NameState(
    opacity: 1,
    letterSpacingEm: .62,
    blur: 0,
    translateY: 0,
  );

  final double opacity;
  final double letterSpacingEm;
  final double blur;
  final double translateY;
}

class _VerticalRevealState {
  const _VerticalRevealState({required this.opacity, required this.translateY});

  static const staticState = _VerticalRevealState(opacity: 1, translateY: 0);

  final double opacity;
  final double translateY;
}

class _GlowState {
  const _GlowState({required this.opacity, required this.scale});

  static const staticState = _GlowState(opacity: .58, scale: 1);

  final double opacity;
  final double scale;
}

class _OrbitState {
  const _OrbitState({
    required this.opacity,
    required this.angle,
    required this.scale,
  });

  final double opacity;
  final double angle;
  final double scale;
}

class _AuroraState {
  const _AuroraState({
    required this.opacity,
    required this.translateX,
    required this.translateY,
    required this.scale,
  });

  final double opacity;
  final double translateX;
  final double translateY;
  final double scale;
}

class _Star {
  const _Star(this.x, this.y, this.delay);

  final double x;
  final double y;
  final double delay;
}

class _StarState {
  const _StarState({required this.opacity, required this.scale});

  final double opacity;
  final double scale;
}

_MarkState _markState(double time) {
  final p = _localProgress(time, 350, 7200);
  const stops = <double>[0, .12, .3, .52, .83, 1];
  const curve = Cubic(.2, .8, .2, 1);
  final shadow = _colorKeyframes(
    p,
    stops,
    const <Color>[
      Color(0xB3F0D8FF),
      Color(0xB3F0D8FF),
      Color(0x8CE1B4FF),
      Color(0x57E1B4FF),
      Color(0x57E1B4FF),
      Color(0x33E1B4FF),
    ],
    curve,
  );
  return _MarkState(
    opacity: _keyframes(p, stops, const <double>[0, 0, 1, 1, 1, 0], curve),
    translateY:
        _keyframes(p, stops, const <double>[14, 14, 0, 0, 0, -4], curve),
    scale:
        _keyframes(p, stops, const <double>[.76, .76, 1.05, 1, 1, .97], curve),
    brightness:
        _keyframes(p, stops, const <double>[2.2, 2.2, 1.38, 1, 1, .72], curve),
    saturation:
        _keyframes(p, stops, const <double>[.25, .25, .7, .9, .9, .6], curve),
    blur: _keyframes(p, stops, const <double>[8, 8, 0, 0, 0, 1], curve),
    shadowBlur:
        _keyframes(p, stops, const <double>[42, 42, 36, 30, 30, 22], curve),
    shadowColor: shadow,
  );
}

_NameState _nameState(double time) {
  final p = _localProgress(time, 350, 7200);
  const stops = <double>[0, .27, .47, .84, 1];
  const curve = Cubic(.2, .75, .25, 1);
  return _NameState(
    opacity: _keyframes(p, stops, const <double>[0, 0, 1, 1, 0], curve),
    letterSpacingEm: _keyframes(
      p,
      stops,
      const <double>[1.05, 1.05, .62, .62, .68],
      curve,
    ),
    blur: _keyframes(p, stops, const <double>[5, 5, 0, 0, 1], curve),
    translateY: _keyframes(p, stops, const <double>[8, 8, 0, 0, -2], curve),
  );
}

_VerticalRevealState _signatureState(double time) {
  final p = _localProgress(time, 400, 7200);
  const stops = <double>[0, .44, .58, .84, 1];
  const curve = Cubic(.25, .1, .25, 1);
  return _VerticalRevealState(
    opacity: _keyframes(p, stops, const <double>[0, 0, 1, 1, 0], curve),
    translateY: _keyframes(p, stops, const <double>[6, 6, 0, 0, -2], curve),
  );
}

_VerticalRevealState _loadingState(double time) {
  final p = _localProgress(time, 0, 7200);
  const stops = <double>[0, .18, .28, .88, 1];
  const curve = Cubic(.25, .1, .25, 1);
  return _VerticalRevealState(
    opacity: _keyframes(p, stops, const <double>[0, 0, 1, 1, 0], curve),
    translateY: _keyframes(p, stops, const <double>[8, 8, 0, 0, -2], curve),
  );
}

_GlowState _glowState(double time, double ambientTime, bool held) {
  final p = _localProgress(time, 0, 7200);
  const stops = <double>[0, .05, .22, .48, .82, 1];
  const curve = Cubic(.2, .7, .25, 1);
  var opacity =
      _keyframes(p, stops, const <double>[0, 0, .45, 1, .76, 0], curve);
  var scale =
      _keyframes(p, stops, const <double>[.35, .35, .74, 1, 1.08, 1.24], curve);
  if (held) {
    final wave = math.sin(ambientTime / 10000 * math.pi * 2);
    opacity = (opacity + wave * .04).clamp(0, 1);
    scale += wave * .015;
  }
  return _GlowState(opacity: opacity, scale: scale);
}

_OrbitState _wideOrbitState(double time, double ambientTime, bool held) {
  final p = _localProgress(time, 450, 6400);
  const stops = <double>[0, .1, .35, .82, 1];
  const curve = Cubic(.2, .75, .25, 1);
  var angle = _keyframes(
        p,
        const <double>[0, .1, 1],
        const <double>[-25, -25, 155],
        curve,
      ) *
      math.pi /
      180;
  if (held) angle += math.sin(ambientTime / 10000 * math.pi * 2) * .025;
  return _OrbitState(
    opacity: _keyframes(p, stops, const <double>[0, 0, .9, .24, 0], curve),
    angle: angle,
    scale: _keyframes(
      p,
      const <double>[0, .1, 1],
      const <double>[.45, .45, 1.45],
      curve,
    ),
  );
}

_OrbitState _tightOrbitState(double time, double ambientTime, bool held) {
  final p = _localProgress(time, 700, 6100);
  const stops = <double>[0, .14, .42, .84, 1];
  const curve = Cubic(.2, .75, .25, 1);
  var angle = _keyframes(
        p,
        const <double>[0, .14, 1],
        const <double>[45, 45, -135],
        curve,
      ) *
      math.pi /
      180;
  if (held) angle -= math.sin(ambientTime / 10000 * math.pi * 2) * .022;
  return _OrbitState(
    opacity: _keyframes(p, stops, const <double>[0, 0, .7, .18, 0], curve),
    angle: angle,
    scale: _keyframes(
      p,
      const <double>[0, .14, 1],
      const <double>[.38, .38, 1.68],
      curve,
    ),
  );
}

_AuroraState _auroraOneState(double time, double ambientTime, bool held) {
  final p = _localProgress(time, 0, 7200);
  const stops = <double>[0, .08, .42, .82, 1];
  const curve = Cubic(.42, 0, .58, 1);
  final wave = held ? math.sin(ambientTime / 10000 * math.pi * 2) : 0;
  return _AuroraState(
    opacity: _keyframes(p, stops, const <double>[0, 0, .7, .36, 0], curve),
    translateX: _keyframes(
          p,
          const <double>[0, .08, 1],
          const <double>[-.18, -.18, .34],
          curve,
        ) +
        wave * .012,
    translateY: _keyframes(
      p,
      const <double>[0, .08, 1],
      const <double>[.1, .1, -.06],
      curve,
    ),
    scale: _keyframes(
      p,
      const <double>[0, .08, 1],
      const <double>[.8, .8, 1.18],
      curve,
    ),
  );
}

_AuroraState _auroraTwoState(double time, double ambientTime, bool held) {
  final p = _localProgress(time, 200, 7200);
  const stops = <double>[0, .16, .52, .86, 1];
  const curve = Cubic(.42, 0, .58, 1);
  final wave = held ? math.sin(ambientTime / 10000 * math.pi * 2) : 0;
  return _AuroraState(
    opacity: _keyframes(p, stops, const <double>[0, 0, .7, .3, 0], curve),
    translateX: _keyframes(
          p,
          const <double>[0, .16, 1],
          const <double>[.2, .2, -.28],
          curve,
        ) -
        wave * .01,
    translateY: _keyframes(
      p,
      const <double>[0, .16, 1],
      const <double>[.1, .1, -.1],
      curve,
    ),
    scale: _keyframes(
      p,
      const <double>[0, .16, 1],
      const <double>[.86, .86, 1.14],
      curve,
    ),
  );
}

_StarState _starState(double ambientTime, double delay) {
  if (ambientTime < delay) return const _StarState(opacity: 0, scale: .3);
  final p = ((ambientTime - delay) % 3600) / 3600;
  const stops = <double>[0, .48, .58, 1];
  const curve = Cubic(.42, 0, .58, 1);
  return _StarState(
    opacity: _keyframes(p, stops, const <double>[0, .75, .32, 0], curve),
    scale: _keyframes(p, stops, const <double>[.3, 1, .72, .3], curve),
  );
}

double _skipOpacity(double time) {
  final p = _localProgress(time, 4800, 1000);
  return const Cubic(.25, .1, .25, 1).transform(p);
}

double _curtainOpacity(double time) {
  final p = (time / 7450).clamp(0.0, 1.0);
  if (p <= .88) return 0;
  if (p >= .98) return 1;
  return (p - .88) / .1;
}

double _localProgress(double time, double delay, double duration) =>
    ((time - delay) / duration).clamp(0.0, 1.0);

double _keyframes(
  double progress,
  List<double> stops,
  List<double> values,
  Curve curve,
) {
  if (progress <= stops.first) return values.first;
  for (var index = 1; index < stops.length; index++) {
    if (progress <= stops[index]) {
      final local =
          (progress - stops[index - 1]) / (stops[index] - stops[index - 1]);
      return ui.lerpDouble(
        values[index - 1],
        values[index],
        curve.transform(local.clamp(0.0, 1.0)),
      )!;
    }
  }
  return values.last;
}

Color _colorKeyframes(
  double progress,
  List<double> stops,
  List<Color> values,
  Curve curve,
) {
  if (progress <= stops.first) return values.first;
  for (var index = 1; index < stops.length; index++) {
    if (progress <= stops[index]) {
      final local =
          (progress - stops[index - 1]) / (stops[index] - stops[index - 1]);
      return Color.lerp(
        values[index - 1],
        values[index],
        curve.transform(local.clamp(0.0, 1.0)),
      )!;
    }
  }
  return values.last;
}

List<double> _brightnessSaturationMatrix(double brightness, double saturation) {
  final inverse = 1 - saturation;
  const red = .213;
  const green = .715;
  const blue = .072;
  return <double>[
    (red * inverse + saturation) * brightness,
    green * inverse * brightness,
    blue * inverse * brightness,
    0,
    0,
    red * inverse * brightness,
    (green * inverse + saturation) * brightness,
    blue * inverse * brightness,
    0,
    0,
    red * inverse * brightness,
    green * inverse * brightness,
    (blue * inverse + saturation) * brightness,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

Color _opaqueHex(String source, int fallback) {
  final value = source.trim().replaceFirst('#', '');
  if (value.length != 6) return Color(fallback);
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? Color(fallback) : Color(0xFF000000 | parsed);
}
