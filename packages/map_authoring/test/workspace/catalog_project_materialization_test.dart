import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  late CatalogStorageStore store;
  late WorkingProjectCatalogDescriptor descriptor;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('catalog-materialized-');
    store = await CatalogStorageStore.open(projectRoot: directory.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'materialized',
      project: const ProjectManifest(
        name: 'Working',
        maps: [
          ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'map.json')
        ],
        tilesets: [
          ProjectTilesetEntry(
              id: 'tile', name: 'Before', relativePath: 'tile.png')
        ],
      ),
    );
    descriptor = working.descriptor;
    await File('${directory.path}/map.json').writeAsString(jsonEncode(
        const MapData(
                id: 'map', name: 'Map', size: GridSize(width: 1, height: 1))
            .toJson()));
  });

  tearDown(() => directory.delete(recursive: true));

  Future<void> renameTile(String name) async {
    final working =
        await WorkingProjectCatalog.open(store: store, descriptor: descriptor);
    final unit = (await working
        .lookup(CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'tile')))!;
    final updated = working.replaceDefinitionValue(unit, {
      ...Map<String, Object?>.from(unit.payload['value']! as Map),
      'name': name
    });
    final editing = await CatalogEditingSession.open(
        store: store, projectId: descriptor.projectId, actorId: 'test');
    try {
      final plan = await editing
          .planPatch(upserts: [updated], idempotencyKey: 'rename-$name');
      await editing.apply(plan);
    } finally {
      await editing.close();
    }
  }

  test(
      'full catalog snapshot retains real descriptor and HEAD and invalidates cached generations',
      () async {
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [directory.path], fileReader: reader),
        fileReader: reader,
        handles: handles);
    final opened = await service.openProject(directory.path);
    addTearDown(() => service.closeWorkspace(opened.workspaceHandle));
    final cache = ProjectSnapshotCache();
    final loader = ProjectSnapshotLoader(
        handles: handles,
        snapshotCache: cache,
        fingerprintCache: ProjectSnapshotFingerprintCache());
    final first = await loader.load(opened.projectHandle);
    expect(first.materializedCatalogProject, isTrue);
    expect(first.manifest.tilesets.single.name, 'Before');
    expect(first.resourceBytes('project'),
        await File('${directory.path}/project.json').readAsBytes());
    expect(
        first.resourceBytes('catalogHead'),
        await File('${directory.path}/${CatalogStorageStore.headStorageKey}')
            .readAsBytes());
    final second = await loader.load(opened.projectHandle);
    expect(second.revision, first.revision);
    expect(cache.hits, 1);
    await renameTile('After');
    final third = await loader.load(opened.projectHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session);
    expect(third.manifest.tilesets.single.name, 'After');
    expect(third.revision, isNot(first.revision));
    expect(third.resourceBytes('project'), first.resourceBytes('project'));
    expect(third.resourceBytes('catalogHead'),
        isNot(first.resourceBytes('catalogHead')));
    expect(cache.invalidations, greaterThan(0));
  });

  test('HEAD changing after materialization rejects a mixed snapshot',
      () async {
    final reader = _HookReader();
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [directory.path], fileReader: reader),
        fileReader: reader,
        handles: handles);
    final opened = await service.openProject(directory.path);
    addTearDown(() => service.closeWorkspace(opened.workspaceHandle));
    reader.onMap = () => renameTile('Concurrent');
    await expectLater(
        ProjectSnapshotLoader(handles: handles).load(opened.projectHandle),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.changed_during_snapshot')));
  });

  test('presentation drafts also materialize their full catalog context',
      () async {
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [directory.path], fileReader: reader),
        fileReader: reader,
        handles: handles);
    final opened = await service.openProject(directory.path);
    addTearDown(() => service.closeWorkspace(opened.workspaceHandle));
    final snapshot = await ProjectSnapshotLoader(handles: handles)
        .loadPresentationDraft(opened.projectHandle);
    expect(snapshot.materializedCatalogProject, isTrue);
    expect(snapshot.manifest.tilesets.single.id, 'tile');
    expect(snapshot.resourceBytes('project'),
        await File('${directory.path}/project.json').readAsBytes());
    expect(
        snapshot.resourceBytes('catalogHead'),
        await File('${directory.path}/${CatalogStorageStore.headStorageKey}')
            .readAsBytes());
    expect(
        ProjectManifest.fromJson(
                jsonDecode(utf8.decode(snapshot.authoringProjectBytes))
                    as Map<String, dynamic>)
            .tilesets
            .single
            .id,
        'tile');
  });

  test('descriptor changing after materialization rejects a mixed snapshot',
      () async {
    final reader = _HookReader();
    final handles = WorkspaceHandleStore();
    final service = ProjectOpenService(
        policy: await WorkspacePolicy.create(
            allowedRootPaths: [directory.path], fileReader: reader),
        fileReader: reader,
        handles: handles);
    final opened = await service.openProject(directory.path);
    addTearDown(() => service.closeWorkspace(opened.workspaceHandle));
    reader.onMap = () => File('${directory.path}/project.json').writeAsString(
        jsonEncode(
            WorkingProjectCatalogDescriptor(projectId: 'other').toJson()));
    await expectLater(
        ProjectSnapshotLoader(handles: handles).load(opened.projectHandle),
        throwsA(isA<ProjectSnapshotException>().having(
            (error) => error.code, 'code', 'project.changed_during_snapshot')));
  });
}

final class _HookReader
    implements
        ProjectFileReader,
        ProjectResourceProbeReader,
        ProjectResourceStreamReader {
  Future<void> Function()? onMap;
  final LocalProjectFileReader delegate = const LocalProjectFileReader();

  @override
  bool get supportsStreamingResources => true;

  @override
  Stream<List<int>> openRead(
          {required String projectRoot, required String relativePath}) =>
      delegate.openRead(projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) async {
    if (relativePath == 'map.json') {
      final hook = onMap;
      onMap = null;
      await hook?.call();
    }
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
