import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import 'player_intro_video_player.dart';
import 'player_intro_video_strings.dart';
import 'player_intro_video_surface.dart';
import 'player_startup_media.dart';

enum PlayerIntroPreviewReducedMotionBehavior { poster, skip }

final class PlayerIntroVideoPreviewController {
  Future<void> Function()? _releaseHandler;

  Future<void> releasePlayback() =>
      _releaseHandler?.call() ?? Future<void>.value();

  void _attach(Future<void> Function() releaseHandler) {
    final previous = _releaseHandler;
    if (previous != null && previous != releaseHandler) {
      unawaited(previous());
    }
    _releaseHandler = releaseHandler;
  }

  void _detach(Future<void> Function() releaseHandler) {
    if (_releaseHandler == releaseHandler) _releaseHandler = null;
  }
}

class PlayerIntroVideoPreview extends StatefulWidget {
  const PlayerIntroVideoPreview({
    super.key,
    required this.source,
    this.controller,
    this.poster,
    this.driverFactory,
    this.reducedMotion = false,
    this.reducedMotionBehavior = PlayerIntroPreviewReducedMotionBehavior.poster,
    this.allowReplay = false,
    this.onInteraction,
  });

  final PlayerIntroVideoSource? source;
  final PlayerIntroVideoPreviewController? controller;
  final ImageProvider? poster;
  final PlayerIntroPlaybackFactory? driverFactory;
  final bool reducedMotion;
  final PlayerIntroPreviewReducedMotionBehavior reducedMotionBehavior;
  final bool allowReplay;
  final VoidCallback? onInteraction;

  @override
  State<PlayerIntroVideoPreview> createState() =>
      _PlayerIntroVideoPreviewState();
}

class _PlayerIntroVideoPreviewState extends State<PlayerIntroVideoPreview> {
  final RuntimeIntroSequenceController _sequence =
      RuntimeIntroSequenceController();
  final PlayerIntroVideoPlayerController _playbackController =
      PlayerIntroVideoPlayerController();
  String? _failureMessage;
  bool _released = false;
  bool _skippedForReducedMotion = false;
  int _sessionRevision = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_releasePlayback);
    _restart();
  }

  @override
  void didUpdateWidget(PlayerIntroVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(_releasePlayback);
      widget.controller?._attach(_releasePlayback);
    }
    if (oldWidget.source?.videoUri != widget.source?.videoUri ||
        oldWidget.source?.aspectRatio != widget.source?.aspectRatio ||
        oldWidget.source?.focalX != widget.source?.focalX ||
        oldWidget.source?.focalY != widget.source?.focalY ||
        oldWidget.poster != widget.poster ||
        oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.reducedMotionBehavior != widget.reducedMotionBehavior ||
        oldWidget.allowReplay != widget.allowReplay) {
      _restart();
    }
  }

  void _restart() {
    _sessionRevision += 1;
    _failureMessage = null;
    _released = false;
    _skippedForReducedMotion = widget.source != null &&
        widget.reducedMotion &&
        widget.reducedMotionBehavior ==
            PlayerIntroPreviewReducedMotionBehavior.skip;
    _sequence.start(
      hasVideo: widget.source != null,
      hasPoster: widget.poster != null,
      reducedMotion: widget.reducedMotion,
      reducedMotionBehavior: widget.reducedMotionBehavior ==
              PlayerIntroPreviewReducedMotionBehavior.skip
          ? RuntimeIntroReducedMotionBehavior.skip
          : RuntimeIntroReducedMotionBehavior.poster,
      allowReplay: widget.allowReplay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    if (source == null || _sequence.phase == RuntimeIntroPhase.completed) {
      return _staticSurface(context);
    }
    return PlayerIntroVideoPlayer(
      key: ValueKey<String>(
        'player-intro-preview-${source.videoUri}-$_sessionRevision',
      ),
      source: source,
      controller: _playbackController,
      poster: widget.poster,
      phase: _sequence.phase,
      allowReplay: widget.allowReplay,
      driverFactory: widget.driverFactory,
      onPlaybackCompleted: _complete,
      onPlaybackFailed: _fail,
      onSkip: _skip,
      onContinue: _continue,
      onReplay: _replay,
    );
  }

  Widget _staticSurface(BuildContext context) {
    final canReplay = _sequence.canReplay && !_released;
    return PlayerIntroVideoSurface(
      key: const ValueKey<String>('player-intro-preview-static'),
      media: _poster(),
      isPoster: true,
      failureMessage: _failureMessage ??
          (_skippedForReducedMotion
              ? PlayerIntroVideoStrings.of(context).reducedMotionSkipped
              : null),
      onSkip: canReplay ? _replay : _noop,
      onReplay: canReplay ? _replay : null,
      onContinue:
          _sequence.phase == RuntimeIntroPhase.poster ? _continue : null,
    );
  }

  Widget? _poster() => widget.poster == null
      ? null
      : Image(
          key: const ValueKey<String>('player-intro-preview-poster'),
          image: widget.poster!,
          fit: BoxFit.cover,
          alignment: widget.source?.focalAlignment ?? Alignment.center,
          errorBuilder: (_, __, ___) => const SizedBox.expand(),
        );

  void _complete() {
    _sequence.playbackCompleted();
    widget.onInteraction?.call();
    if (mounted) setState(() {});
  }

  void _fail(String reason) {
    _failureMessage = reason;
    _sequence.playbackFailed(reason);
    widget.onInteraction?.call();
    if (mounted) setState(() {});
  }

  void _skip() {
    _sequence.skip();
    widget.onInteraction?.call();
    if (mounted) setState(() {});
  }

  void _continue() {
    _sequence.continueFromPoster();
    widget.onInteraction?.call();
    if (mounted) setState(() {});
  }

  void _replay() {
    if (!_sequence.replay()) return;
    _failureMessage = null;
    _released = false;
    _sessionRevision += 1;
    widget.onInteraction?.call();
    if (mounted) setState(() {});
  }

  Future<void> _releasePlayback() async {
    _released = true;
    await _playbackController.stopPlayback();
    _sequence.skip();
    if (mounted) setState(() {});
  }

  void _noop() {}

  @override
  void dispose() {
    widget.controller?._detach(_releasePlayback);
    unawaited(_playbackController.stopPlayback());
    super.dispose();
  }
}
