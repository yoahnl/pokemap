import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'geometry.dart';

const int _minimumJsonSafeInteger = -9007199254740991;
const int _maximumJsonSafeInteger = 9007199254740991;
const int _maximumDiagnosticParameterDepth = 64;
const int _maximumDiagnosticParameterNodes = 10000;
const int _maximumDiagnosticParameterStringCodeUnits = 1000000;

/// Stable diagnostic severities supported by Border V1.
enum BorderDiagnosticSeverity {
  error,
  warning,
  info,
}

/// Stable Border V1 phases that may emit diagnostics.
enum BorderDiagnosticPhase {
  authoring,
  publication,
  resolution,
  materialization,
  freshness,
  resize,
  projectValidation,
  playExport,
}

/// Stable Border V1 scopes that may own diagnostics.
enum BorderDiagnosticScope {
  project,
  catalog,
  blueprint,
  primitive,
  visualSnapshot,
  feature,
  geometry,
  groundCell,
  stroke,
  segment,
  slot,
  placement,
  materialization,
}

/// Returns the explicit stable V1 severity rank.
int borderDiagnosticSeverityV1Rank(BorderDiagnosticSeverity severity) =>
    switch (severity) {
      BorderDiagnosticSeverity.error => 0,
      BorderDiagnosticSeverity.warning => 1,
      BorderDiagnosticSeverity.info => 2,
    };

/// Returns the explicit stable V1 phase rank.
int borderDiagnosticPhaseV1Rank(BorderDiagnosticPhase phase) => switch (phase) {
      BorderDiagnosticPhase.authoring => 0,
      BorderDiagnosticPhase.publication => 1,
      BorderDiagnosticPhase.resolution => 2,
      BorderDiagnosticPhase.materialization => 3,
      BorderDiagnosticPhase.freshness => 4,
      BorderDiagnosticPhase.resize => 5,
      BorderDiagnosticPhase.projectValidation => 6,
      BorderDiagnosticPhase.playExport => 7,
    };

/// Returns the explicit stable V1 scope rank.
int borderDiagnosticScopeV1Rank(BorderDiagnosticScope scope) => switch (scope) {
      BorderDiagnosticScope.project => 0,
      BorderDiagnosticScope.catalog => 1,
      BorderDiagnosticScope.blueprint => 2,
      BorderDiagnosticScope.primitive => 3,
      BorderDiagnosticScope.visualSnapshot => 4,
      BorderDiagnosticScope.feature => 5,
      BorderDiagnosticScope.geometry => 6,
      BorderDiagnosticScope.groundCell => 7,
      BorderDiagnosticScope.stroke => 8,
      BorderDiagnosticScope.segment => 9,
      BorderDiagnosticScope.slot => 10,
      BorderDiagnosticScope.placement => 11,
      BorderDiagnosticScope.materialization => 12,
    };

/// One immutable, machine-readable Border diagnostic.
@immutable
final class BorderDiagnostic implements Comparable<BorderDiagnostic> {
  factory BorderDiagnostic({
    required String code,
    required BorderDiagnosticSeverity severity,
    required BorderDiagnosticPhase phase,
    required BorderDiagnosticScope scope,
    String? blueprintId,
    String? featureId,
    String? slotKey,
    GridPos? cell,
    String? strokeId,
    int? segmentIndex,
    Map<String, Object?> parameters = const <String, Object?>{},
    required String suggestedAction,
  }) {
    _requireStableText(code, 'BorderDiagnostic.code');
    _requireOptionalStableText(
      blueprintId,
      'BorderDiagnostic.blueprintId',
    );
    _requireOptionalStableText(featureId, 'BorderDiagnostic.featureId');
    _requireOptionalStableText(slotKey, 'BorderDiagnostic.slotKey');
    _requireOptionalStableText(strokeId, 'BorderDiagnostic.strokeId');
    _requireStableText(
      suggestedAction,
      'BorderDiagnostic.suggestedAction',
    );
    if (segmentIndex != null && strokeId == null) {
      throw const ValidationException(
        'BorderDiagnostic.segmentIndex requires strokeId',
      );
    }
    if (segmentIndex != null && segmentIndex < 0) {
      throw const ValidationException(
        'BorderDiagnostic.segmentIndex must be >= 0',
      );
    }

    final copiedParameters = _copyDiagnosticParameters(parameters);
    return BorderDiagnostic._(
      code: code,
      severity: severity,
      phase: phase,
      scope: scope,
      blueprintId: blueprintId,
      featureId: featureId,
      slotKey: slotKey,
      cell: cell == null ? null : GridPos(x: cell.x, y: cell.y),
      strokeId: strokeId,
      segmentIndex: segmentIndex,
      parameters: copiedParameters,
      canonicalParameters: _canonicalJsonSafeValue(copiedParameters),
      suggestedAction: suggestedAction,
    );
  }

