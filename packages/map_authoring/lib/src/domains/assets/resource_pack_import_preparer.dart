import 'dart:convert';
import 'dart:async';

import '../../infrastructure/local_resource_pack_store.dart';

import 'dart:math';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/file_backed_payload_store.dart';
import '../../ports/project_file_reader.dart';
import '../../security/resource_pack_bulk_capability.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_payload.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_store.dart';
import 'resource_information_document.dart';
import 'resource_pack_import_projection.dart';
part 'resource_pack_import_review.dart';

final class ResourcePackImportException implements Exception {
  const ResourcePackImportException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'ResourcePackImportException($code): $message';
}

enum ResourcePackPreparedImportStatus { ready, alreadyInstalled, conflict }

final class ResourcePackInspectedArchive {
  ResourcePackInspectedArchive._(this._owner, this.payload, this.inspection);
  final ResourcePackImportPreparer _owner;
  final StoredFilePayload payload;
  final ResourcePackInspection inspection;
}

final class ResourcePackImportSelection {
  ResourcePackImportSelection._(this.handle, this.revision, this.inspection,
      this.roots, this.smartTilePatternIds, this._archiveLease, this.expiresAt);
  final String handle;
  final String revision;
  final ResourcePackInspection inspection;
  final List<ResourcePackRef> roots;
  final List<String> smartTilePatternIds;
  final FileBackedPayloadLease _archiveLease;
  final DateTime expiresAt;
}

final class ResourcePackPreparedImport {
  ResourcePackPreparedImport._(
      {required this.status,
      this.preparedImportHandle,
      this.installation,
      required this.review,
      this.conflicts = const []});
  final ResourcePackPreparedImportStatus status;
  final String? preparedImportHandle;
  final ResourcePackInstallation? installation;
  final ResourcePackImportReview review;
  final List<String> conflicts;
}

final class _Output {
  const _Output(
      this.resource, this.path, this.payload, this.inspection, this.role);
  final AuthoringResourceRef resource;
  final String path;
  final StoredFilePayload payload;
  final AuthoringPayloadInspection inspection;
  final String role;
}

final class _Prepared {
  _Prepared(
      this.selection,
      this.target,
      this.manifest,
      this.installation,
      this.leases,
      this.outputs,
      this.projectBytes,
      this.catalogBytes,
      this.expiresAt);
  final ResourcePackImportSelection selection;
  final ProjectSnapshot target;
  final ProjectManifest manifest;
  final ResourcePackInstallation installation;
  final List<FileBackedPayloadLease> leases;
  final List<_Output> outputs;
  final List<int> projectBytes;
  final List<int> catalogBytes;
  final DateTime expiresAt;
  late final ResourcePackImportReview review;
}

final class _PlanInventory {
  _PlanInventory(this.prepared, Iterable<AuthoringResourceChange> changes)
      : expected = [
          for (final change in changes)
            {
              'resource': change.resource.toJson(),
              'path': change.storageKey,
              'before': change.beforeRevision,
              'after': change.afterRevision
            }
        ];
  final _Prepared prepared;
  final List<Map<String, Object?>> expected;
  void requirePlan(AuthoringPlan plan) {
    final actual = [
      for (final change in plan.changeSet.changes)
        {
          'resource': change.resource.toJson(),
          'path': change.storageKey,
          'before': change.beforeRevision,
          'after': change.afterRevision
        }
    ];
    if (canonicalAuthoringJson(actual) != canonicalAuthoringJson(expected)) {
      _fail('inventory_changed',
          'The final plan differs from its prepared inventory.');
    }
  }
}

typedef ResourcePackPreparedImportResolver = Future<AuthoringMutationDraft>
    Function(AuthoringPlanningContext context, String preparedImportHandle);

final class ResourcePackImportPreparer {
  ResourcePackImportPreparer(
      {required this.store,
      required this.scope,
      required this.workspaceHandle,
      required this.loadSnapshot,
      required this.probeResource,
      DateTime Function()? clock,
      String Function(String)? tokenFactory,
      this.ttl = const Duration(minutes: 10),
      this.policy = const ResourcePackSecurityPolicy()})
      : _clock = clock ?? DateTime.now,
        _tokenFactory = tokenFactory ?? _token {
    if (workspaceHandle.isEmpty || ttl <= Duration.zero) {
      throw ArgumentError('A scoped lifetime is required.');
    }
  }
  final FileBackedPayloadStore store;
  final FileBackedPayloadScope scope;
  final String workspaceHandle;
  final Future<ProjectSnapshot> Function() loadSnapshot;
  final Future<ProjectResourceProbe> Function(String) probeResource;
  final DateTime Function() _clock;
  final String Function(String) _tokenFactory;
  final Duration ttl;
  final ResourcePackSecurityPolicy policy;
  final Map<String, ResourcePackImportSelection> _selections = {};
  final Map<String, _Prepared> _prepared = {};
  final Map<String, _PlanInventory> _planInventories = {};
  final Set<String> _issued = {};
  bool _disposed = false;
  int get preparedCount => _prepared.length;
  int get planInventoryCount => _planInventories.length;

  Future<T> _sourceWorker<T>(
    String handle,
    FutureOr<T> Function(RandomAccessPackageSource) read,
  ) {
    final local = store;
    return local is LocalResourcePackStore
        ? local.withSourceInIsolate(scope: scope, handle: handle, read: read)
        : store.withSource(scope: scope, handle: handle, read: read);
  }

