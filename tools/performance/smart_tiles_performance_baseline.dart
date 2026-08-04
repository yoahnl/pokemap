const int smartTilesPerformanceBaselineSchemaVersion = 1;

/// Verifies deterministic identities and portable work budgets for every
/// configured benchmark row. Host timings are checked only when the caller
/// explicitly supplies the baseline target identifier.
List<String> verifySmartTilesPerformanceBaseline({
  required Map<String, Object?> baseline,
  required Iterable<Map<String, Object?>> receipts,
  String? enforceTimingsForTargetId,
}) {
  if (baseline['schemaVersion'] != smartTilesPerformanceBaselineSchemaVersion) {
    throw const FormatException('unsupported Smart Tiles baseline schema');
  }
  final target = _objectMap(baseline['target'], label: 'target');
  final targetId = target['id'];
  if (targetId is! String || targetId.isEmpty) {
    throw const FormatException('baseline target.id must be a string');
  }
  if (enforceTimingsForTargetId != null &&
      enforceTimingsForTargetId != targetId) {
    throw FormatException(
      'timing target mismatch: expected $targetId, '
      'got $enforceTimingsForTargetId',
    );
  }

  final benchmarkConfigs = _objectMap(
    baseline['benchmarks'],
    label: 'benchmarks',
  );
  final receiptsByBenchmark = <String, Map<String, Object?>>{};
  for (final receipt in receipts) {
    final benchmark = receipt['benchmark'];
    if (benchmark is! String || benchmark.isEmpty) {
      throw const FormatException('receipt benchmark must be a string');
    }
    if (!benchmarkConfigs.containsKey(benchmark)) {
      throw FormatException('receipt benchmark $benchmark is not configured');
    }
    if (receiptsByBenchmark.containsKey(benchmark)) {
      throw FormatException('duplicate receipt for benchmark $benchmark');
    }
    receiptsByBenchmark[benchmark] = receipt;
  }

  final violations = <String>[];
  for (final benchmarkEntry in benchmarkConfigs.entries) {
    final benchmark = benchmarkEntry.key;
    final receipt = receiptsByBenchmark[benchmark];
    if (receipt == null) {
      violations.add('missing receipt for benchmark $benchmark');
      continue;
    }
    final config = _objectMap(
      benchmarkEntry.value,
      label: 'benchmarks.$benchmark',
    );
    final rowConfigs = _objectMap(
      config['rows'],
      label: 'benchmarks.$benchmark.rows',
    );
    final rows = _objectList(receipt['results'], label: '$benchmark.results');
    final rowsByExtent = <String, Map<String, Object?>>{};
    for (final row in rows) {
      final extent = row['extent'];
      if (extent is! int || extent <= 0) {
        throw FormatException('$benchmark result extent must be positive');
      }
      if (rowsByExtent.containsKey('$extent')) {
        throw FormatException('$benchmark has duplicate extent $extent');
      }
      rowsByExtent['$extent'] = row;
    }

    for (final rowEntry in rowConfigs.entries) {
      final extent = rowEntry.key;
      final prefix = '$benchmark[$extent]';
      final row = rowsByExtent[extent];
      if (row == null) {
        violations.add('$prefix is missing');
        continue;
      }
      final rowConfig = _objectMap(
        rowEntry.value,
        label: 'benchmarks.$benchmark.rows.$extent',
      );
      final expectedValues = _optionalObjectMap(
        rowConfig['expectedValues'],
        label: '$prefix expectedValues',
      );
      for (final expected in expectedValues.entries) {
        final actual = _valueAtPath(row, expected.key);
        if (actual != expected.value) {
          violations.add(
            '$prefix ${expected.key} expected ${expected.value}, got $actual',
          );
        }
      }
      _checkBudgets(
        row: row,
        rawBudgets: rowConfig['workBudgets'],
        label: '$prefix workBudgets',
        prefix: prefix,
        violations: violations,
      );
      if (enforceTimingsForTargetId != null) {
        _checkBudgets(
          row: row,
          rawBudgets: rowConfig['timingBudgetsUs'],
          label: '$prefix timingBudgetsUs',
          prefix: prefix,
          violations: violations,
        );
      }
    }
  }
  return List<String>.unmodifiable(violations);
}

void _checkBudgets({
  required Map<String, Object?> row,
  required Object? rawBudgets,
  required String label,
  required String prefix,
  required List<String> violations,
}) {
  final budgets = _optionalObjectMap(rawBudgets, label: label);
  for (final budget in budgets.entries) {
    final ceiling = budget.value;
    if (ceiling is! int || ceiling < 0) {
      throw FormatException('$label.${budget.key} must be non-negative');
    }
    final actual = _valueAtPath(row, budget.key);
    if (actual is! int) {
      violations.add('$prefix ${budget.key} is missing or not an integer');
    } else if (actual > ceiling) {
      violations.add('$prefix ${budget.key}=$actual exceeds $ceiling');
    }
  }
}

Object? _valueAtPath(Map<String, Object?> source, String path) {
  Object? value = source;
  for (final segment in path.split('.')) {
    if (value is! Map) return null;
    value = value[segment];
  }
  return value;
}

Map<String, Object?> _objectMap(Object? value, {required String label}) {
  if (value is! Map) throw FormatException('$label must be an object');
  return Map<String, Object?>.from(value);
}

Map<String, Object?> _optionalObjectMap(
  Object? value, {
  required String label,
}) =>
    value == null ? const <String, Object?>{} : _objectMap(value, label: label);

List<Map<String, Object?>> _objectList(Object? value, {required String label}) {
  if (value is! List) throw FormatException('$label must be a list');
  return <Map<String, Object?>>[
    for (var index = 0; index < value.length; index += 1)
      _objectMap(value[index], label: '$label[$index]'),
  ];
}
