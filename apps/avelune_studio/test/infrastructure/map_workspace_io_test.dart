import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionCheckpoint;
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

final class _RecordingReader implements ProjectFileReader {
  final reads = <String>[];
  final _delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      _delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    reads.add(relativePath);
    return _delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

void main() {
  late Directory root;
  late File mapFile;
  late File manifestFile;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter port;
  const entry = ProjectMapEntry(
    id: 'alpha',
    name: 'Alpha',
    relativePath: 'alpha.json',
  );
  final initial = MapData(
    id: 'alpha',
    name: 'Alpha',
    size: const GridSize(width: 2, height: 2),
    visualStack: MapVisualStackConfig.canonicalV1,
    properties: const {
      'untouched': {'answer': 42},
    },
    layers: const [
      TileLayer(id: 'paint', name: 'Peinture', cells: [0, 0, 0, 0]),
      CollisionLayer(
        id: 'collision',
        name: 'Collisions',
        collisions: [true, false, false, false],
      ),
    ],
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-map-io-');
    root = Directory(await root.resolveSymbolicLinks());
    mapFile = File('${root.path}/alpha.json');
    manifestFile = File('${root.path}/project.json');
    await mapFile.writeAsBytes(encodeMapDocumentBytes(initial));
    await manifestFile.writeAsString(
      jsonEncode(
        ProjectManifest(name: 'Test', maps: [entry], tilesets: []).toJson(),
      ),
    );
    session = ProjectSession(
      sessionId: root.path,
      name: 'Test',
      directoryPath: root.path,
    );
    port = LocalMapWorkspaceAdapter();
    await port.loadProject(session);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  Matcher problem(MapWorkspaceProblem value) =>
      isA<MapWorkspaceFailure>().having((e) => e.problem, 'problem', value);

  test('a large map reopens with its untouched data preserved', () async {
    final largeMap = initial.copyWith(
      properties: {...initial.properties, 'notes': 'x' * (1024 * 1024)},
    );
    await mapFile.writeAsBytes(encodeMapDocumentBytes(largeMap));
    final before = await mapFile.readAsBytes();
    final beforeManifest = await manifestFile.readAsBytes();
    final loaded = await port.loadMap(session, entry);
    expect(loaded.revision, narrativeEventBytesFingerprint(before));
    expect(await mapFile.readAsBytes(), before);
    final changed = loaded.map.copyWith(name: 'Modified');
    final revision = await port.saveMap(session, loaded, changed);
    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadProject(session);
    final actual = await reopened.loadMap(session, entry);
    expect(actual.map, changed);
    expect(actual.revision, revision);
    expect(actual.map.layers.last, initial.layers.last);
    expect(actual.map.properties, largeMap.properties);
    expect(await manifestFile.readAsBytes(), beforeManifest);
  });

  test(
    'manifest map saves record canonical history without reading other maps',
    () async {
      final other = File('${root.path}/elsewhere.json');
      await other.writeAsString('unrelated map bytes');
      final manifest = ProjectManifest(
        name: 'Test',
        maps: [
          entry,
          const ProjectMapEntry(
            id: 'elsewhere',
            name: 'Elsewhere',
            relativePath: 'elsewhere.json',
          ),
        ],
        tilesets: [],
      );
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
      final reader = _RecordingReader();
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      await adapter.loadProject(session);
      final loaded = await adapter.loadMap(session, entry);
      reader.reads.clear();
      final changed = loaded.map.copyWith(name: 'Saved through authoring');
      final revision = await adapter.saveMap(session, loaded, changed);
      final saveReads = List<String>.of(reader.reads);
      expect(saveReads, isNot(contains('elsewhere.json')));
      expect(await other.readAsString(), 'unrelated map bytes');

      final reopened = LocalMapWorkspaceAdapter();
      await reopened.loadProject(session);
      final actual = await reopened.loadMap(session, entry);
      expect(actual.map, changed);
      expect(actual.revision, revision);

      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      );
      final opened = await opener.openProject(root.path);
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
      );
      await api.attachProject(
        projectRootPath: root.path,
        projectHandle: opened.projectHandle,
        workspaceHandle: opened.workspaceHandle,
      );
      addTearDown(() => api.detachWorkspace(opened.workspaceHandle));
      final history = await api.history(opened.projectHandle, limit: 2);
      final entries = history['entries'] as List;
      expect(entries, hasLength(1));
      expect((entries.single as Map)['receipt']['actionId'], 'map.save');
      expect(saveReads, contains(entry.relativePath));
    },
  );

  test(
    'external byte revision conflict never overwrites the newer file',
    () async {
      final loaded = await port.loadMap(session, entry);
      final outside = encodeMapDocumentBytes(initial.copyWith(name: 'Outside'));
      await mapFile.writeAsBytes(outside);
      await expectLater(
        port.saveMap(session, loaded, loaded.map.copyWith(name: 'Mine')),
        throwsA(problem(MapWorkspaceProblem.conflict)),
      );
      expect(await mapFile.readAsBytes(), outside);
    },
  );

