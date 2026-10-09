import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart'
    as glb;
import '../../../../packages/map_runtime/test/session/spatial_exploration_game_session_runtime_test.dart'
    as fixtures;

const _gameId = 'games.test.spatial-durable';
const _saveId = '018f255f-2d50-4f4f-8aa2-c893ae06b8c1';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final directory = Platform.environment['AVELUNE_SPATIAL_RESTART_ROOT'];
  final phase = Platform.environment['AVELUNE_SPATIAL_RESTART_PHASE'];
  if (directory == null || !['write', 'read'].contains(phase)) return;
  test('spatial durable restart $phase', () async {
    final root = Directory(await Directory(directory).resolveSymbolicLinks());
    final support = Directory(p.join(root.path, 'support'));
    if (phase == 'write') await _install(root, support);
    expect(Directory(p.join(root.path, 'authoring')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'game.avelunegame')).existsSync(), isFalse);
    final library = await GameLibraryStore(supportRoot: support).load();
    final game = library.library.games.single;
    final launch = await InstalledGameLaunchResolver(
      supportRoot: support,
      hostCompatibility: aveluneHostCompatibility(),
    ).resolve(game);
    final store = HubSaveStore(supportRoot: support, identity: launch.identity);
    final gateway = HubPlayerSaveGateway(store: store);
    final address = SaveSlotAddress(
      gameId: _gameId,
      profileId: 'profile',
      slotId: 'slot',
    );
    final previous =
        phase == 'read' ? (await store.read(address)).envelope! : null;
    final descriptor = _descriptor(launch, previous);
    SpatialExplorationGameSessionRuntime? runtime;
    final factory = HubInProcessSessionFactory(
      launch: launch,
      saves: store,
      commitCheckpoint: gateway.commit,
      dimension: ProjectDimension.threeD,
      mountGame: (_) async => fail('A spatial game mounted its 2D runtime.'),
      unmountGame: (_) async {},
      mountSpatialSession: (mounted) async => runtime = mounted,
      unmountSpatialSession: (_) async {},
      now: () => DateTime.utc(2026, 10, 8, 2),
    );
    final adapter = factory(descriptor);
    addTearDown(adapter.dispose);
    await adapter.prepare(descriptor);
    await adapter.start();
    final session = runtime!.session!;
    expect(
      p.isWithin(support.path, session.bundle.projectRootDirectory),
      isTrue,
    );
    expect(
      session.bundle.runtimeImageAbsolutePathsById.values.every(
        (path) => p.isWithin(support.path, path),
      ),
      isTrue,
    );
    if (phase == 'write') {
      await fixtures.waitForValue(session.storyActive, (value) => value);
      expect(session.movement.canTraverseActor(4, 4, 4, 5.7), isFalse);
      await expectLater(adapter.captureCheckpoint(), throwsStateError);
      session.frames(1);
      await expectLater(adapter.captureCheckpoint(), throwsStateError);
      for (var i = 0; i < 70; i++) {
        session.frames(.1);
        await Future<void>.delayed(Duration.zero);
      }
      await runtime!.gameplayReady;
      expect(session.storyActive.value, isFalse);
      expect(session.movement.canTraverseActor(4, 4, 4, 5.7), isTrue);
      runtime!.handleInput(
        const RuntimeInputEvent.press(RuntimeInputControl.down),
      );
      for (var i = 0; i < 15; i++) {
        session.frame(.05);
      }
      runtime!.handleInput(
        const RuntimeInputEvent.release(RuntimeInputControl.down),
      );
      expect(session.movement.z, greaterThan(5.5));
      await runtime!.pause();
      final checkpoint = (await adapter.captureCheckpoint())!;
      await gateway.commit(
        GameSessionCheckpointCommit(
          descriptor: descriptor.publicContext,
          checkpoint: checkpoint,
          status: SaveStatus.active,
          trigger: GameSessionCheckpointTrigger.manual,
        ),
      );
    } else {
      await runtime!.gameplayReady;
      expect(
        session.movement.spatialPosition,
        const GameStateSaveEnvelopeMapper()
            .restore(previous!)
            .playerSpatialPosition,
      );
      expect(session.movement.canTraverseActor(4, 4, 4, 5.7), isTrue);
      session.frames(10);
    }
    final state = runtime!.gameStateSnapshot;
    expect(state.trainerProfile.money, 25);
    expect(state.storyFlags.activeFlags, contains('gate-open'));
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      hasLength(1),
    );
    final door = state.spatialWorldState.modelState('field', 'door')!;
    expect(door.blocksMovement, isFalse);
    expect(door.normalizedTime, 1);
    expect(session.worldStateProvider!().modelState('field', 'door'), door);
    expect(state.spatialWorldState.actorState('field', 'npc')!.x, 6.5);
    expect(session.frames(0)['npc:npc']!.x, 6.5);
    final current = (await store.read(address)).envelope!;
    await adapter.dispose();
    var invalidLoads = 0;
    var recoveredBackup = false;
    if (phase == 'read') {
      invalidLoads = await _invalidLoadsPreserveBytes(
        root,
        support,
        launch,
        store,
        current,
      );
      await store.write(current);
      final newer = const SaveEnvelopeCodec().create(
        identity: launch.identity,
        profileId: current.profileId,
        slotId: current.slotId,
        saveId: current.saveId,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt.add(const Duration(minutes: 1)),
        status: current.status,
        playTimeSeconds: current.playTimeSeconds,
        state: current.state,
      );
      await store.write(newer);
      await _saveFile(support).writeAsString('{broken', flush: true);
      final recovered = await store.read(address);
      expect(recovered.status, SaveSlotReadStatus.recoveredFromBackup);
      expect(recovered.envelope!.checksum, current.checksum);
      recoveredBackup = true;
    }
    await File(p.join(root.path, '$phase.json')).writeAsString(
      jsonEncode({
        'phase': phase,
        'pid': pid,
        'sourceRemoved': true,
        'installedAssetsOnly': true,
        'saveChecksum': current.checksum.value,
        'position': state.playerSpatialPosition!.toJson(),
        'doorOpen': true,
        'npcMoved': true,
        'progressRestored': true,
        'invalidLoadsPreservedBytes': invalidLoads,
        'corruptSaveRecoveredBackup': recoveredBackup,
      }),
      flush: true,
    );
  });
}

