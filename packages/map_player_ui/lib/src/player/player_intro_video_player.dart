import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:video_player/video_player.dart';

import 'player_intro_video_controller.dart';
import 'player_intro_video_strings.dart';
import 'player_intro_video_surface.dart';
import 'player_startup_media.dart';

/// Generic intro playback widget controlled by the runtime startup state.
///
/// It reports media events but never advances the startup state by itself.
class PlayerIntroVideoPlayer extends StatefulWidget {
  const PlayerIntroVideoPlayer({
    super.key,
    required this.source,
    required this.phase,
    required this.onPlaybackCompleted,
    required this.onPlaybackFailed,
    required this.onSkip,
    required this.onContinue,
    required this.onReplay,
    this.controller,
    this.poster,
    this.driverFactory,
    this.audioMixer,
    this.allowReplay = false,
  });

  final PlayerIntroVideoSource source;
  final RuntimeIntroPhase phase;
  final PlayerIntroVideoPlayerController? controller;
  final ImageProvider? poster;
  final PlayerIntroPlaybackFactory? driverFactory;
  final RuntimeAudioMixer? audioMixer;
  final VoidCallback onPlaybackCompleted;
  final ValueChanged<String> onPlaybackFailed;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final VoidCallback onReplay;
  final bool allowReplay;

  @override
  State<PlayerIntroVideoPlayer> createState() => _PlayerIntroVideoPlayerState();
}

