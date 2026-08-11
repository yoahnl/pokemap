import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('preview plays captions, completes, replays and skips', (
    tester,
  ) async {
    final sources = <PlayerIntroVideoSource>[];
    final drivers = <_PlaybackDriver>[];
    PlayerIntroPlaybackDriver createDriver(PlayerIntroVideoSource source) {
      sources.add(source);
      final driver = _PlaybackDriver();
      drivers.add(driver);
      return driver;
    }

    final source = PlayerIntroVideoSource(
      videoUri: Uri.parse('file:///intro.mp4'),
      focalX: .2,
      focalY: .8,
    );

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPreview(
          source: source,
          poster: const _PosterProvider(),
          allowReplay: true,
          driverFactory: createDriver,
        ),
      ),
    );
    await tester.pump();

    drivers.single.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      caption: 'Le train entre en gare.',
    );
    await tester.pump();

    expect(find.text('Le train entre en gare.'), findsOneWidget);
    expect(sources.single, same(source));
    final fitted = tester.widget<FittedBox>(find.byType(FittedBox));
    expect(fitted.alignment, source.focalAlignment);

    drivers.single.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      isCompleted: true,
    );
    await tester.pump();
    expect(find.text('Rejouer'), findsOneWidget);
    expect(drivers.single.disposeCalls, 1);

    await tester.tap(find.text('Rejouer'));
    await tester.pump();
    expect(drivers, hasLength(2));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(drivers.last.disposeCalls, 1);
    expect(find.text('Rejouer'), findsOneWidget);
  });

  testWidgets('reduced-motion skip and missing video allocate no decoder', (
    tester,
  ) async {
    var factoryCalls = 0;
    PlayerIntroPlaybackDriver createDriver(PlayerIntroVideoSource source) {
      factoryCalls += 1;
      return _PlaybackDriver();
    }

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPreview(
          source: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///intro.mp4'),
          ),
          reducedMotion: true,
          reducedMotionBehavior: PlayerIntroPreviewReducedMotionBehavior.skip,
          driverFactory: createDriver,
        ),
      ),
    );
    expect(factoryCalls, 0);

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPreview(
          source: null,
          poster: const _PosterProvider(),
          driverFactory: createDriver,
        ),
      ),
    );
    expect(factoryCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('player-intro-preview-poster')),
      findsOneWidget,
    );
  });

  testWidgets('reduced-motion poster preserves the authored focal point', (
    tester,
  ) async {
    var factoryCalls = 0;
    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPreview(
          source: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///intro.mp4'),
            focalX: .2,
            focalY: .7,
          ),
          poster: const _PosterProvider(),
          reducedMotion: true,
          driverFactory: (_) {
            factoryCalls += 1;
            return _PlaybackDriver();
          },
        ),
      ),
    );

    expect(factoryCalls, 0);
    final alignment =
        tester.widget<Image>(find.byType(Image)).alignment as Alignment;
    expect(alignment.x, closeTo(-.6, .0001));
    expect(alignment.y, closeTo(.4, .0001));
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('preview controller releases active playback on scene change', (
    tester,
  ) async {
    final controller = PlayerIntroVideoPreviewController();
    final driver = _PlaybackDriver();
    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPreview(
          controller: controller,
          source: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///intro.mp4'),
          ),
          driverFactory: (_) => driver,
        ),
      ),
    );
    await tester.pump();

    await controller.releasePlayback();
    await tester.pump();

    expect(driver.pauseCalls, 1);
    expect(driver.disposeCalls, 1);
  });
}

final class _PlaybackDriver implements PlayerIntroPlaybackDriver {
  final snapshot = ValueNotifier<PlayerIntroPlaybackSnapshot>(
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
  Future<void> play() async => playCalls += 1;

  @override
  Future<void> pause() async => pauseCalls += 1;

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
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
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: SizedBox(width: 960, height: 540, child: child),
    );
