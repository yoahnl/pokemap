import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/transaction_file_gateway.dart';
import '../security/authoring_permission.dart';
import '../support/authoring_fingerprint.dart';
import 'catalog_generation_retention.dart';
import '../transactions/transaction_journal.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import 'catalog_storage_store.dart';

final class CatalogPartitionPreparation {
  CatalogPartitionPreparation._(
      this.store,
      this.root,
      this.descriptorBytes,
      this.headBytes,
      this.identityBytes,
      this.expectedProjectRevision,
      this._retention,
      this._lease);

  final CatalogStorageStore store;
  final CatalogObjectReference root;
  final List<int> descriptorBytes;
  final List<int> headBytes;
  final List<int> identityBytes;
  final String expectedProjectRevision;
  final CatalogGenerationRetention _retention;
  CatalogGenerationLease _lease;
  bool _closed = false;

  Future<void> attachOperationUnderLock(String operationId) async {
    if (_closed) throw StateError('The catalog preparation is closed.');
    safeAuthoringSecurityIdentifier(operationId, 'operationId');
    await _requireAdmission(operationId);
    if (_lease.ownerId == operationId) return;
    final lease = await _retention.protectUnderLock(
        roots: [root],
        ownerId: operationId,
        purpose: CatalogLeasePurpose.preparation);
    await _retention.releaseUnderLock(_lease.id);
    _lease = lease;
  }

  Future<void> _requireAdmission(String operationId) async {
    if (await store.readHead() != null ||
        await store.readProjectId() != null ||
        await store.gateway.readResourceRevision('project.json') !=
            expectedProjectRevision) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'The project changed before its catalog partition was applied.');
    }
    for (final journal in await readPendingTransactionJournals(store.gateway, allowLegacyScan: true)) {
      if (journal.operationId != operationId &&
          journal.entries.any((entry) =>
              entry.storageKey == CatalogStorageStore.headStorageKey)) {
        throw const CatalogStorageException('catalog.recovery_required',
            'Recover the pending catalog partition before creating another.');
      }
    }
  }

  Future<void> close() async {
    if (_closed) return;
    await store.gateway.withExclusiveWriteLock(() async {
      if (await store.gateway.readJournal(_lease.ownerId) == null) {
        await _retention.releaseUnderLock(_lease.id);
      }
      _closed = true;
    });
  }
}

final class WorkingProjectCatalogIdentity {
  const WorkingProjectCatalogIdentity(
      {required this.name, required this.projectId, required this.root});
  final String name;
  final String projectId;
  final CatalogObjectReference root;
}

final class WorkingProjectCatalog {
  WorkingProjectCatalog._(this.store, this.descriptor, this.catalog);

  static Future<WorkingProjectCatalogIdentity> inspectIdentity(
      {required CatalogStorageStore store,
      required WorkingProjectCatalogDescriptor descriptor}) async {
    final projectId = await store.readProjectId();
    if (projectId != null && projectId != descriptor.projectId) {
      throw const CatalogStorageException('catalog.project_mismatch',
          'The descriptor does not identify the managed catalog.');
    }
    final root = await store.readHead();
    if (root == null) {
      throw const CatalogStorageException(
          'catalog.missing', 'The working project has no catalog generation.');
    }
    try {
      final snapshot = (await store.openRoot(root)).snapshot;
      final shell = await snapshot.lookup(CatalogDefinitionKey(
          CatalogDefinitionKind.catalogMetadata, 'publication-shell'));
      final value = shell?.payload['value'];
      if (shell?.payload['section'] != r'$shell' ||
          value is! Map ||
          value['name'] is! String ||
          (value['name'] as String).trim().isEmpty) {
        throw const FormatException(
            'catalog.identity: project name unavailable');
      }
      if (await store.readHead() != root) _conflict();
      return WorkingProjectCatalogIdentity(
          name: value['name'] as String,
          projectId: descriptor.projectId,
          root: root);
    } on Object {
      if (await store.readHead() != root) _conflict();
      rethrow;
    }
  }

