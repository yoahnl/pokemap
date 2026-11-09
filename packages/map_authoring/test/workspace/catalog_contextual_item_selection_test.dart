import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
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

  static Future<_Fixture> open(int foreign, {bool scopedAvatar = false}) async {
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
        groups: const [
          ProjectMapGroup(id: 'cave', name: 'Cave', type: MapGroupType.dungeon)
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
    await WorkingProjectCatalog.create(
        store: store, projectId: 'contextual', project: project);
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
