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
        id: 'project.audio.media.adopt_asset',
        version: 1,
        summary:
            'Adopt one existing audio source into the game sound library without copying its bytes',
        inputSchemaId:
            'pokemap.authoring.project.audio.media.adopt_asset.input.v1',
        outputSchemaId:
            'pokemap.authoring.project.audio.media.adopt_asset.output.v1',
        riskLevel: AuthoringRiskLevel.low,
        resourceKinds: const ['asset', 'presentationMedia', 'projectAudio'],
        capabilityIds: const ['authoring.presentation_media'],
        requiredPermissions: const [
          AuthoringPermission.projectWrite,
          AuthoringPermission.importRun
        ],
        guarantees: const [
          AuthoringGuarantee.dryRun,
          AuthoringGuarantee.idempotent,
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ],
        extensions: const {
          'parameterNames': ['assetId', 'mediaId', 'label'],
          'inputSchema': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['assetId', 'mediaId', 'label'],
            'properties': {
              'assetId': {'type': 'string', 'minLength': 1},
              'mediaId': {'type': 'string', 'minLength': 1},
              'label': {'type': 'string', 'minLength': 1}
            }
          }
        },
      ),
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
    if (context.request.actionId == 'project.audio.media.adopt_asset') {
      return _adoptAudioAsset(context);
    }
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

  Future<AuthoringMutationDraft> _adoptAudioAsset(
      AuthoringPlanningContext context) async {
    final p = context.request.parameters;
    const keys = {'assetId', 'mediaId', 'label'};
    if (p.length != keys.length ||
        !p.keys.toSet().containsAll(keys) ||
        p.values.any((value) =>
            value is! String || value.isEmpty || value.trim() != value)) {
      throw PresentationMediaImportException(
          'project_audio.adoption_request_invalid',
          'Choose an existing source, a media identity and a nonblank label.');
    }
    final assetId = p['assetId']! as String;
    final mediaId = p['mediaId']! as String;
    final label = p['label']! as String;
    final snapshot = context.snapshot;
    final source = readAssetRecordFromCatalogBytes(
        snapshot.findResourceBytes(assetCatalogResourceIdentity), assetId);
    if (source == null ||
        (!source.artifact.mediaType.startsWith('audio/') &&
            source.artifact.mediaType != 'application/octet-stream')) {
      throw PresentationMediaImportException(
          'project_audio.audio_source_required',
          'Choose an existing audio source from this project.');
    }
    final proposed = ProjectMediaAsset(
        id: mediaId,
        label: label,
        kind: ProjectMediaKind.audio,
        sourceAssetId: source.id);
    final beforeBytes =
        snapshot.findResourceBytes(projectMediaCatalogResourceIdentity);
    final document = readProjectMediaCatalogDocumentBytes(beforeBytes);
    final existing = findProjectAudioMediaForSource(document, source.id);
    if (existing != null) {
      final metadata = existing.technicalMetadata;
      if (metadata == null ||
          !projectAudioSourceMimeMatches(
              source.artifact.mediaType, metadata.mediaType) ||
          metadata.sizeBytes != source.artifact.byteLength) {
        throw PresentationMediaImportException(
            'project_audio.existing_media_invalid',
            'Repair the existing media definition before reusing this source.');
      }
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: {
            'operation': context.request.actionId,
            'assetId': source.id,
            'mediaId': mediaId,
            'existingMediaId': existing.id,
            'noOp': true,
          });
    }
    final entries = document['entries'] as List;
    if (entries.whereType<Map>().any((entry) => entry['id'] == mediaId)) {
      throw PresentationMediaImportException('presentation_media.id_conflict',
          'A media already owns this identity.',
          details: {'mediaId': mediaId});
    }
    final bytes = snapshot
        .findResourceBytes(assetBlobResourceIdentity(source.artifact.digest));
    if (bytes == null) {
      throw PresentationMediaImportException('project_audio.source_unavailable',
          'The selected source bytes are missing. Restore the imported source before adopting it.');
    }
    final actual = ContentArtifactRef.fromBytes(bytes,
        mediaType: source.artifact.mediaType);
    if (actual.digest != source.artifact.digest ||
        actual.byteLength != source.artifact.byteLength) {
      throw PresentationMediaImportException('project_audio.source_mismatch',
          'The selected source bytes differ from their imported content identity.');
    }
    await faultInjector?.call(PresentationMediaImportCheckpoint.beforeProbe);
    final detected = source.artifact.mediaType == 'application/octet-stream'
        ? detectAudioMediaFormat(bytes)
        : null;
    if (source.artifact.mediaType == 'application/octet-stream' &&
        detected == null) {
      throw PresentationMediaImportException(
          'project_audio.audio_source_unsupported',
          'The selected source does not contain a supported audio signature.');
    }
    final inspected = probe.inspect(bytes,
        declaredMediaType: detected?.mediaType ?? source.artifact.mediaType);
    await faultInjector?.call(PresentationMediaImportCheckpoint.afterProbe);
    _requireKindMatchesProbe(ProjectMediaKind.audio, inspected);
    if (!projectAudioSourceMimeMatches(
            source.artifact.mediaType, inspected.mediaType) ||
        inspected.durationMilliseconds == null ||
        inspected.durationMilliseconds! < 1) {
      throw PresentationMediaImportException(
          'project_audio.audio_source_unsupported',
          'This source needs a supported audio format with a finite duration.');
    }
    final media = ProjectMediaAsset.fromJson({
      ...proposed.toJson(),
      'technicalMetadata': inspected.toTechnicalMetadata().toJson()
    });
    final resource = AuthoringResourceRef(
        kind: 'presentationMediaCatalog',
        id: 'project',
        revision:
            snapshot.resourceFingerprints[projectMediaCatalogResourceIdentity]);
    return AuthoringMutationDraft(
        changeSet: AuthoringChangeSet(
            changes: [
              AuthoringResourceChange(
                  resource: resource,
                  storageKey: projectMediaCatalogStorageKey,
                  beforeBytes: beforeBytes,
                  afterBytes: utf8.encode(jsonEncode({
                    ...document,
                    'entries': [...entries, media.toJson()]
                  }))),
            ],
            diff: AuthoringDiff([
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.add,
                  resource: resource,
                  path: '/entries/$mediaId',
                  after: media.toJson())
            ])),
        preview: {
          'operation': context.request.actionId,
          'assetId': source.id,
          'sourceAssetId': source.id,
          'mediaId': media.id,
          'technicalMetadata': media.technicalMetadata!.toJson(),
          'sourceUnchanged': true
        },
        referenceImpact: {
          'mediaId': media.id,
          'sourceAssetId': source.id,
          'sourceUnchanged': true
        });
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

  final existingBlob = snapshot.hasResource(
    assetBlobResourceIdentity(artifact.digest),
  );
  if (assetProjection.deduplicated) {
    if (!snapshot.resourceMatchesArtifact(
        assetBlobResourceIdentity(artifact.digest), artifact)) {
      throw AssetActionException('asset.deduplicated_blob_mismatch',
          'The retained blob does not match the staged media.');
    }
  } else {
    if (existingBlob) {
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
