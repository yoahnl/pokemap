import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _action = 'scene.dialogue.audioMedia.import';

void main() {
  test('audio import declares direct and JSONL execution evidence', () {
    final evidence =
        AuthoringFullParityCatalog.canonical().requireMutationAction(_action);
    expect(evidence.endToEndEvidence.keys.toSet(), {
      AuthoringTransport.directApi,
      AuthoringTransport.cli,
      AuthoringTransport.mcp
    });
  });

  test(
      'JSONL imports a probed sound atomically and reports the identity conflict precisely',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final described = await fixture.command('describe', {});
    expect(jsonEncode(described.toJson()), contains(_action));
    final artifact =
        await fixture.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
    final request = await fixture.request(artifact.reference.handle);
    final before = await fixture.projectFile.readAsBytes();
    final planned = await fixture.command('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(planned.status, AuthoringResultStatus.success);
    expect(await fixture.projectFile.readAsBytes(), before);
    final applied = await fixture.command('apply', {
      'projectHandle': fixture.opened.projectHandle.value,
      'planId': planned.data['planId'],
      'operationId': 'sound-jsonl'
    });
    expect(applied.status, AuthoringResultStatus.success);
    final reloaded = await fixture.loader.load(fixture.opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(reloaded.loadDiagnostics, isEmpty);
    final media = reloaded.manifest.cinematicMediaAssets.single;
    expect(media.kind, CinematicMediaAssetKind.sound);
    expect(media.loopByDefault, isFalse);
    expect(media.durationMs, 1000);
    expect(
        await File('${fixture.directory.path}/${media.relativePath}')
            .readAsBytes(),
        _wav());
    expect(
        await fixture.loader.readRetainedAssetBlob(
            fixture.opened.projectHandle, artifact.reference),
        _wav());
    final conflictBefore = await fixture.projectFile.readAsBytes();
    final conflict = await fixture.command('plan', {
      'projectHandle': fixture.opened.projectHandle.value,
      'request': (await fixture.request(artifact.reference.handle)).toJson()
    });
    expect(conflict.status, AuthoringResultStatus.failure);
    expect(conflict.error!.code, AuthoringErrorCode.validationFailed);
    expect(conflict.error!.details['domainCode'],
        'scene.dialogue.audio_media.conflict');
    expect(await fixture.projectFile.readAsBytes(), conflictBefore);
  });
}

List<int> _wav() {
  final bytes = Uint8List(8044);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, utf8.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, utf8.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, utf8.encode('data'));
  data.setUint32(40, 8000, Endian.little);
  bytes.fillRange(44, bytes.length, 128);
  return bytes;
}

final class _Fixture {
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api,
      this.worker);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  final JsonlWorker worker;
  File get projectFile => File('${directory.path}/project.json');

  static Future<_Fixture> create() async {
    final directory =
        await Directory.systemTemp.createTemp('dialogue-sound-jsonl-');
    await File('${directory.path}/project.json').writeAsString(jsonEncode(
        ProjectManifest(
            name: 'Original JSONL dialogue sound',
            maps: const [],
            tilesets: const []).toJson()));
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
    return _Fixture(
        directory,
        handles,
        opened,
        loader,
        api,
        JsonlWorker(
            api: AuthoringReadApi(openService: opener, snapshotLoader: loader),
            mutations: api));
  }

  Future<AuthoringResult> command(
          String command, Map<String, Object?> arguments) async =>
      AuthoringResult.fromJson(jsonDecode(await worker.processLine(jsonEncode(
              {'id': command, 'command': command, 'args': arguments})))
          as Map<String, dynamic>);

  Future<AuthoringRequest> request(String handle) async => AuthoringRequest(
          requestId: 'sound-jsonl',
          actionId: _action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: (await loader.load(opened.projectHandle)).revision,
          idempotencyKey: 'sound-jsonl',
          parameters: {
            'artifactHandle': handle,
            'assetId': 'sound',
            'mediaId': 'pickup',
            'label': 'Found',
            'logicalPath': 'assets/dialogue/found.wav'
          });

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
