import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_game_surface.dart';

void main() {
  testWidgets('a hidden scene freezes without recreating its game', (
    tester,
  ) async {
    final game = FlameGame();
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (_, active, _) => TickerMode(
          enabled: active,
          child: SpatialGameSurface(
            game: game,
            loadingBuilder: (_) => const SizedBox(),
            errorBuilder: (_, _) => const SizedBox(),
          ),
        ),
      ),
    );
    expect(game.isPaused, isFalse);
    enabled.value = false;
    await tester.pump();
    expect(game.isPaused, isTrue);
    enabled.value = true;
    await tester.pump();
    expect(game.isPaused, isFalse);
    expect(
      tester
          .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget),
          )
          .game,
      same(game),
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('visibility preserves an existing explicit pause', (
    tester,
  ) async {
    final game = FlameGame()..pauseEngine();
    final enabled = ValueNotifier(false);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (_, active, _) => TickerMode(
          enabled: active,
          child: SpatialGameSurface(
            game: game,
            loadingBuilder: (_) => const SizedBox(),
            errorBuilder: (_, _) => const SizedBox(),
          ),
        ),
      ),
    );
    expect(game.isPaused, isTrue);
    enabled.value = true;
    await tester.pump();
    expect(game.isPaused, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('returning to the app keeps a hidden scene paused', (
    tester,
  ) async {
    final game = FlameGame();
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (_, active, _) => TickerMode(
          enabled: active,
          child: SpatialGameSurface(
            game: game,
            loadingBuilder: (_) => const SizedBox(),
            errorBuilder: (_, _) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(game.isAttached, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    expect(game.isPaused, isTrue);
    enabled.value = false;
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.isPaused, isTrue);
    enabled.value = true;
    await tester.pump();
    expect(game.isPaused, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
