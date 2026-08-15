import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentationMedia.import', () {
    test('imports probed bytes once and replays without duplicates', () async {
      final setup = await _ImportSetup.create();
      addTearDown(setup.dispose);
      final request = await setup.request();

      final planned = await setup.mutations.planMutation(
        setup.projectHandle,
        request,
      );
      expect(planned.plan.preview['technicalMetadata'], {
        'mediaType': 'image/png',
        'container': 'png',
        'codec': 'png',
        'sizeBytes': 24,
        'width': 640,
        'height': 360,
      });
      final applied = await setup.mutations.applyMutation(
        setup.projectHandle,
        planId: planned.plan.planId,
        operationId: 'operation-opening-image',
      );
      final replayed = await setup.mutations.applyMutation(
        setup.projectHandle,
        planId: planned.plan.planId,
        operationId: 'operation-opening-image',
      );

      expect(replayed.toJson(), applied.toJson());
      final assets = await setup.assetCatalog();
      final media = await setup.mediaCatalog();
      expect(assets.records, hasLength(1));
      expect(media.entries, hasLength(1));
      expect(media.entries.single.sourceAssetId, 'asset.opening.image');
      expect(media.entries.single.technicalMetadata!.width, 640);
      expect(await setup.blobFiles(), hasLength(1));
      expect(setup.artifacts.list(), isEmpty);
    });

    test('executes the same semantic import through JSONL', () async {
      final setup = await _ImportSetup.create(localArtifactStore: true);
      addTearDown(setup.dispose);
      final source = File('${setup.root.path}/opening.png');
      await source.writeAsBytes(_png(width: 1080, height: 1920));
      final worker = JsonlWorker(api: setup.reads, mutations: setup.mutations);
      final staged = await _jsonl(worker, 'stage_artifact', <String, Object?>{
        'sourcePath': source.path,
        'declaredMediaType': 'image/png',
      });
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = setup.importRequest(
        expectedRevision: snapshot.revision,
        artifactHandle: staged.data['artifactHandle']! as String,
      );

      final planned = await _jsonl(worker, 'plan', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'request': request.toJson(),
      });
      final applied = await _jsonl(worker, 'apply', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'planId': planned.data['planId'],
        'operationId': 'operation-jsonl-opening-image',
      });
      final queried = await _jsonl(worker, 'query', <String, Object?>{
        'projectHandle': setup.projectHandle.value,
        'request': AuthoringQueryRequest(
          resourceKind: 'presentationMedia',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ).toJson(),
      });

      expect(
        (applied.data['receipt']! as Map<String, Object?>)['status'],
        'applied',
      );
      final item = (queried.data['items']! as List).single as Map;
      expect((item['technicalMetadata']! as Map)['width'], 1080);
      expect((item['technicalMetadata']! as Map)['height'], 1920);
      expect(setup.artifacts.list(), isEmpty);
    });

    test('dry-run leaves no project mutation or staged artifact', () async {
      final setup = await _ImportSetup.create();
      addTearDown(setup.dispose);
      final request = await setup.request(dryRun: true);

      final planned = await setup.mutations.planMutation(
        setup.projectHandle,
        request,
      );

      expect(planned.plan.applicable, isFalse);
      expect(
        await File('${setup.root.path}/$assetCatalogStorageKey').exists(),
        isFalse,
      );
      expect(
        await File('${setup.root.path}/$projectMediaCatalogStorageKey')
            .exists(),
        isFalse,
      );
      expect(await setup.blobFiles(), isEmpty);
      expect(setup.artifacts.list(), isEmpty);
    });

    for (final checkpoint in PresentationMediaImportCheckpoint.values) {
      test('$checkpoint leaves project state untouched and clears staging',
          () async {
        final setup = await _ImportSetup.create(
          importFaultInjector: (current) {
            if (current == checkpoint) throw StateError('injected');
          },
        );
        addTearDown(setup.dispose);

        await expectLater(
          () async => setup.mutations.planMutation(
            setup.projectHandle,
            await setup.request(),
          ),
          throwsStateError,
        );

        expect(
          await File(
            '${setup.root.path}/$assetCatalogStorageKey',
          ).exists(),
          isFalse,
        );
        expect(
          await File(
            '${setup.root.path}/$projectMediaCatalogStorageKey',
          ).exists(),
          isFalse,
        );
        expect(await setup.blobFiles(), isEmpty);
        expect(setup.artifacts.list(), isEmpty);
      });
    }

    test('recovers a crash after the first promoted resource exactly once',
        () async {
      var crashed = false;
      final setup = await _ImportSetup.create(
        transactionFaultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 0) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final planned = await setup.mutations.planMutation(
        setup.projectHandle,
        await setup.request(),
      );

      await expectLater(
        () => setup.mutations.applyMutation(
          setup.projectHandle,
          planId: planned.plan.planId,
          operationId: 'operation-crash-opening-image',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );
      final recovered = await setup.mutations.recoverMutation(
        setup.projectHandle,
        operationId: 'operation-crash-opening-image',
      );
      final replayed = await setup.mutations.recoverMutation(
        setup.projectHandle,
        operationId: 'operation-crash-opening-image',
      );

      expect(recovered.receipt.status, AuthoringReceiptStatus.recovered);
      expect(replayed.toJson(), recovered.toJson());
      expect((await setup.assetCatalog()).records, hasLength(1));
      expect((await setup.mediaCatalog()).entries, hasLength(1));
      expect(await setup.blobFiles(), hasLength(1));
      expect(setup.artifacts.list(), isEmpty);
    });
  });
}

