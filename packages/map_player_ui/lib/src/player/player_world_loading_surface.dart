import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

class PlayerWorldLoadingSurface extends StatelessWidget {
  const PlayerWorldLoadingSurface({
    super.key,
    required this.gameTitle,
    required this.stage,
    this.progress,
    this.onCancel,
    this.reducedMotion = false,
  });

  final String gameTitle;
  final String stage;
  final double? progress;
  final VoidCallback? onCancel;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final title = gameTitle.trim().isEmpty ? 'Avelune' : gameTitle;
    final fraction = progress?.clamp(0.0, 1.0);
    final percentage = fraction == null ? null : '${(fraction * 100).round()}%';
    return Semantics(
      container: true,
      label: '$title. $stage',
      value: percentage,
      child: ColoredBox(
        key: const ValueKey<String>('runtime-player-loading-art'),
        color: const Color(0xFF080A15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final orbSize = math.min(
              math.min(size.width * .52, size.height * .27),
              220.0,
            );
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const RepaintBoundary(
                  child: CustomPaint(painter: _WorldLoadingBackdrop()),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: math.max(26, math.min(size.width * .08, 88)),
                      vertical: 26,
                    ),
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'A V E L U N E',
                          style: TextStyle(
                            color: Color(0xFFC9C7D7),
                            fontFamily: 'PokeMapSplashDMSans',
                            package: 'map_player_ui',
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 2.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        SizedBox.square(
                          dimension: orbSize,
                          child: const RepaintBoundary(
                            child: CustomPaint(painter: _WorldLoadingEclipse()),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFF5F1F4),
                            fontFamily: 'PokeMapSplashMarcellus',
                            package: 'map_player_ui',
                            fontSize: math.min(size.width * .075, 34),
                            height: 1.18,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.playerL10n.loading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF9696AA),
                            fontFamily: 'PokeMapSplashDMSans',
                            package: 'map_player_ui',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.8,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      stage,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFB9B9C9),
                                        fontFamily: 'PokeMapSplashDMSans',
                                        package: 'map_player_ui',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.1,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                  if (percentage != null)
                                    Text(
                                      percentage,
                                      style: const TextStyle(
                                        color: Color(0xFFE6E0EB),
                                        fontFamily: 'PokeMapSplashDMSans',
                                        package: 'map_player_ui',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: fraction ?? 0),
                                duration: reducedMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => SizedBox(
                                  height: 3,
                                  child: CustomPaint(
                                    key: const ValueKey<String>(
                                      'runtime-player-loading-progress',
                                    ),
                                    painter: _WorldLoadingProgress(
                                      fraction == null ? null : value,
                                    ),
                                    size: const Size(double.infinity, 3),
                                  ),
                                ),
                              ),
                              if (onCancel != null) ...<Widget>[
                                const SizedBox(height: 25),
                                Semantics(
                                  button: true,
                                  label: context.playerL10n.cancel,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onCancel,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        context.playerL10n.cancel,
                                        style: const TextStyle(
                                          color: Color(0xFF9B99AC),
                                          fontFamily: 'PokeMapSplashDMSans',
                                          package: 'map_player_ui',
                                          fontSize: 12,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
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
    );
  }
}

class _WorldLoadingBackdrop extends CustomPainter {
  const _WorldLoadingBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF080A15),
            Color(0xFF15182B),
            Color(0xFF090B16),
          ],
          stops: <double>[0, .48, 1],
        ).createShader(bounds),
    );
    final glowCenter = Offset(size.width * .5, size.height * .45);
    final glowRadius = math.max(size.width * .62, size.height * .41);
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0x243A427D),
            Color(0x0A534B84),
            Color(0x003D4276),
          ],
          stops: <double>[0, .52, 1],
        ).createShader(Rect.fromCircle(
          center: glowCenter,
          radius: glowRadius,
        )),
    );
    final stars = <Offset>[
      Offset(size.width * .14, size.height * .22),
      Offset(size.width * .78, size.height * .18),
      Offset(size.width * .85, size.height * .63),
      Offset(size.width * .2, size.height * .73),
    ];
    for (final star in stars) {
      canvas.drawCircle(star, 1, Paint()..color = const Color(0x66D6D5E5));
    }
  }

  @override
  bool shouldRepaint(covariant _WorldLoadingBackdrop oldDelegate) => false;
}

class _WorldLoadingEclipse extends CustomPainter {
  const _WorldLoadingEclipse();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * .31;
    final haloBounds = Rect.fromCircle(center: center, radius: radius * 1.6);
    canvas.drawCircle(
      center,
      radius * 1.6,
      Paint()
        ..shader = const RadialGradient(
          colors: <Color>[
            Color(0x356B689B),
            Color(0x124F5B89),
            Color(0x00505B8A),
          ],
          stops: <double>[0, .55, 1],
        ).createShader(haloBounds),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.38);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.8,
        height: radius * .9,
      ),
      Paint()
        ..color = const Color(0x4B898BAF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
    final discBounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF393654),
            Color(0xFF171A31),
            Color(0xFF0D1123),
          ],
        ).createShader(discBounds),
    );
    canvas.drawArc(
      discBounds,
      -math.pi * .8,
      math.pi * 1.35,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: <Color>[
            Color(0xFFB8C8E5),
            Color(0xFFE6CAD7),
            Color(0xFF8C91C6),
            Color(0xFFB8C8E5),
          ],
        ).createShader(discBounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    final glint = Offset(
      center.dx + radius * .94,
      center.dy - radius * .79,
    );
    canvas.drawCircle(glint, 2.2, Paint()..color = const Color(0xFFEDE7F1));
    canvas.drawLine(
      glint.translate(-6, 0),
      glint.translate(6, 0),
      Paint()
        ..color = const Color(0x99EDE7F1)
        ..strokeWidth = .7,
    );
    canvas.drawLine(
      glint.translate(0, -6),
      glint.translate(0, 6),
      Paint()
        ..color = const Color(0x99EDE7F1)
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(covariant _WorldLoadingEclipse oldDelegate) => false;
}

class _WorldLoadingProgress extends CustomPainter {
  const _WorldLoadingProgress(this.progress);

  final double? progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(2)),
      Paint()..color = const Color(0xFF47485D),
    );
    if (progress case final value? when value > 0) {
      final filled = Rect.fromLTWH(0, 0, size.width * value, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(filled, const Radius.circular(2)),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              Color(0xFF8B84BC),
              Color(0xFFC9BDD6),
              Color(0xFFDFCFD5),
            ],
          ).createShader(filled),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldLoadingProgress oldDelegate) =>
      oldDelegate.progress != progress;
}
