import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final jsonl in [false, true]) {
    test('media rename and delete are reversible and source-safe, jsonl=$jsonl',
        () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      final before = await h.mediaFile.readAsBytes();
      final expected = (await h.catalog()).require('image').toJson();
      await h.mutate(
          'presentationMedia.rename',
          {
            'mediaId': 'image',
            'label': 'Introduction — portrait de Chen',
            'expectedMedia': expected
          },
          jsonl: jsonl);
      final renamed = (await h.catalog()).require('image');
      expect(renamed.label, 'Introduction — portrait de Chen');
      expect(renamed.toJson()..remove('label'), expected..remove('label'));
      final renamedBytes = await h.mediaFile.readAsBytes();
      final receipt = await h.mutate('presentationMedia.delete',
          {'mediaId': 'image', 'expectedMedia': renamed.toJson()},
          jsonl: jsonl);
      expect((await h.catalog()).entries, isEmpty);
      expect(await h.blob.exists(), isTrue);
      expect((await h.assets()).find('source'), isNotNull);
      await h.mutations.undo(h.project,
          entryId: receipt['receiptId'] as String,
          idempotencyKey: 'undo-delete');
      expect(await h.mediaFile.readAsBytes(), renamedBytes);
      expect(before, isNot(renamedBytes));
    });
  }
  for (final consumer in ['cinematic', 'poster', 'fallback', 'captions', 'projectAudio']) {
    test('delete blocks $consumer media references', () async {
      final h = await _Harness.create(consumer: consumer);
      addTearDown(h.dispose);
      final before = await h.mediaFile.readAsBytes();
      await expectLater(
          h.plan('presentationMedia.delete', {
            'mediaId': 'image',
            'expectedMedia': (await h.catalog()).require('image').toJson()
          }),
          throwsA(isA<PresentationMediaConfigurationException>().having(
              (e) => e.code,
              'code',
              'presentation_media.references_blocking')));
      expect(await h.mediaFile.readAsBytes(), before);
    });
  }
  test('delete and rename reject stale baselines', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    for (final action in [
      'presentationMedia.delete',
      'presentationMedia.rename'
    ]) {
      await expectLater(
          h.plan(action, {
            'mediaId': 'image',
            'expectedMedia': {
              ...(await h.catalog()).require('image').toJson(),
              'label': 'Changed'
            },
            if (action.endsWith('rename')) 'label': 'New'
          }),
          throwsA(isA<PresentationMediaConfigurationException>().having(
              (e) => e.code, 'code', 'presentation_media.baseline_changed')));
    }
  });
  test('asset deletion protects media entries and startup profile paths',
      () async {
    final h = await _Harness.create(profile: true);
    addTearDown(h.dispose);
    await expectLater(
        h.plan('asset.delete', {'assetId': 'source'}),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.references_blocking')));
    await h.mutate('presentationMedia.delete', {
      'mediaId': 'image',
      'expectedMedia': (await h.catalog()).require('image').toJson()
    });
    await expectLater(
        h.plan('asset.delete', {'assetId': 'source'}),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.references_blocking')));
    expect(await h.blob.exists(), isTrue);
  });
  test('asset deletion and undo preserve blob-only source layout', () async {
    final h = await _Harness.create(logicalCopy: false);
    addTearDown(h.dispose);
    await h.mutate('presentationMedia.delete', {
      'mediaId': 'image',
      'expectedMedia': (await h.catalog()).require('image').toJson()
    });
    final receipt = await h.mutate('asset.delete', {'assetId': 'source'});
    expect(await h.blob.exists(), isFalse);
    expect(
        await File('${h.root.path}/presentation/image.png').exists(), isFalse);
    await h.mutations.undo(h.project,
        entryId: receipt['receiptId'] as String,
        idempotencyKey: 'restore-blob-only');
    expect(await h.blob.readAsBytes(), [1, 2, 3]);
    expect(
        await File('${h.root.path}/presentation/image.png').exists(), isFalse);
  });
  test('asset deletion retains source until its media record is removed',
      () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    await expectLater(
        h.plan('asset.delete', {'assetId': 'source'}),
        throwsA(isA<AssetActionException>()
            .having((e) => e.code, 'code', 'asset.references_blocking')));
    await h.mutate('presentationMedia.delete', {
      'mediaId': 'image',
      'expectedMedia': (await h.catalog()).require('image').toJson()
    });
    final receipt = await h.mutate('asset.delete', {'assetId': 'source'});
    expect(await h.blob.exists(), isFalse);
    await h.mutations.undo(h.project,
        entryId: receipt['receiptId'] as String,
        idempotencyKey: 'restore-source');
    expect(await h.blob.readAsBytes(), [1, 2, 3]);
  });
}

