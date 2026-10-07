import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class SpatialGameSurface<T extends Game> extends StatelessWidget {
  const SpatialGameSurface({
    super.key,
    required this.game,
    required this.loadingBuilder,
    required this.errorBuilder,
  });
  final T game;
  final Widget Function(BuildContext) loadingBuilder;
  final Widget Function(BuildContext, Object) errorBuilder;
  @override
  Widget build(BuildContext context) => GameWidget<T>(
    game: game,
    autofocus: false,
    loadingBuilder: loadingBuilder,
    errorBuilder: errorBuilder,
  );
}