  static Future<CatalogPartitionPreparation> preparePartition({
    required CatalogStorageStore store,
    required String projectId,
    required ProjectManifest project,
    required String ownerId,
    required String expectedProjectRevision,
  }) async {
    safeAuthoringSecurityIdentifier(ownerId, 'ownerId');
    final descriptor = WorkingProjectCatalogDescriptor(projectId: projectId);
    final build = PortableCatalogPublication.encodeProject(project);
    final units = CatalogSnapshot.readAllSync(
            root: build.storage.root,
            readObject: (reference) => build.storage.objects[reference.sha256]!,
            limits: store.limits)
        .units;
    final storage = CatalogStorageBuilder(limits: store.limits).build([
      ...units,
      ...CatalogMetadataDocuments.initialize(units),
    ]);
    final retention = CatalogGenerationRetention(store: store);
    return store.gateway.withExclusiveWriteLock(() async {
      final lease = await retention.protectUnderLock(
          roots: [storage.root],
          ownerId: ownerId,
          purpose: CatalogLeasePurpose.preparation);
      final preparation = CatalogPartitionPreparation._(
          store,
          storage.root,
          List.unmodifiable(
              utf8.encode(canonicalAuthoringJson(descriptor.toJson()))),
          List.unmodifiable(CatalogStorageStore.encodeHead(storage.root)),
          List.unmodifiable(utf8.encode(canonicalAuthoringJson({
            'schemaVersion': 1,
            'projectId': projectId,
          }))),
          expectedProjectRevision,
          retention,
          lease);
      try {
        await preparation._requireAdmission(ownerId);
        await store.publishObjectsUnderLock(storage.objects);
        final admitted = (await store.openRoot(storage.root)).snapshot;
        await admitted.validate();
        await store.publishIndexAdmissionUnderLock(admitted);
        await store.publishMetadataIndexAdmissionUnderLock(admitted);
        return preparation;
      } on Object {
        await retention.releaseUnderLock(lease.id);
        rethrow;
      }
    });
  }

