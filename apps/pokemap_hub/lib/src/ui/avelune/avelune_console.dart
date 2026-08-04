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
        aspectRatio: 3.25,
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.outline),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color.lerp(
                    colors.surfaceElevated,
                    colors.textPrimary,
                    0.08,
                  )!,
                  colors.surfaceElevated,
                  colors.surface,
                  Color.lerp(colors.surface, colors.background, 0.58)!,
                ],
                stops: const <double>[0, 0.18, 0.62, 1],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.background.withValues(alpha: 0.9),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.all(height * 0.045),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: colors.textPrimary.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: height * 0.24,
                      right: height * 0.24,
                      top: height * 0.035,
                      height: height * 0.16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: <Color>[
                              colors.textPrimary.withValues(alpha: 0.08),
                              colors.textPrimary.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: height * 0.12,
                      left: constraints.maxWidth * 0.25,
                      right: constraints.maxWidth * 0.25,
                      height: height * 0.1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            colors.background,
                            colors.primary,
                            insertionProgress * 0.48,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.outline),
                          boxShadow: insertionProgress == 0
                              ? const <BoxShadow>[]
                              : <BoxShadow>[
                                  BoxShadow(
                                    color: colors.glow.withValues(
                                      alpha: insertionProgress * 0.7,
                                    ),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.16,
                      top: height * 0.12,
                      bottom: height * 0.1,
                      child: Container(
                        width: 1,
                        color: colors.outline.withValues(alpha: 0.48),
                      ),
                    ),
                    Positioned(
                      right: constraints.maxWidth * 0.16,
                      top: height * 0.12,
                      bottom: height * 0.1,
                      child: Container(
                        width: 1,
                        color: colors.background.withValues(alpha: 0.66),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: height * 0.44,
                      child: Center(
                        child: Text(
                          'AVELUNE',
                          style: TextStyle(
                            color: colors.textPrimary.withValues(alpha: 0.42),
                            fontSize: height * 0.18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.35,
                      right: constraints.maxWidth * 0.35,
                      top: height * 0.64,
                      height: height * 0.11,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.background.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: colors.outline.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: height * 0.28,
                      right: height * 0.28,
                      bottom: height * 0.14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          _ConsolePort(colors: colors, size: height * 0.27),
                          _ConsolePort(colors: colors, size: height * 0.27),
                          const Spacer(),
                          _ConsolePort(colors: colors, size: height * 0.27),
                          _ConsolePort(colors: colors, size: height * 0.27),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: height * 0.13,
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
                                color: colors.glow.withValues(alpha: 0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: height * 0.23,
                            height: height * 0.045,
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
    );
  }
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
          height: 13,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            border: Border(
              top: BorderSide(
                color: colors.textPrimary.withValues(alpha: 0.1),
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color.lerp(colors.woodHighlight, colors.textPrimary, 0.08)!,
                colors.woodHighlight,
                colors.wood,
                Color.lerp(colors.wood, colors.background, 0.34)!,
              ],
              stops: const <double>[0, 0.16, 0.7, 1],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.woodHighlight.withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
