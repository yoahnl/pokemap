import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as path;

import 'literal_autotile_composer.dart';
import 'approved_asset_library.dart';
import 'literal_tile_composer.dart';
import 'source_semantic_study_composer.dart';
import 'source_event_study_composer.dart';
import 'source_event_arrival_validation.dart';
import 'source_catalog_study_composer.dart';
import 'source_catalog_projection.dart';

final class NativeWriteLimits {
  const NativeWriteLimits({
    this.maxArtifacts = 32,
    this.maxMutations = 256,
    this.maxArtifactBytes = 16777216,
    this.maxTotalArtifactBytes = 67108864,
    this.maxImagePixels = 16777216,
    this.maxMapCells = 1048576,
    this.jsonLimits = const ContractLimits(),
  });

  final int maxArtifacts;
  final int maxMutations;
  final int maxArtifactBytes;
  final int maxTotalArtifactBytes;
  final int maxImagePixels;
  final int maxMapCells;
  final ContractLimits jsonLimits;

  void validate() => _validate();

  void _validate() {
    final values = [
      (maxArtifacts, 256),
      (maxMutations, 2048),
      (maxArtifactBytes, 67108864),
      (maxTotalArtifactBytes, 268435456),
      (maxImagePixels, 16777216),
      (maxMapCells, 4194304),
      (jsonLimits.maxDepth, 64),
      (jsonLimits.maxNodes, 4000000),
      (jsonLimits.maxStringCodeUnits, 1048576),
      (jsonLimits.maxTextCodeUnits, 16777216),
    ];
    if (values.any((entry) => entry.$1 <= 0 || entry.$1 > entry.$2)) {
      throw const NativeWriteException(
          'native.invalid_limits', 'Limits must be positive and bounded');
    }
  }
}

