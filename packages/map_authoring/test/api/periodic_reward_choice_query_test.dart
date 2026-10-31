import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final catalog in [false, true]) {
    for (final wire in [false, true]) {
      test('bounded reward source pages catalog=$catalog JSONL=$wire',
          () async {
        final fixture = await _Fixture.create(catalog: catalog);
        addTearDown(fixture.dispose);
        final page = await fixture.query(_scenes(), wire: wire);
        expect(page.totalAvailable, 3);
        expect(page.items.single['sceneId'], 'source');
        expect(page.items.single['label'], 'Verger');
        expect(page.items.single['revision'], isA<String>());
        expect(page.items.single.containsKey('graph'), isFalse);
        expect(page.items.single.containsKey('runtimeBuildable'), isFalse);
        final next =
            await fixture.query(_scenes(cursor: page.nextCursor), wire: wire);
        expect(next.items.single['sceneId'], 'foreign-0');
        final nodes = await fixture.query(_nodes(), wire: wire);
        expect(nodes.totalAvailable, 2);
        expect(nodes.items.single['nodeId'], 'claim-0');
        expect(nodes.items.single['label'], 'Noigrume rouge');
        expect(nodes.items.single['quantity'], 2);
        expect(
            nodes.items.single['reference'],
            PeriodicRewardReference(
              sceneId: 'source',
              nodeId: 'claim-0',
              rewardId: 'fruit-0',
            ).toJson());
        expect(
            PeriodicRewardSceneChoice.fromJson(
                    Map<String, dynamic>.from(page.items.single))
                .toJson(),
            page.items.single);
        expect(
            PeriodicRewardNodeChoice.fromJson(
                    Map<String, dynamic>.from(nodes.items.single))
                .toJson(),
            nodes.items.single);
        final pinned = await fixture.query(
            _nodes(sourceRevision: page.items.single['revision'] as String),
            wire: wire);
        expect(pinned.items, nodes.items);
        final last =
            await fixture.query(_nodes(cursor: nodes.nextCursor), wire: wire);
        expect(last.items.single['nodeId'], 'claim-1');
        expect(last.nextCursor, isNull);
        expect(
            fixture.reader.paths.where((p) =>
                p.startsWith('maps/') ||
                p.startsWith('assets/') ||
                p.contains('items.json') ||
                p.endsWith('history.jsonl')),
            isEmpty);
      });
    }
  }
  test('source cursors bind query signature and current revision', () async {
    final fixture = await _Fixture.create(catalog: false);
    addTearDown(fixture.dispose);
    final first = await fixture.query(_scenes());
    await expectLater(
        fixture.query(_scenes(cursor: first.nextCursor, pageSize: 2)),
        throwsA(_code('query.cursor_mismatch')));
    await expectLater(fixture.query(_scenes(cursor: 'broken')),
        throwsA(_code('query.cursor_invalid')));
    final file = File('${fixture.root.path}/project.json');
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    raw['name'] = 'Concurrent';
    await file.writeAsString(jsonEncode(raw));
    await expectLater(fixture.query(_scenes(cursor: first.nextCursor)),
        throwsA(_code('query.cursor_stale')));
  });
  test(
      'missing, ambiguous and malformed published sources never become a first match',
      () async {
    final fixture = await _Fixture.create(catalog: false);
    addTearDown(fixture.dispose);
    expect((await fixture.query(_nodes(scene: 'foreign-0'))).items, isEmpty);
    await expectLater(fixture.query(_nodes(scene: 'missing')),
        throwsA(_code('query.resource_not_found')));
    final file = File('${fixture.root.path}/project.json');
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final scenes = raw['scenes'] as List;
    scenes.add(scenes.first);
    await file.writeAsString(jsonEncode(raw));
    await expectLater(fixture.query(_nodes()),
        throwsA(_code('query.periodic_reward_scene_ambiguous')));
    scenes.removeLast();
    final graph = (scenes.first as Map)['graph'] as Map;
    final nodes = graph['nodes'] as List;
    nodes.add(nodes[1]);
    await file.writeAsString(jsonEncode(raw));
    await expectLater(
        fixture.query(_nodes()), throwsA(_code('SceneGraph.nodes')));
  });
  test(
      'node reads require one explicit scene and reject global query semantics',
      () async {
    final fixture = await _Fixture.create(catalog: true);
    addTearDown(fixture.dispose);
    for (final request in [
      AuthoringQueryRequest(
          resourceKind: 'periodicRewardNode',
          operation: AuthoringQueryOperation.list),
      AuthoringQueryRequest(
          resourceKind: 'periodicRewardNode',
          operation: AuthoringQueryOperation.list,
          filters: const {'sceneId': ''}),
      AuthoringQueryRequest(
          resourceKind: 'periodicRewardNode',
          operation: AuthoringQueryOperation.list,
          filters: const {'sceneId': 'source'},
          searchTerm: 'fruit'),
      AuthoringQueryRequest(
          resourceKind: 'periodicRewardNode',
          operation: AuthoringQueryOperation.list,
          filters: const {'sceneId': 'source'},
          extensions: const {'draftScene': {}}),
      AuthoringQueryRequest(
          resourceKind: 'periodicRewardNode',
          operation: AuthoringQueryOperation.list,
          filters: const {'sceneId': 'source'},
          extensions: const {'sourceRevision': 1}),
    ]) {
      await expectLater(fixture.query(request),
          throwsA(_code('query.periodic_reward_scope_invalid')));
    }
    await expectLater(fixture.query(_nodes(scene: 'missing')),
        throwsA(_code('query.resource_not_found')));
    final first = await fixture.query(_nodes());
    await expectLater(fixture.query(_nodes(sourceRevision: 'obsolete')),
        throwsA(_code('query.periodic_reward_source_stale')));
    await expectLater(
        fixture.query(_nodes(scene: 'foreign-0', cursor: first.nextCursor)),
        throwsA(_code('query.cursor_mismatch')));
  });
  for (final unrelated in [0, 240]) {
    test(
        'first and repeated picker reads stay scoped with $unrelated foreign scenes and history',
        () async {
      final fixture =
          await _Fixture.create(catalog: true, unrelated: unrelated);
      addTearDown(fixture.dispose);
      for (var repeat = 0; repeat < 2; repeat++) {
        fixture.reader.clear();
        await fixture.query(_scenes());
        expect(
            fixture.reader.definitions
                .where((id) => id.startsWith('["projectDefinition","scenes",')),
            ['["projectDefinition","scenes",0]']);
        fixture.reader.clear();
        await fixture.query(_nodes());
        expect(
            fixture.reader.definitions
                .where((id) => id.startsWith('["projectDefinition","scenes",')),
            ['["projectDefinition","scenes",0]']);
        expect(
            fixture.reader.definitions.where((id) =>
                id.startsWith('["projectDefinition",') &&
                !id.startsWith('["projectDefinition","scenes",')),
            isEmpty);
        expect(
            fixture.reader.paths.where((p) =>
                p.startsWith('maps/') ||
                p.startsWith('assets/') ||
                p.contains('items.json') ||
                p.endsWith('history.jsonl')),
            isEmpty);
      }
    });
  }
}

