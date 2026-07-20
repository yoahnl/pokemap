import 'package:meta/meta.dart' show immutable;

enum NarrativeValidationStatus { pass, fail, indeterminate, notRun }

enum NarrativeValidationDimension {
  structurallyValid,
  narrativelySolvable,
  physicallyReachable,
  runtimeSmokeVerified,
}

@immutable
final class NarrativeMultidimensionalDiagnostic {
  NarrativeMultidimensionalDiagnostic({
    required this.id,
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
    List<String> provenance = const <String>[],
  }) : provenance = List.unmodifiable(provenance);

  factory NarrativeMultidimensionalDiagnostic.fromJson(
      Map<String, dynamic> json) {
    return NarrativeMultidimensionalDiagnostic(
      id: _requiredString(json, 'id'),
      code: _requiredString(json, 'code'),
      severity: _requiredString(json, 'severity'),
      message: _requiredString(json, 'message'),
      path: _requiredString(json, 'path'),
      provenance: _stringList(json, 'provenance'),
    );
  }

  final String id;
  final String code;
  final String severity;
  final String message;
  final String path;
  final List<String> provenance;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'severity': severity,
        'message': message,
        'path': path,
        'provenance': provenance,
      };
}

@immutable
final class NarrativeValidationDimensionResult {
  NarrativeValidationDimensionResult({
    required this.status,
    List<NarrativeMultidimensionalDiagnostic> diagnostics =
        const <NarrativeMultidimensionalDiagnostic>[],
    List<String> evidenceRefs = const <String>[],
    List<String> limitations = const <String>[],
  })  : diagnostics = List.unmodifiable(diagnostics),
        evidenceRefs = _stableStrings(evidenceRefs),
        limitations = _stableStrings(limitations);

  factory NarrativeValidationDimensionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return NarrativeValidationDimensionResult(
      status: _status(json['status']),
      diagnostics: [
        for (final item in _objectList(json, 'diagnostics'))
          NarrativeMultidimensionalDiagnostic.fromJson(item),
      ],
      evidenceRefs: _stringList(json, 'evidenceRefs'),
      limitations: _stringList(json, 'limitations'),
    );
  }

  final NarrativeValidationStatus status;
  final List<NarrativeMultidimensionalDiagnostic> diagnostics;
  final List<String> evidenceRefs;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'evidenceRefs': evidenceRefs,
        'limitations': limitations,
      };
}

@immutable
final class NarrativeMultidimensionalValidationReport {
  NarrativeMultidimensionalValidationReport({
    this.schemaVersion = 1,
    required this.validatorVersion,
    required this.profileId,
    required this.profileVersion,
    required this.projectFingerprint,
    required DateTime generatedAt,
    required this.structurallyValid,
    required this.narrativelySolvable,
    required this.physicallyReachable,
    required this.runtimeSmokeVerified,
  }) : generatedAt = generatedAt.toUtc() {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
  }

  factory NarrativeMultidimensionalValidationReport.fromJson(
      Map<String, dynamic> json) {
    final dimensions = _object(json, 'dimensions');
    return NarrativeMultidimensionalValidationReport(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      validatorVersion: _requiredString(json, 'validatorVersion'),
      profileId: _requiredString(json, 'profileId'),
      profileVersion: _requiredInt(json, 'profileVersion'),
      projectFingerprint: _requiredString(json, 'projectFingerprint'),
      generatedAt: DateTime.parse(_requiredString(json, 'generatedAt')),
      structurallyValid: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.structurallyValid.name),
      ),
      narrativelySolvable: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.narrativelySolvable.name),
      ),
      physicallyReachable: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.physicallyReachable.name),
      ),
      runtimeSmokeVerified: NarrativeValidationDimensionResult.fromJson(
        _object(
            dimensions, NarrativeValidationDimension.runtimeSmokeVerified.name),
      ),
    );
  }

  final int schemaVersion;
  final String validatorVersion;
  final String profileId;
  final int profileVersion;
  final String projectFingerprint;
  final DateTime generatedAt;
  final NarrativeValidationDimensionResult structurallyValid;
  final NarrativeValidationDimensionResult narrativelySolvable;
  final NarrativeValidationDimensionResult physicallyReachable;
  final NarrativeValidationDimensionResult runtimeSmokeVerified;

  List<NarrativeValidationDimensionResult> get dimensions => [
        structurallyValid,
        narrativelySolvable,
        physicallyReachable,
        runtimeSmokeVerified,
      ];

  bool get isPlayable => dimensions
      .every((dimension) => dimension.status == NarrativeValidationStatus.pass);

  NarrativeValidationStatus get overallStatus {
    if (dimensions
        .any((item) => item.status == NarrativeValidationStatus.fail)) {
      return NarrativeValidationStatus.fail;
    }
    if (dimensions.any(
      (item) => item.status == NarrativeValidationStatus.indeterminate,
    )) {
      return NarrativeValidationStatus.indeterminate;
    }
    if (dimensions
        .any((item) => item.status == NarrativeValidationStatus.notRun)) {
      return NarrativeValidationStatus.notRun;
    }
    return NarrativeValidationStatus.pass;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'validatorVersion': validatorVersion,
        'profileId': profileId,
        'profileVersion': profileVersion,
        'projectFingerprint': projectFingerprint,
        'generatedAt': generatedAt.toIso8601String(),
        'dimensions': {
          NarrativeValidationDimension.structurallyValid.name:
              structurallyValid.toJson(),
          NarrativeValidationDimension.narrativelySolvable.name:
              narrativelySolvable.toJson(),
          NarrativeValidationDimension.physicallyReachable.name:
              physicallyReachable.toJson(),
          NarrativeValidationDimension.runtimeSmokeVerified.name:
              runtimeSmokeVerified.toJson(),
        },
      };
}

NarrativeValidationStatus _status(Object? value) {
  if (value is String) {
    for (final status in NarrativeValidationStatus.values) {
      if (status.name == value) return status;
    }
  }
  throw FormatException('Unknown NarrativeValidationStatus "$value".');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

Map<String, dynamic> _object(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('$key must be an object.');
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _objectList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('$key must be a list.');
  return [
    for (final item in value)
      if (item is Map)
        Map<String, dynamic>.from(item)
      else
        throw FormatException('$key entries must be objects.'),
  ];
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.from(value);
}

List<String> _stableStrings(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(result);
}
