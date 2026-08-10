import 'dart:convert';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/authoring_request.dart';
import '../../contracts/json_contract_support.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/artifact_store.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'asset_actions.dart';
import 'asset_store.dart';

final class CharacterStudioAssetException implements Exception {
  CharacterStudioAssetException(
    this.code,
    this.message, {
    Map<String, Object?> details = const <String, Object?>{},
  }) : details = freezeContractJsonObject(details, field: 'details');

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => 'CharacterStudioAssetException($code): $message';
}

final class CharacterStudioAssetActions {
  const CharacterStudioAssetActions({required this.artifactStore});

  final ArtifactStore artifactStore;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'characterStudio.asset.import',
        'Import one inspected portable Character Studio PNG asset',
        AuthoringRiskLevel.low,
      ),
      _descriptor(
        'characterStudio.asset.replace',
        'Replace one Character Studio PNG and close its orphaned blob',
        AuthoringRiskLevel.medium,
      ),
    ],
  );

  Future<AuthoringMutationDraft> build(
    AuthoringPlanningContext context,
  ) async {
    final parameters = _CharacterStudioAssetParameters(
      context.request.parameters,
    );
    final actionId = context.request.actionId;
    final replacing = actionId == 'characterStudio.asset.replace';
    if (!replacing && actionId != 'characterStudio.asset.import') {
      throw CharacterStudioAssetException(
        'character_studio.asset.action_unsupported',
        'The requested Character Studio asset action is unsupported.',
        details: <String, Object?>{'actionId': actionId},
      );
    }
    parameters.allow(
      replacing
          ? const <String>{'artifactHandle', 'assetId', 'sourceRect'}
          : const <String>{
              'artifactHandle',
              'assetId',
              'logicalPath',
              'mediaKind',
              'sourceRect',
              'tags',
            },
    );
    final artifactHandle = parameters.string('artifactHandle');
    final artifact = artifactStore.inspect(artifactHandle);
    if (artifact == null) {
      throw CharacterStudioAssetException(
        'character_studio.asset.artifact_unknown',
        'The staged Character Studio artifact is unknown or expired.',
        details: <String, Object?>{'artifactHandle': artifactHandle},
      );
    }
    final bytes = await artifactStore.read(artifact.handle);
    final image = _inspectPng(artifact.mediaType, bytes);
    final sourceRect = parameters.sourceRect(
      width: image.width,
      height: image.height,
    );
    final catalog = _catalog(context.snapshot);
    final assetId = parameters.string('assetId');
    final before = replacing ? catalog.require(assetId) : null;
    final mediaKind = replacing
        ? _mediaKindFromRecord(before!)
        : parameters.mediaKind('mediaKind');
    final translatedParameters = replacing
        ? <String, Object?>{
            'artifactHandle': artifactHandle,
            'assetId': assetId,
          }
        : <String, Object?>{
            'artifactHandle': artifactHandle,
            'assetId': assetId,
            'logicalPath': parameters.string('logicalPath'),
            'tags': <String>{
              ...parameters.strings('tags'),
              'character-studio',
              'character-studio:${mediaKind.wireName}',
            }.toList()
              ..sort(),
          };
    final baseDraft = await AssetActions(artifactStore: artifactStore).build(
      AuthoringPlanningContext(
        snapshot: context.snapshot,
        request: _translatedRequest(
          context.request,
          actionId: replacing ? 'asset.replace' : 'asset.import',
          parameters: translatedParameters,
        ),
        planId: context.planId,
        seed: context.seed,
      ),
    );
    final orphanedBlobDeleted = replacing &&
        before!.artifact.digest != artifact.digest &&
        !catalog.records.any(
          (record) =>
              record.id != before.id &&
              record.artifact.digest == before.artifact.digest,
        );
    final changes = baseDraft.changeSet.changes.toList();
    final diff = baseDraft.changeSet.diff.entries.toList();
    if (orphanedBlobDeleted) {
      final identity = assetBlobResourceIdentity(before.artifact.digest);
      final oldBytes = context.snapshot.findResourceBytes(identity);
      if (oldBytes == null) {
        throw CharacterStudioAssetException(
          'character_studio.asset.rollback_blob_required',
          'Replacing the last blob reference requires its exact pre-image.',
          details: <String, Object?>{'assetId': before.id},
        );
      }
      final resource = AuthoringResourceRef(
        kind: 'assetBlob',
        id: before.artifact.digest,
        revision: context.snapshot.resourceFingerprints[identity],
      );
      changes.add(
        AuthoringResourceChange(
          resource: resource,
          storageKey: assetBlobStorageKey(before.artifact),
          beforeBytes: oldBytes,
          afterBytes: null,
        ),
      );
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: resource,
          path: '/',
          before: before.artifact.toJson(),
        ),
      );
    }
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: changes,
        diff: AuthoringDiff(diff),
      ),
      preview: <String, Object?>{
        ...baseDraft.preview,
        'mediaKind': mediaKind.wireName,
        'width': image.width,
        'height': image.height,
        'sourceRect': sourceRect,
        'orphanedBlobDeleted': orphanedBlobDeleted,
      },
      referenceImpact: <String, Object?>{
        ...baseDraft.referenceImpact,
        'portableAssetId': assetId,
        'orphanedBlobDeleted': orphanedBlobDeleted,
      },
      artifacts: baseDraft.artifacts,
    );
  }
}

enum _CharacterStudioMediaKind {
  portrait('portrait'),
  spriteSheet('spriteSheet');

  const _CharacterStudioMediaKind(this.wireName);

  final String wireName;
}

final class _PngInspection {
  const _PngInspection({required this.width, required this.height});

  final int width;
  final int height;
}

