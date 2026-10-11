import 'dart:async';
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('presentation drafts read only the manifest and media catalogs',
      () async {
    final f = await _Fixture.open();
    final snapshot = await f.loader
        .loadPresentationDraft(f.opened.projectHandle)
        .timeout(const Duration(seconds: 2));

    expect(snapshot.manifest, f.project);
    expect(snapshot.maps, isEmpty);
    expect(snapshot.resourceStorageKeys.values.toSet(),
        f.reader.resources.keys.toSet());
    expect(f.reader.reads.toSet(), f.reader.resources.keys.toSet());
    expect(snapshot.revision, matches(r'^sha256:[0-9a-f]{64}$'));
    expect(
        () => snapshot.resourceBytes('project')[0] = 0, throwsUnsupportedError);
    final draft = PresentationCinematicDraft.fromSnapshot(
      snapshot,
      expectedProject: f.project,
    );
    expect(draft.manifest, f.project);
  });

  test('a catalog changed between observations rejects the draft', () async {
    final f = await _Fixture.open();
    f.reader.onRead = (path, count) {
      if (path == assetCatalogStorageKey && count == 2) {
        return utf8.encode(jsonEncode(AssetCatalog().toJson()));
      }
      return null;
    };

    await expectLater(
      f.loader.loadPresentationDraft(f.opened.projectHandle),
      throwsA(isA<ProjectSnapshotException>().having(
        (error) => error.code,
        'code',
        'project.changed_during_snapshot',
      )),
    );
  });

  test('a catalog appearing between observations rejects the draft', () async {
    final f = await _Fixture.open();
    f.reader.resources.remove(projectMediaCatalogStorageKey);
    f.reader.onRead = (path, count) {
      if (path == projectMediaCatalogStorageKey && count == 2) {
        return encodeProjectMediaCatalogBytes(ProjectMediaCatalog());
      }
      return null;
    };

    await expectLater(
      f.loader.loadPresentationDraft(f.opened.projectHandle),
      throwsA(isA<ProjectSnapshotException>().having(
        (error) => error.code,
        'code',
        'project.changed_during_snapshot',
      )),
    );
  });

  test('closing the workspace rejects a presentation draft read', () async {
    final f = await _Fixture.open();
    f.handles.closeWorkspace(f.opened.workspaceHandle);
    await expectLater(
      f.loader.loadPresentationDraft(f.opened.projectHandle),
      throwsA(isA<WorkspaceHandleException>()),
    );
  });
}

class _Fixture {
  _Fixture(this.project, this.reader, this.handles, this.opened, this.loader);
  final ProjectManifest project;
  final _Reader reader;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;

  static Future<_Fixture> open() async {
    final project = ProjectManifest(
      name: 'Présentation',
      version: ProjectVersion.v8,
      maps: const [
        ProjectMapEntry(
            id: 'cloud', name: 'Carte cloud', relativePath: 'maps/cloud.json')
      ],
      tilesets: const [],
      presentationCinematics: [
        PresentationCinematicAsset(
            id: 'intro', title: 'Introduction', durationUs: 1000000)
      ],
    );
    final reader = _Reader({
      'project.json': utf8.encode(jsonEncode(project.toJson())),
      assetCatalogStorageKey: utf8.encode(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: 'cloud',
            logicalPath: 'assets/cloud.png',
            artifact: ContentArtifactRef.fromBytes([1, 2, 3],
                mediaType: 'image/png')),
      ]).toJson())),
      projectMediaCatalogStorageKey:
          encodeProjectMediaCatalogBytes(ProjectMediaCatalog()),
    });
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: ['/project'], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject('/project');
    addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));
    reader.reads.clear();
    reader.counts.clear();
    return _Fixture(project, reader, handles, opened,
        ProjectSnapshotLoader(handles: handles));
  }
}

class _Reader implements ProjectFileReader {
  _Reader(this.resources);
  final Map<String, List<int>> resources;
  final reads = <String>[];
  final counts = <String, int>{};
  List<int>? Function(String path, int count)? onRead;

  @override
  Future<String> canonicalizeDirectory(String path) async => path;

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    reads.add(relativePath);
    final count =
        counts.update(relativePath, (value) => value + 1, ifAbsent: () => 1);
    final intercepted = onRead?.call(relativePath, count);
    if (intercepted != null) return intercepted;
    final bytes = resources[relativePath];
    if (bytes != null) return bytes;
    if (relativePath == assetCatalogStorageKey ||
        relativePath == projectMediaCatalogStorageKey) {
      throw const WorkspaceAccessException(
          'workspace.file_unavailable', 'Catalog absent');
    }
    return Completer<List<int>>().future;
  }
}
