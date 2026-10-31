import 'package:flutter/widgets.dart';
import 'package:flame/game.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'scene_image_puzzle_durable_host_test.dart'
    show SceneImagePuzzleDurableHostFixture, DurableHostCountedFile;
import 'player/runtime_deferred_crafting_service_test.dart' show definition;

const periodicQa =
    '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-runtime';
SceneInteractiveCommand rewardCommand(String id) =>
    SceneInteractiveCommand.claimPeriodicReward(
      definition: PeriodicItemRewardDefinition(
        rewardId: id,
        label: 'Fruit',
        itemId: 'fruit',
        quantity: 2,
      ),
    );
SceneAsset rewardScene({
  bool craftingFirst = false,
  bool crafting = false,
  bool failLater = false,
  bool pendingBag = false,
}) {
  final commands = <SceneInteractiveCommand>[
    if (crafting && craftingFirst)
      SceneInteractiveCommand.openCrafting(definition: definition),
    rewardCommand('tree'),
    if (crafting && !craftingFirst)
      SceneInteractiveCommand.openCrafting(definition: definition),
    rewardCommand('other-tree'),
    if (failLater) SceneInteractiveCommand.wait(durationMs: 0),
  ];
  return SceneAsset(
    id: 'puzzle',
    name: 'Rewards',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'money',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            pendingBag
                ? SceneConsequence.giveItem(itemId: 'fruit', quantity: 1)
                : SceneConsequence.giveMoney(amount: 25),
          ),
        ),
        for (var i = 0; i < commands.length; i++)
          SceneNode(
            id: 'cmd-$i',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(commands[i]),
          ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'money',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'money',
          fromNodeId: 'money',
          fromPortId: 'completed',
          toNodeId: 'cmd-0',
          kind: SceneEdgeKind.actionCompleted,
        ),
        for (var i = 0; i < commands.length; i++)
          for (final port in commands[i].outputPortIds)
            SceneEdge(
              id: '$i-$port',
              fromNodeId: 'cmd-$i',
              fromPortId: port,
              toNodeId: i + 1 == commands.length ? 'end' : 'cmd-${i + 1}',
              kind: SceneEdgeKind.actionCompleted,
            ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('2D old Continue observes civil day without rewriting the save and requires the condition capability', () async {
    final fixture = await SceneImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa);
    addTearDown(fixture.dispose);
    final initial = fixture.game.playerServiceGameStateSnapshot;
    expect(initial.gameplayCalendarState.isInitialized, isFalse);
    final identity = GameIdentity(gameId: 'org.example.periodic', gameVersion: '1.0.0', projectFormat: ProjectFormat.v8, saveFormat: 2, compatibilityId: 'periodic');
    final envelope = const GameStateSaveEnvelopeMapper().create(identity: identity, profileId: 'profile', slotId: 'slot', saveId: initial.saveId, createdAt: fixture.now.toUtc(), updatedAt: fixture.now.toUtc(), status: SaveStatus.active, playTimeSeconds: 0, gameState: initial);
    final file = File('${fixture.root.path}/continue.avelunesave');
    await file.writeAsBytes(const SaveEnvelopeCodec().encodeUtf8(envelope), flush: true);
    final bytes = await file.readAsBytes();
    for (final allowed in [false, true]) {
      final runtime = PlayableMapGameSessionRuntime(descriptor: GameSessionDescriptor(sessionId: 'continue', sessionToken: 'token', identity: identity, profileId: 'profile', slotId: 'slot', launchMode: GameSessionLaunchMode.continueGame, installedVersionHandle: 'installed', saveReadHandle: 'save', runtimeApiVersion: '1.4.0', grantedCapabilities: {'map@1', if (allowed) SpatialGameplayCapabilities.periodicRewardConditionCapabilityId}, locale: 'fr', accessibility: const GameSessionAccessibilityOptions()),
        now: () => fixture.now, projectFilePath: () async => '${fixture.root.path}/project.json', initialSave: () async => const SaveEnvelopeCodec().decode(await file.readAsString()),
        preloadedInitialMap: ({required projectFilePath, required descriptor, required initialSave}) async => RuntimeInitialMapPreloadResult(bundle: RuntimeMapBundle(manifest: fixture.project, map: fixture.map, projectRootDirectory: fixture.root.path, tilesetAbsolutePathsById: const {})), mountGame: (_) async {}, unmountGame: (_) async {});
      try {
        if (allowed) {
          await runtime.load((_) {});
          expect(runtime.game!.playerServiceGameStateSnapshot.gameplayCalendarState.observedLocalDay, '2026-10-30');
          expect(runtime.game!.playerServiceGameStateSnapshot.bag, initial.bag);
        } else { await expectLater(runtime.load((_) {}), throwsA(isA<StateError>().having((error) => error.message, 'message', contains('gameplay.periodic-reward-condition@1')))); }
        expect(await file.readAsBytes(), bytes);
      } finally { await runtime.dispose(); }
    }
  });
  testWidgets('2D real map activation and projections regrow on the same map and foreground', (tester) async {
    await tester.runAsync(() async {
      final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
      final leaf = NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: true);
      final entity = MapEntity(id: 'daily-tree', kind: MapEntityKind.custom, pos: const GridPos(x: 2, y: 2), presentation: MapEntityPresentation(variants: [MapEntityPresentationVariant(id: 'full', condition: NarrativeEventConditionExpression.leaf(leaf), blocksMovement: true)]));
      final fixture = await SceneImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa, legacyPage: true, withRuntimeCatalog: true,
        configureMap: (map) => map.copyWith(entities: [entity]),
        configureProject: (project) => project.copyWith(eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.dualRead, legacyClaims: const [], records: [NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(id: 'evt_019abcde-0000-7000-8000-000000000001', name: 'Daily activation', source: NarrativeEventSourceRef.mapEnter('field'), conditions: [leaf], sceneId: 'puzzle', reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true)]), worldRules: [WorldRuleDefinition(id: 'daily-hide', label: 'Daily', source: WorldRuleSource.periodicRewardAvailable(reference: reference, expectedValue: false), target: const WorldRuleTarget(kind: WorldRuleTargetKind.mapEvent, mapId: 'field', eventId: 'artisan'), effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventHidden))]));
      try {
        await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: GameWidget(game: fixture.game)));
        await fixture.game.loaded.timeout(const Duration(seconds: 10));
        await tester.pump(); await fixture.game.ready().timeout(const Duration(seconds: 10));
        for (var i = 0; i < 300 && (fixture.repository.writes == 0 || fixture.game.debugIsMapActivationDispatchInFlight); i++) {
          fixture.game.update(.016); await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(fixture.repository.writes, 1);
        expect(fixture.game.debugMapEntityPosition('daily-tree'), isNull);
        expect(fixture.game.overworldInteractionSnapshot.primaryAction, isNull);
        final bytes = await fixture.file.readAsBytes();
        final game = fixture.game;
        fixture.now = fixture.now.add(const Duration(minutes: 2));
        fixture.game.update(.016);
        expect(fixture.game.debugMapEntityPosition('daily-tree'), const GridPos(x: 2, y: 2));
        expect(fixture.game.overworldInteractionSnapshot.primaryAction?.request.targetId, 'artisan');
        expect(await fixture.file.readAsBytes(), bytes);
        fixture.game.didChangeAppLifecycleState(AppLifecycleState.paused);
        fixture.now = fixture.now.add(const Duration(days: 1));
        fixture.game.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(fixture.game, same(game));
        expect(fixture.repository.writes, 1);
        expect(await fixture.file.readAsBytes(), bytes);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally { await fixture.dispose(); }
    });
  });
  testWidgets('2D legacy input consumes real typed condition with an indexed admitted catalog', (tester) async {
    await tester.runAsync(() async {
      final entity = MapEntity(id: 'tree-visual', kind: MapEntityKind.custom, pos: const GridPos(x: 2, y: 2), presentation: MapEntityPresentation(variants: [MapEntityPresentationVariant(id: 'full', condition: NarrativeEventConditionExpression.leaf(NarrativeEventCondition.periodicRewardAvailable(reference: PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree'), expectedValue: true)), blocksMovement: true)]));
      final fixture = await SceneImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa, legacyPage: true, withRuntimeCatalog: true, configureMap: (map) => map.copyWith(entities: [entity]));
      try {
        await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: GameWidget(game: fixture.game)));
        await fixture.game.loaded;
        await tester.pump();
        await fixture.game.ready();
        for (var i = 0; i < 200 && fixture.game.debugIsMapActivationDispatchInFlight; i++) {
          fixture.game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(fixture.game.debugMapEntityPosition('tree-visual'), const GridPos(x: 2, y: 2));
        fixture.game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.primary));
        fixture.game.update(.016);
        fixture.game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.primary));
        for (var i = 0; i < 200 && fixture.repository.writes == 0; i++) {
          fixture.game.update(.016);
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(fixture.repository.writes, 1);
        expect((await fixture.saved()).periodicRewardState.claimFor('tree'), isNotNull);
        expect(fixture.game.debugMapEntityPosition('tree-visual'), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      } finally { await fixture.dispose(); }
    });
  });
  test('2D availability regrows on the same map without hidden writes', () async {
    final fixture = await SceneImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa, unrelatedMaps: 80);
    addTearDown(fixture.dispose);
    expect(await fixture.run(), isA<NarrativeSceneExecutionCompleted>());
    final map = fixture.project.maps.singleWhere((entry) => entry.id == 'field');
    final before = await fixture.file.readAsBytes();
    fixture.now = fixture.now.add(const Duration(minutes: 2));
    fixture.game.refreshPeriodicRewardAvailability();
    expect(await fixture.file.readAsBytes(), before);
    expect(fixture.repository.writes, 1);
    expect(await fixture.run(), isA<NarrativeSceneExecutionCompleted>());
    expect(fixture.repository.writes, 2);
    expect((await fixture.saved()).periodicRewardState.claimFor('tree')!.revision, 2);
    expect(fixture.project.maps.singleWhere((entry) => entry.id == 'field'), same(map));
  });
  test('2D typed condition observes civil day and committed claim in one Scene', () async {
    final fixture = await SceneImagePuzzleDurableHostFixture.create(
      sceneOverride: availabilityScene(), qaDirectory: periodicQa,
    );
    addTearDown(fixture.dispose);
    final result = await fixture.run();
    expect(result, isA<NarrativeSceneExecutionCompleted>());
    expect(fixture.repository.writes, 1);
    expect((await fixture.saved()).periodicRewardState.claimsById.keys, ['tree']);
    expect((result as NarrativeSceneExecutionCompleted).updatedGameState.trainerProfile.money, 77);
    expect((await fixture.saved()).trainerProfile.money, 0);
    final bytes = await fixture.file.readAsBytes();
    await fixture.run();
    expect(await fixture.file.readAsBytes(), bytes);
    expect(fixture.repository.writes, 1);
  });
  test(
    '2D reward checkpoint excludes transient money and survives cold repeat',
    () async {
      final fixture = await SceneImagePuzzleDurableHostFixture.create(
        sceneOverride: rewardScene(),
        qaDirectory: periodicQa,
      );
      addTearDown(fixture.dispose);
      expect(await fixture.run(), isA<NarrativeSceneExecutionCompleted>());
      final saved = await fixture.saved();
      expect(const BagOperations().quantityOf(saved.bag, 'fruit'), 8);
      expect(saved.trainerProfile.money, 0);
      expect(fixture.repository.writes, 2);
      await fixture.reopen(saved, day: fixture.now);
      expect(await fixture.run(), isA<NarrativeSceneExecutionCompleted>());
      expect(fixture.repository.writes, 0);
      expect(fixture.game.playerServiceGameStateSnapshot.bag, saved.bag);
    },
  );
  for (final unrelated in [0, 80]) {
    test(
      'reward first and repeated checkpoint write only save with $unrelated unrelated maps',
      () async {
        final fixture = await SceneImagePuzzleDurableHostFixture.create(
          sceneOverride: rewardScene(),
          qaDirectory: periodicQa,
          unrelatedMaps: unrelated,
        );
        addTearDown(fixture.dispose);
        final reads = <String>[], writes = <String>[], renames = <String>[];
        final baseZone = Zone.current;
        await IOOverrides.runZoned(
          () => fixture.run(),
          createFile: (path) => DurableHostCountedFile(
            baseZone.run(() => File(path)),
            reads,
            writes,
            renames,
          ),
        );
        expect(reads.where((path) => path.contains('unrelated-')), isEmpty);
        expect(writes, [
          '${fixture.file.path}.tmp',
          '${fixture.file.path}.tmp',
        ]);
        expect(renames, [fixture.file.path, fixture.file.path]);
      },
    );
  }
  test(
    '2D pending Scene inventory is refused before any durable reward write',
    () async {
      final fixture = await SceneImagePuzzleDurableHostFixture.create(
        sceneOverride: rewardScene(pendingBag: true),
        qaDirectory: periodicQa,
      );
      addTearDown(fixture.dispose);
      expect(await fixture.run(), isA<NarrativeSceneExecutionCompleted>());
      expect(fixture.repository.writes, 0);
      expect(
        fixture
            .game
            .playerServiceGameStateSnapshot
            .periodicRewardState
            .claimsById,
        isEmpty,
      );
      expect(
        const BagOperations().quantityOf(
          (await fixture.game.debugReadNarrativeGameStateForTest()).bag,
          'fruit',
        ),
        5,
      );
    },
  );
  for (final craftingFirst in [true, false]) {
    test(
      '2D mixed durable checkpoints preserve latest bag after rollback craftingFirst=$craftingFirst',
      () async {
        final fixture = await SceneImagePuzzleDurableHostFixture.create(
          sceneOverride: rewardScene(
            crafting: true,
            craftingFirst: craftingFirst,
            failLater: true,
          ),
          qaDirectory: periodicQa,
        );
        addTearDown(fixture.dispose);
        final running = fixture.run();
        await fixture.active();
        await fixture.send(
          RuntimeWorldServiceAction.select,
          target: 'fruit-ball',
        );
        await fixture.send(RuntimeWorldServiceAction.confirm);
        await fixture.send(RuntimeWorldServiceAction.confirm);
        await fixture.send(RuntimeWorldServiceAction.close);
        expect(await running, isA<NarrativeSceneExecutionFailed>());
        final saved = await fixture.saved();
        final live = await fixture.game.debugReadNarrativeGameStateForTest();
        expect(const BagOperations().quantityOf(saved.bag, 'fruit'), 6);
        expect(live, saved);
        expect(saved.periodicRewardState.claimsById.length, 2);
        expect(
          saved.deferredCraftingState.serviceFor('artisan').pendingOrder,
          isNotNull,
        );
        expect(saved.trainerProfile.money, 0);
        expect(fixture.repository.writes, 3);
      },
    );
  }
}

