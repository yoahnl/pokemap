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
final class RuntimeAudioMixer {
  RuntimeAudioMixer({RuntimeAudioMix mix = const RuntimeAudioMix()})
      : _mix = mix;

  RuntimeAudioMix _mix;
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

  Future<void> transitionTo(RuntimeAudioMix mix) async {
    _mix = mix;
    for (final channel in _channels.values.toList(growable: false)) {
      await channel.apply(mix, _duckingGainFor(channel.route.bus));
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
