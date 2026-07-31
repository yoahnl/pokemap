import 'dart:math';

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

/// Authorized read-only access associated with an opaque project handle.
///
/// The canonical filesystem root remains captured privately by [readBytes].
final class ProjectWorkspaceAccess {
  ProjectWorkspaceAccess._({
    required this.projectHandle,
    required this.projectName,
    required this.initialFingerprint,
    required this.expiresAt,
    required ProjectResourceReader readBytes,
  }) : _readBytes = readBytes;

  final ProjectHandle projectHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader _readBytes;

  Future<List<int>> readBytes(String relativePath) async =>
      List<int>.unmodifiable(await _readBytes(relativePath));
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
    return List<int>.unmodifiable(bytes);
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
  });

  final WorkspaceHandle workspaceHandle;
  final String projectName;
  final String initialFingerprint;
  final DateTime expiresAt;
  final ProjectResourceReader readBytes;
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
