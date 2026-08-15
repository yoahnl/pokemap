import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/artifact_ref.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_receipt.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_actions.dart';
import 'asset_store.dart';
import 'project_media_store.dart';

enum PresentationMediaImportCheckpoint {
  beforeStagedBytesRead,
  afterStagedBytesRead,
  beforeProbe,
  afterProbe,
  beforeCatalogProjection,
  afterCatalogProjection,
}

typedef PresentationMediaImportFaultInjector = FutureOr<void> Function(
  PresentationMediaImportCheckpoint checkpoint,
);

final class PresentationMediaImportException implements Exception {
  PresentationMediaImportException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = Map<String, Object?>.unmodifiable(details);

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'PresentationMediaImportException($code): $message';
}

final class PresentationMediaImportActions {
  const PresentationMediaImportActions({
    required this.artifactStore,
    required this.probe,
    this.faultInjector,
  });

  final ArtifactStore artifactStore;
  final PresentationMediaProbePort probe;
  final PresentationMediaImportFaultInjector? faultInjector;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      AuthoringActionDescriptor(
        id: 'presentationMedia.import',
        version: 1,
        summary: 'Import one probed Presentation media atomically',
        inputSchemaId: 'pokemap.authoring.presentationMedia.import.input.v1',
        outputSchemaId: 'pokemap.authoring.presentationMedia.import.output.v1',
        riskLevel: AuthoringRiskLevel.medium,
        resourceKinds: const <String>['asset', 'presentationMedia'],
        capabilityIds: const <String>['authoring.presentation_media'],
        requiredPermissions: const <AuthoringPermission>[
          AuthoringPermission.projectWrite,
          AuthoringPermission.importRun,
        ],
        guarantees: const <AuthoringGuarantee>[
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable,
        ],
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(AuthoringPlanningContext context) async {
    if (context.request.actionId != 'presentationMedia.import') {
      throw PresentationMediaImportException(
        'presentation_media.action_unsupported',
        'The requested Presentation media action is unsupported.',
      );
    }
    final parameters = _PresentationMediaImportParameters(
      context.request.parameters,
    );
    final handle = parameters.string('artifactHandle');
    final artifact = artifactStore.inspect(handle);
    if (artifact == null) {
      throw const ArtifactStoreException(
        'artifact.unknown',
        'The artifact handle is unknown or has expired.',
      );
    }
    try {
      return await _buildStaged(context, parameters, handle, artifact);
    } on Object {
      await artifactStore.release(handle);
      rethrow;
    }
  }

  Future<AuthoringMutationDraft> _buildStaged(
    AuthoringPlanningContext context,
    _PresentationMediaImportParameters parameters,
    String handle,
    ContentArtifactRef artifact,
  ) async {
    await faultInjector?.call(
      PresentationMediaImportCheckpoint.beforeStagedBytesRead,
    );
    final bytes = await artifactStore.read(handle);
    await faultInjector?.call(
      PresentationMediaImportCheckpoint.afterStagedBytesRead,
    );
    final actual = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: artifact.mediaType,
    );
    if (actual.digest != artifact.digest ||
        actual.byteLength != artifact.byteLength) {
      throw PresentationMediaImportException(
        'presentation_media.staged_artifact_mismatch',
        'The staged bytes no longer match their content identity.',
        details: <String, Object?>{'artifactHandle': handle},
      );
    }
    await faultInjector?.call(PresentationMediaImportCheckpoint.beforeProbe);
    final inspected = probe.inspect(
      bytes,
      declaredMediaType: artifact.mediaType,
    );
    await faultInjector?.call(PresentationMediaImportCheckpoint.afterProbe);
    final kind = ProjectMediaKind.fromJson(parameters.string('kind'));
    _requireKindMatchesProbe(kind, inspected);
    await faultInjector?.call(
      PresentationMediaImportCheckpoint.beforeCatalogProjection,
    );
    final draft = _project(
      context.snapshot,
      bytes: bytes,
      artifact: artifact,
      asset: AssetRecord(
        id: parameters.string('assetId'),
        logicalPath: parameters.string('logicalPath'),
        artifact: artifact,
        tags: const <String>['presentation'],
      ),
      media: ProjectMediaAsset(
        id: parameters.string('mediaId'),
        label: parameters.string('label'),
        kind: kind,
        sourceAssetId: parameters.string('assetId'),
        technicalMetadata: inspected.toTechnicalMetadata(),
      ),
    );
    await faultInjector?.call(
      PresentationMediaImportCheckpoint.afterCatalogProjection,
    );
    if (context.request.dryRun) {
      await artifactStore.release(handle);
    }
    return draft;
  }
}

