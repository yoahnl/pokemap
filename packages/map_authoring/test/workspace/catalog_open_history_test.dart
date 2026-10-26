import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_action_contracts.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_authoring_session.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final preparedHistory in [true, false]) {
    test(
        'cold workshop opening never admits retained generations with history prepared=$preparedHistory',
        () async {
      final taskRoot = Directory(
          '${Platform.environment['AVELUNE_QA_ROOT'] ?? '${Platform.environment['HOME']}/Library/Caches/AveluneQA/studio-project-lifecycle'}/opening-regression');
      await taskRoot.create(recursive: true);
      final fixture = await taskRoot.createTemp('fixture-');
      addTearDown(() async {
        await fixture.delete(recursive: true);
        if (await taskRoot.list().isEmpty) await taskRoot.delete();
      });
      final root = await Directory('${fixture.path}/project').create();
      final original = await CatalogStorageStore.open(
          projectRoot: root.path,
          trustedAdmissionDirectory: Directory('${fixture.path}/original'));
      final working = await WorkingProjectCatalog.create(
          store: original,
          projectId: 'game',
          project: ProjectManifest(
              name: 'Long history', maps: const [], tilesets: const []));
      final history =
          await FileAuthoringHistoryStore.open(projectRoot: root.path);
      final initialHead = (await original.readHead())!;
      final bootstrap = AuthoringResourceChange(
          resource: AuthoringResourceRef(kind: 'catalogHead', id: 'game'),
          storageKey: CatalogStorageStore.headStorageKey,
          beforeBytes: null,
          afterBytes: CatalogStorageStore.encodeHead(initialHead));
      final bootstrapChanges = AuthoringChangeSet(
          changes: [bootstrap],
          diff: AuthoringDiff([
            AuthoringDiffEntry(
                operation: AuthoringDiffOperation.add,
                resource: bootstrap.resource,
                path: '/',
                after: initialHead.toJson())
          ]));
      final blobs =
          await FileAuthoringContentBlobStore.open(projectRoot: root.path);
      await AuthoringHistoryRecorder(store: history, blobs: blobs).record(
          AuthoringCommittedMutation(
              scope: AuthoringIdempotencyScope(
                  actorId: 'legacy-producer',
                  projectId: 'game',
                  actionId: 'project.catalog.partition',
                  actionVersion: 1,
                  key: 'legacy-bootstrap'),
              planId: 'legacy-bootstrap',
              operationId: 'legacy-bootstrap',
              receipt: AuthoringReceipt(
                  receiptId: 'receipt_legacy_bootstrap',
                  requestId: 'legacy-bootstrap',
                  actionId: 'project.catalog.partition',
                  actionVersion: 1,
                  status: AuthoringReceiptStatus.applied,
                  beforeRevision:
                      AuthoringRevisionSet.beforeChangeSet(bootstrapChanges)
                          .fingerprint,
                  afterRevision:
                      AuthoringRevisionSet.afterChangeSet(bootstrapChanges)
                          .fingerprint,
                  createdAtUtc: DateTime.utc(2026, 10, 1).toIso8601String(),
                  diff: bootstrapChanges.diff),
              changes: bootstrapChanges.changes));
      expect(await history.localWindow('game'), isNull);
      final editing = await CatalogEditingSession.open(
          store: original,
          projectId: 'game',
          actorId: 'editor',
          incrementalHistory: true,
          history: history);
      final oldRootPaths = <String>{};
      try {
        for (var index = 0; index < 60; index++) {
          oldRootPaths
              .add('catalog/objects/${editing.snapshot.root.sha256}.json');
          final key =
              CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'selected');
          await editing.apply(await editing.planPatch(upserts: [
            CatalogDefinitionUnit(
                key: key, payload: {'name': 'Selected $index'})
          ], idempotencyKey: 'seed-$index'));
        }
      } finally {
        await editing.close();
      }
      expect((await history.list(projectId: 'game', limit: 100)).entries,
          hasLength(61));
      if (preparedHistory) await history.prepareLocalHistory();
      final marker = File(
          '${root.path}/.pokemap/authoring/history-local-preparation.json');
      final markerBefore =
          await marker.exists() ? await marker.readAsBytes() : null;
      final historyFile = File('${root.path}/.pokemap/authoring/history.jsonl');
      final historyBefore = await historyFile.readAsBytes();
      final head = (await original.readHead())!;
      final reader = _CountingReader();
      final coldStore = CatalogStorageStore(
          projectRoot: root.path,
          reader: reader,
          gateway:
              await LocalTransactionFileGateway.open(projectRoot: root.path),
          trustedAdmissionDirectory: Directory('${fixture.path}/cold'));
      final catalogReader = (await CatalogProjectReader.open(
          store: coldStore,
          descriptor: working.descriptor.toJson(),
          metadataFields: {}))!;
      final session = _session(catalogReader);
      addTearDown(session.close);
      reader.paths.clear();

      final historyReads = _HistoryReads(historyFile.path);
      await IOOverrides.runWithIOOverrides(
          session.prepareWorkshopCatalog, historyReads);

      expect(reader.paths.where(oldRootPaths.contains), isEmpty);
      expect(historyReads.fullReads, preparedHistory ? 0 : 1);
      expect(await coldStore.readHead(), head);
      expect(await historyFile.readAsBytes(), historyBefore);
      if (preparedHistory) expect(await marker.readAsBytes(), markerBefore);
      final reopenedHistory = await FileAuthoringHistoryStore.open(
          projectRoot: root.path, incrementalWrites: true);
      expect((await reopenedHistory.latestLocalEntry(projectId: 'game')),
          isNotNull);
      historyReads.fullReads = 0;
      await IOOverrides.runWithIOOverrides(
          session.prepareWorkshopCatalog, historyReads);
      expect(historyReads.fullReads, 0);
      expect(reader.paths.where(oldRootPaths.contains), isEmpty);
    }, timeout: const Timeout(Duration(minutes: 2)));
  }
}

