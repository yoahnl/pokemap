import 'package:map_authoring/map_authoring.dart';

/// One editor-private owner of Authoring sessions keyed by canonical root.
abstract interface class EditorAuthoringLifecycleParticipant {
  /// Temporarily authorizes one project candidate during an editor switch.
  Future<void> allowCandidate(String canonicalRoot);

  /// Closes every session except [canonicalRoot].
  Future<void> retainOnly(String canonicalRoot);

  /// Closes the session for [canonicalRoot] when it exists.
  Future<void> closeProject(String canonicalRoot);

  /// Closes every owned session.
  Future<void> closeAll();
}

final class EditorAuthoringStaleSessionException implements Exception {
  const EditorAuthoringStaleSessionException();

  String get code => 'editor.authoring_session_stale';
  String get message =>
      'The project session is no longer active or an authorized candidate.';

  @override
  String toString() => 'EditorAuthoringStaleSessionException: $message';
}

final class EditorAuthoringSessionDiagnostics {
  const EditorAuthoringSessionDiagnostics({
    required this.retainedRoot,
    required this.candidateRoot,
    required this.liveSessions,
    required this.openingSessions,
    required this.retiringSessions,
    required this.activeOperations,
    required this.closeCount,
  });

  final String? retainedRoot;
  final String? candidateRoot;
  final int liveSessions;
  final int openingSessions;
  final int retiringSessions;
  final int activeOperations;
  final int closeCount;
}

/// Coordinates the editor's mono-project Authoring session lifecycle.
///
/// This coordinator is intentionally editor-private. The canonical Authoring
/// API, JSONL transport, and MCP server remain multi-workspace and keep their
/// explicit open/close semantics.
final class EditorAuthoringSessionLifecycle {
  EditorAuthoringSessionLifecycle({required ProjectFileReader fileReader})
      : _fileReader = fileReader;

  final ProjectFileReader _fileReader;
  final List<EditorAuthoringLifecycleParticipant> _participants = [];
  Future<void> _transition = Future<void>.value();
  String? _activeRoot;
  String? _candidateRoot;

  String? get activeRoot => _activeRoot;
  String? get candidateRoot => _candidateRoot;
  int get participantCount => _participants.length;

  void attach(EditorAuthoringLifecycleParticipant participant) {
    if (_participants.any((current) => identical(current, participant))) {
      return;
    }
    _participants.add(participant);
  }

  Future<void> activate(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot && _candidateRoot == null) return;
        try {
          await _allSettled(
            _participants.map(
              (participant) => participant.retainOnly(canonicalRoot),
            ),
          );
        } finally {
          // Concrete participants switch their admission boundary before
          // waiting for retired leases to drain. Commit the same fail-closed
          // root even when one close reports an error, so the editor cannot
          // silently reopen the previous project.
          _activeRoot = canonicalRoot;
          _candidateRoot = null;
        }
      });

  Future<void> prepareCandidate(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) {
          if (_candidateRoot == null) return;
          try {
            await _allSettled(
              _participants.map(
                (participant) => participant.retainOnly(canonicalRoot),
              ),
            );
          } finally {
            _candidateRoot = null;
          }
          return;
        }
        if (_candidateRoot == canonicalRoot) return;
        final previous = _candidateRoot;
        if (previous != null) {
          await _allSettled(
            _participants.map(
              (participant) => participant.closeProject(previous),
            ),
          );
        }
        await _allSettled(
          _participants.map(
            (participant) => participant.allowCandidate(canonicalRoot),
          ),
        );
        _candidateRoot = canonicalRoot;
      });

  Future<void> discard(String projectRootPath) => _serialize(() async {
        final canonicalRoot =
            await _fileReader.canonicalizeDirectory(projectRootPath);
        if (_activeRoot == canonicalRoot) return;
        try {
          await _allSettled(
            _participants.map(
              (participant) => participant.closeProject(canonicalRoot),
            ),
          );
        } finally {
          if (_candidateRoot == canonicalRoot) _candidateRoot = null;
        }
      });

  Future<void> closeAll() => _serialize(() async {
        await _allSettled(
          _participants.map((participant) => participant.closeAll()),
        );
        _activeRoot = null;
        _candidateRoot = null;
      });

  Future<void> _serialize(Future<void> Function() operation) {
    final current = _transition.then((_) => operation());
    _transition = current.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return current;
  }
}

Future<void> _allSettled(Iterable<Future<void>> operations) async {
  Object? firstError;
  StackTrace? firstStackTrace;
  await Future.wait<void>(
    operations.map((operation) async {
      try {
        await operation;
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }),
  );
  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }
}
