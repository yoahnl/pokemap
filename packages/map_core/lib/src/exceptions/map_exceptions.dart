sealed class MapException implements Exception {
  final String message;
  const MapException(this.message);
  @override
  String toString() => message;
}

class ValidationException extends MapException {
  const ValidationException(
    super.message, {
    this.code,
    this.details = const {},
    this.remediation = const [],
  });

  /// Optional stable metadata lets protocol adapters expose actionable domain
  /// diagnostics without parsing or leaking arbitrary exception strings.
  final String? code;
  final Map<String, Object?> details;
  final List<String> remediation;
}

class ProjectLoadException extends MapException {
  const ProjectLoadException(super.message);
}

class MapLoadException extends MapException {
  const MapLoadException(super.message);
}

class AssetNotFoundException extends MapException {
  const AssetNotFoundException(super.message);
}
