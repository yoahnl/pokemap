import 'dart:collection';

import 'package:map_core/map_core.dart';

const _fractionUnit = 4096;
const _maximumParticles = 4096;
const _maximumBatches = 4096;

enum BattleParticleEventKind { emission, expiration }

final class BattleParticleEmitterTiming {
  const BattleParticleEmitterTiming({
    required this.textureId,
    required int emissionDurationMs,
    required int emissionIntervalMs,
    required int particleLifetimeMs,
    required this.particlesPerEmission,
    this.fractionalEmission4096 = 0,
    int startDelayMs = 0,
  }) : _durationUnits = emissionDurationMs,
       _intervalUnits = emissionIntervalMs,
       _lifetimeUnits = particleLifetimeMs,
       _startDelayUnits = startDelayMs,
       _unitsPerSecond = 1000;

  const BattleParticleEmitterTiming.ticks({
    required this.textureId,
    required int emissionDurationTicks,
    required int emissionIntervalTicks,
    required int particleLifetimeTicks,
    required this.particlesPerEmission,
    required int ticksPerSecond,
    this.fractionalEmission4096 = 0,
    int startDelayTicks = 0,
  }) : _durationUnits = emissionDurationTicks,
       _intervalUnits = emissionIntervalTicks,
       _lifetimeUnits = particleLifetimeTicks,
       _startDelayUnits = startDelayTicks,
       _unitsPerSecond = ticksPerSecond;

  final String textureId;
  final int _durationUnits;
  final int _intervalUnits;
  final int _lifetimeUnits;
  final int _startDelayUnits;
  final int _unitsPerSecond;
  final int particlesPerEmission;
  final int fractionalEmission4096;

  int _microsecondsAt(int units) =>
      (units * Duration.microsecondsPerSecond) ~/ _unitsPerSecond;
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
    var totalBatches = 0;
    for (final emitter in emitters) {
      if (emitter.textureId.isEmpty ||
          emitter.textureId.trim() != emitter.textureId ||
          emitter._unitsPerSecond < 1 ||
          emitter._unitsPerSecond > 1000 ||
          emitter._durationUnits < 1 ||
          emitter._durationUnits > emitter._unitsPerSecond * 60 ||
          emitter._intervalUnits < 1 ||
          emitter._intervalUnits > emitter._unitsPerSecond * 60 ||
          emitter._lifetimeUnits < 1 ||
          emitter._lifetimeUnits > emitter._unitsPerSecond * 60 ||
          emitter.particlesPerEmission < 0 ||
          emitter.particlesPerEmission > 64 ||
          emitter.fractionalEmission4096 < 0 ||
          emitter.fractionalEmission4096 >= _fractionUnit ||
          (emitter.particlesPerEmission == 0 &&
              emitter.fractionalEmission4096 == 0) ||
          (emitter.particlesPerEmission == 64 &&
              emitter.fractionalEmission4096 != 0) ||
          emitter._startDelayUnits < 0 ||
          emitter._startDelayUnits > emitter._unitsPerSecond * 60) {
        throw const FormatException('Invalid particle timing');
      }
      final batches =
          (emitter._durationUnits + emitter._intervalUnits - 1) ~/
          emitter._intervalUnits;
      totalBatches += batches;
      totalParticles +=
          batches * emitter.particlesPerEmission +
          (batches * emitter.fractionalEmission4096) ~/ _fractionUnit;
      if (totalParticles > _maximumParticles ||
          totalBatches > _maximumBatches) {
        throw const FormatException('Particle emission limit exceeded');
      }
      _states.add(_EmitterState(batches));
      final end = emitter._microsecondsAt(
        emitter._startDelayUnits +
            (batches - 1) * emitter._intervalUnits +
            emitter._lifetimeUnits,
      );
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
      !_cancelled &&
      _states.every(
        (state) =>
            state.emitted == state.batches && state.pendingExpirations.isEmpty,
      );
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
    var work = 0;
    while (work < workBudget) {
      final event = _nextEvent();
      if (event == null || event.at.inMicroseconds > _targetMicros) break;
      work++;
      _nowMicros = event.at.inMicroseconds;
      final state = _states[event.emitterIndex];
      if (event.kind == BattleParticleEventKind.emission) {
        state.emitted++;
        if (event.count == 0) continue;
        state.pendingExpirations.addLast(event.batchIndex);
        _activeParticles += event.count;
      } else {
        state.pendingExpirations.removeFirst();
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
    for (final state in _states) {
      state.pendingExpirations.clear();
    }
  }

  BattleParticleEvent? _nextEvent() {
    int? earliestMicros;
    var earliestIndex = 0;
    var earliestBatch = 0;
    var earliestKind = BattleParticleEventKind.emission;
    void consider(
      int atMicros,
      BattleParticleEventKind kind,
      int index,
      int batch,
    ) {
      final previousMicros = earliestMicros;
      if (previousMicros == null ||
          atMicros < previousMicros ||
          (atMicros == previousMicros &&
              kind == BattleParticleEventKind.expiration &&
              earliestKind == BattleParticleEventKind.emission) ||
          (atMicros == previousMicros &&
              kind == earliestKind &&
              index < earliestIndex)) {
        earliestMicros = atMicros;
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
          emitter._microsecondsAt(
            emitter._startDelayUnits + state.emitted * emitter._intervalUnits,
          ),
          BattleParticleEventKind.emission,
          index,
          state.emitted,
        );
      }
      if (state.pendingExpirations.isNotEmpty) {
        final batch = state.pendingExpirations.first;
        consider(
          emitter._microsecondsAt(
            emitter._startDelayUnits +
                batch * emitter._intervalUnits +
                emitter._lifetimeUnits,
          ),
          BattleParticleEventKind.expiration,
          index,
          batch,
        );
      }
    }
    final atMicros = earliestMicros;
    if (atMicros == null) return null;
    final emitter = _emitters[earliestIndex];
    return BattleParticleEvent(
      kind: earliestKind,
      emitterIndex: earliestIndex,
      batchIndex: earliestBatch,
      textureId: emitter.textureId,
      at: Duration(microseconds: atMicros),
      count:
          emitter.particlesPerEmission +
          ((earliestBatch + 1) * emitter.fractionalEmission4096) ~/
              _fractionUnit -
          (earliestBatch * emitter.fractionalEmission4096) ~/ _fractionUnit,
    );
  }
}

final class _EmitterState {
  _EmitterState(this.batches);

  final int batches;
  int emitted = 0;
  final Queue<int> pendingExpirations = Queue<int>();
}
