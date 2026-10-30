import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

final craftingDefinition = DeferredCraftingDefinition(
  serviceId: 'artisan',
  label: 'Artisan',
  recipes: [
    DeferredCraftingRecipe(
      recipeId: 'ball',
      label: 'Ball',
      inputItemId: 'fruit',
      inputQuantity: 2,
      outputItemId: 'ball',
      outputQuantity: 1,
    ),
  ],
);
final craftingCatalog = ItemCatalogSnapshot.fromCatalog(
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final unrelated in [0, 80]) {
    test(
      'crafting persistence reads no unrelated content and writes one storage unit with $unrelated unrelated maps',
      () async {
        final fixture = await _Fixture.create(unrelatedMaps: unrelated);
        addTearDown(fixture.dispose);
        final baseZone = Zone.current;
        for (final collecting in [false, true]) {
          if (collecting) fixture.now = DateTime(2026, 10, 31);
          final running = fixture.run();
          await fixture.active();
          final reads = <String>[];
          final writes = <String>[];
          final renames = <String>[];
          await IOOverrides.runZoned(
            () async {
              if (!collecting) {
                await fixture.send(
                  RuntimeWorldServiceAction.select,
                  target: 'ball',
                );
                await fixture.send(RuntimeWorldServiceAction.confirm);
              }
              await fixture.send(RuntimeWorldServiceAction.confirm);
            },
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
          await fixture.send(RuntimeWorldServiceAction.close);
          await running;
        }
        expect(fixture.repository.writes, 2);
      },
    );
  }
  for (final postGift in [false, true]) {
    testWidgets(
      '2D legacy map-event Scene checkpoints and preserves later gift=$postGift',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await _Fixture.create(
            legacyPage: true,
            postGift: postGift,
          );
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
              RuntimeWorldServiceAction.select,
              target: 'ball',
            );
            await fixture.send(RuntimeWorldServiceAction.confirm);
            await fixture.send(RuntimeWorldServiceAction.confirm);
            expect((await fixture.saved()).trainerProfile.money, 0);
            await fixture.send(RuntimeWorldServiceAction.close);
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
            expect(
              fixture.game.playerServiceGameStateSnapshot.trainerProfile.money,
              25,
            );
            expect(fixture.repository.writes, 1);
            final committed = await fixture.game
                .debugReadNarrativeGameStateForTest()
                .timeout(const Duration(seconds: 2));
            if (postGift) {
              expect(
                const BagOperations().quantityOf(committed.bag, 'ball'),
                1,
              );
              expect(
                const BagOperations().quantityOf(
                  fixture.game.gameStateSnapshot.bag,
                  'ball',
                ),
                1,
              );
              expect(
                committed.narrativeFactRuntimeState.valueFor('gifted'),
                const NarrativeValue.boolean(true),
              );
              await Future<void>.delayed(Duration.zero);
              expect(await fixture.game.saveGame(), isTrue);
              final saved = await fixture.saved();
              expect(saved.bag, committed.bag);
              expect(
                saved.narrativeFactRuntimeState.valueFor('gifted'),
                const NarrativeValue.boolean(true),
              );
            } else {
              expect(committed.bag, (await fixture.saved()).bag);
            }
            await tester.pumpWidget(const SizedBox.shrink());
          } finally {
            await fixture.dispose();
          }
        });
      },
    );
  }
  test('2D session cold Continue observes next civil day without rewriting source save', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final submitted = const DeferredCraftingOperations()
        .deposit(
          fixture.game.playerServiceGameStateSnapshot,
          definition: craftingDefinition,
          recipeId: 'ball',
          batchQuantity: 1,
          expectedServiceRevision: 0,
          expectedInputQuantity: 4,
          itemCatalog: craftingCatalog,
        )
        .state;
    final identity = GameIdentity(
      gameId: 'org.example.crafting',
      gameVersion: '1.0.0',
      projectFormat: ProjectFormat.v8,
      saveFormat: 2,
      compatibilityId: 'crafting',
    );
    final envelope = const GameStateSaveEnvelopeMapper().create(
      identity: identity,
      profileId: 'profile',
      slotId: 'slot',
      saveId: submitted.saveId,
      createdAt: DateTime.utc(2026, 10, 30),
      updatedAt: DateTime.utc(2026, 10, 30),
      status: SaveStatus.active,
      playTimeSeconds: 0,
      gameState: submitted,
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
        grantedCapabilities: {
          'map@1',
          SpatialGameplayCapabilities.deferredCraftingCapabilityId,
        },
        locale: 'fr',
        accessibility: const GameSessionAccessibilityOptions(),
      ),
      now: () => DateTime(2026, 10, 31, 0, 1),
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
      final state = runtime.game!.playerServiceGameStateSnapshot;
      expect(state.gameplayCalendarState.dayRevision, 1);
      expect(
        const DeferredCraftingOperations()
            .inspect(state, serviceId: 'artisan')
            .status,
        DeferredCraftingStatus.ready,
      );
      expect(await file.readAsBytes(), before);
    } finally {
      await runtime.dispose();
    }
  });
  test('2D pending Scene inventory edits refuse crafting without checkpoint writes', () async {
    final fixture = await _Fixture.create(pendingIngredients: true);
    addTearDown(fixture.dispose);
    final result = await fixture.run();
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(fixture.repository.writes, 0);
    expect(await fixture.file.exists(), isFalse);
    expect(fixture.controller.worldServiceSnapshot, isNull);
    final committed = await fixture.game.debugReadNarrativeGameStateForTest();
    expect(
      committed.deferredCraftingState.serviceFor('artisan').pendingOrder,
      isNull,
    );
    expect(const BagOperations().quantityOf(committed.bag, 'fruit'), 5);
  });
  test('2D Scene removal during disk write retains durable craft and rolls back unrelated prefix', () async {
    for (final fail in [false, true]) {
      final fixture = await _Fixture.create();
      try {
        final running = fixture.run();
        await fixture.active();
        await fixture.send(RuntimeWorldServiceAction.select, target: 'ball');
        await fixture.send(RuntimeWorldServiceAction.confirm);
        final gate = Completer<void>();
        fixture.repository.gate = gate.future;
        fixture.repository.fail = fail;
        final applying = fixture.send(RuntimeWorldServiceAction.confirm);
        await Future<void>.delayed(Duration.zero);
        fixture.game.onRemove();
        final disposing = fixture.controller.dispose();
        gate.complete();
        await applying;
        await disposing;
        expect(await running, isA<NarrativeSceneExecutionFailed>());
        final committed = await fixture.game
            .debugReadNarrativeGameStateForTest();
        expect(committed.trainerProfile.money, 0);
        expect(committed.bag.entries.single.quantity, fail ? 4 : 2);
        expect(await fixture.file.exists(), !fail);
        if (!fail) expect((await fixture.saved()).bag, committed.bag);
      } finally {
        await fixture.dispose();
      }
    }
  });
  for (final failsLater in [false, true]) {
    test(
      '2D owned Scene persists only crafting and later Scene failure=$failsLater preserves it',
      () async {
        final fixture = await _Fixture.create(failsLater: failsLater);
        addTearDown(fixture.dispose);
        final running = fixture.run();
        await fixture.active();
        await fixture.send(RuntimeWorldServiceAction.select, target: 'ball');
        await fixture.send(RuntimeWorldServiceAction.confirm);
        await fixture.send(RuntimeWorldServiceAction.confirm);
        final saved = await fixture.saved();
        expect(saved.bag.entries.single.quantity, 2);
        expect(saved.trainerProfile.money, 0);
        expect(
          saved.deferredCraftingState.serviceFor('artisan').pendingOrder,
          isNotNull,
        );
        expect(fixture.repository.writes, 1);
        await fixture.send(RuntimeWorldServiceAction.close);
        final result = await running;
        expect(result is NarrativeSceneExecutionFailed, failsLater);
        final committed = await fixture.game
            .debugReadNarrativeGameStateForTest();
        expect(committed.bag, saved.bag);
        expect(committed.trainerProfile.money, failsLater ? 0 : 25);
        expect((await fixture.saved()).bag, saved.bag);
      },
    );
  }
  test('2D real file failed deposit and failed collect preserve bytes and permit retry', () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    await fixture.repository.save(fixture.game.playerServiceGameStateSnapshot);
    final original = await fixture.file.readAsBytes();
    fixture.repository.fail = true;
    final running = fixture.run();
    await fixture.active();
    await fixture.send(RuntimeWorldServiceAction.select, target: 'ball');
    await fixture.send(RuntimeWorldServiceAction.confirm);
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await fixture.file.readAsBytes(), original);
    expect(
      fixture.game.playerServiceGameStateSnapshot.bag.entries.single.quantity,
      4,
    );
    fixture.repository.fail = false;
    await fixture.send(RuntimeWorldServiceAction.confirm);
    await fixture.send(RuntimeWorldServiceAction.close);
    await running;
    final deposited = await fixture.saved();
    final submittedBytes = await fixture.file.readAsBytes();
    await fixture.reopen(deposited, day: DateTime(2026, 10, 31, 0, 1));
    final collecting = fixture.run();
    await fixture.active();
    fixture.repository.fail = true;
    expect(
      (await fixture.send(RuntimeWorldServiceAction.confirm)).status,
      RuntimeWorldServiceCommandStatus.failed,
    );
    expect(await fixture.file.readAsBytes(), submittedBytes);
    expect(
      fixture.game.playerServiceGameStateSnapshot.deferredCraftingState
          .serviceFor('artisan')
          .pendingOrder,
      isNotNull,
    );
    fixture.repository.fail = false;
    await fixture.send(RuntimeWorldServiceAction.confirm);
    await fixture.send(RuntimeWorldServiceAction.close);
    await collecting;
    final collected = await fixture.saved();
    expect(
      collected.deferredCraftingState.serviceFor('artisan').pendingOrder,
      isNull,
    );
    expect(const BagOperations().quantityOf(collected.bag, 'ball'), 1);
    await fixture.reopen(collected, day: DateTime(2026, 10, 31));
    final replay = fixture.run();
    await fixture.active();
    expect(
      (fixture.controller.worldServiceSnapshot!.content
              as RuntimeCraftingServiceContent)
          .status,
      RuntimeCraftingStatus.idle,
    );
    await fixture.send(RuntimeWorldServiceAction.cancel);
    await replay;
    expect(
      const BagOperations().quantityOf((await fixture.saved()).bag, 'ball'),
      1,
    );
  });
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
      '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/crafting',
    );
    await qa.create(recursive: true);
    final root = await qa.createTemp('durable-2d-');
    final scene = SceneAsset(
      id: 'craft',
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
            id: 'craft',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              SceneInteractiveCommand.openCrafting(
                definition: craftingDefinition,
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
            toNodeId: 'craft',
            kind: SceneEdgeKind.actionCompleted,
          ),
          for (final port in ['completed', 'cancelled'])
            SceneEdge(
              id: port,
              fromNodeId: 'craft',
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
                sceneTarget: MapEventSceneTarget(sceneId: 'craft'),
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
    state = observeGameplayCalendar(state, localDay: runtimeCivilDay(now));
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
      commitCraftingAndSave: game.commitAndSaveCraftingState,
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async =>
          const RuntimePlayerServiceRecoveryCaps(maxHpByPartyIndex: {}),
      itemCatalog: craftingCatalog,
      civilNow: () => now,
    );
    game.setPlayerServiceRuntimeController(controller);
  }

  Future<NarrativeSceneExecutionResult> run() =>
      game.debugExecuteNarrativeSceneForTest(
        NarrativeSceneExecutionRequest(
          eventId: 'event',
          sceneId: 'craft',
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
  }) => controller.dispatchWorldService(
    RuntimeWorldServiceCommand(
      action: action,
      snapshotRevision: controller.worldServiceSnapshot!.revision,
      targetId: target,
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
