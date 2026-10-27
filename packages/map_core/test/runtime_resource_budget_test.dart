import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('tall atlas admission retains both default 64 MiB limits', () {
    const profile = RuntimeResourceProfile();
    final allocation = runtimeTilesetImageAllocation(
      encodedLength: 600000,
      width: 256,
      height: 28160,
    );
    expect(allocation.residentBytes, 256 * 28160 * 4);
    expect(
      allocation.residentBytes,
      lessThanOrEqualTo(profile.maximumResidentBytes),
    );
    expect(
      allocation.transientBytes,
      lessThanOrEqualTo(profile.maximumTransientBytes),
    );
    expect(profile.maximumResidentBytes, 64 * 1024 * 1024);
    expect(profile.maximumTransientBytes, 64 * 1024 * 1024);
  });

  test(
    'tall atlas admission respects a stricter resident or transient profile',
    () {
      for (final profile in [
        const RuntimeResourceProfile(maximumResidentBytes: 16 * 1024 * 1024),
        const RuntimeResourceProfile(maximumTransientBytes: 32 * 1024 * 1024),
      ]) {
        expect(
          () => runtimeTilesetImageAllocation(
            encodedLength: 600000,
            width: 256,
            height: 28160,
            profile: profile,
          ),
          throwsA(isA<RuntimeResourceAdmissionException>()),
        );
      }
    },
  );

  test(
    'a nonchunked transparency transform retains its full scratch admission',
    () {
      const profile = RuntimeResourceProfile(
        maximumTransientBytes: 3 * 32 * 32 * 4 + 200,
      );
      expect(
        runtimeTilesetImageAllocation(
          encodedLength: 100,
          width: 32,
          height: 32,
          profile: profile,
        ),
        isNotNull,
      );
      expect(
        () => runtimeTilesetImageAllocation(
          encodedLength: 100,
          width: 32,
          height: 32,
          transformRgba: true,
          profile: profile,
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
    },
  );

  test(
    'high bit depth chunked PNGs reserve their CPU normalization buffer',
    () {
      const width = 16;
      const height = 5000;
      final low = runtimeTilesetImageAllocation(
        encodedLength: 100,
        width: width,
        height: height,
      );
      final high = runtimeTilesetImageAllocation(
        encodedLength: 100,
        width: width,
        height: height,
        sourceBitDepth: 16,
      );
      expect(high.residentBytes, low.residentBytes);
      expect(high.transientBytes - low.transientBytes, width * height * 4 * 2);
    },
  );

  test('encoded scratch cannot overflow a tileset admission', () {
    expect(
      () => runtimeTilesetImageAllocation(
        encodedLength: 0x7fffffffffffffff,
        width: 1,
        height: 1,
        profile: const RuntimeResourceProfile(
          maximumEncodedBytes: 0x7fffffffffffffff,
          maximumTransientBytes: 0x7fffffffffffffff,
        ),
      ),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
  });

  test('RGBA dimensions are bounded before integer multiplication', () {
    expect(runtimeImageRgbaByteLength(2, 3, maximumBytes: 24), 24);
    for (final dimensions in [
      (1 << 62, 4),
      (4, 1 << 62),
      (2, 3),
      (0, 1),
      (-1, 1),
    ]) {
      expect(
        () => runtimeImageRgbaByteLength(
          dimensions.$1,
          dimensions.$2,
          maximumBytes: 23,
        ),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
    }
  });

  test('resident and transient sums cannot wrap integer admission', () async {
    final controller = RuntimeResourceBudget(
      profile: const RuntimeResourceProfile(
        maximumResidentBytes: 0x7fffffffffffffff,
        maximumTransientBytes: 0x7fffffffffffffff,
      ),
    );
    final first = await controller.acquire(
      residentBytes: 1 << 62,
      transientBytes: 1 << 62,
    );
    await expectLater(
      controller.acquire(residentBytes: 1 << 62),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    final queued = controller.acquire(transientBytes: 1 << 62);
    expect(controller.residentBytes, 1 << 62);
    expect(controller.transientBytes, 1 << 62);
    expect(controller.peakBytes, 0x7fffffffffffffff);
    expect(controller.pendingDecodes, 1);
    first.commit();
    final next = await queued;
    expect(controller.residentBytes, 1 << 62);
    expect(controller.transientBytes, 1 << 62);
    expect(controller.peakBytes, 0x7fffffffffffffff);
    next.release();
    first.release();
    expect(controller.residentBytes, 0);
    expect(controller.transientBytes, 0);
    controller.dispose();
  });

  RuntimeResourceBudget budget() => RuntimeResourceBudget(
    profile: const RuntimeResourceProfile(
      maximumResidentBytes: 100,
      maximumTransientBytes: 80,
      maximumConcurrentDecodes: 1,
      maximumEncodedBytes: 40,
    ),
  );

  RuntimeResourceBudget concurrentBudget() => RuntimeResourceBudget(
    profile: const RuntimeResourceProfile(
      maximumResidentBytes: 100,
      maximumTransientBytes: 80,
      maximumConcurrentDecodes: 2,
    ),
  );

  test('mandatory admission evicts optional committed reservations', () async {
    final controller = budget();
    addTearDown(controller.dispose);
    var evicted = 0;
    final optional = await controller.acquire(residentBytes: 80);
    optional.commit();
    optional.retainOptionally(() => evicted++);
    final required = await controller.acquire(residentBytes: 100);
    expect(evicted, 1);
    expect(controller.residentBytes, 100);
    required.release();
    expect(controller.residentBytes, 0);
  });

  test(
    'resize reclaims optional memory before rejecting any consumer',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      var evicted = false;
      optional.retainOptionally(() => evicted = true);
      final mandatory = await controller.acquire(residentBytes: 8);
      mandatory.resize(residentBytes: 100, transientBytes: 0);
      expect(evicted, isTrue);
      expect(controller.residentBytes, 100);
      mandatory.release();
    },
  );

  test('impossible requests preserve optional resident resources', () async {
    final controller = budget();
    addTearDown(controller.dispose);
    final optional = await controller.acquire(residentBytes: 80);
    optional.commit();
    optional.retainOptionally(() => fail('Impossible request evicted memory'));
    await expectLater(
      controller.acquire(residentBytes: 101),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 80);
  });

  test(
    'optional eviction during acquire keeps the initiating request first',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      Future<RuntimeResourceReservation>? callbackAdmission;
      optional.retainOptionally(() {
        callbackAdmission = controller.acquire(residentBytes: 50);
      });
      final mandatory = await controller.acquire(residentBytes: 100);
      await expectLater(
        callbackAdmission!,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(controller.residentBytes, 100);
      expect(controller.activeDecodes, 1);
      mandatory.release();
    },
  );

  test(
    'failed resize preserves resident accounting before callback admission',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 70);
      optional.commit();
      Future<RuntimeResourceReservation>? callbackAdmission;
      optional.retainOptionally(() {
        callbackAdmission = controller.acquire(residentBytes: 81);
      });
      final mandatory = await controller.acquire(residentBytes: 20);
      final blocker = await controller.acquire(transientBytes: 20);
      expect(
        () => mandatory.resize(residentBytes: 100, transientBytes: 70),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      blocker.release();
      await expectLater(
        callbackAdmission!,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(controller.residentBytes, 20);
      expect(controller.activeDecodes, 1);
      mandatory.release();
    },
  );

  test('impossible transient requests preserve optional resources', () async {
    final controller = budget();
    addTearDown(controller.dispose);
    final optional = await controller.acquire(residentBytes: 80);
    optional.commit();
    optional.retainOptionally(() => fail('Impossible request evicted memory'));
    await expectLater(
      controller.acquire(residentBytes: 90, transientBytes: 81),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 80);
  });

  test(
    'failed optional callbacks keep bytes counted and try other resources',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final failed = await controller.acquire(residentBytes: 50);
      failed.commit();
      failed.retainOptionally(() => throw StateError('Cache cleanup failed'));
      final optional = await controller.acquire(residentBytes: 40);
      optional.commit();
      optional.retainOptionally(() {});
      final mandatory = await controller.acquire(residentBytes: 50);
      expect(controller.residentBytes, 100);
      expect(failed.residentBytes, 50);
      mandatory.release();
    },
  );

  test('eviction disposal rejects the initiating admission', () async {
    final controller = concurrentBudget();
    final optional = await controller.acquire(residentBytes: 80);
    optional.commit();
    optional.retainOptionally(controller.dispose);
    await expectLater(
      controller.acquire(residentBytes: 100),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 0);
    expect(controller.activeDecodes, 0);
    expect(controller.pendingDecodes, 0);
  });

  test(
    'eviction disposal rejects the initiating resize without residual bytes',
    () async {
      final controller = concurrentBudget();
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      final mandatory = await controller.acquire(residentBytes: 20);
      optional.retainOptionally(controller.dispose);
      expect(
        () => mandatory.resize(residentBytes: 100, transientBytes: 0),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(controller.residentBytes, 0);
      expect(controller.transientBytes, 0);
      expect(controller.activeDecodes, 0);
    },
  );

  test('eviction cancellation rejects the initiating admission', () async {
    final controller = concurrentBudget();
    addTearDown(controller.dispose);
    var current = true;
    final optional = await controller.acquire(residentBytes: 80);
    optional.commit();
    optional.retainOptionally(() => current = false);
    await expectLater(
      controller.acquire(residentBytes: 100, isCurrent: () => current),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 0);
    expect(controller.activeDecodes, 0);
  });

  test(
    'resize survives a callback releasing its initiating reservation',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      final mandatory = await controller.acquire(residentBytes: 20);
      optional.retainOptionally(mandatory.release);
      expect(
        () => mandatory.resize(residentBytes: 100, transientBytes: 0),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(controller.residentBytes, 0);
      expect(controller.activeDecodes, 0);
    },
  );

  test(
    'eviction callbacks cannot resize another reservation recursively',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      final mandatory = await controller.acquire(residentBytes: 20);
      optional.retainOptionally(() {
        expect(
          () => mandatory.resize(residentBytes: 30, transientBytes: 0),
          throwsStateError,
        );
      });
      mandatory.resize(residentBytes: 100, transientBytes: 0);
      expect(controller.residentBytes, 100);
      mandatory.release();
    },
  );

  test('promoted required memory cannot be evicted', () async {
    final controller = budget();
    addTearDown(controller.dispose);
    final lease = await controller.acquire(residentBytes: 80);
    lease.commit();
    lease.retainOptionally(() => fail('Required lease evicted'));
    lease.retainRequired();
    await expectLater(
      controller.acquire(residentBytes: 30),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 80);
  });

  test(
    'eviction callbacks cannot recursively drain or expose resize headroom',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final optional = await controller.acquire(residentBytes: 80);
      optional.commit();
      Future<RuntimeResourceReservation>? callbackAdmission;
      optional.retainOptionally(() {
        optional.release();
        callbackAdmission = controller.acquire(residentBytes: 50);
      });
      final mandatory = await controller.acquire(residentBytes: 8);
      mandatory.resize(residentBytes: 100, transientBytes: 0);
      await expectLater(
        callbackAdmission!,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      expect(controller.residentBytes, 100);
      expect(controller.activeDecodes, 1);
      expect(controller.pendingDecodes, 0);
      mandatory.release();
    },
  );

  test('admission checks exact boundaries before work starts', () async {
    final controller = budget();
    final lease = await controller.acquire(
      residentBytes: 100,
      transientBytes: 80,
    );
    expect(controller.residentBytes, 100);
    expect(controller.transientBytes, 80);
    lease.commit();
    expect(controller.activeDecodes, 0);
    expect(controller.transientBytes, 0);
    await expectLater(
      controller.acquire(residentBytes: 1),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    lease.release();
    expect(controller.residentBytes, 0);
    controller.dispose();
  });

  test('concurrent decode slots queue without starting extra work', () async {
    final controller = budget();
    final first = await controller.acquire(transientBytes: 20);
    var started = false;
    final second = controller.acquire(transientBytes: 30).then((value) {
      started = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(started, isFalse);
    expect(controller.activeDecodes, 1);
    first.release();
    final next = await second;
    expect(controller.transientBytes, 30);
    next.release();
    expect(controller.activeDecodes, 0);
    controller.dispose();
  });

  test('resize rejects before adding decoded allocations', () async {
    final controller = budget();
    final lease = await controller.acquire(transientBytes: 20);
    expect(
      () => lease.resize(residentBytes: 101, transientBytes: 20),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 0);
    lease.resize(residentBytes: 100, transientBytes: 80);
    lease.release();
    expect(controller.residentBytes + controller.transientBytes, 0);
    controller.dispose();
  });

  for (final commit in [true, false]) {
    test(
      'transient pressure queues until the active decode ${commit ? 'commits' : 'releases'}',
      () async {
        final controller = concurrentBudget();
        addTearDown(controller.dispose);
        final held = await controller.acquire(
          residentBytes: 10,
          transientBytes: 70,
        );
        RuntimeResourceReservation? next;
        Object? error;
        final queued = controller
            .acquire(transientBytes: 20)
            .then<void>(
              (lease) {
                next = lease;
              },
              onError: (Object failure) {
                error = failure;
              },
            );
        await Future<void>.delayed(Duration.zero);
        expect(error, isNull);
        expect(next, isNull);
        expect(controller.pendingDecodes, 1);
        expect(controller.activeDecodes, 1);
        expect(controller.transientBytes, 70);
        if (commit) {
          held.commit();
        } else {
          held.release();
        }
        await queued;
        expect(error, isNull);
        expect(next, isNotNull);
        expect(controller.transientBytes, 20);
        expect(controller.pendingDecodes, 0);
        expect(controller.activeDecodes, 1);
        expect(controller.peakConcurrentDecodes, 1);
        next!.release();
        held.release();
        expect(controller.transientBytes, 0);
        expect(controller.residentBytes, 0);
        expect(controller.activeDecodes, 0);
      },
    );
  }

  test(
    'an individually oversized transient request still fails immediately',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final held = await controller.acquire(transientBytes: 70);
      await expectLater(
        controller.acquire(transientBytes: 81),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (error) => error.reason,
            'reason',
            'transient_bytes',
          ),
        ),
      );
      expect(controller.pendingDecodes, 0);
      expect(controller.transientBytes, 70);
      expect(controller.activeDecodes, 1);
      held.release();
    },
  );

  test(
    'resident overflow still fails before waiting for transient capacity',
    () async {
      final controller = concurrentBudget();
      addTearDown(controller.dispose);
      final held = await controller.acquire(
        residentBytes: 90,
        transientBytes: 70,
      );
      await expectLater(
        controller.acquire(residentBytes: 11, transientBytes: 20),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (error) => error.reason,
            'reason',
            'resident_bytes',
          ),
        ),
      );
      expect(controller.pendingDecodes, 0);
      expect(controller.residentBytes, 90);
      expect(controller.transientBytes, 70);
      held.release();
    },
  );

  test('negative demand is rejected during transient pressure', () async {
    final controller = concurrentBudget();
    addTearDown(controller.dispose);
    final held = await controller.acquire(transientBytes: 70);
    await expectLater(
      controller.acquire(residentBytes: -1, transientBytes: 20),
      throwsArgumentError,
    );
    expect(controller.pendingDecodes, 0);
    expect(controller.residentBytes, 0);
    expect(controller.transientBytes, 70);
    held.release();
  });

  test('transient queued demand keeps priority over prefetch', () async {
    final controller = concurrentBudget();
    addTearDown(controller.dispose);
    final held = await controller.acquire(transientBytes: 70);
    final order = <String>[];
    final prefetch = controller
        .acquire(transientBytes: 20, prefetch: true)
        .then((lease) {
          order.add('prefetch');
          return lease;
        });
    final demand = controller.acquire(transientBytes: 10).then((lease) {
      order.add('demand');
      return lease;
    });
    final first = await demand;
    expect(order, ['demand']);
    expect(controller.transientBytes, 80);
    expect(controller.pendingDecodes, 1);
    first.release();
    expect(controller.pendingDecodes, 1);
    held.commit();
    final last = await prefetch;
    expect(order, ['demand', 'prefetch']);
    expect(controller.transientBytes, 20);
    last.release();
    held.release();
  });

  test('cancellation rejects demand queued by transient pressure', () async {
    final controller = concurrentBudget();
    addTearDown(controller.dispose);
    final held = await controller.acquire(transientBytes: 70);
    var current = true;
    final cancelled = expectLater(
      controller.acquire(transientBytes: 20, isCurrent: () => current),
      throwsA(
        isA<RuntimeResourceAdmissionException>().having(
          (error) => error.reason,
          'reason',
          'cancelled',
        ),
      ),
    );
    current = false;
    held.commit();
    await cancelled;
    expect(controller.pendingDecodes, 0);
    expect(controller.transientBytes, 0);
    expect(controller.activeDecodes, 0);
    held.release();
  });

  test(
    'disposal rejects transient queued demand and frees active capacity',
    () async {
      final controller = concurrentBudget();
      final held = await controller.acquire(
        residentBytes: 10,
        transientBytes: 70,
      );
      final closed = expectLater(
        controller.acquire(transientBytes: 20),
        throwsA(
          isA<RuntimeResourceAdmissionException>().having(
            (error) => error.reason,
            'reason',
            'session_closed',
          ),
        ),
      );
      controller.dispose();
      await closed;
      expect(controller.pendingDecodes, 0);
      expect(controller.transientBytes, 0);
      expect(controller.residentBytes, 0);
      expect(controller.activeDecodes, 0);
      expect(
        () => held.commit(),
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      held.release();
    },
  );

  test(
    'demand wins over queued prefetch and cancellation is observed',
    () async {
      final controller = budget();
      final held = await controller.acquire();
      var current = true;
      final cancelled = controller.acquire(
        prefetch: true,
        isCurrent: () => current,
      );
      final error = expectLater(
        cancelled,
        throwsA(isA<RuntimeResourceAdmissionException>()),
      );
      final demand = controller.acquire();
      current = false;
      held.release();
      final next = await demand;
      next.release();
      await error;
      controller.dispose();
    },
  );

  test('disposal rejects queued and active late publication', () async {
    final controller = budget();
    final held = await controller.acquire(residentBytes: 10);
    final queued = expectLater(
      controller.acquire(),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    controller.dispose();
    await queued;
    expect(
      () => held.commit(),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    held.release();
    expect(controller.residentBytes, 0);
    expect(controller.transientBytes, 0);
  });
}
