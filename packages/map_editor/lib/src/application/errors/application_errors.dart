sealed class EditorApplicationException implements Exception {
  const EditorApplicationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class EditorValidationException extends EditorApplicationException {
  const EditorValidationException(super.message);
}

final class EditorNotFoundException extends EditorApplicationException {
  const EditorNotFoundException(super.message);
}

final class EditorConflictException extends EditorApplicationException {
  const EditorConflictException(super.message);
}

final class EditorInvalidOperationException extends EditorApplicationException {
  const EditorInvalidOperationException(super.message);
}

final class EditorMissingDependencyException
    extends EditorApplicationException {
  const EditorMissingDependencyException(super.message);
}

final class EditorPersistenceException extends EditorApplicationException {
  const EditorPersistenceException(super.message);
}
