import 'dart:developer';
import 'dart:isolate' as isolate;

import 'package:vm_service/utils.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

abstract interface class VmMemoryClient {
  Future<void> resetAllocations();

  Future<VmMemorySnapshot> readAllocations();

  Future<VmMemorySnapshot> collectGarbage();

  Future<void> close();
}

final class VmMemorySnapshot {
  const VmMemorySnapshot({
    required this.allocatedBytes,
    required this.allocationCount,
    required this.heapUsageBytes,
    required this.heapCapacityBytes,
    required this.externalUsageBytes,
    required this.garbageCollectionTimestampMicros,
  });

  final int allocatedBytes;
  final int allocationCount;
  final int heapUsageBytes;
  final int heapCapacityBytes;
  final int externalUsageBytes;
  final int? garbageCollectionTimestampMicros;
}

final class VmMemoryMeasurement {
  const VmMemoryMeasurement({
    required this.allocatedBytes,
    required this.allocationCount,
    required this.heapBeforeGcBytes,
    required this.heapAfterGcBytes,
    required this.heapCapacityAfterGcBytes,
    required this.externalAfterGcBytes,
    required this.garbageCollectionTimestampMicros,
  });

  final int allocatedBytes;
  final int allocationCount;
  final int heapBeforeGcBytes;
  final int heapAfterGcBytes;
  final int heapCapacityAfterGcBytes;
  final int externalAfterGcBytes;
  final int? garbageCollectionTimestampMicros;

  Map<String, Object?> toJson() => <String, Object?>{
    'allocatedBytes': allocatedBytes,
    'allocationCount': allocationCount,
    'heapBeforeGcBytes': heapBeforeGcBytes,
    'heapAfterGcBytes': heapAfterGcBytes,
    'heapCapacityAfterGcBytes': heapCapacityAfterGcBytes,
    'externalAfterGcBytes': externalAfterGcBytes,
    'forcedGarbageCollection': garbageCollectionTimestampMicros != null,
    'garbageCollectionTimestampMicros': garbageCollectionTimestampMicros,
  };
}

final class VmMemoryProbe {
  const VmMemoryProbe.withClient(this._client);

  final VmMemoryClient _client;

  static Future<VmMemoryProbe> connect() async {
    final serviceInfo = await Service.getInfo();
    final serviceUri = serviceInfo.serverUri;
    final isolateId = Service.getIsolateId(isolate.Isolate.current);
    if (serviceUri == null || isolateId == null) {
      throw StateError('The Dart VM service is unavailable.');
    }
    final websocketUri = convertToWebSocketUrl(serviceProtocolUrl: serviceUri);
    final service = await vmServiceConnectUri(websocketUri.toString());
    return VmMemoryProbe.withClient(
      _VmServiceMemoryClient(service: service, isolateId: isolateId),
    );
  }

  Future<VmMemoryMeasurement> measure(Future<void> Function() action) async {
    await _client.resetAllocations();
    await action();
    final measured = await _client.readAllocations();
    final collected = await _client.collectGarbage();
    return VmMemoryMeasurement(
      allocatedBytes: measured.allocatedBytes,
      allocationCount: measured.allocationCount,
      heapBeforeGcBytes: measured.heapUsageBytes,
      heapAfterGcBytes: collected.heapUsageBytes,
      heapCapacityAfterGcBytes: collected.heapCapacityBytes,
      externalAfterGcBytes: collected.externalUsageBytes,
      garbageCollectionTimestampMicros:
          collected.garbageCollectionTimestampMicros,
    );
  }

  Future<void> close() => _client.close();
}

final class _VmServiceMemoryClient implements VmMemoryClient {
  const _VmServiceMemoryClient({
    required VmService service,
    required String isolateId,
  }) : _service = service,
       _isolateId = isolateId;

  final VmService _service;
  final String _isolateId;

  @override
  Future<void> resetAllocations() async {
    await _service.getAllocationProfile(_isolateId, reset: true);
  }

  @override
  Future<VmMemorySnapshot> readAllocations() async {
    return _snapshot(await _service.getAllocationProfile(_isolateId));
  }

  @override
  Future<VmMemorySnapshot> collectGarbage() async {
    return _snapshot(await _service.getAllocationProfile(_isolateId, gc: true));
  }

  @override
  Future<void> close() => _service.dispose();
}

VmMemorySnapshot _snapshot(AllocationProfile profile) {
  final members = profile.members ?? const <ClassHeapStats>[];
  final memory = profile.memoryUsage;
  return VmMemorySnapshot(
    allocatedBytes: members.fold<int>(
      0,
      (total, member) => total + (member.accumulatedSize ?? 0),
    ),
    allocationCount: members.fold<int>(
      0,
      (total, member) => total + (member.instancesAccumulated ?? 0),
    ),
    heapUsageBytes: memory?.heapUsage ?? 0,
    heapCapacityBytes: memory?.heapCapacity ?? 0,
    externalUsageBytes: memory?.externalUsage ?? 0,
    garbageCollectionTimestampMicros: profile.dateLastServiceGC,
  );
}
