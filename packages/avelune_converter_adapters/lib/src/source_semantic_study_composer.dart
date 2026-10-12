import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'literal_tile_composer.dart';
import 'native_project_writer.dart';
import 'source_player_character_import.dart';
import 'source_semantics_projection.dart';

final class SourceSemanticStudyComposer {
  const SourceSemanticStudyComposer();

  Future<NativeProjectDraft?> compose({
    required NormalizedSourceProject source,
    required LiteralTileComposition base,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    if (base.draft == null ||
        !SourceSemanticResolver.forProject(source).profile.isQualified) {
      return null;
    }
    final recording = SourceSemanticWitnessFiles(
        source.snapshot, files, limits, cancellation);
    final literal = await const LiteralTileComposer().compose(
        source: source,
        files: recording,
        selectedSourceMapIds: base.selectedSourceMapIds,
        projectName: base.draft!.projectName,
        parentPath: base.draft!.parentPath,
        folderName: base.draft!.folderName,
        sourceRootPath: base.draft!.sourceRootPath,
        dependencyDecisions: sourceSemanticDependencyDecisions(
            source,
            (base.draft!.compositionEvidence['composition'] as Map)['decisions']
                as List),
        allowFirstFrameAutotiles:
            (base.draft!.compositionEvidence['composition']
                    as Map)['allowFirstFrameAutotiles'] ==
                true,
        limits: limits,
        cancellation: cancellation);
    if (literal.compositionHash != base.compositionHash ||
        literal.draft == null) {
      throw const NativeWriteException('semantics.literal.changed',
          'Source semantic composition requires the exact original literal generation');
    }
    final player = await const SourcePlayerCharacterImporter().read(
        snapshot: source.snapshot,
        files: recording,
        cancellation: cancellation);
    final projection = await const SourceSemanticsProjector().project(
        source: source,
        base: literal,
        player: player,
        files: recording,
        limits: limits,
        cancellation: cancellation);
    final playerArtifact =
        NativeArtifact(bytes: player.outputBytes, limits: limits);
    NativeMutation mutation(String suffix, String action,
            List<ConverterId> targets, Map<String, Object?> parameters) =>
        NativeMutation(
            operationId: ConverterId('ac12-player-$suffix'),
            actionId: action,
            sourceEntityIds: [
              player.metadataFile.fileId,
              player.imageFile.fileId
            ],
            targetEntityIds: targets,
            parameters: parameters,
            limits: limits);
    final playerMutations = [
      mutation('import', 'tileset.import_image', [
        ConverterId(player.tilesetId),
        ConverterId(player.assetId)
      ], {
        'artifactHandle': playerArtifact.handle,
        'tilesetId': player.tilesetId,
        'name': player.character.name,
        'tileWidth': 32,
        'tileHeight': 32,
      }),
      mutation('create', 'characterStudio.character.create', [
        ConverterId(player.character.id)
      ], {
        'name': player.character.name,
        'tilesetId': player.tilesetId,
        'frameWidth': player.character.frameWidth,
        'frameHeight': player.character.frameHeight,
        'tags': player.character.tags,
      }),
      for (final clip in player.character.animations)
        mutation('clip-${clip.state.name}-${clip.direction.name}',
            'characterStudio.animationClip.upsert', [
          ConverterId(player.character.id)
        ], {
          'characterId': player.character.id,
          'kind': 'system',
          'state': clip.state.name,
          'direction': clip.direction.name,
          'sourceAssetId': clip.sourceAssetId,
          'loop': clip.loop,
          'frames': clip.frames.map((frame) => frame.toJson()).toList(),
        }),
      mutation(
          'default',
          'characterStudio.character.setDefault',
          [ConverterId(player.character.id)],
          {'characterId': player.character.id}),
    ];
    final original = literal.draft!;
    final artifacts = {
      for (final artifact in [
        ...original.artifacts,
        playerArtifact,
        ...projection.artifacts
      ])
        artifact.handle: artifact,
    }.values.toList()
      ..sort((a, b) => a.handle.compareTo(b.handle));
    final witnesses = recording.artifacts.values.toList()
      ..sort((a, b) => a.handle.compareTo(b.handle));
    final semantic = {
      'kind': 'sourceSemanticStudy',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'projection': projection.semanticEvidence,
      'player': player.evidence,
      'witnesses': recording.evidence,
      'automatic': true,
      'aiCalls': 0,
      'playableCertified': false,
      'operationIds': [
        ...playerMutations.map((entry) => entry.operationId.value),
        ...projection.operationIds.map((entry) => entry.value),
      ],
    };
    return NativeProjectDraft(
        source: source,
        projectName: original.projectName,
        parentPath: original.parentPath,
        folderName: original.folderName,
        sourceRootPath: original.sourceRootPath,
        mapIds: original.mapIds,
        artifacts: artifacts,
        sourceArtifacts: witnesses,
        mutations: [
          ...original.mutations
              .where((entry) => !entry.actionId.startsWith('map.')),
          ...playerMutations,
          ...projection.mutations
              .where((entry) => !entry.actionId.startsWith('map.')),
          ...original.mutations
              .where((entry) => entry.actionId == 'map.create'),
          ...projection.mutations
              .where((entry) => entry.actionId.startsWith('map.')),
        ],
        compositionEvidence: {
          ...original.compositionEvidence,
          'sourceSemantics': semantic
        },
        defaultMapWidth: original.defaultMapWidth,
        defaultMapHeight: original.defaultMapHeight,
        limits: limits);
  }
}

List<LiteralDependencyDecision> sourceSemanticDependencyDecisions(
    NormalizedSourceProject source, List rows) {
  final locators = {
    for (final map in source.maps)
      for (final event in map.map.events)
        for (final page in event.pages)
          for (final command in page.commands)
            canonicalJsonOf(command.sourceLocator.toJson()):
                command.sourceLocator,
  };
  return [
    for (final row in rows)
      LiteralDependencyDecision(
          sourceSnapshotHash: Sha256Hash(row['sourceSnapshotHash'] as String),
          selectionHash: Sha256Hash(row['selectionHash'] as String),
          locator: locators[canonicalJsonOf(row['locator'])] ??
              (throw const NativeWriteException('semantics.dependency.locator',
                  'Semantic dependency decisions must address an original source command')),
          targetSourceMapId: row['targetSourceMapId'] as int,
          decision: LiteralDependencyDisposition.values
              .singleWhere((value) => value.name == row['decision'])),
  ];
}

final class SourceSemanticWitnessFiles implements SourceFilePort {
  SourceSemanticWitnessFiles(
      this.snapshot, this.delegate, this.limits, this.cancellation);

