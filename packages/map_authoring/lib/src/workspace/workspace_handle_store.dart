import 'dart:typed_data';
import 'dart:collection';
import 'dart:math';

import '../ports/project_file_reader.dart';

typedef WorkspaceClock = DateTime Function();
typedef WorkspaceTokenFactory = String Function(String prefix);
typedef ProjectResourceReader = Future<List<int>> Function(String relativePath);

final class WorkspaceHandle {
  const WorkspaceHandle(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is WorkspaceHandle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class ProjectHandle {
  const ProjectHandle(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProjectHandle && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class WorkspaceHandleException implements Exception {
  const WorkspaceHandleException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'WorkspaceHandleException($code): $message';
}

/// Immutable bytes whose backing storage is owned by the workspace boundary.
///
/// The wrapper lets internal snapshot construction transfer that immutable
/// storage without copying it again. Callers can only obtain instances from an
/// authorized [ProjectWorkspaceAccess].
final class ProjectResourceBytes {
  ProjectResourceBytes._(List<int> source)
      : this._typed(Uint8List.fromList(source));

  ProjectResourceBytes._typed(this.typedBytes)
      : bytes = UnmodifiableListView<int>(typedBytes);

  /// Immutable view of the resource. Mutating a snapshot must throw, and
  /// `project_open_service_test` pins that contract.
  final List<int> bytes;

  /// The same bytes as typed data, for hashing hot paths only.
  ///
  /// Walking the unmodifiable view element by element denies the crypto sinks
  /// their fast typed-data path; on a 10 MB project that cost ~25% of a whole
  /// snapshot. Read through [bytes] everywhere else so the contract holds.
  final Uint8List typedBytes;
}

/// Authorized read-only access associated with an opaque project handle.
///
/// The canonical filesystem root remains captured privately by [readBytes].
typedef ProjectResourceIdentityLookup = Future<ProjectResourceIdentity?>
    Function(String relativePath);

final class ProjectWorkspaceAccess {
  ProjectWorkspaceAccess._({
    required this.projectHandle,
    required this.projectName,
    required this.initialFingerprint,
    required this.expiresAt,
    required ProjectResourceReader readBytes,
    ProjectResourceIdentityLookup? readIdentity,
  })  : _readBytes = readBytes,
        _readIdentity = readIdentity;

  final ProjectHandle projectHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader _readBytes;
  final ProjectResourceIdentityLookup? _readIdentity;

  /// Identity of a stored resource when the reader can report it cheaply.
  ///
  /// Null means "unknown": callers must fall back to reading the bytes.
  Future<ProjectResourceIdentity?> readResourceIdentity(
    String relativePath,
  ) async =>
      await _readIdentity?.call(relativePath);

  Future<ProjectResourceBytes> readResourceBytes(String relativePath) async =>
      ProjectResourceBytes._(await _readBytes(relativePath));

  /// Wraps already-trusted bytes without re-reading them.
  ProjectResourceBytes adoptResourceBytes(List<int> bytes) =>
      ProjectResourceBytes._(bytes);

  Future<List<int>> readBytes(String relativePath) async =>
      (await readResourceBytes(relativePath)).bytes;

  Future<bool> matchesResourceBytes(
    String relativePath,
    List<int> expected,
  ) async {
    final observed = await _readBytes(relativePath);
    if (observed.length != expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (observed[index] != expected[index]) return false;
    }
    return true;
  }
}

final class RegisteredProjectHandles {
  const RegisteredProjectHandles({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.expiresAt,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final DateTime expiresAt;
}

/// In-memory, expiring handle store. Durable sessions are outside phase 2.
final class WorkspaceHandleStore {
  WorkspaceHandleStore({
    WorkspaceClock? clock,
    WorkspaceTokenFactory? tokenFactory,
    this.ttl = const Duration(minutes: 15),
  })  : _clock = clock ?? _systemClock,
        _tokenFactory = tokenFactory ?? _secureToken {
    if (ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'must be positive');
    }
  }

  final WorkspaceClock _clock;
  final WorkspaceTokenFactory _tokenFactory;
  final Duration ttl;
  final Map<WorkspaceHandle, ProjectHandle> _projectsByWorkspace = {};
  final Map<ProjectHandle, _StoredProjectAccess> _projects = {};

  RegisteredProjectHandles registerProject({
    required String projectName,
    required String initialFingerprint,
    required ProjectResourceReader readBytes,
    ProjectResourceIdentityLookup? readIdentity,
  }) {
    final workspaceHandle = WorkspaceHandle(_nextUniqueToken('ws_'));
    final projectHandle = ProjectHandle(_nextUniqueToken('prj_'));
    final expiresAt = _clock().toUtc().add(ttl);
    _projectsByWorkspace[workspaceHandle] = projectHandle;
    _projects[projectHandle] = _StoredProjectAccess(
      workspaceHandle: workspaceHandle,
      projectName: projectName,
      initialFingerprint: initialFingerprint,
      expiresAt: expiresAt,
      readBytes: readBytes,
      readIdentity: readIdentity,
    );
    return RegisteredProjectHandles(
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      expiresAt: expiresAt,
    );
  }

  ProjectWorkspaceAccess resolveProject(ProjectHandle handle) {
    final stored = _requireActive(handle);
    return ProjectWorkspaceAccess._(
      projectHandle: handle,
      projectName: stored.projectName,
      initialFingerprint: stored.initialFingerprint,
      expiresAt: stored.expiresAt,
      readBytes: (relativePath) => _readForHandle(handle, relativePath),
      readIdentity: stored.readIdentity,
    );
  }

  bool closeWorkspace(WorkspaceHandle handle) {
    final projectHandle = _projectsByWorkspace.remove(handle);
    if (projectHandle == null) return false;
    _projects.remove(projectHandle);
    return true;
  }

  _StoredProjectAccess _requireActive(ProjectHandle handle) {
    final stored = _projects[handle];
    if (stored == null) {
      throw const WorkspaceHandleException(
        'workspace.handle_unknown',
        'The requested project handle is unknown.',
      );
    }
    if (!_clock().toUtc().isBefore(stored.expiresAt)) {
      _remove(handle, stored);
      throw const WorkspaceHandleException(
        'workspace.handle_expired',
        'The requested project handle has expired.',
      );
    }
    return stored;
  }

  Future<List<int>> _readForHandle(
    ProjectHandle handle,
    String relativePath,
  ) async {
    final stored = _requireActive(handle);
    final bytes = await stored.readBytes(relativePath);
    _requireActive(handle);
    // ProjectWorkspaceAccess.readBytes is the single public freeze boundary.
    // Keeping this transfer owned avoids copying every resource twice inside
    // the handle store while preserving the post-read expiry check above.
    return bytes;
  }

  void _remove(ProjectHandle handle, _StoredProjectAccess stored) {
    _projects.remove(handle);
    _projectsByWorkspace.remove(stored.workspaceHandle);
  }

  String _nextUniqueToken(String prefix) {
    for (var attempt = 0; attempt < 32; attempt++) {
      final token = _tokenFactory(prefix).trim();
      if (!token.startsWith(prefix) || token.length <= prefix.length) {
        throw ArgumentError.value(
          token,
          'tokenFactory',
          'must return a nonblank token beginning with $prefix',
        );
      }
      final alreadyUsed =
          _projects.keys.any((handle) => handle.value == token) ||
              _projectsByWorkspace.keys.any((handle) => handle.value == token);
      if (!alreadyUsed) return token;
    }
    throw StateError('Unable to allocate a unique workspace handle.');
  }
}

final class _StoredProjectAccess {
  const _StoredProjectAccess({
    required this.workspaceHandle,
    required this.projectName,
    required this.initialFingerprint,
    required this.expiresAt,
    required this.readBytes,
    this.readIdentity,
  });

  final WorkspaceHandle workspaceHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader readBytes;
  final ProjectResourceIdentityLookup? readIdentity;
}

DateTime _systemClock() => DateTime.now().toUtc();

String _secureToken(String prefix) {
  final random = Random.secure();
  final body = List.generate(
    24,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '$prefix$body';
}