Future<void> _install(Directory root, Directory support) async {
  final authoring = Directory(p.join(root.path, 'authoring'));
  final source = Directory(
    p.normalize(p.join(Directory.current.path, '..', 'hgss_first_map')),
  );
  final original = await loadProjectManifestFromFile(
    p.join(source.path, 'project.json'),
  );
  final modelBytes = _doorGlb();
  final model = ProjectModel3dEntry(
    id: 'door-model',
    name: 'Door',
    sourceAssetId: 'nb2-door',
    relativePath: 'assets/models3d/door-model.glb',
    inspection: const GlbModel3dInspector().inspect(modelBytes),
  );
  final npc = MapEntity(
    id: 'npc',
    kind: MapEntityKind.npc,
    pos: const GridPos(x: 4, y: 2),
    npc: MapEntityNpcData(characterId: original.characters.single.id),
  );
  final map = MapData(
    version: ProjectVersion.v9,
    id: 'field',
    name: 'Field',
    size: const GridSize(width: 8, height: 8),
    layers: const [],
    entities: [npc],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      instances: [
        SpatialModelInstance(
          id: 'door',
          modelId: model.id,
          blocksMovement: true,
          position: Model3dVector3(x: 4, y: 0, z: 5),
        ),
      ],
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
    ),
  );
  final base = RuntimeMapBundle(
    manifest: original,
    map: map,
    projectRootDirectory: authoring.path,
    tilesetAbsolutePathsById: const {},
  );
  final cinematic =
      fixtures.npcCinematicBundle(base).manifest.cinematics.single;
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    SceneNode(
      id: 'cinematic',
      kind: SceneNodeKind.cinematic,
      payload: SceneCinematicPayload(cinematicId: cinematic.id),
    ),
    SceneNode(
      id: 'open',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.playModelAnimation(
          mapId: 'field',
          instanceId: 'door',
          animationIndex: 0,
          blocksMovementAfter: false,
        ),
      ),
    ),
    SceneNode(
      id: 'reward',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.giveMoney(amount: 25),
      ),
    ),
    SceneNode(
      id: 'fact',
      kind: SceneNodeKind.action,
      payload: SceneActionPayload.consequence(
        SceneConsequence.setFact(factId: 'gate-open', value: true),
      ),
    ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  final scene = SceneAsset(
    id: 'arrival',
    name: 'Arrival',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var i = 0; i < nodes.length - 1; i++)
          SceneEdge(
            id: 'edge_$i',
            fromNodeId: nodes[i].id,
            fromPortId: 'completed',
            toNodeId: nodes[i + 1].id,
            kind:
                nodes[i].kind == SceneNodeKind.cinematic
                    ? SceneEdgeKind.cinematicCompleted
                    : nodes[i].kind == SceneNodeKind.action
                    ? SceneEdgeKind.actionCompleted
                    : SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
  final project = ProjectManifest(
    version: ProjectVersion.v9,
    name: 'Durable 3D',
    settings: original.settings,
    pokemon: original.pokemon.copyWith(enabled: false),
    newGame: ProjectNewGameConfig(
      enabled: true,
      startMapId: 'field',
      playerName: 'Yoahn',
      playerAvatarCharacterIds: [original.characters.single.id],
    ),
    maps: const [
      ProjectMapEntry(
        id: 'field',
        name: 'Field',
        relativePath: 'maps/field.json',
      ),
    ],
    tilesets: original.tilesets,
    characters: original.characters,
    models3d: [model],
    cinematics: [cinematic],
    scenes: [scene],
    facts: [NarrativeFactDefinition(id: 'gate-open', label: 'Gate open')],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        fixtures.spatialEvent(
          NarrativeEventSourceRef.mapEnter('field'),
          scene.id,
        ),
      ],
      legacyClaims: const [],
    ),
  );
  await Directory(p.join(authoring.path, 'maps')).create(recursive: true);
  await File(
    p.join(authoring.path, 'project.json'),
  ).writeAsString(jsonEncode(project.toJson()));
  await File(
    p.join(authoring.path, 'maps/field.json'),
  ).writeAsString(jsonEncode(map.toJson()));
  for (final file in source.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.png')) continue;
    final target = File(
      p.join(authoring.path, p.relative(file.path, from: source.path)),
    );
    await target.parent.create(recursive: true);
    await file.copy(target.path);
  }
  final modelFile = File(p.join(authoring.path, model.relativePath));
  await modelFile.parent.create(recursive: true);
  await modelFile.writeAsBytes(modelBytes);
  final sourceCatalog =
      jsonDecode(
            await File(
              p.join(source.path, 'assets/.pokemap-assets.json'),
            ).readAsString(),
          )
          as Map<String, dynamic>;
  final artifact = ContentArtifactRef.fromBytes(
    modelBytes,
    mediaType: 'model/gltf-binary',
  );
  final digest = artifact.hexDigest;
  final blobDirectory = Directory(
    p.join(authoring.path, 'assets/.pokemap-store'),
  );
  await blobDirectory.create(recursive: true);
  for (final record in sourceCatalog['records'] as List) {
    if (!(record['logicalPath'] as String).endsWith('.png')) continue;
    final key = (record['artifact']['digest'] as String).substring(7);
    await File(
      p.join(authoring.path, record['logicalPath'] as String),
    ).copy(p.join(blobDirectory.path, '$key.blob'));
  }
  await File(
    p.join(blobDirectory.path, '$digest.blob'),
  ).writeAsBytes(modelBytes);
  await File(
    p.join(authoring.path, 'assets/.pokemap-assets.json'),
  ).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'records': [
        for (final record in sourceCatalog['records'] as List)
          if ((record['logicalPath'] as String).endsWith('.png')) record,
        {
          'id': model.sourceAssetId,
          'logicalPath': model.relativePath,
          'artifact': artifact.toJson(),
          'usages': <String>[],
          'tags': <String>[],
        },
      ],
    }),
  );
  final package = File(p.join(root.path, 'game.avelunegame'));
  await const CanonicalGamePackageExportService()
      .exportToFile(
        projectRoot: authoring,
        outputFile: package,
        mode: GamePackageExportMode.localTest,
        profile: GamePackageExportProfile(
          gameId: _gameId,
          gameVersion: '1.0.0',
          title: 'Durable 3D',
          authorName: 'Test',
          defaultLocale: 'fr',
          supportedLocales: ['fr'],
        ),
      )
      .catchError((Object error) {
        if (error is GamePackageExportException) {
          throw StateError(
            'Export ${error.code} at ${error.path}: ${error.message}',
          );
        }
        throw error;
      });
  await authoring.delete(recursive: true);
  await GamePackageInstaller(
    supportRoot: support,
    inspector: GamePackageInspector(
      hostCompatibility: aveluneHostCompatibility(),
    ),
    availableDiskBytes: (_) async => 1 << 40,
    loadSmoke: (_, _) async {},
    prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
  ).install(package, source: GamePackageInstallSource.localFile);
  await package.delete();
}

