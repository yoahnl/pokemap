import 'dart:async';

import 'package:map_core/src/runtime/runtime_prefetch_queue.dart';
import 'package:test/test.dart';

void main() {
  test('prefetch is bounded and invalidation drops queued jobs', () async {
    final queue = RuntimePrefetchQueue(maximumQueued: 1);
    final gate = Completer<void>();
    final started = <int>[];
    var current = true;
    final first = queue.schedule((isCurrent) async {
      started.add(1);
      await gate.future;
      current = isCurrent();
    });
    final second = queue.schedule((_) async => started.add(2));
    expect(queue.schedule((_) async => started.add(3)), isNull);
    queue.invalidate();
    await second;
    gate.complete();
    await first;
    expect(started, [1]);
    expect(current, isFalse);
    await queue.schedule((_) async => started.add(4));
    expect(started, [1, 4]);
    queue.dispose();
    expect(queue.schedule((_) async {}), isNull);
  });
}
