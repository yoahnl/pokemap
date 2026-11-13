import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_consumers.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_narrative_event_documents.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

String _event(int index, {int block = 0}) =>
    'evt_019abcde-000$block-7000-8000-${index.toRadixString(16).padLeft(12, '0')}';

final _free = _event(1);
final _consumed = _event(2);
final _consumer = _event(3);
final _ruled = _event(4);
final _mapped = _event(5);
final _sourced = _event(6);
final _spare = _event(7);

NarrativeEventRecord _draft(String id, String name,
        {String? sceneId,
        List<NarrativeEventCondition> conditions = const [],
        int order = 0}) =>
    NarrativeEventRecord.draft(NarrativeEventDraft(
        id: id,
        name: name,
        sceneId: sceneId,
        conditions: conditions,
        priority: 0,
        order: order));

WorldRuleDefinition _targetRule(String eventId) => WorldRuleDefinition(
        id: 'world_rule_target',
        label: 'Target',
        source: WorldRuleSource.civilWeekday(
            weekday: CivilWeekday.friday, expectedValue: true),
        target: WorldRuleTarget(
            kind: WorldRuleTargetKind.narrativeEvent,
            mapId: '',
            eventId: eventId),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventDisabled));

SceneAsset _scene(String id) => SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'flow',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow)
    ]));

MapData _map(String id, String name, {String? consumes}) => MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    tilesetId: 'atlas',
    layers: const [ObjectLayer(id: 'objects', name: 'Objects')],
    mapMetadata: MapMetadata(contextualItemUses: [
      if (consumes != null)
        ContextualItemUseRule(
            id: 'use-key',
            itemId: 'key',
            sceneId: 'talk',
            conditionExpression: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.narrativeEventConsumed(
                    consumes, true))),
    ]));

