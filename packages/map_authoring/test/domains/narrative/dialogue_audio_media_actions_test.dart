import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _action = 'scene.dialogue.audioMedia.import';

void main() {
  test(
      'canonical typed music imports a looping track with exact retained bytes',
      () async {
    final f = await _Fixture.create();
    addTearDown(f.dispose);
    final stored =
        await f.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
    final req = await f.request(stored.reference.handle, mediaKind: 'music');
    final plan = await f.api.planMutation(f.opened.projectHandle, req);
    await f.api.apply(f.opened.projectHandle,
        planId: plan.planId, operationId: 'music');
    final snapshot = await f.loader
        .load(f.opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
    final media = snapshot.manifest.cinematicMediaAssets.single;
    expect(media.kind, CinematicMediaAssetKind.music);
    expect(media.loopByDefault, isTrue);
    expect(media.durationMs, 1000);
    expect(
        await File('${f.directory.path}/${media.relativePath}').readAsBytes(),
        _wav());
    expect(
        await f.loader
            .readRetainedAssetBlob(f.opened.projectHandle, stored.reference),
        _wav());
  });
  for (final kind in <Object?>[null, 'soundEffect', 'Music', 0, false]) {
    test(
        'canonical audio rejects unknown or malformed explicit media kind $kind',
        () async {
      final f = await _Fixture.create();
      addTearDown(f.dispose);
      final stored =
          await f.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
      final req = await f.request(stored.reference.handle,
          mediaKind: kind, explicitKind: true);
      final before = await f.projectFile.readAsBytes();
      await expectLater(
          f.api.planMutation(f.opened.projectHandle, req), throwsA(anything));
      expect(await f.projectFile.readAsBytes(), before);
    });
  }
  test(
      'canonical dialogue audio import atomically survives a strict native reopen',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final bytes = _wav();
    final stored =
        await fixture.api.artifacts.put(bytes, declaredMediaType: 'audio/wav');
    expect(
        MapMutationDispatcher.canonical().descriptor(_action).guarantees,
        containsAll(
            [AuthoringGuarantee.atomic, AuthoringGuarantee.revisionChecked]));
    final planned = await fixture.api.planMutation(fixture.opened.projectHandle,
        await fixture.request(stored.reference.handle));
    expect(
        (await fixture.loader.load(fixture.opened.projectHandle))
            .manifest
            .cinematicMediaAssets,
        isEmpty);
    await fixture.api.apply(fixture.opened.projectHandle,
        planId: planned.planId, operationId: 'sound');
    final reloaded = await fixture.loader.load(fixture.opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.strict);
    expect(reloaded.loadDiagnostics, isEmpty);
    final media = reloaded.manifest.cinematicMediaAssets.single;
    expect(media.id, 'pickup');
    expect(media.kind, CinematicMediaAssetKind.sound);
    expect(media.loopByDefault, isFalse);
    expect(media.durationMs, 1000);
    expect(
        await File('${fixture.directory.path}/${media.relativePath}')
            .readAsBytes(),
        bytes);
    final blob = await fixture.loader
        .readRetainedAssetBlob(fixture.opened.projectHandle, stored.reference);
    expect(blob, bytes);
  });

  test('a mislabeled or non-audio artifact cannot create a dialogue sound',
      () async {
    final fixture = await _Fixture.create();
    addTearDown(fixture.dispose);
    final stored = await fixture.api.artifacts.put(
        utf8.encode('{"original":true}'),
        declaredMediaType: 'application/json');
    final before = await fixture.projectFile.readAsBytes();
    await expectLater(
        fixture.api.planMutation(fixture.opened.projectHandle,
            await fixture.request(stored.reference.handle)),
        throwsA(anything));
    expect(await fixture.projectFile.readAsBytes(), before);
    expect(
        await File('${fixture.directory.path}/assets/dialogue/pickup.wav')
            .exists(),
        isFalse);
  });

  test('conflicting sound identity is rejected before any disk change',
      () async {
    final fixture = await _Fixture.create(existing: true);
    addTearDown(fixture.dispose);
    final stored =
        await fixture.api.artifacts.put(_wav(), declaredMediaType: 'audio/wav');
    final before = await fixture.projectFile.readAsBytes();
    await expectLater(
        fixture.api.planMutation(fixture.opened.projectHandle,
            await fixture.request(stored.reference.handle)),
        throwsA(isA<NarrativeAuthoringException>().having((error) => error.code,
            'code', 'scene.dialogue.audio_media.conflict')));
    expect(await fixture.projectFile.readAsBytes(), before);
  });
}

List<int> _wav() {
  final bytes = Uint8List(44 + 8000);
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
  _Fixture(this.directory, this.handles, this.opened, this.loader, this.api);
  final Directory directory;
  final WorkspaceHandleStore handles;
  final OpenedProject opened;
  final ProjectSnapshotLoader loader;
  final LocalMapAuthoringMutationApi api;
  File get projectFile => File('${directory.path}/project.json');

  static Future<_Fixture> create({bool existing = false}) async {
    final directory =
        await Directory.systemTemp.createTemp('dialogue-sound-native-');
    final manifest = ProjectManifest(
        name: 'Original dialogue sound',
        maps: const [],
        tilesets: const [],
        cinematicMediaAssets: existing
            ? [
                CinematicMediaAsset(
                    id: 'pickup',
                    label: 'Existing',
                    kind: CinematicMediaAssetKind.sound,
                    relativePath: 'assets/existing.wav')
              ]
            : const []);
    await File('${directory.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    if (existing) {
      final file = File('${directory.path}/assets/existing.wav');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(_wav());
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
    return _Fixture(directory, handles, opened, loader, api);
  }

  Future<AuthoringRequest> request(String handle,
          {Object? mediaKind, bool explicitKind = false}) async =>
      AuthoringRequest(
          requestId: 'sound',
          actionId: _action,
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          expectedRevision: (await loader.load(opened.projectHandle)).revision,
          idempotencyKey: 'sound',
          parameters: {
            'artifactHandle': handle,
            'assetId': 'pickup_audio',
            'mediaId': 'pickup',
            'label': 'Original pickup sound',
            'logicalPath': 'assets/dialogue/pickup.wav',
            if (explicitKind || mediaKind != null) 'mediaKind': mediaKind
          });

  Future<void> dispose() async {
    await api.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    await directory.delete(recursive: true);
  }
}
