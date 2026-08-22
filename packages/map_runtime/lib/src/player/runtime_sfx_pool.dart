import 'runtime_presentation_audio_controller.dart';

/// Reuses a bounded set of players for frequent sound effects — BETA-SYS-004.
///
/// [FlameRuntimePresentationAudioDriver] allocates an `AudioPlayer` per play
/// and disposes it on stop. That is right for a music bed, which holds its
/// player for minutes, and wrong for a footstep or a menu blip: allocating and
/// tearing down a platform player several times a second is exactly what a pool
/// exists to avoid.
///
/// So this wraps any driver and keeps released voices instead of disposing
/// them, keyed by source. Nothing else changes: the pool speaks the same driver
/// interface, so callers and the mixer are unaware of it.
///
/// A looping source is never pooled. A loop keeps its voice for its whole life,
/// so putting it in a pool would only make it eligible for reuse while still
/// playing.
final class RuntimeSfxPool implements RuntimePresentationAudioDriver {
  RuntimeSfxPool({
    required RuntimePresentationAudioDriver driver,
    this.voicesPerSource = 4,
  })  : _driver = driver,
        assert(voicesPerSource >= 1, 'a pool needs at least one voice');

  final RuntimePresentationAudioDriver _driver;

  /// How many voices one source may hold at once. Beyond it the oldest playing
  /// voice is stolen rather than the new shot dropped: silence is a worse
  /// answer than a clipped tail for feedback the player just triggered.
  final int voicesPerSource;

  final Map<String, List<_PooledVoice>> _idle = <String, List<_PooledVoice>>{};
  final Map<String, List<_PooledVoice>> _busy = <String, List<_PooledVoice>>{};
  final Map<Object, _PooledVoice> _byHandle = <Object, _PooledVoice>{};
  final Set<Object> _unpooled = <Object>{};
  var _disposed = false;
  var _allocations = 0;

  /// How many underlying players this pool has ever created. The point of a
  /// pool is that this stays at or under the cap however many times a sound
  /// plays, so it is observable rather than inferred.
  int get allocatedVoiceCount => _allocations;

  int idleVoiceCount(Uri source) => _idle[source.toString()]?.length ?? 0;

  int busyVoiceCount(Uri source) => _busy[source.toString()]?.length ?? 0;

  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
  }) async {
    if (_disposed) {
      throw StateError('The SFX pool is disposed.');
    }
    if (loop) {
      // Straight through: a loop owns its voice until it is stopped.
      final handle = await _driver.play(
        source,
        volume: volume,
        loop: true,
        position: position,
      );
      _unpooled.add(handle);
      return handle;
    }

    final key = source.toString();
    final idle = _idle[key];
    if (idle != null && idle.isNotEmpty) {
      final voice = idle.removeLast();
      await _driver.setVolume(voice.handle, volume);
      _busy.putIfAbsent(key, () => <_PooledVoice>[]).add(voice);
      // Replaying a reused voice is the driver's business; the pool only
      // guarantees the handle is the same one.
      await _driver.resume(voice.handle);
      return voice.handle;
    }

    final busy = _busy.putIfAbsent(key, () => <_PooledVoice>[]);
    if (busy.length >= voicesPerSource) {
      final stolen = busy.removeAt(0);
      await _driver.setVolume(stolen.handle, volume);
      await _driver.resume(stolen.handle);
      busy.add(stolen);
      return stolen.handle;
    }

    final handle = await _driver.play(
      source,
      volume: volume,
      loop: false,
      position: position,
    );
    _allocations += 1;
    final voice = _PooledVoice(key: key, handle: handle);
    busy.add(voice);
    _byHandle[handle] = voice;
    return handle;
  }

  @override
  Future<void> pause(Object handle) => _driver.pause(handle);

  @override
  Future<void> resume(Object handle) => _driver.resume(handle);

  @override
  Future<void> setVolume(Object handle, double volume) =>
      _driver.setVolume(handle, volume);

  /// Returns a pooled voice to the pool instead of disposing it. An unpooled
  /// handle — a loop, or anything from before the pool was installed — is
  /// stopped for real.
  @override
  Future<void> stop(Object handle) async {
    if (_unpooled.remove(handle)) {
      await _driver.stop(handle);
      return;
    }
    final voice = _byHandle[handle];
    if (voice == null) {
      await _driver.stop(handle);
      return;
    }
    _busy[voice.key]?.remove(voice);
    if (_disposed) {
      _byHandle.remove(handle);
      await _driver.stop(handle);
      return;
    }
    await _driver.pause(handle);
    _idle.putIfAbsent(voice.key, () => <_PooledVoice>[]).add(voice);
  }

  /// Releases every voice for real, pooled or not. "dispose libère toutes les
  /// ressources" has to include the ones the pool was deliberately holding on
  /// to, or a pool is just a leak with a nicer name.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final handles = <Object>[
      ..._unpooled,
      for (final voices in _idle.values)
        for (final voice in voices) voice.handle,
      for (final voices in _busy.values)
        for (final voice in voices) voice.handle,
    ];
    _unpooled.clear();
    _idle.clear();
    _busy.clear();
    _byHandle.clear();
    for (final handle in handles) {
      await _driver.stop(handle);
    }
  }
}

final class _PooledVoice {
  const _PooledVoice({required this.key, required this.handle});

  final String key;
  final Object handle;
}