SceneAsset availabilityScene() {
  final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
  return SceneAsset(id: 'puzzle', name: 'Availability', graph: SceneGraph(startNodeId: 'start', nodes: [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (final id in ['before', 'after']) SceneNode(id: id, kind: SceneNodeKind.condition,
      payload: SceneConditionPayload(conditionSource: SceneConditionSource.periodicRewardAvailable(reference: reference, expectedValue: true))),
    SceneNode(id: 'claim', kind: SceneNodeKind.action, payload: SceneActionPayload.interactive(rewardCommand('tree'))),
    SceneNode(id: 'marker', kind: SceneNodeKind.action, payload: SceneActionPayload.consequence(SceneConsequence.giveMoney(amount: 77))),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ], edges: [
    SceneEdge(id: 'start-before', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'before', kind: SceneEdgeKind.defaultFlow),
    for (final port in ['true', 'false']) SceneEdge(id: 'before-$port', fromNodeId: 'before', fromPortId: port, toNodeId: port == 'true' ? 'claim' : 'end', kind: port == 'true' ? SceneEdgeKind.conditionTrue : SceneEdgeKind.conditionFalse),
    for (final port in rewardCommand('tree').outputPortIds) SceneEdge(id: 'claim-$port', fromNodeId: 'claim', fromPortId: port, toNodeId: 'after', kind: SceneEdgeKind.actionCompleted),
    for (final port in ['true', 'false']) SceneEdge(id: 'after-$port', fromNodeId: 'after', fromPortId: port, toNodeId: port == 'false' ? 'marker' : 'end', kind: port == 'true' ? SceneEdgeKind.conditionTrue : SceneEdgeKind.conditionFalse),
    SceneEdge(id: 'marker-end', fromNodeId: 'marker', fromPortId: 'completed', toNodeId: 'end', kind: SceneEdgeKind.actionCompleted),
  ]));
}

GameState calendarCeilingFaultFixture(GameState initial) => initial.copyWith(
  gameplayCalendarState: GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: GameplayCalendarState.maximumRevision),
);
