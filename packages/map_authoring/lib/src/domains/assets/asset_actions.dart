import 'dart:convert';

import '../../contracts/artifact_ref.dart';
import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_receipt.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_store.dart';

final class AssetActionException implements Exception {
  AssetActionException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'AssetActionException($code): $message';
}

final class AssetActionResult {
  AssetActionResult({
    required this.operation,
    required this.catalog,
    this.before,
    this.after,
    this.deletedBlob = false,
    List<int>? rollbackBlobBytes,
    this.deduplicated = false,
  }) : rollbackBlobBytes = rollbackBlobBytes == null
            ? null
            : List<int>.unmodifiable(rollbackBlobBytes);

  final String operation;
  final AssetCatalog catalog;
  final AssetRecord? before;
  final AssetRecord? after;
  final bool deletedBlob;
  final List<int>? rollbackBlobBytes;
  final bool deduplicated;

  Map<String, Object?> toJson() => {
        'operation': operation,
        if (before != null) 'before': before!.toJson(),
        if (after != null) 'after': after!.toJson(),
        'deletedBlob': deletedBlob,
        'rollbackByteLength': rollbackBlobBytes?.length,
        'deduplicated': deduplicated,
      };
}

/// Pure asset-catalog projector used by both standalone and composite imports.
///
/// It intentionally has no access to an artifact store or filesystem. The
/// caller owns staging bytes and turning the projected catalog into a durable
/// transaction plan.
final class AssetImportProjector {
  const AssetImportProjector();

  AssetActionResult project(
    AssetCatalog catalog, {
    required AssetRecord record,
  }) {
    if (catalog.find(record.id) != null) {
      throw AssetActionException(
        'asset.id_conflict',
        'An asset already owns this identity.',
        details: {'assetId': record.id},
      );
    }
    if (catalog.records.any(
      (candidate) => candidate.logicalPath == record.logicalPath,
    )) {
      throw AssetActionException(
        'asset.path_conflict',
        'An asset already owns this logical path.',
        details: {'logicalPath': record.logicalPath},
      );
    }
    final deduplicated = catalog.records.any(
      (candidate) => candidate.artifact.digest == record.artifact.digest,
    );
    return AssetActionResult(
      operation: 'import',
      catalog: AssetCatalog(records: [...catalog.records, record]),
      after: record,
      deduplicated: deduplicated,
    );
  }
}

/// Pure asset catalog operations. Durable filesystem application is left to
/// the Phase-3 transaction boundary so these methods cannot bypass recovery.
final class AssetActions {
  const AssetActions({this.artifactStore});

