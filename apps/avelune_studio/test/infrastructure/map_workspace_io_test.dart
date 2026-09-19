import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/src/features/map_workspace/application/map_workspace_port.dart';
import 'package:avelune_studio/src/features/map_workspace/infrastructure/local_map_workspace_adapter.dart';
import 'package:avelune_studio/src/features/project_session/application/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

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

  test('read is unchanged and save reload preserves untouched data', () async {
    final before = await mapFile.readAsBytes();
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
    expect(actual.map.properties, initial.properties);
    expect(await root.list().length, 2);
  });

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
    AtomicMapDocumentWriteCheckpoint.afterTempFlushed,
    AtomicMapDocumentWriteCheckpoint.afterJournalPrepared,
    AtomicMapDocumentWriteCheckpoint.beforeSecondCompareAndSwap,
  ]) {
    test(
      'failure at ${checkpoint.name} preserves last good map and retry works',
      () async {
        var fail = true;
        final failing = LocalMapWorkspaceAdapter(
          persistence: AtomicMapDocumentPersistence(
            faultInjector: (point, _) {
              if (point == checkpoint && fail) {
                throw const FileSystemException('injected write failure');
              }
            },
          ),
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
        expect(await root.list().length, 2);
        fail = false;
        await failing.saveMap(session, loaded, changed);
        expect((await failing.loadMap(session, entry)).map, changed);
      },
    );
  }

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
