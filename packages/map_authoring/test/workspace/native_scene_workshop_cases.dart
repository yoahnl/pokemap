part of 'native_workshop_snapshot_test.dart';

void registerNativeSceneWorkshopCases() {
  test('a retained map instance owner stays separate from the event registry',
      () async {
    final f = _Fixture(unrelated: 0);
    const ownerId = 'evt_00000000-0000-7000-8000-000000000052';
    final map = MapData(
        id: 'owner',
        name: 'Map',
        size: const GridSize(width: 2, height: 2),
        entities: [
          MapEntity(
              id: ownerId,
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 0, y: 0))
        ]);
    f.resources['maps/owner.json'] = utf8.encode(jsonEncode(map.toJson()));
    final scene = SceneAsset(
        id: 'temporary',
        name: 'Temporary state',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'set',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                  SceneConsequence.setMapEventInstanceBoolean(
                      mapId: map.id, eventId: ownerId, key: 'A', value: true))),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'first',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'set',
              kind: SceneEdgeKind.defaultFlow),
          SceneEdge(
              id: 'last',
              fromNodeId: 'set',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted),
        ]));
    f.raw['scenes'] = [scene.toJson()];
    f.raw['eventRegistry'] = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        legacyClaims: const [],
        records: [
          NarrativeEventRecord.draft(NarrativeEventDraft(
              id: ownerId,
              name: 'Unrelated event with the same ID',
              conditions: const [],
              priority: 0,
              order: 0))
        ]).toJson();
    f.updateProject();
    final snapshot = await f.loader.loadWorkshop(f.handle,
        actionId: 'scene.graph.patch',
        parameters: {'sceneId': scene.id, 'upsertNodes': []});
    expect(snapshot.manifest.eventRegistry!.mode, EventSystemMode.v2Only);
    expect(snapshot.manifest.eventRegistry!.records, isEmpty);
    expect(snapshot.availableProjectDocuments!['eventRegistry'], isEmpty);
    expect(snapshot.maps.single.entities.single.id, ownerId);
  });
  for (final unrelated in [0, 900]) {
    test(
        'first reward reads just its item catalogue with $unrelated foreign documents',
        () async {
      final f = _Fixture(unrelated: unrelated);
      f.raw['pokemon'] = {
        ...f.raw['pokemon'] as Map,
        'enabled': false,
        'catalogFiles': {'items': 'items.json', 'moves': 'missing-moves.json'},
      };
      f.updateProject();
      final command = SceneInteractiveCommand.claimPeriodicReward(
        definition: PeriodicItemRewardDefinition(
            rewardId: 'fruit-tree',
            label: 'Fruit',
            itemId: 'fruit',
            quantity: 2),
      );
      final scene = SceneAsset(
          id: 'reward',
          name: 'Reward',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                  id: 'pick',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(command)),
              SceneNode(id: 'end', kind: SceneNodeKind.end),
            ],
            edges: [
              SceneEdge(
                  id: 'start',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'pick',
                  kind: SceneEdgeKind.defaultFlow),
              for (final port in [
                'received',
                'alreadyClaimed',
                'bagFull',
                'blocked'
              ])
                SceneEdge(
                    id: port,
                    fromNodeId: 'pick',
                    fromPortId: port,
                    toNodeId: 'end',
                    kind: SceneEdgeKind.actionCompleted),
            ],
          ));
      Future<ProjectSnapshot> load() => f.loader.loadWorkshop(f.handle,
          actionId: 'scene.upsert', parameters: {'scene': scene.toJson()});
      final absent = await load();
      expect(absent.itemCatalog, isNull);
      expect(absent.scopedStorageRevisions, containsPair('items.json', null));
      expect(f.reads,
          ['project.json', 'items.json', 'project.json', 'items.json']);

      f.resources['items.json'] = utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'entries': [
          {'id': 'fruit', 'displayName': 'Fruit', 'pocketId': 'materials'},
        ]
      }));
      for (var attempt = 0; attempt < 2; attempt++) {
        f.reads.clear();
        final snapshot = await load();
        expect(snapshot.revision, isNot(absent.revision));
        expect(snapshot.scopedStorageRevisions!['items.json'], isNotNull);
        expect(snapshot.availableProjectDocuments!['scenes'], {'reward'});
        expect(snapshot.itemCatalog!.entries.single.id, 'fruit');
        expect(snapshot.maps, isEmpty);
        expect(f.reads,
            ['project.json', 'items.json', 'project.json', 'items.json']);
      }

      final owner = NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
            id: 'evt_00000000-0000-7000-8000-000000000001',
            name: 'Parallel',
            source: NarrativeEventSourceRef.mapEnter('owner'),
            conditions: const [],
            sceneId: scene.id,
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 0,
            parallelPolicy: NarrativeEventParallelPolicy(cadenceMs: 100)),
        enabled: true,
      );
      f.raw['eventRegistry'] = {
        'schemaVersion': 1,
        'mode': 'v2Only',
        'legacyClaims': [],
        'records': [
          owner.toJson(),
          for (var i = 0; i < unrelated; i++)
            {
              'draft': {
                'id': 'unrelated_$i',
                'sceneId': 'foreign_$i',
                'name': 7
              },
            },
        ]
      };
      f.updateProject();
      f.reads.clear();
      final restricted = await load();
      expect(restricted.manifest.eventRegistry!.records.single.id, owner.id);
      expect(restricted.maps.single.id, 'owner');
      expect(f.reads, [
        'project.json',
        'maps/owner.json',
        'items.json',
        'project.json',
        'maps/owner.json',
        'items.json'
      ]);
      final diagnostics = diagnoseSceneAgainstProject(
          scene, restricted.manifest,
          availableItemIds: {'fruit'},
          mapsById: {'owner': restricted.maps.single});
      expect(diagnostics.diagnostics.map((issue) => issue.code),
          contains(SceneDiagnosticCode.capabilityForbiddenForProfile));

      f.resources['items.json'] = utf8.encode('invalid catalogue');
      await expectLater(
          load,
          throwsA(isA<ProjectSnapshotException>().having(
              (error) => error.code, 'code', 'project.item_catalog_invalid')));
    });
  }
}