  final ArtifactStore? artifactStore;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor('asset.import', 'Import one inspected artifact',
        AuthoringRiskLevel.low),
    _descriptor(
        'asset.replace', 'Replace one asset blob', AuthoringRiskLevel.medium),
    _descriptor(
      'asset.raw.replace',
      'Replace one unmanaged project asset with an exact pre-image',
      AuthoringRiskLevel.medium,
      resourceKinds: const ['asset'],
    ),
    _descriptor(
        'asset.move', 'Move one logical asset path', AuthoringRiskLevel.low),
    _descriptor('asset.delete', 'Delete one unreferenced asset',
        AuthoringRiskLevel.high),
  ]);

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final store = artifactStore;
    if (store == null &&
        const {'asset.import', 'asset.replace', 'asset.raw.replace'}
            .contains(context.request.actionId)) {
      throw AssetActionException(
        'artifact.store_required',
        'Import and replace require an injected artifact store.',
      );
    }
    final state = _catalogState(context.snapshot);
    final parameters = _AssetParameters(context.request.parameters);
    if (context.request.actionId == 'asset.raw.replace') {
      parameters.allow(const {
        'logicalPath',
        'expectedArtifactHandle',
        'replacementArtifactHandle',
      });
      return _rawReplacementDraft(
        state,
        logicalPath: _rawAssetLogicalPath(parameters.string('logicalPath')),
        expectedArtifact: _requireArtifact(
          store!,
          parameters.string('expectedArtifactHandle'),
        ),
        replacementArtifact: _requireArtifact(
          store,
          parameters.string('replacementArtifactHandle'),
        ),
        artifactStore: store,
      );
    }
    late final AssetActionResult result;
    ContentArtifactRef? addedArtifact;
    List<int>? addedBytes;
    switch (context.request.actionId) {
      case 'asset.import':
        parameters.allow(const {
          'artifactHandle',
          'assetId',
          'logicalPath',
          'tags',
          'usages'
        });
        addedArtifact =
            _requireArtifact(store!, parameters.string('artifactHandle'));
        addedBytes = await store.read(addedArtifact.handle);
        result = import(
          state.catalog,
          record: AssetRecord(
            id: parameters.string('assetId'),
            logicalPath: parameters.string('logicalPath'),
            artifact: addedArtifact,
            tags: parameters.strings('tags'),
            usages: parameters.strings('usages'),
          ),
        );
      case 'asset.replace':
        parameters.allow(const {'artifactHandle', 'assetId'});
        addedArtifact =
            _requireArtifact(store!, parameters.string('artifactHandle'));
        addedBytes = await store.read(addedArtifact.handle);
        result = replace(
          state.catalog,
          assetId: parameters.string('assetId'),
          artifact: addedArtifact,
        );
      case 'asset.move':
        parameters.allow(const {'assetId', 'logicalPath'});
        result = move(
          state.catalog,
          assetId: parameters.string('assetId'),
          logicalPath: parameters.string('logicalPath'),
        );
      case 'asset.delete':
        parameters.allow(const {'assetId', 'acknowledgedUsages'});
        final current = state.catalog.require(parameters.string('assetId'));
        final derivedUsages = deriveAssetUsages(
          manifest: context.snapshot.manifest,
          maps: context.snapshot.maps,
          asset: current,
        );
        if (derivedUsages.isNotEmpty) {
          throw AssetActionException(
            'asset.references_blocking',
            'The asset is still referenced and cannot be deleted safely.',
            details: {'assetId': current.id, 'usages': derivedUsages},
          );
        }
        result = delete(
          state.catalog,
          assetId: current.id,
          blobBytes: context.snapshot.findResourceBytes(
            assetBlobResourceIdentity(current.artifact.digest),
          ),
          acknowledgedUsages: parameters.strings('acknowledgedUsages'),
        );
      default:
        throw AssetActionException(
          'asset.action_unsupported',
          'The requested asset action is unsupported.',
          details: {'actionId': context.request.actionId},
        );
    }
    return _draft(
      context.snapshot,
      state,
      result,
      addedArtifact: addedArtifact,
      addedBytes: addedBytes,
    );
  }

  AssetActionResult import(
    AssetCatalog catalog, {
    required AssetRecord record,
  }) =>
      const AssetImportProjector().project(catalog, record: record);

  AssetActionResult replace(
    AssetCatalog catalog, {
    required String assetId,
    required ContentArtifactRef artifact,
  }) {
    final before = catalog.require(assetId);
    final contentAddressedLogicalPath =
        before.logicalPath == assetBlobStorageKey(before.artifact);
    final after = before.copyWith(
      artifact: artifact,
      logicalPath: contentAddressedLogicalPath
          ? assetBlobStorageKey(artifact)
          : before.logicalPath,
    );
    if (before.artifact == artifact) {
      throw AssetActionException(
        'asset.no_change',
        'The replacement bytes are identical to the current asset.',
        details: {'assetId': assetId},
      );
    }
    return AssetActionResult(
      operation: 'replace',
      catalog: _replace(catalog, after),
      before: before,
      after: after,
      deduplicated: catalog.records.any(
        (record) =>
            record.id != assetId && record.artifact.digest == artifact.digest,
      ),
    );
  }

  AssetActionResult move(
    AssetCatalog catalog, {
    required String assetId,
    required String logicalPath,
  }) {
    final before = catalog.require(assetId);
    final after = before.copyWith(logicalPath: logicalPath);
    if (before.logicalPath == after.logicalPath) {
      throw AssetActionException(
        'asset.no_change',
        'The requested asset path is already current.',
        details: {'assetId': assetId},
      );
    }
    return AssetActionResult(
      operation: 'move',
      catalog: _replace(catalog, after),
      before: before,
      after: after,
    );
  }

  AssetActionResult delete(
    AssetCatalog catalog, {
    required String assetId,
    List<int>? blobBytes,
    Iterable<String> acknowledgedUsages = const [],
  }) {
    final before = catalog.require(assetId);
    final acknowledged = acknowledgedUsages.toSet();
    if (before.usages.toSet().difference(acknowledged).isNotEmpty ||
        acknowledged.difference(before.usages.toSet()).isNotEmpty) {
      throw AssetActionException(
        'asset.references_blocking',
        'The asset is still referenced and cannot be deleted safely.',
        details: {'assetId': assetId, 'usages': before.usages},
      );
    }
    final remaining =
        catalog.records.where((record) => record.id != assetId).toList();
    final deletesBlob = !remaining.any(
      (record) => record.artifact.digest == before.artifact.digest,
    );
    if (deletesBlob && blobBytes == null) {
      throw AssetActionException(
        'asset.rollback_blob_required',
        'Deleting the last reference requires the exact blob pre-image.',
        details: {'assetId': assetId, 'digest': before.artifact.digest},
      );
    }
    if (blobBytes != null) {
      final actual = ContentArtifactRef.fromBytes(
        blobBytes,
        mediaType: before.artifact.mediaType,
      );
      if (actual.digest != before.artifact.digest ||
          actual.byteLength != before.artifact.byteLength) {
        throw AssetActionException(
          'asset.rollback_blob_mismatch',
          'The supplied rollback blob does not match the catalog artifact.',
          details: {'assetId': assetId},
        );
      }
    }
    return AssetActionResult(
      operation: 'delete',
      catalog: AssetCatalog(records: remaining),
      before: before,
      deletedBlob: deletesBlob,
      rollbackBlobBytes: deletesBlob ? blobBytes : null,
    );
  }
}

