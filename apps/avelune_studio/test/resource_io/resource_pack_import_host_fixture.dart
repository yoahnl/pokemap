import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_pack_adapter.dart';
import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
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
    show AuthoringTransactionFaultInjector;

import '../../../../packages/map_authoring/test/domains/assets/resource_pack_import_fixture.dart';
import '../support/map_workspace_fixture.dart';

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
