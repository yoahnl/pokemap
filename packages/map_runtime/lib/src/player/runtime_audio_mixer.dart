typedef RuntimeAudioVolumeSetter = Future<void> Function(double volume);

/// Runtime-owned audio identities. Routes intentionally stay independent from
/// file paths so title, map, battle, and cinematic sources share one mixer.
enum RuntimeAudioRoute {
  splash,
  title,
  overworld,
  battle,
  cinematicMusic,
  cinematicEffects,
}

enum RuntimeAudioBus { music, effects }

extension RuntimeAudioRouteBus on RuntimeAudioRoute {
  RuntimeAudioBus get bus => switch (this) {
        RuntimeAudioRoute.title ||
        RuntimeAudioRoute.splash ||
        RuntimeAudioRoute.overworld ||
        RuntimeAudioRoute.battle ||
        RuntimeAudioRoute.cinematicMusic =>
          RuntimeAudioBus.music,
        RuntimeAudioRoute.cinematicEffects => RuntimeAudioBus.effects,
      };
}

/// Persistable three-bus mix projected by the embedding player.
final class RuntimeAudioMix {
  const RuntimeAudioMix({
    this.masterVolume = 1,
    this.musicVolume = 1,
    this.effectsVolume = 1,
  })  : assert(
          masterVolume >= 0 && masterVolume <= 1,
          'masterVolume must be between 0 and 1',
        ),
        assert(
          musicVolume >= 0 && musicVolume <= 1,
          'musicVolume must be between 0 and 1',
        ),
        assert(
          effectsVolume >= 0 && effectsVolume <= 1,
          'effectsVolume must be between 0 and 1',
        );

  final double masterVolume;
  final double musicVolume;
  final double effectsVolume;

  /// Interpolates towards [target]. Used by a mix fade, which needs the
  /// intermediate mixes rather than a jump.
  RuntimeAudioMix lerpTo(RuntimeAudioMix target, double t) {
    final progress = t.clamp(0.0, 1.0);
    double at(double from, double to) =>
        (from + (to - from) * progress).clamp(0.0, 1.0);
    return RuntimeAudioMix(
      masterVolume: at(masterVolume, target.masterVolume),
      musicVolume: at(musicVolume, target.musicVolume),
      effectsVolume: at(effectsVolume, target.effectsVolume),
    );
  }

  double volumeFor(
    RuntimeAudioRoute route, {
    double sourceVolume = 1,
  }) {
    final normalizedSource = sourceVolume.clamp(0.0, 1.0);
    final busVolume = switch (route.bus) {
      RuntimeAudioBus.music => musicVolume,
      RuntimeAudioBus.effects => effectsVolume,
    };
    return (masterVolume * busVolume * normalizedSource).clamp(0.0, 1.0);
  }
}

/// Applies mix transitions to every active runtime channel.
///
/// Playback ownership remains with the title, overworld, battle, or cinematic
/// controller. The mixer only retains safe channel identifiers and volume
/// callbacks, and unregistering never stops playback.
/// Waits for [delay]. Injected so a fade is deterministic in a test instead of
/// depending on wall-clock timing.
typedef RuntimeAudioFadeDelay = Future<void> Function(Duration delay);

final class RuntimeAudioMixer {
  RuntimeAudioMixer({
    RuntimeAudioMix mix = const RuntimeAudioMix(),
    RuntimeAudioFadeDelay? fadeDelay,
    int fadeSteps = 8,
  })  : _mix = mix,
        _fadeDelay = fadeDelay ?? Future<void>.delayed,
        _fadeSteps = fadeSteps < 1 ? 1 : fadeSteps;

  RuntimeAudioMix _mix;
  final RuntimeAudioFadeDelay _fadeDelay;
  final int _fadeSteps;

  /// Bumped by anything that supersedes a fade. A ramp compares it on every
  /// step and drops itself the moment it is no longer the current one, which
  /// is what "annulable sans double player" means in practice: exactly one
  /// ramp may write volumes, so a late step from a cancelled fade can never
  /// land on top of a newer target.
  int _fadeGeneration = 0;

  bool get isFading => _fadingGeneration == _fadeGeneration;
  int _fadingGeneration = -1;
  final Map<Object, _RuntimeMixedChannel> _channels =
      <Object, _RuntimeMixedChannel>{};
  final Map<Object, _RuntimeAudioDuck> _ducking = <Object, _RuntimeAudioDuck>{};

  RuntimeAudioMix get mix => _mix;