final class _ImportSetup {
  const _ImportSetup({
    required this.root,
    required this.reads,
    required this.mutations,
    required this.snapshots,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.artifacts,
    required this.artifactHandle,
  });

  static Future<_ImportSetup> create({
    bool localArtifactStore = false,
    PresentationMediaImportFaultInjector? importFaultInjector,
    AuthoringTransactionFaultInjector? transactionFaultInjector,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'presentation-media-import-',
    );
    final manifest = ProjectManifest(
      name: 'Presentation media import fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      flush: true,
    );
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
    final ArtifactStore artifacts = localArtifactStore
        ? LocalArtifactStore(
            allowedSourceRoots: <String>[root.path],
            maximumArtifactBytes: 1024 * 1024,
          )
        : MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024);
    String artifactHandle = '';
    if (!localArtifactStore) {
      artifactHandle = (await artifacts.put(
        _png(width: 640, height: 360),
        declaredMediaType: 'image/png',
      ))
          .reference
          .handle;
    }
    final dispatcher = MapMutationDispatcher.canonical(
      artifactStore: artifacts,
      presentationMediaFaultInjector: importFaultInjector,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      dispatcher: dispatcher,
      faultInjector: transactionFaultInjector,
      clock: () => DateTime.utc(2026, 8, 14, 18),
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _ImportSetup(
      root: root,
      reads: reads,
      mutations: mutations,
      snapshots: snapshots,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      artifacts: artifacts,
      artifactHandle: artifactHandle,
    );
  }

  final Directory root;
  final AuthoringReadApi reads;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ArtifactStore artifacts;
  final String artifactHandle;

  Future<AuthoringRequest> request({bool dryRun = false}) async {
    final snapshot = await snapshots.load(projectHandle);
    return importRequest(
      expectedRevision: snapshot.revision,
      artifactHandle: artifactHandle,
      dryRun: dryRun,
    );
  }

  AuthoringRequest importRequest({
    required String expectedRevision,
    required String artifactHandle,
    bool dryRun = false,
  }) =>
      AuthoringRequest(
        requestId: 'request-opening-image',
        actionId: 'presentationMedia.import',
        actionVersion: 1,
        workspaceHandle: workspaceHandle.value,
        expectedRevision: expectedRevision,
        dryRun: dryRun,
        idempotencyKey: 'opening-image-import',
        parameters: <String, Object?>{
          'artifactHandle': artifactHandle,
          'mediaId': 'opening-image',
          'label': 'Opening image',
          'kind': 'image',
          'assetId': 'asset.opening.image',
          'logicalPath': 'assets/presentation/opening.png',
        },
      );

  Future<AssetCatalog> assetCatalog() async {
    final bytes = await File(
      '${root.path}/$assetCatalogStorageKey',
    ).readAsBytes();
    return AssetCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
    );
  }

  Future<ProjectMediaCatalog> mediaCatalog() async =>
      decodeProjectMediaCatalogBytes(
        await File(
          '${root.path}/$projectMediaCatalogStorageKey',
        ).readAsBytes(),
      );

  Future<List<FileSystemEntity>> blobFiles() async {
    final directory = Directory('${root.path}/assets/.pokemap-store');
    if (!await directory.exists()) return const <FileSystemEntity>[];
    return directory
        .list()
        .where((entry) => entry is File && entry.path.endsWith('.blob'))
        .toList();
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

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

Uint8List _png({required int width, required int height}) {
  final bytes = Uint8List(24)
    ..setRange(0, 8, const <int>[137, 80, 78, 71, 13, 10, 26, 10])
    ..setRange(12, 16, 'IHDR'.codeUnits);
  ByteData.sublistView(bytes)
    ..setUint32(16, width)
    ..setUint32(20, height);
  return bytes;
}
