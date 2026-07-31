# PMCP-040 — Annexe des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `packages/map_authoring/lib/src/contracts/artifact_ref.dart`

```dart
import 'json_contract_support.dart';
import '../support/authoring_fingerprint.dart';

/// Path-free identity for bytes staged before a project mutation is planned.
///
/// The digest is the authority. File names and source paths are deliberately
/// absent so API and future MCP clients cannot turn an artifact handle into an
/// ambient filesystem capability.
final class ContentArtifactRef {
  ContentArtifactRef({
    required String digest,
    required String mediaType,
    required int byteLength,
  })  : digest = _digest(digest),
        mediaType = _mediaType(mediaType),
        byteLength = _byteLength(byteLength),
        handle = _handleForDigest(_digest(digest));

  factory ContentArtifactRef.fromBytes(
    List<int> bytes, {
    required String mediaType,
  }) {
    _validateBytes(bytes);
    return ContentArtifactRef(
      // The authoring fingerprint uses SHA-256 with a stable domain frame. It
      // remains content-addressed while avoiding a second crypto dependency.
      digest: computeAuthoringBytesFingerprint(
        bytes,
        logicalName: 'artifact-content',
      ),
      mediaType: mediaType,
      byteLength: bytes.length,
    );
  }

  factory ContentArtifactRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
      json,
      const {'digest', 'handle', 'mediaType', 'byteLength'},
    );
    final rawLength = json['byteLength'];
    if (rawLength is! int) {
      throw const FormatException('byteLength must be an integer');
    }
    try {
      final reference = ContentArtifactRef(
        digest: requireContractString(json['digest'], 'digest'),
        mediaType: requireContractString(json['mediaType'], 'mediaType'),
        byteLength: rawLength,
      );
      if (json['handle'] != reference.handle) {
        throw const FormatException('handle must match digest');
      }
      return reference;
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String digest;
  final String handle;
  final String mediaType;
  final int byteLength;

  String get hexDigest => digest.substring('sha256:'.length);

  Map<String, Object?> toJson() => {
        'digest': digest,
        'handle': handle,
        'mediaType': mediaType,
        'byteLength': byteLength,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentArtifactRef &&
          other.digest == digest &&
          other.mediaType == mediaType &&
          other.byteLength == byteLength;

  @override
  int get hashCode => Object.hash(digest, mediaType, byteLength);
}

String _digest(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'digest',
      'must be a lowercase SHA-256 digest',
    );
  }
  return value;
}

String _mediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
          .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'mediaType', 'must be a stable MIME type');
  }
  return normalized;
}

int _byteLength(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'byteLength', 'must not be negative');
  }
  return value;
}

String _handleForDigest(String digest) =>
    'artifact://sha256/${digest.substring('sha256:'.length)}';

void _validateBytes(List<int> bytes) {
  if (bytes.any((byte) => byte < 0 || byte > 255)) {
    throw ArgumentError.value(bytes, 'bytes', 'must contain bytes');
  }
}
```

## `packages/map_authoring/lib/src/domains/assets/asset_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/assets/asset_store.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/artifact_ref.dart';
import '../../contracts/json_contract_support.dart';
import '../../ports/project_file_reader.dart';

const String assetCatalogStorageKey = 'assets/.pokemap-assets.json';
const String assetCatalogResourceIdentity = 'assetCatalog';

String assetBlobResourceIdentity(String digest) => 'assetBlob:$digest';

String assetBlobStorageKey(ContentArtifactRef artifact) =>
    'assets/.pokemap-store/${artifact.hexDigest}.blob';

/// Computes references from canonical project/map payloads instead of trusting
/// a caller-provided usage list. Stable owner/path strings are sufficient for
/// delete preflight without leaking storage paths outside the package.
List<String> deriveAssetUsages({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
  required AssetRecord asset,
}) {
  final needles = {
    asset.id,
    asset.logicalPath,
    asset.artifact.handle,
    asset.artifact.digest,
  };
  final usages = <String>{};
  _collectAssetUsages(
    manifest.toJson(),
    owner: 'project',
    path: r'$',
    needles: needles,
    output: usages,
  );
  for (final map in maps) {
    _collectAssetUsages(
      map.toJson(),
      owner: 'map:${map.id}',
      path: r'$',
      needles: needles,
      output: usages,
    );
  }
  return List.unmodifiable(usages.toList()..sort());
}

