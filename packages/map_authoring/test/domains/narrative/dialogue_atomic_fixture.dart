import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

class DialogueAtomicFixture {
  DialogueAtomicFixture(this.directory, this.handles, this.opened, this.loader,
      this.api, this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  int _requests = 0;
  File get source => File('${directory.path}/dialogues/gare.yarn');
  static const entry = ProjectDialogueEntry(
      id: 'gare',
      name: 'Chef de gare',
      relativePath: 'dialogues/gare.yarn',
      defaultStartNode: 'Accueil');
  static const sourceText = 'title: Accueil\n---\nBonjour !\n===\n';

  static Future<DialogueAtomicFixture> create({bool catalog = false}) async {
    final directory = await Directory.systemTemp.createTemp('dialogue_atomic_');
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/${entry.relativePath}')
        .writeAsString(sourceText);
    const project = ProjectManifest(
        name: 'Dialogue', maps: [], tilesets: [], dialogues: [entry]);
    if (catalog) {
      final store = await CatalogStorageStore.open(projectRoot: directory.path);
      await WorkingProjectCatalog.create(
          store: store, projectId: 'dialogue-localization', project: project);
      await store.prepareLocalEditing();
    } else {
      await File('${directory.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(directory.path);
    final loader = ProjectSnapshotLoader(handles: handles);
    final api =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return DialogueAtomicFixture(directory, handles, opened, loader, api,
        AuthoringReadApi(openService: opener, snapshotLoader: loader));
  }

  Future<AuthoringRequest> request(
          String action, Map<String, Object?> parameters) async =>
      AuthoringRequest(
          requestId: action,
          actionId: action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: (await loader.load(opened.projectHandle)).revision,
          idempotencyKey: '$action-${++_requests}',
          parameters: parameters);

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
