import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('JSONL transports an atomic dialogue update without a map', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final worker = JsonlWorker(api: f.readApi, mutations: f.api);
    Future<AuthoringResult> command(
            String name, Map<String, Object?> args) async =>
        AuthoringResult.fromJson(
            jsonDecode(await worker.processLine(jsonEncode({
          'id': name,
          'command': name,
          'args': args,
        }))) as Map<String, dynamic>);
    final describe = await command('describe', {});
    expect(jsonEncode(describe.toJson()),
        contains('optional Yarn source atomically'));
    final entry = _Fixture.entry.copyWith(name: 'Publié via JSONL');
    final source = _Fixture.sourceText.replaceFirst('Bonjour', 'Salut');
    final request = await f.request(
        'dialogue.update', {'entry': entry.toJson(), 'source': source});
    final planned = await command('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson(),
    });
    expect(planned.status, AuthoringResultStatus.success,
        reason: jsonEncode(planned.toJson()));
    final applied = await command('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'jsonl-update',
    });
    expect(applied.status, AuthoringResultStatus.success,
        reason: jsonEncode(applied.toJson()));
    final disk = await f.loader.load(f.opened.projectHandle);
    expect(disk.manifest.dialogues.single, entry);
    expect(disk.maps, isEmpty);
    expect(await f.source.readAsString(), source);
  });

  test(
      'dialogue.update publishes entry and source in one plan and undo restores both',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final entry = _Fixture.entry.copyWith(
        name: 'Renommé',
        declaredOutcomes: const [
          DialogueDeclaredOutcome(id: 'partir', label: 'Partir')
        ]);
    const source =
        'title: Accueil\n---\nBienvenue\n-> Partir\n  <<outcome partir>>\n===\n';
    final request = await f.request('dialogue.update', {
      'entry': entry.toJson(),
      'source': source,
    });
    final planned = await f.api.planMutation(f.opened.projectHandle, request);
    expect(planned.plan.changeSet.changes.map((e) => e.storageKey).toSet(),
        {'project.json', 'dialogues/gare.yarn'});
    expect(await f.source.readAsString(), _Fixture.sourceText);
    final applied = await f.api.apply(f.opened.projectHandle,
        planId: planned.planId, operationId: 'atomic-update');
    final disk = await f.loader.load(f.opened.projectHandle);
    expect(disk.manifest.dialogues.single, entry);
    expect(await f.source.readAsString(), source);
    expect(
        const DialogueAuthoringCompiler()
            .compile(entry: entry, source: source)
            .canPublish,
        isTrue);
    final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
    await f.api.undo(f.opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-atomic-update');
    expect(
        (await f.loader.load(f.opened.projectHandle)).manifest.dialogues.single,
        _Fixture.entry);
    expect(await f.source.readAsString(), _Fixture.sourceText);
  });

  test('metadata rename with identical source writes only manifest', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final request = await f.request('dialogue.update', {
      'entry': _Fixture.entry.copyWith(name: 'Renommé').toJson(),
      'source': _Fixture.sourceText,
    });
    final planned = await f.api.planMutation(f.opened.projectHandle, request);
    expect(planned.plan.changeSet.changes.map((e) => e.storageKey),
        ['project.json']);
    expect(planned.plan.changeSet.diff.affectedResources.map((e) => e.kind),
        ['project']);
  });

  test('unchanged atomic and source-only requests are genuine no-ops',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    for (final action in ['dialogue.update', 'dialogue.source_update']) {
      final request = await f.request(action, {
        if (action == 'dialogue.update')
          'entry': _Fixture.entry.toJson()
        else
          'dialogueId': _Fixture.entry.id,
        'source': _Fixture.sourceText,
      });
      final planned = await f.api.planMutation(f.opened.projectHandle, request);
      expect(planned.plan.changeSet.changes, isEmpty);
      expect(planned.plan.changeSet.diff.affectedResources, isEmpty);
    }
  });

  test('delete remains confirmation protected at the canonical API', () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final planned = await f.api.planMutation(f.opened.projectHandle,
        await f.request('dialogue.delete', {'dialogueId': _Fixture.entry.id}));
    await expectLater(
        f.api.applyMutation(f.opened.projectHandle,
            planId: planned.planId, operationId: 'unconfirmed-delete'),
        throwsA(anything));
    expect(await f.source.exists(), isTrue);
    expect((await f.loader.load(f.opened.projectHandle)).manifest.dialogues,
        [_Fixture.entry]);
  });
}

class _Fixture {
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api,
      this.readApi);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final AuthoringReadApi readApi;
  File get source => File('${directory.path}/dialogues/gare.yarn');
  static const entry = ProjectDialogueEntry(
      id: 'gare',
      name: 'Chef de gare',
      relativePath: 'dialogues/gare.yarn',
      defaultStartNode: 'Accueil');
  static const sourceText = 'title: Accueil\n---\nBonjour !\n===\n';

  static Future<_Fixture> create() async {
    final directory = await Directory.systemTemp.createTemp('dialogue_atomic_');
    await Directory('${directory.path}/dialogues').create();
    await File('${directory.path}/${entry.relativePath}')
        .writeAsString(sourceText);
    await File('${directory.path}/project.json').writeAsString(jsonEncode(
        const ProjectManifest(
            name: 'Dialogue',
            maps: [],
            tilesets: [],
            dialogues: [entry]).toJson()));
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
    return _Fixture(directory, handles, opened, loader, api,
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
          idempotencyKey: action,
          parameters: parameters);

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
