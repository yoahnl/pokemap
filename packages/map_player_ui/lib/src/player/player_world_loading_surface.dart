import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../localization/player_localizations.dart';

class PlayerWorldLoadingSurface extends StatelessWidget {
  const PlayerWorldLoadingSurface({
    super.key,
    required this.gameTitle,
    required this.stage,
    this.logo,
    this.wordmark,
    this.progress,
    this.onCancel,
    this.reducedMotion = false,
  });

  final String gameTitle;
  final String stage;
  final ImageProvider? logo;
  final ImageProvider? wordmark;
  final double? progress;
  final VoidCallback? onCancel;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final title =
        gameTitle.trim().isEmpty ? context.playerL10n.loading : gameTitle;
    final fraction = progress?.clamp(0.0, 1.0);
    final percentage = fraction == null ? null : '${(fraction * 100).round()}%';
    return Semantics(
      container: true,
      label: '$title. $stage',
      value: percentage,
      child: DecoratedBox(
        key: const ValueKey<String>('runtime-player-loading-art'),
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.12),
            radius: 1.12,
            colors: <Color>[
              Color(0xFF191525),
              Color(0xFF0A0912),
              Color(0xFF030306),
            ],
            stops: <double>[0, .52, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: math.max(26, math.min(width * .08, 88)),
                  vertical: 26,
                ),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 3),
                    if (logo != null)
                      SizedBox.square(
                        dimension:
                            math.min(math.min(width * .3, height * .17), 124),
                        child: Image(
                          key: const ValueKey<String>(
                              'runtime-player-loading-logo'),
                          image: ResizeImage(logo!, width: 256),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    if (wordmark != null) ...<Widget>[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: math.min(width * .62, 260),
                        height: math.min(height * .11, 72),
                        child: Image(
                          key: const ValueKey<String>(
                              'runtime-player-loading-wordmark'),
                          image: ResizeImage(wordmark!, width: 640),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ],
                    if (logo != null || wordmark != null)
                      const SizedBox(height: 24),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF5F1F4),
                        fontFamily: 'PokeMapSplashMarcellus',
                        package: 'map_player_ui',
                        fontSize: math.min(width * .075, 34),
                        height: 1.18,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(flex: 4),
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
            );
          },
        ),
      ),
    );
  }
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
              Color(0xFFAA8EEC),
              Color(0xFF88D8F6),
              Color(0xFFF6D7B8),
            ],
          ).createShader(filled),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WorldLoadingProgress oldDelegate) =>
      oldDelegate.progress != progress;
}