Matcher _code(String code) =>
    predicate((error) => error.toString().contains(code));

AuthoringQueryRequest _scenes({String? cursor, int pageSize = 1}) =>
    AuthoringQueryRequest(
      resourceKind: 'periodicRewardScene',
      operation: AuthoringQueryOperation.list,
      pageSize: pageSize,
      cursor: cursor,
    );

AuthoringQueryRequest _nodes(
        {String scene = 'source', String? cursor, String? sourceRevision}) =>
    AuthoringQueryRequest(
      resourceKind: 'periodicRewardNode',
      operation: AuthoringQueryOperation.list,
      filters: {'sceneId': scene},
      pageSize: 1,
      cursor: cursor,
      extensions: {
        if (sourceRevision != null) 'sourceRevision': sourceRevision
      },
    );

SceneAsset _scene(String id, String label, {int rewards = 0}) => SceneAsset(
      id: id,
      name: label,
      graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var i = 0; i < rewards; i++)
          SceneNode(
              id: 'claim-$i',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.claimPeriodicReward(
                definition: PeriodicItemRewardDefinition(
                    rewardId: 'fruit-$i',
                    label: 'Noigrume rouge',
                    itemId: 'fruit',
                    quantity: 2 + i),
              ))),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: const []),
    );

final class _Fixture {
  _Fixture(this.root, this.reader, this.api, this.opened);
  final Directory root;
  final _Reader reader;
  final AuthoringReadApi api;
  final OpenedProject opened;

  static Future<_Fixture> create(
      {required bool catalog, int unrelated = 2}) async {
    final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring');
    await qa.create(recursive: true);
    final root = await qa.createTemp('query-');
    final project = ProjectManifest(
        name: 'Choices',
        maps: const [],
        tilesets: const [],
        scenes: [
          _scene('source', 'Verger', rewards: 2),
          for (var i = 0; i < unrelated; i++)
            _scene('foreign-$i', 'Foreign $i'),
        ]);
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      await WorkingProjectCatalog.create(
          store: store, projectId: 'picker', project: project);
    } else {
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
    }
    final history = File('${root.path}/.pokemap/authoring/history.jsonl');
    await history.parent.create(recursive: true);
    await history.writeAsString('unrelated history\n' * (unrelated + 1));
    final reader = _Reader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final api = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    final opened = await api.openProject(root.path);
    reader.clear();
    return _Fixture(root, reader, api, opened);
  }

  Future<AuthoringQueryPage> query(AuthoringQueryRequest request,
      {bool wire = false}) async {
    if (!wire) return api.queryProject(opened.projectHandle, request);
    final worker = JsonlWorker(api: api);
    final result = AuthoringResult.fromJson(
        jsonDecode(await worker.processLine(jsonEncode({
      'id': 'picker',
      'command': 'query',
      'args': {
        'projectHandle': opened.projectHandle.value,
        'request': request.toJson()
      },
    }))) as Map<String, dynamic>);
    if (result.status != AuthoringResultStatus.success) {
      throw StateError(jsonEncode(result.toJson()));
    }
    return AuthoringQueryPage.fromJson(Map<String, dynamic>.from(result.data));
  }

  Future<void> dispose() async {
    await api.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class _Reader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final definitions = <String>[];
  void clear() {
    paths.clear();
    definitions.clear();
  }

  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      const LocalProjectFileReader()
          .probeResource(projectRoot: projectRoot, relativePath: relativePath);
  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  Future<String> canonicalizeDirectory(String path) =>
      const LocalProjectFileReader().canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    paths.add(relativePath);
    final bytes = await const LocalProjectFileReader()
        .readBytes(projectRoot: projectRoot, relativePath: relativePath);
    if (relativePath.startsWith('catalog/objects/')) {
      final raw = jsonDecode(utf8.decode(bytes));
      if (raw is Map && raw['key'] is Map) {
        definitions.add((raw['key'] as Map)['id'] as String);
      }
    }
    return bytes;
  }
}
