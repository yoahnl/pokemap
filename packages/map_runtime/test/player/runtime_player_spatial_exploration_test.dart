import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('exploration starts without seed and exposes no save or continuation',
      () async {
    final source = _SpatialSource();
    final saves = MemoryPlayerSaveGateway(identity: source.identity);
    final preferences = MemoryPlayerPreferencesGateway();
    final adapters = <FakeRuntimeSessionAdapter>[];
    final sessions = GameSessionController(
        adapterFactory: (descriptor) {
          final adapter = FakeRuntimeSessionAdapter(descriptor.sessionId);
          adapters.add(adapter);
          return adapter;
        },
        commitCheckpoint: saves.commit);
    final coordinator = RuntimePlayerCoordinator(
        gameSource: source,
        saveGateway: saves,
        preferencesGateway: preferences,
        newGameFlow: _SpatialFlow(),
        sessionController: sessions,
        externalExit: MemoryRuntimeExternalExit(),
        explorationOnly: true,
        defaultSaveSlot:
            const RuntimePlayerLoadSlot(profileId: 'profile', slotId: 'slot'));
    addTearDown(coordinator.dispose);
    await coordinator.initialize();
    expect(
        coordinator.snapshot.isActionEnabled(RuntimePlayerAction.continueGame),
        isFalse);
    expect(coordinator.snapshot.isActionEnabled(RuntimePlayerAction.load),
        isFalse);
    final launched = await coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: coordinator.snapshot.revision));
    expect(launched.status, RuntimePlayerCommandStatus.accepted);
    expect(source.initialState, isNull);
    expect(adapters, hasLength(1));
    adapters.single.emitRunning();
    await coordinator.settle();
    await coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.openMenu,
        snapshotRevision: coordinator.snapshot.revision));
    await coordinator.settle();
    expect(coordinator.snapshot.isActionEnabled(RuntimePlayerAction.save),
        isFalse);
    expect(coordinator.snapshot.isActionEnabled(RuntimePlayerAction.openParty),
        isFalse);
    expect(
        coordinator.snapshot.isActionEnabled(RuntimePlayerAction.openOptions),
        isTrue);
    final save = await coordinator.dispatch(RuntimePlayerCommand(
        action: RuntimePlayerAction.save,
        snapshotRevision: coordinator.snapshot.revision));
    expect(save.status, RuntimePlayerCommandStatus.unavailable);
    expect(saves.commits, isEmpty);
  });
}

final class _SpatialSource implements RuntimeGameSource {
  GameState? initialState;
  @override
  final identity = GameIdentity(
      gameId: 'org.example.spatial',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v9,
      saveFormat: 1,
      compatibilityId: 'spatial');
  @override
  String get displayTitle => 'Explore';
  @override
  Set<ProjectPauseActionId> get defaultVisiblePauseActions => {
        ProjectPauseActionId.resume,
        ProjectPauseActionId.options,
        ProjectPauseActionId.returnToTitle
      };
  @override
  Future<GameSessionDescriptor> createSessionDescriptor(
      {required GameSessionLaunchMode launchMode,
      required String profileId,
      required String slotId,
      String? saveReadHandle,
      GameState? initialGameState}) async {
    initialState = initialGameState;
    return GameSessionDescriptor(
        sessionId: 'session',
        sessionToken: 'token',
        identity: identity,
        profileId: profileId,
        slotId: slotId,
        launchMode: launchMode,
        installedVersionHandle: 'install',
        saveReadHandle: saveReadHandle,
        initialGameState: initialGameState,
        runtimeApiVersion: '1.4.0',
        grantedCapabilities: const {'map3d@1'},
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions());
  }
}

final class _SpatialFlow implements RuntimeNewGameFlowPort {
  @override
  Future<RuntimeNewGamePreparation> prepare() async =>
      RuntimeNewGamePreparation(
          projectRevision: 'spatial',
          project: const ProjectManifest(
              name: 'Spatial',
              version: ProjectVersion.v9,
              maps: [],
              tilesets: [],
              settings: ProjectSettings(dimension: ProjectDimension.threeD)),
          startMap: MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v9,
              size: const GridSize(width: 8, height: 8),
              layers: const [],
              spatialScene: MapSpatialScene(width: 8, depth: 8)));
  @override
  Future<String> readCurrentProjectRevision() async => 'spatial';
  @override
  void clear() {}
}