final class AssetRecord {
  AssetRecord({
    required String id,
    required String logicalPath,
    required this.artifact,
    Iterable<String> usages = const [],
    Iterable<String> tags = const [],
  })  : id = _identity(id, 'id'),
        logicalPath = _logicalPath(logicalPath),
        usages = normalizedContractStrings(usages, 'usages'),
        tags = normalizedContractStrings(tags, 'tags');

  factory AssetRecord.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
      json,
      const {'id', 'logicalPath', 'artifact', 'usages', 'tags'},
    );
    final rawArtifact = json['artifact'];
    if (rawArtifact is! Map) {
      throw const FormatException('artifact must be a JSON object');
    }
    try {
      return AssetRecord(
        id: requireContractString(json['id'], 'id'),
        logicalPath: requireContractString(json['logicalPath'], 'logicalPath'),
        artifact: ContentArtifactRef.fromJson(
          Map<String, dynamic>.from(rawArtifact),
        ),
        usages: readContractStringList(json['usages'], 'usages'),
        tags: readContractStringList(json['tags'], 'tags'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final String logicalPath;
  final ContentArtifactRef artifact;
  final List<String> usages;
  final List<String> tags;

  AssetRecord copyWith({
    String? logicalPath,
    ContentArtifactRef? artifact,
    Iterable<String>? usages,
    Iterable<String>? tags,
  }) =>
      AssetRecord(
        id: id,
        logicalPath: logicalPath ?? this.logicalPath,
        artifact: artifact ?? this.artifact,
        usages: usages ?? this.usages,
        tags: tags ?? this.tags,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'logicalPath': logicalPath,
        'artifact': artifact.toJson(),
        'usages': usages,
        'tags': tags,
      };
}

/// Deterministically ordered project asset registry.
final class AssetCatalog {
  AssetCatalog({Iterable<AssetRecord> records = const []})
      : records = _validatedRecords(records) {
    _byId = Map.unmodifiable(
        {for (final record in this.records) record.id: record});
  }

  factory AssetCatalog.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, const {'schemaVersion', 'records'});
    if (json['schemaVersion'] != 1 || json['records'] is! List) {
      throw const FormatException('Unsupported asset catalog document');
    }
    return AssetCatalog(
      records: (json['records']! as List).map((raw) {
        if (raw is! Map) {
          throw const FormatException('record must be an object');
        }
        return AssetRecord.fromJson(Map<String, dynamic>.from(raw));
      }),
    );
  }

  final List<AssetRecord> records;
  late final Map<String, AssetRecord> _byId;

  AssetRecord? find(String id) => _byId[id];

  AssetRecord require(String id) =>
      find(id) ??
      (throw AssetCatalogException(
        'asset.unknown',
        'The asset identity is unknown.',
        details: {'assetId': id},
      ));

  List<AssetRecord> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return records;
    return List.unmodifiable(records.where((record) {
      return record.id.toLowerCase().contains(needle) ||
          record.logicalPath.toLowerCase().contains(needle) ||
          record.artifact.mediaType.contains(needle) ||
          record.tags.any((tag) => tag.toLowerCase().contains(needle));
    }));
  }

  List<AssetRecord> unused() =>
      List.unmodifiable(records.where((record) => record.usages.isEmpty));

  List<List<AssetRecord>> duplicateGroups() {
    final groups = <String, List<AssetRecord>>{};
    for (final record in records) {
      groups.putIfAbsent(record.artifact.digest, () => []).add(record);
    }
    final duplicates = groups.values.where((group) => group.length > 1).toList()
      ..sort((left, right) => left.first.id.compareTo(right.first.id));
    return List.unmodifiable([
      for (final group in duplicates) List<AssetRecord>.unmodifiable(group),
    ]);
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'records': [for (final record in records) record.toJson()],
      };
}

