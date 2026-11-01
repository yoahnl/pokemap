final class BattleSplParticlePool {
  BattleSplParticlePool({required this.capacity}) {
    if (capacity < 1 || capacity > 4096) {
      throw const FormatException('Invalid SPL particle pool capacity');
    }
  }

  final int capacity;
  int _inUse = 0;

  int get inUse => _inUse;

  BattleSplParticleLease createLease() => BattleSplParticleLease._(this);
}

final class BattleSplParticleLease {
  BattleSplParticleLease._(this._pool);

  final BattleSplParticlePool _pool;
  int _inUse = 0;
  bool _disposed = false;

  int acquire(int count) {
    if (_disposed) throw StateError('SPL particle lease is disposed');
    if (count < 0) throw ArgumentError.value(count, 'count');
    final available = _pool.capacity - _pool._inUse;
    final acquired = count < available ? count : available;
    _inUse += acquired;
    _pool._inUse += acquired;
    return acquired;
  }

  void release(int count) {
    if (_disposed) throw StateError('SPL particle lease is disposed');
    if (count < 0) throw ArgumentError.value(count, 'count');
    if (count > _inUse) throw StateError('SPL particle lease is over-released');
    _inUse -= count;
    _pool._inUse -= count;
  }

  void dispose() {
    if (_disposed) return;
    _pool._inUse -= _inUse;
    _inUse = 0;
    _disposed = true;
  }
}
