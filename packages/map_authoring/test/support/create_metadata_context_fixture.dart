import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> arguments) async {
  final root = await Directory(arguments.first).create(recursive: true);
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  if (arguments.contains('--inspect-context')) {
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    stdout.writeln(jsonEncode({
      'metadataRevision': await store.requireMetadataContextAdmission(snapshot),
    }));
    return;
  }
  await WorkingProjectCatalog.create(
      store: store,
      projectId: 'metadata-context',
      project: const ProjectManifest(
          name: 'Metadata context', maps: [], tilesets: []));
  if (!arguments.contains('--verify-api')) return;
  const reader = LocalProjectFileReader();
  final handles = WorkspaceHandleStore();
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path], fileReader: reader);
  final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
      catalogMetadataFields: {}).openProject(root.path);
  final api = LocalMapAuthoringMutationApi(
      policy: policy, snapshotLoader: ProjectSnapshotLoader(handles: handles));
  await api.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle);
  try {
    await api.prepareWorkshopCatalog(opened.projectHandle);
    final snapshot = (await store.openRoot((await store.readHead())!)).snapshot;
    if (await store.metadataContextRevision(snapshot) != null) {
      throw StateError('Default preparation activated metadata context');
    }
    final before = await File('${root.path}/catalog/HEAD.json').readAsBytes();
    final result = await api.prepareWorkshopDocument(opened.projectHandle,
        scope: 'metadataContext');
    if (result['scope'] != 'explicitCatalogMetadataContext' ||
        result['contextVersion'] != 1 ||
        result['metadataRevision'] !=
            await store.requireMetadataContextAdmission(snapshot) ||
        base64.encode(
                await File('${root.path}/catalog/HEAD.json').readAsBytes()) !=
            base64.encode(before)) {
      throw StateError('The explicit metadata context contract differs');
    }
    stdout.writeln(jsonEncode(result));
  } finally {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
  }
}
