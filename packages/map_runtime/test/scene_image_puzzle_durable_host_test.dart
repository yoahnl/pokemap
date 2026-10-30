import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:image/image.dart' as img;
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

final puzzleDefinition = ImagePuzzleDefinition(
  puzzleId: 'mosaic',
  imageResourceId: 'mosaic-image',
  rows: 1,
  columns: 2,
  initialPieces: [
    const ImagePuzzlePiece(pieceId: 0, slot: 2),
    const ImagePuzzlePiece(pieceId: 1, slot: 1),
  ],
);
final puzzleCatalog = ItemCatalogSnapshot.fromCatalog(
  const ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ProjectItemDefinition(
        id: 'fruit',
        displayName: 'Fruit',
        pocketId: 'materials',
      ),
      ProjectItemDefinition(id: 'ball', displayName: 'Ball', pocketId: 'balls'),
    ],
  ),
);

Future<void> writePuzzleMedia(Directory root) async {
  final bytes = img.encodePng(img.Image(width: 40, height: 20));
  final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
  final file = File('${root.path}/${assetBlobStorageKey(artifact)}');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  await File('${root.path}/$assetCatalogStorageKey').writeAsString(
    jsonEncode(
      AssetCatalog(
        records: [
          AssetRecord(
            id: 'mosaic-source',
            logicalPath: 'assets/mosaic.png',
            artifact: artifact,
          ),
        ],
      ).toJson(),
    ),
  );
  await File('${root.path}/$projectMediaCatalogStorageKey').writeAsString(
    jsonEncode(
      ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'mosaic-image',
            label: 'Mosaic',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'mosaic-source',
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'image/png',
              container: 'png',
              codec: 'png',
              sizeBytes: bytes.length,
              width: 40,
              height: 20,
            ),
          ),
        ],
      ).toJson(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final unrelated in [0, 80]) {
    test(
      '2D puzzle first and repeated durable moves touch only save with $unrelated unrelated maps',
      () async {
        final fixture = await _Fixture.create(unrelatedMaps: unrelated);
        addTearDown(fixture.dispose);
        final run = fixture.run();
        await fixture.active();
        expect(fixture.repository.writes, 1);
        final baseZone = Zone.current;
        for (final slot in ['0', '2']) {
          final reads = <String>[], writes = <String>[], renames = <String>[];
          await IOOverrides.runZoned(
            () => fixture.send(
              RuntimeWorldServiceAction.move,
              target: '0',
              slot: slot,
            ),
            createFile: (path) => _CountedFile(
              baseZone.run(() => File(path)),
              reads,
              writes,
              renames,
            ),
          );
          expect(reads, isEmpty);
          expect(writes, ['${fixture.file.path}.tmp']);
          expect(renames, [fixture.file.path]);
          expect((await fixture.saved()).trainerProfile.money, 0);
        }
        await fixture.send(RuntimeWorldServiceAction.cancel);
        expect(await run, isA<NarrativeSceneExecutionCompleted>());
        expect(
          (await fixture.game.debugReadNarrativeGameStateForTest())
              .trainerProfile
              .money,
          25,
        );
        final saved = await fixture.saved();
        await fixture.reopen(saved, day: DateTime(2026, 10, 31));
        final resume = fixture.run();
        await fixture.active();
        expect(
          (fixture.controller.worldServiceSnapshot!.content
                  as RuntimeImagePuzzleServiceContent)
              .progress,
          saved.imagePuzzleState.puzzlesById['mosaic'],
        );
        await fixture.send(RuntimeWorldServiceAction.cancel);
        await resume;
      },
    );
  }
  test('2D failed move preserves file bytes and later Scene failure preserves durable puzzle', () async {
    final fixture = await _Fixture.create(failsLater: true);
    addTearDown(fixture.dispose);
    final run = fixture.run();
    await fixture.active();
    final before = await fixture.file.readAsBytes();
    fixture.repository.fail = true;
    expect(
      (await fixture.send(
        RuntimeWorldServiceAction.move,
        target: '0',
        slot: '0',
      )).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await fixture.file.readAsBytes(), before);
    fixture.repository.fail = false;
    await fixture.send(RuntimeWorldServiceAction.move, target: '0', slot: '0');
    await fixture.send(RuntimeWorldServiceAction.confirm);
    expect(await run, isA<NarrativeSceneExecutionFailed>());
    final committed = await fixture.game.debugReadNarrativeGameStateForTest();
    expect(
      committed.imagePuzzleState,
      (await fixture.saved()).imagePuzzleState,
    );
    expect(committed.trainerProfile.money, 0);
  });
  test(
    '2D session cold Continue restores saved puzzle without rewriting bytes',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final running = fixture.run();
      await fixture.active();
      await fixture.send(RuntimeWorldServiceAction.rotate, target: '0');
      await fixture.send(RuntimeWorldServiceAction.cancel);
      await running;
      final saved = await fixture.saved();
      final identity = GameIdentity(
        gameId: 'org.example.puzzle',
        gameVersion: '1.0.0',
        projectFormat: ProjectFormat.v8,
        saveFormat: 2,
        compatibilityId: 'puzzle',
      );
      final envelope = const GameStateSaveEnvelopeMapper().create(
        identity: identity,
        profileId: 'profile',
        slotId: 'slot',
        saveId: saved.saveId,
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 30),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        gameState: saved,
      );
      final file = File('${fixture.root.path}/continue.avelunesave');
      await file.writeAsBytes(
        const SaveEnvelopeCodec().encodeUtf8(envelope),
        flush: true,
      );
      final before = await file.readAsBytes();
      final runtime = PlayableMapGameSessionRuntime(
        descriptor: GameSessionDescriptor(
          sessionId: 'continue',
          sessionToken: 'token',
          identity: identity,
          profileId: 'profile',
          slotId: 'slot',
          launchMode: GameSessionLaunchMode.continueGame,
          installedVersionHandle: 'installed',
          saveReadHandle: 'save',
          runtimeApiVersion: '1.4.0',
          grantedCapabilities: {'map@1'},
          locale: 'fr',
          accessibility: const GameSessionAccessibilityOptions(),
        ),
        projectFilePath: () async => '${fixture.root.path}/project.json',
        initialSave: () async =>
            const SaveEnvelopeCodec().decode(await file.readAsString()),
        preloadedInitialMap:
            ({
              required projectFilePath,
              required descriptor,
              required initialSave,
            }) async => RuntimeInitialMapPreloadResult(
              bundle: RuntimeMapBundle(
                manifest: fixture.project,
                map: fixture.map,
                projectRootDirectory: fixture.root.path,
                tilesetAbsolutePathsById: const {},
              ),
            ),
        mountGame: (_) async {},
        unmountGame: (_) async {},
      );
      try {
        await runtime.load((_) {});
        expect(
          runtime.game!.playerServiceGameStateSnapshot.imagePuzzleState,
          saved.imagePuzzleState,
        );
        expect(await file.readAsBytes(), before);
      } finally {
        await runtime.dispose();
      }
    },
  );
  testWidgets(
    '2D legacy puzzle preserves later reward, fact and Scene outcome',
    (tester) async {
      await tester.runAsync(() async {
        final fixture = await _Fixture.create(legacyPage: true, postGift: true);
        try {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: GameWidget(game: fixture.game),
            ),
          );
          await fixture.game.loaded;
          await tester.pump();
          await fixture.game.ready();
          for (
            var i = 0;
            i < 200 && fixture.game.debugIsMapActivationDispatchInFlight;
            i++
          ) {
            fixture.game.update(.016);
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          fixture.game.handleRuntimeInputEvent(
            const RuntimeInputEvent.press(RuntimeInputControl.primary),
          );
          fixture.game.update(.016);
          fixture.game.handleRuntimeInputEvent(
            const RuntimeInputEvent.release(RuntimeInputControl.primary),
          );
          await fixture.active();
          await fixture.send(
            RuntimeWorldServiceAction.move,
            target: '0',
            slot: '0',
          );
          await fixture.send(RuntimeWorldServiceAction.confirm);
          for (
            var i = 0;
            i < 200 &&
                fixture
                        .game
                        .playerServiceGameStateSnapshot
                        .trainerProfile
                        .money !=
                    25;
            i++
          ) {
            fixture.game.update(.016);
            await Future<void>.delayed(const Duration(milliseconds: 5));
          }
          final committed = await fixture.game
              .debugReadNarrativeGameStateForTest()
              .timeout(const Duration(seconds: 2));
          expect(committed.trainerProfile.money, 25);
          expect(const BagOperations().quantityOf(committed.bag, 'ball'), 1);
          expect(
            committed.narrativeFactRuntimeState.valueFor('gifted'),
            const NarrativeValue.boolean(true),
          );
          expect(
            committed.imagePuzzleState.puzzlesById['mosaic']!.isSolved,
            isTrue,
          );
          await Future<void>.delayed(Duration.zero);
          expect(await fixture.game.saveGame(), isTrue);
          expect((await fixture.saved()).bag, committed.bag);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          await fixture.dispose();
        }
      });
    },
  );
}

