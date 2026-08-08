import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  final source = PlayerIntroVideoSource(
    videoUri: Uri.parse('file:///intro.mp4'),
  );

  testWidgets('poster phase does not allocate a video decoder', (tester) async {
    var factoryCalls = 0;
    var continued = false;

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPlayer(
          source: source,
          phase: RuntimeIntroPhase.poster,
          poster: const _PosterProvider(),
          driverFactory: (_) {
            factoryCalls++;
            return _FakeDriver();
          },
          onPlaybackCompleted: () {},
          onPlaybackFailed: (_) {},
          onSkip: () {},
          onContinue: () => continued = true,
          onReplay: () {},
        ),
      ),
    );

    expect(factoryCalls, 0);
    await tester.tap(find.text('Continuer'));
    expect(continued, isTrue);
  });

  testWidgets('decoder failure is reported once and leaves a safe surface',
      (tester) async {
    final driver = _FakeDriver()..initializeError = StateError('decoder');
    final failures = <String>[];

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPlayer(
          source: source,
          phase: RuntimeIntroPhase.playing,
          driverFactory: (_) => driver,
          onPlaybackCompleted: () {},
          onPlaybackFailed: failures.add,
          onSkip: () {},
          onContinue: () {},
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();

    expect(failures, hasLength(1));
    expect(failures.single, 'Intro video playback failed.');
    expect(find.text('La vidéo ne peut pas être lue.'), findsOneWidget);
  });

  testWidgets('completion, buffering, captions and disposal are deterministic',
      (tester) async {
    final driver = _FakeDriver();
    var completions = 0;

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPlayer(
          source: source,
          phase: RuntimeIntroPhase.playing,
          driverFactory: (_) => driver,
          onPlaybackCompleted: () => completions++,
          onPlaybackFailed: (_) {},
          onSkip: () {},
          onContinue: () {},
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();

    driver.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      isBuffering: true,
      caption: 'Prochain arrêt : Hisui.',
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Prochain arrêt : Hisui.'), findsOneWidget);

    driver.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      isCompleted: true,
    );
    await tester.pump();
    driver.snapshot.value = const PlayerIntroPlaybackSnapshot(
      isInitialized: true,
      isCompleted: true,
    );
    await tester.pump();
    expect(completions, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(driver.disposeCalls, 1);
  });

  testWidgets('application lifecycle pauses and resumes active playback',
      (tester) async {
    final driver = _FakeDriver();

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoPlayer(
          source: source,
          phase: RuntimeIntroPhase.playing,
          driverFactory: (_) => driver,
          onPlaybackCompleted: () {},
          onPlaybackFailed: (_) {},
          onSkip: () {},
          onContinue: () {},
          onReplay: () {},
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

  testWidgets('replay after a decoder failure allocates a fresh driver',
      (tester) async {
    final failed = _FakeDriver()..initializeError = StateError('decoder');
    final retry = _FakeDriver();
    final drivers = <_FakeDriver>[failed, retry];
    var factoryCalls = 0;

    Widget player(RuntimeIntroPhase phase) => _app(
          PlayerIntroVideoPlayer(
            source: source,
            phase: phase,
            driverFactory: (_) => drivers[factoryCalls++],
            onPlaybackCompleted: () {},
            onPlaybackFailed: (_) {},
            onSkip: () {},
            onContinue: () {},
            onReplay: () {},
          ),
        );

    await tester.pumpWidget(player(RuntimeIntroPhase.playing));
    await tester.pump();
    await tester.pumpWidget(player(RuntimeIntroPhase.poster));
    await tester.pumpWidget(player(RuntimeIntroPhase.playing));
    await tester.pump();

    expect(factoryCalls, 2);
    expect(failed.disposeCalls, 1);
    expect(retry.playCalls, 1);
  });
}

class _FakeDriver implements PlayerIntroPlaybackDriver {
  final snapshot = ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );
  Object? initializeError;
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => snapshot;

  @override
  Widget buildVideo() => const ColoredBox(
        key: ValueKey<String>('fake-video'),
        color: Colors.black,
      );

  @override
  Future<void> initialize() async {
    if (initializeError case final error?) throw error;
    snapshot.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    snapshot.dispose();
  }
}

class _PosterProvider extends ImageProvider<_PosterProvider> {
  const _PosterProvider();

  @override
  ImageStreamCompleter loadImage(
    _PosterProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(StateError('poster deliberately unavailable')),
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
      home: child,
    );
