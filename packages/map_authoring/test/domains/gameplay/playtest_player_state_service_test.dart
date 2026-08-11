import 'dart:async';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  late WorkspaceHandleStore handles;
  late RegisteredProjectHandles firstProject;
  late RegisteredProjectHandles secondProject;
  var tokenSequence = 0;

  setUp(() {
    tokenSequence = 0;
    handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '$prefix${++tokenSequence}',
    );
    firstProject = _register(handles, 'first');
    secondProject = _register(handles, 'second');
  });

  test('separates playtest permissions and receipts from authoring mutations',
      () async {
    final deniedStart = PlaytestPlayerStateService(
      handles: handles,
      playtest: _FakePlaytestPort(),
      actor: AuthoringActor(actorId: 'read-only'),
    );
    await expectLater(
      deniedStart.start(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        request: _request('session-denied'),
      ),
      throwsA(_serviceError('playtest.permission_denied')),
    );

    final runOnly = PlaytestPlayerStateService(
      handles: handles,
      playtest: _FakePlaytestPort(),
      actor: AuthoringActor(
        actorId: 'runner',
        permissions: const [AuthoringPermissionScope.playtestRun],
      ),
    );
    await runOnly.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-run-only'),
    );
    await expectLater(
      runOnly.executeBagCommand(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        sessionId: 'session-run-only',
        command: PlaytestPlayerStateCommand.giveItem(
          commandId: 'give-denied',
          itemId: 'potion',
          quantity: 2,
        ),
      ),
      throwsA(_serviceError('playtest.permission_denied')),
    );

    final service = _service(handles);
    await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-full'),
    );
    final receipt = await service.executeBagCommand(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      sessionId: 'session-full',
      command: PlaytestPlayerStateCommand.giveItem(
        commandId: 'give-potion',
        itemId: 'potion',
        quantity: 2,
      ),
    );

    expect(receipt.operation, 'bag.give');
    expect(receipt.snapshot.state['bag'], {'potion': 2});
    expect(
        receipt.toJson(), containsPair('receiptKind', 'playtest_player_state'));
    expect(receipt.toJson(), containsPair('durable', false));
    expect(
      receipt.toJson(),
      containsPair('requiredPermission', 'playtest.control'),
    );
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .singleWhere((entry) => entry.id == 'item.create')
          .requiredPermissions,
      contains(AuthoringPermission.projectWrite),
    );
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .singleWhere((entry) => entry.id == 'campaign.new_game.update')
          .requiredPermissions,
      contains(AuthoringPermission.projectWrite),
    );
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((entry) => entry.id),
      isNot(contains('bag.give')),
    );

    final terminalReceipt = await service.stop(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      sessionId: 'session-full',
    );
    expect(terminalReceipt.terminalState, PlaytestSessionState.stopped);
    await expectLater(
      service.executeBagCommand(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        sessionId: 'session-full',
        command: PlaytestPlayerStateCommand.giveItem(
          commandId: 'give-after-stop',
          itemId: 'potion',
          quantity: 1,
        ),
      ),
      throwsA(_serviceError('playtest.session_unknown')),
    );
  });

  test('rejects missing sessions and foreign workspace ownership', () async {
    final service = _service(handles);
    final command = PlaytestPlayerStateCommand.giveItem(
      commandId: 'give-potion',
      itemId: 'potion',
      quantity: 1,
    );

    await expectLater(
      service.executeBagCommand(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        sessionId: 'session-missing',
        command: command,
      ),
      throwsA(_serviceError('playtest.session_unknown')),
    );
    await expectLater(
      service.start(
        workspaceHandle: secondProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        request: _request('session-mismatched-start'),
      ),
      throwsA(
        isA<WorkspaceHandleException>().having(
          (error) => error.code,
          'code',
          'workspace.project_mismatch',
        ),
      ),
    );

    await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-owned'),
    );
    await expectLater(
      service.executeBagCommand(
        workspaceHandle: secondProject.workspaceHandle,
        projectHandle: secondProject.projectHandle,
        sessionId: 'session-owned',
        command: command,
      ),
      throwsA(_serviceError('playtest.session_ownership_mismatch')),
    );
  });

  test('bag commands stay in memory and never accept a save path', () async {
    final sandbox = await Directory.systemTemp.createTemp('item-session-');
    addTearDown(() => sandbox.delete(recursive: true));
    final projectRoot = await Directory('${sandbox.path}/project').create();
    final outsideSave = File('${sandbox.path}/user-save.json');
    await outsideSave.writeAsString('untouched');
    final project = handles.registerProject(
      projectName: 'bounded',
      initialFingerprint: 'sha256:${'a' * 64}',
      readBytes: (relativePath) =>
          File('${projectRoot.path}/$relativePath').readAsBytes(),
    );
    final service = _service(handles);

    await service.start(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      request: _request('session-bounded'),
    );
    final receipt = await service.executeBagCommand(
      workspaceHandle: project.workspaceHandle,
      projectHandle: project.projectHandle,
      sessionId: 'session-bounded',
      command: PlaytestPlayerStateCommand.consumeItem(
        commandId: 'consume-potion',
        itemId: 'potion',
        quantity: 1,
      ),
    );

    expect(await outsideSave.readAsString(), 'untouched');
    expect(receipt.toJson().toString(), isNot(contains(sandbox.path)));
    expect(receipt.toJson().keys, isNot(contains('savePath')));
  });

  test('reserves a session ID before awaiting the runtime port', () async {
    final playtest = _ControlledPlaytestPort();
    final service = PlaytestPlayerStateService(
      handles: handles,
      playtest: playtest,
      actor: AuthoringActor(
        actorId: 'controller',
        permissions: const [
          AuthoringPermissionScope.playtestRun,
          AuthoringPermissionScope.playtestControl,
        ],
      ),
    );
    final first = service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-concurrent'),
    );
    await Future<void>.delayed(Duration.zero);
    final duplicateError = expectLater(
      service.start(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        request: _request('session-concurrent'),
      ),
      throwsA(_serviceError('playtest.session_exists')),
    );
    await Future<void>.delayed(Duration.zero);
    final startCountBeforeRelease = playtest.startCount;
    playtest.release();

    await first;
    await duplicateError;
    expect(startCountBeforeRelease, 1);
  });

  test('evicts a terminal failed session so its ID can be reused', () async {
    final failed = _FailingPlaytestSession(_request('session-retry'));
    final playtest = _SequencedPlaytestPort([
      (_) => failed,
      _FakePlaytestSession.new,
    ]);
    final service = PlaytestPlayerStateService(
      handles: handles,
      playtest: playtest,
      actor: AuthoringActor(
        actorId: 'controller',
        permissions: const [
          AuthoringPermissionScope.playtestRun,
          AuthoringPermissionScope.playtestControl,
        ],
      ),
    );
    await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-retry'),
    );

    await expectLater(
      service.executeBagCommand(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        sessionId: 'session-retry',
        command: PlaytestPlayerStateCommand.giveItem(
          commandId: 'fail-command',
          itemId: 'potion',
          quantity: 1,
        ),
      ),
      throwsStateError,
    );
    expect(failed.state, PlaytestSessionState.failed);

    final restarted = await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-retry'),
    );
    expect(restarted.state, PlaytestSessionState.running);
    expect(playtest.startCount, 2);
  });

  test('evicts a terminal failed stop so its ID can be reused', () async {
    final failed = _FailingStopPlaytestSession(_request('session-stop-retry'));
    final playtest = _SequencedPlaytestPort([
      (_) => failed,
      _FakePlaytestSession.new,
    ]);
    final service = PlaytestPlayerStateService(
      handles: handles,
      playtest: playtest,
      actor: AuthoringActor(
        actorId: 'controller',
        permissions: const [
          AuthoringPermissionScope.playtestRun,
          AuthoringPermissionScope.playtestControl,
        ],
      ),
    );
    await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-stop-retry'),
    );

    await expectLater(
      service.stop(
        workspaceHandle: firstProject.workspaceHandle,
        projectHandle: firstProject.projectHandle,
        sessionId: 'session-stop-retry',
      ),
      throwsStateError,
    );
    expect(failed.state, PlaytestSessionState.failed);

    final restarted = await service.start(
      workspaceHandle: firstProject.workspaceHandle,
      projectHandle: firstProject.projectHandle,
      request: _request('session-stop-retry'),
    );
    expect(restarted.state, PlaytestSessionState.running);
    expect(playtest.startCount, 2);
  });
}

