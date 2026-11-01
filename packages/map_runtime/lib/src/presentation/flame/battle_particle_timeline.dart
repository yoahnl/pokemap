import 'package:map_core/map_core.dart';

enum BattleParticleEventKind { emission, expiration }

final class BattleParticleEmitterTiming {
  const BattleParticleEmitterTiming({
    required this.textureId,
    required this.emissionDurationMs,
    required this.emissionIntervalMs,
    required this.particleLifetimeMs,
    required this.particlesPerEmission,
  });

  final String textureId;
  final int emissionDurationMs;
  final int emissionIntervalMs;
  final int particleLifetimeMs;
  final int particlesPerEmission;
}

final class BattleParticleEvent {
  const BattleParticleEvent({
    required this.kind,
    required this.emitterIndex,
    required this.batchIndex,
    required this.textureId,
    required this.at,
    required this.count,
  });

  final BattleParticleEventKind kind;
  final int emitterIndex;
  final int batchIndex;
  final String textureId;
  final Duration at;
  final int count;
}

final class BattleParticleTimeline {
  factory BattleParticleTimeline.fromDefinition(
    BattleParticleDefinition definition,
  ) => BattleParticleTimeline([
    for (final emitter in definition.emitters)
      BattleParticleEmitterTiming(
        textureId: emitter.textureId,
        emissionDurationMs: emitter.emissionDurationMs,
        emissionIntervalMs: emitter.emissionIntervalMs,
        particleLifetimeMs: emitter.particleLifetimeMs,
        particlesPerEmission: emitter.particlesPerEmission,
      ),
  ]);

  BattleParticleTimeline(List<BattleParticleEmitterTiming> emitters)
    : _emitters = List.unmodifiable(emitters) {
    if (emitters.isEmpty || emitters.length > 32) {
      throw const FormatException('Invalid emitter count');
    }
    var totalParticles = 0;
    for (final emitter in emitters) {
      if (emitter.textureId.isEmpty ||
          emitter.textureId.trim() != emitter.textureId ||
          emitter.emissionDurationMs < 1 ||
          emitter.emissionDurationMs > 60000 ||
          emitter.emissionIntervalMs < 1 ||
          emitter.emissionIntervalMs > 60000 ||
          emitter.particleLifetimeMs < 1 ||
          emitter.particleLifetimeMs > 60000 ||
          emitter.particlesPerEmission < 1 ||
          emitter.particlesPerEmission > 64) {
        throw const FormatException('Invalid particle timing');
      }
      final batches =
          (emitter.emissionDurationMs + emitter.emissionIntervalMs - 1) ~/
          emitter.emissionIntervalMs;
      totalParticles += batches * emitter.particlesPerEmission;
      if (totalParticles > 4096) {
        throw const FormatException('Particle emission limit exceeded');
      }
      _states.add(_EmitterState(batches));
      final end =
          ((batches - 1) * emitter.emissionIntervalMs +
              emitter.particleLifetimeMs) *
          1000;
      if (end > _endMicros) _endMicros = end;
    }
  }

  final List<BattleParticleEmitterTiming> _emitters;
  final List<_EmitterState> _states = [];
  int _targetMicros = 0;
  int _nowMicros = 0;
  int _endMicros = 0;
  int _activeParticles = 0;
  bool _cancelled = false;

  int get activeParticles => _activeParticles;
  bool get isCancelled => _cancelled;
  Duration get elapsed => Duration(microseconds: _nowMicros);
  bool get isComplete =>
      !_cancelled && _states.every((state) => state.expired == state.batches);
  bool get hasPendingEvents {
    if (_cancelled) return false;
    final next = _nextEvent();
    return next != null && next.at.inMicroseconds <= _targetMicros;
  }

  List<BattleParticleEvent> advance(Duration elapsed, {int workBudget = 256}) {
    if (elapsed.isNegative || workBudget < 0 || workBudget > 256) {
      throw ArgumentError('Invalid particle time or work budget');
    }
    if (_cancelled || isComplete) return const [];
    final remaining = _endMicros - _targetMicros;
    _targetMicros += elapsed.inMicroseconds >= remaining
        ? remaining
        : elapsed.inMicroseconds;
    final events = <BattleParticleEvent>[];
    while (events.length < workBudget) {
      final event = _nextEvent();
      if (event == null || event.at.inMicroseconds > _targetMicros) break;
      _nowMicros = event.at.inMicroseconds;
      final state = _states[event.emitterIndex];
      if (event.kind == BattleParticleEventKind.emission) {
        state.emitted++;
        _activeParticles += event.count;
      } else {
        state.expired++;
        _activeParticles -= event.count;
      }
      events.add(event);
    }
    if (!hasPendingEvents) _nowMicros = _targetMicros;
    return List.unmodifiable(events);
  }

  void cancel() {
    _cancelled = true;
    _activeParticles = 0;
  }

  BattleParticleEvent? _nextEvent() {
    int? earliestMs;
    var earliestIndex = 0;
    var earliestBatch = 0;
    var earliestKind = BattleParticleEventKind.emission;
    void consider(
      int atMs,
      BattleParticleEventKind kind,
      int index,
      int batch,
    ) {
      final previousMs = earliestMs;
      if (previousMs == null ||
          atMs < previousMs ||
          (atMs == previousMs &&
              kind == BattleParticleEventKind.expiration &&
              earliestKind == BattleParticleEventKind.emission) ||
          (atMs == previousMs &&
              kind == earliestKind &&
              index < earliestIndex)) {
        earliestMs = atMs;
        earliestKind = kind;
        earliestIndex = index;
        earliestBatch = batch;
      }
    }

    for (var index = 0; index < _emitters.length; index++) {
      final emitter = _emitters[index];
      final state = _states[index];
      if (state.emitted < state.batches) {
        consider(
          state.emitted * emitter.emissionIntervalMs,
          BattleParticleEventKind.emission,
          index,
          state.emitted,
        );
      }
      if (state.expired < state.emitted) {
        consider(
          state.expired * emitter.emissionIntervalMs +
              emitter.particleLifetimeMs,
          BattleParticleEventKind.expiration,
          index,
          state.expired,
        );
      }
    }
    final atMs = earliestMs;
    if (atMs == null) return null;
    final emitter = _emitters[earliestIndex];
    return BattleParticleEvent(
      kind: earliestKind,
      emitterIndex: earliestIndex,
      batchIndex: earliestBatch,
      textureId: emitter.textureId,
      at: Duration(milliseconds: atMs),
      count: emitter.particlesPerEmission,
    );
  }
}

final class _EmitterState {
  _EmitterState(this.batches);

  final int batches;
  int emitted = 0;
  int expired = 0;
}