AuthoringMutationDraft _draft(
  ProjectSnapshot snapshot,
  _AssetCatalogState state,
  AssetActionResult result, {
  ContentArtifactRef? addedArtifact,
  List<int>? addedBytes,
}) {
  final changes = <AuthoringResourceChange>[];
  final diff = <AuthoringDiffEntry>[];
  final catalogRef = AuthoringResourceRef(
    kind: 'assetCatalog',
    id: 'project',
    revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
  );
  changes.add(
    AuthoringResourceChange(
      resource: catalogRef,
      storageKey: assetCatalogStorageKey,
      beforeBytes: state.bytes,
      afterBytes: _encodeCatalog(result.catalog),
    ),
  );
  diff.add(
    AuthoringDiffEntry(
      operation: switch (result.operation) {
        'import' => AuthoringDiffOperation.add,
        'delete' => AuthoringDiffOperation.remove,
        'move' => AuthoringDiffOperation.move,
        _ => AuthoringDiffOperation.replace,
      },
      resource: catalogRef,
      path: '/records/${result.after?.id ?? result.before?.id}',
      before: result.before?.toJson(),
      after: result.after?.toJson(),
    ),
  );
  final beforeRecord = result.before;
  final afterRecord = result.after;
  final beforeLogicalBytes = beforeRecord == null
      ? null
      : snapshot.findResourceBytes(
          assetBlobResourceIdentity(beforeRecord.artifact.digest),
        );
  switch (result.operation) {
    case 'import':
      _addLogicalAssetChange(
        changes: changes,
        diff: diff,
        record: afterRecord!,
        beforeBytes: null,
        afterBytes: addedBytes!,
        beforeArtifact: null,
        afterArtifact: afterRecord.artifact,
        operation: AuthoringDiffOperation.add,
      );
    case 'replace':
      _addLogicalAssetChange(
        changes: changes,
        diff: diff,
        record: afterRecord!,
        beforeBytes: beforeLogicalBytes,
        afterBytes: addedBytes!,
        beforeArtifact: beforeRecord!.artifact,
        afterArtifact: afterRecord.artifact,
        operation: AuthoringDiffOperation.replace,
      );
    case 'move':
      _addLogicalAssetChange(
        changes: changes,
        diff: diff,
        record: beforeRecord!,
        resourceId: '${beforeRecord.id}:source',
        beforeBytes: beforeLogicalBytes,
        afterBytes: null,
        beforeArtifact: beforeRecord.artifact,
        afterArtifact: null,
        operation: AuthoringDiffOperation.remove,
      );
      _addLogicalAssetChange(
        changes: changes,
        diff: diff,
        record: afterRecord!,
        resourceId: '${afterRecord.id}:target',
        beforeBytes: null,
        afterBytes: beforeLogicalBytes,
        beforeArtifact: null,
        afterArtifact: afterRecord.artifact,
        operation: AuthoringDiffOperation.add,
      );
    case 'delete':
      _addLogicalAssetChange(
        changes: changes,
        diff: diff,
        record: beforeRecord!,
        beforeBytes: beforeLogicalBytes,
        afterBytes: null,
        beforeArtifact: beforeRecord.artifact,
        afterArtifact: null,
        operation: AuthoringDiffOperation.remove,
      );
  }
  if (addedArtifact != null &&
      !state.catalog.records.any(
        (record) => record.artifact.digest == addedArtifact.digest,
      )) {
    final bytes = addedBytes!;
    final blobRef = AuthoringResourceRef(
      kind: 'assetBlob',
      id: addedArtifact.digest,
    );
    changes.add(
      AuthoringResourceChange(
        resource: blobRef,
        storageKey: assetBlobStorageKey(addedArtifact),
        beforeBytes: null,
        afterBytes: bytes,
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: blobRef,
        path: '/',
        after: addedArtifact.toJson(),
      ),
    );
  }
  if (result.deletedBlob) {
    final artifact = result.before!.artifact;
    final blobRef = AuthoringResourceRef(
      kind: 'assetBlob',
      id: artifact.digest,
      revision: snapshot
          .resourceFingerprints[assetBlobResourceIdentity(artifact.digest)],
    );
    changes.add(
      AuthoringResourceChange(
        resource: blobRef,
        storageKey: assetBlobStorageKey(artifact),
        beforeBytes: result.rollbackBlobBytes,
        afterBytes: null,
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.remove,
        resource: blobRef,
        path: '/',
        before: artifact.toJson(),
      ),
    );
  }
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diff),
    ),
    preview: result.toJson(),
    referenceImpact: {
      'assetId': result.after?.id ?? result.before?.id,
      'usages':
          result.before?.usages ?? result.after?.usages ?? const <String>[],
      'blobDeleted': result.deletedBlob,
    },
    artifacts: addedArtifact == null
        ? const []
        : [
            AuthoringArtifactRef(
              id: addedArtifact.digest,
              mediaType: addedArtifact.mediaType,
              uri: addedArtifact.handle,
              byteLength: addedArtifact.byteLength,
              sha256: addedArtifact.digest,
            ),
          ],
  );
}

