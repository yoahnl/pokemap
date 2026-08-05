import 'package:flutter/material.dart';

import 'avelune_theme.dart';

class AveluneConsole extends StatelessWidget {
  const AveluneConsole({
    super.key,
    this.insertionProgress = 0,
  });

  final double insertionProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 3.08,
        child: RepaintBoundary(
          child: PhysicalShape(
            key: const ValueKey<String>('avelune-console-silhouette'),
            clipper: const _AveluneConsoleSilhouetteClipper(),
            color: colors.outline,
            elevation: 10,
            shadowColor: colors.background,
            child: Padding(
              padding: const EdgeInsets.all(1.2),
              child: ClipPath(
                clipper: const _AveluneConsoleSilhouetteClipper(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color.lerp(
                                  colors.surfaceElevated,
                                  colors.textPrimary,
                                  0.12,
                                )!,
                                colors.surfaceElevated,
                                colors.surface,
                                Color.lerp(
                                  colors.surface,
                                  colors.background,
                                  0.7,
                                )!,
                              ],
                              stops: const <double>[0, 0.2, 0.62, 1],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: kAveluneConsoleTextureOpacity,
                            child: Image.asset(
                              kAveluneMatteAbsTextureAssetPath,
                              key: const ValueKey<String>(
                                'avelune-console-material-texture',
                              ),
                              fit: BoxFit.cover,
                              color: colors.surfaceElevated,
                              colorBlendMode: BlendMode.modulate,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * 0.08,
                          right: width * 0.08,
                          top: height * 0.035,
                          height: height * 0.26,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                                bottom: Radius.circular(5),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  colors.textPrimary.withValues(alpha: 0.13),
                                  colors.textPrimary.withValues(alpha: 0.025),
                                  colors.background.withValues(alpha: 0.16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * 0.025,
                          right: width * 0.025,
                          top: height * 0.37,
                          height: 1,
                          child: ColoredBox(
                            color: colors.background.withValues(alpha: 0.82),
                          ),
                        ),
                        Positioned(
                          key: const ValueKey<String>(
                            'avelune-console-faceplate',
                          ),
                          left: width * 0.075,
                          right: width * 0.075,
                          top: height * 0.39,
                          bottom: height * 0.065,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: colors.background.withValues(alpha: 0.9),
                                width: 1.4,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  colors.background.withValues(alpha: 0.76),
                                  colors.surface.withValues(alpha: 0.58),
                                  colors.background.withValues(alpha: 0.9),
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: colors.background.withValues(
                                    alpha: 0.86,
                                  ),
                                  blurRadius: 9,
                                  offset: const Offset(0, -3),
                                ),
                                BoxShadow(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.055,
                                  ),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: kAveluneConsoleWearOpacity,
                            child: Image.asset(
                              kAveluneAgedAbsWearAssetPath,
                              key: const ValueKey<String>(
                                'avelune-console-wear-texture',
                              ),
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        Positioned(
                          key: const ValueKey<String>(
                            'avelune-console-insertion-well',
                          ),
                          top: height * 0.11,
                          left: width * 0.295,
                          right: width * 0.295,
                          height: height * 0.105,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                colors.background,
                                colors.primary,
                                insertionProgress * 0.44,
                              ),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: colors.background,
                                width: 1.5,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: colors.background.withValues(
                                    alpha: 0.96,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 3),
                                ),
                                if (insertionProgress > 0)
                                  BoxShadow(
                                    color: colors.glow.withValues(
                                      alpha: insertionProgress * 0.76,
                                    ),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          key: const ValueKey<String>(
                            'avelune-console-slot-lip',
                          ),
                          top: height * 0.19,
                          left: width * 0.275,
                          right: width * 0.275,
                          height: height * 0.095,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  colors.textPrimary.withValues(alpha: 0.16),
                                  colors.surfaceElevated,
                                  colors.surface,
                                  colors.background,
                                ],
                              ),
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.86),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: colors.background.withValues(
                                    alpha: 0.96,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * 0.19,
                          top: height * 0.14,
                          bottom: height * 0.08,
                          child: Container(
                            width: 1,
                            color: colors.outline.withValues(alpha: 0.48),
                          ),
                        ),
                        Positioned(
                          right: width * 0.19,
                          top: height * 0.14,
                          bottom: height * 0.08,
                          child: Container(
                            width: 1,
                            color: colors.background.withValues(alpha: 0.8),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: height * 0.43,
                          child: Center(
                            child: Text(
                              'AVELUNE',
                              style: TextStyle(
                                color: colors.textPrimary.withValues(
                                  alpha: 0.46,
                                ),
                                fontSize: height * 0.16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.3,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: colors.textPrimary.withValues(
                                      alpha: 0.15,
                                    ),
                                    offset: const Offset(0, -1),
                                  ),
                                  Shadow(
                                    color: colors.background.withValues(
                                      alpha: 0.96,
                                    ),
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * 0.13,
                          top: height * 0.29,
                          child: _ConsoleFastener(
                            colors: colors,
                            size: height * 0.055,
                          ),
                        ),
                        Positioned(
                          right: width * 0.13,
                          top: height * 0.29,
                          child: _ConsoleFastener(
                            colors: colors,
                            size: height * 0.055,
                          ),
                        ),
                        Positioned(
                          left: width * 0.37,
                          right: width * 0.37,
                          top: height * 0.62,
                          height: height * 0.1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.background.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.58),
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: colors.background,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: height * 0.27,
                          right: height * 0.27,
                          bottom: height * 0.125,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              _ConsolePort(
                                colors: colors,
                                size: height * 0.255,
                              ),
                              _ConsolePort(
                                colors: colors,
                                size: height * 0.255,
                              ),
                              const Spacer(),
                              _ConsolePort(
                                colors: colors,
                                size: height * 0.255,
                              ),
                              _ConsolePort(
                                colors: colors,
                                size: height * 0.255,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: height * 0.115,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color.lerp(
                                      colors.primaryBright,
                                      colors.textPrimary,
                                      0.16,
                                    )!,
                                    colors.primary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: colors.glow.withValues(alpha: 0.82),
                                    blurRadius: 13,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                width: height * 0.24,
                                height: height * 0.045,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: width * 0.045,
                          right: width * 0.045,
                          bottom: height * 0.025,
                          height: height * 0.075,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  colors.textPrimary.withValues(alpha: 0.055),
                                  colors.background.withValues(alpha: 0.74),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AveluneConsoleSilhouetteClipper extends CustomClipper<Path> {
  const _AveluneConsoleSilhouetteClipper();

  @override
  Path getClip(Size size) {
    final width = size.width;
    final height = size.height;
    return Path()
      ..moveTo(0, height * 0.38)
      ..cubicTo(
        0,
        height * 0.28,
        width * 0.03,
        height * 0.23,
        width * 0.075,
        height * 0.19,
      )
      ..lineTo(width * 0.19, height * 0.08)
      ..quadraticBezierTo(
        width * 0.225,
        height * 0.02,
        width * 0.29,
        height * 0.02,
      )
      ..lineTo(width * 0.71, height * 0.02)
      ..quadraticBezierTo(
        width * 0.775,
        height * 0.02,
        width * 0.8,
        height * 0.065,
      )
      ..lineTo(width * 0.925, height * 0.19)
      ..cubicTo(
        width * 0.97,
        height * 0.23,
        width,
        height * 0.28,
        width,
        height * 0.38,
      )
      ..lineTo(width, height * 0.86)
      ..quadraticBezierTo(width, height * 0.98, width * 0.92, height * 0.98)
      ..lineTo(width * 0.08, height * 0.98)
      ..quadraticBezierTo(0, height * 0.98, 0, height * 0.86)
      ..close();
  }

  @override
  bool shouldReclip(_AveluneConsoleSilhouetteClipper oldClipper) => false;
}

class AveluneConsoleDock extends StatelessWidget {
  const AveluneConsoleDock({
    super.key,
    required this.consoleWidth,
    this.insertionProgress = 0,
  });

  final double consoleWidth;
  final double insertionProgress;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Column(
      children: <Widget>[
        SizedBox(
          width: consoleWidth,
          child: AveluneConsole(insertionProgress: insertionProgress),
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

class _ConsolePort extends StatelessWidget {
  const _ConsolePort({required this.colors, required this.size});

  final AveluneColors colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        margin: EdgeInsets.symmetric(horizontal: size * 0.08),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              colors.surfaceElevated,
              colors.background,
            ],
          ),
          border: Border.all(color: colors.outline, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: colors.background.withValues(alpha: 0.72),
              blurRadius: 3,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(
              3,
              (_) => Container(
                width: size * 0.06,
                height: size * 0.06,
                margin: EdgeInsets.symmetric(horizontal: size * 0.025),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.gold.withValues(alpha: 0.76),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ConsoleFastener extends StatelessWidget {
  const _ConsoleFastener({required this.colors, required this.size});

  final AveluneColors colors;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.background.withValues(alpha: 0.38),
          border: Border.all(
            color: colors.textPrimary.withValues(alpha: 0.13),
          ),
        ),
        child: Center(
          child: Transform.rotate(
            angle: 0.34,
            child: Container(
              width: size * 0.52,
              height: 0.8,
              color: colors.outline.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
}
