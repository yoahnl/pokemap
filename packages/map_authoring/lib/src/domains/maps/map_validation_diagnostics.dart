import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';

/// Safe, JSON-compatible projection of one fail-fast map validation issue.
/// Structured core diagnostics are preserved verbatim; unknown exceptions are
/// deliberately reduced to a stable fallback without exposing stack traces or
/// filesystem data.
final class MapValidationIssue {
  MapValidationIssue._({
    required this.code,
    required this.message,
    required Map<String, Object?> details,
    required Iterable<String> remediation,
  })  : details = Map.unmodifiable(details),
        remediation = List.unmodifiable(remediation);

  factory MapValidationIssue.fromError(
    Object error, {
    required String fallbackCode,
    required String fallbackMessage,
  }) {
    if (error is ValidationException) {
      return MapValidationIssue._(
        code: error.code ?? fallbackCode,
        message: error.message,
        details: {
          ...error.details,
          'validationType': error.runtimeType.toString(),
        },
        remediation: error.remediation,
      );
    }
    return MapValidationIssue._(
      code: fallbackCode,
      message: fallbackMessage,
      details: {'validationType': error.runtimeType.toString()},
      remediation: const [],
    );
  }

  final String code;
  final String message;
  final Map<String, Object?> details;
  final List<String> remediation;

  bool equivalentTo(MapValidationIssue other) =>
      code == other.code && message == other.message;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'details': details,
        'remediation': remediation,
      };

  MapAuthoringException toFailure({
    required String validationState,
    MapValidationIssue? initialIssue,
  }) =>
      MapAuthoringException(
        code: code,
        message: message,
        details: {
          ...details,
          'validationState': validationState,
          if (initialIssue != null && !equivalentTo(initialIssue))
            'initialIssue': initialIssue.toJson(),
        },
        remediation: remediation,
      );
}

MapValidationIssue? inspectMapValidation(
  MapData map, {
  required ProjectManifest manifest,
  required String fallbackCode,
  required String fallbackMessage,
}) {
  try {
    MapValidator.validate(map, projectDialogueContext: manifest);
    return null;
  } on Object catch (error) {
    return MapValidationIssue.fromError(
      error,
      fallbackCode: fallbackCode,
      fallbackMessage: fallbackMessage,
    );
  }
}