  Future<ResourcePackInspectedArchive> inspectArchive(
    String archiveHandle, {
    ResourcePackInspection Function(RandomAccessPackageSource)? inspector,
  }) async {
    _checkOpen();
    final lease = await store.retain(scope: scope, handle: archiveHandle);
    try {
      final securityPolicy = policy;
      final inspect =
          inspector ??
          (source) =>
              ResourcePackInspector(policy: securityPolicy)
                  .inspectSourceSync(source);
      final inspection = await _sourceWorker(archiveHandle, inspect);
      _checkOpen();
      if (inspection.archiveRawSha256 != lease.payload.rawSha256) {
        _fail('archive_changed', 'The certified archive identity differs.');
      }
      return ResourcePackInspectedArchive._(this, lease.payload, inspection);
    } finally {
      await store.release(scope: scope, leaseId: lease.leaseId);
    }
  }

  Future<ResourcePackImportSelection> selectInspected({
    required ResourcePackInspectedArchive proof,
    required Iterable<ResourcePackRef> roots,
    Iterable<String> smartTilePatternIds = const [],
  }) async {
    if (!identical(proof._owner, this)) {
      _fail(
        'inspection_owner_invalid',
        'The inspection belongs to another session.',
      );
    }
    return _select(
      archiveHandle: proof.payload.handle,
      roots: roots,
      smartTilePatternIds: smartTilePatternIds,
      proof: proof,
    );
  }

  Future<ResourcePackImportSelection> select({
    required String archiveHandle,
    required Iterable<ResourcePackRef> roots,
    Iterable<String> smartTilePatternIds = const [],
  }) => _select(
    archiveHandle: archiveHandle,
    roots: roots,
    smartTilePatternIds: smartTilePatternIds,
  );

  Future<ResourcePackImportSelection> _select({
    required String archiveHandle,
    required Iterable<ResourcePackRef> roots,
    Iterable<String> smartTilePatternIds = const [],
    ResourcePackInspectedArchive? proof,
  }) async {
    _checkOpen();
    await collectExpired();
    final lease = await store.retain(scope: scope, handle: archiveHandle);
    try {
      final certified = proof ?? await inspectArchive(archiveHandle);
      if (certified.payload.handle != lease.payload.handle ||
          certified.payload.rawSha256 != lease.payload.rawSha256 ||
          certified.payload.byteLength != lease.payload.byteLength) {
        _fail('archive_changed', 'The certified archive binding differs.');
      }
      await _sourceWorker(archiveHandle, _verifiedSource);
      final inspection = certified.inspection;
      final selected = roots.toList()
        ..sort((a, b) => a.identity.compareTo(b.identity));
      final patterns = smartTilePatternIds.toList()..sort();
      if (selected.isEmpty && patterns.isEmpty ||
          selected.map((e) => e.identity).toSet().length != selected.length ||
          patterns.toSet().length != patterns.length) {
        _fail(
            'selection_invalid', 'Select a nonempty unique set of pack roots.');
      }
      ResourcePackDependencyGraph.fromCatalog(inspection.catalog)
          .closure(roots: selected, smartTilePatternIds: patterns);
      final revision = computeAuthoringJsonFingerprint({
        'archive': inspection.archiveRawSha256,
        'roots': [for (final root in selected) root.toJson()],
        'patterns': patterns
      }, logicalName: 'resource-pack-selection');
      final value = ResourcePackImportSelection._(
          _next('selection'),
          revision,
          inspection,
          List.unmodifiable(selected),
          List.unmodifiable(patterns),
          lease,
          _clock().toUtc().add(ttl));
      _checkOpen();
      _selections[value.handle] = value;
      return value;
    } on Object {
      await store.release(scope: scope, leaseId: lease.leaseId);
      rethrow;
    }
  }

