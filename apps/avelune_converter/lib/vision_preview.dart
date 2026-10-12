import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;

ConverterId visionRegionId(
  ConverterId candidateId,
  ConverterId partId,
) => ConverterId(
  'vision-region:${canonicalHashOf({'candidateId': candidateId.value, 'partId': partId.value}).value}',
);

Future<VisionMaterial> buildVisionPreview({
  required AssetReviewSession session,
  required Set<ConverterId> candidateIds,
  required SourceFilePort sourceFiles,
  required ConverterId requestId,
  required String model,
  String promptVersion = '1',
  Map<String, Object?> options = const {},
  VisionLimits limits = const VisionLimits(),
  ScanCancellation? cancellation,
}) async {
  cancellation?.check();
  _requirePreview(candidateIds.isNotEmpty && candidateIds.length <= 2);
  final candidates =
      session.activeCandidates
          .where((candidate) => candidateIds.contains(candidate.candidateId))
          .toList()
        ..sort((a, b) => a.candidateId.value.compareTo(b.candidateId.value));
  _requirePreview(candidates.length == candidateIds.length);
  final selectedParts = [
    for (final candidate in candidates)
      for (final part in candidate.parts)
        (candidateId: candidate.candidateId, part: part),
  ];
  final parts = selectedParts.map((selected) => selected.part).toList();
  _requirePreview(
    parts.isNotEmpty &&
        parts.length <= 8 &&
        parts.length <= limits.maxCrops &&
        selectedParts
                .map(
                  (selected) => visionRegionId(
                    selected.candidateId,
                    selected.part.partId,
                  ),
                )
                .toSet()
                .length ==
            parts.length,
  );
  const sourceLimits = NativeWriteLimits();
  final sources = <ConverterId, SourceImage>{};
  var cropPixels = 0;
  for (final candidate in candidates) {
    for (final part in candidate.parts) {
      final matching = candidate.sources
          .where((source) => source.fileId == part.sourceFileId)
          .toList();
      _requirePreview(matching.length == 1);
      final source = matching.single;
      final existing = sources[source.fileId];
      _requirePreview(
        existing == null ||
            canonicalHashOf(existing.toJson()) ==
                canonicalHashOf(source.toJson()),
      );
      _requirePreview(
        source.pixelWidth > 0 &&
            source.pixelHeight > 0 &&
            source.pixelWidth * source.pixelHeight <=
                sourceLimits.maxImagePixels,
      );
      final rect = part.sourceRect;
      _requirePreview(
        rect.x >= 0 &&
            rect.y >= 0 &&
            rect.width > 0 &&
            rect.height > 0 &&
            rect.x + rect.width <= source.pixelWidth &&
            rect.y + rect.height <= source.pixelHeight,
      );
      cropPixels += rect.width * rect.height;
      _requirePreview(cropPixels <= limits.maxPixels);
      sources[source.fileId] = source;
    }
  }
  final decodedSources = <ConverterId, image.Image>{};
  for (final source in sources.values) {
    cancellation?.check();
    final bytes = await sourceFiles.read(source.fileId);
    cancellation?.check();
    final artifact = NativeArtifact(bytes: bytes, limits: sourceLimits);
    _requirePreview(artifact.rawSha256 == source.contentHash);
    image.Image? decoded;
    try {
      const NativePngValidator().validate(artifact.bytes, limits: sourceLimits);
      _requirePreview(artifact.bytes[24] <= 8);
      final decoder = image.PngDecoder();
      final info = decoder.startDecode(Uint8List.fromList(artifact.bytes));
      _requirePreview(
        info != null &&
            info.width == source.pixelWidth &&
            info.height == source.pixelHeight,
      );
      decoded = decoder.decodeFrame(0);
    } catch (_) {
      throw const FormatException('vision.preview.source: invalid source PNG');
    }
    _requirePreview(
      decoded != null &&
          decoded.width == source.pixelWidth &&
          decoded.height == source.pixelHeight,
    );
    decodedSources[source.fileId] = decoded!;
  }
  final crops = <VisionCrop>[];
  var totalImageBytes = 0;
  for (final selected in selectedParts) {
    final part = selected.part;
    cancellation?.check();
    final rect = part.sourceRect;
    var raster = image.copyCrop(
      decodedSources[part.sourceFileId]!,
      x: rect.x,
      y: rect.y,
      width: rect.width,
      height: rect.height,
    );
    if (part.reflected) raster = image.flipHorizontal(raster);
    if (part.quarterTurns != 0) {
      raster = image.copyRotate(raster, angle: part.quarterTurns * 90);
    }
    final pixelRaster = image.Image.fromBytes(
      width: raster.width,
      height: raster.height,
      bytes: raster
          .convert(
            format: image.Format.uint8,
            numChannels: 4,
            withPalette: false,
          )
          .getBytes(order: image.ChannelOrder.rgba)
          .buffer,
      numChannels: 4,
      order: image.ChannelOrder.rgba,
    );
    final pngBytes = image.encodePng(pixelRaster);
    totalImageBytes += pngBytes.length;
    _requirePreview(
      pngBytes.length <= limits.maxImageBytes &&
          totalImageBytes <= limits.maxTotalImageBytes,
    );
    crops.add(
      VisionCrop(
        regionId: visionRegionId(selected.candidateId, part.partId),
        fileId: part.sourceFileId,
        sourceHash: sources[part.sourceFileId]!.contentHash,
        sourceRect: rect.toJson(),
        pngBytes: pngBytes,
        transmittedWidth: raster.width,
        transmittedHeight: raster.height,
        quarterTurns: part.quarterTurns,
        reflected: part.reflected,
        transformVersion: '1',
      ),
    );
  }
  cancellation?.check();
  return VisionMaterial(
    context: VisionRequestContext(
      requestId: requestId,
      sourceSnapshotHash: session.sourceSnapshotHash,
      inputRevision: session.revision,
      candidateIds: candidates
          .map((candidate) => candidate.candidateId)
          .toSet(),
      sourceRegionIds: crops.map((crop) => crop.regionId).toSet(),
    ),
    expectedSessionHash: session.canonicalHash,
    candidateHashes: {
      for (final candidate in candidates)
        candidate.candidateId: candidate.canonicalHash,
    },
    crops: crops,
    model: model,
    promptVersion: promptVersion,
    options: options,
    limits: limits,
  );
}

void _requirePreview(bool valid) {
  if (!valid) {
    throw const FormatException(
      'vision.preview.invalid: invalid or oversized preview',
    );
  }
}
