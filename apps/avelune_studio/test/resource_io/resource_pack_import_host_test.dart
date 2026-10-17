import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_pack_adapter.dart';
import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_api.dart';
import 'package:map_authoring/map_authoring_local.dart'
    show
        LocalProjectFileReader,
        WorkspacePolicy,
        WorkspaceHandleStore,
        ProjectOpenService,
        ProjectSnapshotLoader,
        ProjectSnapshotLoadPolicy;
import 'package:map_authoring/map_authoring.dart'
    show NativeResourcePackRef, AuthoringTransactionFaultInjector;

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import '../../../../packages/map_authoring/test/domains/assets/resource_pack_export_test.dart'
    show nativeImage;
import '../support/map_workspace_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('valid 3D project imports the global eight resources and thirteen supports then reopens after session close', () async {
    final camera = SpatialCameraProfile();
    final map = MapData(
      id: 'spatial-room',
      name: 'Spatial room',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 6),
      layers: const [],
      spatialScene: MapSpatialScene(width: 8, depth: 6, camera: camera),
    );
    final target = ProjectManifest(
      name: 'Spatial pack target',
      version: ProjectVersion.v9,
      tilesets: [],
      maps: [
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'spatial-room.json',
        ),
      ],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: camera,
        tileWidth: 2,
        tileHeight: 2,
      ),
    );
    ProjectValidator.validate(target, maps: [map]);
    MapValidator.validate(map, projectDialogueContext: target);
    final source = await ResourcePackImportFixture.create(target: target);
    final host = await ResourcePackTestHost.create(
      sourceFixture: source,
      initialMap: map,
    );
    addTearDown(host.dispose);
    final mapFile = File('${host.root.path}/spatial-room.json');
    final mapBefore = await mapFile.readAsBytes();
    await host.prepare();
    expect(host.transfer.error, isNull);
    expect(host.transfer.preparedSummary['resourceCount'], 8);
    expect(host.transfer.preparedSummary['supportCount'], 13);
    expect(host.transfer.canApply, isTrue);
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    expect(host.transfer.requiresReconciliation, isFalse);
    expect(host.navigation.pendingReceipt, isNull);
    final installed = host.workspace.project!;
    expect(installed.tilesets, hasLength(1));
    expect(installed.elements, hasLength(2));
    expect(installed.models3d, hasLength(1));
    expect(installed.characters, hasLength(1));
    expect(installed.smartTileCatalog.presets, hasLength(1));
    expect(installed.borderCatalog.records, hasLength(1));
    expect(installed.environmentPresets, hasLength(1));
    expect(
      installed.resourcePackInstallations.entries.single.resources,
      hasLength(8),
    );
    expect(
      installed.resourcePackInstallations.entries.single.supports,
      hasLength(13),
    );
    final projectAfterImport = await host.manifestFile.readAsBytes();
    expect(await host.transfer.requestClose(), isTrue);
    await host.closeSession();
    final reopenedAdapter = LocalMapWorkspaceAdapter();
    final reopened = await reopenedAdapter.loadProject(host.session);
    final reopenedMap = (await reopenedAdapter.loadMap(
      host.session,
      reopened.maps.single,
    )).map;
    ProjectValidator.validate(reopened, maps: [reopenedMap]);
    MapValidator.validate(reopenedMap, projectDialogueContext: reopened);
    expect(reopened, installed);
    expect(reopened.settings.dimension, ProjectDimension.threeD);
    expect(reopened.settings.spatialCamera, camera);
    expect(reopenedMap.spatialScene!.camera, camera);
    expect(reopenedMap, map);
    expect(await mapFile.readAsBytes(), mapBefore);
    expect(await host.manifestFile.readAsBytes(), projectAfterImport);
  });
  test('additional roots in an existing installation reveal a newly added native resource', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.transfer.beginImport();
    await host.transfer.setFilter(kind: 'element');
    await host.transfer.selectFiltered();
    await host.transfer.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    expect(host.transfer.addedCount, greaterThan(0));
    expect(host.transfer.firstImported, isNotNull);
    final selected = host.transfer.firstImported!;
    expect(selected.kind, isNot('element'));
  });
  test('1282 distinct native aliases reconcile a real compact paginated receipt', () async {
    const count = 1282;
    final source = await ResourcePackImportFixture.create(
      sourceManifest: ProjectManifest(
        name: 'Bulk aliases',
        maps: [],
        settings: ProjectSettings(tileWidth: 2, tileHeight: 2),
        tilesets: [
          for (var i = 0; i < count; i++)
            ProjectTilesetEntry(
              id: 'atlas-$i',
              name: 'Atlas $i',
              relativePath: 'assets/image-$i.png',
              source: ProjectTilesetSource.regularAtlas(
                assetId: 'image-$i',
                pixelWidth: 2,
                pixelHeight: 2,
                tileWidth: 2,
                tileHeight: 2,
              ),
            ),
        ],
      ),
      sourceFiles: [
        for (var i = 0; i < count; i++)
          nativeImage(id: 'image-$i', path: 'assets/image-$i.png'),
      ],
      roots: [
        for (var i = 0; i < count; i++)
          NativeResourcePackRef(kind: ResourcePackKind.tileset, id: 'atlas-$i'),
      ],
    );
    late RecordingPackPort recording;
    final host = await ResourcePackTestHost.create(
      sourceFixture: source,
      wrapPack: (port) => recording = RecordingPackPort(port),
    );
    addTearDown(host.dispose);
    final beforeState = await host.resourceState();
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    final actual = recording.projection!['receipt']! as Map;
    expect(
      (actual['diff']! as Map)['diffRef'],
      isA<String>(),
      reason:
          'receiptBytes=${utf8.encode(jsonEncode(actual)).length}, diffEntries=${(actual['diff']! as Map)['entries'] is List ? ((actual['diff']! as Map)['entries']! as List).length : 'paged'}',
    );
    expect(actual['affectedResources'], isA<Map>());
    expect(recording.receipt!.changedPaths.length, greaterThan(count));
    final afterState = await host.resourceState();
    final expected = <String, String?>{};
    for (final identity in {
      ...beforeState.fingerprints.keys,
      ...afterState.fingerprints.keys,
    }) {
      if (beforeState.fingerprints[identity] !=
          afterState.fingerprints[identity]) {
        expected[afterState.paths[identity] ?? beforeState.paths[identity]!] =
            afterState.fingerprints[identity];
      }
    }
    expect(recording.receipt!.changedPaths.toSet(), expected.keys.toSet());
    expect(recording.receipt!.pathRevisions, expected);
    expect(
      recording.receipt!.pathRevisions.length,
      recording.receipt!.changedPaths.length,
    );
    expect((await host.reopen()).tilesets, hasLength(count));
    final sentinelPath = recording.receipt!.changedPaths.lastWhere(
      (path) => path.endsWith('.png') && !path.contains('/blobs/'),
    );
    expect(
      recording.receipt!.changedPaths.indexOf(sentinelPath),
      greaterThan(recording.receipt!.changedPaths.length - 100),
    );
    final sentinel = File('${host.root.path}/$sentinelPath');
    final original = await sentinel.readAsBytes();
    try {
      final altered = [...original];
      altered[altered.length - 1] ^= 1;
      await sentinel.writeAsBytes(altered);
      await expectLater(
        host.pack.reconcile(recording.receipt!),
        throwsA(anything),
      );
    } finally {
      await sentinel.writeAsBytes(original);
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
  test('real archive installs seven native kinds and supports, reopens and reimports without apply', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    await host.prepare();
    expect(host.transfer.canApply, isTrue);
    await host.transfer.apply();
    expect(host.transfer.error, isNull);
    final receipt = host.navigation.workspace.project!;
    expect(receipt.tilesets, isNotEmpty);
    expect(receipt.elements, isNotEmpty);
    expect(receipt.models3d, isNotEmpty);
    expect(receipt.characters, isNotEmpty);
    expect(receipt.smartTileCatalog.presets, isNotEmpty);
    expect(receipt.smartTileCatalog.atlases, isNotEmpty);
    expect(receipt.smartTileCatalog.materials, isNotEmpty);
    expect(receipt.borderCatalog.records, isNotEmpty);
    expect(receipt.environmentPresets, isNotEmpty);
    final reopened = await host.reopen();
    expect(reopened, receipt);
    await host.navigation.mutate('resource.classify', {
      'resourceKind': 'element',
      'resourceId': receipt.elements.first.id,
      'placementContext': 'interior',
    });
    final before = await host.manifestFile.readAsBytes();
    await host.prepare();
    expect(host.transfer.canApply, isFalse);
    expect(host.transfer.notice, contains('déjà installées'));
    expect(await host.manifestFile.readAsBytes(), before);
    expect(
      (await host.reopen()).resourceLibraryCatalog
          .entryFor('element', receipt.elements.first.id)
          ?.placementContext,
      ResourcePlacementContext.interior,
    );
  });

  test('commit refresh failure retains actual receipt and navigation retry never applies twice', () async {
    var fail = true;
    final host = await ResourcePackTestHost.create(
      beforeReconciliation: () async {
        if (fail) throw StateError('refresh unavailable');
      },
    );
    addTearDown(host.dispose);
    await host.prepare();
    await host.transfer.apply();
    expect(host.transfer.requiresReconciliation, isTrue);
    expect(host.navigation.pendingReceipt, isNotNull);
    expect(await host.transfer.requestClose(), isFalse);
    final receipt = host.navigation.pendingReceipt!;
    expect(receipt.operationId, startsWith('studio_pack_'));
    expect(receipt.snapshotBeforeRevision, isNot(receipt.beforeRevision));
    expect(receipt.pathRevisions, isNotEmpty);
    final bytes = await host.manifestFile.readAsBytes();
    fail = false;
    expect(await host.navigation.retryReconciliation(), isTrue);
    expect(host.navigation.pendingReceipt, isNull);
    expect(host.transfer.requiresReconciliation, isFalse);
    expect(await host.transfer.requestClose(), isTrue);
    expect(await host.manifestFile.readAsBytes(), bytes);
  });

  test('invalid archive preserves the target', () async {
    final host = await ResourcePackTestHost.create();
    addTearDown(host.dispose);
    final before = await host.manifestFile.readAsBytes();
    await host.archiveFile.writeAsString('not an archive');
    await host.transfer.beginImport();
    expect(host.transfer.error, isNotNull);
    expect(await host.manifestFile.readAsBytes(), before);
  });
  test(
    'stale preparation refuses apply and preserves the newer target',
    () async {
      final host = await ResourcePackTestHost.create();
      addTearDown(host.dispose);
      await host.prepare();
      final changed = (await host.reopen()).copyWith(
        name: 'Changed after preparation',
      );
      await host.manifestFile.writeAsString(jsonEncode(changed.toJson()));
      final bytes = await host.manifestFile.readAsBytes();
      await host.transfer.apply();
      expect(host.transfer.error, isNotNull);
      expect(host.transfer.requiresRecovery, isFalse);
      expect(await host.manifestFile.readAsBytes(), bytes);
      expect((await host.reopen()).elements, isEmpty);
    },
  );
}

class ResourcePackTestHost {
  ResourcePackTestHost(
    this.source,
    this.root,
    this.session,
    this.maps,
    this.resources,
    this.pack,
    this.workspace,
    this.navigation,
    this.archiveFile,
  );
  final ResourcePackImportFixture source;
  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final LocalResourceAdapter resources;
  final LocalResourcePackAdapter pack;
  final MapWorkspaceController workspace;
  final ResourceNavigation navigation;
  final File archiveFile;
  File get manifestFile => File('${root.path}/project.json');
  ResourcePackTransferController get transfer => navigation.packTransfer!;
  static Future<ResourcePackTestHost> create({
    Future<void> Function()? beforeReconciliation,
    ResourcePackExportSink? exportSink,
    PickResourcePackLicenses? pickLicenses,
    ResourcePackImportFixture? sourceFixture,
    MapData? initialMap,
    ResourcePackPort Function(ResourcePackPort)? wrapPack,
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final source = sourceFixture ?? await ResourcePackImportFixture.create();
    final root = await Directory('${source.directory.path}/studio-target')
        .create();
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(source.snapshot.manifest.toJson()));
    if (initialMap != null) {
      final project = source.snapshot.manifest;
      ProjectValidator.validate(project, maps: [initialMap]);
      MapValidator.validate(initialMap, projectDialogueContext: project);
      final entry = project.maps.singleWhere(
        (entry) => entry.id == initialMap.id,
      );
      final file = File('${root.path}/${entry.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(initialMap.toJson()));
    }
    final archiveFile = File(
      '${source.directory.path}/studio-source.aveluneassets',
    );
    final sink = archiveFile.openWrite();
    await source.archive.withSource(
      (archive) => sink.addStream(sourceChunks(archive)),
    );
    await sink.close();
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Pack target',
      directoryPath: await root.resolveSymbolicLinks(),
    );
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(session, maps);
    await workspace.initialize();
    final resources = LocalResourceAdapter(
      session: session,
      mapAdapter: maps,
      beforeReconciliation: beforeReconciliation,
    );
    final pack = LocalResourcePackAdapter(
      session: session,
      mapAdapter: maps,
      resources: resources,
      faultInjector: faultInjector,
    );
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: resources,
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
      packPort: wrapPack?.call(pack) ?? pack,
      packPicker: () async => archiveFile.path,
      packExportSink: exportSink,
      packLicensePicker: pickLicenses,
    );
    return ResourcePackTestHost(
      source,
      root,
      session,
      maps,
      resources,
      pack,
      workspace,
      navigation,
      archiveFile,
    );
  }

  Future<void> prepare() async {
    await transfer.beginImport();
    await transfer.selectFiltered();
    await transfer.prepare();
  }

  Future<ProjectManifest> reopen() =>
      LocalMapWorkspaceAdapter().loadProject(session);
  Future<({Map<String, String> fingerprints, Map<String, String> paths})>
  resourceState() async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    try {
      final snapshot = await ProjectSnapshotLoader(handles: handles).load(
        opened.projectHandle,
        policy: ProjectSnapshotLoadPolicy.editorReadProjection,
      );
      return (
        fingerprints: Map.of(snapshot.resourceFingerprints),
        paths: Map.of(snapshot.resourceStorageKeys),
      );
    } finally {
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  bool _sessionClosed = false;
  Future<void> closeSession() async {
    if (_sessionClosed) return;
    _sessionClosed = true;
    navigation.dispose();
    await pack.dispose();
    workspace.dispose();
    await resources.dispose();
  }

  Future<void> dispose() async {
    await closeSession();
    await source.dispose();
  }
}

class RecordingPackPort implements ResourcePackPort {
  RecordingPackPort(this.delegate);
  final ResourcePackPort delegate;
  Map<String, Object?>? projection;
  ResourceMutationReceipt? receipt;
  @override
  String get sessionId => delegate.sessionId;
  @override
  Future<void> authorizeSource(String path) => delegate.authorizeSource(path);
  @override
  Future<String> captureRevision() => delegate.captureRevision();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) => delegate.transfer(verb, input);
  @override
  Future<Map<String, Object?>> query(AuthoringQueryRequest request) =>
      delegate.query(request);
  @override
  Future<List<int>> readExportPayloadChunk(
    String payloadRef,
    int offset,
    int length,
  ) => delegate.readExportPayloadChunk(payloadRef, offset, length);
  @override
  Future<ResourceMutationReceipt> applyImport({
    required String preparedHandle,
    required String expectedRevision,
    required String operationId,
    required ResourcePackJobMonitor monitor,
  }) async => receipt = await delegate.applyImport(
    preparedHandle: preparedHandle,
    expectedRevision: expectedRevision,
    operationId: operationId,
    monitor: (start) async => projection = await monitor(start),
  );
  @override
  Future<ResourceMutationReceipt> rereadApplied() => delegate.rereadApplied();
  @override
  Future<void> reconcile(ResourceMutationReceipt receipt) =>
      delegate.reconcile(receipt);
  @override
  Future<void> dispose() => delegate.dispose();
}