List<int> _doorGlb() {
  final source = glb.animatedGlb(
    edit: (json) {
      json['nodes'][0]['translation'] = [0, 0, 0];
      json['nodes'][0]['scale'] = [1, 1, 1];
      json['accessors'][0]['min'] = [-.5, 0, -.1];
      json['accessors'][0]['max'] = [.5, 2, .1];
    },
  );
  final bytes = Uint8List.fromList(source);
  final data = ByteData.sublistView(bytes);
  final offset = 28 + data.getUint32(12, Endian.little);
  final positions = [-.5, 0.0, -.1, .5, 0.0, .1, .5, 2.0, .1];
  for (var i = 0; i < positions.length; i++) {
    data.setFloat32(offset + i * 4, positions[i], Endian.little);
  }
  return bytes;
}

GameSessionDescriptor _descriptor(
  InstalledGameLaunchContext launch,
  SaveEnvelope? save,
) => GameSessionDescriptor(
  sessionId: 'session-$pid',
  sessionToken: 'test-token',
  identity: launch.identity,
  profileId: 'profile',
  slotId: 'slot',
  launchMode:
      save == null
          ? GameSessionLaunchMode.newGame
          : GameSessionLaunchMode.continueGame,
  saveReadHandle: save == null ? null : hubSaveReadHandle(save),
  installedVersionHandle: launch.installedVersionHandle,
  runtimeApiVersion: launch.runtimeApiVersion,
  grantedCapabilities: launch.grantedCapabilities,
  locale: 'fr',
  accessibility: const GameSessionAccessibilityOptions(),
  initialGameState:
      save != null
          ? null
          : GameState(
            saveId: _saveId,
            currentMapId: 'field',
            playerPosition: const GridPos(x: 4, y: 4),
            playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4),
            trainerProfile: const TrainerProfile(
              name: 'Yoahn',
              avatarCharacterId: 'voyageur-psdk',
            ),
          ),
);