final class AssetCatalogException implements Exception {
  AssetCatalogException(
    this.code,
    this.message, {
    Map<String, Object?> details = const {},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'AssetCatalogException($code): $message';
}

List<AssetRecord> _validatedRecords(Iterable<AssetRecord> values) {
  final records = values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final ids = <String>{};
  final paths = <String>{};
  for (final record in records) {
    if (!ids.add(record.id)) {
      throw AssetCatalogException(
        'asset.duplicate_id',
        'Asset identities must be unique.',
        details: {'assetId': record.id},
      );
    }
    if (!paths.add(record.logicalPath)) {
      throw AssetCatalogException(
        'asset.duplicate_path',
        'Asset logical paths must be unique.',
        details: {'logicalPath': record.logicalPath},
      );
    }
  }
  return List.unmodifiable(records);
}

String _identity(String value, String field) {
  final normalized = value.trim();
  if (normalized != value ||
      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable identity');
  }
  return normalized;
}

String _logicalPath(String value) {
  final segments = validateProjectRelativePath(value);
  final normalized = segments.join('/');
  if (normalized != value || segments.first == '.pokemap') {
    throw ArgumentError.value(
      value,
      'logicalPath',
      'must be a canonical project-relative path',
    );
  }
  return normalized;
}

void _collectAssetUsages(
  Object? value, {
  required String owner,
  required String path,
  required Set<String> needles,
  required Set<String> output,
}) {
  if (value is String) {
    if (needles.contains(value)) output.add('$owner:$path');
    return;
  }
  if (value is List) {
    for (var index = 0; index < value.length; index++) {
      _collectAssetUsages(
        value[index],
        owner: owner,
        path: '$path[$index]',
        needles: needles,
        output: output,
      );
    }
    return;
  }
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      _collectAssetUsages(
        value[key],
        owner: owner,
        path: '$path.$key',
        needles: needles,
        output: output,
      );
    }
  }
}
```

## `packages/map_authoring/lib/src/ports/artifact_store.dart`

```dart
import 'dart:io';

import '../contracts/artifact_ref.dart';
import 'project_file_reader.dart';

final class ArtifactStoreException implements Exception {
  const ArtifactStoreException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'ArtifactStoreException($code): $message';
}

final class StoredArtifact {
  const StoredArtifact({
    required this.reference,
    required this.deduplicated,
  });

  final ContentArtifactRef reference;
  final bool deduplicated;
}

/// Opaque byte staging boundary used before an asset mutation is planned.
abstract interface class ArtifactStore {
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  });

  ContentArtifactRef? inspect(String handle);

  Future<List<int>> read(String handle);

  Future<bool> release(String handle);

  List<ContentArtifactRef> list();
}

/// Deterministic in-memory store suitable for direct API clients and tests.
///
/// Production protocol adapters may replace it with a durable store while
/// keeping the same path-free handles and validation behavior.
final class MemoryArtifactStore implements ArtifactStore {
  MemoryArtifactStore({required this.maximumArtifactBytes}) {
    if (maximumArtifactBytes <= 0) {
      throw ArgumentError.value(
        maximumArtifactBytes,
        'maximumArtifactBytes',
        'must be positive',
      );
    }
  }

  final int maximumArtifactBytes;
  final Map<String, _ArtifactEntry> _entries = {};

  @override
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  }) async {
    if (bytes.length > maximumArtifactBytes) {
      throw const ArtifactStoreException(
        'artifact.too_large',
        'The artifact exceeds the configured byte limit.',
      );
    }
    if (bytes.any((byte) => byte < 0 || byte > 255)) {
      throw const ArtifactStoreException(
        'artifact.bytes_invalid',
        'The artifact payload contains invalid bytes.',
      );
    }
    final mediaType = sniffArtifactMediaType(bytes);
    final declared = declaredMediaType?.trim().toLowerCase();
    if (declared != null &&
        declared.isNotEmpty &&
        mediaType != 'application/octet-stream' &&
        declared != mediaType) {
      throw const ArtifactStoreException(
        'artifact.mime_mismatch',
        'The declared media type conflicts with the inspected bytes.',
      );
    }
    final reference = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: mediaType == 'application/octet-stream' &&
              declared != null &&
              declared.isNotEmpty
          ? declared
          : mediaType,
    );
    final existing = _entries[reference.handle];
    if (existing != null) {
      existing.retainCount++;
      return StoredArtifact(reference: existing.reference, deduplicated: true);
    }
    _entries[reference.handle] = _ArtifactEntry(
      reference: reference,
      bytes: List<int>.unmodifiable(bytes),
    );
    return StoredArtifact(reference: reference, deduplicated: false);
  }

  @override
  ContentArtifactRef? inspect(String handle) => _entries[handle]?.reference;

  @override
  Future<List<int>> read(String handle) async {
    final entry = _entries[handle];
    if (entry == null) {
      throw const ArtifactStoreException(
        'artifact.unknown',
        'The artifact handle is unknown or has expired.',
      );
    }
    return List<int>.unmodifiable(entry.bytes);
  }

  @override
  Future<bool> release(String handle) async {
    final entry = _entries[handle];
    if (entry == null) return false;
    entry.retainCount--;
    if (entry.retainCount <= 0) _entries.remove(handle);
    return true;
  }

  @override
  List<ContentArtifactRef> list() => List.unmodifiable(
        _entries.values.map((entry) => entry.reference).toList()
          ..sort((left, right) => left.handle.compareTo(right.handle)),
      );
}