class _Repository extends FileGameSaveRepository {
  _Repository(this.file, NarrativeRuntimeActivityGate gate)
    : super(activityGate: gate);
  final File file;
  int writes = 0;
  bool fail = false;
  Future<void>? gate;
  @override
  Future<String> getSaveFilePath() async => file.path;
  @override
  Future<void> saveOwnedSceneCheckpoint(
    GameState state,
    NarrativeRuntimeSceneCheckpointOwner owner,
  ) async {
    await gate;
    if (fail) throw GameSaveException('disk full');
    await super.saveOwnedSceneCheckpoint(state, owner);
    writes++;
  }
}

class _Fixture {
  _Fixture(this.root, this.project, this.map);
  final Directory root;
  final ProjectManifest project;
  final MapData map;
  File get file => File('${root.path}/save.json');
  late _Repository repository;
  late PlayableMapGame game;
  late PlayerServiceRuntimeController controller;
  DateTime now = DateTime(2026, 10, 30, 23, 59);
  static Future<_Fixture> create({
    bool failsLater = false,
    bool pendingIngredients = false,
    bool legacyPage = false,
    bool postGift = false,
    int unrelatedMaps = 0,
  }) async {
    final qa = Directory(
      '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/puzzle',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('durable-2d-');
    await writePuzzleMedia(root);
    final scene = SceneAsset(
      id: 'puzzle',
      name: 'Craft',
      declaredOutcomes: [
        if (legacyPage) SceneOutcome(id: 'crafted', label: 'Crafted'),
      ],
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
          if (postGift) ...[
            SceneNode(
              id: 'later-gift',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.giveItem(itemId: 'ball', quantity: 1),
              ),
            ),
            SceneNode(
              id: 'gift-fact',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: 'gifted', value: true),
              ),
            ),
          ],
          if (failsLater)
            SceneNode(
              id: 'wait',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.wait(durationMs: 0),
              ),
            ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: legacyPage
                ? SceneEndPayload(
                    sceneOutcomeId: 'crafted',
                    outcomePolicy: SceneOutcomePolicy.progression,
                  )
                : null,
          ),
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
              toNodeId: failsLater
                  ? 'wait'
                  : postGift
                  ? 'later-gift'
                  : 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          if (postGift) ...[
            SceneEdge(
              id: 'gift-fact',
              fromNodeId: 'later-gift',
              fromPortId: 'completed',
              toNodeId: 'gift-fact',
              kind: SceneEdgeKind.actionCompleted,
            ),
            SceneEdge(
              id: 'fact-end',
              fromNodeId: 'gift-fact',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
          if (failsLater)
            SceneEdge(
              id: 'c',
              fromNodeId: 'wait',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
        ],
      ),
    );
    final project = ProjectManifest(
      name: 'Crafting',
      maps: [
        const ProjectMapEntry(
          id: 'field',
          name: 'Field',
          relativePath: 'map.json',
        ),
        for (var index = 0; index < unrelatedMaps; index++)
          ProjectMapEntry(
            id: 'unrelated-$index',
            name: 'Unrelated',
            relativePath: 'unrelated-$index.json',
          ),
      ],
      tilesets: const [],
      scenes: [scene],
      facts: [
        if (postGift)
          NarrativeFactDefinition(
            id: 'gifted',
            label: 'Gifted',
            initialValue: const NarrativeValue.boolean(false),
          ),
      ],
      pokemon: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        catalogFiles: {'items': 'items.json'},
      ),
    );
    final map = MapData(
      id: 'field',
      name: 'Field',
      size: const GridSize(width: 4, height: 4),
      layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      events: [
        if (legacyPage)
          MapEventDefinition(
            id: 'artisan',
            title: 'Artisan',
            position: const EventPosition(layerId: 'objects', x: 1, y: 1),
            pages: const [
              MapEventPage(
                pageNumber: 0,
                sceneTarget: MapEventSceneTarget(sceneId: 'puzzle'),
              ),
            ],
          ),
      ],
    );
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
    for (var index = 0; index < unrelatedMaps; index++) {
      await File('${root.path}/unrelated-$index.json').writeAsString(
        jsonEncode(map.copyWith(id: 'unrelated-$index').toJson()),
      );
    }
    final fixture = _Fixture(root, project, map);
    await fixture.reopen(
      const GameState(
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        currentMapId: 'field',
        playerPosition: GridPos(x: 1, y: 2),
        playerFacing: EntityFacing.north,
        trainerProfile: TrainerProfile(name: 'Leaf', money: 0),
        bag: Bag(entries: [BagEntry(itemId: 'fruit', quantity: 4)]),
      ),
    );
    return fixture;
  }

  Future<void> reopen(GameState state, {DateTime? day}) async {
    if (day != null) {
      await controller.dispose();
      now = day;
    }

    final gate = NarrativeRuntimeActivityGate();
    repository = _Repository(file, gate);
    game = PlayableMapGame(
      bundle: RuntimeMapBundle(
        manifest: project,
        map: map,
        projectRootDirectory: root.path,
        tilesetAbsolutePathsById: const {},
      ),
      projectFilePath: '${root.path}/project.json',
      saveData: saveDataFromGameState(state),
      saveRepository: repository,
      initialMapActivationReason: MapActivationReason.saveRestore,
      narrativeRuntimeActivityGate: gate,
    );
    controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => game.playerServiceGameStateSnapshot,
      commitAndSave: game.commitAndSavePlayerServiceState,
      commitImagePuzzleAndSave: game.commitAndSaveImagePuzzleState,
      projectRootDirectory: root.path,
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
      itemCatalog: puzzleCatalog,
      civilNow: () => now,
    );
    game.setPlayerServiceRuntimeController(controller);
  }

  Future<NarrativeSceneExecutionResult> run() =>
      game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'event',
          sceneId: 'puzzle',
          executionId: 'run',
          gameState: game.playerServiceGameStateSnapshot,
        ),
      );
  Future<void> active() async {
    for (var i = 0; i < 200 && controller.worldServiceSnapshot == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(controller.worldServiceSnapshot, isNotNull);
  }

  Future<RuntimeWorldServiceCommandResult> send(
    RuntimeWorldServiceAction action, {
    String? target,
    String? slot,
  }) => controller.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: controller.worldServiceSnapshot!.revision,
      targetId: target,
      secondaryTargetId: slot,
    ),
  );
  Future<GameState> saved() async => gameStateFromStrictSaveJson(
    jsonDecode(await file.readAsString()) as Map<String, dynamic>,
  );
  Future<void> dispose() async {
    await controller.dispose();
    await root.delete(recursive: true);
  }
}

class _CountedFile implements File {
  _CountedFile(this.delegate, this.reads, this.writes, this.renames);
  final File delegate;
  final List<String> reads, writes, renames;
  @override
  String get path => delegate.path;
  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    reads.add(path);
    return delegate.readAsString(encoding: encoding);
  }

  @override
  Future<Uint8List> readAsBytes() {
    reads.add(path);
    return delegate.readAsBytes();
  }

  @override
  Stream<List<int>> openRead([int? start, int? end]) {
    reads.add(path);
    return delegate.openRead(start, end);
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    writes.add(path);
    return delegate.writeAsString(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) {
    writes.add(path);
    return delegate.writeAsBytes(bytes, mode: mode, flush: flush);
  }

  @override
  Future<File> rename(String newPath) {
    renames.add(newPath);
    return delegate.rename(newPath);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
