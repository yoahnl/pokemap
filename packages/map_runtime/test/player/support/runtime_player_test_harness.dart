import 'dart:async';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

final class RuntimePlayerTestHarness {
  RuntimePlayerTestHarness({
    PlayerSaveSummary? latestSave,
    Future<void>? descriptorGate,
    Object? descriptorError,
  })  : source = MemoryRuntimeGameSource(
          descriptorGate: descriptorGate,
          descriptorError: descriptorError,
        ),
        preferences = MemoryPlayerPreferencesGateway(),
        exit = MemoryRuntimeExternalExit() {
    saves = MemoryPlayerSaveGateway(
      identity: source.identity,
      latestSave: latestSave,
    );
    sessions = GameSessionController(
      adapterFactory: (descriptor) {
        final adapter = FakeRuntimeSessionAdapter(descriptor.sessionId);
        adapters.add(adapter);
        return adapter;
      },
      commitCheckpoint: saves.commit,
    );
    coordinator = RuntimePlayerCoordinator(
      gameSource: source,
      saveGateway: saves,
      preferencesGateway: preferences,
      sessionController: sessions,
      externalExit: exit,
    );
    exit.disposedProbe = () => coordinator.isDisposed;
  }

  final MemoryRuntimeGameSource source;
  late final MemoryPlayerSaveGateway saves;
  final MemoryPlayerPreferencesGateway preferences;
  final MemoryRuntimeExternalExit exit;
  late final GameSessionController sessions;
  late final RuntimePlayerCoordinator coordinator;
  final adapters = <FakeRuntimeSessionAdapter>[];

  FakeRuntimeSessionAdapter get adapter => adapters.single;

  Future<void> dispose() => coordinator.dispose();
}

final class SessionDescriptorRequest {
  const SessionDescriptorRequest({
    required this.launchMode,
    required this.profileId,
    required this.slotId,
    required this.saveReadHandle,
  });

  final GameSessionLaunchMode launchMode;
  final String profileId;
  final String slotId;
  final String? saveReadHandle;
}

final class MemoryRuntimeGameSource implements RuntimeGameSource {
  MemoryRuntimeGameSource({
    this.descriptorGate,
    this.descriptorError,
  });

  final Future<void>? descriptorGate;
  final Object? descriptorError;
  final requests = <SessionDescriptorRequest>[];
  int _sessionSerial = 0;

  @override
  final GameIdentity identity = GameIdentity(
    gameId: 'com.pokemap.runtime-player-test',
    gameVersion: '1.2.0',
    projectFormat: ProjectFormat.v2,
    saveFormat: 1,
    compatibilityId: 'runtime-player-test-v1',
  );

  @override
  String get displayTitle => 'Runtime Player Test';

  @override
  Future<GameSessionDescriptor> createSessionDescriptor({
    required GameSessionLaunchMode launchMode,
    required String profileId,
    required String slotId,
    String? saveReadHandle,
  }) async {
    requests.add(
      SessionDescriptorRequest(
        launchMode: launchMode,
        profileId: profileId,
        slotId: slotId,
        saveReadHandle: saveReadHandle,
      ),
    );
    await descriptorGate;
    if (descriptorError case final error?) throw error;
    _sessionSerial++;
    return GameSessionDescriptor(
      sessionId: 'runtime-player-session-$_sessionSerial',
      sessionToken: 'runtime-player-secret-$_sessionSerial',
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      launchMode: launchMode,
      installedVersionHandle: 'installed-runtime-player-test',
      saveReadHandle: saveReadHandle,
      runtimeApiVersion: '1.0.0',
      grantedCapabilities: const <String>{'battle.v1'},
      locale: 'fr',
      accessibility: const GameSessionAccessibilityOptions(),
    );
  }
}

final class MemoryPlayerSaveGateway implements PlayerSaveGateway {
  MemoryPlayerSaveGateway({
    required this.identity,
    PlayerSaveSummary? latestSave,
  }) : _latestSave = latestSave {
    if (latestSave case final save?) {
      _summaries[save.address] = save;
    }
  }