  Future<ResourcePackPreparedImport> prepare({
    required String selectionHandle,
    required String selectionRevision,
    required String expectedRevision,
    ResourcePackConflictPolicy conflictPolicy =
        ResourcePackConflictPolicy.preserveProject,
    void Function()? checkCancelled,
  }) async {
    _checkOpen();
    await collectExpired();
    final selection = _selections[selectionHandle];
    if (selection == null) {
      _fail('selection_unknown', 'The selection is unknown or expired.');
    }
    if (selection.revision != selectionRevision) {
      _fail('selection_stale', 'The immutable selection revision differs.');
    }
    checkCancelled?.call();
    final snapshot = await loadSnapshot();
    if (snapshot.revision != expectedRevision) {
      _fail('project_stale', 'The target project revision differs.');
    }
    final inspection = selection.inspection;
    final pack = inspection.manifest.pack;
    final installed = snapshot.manifest.resourcePackInstallations.entries;
    if (installed.any((e) =>
        e.packId == pack.id &&
        e.packVersion == pack.version &&
        (e.archiveRawSha256 != inspection.archiveRawSha256 ||
            e.catalogRawSha256 !=
                inspection.manifest.content.catalog.rawSha256))) {
      _fail('pack.identity_conflict',
          'This immutable pack version has another archive hash.');
    }
    final same = installed
        .where((e) => e.packId == pack.id && e.packVersion == pack.version)
        .toList();
    final closure = ResourcePackDependencyGraph.fromCatalog(inspection.catalog).closure(roots: selection.roots, smartTilePatternIds: selection.smartTilePatternIds);
    if (conflictPolicy == ResourcePackConflictPolicy.preserveProject) {
      for (final entry in same) {
        if (selection.roots.every(
                (r) => entry.resources.any((mapping) => mapping.source == r)) &&
            selection.smartTilePatternIds.every((id) => entry.supports.any(
                (mapping) =>
                    mapping.kind == ResourcePackSupportKind.smartTilePattern &&
                    mapping.sourceId == id))) {
          return ResourcePackPreparedImport._(
              status: ResourcePackPreparedImportStatus.alreadyInstalled,
              review: _buildImportReview(selection: selection, snapshot: snapshot, closure: closure, previous: entry, installation: entry, policy: conflictPolicy, status: ResourcePackPreparedImportStatus.alreadyInstalled),
              installation: entry);
        }
      }
    }
    final compatibility = inspection.manifest.compatibility;
    if (compatibility.tileWidth != snapshot.manifest.settings.tileWidth ||
        compatibility.tileHeight != snapshot.manifest.settings.tileHeight) {
      _fail('dimensions_incompatible',
          'Pack cell dimensions differ from the native project.');
    }
    final previous = conflictPolicy == ResourcePackConflictPolicy.importCopy
        ? null
        : same.where((e) => e.copyOrdinal == 0).firstOrNull;
    final ordinal = conflictPolicy == ResourcePackConflictPolicy.importCopy
        ? same.fold<int>(0, (v, e) => max(v, e.copyOrdinal)) + 1
        : 0;
    final assetCatalogBytes =
        snapshot.findResourceBytes(assetCatalogResourceIdentity);
    final assets = assetCatalogBytes == null
        ? AssetCatalog()
        : AssetCatalog.fromJson(Map<String, dynamic>.from(
            jsonDecode(utf8.decode(assetCatalogBytes)) as Map));
    var projection = ResourcePackImportProjection(
        inspection: inspection,
        closure: closure,
        copyOrdinal: ordinal,
        previous: previous);
    for (final entry in projection.filePaths.entries) {
      if (entry.value.startsWith('assets/borders/snapshots/')) {
        final existing = assets.findByLogicalPath(entry.value);
        if (existing != null) {
          projection.mapping[resourcePackNativeKey('file', entry.key)] =
              existing.id;
        }
      }
    }
    projection = await Isolate.run(_projectionWorker(projection));
    final leases = <FileBackedPayloadLease>[];
    try {
      leases.add(await store.retain(
          scope: scope, handle: selection._archiveLease.payload.handle));
      final neededLicenses = <String>{
        for (final file in inspection.catalog.files
            .where((f) => closure.files.contains(f.id)))
          ...file.licenseIds,
        for (final origin in inspection.catalog.provenance)
          if (origin.resources.any((r) => closure.resources.contains(r)))
            ...origin.licenseIds,
      };
      final archivePaths = <String>{
        for (final file in inspection.catalog.files
            .where((f) => closure.files.contains(f.id)))
          file.archivePath,
        ...neededLicenses
      };
      final staged = <String, StoredFilePayload>{};
      checkCancelled?.call();
      final certifiedEntries = await _sourceWorker(
        selection._archiveLease.payload.handle,
        _archiveEntriesWorker(inspection, policy),
      );
      checkCancelled?.call();
      await store.withSource(
        scope: scope,
        handle: selection._archiveLease.payload.handle,
        read: (source) async {
          final entries = certifiedEntries;
          final inventory = {
            for (final file in inspection.manifest.content.files)
              file.path: file,
          };
          for (final path in archivePaths.toList()..sort()) {
            checkCancelled?.call();
            final entry = entries[path];
            final descriptor = inventory[path];
            if (entry == null || descriptor == null) {
              _fail(
                'archive_inventory_invalid',
                'A prepared source is absent from the certified archive.',
              );
            }
            final lease = await store.stage(
              scope: scope,
              chunks: _chunks(
                source,
                entry.dataOffset,
                entry.size,
                policy.maxChunkBytes,
              ),
              byteLength: descriptor.byteLength,
              expectedRawSha256: descriptor.rawSha256,
              checkCancelled: checkCancelled,
            );
            leases.add(lease);
            staged[path] = lease.payload;
          }
        },
      );
      checkCancelled?.call();
      projection = await _sourceWorker(
        selection._archiveLease.payload.handle,
        _borderWorker(
          projection,
          snapshot.manifest,
          inspection,
          certifiedEntries,
          policy.maxChunkBytes,
        ),
      );
      checkCancelled?.call();
      final conflicts = _definitionConflicts(
        snapshot.manifest,
        projection,
        previous,
      );
      final records = <AssetRecord>[...assets.records];
      final outputs = <_Output>[];
      final newBlobs = <String>{};
      final mappings = <ResourcePackAssetMapping>[];
      for (final file in inspection.catalog.files
          .where((f) => closure.files.contains(f.id))) {
        final id = projection.reference('file', file.id);
        final path = projection.filePaths[file.id]!;
        final payload = staged[file.archivePath]!;
        final observed = await _inspect(payload, path);
        final artifact = ContentArtifactRef(
            digest: observed.contentDigest,
            byteLength: payload.byteLength,
            mediaType: file.mediaType);
        final record =
            AssetRecord(id: id, logicalPath: path, artifact: artifact);
        mappings.add(ResourcePackAssetMapping(
            fileId: file.id,
            assetId: id,
            targetPath: path,
            rawSha256: file.rawSha256,
            byteLength: file.byteLength,
            mediaType: file.mediaType));
        await _addFile(snapshot, assets, records, record, payload, observed,
            outputs, newBlobs, conflicts,
            historical:
                previous?.assets.any((a) => a.fileId == file.id) ?? false,
            contentAddressed: path.startsWith('assets/borders/snapshots/'));
      }
      final historicalLicenses = <String>{
        if (previous != null) ...[
          for (final file in inspection.catalog.files)
            if (previous.assets.any((a) => a.fileId == file.id))
              ...file.licenseIds,
          for (final origin in inspection.catalog.provenance)
            if (origin.resources.any((r) =>
                previous.resources.any((mapping) => mapping.source == r)))
              ...origin.licenseIds,
        ]
      };
      for (final license in neededLicenses.toList()..sort()) {
        final payload = staged[license]!;
        final path = 'assets/resource_packs/${projection.namespace}/$license';
        final observed = await _inspect(payload, path);
        final record = AssetRecord(
            id: 'rp_${projection.namespace}_license_${payload.rawSha256}',
            logicalPath: path,
            artifact: ContentArtifactRef(
                digest: observed.contentDigest,
                byteLength: payload.byteLength,
                mediaType: 'text/plain'));
        await _addFile(snapshot, assets, records, record, payload, observed,
            outputs, newBlobs, conflicts,
            historical: historicalLicenses.contains(license),
            contentAddressed: false);
      }
      if (conflicts.isNotEmpty) {
        return ResourcePackPreparedImport._(
            status: ResourcePackPreparedImportStatus.conflict,
            review: _buildImportReview(selection: selection, snapshot: snapshot, closure: closure, previous: previous, projection: projection, policy: conflictPolicy, status: ResourcePackPreparedImportStatus.conflict, conflicts: conflicts),
            conflicts: List.unmodifiable(conflicts.toList()..sort()));
      }
      final logicalCount =
          outputs.where((output) => output.role == 'logical').length;
      final blobCount = outputs.where((output) => output.role == 'blob').length;
      if (logicalCount > policy.maxPublishedFiles ||
          logicalCount > 20000 ||
          blobCount > logicalCount ||
          outputs.length + 2 > 40002) {
        _fail('output_limit_exceeded',
            'The complete native output exceeds the certified import budget.');
      }
      final installation = _installation(selection, projection, previous,
          mappings, _clock().toUtc().toIso8601String());
      final manifest =
          _merge(snapshot.manifest, projection, previous, installation);
      ProjectValidator.validate(manifest);
      final catalog = AssetCatalog(records: records);
      final value = _Prepared(
          selection,
          snapshot,
          manifest,
          installation,
          List.unmodifiable(leases),
          List.unmodifiable(outputs),
          encodeResourceInformationDocument(snapshot, manifest),
          utf8.encode(jsonEncode(catalog.toJson())),
          _clock().toUtc().add(ttl));
      if ((await loadSnapshot()).revision != snapshot.revision) {
        _fail('project_stale', 'The project changed during preparation.');
      }
      _checkOpen();
      checkCancelled?.call();
      final handle = _next('prepared');
      value.review = _buildImportReview(selection: selection, snapshot: snapshot, closure: closure, previous: previous, projection: projection, installation: installation, policy: conflictPolicy, status: ResourcePackPreparedImportStatus.ready, outputs: outputs, metadataBytes: value.projectBytes.length + value.catalogBytes.length);
      _prepared[handle] = value;
      leases.clear();
      return ResourcePackPreparedImport._(
          status: ResourcePackPreparedImportStatus.ready,
          review: value.review,
          preparedImportHandle: handle,
          installation: installation);
    } finally {
      for (final lease in leases) {
        await store.release(scope: scope, leaseId: lease.leaseId);
      }
    }
  }