File _saveFile(Directory support) => File(
  p.join(support.path, 'saves', _gameId, 'profile', 'slot', 'save.json'),
);

Future<int> _invalidLoadsPreserveBytes(
  Directory root,
  Directory support,
  InstalledGameLaunchContext launch,
  HubSaveStore store,
  SaveEnvelope saved,
) async {
  final state = const GameStateSaveEnvelopeMapper().restore(saved);
  final invalid = [
    state.copyWith(currentMapId: 'absent-map'),
    state.copyWith(
      spatialWorldState: state.spatialWorldState.setModelState(
        'field',
        'absent-door',
        SpatialModelRuntimeState(
          modelId: 'door-model',
          animationIndex: 0,
          normalizedTime: 1,
          blocksMovement: false,
        ),
      ),
    ),
    state.copyWith(
      spatialWorldState: state.spatialWorldState.setActorState(
        'field',
        'absent-npc',
        SpatialActorRuntimeState(x: 6.5, z: 2.5, facing: EntityFacing.south),
      ),
    ),
    state.copyWith(
      spatialWorldState: state.spatialWorldState.setModelState(
        'field',
        'door',
        SpatialModelRuntimeState(
          modelId: 'door-model',
          animationIndex: 7,
          normalizedTime: 1,
          blocksMovement: false,
        ),
      ),
    ),
  ];
  for (final next in invalid) {
    final proposal = const GameStateSaveEnvelopeMapper().create(
      identity: launch.identity,
      profileId: saved.profileId,
      slotId: saved.slotId,
      saveId: saved.saveId,
      createdAt: saved.createdAt,
      updatedAt: saved.updatedAt,
      status: saved.status,
      playTimeSeconds: saved.playTimeSeconds,
      gameState: next,
    );
    await store.write(proposal);
    final before = await _saveFile(support).readAsBytes();
    var mounted = false;
    final adapter = HubInProcessSessionFactory(
      launch: launch,
      saves: store,
      dimension: ProjectDimension.threeD,
      mountGame: (_) async {},
      unmountGame: (_) async {},
      mountSpatialSession: (_) async => mounted = true,
      unmountSpatialSession: (_) async {},
    )(_descriptor(launch, proposal));
    await adapter.prepare(_descriptor(launch, proposal));
    await expectLater(
      adapter.start(),
      throwsA(anyOf(isA<StateError>(), isA<FormatException>())),
    );
    await adapter.dispose();
    expect(mounted, isFalse);
    expect(await _saveFile(support).readAsBytes(), before);
  }
  return invalid.length;
}