/// Filesystem acquisition adapter that rejects traversal and escaping links
/// before delegating bytes to the same content-addressed store.
final class LocalArtifactStore implements ArtifactStore {
  LocalArtifactStore({
    required Iterable<String> allowedSourceRoots,
    required int maximumArtifactBytes,
  })  : _allowedSourceRoots = List.unmodifiable(allowedSourceRoots),
        _memory = MemoryArtifactStore(
          maximumArtifactBytes: maximumArtifactBytes,
        ) {
    if (_allowedSourceRoots.isEmpty ||
        _allowedSourceRoots.any((root) => root.trim().isEmpty)) {
      throw ArgumentError.value(
        allowedSourceRoots,
        'allowedSourceRoots',
        'must contain at least one nonblank directory',
      );
    }
  }

  final List<String> _allowedSourceRoots;
  final MemoryArtifactStore _memory;

  Future<StoredArtifact> importFile(
    String sourcePath, {
    String? declaredMediaType,
  }) async {
    final source = File(sourcePath);
    late final String resolvedSource;
    try {
      resolvedSource = await source.resolveSymbolicLinks();
    } on FileSystemException {
      throw const ArtifactStoreException(
        'artifact.source_unavailable',
        'The artifact source is unavailable.',
      );
    }
    final roots = <String>[];
    for (final root in _allowedSourceRoots) {
      try {
        roots.add(await Directory(root).resolveSymbolicLinks());
      } on FileSystemException {
        throw const ArtifactStoreException(
          'artifact.source_root_unavailable',
          'An allowed artifact source root is unavailable.',
        );
      }
    }
    if (!roots.any(
      (root) => workspacePathIsWithin(root: root, candidate: resolvedSource),
    )) {
      throw const ArtifactStoreException(
        'artifact.source_outside_allowed_roots',
        'The artifact source resolves outside the allowed roots.',
      );
    }
    final before = await File(resolvedSource).stat();
    if (before.type != FileSystemEntityType.file) {
      throw const ArtifactStoreException(
        'artifact.source_not_regular',
        'The artifact source must be a regular file.',
      );
    }
    if (before.size > _memory.maximumArtifactBytes) {
      throw const ArtifactStoreException(
        'artifact.too_large',
        'The artifact exceeds the configured byte limit.',
      );
    }
    final bytes = await File(resolvedSource).readAsBytes();
    final after = await File(resolvedSource).stat();
    if (before.modified != after.modified || before.size != after.size) {
      throw const ArtifactStoreException(
        'artifact.source_changed_during_read',
        'The artifact source changed while it was inspected.',
      );
    }
    return _memory.put(bytes, declaredMediaType: declaredMediaType);
  }

  @override
  Future<StoredArtifact> put(
    List<int> bytes, {
    String? declaredMediaType,
  }) =>
      _memory.put(bytes, declaredMediaType: declaredMediaType);

  @override
  ContentArtifactRef? inspect(String handle) => _memory.inspect(handle);

  @override
  Future<List<int>> read(String handle) => _memory.read(handle);

  @override
  Future<bool> release(String handle) => _memory.release(handle);

  @override
  List<ContentArtifactRef> list() => _memory.list();
}