PlaytestPlayerStateService _service(WorkspaceHandleStore handles) =>
    PlaytestPlayerStateService(
      handles: handles,
      playtest: _FakePlaytestPort(),
      actor: AuthoringActor(
        actorId: 'controller',
        permissions: const [
          AuthoringPermissionScope.playtestRun,
          AuthoringPermissionScope.playtestControl,
        ],
      ),
    );

RegisteredProjectHandles _register(WorkspaceHandleStore handles, String name) =>
    handles.registerProject(
      projectName: name,
      initialFingerprint: 'sha256:${'a' * 64}',
      readBytes: (_) async => const <int>[],
    );

PlaytestStartRequest _request(String sessionId) => PlaytestStartRequest(
      sessionId: sessionId,
      projectId: 'project-under-test',
      projectRevision: 'sha256:${'a' * 64}',
      scenarioId: 'item-session',
      seed: 42,
    );

Matcher _serviceError(String code) => isA<PlaytestPlayerStateServiceException>()
    .having((error) => error.code, 'code', code);

final class _FakePlaytestPort implements PlaytestPort {
  @override
  Future<PlaytestSession> start(PlaytestStartRequest request) async =>
      _FakePlaytestSession(request);
}

final class _ControlledPlaytestPort implements PlaytestPort {
  final Completer<void> _gate = Completer<void>();
  var startCount = 0;