AuthoringMutationDraft _project(
  ProjectSnapshot snapshot, {
  required List<int> bytes,
  required ContentArtifactRef artifact,
  required AssetRecord asset,
  required ProjectMediaAsset media,
}) {
  final assetCatalogBeforeBytes = snapshot.findResourceBytes(
    assetCatalogResourceIdentity,
  );
  final assetCatalogBefore = _decodeAssetCatalog(assetCatalogBeforeBytes);
  final assetProjection = const AssetImportProjector().project(
    assetCatalogBefore,
    record: asset,
  );
  final mediaCatalogBeforeBytes = snapshot.findResourceBytes(
    projectMediaCatalogResourceIdentity,
  );
  final mediaCatalogBefore = mediaCatalogBeforeBytes == null
      ? ProjectMediaCatalog()
      : decodeProjectMediaCatalogBytes(mediaCatalogBeforeBytes);
  if (mediaCatalogBefore.find(media.id) != null) {
    throw PresentationMediaImportException(
      'presentation_media.id_conflict',
      'A Presentation media already owns this identity.',
      details: <String, Object?>{'mediaId': media.id},
    );
  }
  final mediaCatalogAfter = ProjectMediaCatalog(
    entries: <ProjectMediaAsset>[...mediaCatalogBefore.entries, media],
  );
  final changes = <AuthoringResourceChange>[
    AuthoringResourceChange(
      resource: AuthoringResourceRef(
        kind: 'assetCatalog',
        id: 'project',
        revision: snapshot.resourceFingerprints[assetCatalogResourceIdentity],
      ),
      storageKey: assetCatalogStorageKey,
      beforeBytes: assetCatalogBeforeBytes,
      afterBytes: _encodeAssetCatalog(assetProjection.catalog),
    ),
  ];
  final diff = <AuthoringDiffEntry>[
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: changes.single.resource,
      path: '/records/${asset.id}',
      after: asset.toJson(),
    ),
  ];

  final existingBlob = snapshot.findResourceBytes(
    assetBlobResourceIdentity(artifact.digest),
  );
  if (assetProjection.deduplicated) {
    _requireDeduplicatedBlob(artifact, bytes, existingBlob);
  } else {
    if (existingBlob != null) {
      throw AssetActionException(
        'asset.orphan_blob_conflict',
        'An unowned blob already occupies the imported artifact digest.',
        details: <String, Object?>{'digest': artifact.digest},
      );
    }
    final resource = AuthoringResourceRef(
      kind: 'assetBlob',
      id: artifact.digest,
    );
    changes.add(
      AuthoringResourceChange(
        resource: resource,
        storageKey: assetBlobStorageKey(artifact),
        beforeBytes: null,
        afterBytes: bytes,
      ),
    );
    diff.add(
      AuthoringDiffEntry(
        operation: AuthoringDiffOperation.add,
        resource: resource,
        path: '/',
        after: artifact.toJson(),
      ),
    );
  }

  final mediaResource = AuthoringResourceRef(
    kind: 'presentationMediaCatalog',
    id: 'project',
    revision:
        snapshot.resourceFingerprints[projectMediaCatalogResourceIdentity],
  );
  changes.add(
    AuthoringResourceChange(
      resource: mediaResource,
      storageKey: projectMediaCatalogStorageKey,
      beforeBytes: mediaCatalogBeforeBytes,
      afterBytes: encodeProjectMediaCatalogBytes(mediaCatalogAfter),
    ),
  );
  diff.add(
    AuthoringDiffEntry(
      operation: AuthoringDiffOperation.add,
      resource: mediaResource,
      path: '/entries/${media.id}',
      after: media.toJson(),
    ),
  );

  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diff),
    ),
    preview: <String, Object?>{
      'operation': 'presentationMedia.import',
      'mediaId': media.id,
      'assetId': asset.id,
      'blobDeduplicated': assetProjection.deduplicated,
      'technicalMetadata': media.technicalMetadata!.toJson(),
    },
    referenceImpact: <String, Object?>{
      'mediaId': media.id,
      'sourceAssetId': asset.id,
    },
    artifacts: <AuthoringArtifactRef>[
      AuthoringArtifactRef(
        id: artifact.digest,
        mediaType: artifact.mediaType,
        uri: artifact.handle,
        byteLength: artifact.byteLength,
        sha256: artifact.digest,
      ),
    ],
  );
}