void _addLogicalAssetChange({
  required List<AuthoringResourceChange> changes,
  required List<AuthoringDiffEntry> diff,
  required AssetRecord record,
  required List<int>? beforeBytes,
  required List<int>? afterBytes,
  required ContentArtifactRef? beforeArtifact,
  required ContentArtifactRef? afterArtifact,
  required AuthoringDiffOperation operation,
  String? resourceId,
}) {
  if (record.logicalPath == assetBlobStorageKey(record.artifact)) return;
  final resource = AuthoringResourceRef(
    kind: 'asset',
    id: resourceId ?? record.id,
  );
  changes.add(
    AuthoringResourceChange(
      resource: resource,
      storageKey: record.logicalPath,
      beforeBytes: beforeBytes,
      afterBytes: afterBytes,
    ),
  );
  diff.add(
    AuthoringDiffEntry(
      operation: operation,
      resource: resource,
      path: '/',
      before: beforeArtifact?.toJson(),
      after: afterArtifact?.toJson(),
    ),
  );
}

Future<AuthoringMutationDraft> _rawReplacementDraft(
  _AssetCatalogState state, {
  required String logicalPath,
  required ContentArtifactRef expectedArtifact,
  required ContentArtifactRef replacementArtifact,
  required ArtifactStore artifactStore,
}) async {
  final managed = state.catalog.records
      .where((record) => record.logicalPath == logicalPath)
      .firstOrNull;
  if (managed != null) {
    throw AssetActionException(
      'asset.raw.managed_path',
      'This path is catalog-managed and must be changed with asset.replace.',
      details: {'logicalPath': logicalPath, 'assetId': managed.id},
    );
  }
  if (expectedArtifact.digest == replacementArtifact.digest) {
    throw AssetActionException(
      'asset.no_change',
      'The replacement bytes are identical to the expected current asset.',
      details: {'logicalPath': logicalPath},
    );
  }
  if (expectedArtifact.mediaType != replacementArtifact.mediaType) {
    throw AssetActionException(
      'asset.raw.media_type_mismatch',
      'Raw replacement must preserve the inspected asset media type.',
      details: {
        'logicalPath': logicalPath,
        'expectedMediaType': expectedArtifact.mediaType,
        'replacementMediaType': replacementArtifact.mediaType,
      },
    );
  }
  final beforeBytes = await artifactStore.read(expectedArtifact.handle);
  final afterBytes = await artifactStore.read(replacementArtifact.handle);
  final resource = AuthoringResourceRef(
    kind: 'asset',
    id: 'raw:$logicalPath',
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: resource,
          storageKey: logicalPath,
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.replace,
          resource: resource,
          path: '/',
          before: expectedArtifact.toJson(),
          after: replacementArtifact.toJson(),
        ),
      ]),
    ),
    preview: {
      'operation': 'rawReplace',
      'logicalPath': logicalPath,
      'before': expectedArtifact.toJson(),
      'after': replacementArtifact.toJson(),
    },
    referenceImpact: {
      'logicalPath': logicalPath,
      'catalogManaged': false,
    },
    artifacts: [
      AuthoringArtifactRef(
        id: replacementArtifact.digest,
        mediaType: replacementArtifact.mediaType,
        uri: replacementArtifact.handle,
        byteLength: replacementArtifact.byteLength,
        sha256: replacementArtifact.digest,
      ),
    ],
  );
}

