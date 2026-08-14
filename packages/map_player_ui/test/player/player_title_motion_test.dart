import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('reduced motion never allocates a title video decoder', (
    tester,
  ) async {
    var factoryCalls = 0;

    await tester.pumpWidget(
      _app(
        PlayerTitleMotion(
          source: _source('title.mp4'),
          reducedMotion: true,
          driverFactory: (_) {
            factoryCalls += 1;
            return _PlaybackDriver();
          },
        ),
      ),
    );

    expect(factoryCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('player-title-motion-video')),
      findsNothing,
    );
  });

  testWidgets('a missing video keeps the deterministic poster fallback', (
    tester,
  ) async {
    var factoryCalls = 0;

    await tester.pumpWidget(
      _app(
        PlayerTitleMotion(
          source: null,
          poster: const _PosterProvider(),
          driverFactory: (_) {
            factoryCalls += 1;
            return _PlaybackDriver();
          },
        ),
      ),
    );

    expect(factoryCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('player-title-motion-poster')),
      findsOneWidget,
    );
  });

  testWidgets('the host releases the active title decoder deterministically', (
    tester,
  ) async {
    final controller = PlayerTitleMotionController();
    final driver = _PlaybackDriver();

    await tester.pumpWidget(
      _app(
        PlayerTitleMotion(
          controller: controller,
          source: _source('title.mp4'),
          driverFactory: (_) => driver,
        ),
      ),
    );
    await tester.pump();

    expect(driver.playCalls, 1);
    await controller.releasePlayback();
    await tester.pump();

    expect(driver.pauseCalls, 1);
    expect(driver.disposeCalls, 1);
    expect(
      find.byKey(const ValueKey<String>('player-title-motion-video')),
      findsNothing,
    );
  });

  testWidgets(
      'changing title media disposes the old decoder before replacing it', (
    tester,
  ) async {
    final disposal = Completer<void>();
    final first = _PlaybackDriver(disposalGate: disposal);
    final second = _PlaybackDriver();
    final allocated = <Uri>[];

    PlayerIntroPlaybackDriver createDriver(PlayerIntroVideoSource source) {
      allocated.add(source.videoUri);
      return allocated.length == 1 ? first : second;
    }

    Widget motion(String file) => _app(
          PlayerTitleMotion(
            source: _source(file),
            driverFactory: createDriver,
          ),
        );

    await tester.pumpWidget(motion('prompt.mp4'));
    await tester.pump();
    await tester.pumpWidget(motion('menu.mp4'));
    await tester.pump();

    expect(allocated, <Uri>[Uri.parse('file:///prompt.mp4')]);
    expect(first.disposeCalls, 1);

    disposal.complete();
    await tester.pump();
    await tester.pump();

    expect(allocated, <Uri>[
      Uri.parse('file:///prompt.mp4'),
      Uri.parse('file:///menu.mp4'),
    ]);
    expect(second.playCalls, 1);
  });

  testWidgets('application lifecycle pauses and resumes the title loop', (
    tester,
  ) async {
    final driver = _PlaybackDriver();
    await tester.pumpWidget(
      _app(
        PlayerTitleMotion(
          source: _source('title.mp4'),
          driverFactory: (_) => driver,
        ),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(driver.pauseCalls, 1);
    expect(driver.playCalls, 2);
  });
}

PlayerIntroVideoSource _source(String file) => PlayerIntroVideoSource(
      videoUri: Uri.parse('file:///$file'),
      looping: true,
    );

final class _PlaybackDriver implements PlayerIntroPlaybackDriver {
  _PlaybackDriver({this.disposalGate});

  final Completer<void>? disposalGate;
  final ValueNotifier<PlayerIntroPlaybackSnapshot> snapshot =
      ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => snapshot;

  @override
  Widget buildVideo() => const ColoredBox(color: Colors.black);

  @override
  Future<void> initialize() async {
    snapshot.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> play() async => playCalls += 1;

  @override
  Future<void> pause() async => pauseCalls += 1;

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await disposalGate?.future;
    snapshot.dispose();
  }
}

final class _PosterProvider extends ImageProvider<_PosterProvider> {
  const _PosterProvider();

  @override
  ImageStreamCompleter loadImage(
    _PosterProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('poster unavailable')),
      );

  @override
  Future<_PosterProvider> obtainKey(ImageConfiguration configuration) async =>
      this;
}

Widget _app(Widget child) => MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: SizedBox(width: 960, height: 540, child: child),
    );