String sniffArtifactMediaType(List<int> bytes) {
  if (_startsWith(
      bytes, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
    return 'image/png';
  }
  if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return 'image/jpeg';
  if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
  if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
      bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  if (_startsWith(bytes, const [0x4f, 0x67, 0x67, 0x53])) return 'audio/ogg';
  if (_startsWith(bytes, const [0x49, 0x44, 0x33]) ||
      (bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0)) {
    return 'audio/mpeg';
  }
  if (_startsWith(bytes, const [0x00, 0x01, 0x00, 0x00]) ||
      _startsWith(bytes, const [0x4f, 0x54, 0x54, 0x4f])) {
    return 'font/ttf';
  }
  if (bytes.isNotEmpty && bytes.every(_isTextByte)) return 'text/plain';
  return 'application/octet-stream';
}

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

bool _isTextByte(int byte) =>
    byte == 0x09 ||
    byte == 0x0a ||
    byte == 0x0d ||
    (byte >= 0x20 && byte <= 0x7e);

final class _ArtifactEntry {
  _ArtifactEntry({required this.reference, required this.bytes});

  final ContentArtifactRef reference;
  final List<int> bytes;
  int retainCount = 1;
}
```

## `packages/map_authoring/test/domains/assets/asset_security_test.dart`

```dart
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('LocalArtifactStore security', () {
    late Directory sandbox;
    late Directory allowed;

    setUp(() async {
      sandbox =
          await Directory.systemTemp.createTemp('pokemap_asset_security_');
      allowed = await Directory('${sandbox.path}/allowed').create();
    });

    tearDown(() async {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    });

    test('rejects a source symlink that resolves outside the allowed roots',
        () async {
      final outside = File('${sandbox.path}/outside.png');
      await outside.writeAsBytes(_pngBytes);
      final link = Link('${allowed.path}/escape.png');
      await link.create(outside.path);
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 1024,
      );

      await expectLater(
        store.importFile(link.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.source_outside_allowed_roots',
          ),
        ),
      );
    });

    test('rejects an oversized source before retaining its bytes', () async {
      final source = File('${allowed.path}/large.bin');
      await source.writeAsBytes(List<int>.filled(9, 1));
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 8,
      );

      await expectLater(
        store.importFile(source.path),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.too_large',
          ),
        ),
      );
      expect(store.list(), isEmpty);
    });

    test('uses sniffed MIME and rejects a conflicting declared type', () async {
      final source = File('${allowed.path}/sprite.png');
      await source.writeAsBytes(_pngBytes);
      final store = LocalArtifactStore(
        allowedSourceRoots: [allowed.path],
        maximumArtifactBytes: 1024,
      );

      await expectLater(
        store.importFile(source.path, declaredMediaType: 'audio/mpeg'),
        throwsA(
          isA<ArtifactStoreException>().having(
            (error) => error.code,
            'code',
            'artifact.mime_mismatch',
          ),
        ),
      );
    });
  });
}

