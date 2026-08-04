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
        'asset.move', 'Move one logical asset path', AuthoringRiskLevel.low),
    _descriptor('asset.delete', 'Delete one unreferenced asset',
        AuthoringRiskLevel.high),
  ]);

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    final store = artifactStore;
    if (store == null &&
        const {'asset.import', 'asset.replace'}
            .contains(context.request.actionId)) {
      throw AssetActionException(
        'artifact.store_required',
        'Import and replace require an injected artifact store.',
      );
    }
    final state = _catalogState(context.snapshot);
    final parameters = _AssetParameters(context.request.parameters);
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
        parameters.allow(const {'assetId'});
        final current = state.catalog.require(parameters.string('assetId'));
        final derivedUsages = deriveAssetUsages(
          manifest: context.snapshot.manifest,
          maps: context.snapshot.maps,
          asset: current,
        );
        final before = current.copyWith(
          usages: {...current.usages, ...derivedUsages},
        );
        final catalogWithVerifiedUsages = _replace(state.catalog, before);
        result = delete(
          catalogWithVerifiedUsages,
          assetId: before.id,
          blobBytes: context.snapshot.findResourceBytes(
            assetBlobResourceIdentity(before.artifact.digest),
          ),
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
    final after = before.copyWith(artifact: artifact);
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
  }) {
    final before = catalog.require(assetId);
    if (before.usages.isNotEmpty) {
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
  AuthoringRiskLevel riskLevel,
) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring.$id.input.v1',
    outputSchemaId: 'pokemap.authoring.asset.mutation.v1',
    riskLevel: riskLevel,
    resourceKinds: const ['assetCatalog', 'assetBlob'],
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