void _requireKindMatchesProbe(
  ProjectMediaKind kind,
  PresentationMediaProbeResult inspected,
) {
  final matches = switch (kind.id) {
    'image' || 'poster' => inspected.mediaType.startsWith('image/'),
    'audio' => inspected.mediaType.startsWith('audio/'),
    'video' => inspected.mediaType.startsWith('video/'),
    'captions' => inspected.mediaType == 'text/vtt',
    _ => false,
  };
  if (!matches) {
    throw PresentationMediaImportException(
      'presentation_media.kind_mismatch',
      'The logical media kind conflicts with the probed MIME.',
      details: <String, Object?>{
        'kind': kind.id,
        'mediaType': inspected.mediaType,
      },
    );
  }
}

AssetCatalog _decodeAssetCatalog(List<int>? bytes) {
  if (bytes == null) return AssetCatalog();
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    throw AssetActionException(
      'asset.catalog_invalid',
      'The current project asset catalog is invalid.',
    );
  }
}

List<int> _encodeAssetCatalog(AssetCatalog catalog) => List<int>.unmodifiable(
      utf8.encode(
          '${const JsonEncoder.withIndent('  ').convert(catalog.toJson())}\n'),
    );

void _requireDeduplicatedBlob(
  ContentArtifactRef artifact,
  List<int> bytes,
  List<int>? existingBlob,
) {
  if (existingBlob == null) {
    throw AssetActionException(
      'asset.deduplicated_blob_missing',
      'The deduplicated artifact blob is unavailable.',
      details: <String, Object?>{'digest': artifact.digest},
    );
  }
  final actual = ContentArtifactRef.fromBytes(
    existingBlob,
    mediaType: artifact.mediaType,
  );
  if (actual.digest != artifact.digest ||
      actual.byteLength != artifact.byteLength ||
      !_sameBytes(existingBlob, bytes)) {
    throw AssetActionException(
      'asset.deduplicated_blob_mismatch',
      'The deduplicated artifact blob does not match the staged media.',
      details: <String, Object?>{'digest': artifact.digest},
    );
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _PresentationMediaImportParameters {
  _PresentationMediaImportParameters(Map<String, Object?> values)
      : _values = Map<String, Object?>.unmodifiable(values) {
    const allowed = <String>{
      'artifactHandle',
      'mediaId',
      'label',
      'kind',
      'assetId',
      'logicalPath',
    };
    final unknown = _values.keys.toSet().difference(allowed);
    if (unknown.isNotEmpty || !_values.keys.toSet().containsAll(allowed)) {
      throw PresentationMediaImportException(
        'presentation_media.request_invalid',
        'The Presentation media import parameters are incomplete or unknown.',
        details: <String, Object?>{'unknown': unknown.toList()..sort()},
      );
    }
  }

  final Map<String, Object?> _values;

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.isEmpty || value.trim() != value) {
      throw PresentationMediaImportException(
        'presentation_media.request_invalid',
        'Parameter $key must be a nonblank trimmed string.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }
}