  @override
  final GameIdentity identity;
  final _summaries = <SaveSlotAddress, PlayerSaveSummary>{};
  final commits = <GameSessionCheckpointCommit>[];
  final commitAttempts = <GameSessionCheckpointCommit>[];
  PlayerSaveSummary? _latestSave;
  Object? commitError;
  Completer<void>? commitGate;
  int activeCommits = 0;
  int maxConcurrentCommits = 0;

  set latestSave(PlayerSaveSummary? value) {
    _latestSave = value;
    if (value case final save?) {
      _summaries[save.address] = save;
    }
  }

  @override
  Future<void> commit(GameSessionCheckpointCommit request) async {
    commitAttempts.add(request);
    activeCommits++;
    if (activeCommits > maxConcurrentCommits) {
      maxConcurrentCommits = activeCommits;
    }
    try {
      await commitGate?.future;
      if (commitError case final error?) throw error;
      commits.add(request);
      latestSave = PlayerSaveSummary(
        address: SaveSlotAddress(
          gameId: request.descriptor.identity.gameId,
          profileId: request.descriptor.profileId,
          slotId: request.descriptor.slotId,
        ),
        updatedAt: request.checkpoint.updatedAt,
        playTimeSeconds: request.checkpoint.playTimeSeconds,
        status: request.status,
        canContinue: request.status == SaveStatus.active,
      );
    } finally {
      activeCommits--;
    }
  }

  @override
  Future<String?> openReadHandle(SaveSlotAddress address) async {
    return _summaries.containsKey(address)
        ? 'save:${address.profileId}:${address.slotId}'
        : null;
  }

  @override
  Future<PlayerSaveSummary?> readLatestSummary() async => _latestSave;

  @override
  Future<PlayerSaveSummary?> readSummary(SaveSlotAddress address) async {
    return _summaries[address];
  }
}

final class MemoryPlayerPreferencesGateway implements PlayerPreferencesGateway {
  PlayerPreferencesSnapshot current = const PlayerPreferencesSnapshot(
    locale: 'fr',
    accessibility: GameSessionAccessibilityOptions(),
  );
  int loads = 0;
  int saves = 0;
  Object? loadError;

  @override
  Future<PlayerPreferencesSnapshot> load() async {
    loads++;
    if (loadError case final error?) throw error;
    return current;
  }

  @override
  Future<void> save(PlayerPreferencesSnapshot preferences) async {
    saves++;
    current = preferences;
  }
}

final class MemoryRuntimeExternalExit implements RuntimeExternalExit {
  int calls = 0;
  bool disposedWhenCalled = false;
  bool Function()? disposedProbe;

  @override
  Future<void> returnToHost() async {
    calls++;
    disposedWhenCalled = disposedProbe?.call() ?? false;
  }
}

final class FakeRuntimeSessionAdapter
    implements GameSessionAdapter, RuntimeWorldServicePort {
  FakeRuntimeSessionAdapter(this.sessionId);

  final String sessionId;
  final calls = <String>[];
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();
  final _worldServices =
      StreamController<RuntimeWorldServiceSnapshot?>.broadcast();
  final worldServiceCommands = <RuntimeWorldServiceCommand>[];
  RuntimeWorldServiceSnapshot? _worldServiceSnapshot;
  GameSessionCheckpoint? checkpoint;
  int disposeCalls = 0;
  bool gameplayLocked = false;
  final completionAcknowledgements = <bool>[];
  Object? stopError;
  Object? disposeError;

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  @override
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot =>
      _worldServiceSnapshot;

  @override
  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots =>
      _worldServices.stream;

  void emit(GameSessionAdapterEvent event) => _events.add(event);

  void emitRunning() => emit(GameSessionRunning(sessionId));

  void publishWorldService(RuntimeWorldServiceSnapshot? snapshot) {
    _worldServiceSnapshot = snapshot;
    _worldServices.add(snapshot);
  }

  void emitCompletion(GameCompletionEvent completion) {
    emit(GameSessionCompleted(completion));
  }

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async {
    calls.add('completion:$accepted');
    completionAcknowledgements.add(accepted);
  }

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    calls.add('checkpoint');
    return checkpoint;
  }

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    disposeCalls++;
    await _worldServices.close();
    await _events.close();
    if (disposeError case final error?) throw error;
  }

  @override
  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  ) async {
    worldServiceCommands.add(command);
    return const RuntimeWorldServiceCommandResult(
      status: RuntimeWorldServiceCommandStatus.accepted,
    );
  }

  @override
  bool handleInput(RuntimeInputEvent event) {
    calls.add('input:${event.control.name}:${event.phase.name}');
    return true;
  }

  @override
  Future<void> lockGameplayForCompletion() async {
    calls.add('lock-completion');
    gameplayLocked = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
  }

  @override
  Future<void> prepare(GameSessionDescriptor descriptor) async {
    calls.add('prepare');
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
  }

  @override
  Future<void> start() async {
    calls.add('start');
  }

  @override
  Future<void> stop(GameSessionExitReason reason) async {
    calls.add('stop:${reason.name}');
    if (stopError case final error?) throw error;
  }
}

