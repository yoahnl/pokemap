import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Imperative bridge used only for the ordered intro-to-title audio handoff.
///
/// Navigation remains runtime-owned: this controller can silence the concrete
/// decoder, but it cannot advance or mutate the startup state machine.
final class PlayerIntroVideoPlayerController {
  Future<void> Function()? _stopHandler;

  Future<void> stopPlayback() => _stopHandler?.call() ?? Future<void>.value();

  void attach(Future<void> Function() stopHandler) {
    _stopHandler = stopHandler;
  }

  void detach(Future<void> Function() stopHandler) {
    if (_stopHandler == stopHandler) _stopHandler = null;
  }
}

@immutable
final class PlayerIntroVideoSource {
  const PlayerIntroVideoSource({
    required this.videoUri,
    this.captionsLoader,
    this.volume = 1,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    this.focalX = .5,
    this.focalY = .5,
  })  : assert(volume >= 0 && volume <= 1),
        assert(aspectRatio > 0),
        assert(focalX >= 0 && focalX <= 1),
        assert(focalY >= 0 && focalY <= 1);

  final Uri videoUri;
  final Future<String> Function()? captionsLoader;
  final double volume;
  final bool looping;
  final double aspectRatio;
  final double focalX;
  final double focalY;

  Alignment get focalAlignment => Alignment(focalX * 2 - 1, focalY * 2 - 1);
}

@immutable
final class PlayerIntroPlaybackSnapshot {
  const PlayerIntroPlaybackSnapshot({
    this.isInitialized = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.caption,
    this.errorDescription,
  });

  final bool isInitialized;
  final bool isBuffering;
  final bool isCompleted;
  final String? caption;
  final String? errorDescription;
}

abstract interface class PlayerIntroPlaybackDriver {
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots;

  Widget buildVideo();
  Future<void> initialize();
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

typedef PlayerIntroPlaybackFactory = PlayerIntroPlaybackDriver Function(
  PlayerIntroVideoSource source,
);