const List<int> _pngBytes = [
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
];
```

## `packages/map_authoring/test/domains/assets/content_addressing_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('content-addressed artifact store', () {
    test('deduplicates identical bytes and round-trips the public reference',
        () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);

      final first = await store.put(
        utf8.encode('same payload'),
        declaredMediaType: 'text/plain',
      );
      final second = await store.put(
        utf8.encode('same payload'),
        declaredMediaType: 'text/plain',
      );

      expect(second.reference, first.reference);
      expect(second.deduplicated, isTrue);
      expect(store.list(), hasLength(1));
      expect(
        ContentArtifactRef.fromJson(first.reference.toJson()),
        first.reference,
      );
    });

    test('canonical plan/apply/delete/undo restores the exact blob', () async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_asset_transaction_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final manifest = ProjectManifest(
        name: 'Asset transaction fixture',
        maps: const [],
        tilesets: const [],
      );
      await File('${directory.path}/project.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      );
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final openService = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      );
      final snapshotLoader = ProjectSnapshotLoader(handles: handles);
      final opened = await openService.openProject(directory.path);
      final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await artifacts.put(
        utf8.encode('transactional asset bytes'),
        declaredMediaType: 'text/plain',
      );
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshotLoader,
        artifactStore: artifacts,
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );

      final importPlan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-asset-import',
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'artifactHandle': staged.reference.handle,
            'assetId': 'dialogue-portrait',
            'logicalPath': 'images/dialogue/portrait.txt',
          },
          expectedRevision: opened.fingerprint,
          idempotencyKey: 'idem-asset-import',
        ),
      );
      final importResult = await api.apply(
        opened.projectHandle,
        planId: importPlan['planId']! as String,
        operationId: 'op-asset-import',
      );
      final importedRevision = importResult['snapshotRevision']! as String;
      final blob = File(
        '${directory.path}/${assetBlobStorageKey(staged.reference)}',
      );
      expect(
          await blob.readAsBytes(), utf8.encode('transactional asset bytes'));
      final assetPage = const ProjectQueryService().query(
        await snapshotLoader.load(opened.projectHandle),
        AuthoringQueryRequest(
          resourceKind: 'asset',
          operation: AuthoringQueryOperation.search,
          view: AuthoringQueryView.detail,
          searchTerm: 'portrait',
        ),
      );
      expect(assetPage.totalAvailable, 1);
      expect(assetPage.items.single['id'], 'dialogue-portrait');
      expect(
        (assetPage.items.single['preview']! as Map)['artifactHandle'],
        staged.reference.handle,
      );

      final deletePlan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-asset-delete',
          actionId: 'asset.delete',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {'assetId': 'dialogue-portrait'},
          expectedRevision: importedRevision,
          idempotencyKey: 'idem-asset-delete',
        ),
      );
      final confirmation = await api.confirm(
        opened.projectHandle,
        planId: deletePlan['planId']! as String,
      );
      final deleteResult = await api.apply(
        opened.projectHandle,
        planId: deletePlan['planId']! as String,
        operationId: 'op-asset-delete',
        confirmationToken: confirmation['confirmationToken']! as String,
      );
      expect(await blob.exists(), isFalse);
      final receipt = Map<String, Object?>.from(
        deleteResult['receipt']! as Map,
      );

      await api.undo(
        opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem-asset-delete-undo',
      );
      expect(
          await blob.readAsBytes(), utf8.encode('transactional asset bytes'));
    });

    test('catalog search is deterministic and reports unused assets', () {
      final used = _record('used', 'images/used.png', usages: ['map:town']);
      final unused = _record('unused', 'images/unused.png');
      final catalog = AssetCatalog(records: [unused, used]);

      expect(
        catalog.search('IMAGE').map((record) => record.id),
        ['unused', 'used'],
      );
      expect(catalog.unused().map((record) => record.id), ['unused']);
      expect(
        AssetCatalog.fromJson(catalog.toJson()).toJson(),
        catalog.toJson(),
      );
    });

    test('delete planning refuses references and exposes their impact', () {
      final catalog = AssetCatalog(
        records: [
          _record('hero', 'characters/hero.png', usages: ['map:town']),
        ],
      );

      expect(
        () => const AssetActions().delete(
          catalog,
          assetId: 'hero',
        ),
        throwsA(
          isA<AssetActionException>()
              .having(
            (error) => error.code,
            'code',
            'asset.references_blocking',
          )
              .having(
            (error) => error.details['usages'],
            'usages',
            ['map:town'],
          ),
        ),
      );
    });

    test('delete plan retains exact bytes needed by undo', () {
      final bytes = utf8.encode('exact blob');
      final record = AssetRecord(
        id: 'unused',
        logicalPath: 'images/unused.bin',
        artifact: ContentArtifactRef.fromBytes(
          bytes,
          mediaType: 'application/octet-stream',
        ),
      );
      final result = const AssetActions().delete(
        AssetCatalog(records: [record]),
        assetId: 'unused',
        blobBytes: bytes,
      );

      expect(result.catalog.records, isEmpty);
      expect(result.rollbackBlobBytes, bytes);
      expect(result.deletedBlob, isTrue);
    });
  });
}

AssetRecord _record(
  String id,
  String logicalPath, {
  List<String> usages = const [],
}) {
  return AssetRecord(
    id: id,
    logicalPath: logicalPath,
    artifact: ContentArtifactRef.fromBytes(
      utf8.encode(id),
      mediaType: 'application/octet-stream',
    ),
    usages: usages,
  );
}
```

## `packages/map_authoring/tool/generate_evidence_appendix.dart`

```dart
import 'dart:io';

