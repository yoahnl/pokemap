import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_targeted_map_edit.dart';
import 'package:map_core/map_core.dart';

final class ResourceIndexFixture {
  ResourceIndexFixture._(this.root, this.store, this.handles, this.opened,
      this.api, this.loader, this.reader, this.descriptor);

  final Directory root;
  final CatalogStorageStore store;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final LocalMapAuthoringMutationApi api;
  final ProjectSnapshotLoader loader;
  final ResourceIndexReader reader;
  final Map<String, Object?> descriptor;
  var _sequence = 0;

  static Future<ResourceIndexFixture> create({
    required Directory root,
    required ProjectManifest project,
    required List<MapData> maps,
    Map<String, List<int>> files = const {},
  }) async {
    await root.create(recursive: true);
    for (final map in maps) {
      final path =
          project.maps.singleWhere((entry) => entry.id == map.id).relativePath;
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map.toJson()));
    }
    for (final entry in files.entries) {
      final file = File('${root.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    final working = await WorkingProjectCatalog.create(
        store: store, projectId: 'resource-index-fixture', project: project);
    final descriptor = working.descriptor.toJson();
    await working.close();
    return openExisting(root, descriptor: descriptor);
  }

  static Future<ResourceIndexFixture> openExisting(Directory root,
      {Map<String, Object?>? descriptor}) async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    descriptor ??= Map<String, Object?>.from(
        jsonDecode(await File('${root.path}/project.json').readAsString())
            as Map);
    final handles = WorkspaceHandleStore();
    final reader = ResourceIndexReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        catalogMetadataFields: {}).openProject(root.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: loader, catalogFileReader: reader);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    await api.prepareWorkshopCatalog(opened.projectHandle);
    return ResourceIndexFixture._(
        root, store, handles, opened, api, loader, reader, descriptor);
  }

  Future<void> prepare() => api.prepareWorkshopCatalog(opened.projectHandle,
      scope: 'resourceIndexes');

  Future<CatalogSnapshot> catalog() async =>
      (await store.openRoot((await store.readHead())!)).snapshot;

  Future<AuthoringMutationResult> mutate(
      String action, Map<String, Object?> parameters) async {
    final String revision;
    if (action == 'map.save') {
      final current = (await CatalogProjectReader.open(
          store: store, descriptor: descriptor, metadataFields: {}))!;
      final selection = await CatalogTargetedMapSelection.read(
          reader: current, mapId: (parameters['map'] as Map)['id'] as String);
      revision = selection.snapshotRevision;
    } else {
      revision = (await api.readWorkshopSnapshot(opened.projectHandle,
              actionId: action, parameters: parameters))
          .revision;
    }
    final id =
        'resource-index-${DateTime.now().microsecondsSinceEpoch}-${++_sequence}';
    final plan = await api.planMutation(
        opened.projectHandle,
        AuthoringRequest(
          requestId: id,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: parameters,
          expectedRevision: revision,
          idempotencyKey: id,
          extensions:
              action == 'map.save' ? const {} : const {'workshopScope': true},
        ));
    try {
      return await api.applyMutation(opened.projectHandle,
          planId: plan.planId, operationId: id);
    } finally {
      await plan.plan.releaseAppliedPayload();
    }
  }

  Future<void> close() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}

final class ResourceIndexReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final delegate = const LocalProjectFileReader();
  final paths = <String>[];
  final decodedUnits = <String, int>{};
  final forbiddenPaths = <String>{};

  void clear() {
    paths.clear();
    decodedUnits.clear();
  }

  void _record(String path, List<int> bytes) {
    paths.add(path);
    if (forbiddenPaths.contains(path)) {
      throw StateError('Unrelated resource read: $path');
    }
    if (!path.startsWith('catalog/objects/')) return;
    final json = jsonDecode(utf8.decode(bytes));
    if (json is Map && json['type'] == 'unit') {
      final key = json['key'] as Map;
      final identity = '${key['kind']}:${key['id']}';
      decodedUnits.update(identity, (value) => value + 1, ifAbsent: () => 1);
    }
  }

  @override
  bool get supportsStreamingResources => true;
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
    final bytes = await delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
    _record(relativePath, bytes);
    return bytes;
  }

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) async* {
    yield await readBytes(projectRoot: projectRoot, relativePath: relativePath);
  }
}
