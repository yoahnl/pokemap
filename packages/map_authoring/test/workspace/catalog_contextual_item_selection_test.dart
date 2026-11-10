import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final action in ['item.set_overworld_effect', 'item.set_battle_effect', 'item.set_held_effect']) {
    test('$action uses a targeted catalog scope without reading foreign maps', () async {
      final f = await _Fixture.open(80);
      addTearDown(f.close);
      final parameters = <String, Object?>{'itemId': 'rope',
        if (action == 'item.set_held_effect') 'heldEffectId': 'oran_berry' else 'use': {
          'contexts': [action == 'item.set_battle_effect' ? 'battle' : 'overworld'], 'target': 'party_member', 'consumption': 'on_applied',
          'effect': {'kind': 'heal_hp', 'mode': 'flat', 'amount': 50}, 'friendshipLoss': {'low': 5, 'medium': 5, 'high': 10},
        }};
      f.reader.paths.clear();
      final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle, actionId: action, parameters: parameters);
      final plan = await f.api.planMutation(f.opened.projectHandle, AuthoringRequest(requestId: action, actionId: action, actionVersion: 1,
        workspaceHandle: f.opened.workspaceHandle.value, expectedRevision: snapshot.revision, idempotencyKey: action, parameters: parameters));
      await f.api.applyMutation(f.opened.projectHandle, planId: plan.planId, operationId: action);
      final saved = decodeProjectItemCatalog(jsonDecode(await File('${f.root.path}/items.json').readAsString()));
      if (action == 'item.set_held_effect') {
        expect(saved.entries.single.heldEffectId, 'oran_berry');
      } else {
        expect(saved.entries.single.uses.single.friendshipLoss, const ProjectItemFriendshipLoss(low: 5, medium: 5, high: 10));
      }
      expect(f.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    });
  }
  for (final foreign in [0, 80]) {
    test(
        'camera edit preserves an Escape Rope dungeon with $foreign foreign maps',
        () async {
      final f = await _Fixture.open(foreign, spatial: true);
      addTearDown(f.close);
      final file = File('${f.root.path}/maps/source.json');
      final original = MapData.fromJson(
              jsonDecode(await file.readAsString()) as Map<String, dynamic>)
          .copyWith(
              version: ProjectVersion.v9,
              mapMetadata: const MapMetadata(escapeRopeDungeonId: 'cave'),
              spatialScene: MapSpatialScene(width: 8, depth: 8));
      await file.writeAsString(jsonEncode(original.toJson()));
      for (final pitch in [45.0, 50.0]) {
        f.reader.paths.clear();
        final parameters = <String, Object?>{
          'mapId': 'source',
          'camera': original.spatialScene!.camera
              .copyWith(pitchDegrees: pitch)
              .toJson()
        };
        final snapshot = await f.api.readWorkshopSnapshot(
            f.opened.projectHandle,
            actionId: 'map3d.camera.configure',
            parameters: parameters);
        expect(snapshot.manifest.groups.map((group) => group.id), ['cave']);
        final plan = await f.api.planMutation(
            f.opened.projectHandle,
            AuthoringRequest(
                requestId: 'camera-$pitch',
                actionId: 'map3d.camera.configure',
                actionVersion: 1,
                workspaceHandle: f.opened.workspaceHandle.value,
                expectedRevision: snapshot.revision,
                idempotencyKey: 'camera-$pitch',
                parameters: parameters));
        await f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'camera-$pitch');
        expect(
            f.reader.paths.where((path) =>
                path.startsWith('maps/') && path != 'maps/source.json'),
            isEmpty);
        expect(f.reader.paths.where((path) => path.endsWith('history.jsonl')),
            isEmpty);
        await f.reopen();
        final saved = MapData.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>);
        expect(saved.mapMetadata, original.mapMetadata);
        expect(saved.spatialScene!.camera.pitchDegrees, pitch);
        expect(
            saved.copyWith(
                spatialScene: saved.spatialScene!
                    .copyWith(camera: original.spatialScene!.camera)),
            original);
      }
    });
  }
  test('camera edit with a dungeon uses the canonical JSONL transport',
      () async {
    final f = await _Fixture.open(0, spatial: true);
    addTearDown(f.close);
    final file = File('${f.root.path}/maps/source.json');
    final original = MapData.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>)
        .copyWith(
            version: ProjectVersion.v9,
            mapMetadata: const MapMetadata(escapeRopeDungeonId: 'cave'),
            spatialScene: MapSpatialScene(width: 8, depth: 8));
    await file.writeAsString(jsonEncode(original.toJson()));
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [f.root.path], fileReader: f.reader);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: f.reader,
                handles: f.handles,
                catalogMetadataFields: {}),
            snapshotLoader: ProjectSnapshotLoader(handles: f.handles)),
        mutations: f.api);
    Future<AuthoringResult> command(
            String name, Map<String, Object?> parameters) async =>
        AuthoringResult.fromJson(jsonDecode(await worker.processLine(
            jsonEncode({'id': name, 'command': name, 'args': parameters}))));
    final parameters = <String, Object?>{
      'mapId': 'source',
      'camera':
          original.spatialScene!.camera.copyWith(pitchDegrees: 47).toJson()
    };
    final selected = await command('workshop_snapshot', {
      'projectHandle': f.opened.projectHandle.value,
      'actionId': 'map3d.camera.configure',
      'parameters': parameters
    });
    expect(selected.status, AuthoringResultStatus.success);
    final planned = await command('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': AuthoringRequest(
              requestId: 'jsonl-camera',
              actionId: 'map3d.camera.configure',
              actionVersion: 1,
              workspaceHandle: f.opened.workspaceHandle.value,
              expectedRevision: selected.data['snapshotRevision'] as String,
              idempotencyKey: 'jsonl-camera',
              parameters: parameters)
          .toJson()
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: planned.toJson().toString());
    final applied = await command('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-camera'
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: applied.toJson().toString());
    final saved = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    expect(saved.mapMetadata, original.mapMetadata);
    expect(saved.spatialScene!.camera.pitchDegrees, 47);
  });

  test('camera edit rejects an undeclared dungeon without writing', () async {
    final f = await _Fixture.open(0, spatial: true);
    addTearDown(f.close);
    final file = File('${f.root.path}/maps/source.json');
    final original = MapData.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>)
        .copyWith(
            version: ProjectVersion.v9,
            mapMetadata: const MapMetadata(escapeRopeDungeonId: 'missing'),
            spatialScene: MapSpatialScene(width: 8, depth: 8));
    await file.writeAsString(jsonEncode(original.toJson()));
    final before = await file.readAsBytes();
    final parameters = <String, Object?>{
      'mapId': 'source',
      'camera':
          original.spatialScene!.camera.copyWith(pitchDegrees: 47).toJson()
    };
    final selected = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
        actionId: 'map3d.camera.configure', parameters: parameters);
    await expectLater(
        () => f.api.planMutation(
            f.opened.projectHandle,
            AuthoringRequest(
                requestId: 'invalid-camera',
                actionId: 'map3d.camera.configure',
                actionVersion: 1,
                workspaceHandle: f.opened.workspaceHandle.value,
                expectedRevision: selected.revision,
                idempotencyKey: 'invalid-camera',
                parameters: parameters)),
        throwsA(isA<ValidationException>()));
    expect(await file.readAsBytes(), before);
  });
  test(
      'explicit group addition scope never materializes maps and refuses removals',
      () async {
    final f = await _Fixture.open(80);
    addTearDown(f.close);
    final groups = const [
      ProjectMapGroup(id: 'cave', name: 'Cave', type: MapGroupType.dungeon),
      ProjectMapGroup(
          id: 'new-cave', name: 'New cave', type: MapGroupType.dungeon)
    ];
    final parameters = {
      'groups': groups.map((group) => group.toJson()).toList(),
      'assignments': <Object?>[]
    };
    f.reader.paths.clear();
    final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
        actionId: 'map.library.reorganize', parameters: parameters);
    final plan = await f.api.planMutation(
        f.opened.projectHandle,
        AuthoringRequest(
            requestId: 'add-group',
            actionId: 'map.library.reorganize',
            actionVersion: 1,
            workspaceHandle: f.opened.workspaceHandle.value,
            expectedRevision: snapshot.revision,
            idempotencyKey: 'add-group',
            parameters: parameters,
            extensions: const {'workshopScope': true}));
    await f.api.applyMutation(f.opened.projectHandle,
        planId: plan.planId, operationId: 'add-group');
    expect(f.reader.paths.where((path) => path.startsWith('maps/')), isEmpty);
    await f.reopen();
    final persisted = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
        actionId: 'map.library.reorganize', parameters: parameters);
    expect(persisted.manifest.groups, groups);
    await expectLater(
        () => f.api.readWorkshopSnapshot(f.opened.projectHandle,
            actionId: 'map.library.reorganize',
            parameters: {'groups': [], 'assignments': []}),
        throwsA(isA<AuthoringPlanException>()));
  });
  final counts = <int>[];
  for (final foreign in [0, 80]) {
    test(
        'contextual metadata reads only selected dependencies with $foreign foreign maps',
        () async {
      final f = await _Fixture.open(foreign);
      addTearDown(f.close);
      for (final priority in [1, 2]) {
        f.reader.paths.clear();
        final parameters = {
          'mapId': 'source',
          'escapeRopeDungeonId': 'cave',
          'contextualItemUses': [
            ContextualItemUseRule(
                    id: 'secret-use',
                    itemId: 'rope',
                    sceneId: 'secret',
                    priority: priority,
                    conditionExpression: NarrativeEventConditionExpression.leaf(
                        NarrativeEventCondition.fact('ready', true)))
                .toJson(),
          ]
        };
        final timer = Stopwatch()..start();
        final snapshot = await f.api.readWorkshopSnapshot(
            f.opened.projectHandle,
            actionId: 'map.update_metadata',
            parameters: parameters);
        final plan = await f.api.planMutation(
            f.opened.projectHandle,
            AuthoringRequest(
                requestId: 'context-$priority',
                actionId: 'map.update_metadata',
                actionVersion: 1,
                workspaceHandle: f.opened.workspaceHandle.value,
                expectedRevision: snapshot.revision,
                idempotencyKey: 'context-$priority',
                parameters: parameters));
        await f.api.applyMutation(f.opened.projectHandle,
            planId: plan.planId, operationId: 'context-$priority');
        timer.stop();
        expect(
            f.reader.paths.where((path) =>
                path.startsWith('maps/') && path != 'maps/source.json'),
            isEmpty);
        expect(f.reader.paths.where((path) => path.endsWith('history.jsonl')),
            isEmpty);
        expect(f.reader.paths.where((path) => path == 'items.json').length,
            lessThanOrEqualTo(6));
        if (priority == 1)
          counts.add(f.reader.paths
              .where((path) => path == 'maps/source.json')
              .length);
        print(
            'contextual foreign=$foreign priority=$priority reads=${f.reader.paths.length} elapsedUs=${timer.elapsedMicroseconds}');
      }
      if (counts.length == 2) expect(counts.last, counts.first);
      final stored = MapData.fromJson(jsonDecode(
              await File('${f.root.path}/maps/source.json').readAsString())
          as Map<String, dynamic>);
      expect(stored.contextualItemUses.single.priority, 2);
      expect(stored.mapMetadata.escapeRopeDungeonId, 'cave');
      await f.reopen();
      final snapshot = await f.api.readWorkshopSnapshot(f.opened.projectHandle,
          actionId: 'map.update_metadata',
          parameters: {'mapId': 'source', 'allowEscapeRope': false});
      expect(snapshot.maps.single.contextualItemUses.single.priority, 2);
    });
  }

  test('contextual Scene cannot import a character scoped to another map',
      () async {
    final f = await _Fixture.open(0, scopedAvatar: true);
    addTearDown(f.close);
    final before = await File('${f.root.path}/maps/source.json').readAsBytes();
    await expectLater(
        () => f.api.readWorkshopSnapshot(f.opened.projectHandle,
                actionId: 'map.update_metadata',
                parameters: {
                  'mapId': 'source',
                  'contextualItemUses': [
                    const ContextualItemUseRule(
                            id: 'secret-use', itemId: 'rope', sceneId: 'secret')
                        .toJson()
                  ],
                }),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
    expect(await File('${f.root.path}/maps/source.json').readAsBytes(), before);
  });
}

