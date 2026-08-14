import 'dart:io';

/// Stable, path-free failure raised by the read-only project filesystem port.
final class WorkspaceAccessException implements Exception {
  const WorkspaceAccessException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'WorkspaceAccessException($code): $message';
}

/// Cheap identity of a stored resource, used to skip work on unchanged files.
///
/// [scope] is the canonical project root, so two projects holding the same
/// relative path can never share a cache entry.
final class ProjectResourceIdentity {
  const ProjectResourceIdentity({
    required this.scope,
    required this.relativePath,
    required this.byteLength,
    required this.modifiedAtMicros,
    this.changedAtMicros,
  });

  final String scope;
  final String relativePath;
  final int byteLength;
  final int modifiedAtMicros;
  final int? changedAtMicros;

  @override
  bool operator ==(Object other) =>
      other is ProjectResourceIdentity &&
      other.scope == scope &&
      other.relativePath == relativePath &&
      other.byteLength == byteLength &&
      other.modifiedAtMicros == modifiedAtMicros &&
      other.changedAtMicros == changedAtMicros;

  @override
  int get hashCode => Object.hash(
        scope,
        relativePath,
        byteLength,
        modifiedAtMicros,
        changedAtMicros,
      );
}

/// Optional capability: a reader that can report a resource's identity without
/// reading it. Readers that cannot simply do not implement it and lose the
/// caching, never the correctness.
abstract interface class ProjectResourceIdentityReader {
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  });
}

/// Opt-in guarantee required before a complete snapshot may be reused.
///
/// Implementations promise that [ProjectResourceIdentityReader.readIdentity]
/// is a cheap generation observation: a changed resource receives a different
/// identity, and `null` means the resource is absent. Readers that only offer
/// best-effort metadata must not implement this capability; they still benefit
/// from decoded-model and fingerprint caching after strict byte reads.
abstract interface class ProjectSnapshotCacheIdentityReader
    implements ProjectResourceIdentityReader {}

abstract interface class ProjectDirectoryReader {
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  });
}

/// The complete filesystem capability available to the Authoring Read API.
///
/// Deliberately no mutation method is exposed by this port.
abstract interface class ProjectFileReader {
  Future<String> canonicalizeDirectory(String path);

  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  });
}