  final SourceSnapshot snapshot;
  final SourceFilePort delegate;
  final NativeWriteLimits limits;
  final ScanCancellation? cancellation;
  final Map<String, NativeArtifact> artifacts = {};
  final Map<ConverterId, Map<String, Object?>> _evidence = {};
  final Map<ConverterId, List<int>> _bytes = {};
  static const chunkSize = 262144;
  int _reservedBytes = 0;
  int _reservedArtifactCount = 0;

  List<Map<String, Object?>> get evidence => (_evidence.values.toList()
        ..sort(
            (a, b) => (a['fileId'] as String).compareTo(b['fileId'] as String)))
      .map((entry) => Map<String, Object?>.unmodifiable(entry))
      .toList(growable: false);

  @override
  Future<List<int>> read(ConverterId fileId) async {
    cancellation?.check();
    final existing = _bytes[fileId];
    if (existing != null) return existing;
    final entries = snapshot.entries.where((entry) => entry.fileId == fileId);
    if (entries.length != 1 ||
        entries.single.sha256 == null ||
        entries.single.kind != SourceNodeKind.file) {
      throw const NativeWriteException('semantics.witness.file',
          'A semantic witness requires one exact inventoried source file');
    }
    final entry = entries.single;
    final png = entry.relativePath.toLowerCase().endsWith('.png');
    final chunkCount =
        png ? 1 : (entry.byteLength + chunkSize - 1) ~/ chunkSize;
    final artifactCount = chunkCount == 0 ? 1 : chunkCount;
    final reservedSize = png
        ? entry.byteLength
        : ((entry.byteLength + 2 * artifactCount) ~/ 3) * 4 +
            256 * artifactCount;
    final largestChunk =
        entry.byteLength < chunkSize ? entry.byteLength : chunkSize;
    if (_reservedArtifactCount + artifactCount > limits.maxArtifacts ||
        entry.byteLength > limits.maxArtifactBytes ||
        (!png &&
            (((largestChunk + 2) ~/ 3) * 4 + 256 > limits.maxArtifactBytes ||
                ((largestChunk + 2) ~/ 3) * 4 >
                    limits.jsonLimits.maxStringCodeUnits)) ||
        _reservedBytes + reservedSize > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException(
          'semantics.witness.quota', 'Semantic source witness budget exceeded');
    }
    _reservedBytes += reservedSize;
    _reservedArtifactCount += artifactCount;
    final bytes = await delegate.read(fileId);
    cancellation?.check();
    if (bytes.length != entry.byteLength ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw const NativeWriteException('semantics.witness.changed',
          'Semantic source witness differs from its admitted snapshot');
    }
    final witness = <String, Object?>{
      'fileId': fileId.value,
      'relativePath': entry.relativePath,
      'byteLength': entry.byteLength,
      'rawSha256': entry.sha256!.value,
    };
    if (png) {
      final artifact = NativeArtifact(bytes: bytes, limits: limits);
      artifacts[artifact.handle] = artifact;
      witness.addAll({'artifactHandle': artifact.handle, 'encoding': 'png'});
    } else {
      final chunks = <Map<String, Object?>>[];
      for (var index = 0; index < artifactCount; index++) {
        cancellation?.check();
        final offset = index * chunkSize;
        final end = offset + chunkSize < bytes.length
            ? offset + chunkSize
            : bytes.length;
        final artifact = NativeArtifact(
            bytes: utf8.encode(canonicalJsonOf({
              'kind': 'sourceSemanticByteChunk',
              'version': 1,
              'offset': offset,
              'bytesBase64': base64Encode(bytes.sublist(offset, end)),
            }, limits: limits.jsonLimits)),
            mediaType: 'application/json',
            limits: limits);
        artifacts[artifact.handle] = artifact;
        chunks.add({
          'artifactHandle': artifact.handle,
          'offset': offset,
          'byteLength': end - offset
        });
      }
      witness
          .addAll({'encoding': 'canonicalJsonBase64Chunks', 'chunks': chunks});
    }
    _evidence[fileId] = witness;
    _bytes[fileId] = List.unmodifiable(bytes);
    return _bytes[fileId]!;
  }
}