  static Future<WorkingProjectCatalog> create({
    required CatalogStorageStore store,
    required String projectId,
    required ProjectManifest project,
    String? expectedProjectRevision,
  }) async {
    await preparePendingTransactionJournals(store.gateway);
    final descriptor = WorkingProjectCatalogDescriptor(projectId: projectId);
    if (await store.gateway.readResourceRevision('project.json') !=
        expectedProjectRevision) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'The project changed before its working catalog was prepared.');
    }
    final build = PortableCatalogPublication.encodeProject(project);
    final units = CatalogSnapshot.readAllSync(
            root: build.storage.root,
            readObject: (reference) => build.storage.objects[reference.sha256]!,
            limits: store.limits)
        .units;
    final storage = CatalogStorageBuilder(limits: store.limits).build([
      ...units,
      ...CatalogMetadataDocuments.initialize(units),
    ]);
    final previous = await store.readHead();
    if (previous != null &&
        previous != storage.root &&
        previous != build.storage.root) {
      throw const CatalogStorageException('catalog.revision_conflict',
          'A different catalog generation is already published.');
    }
    final published =
        await store.publish(storage, expectedRootRevision: previous?.sha256);
    await store.gateway.withExclusiveWriteLock(
        () => store.publishMetadataIndexAdmissionUnderLock(published.snapshot));
    await store.gateway.withExclusiveWriteLock(() async {
      if (await store.gateway.readResourceRevision('project.json') !=
          expectedProjectRevision) {
        throw const CatalogStorageException('catalog.revision_conflict',
            'The project changed before its working catalog was published.');
      }
      await CatalogGenerationRetention(store: store)
          .bindProjectUnderLock(projectId);
      const operation = 'working_catalog_initialization';
      try {
        await store.gateway.stagePayload(
            operationId: operation,
            storageKey: 'project.json',
            kind: TransactionPayloadKind.after,
            bytes: utf8.encode(jsonEncode(descriptor.toJson())));
        await store.gateway.promoteStaged(
            operationId: operation,
            storageKey: 'project.json',
            kind: TransactionPayloadKind.after,
            expectedCurrentRevision: expectedProjectRevision);
      } finally {
        await store.gateway.deleteTransaction(operation);
      }
    });
    return open(store: store, descriptor: descriptor);
  }

  static Future<WorkingProjectCatalog> open({
    required CatalogStorageStore store,
    required WorkingProjectCatalogDescriptor descriptor,
    Set<String>? metadataFields,
  }) async {
    await _requireReadableStore(store);
    final projectId = await store.readProjectId();
    if (projectId != null && projectId != descriptor.projectId) {
      throw const CatalogStorageException('catalog.project_mismatch',
          'The descriptor does not identify the managed catalog.');
    }
    final root = await store.readHead();
    if (root == null) {
      throw const CatalogStorageException(
          'catalog.missing', 'The working project has no catalog generation.');
    }
    try {
      final snapshot = (await store.openRoot(root)).snapshot;
      final catalog = await PortableProjectCatalog.fromSnapshot(snapshot,
          metadataFields: metadataFields);
      final working = WorkingProjectCatalog._(store, descriptor, catalog);
      await working._requireCurrentRoot();
      return working;
    } on Object {
      await _requireReadableStore(store);
      if (await store.readHead() != root) _conflict();
      rethrow;
    }
  }

  final CatalogStorageStore store;
  final WorkingProjectCatalogDescriptor descriptor;
  final PortableProjectCatalog catalog;
  bool _closed = false;
  CatalogObjectReference get root => catalog.snapshot.root;

  Future<T> readCatalog<T>(
      Future<T> Function(PortableProjectCatalog) read) async {
    await _requireCurrentRoot();
    try {
      final result = await read(catalog);
      await _requireCurrentRoot();
      return result;
    } on Object {
      await _requireCurrentRoot();
      rethrow;
    }
  }

  Future<WorkingProjectCatalog> withMetadataFields(Set<String> fields) =>
      readCatalog((catalog) async => WorkingProjectCatalog._(
          store,
          descriptor,
          await PortableProjectCatalog.fromSnapshot(catalog.snapshot,
              metadataFields: fields)));

  Future<CatalogSearchPage> search(
          {CatalogDefinitionKind? kind,
          String text = '',
          int limit = 50,
          String? cursor,
          String? familyId,
          String? placementContext}) =>
      readCatalog((catalog) => catalog.snapshot.search(
          kind: kind,
          text: text,
          limit: limit,
          cursor: cursor,
          familyId: familyId,
          placementContext: placementContext));

  Future<CatalogDefinitionUnit?> lookup(CatalogDefinitionKey key) =>
      readCatalog((catalog) => catalog.lookup(key));

  CatalogDefinitionUnit replaceDefinitionValue(
          CatalogDefinitionUnit current, Map<String, Object?> value) =>
      catalog.replaceDefinitionValue(current, value);

  Future<ProjectManifest> exportProject() =>
      readCatalog((catalog) => catalog.exportProject());

  Future<void> close() async {
    _closed = true;
  }

  Future<void> _requireCurrentRoot() async {
    if (_closed) throw StateError('The working catalog is closed.');
    await _requireReadableStore(store);
    final projectId = await store.readProjectId();
    if (projectId != null && projectId != descriptor.projectId) {
      throw const CatalogStorageException('catalog.project_mismatch',
          'The descriptor does not identify the managed catalog.');
    }
    if (await store.readHead() != root) _conflict();
  }

  static Never _conflict() => throw const CatalogStorageException(
      'catalog.revision_conflict',
      'The catalog generation changed; reopen it before retrying this read.');

  static Future<void> _requireReadableStore(CatalogStorageStore store) async {
    for (final journal in await readPendingTransactionJournals(store.gateway, allowLegacyScan: true)) {
      if (journal.status != AuthoringTransactionStatus.committed &&
          journal.status != AuthoringTransactionStatus.compensated &&
          journal.entries.any((entry) =>
              entry.storageKey == CatalogStorageStore.headStorageKey)) {
        throw const CatalogStorageException('catalog.recovery_required',
            'Recover the pending catalog transaction before reading the working project.');
      }
    }
  }
}
