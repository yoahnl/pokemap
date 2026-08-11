import '../contracts/playtest_contracts.dart';
import '../ports/playtest_port.dart';
import '../security/authoring_permission.dart';
import '../workspace/workspace_handle_store.dart';

final class PlaytestPlayerStateServiceException implements Exception {
  const PlaytestPlayerStateServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PlaytestPlayerStateServiceException($code): $message';
}

final class PlaytestPlayerStateCommand {
  PlaytestPlayerStateCommand._({
    required String commandId,
    required this.operation,
    required String itemId,
    required this.quantity,
  })  : commandId = _nonBlank(commandId, 'commandId'),
        itemId = _nonBlank(itemId, 'itemId') {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }
  }

  factory PlaytestPlayerStateCommand.giveItem({
    required String commandId,
    required String itemId,
    required int quantity,
  }) =>
      PlaytestPlayerStateCommand._(
        commandId: commandId,
        operation: 'bag.give',
        itemId: itemId,
        quantity: quantity,
      );

  factory PlaytestPlayerStateCommand.consumeItem({
    required String commandId,
    required String itemId,
    required int quantity,
  }) =>
      PlaytestPlayerStateCommand._(
        commandId: commandId,
        operation: 'bag.consume',
        itemId: itemId,
        quantity: quantity,
      );

  final String commandId;
  final String operation;
  final String itemId;
  final int quantity;

  PlaytestCommand toPlaytestCommand() => PlaytestCommand(
        commandId: commandId,
        operation: operation,
        arguments: <String, Object?>{
          'itemId': itemId,
          'quantity': quantity,
        },
      );
}

final class PlaytestPlayerStateSessionHandle {
  const PlaytestPlayerStateSessionHandle({
    required this.sessionId,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.state,
  });

  final String sessionId;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final PlaytestSessionState state;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionId': sessionId,
        'workspaceHandle': workspaceHandle.value,
        'projectHandle': projectHandle.value,
        'state': state.name,
      };
}

final class PlaytestPlayerStateReceipt {
  const PlaytestPlayerStateReceipt({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.sessionId,
    required this.commandId,
    required this.operation,
    required this.snapshot,
    required this.diff,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final String sessionId;
  final String commandId;
  final String operation;
  final PlaytestSnapshot snapshot;
  final PlaytestStateDiff diff;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptKind': 'playtest_player_state',
        'durable': false,
        'requiredPermission': AuthoringPermissionScope.playtestControl.wireName,
        'workspaceHandle': workspaceHandle.value,
        'projectHandle': projectHandle.value,
        'sessionId': sessionId,
        'commandId': commandId,
        'operation': operation,
        'snapshot': snapshot.toJson(),
        'diff': diff.toJson(),
      };
}

final class PlaytestPlayerStateService {
  PlaytestPlayerStateService({
    required WorkspaceHandleStore handles,
    required PlaytestPort playtest,
    required AuthoringActor actor,
  })  : _handles = handles,
        _playtest = playtest,
        _actor = actor;

  final WorkspaceHandleStore _handles;
  final PlaytestPort _playtest;
  final AuthoringActor _actor;
  final Map<String, _BoundPlaytestSession> _sessions = {};
  final Set<String> _startingSessionIds = {};

  Future<PlaytestPlayerStateSessionHandle> start({
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required PlaytestStartRequest request,
  }) async {
    _requirePermission(AuthoringPermissionScope.playtestRun);
    _handles.requireWorkspaceOwnsProject(workspaceHandle, projectHandle);
    if (_sessions.containsKey(request.sessionId) ||
        !_startingSessionIds.add(request.sessionId)) {
      throw const PlaytestPlayerStateServiceException(
        'playtest.session_exists',
        'The playtest session ID is already active.',
      );
    }
    try {
      final session = await _playtest.start(request);
      if (session.sessionId != request.sessionId ||
          session.state != PlaytestSessionState.running) {
        await _stopInvalidSession(session);
        throw const PlaytestPlayerStateServiceException(
          'playtest.session_invalid',
          'The playtest port returned an invalid session.',
        );
      }
      _sessions[session.sessionId] = _BoundPlaytestSession(
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        session: session,
      );
      return PlaytestPlayerStateSessionHandle(
        sessionId: session.sessionId,
        workspaceHandle: workspaceHandle,
        projectHandle: projectHandle,
        state: session.state,
      );
    } finally {
      _startingSessionIds.remove(request.sessionId);
    }
  }

