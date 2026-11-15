import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class CatalogMapLifecycleFixture {
  CatalogMapLifecycleFixture._(
    this.root,
    this.reader,
    this.handles,
    this.api,
    this.opened,
    this.descriptor,
  );

  final Directory root;
  final CatalogLifecycleReader reader;
  final WorkspaceHandleStore handles;
  final LocalMapAuthoringMutationApi api;
  final OpenedProject opened;
  final WorkingProjectCatalogDescriptor descriptor;
  var _operations = 0;

  static MapData spatialMap(String id) => MapData(
        id: id,
        name: id,
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(width: 8, depth: 8),
      );

  static Future<CatalogMapLifecycleFixture> open(
    int foreign, {
    MapData? source,
  }) async {
    final temporary = await Directory.systemTemp.createTemp('map-lifecycle-');
    final root = Directory(await temporary.resolveSymbolicLinks());
    final project = ProjectManifest(
      name: 'Lifecycle',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [
        for (final id in [
          'source',
          'other',
          for (var i = 0; i < foreign; i++) 'foreign-$i',
        ])
          ProjectMapEntry(
            id: id,
            name: id,
            relativePath: 'maps/$id.json',
            groupId: id == 'other' ? 'villes' : null,
          ),
      ],
      tilesets: const [],
      groups: const [
        ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.route),
        ProjectMapGroup(
          id: 'routes',
          name: 'Routes',
          type: MapGroupType.route,
          parentGroupId: 'johto',
          sortOrder: 1,
        ),
        ProjectMapGroup(
          id: 'villes',
          name: 'Villes',
          type: MapGroupType.city,
          parentGroupId: 'johto',
          sortOrder: 2,
        ),
      ],
    );
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
      store: store,
      projectId: 'lifecycle',
      project: project,
    );
    final descriptor = working.descriptor;
    await working.close();
    await Directory('${root.path}/maps').create();
    for (final map in [source ?? spatialMap('source'), spatialMap('other')]) {
      await File(
        '${root.path}/maps/${map.id}.json',
      ).writeAsString(jsonEncode(map.toJson()));
    }
    for (var i = 0; i < foreign; i++) {
      await File(
        '${root.path}/maps/foreign-$i.json',
      ).writeAsString('unrelated map must not be decoded');
    }
    final reader = CatalogLifecycleReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {},
    ).openProject(root.path);
    final api = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      catalogFileReader: reader,
    );
    await api.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return CatalogMapLifecycleFixture._(
      root,
      reader,
      handles,
      api,
      opened,
      descriptor,
    );
  }

  Future<AuthoringMutationResult> apply(
    String actionId,
    Map<String, Object?> parameters,
  ) async {
    final id = '$actionId-${_operations++}';
    final snapshot = await api.readWorkshopSnapshot(
      opened.projectHandle,
      actionId: actionId,
      parameters: parameters,
    );
    final plan = await api.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: id,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: id,
        parameters: parameters,
        extensions: const {'workshopScope': true},
      ),
    );
    return api.applyMutation(
      opened.projectHandle,
      planId: plan.planId,
      operationId: id,
    );
  }

  Future<ProjectManifest> metadata() async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.open(
      store: store,
      descriptor: descriptor,
      metadataFields: {'maps', 'groups'},
    );
    try {
      return working.catalog.projectMetadata;
    } finally {
      await working.close();
    }
  }

  Future<List<ProjectMapGroup>> groups() async => (await metadata()).groups;

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await root.delete(recursive: true);
  }
}

final class CatalogLifecycleReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  bool get supportsStreamingResources => true;
  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) =>
      delegate.probeResource(
        projectRoot: projectRoot,
        relativePath: relativePath,
      );
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
