import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

import 'package:pokemap_hub/presentation/features/player/state/hub_title_presentation_loader.dart';

@immutable
final class HubIntroPlaybackSnapshot {
  const HubIntroPlaybackSnapshot({
    this.initialized = false,
    this.isBuffering = false,
    this.isCompleted = false,
    this.caption,
    this.errorDescription,
  });

  final bool initialized;
  final bool isBuffering;
  final bool isCompleted;
  final String? caption;
  final String? errorDescription;
}

abstract interface class HubIntroPlaybackDriver {
  ValueListenable<HubIntroPlaybackSnapshot> get snapshot;
  Widget get video;

  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> replay();
  Future<void> dispose();
}

typedef HubIntroPlaybackFactory = HubIntroPlaybackDriver Function(
  HubLoadedIntroVideo intro,
  double volume,
);

/// Plays one installed intro while retaining skip, lifecycle, and safe fallback.
class HubIntroVideoPlayer extends StatefulWidget {
  const HubIntroVideoPlayer({
    super.key,
    required this.intro,
    required this.reducedMotion,
    required this.volume,
    required this.onFinished,
    this.playbackFactory,
  });

  final HubLoadedIntroVideo intro;
  final bool reducedMotion;
  final double volume;
  final VoidCallback onFinished;
  final HubIntroPlaybackFactory? playbackFactory;

  @override
  State<HubIntroVideoPlayer> createState() => _HubIntroVideoPlayerState();
}

class _HubIntroVideoPlayerState extends State<HubIntroVideoPlayer>
    with WidgetsBindingObserver {
  late final RuntimeIntroSequenceController _sequence;
  HubIntroPlaybackDriver? _playback;
  HubIntroPlaybackSnapshot _snapshot = const HubIntroPlaybackSnapshot();
  bool _failureHandled = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sequence = RuntimeIntroSequenceController()
      ..start(
        hasVideo: true,
        hasPoster: widget.intro.poster != null,
        reducedMotion: widget.reducedMotion,
        reducedMotionBehavior: widget.intro.reducedMotionBehavior == 'skip'
            ? RuntimeIntroReducedMotionBehavior.skip
            : RuntimeIntroReducedMotionBehavior.poster,
        allowReplay: widget.intro.allowReplay,
      );
    if (_sequence.phase == RuntimeIntroPhase.playing) {
      _startPlayback();
    } else if (_sequence.phase == RuntimeIntroPhase.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  void _startPlayback() {
    final factory =
        widget.playbackFactory ?? _createInstalledIntroPlaybackDriver;
    final playback = factory(widget.intro, widget.volume.clamp(0.0, 1.0));
    _playback = playback;
    playback.snapshot.addListener(_handlePlaybackSnapshot);
    unawaited(_initializePlayback(playback));
  }

  Future<void> _initializePlayback(HubIntroPlaybackDriver playback) async {
    try {
      await playback.initialize();
      if (!mounted || !identical(_playback, playback) || _finished) return;
      await playback.play();
    } on Object catch (error) {
      if (!mounted || !identical(_playback, playback) || _finished) return;
      _handlePlaybackFailure(error.toString());
    }
  }

  void _handlePlaybackSnapshot() {
    final playback = _playback;
    if (playback == null || _finished) return;
    final snapshot = playback.snapshot.value;
    if (snapshot.errorDescription case final error?) {
      _handlePlaybackFailure(error);
      return;
    }
    _snapshot = snapshot;
    if (snapshot.isCompleted) {
      _sequence.playbackCompleted();
      _finish();
      return;
    }
    if (mounted) setState(() {});
  }

  void _handlePlaybackFailure(String reason) {
    if (_failureHandled || _finished) return;
    _failureHandled = true;
    _sequence.playbackFailed(reason);
    unawaited(_playback?.pause());
    if (_sequence.phase == RuntimeIntroPhase.completed) {
      _finish();
    } else if (mounted) {
      setState(() {});
    }
  }

  void _skip() {
    _sequence.skip();
    _finish();
  }

  void _continueFromPoster() {
    _sequence.continueFromPoster();
    _finish();
  }

  void _replay() {
    if (!_sequence.replay()) return;
    _failureHandled = false;
    _snapshot = const HubIntroPlaybackSnapshot(initialized: true);
    unawaited(_playback?.replay());
    if (mounted) setState(() {});
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    unawaited(_playback?.pause());
    widget.onFinished();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_finished) return;
    if (state == AppLifecycleState.resumed) {
      if (_sequence.phase == RuntimeIntroPhase.paused) {
        _sequence.resumeAfterLifecycle();
        unawaited(_playback?.play());
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _sequence.pauseForLifecycle();
      unawaited(_playback?.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_finished || _sequence.phase == RuntimeIntroPhase.completed) {
      return const SizedBox.expand();
    }
    if (_sequence.phase == RuntimeIntroPhase.poster) {
      final poster = widget.intro.poster;
      return PlayerIntroVideoSurface(
        media: poster == null
            ? null
            : Image(
                image: poster,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.expand(),
              ),
        isPoster: true,
        failureMessage: _sequence.failureReason,
        onSkip: _skip,
        onContinue: _continueFromPoster,
        onReplay: !widget.reducedMotion && _sequence.canReplay ? _replay : null,
      );
    }
    return PlayerIntroVideoSurface(
      media: _playback?.video,
      caption: _snapshot.caption,
      isBuffering: !_snapshot.initialized || _snapshot.isBuffering,
      onSkip: _skip,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final playback = _playback;
    _playback = null;
    if (playback != null) {
      playback.snapshot.removeListener(_handlePlaybackSnapshot);
      unawaited(playback.dispose());
    }
    super.dispose();
  }
}

HubIntroPlaybackDriver _createInstalledIntroPlaybackDriver(
  HubLoadedIntroVideo intro,
  double volume,
) =>
    _VideoPlayerIntroPlaybackDriver(
      videoPath: intro.videoPath,
      captionsPath: intro.captionsPath,
      volume: volume,
    );

final class _VideoPlayerIntroPlaybackDriver implements HubIntroPlaybackDriver {
  _VideoPlayerIntroPlaybackDriver({
    required String videoPath,
    required String? captionsPath,
    required this.volume,
  }) : _controller = VideoPlayerController.file(
          File(videoPath),
          closedCaptionFile: captionsPath == null
              ? null
              : File(captionsPath)
                  .readAsString()
                  .then<ClosedCaptionFile>(WebVTTCaptionFile.new),
        );

  final VideoPlayerController _controller;
  final double volume;
  final ValueNotifier<HubIntroPlaybackSnapshot> _snapshot =
      ValueNotifier<HubIntroPlaybackSnapshot>(
    const HubIntroPlaybackSnapshot(),
  );

  @override
  ValueListenable<HubIntroPlaybackSnapshot> get snapshot => _snapshot;

  @override
  Widget get video => VideoPlayer(_controller);

  @override
  Future<void> initialize() async {
    _controller.addListener(_synchronize);
    await _controller.initialize();
    await _controller.setLooping(false);
    await _controller.setVolume(volume);
    _synchronize();
  }

  void _synchronize() {
    final value = _controller.value;
    _snapshot.value = HubIntroPlaybackSnapshot(
      initialized: value.isInitialized,
      isBuffering: value.isBuffering,
      isCompleted: value.isCompleted,
      caption: value.caption.text,
      errorDescription: value.errorDescription,
    );
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> replay() async {
    await _controller.seekTo(Duration.zero);
    await _controller.play();
  }

  @override
  Future<void> dispose() async {
    _controller.removeListener(_synchronize);
    await _controller.dispose();
    _snapshot.dispose();
  }
}
