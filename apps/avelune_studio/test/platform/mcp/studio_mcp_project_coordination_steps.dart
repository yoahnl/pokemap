import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<({List<ProjectMapEntry> entries, ProjectManifest project})>
seedCoordinationProject(
  Directory root, {
  required int foreignCount,
  required ProjectSessionStorage storage,
}) async {
  await Directory('${root.path}/maps').create();
  final entries = [
    for (final id in [
      'a',
      'b',
      for (var i = 0; i < foreignCount; i++) 'foreign-$i',
    ])
      ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
  ];
  for (final entry in entries) {
    final map = MapData(
      id: entry.id,
      name: entry.name,
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      layers: const [],
      spatialScene: MapSpatialScene(width: 4, depth: 4),
    );
    await File('${root.path}/${entry.relativePath}')
        .writeAsString(jsonEncode(map.toJson()));
  }
  final project = ProjectManifest(
    name: 'Coordination',
    version: ProjectVersion.v9,
    settings: ProjectSettings(
      dimension: ProjectDimension.threeD,
      spatialCamera: SpatialCameraProfile(),
    ),
    maps: entries,
    tilesets: const [],
  );
  if (storage == ProjectSessionStorage.workingCatalog) {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
      store: store,
      projectId: 'coordination',
      project: project,
    );
  } else {
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
  }
  return (entries: entries, project: project);
}

Future<AuthoringMutationPlanResult> planExternalMutation(
  LocalMapAuthoringMutationApi api,
  OpenedProject opened,
  String id,
  Map<String, Object?> parameters,
  String expectedRevision, {
  String actionId = 'map.update_metadata',
}) => api.planMutation(
  opened.projectHandle,
  AuthoringRequest(
    requestId: id,
    actionId: actionId,
    actionVersion: 1,
    workspaceHandle: opened.workspaceHandle.value,
    parameters: parameters,
    expectedRevision: expectedRevision,
    idempotencyKey: id,
  ),
);

Future<void> applyExternalMutation(
  LocalMapAuthoringMutationApi api,
  OpenedProject opened,
  String id,
  Map<String, Object?> parameters,
  String expectedRevision,
) async {
  final planned = await planExternalMutation(
    api,
    opened,
    id,
    parameters,
    expectedRevision,
  );
  await api.applyMutation(
    opened.projectHandle,
    planId: planned.planId,
    operationId: id,
  );
}

Future<Set<({String kind, String id})>> applyExternalChange(
  LocalMapAuthoringMutationApi api,
  OpenedProject opened,
  String id,
  Map<String, Object?> parameters,
  String expectedRevision, {
  String actionId = 'map.update_metadata',
}) async {
  final planned = await planExternalMutation(
    api,
    opened,
    id,
    parameters,
    expectedRevision,
    actionId: actionId,
  );
  final result = await api.apply(
    opened.projectHandle,
    planId: planned.planId,
    operationId: id,
  );
  final notification = result['changeNotification'] as Map;
  return {
    for (final ref in notification['resources'] as List)
      (kind: (ref as Map)['kind'] as String, id: ref['id'] as String),
  };
}
