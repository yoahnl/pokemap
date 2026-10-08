import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class MapMetadataFixture {
  MapMetadataFixture(
      this.root, this.api, this.snapshots, this.opened, this.worker);

  final Directory root;
  final LocalMapAuthoringMutationApi api;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  var sequence = 0;

  static Future<MapMetadataFixture> create({
    AuthoringTransactionFaultInjector? faultInjector,
    ProjectDimension dimension = ProjectDimension.twoD,
  }) async {
    final root = await Directory.systemTemp.createTemp('map-metadata-');
    final spatial = dimension == ProjectDimension.threeD;
    final version = spatial ? ProjectVersion.v9 : ProjectVersion.v8;
    final map = MapData(
      id: 'town',
      name: 'Town',
      version: version,
      size: const GridSize(width: 5, height: 4),
      spatialScene: spatial ? MapSpatialScene(width: 5, depth: 4) : null,
      tilesetId: '',
      layers: const [],
      warps: const [
        MapWarp(
            id: 'return',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'town',
            targetPos: GridPos(x: 2, y: 2))
      ],
    );
    final manifest = ProjectManifest(
      name: 'Metadata',
      version: version,
      settings: ProjectSettings(
          dimension: dimension,
          spatialCamera: spatial ? SpatialCameraProfile() : null),
      tilesets: const [],
      maps: const [
        ProjectMapEntry(
            id: 'town',
            name: 'Town',
            relativePath: 'documents/unusual.json',
            sortOrder: 7)
      ],
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'town'),
    );
    await Directory('${root.path}/documents').create();
    await File('${root.path}/documents/unusual.json')
        .writeAsBytes(encodeMapAuthoringDocument(map));
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final open = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        faultInjector: faultInjector);
    await api.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return MapMetadataFixture(
        root,
        api,
        snapshots,
        opened,
        JsonlWorker(
            api: AuthoringReadApi(openService: open, snapshotLoader: snapshots),
            mutations: api));
  }

  Future<AuthoringRequest> request(
      {String name = 'Village été', Map<String, Object?>? parameters}) async {
    final snapshot = await snapshots.load(opened.projectHandle);
    sequence++;
    return AuthoringRequest(
        requestId: 'metadata-$sequence',
        actionId: 'map.update_metadata',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: parameters ?? {'mapId': 'town', 'name': name},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'metadata-$sequence');
  }

  Future<Map<String, Object?>> plan(
          {String name = 'Village été',
          Map<String, Object?>? parameters}) async =>
      api.plan(opened.projectHandle,
          await request(name: name, parameters: parameters));

  Future<Map<String, Object?>> apply(Map<String, Object?> plan) =>
      api.apply(opened.projectHandle,
          planId: plan['planId']! as String,
          operationId: 'metadata-apply-$sequence');

  Future<AuthoringResult> wire(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode({
        'id': 'wire-${sequence++}',
        'command': command,
        'args': args,
      }))) as Map<String, dynamic>);

  Future<MapData> map() async => MapData.fromJson(jsonDecode(
          await File('${root.path}/documents/unusual.json').readAsString())
      as Map<String, dynamic>);
  Future<ProjectManifest> manifest() async => ProjectManifest.fromJson(
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>);
  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}
