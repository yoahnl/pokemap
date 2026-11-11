import 'package:avelune_render_host/avelune_render_host.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Engine implements RenderSurfaceEngine {
  _Engine({this.isAttached = true});

  @override
  bool isAttached;

  @override
  bool isPaused = false;

  int pauses = 0;
  int resumes = 0;
  int frames = 0;

  @override
  void pause() {
    pauses++;
    isPaused = true;
  }

  @override
  void resume() {
    resumes++;
    isPaused = false;
  }

  @override
  void presentFrame() => frames++;
}

Widget _host(
  RenderSurfaceEngine engine, {
  bool continuous = true,
  bool visible = true,
}) => TickerMode(
  enabled: visible,
  child: RenderSurfaceActivity(
    engine: engine,
    continuous: continuous,
    child: const SizedBox(),
  ),
);

void main() {
  testWidgets('an on-demand surface settles and presents once per request', (
    tester,
  ) async {
    final engine = _Engine();
    await tester.pumpWidget(_host(engine, continuous: false));
    expect(engine.isPaused, isTrue);
    expect(engine.frames, 1);

    await tester.pump(const Duration(seconds: 1));
    expect(engine.frames, 1);

    await tester.pumpWidget(_host(engine, continuous: false));
    expect(engine.frames, 2);
    expect(engine.isPaused, isTrue);

    await tester.pumpWidget(_host(engine));
    expect(engine.isPaused, isFalse);
    final frames = engine.frames;

    await tester.pumpWidget(_host(engine, continuous: false));
    expect(engine.isPaused, isTrue);
    expect(engine.frames, frames + 1);
  });

  testWidgets('an on-demand surface waits for the engine to attach', (
    tester,
  ) async {
    final engine = _Engine(isAttached: false);
    await tester.pumpWidget(_host(engine, continuous: false));
    expect(engine.frames, 0);
    expect(engine.isPaused, isFalse);

    await tester.pump();
    expect(engine.frames, 0);

    engine.isAttached = true;
    tester.binding.scheduleFrame();
    await tester.pump();
    expect(engine.frames, 1);
    expect(engine.isPaused, isTrue);
  });

  testWidgets('a hidden surface pauses and resumes when visible again', (
    tester,
  ) async {
    final engine = _Engine();
    await tester.pumpWidget(_host(engine));
    expect(engine.isPaused, isFalse);

    await tester.pumpWidget(_host(engine, visible: false));
    expect(engine.isPaused, isTrue);
    expect(engine.frames, 0);

    await tester.pumpWidget(_host(engine));
    expect(engine.isPaused, isFalse);
    expect(engine.resumes, 1);
  });

  testWidgets('visibility never lifts an explicit pause', (tester) async {
    final engine = _Engine();
    await tester.pumpWidget(_host(engine));
    engine.pause();

    await tester.pumpWidget(_host(engine, visible: false));
    await tester.pumpWidget(_host(engine));

    expect(engine.isPaused, isTrue);
    expect(engine.resumes, 0);
  });

  testWidgets('returning to the app keeps a hidden surface paused', (
    tester,
  ) async {
    final engine = _Engine();
    await tester.pumpWidget(_host(engine, visible: false));
    expect(engine.isPaused, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();

    expect(engine.isPaused, isTrue);
    expect(engine.resumes, 0);
  });

  testWidgets('a replaced engine starts from a clean activity state', (
    tester,
  ) async {
    final first = _Engine();
    await tester.pumpWidget(_host(first, continuous: false));
    expect(first.isPaused, isTrue);

    final second = _Engine();
    await tester.pumpWidget(_host(second));

    expect(second.isPaused, isFalse);
    expect(second.resumes, 0);
    expect(first.isPaused, isTrue);
    expect(first.resumes, 0);
  });
}