final class _Harness {
  _Harness(this.root, this.reads, this.mutations, this.snapshots, this.project,
      this.workspace, this.worker, this.blob);
  final Directory root;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final JsonlWorker worker;
  final File blob;
  int sequence = 0;
  File get mediaFile => File('${root.path}/$projectMediaCatalogStorageKey');
  Future<ProjectMediaCatalog> catalog() async =>
      decodeProjectMediaCatalogBytes(await mediaFile.readAsBytes());
  Future<AssetCatalog> assets() async => AssetCatalog.fromJson(jsonDecode(
          await File('${root.path}/$assetCatalogStorageKey').readAsString())
      as Map<String, dynamic>);
  static Future<_Harness> create(
      {String? consumer, bool profile = false, bool logicalCopy = true}) async {
    final temp = await Directory.systemTemp.createTemp('media-management-');
    final root = Directory(await temp.resolveSymbolicLinks());
    final image = ProjectMediaAsset(
        id: 'image',
        label: 'image.png',
        kind: consumer == 'projectAudio' ? ProjectMediaKind.audio : ProjectMediaKind.image,
        sourceAssetId: 'source',
        technicalMetadata: ProjectMediaTechnicalMetadata(
            mediaType: consumer == 'projectAudio' ? 'audio/wav' : 'image/png',
            container: consumer == 'projectAudio' ? 'wav' : 'png',
            codec: consumer == 'projectAudio' ? 'pcm' : 'png',
            sizeBytes: 3,
            width: consumer == 'projectAudio' ? null : 1,
            height: consumer == 'projectAudio' ? null : 1));
    final manifest = ProjectManifest(
        name: 'Media management',
        version: ProjectVersion.v9,
        settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
            audio: consumer == 'projectAudio' ? ProjectAudioSettings(cues: {
              ProjectSoundCue.uiConfirm: const ProjectSoundBinding(source: ProjectSoundSource.custom, mediaId: 'image'),
            }) : null),
        maps: const [],
        tilesets: const [],
        presentation: profile
            ? const ProjectPresentationProfile(
                branding:
                    ProjectBrandingProfile(iconPath: 'presentation/image.png'))
            : null,
        presentationCinematics: consumer == 'cinematic'
            ? [
                PresentationCinematicAsset(
                    id: 'opening',
                    title: 'Opening',
                    durationUs: 1000000,
                    layers: [
                      PresentationLayer(
                          id: 'visual', label: 'Visual', zIndex: 0)
                    ],
                    tracks: [
                      PresentationTrack(
                          id: 'visuals',
                          label: 'Visuals',
                          kind: PresentationTrackKind.visual,
                          clips: [
                            PresentationVisualClip(
                                id: 'image',
                                startUs: 0,
                                durationUs: 1000000,
                                layerId: 'visual',
                                resourceId: 'image')
                          ])
                    ])
              ]
            : const []);
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final catalog = ProjectMediaCatalog(entries: [
      image,
      if (consumer != null && consumer != 'cinematic' && consumer != 'projectAudio')
        ProjectMediaAsset(
            id: 'consumer',
            label: 'Consumer',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'source',
            posterMediaId: consumer == 'poster' ? 'image' : null,
            fallbackMediaId: consumer == 'fallback' ? 'image' : null,
            captionMediaIds: consumer == 'captions' ? ['image'] : const [])
    ]);
    final mediaFile = File('${root.path}/$projectMediaCatalogStorageKey');
    await mediaFile.parent.create(recursive: true);
    await mediaFile.writeAsBytes(encodeProjectMediaCatalogBytes(catalog));
    final artifact =
        ContentArtifactRef.fromBytes([1, 2, 3], mediaType: consumer == 'projectAudio' ? 'audio/wav' : 'image/png');
    await File('${root.path}/$assetCatalogStorageKey')
        .writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: 'source',
          logicalPath: 'presentation/image.png',
          artifact: artifact)
    ]).toJson()));
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes([1, 2, 3]);
    final logical = File('${root.path}/presentation/image.png');
    await logical.parent.create(recursive: true);
    if (logicalCopy) await logical.writeAsBytes([1, 2, 3]);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
        openService: ProjectOpenService(
            policy: policy, fileReader: reader, handles: handles),
        snapshotLoader: snapshots);
    final opened = await reads.openProject(root.path);
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: snapshots);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle);
    return _Harness(
        root,
        reads,
        mutations,
        snapshots,
        opened.projectHandle,
        opened.workspaceHandle,
        JsonlWorker(api: reads, mutations: mutations),
        blob);
  }

  Future<AuthoringRequest> request(
          String action, Map<String, Object?> parameters) async =>
      AuthoringRequest(
          requestId: 'request-${++sequence}',
          actionId: action,
          actionVersion: 1,
          workspaceHandle: workspace.value,
          expectedRevision: (await snapshots.load(project)).revision,
          idempotencyKey: 'key-$sequence',
          parameters: parameters);
  Future<Map<String, Object?>> plan(
          String action, Map<String, Object?> parameters) async =>
      mutations.plan(project, await request(action, parameters));
  Future<Map<String, Object?>> jsonl(
      String command, Map<String, Object?> args) async {
    final result = AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode({
      'id': '$command-$sequence',
      'command': command,
      'args': args
    }))) as Map<String, dynamic>);
    expect(result.status, AuthoringResultStatus.success,
        reason: result.error?.toJson().toString());
    return result.data;
  }

  Future<Map<String, Object?>> mutate(
      String action, Map<String, Object?> parameters,
      {bool jsonl = false}) async {
    final before = await mediaFile.readAsBytes();
    final r = await request(action, parameters);
    final plan = jsonl
        ? await this.jsonl(
            'plan', {'projectHandle': project.value, 'request': r.toJson()})
        : await mutations.plan(project, r);
    expect(await mediaFile.readAsBytes(), before);
    final confirmation = action.endsWith('delete')
        ? (jsonl
            ? await this.jsonl('confirm',
                {'projectHandle': project.value, 'planId': plan['planId']})
            : await mutations.confirm(project,
                planId: plan['planId'] as String))
        : null;
    final result = jsonl
        ? await this.jsonl('apply', {
            'projectHandle': project.value,
            'planId': plan['planId'],
            'operationId': 'apply-$sequence',
            if (confirmation != null)
              'confirmationToken': confirmation['confirmationToken']
          })
        : await mutations.apply(project,
            planId: plan['planId'] as String,
            operationId: 'apply-$sequence',
            confirmationToken: confirmation?['confirmationToken'] as String?);
    return Map<String, Object?>.from(result['receipt'] as Map);
  }

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspace);
    await reads.close(workspace);
    await root.delete(recursive: true);
  }
}