class _PlayerIntroVideoPlayerState extends State<PlayerIntroVideoPlayer>
    with WidgetsBindingObserver {
  PlayerIntroPlaybackDriver? _driver;
  PlayerIntroPlaybackSnapshot _snapshot = const PlayerIntroPlaybackSnapshot();
  String? _failureMessage;
  int _generation = 0;
  bool _completionReported = false;
  bool _failureReported = false;
  bool _stoppedByHost = false;
  final RuntimeAudioMixer _localAudioMixer = RuntimeAudioMixer();
  RuntimeAudioMixer? _registeredMixer;
  PlayerIntroPlaybackDriver? _registeredDriver;

  bool get _shouldPlay => widget.phase == RuntimeIntroPhase.playing;

  RuntimeAudioMixer get _audioMixer => widget.audioMixer ?? _localAudioMixer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?.attach(_stopPlaybackForHost);
    if (_shouldPlay) _startPlayback();
  }

  @override
  void didUpdateWidget(PlayerIntroVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.detach(_stopPlaybackForHost);
      widget.controller?.attach(_stopPlaybackForHost);
    }
    if (oldWidget.source.videoUri != widget.source.videoUri ||
        !identical(oldWidget.audioMixer, widget.audioMixer)) {
      _replaceDriver();
      return;
    }
    if (oldWidget.source.volume != widget.source.volume &&
        identical(_registeredDriver, _driver)) {
      unawaited(
        _audioMixer.updateSourceVolume(_driver!, widget.source.volume),
      );
    }
    if (oldWidget.phase != widget.phase) {
      if (_shouldPlay) {
        _stoppedByHost = false;
        _completionReported = false;
        _failureReported = false;
        if (_failureMessage != null) {
          _replaceDriver();
        } else if (_driver == null) {
          _startPlayback();
        } else {
          unawaited(_activate(_driver!, _generation));
        }
      } else {
        _unregister(_driver);
        unawaited(_driver?.pause());
      }
    }
  }

  void _replaceDriver() {
    final previous = _driver;
    if (previous != null) {
      _unregister(previous);
      previous.snapshots.removeListener(_handleSnapshot);
      unawaited(previous.dispose());
    }
    _driver = null;
    _snapshot = const PlayerIntroPlaybackSnapshot();
    _failureMessage = null;
    _generation++;
    _completionReported = false;
    _failureReported = false;
    if (_shouldPlay) _startPlayback();
  }

  void _startPlayback() {
    final generation = ++_generation;
    final factory = widget.driverFactory ?? VideoPlayerIntroPlaybackDriver.new;
    late final PlayerIntroPlaybackDriver driver;
    try {
      driver = factory(widget.source);
    } on Object catch (error) {
      _reportFailure(error.toString());
      return;
    }
    _driver = driver;
    driver.snapshots.addListener(_handleSnapshot);
    unawaited(_initialize(driver, generation));
  }

  Future<void> _initialize(
    PlayerIntroPlaybackDriver driver,
    int generation,
  ) async {
    try {
      await driver.initialize();
      if (!mounted || generation != _generation || !_shouldPlay) return;
      await _activate(driver, generation);
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      _reportFailure(error.toString());
    }
  }

  Future<void> _activate(
    PlayerIntroPlaybackDriver driver,
    int generation,
  ) async {
    try {
      final mixer = _audioMixer;
      await mixer.register(
        channel: driver,
        route: RuntimeAudioRoute.cinematicMusic,
        sourceVolume: widget.source.volume,
        setVolume: driver.setVolume,
      );
      if (!mounted || generation != _generation || !_shouldPlay) {
        mixer.unregister(driver);
        return;
      }
      _registeredMixer = mixer;
      _registeredDriver = driver;
      await driver.play();
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      _reportFailure(error.toString());
    }
  }

  void _handleSnapshot() {
    final driver = _driver;
    if (driver == null || !mounted || _stoppedByHost) return;
    final next = driver.snapshots.value;
    if (next.errorDescription case final reason?) {
      _reportFailure(reason);
      return;
    }
    setState(() => _snapshot = next);
    if (next.isCompleted && !_completionReported) {
      _completionReported = true;
      widget.onPlaybackCompleted();
    }
  }

  void _reportFailure(String _) {
    if (_failureReported || !mounted) return;
    const safeReason = 'Intro video playback failed.';
    _failureReported = true;
    _unregister(_driver);
    unawaited(_driver?.pause());
    setState(() => _failureMessage = safeReason);
    widget.onPlaybackFailed(safeReason);
  }

  /// The coordinator awaits this pause before title music may begin. The
  /// generation guard also prevents a pending initialize from restarting the
  /// decoder while the startup phase is still being committed.
  Future<void> _stopPlaybackForHost() async {
    _stoppedByHost = true;
    _generation++;
    _unregister(_driver);
    await _driver?.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final driver = _driver;
    if (driver == null) return;
    if (state == AppLifecycleState.resumed) {
      if (_shouldPlay &&
          !_stoppedByHost &&
          !_failureReported &&
          !_completionReported) {
        unawaited(driver.play());
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(driver.pause());
    }
  }

  @override
  Widget build(BuildContext context) {
    final posterMode =
        widget.phase == RuntimeIntroPhase.poster || _failureMessage != null;
    final media = posterMode
        ? _poster()
        : _video() ?? _poster() ?? const SizedBox.expand();
    return PlayerIntroVideoSurface(
      media: media,
      caption: posterMode ? null : _snapshot.caption,
      isPoster: posterMode,
      isBuffering:
          !posterMode && (!_snapshot.isInitialized || _snapshot.isBuffering),
      failureMessage: _failureMessage == null
          ? null
          : PlayerIntroVideoStrings.of(context).unavailable,
      onSkip: widget.onSkip,
      onContinue: posterMode ? widget.onContinue : null,
      onReplay: posterMode && widget.allowReplay ? widget.onReplay : null,
    );
  }

  Widget? _poster() => widget.poster == null
      ? null
      : Image(
          image: widget.poster!,
          fit: BoxFit.cover,
          alignment: widget.source.focalAlignment,
          errorBuilder: (_, __, ___) => const SizedBox.expand(),
        );

  Widget? _video() {
    if (!_snapshot.isInitialized) return null;
    final video = _driver?.buildVideo();
    if (video == null) return null;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        alignment: widget.source.focalAlignment,
        child: SizedBox(
          width: widget.source.aspectRatio,
          height: 1,
          child: video,
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.detach(_stopPlaybackForHost);
    _generation++;
    final driver = _driver;
    _driver = null;
    if (driver != null) {
      _unregister(driver);
      driver.snapshots.removeListener(_handleSnapshot);
      unawaited(driver.dispose());
    }
    super.dispose();
  }

  void _unregister(PlayerIntroPlaybackDriver? driver) {
    if (driver == null || !identical(_registeredDriver, driver)) return;
    _registeredMixer?.unregister(driver);
    _registeredMixer = null;
    _registeredDriver = null;
  }
}

/// Default `video_player` adapter used by mobile, desktop, and web hosts.
final class VideoPlayerIntroPlaybackDriver
    implements PlayerIntroPlaybackDriver {
  VideoPlayerIntroPlaybackDriver(PlayerIntroVideoSource source)
      : _looping = source.looping,
        _controller = createPlayerIntroVideoController(
          source.videoUri,
          captions: source.captionsLoader == null
              ? null
              : source.captionsLoader!()
                  .then<ClosedCaptionFile>(WebVTTCaptionFile.new),
        );

  final VideoPlayerController _controller;
  final bool _looping;
  final ValueNotifier<PlayerIntroPlaybackSnapshot> _snapshots =
      ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => _snapshots;

  @override
  Widget buildVideo() => VideoPlayer(_controller);

  @override
  Future<void> initialize() async {
    _controller.addListener(_synchronize);
    await _controller.initialize();
    await _controller.setLooping(_looping);
    await _controller.setVolume(0);
    _synchronize();
  }

  @override
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  void _synchronize() {
    final value = _controller.value;
    _snapshots.value = PlayerIntroPlaybackSnapshot(
      isInitialized: value.isInitialized,
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
  Future<void> dispose() async {
    _controller.removeListener(_synchronize);
    await _controller.dispose();
    _snapshots.dispose();
  }
}
