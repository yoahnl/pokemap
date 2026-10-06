import 'map_authoring_exception.dart';

MapAuthoringException invalidSemanticField(String field, String expected) =>
    semanticFailure(
      'map.request_invalid',
      'Parameter "$field" must be $expected.',
      details: {'parameter': field, 'expected': expected},
    );

MapAuthoringException semanticFailure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
  Iterable<String> remediation = const [],
}) =>
    MapAuthoringException(
      code: code,
      message: message,
      details: details,
      remediation: remediation,
    );