/// `dart:io` implementation constrained to an already-authorized project root.
final class LocalProjectFileReader
    implements
        ProjectFileReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader,
        ProjectDirectoryReader {
  const LocalProjectFileReader();

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) async {
    final root = _requirePath(projectRoot, field: 'projectRoot');
    final segments = _projectRelativeSegments(relativeDirectory);
    final lexicalTarget = [root, ...segments].join(Platform.pathSeparator);
    try {
      final resolvedDirectory = await Directory(
        lexicalTarget,
      ).resolveSymbolicLinks();
      if (!workspacePathIsWithin(root: root, candidate: resolvedDirectory)) {
        throw const WorkspaceAccessException(
          'workspace.path_outside_project',
          'The requested project directory resolves outside the project.',
        );
      }
      final files = <String>[];
      await for (final entity in Directory(resolvedDirectory).list()) {
        if (entity is! File) continue;
        final resolvedFile = await entity.resolveSymbolicLinks();
        if (!workspacePathIsWithin(root: root, candidate: resolvedFile)) {
          throw const WorkspaceAccessException(
            'workspace.path_outside_project',
            'A project directory entry resolves outside the project.',
          );
        }
        final relative = resolvedFile
            .substring(root.length + 1)
            .split(
              Platform.pathSeparator,
            )
            .join('/');
        files.add(relative);
      }
      files.sort();
      return List.unmodifiable(files);
    } on WorkspaceAccessException {
      rethrow;
    } on FileSystemException {
      throw const WorkspaceAccessException(
        'workspace.directory_unavailable',
        'The requested project directory is unavailable.',
      );
    }
  }

  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) async {
    try {
      final root = _requirePath(projectRoot, field: 'projectRoot');
      final segments = _projectRelativeSegments(relativePath);
      final lexicalTarget = [root, ...segments].join(Platform.pathSeparator);
      final resolved = await File(lexicalTarget).resolveSymbolicLinks();
      if (!workspacePathIsWithin(root: root, candidate: resolved)) return null;
      final stat = await File(resolved).stat();
      if (stat.type != FileSystemEntityType.file) return null;
      return ProjectResourceIdentity(
        scope: root,
        relativePath: relativePath,
        byteLength: stat.size,
        modifiedAtMicros: stat.modified.microsecondsSinceEpoch,
        changedAtMicros: stat.changed.microsecondsSinceEpoch,
      );
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<String> canonicalizeDirectory(String path) async {
    final normalized = _requirePath(path, field: 'directory');
    try {
      final directory = Directory(normalized);
      final stat = await directory.stat();
      if (stat.type != FileSystemEntityType.directory) {
        throw const WorkspaceAccessException(
          'workspace.directory_required',
          'The requested workspace root is not a directory.',
        );
      }
      return await directory.resolveSymbolicLinks();
    } on WorkspaceAccessException {
      rethrow;
    } on FileSystemException {
      throw const WorkspaceAccessException(
        'workspace.directory_unavailable',
        'The requested workspace root is unavailable.',
      );
    }
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final root = _requirePath(projectRoot, field: 'projectRoot');
    final segments = _projectRelativeSegments(relativePath);
    final lexicalTarget = [root, ...segments].join(Platform.pathSeparator);
    try {
      final resolvedBefore = await File(lexicalTarget).resolveSymbolicLinks();
      if (!workspacePathIsWithin(root: root, candidate: resolvedBefore)) {
        throw const WorkspaceAccessException(
          'workspace.path_outside_project',
          'The requested project resource resolves outside the project.',
        );
      }
      final file = File(resolvedBefore);
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const WorkspaceAccessException(
          'workspace.file_required',
          'The requested project resource is not a regular file.',
        );
      }
      final bytes = await file.readAsBytes();
      final resolvedAfter = await File(lexicalTarget).resolveSymbolicLinks();
      if (resolvedAfter != resolvedBefore ||
          !workspacePathIsWithin(root: root, candidate: resolvedAfter)) {
        throw const WorkspaceAccessException(
          'workspace.path_changed_during_read',
          'The requested project resource changed while it was read.',
        );
      }
      // `readAsBytes` gives this reader exclusive ownership of the backing
      // buffer. Expose an immutable zero-copy view; the workspace capability
      // will establish its own immutable ownership boundary before returning
      // bytes to callers.
      return bytes.asUnmodifiableView();
    } on WorkspaceAccessException {
      rethrow;
    } on FileSystemException {
      throw const WorkspaceAccessException(
        'workspace.file_unavailable',
        'The requested project resource is unavailable.',
      );
    }
  }
}

bool workspacePathIsWithin({
  required String root,
  required String candidate,
}) {
  if (candidate == root) return true;
  final rootWithSeparator = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return candidate.startsWith(rootWithSeparator);
}

List<String> validateProjectRelativePath(String value) =>
    List<String>.unmodifiable(_projectRelativeSegments(value));

String _requirePath(String value, {required String field}) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains('\u0000')) {
    throw WorkspaceAccessException(
      'workspace.path_invalid',
      'The $field path is invalid.',
    );
  }
  return normalized;
}

List<String> _projectRelativeSegments(String value) {
  final normalized = _requirePath(value, field: 'resource');
  if (File(normalized).isAbsolute ||
      normalized.startsWith('/') ||
      normalized.startsWith(r'\') ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(normalized)) {
    throw const WorkspaceAccessException(
      'workspace.path_absolute',
      'Project resource paths must be relative.',
    );
  }
  final segments = normalized.split(RegExp(r'[\\/]'));
  if (segments.any((segment) => segment == '..')) {
    throw const WorkspaceAccessException(
      'workspace.path_traversal',
      'Project resource paths cannot contain traversal segments.',
    );
  }
  final meaningful = segments.where((segment) => segment.isNotEmpty).toList();
  if (meaningful.isEmpty || meaningful.any((segment) => segment == '.')) {
    throw const WorkspaceAccessException(
      'workspace.path_invalid',
      'The project resource path is invalid.',
    );
  }
  return meaningful;
}