void main() {
  test('an unprepared catalog refuses the deletion and keeps the behaviour',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final head = await fixture.headBytes();

    await expectLater(
        fixture.delete(_free, 'unprepared'),
        throwsA(isA<AuthoringPlanException>()
            .having((error) => error.code, 'code',
                'catalog.narrative_event_consumers.preparation_required')
            .having((error) => error.remediation.join(' '), 'remediation',
                contains('narrativeEventConsumers'))));

    expect(await fixture.headBytes(), head);
    expect(await fixture.storedRecordIds(), contains(_free));
  });

  test(
      'an unused behaviour is deleted and its document and scene owner row are gone after reopen',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final before = await fixture.snapshot();
    expect(
        await before.lookup(CatalogNarrativeEventDocuments.recordKey(_free)),
        isNotNull);
    expect(
        await before
            .lookup(CatalogNarrativeEventDocuments.sceneOwnerKey('lonely')),
        isNotNull);

    final result = await fixture.delete(_free, 'delete-free');

    expect(result.snapshotRevision, isNotNull);
    await fixture.reattach();
    final after = await fixture.snapshot();
    expect(await after.lookup(CatalogNarrativeEventDocuments.recordKey(_free)),
        isNull);
    expect(
        await after
            .lookup(CatalogNarrativeEventDocuments.sceneOwnerKey('lonely')),
        isNull);
    expect(
        await CatalogNarrativeEventDocuments.readSceneOwnerIds(
            after, fixture.root.path, {'talk'}),
        {_consumer});
    final stored = await fixture.storedRecordIds();
    expect(stored, isNot(contains(_free)));
    expect(stored, containsAll([_consumed, _consumer, _ruled, _mapped]));
    final reread = await fixture.api.readWorkshopSnapshot(
        fixture.opened.projectHandle,
        actionId: 'event_v2.record_upsert',
        parameters: {'record': _draft(_spare, 'Spare').toJson()});
    expect(reread.manifest.eventRegistry!.records.map((record) => record.id),
        isNot(contains(_free)));
  });

  test('a behaviour consumed by another behaviour is refused with its user',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final head = await fixture.headBytes();

    await expectLater(
        fixture.delete(_consumed, 'consumed'),
        throwsA(isA<NarrativeAuthoringException>()
            .having((error) => error.code, 'code', 'eventReferenced')
            .having((error) => error.details['consumers'], 'consumers', [
          {'kind': 'event', 'id': _consumer, 'label': 'Consumer'}
        ])));

    expect(await fixture.headBytes(), head);
    expect(await fixture.storedRecordIds(), contains(_consumed));
  });

  test(
      'world rules that target or consume a behaviour refuse it until released',
      () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();

    await expectLater(
        fixture.delete(_sourced, 'sourced'),
        throwsA(isA<NarrativeAuthoringException>()
            .having((error) => error.code, 'code', 'eventReferenced')
            .having((error) => error.details['consumers'], 'consumers', [
          {'kind': 'worldRule', 'id': 'world_rule_consumed', 'label': 'Consumed'}
        ])));

    await fixture.apply('world_rule.create',
        {'rule': _targetRule(_ruled).toJson()}, 'create-rule');
    final head = await fixture.headBytes();
    await expectLater(
        fixture.delete(_ruled, 'ruled'),
        throwsA(isA<NarrativeAuthoringException>()
            .having((error) => error.code, 'code', 'eventReferenced')
            .having((error) => error.details['consumers'], 'consumers', [
          {'kind': 'worldRule', 'id': 'world_rule_target', 'label': 'Target'}
        ])));
    expect(await fixture.headBytes(), head);

    await fixture.apply('world_rule.update',
        {'rule': _targetRule(_spare).toJson()}, 'retarget-rule');
    await fixture.delete(_ruled, 'ruled-released');
    expect(await fixture.storedRecordIds(), isNot(contains(_ruled)));
    await expectLater(
        fixture.delete(_spare, 'spare'),
        throwsA(isA<NarrativeAuthoringException>()
            .having((error) => error.details['consumers'], 'consumers', [
          {'kind': 'worldRule', 'id': 'world_rule_target', 'label': 'Target'}
        ])));
  });

  test('a map condition that consumes a behaviour refuses it', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final head = await fixture.headBytes();

    await expectLater(
        fixture.delete(_mapped, 'mapped'),
        throwsA(isA<NarrativeAuthoringException>()
            .having((error) => error.code, 'code', 'eventReferenced')
            .having((error) => error.details['consumers'], 'consumers', [
          {'kind': 'map', 'id': 'town', 'label': 'Town'}
        ])));
    expect(await fixture.headBytes(), head);
  });

  test('map saves keep the consumer index current', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    await fixture.prepare();
    final snapshot = await fixture.snapshot();
    List<int> bytes(MapData map) => utf8.encode(jsonEncode(map.toJson()));
    AuthoringResourceChange change(MapData before, MapData after) =>
        AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: 'map', id: before.id),
            storageKey: 'maps/${before.id}.json',
            beforeBytes: bytes(before),
            afterBytes: bytes(after));

    final added = await CatalogNarrativeEventConsumers.maintain(
        snapshot: snapshot,
        upserts: const [],
        removals: const [],
        additionalChanges: [
          change(_map('route', 'Route'), _map('route', 'Route', consumes: _free))
        ]);
    expect(added.removals, isEmpty);
    expect(added.upserts.single.key,
        CatalogNarrativeEventConsumers.facetKey(_free));
    expect(added.upserts.single.payload['consumers'], [
      {'kind': 'map', 'id': 'route', 'label': 'Route'}
    ]);

    final released = await CatalogNarrativeEventConsumers.maintain(
        snapshot: snapshot,
        upserts: const [],
        removals: const [],
        additionalChanges: [
          change(_map('town', 'Town', consumes: _mapped), _map('town', 'Town'))
        ]);
    expect(released.upserts, isEmpty);
    expect(released.removals,
        [CatalogNarrativeEventConsumers.facetKey(_mapped)]);

    final untouched = await CatalogNarrativeEventConsumers.maintain(
        snapshot: snapshot,
        upserts: const [],
        removals: const [],
        additionalChanges: [
          change(_map('route', 'Route'), _map('route', 'Renamed route'))
        ]);
    expect(untouched.upserts, isEmpty);
    expect(untouched.removals, isEmpty);
  });

  test('deleting one behaviour next to 400 unrelated records stays bounded',
      () async {
    final observer = _CaptureWorkObserver();
    final fixture =
        await _Fixture.open(unrelated: 400, observer: observer);
    addTearDown(fixture.close);
    await fixture.prepare();
    final before = {
      for (final unit in await (await fixture.snapshot()).readAllUnits())
        unit.key: jsonEncode(unit.payload)
    };

    observer.counters.clear();
    await fixture.delete(_free, 'bounded');

    expect(fixture.lastStorageKeys, [CatalogStorageStore.headStorageKey]);
    expect(
        observer.counters[AuthoringPerformanceCounterName
                .gatewayJournalCompletedWriteInputBytes] ??
            0,
        lessThan(64 * 1024));
    final after = {
      for (final unit in await (await fixture.snapshot()).readAllUnits())
        unit.key: jsonEncode(unit.payload)
    };
    final changed = {
      for (final key in {...before.keys, ...after.keys})
        if (before[key] != after[key]) key
    };
    expect(
        changed
            .where((key) => key.kind == CatalogDefinitionKind.workspaceState &&
                key.id != 'workspace')
            .toSet(),
        {
          CatalogNarrativeEventDocuments.recordKey(_free),
          CatalogNarrativeEventDocuments.sceneOwnerKey('lonely'),
        });
    expect(changed.length, lessThan(12));
  });
}