final class _HistoryReads extends IOOverrides {
  _HistoryReads(this.historyPath);

  final String historyPath;
  var fullReads = 0;

  @override
  File createFile(String path) {
    final file = super.createFile(path);
    return path == historyPath ? _HistoryFile(file, this) : file;
  }
}

final class _HistoryFile implements File {
  const _HistoryFile(this.delegate, this.reads);

  final File delegate;
  final _HistoryReads reads;

  @override
  String get path => delegate.path;

  @override
  Future<FileStat> stat() => delegate.stat();

  @override
  Future<Uint8List> readAsBytes() {
    reads.fullReads++;
    return delegate.readAsBytes();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CatalogAuthoringSession _session(CatalogProjectReader reader) =>
    CatalogAuthoringSession(
        reader: reader,
        workspaceHandle: const WorkspaceHandle('workspace:opening'),
        projectHandle: const ProjectHandle('project:opening'),
        actor: AuthoringActor(
            actorId: 'editor', permissions: AuthoringPermissionScope.values),
        requireActive: () {},
        dispatcher: MapMutationDispatcher.canonical(),
        resolveAction: (_) => catalogDefinitionUpdateDescriptor,
        inspectHistoryReplay: (_, __, ___) async => null,
        loadProject: () async => throw StateError('unused'),
        buildProjectPlan: (_) async => throw StateError('unused'),
        buildScopedProjectPlan: (_, __) async => throw StateError('unused'),
        discardProjectPlan: (_) async {},
        inspectReplay: (_, __) async => null,
        prepareApply: (_, __) async {},
        requirePlanPreconditions: (_) async {},
        projections: null,
        auditOutcome: (_, __, ___, ____, _____) async {},
        clock: DateTime.now,
        limits: const AuthoringSecurityLimits());

final class _CountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource(
          {required String projectRoot, required String relativePath}) =>
      delegate.probeResource(
          projectRoot: projectRoot, relativePath: relativePath);

  @override
  Future<List<int>> readBytes(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.readBytes(
        projectRoot: projectRoot, relativePath: relativePath);
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Stream<List<int>> openRead(
      {required String projectRoot, required String relativePath}) {
    paths.add(relativePath);
    return delegate.openRead(
        projectRoot: projectRoot, relativePath: relativePath);
  }
}