final class _Fixture {
  _Fixture(this.root, this.reader, this.handles, this.api, this.opened);
  final Directory root;
  final _Reader reader;
  final WorkspaceHandleStore handles;
  LocalMapAuthoringMutationApi api;
  OpenedProject opened;

  static Future<_Fixture> open(int foreign,
      {bool scopedAvatar = false, bool spatial = false}) async {
    final root = await Directory.systemTemp.createTemp('context-catalog-');
    final scene = SceneAsset(
        id: 'secret',
        name: 'Secret',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          if (scopedAvatar)
            SceneNode(
                id: 'avatar',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.consequence(
                    SceneConsequence.setPlayerAvatar(characterId: 'costume'))),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ], edges: [
          SceneEdge(
              id: 'edge',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: scopedAvatar ? 'avatar' : 'end',
              kind: SceneEdgeKind.defaultFlow),
          if (scopedAvatar)
            SceneEdge(
                id: 'avatar-end',
                fromNodeId: 'avatar',
                fromPortId: 'completed',
                toNodeId: 'end',
                kind: SceneEdgeKind.defaultFlow),
        ]));
    final project = ProjectManifest(
        name: 'Context',
        version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
        settings: ProjectSettings(
            dimension:
                spatial ? ProjectDimension.threeD : ProjectDimension.twoD),
        maps: [
          for (final id in [
            'source',
            'other',
            for (var i = 0; i < foreign; i++) 'foreign-$i'
          ])
            ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
        ],
        tilesets: [],
        scenes: [scene],
        facts: [NarrativeFactDefinition(id: 'ready', label: 'Ready')],
        groups: [
          const ProjectMapGroup(
              id: 'cave', name: 'Cave', type: MapGroupType.dungeon),
          if (spatial)
            for (var index = 0; index < foreign; index++)
              ProjectMapGroup(
                  id: 'foreign-group-$index',
                  name: 'Foreign $index',
                  type: MapGroupType.dungeon),
        ],
        pokemon: const ProjectPokemonConfig(
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            catalogFiles: {'items': 'items.json'}),
        characters: [
          if (scopedAvatar)
            const ProjectCharacterEntry(
                id: 'costume', name: 'Costume', tilesetId: '')
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
          if (scopedAvatar)
            ResourceLibraryEntry(
                resourceKind: 'character',
                resourceId: 'costume',
                mapId: 'other')
        ]));
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'contextual', project: project);
    try {
      if (spatial) {
        for (var index = 0; index < foreign; index++) {
          final entry = (await working.catalog.snapshot.indexEntry(
              CatalogDefinitionKey(CatalogDefinitionKind.catalogMetadata,
                  jsonEncode(['projectDefinition', 'groups', index + 1]))))!;
          await File(
                  '${root.path}/catalog/objects/${entry.reference.sha256}.json')
              .writeAsString('unrelated group must not be decoded');
        }
      }
    } finally {
      await working.close();
    }
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/source.json').writeAsString(jsonEncode(
        const MapData(
                id: 'source',
                name: 'Source',
                size: GridSize(width: 8, height: 8))
            .toJson()));
    for (final entry in project.maps.where((entry) => entry.id != 'source')) {
      await File('${root.path}/${entry.relativePath}')
          .writeAsString('unrelated map must not be decoded');
    }
    await File('${root.path}/items.json').writeAsString(jsonEncode(
        const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(id: 'rope', displayName: 'Corde', pocketId: 'items')
    ]).toJson()));
    final reader = _Reader(), handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Fixture(root, reader, handles, api, opened);
  }

  Future<void> reopen() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
        catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
