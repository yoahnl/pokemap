import 'package:map_core/map_core.dart';

import 'battle_spl_configured_emitter.dart';
import 'battle_spl_particle_motion.dart';
import 'battle_spl_particle_pool.dart';
import 'battle_spl_point_emitter_playback.dart';
import 'battle_spl_random.dart';

enum BattleSplAdmissionFailure {
  arithmetic,
  poolExhausted,
  frameLimit,
  workLimit,
  textureUnavailable,
  projectionUnavailable,
}

final class BattleSplStaticEmitter {
  const BattleSplStaticEmitter({
    required this.emitterIndex,
    required this.startTick,
    required this.position,
    this.velocity = (x: 0, y: 0, z: 0),
  });

  final int emitterIndex;
  final int startTick;
  final BattleSplVector position;
  final BattleSplVector velocity;
}

final class BattleSplStaticFrame {
  BattleSplStaticFrame._(
    this.emitterIndex,
    this.aspectRatio4096,
    this.directional,
    this.childDirectional,
    this.scaleAxis,
    this.polygonX,
    this.polygonY,
    this.relativeBasePosition,
    this.directionalPolygon,
    this.sourcePolygon,
    this.hideParent,
    this.followEmitter,
    this.childFollowsEmitter,
    List<BattleSplPointParticle> particles,
  ) : particles = List.unmodifiable(particles);

  final int emitterIndex;
  final int aspectRatio4096;
  final bool directional;
  final bool childDirectional;
  final String scaleAxis;
  final int polygonX;
  final int polygonY;
  final BattleSplVector? relativeBasePosition;
  final bool directionalPolygon;
  final bool sourcePolygon;
  final bool hideParent;
  final bool followEmitter;
  final bool childFollowsEmitter;
  final List<BattleSplPointParticle> particles;
}

final class BattleSplStaticPreparation {
  const BattleSplStaticPreparation._({this.playback, this.failure});

  final BattleSplStaticPlayback? playback;
  final BattleSplAdmissionFailure? failure;
}

abstract final class BattleSplStaticAdmission {
  static const maxTicks = 600;
  static const maxWork = 131072;

  static BattleSplStaticPreparation prepare({
    required BattleSplParticleDefinition definition,
    required Map<String, int> textureIndices,
    required List<BattleSplStaticEmitter> emitters,
    required int seed,
    required int poolCapacity,
    required int maxTicks,
  }) {
    if (seed < 0 ||
        seed > 0xffffffff ||
        poolCapacity < 1 ||
        poolCapacity > 4096 ||
        maxTicks < 1 ||
        maxTicks > BattleSplStaticAdmission.maxTicks ||
        emitters.isEmpty ||
        emitters.length > 32 ||
        textureIndices.length != definition.textureIds.length ||
        !textureIndices.keys.toSet().containsAll(definition.textureIds) ||
        textureIndices.values.any((index) => index < 0 || index > 255) ||
        textureIndices.values.toSet().length != textureIndices.length ||
        emitters.any(
          (entry) =>
              entry.emitterIndex < 0 ||
              entry.emitterIndex >= definition.emitters.length ||
              entry.startTick < 0 ||
              entry.startTick >= maxTicks ||
              !_validVector(entry.position) ||
              !_validVector(entry.velocity),
        )) {
      throw const FormatException('Invalid static SPL admission');
    }
    if (poolCapacity * maxTicks * emitters.length > maxWork) {
      return const BattleSplStaticPreparation._(
        failure: BattleSplAdmissionFailure.workLimit,
      );
    }
    final schedule = List<BattleSplStaticEmitter>.unmodifiable(emitters);
    final textures = Map<String, int>.unmodifiable(textureIndices);
    BattleSplStaticPlayback create() => BattleSplStaticPlayback._(
      definition: definition,
      textureIndices: textures,
      schedule: schedule,
      seed: seed,
      poolCapacity: poolCapacity,
      maxTicks: maxTicks,
    );

    final probe = create();
    try {
      while (!probe.isComplete && probe.tick < maxTicks) {
        final failure = probe.advance();
        if (failure != null) {
          return BattleSplStaticPreparation._(failure: failure);
        }
      }
      if (!probe.isComplete) {
        return const BattleSplStaticPreparation._(
          failure: BattleSplAdmissionFailure.frameLimit,
        );
      }
    } finally {
      probe.cancel();
    }
    return BattleSplStaticPreparation._(playback: create());
  }
}

