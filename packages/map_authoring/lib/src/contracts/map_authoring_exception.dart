/// Stable domain failure returned by map action adapters.
final class MapAuthoringException implements Exception {
  MapAuthoringException({
    required this.code,
    required this.message,
    Map<String, Object?> details = const {},
    Iterable<String> remediation = const [],
  })  : details = Map.unmodifiable(details),
        remediation = List.unmodifiable(remediation);

  final String code;
  final String message;
  final Map<String, Object?> details;
  final List<String> remediation;

  @override
  String toString() => 'MapAuthoringException($code): $message';
}
