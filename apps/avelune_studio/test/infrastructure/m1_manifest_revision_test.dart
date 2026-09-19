import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import 'project_fixture.dart';

void main() {
  test(
    'clean playtest recheck rejects changed manifest before map read and preserves saved work',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'studio-manifest-revision-',
      );
      final root = Directory(await temporary.resolveSymbolicLinks());
      addTearDown(() => root.delete(recursive: true));
      const entry = ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'map.json',
      );
      final manifest = ProjectManifest(
        name: 'Original',
        maps: [entry],
        tilesets: [],
      );
      final manifestFile = File('${root.path}/project.json');
      final mapFile = File('${root.path}/map.json');
      await manifestFile.writeAsString(jsonEncode(manifest.toJson()));
      await mapFile.writeAsBytes(
        encodeMapDocumentBytes(
          const MapData(
            id: 'map',
            name: 'Map',
            size: GridSize(width: 2, height: 2),
          ),
        ),
      );
      final reader = CountingProjectReader();
      final port = LocalMapWorkspaceAdapter(reader: reader);
      final session = ProjectSession(
        sessionId: 'test',
        name: 'Original',
        directoryPath: root.path,
      );
      final controller = MapWorkspaceController(session, port);
      addTearDown(controller.dispose);
      await controller.initialize();
      final document = controller.active!;
      document.commit(document.current.copyWith(name: 'Saved work'));
      expect(await controller.save(document), isTrue);
      expect(document.dirty, isFalse);
      final savedBytes = await mapFile.readAsBytes();
      final savedRevision = document.base.revision;
      await manifestFile.writeAsString(
        jsonEncode(manifest.copyWith(name: 'Outside change').toJson()),
      );
      reader.readPaths.clear();
      expect(await controller.save(document), isTrue);
      await expectLater(
        port.loadMap(session, entry),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (error) => error.problem,
            'problem',
            MapWorkspaceProblem.conflict,
          ),
        ),
      );
      expect(reader.readPaths, ['project.json']);
      expect(controller.active, same(document));
      expect(document.current.name, 'Saved work');
      expect(document.base.revision, savedRevision);
      expect(document.dirty, isFalse);
      expect(await mapFile.readAsBytes(), savedBytes);
      expect(
        jsonDecode(await manifestFile.readAsString())['name'],
        'Outside change',
      );
    },
  );
}