_AssetCatalogState _catalogState(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return _AssetCatalogState(AssetCatalog(), null);
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return _AssetCatalogState(
      AssetCatalog.fromJson(Map<String, dynamic>.from(decoded)),
      bytes,
    );
  } on Object {
    throw AssetActionException(
      'asset.catalog_invalid',
      'The current project asset catalog is invalid.',
    );
  }
}

List<int> _encodeCatalog(AssetCatalog catalog) => List<int>.unmodifiable(
      utf8.encode(
          '${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n'),
    );

ContentArtifactRef _requireArtifact(ArtifactStore store, String handle) {
  final artifact = store.inspect(handle);
  if (artifact == null) {
    throw AssetActionException(
      'artifact.unknown',
      'The artifact handle is unknown or expired.',
      details: {'artifactHandle': handle},
    );
  }
  return artifact;
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  AuthoringRiskLevel riskLevel, {
  List<String> resourceKinds = const ['assetCatalog', 'assetBlob', 'asset'],
}) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring.$id.input.v1',
    outputSchemaId: 'pokemap.authoring.asset.mutation.v1',
    riskLevel: riskLevel,
    resourceKinds: resourceKinds,
    capabilityIds: const ['authoring.assets'],
    requiredPermissions: const [
      AuthoringPermission.assetWrite,
      AuthoringPermission.projectWrite,
    ],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
  );
}

String _rawAssetLogicalPath(String value) {
  final segments = value.split('/');
  final extension = segments.last.toLowerCase();
  final isAssetRoot = segments.first == 'assets' || segments.first == 'data';
  final invalid = segments.length < 2 ||
      !isAssetRoot ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            segment.startsWith('.'),
      ) ||
      value.contains(r'\') ||
      extension.endsWith('.json');
  if (invalid) {
    throw AssetActionException(
      'asset.raw.path_forbidden',
      'Raw replacement accepts only non-JSON files below assets/ or data/.',
      details: {'logicalPath': value},
    );
  }
  return value;
}

final class _AssetCatalogState {
  const _AssetCatalogState(this.catalog, this.bytes);

  final AssetCatalog catalog;
  final List<int>? bytes;
}

final class _AssetParameters {
  _AssetParameters(Map<String, Object?> values) : _values = values;

  final Map<String, Object?> _values;

  void allow(Set<String> allowed) {
    final unknown = _values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw AssetActionException(
        'asset.parameters_unknown',
        'The request contains unsupported asset parameters.',
        details: {'parameters': unknown},
      );
    }
  }

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw AssetActionException(
        'asset.parameter_invalid',
        'A required asset parameter is invalid.',
        details: {'parameter': key},
      );
    }
    return value;
  }

  List<String> strings(String key) {
    final value = _values[key];
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw AssetActionException(
        'asset.parameter_invalid',
        'An asset list parameter is invalid.',
        details: {'parameter': key},
      );
    }
    return value.cast<String>();
  }
}

AssetCatalog _replace(AssetCatalog catalog, AssetRecord replacement) {
  return AssetCatalog(
    records: [
      for (final record in catalog.records)
        if (record.id == replacement.id) replacement else record,
    ],
  );
}