  void release() => _gate.complete();

  @override
  Future<PlaytestSession> start(PlaytestStartRequest request) async {
    startCount += 1;
    await _gate.future;
    return _FakePlaytestSession(request);
  }
}

typedef _PlaytestSessionFactory = PlaytestSession Function(
  PlaytestStartRequest request,
);

final class _SequencedPlaytestPort implements PlaytestPort {
  _SequencedPlaytestPort(this._factories);

  final List<_PlaytestSessionFactory> _factories;
  var startCount = 0;

  @override
  Future<PlaytestSession> start(PlaytestStartRequest request) async {
    startCount += 1;
    return _factories.removeAt(0)(request);
  }
}

final class _FailingPlaytestSession implements PlaytestSession {
  _FailingPlaytestSession(this.request);

  final PlaytestStartRequest request;
  var _state = PlaytestSessionState.running;

  @override
  Stream<PlaytestEvent> get events => const Stream.empty();

  @override
  String get sessionId => request.sessionId;

  @override
  PlaytestSessionState get state => _state;

  @override
  Future<PlaytestCommandResult> execute(PlaytestCommand command) async {
    _state = PlaytestSessionState.failed;
    throw StateError('command failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FailingStopPlaytestSession extends _FakePlaytestSession {
  _FailingStopPlaytestSession(super.request);

  @override
  Future<PlaytestReceipt> stop() async {
    _state = PlaytestSessionState.failed;
    throw StateError('stop failed');
  }
}

base class _FakePlaytestSession implements PlaytestSession {
  _FakePlaytestSession(this.request);

  final PlaytestStartRequest request;
  final Map<String, int> _bag = {};
  var _sequence = 0;
  var _state = PlaytestSessionState.running;

  @override
  Stream<PlaytestEvent> get events => const Stream.empty();

  @override
  String get sessionId => request.sessionId;

  @override
  PlaytestSessionState get state => _state;

  @override
  Future<PlaytestCommandResult> execute(PlaytestCommand command) async {
    final itemId = command.arguments['itemId']! as String;
    final quantity = command.arguments['quantity']! as int;
    final before = _bag[itemId] ?? 0;
    final after = command.operation == 'bag.give'
        ? before + quantity
        : (before - quantity).clamp(0, before);
    if (after == 0) {
      _bag.remove(itemId);
    } else {
      _bag[itemId] = after;
    }
    _sequence += 1;
    return PlaytestCommandResult(
      commandId: command.commandId,
      snapshot: await snapshot(),
      diff: PlaytestStateDiff([
        PlaytestStateChange(
          path: 'bag.$itemId',
          before: before,
          after: after,
        ),
      ]),
    );
  }

  @override
  Future<PlaytestSnapshot> snapshot() async => PlaytestSnapshot(
        projectRevision: request.projectRevision,
        sequence: _sequence,
        state: {'bag': Map<String, int>.from(_bag)},
      );

  @override
  Future<void> pause() async {
    _state = PlaytestSessionState.paused;
  }

  @override
  Future<void> resume() async {
    _state = PlaytestSessionState.running;
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) =>
      throw UnimplementedError();

  @override
  Future<PlaytestReceipt> stop() async {
    _state = PlaytestSessionState.stopped;
    final digest = (await snapshot()).stateDigest;
    return PlaytestReceipt(
      receiptId: 'receipt-${request.sessionId}',
      sessionId: request.sessionId,
      projectId: request.projectId,
      projectRevision: request.projectRevision,
      scenarioId: request.scenarioId,
      seed: request.seed,
      terminalState: PlaytestSessionState.stopped,
      startedAtUtc: '2026-08-11T10:00:00.000Z',
      finishedAtUtc: '2026-08-11T10:00:01.000Z',
      commandCount: _sequence,
      finalSnapshotDigest: digest,
    );
  }
}