  Future<void> register({
    required Object channel,
    required RuntimeAudioRoute route,
    double sourceVolume = 1,
    required RuntimeAudioVolumeSetter setVolume,
    bool applyImmediately = true,
  }) async {
    final registered = _RuntimeMixedChannel(
      route: route,
      sourceVolume: sourceVolume.clamp(0.0, 1.0),
      setVolume: setVolume,
    );
    final previous = _channels[channel];
    _channels[channel] = registered;
    if (applyImmediately) {
      try {
        await registered.apply(_mix, _duckingGainFor(route.bus));
      } on Object {
        if (identical(_channels[channel], registered)) {
          if (previous == null) {
            _channels.remove(channel);
          } else {
            _channels[channel] = previous;
          }
        }
        rethrow;
      }
    }
  }

  Future<void> updateSourceVolume(Object channel, double sourceVolume) async {
    final current = _channels[channel];
    if (current == null) return;
    final updated = current.copyWith(
      sourceVolume: sourceVolume.clamp(0.0, 1.0),
    );
    _channels[channel] = updated;
    await updated.apply(_mix, _duckingGainFor(updated.route.bus));
  }

  void unregister(Object channel) {
    _channels.remove(channel);
  }

  /// Moves the mix to [mix], optionally ramping over [fade].
  ///
  /// With no fade this is the instantaneous behaviour every existing caller
  /// already relies on, unchanged. With a fade the ramp is cancelled by the
  /// next transition, by [cancelFade], and by [dispose]; a cancelled ramp
  /// stops writing immediately, so two transitions in a row settle on the
  /// second target and never on a stale step of the first.
  Future<void> transitionTo(
    RuntimeAudioMix mix, {
    Duration fade = Duration.zero,
  }) async {
    final generation = ++_fadeGeneration;
    if (fade <= Duration.zero) {
      _mix = mix;
      await _applyAll();
      return;
    }
    final from = _mix;
    final step = Duration(
      microseconds: (fade.inMicroseconds / _fadeSteps).ceil(),
    );
    _fadingGeneration = generation;
    try {
      for (var index = 1; index <= _fadeSteps; index += 1) {
        await _fadeDelay(step);
        if (generation != _fadeGeneration) return;
        _mix = from.lerpTo(mix, index / _fadeSteps);
        await _applyAll();
        if (generation != _fadeGeneration) return;
      }
    } finally {
      if (generation == _fadingGeneration) _fadingGeneration = -1;
    }
  }

  /// Stops a ramp where it got to. The mix keeps its current value — a fade
  /// that jumped to its target on cancel would be indistinguishable from no
  /// fade at all.
  void cancelFade() {
    _fadeGeneration += 1;
    _fadingGeneration = -1;
  }

  Future<void> _applyAll() async {
    for (final channel in _channels.values.toList(growable: false)) {
      await channel.apply(_mix, _duckingGainFor(channel.route.bus));
    }
  }

  Future<void> setDucking({
    required Object owner,
    required RuntimeAudioBus bus,
    required double gain,
  }) async {
    if (!gain.isFinite || gain < 0 || gain > 1) {
      throw ArgumentError.value(gain, 'gain', 'must be between zero and one');
    }
    final previousBus = _ducking[owner]?.bus;
    _ducking[owner] = _RuntimeAudioDuck(bus: bus, gain: gain);
    if (previousBus != null && previousBus != bus) {
      await _applyBus(previousBus);
    }
    await _applyBus(bus);
  }

  Future<void> clearDucking(Object owner) async {
    final removed = _ducking.remove(owner);
    if (removed == null) return;
    await _applyBus(removed.bus);
  }

  double _duckingGainFor(RuntimeAudioBus bus) {
    var gain = 1.0;
    for (final duck in _ducking.values) {
      if (duck.bus == bus && duck.gain < gain) gain = duck.gain;
    }
    return gain;
  }

  Future<void> _applyBus(RuntimeAudioBus bus) async {
    for (final channel in _channels.values.toList(growable: false)) {
      if (channel.route.bus == bus) {
        await channel.apply(_mix, _duckingGainFor(bus));
      }
    }
  }
}

final class _RuntimeAudioDuck {
  const _RuntimeAudioDuck({required this.bus, required this.gain});

  final RuntimeAudioBus bus;
  final double gain;
}

final class _RuntimeMixedChannel {
  const _RuntimeMixedChannel({
    required this.route,
    required this.sourceVolume,
    required this.setVolume,
  });

  final RuntimeAudioRoute route;
  final double sourceVolume;
  final RuntimeAudioVolumeSetter setVolume;

  Future<void> apply(RuntimeAudioMix mix, double duckingGain) => setVolume(
        mix.volumeFor(route, sourceVolume: sourceVolume) * duckingGain,
      );

  _RuntimeMixedChannel copyWith({required double sourceVolume}) =>
      _RuntimeMixedChannel(
        route: route,
        sourceVolume: sourceVolume,
        setVolume: setVolume,
      );
}
