import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_spl_particle_pool.dart';

void main() {
  test('shares capacity and returns only a lease’s own particles', () {
    final pool = BattleSplParticlePool(capacity: 2);
    final first = pool.createLease();
    final second = pool.createLease();

    expect(first.acquire(3), 2);
    expect(second.acquire(1), 0);
    expect(pool.inUse, 2);
    expect(() => second.release(1), throwsStateError);
    first.release(1);
    expect(second.acquire(1), 1);
    expect(pool.inUse, 2);

    first.dispose();
    first.dispose();
    expect(pool.inUse, 1);
    expect(() => first.acquire(1), throwsStateError);
    second.dispose();
    expect(pool.inUse, 0);
  });

  test('rejects invalid capacities and allocation counts', () {
    expect(() => BattleSplParticlePool(capacity: 0), throwsFormatException);
    expect(() => BattleSplParticlePool(capacity: 4097), throwsFormatException);
    final lease = BattleSplParticlePool(capacity: 1).createLease();
    expect(() => lease.acquire(-1), throwsArgumentError);
    expect(() => lease.release(-1), throwsArgumentError);
    expect(lease.acquire(0), 0);
    lease.dispose();
  });
}
