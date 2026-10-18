import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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
    await expectLater(
      controller.acquire(transientBytes: 1 << 62),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    expect(controller.residentBytes, 1 << 62);
    expect(controller.transientBytes, 1 << 62);
    expect(controller.peakBytes, 0x7fffffffffffffff);
    first.release();
  });

  RuntimeResourceBudget budget() => RuntimeResourceBudget(
    profile: const RuntimeResourceProfile(
      maximumResidentBytes: 100,
      maximumTransientBytes: 80,
      maximumConcurrentDecodes: 1,
      maximumEncodedBytes: 40,
    ),
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
