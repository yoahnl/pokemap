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
  late ProjectSession session;
  late LocalMapWorkspaceAdapter port;
  const map = MapData(
    id: 'alpha',
    name: 'Alpha',
    size: GridSize(width: 1, height: 1),
  );
  const entry = ProjectMapEntry(
    id: 'alpha',
    name: 'Alpha',
    relativePath: 'alpha.json',
  );

  Future<void> open(ProjectMapEntry declared) async {
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(name: 'Test', maps: [declared], tilesets: []).toJson(),
      ),
    );
    await port.loadProject(session);
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-map-safety-');
    root = Directory(await root.resolveSymbolicLinks());
    mapFile = File('${root.path}/alpha.json');
    await mapFile.writeAsBytes(encodeMapDocumentBytes(map));
    session = ProjectSession(
      sessionId: root.path,
      name: 'Test',
      directoryPath: root.path,
    );
    port = LocalMapWorkspaceAdapter();
    await open(entry);
  });
  tearDown(() => root.delete(recursive: true));

  final unsafePath = throwsA(
    isA<MapWorkspaceFailure>().having(
      (e) => e.problem,
      'problem',
      MapWorkspaceProblem.unsafePath,
    ),
  );

  test('declared traversal is rejected before reading another file', () async {
    final unsafe = entry.copyWith(relativePath: '../outside.json');
    await open(unsafe);
    await expectLater(port.loadMap(session, unsafe), unsafePath);
  });

  test('a declared parent symlink cannot escape the project', () async {
    final outside = await Directory.systemTemp.createTemp('avelune-outside-');
    addTearDown(() => outside.delete(recursive: true));
    final outsideFile = File('${outside.path}/alpha.json');
    final before = encodeMapDocumentBytes(map.copyWith(name: 'Outside'));
    await outsideFile.writeAsBytes(before);
    await Link('${root.path}/linked').create(outside.path);
    final unsafe = entry.copyWith(relativePath: 'linked/alpha.json');
    await open(unsafe);
    await expectLater(port.loadMap(session, unsafe), unsafePath);
    expect(await outsideFile.readAsBytes(), before);
  });

  test(
    'loading never promotes or cleans interrupted write artifacts',
    () async {
      final crash = AtomicMapDocumentPersistence(
        faultInjector: (point, _) {
          if (point == AtomicMapDocumentWriteCheckpoint.afterJournalPrepared) {
            throw const AtomicMapDocumentSimulatedCrash();
          }
        },
      );
      final before = await mapFile.readAsBytes();
      await expectLater(
        crash.write(
          mapFile.path,
          encodeMapDocumentBytes(map.copyWith(name: 'Prepared')),
          precondition: MapDocumentWritePrecondition.revision(
            narrativeEventBytesFingerprint(before),
          ),
        ),
        throwsA(isA<AtomicMapDocumentSimulatedCrash>()),
      );
      final inventoryBefore =
          await root.list().map((entry) => entry.path).toList()
            ..sort();
      final loaded = await port.loadMap(session, entry);
      expect(loaded.map, map);
      expect(await mapFile.readAsBytes(), before);
      expect(
        await root.list().map((entry) => entry.path).toList()
          ..sort(),
        inventoryBefore,
      );
    },
  );
}
