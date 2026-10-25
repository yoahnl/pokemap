import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_game_surface.dart';

void main() {
  testWidgets('a static preview settles and repaints only when requested', (
    tester,
  ) async {
    final game = _CountingGame();
    final refresh = ValueNotifier(0);
    final continuous = ValueNotifier(false);
    addTearDown(refresh.dispose);
    addTearDown(continuous.dispose);
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: Listenable.merge([refresh, continuous]),
        builder: (_, _) => Directionality(
          textDirection: TextDirection.ltr,
          child: SpatialGameSurface(
            game: game,
            continuous: continuous.value,
            loadingBuilder: (_) => const SizedBox(),
            errorBuilder: (_, _) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.runAsync(game.ready);
    await tester.pump();
    await tester.pump();
    expect(game.isPaused, isTrue);
    final updates = game.updates;
    await tester.pump(const Duration(seconds: 1));
    expect(game.updates, updates);
    refresh.value++;
    await tester.pump();
    await tester.pump();
    expect(game.updates, greaterThan(updates));
    expect(game.isPaused, isTrue);
    continuous.value = true;
    await tester.pump();
    expect(game.isPaused, isFalse);
    final animated = game.updates;
    await tester.pump(const Duration(milliseconds: 50));
    expect(game.updates, greaterThan(animated));
    continuous.value = false;
    await tester.pump();
    await tester.pump();
    expect(game.isPaused, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

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

class _CountingGame extends FlameGame {
  int updates = 0;

  @override
  void update(double dt) {
    updates++;
    super.update(dt);
  }
}