  Future<void> _addFile(
      ProjectSnapshot snapshot,
      AssetCatalog assets,
      List<AssetRecord> records,
      AssetRecord record,
      StoredFilePayload payload,
      AuthoringPayloadInspection observed,
      List<_Output> outputs,
      Set<String> newBlobs,
      Set<String> conflicts,
      {required bool historical,
      required bool contentAddressed}) async {
    final existing = assets.find(record.id);
    final atPath = assets.findByLogicalPath(record.logicalPath);
    if (existing != null || atPath != null) {
      final known = existing ?? atPath!;
      final identity = snapshot.resourceStorageKeys.entries
          .where((e) => e.value == known.logicalPath)
          .firstOrNull
          ?.key;
      if ((!historical && !contentAddressed) ||
          known.id != record.id ||
          known.logicalPath != record.logicalPath ||
          known.artifact != record.artifact ||
          identity == null ||
          !snapshot.resourceMatchesArtifact(identity, record.artifact)) {
        conflicts.add('asset_dependency_conflict:${record.id}');
      } else {
        final captured = await snapshot.captureResourcePayload(identity);
        try {
          if (captured.rawSha256 != payload.rawSha256) {
            conflicts.add('asset_dependency_conflict:${record.id}');
          }
        } finally {
          await captured.release();
        }
      }
    } else if (historical) {
      conflicts.add('asset_dependency_missing:${record.id}');
    } else if (await _missing(record.logicalPath, conflicts)) {
      records.add(record);
      outputs.add(_Output(AuthoringResourceRef(kind: 'asset', id: record.id),
          record.logicalPath, payload, observed, 'logical'));
    }
    final blob = assetBlobStorageKey(record.artifact);
    final blobIdentity = assetBlobResourceIdentity(record.artifact.digest);
    if (snapshot.hasResource(blobIdentity)) {
      if (!snapshot.resourceMatchesArtifact(blobIdentity, record.artifact)) {
        conflicts.add('blob_conflict:${record.artifact.digest}');
      } else {
        final captured = await snapshot.captureResourcePayload(blobIdentity);
        try {
          if (captured.rawSha256 != payload.rawSha256) {
            conflicts.add('blob_conflict:${record.artifact.digest}');
          }
        } finally {
          await captured.release();
        }
      }
    } else if (newBlobs.add(blob) && await _missing(blob, conflicts)) {
      outputs.add(_Output(
          AuthoringResourceRef(kind: 'assetBlob', id: record.artifact.digest),
          blob,
          payload,
          await _inspect(payload, blob),
          'blob'));
    }
  }