final class _Fixture {
  _Fixture(this.root, this.opened, this.handles, this.api);
  final Directory root;
  final OpenedProject opened;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;
  List<String> lastStorageKeys = const [];

  static Future<_Fixture> open(
      {int unrelated = 0, _CaptureWorkObserver? observer}) async {
    final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/histoire-a2/catalog-deletion');
    await qa.create(recursive: true);
    final root = await qa.createTemp('project-');
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'event-deletion',
      project: ProjectManifest(
        name: 'Event deletion',
        maps: const [
          ProjectMapEntry(
              id: 'town', name: 'Town', relativePath: 'maps/town.json'),
          ProjectMapEntry(
              id: 'route', name: 'Route', relativePath: 'maps/route.json'),
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'atlas', name: 'Atlas', relativePath: 'assets/atlas.png'),
        ],
        scenes: [_scene('talk'), _scene('lonely')],
        worldRules: [
          WorldRuleDefinition(
              id: 'world_rule_consumed',
              label: 'Consumed',
              source: WorldRuleSource(
                  kind: WorldRuleSourceKind.consumedEvent,
                  sourceId: _sourced,
                  predicate: WorldRuleSourcePredicate.consumed),
              target: const WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: 'town',
                  entityId: 'tree'),
              effect:
                  const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden)),
        ],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            _draft(_free, 'Free', sceneId: 'lonely'),
            _draft(_consumed, 'Consumed'),
            _draft(_consumer, 'Consumer',
                sceneId: 'talk',
                conditions: [
                  NarrativeEventCondition.narrativeEventConsumed(
                      _consumed, true)
                ]),
            _draft(_ruled, 'Ruled'),
            _draft(_mapped, 'Mapped'),
            _draft(_sourced, 'Sourced'),
            _draft(_spare, 'Spare'),
            for (var i = 0; i < unrelated; i++)
              _draft(_event(i, block: 1), 'Unrelated $i', order: i),
          ],
          legacyClaims: const [],
        ),
      ),
    );
    for (final map in [
      _map('town', 'Town', consumes: _mapped),
      _map('route', 'Route')
    ]) {
      final file = File('${root.path}/maps/${map.id}.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map.toJson()));
    }
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      catalogFileReader: reader,
      performanceObserver: observer,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, opened, handles, api);
  }

  Future<void> prepare() => api.prepareWorkshopCatalog(opened.projectHandle,
      scope: 'narrativeEventConsumers');

  Future<void> reattach() async {
    await api.detachWorkspace(opened.workspaceHandle);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<List<int>> headBytes() =>
      File('${root.path}/catalog/HEAD.json').readAsBytes();

  Future<CatalogSnapshot> snapshot() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    return (await store.openRoot((await store.readHead())!)).snapshot;
  }

  Future<Set<String>> storedRecordIds() async {
    final catalog = await PortableProjectCatalog.fromSnapshot(await snapshot(),
        metadataFields: {'eventRegistry'});
    return {
      for (final record in catalog.projectMetadata.eventRegistry!.records)
        record.id
    };
  }

  Future<AuthoringMutationResult> apply(String action,
      Map<String, Object?> parameters, String operation) async {
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: action, parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    return api.applyMutation(opened.projectHandle,
        planId: plan.planId, operationId: operation);
  }

  Future<AuthoringMutationResult> delete(String eventId, String operation) async {
    final parameters = {'eventId': eventId};
    final snapshot = await api.readWorkshopSnapshot(opened.projectHandle,
        actionId: 'event_v2.delete', parameters: parameters);
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
            requestId: operation,
            actionId: 'event_v2.delete',
            actionVersion: 1,
            workspaceHandle: opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: operation,
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    lastStorageKeys = [
      for (final change in plan.plan.changeSet.changes) change.storageKey
    ];
    final confirmation =
        await api.confirmMutation(opened.projectHandle, planId: plan.planId);
    return api.applyMutation(opened.projectHandle,
        planId: plan.planId,
        operationId: operation,
        confirmationToken: confirmation.confirmationToken);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _CaptureWorkObserver implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) =>
      counters.update(name, (value) => value + by, ifAbsent: () => by);
}
