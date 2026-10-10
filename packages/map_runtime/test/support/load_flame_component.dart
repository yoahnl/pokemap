import 'package:flame/components.dart';
import 'package:flame/game.dart';

Future<void> loadFlameComponent(Component component) async {
  final game = FlameGame();
  game.onGameResize(
    component is PositionComponent ? component.size.clone() : Vector2(960, 540),
  );
  game.add(component);
  await component.loaded;
}
