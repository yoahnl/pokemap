import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';
import 'resource_usage_projection_test.dart' show planche, decor, noPokemon;

void main() {
  for (final transport in ['direct', 'jsonl']) {
    test('$transport resourceUsage reads closed maps without reading binaries',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('resource_usage_transport_');
      addTearDown(() => directory.delete(recursive: true));
      final map = catalogMap('closed').copyWith(placedElements: const [
        MapPlacedElement(
            id: 'instance',
            layerId: 'base',
            elementId: 'shared',
            pos: GridPos(x: 1, y: 1))
      ]);
      final manifest =
          ProjectManifest(name: 'Fixture', pokemon: noPokemon, maps: const [
        ProjectMapEntry(
            id: 'closed',
            name: 'Carte fermée',
            relativePath: 'maps/closed.json')
      ], tilesets: [
        planche
      ], elements: [
        decor
      ]);
      final catalog = AssetCatalog(records: [
        AssetRecord(
            id: 'physical',
            logicalPath: planche.relativePath,
            artifact:
                ContentArtifactRef.fromBytes([1, 2], mediaType: 'image/png'))
      ]);
      final files = {
        'project.json': jsonEncode(manifest.toJson()),
        'maps/closed.json': jsonEncode(map.toJson()),
        assetCatalogStorageKey: jsonEncode(catalog.toJson()),
      };
      for (final entry in files.entries) {
        final file = File('${directory.path}/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }
      final reader = UsageTransportReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [directory.path], fileReader: reader);
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final api = AuthoringReadApi(
          openService: ProjectOpenService(
              policy: policy, fileReader: reader, handles: handles),
          snapshotLoader: snapshots);
      final opened = await api.openProject(directory.path);
      addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
      final request = AuthoringQueryRequest(
          resourceKind: 'resourceUsage',
          operation: AuthoringQueryOperation.get,
          ids: ['images:shared'],
          view: AuthoringQueryView.detail);
      Map<String, Object?> result;
      if (transport == 'direct') {
        result =
            (await api.queryProject(opened.projectHandle, request)).toJson();
      } else {
        final worker = JsonlWorker(api: api);
        final response = AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': 'read',
          'command': 'query',
          'args': {
            'projectHandle': opened.projectHandle.value,
            'request': request.toJson()
          }
        }))) as Map<String, dynamic>);
        expect(response.status, AuthoringResultStatus.success,
            reason: response.toJson().toString());
        result = response.data;
      }
      final report = (result['items'] as List).single as Map;
      expect(report['complete'], isTrue);
      final entries = (report['entries'] as List).cast<Map>();
      expect(
          entries.any((entry) =>
              entry['ownerKind'] == 'map' &&
              entry['ownerId'] == 'closed' &&
              entry['entityId'] == 'instance'),
          isTrue);
      expect(
          reader.paths
              .any((path) => path.endsWith('.png') || path.endsWith('.blob')),
          isFalse);
      for (final entry in files.entries) {
        expect(await File('${directory.path}/${entry.key}').readAsString(),
            entry.value);
      }
    });
  }
}

final class UsageTransportReader
    implements ProjectFileReader, ProjectDirectoryReader {
  final delegate = const LocalProjectFileReader();
  final paths = <String>[];
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<String>> listFiles(
          {required String projectRoot, required String relativeDirectory}) =>
      delegate.listFiles(
          projectRoot: projectRoot, relativeDirectory: relativeDirectory);
  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
