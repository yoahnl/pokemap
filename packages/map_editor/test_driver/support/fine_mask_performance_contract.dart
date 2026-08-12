void validateFineMaskPerformanceReceipt(
  Map<String, dynamic> data, {
  required bool requireProvenance,
}) {
  if (data['schemaVersion'] != 2 ||
      data['target'] != 'integration_test/editor_fine_mask_journey_test.dart') {
    throw const FormatException('Invalid fine-mask performance receipt.');
  }
  if (requireProvenance) _validateProvenance(data);
  final results = data['results'];
  if (data['pointerMovesPerExtent'] != 30 || results is! List) {
    throw const FormatException(
      'Fine-mask journey must declare 30 pointer moves per extent.',
    );
  }
  final rows = results.whereType<Map>().toList(growable: false);
  const expectedExtents = <int>{64, 256, 512, 1024};
  final extents = rows.map((row) => row['extent']).toSet();
  if (rows.length != expectedExtents.length ||
      extents.length != expectedExtents.length ||
      !extents.containsAll(expectedExtents)) {
    throw const FormatException(
      'Fine-mask journey must cover 64, 256, 512 and 1024 pixels.',
    );
  }
  for (final row in rows) {
    if (row['pointerMoveCount'] != 30) {
      throw const FormatException(
        'Fine-mask rows must include exactly 30 pointer moves.',
      );
    }
    final move = row['moveInstrumentation'];
    final commit = row['commitInstrumentation'];
    final extent = row['extentInstrumentation'];
    if (move is! Map || commit is! Map || extent is! Map) {
      throw const FormatException(
        'Fine-mask rows must include move, commit and extent telemetry.',
      );
    }
    _validateNamedSpan(move, 'mask.pointer_move', expectedCount: 30);
    _validateNamedSpan(commit, 'mask.commit', expectedCount: 1);
    _validateNamedSpan(extent, 'mask.readback', expectedCount: 1);
    _validateNamedSpan(extent, 'mask.build', minimumCount: 1);
    _validateNamedSpan(extent, 'mask.paint', minimumCount: 1);
    final moveCounters = move['counters'];
    if (moveCounters is! Map ||
        moveCounters.values.any((value) => value != 0)) {
      throw const FormatException(
        'Fine-mask pointer moves must perform zero filesystem, JSON and base64 work.',
      );
    }
    final commitCounters = commit['counters'];
    if (commitCounters is! Map ||
        commitCounters['base64.encode'] != 3 ||
        commitCounters['base64.decode'] != 1) {
      throw const FormatException(
        'Fine-mask commit must encode three masks and derive cells once.',
      );
    }
    final frameMetrics = row['frameMetrics'];
    final frameSamples = frameMetrics is Map ? frameMetrics['samplesUs'] : null;
    if (frameMetrics is! Map || frameSamples is! List || frameSamples.isEmpty) {
      throw const FormatException(
        'Fine-mask rows must include raw Flutter frame timings.',
      );
    }
    _validateSampleRow(frameMetrics, expectedSampleCount: frameSamples.length);
  }
  _validateMemory(data);
  _validateSoak(data);
}

void _validateNamedSpan(
  Map instrumentation,
  String name, {
  int? expectedCount,
  int? minimumCount,
}) {
  final spans = instrumentation['spans'];
  final metrics = spans is Map ? spans[name] : null;
  final count = metrics is Map ? metrics['count'] : null;
  if (metrics is! Map ||
      count is! int ||
      (expectedCount != null && count != expectedCount) ||
      (minimumCount != null && count < minimumCount)) {
    throw FormatException('Fine-mask journey has invalid $name samples.');
  }
  _validateSampleRow(metrics, expectedSampleCount: count);
}

void _validateSampleRow(Map row, {required int expectedSampleCount}) {
  final samples = row['samplesUs'];
  if (samples is! List ||
      samples.length != expectedSampleCount ||
      samples.any((sample) => sample is! int || sample < 0)) {
    throw const FormatException(
      'Performance rows must contain the declared non-negative raw samples.',
    );
  }
  final sorted = samples.cast<int>().toList(growable: false)..sort();
  if (row['p50Us'] != _percentile(sorted, 0.50) ||
      row['p95Us'] != _percentile(sorted, 0.95) ||
      row['p99Us'] != _percentile(sorted, 0.99) ||
      row['maxUs'] != sorted.last) {
    throw const FormatException(
      'Performance row percentiles must match its raw samples.',
    );
  }
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

void _validateMemory(Map<String, dynamic> data) {
  final memory = data['memory'];
  if (memory is! Map) {
    throw const FormatException(
      'Fine-mask journey must include VM allocation and post-GC memory evidence.',
    );
  }
  _validateMemoryValues(memory);
}

void _validateSoak(Map<String, dynamic> data) {
  final memory = data['soakMemory'];
  final budget = data['soakHeapGrowthBudgetBytes'];
  if (data['soakCycles'] != 3 ||
      memory is! Map ||
      budget is! int ||
      budget <= 0) {
    throw const FormatException(
      'Fine-mask journey must include three repeated-open memory cycles.',
    );
  }
  _validateMemoryValues(memory);
  final baseline = data['memory']! as Map;
  final stable =
      (memory['heapAfterGcBytes']! as int) -
          (baseline['heapAfterGcBytes']! as int) <=
      budget;
  if (!stable || data['soakHeapStable'] != stable) {
    throw const FormatException(
      'Fine-mask repeated-open heap must remain inside its declared budget.',
    );
  }
}

void _validateMemoryValues(Map memory) {
  if (memory['allocatedBytes'] is! int ||
      memory['allocationCount'] is! int ||
      memory['heapBeforeGcBytes'] is! int ||
      memory['heapAfterGcBytes'] is! int ||
      memory['heapCapacityAfterGcBytes'] is! int ||
      memory['externalAfterGcBytes'] is! int ||
      memory['forcedGarbageCollection'] != true ||
      memory['garbageCollectionTimestampMicros'] is! int) {
    throw const FormatException(
      'Fine-mask journey must include VM allocation and post-GC memory evidence.',
    );
  }
}

void _validateProvenance(Map<String, dynamic> data) {
  final commit = data['commit'];
  final toolchain = data['toolchain'];
  final flutter = toolchain is Map ? toolchain['flutter'] : null;
  if (data['executionMode'] != 'flutter-profile' ||
      data['treeState'] != 'clean' ||
      commit is! String ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(commit) ||
      data['sdk'] is! String ||
      toolchain is! Map ||
      toolchain['dart'] is! String ||
      flutter is! Map ||
      flutter['frameworkRevision'] is! String ||
      toolchain['flame'] is! String) {
    throw const FormatException(
      'Fine-mask receipt must come from a clean profile run with complete provenance.',
    );
  }
}
