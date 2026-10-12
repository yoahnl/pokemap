import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

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
    Sha256Hash? expectedSha256,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    final byteLength = bytes.length;
    if (byteLength > limits.maxArtifactBytes) {
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
    final hash = Sha256Hash(sha256.convert(frozen).toString());
    if (expectedSha256 != null && expectedSha256 != hash) {
      throw const NativeWriteException(
          'native.artifact.hash', 'Artifact hash mismatch');
    }
    return NativeArtifact._(frozen, hash,
        ContentArtifactRef.fromBytes(frozen, mediaType: 'image/png'));
  }

  const NativeArtifact._(this.bytes, this.rawSha256, this.reference);
  final List<int> bytes;
  final Sha256Hash rawSha256;
  final ContentArtifactRef reference;
  String get handle => reference.handle;
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
    required List<NativeMutation> mutations,
    Map<String, Object?> compositionEvidence = const {},
    String? sourceRootPath,
    int defaultMapWidth = 3,
    int defaultMapHeight = 3,
    NativeWriteLimits limits = const NativeWriteLimits(),
  }) {
    limits._validate();
    if (mapIds.length > limits.maxMutations ||
        artifacts.length > limits.maxArtifacts ||
        mutations.length > limits.maxMutations) {
      throw const NativeWriteException(
          'native.quota.draft', 'Draft entry budget exceeded');
    }
    var total = 0;
    for (final artifact in artifacts) {
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
  final List<NativeMutation> mutations;
  final Sha256Hash normalizedSourceHash;
  final Map<String, Object?> compositionEvidence;
  final Sha256Hash canonicalHash;
  final Map<String, Object?> _binding;
  String get bindingEvidence => 'native-draft-sha256:${canonicalHash.value}';
}

enum NativeWriteStage {
  beforeStage,
  stageCreated,
  afterBootstrap,
  afterMutation,
  afterMutations,
  beforeNativeVerify,
  afterNativeVerify,
}

typedef NativeWriteCheckpoint = FutureOr<void> Function(
    NativeWriteStage stage, String? stagingRoot, String? projectPath);

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
  const NativeProjectWriter({this.creation, this.checkpoint});
  final ProjectCreationPort? creation;
  final NativeWriteCheckpoint? checkpoint;

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
      final prepared = _prepareNativeDraft(plan, draft, limits);
      final creator = creation ?? const LocalProjectCreationService();
      final requested = _creationRequest(draft, draft.parentPath);
      requested.validate();
      _requireAbsolute(draft.parentPath);
      final parent = await Directory(draft.parentPath).resolveSymbolicLinks();
      await _guardDestination(draft, parent);
      await checkpoint?.call(NativeWriteStage.beforeStage, null, null);
      _checkCancelled(cancellation);
      await _guardDestination(draft, parent);
      stagingRoot =
          (await Directory(parent).createTemp('.avelune-converter-stage-'))
              .path;
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
        final stored = await api.artifacts
            .put(artifact.bytes, declaredMediaType: 'image/png');
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
      for (final entry in prepared.maps.entries) {
        _checkCancelled(cancellation);
        final actual = snapshot.mapById(entry.key);
        if (actual == null ||
            canonicalJsonOf(actual.toJson(), limits: limits.jsonLimits) !=
                canonicalJsonOf(entry.value.toJson(),
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
            source.tileWidth != 32 ||
            source.tileHeight != 32) {
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
      this.bootstrap, this.manifest, this.maps, this.tilesets);
  final ProjectManifest bootstrap;
  final ProjectManifest manifest;
  final Map<String, MapData> maps;
  final Map<String, NativeArtifact> tilesets;
}

_PreparedNativeDraft _prepareNativeDraft(
    ConversionPlan plan, NativeProjectDraft draft, NativeWriteLimits limits) {
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
  if (draft.artifacts.length > limits.maxArtifacts ||
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
    final domain = mutation.actionId == 'tileset.import_image'
        ? OperationDomain.assets
        : OperationDomain.maps;
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
    if (!const {'tileset.import_image', 'map.create', 'map.save'}
        .contains(mutation.actionId)) {
      throw const NativeWriteException('native.action.unsupported',
          'Only image import, map creation and native map save are admitted in AC-05');
    }
  }
  final artifacts = <String, NativeArtifact>{};
  var totalBytes = 0;
  var totalPixels = 0;
  final dimensions = <String, (int, int)>{};
  for (final artifact in draft.artifacts) {
    totalBytes += artifact.bytes.length;
    if (artifact.bytes.length > limits.maxArtifactBytes ||
        totalBytes > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException(
          'native.quota.artifact', 'Artifact byte budget exceeded');
    }
    if (artifacts.containsKey(artifact.handle)) {
      throw const NativeWriteException('native.artifact.duplicate',
          'Duplicate artifact handles are not admitted');
    }
    final size = _pngHeaderDimensions(artifact.bytes, limits);
    totalPixels += size.$1 * size.$2;
    if (totalPixels > limits.maxImagePixels) {
      throw const NativeWriteException(
          'native.quota.image', 'Aggregate image pixel budget exceeded');
    }
    artifacts[artifact.handle] = artifact;
    dimensions[artifact.handle] = size;
  }
  var importBytes = 0;
  var importPixels = 0;
  for (final mutation in draft.mutations) {
    if (mutation.actionId != 'tileset.import_image') continue;
    final handle = mutation.parameters['artifactHandle'];
    final artifact = artifacts[handle];
    final size = dimensions[handle];
    if (artifact == null || size == null) {
      throw const NativeWriteException('native.tileset.invalid',
          'An imported atlas must name an admitted artifact');
    }
    importBytes += artifact.bytes.length;
    importPixels += size.$1 * size.$2;
    if (importBytes > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('native.quota.artifact',
          'Aggregate logical image import byte budget exceeded');
    }
    if (importPixels > limits.maxImagePixels) {
      throw const NativeWriteException('native.quota.image',
          'Aggregate logical image import pixel budget exceeded');
    }
  }
  for (final artifact in draft.artifacts) {
    _pngDimensions(artifact.bytes, limits);
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
  final usedArtifacts = <String>{};
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
        if (id.length > 64 ||
            !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
            tilesets.keys.any((key) => key.toLowerCase() == id.toLowerCase()) ||
            artifact == null ||
            parameters['tileWidth'] != 32 ||
            parameters['tileHeight'] != 32 ||
            !_targetIds(mutation.targetEntityIds, {id, 'image_$id'})) {
          throw const NativeWriteException('native.tileset.invalid',
              'A unique native atlas, its asset identity and explicit 32px grid are required');
        }
        final size = dimensions[handle]!;
        if (size.$1 % 32 != 0 || size.$2 % 32 != 0) {
          throw const NativeWriteException('native.tileset.geometry',
              'Atlas image must contain complete 32px cells');
        }
        tilesets[id] = artifact;
        usedArtifacts.add(handle);
        tilesetEntries.add(ProjectTilesetEntry(
            id: id,
            name: name,
            relativePath: 'assets/studio/$id.png',
            source: ProjectRegularAtlasTilesetSource(
                assetId: 'image_$id',
                pixelWidth: size.$1,
                pixelHeight: size.$2,
                tileWidth: 32,
                tileHeight: 32)));
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
      default:
        throw const NativeWriteException('native.action.unsupported',
            'Only image import, map creation and native map save are admitted in AC-05');
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
  final manifest =
      bootstrap.copyWith(maps: mapEntries, tilesets: tilesetEntries);
  ProjectValidator.validate(manifest, maps: maps.values);
  for (final map in maps.values) {
    MapValidator.validate(map, projectDialogueContext: manifest);
  }
  _verifyLiteralCompositionContents(draft, maps, limits);
  return _PreparedNativeDraft(bootstrap, manifest, maps, tilesets);
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

void _verifyLiteralCompositionContents(NativeProjectDraft draft,
    Map<String, MapData> maps, NativeWriteLimits limits) {
  if (draft.compositionEvidence.isEmpty) return;
  final composition =
      draft.compositionEvidence['composition'] as Map<String, Object?>;
  final mapIds = {
    for (final entry in draft.mapIds.entries) '${entry.key}': entry.value,
  };
  final tilesetIds = <String, String>{};
  for (final mutation in draft.mutations) {
    if (mutation.actionId != 'tileset.import_image') continue;
    final identities = draft.source.tilesets
        .where((entry) => mutation.sourceEntityIds.contains(entry.identity));
    if (identities.length != 1) {
      throw const NativeWriteException('native.composition.contents',
          'A literal import must bind one exact normalized tileset identity');
    }
    final sourceId = '${identities.single.sourceTilesetId}';
    if (tilesetIds.containsKey(sourceId)) {
      throw const NativeWriteException('native.composition.contents',
          'Literal tileset mapping must account for each source identity once');
    }
    tilesetIds[sourceId] = mutation.parameters['tilesetId'] as String;
  }
  final mapHashes = {
    for (final entry in draft.mapIds.entries)
      '${entry.key}': canonicalHashOf(maps[entry.value]!.toJson(),
              limits: limits.jsonLimits)
          .value,
  };
  final artifacts = [
    for (final artifact in draft.artifacts)
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
      this.mutations);
  final ProjectOpenService opener;
  final ProjectSnapshotLoader snapshots;
  final ProjectHandle project;
  final WorkspaceHandle workspace;
  final LocalMapAuthoringMutationApi? mutations;

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
            policy: policy, snapshotLoader: snapshots);
        await mutations.attachProject(
            projectRootPath: root,
            workspaceHandle: opened.workspaceHandle,
            projectHandle: opened.projectHandle);
      }
      return _NativeSession._(opener, snapshots, opened.projectHandle,
          opened.workspaceHandle, mutations);
    } catch (_) {
      opener.closeWorkspace(opened.workspaceHandle);
      rethrow;
    }
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