  Future<bool> _missing(String path, Set<String> conflicts) async {
    final probe = await probeResource(path);
    if (probe.status == ProjectResourceProbeStatus.missing) return true;
    if (probe.status == ProjectResourceProbeStatus.exists) {
      conflicts.add('path_occupied:$path');
      return false;
    }
    _fail('inventory_unavailable',
        'The native file inventory cannot certify an unused output path.');
  }

  Future<AuthoringPayloadInspection> _inspect(
          StoredFilePayload payload, String path) =>
      store.withSource(
          scope: scope,
          handle: payload.handle,
          read: (source) => inspectAuthoringPayload(
              _chunks(source, 0, source.length, policy.maxChunkBytes),
              storageKey: path,
              byteLength: payload.byteLength));
  Future<AuthoringMutationDraft> buildDraft(
      AuthoringPlanningContext context, String handle) async {
    _checkOpen();
    await collectExpired();
    final prepared = _prepared[handle];
    if (prepared == null) {
      _fail('prepared_unknown', 'The prepared import is unknown or expired.');
    }
    if (context.request.workspaceHandle != workspaceHandle ||
        context.snapshot.projectHandle != prepared.target.projectHandle) {
      _fail('owner_mismatch',
          'This preparation belongs to another workspace or project.');
    }
    if (context.snapshot.revision != prepared.target.revision) {
      _fail('project_stale', 'The prepared target revision changed.');
    }
    final changes = <AuthoringResourceChange>[];
    try {
      for (final output in prepared.outputs) {
        final payload =
            context.snapshot.ownPayload(await AuthoringPayload.stored(
                store: store,
                scope: scope,
                payload: output.payload,
                storageKey: output.path,
                resourceRevision: output.inspection.resourceRevision,
                release: () async {
                  _planInventories.remove(context.planId);
                }));
        changes.add(AuthoringResourceChange.withPayloads(
            resource: output.resource,
            storageKey: output.path,
            beforePayload: null,
            afterPayload: payload));
      }
      final catalogBefore =
          context.snapshot.findResourceBytes(assetCatalogResourceIdentity);
      for (final (kind, id, path, before, after) in [
        (
          'project',
          'project',
          'project.json',
          context.snapshot.resourceBytes('project'),
          prepared.projectBytes
        ),
        (
          'assetCatalog',
          'catalog',
          assetCatalogStorageKey,
          catalogBefore,
          prepared.catalogBytes
        ),
      ]) {
        if (before != null &&
            computeAuthoringBytesFingerprint(before, logicalName: path) ==
                computeAuthoringBytesFingerprint(after, logicalName: path)) {
          continue;
        }
        changes.add(AuthoringResourceChange(
            resource: AuthoringResourceRef(kind: kind, id: id),
            storageKey: path,
            beforeBytes: before,
            afterBytes: after));
      }
      final diff = AuthoringDiff([
        for (final change in changes)
          AuthoringDiffEntry(
              operation: change.beforePayload == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
              resource: change.resource,
              path: '/',
              after: {
                'byteLength': change.afterPayload!.byteLength,
                'revision': change.afterRevision
              })
      ]);
      final changeSet = AuthoringChangeSet(changes: changes, diff: diff);
      _planInventories[context.planId] =
          _PlanInventory(prepared, changeSet.changes);
      context.snapshot.payloadOwner?.onRelease(() {
        _planInventories.remove(context.planId);
      });
      return AuthoringMutationDraft(
          changeSet: changeSet,
          projectedProject: prepared.manifest,
          preview: {
            'operation': 'resource_pack.import',
            'createdResources': prepared.review.summary['createdDefinitionCount'],
            'selectionSummary': prepared.review.summary,
            'logicalOutputs':
                prepared.outputs.where((o) => o.role == 'logical').length,
            'copyOrdinal': prepared.installation.copyOrdinal
          },
          referenceImpact: const {
            'mapsUnchanged': true,
            'scenesUnchanged': true,
            'progressionUnchanged': true
          });
    } on Object {
      _planInventories.remove(context.planId);
      await releaseAuthoringPayloads(changes.map((c) => c.afterPayload));
      rethrow;
    }
  }

  void certifyPlan(
      {required AuthoringPlan plan,
      required String actorId,
      required String projectId,
      required String operationId}) {
    final existing = plan.bulkCapability;
    if (existing != null) {
      existing.requirePlan(plan,
          actorId: actorId, projectId: projectId, operationId: operationId);
      return;
    }
    final inventory = _planInventories[plan.planId];
    if (inventory == null || projectId != scope.projectId) {
      _fail(
          'inventory_unknown', 'No trusted prepared inventory owns this plan.');
    }
    inventory.requirePlan(plan);
    plan.bindBulkCapability(ResourcePackBulkAuthority.certifyImport(
        plan: plan,
        actorId: actorId,
        projectId: projectId,
        operationId: operationId,
        logicalStorageKeys: inventory.prepared.outputs
            .where((o) => o.role == 'logical')
            .map((o) => o.path),
        contentBlobStorageKeys: inventory.prepared.outputs
            .where((o) => o.role == 'blob')
            .map((o) => o.path)));
  }

