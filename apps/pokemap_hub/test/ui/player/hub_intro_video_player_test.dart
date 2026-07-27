import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/src/ui/player/hub_intro_video_player.dart';
import 'package:pokemap_hub/src/ui/player/hub_title_presentation_loader.dart';

void main() {
  testWidgets('reduced motion uses the poster without creating a decoder',
      (tester) async {
    var factoryCalls = 0;
    var finished = false;
    final intro = HubLoadedIntroVideo(
      videoPath: '/installed/video.mp4',
      poster: const _TestImageProvider(),
      captionsPath: null,
      reducedMotionBehavior: 'poster',
      allowReplay: true,
    );

    await tester.pumpWidget(
      _app(
        HubIntroVideoPlayer(
          intro: intro,
          reducedMotion: true,
          volume: 1,
          playbackFactory: (_, __) {
            factoryCalls++;
            return _FakePlayback();
          },
          onFinished: () => finished = true,
        ),
      ),
    );

    expect(factoryCalls, 0);
    expect(find.text('Continuer'), findsOneWidget);

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('decoder failure falls back to poster and then title',
      (tester) async {
    final playback = _FakePlayback();
    var finished = false;

    await tester.pumpWidget(
      _app(
        HubIntroVideoPlayer(
          intro: HubLoadedIntroVideo(
            videoPath: '/installed/video.mp4',
            poster: const _TestImageProvider(),
            captionsPath: '/installed/captions.vtt',
            reducedMotionBehavior: 'poster',
            allowReplay: true,
          ),
          reducedMotion: false,
          volume: .5,
          playbackFactory: (_, volume) {
            expect(volume, .5);
            return playback;
          },
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pump();

    playback.emit(
      const HubIntroPlaybackSnapshot(
        initialized: false,
        errorDescription: 'decoder unavailable',
      ),
    );
    await tester.pump();

    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);
    expect(finished, isFalse);

    await tester.tap(find.text('Continuer'));
    await tester.pump();
    expect(finished, isTrue);
  });

  testWidgets('completion and skip both release the intro', (tester) async {
    final playback = _FakePlayback();
    var finishCount = 0;

    await tester.pumpWidget(
      _app(
        HubIntroVideoPlayer(
          intro: const HubLoadedIntroVideo(
            videoPath: '/installed/video.mp4',
            poster: null,
            captionsPath: null,
            reducedMotionBehavior: 'skip',
            allowReplay: false,
          ),
          reducedMotion: false,
          volume: 1,
          playbackFactory: (_, __) => playback,
          onFinished: () => finishCount++,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Passer'), findsOneWidget);

    playback.emit(
      const HubIntroPlaybackSnapshot(
        initialized: true,
        isCompleted: true,
      ),
    );
    await tester.pump();
    expect(finishCount, 1);

    playback.emit(
      const HubIntroPlaybackSnapshot(
        initialized: true,
        isCompleted: true,
      ),
    );
    await tester.pump();
    expect(finishCount, 1);
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: child),
    );

final class _FakePlayback implements HubIntroPlaybackDriver {
  final ValueNotifier<HubIntroPlaybackSnapshot> _snapshot = ValueNotifier(
    const HubIntroPlaybackSnapshot(),
  );

  @override
  ValueListenable<HubIntroPlaybackSnapshot> get snapshot => _snapshot;

  @override
  Widget get video => const SizedBox(
        key: ValueKey<String>('fake-intro-video'),
      );

  @override
  Future<void> initialize() async {
    emit(const HubIntroPlaybackSnapshot(initialized: true));
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> replay() async {}

  @override
  Future<void> dispose() async {
    _snapshot.dispose();
  }

  void emit(HubIntroPlaybackSnapshot value) => _snapshot.value = value;
}

final class _TestImageProvider extends ImageProvider<_TestImageProvider> {
  const _TestImageProvider();

  @override
  Future<_TestImageProvider> obtainKey(
          ImageConfiguration configuration) async =>
      this;

  @override
  ImageStreamCompleter loadImage(
    _TestImageProvider key,
    ImageDecoderCallback decode,
  ) =>
      OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
