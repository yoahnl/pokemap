import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';
import 'native_terrain_brush.dart';

final class ApprovedAssetLibraryDiagnostic {
  const ApprovedAssetLibraryDiagnostic({
    required this.code,
    required this.message,
    required this.blocksExport,
    this.candidateId,
    this.locator,
  });

  final String code;
  final String message;
  final bool blocksExport;
  final ConverterId? candidateId;
  final SourceLocator? locator;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'blocksExport': blocksExport,
        'candidateId': candidateId?.value,
        'locator': locator?.toJson(),
      };
}

final class ApprovedAssetLibraryFailure implements Exception {
  const ApprovedAssetLibraryFailure(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'ApprovedAssetLibraryFailure($code): $message';
}

final class ApprovedAssetCandidateBinding {
  const ApprovedAssetCandidateBinding._(this.record);
  final Map<String, Object?> record;

  ConverterId get candidateId => ConverterId(record['candidateId'] as String);
  Sha256Hash get candidateHash => Sha256Hash(record['candidateHash'] as String);
  String get nativeElementId => record['nativeElementId'] as String;
  String get nativeTilesetId => record['nativeTilesetId'] as String;
  String get nativeCategoryId => record['nativeCategoryId'] as String;
  String get nativeImageAssetId => record['nativeImageAssetId'] as String;
  String get companionAssetId => record['companionAssetId'] as String;
  String get pngArtifactHandle => record['pngArtifactHandle'] as String;
  String get companionArtifactHandle =>
      record['companionArtifactHandle'] as String;
  Map<String, Object?> toJson() => record;
}

final class ApprovedAssetLibraryComposition {
  const ApprovedAssetLibraryComposition._({
    required this.artifacts,
    required this.sourceArtifacts,
    required this.mutations,
    required this.candidateBindings,
    required this.evidence,
    required this.diagnostics,
    required this.compositionHash,
  });

  final List<NativeArtifact> artifacts;
  final List<NativeArtifact> sourceArtifacts;
  final List<NativeMutation> mutations;
  final List<ApprovedAssetCandidateBinding> candidateBindings;
  final Map<String, Object?> evidence;
  final List<ApprovedAssetLibraryDiagnostic> diagnostics;
  final Sha256Hash compositionHash;
  bool get canExport =>
      candidateBindings.isNotEmpty &&
      !diagnostics.any((diagnostic) => diagnostic.blocksExport);
}

final class ApprovedAssetLibraryComposer {
  const ApprovedAssetLibraryComposer();