final class BattleSplStaticPlayback {
  BattleSplStaticPlayback._({
    required BattleSplParticleDefinition definition,
    required Map<String, int> textureIndices,
    required List<BattleSplStaticEmitter> schedule,
    required int seed,
    required int poolCapacity,
    required this.maxTicks,
  }) : _pool = BattleSplParticlePool(capacity: poolCapacity),
       textureIndices = Set.unmodifiable(textureIndices.values) {
    final random = BattleSplRandom(seed: seed);
    try {
      for (final entry in schedule) {
        _emitters.add(
          _StaticEmitterState(
            entry,
            BattleSplConfiguredEmitter(
              definition: definition.emitters[entry.emitterIndex],
              textureIndices: textureIndices,
              random: random,
              pool: _pool,
            ),
          ),
        );
      }
      final order = List<int>.generate(_emitters.length, (index) => index);
      order.sort((left, right) {
        final byStart = schedule[right].startTick.compareTo(
          schedule[left].startTick,
        );
        return byStart != 0 ? byStart : right.compareTo(left);
      });
      _drawOrder = List.unmodifiable(order);
      _updateOrder = List.unmodifiable(order.map((index) => _emitters[index]));
    } catch (_) {
      cancel();
      rethrow;
    }
  }

  final int maxTicks;
  final Set<int> textureIndices;
  final BattleSplParticlePool _pool;
  final List<_StaticEmitterState> _emitters = [];
  late final List<int> _drawOrder;
  late final List<_StaticEmitterState> _updateOrder;
  int _tick = 0;
  bool _cancelled = false;
  BattleSplAdmissionFailure? _failure;

  int get tick => _tick;
  int get activeParticles => _pool.inUse;
  List<int> get drawOrder => _drawOrder;
  bool get isComplete =>
      _cancelled ||
      _emitters.every(
        (entry) =>
            _tick > entry.schedule.startTick &&
            entry.emitter.playback.isComplete,
      );
  List<BattleSplStaticFrame> get frames => List.unmodifiable([
    for (final entry in _emitters)
      BattleSplStaticFrame._(
        entry.schedule.emitterIndex,
        entry.emitter.aspectRatio4096,
        entry.emitter.directional,
        entry.emitter.childDirectional,
        entry.emitter.scaleAxis,
        entry.emitter.polygonX,
        entry.emitter.polygonY,
        entry.emitter.relativeBasePosition,
        entry.emitter.directionalPolygon,
        entry.emitter.sourcePolygon,
        entry.emitter.hideParent,
        entry.emitter.playback.followEmitter,
        entry.emitter.playback.childFollowsEmitter,
        entry.emitter.playback.particles,
      ),
  ]);

  BattleSplAdmissionFailure? advance({BattleSplVector? emitterPosition}) {
    if (isComplete) return _failure;
    if (_tick >= maxTicks) return _fail(BattleSplAdmissionFailure.frameLimit);
    if (emitterPosition != null &&
        (_emitters.length != 1 || !_validVector(emitterPosition))) {
      return _fail(BattleSplAdmissionFailure.arithmetic);
    }
    try {
      for (final entry in _updateOrder) {
        if (_tick < entry.schedule.startTick ||
            entry.emitter.playback.isComplete) {
          continue;
        }
        final result = entry.emitter.step(
          managerFrame: _tick & 1,
          position: emitterPosition ?? entry.schedule.position,
          velocity: entry.schedule.velocity,
        );
        if (result.droppedParents != 0 || result.droppedChildren != 0) {
          return _fail(BattleSplAdmissionFailure.poolExhausted);
        }
      }
      _tick++;
      return null;
    } on FormatException {
      return _fail(BattleSplAdmissionFailure.arithmetic);
    } catch (_) {
      cancel();
      rethrow;
    }
  }

  BattleSplAdmissionFailure _fail(BattleSplAdmissionFailure failure) {
    _failure = failure;
    cancel();
    return failure;
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final entry in _emitters) {
      entry.emitter.cancel();
    }
  }
}

final class _StaticEmitterState {
  const _StaticEmitterState(this.schedule, this.emitter);

  final BattleSplStaticEmitter schedule;
  final BattleSplConfiguredEmitter emitter;
}

bool _validVector(BattleSplVector value) =>
    value.x >= -2147483648 &&
    value.x <= 2147483647 &&
    value.y >= -2147483648 &&
    value.y <= 2147483647 &&
    value.z >= -2147483648 &&
    value.z <= 2147483647;