  Future<PlaytestPlayerStateReceipt> executeBagCommand({
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required String sessionId,
    required PlaytestPlayerStateCommand command,
  }) async {
    _requirePermission(AuthoringPermissionScope.playtestControl);
    final bound = _requireOwnedSession(
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      sessionId: sessionId,
    );
    _handles.requireWorkspaceOwnsProject(workspaceHandle, projectHandle);
    if (bound.session.state != PlaytestSessionState.running) {
      throw PlaytestPlayerStateServiceException(
        'playtest.session_not_running',
        'The playtest session is ${bound.session.state.name}.',
      );
    }
    late PlaytestCommandResult result;
    try {
      result = await bound.session.execute(command.toPlaytestCommand());
    } catch (_) {
      if (bound.session.state == PlaytestSessionState.failed ||
          bound.session.state == PlaytestSessionState.stopped) {
        _sessions.remove(sessionId);
      }
      rethrow;
    }
    if (result.commandId != command.commandId) {
      _sessions.remove(sessionId);
      await _stopInvalidSession(bound.session);
      throw const PlaytestPlayerStateServiceException(
        'playtest.command_receipt_invalid',
        'The playtest command receipt does not match the request.',
      );
    }
    return PlaytestPlayerStateReceipt(
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      sessionId: sessionId,
      commandId: command.commandId,
      operation: command.operation,
      snapshot: result.snapshot,
      diff: result.diff,
    );
  }

  Future<PlaytestReceipt> stop({
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required String sessionId,
  }) async {
    _requirePermission(AuthoringPermissionScope.playtestControl);
    final bound = _requireOwnedSession(
      workspaceHandle: workspaceHandle,
      projectHandle: projectHandle,
      sessionId: sessionId,
    );
    try {
      final receipt = await bound.session.stop();
      _sessions.remove(sessionId);
      return receipt;
    } catch (_) {
      if (bound.session.state == PlaytestSessionState.failed ||
          bound.session.state == PlaytestSessionState.stopped) {
        _sessions.remove(sessionId);
      }
      rethrow;
    }
  }

  _BoundPlaytestSession _requireOwnedSession({
    required WorkspaceHandle workspaceHandle,
    required ProjectHandle projectHandle,
    required String sessionId,
  }) {
    final bound = _sessions[sessionId];
    if (bound == null) {
      throw const PlaytestPlayerStateServiceException(
        'playtest.session_unknown',
        'A live playtest session is required for player-state commands.',
      );
    }
    if (bound.workspaceHandle != workspaceHandle ||
        bound.projectHandle != projectHandle) {
      throw const PlaytestPlayerStateServiceException(
        'playtest.session_ownership_mismatch',
        'The playtest session belongs to another workspace or project.',
      );
    }
    return bound;
  }

  void _requirePermission(AuthoringPermissionScope permission) {
    if (_actor.allows(permission)) return;
    throw PlaytestPlayerStateServiceException(
      'playtest.permission_denied',
      'The actor lacks ${permission.wireName}.',
    );
  }

  Future<void> _stopInvalidSession(PlaytestSession session) async {
    if (session.state == PlaytestSessionState.running ||
        session.state == PlaytestSessionState.paused) {
      await session.stop();
    }
  }
}

final class _BoundPlaytestSession {
  const _BoundPlaytestSession({
    required this.workspaceHandle,
    required this.projectHandle,
    required this.session,
  });

  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final PlaytestSession session;
}

String _nonBlank(String value, String field) {
  if (value.trim() != value || value.isEmpty) {
    throw ArgumentError.value(value, field, 'must be nonblank');
  }
  return value;
}