  const BorderDiagnostic._({
    required this.code,
    required this.severity,
    required this.phase,
    required this.scope,
    required this.blueprintId,
    required this.featureId,
    required this.slotKey,
    required this.cell,
    required this.strokeId,
    required this.segmentIndex,
    required Map<String, Object?> parameters,
    required String canonicalParameters,
    required this.suggestedAction,
  })  : _parameters = parameters,
        _canonicalParameters = canonicalParameters;

  final String code;
  final BorderDiagnosticSeverity severity;
  final BorderDiagnosticPhase phase;
  final BorderDiagnosticScope scope;
  final String? blueprintId;
  final String? featureId;
  final String? slotKey;
  final GridPos? cell;
  final String? strokeId;
  final int? segmentIndex;
  final Map<String, Object?> _parameters;
  final String _canonicalParameters;
  final String suggestedAction;

  Map<String, Object?> get parameters => _parameters;

  @override
  int compareTo(BorderDiagnostic other) {
    var result = borderDiagnosticSeverityV1Rank(severity)
        .compareTo(borderDiagnosticSeverityV1Rank(other.severity));
    if (result != 0) {
      return result;
    }
    result = borderDiagnosticPhaseV1Rank(phase)
        .compareTo(borderDiagnosticPhaseV1Rank(other.phase));
    if (result != 0) {
      return result;
    }
    result = borderDiagnosticScopeV1Rank(scope)
        .compareTo(borderDiagnosticScopeV1Rank(other.scope));
    if (result != 0) {
      return result;
    }
    result = _compareNullable(blueprintId, other.blueprintId, _compareString);
    if (result != 0) {
      return result;
    }
    result = _compareNullable(featureId, other.featureId, _compareString);
    if (result != 0) {
      return result;
    }
    result = _compareNullable(cell, other.cell, _compareCell);
    if (result != 0) {
      return result;
    }
    result = _compareNullable(strokeId, other.strokeId, _compareString);
    if (result != 0) {
      return result;
    }
    result = _compareNullable(segmentIndex, other.segmentIndex, _compareInt);
    if (result != 0) {
      return result;
    }
    result = _compareNullable(slotKey, other.slotKey, _compareString);
    if (result != 0) {
      return result;
    }
    result = code.compareTo(other.code);
    if (result != 0) {
      return result;
    }
    result = _canonicalParameters.compareTo(other._canonicalParameters);
    if (result != 0) {
      return result;
    }
    return suggestedAction.compareTo(other.suggestedAction);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderDiagnostic &&
          code == other.code &&
          severity == other.severity &&
          phase == other.phase &&
          scope == other.scope &&
          blueprintId == other.blueprintId &&
          featureId == other.featureId &&
          slotKey == other.slotKey &&
          cell == other.cell &&
          strokeId == other.strokeId &&
          segmentIndex == other.segmentIndex &&
          _deepJsonSafeEquals(_parameters, other._parameters) &&
          suggestedAction == other.suggestedAction;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        phase,
        scope,
        blueprintId,
        featureId,
        slotKey,
        cell,
        strokeId,
        segmentIndex,
        _deepJsonSafeHash(_parameters),
        suggestedAction,
      );
}

/// Canonically ordered immutable collection of Border diagnostics.
@immutable
final class BorderDiagnosticsReport {
  const BorderDiagnosticsReport.empty()
      : _diagnostics = const <BorderDiagnostic>[],
        errorCount = 0,
        warningCount = 0,
        infoCount = 0;