_PngInspection _inspectPng(String mediaType, List<int> bytes) {
  const signature = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  final signatureMatches = bytes.length >= 24 &&
      List<int>.generate(8, (index) => index)
          .every((index) => bytes[index] == signature[index]);
  final hasHeader = bytes.length >= 24 &&
      bytes[12] == 0x49 &&
      bytes[13] == 0x48 &&
      bytes[14] == 0x44 &&
      bytes[15] == 0x52;
  if (mediaType != 'image/png' || !signatureMatches || !hasHeader) {
    throw CharacterStudioAssetException(
      'character_studio.asset.png_required',
      'Character Studio portraits and sprite sheets must be valid PNG files.',
    );
  }
  final width = _uint32(bytes, 16);
  final height = _uint32(bytes, 20);
  if (width < 1 || height < 1 || width > 16384 || height > 16384) {
    throw CharacterStudioAssetException(
      'character_studio.asset.dimensions_invalid',
      'Character Studio PNG dimensions must be between 1 and 16384 pixels.',
      details: <String, Object?>{'width': width, 'height': height},
    );
  }
  return _PngInspection(width: width, height: height);
}

int _uint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

_CharacterStudioMediaKind _mediaKindFromRecord(AssetRecord record) {
  for (final kind in _CharacterStudioMediaKind.values) {
    if (record.tags.contains('character-studio:${kind.wireName}')) return kind;
  }
  return _CharacterStudioMediaKind.portrait;
}

AssetCatalog _catalog(ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return AssetCatalog();
  try {
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map) throw const FormatException();
    return AssetCatalog.fromJson(Map<String, dynamic>.from(json));
  } on Object {
    throw CharacterStudioAssetException(
      'character_studio.asset.catalog_invalid',
      'The current project asset catalog is invalid.',
    );
  }
}

AuthoringRequest _translatedRequest(
  AuthoringRequest source, {
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return AuthoringRequest(
    requestId: source.requestId,
    actionId: actionId,
    actionVersion: source.actionVersion,
    workspaceHandle: source.workspaceHandle,
    parameters: parameters,
    expectedRevision: source.expectedRevision,
    idempotencyKey: source.idempotencyKey,
    dryRun: source.dryRun,
    extensions: source.extensions,
  );
}

final class _CharacterStudioAssetParameters {
  _CharacterStudioAssetParameters(this.values);

  final Map<String, Object?> values;

  void allow(Set<String> allowed) {
    final unknown = values.keys.toSet().difference(allowed);
    if (unknown.isNotEmpty) {
      throw CharacterStudioAssetException(
        'character_studio.asset.parameters_unknown',
        'The Character Studio asset request contains unknown parameters.',
        details: <String, Object?>{'parameters': unknown.toList()..sort()},
      );
    }
  }

  String string(String key) {
    final value = values[key];
    if (value is! String || value.trim().isEmpty || value != value.trim()) {
      throw CharacterStudioAssetException(
        'character_studio.asset.parameter_invalid',
        'Character Studio asset parameters must be nonblank strings.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return value;
  }

  List<String> strings(String key) {
    final value = values[key];
    if (value == null) return const <String>[];
    if (value is! List || value.any((item) => item is! String)) {
      throw CharacterStudioAssetException(
        'character_studio.asset.parameter_invalid',
        'Character Studio asset tags must be a string list.',
        details: <String, Object?>{'parameter': key},
      );
    }
    return normalizedContractStrings(value.cast<String>(), key);
  }

  _CharacterStudioMediaKind mediaKind(String key) {
    final value = string(key);
    return _CharacterStudioMediaKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => throw CharacterStudioAssetException(
        'character_studio.asset.media_kind_invalid',
        'Character Studio media kind must be portrait or spriteSheet.',
        details: <String, Object?>{'mediaKind': value},
      ),
    );
  }

  Map<String, Object?> sourceRect({
    required int width,
    required int height,
  }) {
    final raw = values['sourceRect'];
    if (raw == null) {
      return <String, Object?>{
        'x': 0,
        'y': 0,
        'width': width,
        'height': height,
      };
    }
    if (raw is! Map ||
        raw.keys.any((key) => key is! String) ||
        raw.keys
            .toSet()
            .difference(<String>{'x', 'y', 'width', 'height'}).isNotEmpty ||
        raw.length != 4 ||
        raw.values.any((value) => value is! int)) {
      throw CharacterStudioAssetException(
        'character_studio.asset.source_rect_invalid',
        'Character Studio sourceRect must contain four integer coordinates.',
      );
    }
    final rect = Map<String, Object?>.from(raw);
    final x = rect['x']! as int;
    final y = rect['y']! as int;
    final rectWidth = rect['width']! as int;
    final rectHeight = rect['height']! as int;
    if (x < 0 ||
        y < 0 ||
        rectWidth < 1 ||
        rectHeight < 1 ||
        x + rectWidth > width ||
        y + rectHeight > height) {
      throw CharacterStudioAssetException(
        'character_studio.asset.source_rect_out_of_bounds',
        'Character Studio sourceRect must remain inside the PNG dimensions.',
        details: <String, Object?>{
          'sourceRect': rect,
          'imageWidth': width,
          'imageHeight': height,
        },
      );
    }
    return rect;
  }
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
    outputSchemaId: 'pokemap.authoring.characterStudio.asset.output.v1',
    riskLevel: riskLevel,
    resourceKinds: const <String>['assetCatalog', 'assetBlob'],
    capabilityIds: const <String>['authoring.characterStudio.assets'],
    requiredPermissions: const <AuthoringPermission>[
      AuthoringPermission.assetWrite,
      AuthoringPermission.projectWrite,
    ],
    guarantees: const <AuthoringGuarantee>[
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.atomic,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
    ],
  );
}
