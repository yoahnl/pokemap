import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/vm_memory_probe.dart';

void main() {
  test('measures allocations and heap after a forced VM collection', () async {
    final client = _FakeVmMemoryClient(
      measured: const VmMemorySnapshot(
        allocatedBytes: 2048,
        allocationCount: 12,
        heapUsageBytes: 4096,
        heapCapacityBytes: 8192,
        externalUsageBytes: 64,
        garbageCollectionTimestampMicros: null,
      ),
      collected: const VmMemorySnapshot(
        allocatedBytes: 2304,
        allocationCount: 14,
        heapUsageBytes: 1024,
        heapCapacityBytes: 8192,
        externalUsageBytes: 32,
        garbageCollectionTimestampMicros: 99,
      ),
    );
    final probe = VmMemoryProbe.withClient(client);
    var actionRan = false;

    final measurement = await probe.measure(() async {
      actionRan = true;
    });

    expect(actionRan, isTrue);
    expect(client.resetCount, 1);
    expect(client.readCount, 1);
    expect(client.collectCount, 1);
    expect(measurement.toJson(), <String, Object?>{
      'allocatedBytes': 2048,
      'allocationCount': 12,
      'heapBeforeGcBytes': 4096,
      'heapAfterGcBytes': 1024,
      'heapCapacityAfterGcBytes': 8192,
      'externalAfterGcBytes': 32,
      'forcedGarbageCollection': true,
      'garbageCollectionTimestampMicros': 99,
    });

    await probe.close();
    expect(client.closeCount, 1);
  });
}

final class _FakeVmMemoryClient implements VmMemoryClient {
  _FakeVmMemoryClient({required this.measured, required this.collected});

  final VmMemorySnapshot measured;
  final VmMemorySnapshot collected;
  var resetCount = 0;
  var readCount = 0;
  var collectCount = 0;
  var closeCount = 0;

  @override
  Future<void> resetAllocations() async {
    resetCount++;
  }

  @override
  Future<VmMemorySnapshot> readAllocations() async {
    readCount++;
    return measured;
  }

  @override
  Future<VmMemorySnapshot> collectGarbage() async {
    collectCount++;
    return collected;
  }

  @override
  Future<void> close() async {
    closeCount++;
  }
}