  factory BorderDiagnosticsReport({
    required Iterable<BorderDiagnostic> diagnostics,
  }) {
    final sorted = List<BorderDiagnostic>.of(diagnostics)..sort();
    var errors = 0;
    var warnings = 0;
    var info = 0;
    for (final diagnostic in sorted) {
      switch (diagnostic.severity) {
        case BorderDiagnosticSeverity.error:
          errors += 1;
        case BorderDiagnosticSeverity.warning:
          warnings += 1;
        case BorderDiagnosticSeverity.info:
          info += 1;
      }
    }
    return BorderDiagnosticsReport._(
      diagnostics: List<BorderDiagnostic>.unmodifiable(sorted),
      errorCount: errors,
      warningCount: warnings,
      infoCount: info,
    );
  }

  const BorderDiagnosticsReport._({
    required List<BorderDiagnostic> diagnostics,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
  }) : _diagnostics = diagnostics;

  final List<BorderDiagnostic> _diagnostics;
  final int errorCount;
  final int warningCount;
  final int infoCount;

  List<BorderDiagnostic> get diagnostics => _diagnostics;

  int get diagnosticCount => _diagnostics.length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  bool get hasWarnings => warningCount > 0;

  bool get hasInfo => infoCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderDiagnosticsReport &&
          _listsEqual(_diagnostics, other._diagnostics);

  @override
  int get hashCode => Object.hashAll(_diagnostics);
}

Map<String, Object?> _copyDiagnosticParameters(
  Map<String, Object?> parameters,
) {
  final activeContainers = HashSet<Object>.identity();
  final budget = _DiagnosticParameterBudget();
  final copied = _copyJsonSafeValue(
    parameters,
    activeContainers,
    'BorderDiagnostic.parameters',
    budget,
    0,
  );
  return copied! as Map<String, Object?>;
}

Object? _copyJsonSafeValue(
  Object? value,
  Set<Object> activeContainers,
  String path,
  _DiagnosticParameterBudget budget,
  int depth,
) {
  budget.visitNode(depth, path);
  if (value == null || value is bool) {
    return value;
  }
  if (value is String) {
    budget.addStringCodeUnits(value.length, path);
    return value;
  }
  if (value is int) {
    if (value < _minimumJsonSafeInteger || value > _maximumJsonSafeInteger) {
      throw ValidationException('$path must contain only JSON-safe integers');
    }
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw ValidationException('$path must contain only finite doubles');
    }
    return value == 0 ? 0.0 : value;
  }
  if (value is List) {
    budget.requireNodeCapacity(value.length, path);
    _enterContainer(value, activeContainers, path);
    try {
      return List<Object?>.unmodifiable(
        <Object?>[
          for (var index = 0; index < value.length; index += 1)
            _copyJsonSafeValue(
              value[index] as Object?,
              activeContainers,
              '$path[$index]',
              budget,
              depth + 1,
            ),
        ],
      );
    } finally {
      activeContainers.remove(value);
    }
  }
  if (value is Map) {
    budget.requireNodeCapacity(value.length, path);
    _enterContainer(value, activeContainers, path);
    try {
      final keys = <String>[];
      for (final key in value.keys) {
        if (key is! String) {
          throw ValidationException('$path must contain only string map keys');
        }
        _requireStableText(key, '$path map key');
        budget.addStringCodeUnits(key.length, '$path map key');
        keys.add(key);
      }
      keys.sort();
      final copied = <String, Object?>{};
      for (final key in keys) {
        copied[key] = _copyJsonSafeValue(
          value[key] as Object?,
          activeContainers,
          '$path.$key',
          budget,
          depth + 1,
        );
      }
      return Map<String, Object?>.unmodifiable(copied);
    } finally {
      activeContainers.remove(value);
    }
  }
  throw ValidationException(
    '$path contains unsupported value type ${value.runtimeType}',
  );
}

final class _DiagnosticParameterBudget {
  int _visitedNodes = 0;
  int _stringCodeUnits = 0;

  void visitNode(int depth, String path) {
    if (depth > _maximumDiagnosticParameterDepth) {
      throw ValidationException(
        '$path exceeds maximum diagnostic parameter depth '
        '$_maximumDiagnosticParameterDepth',
      );
    }
    _visitedNodes += 1;
    if (_visitedNodes > _maximumDiagnosticParameterNodes) {
      throw ValidationException(
        '$path exceeds maximum diagnostic parameter node count '
        '$_maximumDiagnosticParameterNodes',
      );
    }
  }