/// Deterministically reproduces created text files in a Markdown Evidence Pack.
///
/// Reports intentionally exclude themselves to avoid recursive content. This
/// tool is kept in the package because every PMCP lot has the same auditable
/// full-content requirement.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'Usage: dart run tool/generate_evidence_appendix.dart '
      '<output.md> <title> <input> [input ...]',
    );
    exitCode = 64;
    return;
  }
  final outputPath = arguments[0];
  final title = arguments[1].trim();
  final inputPaths = arguments.sublist(2)..sort();
  if (title.isEmpty || inputPaths.contains(outputPath)) {
    stderr.writeln('Title must be nonblank and output cannot be an input.');
    exitCode = 64;
    return;
  }
  final buffer = StringBuffer()
    ..writeln('# $title')
    ..writeln()
    ..writeln(
      'Cette annexe reproduit intégralement les fichiers texte créés par le lot.',
    )
    ..writeln();
  for (var index = 0; index < inputPaths.length; index++) {
    final inputPath = inputPaths[index];
    final file = File(inputPath);
    if (!await file.exists()) {
      stderr.writeln('Missing input: $inputPath');
      exitCode = 66;
      return;
    }
    final content = await file.readAsString();
    final fence = _fenceFor(inputPath);
    buffer
      ..writeln('## `$inputPath`')
      ..writeln()
      ..writeln('```$fence')
      ..write(content);
    if (!content.endsWith('\n')) buffer.writeln();
    buffer.writeln('```');
    if (index < inputPaths.length - 1) buffer.writeln();
  }
  await File(outputPath).writeAsString(buffer.toString(), flush: true);
}

String _fenceFor(String path) {
  if (path.endsWith('.dart')) return 'dart';
  if (path.endsWith('.json') || path.endsWith('.jsonl')) return 'json';
  if (path.endsWith('.yaml') || path.endsWith('.yml')) return 'yaml';
  if (path.endsWith('.md')) return 'markdown';
  return 'text';
}
```

## `pokemap_authoring_api_mcp_phase_5_implementation_plan.md`

```markdown
# PokeMap Authoring API — Phase 5 Implementation Plan

> Phase: **5 — Contenu du jeu**
> Lots: **PMCP-040 → PMCP-063**
> Execution: current branch, one verified commit per lot, no push
> Initial Git state: clean at `b44cc91ba feat(authoring): add world graph and map rendering`

## Goal and exit contract

Phase 5 extends the protocol-neutral Authoring API from maps to the content
needed by a playable fangame. Existing `map_core`, `map_gameplay`,
`map_battle`, editor, and runtime rules remain authoritative; the new package
provides typed façades, safe plans, capability truth, and adapter seams without
copying engine logic into `map_authoring`.

The phase is complete only when fresh evidence proves:

- imported assets are content-addressed, MIME-inspected, bounded, reference
  aware, recoverable, and path-safe;
- tilesets, palettes, elements, and semantic presets expose strict contracts
  with atlas, grid, dependency, and map-consumption preflights;
- presentation media, typography, licences, glyphs, contrast, and long-running
  processing expose honest diagnostics and artifact/job handles;
- legacy dialogue/script content and modern Scene/Event/Facts/World Rules are
  authorable through existing pure operations and runtime capability truth;
- Storyline/Scenario migration and cinematic timelines retain identities,
  references, revisions, preflight limitations, and legacy readability;
- Pokémon species, moves, abilities, items, trainers, encounters, shops,
  badges, New Game, saves, player state, battles, and progression are covered
  by typed authoring/sandbox façades;
- gameplay simulations delegate to `map_battle`/`map_gameplay`, use explicit
  seeds and decisions, and never modify a production save;
- every PMCP lot has a positive, negative, guard, and non-regression proof,
  package-scoped analysis/tests, a detailed Evidence Pack, and its own commit.

## Architecture decisions

- `map_authoring` remains pure Dart and depends on `map_core`; gameplay and
  battle behavior crosses explicit ports so package direction remains intact.
- Phase 5 contracts are immutable, JSON-safe, deterministic, path-free on the
  public side, and revision-aware where they produce mutations or previews.
- Existing pure authoring operations in `map_core` are adapted, never forked.
- Asset ingestion separates untrusted source acquisition from project mutation:
  an artifact is inspected and addressed first, then a frozen plan can refer to
  its opaque handle.
- Authoring actions over player state operate on an explicit sandbox copy.
  Production save repositories expose read/probe adapters only.