  Future<void> requirePlanPreconditions(AuthoringPlan plan) async {
    final inventory = _planInventories[plan.planId];
    if (inventory == null) {
      _fail(
          'inventory_unknown', 'No prepared import owns these preconditions.');
    }
    inventory.requirePlan(plan);
    final current = await loadSnapshot();
    if (current.revision != plan.baseRevision) {
      _fail('project_stale',
          'A required native dependency changed under the project lock.');
    }
    for (final output in inventory.prepared.outputs) {
      if ((await probeResource(output.path)).status !=
          ProjectResourceProbeStatus.missing) {
        _fail('path_occupied', 'An output path changed after preparation.');
      }
    }
  }

  Future<bool> discardSelection(String handle) async {
    final value = _selections.remove(handle);
    if (value == null) return false;
    await store.release(scope: scope, leaseId: value._archiveLease.leaseId);
    return true;
  }

  Future<bool> discardPrepared(String handle) async {
    final value = _prepared.remove(handle);
    if (value == null) return false;
    for (final lease in value.leases) {
      await store.release(scope: scope, leaseId: lease.leaseId);
    }
    return true;
  }

  Future<void> collectExpired() async {
    for (final handle in _selections.entries
        .where((e) => !_clock().toUtc().isBefore(e.value.expiresAt))
        .map((e) => e.key)
        .toList()) {
      await discardSelection(handle);
    }
    for (final handle in _prepared.entries
        .where((e) => !_clock().toUtc().isBefore(e.value.expiresAt))
        .map((e) => e.key)
        .toList()) {
      await discardPrepared(handle);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final handle in _prepared.keys.toList()) {
      await discardPrepared(handle);
    }
    for (final handle in _selections.keys.toList()) {
      await discardSelection(handle);
    }
    _planInventories.clear();
  }

  void _checkOpen() {
    if (_disposed) _fail('closed', 'The import preparer is closed.');
  }

  String _next(String prefix) {
    final token = _tokenFactory(prefix);
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(token) ||
        !_issued.add(token)) {
      _fail('token_invalid', 'The opaque token factory reused an identity.');
    }
    return token;
  }
}

Stream<List<int>> _chunks(RandomAccessPackageSource source, int offset,
    int length, int chunkSize) async* {
  for (var position = 0; position < length; position += chunkSize) {
    yield source.readAtSync(
        offset + position, min(chunkSize, length - position));
  }
}

