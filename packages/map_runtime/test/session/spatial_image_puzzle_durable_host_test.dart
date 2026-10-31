import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../scene_image_puzzle_durable_host_test.dart'
    show puzzleDefinition, writePuzzleMedia;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('3D real durable host saves arrangement, cold Continue resumes, failed move preserves bytes', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create();
    addTearDown(fixture.dispose);
    await fixture.open();
    await fixture.active();
    expect(fixture.writes, 1);
    expect((await fixture.saved()).trainerProfile.money, 0);
    await fixture.send(RuntimeWorldServiceAction.rotate, target: '0');
    final before = await fixture.file.readAsBytes();
    final saved = await fixture.saved();
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.gameStateSnapshot.trainerProfile.money, 25);
    await fixture.open(continueGame: true);
    await fixture.active();
    expect(
      (fixture.runtime.worldServiceSnapshot!.content
              as RuntimeImagePuzzleServiceContent)
          .progress,
      saved.imagePuzzleState.puzzlesById['mosaic'],
    );
    final persistedBeforeFailure = await fixture.file.readAsBytes();
    fixture.fail = true;
    expect(
      (await fixture.send(
        RuntimeWorldServiceAction.move,
        target: '0',
        slot: '0',
      )).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect((await fixture.saved()).imagePuzzleState, saved.imagePuzzleState);
    expect(await fixture.file.readAsBytes(), persistedBeforeFailure);
    fixture.fail = false;
    await fixture.send(RuntimeWorldServiceAction.move, target: '0', slot: '0');
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.unavailable,
    );
    for (var i = 0; i < 3; i++) {
      await fixture.send(RuntimeWorldServiceAction.rotate, target: '0');
    }
    await fixture.send(RuntimeWorldServiceAction.confirm);
    await fixture.runtime.gameplayReady;
    expect(
      fixture
          .runtime
          .gameStateSnapshot
          .imagePuzzleState
          .puzzlesById['mosaic']!
          .isSolved,
      isTrue,
    );
    expect(
      (await fixture.saved()).imagePuzzleState.puzzlesById['mosaic']!.isSolved,
      isTrue,
    );
    expect(before, isNotEmpty);
  });
}