  void requireNodeCapacity(int count, String path) {
    if (count > _maximumDiagnosticParameterNodes - _visitedNodes) {
      throw ValidationException(
        '$path exceeds maximum diagnostic parameter node count '
        '$_maximumDiagnosticParameterNodes',
      );
    }
  }

  void addStringCodeUnits(int count, String path) {
    if (count > _maximumDiagnosticParameterStringCodeUnits - _stringCodeUnits) {
      throw ValidationException(
        '$path exceeds maximum aggregate diagnostic parameter string '
        'length $_maximumDiagnosticParameterStringCodeUnits',
      );
    }
    _stringCodeUnits += count;
  }
}

void _enterContainer(
  Object value,
  Set<Object> activeContainers,
  String path,
) {
  if (!activeContainers.add(value)) {
    throw ValidationException('$path must not contain reference cycles');
  }
}

String _canonicalJsonSafeValue(Object? value) {
  if (value == null) {
    return 'n';
  }
  if (value is bool) {
    return value ? 'b1' : 'b0';
  }
  if (value is num) {
    return 'q${_canonicalJsonNumber(value)}';
  }
  if (value is String) {
    return 's${jsonEncode(value)}';
  }
  if (value is List<Object?>) {
    return 'l[${value.map(_canonicalJsonSafeValue).join(',')}]';
  }
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList(growable: false)..sort();
    return 'm{${keys.map(
          (key) => '${jsonEncode(key)}:${_canonicalJsonSafeValue(value[key])}',
        ).join(',')}}';
  }
  throw StateError('parameters were not normalized');
}

bool _deepJsonSafeEquals(Object? first, Object? second) {
  if (identical(first, second)) {
    return true;
  }
  if (first is num && second is num) {
    return first == second;
  }
  if (first.runtimeType != second.runtimeType) {
    return false;
  }
  if (first is List<Object?> && second is List<Object?>) {
    return _listsEqualDeep(first, second);
  }
  if (first is Map<String, Object?> && second is Map<String, Object?>) {
    if (first.length != second.length) {
      return false;
    }
    for (final entry in first.entries) {
      if (!second.containsKey(entry.key) ||
          !_deepJsonSafeEquals(entry.value, second[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return first == second;
}

int _deepJsonSafeHash(Object? value) {
  if (value == null) {
    return Object.hash(0, null);
  }
  if (value is bool) {
    return Object.hash(1, value);
  }
  if (value is num) {
    return Object.hash(2, _canonicalJsonNumber(value));
  }
  if (value is String) {
    return Object.hash(3, value);
  }
  if (value is List<Object?>) {
    return Object.hash(4, Object.hashAll(value.map(_deepJsonSafeHash)));
  }
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList(growable: false)..sort();
    return Object.hash(
      5,
      Object.hashAll(
        keys.map(
          (key) => Object.hash(key, _deepJsonSafeHash(value[key])),
        ),
      ),
    );
  }
  throw StateError('parameters were not normalized');
}

String _canonicalJsonNumber(num value) {
  if (value == 0) {
    return '0';
  }
  if (value is int) {
    return value.toString();
  }
  if (value.abs() <= _maximumJsonSafeInteger && value == value.truncate()) {
    return value.toInt().toString();
  }
  return jsonEncode(value);
}

bool _listsEqualDeep(List<Object?> first, List<Object?> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (!_deepJsonSafeEquals(first[index], second[index])) {
      return false;
    }
  }
  return true;
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

int _compareNullable<T>(
  T? first,
  T? second,
  int Function(T first, T second) compare,
) {
  if (first == null) {
    return second == null ? 0 : -1;
  }
  if (second == null) {
    return 1;
  }
  return compare(first, second);
}

int _compareString(String first, String second) => first.compareTo(second);

int _compareInt(int first, int second) => first.compareTo(second);

int _compareCell(GridPos first, GridPos second) {
  final row = first.y.compareTo(second.y);
  return row != 0 ? row : first.x.compareTo(second.x);
}

void _requireStableText(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

void _requireOptionalStableText(String? value, String field) {
  if (value != null) {
    _requireStableText(value, field);
  }
}
