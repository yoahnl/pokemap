import 'package:flutter_test/flutter_test.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_core/map_core.dart';

import '../scene_image_puzzle_durable_host_test.dart' show puzzleDefinition;

import '../scene_periodic_reward_durable_host_test.dart'
    show rewardScene, availabilityScene, periodicQa;

import 'spatial_image_puzzle_durable_host_test.dart'
    show SpatialImagePuzzleDurableHostFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('3D old Continue observes civil day without a hidden checkpoint', () async {
    final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa, configureProject: (project) => project.copyWith(eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, legacyClaims: const [], records: [NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(id: 'evt_019abcde-0000-7000-8000-000000000001', name: 'Ineligible initial event', source: NarrativeEventSourceRef.mapEnter('field'), conditions: [NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: false)], sceneId: 'puzzle', reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true)])));
    addTearDown(fixture.dispose);
    expect(fixture.initial.gameplayCalendarState.isInitialized, isFalse);
    final envelope = const GameStateSaveEnvelopeMapper().create(identity: fixture.descriptor(false).identity, profileId: 'profile', slotId: 'slot', saveId: fixture.initial.saveId, createdAt: fixture.now.toUtc(), updatedAt: fixture.now.toUtc(), status: SaveStatus.active, playTimeSeconds: 0, gameState: fixture.initial);
    await fixture.file.writeAsBytes(const SaveEnvelopeCodec().encodeUtf8(envelope), flush: true);
    final bytes = await fixture.file.readAsBytes();
    await fixture.open(continueGame: true);
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.gameStateSnapshot.gameplayCalendarState.observedLocalDay, '2026-10-30');
    expect(fixture.runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
    expect(fixture.writes, 0);
    expect(await fixture.file.readAsBytes(), bytes);
  });
  test('3D full bag leaves periodic availability visible with no durable claim', () async {
    final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
    final entity = MapEntity(id: 'full-tree', kind: MapEntityKind.custom, pos: const GridPos(x: 1, y: 1), presentation: MapEntityPresentation(variants: [MapEntityPresentationVariant(id: 'full', condition: NarrativeEventConditionExpression.leaf(NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: true)), blocksMovement: true)]));
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa,
      configureProject: (project) => project.copyWith(bagCapacity: const ProjectBagCapacity(pockets: {'materials': BagPocketCapacity(maxDistinctItems: 1, maxQuantityPerItem: 5)})),
      configureMap: (map) => map.copyWith(entities: [entity]));
    addTearDown(fixture.dispose);
    await fixture.open();
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.session!.interactionError.value, isNull);
    expect(fixture.writes, 0);
    expect(fixture.runtime.gameStateSnapshot.periodicRewardState.claimsById, isEmpty);
    expect(fixture.runtime.session!.entityIsPresent!('field', entity), isTrue);
  });
  test('3D Narrative activation, presentation and WorldRule refresh at midnight on the same map', () async {
    final reference = PeriodicRewardReference(sceneId: 'puzzle', nodeId: 'claim', rewardId: 'tree');
    final leaf = NarrativeEventConditionExpression.leaf(NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: true));
    final inverse = NarrativeEventConditionExpression.not(NarrativeEventConditionExpression.leaf(NarrativeEventCondition.periodicRewardAvailable(reference: reference, expectedValue: false)));
    final entity = MapEntity(id: 'daily-entity', kind: MapEntityKind.custom, pos: const GridPos(x: 2, y: 2), presentation: MapEntityPresentation(variants: [MapEntityPresentationVariant(id: 'full', condition: NarrativeEventConditionExpression.all([leaf, inverse]), blocksMovement: true)]));
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa,
      configureMap: (map) => map.copyWith(entities: [entity, const MapEntity(id: 'rule-target', kind: MapEntityKind.custom, pos: GridPos(x: 1, y: 1))]),
      configureProject: (project) => project.copyWith(
        eventRegistry: NarrativeEventRegistry(schemaVersion: 1, mode: EventSystemMode.v2Only, legacyClaims: const [], records: [NarrativeEventRecord.configuredStructurallyUnchecked(NarrativeEventDefinition(id: project.eventRegistry!.records.single.id, name: 'Daily activation', source: NarrativeEventSourceRef.mapEnter('field'), conditions: NarrativeEventConditionExpression.any([leaf, inverse]).leaves, conditionExpression: NarrativeEventConditionExpression.any([leaf, inverse]), sceneId: 'puzzle', reusePolicy: NarrativeEventReusePolicy.oneShot, priority: 0, order: 0), enabled: true)]),
        worldRules: [WorldRuleDefinition(id: 'daily-hide', label: 'Daily', source: WorldRuleSource.periodicRewardAvailable(reference: reference, expectedValue: false), target: const WorldRuleTarget(kind: WorldRuleTargetKind.mapEntity, mapId: 'field', entityId: 'rule-target'), effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden))]));
    addTearDown(fixture.dispose);
    await fixture.open();
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.session!.interactionError.value, isNull);
    expect(fixture.writes, 1);
    final session = fixture.runtime.session!;
    final bundle = session.bundle;
    final target = bundle.map.entities.last;
    expect(session.entityIsPresent!('field', entity), isFalse);
    expect(session.entityIsPresent!('field', target), isFalse);
    final bytes = await fixture.file.readAsBytes();
    fixture.now = fixture.now.add(const Duration(minutes: 2));
    await fixture.runtime.resume();
    expect(session.entityIsPresent!('field', entity), isTrue);
    expect(session.entityIsPresent!('field', target), isTrue);
    expect(fixture.runtime.session, same(session));
    expect(session.bundle, same(bundle));
    expect(await fixture.file.readAsBytes(), bytes);
    expect(fixture.writes, 1);
    session.setLifecyclePaused(true);
    fixture.now = fixture.now.add(const Duration(days: 1));
    session.setLifecyclePaused(false);
    expect(session.entityIsPresent!('field', entity), isTrue);
    expect(await fixture.file.readAsBytes(), bytes);
  });
  test('3D real session evaluates periodic conditions before and after claim', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(sceneOverride: availabilityScene(), qaDirectory: periodicQa);
    addTearDown(fixture.dispose);
    await fixture.open();
    await fixture.runtime.gameplayReady;
    expect(fixture.runtime.session!.interactionError.value, isNull);
    expect(fixture.writes, 1);
    expect(fixture.runtime.gameStateSnapshot.trainerProfile.money, 77);
    expect((await fixture.saved()).trainerProfile.money, 0);
    expect((await fixture.saved()).periodicRewardState.claimsById.keys, ['tree']);
    await fixture.open(continueGame: true);
    await fixture.runtime.gameplayReady;
    expect(fixture.writes, 1);
  });
  test('3D immediate rewards persist once across cold Continue', () async {
    final fixture = await SpatialImagePuzzleDurableHostFixture.create(
      sceneOverride: rewardScene(),
      qaDirectory: periodicQa,
    );
    addTearDown(fixture.dispose);
    await fixture.open();
    await fixture.runtime.gameplayReady;
    final saved = await fixture.saved();
    expect(const BagOperations().quantityOf(saved.bag, 'fruit'), 8);
    expect(saved.periodicRewardState.claimsById.length, 2);
    expect(saved.trainerProfile.money, 0);
    expect(fixture.runtime.worldServiceSnapshot, isNull);
    expect(fixture.writes, 2);
    final bytes = await fixture.file.readAsBytes();
    await fixture.open(continueGame: true);
    await fixture.runtime.gameplayReady;
    expect(await fixture.file.readAsBytes(), bytes);
    expect(fixture.writes, 2);
    expect(
      fixture.runtime.gameStateSnapshot.periodicRewardState,
      saved.periodicRewardState,
    );
    fixture.now = fixture.now.add(const Duration(days: 1));
    await fixture.open(continueGame: true);
    await fixture.runtime.gameplayReady;
    expect(
      const BagOperations().quantityOf((await fixture.saved()).bag, 'fruit'),
      12,
    );
    expect(fixture.writes, 4);
  });

  for (final craftingFirst in [true, false]) {
    test(
      '3D mixed checkpoints survive late durable failure craftingFirst=$craftingFirst',
      () async {
        final fixture = await SpatialImagePuzzleDurableHostFixture.create(
          sceneOverride: lateFailureScene(craftingFirst),
          qaDirectory: periodicQa,
        );
        addTearDown(fixture.dispose);
        await fixture.open(
          checkpointCommitter: (request) async {
            if (fixture.writes == 3) {
              throw StateError('late durable writer failure');
            }
            final envelope = const SaveEnvelopeCodec().create(
              identity: fixture.descriptor(false).identity,
              profileId: 'profile',
              slotId: 'slot',
              saveId: fixture.initial.saveId,
              createdAt: DateTime.utc(2026, 10, 30),
              updatedAt: fixture.now.toUtc(),
              status: SaveStatus.active,
              playTimeSeconds: 0,
              state: request.checkpoint.state,
            );
            await fixture.file.writeAsBytes(
              const SaveEnvelopeCodec().encodeUtf8(envelope),
              flush: true,
            );
            fixture.writes++;
          },
        );
        await fixture.active();
        await fixture.send(
          RuntimeWorldServiceAction.select,
          target: 'fruit-ball',
        );
        await fixture.send(RuntimeWorldServiceAction.confirm);
        await fixture.send(RuntimeWorldServiceAction.confirm);
        await fixture.send(RuntimeWorldServiceAction.close);
        await fixture.runtime.gameplayReady;
        final saved = await fixture.saved();
        expect(fixture.runtime.session!.interactionError.value, isNotNull);
        expect(const BagOperations().quantityOf(saved.bag, 'fruit'), 6);
        expect(fixture.runtime.gameStateSnapshot, saved);
        expect(saved.periodicRewardState.claimsById.length, 2);
        expect(
          saved.deferredCraftingState.serviceFor('artisan').pendingOrder,
          isNotNull,
        );
        expect(saved.trainerProfile.money, 0);
        expect(fixture.writes, 3);
      },
    );
  }
}

SceneAsset lateFailureScene(bool craftingFirst) {
  final base = rewardScene(crafting: true, craftingFirst: craftingFirst);
  final late = SceneInteractiveCommand.openImagePuzzle(
    definition: puzzleDefinition,
  );
  return SceneAsset(
    id: base.id,
    name: base.name,
    graph: SceneGraph(
      startNodeId: base.graph.startNodeId,
      nodes: [
        ...base.graph.nodes,
        SceneNode(
          id: 'late',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(late),
        ),
      ],
      edges: [
        for (final edge in base.graph.edges)
          SceneEdge.fromJson({
            ...edge.toJson(),
            if (edge.toNodeId == 'end') 'toNodeId': 'late',
          }),
        for (final port in late.outputPortIds)
          SceneEdge(
            id: 'late-$port',
            fromNodeId: 'late',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
  );
}