class SpatialImagePuzzleDurableHostFixture {
  SpatialImagePuzzleDurableHostFixture(this.root, this.bundle, this.initial);
  final Directory root;
  final RuntimeMapBundle bundle;
  final GameState initial;
  SpatialExplorationGameSessionRuntime? _runtime;
  SpatialExplorationGameSessionRuntime get runtime => _runtime!;
  File get file => File('${root.path}/save.avelunesave');
  DateTime now = DateTime(2026, 10, 30, 23, 59);
  int writes = 0;
  bool fail = false;
  Future<void>? gate;
  static Future<SpatialImagePuzzleDurableHostFixture> create({
    SceneAsset? sceneOverride,
    String? qaDirectory,
    bool pendingIngredients = false,
    ProjectManifest Function(ProjectManifest)? configureProject,
    MapData Function(MapData)? configureMap,
    GameState Function(GameState)? configureInitialState,
  }) async {
    final qa = Directory(
      qaDirectory ?? Platform.environment['AVELUNE_QA_ROOT'] ?? '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('durable-3d-');
    await writePuzzleMedia(root);
    final picture = img.encodePng(img.Image(width: 32, height: 32));
    await File('${root.path}/hero.png').writeAsBytes(picture);
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            sourceAssetId: 'sheet',
            frames: const [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
    final scene = SceneAsset(
      id: 'puzzle',
      name: 'Craft',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'money',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              pendingIngredients
                  ? SceneConsequence.giveItem(itemId: 'fruit', quantity: 1)
                  : SceneConsequence.giveMoney(amount: 25),
            ),
          ),
          SceneNode(
            id: 'puzzle',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openImagePuzzle(
                definition: puzzleDefinition,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'a',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'money',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'b',
            fromNodeId: 'money',
            fromPortId: 'completed',
            toNodeId: 'puzzle',
            kind: SceneEdgeKind.actionCompleted,
          ),
          for (final port in ['solved', 'quit'])
            SceneEdge(
              id: port,
              fromNodeId: 'puzzle',
              fromPortId: port,
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );
    var map = MapData(
      version: ProjectVersion.v9,
      id: 'field',
      name: 'Field',
      size: const GridSize(width: 8, height: 8),
      layers: const [],
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 4, z: 4)),
      ),
    );
    map = configureMap?.call(map) ?? map;
    var project = ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Craft',
      settings: const ProjectSettings(
        dimension: ProjectDimension.threeD,
        defaultPlayerCharacterId: 'hero',
      ),
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'field'),
      maps: const [
        ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'map.json'),
      ],
      tilesets: const [],
      characters: [character],
      scenes: [sceneOverride ?? scene],
      pokemon: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'items.json'},
      ),
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        legacyClaims: const [],
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: 'evt_019abcde-0000-7000-8000-000000000001',
              name: 'Craft',
              source: NarrativeEventSourceRef.mapEnter('field'),
              conditions: const [],
              sceneId: 'puzzle',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
              resetPolicy: const NarrativeEventResetPolicy.never(),
            ),
            enabled: true,
          ),
        ],
      ),
    );
    project = configureProject?.call(project) ?? project;
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/map.json').writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/items.json').writeAsString(
      jsonEncode(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'fruit',
              displayName: 'Fruit',
              pocketId: 'materials',
            ),
            ProjectItemDefinition(
              id: 'ball',
              displayName: 'Ball',
              pocketId: 'balls',
            ),
          ],
        ).toJson(),
      ),
    );
    final bundle = RuntimeMapBundle(
      manifest: project,
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {
        'sheet': '${root.path}/hero.png',
      },
    );
    final initial = GameState(
      saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
      currentMapId: 'field',
      playerPosition: const GridPos(x: 4, y: 4),
      playerSpatialPosition: PlayerSpatialPosition(x: 4, z: 4),
      trainerProfile: const TrainerProfile(
        name: 'Leaf',
        money: 0,
        avatarCharacterId: 'hero',
      ),
      bag: const Bag(entries: [BagEntry(itemId: 'fruit', quantity: 4)]),
    );
    return SpatialImagePuzzleDurableHostFixture(
      root,
      bundle,
      configureInitialState?.call(initial) ?? initial,
    );
  }

  GameSessionDescriptor descriptor(bool continueGame) => GameSessionDescriptor(
    sessionId: 'puzzle',
    sessionToken: 'token',
    identity: GameIdentity(
      gameId: 'org.example.crafting',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v9,
      saveFormat: 2,
      compatibilityId: 'crafting',
    ),
    profileId: 'profile',
    slotId: 'slot',
    launchMode: continueGame
        ? GameSessionLaunchMode.continueGame
        : GameSessionLaunchMode.newGame,
    saveReadHandle: continueGame ? 'save' : null,
    initialGameState: continueGame ? null : initial,
    installedVersionHandle: 'installed',
    runtimeApiVersion: '1.4.0',
    grantedCapabilities: {
      'map3d@1',
      SpatialGameplayCapabilities.periodicRewardConditionCapabilityId,
      SpatialGameplayCapabilities.periodicRewardCapabilityId,
      SpatialGameplayCapabilities.storyCapabilityId,
      SpatialGameplayCapabilities.deferredCraftingCapabilityId,
    },
    locale: 'fr',
    accessibility: const GameSessionAccessibilityOptions(),
  );
  Future<void> open({
    bool continueGame = false,
    GameSessionCheckpointCommitter? checkpointCommitter,
    Future<SaveEnvelope?> Function()? saveLoader,
  }) async {
    await _runtime?.dispose();
    final descriptor = this.descriptor(continueGame);
    _runtime = SpatialExplorationGameSessionRuntime(
      descriptor: descriptor,
      now: () => now,
      projectFilePath: () async => '${root.path}/project.json',
      initialSave: continueGame
          ? saveLoader ??
                () async =>
                    const SaveEnvelopeCodec().decode(await file.readAsString())
          : null,
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      commitCheckpoint:
          checkpointCommitter ??
          (request) async {
            await gate;
            if (fail) throw StateError('disk full');
            final envelope = const SaveEnvelopeCodec().create(
              identity: descriptor.identity,
              profileId: 'profile',
              slotId: 'slot',
              saveId: initial.saveId,
              createdAt: DateTime.utc(2026, 10, 30),
              updatedAt: now.toUtc(),
              status: SaveStatus.active,
              playTimeSeconds: 0,
              state: request.checkpoint.state,
            );
            final temporary = File('${file.path}.tmp');
            await temporary.writeAsBytes(
              const SaveEnvelopeCodec().encodeUtf8(envelope),
              flush: true,
            );
            await temporary.rename(file.path);
            writes++;
          },
      mountSession: (_) async {},
      unmountSession: (_) async {},
    );
    await runtime.load((_) {});
  }

  Future<void> active() async {
    for (var i = 0; i < 300 && runtime.worldServiceSnapshot == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(
      runtime.worldServiceSnapshot,
      isNotNull,
      reason: '${runtime.session?.interactionError.value}',
    );
  }

  Future<RuntimeWorldServiceCommandResult> send(
    RuntimeWorldServiceAction action, {
    String? target,
    String? slot,
  }) => runtime.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: runtime.worldServiceSnapshot!.revision,
      targetId: target,
      secondaryTargetId: slot,
    ),
  );
  Future<GameState> saved() async => const GameStateSaveEnvelopeMapper()
      .restore(const SaveEnvelopeCodec().decode(await file.readAsString()));
  Future<void> dispose() async {
    await _runtime?.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
