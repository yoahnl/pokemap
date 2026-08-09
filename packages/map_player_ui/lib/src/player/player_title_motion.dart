import 'dart:async';

import 'package:flutter/material.dart';

import 'player_intro_video_player.dart';
import 'player_startup_media.dart';

/// Silent looping motion used behind the title prompt and title menu.
///
/// The poster remains visible until the decoder is ready and becomes the
/// deterministic fallback when playback cannot start or reduced motion is on.
class PlayerTitleMotion extends StatefulWidget {
  const PlayerTitleMotion({
    super.key,
    required this.source,
    this.poster,
    this.driverFactory,
    this.reducedMotion = false,
  });

  final PlayerIntroVideoSource? source;
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

  bool get _canPlay =>
      widget.source != null && widget.source!.looping && !widget.reducedMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_canPlay) _start();
  }

  @override
  void didUpdateWidget(PlayerTitleMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        oldWidget.source?.videoUri != widget.source?.videoUri ||
            oldWidget.source?.aspectRatio != widget.source?.aspectRatio ||
            oldWidget.source?.focalX != widget.source?.focalX ||
            oldWidget.source?.focalY != widget.source?.focalY;
    if (sourceChanged || oldWidget.reducedMotion != widget.reducedMotion) {
      _replace();
    }
  }

  void _replace() {
    final previous = _driver;
    _driver = null;
    _snapshot = const PlayerIntroPlaybackSnapshot();
    _generation++;
    if (previous != null) {
      previous.snapshots.removeListener(_synchronize);
      unawaited(previous.dispose());
    }
    if (_canPlay) _start();
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
      // The poster is the deliberately silent, deterministic fallback.
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
      setState(() => _snapshot = const PlayerIntroPlaybackSnapshot());
    }
  }

  void _synchronize() {
    final driver = _driver;
    if (!mounted || driver == null) return;
    final next = driver.snapshots.value;
    if (next.errorDescription != null) {
      unawaited(driver.pause());
      setState(() => _snapshot = const PlayerIntroPlaybackSnapshot());
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
    _generation++;
    final driver = _driver;
    _driver = null;
    if (driver != null) {
      driver.snapshots.removeListener(_synchronize);
      unawaited(driver.dispose());
    }
    super.dispose();
  }
}