- A capability is `supported` only when a real runtime consumer is registered;
  syntactically authorable but unconsumed definitions remain `partial` or
  `blocked` with stable diagnostics.

## Verification and review passes

`codex_rule.md` requires independent viewpoints. For each stream, the work uses
these named passes (delegated when safe, local otherwise):

1. **Audit / Architecture** — existing contracts, package boundaries, reports,
   roadmap dependencies, and FG status;
2. **Implementation** — smallest production diff satisfying the lot contract;
3. **Tests** — mandatory RED/GREEN plus negative, guard, and non-regression;
4. **Build / Validation** — focused/full tests, analyzer, formatter, and the
   best package build alternative;
5. **Critique finale** — overclaim, accidental scope, runtime consumption,
   security, determinism, and Git inventory.

## Lot sequence and commits

### Phase 5A — Assets and libraries

- `PMCP-040`: content-addressed artifact/asset store, safe imports, reference
  impact, dedupe, rollback, and undo evidence.
  Commit: `feat(authoring): add secure asset store`
- `PMCP-041`: tilesets, palettes, elements, presets, atlas/grid validation,
  cross-map dependency preflight, and semantic-map compatibility.
  Commit: `feat(authoring): add visual library authoring`
- `PMCP-042`: presentation, video/audio/fonts, media validation, async process
  port, preview, and editor adapter characterization.
  Commit: `feat(authoring): add presentation authoring`

### Phase 5B — Narrative

- `PMCP-050`: dialogue/Yarn/script lifecycle, compile/simulate, outcome guards,
  and loss-aware legacy migration.
  Commit: `feat(authoring): add dialogue and script authoring`
- `PMCP-051`: Scene, Event V2, Facts, World Rules, dependency impact,
  reachability, publication gates, and runtime-consumer truth.
  Commit: `feat(authoring): add modern narrative authoring`
- `PMCP-052`: Storyline lifecycle/progression and planned Scenario migration
  with stable identities and legacy readability.
  Commit: `feat(authoring): add storyline and scenario authoring`
- `PMCP-053`: cinematic stage/timeline/preflight/preview and narrative parity
  gate across editor, API, and runtime.
  Commit: `feat(authoring): add cinematic authoring gate`

### Phase 5C — Game data and mechanics

- `PMCP-060`: generic catalogs, species/forms, learnsets/evolutions/media,
  explicit-network import preview, batch validation, and lossless round-trip.
  Commit: `feat(authoring): add pokemon catalog authoring`
- `PMCP-061`: moves/abilities/items and campaign trainers, encounters, shops,
  badges, characters, New Game, and runtime-support diagnostics.
  Commit: `feat(authoring): add campaign content authoring`
- `PMCP-062`: save inspection/migration/diff and sandbox-only party/PC/bag,
  shop/heal/PC service operations with production isolation.
  Commit: `feat(authoring): add sandbox player state authoring`
- `PMCP-063`: deterministic battle simulation, trace/outcome/write-back,
  progression decisions, rewards/capture, and runtime consumption proof.
  Commit: `feat(authoring): add battle progression authoring`

## Mechanics roadmap scope

Phase 5 consumes existing mechanics rather than silently closing unrelated
gameplay gaps. The relevant families are `FG-010–016`, `FG-020–030`,
`FG-040–053`, `FG-060–079`, `FG-080–094`, `FG-100–108`, `FG-120–129`, and
`FG-140–147`. Each lot Evidence Pack will state whether a touched FG item stays
`TODO`, `PARTIAL`, `BLOCKED`, or can merely be proposed `DONE`; this plan does
not edit the mechanics roadmap.

## Final phase validation

Run from each changed package, at minimum:

```bash
cd packages/map_authoring && dart test && dart analyze
cd packages/map_core && dart test && dart analyze
cd packages/map_gameplay && dart test && dart analyze
cd packages/map_battle && dart test && dart analyze
cd packages/map_runtime && flutter test && flutter analyze
cd packages/map_editor && flutter test && flutter analyze
```

Runtime smoke checks required by gameplay/battle changes:

```bash
cd packages/map_runtime && \
  flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && \
  flutter test test/phase_a_golden_slice_launch_test.dart
```

No roadmap status is changed without a separate explicit request. Every commit
must stage only its lot, pass `git diff --cached --check`, and leave unrelated
work untouched.
```
