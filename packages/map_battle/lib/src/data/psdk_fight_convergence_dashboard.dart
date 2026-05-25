import 'generated/psdk_item_effect_manifest.dart';

String renderPsdkFightConvergenceDashboard(
  Map<String, Object?> auditJson, {
  DateTime? generatedAt,
}) {
  final attacks = _map(auditJson['attacks']);
  final methods = _map(auditJson['methods']);
  final effects = _map(auditJson['effects']);
  final runtimeBridge = _map(auditJson['runtimeBridge']);

  final totalAttacks = _int(attacks['totalAttacks']);
  final strictAttacks = _int(attacks['fait']);
  final partialAttacks = _int(attacks['partiel']);
  final totalMethods = _int(methods['totalMethods']);
  final methodStatus = _map(methods['byStatus']);
  final portedMethods = _int(methodStatus['ported']);
  final partialMethods = _int(methodStatus['partial']);
  final totalEffects = _int(effects['totalEffects']);
  final effectStatus = _map(effects['byStatus']);
  final portedEffects = _int(effectStatus['ported']);
  final partialEffects = _int(effectStatus['partial']);
  final missingEffects = _int(effectStatus['missing']);
  final runtimeStatus = _string(runtimeBridge['status']);

  final buffer = StringBuffer()
    ..writeln('# PSDK Fight Convergence Dashboard')
    ..writeln()
    ..writeln(
        'Generated: ${(generatedAt ?? DateTime.now().toUtc()).toIso8601String()}')
    ..writeln()
    ..writeln('## Final Gate Axes')
    ..writeln()
    ..writeln('| Axis | Complete | Percent | Remaining |')
    ..writeln('| --- | ---: | ---: | ---: |')
    ..writeln(
      '| Attacks | $strictAttacks / $totalAttacks | '
      '${_percent(strictAttacks, totalAttacks)} | $partialAttacks |',
    )
    ..writeln(
      '| Methods | $portedMethods / $totalMethods | '
      '${_percent(portedMethods, totalMethods)} | $partialMethods |',
    )
    ..writeln(
      '| Effects | $portedEffects / $totalEffects | '
      '${_percent(portedEffects, totalEffects)} | '
      '${partialEffects + missingEffects} |',
    )
    ..writeln()
    ..writeln('## Effects By Family')
    ..writeln()
    ..writeln('| Family | Ported | Partial | Missing | Remaining |')
    ..writeln('| --- | ---: | ---: | ---: | ---: |');

  final families = _map(effects['byFamilyAndStatus']);
  final familyNames = families.keys.toList()..sort();
  var highestRemainingFamily = '';
  var highestRemaining = -1;
  for (final family in familyNames) {
    final status = _map(families[family]);
    final ported = _int(status['ported']);
    final partial = _int(status['partial']);
    final missing = _int(status['missing']);
    final remaining = partial + missing;
    if (remaining > highestRemaining) {
      highestRemainingFamily = family;
      highestRemaining = remaining;
    }
    buffer.writeln(
      '| $family | $ported | $partial | $missing | $remaining |',
    );
  }
  _writeMethodBacklog(buffer, methods);
  _writeAbilityEffectBacklog(buffer, effects);
  _writeItemEffectBacklog(buffer, effects);

  buffer
    ..writeln()
    ..writeln('## Runtime Bridge')
    ..writeln()
    ..writeln('| Metric | Value |')
    ..writeln('| --- | --- |')
    ..writeln('| Status | `$runtimeStatus` |')
    ..writeln('| Reason | ${_string(runtimeBridge['reason'])} |')
    ..writeln()
    ..writeln('## Next Recommendation')
    ..writeln();

  if (runtimeStatus == 'not_measured') {
    buffer.writeln('Next recommended lot: measure runtime bridge diagnostics.');
  } else if (highestRemainingFamily.isNotEmpty && highestRemaining > 0) {
    buffer.writeln(
      'Next recommended lot: close effect family `$highestRemainingFamily` '
      '($highestRemaining remaining effects).',
    );
  } else if (partialMethods > 0) {
    buffer.writeln('Next recommended lot: close partial move methods.');
  } else if (partialAttacks > 0) {
    buffer.writeln('Next recommended lot: close partial attack entries.');
  } else {
    buffer.writeln('Next recommended lot: run final acceptance gate.');
  }

  return buffer.toString();
}

