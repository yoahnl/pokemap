import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/pokemap_player_theme.dart';
import 'player_world_map_loading_emblem.dart';

part 'player_world_map_loading_painters.dart';

class PlayerWorldMapLoadingScene extends StatefulWidget {
  const PlayerWorldMapLoadingScene({
    super.key,
    required this.progress,
    required this.reducedMotion,
    required this.detailsBuilder,
    this.logo,
  });

  final double? progress;
  final bool reducedMotion;
  final Widget Function(bool compact) detailsBuilder;
  final ImageProvider? logo;

  @override
  State<PlayerWorldMapLoadingScene> createState() =>
      _PlayerWorldMapLoadingSceneState();
}

class _PlayerWorldMapLoadingSceneState extends State<PlayerWorldMapLoadingScene>
    with SingleTickerProviderStateMixin {
  late final _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(PlayerWorldMapLoadingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.reducedMotion || !TickerMode.valuesOf(context).enabled) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highContrast =
        MediaQuery.highContrastOf(context) ||
        (Theme.of(context).extension<PokeMapPlayerColors>()?.highContrast ??
            false);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-.45, -.4),
          radius: 1.15,
          colors: [Color(0xff1a303c), Color(0xff0a121e)],
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final landscape = width >= 500 && width >= height * 1.1;
            final compact = landscape && height < 320;
            final gap = compact ? 24.0 : 40.0;
            final mapWidth = math.min(
              422.0,
              landscape
                  ? math.min(width * (compact ? .46 : .54), height * 1.48)
                  : width,
            );
            final detailsWidth = math.min(
              320.0,
              landscape ? width - mapWidth - gap : width,
            );
            return Center(
              child: SingleChildScrollView(
                child: Flex(
                  direction: landscape ? Axis.horizontal : Axis.vertical,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      key: const ValueKey('player-world-loading-map'),
                      width: mapWidth,
                      height: mapWidth / 1.48,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(18),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const RepaintBoundary(
                              child: CustomPaint(painter: _ChartPainter()),
                            ),
                            RepaintBoundary(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: widget.progress ?? 0),
                                duration:
                                    widget.reducedMotion || widget.progress == 1
                                    ? Duration.zero
                                    : const Duration(milliseconds: 420),
                                curve: Curves.easeOutCubic,
                                builder: (context, fraction, _) => CustomPaint(
                                  painter: _RoutePainter(_ambient, fraction),
                                ),
                              ),
                            ),
                            if (widget.logo case final logo?)
                              PositionedDirectional(
                                start: 8,
                                top: 8,
                                child: PlayerWorldMapLoadingEmblem(
                                  logo: logo,
                                  ambient: _ambient,
                                  reducedMotion: widget.reducedMotion,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: landscape ? gap : 0,
                      height: landscape ? 0 : 28,
                    ),
                    SizedBox(
                      width: detailsWidth,
                      child: Theme(
                        data: PokeMapPlayerTheme.dark(
                          highContrast: highContrast,
                          reducedMotion: widget.reducedMotion,
                        ),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ProgressIndicatorTheme(
                            data: const ProgressIndicatorThemeData(
                              color: _routeLight,
                              linearTrackColor: Color(0xff2b4750),
                            ),
                            child: widget.detailsBuilder(compact),
                          ),
                        ),
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
