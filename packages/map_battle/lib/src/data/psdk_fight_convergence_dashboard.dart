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

Map<String, Object?> _map(Object? value) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  return const <String, Object?>{};
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
