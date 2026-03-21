sealed class MapException implements Exception {
  final String message;
  const MapException(this.message);
  @override
  String toString() => message;
}

class ValidationException extends MapException {
  const ValidationException(super.message);
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