final class NativeArtifact {
  factory NativeArtifact({
    required List<int> bytes,
    String mediaType = 'image/png',
    Sha256Hash? expectedSha256,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    if (mediaType != 'image/png' &&
        mediaType != 'application/json' &&
        !_nativeAudioMediaTypes.contains(mediaType)) {
      throw const NativeWriteException(
          'native.artifact.media', 'Unsupported native artifact media type');
    }
    final byteLength = bytes.length;
    if (byteLength > limits.maxArtifactBytes ||
        (mediaType == 'application/json' && byteLength > 1048576)) {
      throw const NativeWriteException(
          'native.quota.artifact', 'Artifact byte budget exceeded');
    }
    final owned = Uint8List(byteLength);
    for (var i = 0; i < byteLength; i++) {
      final value = bytes[i];
      if (value < 0 || value > 255) {
        throw const NativeWriteException(
            'native.artifact.bytes', 'Invalid artifact bytes');
      }
      owned[i] = value;
    }
    final frozen = owned.asUnmodifiableView();
    if (mediaType == 'application/json') {
      _validateNativeArtifactJson(frozen, limits.jsonLimits);
    } else if (_nativeAudioMediaTypes.contains(mediaType)) {
      _validateNativeAudioArtifact(frozen, mediaType);
    }
    final hash = Sha256Hash(sha256.convert(frozen).toString());
    if (expectedSha256 != null && expectedSha256 != hash) {
      throw const NativeWriteException(
          'native.artifact.hash', 'Artifact hash mismatch');
    }
    return NativeArtifact._(frozen, hash,
        ContentArtifactRef.fromBytes(frozen, mediaType: mediaType));
  }

  const NativeArtifact._(this.bytes, this.rawSha256, this.reference);
  final List<int> bytes;
  final Sha256Hash rawSha256;
  final ContentArtifactRef reference;
  String get handle => reference.handle;
}

const _nativeAudioMediaTypes = {
  'audio/wav',
  'audio/ogg',
  'audio/mpeg',
  'audio/flac'
};

PresentationMediaProbeResult _validateNativeAudioArtifact(
    List<int> bytes, String mediaType) {
  try {
    final inspected = const PresentationMediaHeaderProbe()
        .inspect(bytes, declaredMediaType: mediaType);
    if (!_nativeAudioMediaTypes.contains(inspected.mediaType) ||
        inspected.durationMilliseconds == null ||
        inspected.durationMilliseconds! < 1) {
      throw const FormatException('A finite supported sound is required');
    }
    return inspected;
  } on Object {
    throw const NativeWriteException('native.artifact.audio',
        'Audio bytes must match their supported MIME and finite probed duration');
  }
}

Map<String, Object?> _validateNativeArtifactJson(
    List<int> bytes, ContractLimits limits) {
  try {
    final text = utf8.decode(bytes, allowMalformed: false);
    final containers = <int>[];
    var quoted = false;
    var escaped = false;
    var expectingValue = true;
    var nodes = 0;
    void value() {
      if (++nodes > limits.maxNodes || containers.length > limits.maxDepth) {
        throw const FormatException('JSON structure budget exceeded');
      }
      expectingValue = false;
    }

    for (final unit in text.codeUnits) {
      if (quoted) {
        if (escaped) {
          escaped = false;
        } else if (unit == 92) {
          escaped = true;
        } else if (unit == 34) {
          quoted = false;
          expectingValue = false;
        }
        continue;
      }
      if (unit == 34) {
        if (expectingValue) value();
        quoted = true;
      } else if (unit == 123 || unit == 91) {
        if (expectingValue) value();
        if (containers.length > limits.maxDepth) {
          throw const FormatException('JSON nesting budget exceeded');
        }
        containers.add(unit);
        expectingValue = unit == 91;
      } else if (unit == 125 || unit == 93) {
        if (containers.isEmpty ||
            containers.removeLast() != (unit == 125 ? 123 : 91)) {
          throw const FormatException('Unbalanced JSON structure');
        }
        expectingValue = false;
      } else if (unit == 58) {
        expectingValue = true;
      } else if (unit == 44) {
        expectingValue = containers.isNotEmpty && containers.last == 91;
      } else if (unit != 32 && unit != 9 && unit != 10 && unit != 13) {
        if (expectingValue) value();
      }
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?> ||
        canonicalJsonOf(decoded, limits: limits) != text) {
      throw const FormatException('A canonical JSON object is required');
    }
    return decoded;
  } on FormatException {
    throw const NativeWriteException('native.artifact.json',
        'A bounded canonical inert JSON object is required');
  }
}

final class NativeMutation {
  factory NativeMutation({
    required ConverterId operationId,
    required String actionId,
    int actionVersion = 1,
    required List<ConverterId> sourceEntityIds,
    required List<ConverterId> targetEntityIds,
    required Map<String, Object?> parameters,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    if (sourceEntityIds.length > limits.maxMutations ||
        targetEntityIds.length > limits.maxMutations) {
      throw const NativeWriteException(
          'native.quota.references', 'Mutation reference budget exceeded');
    }
    canonicalJsonOf({
      'operationId': operationId.value,
      'actionId': actionId,
      'actionVersion': actionVersion,
      'sourceEntityIds': sourceEntityIds.map((id) => id.value).toList(),
      'targetEntityIds': targetEntityIds.map((id) => id.value).toList(),
      'parameters': parameters
    }, limits: limits.jsonLimits);
    return NativeMutation._(
        operationId,
        actionId,
        actionVersion,
        List.unmodifiable(sourceEntityIds),
        List.unmodifiable(targetEntityIds),
        _freezeNativeJson(jsonDecode(
                canonicalJsonOf(parameters, limits: limits.jsonLimits)))
            as Map<String, Object?>);
  }

  const NativeMutation._(this.operationId, this.actionId, this.actionVersion,
      this.sourceEntityIds, this.targetEntityIds, this.parameters);

  final ConverterId operationId;
  final String actionId;
  final int actionVersion;
  final List<ConverterId> sourceEntityIds;
  final List<ConverterId> targetEntityIds;
  final Map<String, Object?> parameters;

  OperationDomain get domain => switch (actionId.split('.').first) {
        'map' || 'entity' || 'trigger' || 'warp' => OperationDomain.maps,
        'event_v2' ||
        'fact' ||
        'world_rule' ||
        'dialogue' ||
        'scene' =>
          OperationDomain.events,
        'item' || 'pokemon' || 'campaign' => OperationDomain.catalogs,
        _ => OperationDomain.assets,
      };

  Map<String, Object?> toJson(int ordinal) => {
        'operationId': operationId.value,
        'actionId': actionId,
        'actionVersion': actionVersion,
        'ordinal': ordinal,
        'sourceEntityIds': sourceEntityIds.map((id) => id.value).toList(),
        'targetEntityIds': targetEntityIds.map((id) => id.value).toList(),
        'parameters': parameters,
      };
}

final class NativeProjectDraft {
  factory NativeProjectDraft({
    required NormalizedSourceProject source,
    required String projectName,
    required String parentPath,
    required String folderName,
    required Map<int, String> mapIds,
    required List<NativeArtifact> artifacts,
    List<NativeArtifact> sourceArtifacts = const [],
    required List<NativeMutation> mutations,
    Map<String, Object?> compositionEvidence = const {},
    String? sourceRootPath,
    int defaultMapWidth = 3,
    int defaultMapHeight = 3,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    if (mapIds.length > limits.maxMutations ||
        artifacts.length + sourceArtifacts.length > limits.maxArtifacts ||
        mutations.length > limits.maxMutations) {
      throw const NativeWriteException(
          'native.quota.draft', 'Draft entry budget exceeded');
    }
    var total = 0;
    for (final artifact in [...artifacts, ...sourceArtifacts]) {
      total += artifact.bytes.length;
      if (artifact.bytes.length > limits.maxArtifactBytes ||
          total > limits.maxTotalArtifactBytes) {
        throw const NativeWriteException(
            'native.quota.artifact', 'Aggregate artifact budget exceeded');
      }
    }
    if (!source.canPlan ||
        !source.archive.isSealed ||
        source.snapshot.state != SourceScanState.complete) {
      throw const NativeWriteException('native.source.incomplete',
          'A complete plannable normalized source is required');
    }
    final normalizedHash = source.canonicalHash;
    canonicalJsonOf(compositionEvidence, limits: limits.jsonLimits);
    final frozenComposition =
        _freezeNativeJson(compositionEvidence) as Map<String, Object?>;
    final binding = {
      'kind': 'nativeProjectDraft',
      'version': 1,
      'projectName': projectName,
      'parentPath': parentPath,
      'folderName': folderName,
      'sourceRootPath': sourceRootPath,
      'dimension': 'twoD',
      'template': 'empty',
      'tileSize': 32,
      'defaultMapWidth': defaultMapWidth,
      'defaultMapHeight': defaultMapHeight,
      'normalizedSourceHash': normalizedHash.value,
      'compositionEvidence': frozenComposition,
      'mapIds': {
        for (final entry in mapIds.entries) '${entry.key}': entry.value
      },
      'artifacts': artifacts
          .map((artifact) => {
                'reference': artifact.reference.toJson(),
                'rawSha256': artifact.rawSha256.value
              })
          .toList(),
      if (sourceArtifacts.isNotEmpty)
        'sourceArtifacts': sourceArtifacts
            .map((artifact) => {
                  'reference': artifact.reference.toJson(),
                  'rawSha256': artifact.rawSha256.value
                })
            .toList(),
      'mutations': [
        for (var i = 0; i < mutations.length; i++) mutations[i].toJson(i)
      ],
    };
    final hash = canonicalHashOf(binding, limits: limits.jsonLimits);
    return NativeProjectDraft._(
        source,
        projectName,
        parentPath,
        folderName,
        sourceRootPath,
        defaultMapWidth,
        defaultMapHeight,
        Map.unmodifiable(mapIds),
        List.unmodifiable(artifacts),
        List.unmodifiable(sourceArtifacts),
        List.unmodifiable(mutations),
        normalizedHash,
        frozenComposition,
        hash,
        _freezeNativeJson(binding) as Map<String, Object?>);
  }

  const NativeProjectDraft._(
      this.source,
      this.projectName,
      this.parentPath,
      this.folderName,
      this.sourceRootPath,
      this.defaultMapWidth,
      this.defaultMapHeight,
      this.mapIds,
      this.artifacts,
      this.sourceArtifacts,
      this.mutations,
      this.normalizedSourceHash,
      this.compositionEvidence,
      this.canonicalHash,
      this._binding);

  final NormalizedSourceProject source;
  final String projectName;
  final String parentPath;
  final String folderName;
  final String? sourceRootPath;
  final int defaultMapWidth;
  final int defaultMapHeight;
  final Map<int, String> mapIds;
  final List<NativeArtifact> artifacts;
  final List<NativeArtifact> sourceArtifacts;
  final List<NativeMutation> mutations;
  final Sha256Hash normalizedSourceHash;
  final Map<String, Object?> compositionEvidence;
  final Sha256Hash canonicalHash;
  final Map<String, Object?> _binding;
  String get bindingEvidence => 'native-draft-sha256:${canonicalHash.value}';

  void validateResourceBudget({
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    _preflightNativeResourceBudget(this, limits);
  }
}

enum NativeWriteStage {
  beforeStage,
  stageCreated,
  beforeBootstrap,
  afterBootstrap,
  afterMutation,
  afterMutations,
  beforeNativeVerify,
  afterNativeVerify,
}

typedef NativeWriteCheckpoint = FutureOr<void> Function(
    NativeWriteStage stage, String? stagingRoot, String? projectPath);

typedef NativeStagingFactory = Future<String> Function();

final class NativeWriteReceipt {
  NativeWriteReceipt._({
    required this.stagingRoot,
    required this.projectPath,
    required this.draftHash,
    required this.nativeRevision,
    required Map<String, Sha256Hash> mapHashes,
    required Map<String, Sha256Hash> assetHashes,
  })  : mapHashes = Map.unmodifiable(mapHashes),
        assetHashes = Map.unmodifiable(assetHashes);

  final String stagingRoot;
  final String projectPath;
  final Sha256Hash draftHash;
  final String nativeRevision;
  final Map<String, Sha256Hash> mapHashes;
  final Map<String, Sha256Hash> assetHashes;
  bool get verified => true;
  bool get published => false;
}

final class NativeWriteException implements Exception {
  const NativeWriteException(this.code, this.message, {this.stagingPath});
  final String code;
  final String message;
  final String? stagingPath;
  @override
  String toString() => '$code: $message';
}

final class NativeProjectWriter {
  const NativeProjectWriter(
      {this.creation, this.checkpoint, this.stagingFactory});
  final ProjectCreationPort? creation;
  final NativeWriteCheckpoint? checkpoint;
  final NativeStagingFactory? stagingFactory;

  Future<NativeWriteReceipt> write(
    ConversionPlan plan,
    PlanContext context,
    NativeProjectDraft draft, {
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    String? stagingRoot;
    String? projectPath;
    _NativeSession? session;
    try {
      admitPlan(plan, context);
      limits._validate();
      _checkCancelled(cancellation);
      final prepared =
          await _prepareNativeDraft(plan, context, draft, limits, cancellation);
      final creator = creation ?? const LocalProjectCreationService();
      final requested = _creationRequest(draft, draft.parentPath);
      requested.validate();
      _requireAbsolute(draft.parentPath);
      final parent = await Directory(draft.parentPath).resolveSymbolicLinks();
      await _guardDestination(draft, parent);
      await checkpoint?.call(NativeWriteStage.beforeStage, null, null);
      _checkCancelled(cancellation);
      await _guardDestination(draft, parent);
      stagingRoot = stagingFactory == null
          ? (await Directory(parent).createTemp('.avelune-converter-stage-')).path
          : await stagingFactory!();
      _makePrivate(stagingRoot);
      projectPath = path.join(stagingRoot, draft.folderName);
      await _guardStage(draft, parent, stagingRoot);
      await checkpoint?.call(
          NativeWriteStage.stageCreated, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await _guardStage(draft, parent, stagingRoot);
      final stageRequest = _creationRequest(draft, stagingRoot);
      final destination = await creator.validateDestination(stageRequest);
      if (destination != projectPath) {
        throw const NativeWriteException('native.destination.changed',
            'Creation destination differs from the private staging path');
      }
      await checkpoint?.call(
          NativeWriteStage.beforeBootstrap, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await _guardStage(draft, parent, stagingRoot);
      final created = await creator.create(stageRequest,
          expectedDestination: projectPath,
          isCancelled: () => cancellation?.isCancelled ?? false);
      if (created.projectPath != projectPath ||
          canonicalJsonOf(created.manifest.toJson()) !=
              canonicalJsonOf(prepared.bootstrap.toJson())) {
        throw const NativeWriteException('native.bootstrap.mismatch',
            'Bootstrap receipt differs from the requested empty project');
      }
      await checkpoint?.call(
          NativeWriteStage.afterBootstrap, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await _guardStage(draft, parent, stagingRoot);
      session = await _NativeSession.open(projectPath,
          allowedRoot: stagingRoot, mutable: true);
      final api = session.mutations!;
      for (final artifact in draft.artifacts) {
        _checkCancelled(cancellation);
        final stored = await api.artifacts.put(artifact.bytes,
            declaredMediaType: artifact.reference.mediaType);
        if (stored.reference != artifact.reference) {
          throw const NativeWriteException('native.artifact.stage',
              'Native artifact staging changed the content reference');
        }
      }
      for (var i = 0; i < draft.mutations.length; i++) {
        _checkCancelled(cancellation);
        await _guardStage(draft, parent, stagingRoot);
        final mutation = draft.mutations[i];
        final before = await session.snapshots.load(session.project);
        final mutationPlan = await api.planMutation(
            session.project,
            AuthoringRequest(
                requestId: '${plan.planId.value}:native:$i',
                actionId: mutation.actionId,
                actionVersion: mutation.actionVersion,
                workspaceHandle: session.workspace.value,
                expectedRevision: before.revision,
                idempotencyKey: mutation.operationId.value,
                parameters: mutation.parameters));
        if (!mutationPlan.applicable ||
            mutationPlan.snapshotRevision != before.revision) {
          throw NativeWriteException('native.mutation.plan',
              'Native mutation cannot be applied: ${mutationPlan.nonApplicableReason ?? mutation.actionId}');
        }
        final applied = await api.applyMutation(session.project,
            planId: mutationPlan.planId,
            operationId: mutation.operationId.value);
        if (applied.receipt.status != AuthoringReceiptStatus.applied ||
            applied.receipt.actionId != mutation.actionId ||
            applied.receipt.actionVersion != mutation.actionVersion ||
            applied.receipt.extensions['planId'] != mutationPlan.planId ||
            applied.receipt.extensions['operationId'] !=
                mutation.operationId.value ||
            applied.receipt.beforeRevision == null ||
            applied.receipt.afterRevision == null ||
            applied.receipt.beforeRevision == applied.receipt.afterRevision ||
            applied.snapshotRevision == before.revision) {
          throw NativeWriteException(
              'native.mutation.receipt',
              'Native mutation ${mutation.actionId} has inconsistent receipt '
                  '(status=${applied.receipt.status.name}, '
                  'plan=${applied.receipt.extensions['planId']}, '
                  'operation=${applied.receipt.extensions['operationId']}, '
                  'beforeSnapshot=${before.revision}, '
                  'afterSnapshot=${applied.snapshotRevision})');
        }
        final observed = await session.snapshots.load(session.project);
        if (observed.revision != applied.snapshotRevision) {
          throw const NativeWriteException('native.mutation.revision',
              'Applied native revision differs from the reloaded snapshot');
        }
        await checkpoint?.call(
            NativeWriteStage.afterMutation, stagingRoot, projectPath);
      }
      await session.close();
      session = null;
      await checkpoint?.call(
          NativeWriteStage.afterMutations, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await checkpoint?.call(
          NativeWriteStage.beforeNativeVerify, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await _guardStage(draft, parent, stagingRoot);
      session = await _NativeSession.open(projectPath,
          allowedRoot: stagingRoot, mutable: false);
      final snapshot = await session.snapshots
          .load(session.project, policy: ProjectSnapshotLoadPolicy.strict);
      if (snapshot.loadDiagnostics.isNotEmpty ||
          canonicalJsonOf(snapshot.manifest.toJson()) !=
              canonicalJsonOf(prepared.manifest.toJson())) {
        throw const NativeWriteException('native.verify.manifest',
            'Fresh native manifest differs from the approved draft');
      }
      ProjectValidator.validate(snapshot.manifest, maps: snapshot.maps);
      if (snapshot.maps.length != prepared.maps.length) {
        throw const NativeWriteException('native.verify.maps',
            'Fresh native map inventory differs from the approved draft');
      }
      final mapHashes = <String, Sha256Hash>{};
      for (final entry in prepared.dialogueSources.entries) {
        _checkCancelled(cancellation);
        final bytes =
            snapshot.resourceBytes(dialogueSourceResourceIdentity(entry.key));
        final expected = utf8.encode(entry.value);
        if (bytes.length != expected.length ||
            sha256.convert(bytes) != sha256.convert(expected)) {
          throw const NativeWriteException('native.verify.dialogue',
              'Fresh native dialogue bytes differ from the approved source projection');
        }
      }
      for (final entry in prepared.maps.entries) {
        _checkCancelled(cancellation);
        final actual = snapshot.mapById(entry.key);
        if (actual == null ||
            canonicalJsonOf(jsonDecode(jsonEncode(actual.toJson())),
                    limits: limits.jsonLimits) !=
                canonicalJsonOf(jsonDecode(jsonEncode(entry.value.toJson())),
                    limits: limits.jsonLimits)) {
          throw const NativeWriteException('native.verify.map',
              'Fresh native map differs from the approved draft');
        }
        MapValidator.validate(actual,
            projectDialogueContext: snapshot.manifest);
        final bytes = snapshot.resourceBytes('map:${entry.key}');
        mapHashes[entry.key] = Sha256Hash(sha256.convert(bytes).toString());
      }
      final assetHashes = <String, Sha256Hash>{};
      final actualCatalog = AssetCatalog.fromJson(jsonDecode(
              utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)))
          as Map<String, dynamic>);
      if (canonicalJsonOf(actualCatalog.toJson(), limits: limits.jsonLimits) !=
          canonicalJsonOf(prepared.catalog.toJson(),
              limits: limits.jsonLimits)) {
        throw const NativeWriteException('native.verify.catalog',
            'Fresh native asset catalog differs from the approved draft');
      }
      for (final entry in prepared.tilesets.entries) {
        _checkCancelled(cancellation);
        final assetId = 'image_${entry.key}';
        final artifact = entry.value;
        final bytes = snapshot.resourceBytes('assetLogical:$assetId');
        final hash = Sha256Hash(sha256.convert(bytes).toString());
        if (bytes.length != artifact.bytes.length ||
            hash != artifact.rawSha256) {
          throw const NativeWriteException('native.verify.image',
              'Native logical image differs from the approved artifact');
        }
        final dimensions = _pngDimensions(bytes, limits);
        final source = snapshot.manifest.tilesets
            .singleWhere((tileset) => tileset.id == entry.key)
            .source;
        if (source is! ProjectRegularAtlasTilesetSource ||
            source.assetId != assetId ||
            source.pixelWidth != dimensions.$1 ||
            source.pixelHeight != dimensions.$2 ||
            source.tileWidth !=
                (prepared.manifest.tilesets
                        .singleWhere((tileset) => tileset.id == entry.key)
                        .source as ProjectRegularAtlasTilesetSource)
                    .tileWidth ||
            source.tileHeight !=
                (prepared.manifest.tilesets
                        .singleWhere((tileset) => tileset.id == entry.key)
                        .source as ProjectRegularAtlasTilesetSource)
                    .tileHeight) {
          throw const NativeWriteException('native.verify.tileset',
              'Native atlas geometry differs from the loaded image');
        }
        final blob = await session.snapshots
            .readRetainedAssetBlob(session.project, artifact.reference);
        if (blob == null ||
            blob.length != bytes.length ||
            Sha256Hash(sha256.convert(blob).toString()) != artifact.rawSha256) {
          throw const NativeWriteException('native.verify.blob',
              'Native retained blob is missing or differs from the approved image');
        }
        assetHashes[assetId] = hash;
      }
      if (snapshot.itemCatalog != prepared.itemCatalog) {
        throw const NativeWriteException('native.verify.items',
            'Fresh item catalog differs from the exact source bindings');
      }
      await _verifyNativeCatalogs(session, prepared, limits, cancellation);
      for (final entry in prepared.audio.entries) {
        final bytes = await session.readCompanion(
            prepared.catalog.require(entry.key).logicalPath, entry.value,
            errorCode: 'native.verify.audio');
        final blob = await session.snapshots
            .readRetainedAssetBlob(session.project, entry.value.reference);
        if (blob == null ||
            blob.length != bytes.length ||
            sha256.convert(blob) != sha256.convert(bytes)) {
          throw const NativeWriteException('native.verify.audio',
              'Dialogue sound logical file and retained blob must match exact source bytes');
        }
        assetHashes[entry.key] = Sha256Hash(sha256.convert(bytes).toString());
      }
      for (final entry in prepared.companions.entries) {
        _checkCancelled(cancellation);
        final bytes = await session.readCompanion(
            prepared.catalog.require(entry.key).logicalPath, entry.value,
            errorCode: 'native.verify.companion');
        final hash = Sha256Hash(sha256.convert(bytes).toString());
        final artifact = entry.value;
        if (bytes.length != artifact.bytes.length ||
            hash != artifact.rawSha256) {
          throw const NativeWriteException('native.verify.companion',
              'Native provenance bytes differ from the approved companion');
        }
        _validateNativeArtifactJson(bytes, limits.jsonLimits);
        final blob = await session.snapshots
            .readRetainedAssetBlob(session.project, artifact.reference);
        if (blob == null ||
            blob.length != bytes.length ||
            Sha256Hash(sha256.convert(blob).toString()) != hash) {
          throw const NativeWriteException('native.verify.blob',
              'Native retained companion blob differs from the approved bytes');
        }
        assetHashes[entry.key] = hash;
      }
      await checkpoint?.call(
          NativeWriteStage.afterNativeVerify, stagingRoot, projectPath);
      _checkCancelled(cancellation);
      await _guardStage(draft, parent, stagingRoot);
      final finalSnapshot = await session.snapshots
          .load(session.project, policy: ProjectSnapshotLoadPolicy.strict);
      if (finalSnapshot.revision != snapshot.revision) {
        throw const NativeWriteException('native.verify.changed',
            'Native staging project changed after verification');
      }
      await _verifyNativeCatalogs(session, prepared, limits, cancellation);
      for (final entry in {...prepared.companions, ...prepared.audio}.entries) {
        _checkCancelled(cancellation);
        await session.readCompanion(
            prepared.catalog.require(entry.key).logicalPath, entry.value,
            errorCode: 'native.verify.changed');
      }
      return NativeWriteReceipt._(
          stagingRoot: stagingRoot,
          projectPath: projectPath,
          draftHash: draft.canonicalHash,
          nativeRevision: snapshot.revision,
          mapHashes: mapHashes,
          assetHashes: assetHashes);
    } catch (error) {
      if (error is NativeWriteException) {
        throw NativeWriteException(error.code, error.message,
            stagingPath: stagingRoot ?? error.stagingPath);
      }
      if (error is ContractError) {
        throw NativeWriteException(
            'native.admission.${error.code}', error.message.toString(),
            stagingPath: stagingRoot);
      }
      throw NativeWriteException('native.write.failed', error.toString(),
          stagingPath: stagingRoot);
    } finally {
      await session?.close();
    }
  }
}

final class _PreparedNativeDraft {
  const _PreparedNativeDraft(
      this.bootstrap,
      this.manifest,
      this.maps,
      this.tilesets,
      this.companions,
      this.catalog,
      this.dialogueSources,
      this.audio,
      this.itemCatalog,
      this.pokemonDocuments);
  final ProjectManifest bootstrap;
  final ProjectManifest manifest;
  final Map<String, MapData> maps;
  final Map<String, NativeArtifact> tilesets;
  final Map<String, NativeArtifact> companions;
  final AssetCatalog catalog;
  final Map<String, String> dialogueSources;
  final Map<String, NativeArtifact> audio;
  final ProjectItemCatalog? itemCatalog;
  final List<SourceCatalogDocument> pokemonDocuments;
}

({Map<String, NativeArtifact> artifacts, Map<String, (int, int)> dimensions})
    _preflightNativeResourceBudget(
        NativeProjectDraft draft, NativeWriteLimits limits) {
  if (draft.artifacts.length + draft.sourceArtifacts.length >
      limits.maxArtifacts) {
    throw const NativeWriteException('native.quota.draft',
        'Retained artifact and source witness count exceeds the budget');
  }
  final artifacts = <String, NativeArtifact>{};
  final dimensions = <String, (int, int)>{};
  final witnessHandles = <String>{};
  var totalBytes = 0;
  var totalPixels = 0;
  for (final entry in [
    for (final artifact in draft.artifacts) (artifact, false),
    for (final artifact in draft.sourceArtifacts) (artifact, true),
  ]) {
    final artifact = entry.$1;
    final witness = entry.$2;
    totalBytes += artifact.bytes.length;
    if (artifact.bytes.length > limits.maxArtifactBytes ||
        totalBytes > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('native.quota.artifact',
          'Retained artifact and source witness byte budget exceeded');
    }
    if (witness
        ? !witnessHandles.add(artifact.handle)
        : artifacts.containsKey(artifact.handle)) {
      throw const NativeWriteException('native.artifact.duplicate',
          'Duplicate artifact handles are not admitted');
    }
    if (artifact.reference.mediaType == 'image/png') {
      final size = _pngHeaderDimensions(artifact.bytes, limits);
      totalPixels += size.$1 * size.$2;
      if (totalPixels > limits.maxImagePixels) {
        throw const NativeWriteException('native.quota.image',
            'Aggregate retained image pixel budget exceeded');
      }
      if (!witness) dimensions[artifact.handle] = size;
    } else if (_nativeAudioMediaTypes.contains(artifact.reference.mediaType) &&
        !witness) {
      _validateNativeAudioArtifact(
          artifact.bytes, artifact.reference.mediaType);
    } else if (artifact.reference.mediaType != 'application/json') {
      throw const NativeWriteException('native.library.witness',
          'Source witnesses must be exact admitted PNG images');
    } else {
      _validateNativeArtifactJson(artifact.bytes, limits.jsonLimits);
    }
    if (!witness) artifacts[artifact.handle] = artifact;
  }
  var importBytes = 0;
  var importPixels = 0;
  for (final mutation in draft.mutations) {
    if (mutation.actionId != 'tileset.import_image' &&
        mutation.actionId != 'asset.import') {
      continue;
    }
    final handle = mutation.parameters['artifactHandle'];
    final artifact = artifacts[handle];
    final size = dimensions[handle];
    if (artifact == null ||
        (mutation.actionId == 'tileset.import_image' && size == null)) {
      throw const NativeWriteException('native.tileset.invalid',
          'An imported resource must name an admitted artifact');
    }
    importBytes += artifact.bytes.length;
    if (size != null) importPixels += size.$1 * size.$2;
    if (importBytes > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('native.quota.artifact',
          'Aggregate logical import byte budget exceeded');
    }
    if (importPixels > limits.maxImagePixels) {
      throw const NativeWriteException('native.quota.image',
          'Aggregate logical image import pixel budget exceeded');
    }
  }
  return (artifacts: artifacts, dimensions: dimensions);
}

Future<_PreparedNativeDraft> _prepareNativeDraft(
    ConversionPlan plan,
    PlanContext context,
    NativeProjectDraft draft,
    NativeWriteLimits limits,
    ScanCancellation? cancellation) async {
  if (!plan.outputPolicy.offline ||
      !plan.outputPolicy.destinationMustBeNew ||
      plan.outputPolicy.destinationFolderName != draft.folderName) {
    throw const NativeWriteException('native.output.policy',
        'The approved output must be offline and use the exact new destination folder');
  }
  if (draft.source.snapshot.state != SourceScanState.complete ||
      !draft.source.canPlan ||
      !draft.source.archive.isSealed ||
      draft.source.snapshot.canonicalHash != plan.sourceSnapshotHash ||
      draft.source.snapshot.logicalProjectNamespace !=
          plan.logicalProjectNamespace) {
    throw const NativeWriteException('native.source.context',
        'Normalized source differs from the approved plan context');
  }
  if (draft.artifacts.length + draft.sourceArtifacts.length >
          limits.maxArtifacts ||
      draft.mutations.length > limits.maxMutations ||
      draft.mapIds.length > limits.maxMutations) {
    throw const NativeWriteException(
        'native.quota.draft', 'Draft collection budget exceeded');
  }
  canonicalJsonOf(draft._binding, limits: limits.jsonLimits);
  final wantedMaps = {
    ...plan.selectedSourceMapIds,
    ...plan.dependencySourceMapIds
  };
  if (wantedMaps.isEmpty ||
      wantedMaps.length != draft.mapIds.length ||
      !wantedMaps.containsAll(draft.mapIds.keys) ||
      draft.mapIds.values.toSet().length != draft.mapIds.length ||
      !draft.source.selectedSourceMapIds
          .toSet()
          .containsAll(plan.selectedSourceMapIds) ||
      !wantedMaps.every(
          (id) => draft.source.maps.any((map) => map.map.sourceMapId == id))) {
    throw const NativeWriteException('native.maps.binding',
        'Native map identities differ from the approved source selection');
  }
  _verifyLiteralCompositionBinding(plan, draft, limits);
  if (draft.sourceArtifacts.isNotEmpty &&
      !draft.compositionEvidence.containsKey('assetLibrary') &&
      !draft.compositionEvidence.containsKey('sourceSemantics')) {
    throw const NativeWriteException('native.library.evidence',
        'Source witnesses require an exact approved asset library binding');
  }
  final planned = plan.operations
      .where((operation) => operation.status == OperationStatus.planned)
      .toList();
  if (planned.length != draft.mutations.length) {
    throw const NativeWriteException('native.operations.binding',
        'Every planned operation must have exactly one native mutation');
  }
  final operationIds = <ConverterId>{};
  for (var i = 0; i < draft.mutations.length; i++) {
    final mutation = draft.mutations[i];
    final operation = planned[i];
    final domain = mutation.domain;
    if (mutation.operationId != operation.operationId ||
        mutation.actionId != operation.targetActionId ||
        mutation.actionVersion != 1 ||
        operation.domain != domain ||
        !operationIds.add(mutation.operationId) ||
        !_sameIds(mutation.sourceEntityIds, operation.sourceEntityIds) ||
        !_sameIds(mutation.targetEntityIds, operation.targetEntityIds) ||
        !operation.evidenceRefs.contains(draft.bindingEvidence) ||
        mutation.sourceEntityIds.isEmpty ||
        mutation.sourceEntityIds.length > limits.maxMutations ||
        mutation.targetEntityIds.length > limits.maxMutations) {
      throw const NativeWriteException('native.operation.binding',
          'Native operation differs from its exact approved action, references or draft evidence');
    }
    final ordinary = const {
      'tileset.import_image',
      'tileset.upsert',
      'map.create',
      'map.save'
    }.contains(mutation.actionId);
    final library = draft.compositionEvidence.containsKey('assetLibrary') &&
        const {'element_category.upsert', 'element.upsert', 'asset.import'}
            .contains(mutation.actionId);
    final semantic = draft.compositionEvidence.containsKey('sourceSemantics') &&
        const {
          'element_category.upsert',
          'element.upsert',
          'characterStudio.character.create',
          'characterStudio.character.update',
          'characterStudio.animationClip.upsert',
          'characterStudio.character.setDefault',
        }.contains(mutation.actionId);
    final event = draft.compositionEvidence.containsKey('sourceEvents') &&
        const {
          'asset.import',
          'fact.create',
          'fact.update',
          'entity.upsert',
          'trigger.create',
          'warp.create',
          'dialogue.create',
          'scene.upsert',
          'world_rule.create',
          'world_rule.update',
          'event_v2.registry_mode.set',
          'event_v2.record_upsert',
          'pokemon.catalog.write',
          'pokemon.configuration.set_enabled',
          'item.create',
          'scene.dialogue.audioMedia.import',
        }.contains(mutation.actionId);
    final catalogs = draft.compositionEvidence.containsKey('sourceCatalogs') &&
        const {
          'asset.import',
          'pokemon.configuration.set_enabled',
          'pokemon.catalog.write',
          'pokemon.species.write',
          'pokemon.documents.write',
          'pokemon.learnset.write',
          'pokemon.evolution.write',
          'pokemon.media.write',
          'campaign.encounter_table.upsert',
          'campaign.trainer.upsert',
        }.contains(mutation.actionId);
    if (!ordinary && !library && !semantic && !event && !catalogs) {
      throw const NativeWriteException('native.action.unsupported',
          'Only image import, atlas animation upsert, map creation and native map save are admitted');
    }
  }
  final budget = _preflightNativeResourceBudget(draft, limits);
  final artifacts = budget.artifacts;
  final dimensions = budget.dimensions;
  final semantics = await _verifySourceSemantics(draft, limits, cancellation);
  final library = await _verifyApprovedAssetLibrary(
      plan, context, draft, limits, cancellation, semantics);
  if (semantics.verified &&
      (draft.mutations.any((mutation) =>
              !semantics.regeneratedOperationIds
                  .contains(mutation.operationId) &&
              !library.operationIds.contains(mutation.operationId)) ||
          draft.artifacts.any((artifact) =>
              !semantics.artifactHandles.contains(artifact.handle) &&
              !library.artifactHandles.contains(artifact.handle)))) {
    throw const NativeWriteException('native.semantics.regeneration',
        'Every semantic study operation and output artifact requires exact regeneration');
  }
  final candidateIds =
      context.candidates.map((candidate) => candidate.candidateId).toSet();
  for (final mutation in draft.mutations) {
    if (mutation.sourceEntityIds.any(candidateIds.contains) &&
        !library.operationIds.contains(mutation.operationId)) {
      throw const NativeWriteException('native.library.consumer',
          'Candidate-consuming mutations require their exact approved library binding');
    }
  }
  for (final artifact in draft.artifacts) {
    if (artifact.reference.mediaType == 'image/png') {
      _pngDimensions(artifact.bytes, limits);
    } else if (!library.artifactHandles.contains(artifact.handle) &&
        !semantics.artifactHandles.contains(artifact.handle)) {
      throw const NativeWriteException('native.library.companion',
          'JSON artifacts require an exact approved companion binding');
    }
  }
  final bootstrap = ProjectManifest(
      name: draft.projectName.trim(),
      version: ProjectVersion.v8,
      maps: const [],
      tilesets: const [],
      settings: ProjectSettings(
          dimension: ProjectDimension.twoD,
          tileWidth: 32,
          tileHeight: 32,
          defaultMapWidth: draft.defaultMapWidth,
          defaultMapHeight: draft.defaultMapHeight),
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
  final tilesets = <String, NativeArtifact>{};
  final tilesetEntries = <ProjectTilesetEntry>[];
  final mapEntries = <ProjectMapEntry>[];
  final maps = <String, MapData>{};
  final createdMaps = <String, Map<String, Object?>>{};
  final animatedTilesets = <String>{};
  final usedArtifacts = <String>{};
  final companions = <String, NativeArtifact>{};
  final audio = <String, NativeArtifact>{};
  final mediaAssets = <CinematicMediaAsset>[];
  final categories = <ProjectElementCategory>[];
  final elements = <ProjectElementEntry>[];
  final characters = <ProjectCharacterEntry>[];
  String? defaultPlayerCharacterId;
  final assetRecords = <AssetRecord>[];
  var mapCells = 0;
  for (var i = 0; i < draft.mutations.length; i++) {
    final mutation = draft.mutations[i];
    final parameters = mutation.parameters;
    switch (mutation.actionId) {
      case 'tileset.import_image':
        _allowParameters(parameters, const {
          'artifactHandle',
          'tilesetId',
          'name',
          'tileWidth',
          'tileHeight'
        });
        final id = _string(parameters, 'tilesetId');
        final name = _string(parameters, 'name');
        final handle = _string(parameters, 'artifactHandle');
        final artifact = artifacts[handle];
        final cellWidth = parameters['tileWidth'];
        final cellHeight = parameters['tileHeight'];
        final feedbackIcon = semantics.events?.draft.mutations.any((entry) =>
                entry.operationId == mutation.operationId &&
                entry.actionId == 'tileset.import_image' &&
                entry.parameters['tileWidth'] == 1 &&
                entry.parameters['tileHeight'] == 1) ??
            false;
        if (id.length > 64 ||
            !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
            tilesets.keys.any((key) => key.toLowerCase() == id.toLowerCase()) ||
            artifact == null ||
            artifact.reference.mediaType != 'image/png' ||
            (cellWidth != 32 || cellHeight != 32) &&
                !(feedbackIcon && cellWidth == 1 && cellHeight == 1) ||
            !_targetIds(mutation.targetEntityIds, {id, 'image_$id'})) {
          throw const NativeWriteException('native.tileset.invalid',
              'A unique native atlas, its asset identity and explicit 32px grid are required');
        }
        final size = dimensions[handle]!;
        if (size.$1 % (cellWidth as int) != 0 ||
            size.$2 % (cellHeight as int) != 0) {
          throw const NativeWriteException('native.tileset.geometry',
              'Atlas image must contain complete 32px cells');
        }
        tilesets[id] = artifact;
        usedArtifacts.add(handle);
        assetRecords.add(AssetRecord(
            id: 'image_$id',
            logicalPath: 'assets/studio/$id.png',
            artifact: artifact.reference,
            usages: const ['tileset']));
        tilesetEntries.add(ProjectTilesetEntry(
            id: id,
            name: name,
            relativePath: 'assets/studio/$id.png',
            source: ProjectRegularAtlasTilesetSource(
                assetId: 'image_$id',
                pixelWidth: size.$1,
                pixelHeight: size.$2,
                tileWidth: cellWidth,
                tileHeight: cellHeight)));
      case 'tileset.upsert':
        _allowParameters(parameters, const {'tileset'});
        final raw = parameters['tileset'];
        if (raw is! Map<String, Object?>) {
          throw const NativeWriteException('native.tileset.animation',
              'Atlas animation must describe one canonical imported tileset');
        }
        final next =
            ProjectTilesetEntry.fromJson(Map<String, dynamic>.from(raw));
        final index = tilesetEntries.indexWhere((entry) => entry.id == next.id);
        final atlas = next.source;
        final imported = draft.mutations.where((entry) =>
            entry.actionId == 'tileset.import_image' &&
            entry.parameters['tilesetId'] == next.id);
        if (index < 0 ||
            atlas is! ProjectRegularAtlasTilesetSource ||
            imported.length != 1 ||
            !_sameIds(
                mutation.sourceEntityIds, imported.single.sourceEntityIds) ||
            !_targetIds(mutation.targetEntityIds, {next.id}) ||
            !animatedTilesets.add(next.id) ||
            createdMaps.isNotEmpty ||
            canonicalJsonOf(next.toJson(), limits: limits.jsonLimits) !=
                canonicalJsonOf(raw, limits: limits.jsonLimits)) {
          throw const NativeWriteException('native.tileset.animation',
              'A unique canonical animation upsert must follow its exact image import before map creation');
        }
        final unchanged = next.toJson();
        final unchangedSource = Map<String, Object?>.from(atlas.toJson())
          ..remove('tileAnimations');
        unchanged['source'] = unchangedSource;
        if (!semantics.operationIds.contains(mutation.operationId) &&
            canonicalJsonOf(unchanged, limits: limits.jsonLimits) !=
                canonicalJsonOf(tilesetEntries[index].toJson(),
                    limits: limits.jsonLimits)) {
          throw const NativeWriteException('native.tileset.animation',
              'An animation upsert must retain the imported identity, image, geometry and properties');
        }
        tilesetEntries[index] = next;
      case 'element_category.upsert':
        if (!semantics.operationIds.contains(mutation.operationId)) {
          _requireLibraryMutation(library, mutation);
        }
        _allowParameters(parameters, const {'category'});
        final category = ProjectElementCategory.fromJson(
            Map<String, dynamic>.from(parameters['category'] as Map));
        if (categories.any((entry) => entry.id == category.id) ||
            !_targetIds(mutation.targetEntityIds, {category.id})) {
          throw const NativeWriteException('native.library.category',
              'Library categories must be unique approved native identities');
        }
        categories.add(category);
      case 'element.upsert':
        if (!semantics.operationIds.contains(mutation.operationId)) {
          _requireLibraryMutation(library, mutation);
        }
        _allowParameters(parameters, const {'element'});
        final element = ProjectElementEntry.fromJson(
            Map<String, dynamic>.from(parameters['element'] as Map));
        if (elements.any((entry) => entry.id == element.id) ||
            !categories.any((entry) => entry.id == element.categoryId) ||
            !tilesets.containsKey(element.tilesetId) ||
            !_targetIds(mutation.targetEntityIds, {element.id})) {
          throw const NativeWriteException('native.library.element',
              'Library elements require their exact preceding category and atlas');
        }
        elements.add(element);
      case 'characterStudio.character.create':
        semantics.requireOperation(mutation);
        final name = _string(parameters, 'name');
        final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
        if (characters.any((entry) => entry.id == id) ||
            !tilesets.containsKey(parameters['tilesetId']) ||
            !_targetIds(mutation.targetEntityIds, {id})) {
          throw const NativeWriteException('native.semantics.character',
              'Semantic player identity must follow its exact imported atlas');
        }
        characters.add(ProjectCharacterEntry(
            id: id,
            name: name,
            sortOrder: characters.length,
            tilesetId: parameters['tilesetId'] as String,
            frameWidth: parameters['frameWidth'] as int,
            frameHeight: parameters['frameHeight'] as int,
            tags: (parameters['tags'] as List).cast<String>()));
      case 'characterStudio.character.update':
        semantics.requireOperation(mutation);
        final id = _string(parameters, 'characterId');
        final index = characters.indexWhere((entry) => entry.id == id);
        if (index < 0 || !_targetIds(mutation.targetEntityIds, {id})) {
          throw const NativeWriteException('native.semantics.character',
              'Source event character labels require their preceding canonical identity');
        }
        characters[index] =
            characters[index].copyWith(name: _string(parameters, 'name'));
      case 'characterStudio.animationClip.upsert':
        semantics.requireOperation(mutation);
        final id = _string(parameters, 'characterId');
        final index = characters.indexWhere((entry) => entry.id == id);
        if (index < 0) {
          throw const NativeWriteException('native.semantics.character',
              'Semantic player clips require their preceding identity');
        }
        final clip = CharacterAnimation(
            state: CharacterAnimationState.values
                .singleWhere((entry) => entry.name == parameters['state']),
            direction: EntityFacing.values
                .singleWhere((entry) => entry.name == parameters['direction']),
            sourceAssetId: parameters['sourceAssetId'] as String,
            loop: parameters['loop'] as bool,
            frames: [
              for (final frame in parameters['frames'] as List)
                CharacterAnimationFrame.fromJson(
                    Map<String, dynamic>.from(frame)),
            ]);
        characters[index] = characters[index]
            .copyWith(animations: [...characters[index].animations, clip]);
      case 'characterStudio.character.setDefault':
        semantics.requireOperation(mutation);
        final id = _string(parameters, 'characterId');
        if (!characters.any((entry) => entry.id == id)) {
          throw const NativeWriteException('native.semantics.character',
              'Semantic player default requires its preceding character');
        }
        defaultPlayerCharacterId = id;
      case 'scene.dialogue.audioMedia.import':
        semantics.requireOperation(mutation);
        _allowParameters(parameters, const {
          'artifactHandle',
          'assetId',
          'mediaId',
          'label',
          'logicalPath'
        });
        final handle = _string(parameters, 'artifactHandle');
        final id = _string(parameters, 'assetId');
        final mediaId = _string(parameters, 'mediaId');
        final logicalPath = _string(parameters, 'logicalPath');
        final artifact = artifacts[handle];
        if (artifact == null ||
            !_nativeAudioMediaTypes.contains(artifact.reference.mediaType) ||
            audio.containsKey(id) ||
            mediaAssets.any((entry) => entry.id == mediaId)) {
          throw const NativeWriteException('native.events.audio',
              'One exact regenerated finite sound is required');
        }
        final inspected = const PresentationMediaHeaderProbe().inspect(
            artifact.bytes,
            declaredMediaType: artifact.reference.mediaType);
        audio[id] = artifact;
        usedArtifacts.add(handle);
        assetRecords.add(AssetRecord(
            id: id,
            logicalPath: logicalPath,
            artifact: artifact.reference,
            usages: const ['dialogueAudio']));
        mediaAssets.add(CinematicMediaAsset(
            id: mediaId,
            label: _string(parameters, 'label'),
            kind: CinematicMediaAssetKind.sound,
            relativePath: logicalPath,
            durationMs: inspected.durationMilliseconds,
            metadata: {
              'sourceAssetId': id,
              'mediaType': inspected.mediaType,
              'container': inspected.container,
              'codec': inspected.codec
            }));
      case 'asset.import':
        if (!semantics.operationIds.contains(mutation.operationId)) {
          _requireLibraryMutation(library, mutation);
        }
        _allowParameters(parameters, const {
          'artifactHandle',
          'assetId',
          'logicalPath',
          'tags',
          'usages'
        });
        final id = _string(parameters, 'assetId');
        final handle = _string(parameters, 'artifactHandle');
        final artifact = artifacts[handle];
        if (artifact == null ||
            artifact.reference.mediaType != 'application/json' ||
            companions.containsKey(id) ||
            !_targetIds(mutation.targetEntityIds, {id})) {
          throw const NativeWriteException('native.library.companion',
              'Only unique exact approved JSON provenance companions may be imported');
        }
        companions[id] = artifact;
        usedArtifacts.add(handle);
        assetRecords.add(AssetRecord(
            id: id,
            logicalPath: _string(parameters, 'logicalPath'),
            artifact: artifact.reference,
            tags: (parameters['tags'] as List).cast<String>(),
            usages: (parameters['usages'] as List).cast<String>()));
      case 'map.create':
        _allowParameters(parameters, const {
          'mapId',
          'name',
          'width',
          'height',
          'groupId',
          'role',
          'tilesetId'
        });
        final id = _string(parameters, 'mapId');
        _requireMapBinding(draft, mutation, id);
        final width = parameters['width'];
        final height = parameters['height'];
        final tileset = parameters['tilesetId'] ??
            (tilesets.length == 1 ? tilesets.keys.single : null);
        if (width is! int ||
            height is! int ||
            width <= 0 ||
            height <= 0 ||
            width > limits.maxMapCells ||
            height > limits.maxMapCells ||
            width > limits.maxMapCells ~/ height ||
            createdMaps.containsKey(id) ||
            tileset is! String ||
            !tilesets.containsKey(tileset) ||
            parameters['groupId'] != null) {
          throw const NativeWriteException('native.map.create',
              'Map creation must have bounded geometry and an unambiguous imported atlas');
        }
        final roleName = parameters['role'] ?? 'exterior';
        final role =
            MapRole.values.where((role) => role.name == roleName).firstOrNull;
        if (role == null) {
          throw const NativeWriteException(
              'native.map.role', 'Unknown native map role');
        }
        final name =
            parameters['name'] == null ? id : _string(parameters, 'name');
        mapCells += width * height;
        if (mapCells > limits.maxMapCells) {
          throw const NativeWriteException(
              'native.quota.map', 'Aggregate map cell budget exceeded');
        }
        createdMaps[id] = parameters;
        mapEntries.add(ProjectMapEntry(
            id: id, name: name, relativePath: 'maps/$id.json', role: role));
      case 'map.save':
        _allowParameters(parameters, const {'map'});
        final raw = parameters['map'];
        if (raw is! Map<String, Object?> ||
            raw['version'] != 'v8' ||
            raw.containsKey('spatialScene')) {
          throw const NativeWriteException('native.map.codec',
              'A current native v8 two-dimensional map is required');
        }
        final rawLayers = raw['layers'];
        if (rawLayers is! List ||
            rawLayers.any((layer) =>
                layer is! Map ||
                layer.containsKey('tiles') ||
                (layer['kind'] == 'tile' && layer.containsKey('tilesetId')))) {
          throw const NativeWriteException('native.map.legacy',
              'Map layers must use the current native palette/cells codec');
        }
        final map = MapData.fromJson(Map<String, dynamic>.from(raw));
        _requireMapBinding(draft, mutation, map.id);
        final initial = createdMaps[map.id];
        if (initial == null ||
            maps.containsKey(map.id) ||
            map.size.width != initial['width'] ||
            map.size.height != initial['height'] ||
            map.visualStack == null ||
            canonicalJsonOf(map.toJson(), limits: limits.jsonLimits) !=
                canonicalJsonOf(raw, limits: limits.jsonLimits)) {
          throw const NativeWriteException('native.map.save',
              'A canonical map save must follow the exact approved creation geometry');
        }
        maps[map.id] = map;
      case 'pokemon.catalog.write':
      case 'pokemon.configuration.set_enabled':
        semantics.requireOperation(mutation);
        if (semantics.events == null && semantics.catalogs == null) {
          throw const NativeWriteException('native.catalogs.binding',
              'Catalog mutations require exact regenerated source projection');
        }
      case 'pokemon.species.write':
      case 'pokemon.documents.write':
      case 'pokemon.learnset.write':
      case 'pokemon.evolution.write':
      case 'pokemon.media.write':
      case 'campaign.encounter_table.upsert':
      case 'campaign.trainer.upsert':
        semantics.requireOperation(mutation);
        if (semantics.catalogs == null) {
          throw const NativeWriteException('native.catalogs.binding',
              'Catalog documents require their exact regenerated source projection');
        }
      case 'item.create':
      case 'fact.create':
      case 'fact.update':
      case 'entity.upsert':
      case 'trigger.create':
      case 'warp.create':
      case 'dialogue.create':
      case 'scene.upsert':
      case 'world_rule.create':
      case 'world_rule.update':
      case 'event_v2.registry_mode.set':
      case 'event_v2.record_upsert':
        semantics.requireOperation(mutation);
        if (semantics.events == null) {
          throw const NativeWriteException('native.events.binding',
              'Event mutations require their exact regenerated source event projection');
        }
      default:
        throw const NativeWriteException('native.action.unsupported',
            'Only image import, atlas animation upsert, map creation and native map save are admitted');
    }
  }
  if (usedArtifacts.length != artifacts.length ||
      tilesets.isEmpty ||
      maps.length != draft.mapIds.length ||
      createdMaps.length != maps.length ||
      !maps.keys.toSet().containsAll(draft.mapIds.values)) {
    throw const NativeWriteException('native.draft.incomplete',
        'The approved draft must account for every artifact and every final map');
  }
  tilesetEntries.sort((left, right) => left.id.compareTo(right.id));
  elements.sort((left, right) => left.id.compareTo(right.id));
  final projectedEvents = semantics.events?.projection;
  final projectedCatalogs = semantics.catalogs?.projection;
  if (projectedEvents != null) {
    maps
      ..clear()
      ..addEntries(projectedEvents.nativeMaps.values
          .map((map) => MapEntry(map.id, map)));
  }
  final manifest = bootstrap.copyWith(
      maps: mapEntries,
      tilesets: tilesetEntries,
      elements: elements,
      elementCategories: categories,
      characters: characters,
      pokemon: bootstrap.pokemon.copyWith(
          enabled: projectedEvents?.itemCatalog != null ||
              projectedCatalogs?.mergedItemCatalog != null ||
              (projectedCatalogs?.documents.isNotEmpty ?? false)),
      encounterTables: projectedCatalogs?.encounterTables ?? const [],
      trainers: projectedCatalogs?.trainers ?? const [],
      cinematicMediaAssets: mediaAssets,
      facts: projectedEvents?.facts ?? const [],
      worldRules: projectedEvents?.worldRules ?? const [],
      eventRegistry: projectedEvents?.registry,
      dialogues: projectedEvents?.dialogues ?? const [],
      scenes: projectedEvents?.scenes ?? const [],
      settings: bootstrap.settings
          .copyWith(defaultPlayerCharacterId: defaultPlayerCharacterId));
  if (projectedCatalogs != null) {
    _validateCatalogReferences(projectedCatalogs, manifest);
  }
  ProjectValidator.validate(manifest, maps: maps.values);
  for (final map in maps.values) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  if (projectedEvents != null) {
    for (final scene in projectedEvents.scenes) {
      try {
        const SceneActions()
            .upsert(manifest, maps: maps.values.toList(), scene: scene);
      } on NarrativeAuthoringException catch (error) {
        throw NativeWriteException('native.events.scene',
            '${error.code}: ${canonicalJsonOf(error.details, limits: limits.jsonLimits)}');
      }
    }
    const SourceEventArrivalValidator().validate(
        manifest: manifest,
        maps: maps.values.toList(),
        arrivalAnchorIds:
            (projectedEvents.semanticEvidence['arrivalAnchors'] as List)
                .map((entry) => (entry as Map)['warpId'] as String),
        cancellation: cancellation);
  }
  if (!semantics.verified) {
    _verifyLiteralCompositionContents(draft, maps, limits, library);
  }
  return _PreparedNativeDraft(
      bootstrap,
      manifest,
      maps,
      tilesets,
      companions,
      AssetCatalog(records: assetRecords),
      projectedEvents?.dialogueSources ?? const {},
      audio,
      projectedCatalogs?.mergedItemCatalog ?? projectedEvents?.itemCatalog,
      projectedCatalogs?.documents ?? const []);
}

void _validateCatalogReferences(
    SourceCatalogProjection projection, ProjectManifest manifest) {
  final documents = projection.documents;
  final species = <String, PokemonSpeciesFile>{
    for (final document in documents
        .where((entry) => entry.kind == SourceCatalogDocumentKind.species))
      document.document['id'] as String: PokemonSpeciesFile.fromJson(
          Map<String, dynamic>.from(document.document))
  };
  final catalogs = <String, Set<String>>{};
  for (final document in documents
      .where((entry) => entry.kind == SourceCatalogDocumentKind.catalog)) {
    if (document.document['catalog'] == null) continue;
    final value = PokemonCatalogFile.fromJson(
        Map<String, dynamic>.from(document.document));
    catalogs[value.catalog] = value.entries
        .map((entry) => (entry['id'] ?? entry['slug']) as String)
        .toSet();
  }
  final itemIds =
      projection.mergedItemCatalog?.entries.map((entry) => entry.id).toSet() ??
          <String>{};
  void require(String family, String? value) {
    if (value == null) return;
    final present = switch (family) {
      'species' => species.containsKey(value),
      'items' => itemIds.contains(value),
      _ => catalogs[family]?.contains(value) ?? false,
    };
    if (!present) {
      throw NativeWriteException('native.catalogs.reference',
          'A projected $family reference has no exact native definition: $value');
    }
  }

  void form(String speciesId, String? formId) {
    require('species', speciesId);
    if (formId == null) return;
    final owner = species[speciesId]!;
    final declared =
        owner.forms.formId == formId || owner.forms.otherForms.contains(formId);
    final exists = species.values.any((entry) =>
        entry.forms.baseFormId == owner.forms.baseFormId &&
        entry.forms.formId == formId);
    if (!declared || !exists) {
      throw const NativeWriteException('native.catalogs.form',
          'A projected form must belong to its exact species definition');
    }
  }

  for (final table in manifest.encounterTables) {
    if (table.chancePerStep != 0.0) {
      throw const NativeWriteException('native.catalogs.activation',
          'Imported encounter data requires separate native runtime qualification');
    }
    for (final entry in table.entries) {
      require('species', entry.speciesId);
      final overrides = entry.pokemonOverrides;
      require('natures', overrides?.natureId);
      require('abilities', overrides?.abilityId);
      for (final move in overrides?.knownMoveIds ?? <String>[]) {
        require('moves', move);
      }
    }
  }
  for (final trainer in manifest.trainers) {
    if (trainer.team.isEmpty) {
      throw const NativeWriteException('native.catalogs.trainer',
          'A projected trainer cannot have an empty native team');
    }
    for (final entry in trainer.team) {
      form(entry.speciesId, entry.formId);
      require('items', entry.heldItemId);
      require('abilities', entry.abilityId);
      for (final move in entry.moves) {
        require('moves', move);
      }
    }
  }
}

Future<void> _verifyNativeCatalogs(
    _NativeSession session,
    _PreparedNativeDraft prepared,
    NativeWriteLimits limits,
    ScanCancellation? cancellation) async {
  if (prepared.pokemonDocuments.isEmpty) return;
  final access = session.handles.resolveProject(session.project);
  final expectedPaths = <String>{};
  for (final document in prepared.pokemonDocuments) {
    _checkCancelled(cancellation);
    expectedPaths.add(document.relativePath);
    final before = await access.readResourceIdentity(document.relativePath);
    final bytes = await access.readBytes(document.relativePath);
    final after = await access.readResourceIdentity(document.relativePath);
    if (before == null ||
        before != after ||
        bytes.length != before.byteLength ||
        canonicalJsonOf(jsonDecode(utf8.decode(bytes)),
                limits: limits.jsonLimits) !=
            canonicalJsonOf(document.document, limits: limits.jsonLimits)) {
      throw const NativeWriteException('native.verify.pokemon_document',
          'Fresh native Pokemon data differs from its source-bound projection');
    }
  }
  for (final directory in [
    prepared.manifest.pokemon.speciesDir,
    prepared.manifest.pokemon.learnsetsDir,
    prepared.manifest.pokemon.evolutionsDir,
    prepared.manifest.pokemon.mediaDir
  ]) {
    final expected =
        expectedPaths.where((value) => value.startsWith('$directory/')).toSet();
    Set<String> actual;
    try {
      final listed = await access.listFiles(directory);
      if (listed == null) {
        throw const NativeWriteException('native.verify.pokemon_inventory',
            'Native Pokemon data requires an exact available directory inventory');
      }
      actual = listed.where((value) => value.endsWith('.json')).toSet();
    } on WorkspaceAccessException catch (error) {
      if (error.code != 'workspace.directory_missing') rethrow;
      actual = {};
    }
    if (expected.length != actual.length || !expected.containsAll(actual)) {
      throw const NativeWriteException('native.verify.pokemon_inventory',
          'Fresh Pokemon document inventory must equal its complete projection');
    }
  }
  final validation = await AuthoringReadApi(
          openService: session.opener, snapshotLoader: session.snapshots)
      .validateProject(session.project);
  if (!validation.valid) {
    throw NativeWriteException('native.verify.pokemon_coherence',
        canonicalJsonOf(validation.toJson(), limits: limits.jsonLimits));
  }
}

final class _VerifiedAssetLibrary {
  const _VerifiedAssetLibrary(this.operationIds, this.artifactHandles);
  final Set<ConverterId> operationIds;
  final Set<String> artifactHandles;
}

final class _WitnessSourceFiles implements SourceFilePort {
  const _WitnessSourceFiles(this.bytes);
  final Map<ConverterId, List<int>> bytes;

  @override
  Future<List<int>> read(ConverterId fileId) async =>
      bytes[fileId] ??
      (throw const NativeWriteException('native.library.witness',
          'A source image is not present among the declared witnesses'));
}

final class _VerifiedSourceSemantics {
  const _VerifiedSourceSemantics(this.verified, this.operationIds,
      this.regeneratedOperationIds, this.artifactHandles, this.witnessHandles,
      {this.events, this.catalogs});

  final bool verified;
  final Set<ConverterId> operationIds;
  final Set<ConverterId> regeneratedOperationIds;
  final Set<String> artifactHandles;
  final Set<String> witnessHandles;
  final SourceEventStudyComposition? events;
  final SourceCatalogStudyComposition? catalogs;

  void requireOperation(NativeMutation mutation) {
    if (!verified || !operationIds.contains(mutation.operationId)) {
      throw const NativeWriteException('native.semantics.consumer',
          'Source semantic operations require exact bounded regeneration');
    }
  }
}

Future<_VerifiedSourceSemantics> _verifySourceSemantics(
    NativeProjectDraft draft,
    NativeWriteLimits limits,
    ScanCancellation? cancellation) async {
  final raw = draft.compositionEvidence['sourceSemantics'];
  if (raw == null) {
    if (draft.compositionEvidence.containsKey('sourceEvents') ||
        draft.compositionEvidence.containsKey('sourceCatalogs')) {
      throw const NativeWriteException('native.events.binding',
          'Event conversion requires preceding qualified source semantics');
    }
    return const _VerifiedSourceSemantics(false, {}, {}, {}, {});
  }
  if (raw is! Map<String, Object?> ||
      raw['kind'] != 'sourceSemanticStudy' ||
      raw['version'] != 1 ||
      raw['witnesses'] is! List ||
      (raw['witnesses'] as List).length > limits.maxArtifacts ||
      !SourceSemanticResolver.forProject(draft.source).profile.isQualified) {
    throw const NativeWriteException('native.semantics.evidence',
        'Source semantics require an admitted profile and exact witness evidence');
  }
  final supplied = {
    for (final artifact in draft.sourceArtifacts) artifact.handle: artifact
  };
  final entries = {
    for (final entry in draft.source.snapshot.entries) entry.fileId.value: entry
  };
  final files = <ConverterId, List<int>>{};
  final witnessHandles = <String>{};
  var decodedByteBudget = 0;
  var witnessReferenceCount = 0;
  final eventRaw = draft.compositionEvidence['sourceEvents'];
  final catalogRaw = draft.compositionEvidence['sourceCatalogs'];
  if (catalogRaw != null &&
      (catalogRaw is! Map<String, Object?> ||
          catalogRaw['kind'] != 'sourceCatalogStudy' ||
          catalogRaw['version'] != 1 ||
          catalogRaw['witnesses'] is! List)) {
    throw const NativeWriteException('native.catalogs.evidence',
        'Source catalogs require exact bounded witness evidence');
  }
  if (eventRaw != null &&
      (eventRaw is! Map<String, Object?> ||
          eventRaw['kind'] != 'sourceEventStudy' ||
          eventRaw['version'] != 1 ||
          eventRaw['witnesses'] is! List)) {
    throw const NativeWriteException('native.events.evidence',
        'Event evidence must contain one bounded source event composition');
  }
  final witnessRows = <String, Object?>{};
  final suppliedRows = [
    ...raw['witnesses'] as List,
    if (eventRaw is Map<String, Object?>) ...eventRaw['witnesses'] as List,
    if (catalogRaw is Map<String, Object?>) ...catalogRaw['witnesses'] as List,
  ];
  if (suppliedRows.length > limits.maxArtifacts * 3) {
    throw const NativeWriteException('native.semantics.witness_quota',
        'Combined semantic witness envelopes exceed the bounded input budget');
  }
  for (final row in suppliedRows) {
    if (row is! Map || row['fileId'] is! String) {
      throw const NativeWriteException('native.semantics.witness',
          'Semantic witnesses require bounded unique source references');
    }
    final id = row['fileId'] as String;
    final previous = witnessRows[id];
    if (previous == null && witnessRows.length >= limits.maxArtifacts) {
      throw const NativeWriteException('native.semantics.witness_quota',
          'Unique semantic source references exceed the bounded input budget');
    }
    if (previous != null && canonicalJsonOf(previous) != canonicalJsonOf(row)) {
      throw const NativeWriteException('native.semantics.witness',
          'A shared source witness cannot have conflicting envelopes');
    }
    witnessRows[id] = row;
  }
  for (final row in witnessRows.values) {
    if (row is! Map || row['fileId'] is! String) {
      throw const NativeWriteException('native.semantics.witness',
          'Source semantic witnesses must address inventoried files');
    }
    final entry = entries[row['fileId']];
    if (entry == null ||
        entry.sha256 == null ||
        entry.kind != SourceNodeKind.file ||
        entry.relativePath != row['relativePath'] ||
        entry.byteLength != row['byteLength'] ||
        entry.sha256!.value != row['rawSha256'] ||
        files.containsKey(entry.fileId)) {
      throw const NativeWriteException('native.semantics.witness',
          'Source semantic witnesses must bind exact unique snapshot entries');
    }
    final referenceCount = row['encoding'] == 'png'
        ? 1
        : row['chunks'] is List
            ? (row['chunks'] as List).length
            : 0;
    if ((row['encoding'] == 'png' &&
            entry.byteLength > limits.maxArtifactBytes) ||
        decodedByteBudget + entry.byteLength > limits.maxTotalArtifactBytes ||
        witnessReferenceCount + referenceCount > limits.maxArtifacts) {
      throw const NativeWriteException('native.semantics.witness_quota',
          'Decoded semantic source witnesses exceed the cumulative budget');
    }
    decodedByteBudget += entry.byteLength;
    witnessReferenceCount += referenceCount;
    List<int> bytes;
    if (row['encoding'] == 'png' && row['artifactHandle'] is String) {
      final artifact = supplied[row['artifactHandle']];
      if (artifact == null || artifact.reference.mediaType != 'image/png') {
        throw const NativeWriteException(
            'native.semantics.witness', 'Source image witness is missing');
      }
      bytes = artifact.bytes;
      witnessHandles.add(artifact.handle);
    } else if (row['encoding'] == 'canonicalJsonBase64Chunks' &&
        row['chunks'] is List) {
      final chunks = row['chunks'] as List;
      if (chunks.isEmpty || chunks.length > limits.maxArtifacts) {
        throw const NativeWriteException('native.semantics.witness',
            'Source byte witnesses require bounded ordered chunks');
      }
      final restored = BytesBuilder(copy: false);
      for (final chunk in chunks) {
        _checkCancelled(cancellation);
        if (chunk is! Map ||
            chunk['artifactHandle'] is! String ||
            chunk['offset'] != restored.length ||
            chunk['byteLength'] is! int ||
            (chunk['byteLength'] as int) < 0 ||
            (chunk['byteLength'] as int) >
                SourceSemanticWitnessFiles.chunkSize ||
            restored.length + (chunk['byteLength'] as int) > entry.byteLength) {
          throw const NativeWriteException('native.semantics.witness',
              'Source byte chunks must cover the admitted file in order');
        }
        final artifact = supplied[chunk['artifactHandle']];
        if (artifact == null ||
            artifact.reference.mediaType != 'application/json') {
          throw const NativeWriteException('native.semantics.witness',
              'Source byte witness chunk is missing');
        }
        final payload =
            _validateNativeArtifactJson(artifact.bytes, limits.jsonLimits);
        if (payload['kind'] != 'sourceSemanticByteChunk' ||
            payload['version'] != 1 ||
            payload['offset'] != restored.length ||
            payload['bytesBase64'] is! String ||
            payload.length != 4) {
          throw const NativeWriteException('native.semantics.witness',
              'Source byte chunks require the exact bounded canonical envelope');
        }
        try {
          final decoded = base64Decode(payload['bytesBase64'] as String);
          if (decoded.length != chunk['byteLength']) {
            throw const FormatException();
          }
          restored.add(decoded);
        } on FormatException {
          throw const NativeWriteException('native.semantics.witness',
              'Source witness chunk encoding is invalid');
        }
        witnessHandles.add(artifact.handle);
      }
      bytes = restored.takeBytes();
    } else {
      throw const NativeWriteException('native.semantics.witness',
          'Semantic source witness encoding is unsupported');
    }
    if (bytes.length != entry.byteLength ||
        sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw const NativeWriteException('native.semantics.witness',
          'Semantic source bytes differ from their admitted snapshot');
    }
    files[entry.fileId] = bytes;
  }
  _checkCancelled(cancellation);
  final NativeProjectDraft expected;
  SourceEventStudyComposition? eventComposition;
  SourceCatalogStudyComposition? catalogComposition;
  try {
    final composition = draft.compositionEvidence['composition'] as Map;
    final base = await const LiteralTileComposer().compose(
        source: draft.source,
        files: _WitnessSourceFiles(files),
        selectedSourceMapIds:
            (composition['selectedSourceMapIds'] as List).cast<int>(),
        projectName: draft.projectName,
        parentPath: draft.parentPath,
        folderName: draft.folderName,
        sourceRootPath: draft.sourceRootPath,
        dependencyDecisions: sourceSemanticDependencyDecisions(
            draft.source, composition['decisions'] as List),
        allowFirstFrameAutotiles:
            composition['allowFirstFrameAutotiles'] == true,
        limits: limits,
        cancellation: cancellation);
    final regenerated = await const SourceSemanticStudyComposer().compose(
        source: draft.source,
        base: base,
        files: _WitnessSourceFiles(files),
        limits: limits,
        cancellation: cancellation);
    if (regenerated == null) {
      throw const FormatException('Missing semantic draft');
    }
    if (eventRaw != null) {
      eventComposition = await const SourceEventStudyComposer().compose(
          source: draft.source,
          base: regenerated,
          files: _WitnessSourceFiles(files),
          limits: limits,
          cancellation: cancellation);
      if (eventComposition == null) {
        throw const FormatException('Missing source event draft');
      }
    }
    final preceding = eventComposition?.draft ?? regenerated;
    if (catalogRaw != null) {
      catalogComposition = await const SourceCatalogStudyComposer().compose(
          source: draft.source,
          base: preceding,
          files: _WitnessSourceFiles(files),
          limits: limits,
          cancellation: cancellation);
      if (catalogComposition == null) {
        throw const FormatException('Missing source catalog draft');
      }
    }
    expected = catalogComposition?.draft ?? preceding;
  } catch (_) {
    _checkCancelled(cancellation);
    throw const NativeWriteException('native.semantics.regeneration',
        'Source semantic draft could not be regenerated from its exact source witnesses');
  }
  final expectedIds =
      expected.mutations.map((mutation) => mutation.operationId).toSet();
  final actual = draft.mutations
      .where((mutation) => expectedIds.contains(mutation.operationId))
      .toList();
  final evidence = Map<String, Object?>.from(draft.compositionEvidence)
    ..remove('assetLibrary');
  final artifacts = {
    for (final artifact in draft.artifacts) artifact.handle: artifact
  };
  if (canonicalJsonOf(evidence, limits: limits.jsonLimits) !=
          canonicalJsonOf(expected.compositionEvidence,
              limits: limits.jsonLimits) ||
      canonicalJsonOf(
              [for (var i = 0; i < actual.length; i++) actual[i].toJson(i)],
              limits: limits.jsonLimits) !=
          canonicalJsonOf([
            for (var i = 0; i < expected.mutations.length; i++)
              expected.mutations[i].toJson(i)
          ], limits: limits.jsonLimits) ||
      expected.artifacts.any((artifact) =>
          artifacts[artifact.handle]?.rawSha256 != artifact.rawSha256) ||
      canonicalJsonOf(_artifactBindings(expected.sourceArtifacts),
              limits: limits.jsonLimits) !=
          canonicalJsonOf(
              _artifactBindings(draft.sourceArtifacts
                  .where((artifact) => witnessHandles.contains(artifact.handle))
                  .toList()),
              limits: limits.jsonLimits)) {
    throw const NativeWriteException('native.semantics.regeneration',
        'Source semantic mutations, pixels and evidence differ from deterministic regeneration');
  }
  final semanticIds = [
    ...((expected.compositionEvidence['sourceSemantics'] as Map)['operationIds']
            as List)
        .cast<String>()
  ];
  if (eventComposition != null) {
    semanticIds.addAll(((expected.compositionEvidence['sourceEvents']
            as Map)['operationIds'] as List)
        .cast<String>());
  }
  if (catalogComposition != null) {
    semanticIds.addAll(((expected.compositionEvidence['sourceCatalogs']
            as Map)['operationIds'] as List)
        .cast<String>());
  }
  return _VerifiedSourceSemantics(
      true,
      semanticIds.map(ConverterId.new).toSet(),
      expectedIds,
      expected.artifacts.map((artifact) => artifact.handle).toSet(),
      witnessHandles,
      events: eventComposition,
      catalogs: catalogComposition);
}

Future<_VerifiedAssetLibrary> _verifyApprovedAssetLibrary(
    ConversionPlan plan,
    PlanContext context,
    NativeProjectDraft draft,
    NativeWriteLimits limits,
    ScanCancellation? cancellation,
    _VerifiedSourceSemantics semantics) async {
  final raw = draft.compositionEvidence['assetLibrary'];
  if (raw == null) {
    if (draft.sourceArtifacts.any((artifact) =>
            !semantics.witnessHandles.contains(artifact.handle)) ||
        context.approvedCandidateHashes.isNotEmpty) {
      throw const NativeWriteException('native.library.evidence',
          'Approved candidates and source witnesses require library evidence');
    }
    return const _VerifiedAssetLibrary({}, {});
  }
  if (raw is! Map<String, Object?>) {
    throw const NativeWriteException('native.library.evidence',
        'Approved library evidence must be an exact bounded object');
  }
  final candidates = context.candidates
      .where((candidate) =>
          context.approvedCandidateHashes.containsKey(candidate.candidateId))
      .toList();
  if (candidates.isEmpty ||
      candidates.length != context.approvedCandidateHashes.length) {
    throw const NativeWriteException('native.library.approval',
        'Every library candidate requires its exact context approval receipt');
  }
  final witnesses = <Sha256Hash, NativeArtifact>{};
  final expectedHashes = candidates
      .expand(
          (candidate) => candidate.sources.map((image) => image.contentHash))
      .toSet();
  for (final witness in draft.sourceArtifacts) {
    if (!expectedHashes.contains(witness.rawSha256) &&
        semantics.witnessHandles.contains(witness.handle)) {
      continue;
    }
    if (witness.reference.mediaType != 'image/png' ||
        witnesses.containsKey(witness.rawSha256)) {
      throw const NativeWriteException('native.library.witness',
          'Source witnesses must contain each exact PNG content once');
    }
    witnesses[witness.rawSha256] = witness;
  }
  final files = <ConverterId, List<int>>{};
  final usedWitnesses = <Sha256Hash>{};
  for (final candidate in candidates) {
    for (final sourceImage in candidate.sources) {
      final entries = draft.source.snapshot.entries
          .where((entry) => entry.fileId == sourceImage.fileId);
      final witness = witnesses[sourceImage.contentHash];
      if (entries.length != 1 ||
          witness == null ||
          entries.single.kind != SourceNodeKind.file ||
          entries.single.sha256 != witness.rawSha256 ||
          entries.single.byteLength != witness.bytes.length) {
        throw const NativeWriteException('native.library.witness',
            'Every witness must match the exact snapshot file and candidate source');
      }
      files[sourceImage.fileId] = witness.bytes;
      usedWitnesses.add(witness.rawSha256);
    }
  }
  if (usedWitnesses.length != witnesses.length) {
    throw const NativeWriteException('native.library.witness',
        'Every declared source witness must be consumed by an approved candidate');
  }
  _checkCancelled(cancellation);
  final ApprovedAssetLibraryComposition regenerated;
  try {
    regenerated = await const ApprovedAssetLibraryComposer().compose(
        source: draft.source,
        files: _WitnessSourceFiles(files),
        candidates: candidates,
        approvedCandidateHashes: context.approvedCandidateHashes,
        decisions: context.decisions,
        outputMode: plan.outputPolicy.assetOutputMode,
        limits: limits,
        cancellation: cancellation);
  } on ApprovedAssetLibraryFailure catch (error) {
    _checkCancelled(cancellation);
    throw NativeWriteException('native.${error.code}', error.message);
  } on ContractError {
    _checkCancelled(cancellation);
    rethrow;
  }
  _checkCancelled(cancellation);
  if (!regenerated.canExport ||
      canonicalJsonOf(raw, limits: limits.jsonLimits) !=
          canonicalJsonOf(regenerated.evidence, limits: limits.jsonLimits) ||
      canonicalJsonOf(_artifactBindings(witnesses.values.toList()),
              limits: limits.jsonLimits) !=
          canonicalJsonOf(_artifactBindings(regenerated.sourceArtifacts),
              limits: limits.jsonLimits)) {
    throw const NativeWriteException('native.library.contents',
        'Approved library evidence differs from the bounded original-source recomposition');
  }
  final supplied = {
    for (final artifact in draft.artifacts) artifact.handle: artifact
  };
  for (final artifact in regenerated.artifacts) {
    final actual = supplied[artifact.handle];
    if (actual == null ||
        actual.reference != artifact.reference ||
        actual.rawSha256 != artifact.rawSha256 ||
        actual.bytes.length != artifact.bytes.length) {
      throw const NativeWriteException('native.library.artifact',
          'Library artifacts must equal the exact original-source recomposition');
    }
  }
  final operationIds =
      regenerated.mutations.map((mutation) => mutation.operationId).toSet();
  final actualMutations = draft.mutations
      .where((mutation) => operationIds.contains(mutation.operationId))
      .toList();
  if (actualMutations.length != regenerated.mutations.length ||
      canonicalJsonOf([
            for (var i = 0; i < actualMutations.length; i++)
              actualMutations[i].toJson(i)
          ], limits: limits.jsonLimits) !=
          canonicalJsonOf([
            for (var i = 0; i < regenerated.mutations.length; i++)
              regenerated.mutations[i].toJson(i)
          ], limits: limits.jsonLimits)) {
    throw const NativeWriteException('native.library.mutation',
        'Every library mutation must equal its exact approved candidate operation');
  }
  return _VerifiedAssetLibrary(operationIds,
      regenerated.artifacts.map((artifact) => artifact.handle).toSet());
}

List<Map<String, Object?>> _artifactBindings(List<NativeArtifact> artifacts) =>
    [
      for (final artifact in artifacts)
        {
          'handle': artifact.handle,
          'reference': artifact.reference.toJson(),
          'rawSha256': artifact.rawSha256.value
        }
    ]..sort((left, right) =>
        (left['handle'] as String).compareTo(right['handle'] as String));

void _requireLibraryMutation(
    _VerifiedAssetLibrary library, NativeMutation mutation) {
  if (!library.operationIds.contains(mutation.operationId)) {
    throw const NativeWriteException('native.library.mutation',
        'Native library actions require their exact regenerated candidate binding');
  }
}

void _verifyLiteralCompositionBinding(
    ConversionPlan plan, NativeProjectDraft draft, NativeWriteLimits limits) {
  final evidence = draft.compositionEvidence;
  if (evidence.isEmpty) return;
  final raw = evidence['composition'];
  if (evidence['kind'] == 'literalTileComposition' &&
      (plan.requestedMode != ConversionMode.study ||
          raw is! Map<String, Object?> ||
          raw['playableCertified'] != false)) {
    throw const NativeWriteException('native.composition.mode',
        'Literal tile composition v1 is an uncertified study staging project');
  }
  if (evidence['kind'] != 'literalTileComposition' ||
      evidence['version'] != 1 ||
      raw is! Map<String, Object?> ||
      raw['kind'] != 'literalTileComposition' ||
      raw['version'] != 1 ||
      evidence['compositionHash'] !=
          canonicalHashOf(raw, limits: limits.jsonLimits).value ||
      raw['sourceSnapshotHash'] != plan.sourceSnapshotHash.value ||
      raw['logicalProjectNamespace'] != plan.logicalProjectNamespace.value ||
      raw['normalizedSourceHash'] != draft.normalizedSourceHash.value ||
      raw['sourceArchiveHash'] != draft.source.archive.canonicalHash.value) {
    throw const NativeWriteException('native.composition.evidence',
        'Literal composition evidence must bind the exact normalized source');
  }
  final selected = _literalEvidenceIds(raw['selectedSourceMapIds']);
  final included = _literalEvidenceIds(raw['includedSourceMapIds']);
  if (selected == null ||
      selected.isEmpty ||
      included == null ||
      !_sameIntegerIds(selected, plan.selectedSourceMapIds) ||
      !_sameIntegerIds(included, plan.dependencySourceMapIds) ||
      selected.any(included.contains)) {
    throw const NativeWriteException('native.composition.selection',
        'The approved primary selection and additional dependencies must match literal evidence');
  }
  final expectedSelection = canonicalHashOf({
    'kind': 'literalSelection',
    'version': 1,
    'sourceSnapshotHash': plan.sourceSnapshotHash.value,
    'logicalProjectNamespace': plan.logicalProjectNamespace.value,
    'selectedSourceMapIds': selected.toList()..sort(),
  });
  final decisions = raw['decisions'];
  if (raw['selectionHash'] != expectedSelection.value || decisions is! List) {
    throw const NativeWriteException('native.composition.decisions',
        'Literal decisions require the exact source selection receipt');
  }
  final explicitlyIncluded = <int>{};
  for (final decision in decisions) {
    if (decision is! Map ||
        decision['sourceSnapshotHash'] != plan.sourceSnapshotHash.value ||
        decision['selectionHash'] != expectedSelection.value ||
        decision['targetSourceMapId'] is! int ||
        (decision['targetSourceMapId'] as int) <= 0 ||
        decision['locator'] is! Map ||
        !const {'include', 'excludeStudy', 'block'}
            .contains(decision['decision']) ||
        decision['decision'] == 'block') {
      throw const NativeWriteException('native.composition.decisions',
          'Literal dependency decisions must be bound and nonblocking');
    }
    if (decision['decision'] == 'include') {
      explicitlyIncluded.add(decision['targetSourceMapId'] as int);
    }
  }
  if (!explicitlyIncluded.containsAll(included)) {
    throw const NativeWriteException('native.composition.decisions',
        'Every additional source map requires an explicit inclusion decision');
  }
}

void _verifyLiteralCompositionContents(
    NativeProjectDraft draft,
    Map<String, MapData> maps,
    NativeWriteLimits limits,
    _VerifiedAssetLibrary library) {
  if (draft.compositionEvidence.isEmpty) return;
  final composition =
      draft.compositionEvidence['composition'] as Map<String, Object?>;
  final mapIds = {
    for (final entry in draft.mapIds.entries) '${entry.key}': entry.value,
  };
  final tilesetIds = <String, String>{};
  final rawAutotiles = composition['autotiles'];
  if (rawAutotiles != null && rawAutotiles is! List) {
    throw const NativeWriteException('native.composition.autotiles',
        'Autotile evidence must be a bounded collection');
  }
  final autotileEvidence = <String, Map>{};
  final autotileSlots = <String>{};
  for (final row in (rawAutotiles as List?) ?? const []) {
    if (row is! Map ||
        row['nativeTilesetId'] is! String ||
        row['sourceTilesetId'] is! int ||
        row['autotileSlot'] is! int ||
        (row['autotileSlot'] as int) < 0 ||
        (row['autotileSlot'] as int) > 6 ||
        row['tileAnimations'] is! List ||
        row['degraded'] is! bool ||
        row['firstFrameOnly'] is! bool ||
        row['animationVerified'] is! bool ||
        autotileEvidence.containsKey(row['nativeTilesetId']) ||
        !autotileSlots
            .add('${row['sourceTilesetId']}:${row['autotileSlot']}')) {
      throw const NativeWriteException('native.composition.autotiles',
          'Each literal autotile requires a unique source slot and native atlas');
    }
    if (row['degraded'] == true &&
        (composition['allowFirstFrameAutotiles'] != true ||
            row['firstFrameOnly'] != true ||
            row['animationVerified'] != false ||
            (row['tileAnimations'] as List).isNotEmpty)) {
      throw const NativeWriteException('native.composition.autotiles',
          'Degraded animation requires an explicit first-frame study choice');
    }
    autotileEvidence[row['nativeTilesetId'] as String] = row;
  }
  final seenAutotiles = <String>{};
  final literalArtifactHandles = <String>{};
  for (final mutation in draft.mutations) {
    if (library.operationIds.contains(mutation.operationId)) continue;
    if (mutation.actionId != 'tileset.import_image') continue;
    literalArtifactHandles.add(mutation.parameters['artifactHandle'] as String);
    final identities = draft.source.tilesets
        .where((entry) => mutation.sourceEntityIds.contains(entry.identity));
    if (identities.length != 1) {
      throw const NativeWriteException('native.composition.contents',
          'A literal import must bind one exact normalized tileset identity');
    }
    final normalized = identities.single;
    final nativeId = mutation.parameters['tilesetId'] as String;
    final autotile = autotileEvidence[nativeId];
    if (autotile != null) {
      final images = normalized.images.where((image) =>
          image.role == 'autotile' && image.slot == autotile['autotileSlot']);
      final artifact = draft.artifacts.where((artifact) =>
          artifact.handle == mutation.parameters['artifactHandle']);
      final updates = draft.mutations.where((entry) =>
          entry.actionId == 'tileset.upsert' &&
          (entry.parameters['tileset'] as Map?)?['id'] == nativeId);
      final sourceEntry = images.length == 1 ? images.single.sourceFile : null;
      final timelines = updates.length == 1
          ? (((updates.single.parameters['tileset'] as Map)['source']
                  as Map)['tileAnimations'] ??
              const [])
          : const [];
      if (normalized.sourceTilesetId != autotile['sourceTilesetId'] ||
          sourceEntry == null ||
          !mutation.sourceEntityIds.contains(sourceEntry.fileId) ||
          sourceEntry.fileId.value != autotile['sourceFileId'] ||
          sourceEntry.sha256?.value != autotile['sourceFileHash'] ||
          artifact.length != 1 ||
          artifact.single.handle != autotile['artifactHandle'] ||
          artifact.single.rawSha256.value != autotile['nativeImageSha256'] ||
          !seenAutotiles.add(nativeId) ||
          updates.length > 1 ||
          canonicalJsonOf(timelines, limits: limits.jsonLimits) !=
              canonicalJsonOf(autotile['tileAnimations'],
                  limits: limits.jsonLimits) ||
          autotile['animationVerified'] !=
              ((autotile['tileAnimations'] as List).isNotEmpty &&
                  autotile['degraded'] == false)) {
        throw const NativeWriteException('native.composition.autotiles',
            'Autotile provenance must bind the exact source image, generated atlas and native timeline');
      }
      _verifyAutotileProvenance(
          draft, autotile, images.single, artifact.single, limits);
      continue;
    }
    final sourceId = '${normalized.sourceTilesetId}';
    if (tilesetIds.containsKey(sourceId)) {
      throw const NativeWriteException('native.composition.contents',
          'Literal tileset mapping must account for each source identity once');
    }
    tilesetIds[sourceId] = mutation.parameters['tilesetId'] as String;
  }
  if (seenAutotiles.length != autotileEvidence.length) {
    throw const NativeWriteException('native.composition.autotiles',
        'Every literal autotile evidence entry must have its exact native import');
  }
  final mapHashes = {
    for (final entry in draft.mapIds.entries)
      '${entry.key}': canonicalHashOf(maps[entry.value]!.toJson(),
              limits: limits.jsonLimits)
          .value,
  };
  final artifacts = [
    for (final artifact in draft.artifacts)
      if (!library.artifactHandles.contains(artifact.handle) ||
          literalArtifactHandles.contains(artifact.handle))
        {'handle': artifact.handle, 'rawSha256': artifact.rawSha256.value},
  ]..sort((a, b) => a['handle']!.compareTo(b['handle']!));
  if (canonicalJsonOf(composition['mapIds'], limits: limits.jsonLimits) !=
          canonicalJsonOf(mapIds, limits: limits.jsonLimits) ||
      canonicalJsonOf(composition['tilesetIds'], limits: limits.jsonLimits) !=
          canonicalJsonOf(tilesetIds, limits: limits.jsonLimits) ||
      canonicalJsonOf(composition['nativeMapHashes'],
              limits: limits.jsonLimits) !=
          canonicalJsonOf(mapHashes, limits: limits.jsonLimits) ||
      canonicalJsonOf(composition['artifacts'], limits: limits.jsonLimits) !=
          canonicalJsonOf(artifacts, limits: limits.jsonLimits)) {
    throw const NativeWriteException('native.composition.contents',
        'Literal provenance must describe the exact native maps and artifact bytes');
  }
}

void _verifyAutotileProvenance(
    NativeProjectDraft draft,
    Map row,
    NormalizedMediaReference sourceImage,
    NativeArtifact artifact,
    NativeWriteLimits limits) {
  final provenance = row['provenance'];
  if (provenance is! Map ||
      row['compositionHash'] !=
          canonicalHashOf(provenance, limits: limits.jsonLimits).value ||
      provenance['kind'] != 'literalAutotile' ||
      provenance['version'] != 1 ||
      provenance['sourceSnapshotHash'] !=
          draft.source.snapshot.canonicalHash.value ||
      provenance['sourceFileId'] != row['sourceFileId'] ||
      provenance['sourceFileHash'] != row['sourceFileHash'] ||
      provenance['sourceFilePath'] != sourceImage.sourceFile!.relativePath ||
      provenance['sourceName'] != sourceImage.sourceName ||
      provenance['sourceTilesetId'] != row['sourceTilesetId'] ||
      provenance['autotileSlot'] != row['autotileSlot'] ||
      provenance['nativeTilesetId'] != row['nativeTilesetId'] ||
      provenance['generatedImageHash'] != row['nativeImageSha256'] ||
      provenance['firstFrameOnly'] != row['firstFrameOnly'] ||
      provenance['degraded'] != row['degraded'] ||
      provenance['variantCount'] != 48 ||
      provenance['localTileIdRule'] != 'frame*48+storedVariant' ||
      provenance['neighborhoodRecomputed'] != false ||
      canonicalJsonOf(provenance['tileAnimations'],
              limits: limits.jsonLimits) !=
          canonicalJsonOf(row['tileAnimations'], limits: limits.jsonLimits)) {
    throw const NativeWriteException('native.composition.autotiles',
        'Autotile internal provenance must match its hash and exact approved contents');
  }
  final frames = provenance['sourceFrameCount'];
  final profile = provenance['sourceProfile'];
  final dimensions = _pngHeaderDimensions(artifact.bytes, limits);
  final animated = row['animationVerified'] == true;
  if (frames is! int ||
      frames <= 0 ||
      frames != dimensions.$2 ~/ 192 ||
      dimensions.$1 != 256 ||
      dimensions.$2 % 192 != 0 ||
      provenance['pixelWidth'] != dimensions.$1 ||
      provenance['pixelHeight'] != dimensions.$2 ||
      row['firstFrameOnly'] != !animated ||
      row['degraded'] != (frames > 1 && !animated) ||
      profile is! Map ||
      profile['sourceSnapshotHash'] !=
          draft.source.snapshot.canonicalHash.value ||
      !const {'unverified', 'attested'}.contains(profile['state']) ||
      (animated &&
          (profile['state'] != 'attested' ||
              provenance['nativeAnimationAvailable'] != true))) {
    throw const NativeWriteException('native.composition.autotiles',
        'Autotile geometry, degradation and source clock must agree');
  }
  if (profile['state'] == 'attested') {
    final sourceClock = draft.source.snapshot.entries
        .where((entry) => entry.fileId.value == profile['sourceFileId']);
    if (sourceClock.length != 1 ||
        sourceClock.single.sha256?.value != profile['sourceFileHash'] ||
        profile['sourceFileHash'] !=
            LiteralAutotileComposer.attestedArchiveSha256 ||
        sourceClock.single.relativePath != profile['sourceFilePath'] ||
        sourcePathCollisionKey(sourceClock.single.relativePath) !=
            'data/scripts.rxdata' ||
        profile['baseFrameDurationMs'] != 250 ||
        profile['nameSuffixUnitMs'] != 50 ||
        profile['clockScale'] != 1 ||
        provenance['frameDurationMs'] !=
            LiteralAutotileComposer.attestedFrameDurationMs(
                sourceImage.sourceName)) {
      throw const NativeWriteException('native.composition.autotiles',
          'Attested source clock must bind its admitted script archive and scale');
    }
  }
  if (!animated) return;
  final duration = provenance['frameDurationMs'];
  final timeline = row['tileAnimations'] as List;
  if (duration is! int ||
      duration <= 0 ||
      duration > 2147483647 ||
      frames < 2 ||
      timeline.length != 48) {
    throw const NativeWriteException('native.composition.autotiles',
        'Animated autotiles require all stored variants and a bounded source duration');
  }
  for (var variant = 0; variant < 48; variant++) {
    final animation = timeline[variant];
    if (animation is! Map ||
        animation['tileId'] != variant ||
        animation['frames'] is! List ||
        (animation['frames'] as List).length != frames) {
      throw const NativeWriteException('native.composition.autotiles',
          'Each stored variant must retain every source frame');
    }
    final steps = animation['frames'] as List;
    for (var frame = 0; frame < frames; frame++) {
      final step = steps[frame];
      if (step is! Map ||
          step['tileId'] != frame * 48 + variant ||
          step['durationMs'] != duration) {
        throw const NativeWriteException('native.composition.autotiles',
            'Native frame order and timing must retain the stored source variant');
      }
    }
  }
}

List<int>? _literalEvidenceIds(Object? value) {
  if (value is! List || value.length > 2048) return null;
  final ids = <int>[];
  for (final id in value) {
    if (id is! int || id <= 0 || id > 2147483647) return null;
    ids.add(id);
  }
  if (ids.toSet().length != ids.length) return null;
  return ids;
}

bool _sameIntegerIds(List<int> left, List<int> right) =>
    left.length == right.length && left.toSet().containsAll(right);

void _requireMapBinding(
    NativeProjectDraft draft, NativeMutation mutation, String id) {
  final binding =
      draft.mapIds.entries.where((entry) => entry.value == id).firstOrNull;
  if (binding == null ||
      id.length > 64 ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$').hasMatch(id) ||
      !_targetIds(mutation.targetEntityIds, {id}) ||
      !mutation.sourceEntityIds
          .contains(draft.source.mapIdentity(binding.key))) {
    throw const NativeWriteException('native.map.identity',
        'Native map identity differs from the approved source-to-target binding');
  }
}

bool _sameIds(List<ConverterId> a, List<ConverterId> b) =>
    a.length == b.length &&
    Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
bool _targetIds(List<ConverterId> ids, Set<String> values) =>
    ids.length == values.length &&
    ids.map((id) => id.value).toSet().containsAll(values);

void _allowParameters(Map<String, Object?> values, Set<String> allowed) {
  if (values.keys.any((key) => !allowed.contains(key))) {
    throw const NativeWriteException(
        'native.parameters.unknown', 'Unexpected native mutation parameters');
  }
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String ||
      value.trim().isEmpty ||
      value.trim() != value ||
      value.contains('\u0000')) {
    throw NativeWriteException('native.parameters.string',
        'A stable nonblank string is required for $key');
  }
  return value;
}

ProjectCreationRequest _creationRequest(
        NativeProjectDraft draft, String parent) =>
    ProjectCreationRequest(
        name: draft.projectName,
        folderName: draft.folderName,
        parentPath: parent,
        template: ProjectCreationTemplate.empty,
        dimension: ProjectDimension.twoD,
        tileSize: 32,
        mapWidth: draft.defaultMapWidth,
        mapHeight: draft.defaultMapHeight);

void _requireAbsolute(String value) {
  if (!path.isAbsolute(value) ||
      value.contains('\u0000') ||
      value.split(RegExp(r'[\\/]')).contains('..')) {
    throw const NativeWriteException('native.path.invalid',
        'An absolute path without traversal is required');
  }
}

Future<void> _guardDestination(NativeProjectDraft draft, String parent) async {
  if (await Directory(draft.parentPath).resolveSymbolicLinks() != parent ||
      await FileSystemEntity.type(parent, followLinks: false) !=
          FileSystemEntityType.directory) {
    throw const NativeWriteException('native.parent.changed',
        'Destination parent changed or is unavailable');
  }
  final target = path.join(parent, draft.folderName);
  if (await FileSystemEntity.type(target, followLinks: false) !=
      FileSystemEntityType.notFound) {
    throw const NativeWriteException('native.destination.exists',
        'Destination must remain absent while the private staging project is prepared');
  }
  final sourcePath = draft.sourceRootPath;
  if (sourcePath != null) {
    _requireAbsolute(sourcePath);
    final source = await Directory(sourcePath).resolveSymbolicLinks();
    if (source == parent ||
        path.isWithin(source, parent) ||
        source == target ||
        path.isWithin(target, source)) {
      throw const NativeWriteException('native.source.overlap',
          'Destination and source trees must not overlap');
    }
  }
}

Future<void> _guardStage(
    NativeProjectDraft draft, String parent, String stage) async {
  await _guardDestination(draft, parent);
  if (!path.isWithin(parent, stage) ||
      await FileSystemEntity.type(stage, followLinks: false) !=
          FileSystemEntityType.directory ||
      await Directory(stage).resolveSymbolicLinks() != stage) {
    throw const NativeWriteException('native.staging.changed',
        'Private staging directory changed or escaped its parent');
  }
  final project = path.join(stage, draft.folderName);
  final type = await FileSystemEntity.type(project, followLinks: false);
  if (type != FileSystemEntityType.notFound &&
      (type != FileSystemEntityType.directory ||
          await Directory(project).resolveSymbolicLinks() != project)) {
    throw const NativeWriteException('native.project.changed',
        'Staging project must remain a direct directory inside its private root');
  }
}

void _makePrivate(String directory) {
  if (Platform.isWindows) return;
  if (!Platform.isMacOS && !Platform.isLinux) {
    throw const NativeWriteException('native.platform.unsupported',
        'Private local staging is unsupported on this platform');
  }
  final bytes = directory.toNativeUtf8();
  try {
    final chmod = DynamicLibrary.process().lookupFunction<
        Int32 Function(Pointer<Utf8>, Uint32),
        int Function(Pointer<Utf8>, int)>('chmod');
    if (chmod(bytes, 0x1c0) != 0) {
      throw const NativeWriteException('native.staging.permissions',
          'Cannot protect the private staging directory');
    }
  } finally {
    calloc.free(bytes);
  }
}

void _checkCancelled(ScanCancellation? cancellation) {
  if (cancellation?.isCancelled ?? false) {
    throw const NativeWriteException(
        'native.cancelled', 'Native staging cancelled');
  }
}

final class _NativeSession {
  _NativeSession._(this.opener, this.snapshots, this.project, this.workspace,
      this.mutations, this.handles);
  final ProjectOpenService opener;
  final ProjectSnapshotLoader snapshots;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi? mutations;
  final WorkspaceHandleStore handles;

  static Future<_NativeSession> open(String root,
      {required String allowedRoot, required bool mutable}) async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [allowedRoot], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(root);
    try {
      LocalMapAuthoringMutationApi? mutations;
      if (mutable) {
        mutations = LocalMapAuthoringMutationApi(
            policy: policy,
            snapshotLoader: snapshots,
            authorizationLimits:
                const AuthoringSecurityLimits(maxOperationsPerWindow: null));
        await mutations.attachProject(
            projectRootPath: root,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
      }
      return _NativeSession._(opener, snapshots, opened.projectHandle,
          opened.workspaceHandle, mutations, handles);
    } catch (_) {
      opener.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
  }

  Future<List<int>> readCompanion(String logicalPath, NativeArtifact expected,
      {required String errorCode}) async {
    final access = handles.resolveProject(project);
    final before = await access.readResourceIdentity(logicalPath);
    if (before == null || before.byteLength != expected.bytes.length) {
      throw NativeWriteException(errorCode,
          'Native provenance size differs from the approved companion');
    }
    final bytes = await access.readBytes(logicalPath);
    final after = await access.readResourceIdentity(logicalPath);
    if (after != before ||
        bytes.length != expected.bytes.length ||
        Sha256Hash(sha256.convert(bytes).toString()) != expected.rawSha256) {
      throw NativeWriteException(errorCode,
          'Native provenance bytes differ from the approved companion');
    }
    return bytes;
  }

  Future<void> close() async {
    await mutations?.detachWorkspace(workspace);
    opener.closeWorkspace(workspace);
  }
}

(int, int) _pngHeaderDimensions(List<int> bytes, NativeWriteLimits limits) {
  const header = [137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 33 ||
      bytes.length > limits.maxArtifactBytes ||
      !Iterable<int>.generate(8).every((i) => bytes[i] == header[i])) {
    throw const NativeWriteException(
        'native.png.header', 'A bounded PNG artifact is required');
  }
  final width = _u32(bytes, 16);
  final height = _u32(bytes, 20);
  if (_u32(bytes, 8) != 13 ||
      String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR' ||
      width == 0 ||
      height == 0 ||
      width > limits.maxImagePixels ||
      height > limits.maxImagePixels ||
      width > limits.maxImagePixels ~/ height) {
    throw const NativeWriteException(
        'native.quota.image', 'PNG geometry exceeds the pixel budget');
  }
  return (width, height);
}

final class NativePngValidator {
  const NativePngValidator();

  (int, int) headerDimensions(List<int> bytes,
      {NativeWriteLimits limits = const NativeWriteLimits()}) {
    limits._validate();
    return _pngHeaderDimensions(bytes, limits);
  }

  (int, int) validate(List<int> bytes,
      {NativeWriteLimits limits = const NativeWriteLimits()}) {
    limits._validate();
    return _pngDimensions(bytes, limits, decodePixels: false);
  }
}

(int, int) _pngDimensions(List<int> bytes, NativeWriteLimits limits,
    {bool decodePixels = true}) {
  final (width, height) = _pngHeaderDimensions(bytes, limits);
  final bits = bytes[24];
  final channels =
      switch (bytes[25]) { 0 => 1, 2 => 3, 3 => 1, 4 => 2, 6 => 4, _ => 0 };
  final legalBits = bytes[25] == 0
      ? const [1, 2, 4, 8, 16]
      : bytes[25] == 3
          ? const [1, 2, 4, 8]
          : const [8, 16];
  if (channels == 0 ||
      !legalBits.contains(bits) ||
      bytes[26] != 0 ||
      bytes[27] != 0 ||
      bytes[28] > 1) {
    throw const NativeWriteException(
        'native.png.format', 'Unsupported PNG pixel format');
  }
  final idat = <(int, int)>[];
  var compressedLength = 0;
  var chunks = 0;
  var ended = false;
  var dataEnded = false;
  var offset = 8;
  while (offset < bytes.length) {
    if (++chunks > 4096 || offset > bytes.length - 12) {
      throw const NativeWriteException(
          'native.png.chunks', 'PNG chunk budget or boundary is invalid');
    }
    final length = _u32(bytes, offset);
    if (length > bytes.length - offset - 12) {
      throw const NativeWriteException(
          'native.png.truncated', 'Truncated PNG chunk');
    }
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (!RegExp(r'^[A-Za-z]{4}$').hasMatch(type) ||
        (type.codeUnitAt(0) < 97 &&
            !const {'IHDR', 'PLTE', 'IDAT', 'IEND'}.contains(type))) {
      throw const NativeWriteException(
          'native.png.chunk_type', 'Unknown or invalid critical PNG chunk');
    }
    if (_crc32(bytes, offset + 4, offset + 8 + length) !=
        _u32(bytes, offset + 8 + length)) {
      throw const NativeWriteException(
          'native.png.crc', 'PNG chunk checksum mismatch');
    }
    if ((offset != 8 && type == 'IHDR') ||
        const {'acTL', 'fcTL', 'fdAT'}.contains(type)) {
      throw const NativeWriteException(
          'native.png.animation', 'Only one static PNG image is admitted');
    }
    if (type == 'PLTE' && (length == 0 || length > 768 || length % 3 != 0)) {
      throw const NativeWriteException(
          'native.png.palette', 'Invalid PNG palette');
    }
    if (type == 'IDAT') {
      if (dataEnded) {
        throw const NativeWriteException(
            'native.png.order', 'PNG image data chunks must be consecutive');
      }
      idat.add((offset + 8, length));
      compressedLength += length;
    } else if (idat.isNotEmpty) {
      dataEnded = true;
    }
    offset += length + 12;
    if (type == 'IEND') {
      if (length != 0 || offset != bytes.length) {
        throw const NativeWriteException(
            'native.png.trailing', 'PNG image must end exactly at IEND');
      }
      ended = true;
      break;
    }
  }
  if (!ended || compressedLength == 0) {
    throw const NativeWriteException(
        'native.png.data', 'PNG image data or terminator is absent');
  }
  var expected = 0;
  final passes = bytes[28] == 0
      ? const [(0, 0, 1, 1)]
      : const [
          (0, 0, 8, 8),
          (4, 0, 8, 8),
          (0, 4, 4, 8),
          (2, 0, 4, 4),
          (0, 2, 2, 4),
          (1, 0, 2, 2),
          (0, 1, 1, 2)
        ];
  for (final pass in passes) {
    final w = width <= pass.$1 ? 0 : (width - pass.$1 + pass.$3 - 1) ~/ pass.$3;
    final h =
        height <= pass.$2 ? 0 : (height - pass.$2 + pass.$4 - 1) ~/ pass.$4;
    if (w != 0 && h != 0) {
      expected += (((w * channels * bits + 7) ~/ 8) + 1) * h;
    }
  }
  final compressed = Uint8List(compressedLength);
  var position = 0;
  for (final part in idat) {
    compressed.setRange(position, position + part.$2, bytes, part.$1);
    position += part.$2;
  }
  final inflated = const BoundedZlibDecoder().decode(compressed,
      limits: ZlibDecodeLimits(
          maxInputBytes: limits.maxArtifactBytes, maxOutputBytes: expected),
      sourcePath: '<native-png-idat>');
  if (inflated.length != expected) {
    throw const NativeWriteException('native.png.scanlines',
        'PNG decoded scanline length differs from its geometry');
  }
  var scanlineOffset = 0;
  for (final pass in passes) {
    final w = width <= pass.$1 ? 0 : (width - pass.$1 + pass.$3 - 1) ~/ pass.$3;
    final h =
        height <= pass.$2 ? 0 : (height - pass.$2 + pass.$4 - 1) ~/ pass.$4;
    if (w == 0 || h == 0) continue;
    final rowBytes = ((w * channels * bits + 7) ~/ 8) + 1;
    for (var y = 0; y < h; y++) {
      if (inflated[scanlineOffset] > 4) {
        throw const NativeWriteException(
            'native.png.filter', 'PNG scanline uses an invalid filter');
      }
      scanlineOffset += rowBytes;
    }
  }
  if (decodePixels) {
    final decoded = image.decodePng(Uint8List.fromList(bytes));
    if (decoded == null || decoded.width != width || decoded.height != height) {
      throw const NativeWriteException(
          'native.png.decode', 'PNG pixels cannot be loaded');
    }
  }
  return (width, height);
}

int _u32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
final _crcTable = List<int>.generate(256, (value) {
  var result = value;
  for (var bit = 0; bit < 8; bit++) {
    result = (result & 1) == 0 ? result >> 1 : (result >> 1) ^ 0xedb88320;
  }
  return result;
}, growable: false);
int _crc32(List<int> bytes, int start, int end) {
  var crc = 0xffffffff;
  for (var i = start; i < end; i++) {
    crc = (crc >> 8) ^ _crcTable[(crc ^ bytes[i]) & 0xff];
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

Object? _freezeNativeJson(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, Object?>.unmodifiable(
        value.map((key, child) => MapEntry(key, _freezeNativeJson(child))));
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeNativeJson));
  }
  return value;
}