PlayerSaveSummary compatiblePlayerSave(GameIdentity identity) {
  return PlayerSaveSummary(
    address: SaveSlotAddress(
      gameId: identity.gameId,
      profileId: 'player',
      slotId: 'slot_1',
    ),
    updatedAt: DateTime.utc(2026, 7, 25, 12),
    playTimeSeconds: 120,
    status: SaveStatus.active,
    canContinue: true,
  );
}

Future<void> launchHarnessToPlaying(RuntimePlayerTestHarness harness) async {
  await harness.coordinator.initialize();
  final result = await harness.coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.newGame,
      snapshotRevision: harness.coordinator.snapshot.revision,
      payload: const RuntimePlayerLoadSlot(
        profileId: 'player',
        slotId: 'slot_1',
      ),
    ),
  );
  if (result.status != RuntimePlayerCommandStatus.accepted) {
    throw StateError('The test player session did not launch.');
  }
  harness.adapter.emitRunning();
  await harness.coordinator.settle();
}

Future<void> openHarnessPause(RuntimePlayerTestHarness harness) async {
  final result = await harness.coordinator.dispatch(
    RuntimePlayerCommand(
      action: RuntimePlayerAction.openMenu,
      snapshotRevision: harness.coordinator.snapshot.revision,
    ),
  );
  if (result.status != RuntimePlayerCommandStatus.accepted) {
    throw StateError('The test pause menu did not open.');
  }
}

GameSessionCheckpoint testPlayerCheckpoint({
  DateTime? updatedAt,
}) {
  final timestamp = updatedAt ?? DateTime.utc(2026, 7, 25, 14);
  return GameSessionCheckpoint(
    saveId: 'runtime-player-save',
    createdAt: DateTime.utc(2026, 7, 25, 12),
    updatedAt: timestamp,
    playTimeSeconds: 240,
    state: const <String, Object?>{
      'currentMapId': 'runtime-player-map',
    },
  );
}

GameCompletionEvent testPlayerCompletion(RuntimePlayerTestHarness harness) {
  final completedAt = DateTime.utc(2026, 7, 25, 15);
  return GameCompletionEvent(
    sessionId: harness.adapter.sessionId,
    gameId: harness.source.identity.gameId,
    endingId: 'main-ending',
    outcome: GameCompletionOutcome.victory,
    completedAt: completedAt,
    playTimeSeconds: 240,
    result: const GameResultSnapshot(
      title: 'Victoire',
      summary: 'La région est sauvée.',
    ),
    credits: const GameCreditsSnapshot(
      title: 'Runtime Player Test',
      author: 'PokeMap',
      endingLabel: 'Fin principale',
    ),
    destination: GameCompletionDestination.playerChoice,
    allowPostGameContinue: false,
    finalCheckpoint: testPlayerCheckpoint(updatedAt: completedAt),
  );
}
