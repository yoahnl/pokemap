import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'character_studio_character_actions_test.dart'
    show characterActionSnapshot;

final class CharacterDeletionFixture {
  CharacterDeletionFixture(
      this.root, this.api, this.snapshots, this.opened, this.worker);
  final Directory root;
  final LocalMapAuthoringMutationApi api;
  final ProjectSnapshotLoader snapshots;
  final OpenedProject opened;
  final JsonlWorker worker;
  int sequence = 0;

  static Future<CharacterDeletionFixture> create(
      {AuthoringTransactionFaultInjector? faultInjector}) async {
    final root =
        await Directory.systemTemp.createTemp('uwu5-character-delete-');
    final snapshot = characterActionSnapshot(
      withReferences: true,
      configuredPlayer: true,
      compatiblePlayer: true,
      rawMetadata: true,
      dialogueSource:
          'title: Start\n---\n<<portrait elia neutral>>\nÉlia: Bonjour elia.\n===\n',
    );
    for (final entry in snapshot.resourceStorageKeys.entries) {
      final file = File('${root.path}/${entry.value}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(snapshot.resourceBytes(entry.key));
    }
    final projectFile = File('${root.path}/project.json');
    final raw =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    (raw['maps'] as List).add(const ProjectMapEntry(
            id: 'untouched',
            name: 'Autre carte fermée',
            relativePath: 'maps/untouched.json')
        .toJson());
    (raw['dialogues'] as List).addAll([
      const ProjectDialogueEntry(
              id: 'second',
              name: 'Second portrait',
              relativePath: 'dialogues/second.yarn')
          .toJson(),
      const ProjectDialogueEntry(
              id: 'untouched',
              name: 'Source étrangère',
              relativePath: 'dialogues/untouched.yarn')
          .toJson(),
    ]);
    await projectFile.writeAsString(jsonEncode(raw));
    await File('${root.path}/maps/untouched.json').writeAsString(jsonEncode(
        MapData(
                id: 'untouched',
                name: 'Autre carte fermée',
                size: const GridSize(width: 8, height: 8))
            .toJson()));
    await File('${root.path}/dialogues/second.yarn').writeAsString(
        'title: Start\n---\n<<portrait elia neutral>>\nUn second dialogue elia.\n===\n');
    await File('${root.path}/dialogues/untouched.yarn').writeAsString(
        'title: Start\n---\nLe mot elia est du texte, pas une référence.\n===\n');
    final portrait = AssetCatalog.fromJson(jsonDecode(utf8
                .decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
            as Map<String, dynamic>)
        .records
        .single;
    final pixels = snapshot
        .resourceBytes(assetBlobResourceIdentity(portrait.artifact.digest));
    await File('${root.path}/assets/characters.png').writeAsBytes(pixels);
    await File('${root.path}/unrelated.txt')
        .writeAsString('Élia elia remains unchanged.');
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
    return CharacterDeletionFixture(
        root,
        api,
        snapshots,
        opened,
        JsonlWorker(
            api: AuthoringReadApi(openService: open, snapshotLoader: snapshots),
            mutations: api));
  }

  Future<AuthoringRequest> request({bool inspect = false}) async {
    final snapshot = await snapshots.load(opened.projectHandle);
    sequence++;
    return AuthoringRequest(
        requestId: 'character-$sequence',
        actionId: inspect
            ? 'characterStudio.character.deletePlan'
            : 'characterStudio.character.delete',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: inspect
            ? {'characterId': 'elia'}
            : {
                'characterId': 'elia',
                'resolution': 'replace',
                'replacementId': 'nox'
              },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'character-$sequence',
        dryRun: inspect);
  }

  Future<Map<String, Object?>> plan() async =>
      api.plan(opened.projectHandle, await request());
  Future<Map<String, Object?>> apply(
      Map<String, Object?> planned, String operation) async {
    final confirmation = await api.confirm(opened.projectHandle,
        planId: planned['planId'] as String);
    return api.apply(opened.projectHandle,
        planId: planned['planId'] as String,
        operationId: operation,
        confirmationToken: confirmation['confirmationToken'] as String);
  }

  Future<AuthoringResult> wire(
          String command, Map<String, Object?> args) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': 'wire-${sequence++}', 'command': command, 'args': args})))
          as Map<String, dynamic>);
  Future<ProjectSnapshot> independent() async {
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final opened = await ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles)
        .openProject(root.path);
    try {
      return await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle);
    } finally {
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  Future<void> dispose() async {
    await wire('close', {'workspaceHandle': opened.workspaceHandle.value});
    await root.delete(recursive: true);
  }
}