String _token(String prefix) {
  final random = Random.secure();
  return '${prefix}_${List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

Never _fail(String code, String message) => throw ResourcePackImportException(
    code.startsWith('pack.') ? code : 'resource_pack.$code', message);

Set<String> _historicalKeys(ResourcePackInstallation? previous) => {
      if (previous != null) ...[
        for (final mapping in previous.resources)
          resourcePackNativeKey(mapping.source.kind.name, mapping.source.id),
        for (final mapping in previous.supports)
          resourcePackNativeKey(
              mapping.kind.name, mapping.sourceId, mapping.owner?.id),
      ]
    };

Map<String, Map<String, dynamic>> _nativeDefinitions(
        ProjectManifest manifest) =>
    indexResourcePackDefinitions(manifest.toJson());

ProjectManifest _projectedLibrary(
    ProjectManifest target, ResourcePackImportProjection projection) {
  final c = projection.catalog;
  final smart = c.smartTileCatalog;
  return target.copyWith(
      tilesets: c.tilesets,
      elements: c.elements,
      models3d: c.models3d,
      characters: c.characters,
      environmentPresets: c.environmentPresets,
      elementCategories: c.elementCategories,
      tilesetFolders: c.tilesetFolders,
      resourceLibraryCatalog: c.resourceLibraryCatalog,
      borderCatalog: c.borderCatalog,
      characterStudioCatalog: c.characterStudioCatalog,
      smartTileCatalog: ProjectSmartTileCatalog(
          categories: smart.categories,
          materials: smart.materials,
          atlases: smart.atlases,
          animations: smart.animations,
          presets: smart.presets,
          patterns: smart.patterns,
          drafts: [
            for (final preset in smart.presets)
              reconstructResourcePackSmartTileDraft(
                  preset: preset, catalog: smart)
          ]));
}

Set<String> _definitionConflicts(
    ProjectManifest target,
    ResourcePackImportProjection projection,
    ResourcePackInstallation? previous) {
  final current = _nativeDefinitions(target);
  final expectedManifest = _projectedLibrary(target, projection);
  final expected = _nativeDefinitions(expectedManifest);
  final historical = _historicalKeys(previous);
  final conflicts = <String>{};
  for (final source in projection.selectedKeys) {
    final parts = jsonDecode(source) as List;
    if (parts[0] == 'file') continue;
    final key = resourcePackNativeKey(
        parts[0] as String,
        projection.mapping[source]!,
        parts[1] == null
            ? null
            : projection.reference('tileset', parts[1] as String));
    final before = current[key];
    final after = expected[key];
    if (historical.contains(source)) {
      if (before == null ||
          CanonicalJson.encode(before) != CanonicalJson.encode(after)) {
        conflicts.add('dependency_modified_or_missing:$key');
      }
    } else if (before != null &&
        !(parts[0] == 'borderSnapshot' &&
            CanonicalJson.encode(before) == CanonicalJson.encode(after))) {
      conflicts.add('id_occupied:$key');
    }
    if (historical.contains(source) && parts[0] == 'smartTilePreset') {
      final id = projection.mapping[source]!;
      final actualDrafts = target.smartTileCatalog.drafts
          .where((d) => d.targetPresetId == id)
          .map((d) => d.toJson())
          .toList();
      final expectedDrafts = expectedManifest.smartTileCatalog.drafts
          .where((d) => d.targetPresetId == id)
          .map((d) => d.toJson())
          .toList();
      if (CanonicalJson.encode(actualDrafts) !=
          CanonicalJson.encode(expectedDrafts)) {
        conflicts.add('dependency_draft_modified_or_missing:$id');
      }
    }
  }
  for (final draft in expectedManifest.smartTileCatalog.drafts) {
    final source = projection.mapping.entries
        .where((entry) =>
            entry.value == draft.targetPresetId &&
            (jsonDecode(entry.key) as List)[0] == 'smartTilePreset')
        .firstOrNull
        ?.key;
    if (source != null &&
        !historical.contains(source) &&
        target.smartTileCatalog.drafts.any((current) =>
            current.id == draft.id ||
            current.targetPresetId == draft.targetPresetId)) {
      conflicts.add('id_occupied:smartTileDraft:${draft.id}');
    }
  }
  for (final source in projection.closure.resources) {
    if (!historical
        .contains(resourcePackNativeKey(source.kind.name, source.id))) {
      continue;
    }
    final targetId = projection.reference(source.kind.name, source.id);
    final expectedEntry = projection.catalog.resourceLibraryCatalog.entries
        .where((entry) =>
            entry.resourceKind == source.kind.name &&
            entry.resourceId == targetId)
        .firstOrNull;
    final existing = target.resourceLibraryCatalog.entries
        .where((e) =>
            e.resourceKind == source.kind.name && e.resourceId == targetId)
        .firstOrNull;
    if (CanonicalJson.encode(existing?.toJson()) !=
        CanonicalJson.encode(expectedEntry?.toJson())) {
      conflicts.add('classification_modified_or_missing:$targetId');
    }
  }
  return conflicts;
}

ResourcePackInstallation _installation(
    ResourcePackImportSelection selection,
    ResourcePackImportProjection projection,
    ResourcePackInstallation? previous,
    List<ResourcePackAssetMapping> assets,
    String installedAtUtc) {
  final manifest = _projectedLibrary(
      ProjectManifest(
          name: 'Projection',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(
              tileWidth: selection.inspection.manifest.compatibility.tileWidth,
              tileHeight:
                  selection.inspection.manifest.compatibility.tileHeight)),
      projection);
  final definitions = _nativeDefinitions(manifest);
  final resources = {
    for (final item
        in previous?.resources ?? const <ResourcePackResourceMapping>[])
      item.source.identity: item
  };
  for (final ref in projection.closure.resources) {
    final target = projection.reference(ref.kind.name, ref.id);
    resources[ref.identity] = ResourcePackResourceMapping(
        source: ref,
        targetId: target,
        definitionRawSha256: CanonicalJson.sha256Hex(
            definitions[resourcePackNativeKey(ref.kind.name, target)]));
  }
  final supports = {
    for (final item
        in previous?.supports ?? const <ResourcePackSupportMapping>[])
      item.sourceIdentity: item
  };
  for (final ref in projection.closure.supports) {
    final item = ResourcePackSupportMapping(
        kind: ref.kind,
        sourceId: ref.id,
        targetId: projection.reference(ref.kind.name, ref.id, ref.owner?.id),
        owner: ref.owner,
        targetOwnerId: ref.owner == null
            ? null
            : projection.reference('tileset', ref.owner!.id));
    supports[item.sourceIdentity] = item;
  }
  final files = {
    for (final item in previous?.assets ?? const <ResourcePackAssetMapping>[])
      item.fileId: item,
    for (final item in assets) item.fileId: item
  };
  return ResourcePackInstallation(
      installationId: previous?.installationId ?? 'rp_${projection.namespace}',
      packId: selection.inspection.manifest.pack.id,
      packVersion: selection.inspection.manifest.pack.version,
      universeId: selection.inspection.manifest.pack.universeId,
      archiveRawSha256: selection.inspection.archiveRawSha256,
      catalogRawSha256: selection.inspection.manifest.content.catalog.rawSha256,
      copyOrdinal: projection.copyOrdinal,
      selectedRoots: {
        ...previous?.selectedRoots ?? const <ResourcePackRef>[],
        ...selection.roots
      },
      selectedSmartTilePatternIds: {
        ...previous?.selectedSmartTilePatternIds ?? const <String>[],
        ...selection.smartTilePatternIds
      },
      resources: resources.values,
      supports: supports.values,
      assets: files.values,
      internalMappings: {
        ...previous?.internalMappings ?? const <String, String>{},
        ...projection.internalMappings
      },
      installedAtUtc: previous?.installedAtUtc ?? installedAtUtc,
      provenanceStatus: selection.inspection.provenanceStatus);
}

ProjectManifest _merge(
    ProjectManifest target,
    ResourcePackImportProjection projection,
    ResourcePackInstallation? previous,
    ResourcePackInstallation installation) {
  final c = _projectedLibrary(target, projection);
  final historical = _historicalKeys(previous);
  bool include(String kind, String id) {
    final source = projection.mapping.entries
        .where((e) => e.value == id && (jsonDecode(e.key) as List)[0] == kind)
        .firstOrNull
        ?.key;
    return source != null && !historical.contains(source);
  }

  final smart = target.smartTileCatalog;
  final imported = c.smartTileCatalog;
  return target.copyWith(
      tilesets: [
        ...target.tilesets,
        ...c.tilesets.where((e) => include('tileset', e.id))
      ],
      elements: [
        ...target.elements,
        ...c.elements.where((e) => include('element', e.id))
      ],
      models3d: [
        ...target.models3d,
        ...c.models3d.where((e) => include('model3d', e.id))
      ],
      characters: [
        ...target.characters,
        ...c.characters.where((e) => include('character', e.id))
      ],
      environmentPresets: [
        ...target.environmentPresets,
        ...c.environmentPresets.where((e) => include('environmentPreset', e.id))
      ],
      elementCategories: [
        ...target.elementCategories,
        ...c.elementCategories.where((e) => include('elementCategory', e.id))
      ],
      tilesetFolders: [
        ...target.tilesetFolders,
        ...c.tilesetFolders.where((e) => include('tilesetFolder', e.id))
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(families: [
        ...target.resourceLibraryCatalog.families,
        ...c.resourceLibraryCatalog.families
            .where((e) => include('resourceFamily', e.id))
      ], entries: [
        ...target.resourceLibraryCatalog.entries,
        ...c.resourceLibraryCatalog.entries
            .where((e) => include(e.resourceKind, e.resourceId))
      ]),
      characterStudioCatalog:
          target.characterStudioCatalog.copyWith(portraitStates: [
        ...target.characterStudioCatalog.portraitStates,
        ...c.characterStudioCatalog.portraitStates
            .where((e) => include('characterPortraitState', e.id))
      ], customAnimationDefinitions: [
        ...target.characterStudioCatalog.customAnimationDefinitions,
        ...c.characterStudioCatalog.customAnimationDefinitions
            .where((e) => include('characterAnimationDefinition', e.id))
      ]),
      smartTileCatalog: ProjectSmartTileCatalog(categories: [
        ...smart.categories,
        ...imported.categories.where((e) => include('smartTileCategory', e.id))
      ], materials: [
        ...smart.materials,
        ...imported.materials.where((e) => include('smartTileMaterial', e.id))
      ], atlases: [
        ...smart.atlases,
        ...imported.atlases.where((e) => include('smartTileAtlas', e.id))
      ], animations: [
        ...smart.animations,
        ...imported.animations.where((e) => include('smartTileAnimation', e.id))
      ], presets: [
        ...smart.presets,
        ...imported.presets.where((e) => include('smartTilePreset', e.id))
      ], patterns: [
        ...smart.patterns,
        ...imported.patterns.where((e) => include('smartTilePattern', e.id))
      ], drafts: [
        ...smart.drafts,
        ...imported.drafts
            .where((e) => include('smartTilePreset', e.targetPresetId))
      ]),
      borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [
            ...target.borderCatalog.records,
            ...c.borderCatalog.records
                .where((e) => include('borderBlueprint', e.id))
          ],
          visualSnapshots: [
            ...target.borderCatalog.visualSnapshots,
            ...c.borderCatalog.visualSnapshots.where((e) =>
                !target.borderCatalog.visualSnapshots.any((v) => v.id == e.id))
          ]),
      resourcePackInstallations: ResourcePackInstallationCatalog(entries: [
        ...target.resourcePackInstallations.entries
            .where((e) => e.installationId != installation.installationId),
        installation
      ]));
}

bool _verifiedSource(RandomAccessPackageSource source) => true;

Map<String, dynamic> Function(RandomAccessPackageSource) _archiveEntriesWorker(
  ResourcePackInspection inspection,
  ResourcePackSecurityPolicy policy,
) => (source) {
  final certified = ResourcePackInspector(policy: policy)
      .inspectSourceSync(source);
  if (certified.archiveRawSha256 != inspection.archiveRawSha256) {
    _fail(
      'archive_changed',
      'The inspected archive changed before preparation.',
    );
  }
  final allowed = {
    'manifest.json',
    inspection.manifest.content.catalog.path,
    ...inspection.manifest.content.files.map((file) => file.path),
  };
  return {
    for (final entry in RandomAccessZipStructureReader(
      const GamePackageSecurityPolicy(),
      entryNameValidator: (name) {
        if (!allowed.contains(name)) {
          _fail('archive_inventory_invalid', 'ZIP inventory differs.');
        }
      },
      maxTotalEntries: policy.maxZipEntries,
      readChunkBytes: policy.maxChunkBytes,
    ).read(source).entries)
      entry.name: entry,
  };
};

ResourcePackImportProjection Function() _projectionWorker(
  ResourcePackImportProjection projection,
) => () {
  projection.project();
  return projection;
};

Future<ResourcePackImportProjection> Function(RandomAccessPackageSource)
_borderWorker(
  ResourcePackImportProjection projection,
  ProjectManifest target,
  ResourcePackInspection inspection,
  Map<String, dynamic> entries,
  int chunkBytes,
) => (source) async {
  List<int> read(String path) {
    final entry = entries[path];
    if (entry == null) {
      _fail(
        'border_source_missing',
        'A Border source is outside the certified inventory.',
      );
    }
    final bytes = BytesBuilder(copy: false);
    for (var offset = 0; offset < (entry.size as int); offset += chunkBytes) {
      bytes.add(
        source.readAtSync(
          (entry.dataOffset as int) + offset,
          min(chunkBytes, (entry.size as int) - offset),
        ),
      );
    }
    return bytes.takeBytes();
  }

  final mapped = {
    for (final file in inspection.catalog.files)
      projection.mapping[resourcePackNativeKey('file', file.id)]: file,
  };
  await projection.certifyBorders(
    target,
    (tileset, assetId) async {
      final binding = mapped[assetId];
      if (binding == null) {
        _fail('border_source_missing', 'A mapped Border source is absent.');
      }
      return read(binding.archivePath);
    },
    (tileset, assetId) async {
      final binding = inspection.catalog.files
          .where((file) => file.id == assetId)
          .firstOrNull;
      if (binding == null) {
        _fail('border_source_missing', 'A portable Border source is absent.');
      }
      return read(binding.archivePath);
    },
  );
  return projection;
};