void _writeMethodBacklog(
  StringBuffer buffer,
  Map<String, Object?> methods,
) {
  final batches = _list(methods['backlogBatches'])
      .map(_map)
      .where((batch) => _int(batch['count']) > 0)
      .toList(growable: false);
  if (batches.isEmpty) {
    return;
  }

  buffer
    ..writeln()
    ..writeln('## Method Backlog')
    ..writeln()
    ..writeln('| Batch | Partial methods | Methods |')
    ..writeln('| --- | ---: | --- |');
  for (final batch in batches) {
    final methods = _stringList(batch['methods']);
    buffer.writeln(
      '| ${_string(batch['label'])} | ${_int(batch['count'])} | '
      '${methods.map((method) => '`$method`').join(', ')} |',
    );
  }
}

void _writeItemEffectBacklog(
  StringBuffer buffer,
  Map<String, Object?> effects,
) {
  final entries = _list(effects['entries']);
  final counts = <PsdkItemEffectBatch, _BacklogCounts>{
    for (final batch in PsdkItemEffectBatch.values) batch: _BacklogCounts(),
  };
  for (final rawEntry in entries) {
    final entry = _map(rawEntry);
    if (_string(entry['family']) != 'item') {
      continue;
    }
    final status = _string(entry['status']);
    if (status == 'ported') {
      continue;
    }
    final batch = psdkItemEffectBatchForPath(_string(entry['rubyPath']));
    final countsForBatch = counts[batch]!;
    if (status == 'partial') {
      countsForBatch.partial += 1;
    } else {
      countsForBatch.missing += 1;
    }
  }
  if (counts.values.every((count) => count.remaining == 0)) {
    return;
  }

  buffer
    ..writeln()
    ..writeln('## Item Effect Backlog')
    ..writeln()
    ..writeln('| Batch | Partial | Missing | Remaining |')
    ..writeln('| --- | ---: | ---: | ---: |');
  for (final batch in PsdkItemEffectBatch.values) {
    final count = counts[batch]!;
    if (count.remaining == 0) {
      continue;
    }
    buffer.writeln(
      '| ${batch.label} | ${count.partial} | ${count.missing} | '
      '${count.remaining} |',
    );
  }
}

void _writeAbilityEffectBacklog(
  StringBuffer buffer,
  Map<String, Object?> effects,
) {
  final entries = _list(effects['entries']);
  final counts = <String, _BacklogCounts>{};
  for (final rawEntry in entries) {
    final entry = _map(rawEntry);
    if (_string(entry['family']) != 'ability') {
      continue;
    }
    final status = _string(entry['status']);
    if (status == 'ported') {
      continue;
    }
    final hookFamilies = _stringList(entry['hookFamilies']);
    final families = hookFamilies.isEmpty
        ? const <String>['unclassified']
        : _sortedUniqueStrings(hookFamilies);
    for (final family in families) {
      final countsForFamily = counts.putIfAbsent(family, _BacklogCounts.new);
      if (status == 'partial') {
        countsForFamily.partial += 1;
      } else {
        countsForFamily.missing += 1;
      }
    }
  }
  if (counts.isEmpty) {
    return;
  }

  final families = counts.keys.toList()
    ..sort((left, right) {
      final byRemaining =
          counts[right]!.remaining.compareTo(counts[left]!.remaining);
      if (byRemaining != 0) {
        return byRemaining;
      }
      return left.compareTo(right);
    });
  buffer
    ..writeln()
    ..writeln('## Ability Effect Backlog')
    ..writeln()
    ..writeln(
      'Effects with multiple PSDK hooks can appear in multiple hook families.',
    )
    ..writeln()
    ..writeln('| Hook family | Partial | Missing | Remaining |')
    ..writeln('| --- | ---: | ---: | ---: |');
  for (final family in families) {
    final count = counts[family]!;
    buffer.writeln(
      '| $family | ${count.partial} | ${count.missing} | ${count.remaining} |',
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return const <String, Object?>{};
}

List<Object?> _list(Object? value) {
  if (value is List) {
    return value;
  }
  return const <Object?>[];
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.map((entry) => entry.toString()).toList(growable: false);
}

List<String> _sortedUniqueStrings(List<String> values) {
  return values.toSet().toList()..sort();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _string(Object? value) => value?.toString() ?? '';

String _percent(int value, int total) {
  if (total == 0) return '0.0%';
  return '${(value * 100 / total).toStringAsFixed(1)}%';
}

final class _BacklogCounts {
  int partial = 0;
  int missing = 0;

  int get remaining => partial + missing;
}
