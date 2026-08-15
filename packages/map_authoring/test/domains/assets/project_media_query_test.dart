import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentationMedia query', () {
    test('paginates canonical media independently of physical paths', () {
      final snapshot = _snapshot();
      final request = AuthoringQueryRequest(
        resourceKind: 'presentationMedia',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
        pageSize: 2,
      );

      final first = const ProjectQueryService().query(snapshot, request);
      final second = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 2,
          cursor: first.nextCursor,
        ),
      );

      expect(first.totalAvailable, 3);
      expect(
        [...first.items, ...second.items].map((item) => item['id']),
        ['opening-captions', 'opening-poster', 'opening-video'],
      );
      expect(first.nextCursor, isNotNull);
      expect(second.nextCursor, isNull);
      expect(
        [...first.items, ...second.items],
        everyElement(
          isNot(
            contains(anyOf('relativePath', 'logicalPath', 'artifactHandle')),
          ),
        ),
      );
    });

    test('gets and searches explicit extensible media kinds', () {
      final snapshot = _snapshot();

      final video = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const ['opening-video'],
        ),
      );
      final captions = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.search,
          view: AuthoringQueryView.summary,
          searchTerm: 'captions',
        ),
      );

      expect(video.items.single, {
        'id': 'opening-video',
        'label': 'Opening video',
        'kind': 'video',
        'sourceAssetId': 'asset.opening.video',
        'posterMediaId': 'opening-poster',
        'captionMediaIds': ['opening-captions'],
        'fallbackMediaId': 'opening-poster',
        'name': 'Opening video',
        'resourceKind': 'presentationMedia',
      });
      expect(captions.items.single['id'], 'opening-captions');
      expect(captions.items.single['kind'], 'captions');
    });

    test('returns the same records through direct API and JSONL', () async {
      final project = await Directory.systemTemp.createTemp(
        'pokemap_project_media_',
      );
      addTearDown(() => project.delete(recursive: true));
      final snapshot = _snapshot();
      await File('${project.path}/project.json').writeAsBytes(
        snapshot.findResourceBytes('project')!,
      );
      final catalogFile = File(
        '${project.path}/$projectMediaCatalogStorageKey',
      );
      await catalogFile.parent.create(recursive: true);
      await catalogFile.writeAsBytes(
        snapshot.findResourceBytes(projectMediaCatalogResourceIdentity)!,
      );
      const reader = LocalProjectFileReader();
      final handles = WorkspaceHandleStore(
        clock: () => DateTime.utc(2026, 8, 14),
        tokenFactory: (prefix) => '${prefix}project-media',
      );
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [project.parent.path],
        fileReader: reader,
      );
      final api = AuthoringReadApi(
        openService: ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
        ),
        snapshotLoader: ProjectSnapshotLoader(handles: handles),
      );
      final worker = JsonlWorker(api: api);
      final opened = await api.open(project.path);
      final handle = ProjectHandle(opened['projectHandle']! as String);
      final request = AuthoringQueryRequest(
        resourceKind: 'presentationMedia',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
        pageSize: 2,
      );

      final direct = await api.query(handle, request);
      final transported = AuthoringResult.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            await worker.processLine(
              jsonEncode({
                'id': 'project-media-query',
                'command': 'query',
                'args': {
                  'projectHandle': handle.value,
                  'request': request.toJson(),
                },
              }),
            ),
          ) as Map,
        ),
      );

      expect(transported.status, AuthoringResultStatus.success);
      expect(transported.data, direct);
      expect(transported.data['nextCursor'], isNotNull);
    });
  });
}

ProjectSnapshot _snapshot() {
  final manifest = ProjectManifest(
    name: 'Project media fixture',
    maps: const [],
    tilesets: const [],
  );
  final catalog = ProjectMediaCatalog(
    entries: [
      ProjectMediaAsset(
        id: 'opening-video',
        label: 'Opening video',
        kind: ProjectMediaKind.video,
        sourceAssetId: 'asset.opening.video',
        posterMediaId: 'opening-poster',
        captionMediaIds: const ['opening-captions'],
        fallbackMediaId: 'opening-poster',
      ),
      ProjectMediaAsset(
        id: 'opening-poster',
        label: 'Opening poster',
        kind: ProjectMediaKind.poster,
        sourceAssetId: 'asset.opening.poster',
      ),
      ProjectMediaAsset(
        id: 'opening-captions',
        label: 'Opening captions',
        kind: ProjectMediaKind.captions,
        sourceAssetId: 'asset.opening.captions',
      ),
    ],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final catalogBytes = utf8.encode(jsonEncode(catalog.toJson()));
  final manifestFingerprint = _fingerprint('project.json', manifestBytes);
  final catalogFingerprint = _fingerprint(
    projectMediaCatalogStorageKey,
    catalogBytes,
  );
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
    NarrativeProjectFingerprintEntry(
      relativePath: projectMediaCatalogStorageKey,
      bytes: catalogBytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_project_media'),
    revision: revision,
    manifest: manifest,
    maps: const [],
    resourceFingerprints: {
      'project': manifestFingerprint,
      projectMediaCatalogResourceIdentity: catalogFingerprint,
    },
    resourceBytes: {
      'project': manifestBytes,
      projectMediaCatalogResourceIdentity: catalogBytes,
    },
    resourceStorageKeys: {
      'project': 'project.json',
      projectMediaCatalogResourceIdentity: projectMediaCatalogStorageKey,
    },
  );
}

String _fingerprint(String path, List<int> bytes) {
  return computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(relativePath: path, bytes: bytes),
  ]);
}
