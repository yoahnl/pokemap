import 'package:avelune_render_host/avelune_render_host.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class SpatialGameSurface<T extends Game> extends StatelessWidget {
  const SpatialGameSurface({
    super.key,
    required this.game,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.autofocus = false,
    this.continuous = true,
  });
  final T game;
  final bool autofocus;
  final bool continuous;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext, Object) errorBuilder;

  @override
  Widget build(BuildContext context) => RenderSurfaceActivity(
    engine: _FlameSurfaceEngine(game),
    continuous: continuous,
    child: GameWidget<T>(
      game: game,
      autofocus: autofocus,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
    ),
  );
}

final class _FlameSurfaceEngine implements RenderSurfaceEngine {
  const _FlameSurfaceEngine(this.game);

  final Game game;

  @override
  bool get isAttached => game.isAttached;

  @override
  bool get isPaused => game.isPaused;

  @override
  void pause() => game.pauseEngine();

  @override
  void resume() => game.resumeEngine();

  @override
  void presentFrame() => game.stepEngine(stepTime: 0);

  @override
  bool operator ==(Object other) =>
      other is _FlameSurfaceEngine && identical(other.game, game);

  @override
  int get hashCode => identityHashCode(game);
}