  test(
    'external manifest change blocks saving a previously declared map',
    () async {
      final loaded = await port.loadMap(session, entry);
      await manifestFile.writeAsString(
        '${await manifestFile.readAsString()}\n',
      );
      final before = await mapFile.readAsBytes();
      await expectLater(
        port.saveMap(session, loaded, loaded.map.copyWith(name: 'Mine')),
        throwsA(problem(MapWorkspaceProblem.conflict)),
      );
      expect(await mapFile.readAsBytes(), before);
    },
  );

  for (final checkpoint in [
    AuthoringTransactionCheckpoint.afterJournalPreparing,
    AuthoringTransactionCheckpoint.afterPayloadsStaged,
  ]) {
    test(
      'failure at ${checkpoint.name} preserves last good map and retry works',
      () async {
        var fail = true;
        final failing = LocalMapWorkspaceAdapter(
          mapSaveFaultInjector: (context) {
            if (context.checkpoint == checkpoint && fail) {
              throw const FileSystemException('injected write failure');
            }
          },
        );
        await failing.loadProject(session);
        final loaded = await failing.loadMap(session, entry);
        final before = await mapFile.readAsBytes();
        final changed = loaded.map.copyWith(name: 'Retry');
        await expectLater(
          failing.saveMap(session, loaded, changed),
          throwsA(problem(MapWorkspaceProblem.writeFailed)),
        );
        expect(await mapFile.readAsBytes(), before);
        fail = false;
        await failing.saveMap(session, loaded, changed);
        expect((await failing.loadMap(session, entry)).map, changed);
      },
    );
  }

  test('an interrupted reserved save recovers its committed map', () async {
    final interrupted = LocalMapWorkspaceAdapter(
      mapSaveFaultInjector: (context) {
        if (context.checkpoint ==
            AuthoringTransactionCheckpoint.beforeResourcePromotion) {
          throw const FileSystemException('injected write failure');
        }
      },
    );
    await interrupted.loadProject(session);
    final loaded = await interrupted.loadMap(session, entry);
    final changed = loaded.map.copyWith(name: 'Recovered');
    final revision = await interrupted.saveMap(session, loaded, changed);
    final reopened = await port.loadMap(session, entry);
    expect(reopened.map, changed);
    expect(reopened.revision, revision);
  });

  test(
    'future unknown map fields are refused instead of lost on save',
    () async {
      final json = initial.toJson()..['futureFeature'] = {'value': 123};
      await mapFile.writeAsString(jsonEncode(json));
      final before = await mapFile.readAsBytes();
      await expectLater(
        port.loadMap(session, entry),
        throwsA(problem(MapWorkspaceProblem.invalidDocument)),
      );
      expect(await mapFile.readAsBytes(), before);
    },
  );

  test('future nested fields and unsupported schema are refused', () async {
    final json =
        jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>;
    (json['layers'] as List).first['futureFeature'] = true;
    await mapFile.writeAsString(jsonEncode(json));
    await expectLater(
      port.loadMap(session, entry),
      throwsA(problem(MapWorkspaceProblem.invalidDocument)),
    );
    json.remove('layers');
    json['version'] = 999;
    await mapFile.writeAsString(jsonEncode(json));
    await expectLater(
      port.loadMap(session, entry),
      throwsA(problem(MapWorkspaceProblem.invalidDocument)),
    );
  });

  test('map id mismatch is refused', () async {
    await mapFile.writeAsBytes(
      encodeMapDocumentBytes(initial.copyWith(id: 'other')),
    );
    await expectLater(
      port.loadMap(session, entry),
      throwsA(problem(MapWorkspaceProblem.invalidDocument)),
    );
  });

  test('map symlink cannot redirect load or save', () async {
    final loaded = await port.loadMap(session, entry);
    await mapFile.rename('${root.path}/target.json');
    await Link(mapFile.path).create('${root.path}/target.json');
    await expectLater(
      port.loadMap(session, entry),
      throwsA(problem(MapWorkspaceProblem.unsafePath)),
    );
    await expectLater(
      port.saveMap(session, loaded, loaded.map.copyWith(name: 'Mine')),
      throwsA(problem(MapWorkspaceProblem.unsafePath)),
    );
    expect(
      decodeValidatedMapDocument(
        await File('${root.path}/target.json').readAsBytes(),
        'target',
      ).name,
      'Alpha',
    );
  });

  test('undeclared or traversal entries cannot be loaded', () async {
    await expectLater(
      port.loadMap(session, entry.copyWith(relativePath: '../alpha.json')),
      throwsA(problem(MapWorkspaceProblem.unsafePath)),
    );
    await expectLater(
      port.loadMap(session, entry.copyWith(id: 'unknown')),
      throwsA(problem(MapWorkspaceProblem.unsafePath)),
    );
  });

  test(
    'a stale baseline cannot overwrite a previous successful save',
    () async {
      final loaded = await port.loadMap(session, entry);
      await port.saveMap(session, loaded, loaded.map.copyWith(name: 'Saved'));
      await expectLater(
        port.saveMap(session, loaded, loaded.map.copyWith(name: 'Stale')),
        throwsA(problem(MapWorkspaceProblem.conflict)),
      );
      expect((await port.loadMap(session, entry)).map.name, 'Saved');
    },
  );
}
