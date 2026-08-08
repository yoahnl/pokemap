import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
final class PlayerIntroVideoSource {
  const PlayerIntroVideoSource({
    required this.videoUri,
    this.captionsLoader,
    this.volume = 1,
  }) : assert(volume >= 0 && volume <= 1);

  final Uri videoUri;
  final Future<String> Function()? captionsLoader;
  final double volume;
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
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

typedef PlayerIntroPlaybackFactory = PlayerIntroPlaybackDriver Function(
  PlayerIntroVideoSource source,
);