  Future<ApprovedAssetLibraryComposition> compose({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required List<AssetCandidate> candidates,
    required Map<ConverterId, Sha256Hash> approvedCandidateHashes,
    required ReviewDecisions decisions,
    required AssetOutputMode outputMode,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    limits.validate();
    cancellation?.check();
    if (candidates.length > limits.maxMutations ~/ 4 ||
        candidates.length > limits.maxArtifacts ~/ 2 ||
        approvedCandidateHashes.length > limits.maxMutations ||
        decisions.decisions.length > limits.maxMutations) {
      throw const ApprovedAssetLibraryFailure(
          'library.quota.entries', 'Library collection budget exceeded');
    }
    final frozenCandidates = List<AssetCandidate>.unmodifiable(candidates);
    final terrainCount = frozenCandidates
        .where((candidate) => candidate.terrainLayout != null)
        .length;
    if (frozenCandidates.length * 4 + terrainCount * 4 > limits.maxMutations) {
      throw const ApprovedAssetLibraryFailure(
          'library.quota.entries', 'Native library action budget exceeded');
    }
    final receipts =
        Map<ConverterId, Sha256Hash>.unmodifiable(approvedCandidateHashes);
    canonicalJsonOf(frozenCandidates.map((value) => value.toJson()).toList(),
        limits: limits.jsonLimits);
    final snapshot = source.snapshot;
    final snapshotHash = snapshot.canonicalHash;
    final diagnostics = <ApprovedAssetLibraryDiagnostic>[];
    void block(String code, String message,
        [AssetCandidate? candidate, SourceLocator? locator]) {
      diagnostics.add(ApprovedAssetLibraryDiagnostic(
          code: code,
          message: message,
          blocksExport: true,
          candidateId: candidate?.candidateId,
          locator: locator));
    }

    if (snapshot.state != SourceScanState.complete || !source.canPlan) {
      block(
          'library.source.incomplete', 'Source is not a complete admitted IR');
    }
    if (decisions.exampleOnly || decisions.sourceSnapshotHash != snapshotHash) {
      block('library.decisions.snapshot', 'Review belongs to another snapshot');
    }
    if (outputMode == AssetOutputMode.packedObjects) {
      block('library.output_mode', 'Packed object output is not implemented');
    }
    final entries = {for (final entry in snapshot.entries) entry.fileId: entry};
    final staticImages = <ConverterId>{};
    final temporalImages = <ConverterId>{};
    for (final tileset in source.tilesets) {
      for (final reference in tileset.images) {
        final id = reference.sourceFile?.fileId;
        if (id == null) continue;
        if (reference.role == 'tileset') {
          staticImages.add(id);
        } else {
          temporalImages.add(id);
        }
      }
    }
    for (final reference in source.eventImages) {
      final id = reference.sourceFile?.fileId;
      if (id != null) temporalImages.add(id);
    }
    final seen = <ConverterId>{};
    final sourceImages = <ConverterId, SourceImage>{};
    final geometries = <ConverterId, _LibraryGeometry>{};
    var partCount = 0;
    var pixelBudget = 0;
    var byteBudget = 0;
    void chargePixels(int width, int height) {
      if (height <= 0 ||
          width <= 0 ||
          width > limits.maxImagePixels ~/ height ||
          width > (limits.maxTotalImagePixels - pixelBudget) ~/ height) {
        throw const ApprovedAssetLibraryFailure('library.quota.pixels',
            'Source and output pixels exceed the aggregate budget');
      }
      pixelBudget += width * height;
    }

    for (final candidate in frozenCandidates) {
      cancellation?.check();
      partCount += (candidate.toJson()['parts'] as List).length;
      if (partCount > limits.maxMutations) {
        throw const ApprovedAssetLibraryFailure(
            'library.quota.parts', 'Part count exceeds the admitted budget');
      }
      if (!seen.add(candidate.candidateId)) {
        block('library.candidate.duplicate', 'Candidate identity is duplicated',
            candidate);
      }
      if (candidate.exampleOnly ||
          candidate.logicalProjectNamespace !=
              snapshot.logicalProjectNamespace ||
          candidate.sourceSnapshotHash != snapshotHash) {
        block('library.candidate.snapshot',
            'Candidate does not belong to this source snapshot', candidate);
      }
      final approval = decisions.decisions
          .where((decision) => decision.candidateId == candidate.candidateId)
          .toList();
      if (candidate.state != CandidateState.approved ||
          candidate.approvedRevision != candidate.revision ||
          receipts[candidate.candidateId] != candidate.canonicalHash ||
          approval.length != 1 ||
          approval.single.action != ReviewAction.approve ||
          !approval.single.humanConfirmed ||
          approval.single.candidateRevision != candidate.revision) {
        block(
            'library.candidate.approval',
            'Candidate needs its exact current human approval receipt',
            candidate);
      }
      if (candidate.integrationMode != IntegrationMode.libraryOnly ||
          candidate.outputMode != outputMode) {
        block(
            'library.candidate.mode',
            'Approved candidate mode differs from library-only output',
            candidate);
      }
      if (candidate.category == AssetCategory.animation ||
          candidate.category == AssetCategory.character) {
        block(
            'library.animation.unsupported',
            'Temporal object composition needs an explicit animation contract',
            candidate);
      }
      if (candidate.uncertainties.isNotEmpty) {
        diagnostics.add(ApprovedAssetLibraryDiagnostic(
            code: 'library.candidate.uncertainty',
            message: 'The approved group retains its original uncertainties',
            blocksExport: false,
            candidateId: candidate.candidateId));
      }
      final usedFiles =
          candidate.parts.map((part) => part.sourceFileId).toSet();
      for (final sourceImage in candidate.sources) {
        final entry = entries[sourceImage.fileId];
        if (!usedFiles.contains(sourceImage.fileId) ||
            entry == null ||
            entry.kind != SourceNodeKind.file ||
            entry.sha256 != sourceImage.contentHash ||
            entry.format != 'raster' ||
            !entry.relativePath.toLowerCase().endsWith('.png')) {
          block('library.source.binding',
              'Candidate image is not an exact admitted PNG source', candidate);
          continue;
        }
        if (!staticImages.contains(entry.fileId) ||
            temporalImages.contains(entry.fileId)) {
          block(
              'library.animation.unsupported',
              'Only attested static regular atlas sources are supported',
              candidate);
        }
        final previous = sourceImages[sourceImage.fileId];
        if (previous != null &&
            (previous.pixelWidth != sourceImage.pixelWidth ||
                previous.pixelHeight != sourceImage.pixelHeight)) {
          block('library.source.dimensions',
              'Candidates disagree on a shared source image', candidate);
        }
        if (previous == null) {
          sourceImages[sourceImage.fileId] = sourceImage;
          chargePixels(sourceImage.pixelWidth, sourceImage.pixelHeight);
          byteBudget += entry.byteLength;
          if (entry.byteLength > limits.maxArtifactBytes) {
            throw const ApprovedAssetLibraryFailure('library.quota.input',
                'Source PNG exceeds the file byte budget');
          }
        }
      }
      final parts = candidate.parts;
      for (var index = 0; index < parts.length; index++) {
        final part = parts[index];
        final width = part.quarterTurns.isOdd
            ? part.sourceRect.height
            : part.sourceRect.width;
        final height = part.quarterTurns.isOdd
            ? part.sourceRect.width
            : part.sourceRect.height;
        for (var otherIndex = 0; otherIndex < index; otherIndex++) {
          final other = parts[otherIndex];
          final otherWidth = other.quarterTurns.isOdd
              ? other.sourceRect.height
              : other.sourceRect.width;
          final otherHeight = other.quarterTurns.isOdd
              ? other.sourceRect.width
              : other.sourceRect.height;
          if (part.destinationOffset.x <
                  other.destinationOffset.x + otherWidth &&
              other.destinationOffset.x < part.destinationOffset.x + width &&
              part.destinationOffset.y <
                  other.destinationOffset.y + otherHeight &&
              other.destinationOffset.y < part.destinationOffset.y + height) {
            block(
                'library.parts.overlap',
                'Overlapping parts require a human geometry revision',
                candidate,
                part.locator);
          }
        }
        if (!_locatorMatches(source, part, entries)) {
          block(
              'library.source.locator',
              'Part locator contradicts the normalized source',
              candidate,
              part.locator);
        }
      }
      if (outputMode == AssetOutputMode.sharedAtlas) {
        final geometry = _sharedGeometry(candidate);
        if (geometry == null) {
          block(
              'library.shared_atlas.geometry',
              'Shared atlas requires one complete contiguous grid rectangle; '
                  'review an explicit standalone object instead',
              candidate,
              candidate.parts.first.locator);
        } else {
          geometries[candidate.candidateId] = geometry;
          chargePixels(candidate.canvasSize.width, candidate.canvasSize.height);
          final sharedEntry = entries[candidate.sources.single.fileId];
          if (sharedEntry != null) byteBudget += sharedEntry.byteLength;
        }
      } else {
        final width = ((candidate.canvasSize.width + 31) ~/ 32) * 32;
        final height = ((candidate.canvasSize.height + 31) ~/ 32) * 32;
        geometries[candidate.candidateId] = _LibraryGeometry(
            width,
            height,
            0,
            0,
            (candidate.canvasSize.width + 31) ~/ 32,
            (candidate.canvasSize.height + 31) ~/ 32);
        chargePixels(width, height);
        final outputBound = _pngByteBound(width, height);
        if (outputBound > limits.maxArtifactBytes) {
          throw const ApprovedAssetLibraryFailure(
              'library.quota.output', 'Generated PNG exceeds its byte budget');
        }
        byteBudget += outputBound;
      }
      if (pixelBudget > limits.maxTotalImagePixels) {
        throw const ApprovedAssetLibraryFailure('library.quota.pixels',
            'Source and output pixels exceed the budget');
      }
      if (byteBudget > limits.maxTotalArtifactBytes) {
        throw const ApprovedAssetLibraryFailure(
            'library.quota.bytes', 'Aggregate image byte budget exceeded');
      }
      if (candidate.terrainLayout != null) {
        chargePixels(128, 128);
        final brushBound = _pngByteBound(128, 128);
        if (brushBound > limits.maxArtifactBytes) {
          throw const ApprovedAssetLibraryFailure('library.quota.output',
              'Terrain brush PNG exceeds its byte budget');
        }
        byteBudget += brushBound;
        if (byteBudget > limits.maxTotalArtifactBytes) {
          throw const ApprovedAssetLibraryFailure('library.quota.bytes',
              'Terrain brush exceeds the aggregate byte budget');
        }
      }
    }
    if (sourceImages.length + frozenCandidates.length * 2 + terrainCount >
        limits.maxArtifacts) {
      throw const ApprovedAssetLibraryFailure('library.quota.entries',
          'Source witnesses and output artifacts exceed the collection budget');
    }
    if (diagnostics.any((diagnostic) => diagnostic.blocksExport) ||
        frozenCandidates.isEmpty) {
      return _composition(source, outputMode, const [], const [], const [],
          const [], diagnostics, limits);
    }
    final sourceArtifacts = <NativeArtifact>[];
    final artifactsBySourceHash = <Sha256Hash, NativeArtifact>{};
    final decodedImages = <ConverterId, image.Image>{};
    final orderedSources = sourceImages.values.toList()
      ..sort((a, b) => a.fileId.value.compareTo(b.fileId.value));
    for (final sourceImage in orderedSources) {
      cancellation?.check();
      final entry = entries[sourceImage.fileId]!;
      final bytes = await files.read(entry.fileId);
      cancellation?.check();
      if (bytes.length != entry.byteLength ||
          sha256.convert(bytes).toString() != entry.sha256!.value) {
        throw const ApprovedAssetLibraryFailure('library.source.hash',
            'Source bytes changed after their inventory');
      }
      final (width, height) =
          const NativePngValidator().headerDimensions(bytes, limits: limits);
      if (width != sourceImage.pixelWidth ||
          height != sourceImage.pixelHeight) {
        throw const ApprovedAssetLibraryFailure('library.source.dimensions',
            'Candidate dimensions differ from the original PNG');
      }
      if (bytes[24] == 16) {
        throw const ApprovedAssetLibraryFailure('library.source.pixel_format',
            'Sixteen-bit source channels require an explicit conversion policy');
      }
      const NativePngValidator().validate(bytes, limits: limits);
      final existing = artifactsBySourceHash[entry.sha256];
      final artifact = existing ??
          NativeArtifact(
              bytes: bytes, expectedSha256: entry.sha256, limits: limits);
      if (existing == null) {
        sourceArtifacts.add(artifact);
        artifactsBySourceHash[artifact.rawSha256] = artifact;
      }
      await Future<void>.delayed(Duration.zero);
      cancellation?.check();
      final decoded = image.decodePng(Uint8List.fromList(artifact.bytes));
      if (decoded == null || decoded.bitsPerChannel != 8) {
        throw const ApprovedAssetLibraryFailure('library.source.pixel_format',
            'Exact library raster export supports eight-bit RGBA channels');
      }
      decodedImages[sourceImage.fileId] = decoded;
    }
    final artifactsByHandle = <String, NativeArtifact>{};
    final bindings = <ApprovedAssetCandidateBinding>[];
    final mutations = <NativeMutation>[];
    var retainedBytes =
        sourceArtifacts.fold<int>(0, (sum, a) => sum + a.bytes.length);
    for (final candidate in frozenCandidates) {
      cancellation?.check();
      final geometry = geometries[candidate.candidateId]!;
      NativeArtifact png;
      String rgbaHash;
      final rgba = await _raster(candidate, decodedImages, geometry,
          cancellation: cancellation);
      if (outputMode == AssetOutputMode.sharedAtlas) {
        png = sourceArtifacts.singleWhere((artifact) =>
            artifact.rawSha256 == candidate.sources.single.contentHash);
        rgbaHash = sha256.convert(rgba).toString();
      } else {
        rgbaHash = sha256.convert(rgba).toString();
        png = NativeArtifact(
            bytes: _encodeLibraryPng(
                rgba, geometry.pixelWidth, geometry.pixelHeight),
            limits: limits);
      }
      if (!artifactsByHandle.containsKey(png.handle)) {
        retainedBytes += png.bytes.length;
        artifactsByHandle[png.handle] = png;
      }
      final suffix = canonicalHashOf({
        'namespace': snapshot.logicalProjectNamespace.value,
        'candidateId': candidate.candidateId.value,
        'revision': candidate.revision,
      }).value.substring(0, 24);
      final tilesetId = 'library_atlas_$suffix';
      final categoryId = 'library_category_$suffix';
      final elementId = 'library_element_$suffix';
      final companionId = 'library_metadata_$suffix';
      final companionPath = 'assets/converter/$companionId.json';
      final nativeName = candidate.name.trim().isEmpty
          ? 'Approved ${candidate.category.name}'
          : candidate.name.trim();
      final terrain = candidate.terrainLayout == null
          ? null
          : NativeTerrainBrush.compile(
              sourcePngBytes: _encodeLibraryPng(rgba, 96, 96),
              tilesetId: 'library_path_image_$suffix',
              atlasId: 'library_path_atlas_$suffix',
              materialId: 'library_path_material_$suffix',
              presetId: 'library_path_preset_$suffix',
              name: nativeName);
      final terrainPng = terrain == null
          ? null
          : NativeArtifact(bytes: terrain.imageBytes, limits: limits);
      if (terrainPng != null &&
          !artifactsByHandle.containsKey(terrainPng.handle)) {
        retainedBytes += terrainPng.bytes.length;
        artifactsByHandle[terrainPng.handle] = terrainPng;
      }
      final record = <String, Object?>{
        'candidateId': candidate.candidateId.value,
        'candidateHash': candidate.canonicalHash.value,
        'revision': candidate.revision,
        'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
        'sourceSnapshotHash': snapshotHash.value,
        'name': candidate.name,
        'category': candidate.category.name,
        'uncertainties': candidate.uncertainties,
        'approvalEvidence':
            candidate.evidence.map((item) => item.toJson()).toList(),
        'outputMode': outputMode.name,
        'libraryOnly': true,
        'placementsSubstituted': false,
        'nativeElementId': elementId,
        'nativeCategoryId': categoryId,
        'nativeTilesetId': tilesetId,
        'nativeImageAssetId': 'image_$tilesetId',
        'companionAssetId': companionId,
        'companionLogicalPath': companionPath,
        'pngArtifactHandle': png.handle,
        'pngSha256': png.rawSha256.value,
        'rgbaSha256': rgbaHash,
        'sourceHashes': [
          for (final sourceImage in candidate.sources)
            {
              'fileId': sourceImage.fileId.value,
              'sha256': sourceImage.contentHash.value,
              'path': entries[sourceImage.fileId]!.relativePath,
              'width': sourceImage.pixelWidth,
              'height': sourceImage.pixelHeight,
            },
        ],
        'canvasSize': candidate.canvasSize.toJson(),
        'anchor': candidate.anchor.toJson(),
        'parts': candidate.parts.map((part) => part.toJson()).toList(),
        'nativeSourceRect': {
          'x': geometry.x,
          'y': geometry.y,
          'width': geometry.width,
          'height': geometry.height,
        },
        'paddedSize': {
          'width': geometry.pixelWidth,
          'height': geometry.pixelHeight
        },
        'padding': {
          'right': outputMode == AssetOutputMode.standaloneObjects
              ? geometry.pixelWidth - candidate.canvasSize.width
              : 0,
          'bottom': outputMode == AssetOutputMode.standaloneObjects
              ? geometry.pixelHeight - candidate.canvasSize.height
              : 0,
          'transparent': true,
        },
        'pixelPolicy': _libraryPixelPolicy,
        if (terrain != null)
          'terrainBrush': {
            'layout': candidate.terrainLayout!.name,
            'pngArtifactHandle': terrainPng!.handle,
            'pngSha256': terrainPng.rawSha256.value,
            'nativeTilesetId': terrain.atlas.tilesetId,
            'nativeAtlasId': terrain.atlas.id,
            'nativeMaterialId': terrain.material.id,
            'nativePresetId': terrain.preset.id,
            'placementsSubstituted': false,
            'sourceGrid': {'columns': 3, 'rows': 3, 'cellSize': 32},
            'variantCount': 16,
            'pixelPolicy': 'exact-source-quadrants-no-transforms',
          },
      };
      final companionText = canonicalJsonOf({
        'type': 'approvedAssetLibraryEntry',
        'version': 1,
        ...record,
      }, limits: limits.jsonLimits);
      var utf8Length = 0;
      for (final rune in companionText.runes) {
        utf8Length += rune < 0x80
            ? 1
            : rune < 0x800
                ? 2
                : rune < 0x10000
                    ? 3
                    : 4;
      }
      if (utf8Length > limits.maxArtifactBytes ||
          utf8Length > 1048576 ||
          retainedBytes + utf8Length > limits.maxTotalArtifactBytes) {
        throw const ApprovedAssetLibraryFailure('library.quota.bytes',
            'Companion and retained images exceed the budget');
      }
      final companion = NativeArtifact(
          bytes: utf8.encode(companionText),
          mediaType: 'application/json',
          limits: limits);
      retainedBytes += companion.bytes.length;
      artifactsByHandle[companion.handle] = companion;
      final binding = ApprovedAssetCandidateBinding._(_freezeLibraryJson({
        ...record,
        'companionArtifactHandle': companion.handle,
        'companionSha256': companion.rawSha256.value,
      }, limits));
      bindings.add(binding);
      void mutate(
          String action, List<String> targets, Map<String, Object?> params,
          {String? operationKey}) {
        mutations.add(NativeMutation(
            operationId:
                ConverterId('library_${suffix}_${operationKey ?? action}'),
            actionId: action,
            sourceEntityIds: [candidate.candidateId],
            targetEntityIds: targets.map(ConverterId.new).toList(),
            parameters: params,
            limits: limits));
      }

      mutate('tileset.import_image', [
        tilesetId,
        'image_$tilesetId'
      ], {
        'artifactHandle': png.handle,
        'tilesetId': tilesetId,
        'name': nativeName,
        'tileWidth': 32,
        'tileHeight': 32,
      });
      mutate('element_category.upsert', [
        categoryId
      ], {
        'category': ProjectElementCategory(
                id: categoryId, name: 'Approved ${candidate.category.name}')
            .toJson(),
      });
      mutate('element.upsert', [
        elementId
      ], {
        'element': ProjectElementEntry(
            id: elementId,
            name: nativeName,
            tilesetId: tilesetId,
            categoryId: categoryId,
            frames: [
              TilesetVisualFrame(
                  source: TilesetSourceRect(
                      x: geometry.x,
                      y: geometry.y,
                      width: geometry.width,
                      height: geometry.height))
            ],
            tags: [
              'converter-library',
              'source-category:${candidate.category.name}'
            ]).toJson(),
      });
      mutate('asset.import', [
        companionId
      ], {
        'artifactHandle': companion.handle,
        'assetId': companionId,
        'logicalPath': companionPath,
        'tags': ['converter-library-metadata'],
        'usages': ['converter-library'],
      });
      if (terrain != null) {
        mutate(
            'tileset.import_image',
            [terrain.atlas.tilesetId, 'image_${terrain.atlas.tilesetId}'],
            {
              'artifactHandle': terrainPng!.handle,
              'tilesetId': terrain.atlas.tilesetId,
              'name': nativeName,
              'tileWidth': 32,
              'tileHeight': 32,
            },
            operationKey: 'terrain.image');
        mutate('smart_tile.atlas.upsert', [terrain.atlas.id],
            {'atlas': terrain.atlas.toJson()});
        mutate('smart_tile.material.upsert', [terrain.material.id],
            {'material': terrain.material.toJson()});
        mutate('smart_tile.preset.publish', [terrain.preset.id],
            {'preset': terrain.preset.toJson()});
      }
    }
    cancellation?.check();
    return _composition(source, outputMode, artifactsByHandle.values.toList(),
        sourceArtifacts, mutations, bindings, diagnostics, limits);
  }
}

const _libraryPixelPolicy = {
  'rgba': 'preserve-eight-bit-components-including-rgb-under-zero-alpha',
  'reflection': 'horizontal-before-clockwise-quarter-turns',
  'overlap': 'rejected',
  'holes': 'transparent-zero-rgba',
  'anchor': 'metadata-preserved-native-anchor-unverified',
  'temporalFramesUsedAsParts': false,
};

final class _LibraryGeometry {
  const _LibraryGeometry(this.pixelWidth, this.pixelHeight, this.x, this.y,
      this.width, this.height);
  final int pixelWidth;
  final int pixelHeight;
  final int x;
  final int y;
  final int width;
  final int height;
}

_LibraryGeometry? _sharedGeometry(AssetCandidate candidate) {
  if (candidate.sources.length != 1) return null;
  final source = candidate.sources.single;
  final size = candidate.canvasSize;
  if (source.pixelWidth % 32 != 0 ||
      source.pixelHeight % 32 != 0 ||
      size.width % 32 != 0 ||
      size.height % 32 != 0) {
    return null;
  }
  final first = candidate.parts.first;
  final originX = first.sourceRect.x - first.destinationOffset.x;
  final originY = first.sourceRect.y - first.destinationOffset.y;
  if (originX < 0 || originY < 0 || originX % 32 != 0 || originY % 32 != 0) {
    return null;
  }
  var covered = 0;
  for (final part in candidate.parts) {
    if (part.sourceFileId != source.fileId ||
        part.quarterTurns != 0 ||
        part.reflected ||
        part.sourceRect.x != originX + part.destinationOffset.x ||
        part.sourceRect.y != originY + part.destinationOffset.y) {
      return null;
    }
    covered += part.sourceRect.width * part.sourceRect.height;
  }
  if (covered != size.width * size.height) return null;
  return _LibraryGeometry(source.pixelWidth, source.pixelHeight, originX ~/ 32,
      originY ~/ 32, size.width ~/ 32, size.height ~/ 32);
}

bool _locatorMatches(NormalizedSourceProject source, AssetPart part,
    Map<ConverterId, SourceFileEntry> entries) {
  final locator = part.locator;
  if (!entries.values.any((entry) => entry.relativePath == locator.file)) {
    return false;
  }
  if (locator.mapId == null) {
    return entries[part.sourceFileId]?.relativePath == locator.file &&
        locator.eventId == null &&
        locator.pageIndex == null &&
        locator.commandIndex == null &&
        locator.tileId == null &&
        locator.line == null;
  }
  final maps = source.maps.where((map) => map.map.sourceMapId == locator.mapId);
  if (maps.length != 1 ||
      entries[maps.single.map.sourceFileId]?.relativePath != locator.file) {
    return false;
  }
  final tilesets = source.tilesets.where(
      (tileset) => tileset.sourceTilesetId == maps.single.map.sourceTilesetId);
  if (tilesets.length != 1) return false;
  final tileset = tilesets.single;
  if (!tileset.images.any((reference) =>
      reference.role == 'tileset' &&
      reference.sourceFile?.fileId == part.sourceFileId)) {
    return false;
  }
  final tileId = locator.tileId;
  if (tileId != null &&
      (tileId < 384 ||
          part.sourceRect.x != ((tileId - 384) % 8) * 32 ||
          part.sourceRect.y != ((tileId - 384) ~/ 8) * 32)) {
    return false;
  }
  if (tileId != null) {
    if (part.sourcePriority != null &&
        (tileId >= tileset.priorities.xSize ||
            tileset.priorities.valueAt(tileId, 0, 0) != part.sourcePriority)) {
      return false;
    }
    if (part.sourceLayer != null &&
        !maps.single.map.layers.any((layer) =>
            layer.sourceZ == part.sourceLayer &&
            layer.cells.contains(tileId))) {
      return false;
    }
  }
  return true;
}

Future<Uint8List> _raster(AssetCandidate candidate,
    Map<ConverterId, image.Image> decoded, _LibraryGeometry geometry,
    {ScanCancellation? cancellation}) async {
  final width = candidate.outputMode == AssetOutputMode.sharedAtlas
      ? candidate.canvasSize.width
      : geometry.pixelWidth;
  final height = candidate.outputMode == AssetOutputMode.sharedAtlas
      ? candidate.canvasSize.height
      : geometry.pixelHeight;
  final result = Uint8List(width * height * 4);
  for (final part in candidate.parts) {
    final source = decoded[part.sourceFileId]!;
    final rect = part.sourceRect;
    for (var sy = 0; sy < rect.height; sy++) {
      if (sy % 32 == 0) await Future<void>.delayed(Duration.zero);
      cancellation?.check();
      for (var sx = 0; sx < rect.width; sx++) {
        final reflectedX = part.reflected ? rect.width - 1 - sx : sx;
        final (tx, ty) = switch (part.quarterTurns) {
          0 => (reflectedX, sy),
          1 => (rect.height - 1 - sy, reflectedX),
          2 => (rect.width - 1 - reflectedX, rect.height - 1 - sy),
          3 => (sy, rect.width - 1 - reflectedX),
          _ => throw StateError('Invalid admitted quarter turn'),
        };
        final destination = ((part.destinationOffset.y + ty) * width +
                part.destinationOffset.x +
                tx) *
            4;
        final pixel = source.getPixel(rect.x + sx, rect.y + sy);
        result[destination] = pixel.r.toInt();
        result[destination + 1] = pixel.g.toInt();
        result[destination + 2] = pixel.b.toInt();
        result[destination + 3] = pixel.a.toInt();
      }
    }
  }
  return result;
}

ApprovedAssetLibraryComposition _composition(
    NormalizedSourceProject source,
    AssetOutputMode mode,
    List<NativeArtifact> artifacts,
    List<NativeArtifact> sourceArtifacts,
    List<NativeMutation> mutations,
    List<ApprovedAssetCandidateBinding> bindings,
    List<ApprovedAssetLibraryDiagnostic> diagnostics,
    NativeWriteLimits limits) {
  final record = _freezeLibraryJson({
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'sourceArchiveHash': source.archive.canonicalHash.value,
    'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
    'outputMode': mode.name,
    'libraryOnly': true,
    'placementsSubstituted': false,
    'pixelPolicy': _libraryPixelPolicy,
    'candidates': bindings.map((binding) => binding.toJson()).toList(),
    'diagnostics':
        diagnostics.map((diagnostic) => diagnostic.toJson()).toList(),
  }, limits);
  final hash = canonicalHashOf(record, limits: limits.jsonLimits);
  return ApprovedAssetLibraryComposition._(
      artifacts: List.unmodifiable(artifacts),
      sourceArtifacts: List.unmodifiable(sourceArtifacts),
      mutations: List.unmodifiable(mutations),
      candidateBindings: List.unmodifiable(bindings),
      evidence: _freezeLibraryJson({
        'type': 'approvedAssetLibrary',
        'version': 1,
        'record': record,
        'compositionHash': hash.value
      }, limits),
      diagnostics: List.unmodifiable(diagnostics),
      compositionHash: hash);
}

Map<String, Object?> _freezeLibraryJson(
    Map<String, Object?> value, NativeWriteLimits limits) {
  final canonical = canonicalJsonOf(value, limits: limits.jsonLimits);
  Object? freeze(Object? value) => switch (value) {
        Map() => Map<String, Object?>.unmodifiable(
            value.map((key, item) => MapEntry(key as String, freeze(item)))),
        List() => List<Object?>.unmodifiable(value.map(freeze)),
        _ => value,
      };
  return freeze(jsonDecode(canonical)) as Map<String, Object?>;
}

int _pngByteBound(int width, int height) {
  final raw = (width * 4 + 1) * height;
  return 128 + raw + ((raw + 1023) ~/ 1024) * 5;
}

Uint8List _encodeLibraryPng(Uint8List rgba, int width, int height) {
  final scanlines = Uint8List((width * 4 + 1) * height);
  for (var row = 0; row < height; row++) {
    scanlines.setRange(row * (width * 4 + 1) + 1, (row + 1) * (width * 4 + 1),
        rgba, row * width * 4);
  }
  final compressed = ZLibCodec(level: 0).encode(scanlines);
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 6);
  return (BytesBuilder(copy: false)
        ..add(const [137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_libraryPngChunk('IHDR', header.buffer.asUint8List()))
        ..add(_libraryPngChunk('IDAT', compressed))
        ..add(_libraryPngChunk('IEND', const [])))
      .takeBytes();
}

Uint8List _libraryPngChunk(String name, List<int> bytes) {
  final output = Uint8List(bytes.length + 12);
  ByteData.sublistView(output).setUint32(0, bytes.length);
  output.setRange(4, 8, ascii.encode(name));
  output.setRange(8, bytes.length + 8, bytes);
  var crc = 0xffffffff;
  for (var index = 4; index < output.length - 4; index++) {
    crc ^= output[index];
    for (var bit = 0; bit < 8; bit++) {
      crc = crc & 1 != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  ByteData.sublistView(output).setUint32(output.length - 4, crc ^ 0xffffffff);
  return output;
}
