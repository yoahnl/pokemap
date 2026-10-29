import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late AuthoringReadApi read;
  late OpenedProject opened;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('map-view-');
    await File('${root.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(name: 'Views', maps: [
      ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'maps/field.json'),
    ], tilesets: []).toJson()));
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/field.json').writeAsString(jsonEncode(
        const MapData(id: 'field', name: 'Field', size: GridSize(width: 4, height: 3))
            .toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    read = AuthoringReadApi(
        openService:
            ProjectOpenService(policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: ProjectSnapshotLoader(handles: handles));
    opened = await read.openProject(root.path);
  });

  tearDown(() => root.delete(recursive: true));

  test('reads one map with its manifest at the snapshot revision', () async {
    final view = await read.readMapView(opened.projectHandle, 'field');
    expect(view.map.id, 'field');
    expect(view.map.size, const GridSize(width: 4, height: 3));
    expect(view.manifest.maps.single.id, 'field');
    final page = await read.queryProject(opened.projectHandle,
        AuthoringQueryRequest(resourceKind: 'map', operation: AuthoringQueryOperation.list));
    expect(view.revision, page.snapshotRevision);
  });

  test('an unknown map is reported as a missing resource', () {
    expect(
      read.readMapView(opened.projectHandle, 'nowhere'),
      throwsA(isA<AuthoringQueryException>()
          .having((error) => error.code, 'code', 'query.resource_not_found')),
    );
  });
}
