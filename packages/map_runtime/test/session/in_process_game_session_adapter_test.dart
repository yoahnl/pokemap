import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('in-process adapter owns one disposable runtime graph', () async {
    late _FakeInProcessRuntime runtime;
    final descriptor = _descriptor();
    final adapter = InProcessGameSessionAdapter(
      runtimeFactory: (createdDescriptor) {
        expect(createdDescriptor, descriptor);
        return runtime = _FakeInProcessRuntime(createdDescriptor.sessionId);
      },
    );
    final events = <GameSessionAdapterEvent>[];
    final subscription = adapter.events.listen(events.add);

    await adapter.prepare(descriptor);
    await adapter.start();
    await Future<void>.delayed(Duration.zero);
    expect(
      events.whereType<GameSessionReady>().single.sessionId,
      descriptor.sessionId,
    );
    expect(
      events
          .whereType<GameSessionLoading>()
          .map((event) => event.progress.stage),
      containsAll(<String>['project', 'assets']),
    );
    expect(events.whereType<GameSessionRunning>(), hasLength(1));

    await adapter.pause();
    await adapter.resume();
    expect(
        runtime.calls,
        containsAllInOrder(<String>[
          'load',
          'pause',
          'resume',
        ]));

    runtime.emit(
      GameSessionDiagnostic(
        descriptor.sessionId,
        const GameSessionDiagnosticData(
          code: 'runtime.notice',
          severity: GameSessionDiagnosticSeverity.info,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<GameSessionDiagnostic>(), hasLength(1));

    await adapter.stop(GameSessionExitReason.hub);
    await adapter.dispose();
    expect(runtime.calls.sublist(runtime.calls.length - 2), <String>[
      'stop:hub',
      'dispose',
    ]);
    await subscription.cancel();
  });

  test('in-process adapter forwards contextual service state and commands',
      () async {
    final runtime = _FakeContextualRuntime('session-a');
    final adapter = InProcessGameSessionAdapter(
      runtimeFactory: (_) => runtime,
    );
    final snapshots = <RuntimeWorldServiceSnapshot?>[];
    final subscription = adapter.worldServiceSnapshots.listen(snapshots.add);

    await adapter.prepare(_descriptor());
    runtime.publishShop();
    await Future<void>.delayed(Duration.zero);

    expect(adapter.worldServiceSnapshot?.request.kind,
        RuntimeWorldServiceKind.shop);
    expect(snapshots.last?.revision, 3);

    final result = await adapter.dispatchWorldService(
      const RuntimeWorldServiceCommand(
        action: RuntimeWorldServiceAction.close,
        snapshotRevision: 3,
      ),
    );
    expect(result.status, RuntimeWorldServiceCommandStatus.accepted);
    expect(runtime.commands.single.action, RuntimeWorldServiceAction.close);

    await adapter.dispose();
    expect(snapshots.last, isNull);
    await subscription.cancel();
  });

  test('in-process adapter forwards runtime-owned pause data', () async {
    final runtime = _FakePauseDataRuntime('session-a');
    final adapter = InProcessGameSessionAdapter(
      runtimeFactory: (_) => runtime,
    );

    await adapter.prepare(_descriptor());
    final details = await adapter.loadPauseDetails();
    final pauseMenuState = await adapter.loadPauseMenuState();

    expect(
      details[RuntimePlayerPauseSection.party]!.entries.single.title,
      'Salamèche',
    );
    expect(runtime.calls, contains('pause-details'));
    expect(
      pauseMenuState.visibilityOverrides,
      <ProjectPauseActionId, bool>{ProjectPauseActionId.pokedex: false},
    );
    await adapter.dispose();
  });
}

GameSessionDescriptor _descriptor() => GameSessionDescriptor(
      sessionId: 'session-a',
      sessionToken: 'secret',
      identity: GameIdentity(
        gameId: 'org.example.adventure',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v2,
        saveFormat: 1,
        compatibilityId: 'story-v1',
      ),
      profileId: 'player-1',
      slotId: 'slot-1',
      launchMode: GameSessionLaunchMode.newGame,
      installedVersionHandle: 'install-a',
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{},
      locale: 'fr-FR',
      accessibility: const GameSessionAccessibilityOptions(),
    );

class _FakeInProcessRuntime implements InProcessGameSessionRuntime {
  _FakeInProcessRuntime(this.sessionId);

  final String sessionId;
  final calls = <String>[];
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  void emit(GameSessionAdapterEvent event) => _events.add(event);

  @override
  Future<void> load(GameSessionProgressReporter reportProgress) async {
    calls.add('load');
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'project',
        current: 1,
        total: 2,
      ),
    );
    reportProgress(
      const GameSessionLoadingProgress(
        stage: 'assets',
        current: 2,
        total: 2,
      ),
    );
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async => null;

  @override
  Future<void> lockGameplayForCompletion() async =>
      calls.add('lock-completion');

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async =>
      calls.add('completion:$accepted');

  @override
  Future<void> stop(GameSessionExitReason reason) async =>
      calls.add('stop:${reason.name}');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _events.close();
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    calls.add('input:${event.control.name}');
    return true;
  }
}

final class _FakeContextualRuntime extends _FakeInProcessRuntime
    implements RuntimeWorldServicePort {
  _FakeContextualRuntime(super.sessionId);

  final _worldServices =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  final commands = <RuntimeWorldServiceCommand>[];
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServices.stream;

  void publishShop() {
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 3,
      request: const OpenShopService(
        interactionId: 'npc.merchant',
        shopId: 'mart',
      ),
      stage: RuntimeWorldServiceStage.active,
    );
    _worldServiceSnapshot = snapshot;
    _worldServices.add(snapshot);
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async {
    commands.add(command);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  @override
  Future<void> dispose() async {
    await _worldServices.close();
    await super.dispose();
  }
}

final class _FakePauseDataRuntime extends _FakeInProcessRuntime
    implements RuntimePlayerPauseDataPort {
  _FakePauseDataRuntime(super.sessionId);

  @override
  Future<PlayerPauseMenuState> loadPauseMenuState() async {
    calls.add('pause-menu-state');
    return const PlayerPauseMenuState.empty().setActionVisibility(
      ProjectPauseActionId.pokedex,
      visible: false,
    );
  }

  @override
  Future<Map<RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>>
      loadPauseDetails() async {
    calls.add('pause-details');
    return <RuntimePlayerPauseSection, RuntimePlayerPauseDetailSnapshot>{
      RuntimePlayerPauseSection.party: RuntimePlayerPauseDetailSnapshot(
        section: RuntimePlayerPauseSection.party,
        title: 'Équipe',
        entries: <RuntimePlayerDetailEntrySnapshot>[
          RuntimePlayerDetailEntrySnapshot(
            id: 'party.0',
            title: 'Salamèche',
          ),
        ],
      ),
    };
  }
}
