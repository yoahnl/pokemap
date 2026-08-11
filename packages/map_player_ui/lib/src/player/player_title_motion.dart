import 'dart:async';

import 'package:flutter/material.dart';

import 'player_intro_video_player.dart';
import 'player_startup_media.dart';

final class PlayerTitleMotionController {
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

/// Silent looping motion used behind the title prompt and title menu.
///
/// The poster remains visible until the decoder is ready and becomes the
/// deterministic fallback when playback cannot start or reduced motion is on.
class PlayerTitleMotion extends StatefulWidget {
  const PlayerTitleMotion({
    super.key,
    required this.source,
    this.controller,
    this.poster,
    this.driverFactory,
    this.reducedMotion = false,
  });

  final PlayerIntroVideoSource? source;
  final PlayerTitleMotionController? controller;
  final ImageProvider? poster;
  final PlayerIntroPlaybackFactory? driverFactory;
  final bool reducedMotion;

  @override
  State<PlayerTitleMotion> createState() => _PlayerTitleMotionState();
}

class _PlayerTitleMotionState extends State<PlayerTitleMotion>
    with WidgetsBindingObserver {
  PlayerIntroPlaybackDriver? _driver;
  PlayerIntroPlaybackSnapshot _snapshot = const PlayerIntroPlaybackSnapshot();
  int _generation = 0;
  bool _lifecycleActive = true;
  bool _releasedByHost = false;
  Future<void> _mediaTransition = Future<void>.value();

  bool get _canPlay =>
      widget.source != null &&
      widget.source!.looping &&
      !widget.reducedMotion &&
      !_releasedByHost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._attach(_releasePlayback);
    if (_canPlay) _start();
  }

  @override
  void didUpdateWidget(PlayerTitleMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(_releasePlayback);
      widget.controller?._attach(_releasePlayback);
    }
    final sourceChanged =
        oldWidget.source?.videoUri != widget.source?.videoUri ||
            oldWidget.source?.looping != widget.source?.looping ||
            oldWidget.source?.aspectRatio != widget.source?.aspectRatio ||
            oldWidget.source?.focalX != widget.source?.focalX ||
            oldWidget.source?.focalY != widget.source?.focalY;
    if (sourceChanged || oldWidget.reducedMotion != widget.reducedMotion) {
      _releasedByHost = false;
      unawaited(_replace());
    }
  }

  Future<void> _replace() async {
    final generation = ++_generation;
    final previous = _detachDriver();
    _snapshot = const PlayerIntroPlaybackSnapshot();
    _mediaTransition = _mediaTransition.then((_) async {
      if (previous != null) {
        try {
          await previous.dispose();
        } on Object {
          return;
        }
      }
      if (!mounted || generation != _generation) return;
      if (_canPlay) _start();
    });
    await _mediaTransition;
  }

  PlayerIntroPlaybackDriver? _detachDriver() {
    final driver = _driver;
    _driver = null;
    driver?.snapshots.removeListener(_synchronize);
    return driver;
  }

  void _start() {
    final source = widget.source!;
    final generation = ++_generation;
    final factory = widget.driverFactory ?? VideoPlayerIntroPlaybackDriver.new;
    try {
      final driver = factory(source);
      _driver = driver;
      driver.snapshots.addListener(_synchronize);
      unawaited(_initialize(driver, generation));
    } on Object {
      _driver = null;
    }
  }

  Future<void> _initialize(
    PlayerIntroPlaybackDriver driver,
    int generation,
  ) async {
    try {
      await driver.initialize();
      if (!mounted || generation != _generation || !_lifecycleActive) return;
      await driver.play();
    } on Object {
      if (!mounted || generation != _generation) return;
      final failed = _detachDriver();
      setState(() => _snapshot = const PlayerIntroPlaybackSnapshot());
      if (failed != null) {
        unawaited(failed.dispose());
      }
    }
  }

  void _synchronize() {
    final driver = _driver;
    if (!mounted || driver == null) return;
    final next = driver.snapshots.value;
    if (next.errorDescription != null) {
      _generation++;
      _detachDriver();
      setState(() => _snapshot = const PlayerIntroPlaybackSnapshot());
      unawaited(driver.dispose());
      return;
    }
    setState(() => _snapshot = next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleActive = state == AppLifecycleState.resumed;
    final driver = _driver;
    if (driver == null) return;
    if (_lifecycleActive && _canPlay) {
      unawaited(driver.play());
    } else {
      unawaited(driver.pause());
    }
  }

  Future<void> _releasePlayback() async {
    _releasedByHost = true;
    _generation++;
    final driver = _detachDriver();
    if (mounted) {
      setState(() => _snapshot = const PlayerIntroPlaybackSnapshot());
    }
    await _mediaTransition;
    if (driver == null) return;
    await driver.pause();
    await driver.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (widget.poster case final poster?)
          Image(
            key: const ValueKey<String>('player-title-motion-poster'),
            image: poster,
            fit: BoxFit.cover,
            alignment: source?.focalAlignment ?? Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.expand(),
          ),
        if (_snapshot.isInitialized && source != null && !widget.reducedMotion)
          ClipRect(
            key: const ValueKey<String>('player-title-motion-video'),
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: source.focalAlignment,
              child: SizedBox(
                width: source.aspectRatio,
                height: 1,
                child: _driver?.buildVideo(),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?._detach(_releasePlayback);
    _generation++;
    final driver = _detachDriver();
    if (driver != null) {
      unawaited(driver.dispose());
    }
    super.dispose();
  }
}
