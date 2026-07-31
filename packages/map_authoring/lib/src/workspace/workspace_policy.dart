import '../ports/project_file_reader.dart';

/// Canonical allow-list policy for read-only PokeMap project roots.
final class WorkspacePolicy {
  WorkspacePolicy._({
    required ProjectFileReader fileReader,
    required List<String> canonicalAllowedRoots,
  })  : _fileReader = fileReader,
        _canonicalAllowedRoots = List.unmodifiable(canonicalAllowedRoots);

  static Future<WorkspacePolicy> create({
    required Iterable<String> allowedRootPaths,
    required ProjectFileReader fileReader,
  }) async {
    final requestedRoots = allowedRootPaths.toList(growable: false);
    if (requestedRoots.isEmpty) {
      throw const WorkspaceAccessException(
        'workspace.allowed_roots_required',
        'At least one allowed workspace root is required.',
      );
    }
    final canonicalRoots = <String>{};
    for (final root in requestedRoots) {
      canonicalRoots.add(await fileReader.canonicalizeDirectory(root));
    }
    final orderedRoots = canonicalRoots.toList()..sort();
    return WorkspacePolicy._(
      fileReader: fileReader,
      canonicalAllowedRoots: orderedRoots,
    );
  }

  final ProjectFileReader _fileReader;
  final List<String> _canonicalAllowedRoots;

  Future<String> authorizeProjectRoot(String projectRootPath) async {
    _rejectTraversal(projectRootPath);
    final canonicalProjectRoot =
        await _fileReader.canonicalizeDirectory(projectRootPath);
    if (!_canonicalAllowedRoots.any(
      (root) => workspacePathIsWithin(
        root: root,
        candidate: canonicalProjectRoot,
      ),
    )) {
      throw const WorkspaceAccessException(
        'workspace.path_outside_allowed_roots',
        'The requested project is outside the allowed workspace roots.',
      );
    }
    return canonicalProjectRoot;
  }
}

void _rejectTraversal(String value) {
  if (value.trim().isEmpty || value.contains('\u0000')) {
    throw const WorkspaceAccessException(
      'workspace.path_invalid',
      'The requested project path is invalid.',
    );
  }
  if (value.split(RegExp(r'[\\/]')).any((segment) => segment == '..')) {
    throw const WorkspaceAccessException(
      'workspace.path_traversal',
      'Workspace paths cannot contain traversal segments.',
    );
  }
}
