import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_emitter_lifecycle.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';

void main() {
  test('shares particle capacity in the order emitters are updated', () {
    final pool = BattleSplParticlePool(capacity: 1);
    final first = _emitter(pool, emitterLifetime: 1);
    final second = _emitter(pool, emitterLifetime: 0);

    expect(first.step(managerFrame: 0).emittedParents, 1);
    expect(second.step(managerFrame: 0).droppedParents, 1);
    expect(pool.inUse, 1);

    expect(first.step(managerFrame: 1).activeParents, 0);
    expect(second.step(managerFrame: 1).emittedParents, 1);
    expect(pool.inUse, 1);

    first.cancel();
    expect(pool.inUse, 1);
    second.cancel();
    second.cancel();
    expect(pool.inUse, 0);
    expect(second.step(managerFrame: 0).complete, isTrue);
  });

  test('cancellation returns parents and children to the shared pool', () {
    final pool = BattleSplParticlePool(capacity: 4);
    final emitter = BattleSplEmitterLifecycle(
      emitterLifetime: 0,
      emissionInterval: 1,
      emissionRate4096: 4096,
      particleLifetime: 3,
      particleLifetimeVariance: 0,
      maxParticles: 4,
      particlePool: pool,
      child: const BattleSplChildTiming(
        emissionCount: 1,
        emissionDelay256: 0,
        emissionInterval: 1,
        lifetime: 2,
      ),
    );

    final frame = emitter.step(managerFrame: 0);
    expect(frame.activeParents, 1);
    expect(frame.activeChildren, 1);
    expect(pool.inUse, 2);
    emitter.cancel();
    expect(pool.inUse, 0);
  });

  test('refuses a pool whose budget differs from the emitter budget', () {
    expect(
      () => BattleSplEmitterLifecycle(
        emitterLifetime: 1,
        emissionInterval: 1,
        emissionRate4096: 4096,
        particleLifetime: 1,
        particleLifetimeVariance: 0,
        maxParticles: 2,
        particlePool: BattleSplParticlePool(capacity: 1),
      ),
      throwsFormatException,
    );
  });
}

BattleSplEmitterLifecycle _emitter(
  BattleSplParticlePool pool, {
  required int emitterLifetime,
}) => BattleSplEmitterLifecycle(
  emitterLifetime: emitterLifetime,
  emissionInterval: 1,
  emissionRate4096: 4096,
  particleLifetime: 1,
  particleLifetimeVariance: 0,
  maxParticles: 1,
  particlePool: pool,
);
