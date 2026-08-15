import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentationMedia.configure', () {
    test('authors rights, localized captions and fallbacks atomically',
        () async {
      final setup = await _ConfigurationSetup.create();
      addTearDown(setup.dispose);
      final request = await setup.request();

      final planned = await setup.mutations.planMutation(
        setup.projectHandle,
        request,
      );
      final applied = await setup.mutations.applyMutation(
        setup.projectHandle,
        planId: planned.plan.planId,
        operationId: 'operation-configure-opening-video',
      );

      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      final video = (await setup.catalog()).require('opening-video');
      expect(video.posterMediaId, 'opening-poster');
      expect(video.fallbackMediaId, 'opening-poster');
      expect(video.captions.single.locale, 'fr-FR');
      expect(video.provenance!.source, 'Avelune Studio original');
      expect(video.license!.identifier, 'LicenseRef-Avelune-Proprietary');
      expect(video.technicalMetadata!.codec, 'h264');
    });

    test('executes the same configuration through JSONL', () async {
      final setup = await _ConfigurationSetup.create();
      addTearDown(setup.dispose);
      final worker = JsonlWorker(api: setup.reads, mutations: setup.mutations);
      final request = await setup.request();

      final planned = await _jsonl(worker, 'plan', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'request': request.toJson(),
      });
      final applied = await _jsonl(worker, 'apply', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'planId': planned.data['planId'],
        'operationId': 'operation-jsonl-configure-opening-video',
      });
      final queried = await _jsonl(worker, 'query', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'request': AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const <String>['opening-video'],
        ).toJson(),
      });

      expect(
        (applied.data['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      final item = (queried.data['items']! as List).single as Map;
      expect((item['provenance']! as Map)['source'], 'Avelune Studio original');
      expect((item['captions']! as List).single, <String, Object?>{
        'locale': 'fr-FR',
        'mediaId': 'opening-captions-fr',
      });
    });

    test('rejects an invalid fallback without mutating the catalog', () async {
      final setup = await _ConfigurationSetup.create();
      addTearDown(setup.dispose);
      final before = await setup.catalogBytes();
      final request = await setup.request(
        fallbackMediaId: 'opening-captions-fr',
      );

      await expectLater(
        () => setup.mutations.planMutation(setup.projectHandle, request),
        throwsA(
          isA<PresentationMediaConfigurationException>().having(
            (error) => error.code,
            'code',
            'presentation_media.configuration_invalid',
          ),
        ),
      );

      expect(await setup.catalogBytes(), before);
    });

    test('reports malformed metadata with a stable authoring error', () async {
      final setup = await _ConfigurationSetup.create();
      addTearDown(setup.dispose);
      final before = await setup.catalogBytes();
      final request = await setup.request(fallbackMediaId: 'opening-video');

      await expectLater(
        () => setup.mutations.planMutation(setup.projectHandle, request),
        throwsA(
          isA<PresentationMediaConfigurationException>().having(
            (error) => error.code,
            'code',
            'presentation_media.request_invalid',
          ),
        ),
      );

      expect(await setup.catalogBytes(), before);
    });
  });
}

final class _ConfigurationSetup {
  const _ConfigurationSetup({
    required this.root,
    required this.reads,
    required this.mutations,
    required this.snapshots,
    required this.workspaceHandle,
    required this.projectHandle,
  });

  static Future<_ConfigurationSetup> create() async {
    final root = await Directory.systemTemp.createTemp(
      'presentation-media-configuration-',
    );
    final manifest = ProjectManifest(
      name: 'Presentation media configuration fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(manifest.toJson()),
      flush: true,
    );
    final catalog = ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        _caption('opening-captions-fr'),
        _poster('opening-poster'),
        ProjectMediaAsset(
          id: 'opening-video',
          label: 'Opening video',
          kind: ProjectMediaKind.video,
          sourceAssetId: 'asset.opening-video',
          technicalMetadata: ProjectMediaTechnicalMetadata(
            mediaType: 'video/mp4',
            container: 'mp4',
            codec: 'h264',
            sizeBytes: 100,
            width: 1920,
            height: 1080,
            durationMilliseconds: 1000,
          ),
        ),
      ],
    );
    final catalogFile = File(
      '${root.path}/$projectMediaCatalogStorageKey',
    );
    await catalogFile.parent.create(recursive: true);
    await catalogFile.writeAsBytes(encodeProjectMediaCatalogBytes(catalog));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final reads = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final opened = await reads.openProject(root.path);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      clock: () => DateTime.utc(2026, 8, 14, 20),
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _ConfigurationSetup(
      root: root,
      reads: reads,
      mutations: mutations,
      snapshots: snapshots,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
  }

  final Directory root;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;

  Future<AuthoringRequest> request({
    String fallbackMediaId = 'opening-poster',
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request-configure-opening-video',
      actionId: 'presentationMedia.configure',
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'configure-opening-video',
      parameters: <String, Object?>{
        'mediaId': 'opening-video',
        'posterMediaId': 'opening-poster',
        'fallbackMediaId': fallbackMediaId,
        'captions': <Object?>[
          <String, Object?>{
            'locale': 'fr-FR',
            'mediaId': 'opening-captions-fr',
          },
        ],
        'provenance': <String, Object?>{
          'source': 'Avelune Studio original',
          'creator': 'Yoahn',
        },
        'license': <String, Object?>{
          'identifier': 'LicenseRef-Avelune-Proprietary',
          'name': 'Avelune proprietary media license',
        },
      },
    );
  }

  Future<List<int>> catalogBytes() => File(
        '${root.path}/$projectMediaCatalogStorageKey',
      ).readAsBytes();

  Future<ProjectMediaCatalog> catalog() async =>
      decodeProjectMediaCatalogBytes(await catalogBytes());

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

ProjectMediaAsset _caption(String id) => ProjectMediaAsset(
      id: id,
      label: id,
      kind: ProjectMediaKind.captions,
      sourceAssetId: 'asset.$id',
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'text/vtt',
        container: 'webvtt',
        codec: 'webvtt',
        sizeBytes: 20,
      ),
    );

ProjectMediaAsset _poster(String id) => ProjectMediaAsset(
      id: id,
      label: id,
      kind: ProjectMediaKind.poster,
      sourceAssetId: 'asset.$id',
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'image/png',
        container: 'png',
        codec: 'png',
        sizeBytes: 20,
        width: 1920,
        height: 1080,
      ),
    );

Future<AuthoringResult> _jsonl(
  JsonlWorker worker,
  String command,
  Map<String, Object?> args,
) async =>
    AuthoringResult.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          await worker.processLine(
            jsonEncode(<String, Object?>{
              'id': 'request-$command',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map,
      ),
    );
